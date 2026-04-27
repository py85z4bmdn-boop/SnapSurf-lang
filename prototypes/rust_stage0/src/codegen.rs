use std::collections::{BTreeMap, BTreeSet};

use crate::ast::*;
use crate::package::Package;

pub fn emit_nasm(ast: &SourceAst, package: &Package) -> String {
    let mut cg = Codegen {
        asm: String::new(),
        strings: Vec::new(),
        label_id: 0,
        functions: BTreeSet::new(),
        package,
    };
    cg.emit(ast);
    cg.asm
}

struct Codegen<'a> {
    asm: String,
    strings: Vec<(String, Vec<u8>)>,
    label_id: usize,
    functions: BTreeSet<String>,
    package: &'a Package,
}

#[derive(Debug, Clone)]
struct FnEnv {
    locals: BTreeMap<String, i32>,
    end_label: String,
    break_labels: Vec<String>,
    continue_labels: Vec<String>,
}

impl<'a> Codegen<'a> {
    fn emit(&mut self, ast: &SourceAst) {
        for item in &ast.items {
            if let Item::Fn(f) = item {
                self.functions.insert(f.name.clone());
            }
        }
        self.line("default rel");
        self.line("global _start");
        self.line("section .text");
        if self.package.runtime == "tiny" {
            self.line("_start:");
            self.line("    call main");
            self.line("    mov edi, eax");
            self.line("    mov eax, 60");
            self.line("    syscall");
            self.line("");
        }
        for item in &ast.items {
            if let Item::Fn(f) = item {
                self.emit_fn(f);
            }
        }
        if !self.strings.is_empty() {
            self.line("section .rodata");
            let strings = std::mem::take(&mut self.strings);
            for (label, bytes) in strings {
                self.line(&format!("{label}:"));
                self.line(&format!("    db {}", format_bytes(&bytes)));
            }
        }
    }

    fn emit_fn(&mut self, f: &FnDecl) {
        let mut locals = BTreeMap::new();
        for param in &f.params {
            let next = ((locals.len() + 1) * 8) as i32;
            locals.insert(param.name.clone(), next);
        }
        collect_locals(&f.body, &mut locals);
        let stack_size = align16(locals.len() * 8);
        let end_label = self.label("fn_end");
        let mut env = FnEnv {
            locals,
            end_label: end_label.clone(),
            break_labels: Vec::new(),
            continue_labels: Vec::new(),
        };

        self.line(&format!("{}:", f.name));
        self.line("    push rbp");
        self.line("    mov rbp, rsp");
        if stack_size > 0 {
            self.line(&format!("    sub rsp, {stack_size}"));
        }
        let regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
        for (idx, param) in f.params.iter().enumerate() {
            if let Some(offset) = env.locals.get(&param.name) {
                if idx < regs.len() {
                    self.line(&format!("    mov [rbp-{offset}], {}", regs[idx]));
                }
            }
        }
        self.emit_block(&f.body, &mut env);
        if f.ret.name == "void" {
            self.line("    xor eax, eax");
        }
        self.line(&format!("{end_label}:"));
        self.line("    mov rsp, rbp");
        self.line("    pop rbp");
        self.line("    ret");
        self.line("");
    }

    fn emit_block(&mut self, block: &Block, env: &mut FnEnv) {
        for stmt in &block.statements {
            self.emit_stmt(stmt, env);
        }
    }

