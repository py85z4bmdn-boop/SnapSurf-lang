use std::fmt;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
}

impl fmt::Display for Severity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Severity::Error => write!(f, "error"),
            Severity::Warning => write!(f, "warning"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Pos {
    pub byte: usize,
    pub line: usize,
    pub column: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Span {
    pub source_file_id: usize,
    pub start: Pos,
    pub end: Pos,
}

impl Span {
    pub fn join(self, other: Span) -> Span {
        Span {
            source_file_id: self.source_file_id,
            start: self.start,
            end: other.end,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Diagnostic {
    pub code: &'static str,
    pub severity: Severity,
    pub message: String,
    pub file_path: PathBuf,
    pub source_file_id: usize,
    pub span: Span,
    pub note: Option<String>,
    pub help: Option<String>,
}

impl Diagnostic {
    pub fn error(
        code: &'static str,
        message: impl Into<String>,
        file_path: impl AsRef<Path>,
        source_file_id: usize,
        span: Span,
    ) -> Self {
        Self {
            code,
            severity: Severity::Error,
            message: message.into(),
            file_path: file_path.as_ref().to_path_buf(),
            source_file_id,
            span,
            note: None,
            help: None,
        }
    }

    pub fn with_help(mut self, help: impl Into<String>) -> Self {
        self.help = Some(help.into());
        self
    }

    pub fn render(&self) -> String {
        let mut out = format!(
            "{}:{}:{} {}\n{}",
            self.file_path.display(),
            self.span.start.line,
            self.span.start.column,
            self.code,
            self.message
        );
        if let Some(note) = &self.note {
            out.push_str("\nnote: ");
            out.push_str(note);
        }
        if let Some(help) = &self.help {
            out.push_str("\nhelp: ");
            out.push_str(help);
        }
        out
    }
}

pub fn dummy_span() -> Span {
    Span {
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
    }
}

