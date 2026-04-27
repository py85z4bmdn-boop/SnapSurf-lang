use std::env;
use std::path::PathBuf;

use surf::driver::{clean, emit_asm, init, run_build, run_check, run_executable};

fn main() {
    let code = match real_main() {
        Ok(()) => 0,
        Err(code) => code,
    };
    std::process::exit(code);
}

fn real_main() -> Result<(), i32> {
    let mut args: Vec<String> = env::args().skip(1).collect();
    if args.is_empty() {
        print_usage();
        return Err(2);
    }

    let cmd = args.remove(0);
    let cwd = env::current_dir().map_err(|e| {
        eprintln!("E9000 failed to read current directory: {e}");
        1
    })?;

    match cmd.as_str() {
        "version" | "--version" | "-V" => {
            println!("surf 0.1.0-foundation-bootstrap");
            Ok(())
        }
        "init" => init(&cwd).map_err(print_diags),
        "check" => {
            let root = args.first().map(PathBuf::from).unwrap_or(cwd);
            run_check(&root).map(|_| ()).map_err(print_diags)
        }
        "emit" => {
            if args.first().map(|s| s.as_str()) != Some("asm") {
                eprintln!("E9000 expected: surf emit asm [package-root]");
                return Err(2);
            }
            let root = args.get(1).map(PathBuf::from).unwrap_or(cwd);
            emit_asm(&root).map(|asm| {
                print!("{asm}");
            }).map_err(print_diags)
        }
        "build" => {
            let root = args.first().map(PathBuf::from).unwrap_or(cwd);
            run_build(&root).map(|path| {
                println!("{}", path.display());
            }).map_err(print_diags)
        }
        "run" => {
            let root = args.first().map(PathBuf::from).unwrap_or(cwd);
            run_executable(&root).map_err(print_diags)
        }
        "clean" => {
            let root = args.first().map(PathBuf::from).unwrap_or(cwd);
            clean(&root).map_err(print_diags)
        }
        _ => {
            print_usage();
            Err(2)
        }
    }
}

fn print_usage() {
    eprintln!("usage: surf <init|check|build|run|clean|emit asm|version> [package-root]");
}

fn print_diags(diags: Vec<surf::diagnostic::Diagnostic>) -> i32 {
    for diag in &diags {
        eprintln!("{}", diag.render());
    }
    1
}