    fn emit_stmt(&mut self, stmt: &Stmt, env: &mut FnEnv) {
        match stmt {
            Stmt::Let { name, expr, .. } | Stmt::Mut { name, expr, .. } => {
                self.emit_expr(expr, env);
                let offset = env.locals[name];
                self.line(&format!("    mov [rbp-{offset}], rax"));
            }
            Stmt::Assign { name, expr, .. } => {
                self.emit_expr(expr, env);
                let offset = env.locals[name];
                self.line(&format!("    mov [rbp-{offset}], rax"));
            }
            Stmt::Ret { expr, .. } => {
                if let Some(expr) = expr {
                    self.emit_expr(expr, env);
                } else {
                    self.line("    xor eax, eax");
                }
                self.line(&format!("    jmp {}", env.end_label));
            }
            Stmt::If {
                cond,
                then_block,
                else_block,
                ..
            } => {
                let else_label = self.label("if_else");
                let end_label = self.label("if_end");
                self.emit_expr(cond, env);
                self.line("    cmp rax, 0");
                if else_block.is_some() {
                    self.line(&format!("    je {else_label}"));
                } else {
                    self.line(&format!("    je {end_label}"));
                }
                self.emit_block(then_block, env);
                self.line(&format!("    jmp {end_label}"));
                if let Some(else_block) = else_block {
                    self.line(&format!("{else_label}:"));
                    self.emit_block(else_block, env);
                }
                self.line(&format!("{end_label}:"));
            }
            Stmt::Loop { body, .. } => {
                let start = self.label("loop_start");
                let end = self.label("loop_end");
                env.continue_labels.push(start.clone());
                env.break_labels.push(end.clone());
                self.line(&format!("{start}:"));
                self.emit_block(body, env);
                self.line(&format!("    jmp {start}"));
                self.line(&format!("{end}:"));
                env.continue_labels.pop();
                env.break_labels.pop();
            }
            Stmt::While { cond, body, .. } => {
                let start = self.label("while_start");
                let end = self.label("while_end");
                env.continue_labels.push(start.clone());
                env.break_labels.push(end.clone());
                self.line(&format!("{start}:"));
                self.emit_expr(cond, env);
                self.line("    cmp rax, 0");
                self.line(&format!("    je {end}"));
                self.emit_block(body, env);
                self.line(&format!("    jmp {start}"));
                self.line(&format!("{end}:"));
                env.continue_labels.pop();
                env.break_labels.pop();
            }
            Stmt::Break { .. } => {
                if let Some(label) = env.break_labels.last() {
                    self.line(&format!("    jmp {label}"));
                }
            }
            Stmt::Continue { .. } => {
                if let Some(label) = env.continue_labels.last() {
                    self.line(&format!("    jmp {label}"));
                }
            }
            Stmt::UnsafeBlock { body, .. } => self.emit_block(body, env),
            Stmt::Expr { expr, .. } => {
                self.emit_expr(expr, env);
            }
            Stmt::Error { .. } => {}
        }
    }

    fn emit_expr(&mut self, expr: &Expr, env: &mut FnEnv) {
        match expr {
            Expr::IntLit { value, .. } => self.line(&format!("    mov rax, {value}")),
            Expr::BoolLit { value, .. } => self.line(&format!("    mov rax, {}", u8::from(*value))),
            Expr::StrLit { bytes, .. } => {
                let label = self.string_label(bytes);
                self.line(&format!("    lea rax, [rel {label}]"));
            }
            Expr::Ident { name, .. } => {
                if let Some(offset) = env.locals.get(name) {
                    self.line(&format!("    mov rax, [rbp-{offset}]"));
                } else if self.functions.contains(name) {
                    self.line(&format!("    call {name}"));
                } else {
                    self.line("    xor eax, eax");
                }
            }
            Expr::Path { .. } => self.line("    xor eax, eax"),
            Expr::Unary { op, expr, .. } => {
                self.emit_expr(expr, env);
                match op {
                    UnaryOp::Neg => self.line("    neg rax"),
                    UnaryOp::Not => {
                        self.line("    cmp rax, 0");
                        self.line("    sete al");
                        self.line("    movzx rax, al");
                    }
                }
            }
            Expr::Binary {
                op,
                left,
                right,
                ..
            } => {
                self.emit_expr(left, env);
                self.line("    push rax");
                self.emit_expr(right, env);
                self.line("    mov rbx, rax");
                self.line("    pop rax");
                match op {
                    BinaryOp::Add => self.line("    add rax, rbx"),
                    BinaryOp::Sub => self.line("    sub rax, rbx"),
                    BinaryOp::Mul => self.line("    imul rax, rbx"),
                    BinaryOp::Div => {
                        self.line("    cqo");
                        self.line("    idiv rbx");
                    }
                    BinaryOp::Mod => {
                        self.line("    cqo");
                        self.line("    idiv rbx");
                        self.line("    mov rax, rdx");
                    }
                    BinaryOp::Eq => self.emit_cmp("sete"),
                    BinaryOp::NotEq => self.emit_cmp("setne"),
                    BinaryOp::Lt => self.emit_cmp("setl"),
                    BinaryOp::LtEq => self.emit_cmp("setle"),
                    BinaryOp::Gt => self.emit_cmp("setg"),
                    BinaryOp::GtEq => self.emit_cmp("setge"),
                    BinaryOp::And => self.line("    and rax, rbx"),
                    BinaryOp::Or => self.line("    or rax, rbx"),
                }
            }
            Expr::Call { callee, args, .. } => self.emit_call(callee, args, env),
            Expr::Error { .. } => self.line("    xor eax, eax"),
        }
    }

