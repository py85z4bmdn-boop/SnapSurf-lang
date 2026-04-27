use crate::diagnostic::{Diagnostic, Pos, Span};
use crate::source::SourceFile;
use crate::token::{keyword_kind, Token, TokenKind};

pub struct Lexer<'a> {
    source: &'a SourceFile,
    bytes: &'a [u8],
    index: usize,
    line: usize,
    column: usize,
    tokens: Vec<Token>,
    diagnostics: Vec<Diagnostic>,
}

impl<'a> Lexer<'a> {
    pub fn new(source: &'a SourceFile) -> Self {
        Self {
            source,
            bytes: source.bytes.as_slice(),
            index: 0,
            line: 1,
            column: 1,
            tokens: Vec::new(),
            diagnostics: Vec::new(),
        }
    }

    pub fn lex(mut self) -> (Vec<Token>, Vec<Diagnostic>) {
        while !self.is_eof() {
            match self.peek() {
                b' ' | b'\t' => {
                    self.advance();
                }
                b'\r' => self.lex_newline(),
                b'\n' => self.lex_newline(),
                b'A'..=b'Z' | b'a'..=b'z' | b'_' => self.lex_ident(),
                b'0'..=b'9' => self.lex_int(),
                b'"' => self.lex_string(),
                b'\'' => self.lex_byte_lit(),
                b'/' if self.peek_next() == Some(b'/') => self.lex_line_comment(),
                b'/' if self.peek_next() == Some(b'*') => self.lex_block_comment(),
                b'/' => self.single(TokenKind::Slash),
                b'+' => self.single(TokenKind::Plus),
                b'-' if self.peek_next() == Some(b'>') => self.double(TokenKind::Arrow),
                b'-' => self.single(TokenKind::Minus),
                b'*' => self.single(TokenKind::Star),
                b'%' => self.single(TokenKind::Percent),
                b'=' if self.peek_next() == Some(b'=') => self.double(TokenKind::EqEq),
                b'=' => self.single(TokenKind::Eq),
                b'!' if self.peek_next() == Some(b'=') => self.double(TokenKind::BangEq),
                b'<' if self.peek_next() == Some(b'=') => self.double(TokenKind::LtEq),
                b'<' => self.single(TokenKind::Lt),
                b'>' if self.peek_next() == Some(b'=') => self.double(TokenKind::GtEq),
                b'>' => self.single(TokenKind::Gt),
                b'(' => self.single(TokenKind::LParen),
                b')' => self.single(TokenKind::RParen),
                b'[' => self.single(TokenKind::LBracket),
                b']' => self.single(TokenKind::RBracket),
                b',' => self.single(TokenKind::Comma),
                b'.' => self.single(TokenKind::Dot),
                b':' => self.single(TokenKind::Colon),
                0 => self.invalid_char("NUL byte is not allowed outside a literal"),
                _ => self.invalid_char("invalid character"),
            }
        }
        let span = self.empty_span();
        self.tokens.push(Token::new(TokenKind::Eof, String::new(), span));
        (self.tokens, self.diagnostics)
    }

    fn lex_newline(&mut self) {
        let start = self.pos();
        if self.peek() == b'\r' && self.peek_next() == Some(b'\n') {
            self.index += 2;
            self.line += 1;
            self.column = 1;
        } else {
            self.advance();
        }
        self.tokens.push(Token::new(
            TokenKind::Newline,
            "\n".to_string(),
            self.span_from(start),
        ));
    }

    fn lex_ident(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        while !self.is_eof() && is_ident_rest(self.peek()) {
            self.advance();
        }
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        let kind = keyword_kind(&text).unwrap_or(TokenKind::Ident);
        self.tokens.push(Token::new(kind, text, self.span_from(start)));
    }

