use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::ast::SourceAst;
use crate::codegen::emit_nasm;
use crate::diagnostic::{dummy_span, Diagnostic};
use crate::lexer::Lexer;
use crate::package::Package;
use crate::parser::Parser;
use crate::sema::check_program;
use crate::source::SourceFile;

#[derive(Debug, Clone)]
pub struct Compilation {
    pub package: Package,
    pub ast: SourceAst,
    pub source_path: PathBuf,
}

pub fn init(root: &Path) -> Result<(), Vec<Diagnostic>> {
    let src = root.join("src");
    fs::create_dir_all(&src).map_err(|e| {
        vec![fatal(
            root,
            format!("failed to create src directory: {e}"),
        )]
    })?;
    let pkg = root.join("surf.pkg");
    if !pkg.exists() {
        fs::write(
            &pkg,
            "package hello\nversion 0.1.0\ntype executable\ntarget linux-x86_64\nruntime tiny\nentry main\n\nrequires syscall\n\ndep core/io 0.1.0\nend\n",
        )
        .map_err(|e| vec![fatal(&pkg, format!("failed to write surf.pkg: {e}"))])?;
    }
    let main = src.join("main.snapsurf");
    if !main.exists() {
        fs::write(
            &main,
            "use core/io\n\nfn main -> i32\n    io.write 1 \"Hello SnapSurf\\n\" 15\n    ret 0\nend\n",
        )
        .map_err(|e| vec![fatal(&main, format!("failed to write src/main.snapsurf: {e}"))])?;
    }
    Ok(())
}

pub fn run_check(root: &Path) -> Result<Compilation, Vec<Diagnostic>> {
    compile_package(root)
}

pub fn emit_asm(root: &Path) -> Result<String, Vec<Diagnostic>> {
    let compilation = compile_package(root)?;
    Ok(emit_nasm(&compilation.ast, &compilation.package))
}

pub fn run_build(root: &Path) -> Result<PathBuf, Vec<Diagnostic>> {
    let compilation = compile_package(root)?;
    let asm = emit_nasm(&compilation.ast, &compilation.package);
    let build_dir = root.join("build");
    fs::create_dir_all(&build_dir)
        .map_err(|e| vec![fatal(&build_dir, format!("failed to create build directory: {e}"))])?;
    let asm_path = build_dir.join(format!("{}.asm", compilation.package.name));
    let obj_path = build_dir.join(format!("{}.o", compilation.package.name));
    let bin_path = build_dir.join(&compilation.package.name);
    fs::write(&asm_path, asm)
        .map_err(|e| vec![fatal(&asm_path, format!("failed to write assembly: {e}"))])?;
    let nasm = Command::new("nasm")
        .args(["-f", "elf64"])
        .arg(&asm_path)
        .arg("-o")
        .arg(&obj_path)
        .output()
        .map_err(|e| vec![fatal(root, format!("failed to run nasm: {e}"))])?;
    if !nasm.status.success() {
        return Err(vec![fatal(
            &asm_path,
            format!("nasm failed: {}", String::from_utf8_lossy(&nasm.stderr)),
        )]);
    }
    let ld = Command::new("ld")
        .arg("-o")
        .arg(&bin_path)
        .arg(&obj_path)
        .output()
        .map_err(|e| vec![fatal(root, format!("failed to run ld: {e}"))])?;
    if !ld.status.success() {
        return Err(vec![fatal(
            &obj_path,
            format!("ld failed: {}", String::from_utf8_lossy(&ld.stderr)),
        )]);
    }
    Ok(bin_path)
}

pub fn run_executable(root: &Path) -> Result<(), Vec<Diagnostic>> {
    let bin = run_build(root)?;
    let status = Command::new(&bin)
        .status()
        .map_err(|e| vec![fatal(&bin, format!("failed to run executable: {e}"))])?;
    if !status.success() {
        return Err(vec![fatal(
            &bin,
            format!("executable exited with status {status}"),
        )]);
    }
    Ok(())
}

pub fn clean(root: &Path) -> Result<(), Vec<Diagnostic>> {
    let build_dir = root.join("build");
    if build_dir.exists() {
        fs::remove_dir_all(&build_dir)
            .map_err(|e| vec![fatal(&build_dir, format!("failed to remove build directory: {e}"))])?;
    }
    Ok(())
}

fn compile_package(root: &Path) -> Result<Compilation, Vec<Diagnostic>> {
    let package = Package::load(root)?;
    let source_path = package.entry_source();
    let source = SourceFile::load_snapsurf(&source_path, 1)?;
    let (tokens, lex_diags) = Lexer::new(&source).lex();
    if !lex_diags.is_empty() {
        return Err(lex_diags);
    }
    let (ast, parse_diags) = Parser::new(&tokens, &source.path, source.id).parse();
    if !parse_diags.is_empty() {
        return Err(parse_diags);
    }
    let sema_diags = check_program(&ast, &package, &source.path);
    if !sema_diags.is_empty() {
        return Err(sema_diags);
    }
    Ok(Compilation {
        package,
        ast,
        source_path,
    })
}

fn fatal(path: &Path, message: impl Into<String>) -> Diagnostic {
    Diagnostic::error("E9000", message, path, 0, dummy_span())
}

