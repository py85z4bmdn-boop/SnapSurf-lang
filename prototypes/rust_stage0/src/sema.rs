use std::collections::BTreeMap;
use std::path::{Path as FsPath, PathBuf};

use crate::ast::*;
use crate::diagnostic::Diagnostic;
use crate::package::{Package, PackageType};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FnSig {
    pub params: Vec<String>,
    pub ret: String,
    pub is_unsafe: bool,
}

#[derive(Debug, Clone)]
struct VarInfo {
    ty: String,
    mutable: bool,
}

pub fn check_program(ast: &SourceAst, package: &Package, file_path: &FsPath) -> Vec<Diagnostic> {
    let mut checker = Checker {
        package,
        file_path: file_path.to_path_buf(),
        functions: BTreeMap::new(),
        diagnostics: Vec::new(),
    };
    checker.check(ast);
    checker.diagnostics
}

struct Checker<'a> {
    package: &'a Package,
    file_path: PathBuf,
    functions: BTreeMap<String, FnSig>,
    diagnostics: Vec<Diagnostic>,
}

impl<'a> Checker<'a> {
    fn check(&mut self, ast: &SourceAst) {
        for item in &ast.items {
            if let Item::Fn(f) = item {
                if self.functions.contains_key(&f.name) {
                    self.error("E4202", "function redeclaration is forbidden in foundation", f.span);
                    continue;
                }
                self.functions.insert(
                    f.name.clone(),
                    FnSig {
                        params: f.params.iter().map(|p| p.ty.name.clone()).collect(),
                        ret: f.ret.name.clone(),
                        is_unsafe: f.is_unsafe,
                    },
                );
                if f.is_unsafe && !self.package.requires.contains("unsafe") {
                    self.error("E0801", "unsafe function requires package capability unsafe", f.span);
                }
            }
        }

        if self.package.package_type == PackageType::Executable {
            match self.functions.get("main") {
                Some(sig) if sig.params.is_empty() && sig.ret == "i32" && !sig.is_unsafe => {}
                Some(_) => self.error(
                    "E0902",
                    "foundation executable main signature must be exactly fn main -> i32",
                    ast.span,
                ),
                None => self.error("E0902", "executable package requires fn main -> i32", ast.span),
            }
        }

        for item in &ast.items {
            if let Item::Fn(f) = item {
                self.check_fn(f);
            }
        }
    }

    fn check_fn(&mut self, f: &FnDecl) {
        let mut ctx = FnCtx {
            vars: BTreeMap::new(),
            return_type: f.ret.name.clone(),
            loop_depth: 0,
            unsafe_depth: usize::from(f.is_unsafe),
        };
        for param in &f.params {
            if ctx.vars.contains_key(&param.name) {
                self.error("E4202", "variable shadowing is forbidden in foundation", param.span);
            } else {
                ctx.vars.insert(
                    param.name.clone(),
                    VarInfo {
                        ty: param.ty.name.clone(),
                        mutable: false,
                    },
                );
            }
        }
        self.check_block(&f.body, &mut ctx);
        if f.ret.name != "void" && !block_returns(&f.body) {
            self.error("E4101", format!("not all control paths return {}", f.ret.name), f.span);
        }
    }

    fn check_block(&mut self, block: &Block, ctx: &mut FnCtx) {
        for stmt in &block.statements {
            self.check_stmt(stmt, ctx);
        }
    }

