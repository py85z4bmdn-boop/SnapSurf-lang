use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

use crate::diagnostic::{Diagnostic, Pos, Span};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PackageType {
    Executable,
    Library,
    BuildScript,
}

#[derive(Debug, Clone)]
pub struct Package {
    pub name: String,
    pub version: String,
    pub package_type: PackageType,
    pub target: String,
    pub runtime: String,
    pub entry: Option<String>,
    pub requires: BTreeSet<String>,
    pub deps: Vec<Dependency>,
    pub root: PathBuf,
    pub path: PathBuf,
}

#[derive(Debug, Clone)]
pub struct Dependency {
    pub name: String,
    pub version: String,
}

impl Package {
    pub fn load(root: &Path) -> Result<Self, Vec<Diagnostic>> {
        let path = root.join("surf.pkg");
        let span = Span {
            source_file_id: 0,
            start: Pos {
                byte: 0,
                line: 1,
                column: 1,
            },
            end: Pos {
                byte: 0,
                line: 1,
                column: 1,
            },
        };
        if !path.exists() {
            return Err(vec![Diagnostic::error(
                "E0901",
                "missing surf.pkg",
                &path,
                0,
                span,
            )]);
        }
        let text = fs::read_to_string(&path).map_err(|e| {
            vec![Diagnostic::error(
                "E0902",
                format!("failed to read surf.pkg: {e}"),
                &path,
                0,
                span,
            )]
        })?;
        parse_package_text(root, &path, &text)
    }

    pub fn entry_source(&self) -> PathBuf {
        match self.package_type {
            PackageType::Executable => self.root.join("src/main.snapsurf"),
            PackageType::Library => self.root.join("src/lib.snapsurf"),
            PackageType::BuildScript => self.root.join("build.snapsurf"),
        }
    }
}

fn parse_package_text(root: &Path, path: &Path, text: &str) -> Result<Package, Vec<Diagnostic>> {
    let mut diagnostics = Vec::new();
    let mut package = None;
    let mut version = None;
    let mut package_type = None;
    let mut target = None;
    let mut runtime = None;
    let mut entry = None;
    let mut requires = BTreeSet::new();
    let mut deps = Vec::new();
    let mut saw_end = false;

    for (line_idx, raw_line) in text.lines().enumerate() {
        let line_no = line_idx + 1;
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with("//") {
            continue;
        }
        let parts: Vec<&str> = line.split_whitespace().collect();
        let span = line_span(line_no);
        match parts.as_slice() {
            ["package", name] => package = Some((*name).to_string()),
            ["version", v] if valid_semver(v) => version = Some((*v).to_string()),
            ["version", _] => diagnostics.push(diag(path, "E0902", "version must be MAJOR.MINOR.PATCH", span)),
            ["type", "executable"] => package_type = Some(PackageType::Executable),
            ["type", "library"] => package_type = Some(PackageType::Library),
            ["type", "build-script"] => package_type = Some(PackageType::BuildScript),
            ["type", _] => diagnostics.push(diag(path, "E0902", "unsupported package type", span)),
            ["target", value] => target = Some((*value).to_string()),
            ["runtime", value] => runtime = Some((*value).to_string()),
            ["entry", value] => entry = Some((*value).to_string()),
            ["requires", "none"] => {
                if parts.len() == 2 {
                    requires.clear();
                }
            }
            ["requires", caps @ ..] => {
                for cap in caps {
                    requires.insert((*cap).to_string());
                }
            }
            ["dep", dep_name, dep_version] if valid_semver(dep_version) => deps.push(Dependency {
                name: (*dep_name).to_string(),
                version: (*dep_version).to_string(),
            }),
            ["dep", ..] => diagnostics.push(diag(path, "E0902", "dep requires name and exact semver", span)),
            ["panic", ..] | ["budget", ..] | ["link", ..] => {}
            ["end"] => saw_end = true,
            [bad, ..] => diagnostics.push(diag(path, "E0902", format!("unknown surf.pkg field `{bad}`"), span)),
            [] => {}
        }
    }

    if !saw_end {
        diagnostics.push(diag(path, "E0902", "surf.pkg must end with end", line_span(1)));
    }
    if package.is_none() {
        diagnostics.push(diag(path, "E0902", "missing package field", line_span(1)));
    }
    if version.is_none() {
        diagnostics.push(diag(path, "E0902", "missing version field", line_span(1)));
    }
    if package_type.is_none() {
        diagnostics.push(diag(path, "E0902", "missing type field", line_span(1)));
    }
    if target.is_none() {
        diagnostics.push(diag(path, "E0902", "missing target field", line_span(1)));
    }
    if runtime.is_none() {
        diagnostics.push(diag(path, "E0902", "missing runtime field", line_span(1)));
    }
    if !diagnostics.is_empty() {
        return Err(diagnostics);
    }

    let pkg = Package {
        name: package.unwrap(),
        version: version.unwrap(),
        package_type: package_type.unwrap(),
        target: target.unwrap(),
        runtime: runtime.unwrap(),
        entry,
        requires,
        deps,
        root: root.to_path_buf(),
        path: path.to_path_buf(),
    };

    if pkg.target != "linux-x86_64" && pkg.target != "host" {
        return Err(vec![diag(
            path,
            "E0904",
            "foundation supports only linux-x86_64 or host target",
            line_span(1),
        )]);
    }
    if pkg.runtime != "tiny" && pkg.runtime != "none" {
        return Err(vec![diag(
            path,
            "E0904",
            "foundation supports only tiny or none runtime",
            line_span(1),
        )]);
    }
    let src_dir = root.join("src");
    if !src_dir.is_dir() && pkg.package_type != PackageType::BuildScript {
        return Err(vec![diag(path, "E0903", "missing src/ directory", line_span(1))]);
    }
    let entry_source = pkg.entry_source();
    if !entry_source.exists() {
        return Err(vec![diag(
            path,
            "E0903",
            format!("missing package source entry {}", entry_source.display()),
            line_span(1),
        )]);
    }
    Ok(pkg)
}

fn valid_semver(s: &str) -> bool {
    let mut parts = s.split('.');
    let Some(a) = parts.next() else { return false };
    let Some(b) = parts.next() else { return false };
    let Some(c) = parts.next() else { return false };
    if parts.next().is_some() {
        return false;
    }
    [a, b, c]
        .iter()
        .all(|p| !p.is_empty() && p.bytes().all(|b| b.is_ascii_digit()))
}

fn line_span(line: usize) -> Span {
    Span {
        source_file_id: 0,
        start: Pos {
            byte: 0,
            line,
            column: 1,
        },
        end: Pos {
            byte: 0,
            line,
            column: 1,
        },
    }
}

fn diag(path: &Path, code: &'static str, message: impl Into<String>, span: Span) -> Diagnostic {
    Diagnostic::error(code, message, path, 0, span)
}