    fn emit_call(&mut self, callee: &Path, args: &[Expr], env: &mut FnEnv) {
        let name = callee.display();
        if name == "io.write" {
            for arg in args {
                self.emit_expr(arg, env);
                self.line("    push rax");
            }
            self.line("    pop rdx");
            self.line("    pop rsi");
            self.line("    pop rdi");
            self.line("    mov rax, 1");
            self.line("    syscall");
            self.line("    xor eax, eax");
            return;
        }
        let regs = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"];
        for arg in args {
            self.emit_expr(arg, env);
            self.line("    push rax");
        }
        for idx in (0..args.len()).rev() {
            if idx < regs.len() {
                self.line(&format!("    pop {}", regs[idx]));
            }
        }
        self.line(&format!("    call {name}"));
    }

    fn emit_cmp(&mut self, setcc: &str) {
        self.line("    cmp rax, rbx");
        self.line(&format!("    {setcc} al"));
        self.line("    movzx rax, al");
    }

    fn string_label(&mut self, bytes: &[u8]) -> String {
        let label = format!(".Lstr{}", self.strings.len());
        self.strings.push((label.clone(), bytes.to_vec()));
        label
    }

    fn label(&mut self, prefix: &str) -> String {
        let label = format!(".L_{prefix}_{}", self.label_id);
        self.label_id += 1;
        label
    }

    fn line(&mut self, line: &str) {
        self.asm.push_str(line);
        self.asm.push('\n');
    }
}

fn collect_locals(block: &Block, locals: &mut BTreeMap<String, i32>) {
    for stmt in &block.statements {
        match stmt {
            Stmt::Let { name, .. } | Stmt::Mut { name, .. } => {
                if !locals.contains_key(name) {
                    let next = ((locals.len() + 1) * 8) as i32;
                    locals.insert(name.clone(), next);
                }
            }
            Stmt::If {
                then_block,
                else_block,
                ..
            } => {
                collect_locals(then_block, locals);
                if let Some(else_block) = else_block {
                    collect_locals(else_block, locals);
                }
            }
            Stmt::Loop { body, .. }
            | Stmt::While { body, .. }
            | Stmt::UnsafeBlock { body, .. } => collect_locals(body, locals),
            _ => {}
        }
    }
}

fn align16(n: usize) -> usize {
    (n + 15) & !15
}

fn format_bytes(bytes: &[u8]) -> String {
    if bytes.is_empty() {
        return "0".to_string();
    }
    bytes
        .iter()
        .map(|b| b.to_string())
        .collect::<Vec<_>>()
        .join(", ")
}