    fn check_stmt(&mut self, stmt: &Stmt, ctx: &mut FnCtx) {
        match stmt {
            Stmt::Let { name, ty, expr, span } => {
                self.declare_var(ctx, name, ty, expr, false, *span);
            }
            Stmt::Mut { name, ty, expr, span } => {
                self.declare_var(ctx, name, ty, expr, true, *span);
            }
            Stmt::Assign { name, expr, span } => {
                let Some(info) = ctx.vars.get(name).cloned() else {
                    self.error("E0401", format!("undeclared variable `{name}`"), *span);
                    return;
                };
                if !info.mutable {
                    self.error("E4201", format!("cannot assign to immutable variable `{name}`"), *span);
                }
                let actual = self.expr_type(expr, ctx);
                self.require_type(&info.ty, &actual, expr.span());
            }
            Stmt::Ret { expr, span } => {
                if ctx.return_type == "void" {
                    if expr.is_some() {
                        self.error("E0402", "void function cannot return a value", *span);
                    }
                } else if let Some(expr) = expr {
                    let actual = self.expr_type(expr, ctx);
                    self.require_type(&ctx.return_type, &actual, expr.span());
                } else {
                    self.error("E0402", format!("return requires {}", ctx.return_type), *span);
                }
            }
            Stmt::If {
                cond,
                then_block,
                else_block,
                ..
            } => {
                let actual = self.expr_type(cond, ctx);
                if !actual.is_bool() {
                    self.error("E4301", "if condition must be bool", cond.span());
                }
                self.check_block(then_block, ctx);
                if let Some(else_block) = else_block {
                    self.check_block(else_block, ctx);
                }
            }
            Stmt::Loop { body, .. } => {
                ctx.loop_depth += 1;
                self.check_block(body, ctx);
                ctx.loop_depth -= 1;
            }
            Stmt::While { cond, body, .. } => {
                let actual = self.expr_type(cond, ctx);
                if !actual.is_bool() {
                    self.error("E4301", "while condition must be bool", cond.span());
                }
                ctx.loop_depth += 1;
                self.check_block(body, ctx);
                ctx.loop_depth -= 1;
            }
            Stmt::Break { span } => {
                if ctx.loop_depth == 0 {
                    self.error("E0501", "break outside loop", *span);
                }
            }
            Stmt::Continue { span } => {
                if ctx.loop_depth == 0 {
                    self.error("E0502", "continue outside loop", *span);
                }
            }
            Stmt::UnsafeBlock { body, span } => {
                if !self.package.requires.contains("unsafe") {
                    self.error("E0801", "unsafe block requires package capability unsafe", *span);
                }
                ctx.unsafe_depth += 1;
                self.check_block(body, ctx);
                ctx.unsafe_depth -= 1;
            }
            Stmt::Expr { expr, .. } => {
                self.expr_type(expr, ctx);
            }
            Stmt::Error { span } => {
                self.error("E0301", "error node reached validation boundary", *span);
            }
        }
    }

    fn declare_var(
        &mut self,
        ctx: &mut FnCtx,
        name: &str,
        ty: &TypeRef,
        expr: &Expr,
        mutable: bool,
        span: crate::diagnostic::Span,
    ) {
        if ctx.vars.contains_key(name) {
            self.error("E4202", "variable shadowing is forbidden in foundation", span);
            return;
        }
        let actual = self.expr_type(expr, ctx);
        self.require_type(&ty.name, &actual, expr.span());
        ctx.vars.insert(
            name.to_string(),
            VarInfo {
                ty: ty.name.clone(),
                mutable,
            },
        );
    }