    fn lex_int(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        let (base, prefix_len) = if self.peek() == b'0' {
            match self.peek_next() {
                Some(b'x') | Some(b'X') => (16, 2),
                Some(b'b') | Some(b'B') => (2, 2),
                Some(b'o') | Some(b'O') => (8, 2),
                _ => (10, 0),
            }
        } else {
            (10, 0)
        };
        for _ in 0..prefix_len {
            self.advance();
        }
        let digits_start = self.index;
        let mut prev_was_digit = false;
        let mut prev_was_underscore = false;
        let mut saw_digit = false;
        while !self.is_eof() {
            let b = self.peek();
            if digit_value(b).is_some_and(|v| v < base) {
                saw_digit = true;
                prev_was_digit = true;
                prev_was_underscore = false;
                self.advance();
            } else if b == b'_' {
                if !prev_was_digit {
                    self.emit_int_error(start, "invalid integer separator");
                }
                prev_was_digit = false;
                prev_was_underscore = true;
                self.advance();
            } else if b.is_ascii_alphanumeric() {
                self.emit_int_error(start, "invalid digit for integer base");
                self.advance();
            } else {
                break;
            }
        }
        if !saw_digit || prev_was_underscore || digits_start == self.index {
            self.emit_int_error(start, "invalid integer literal");
        }
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens
            .push(Token::new(TokenKind::IntLit, text, self.span_from(start)));
    }

    fn lex_string(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        while !self.is_eof() {
            match self.peek() {
                b'"' => {
                    self.advance();
                    let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
                    self.tokens
                        .push(Token::new(TokenKind::StrLit, text, self.span_from(start)));
                    return;
                }
                b'\\' => {
                    self.advance();
                    if self.is_eof() {
                        break;
                    }
                    let esc = self.peek();
                    if esc == b'x' {
                        self.advance();
                        if self.index + 1 >= self.bytes.len() {
                            self.diagnostics.push(Diagnostic::error(
                                "E1001",
                                "invalid escape sequence",
                                &self.source.path,
                                self.source.id,
                                self.span_from(start),
                            ));
                            break;
                        }
                        let a = self.peek();
                        self.advance();
                        let b = self.peek();
                        self.advance();
                        if !is_hex(a) || !is_hex(b) {
                            self.diagnostics.push(Diagnostic::error(
                                "E1001",
                                "invalid escape sequence",
                                &self.source.path,
                                self.source.id,
                                self.span_from(start),
                            ));
                        }
                    } else if matches!(esc, b'n' | b't' | b'r' | b'\\' | b'"' | b'\'' | b'0') {
                        self.advance();
                    } else {
                        self.diagnostics.push(Diagnostic::error(
                            "E1001",
                            "invalid escape sequence",
                            &self.source.path,
                            self.source.id,
                            self.span_from(start),
                        ));
                        self.advance();
                    }
                }
                b'\n' | b'\r' => break,
                _ => {
                    self.advance();
                }
            }
        }
        self.diagnostics.push(Diagnostic::error(
            "E1002",
            "unterminated string literal",
            &self.source.path,
            self.source.id,
            self.span_from(start),
        ));
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens
            .push(Token::new(TokenKind::Error, text, self.span_from(start)));
    }

    fn lex_byte_lit(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        while !self.is_eof() && self.peek() != b'\'' && self.peek() != b'\n' && self.peek() != b'\r' {
            self.advance();
        }
        if !self.is_eof() && self.peek() == b'\'' {
            self.advance();
            let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
            self.tokens
                .push(Token::new(TokenKind::ByteLit, text, self.span_from(start)));
        } else {
            self.diagnostics.push(Diagnostic::error(
                "E1002",
                "unterminated byte literal",
                &self.source.path,
                self.source.id,
                self.span_from(start),
            ));
            let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
            self.tokens
                .push(Token::new(TokenKind::Error, text, self.span_from(start)));
        }
    }

    fn lex_line_comment(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        self.advance();
        while !self.is_eof() && self.peek() != b'\n' && self.peek() != b'\r' {
            self.advance();
        }
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens
            .push(Token::new(TokenKind::Comment, text, self.span_from(start)));
    }

