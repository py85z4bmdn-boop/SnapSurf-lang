use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use surf::driver::{emit_asm, run_build, run_check};
use surf::lexer::Lexer;
use surf::parser::Parser;
use surf::source::SourceFile;

fn temp_root(name: &str) -> PathBuf {
    let root = std::env::temp_dir().join(format!(
        "snapsurf_{name}_{}_{}",
        std::process::id(),
        unique_tick()
    ));
    fs::create_dir_all(root.join("src")).unwrap();
    root
}

fn unique_tick() -> u128 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos()
}

fn write_pkg(root: &Path, requires: &str) {
    fs::write(
        root.join("surf.pkg"),
        format!(
            "package hello\nversion 0.1.0\ntype executable\ntarget linux-x86_64\nruntime tiny\nentry main\n\nrequires {requires}\n\ndep core/io 0.1.0\nend\n"
        ),
    )
    .unwrap();
}

fn write_main(root: &Path, source: &str) {
    fs::write(root.join("src/main.snapsurf"), source).unwrap();
}

fn check_fails_with(source: &str, requires: &str, code: &str) {
    let root = temp_root(code);
    write_pkg(&root, requires);
    write_main(&root, source);
    let err = run_check(&root).unwrap_err();
    assert!(err.iter().any(|d| d.code == code), "{err:#?}");
}

#[test]
fn source_reader_enforces_extension_and_bom() {
    let root = temp_root("source_rules");
    let bad_ext = root.join("src/main.surf");
    fs::write(&bad_ext, "fn main -> i32\n    ret 0\nend\n").unwrap();
    let err = SourceFile::load_snapsurf(&bad_ext, 1).unwrap_err();
    assert_eq!(err[0].code, "E0003");

    let bom = root.join("src/bom.snapsurf");
    fs::write(&bom, [0xEF, 0xBB, 0xBF, b'f', b'n']).unwrap();
    let err = SourceFile::load_snapsurf(&bom, 1).unwrap_err();
    assert_eq!(err[0].code, "E0001");
}

#[test]
fn package_layout_is_strict() {
    let root = temp_root("pkg_missing_entry");
    fs::write(
        root.join("surf.pkg"),
        "package bad\nversion 0.1.0\ntype executable\ntarget linux-x86_64\nruntime tiny\nrequires none\nend\n",
    )
    .unwrap();
    let err = run_check(&root).unwrap_err();
    assert!(err.iter().any(|d| d.code == "E0903"));
}

#[test]
fn parser_recovers_from_invalid_input_without_panicking() {
    let corpus = [
        "",
        "}",
        "fn -> ->\n",
        "else ->\nend\n",
        "fn main -> i32\n if true ->\n",
        "\"unterminated",
        "/* unterminated",
    ];
    for (idx, text) in corpus.iter().enumerate() {
        let path = PathBuf::from(format!("fuzz_{idx}.snapsurf"));
        let source = SourceFile {
            id: 1,
            path: path.clone(),
            bytes: text.as_bytes().to_vec(),
            text: (*text).to_string(),
        };
        let (tokens, _) = Lexer::new(&source).lex();
        let _ = Parser::new(&tokens, &path, 1).parse();
    }
}

#[test]
fn semantic_compile_fail_codes_are_stable() {
    check_fails_with(
        "fn main -> i32\n    let x i32 = true\n    ret x\nend\n",
        "none",
        "E0402",
    );
    check_fails_with(
        "fn main -> i32\n    let x i32 = 1\n    x = 2\n    ret x\nend\n",
        "none",
        "E4201",
    );
    check_fails_with(
        "fn main -> i32\n    if 1 ->\n        ret 0\n    end\n    ret 1\nend\n",
        "none",
        "E4301",
    );
    check_fails_with("fn main -> i32\n    break\n    ret 0\nend\n", "none", "E0501");
    check_fails_with(
        "fn main -> i32\n    continue\n    ret 0\nend\n",
        "none",
        "E0502",
    );
    check_fails_with(
        "fn main -> i32\n    if true ->\n        ret 0\n    end\nend\n",
        "none",
        "E4101",
    );
    check_fails_with(
        "use core/io\n\nfn main -> i32\n    io.write 1 \"bad\\n\" 4\n    ret 0\nend\n",
        "none",
        "E2001",
    );
    check_fails_with("fn main -> void\n    ret\nend\n", "none", "E0902");
}

#[test]
fn hello_world_builds_runs_and_emit_is_deterministic() {
    let root = temp_root("hello");
    write_pkg(&root, "syscall");
    write_main(
        &root,
        "use core/io\n\nfn main -> i32\n    io.write 1 \"Hello SnapSurf\\n\" 15\n    ret 0\nend\n",
    );
    run_check(&root).unwrap();
    let asm_a = emit_asm(&root).unwrap();
    let asm_b = emit_asm(&root).unwrap();
    assert_eq!(asm_a, asm_b);
    assert!(asm_a.contains("section .text"));
    assert!(asm_a.contains("syscall"));

    let bin = run_build(&root).unwrap();
    let output = Command::new(bin).output().unwrap();
    assert!(output.status.success());
    assert_eq!(String::from_utf8_lossy(&output.stdout), "Hello SnapSurf\n");
}

#[test]
fn arithmetic_if_loop_and_calls_compile() {
    let root = temp_root("control");
    write_pkg(&root, "none");
    write_main(
        &root,
        "fn add a i32 b i32 -> i32\n    ret a + b\nend\n\nfn main -> i32\n    mut i i32 = 0\n    while i < 3 ->\n        i = i + 1\n    end\n    if i == 3 and true ->\n        ret add i 4\n    else ->\n        ret 1\n    end\nend\n",
    );
    let bin = run_build(&root).unwrap();
    let status = Command::new(bin).status().unwrap();
    assert_eq!(status.code(), Some(7));
}