    fn expr_type(&mut self, expr: &Expr, ctx: &mut FnCtx) -> Ty {
        match expr {
            Expr::IntLit { value, .. } => Ty::IntLiteral(*value),
            Expr::StrLit { .. } => Ty::Named("str_static".to_string()),
            Expr::BoolLit { .. } => Ty::Named("bool".to_string()),
            Expr::Ident { name, span } => {
                if let Some(var) = ctx.vars.get(name) {
                    Ty::Named(var.ty.clone())
                } else if let Some(sig) = self.functions.get(name).cloned() {
                    if !sig.params.is_empty() {
                        self.error("E0404", format!("function `{name}` expects arguments"), *span);
                    }
                    if sig.is_unsafe && ctx.unsafe_depth == 0 {
                        self.error("E0701", "unsafe function call requires unsafe scope", *span);
                    }
                    Ty::Named(sig.ret)
                } else {
                    self.error("E0401", format!("undeclared variable `{name}`"), *span);
                    Ty::Error
                }
            }
            Expr::Path { path, span } => {
                self.error("E0403", format!("function call target `{}` does not exist", path.display()), *span);
                Ty::Error
            }
            Expr::Unary { op, expr, span } => {
                let ty = self.expr_type(expr, ctx);
                match op {
                    UnaryOp::Not => {
                        if !ty.is_bool() {
                            self.error("E0402", "not requires bool", *span);
                        }
                        Ty::Named("bool".to_string())
                    }
                    UnaryOp::Neg => {
                        if !ty.is_numeric_or_literal() {
                            self.error("E0402", "unary minus requires integer", *span);
                        }
                        ty
                    }
                }
            }
            Expr::Binary {
                op,
                left,
                right,
                span,
            } => {
                let left_ty = self.expr_type(left, ctx);
                let right_ty = self.expr_type(right, ctx);
                match op {
                    BinaryOp::Add | BinaryOp::Sub | BinaryOp::Mul | BinaryOp::Div | BinaryOp::Mod => {
                        if left_ty.is_str() || right_ty.is_str() {
                            self.error("E3001", "string concatenation requires explicit allocation", *span);
                            return Ty::Error;
                        }
                        if !left_ty.is_numeric_or_literal() || !right_ty.is_numeric_or_literal() {
                            self.error("E0402", "arithmetic operands must be integers", *span);
                            Ty::Error
                        } else {
                            merge_numeric(left_ty, right_ty)
                        }
                    }
                    BinaryOp::Eq
                    | BinaryOp::NotEq
                    | BinaryOp::Lt
                    | BinaryOp::LtEq
                    | BinaryOp::Gt
                    | BinaryOp::GtEq => {
                        if !compatible_loose(&left_ty, &right_ty) {
                            self.error("E0402", "comparison operands have incompatible types", *span);
                        }
                        Ty::Named("bool".to_string())
                    }
                    BinaryOp::And | BinaryOp::Or => {
                        if !left_ty.is_bool() || !right_ty.is_bool() {
                            self.error("E0402", "boolean operators require bool operands", *span);
                        }
                        Ty::Named("bool".to_string())
                    }
                }
            }
            Expr::Call { callee, args, span } => self.call_type(callee, args, *span, ctx),
            Expr::Error { .. } => Ty::Error,
        }
    }

    fn call_type(
        &mut self,
        callee: &Path,
        args: &[Expr],
        span: crate::diagnostic::Span,
        ctx: &mut FnCtx,
    ) -> Ty {
        let name = callee.display();
        if name == "io.write" || name == "core/io.write" {
            if !self.package.requires.contains("syscall") {
                self.error(
                    "E2001",
                    "package declares insufficient capability for core/io syscall use",
                    span,
                );
            }
            if args.len() != 3 {
                self.error("E0404", "io.write expects 3 arguments", span);
                return Ty::Named("void".to_string());
            }
            let fd = self.expr_type(&args[0], ctx);
            let msg = self.expr_type(&args[1], ctx);
            let len = self.expr_type(&args[2], ctx);
            if !fd.is_numeric_or_literal() || !len.is_numeric_or_literal() || !msg.is_str() {
                self.error("E0402", "io.write expects integer, string literal, integer", span);
            }
            return Ty::Named("void".to_string());
        }
        if name == "mem.alloc" {
            if !self.package.requires.contains("heap") {
                self.error("E0801", "mem.alloc requires package capability heap", span);
            }
            if ctx.unsafe_depth == 0 {
                self.error("E0701", "mem.alloc requires unsafe scope in foundation", span);
            }
            if args.len() != 1 {
                self.error("E0404", "mem.alloc expects 1 argument", span);
            }
            return Ty::Named("*u8".to_string());
        }
        if callee.segments.len() == 1 {
            let func = &callee.segments[0];
            if let Some(sig) = self.functions.get(func).cloned() {
                if sig.is_unsafe && ctx.unsafe_depth == 0 {
                    self.error("E0701", "unsafe function call requires unsafe scope", span);
                }
                if sig.params.len() != args.len() {
                    self.error("E0404", format!("function `{func}` argument count mismatch"), span);
                } else {
                    for (arg, expected) in args.iter().zip(sig.params.iter()) {
                        let actual = self.expr_type(arg, ctx);
                        self.require_type(expected, &actual, arg.span());
                    }
                }
                return Ty::Named(sig.ret);
            }
        }
        self.error("E0403", format!("function call target `{name}` does not exist"), span);
        Ty::Error
    }

