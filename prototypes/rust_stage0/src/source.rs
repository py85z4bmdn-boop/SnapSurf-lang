use std::fs;
use std::path::{Path, PathBuf};

use crate::diagnostic::{Diagnostic, Pos, Span};

#[derive(Debug, Clone)]
pub struct SourceFile {
    pub id: usize,
    pub path: PathBuf,
    pub bytes: Vec<u8>,
    pub text: String,
}

impl SourceFile {
    pub fn load_snapsurf(path: &Path, id: usize) -> Result<Self, Vec<Diagnostic>> {
        let display_span = Span {
            source_file_id: id,
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
        if path.extension().and_then(|s| s.to_str()) != Some("snapsurf") {
            return Err(vec![Diagnostic::error(
                "E0003",
                "SnapSurf source file must use .snapsurf extension",
                path,
                id,
                display_span,
            )]);
        }
        if path.to_str().is_none() {
            return Err(vec![Diagnostic::error(
                "E0004",
                "source path is not valid UTF-8",
                path,
                id,
                display_span,
            )]);
        }
        let bytes = fs::read(path).map_err(|e| {
            vec![Diagnostic::error(
                "E9000",
                format!("failed to read source file: {e}"),
                path,
                id,
                display_span,
            )]
        })?;
        if bytes.starts_with(&[0xEF, 0xBB, 0xBF]) {
            return Err(vec![Diagnostic::error(
                "E0001",
                "UTF-8 BOM is not allowed",
                path,
                id,
                display_span,
            )]);
        }
        let text = String::from_utf8(bytes.clone()).map_err(|e| {
            let start = e.utf8_error().valid_up_to();
            vec![Diagnostic::error(
                "E0002",
                "invalid UTF-8 sequence",
                path,
                id,
                Span {
                    source_file_id: id,
                    start: Pos {
                        byte: start,
                        line: 1,
                        column: start + 1,
                    },
                    end: Pos {
                        byte: start.saturating_add(1),
                        line: 1,
                        column: start + 2,
                    },
                },
            )]
        })?;
        Ok(Self {
            id,
            path: path.to_path_buf(),
            bytes,
            text,
        })
    }
}