    fn lex_block_comment(&mut self) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        self.advance();
        while !self.is_eof() {
            if self.peek() == b'*' && self.peek_next() == Some(b'/') {
                self.advance();
                self.advance();
                let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
                self.tokens
                    .push(Token::new(TokenKind::Comment, text, self.span_from(start)));
                return;
            }
            self.advance();
        }
        self.diagnostics.push(Diagnostic::error(
            "E0101",
            "unterminated block comment",
            &self.source.path,
            self.source.id,
            self.span_from(start),
        ));
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens
            .push(Token::new(TokenKind::Error, text, self.span_from(start)));
    }

    fn single(&mut self, kind: TokenKind) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens.push(Token::new(kind, text, self.span_from(start)));
    }

    fn double(&mut self, kind: TokenKind) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        self.advance();
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        self.tokens.push(Token::new(kind, text, self.span_from(start)));
    }

    fn invalid_char(&mut self, message: &'static str) {
        let start = self.pos();
        let start_index = self.index;
        self.advance();
        let text = String::from_utf8_lossy(&self.bytes[start_index..self.index]).to_string();
        let span = self.span_from(start);
        self.diagnostics.push(Diagnostic::error(
            "E0102",
            message,
            &self.source.path,
            self.source.id,
            span,
        ));
        self.tokens.push(Token::new(TokenKind::Error, text, span));
    }

    fn emit_int_error(&mut self, start: Pos, msg: &'static str) {
        self.diagnostics.push(Diagnostic::error(
            "E1003",
            msg,
            &self.source.path,
            self.source.id,
            self.span_from(start),
        ));
    }

    fn advance(&mut self) -> u8 {
        let b = self.bytes[self.index];
        self.index += 1;
        if b == b'\n' {
            self.line += 1;
            self.column = 1;
        } else if b == b'\r' {
            if self.index < self.bytes.len() && self.bytes[self.index] == b'\n' {
                self.index += 1;
            }
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        b
    }

    fn peek(&self) -> u8 {
        self.bytes[self.index]
    }

    fn peek_next(&self) -> Option<u8> {
        self.bytes.get(self.index + 1).copied()
    }

    fn is_eof(&self) -> bool {
        self.index >= self.bytes.len()
    }

    fn pos(&self) -> Pos {
        Pos {
            byte: self.index,
            line: self.line,
            column: self.column,
        }
    }

    fn empty_span(&self) -> Span {
        Span {
            source_file_id: self.source.id,
            start: self.pos(),
            end: self.pos(),
        }
    }

    fn span_from(&self, start: Pos) -> Span {
        Span {
            source_file_id: self.source.id,
            start,
            end: self.pos(),
        }
    }
}

fn is_ident_rest(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

fn digit_value(b: u8) -> Option<u32> {
    match b {
        b'0'..=b'9' => Some((b - b'0') as u32),
        b'a'..=b'f' => Some((b - b'a' + 10) as u32),
        b'A'..=b'F' => Some((b - b'A' + 10) as u32),
        _ => None,
    }
}

fn is_hex(b: u8) -> bool {
    digit_value(b).is_some_and(|v| v < 16)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn lex(text: &str) -> (Vec<Token>, Vec<Diagnostic>) {
        let source = SourceFile {
            id: 0,
            path: PathBuf::from("test.snapsurf"),
            bytes: text.as_bytes().to_vec(),
            text: text.to_string(),
        };
        Lexer::new(&source).lex()
    }

    #[test]
    fn lexes_keywords_and_eof() {
        let (tokens, diags) = lex("fn main -> i32\nend");
        assert!(diags.is_empty());
        assert_eq!(tokens[0].kind, TokenKind::Fn);
        assert_eq!(tokens[2].kind, TokenKind::Arrow);
        assert_eq!(tokens.last().unwrap().kind, TokenKind::Eof);
    }

    #[test]
    fn rejects_bad_separator() {
        let (_, diags) = lex("let x i32 = 1__0");
        assert!(diags.iter().any(|d| d.code == "E1003"));
    }

    #[test]
    fn reports_invalid_escape_and_unterminated_block() {
        let (_, diags) = lex("\"\\q\" /* bad");
        assert!(diags.iter().any(|d| d.code == "E1001"));
        assert!(diags.iter().any(|d| d.code == "E0101"));
    }
}