    fn require_type(&mut self, expected: &str, actual: &Ty, span: crate::diagnostic::Span) {
        if actual == &Ty::Error {
            return;
        }
        if let Ty::IntLiteral(value) = actual {
            if is_integer_type(expected) {
                if !literal_fits(*value, expected) {
                    self.error("E4001", format!("integer literal does not fit in {expected}"), span);
                }
                return;
            }
        }
        if actual == &Ty::Named(expected.to_string()) {
            return;
        }
        self.error("E0402", format!("type mismatch: expected {expected}, got {}", actual.display()), span);
    }

    fn error(&mut self, code: &'static str, message: impl Into<String>, span: crate::diagnostic::Span) {
        self.diagnostics.push(Diagnostic::error(
            code,
            message,
            &self.file_path,
            span.source_file_id,
            span,
        ));
    }
}

#[derive(Debug)]
struct FnCtx {
    vars: BTreeMap<String, VarInfo>,
    return_type: String,
    loop_depth: usize,
    unsafe_depth: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Ty {
    Named(String),
    IntLiteral(u128),
    Error,
}

impl Ty {
    fn is_bool(&self) -> bool {
        self == &Ty::Named("bool".to_string())
    }

    fn is_str(&self) -> bool {
        self == &Ty::Named("str_static".to_string())
    }

    fn is_numeric_or_literal(&self) -> bool {
        match self {
            Ty::IntLiteral(_) => true,
            Ty::Named(name) => is_integer_type(name),
            Ty::Error => false,
        }
    }

    fn display(&self) -> String {
        match self {
            Ty::Named(name) => name.clone(),
            Ty::IntLiteral(_) => "integer literal".to_string(),
            Ty::Error => "error".to_string(),
        }
    }
}

fn merge_numeric(left: Ty, right: Ty) -> Ty {
    match (left, right) {
        (Ty::Named(name), _) if is_integer_type(&name) => Ty::Named(name),
        (_, Ty::Named(name)) if is_integer_type(&name) => Ty::Named(name),
        (Ty::IntLiteral(_), Ty::IntLiteral(_)) => Ty::IntLiteral(0),
        _ => Ty::Error,
    }
}

fn compatible_loose(left: &Ty, right: &Ty) -> bool {
    left == right || (left.is_numeric_or_literal() && right.is_numeric_or_literal())
}

fn is_integer_type(name: &str) -> bool {
    matches!(
        name,
        "i8" | "i16" | "i32" | "i64" | "u8" | "u16" | "u32" | "u64" | "byte"
    )
}

fn literal_fits(value: u128, ty: &str) -> bool {
    match ty {
        "i8" => value <= i8::MAX as u128,
        "i16" => value <= i16::MAX as u128,
        "i32" => value <= i32::MAX as u128,
        "i64" => value <= i64::MAX as u128,
        "u8" | "byte" => value <= u8::MAX as u128,
        "u16" => value <= u16::MAX as u128,
        "u32" => value <= u32::MAX as u128,
        "u64" => value <= u64::MAX as u128,
        _ => false,
    }
}

fn block_returns(block: &Block) -> bool {
    block.statements.iter().any(stmt_returns)
}

fn stmt_returns(stmt: &Stmt) -> bool {
    match stmt {
        Stmt::Ret { .. } => true,
        Stmt::If {
            then_block,
            else_block: Some(else_block),
            ..
        } => block_returns(then_block) && block_returns(else_block),
        _ => false,
    }
}
