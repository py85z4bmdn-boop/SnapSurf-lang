use std::path::{Path as FsPath, PathBuf};

use crate::ast::*;
use crate::diagnostic::{Diagnostic, Span};
use crate::token::{Token, TokenKind};

pub struct Parser<'a> {
    tokens: &'a [Token],
    index: usize,
    diagnostics: Vec<Diagnostic>,
    file_path: PathBuf,
    source_file_id: usize,
}

impl<'a> Parser<'a> {
    pub fn new(tokens: &'a [Token], file_path: &FsPath, source_file_id: usize) -> Self {
        Self {
            tokens,
            index: 0,
            diagnostics: Vec::new(),
            file_path: file_path.to_path_buf(),
            source_file_id,
        }
    }

    pub fn parse(mut self) -> (SourceAst, Vec<Diagnostic>) {
        self.skip_newlines_and_comments();
        let start = self.current().span;
        let mut items = Vec::new();
        while !self.at(TokenKind::Eof) {
            match self.current().kind {
                TokenKind::Use => {
                    if let Some(item) = self.parse_use() {
                        items.push(Item::Use(item));
                    }
                }
                TokenKind::Unsafe | TokenKind::Fn => {
                    if let Some(item) = self.parse_fn_item() {
                        items.push(Item::Fn(item));
                    }
                }
                TokenKind::End => {
                    let span = self.bump().span;
                    self.error("E0204", "unexpected end", span);
                }
                TokenKind::Else => {
                    let span = self.bump().span;
                    self.error("E0205", "else without matching if", span);
                }
                _ => {
                    let span = self.bump().span;
                    self.error("E0206", "expected item", span);
                }
            }
            self.skip_newlines_and_comments();
        }
        let end = self.current().span;
        (
            SourceAst {
                items,
                span: start.join(end),
            },
            self.diagnostics,
        )
    }

    fn parse_use(&mut self) -> Option<UseDecl> {
        let start = self.expect(TokenKind::Use)?.span;
        let path = self.parse_path()?;
        let span = start.join(path.span);
        self.consume_statement_end();
        Some(UseDecl { path, span })
    }

    fn parse_fn_item(&mut self) -> Option<FnDecl> {
        let mut is_unsafe = false;
        let start = if self.at(TokenKind::Unsafe) && self.peek_kind(1) == TokenKind::Fn {
            is_unsafe = true;
            self.bump().span
        } else {
            self.current().span
        };
        self.expect(TokenKind::Fn)?;
        let name_tok = match self.expect(TokenKind::Ident) {
            Some(tok) => tok,
            None => {
                self.error("E0201", "missing function name", self.current().span);
                self.synchronize_item();
                return None;
            }
        };
        let mut params = Vec::new();
        while !self.at(TokenKind::Arrow) && !self.at(TokenKind::Eof) && !self.at(TokenKind::Newline) {
            let param_name = match self.expect(TokenKind::Ident) {
                Some(tok) => tok,
                None => {
                    self.error("E0206", "invalid parameter list", self.current().span);
                    self.synchronize_statement();
                    break;
                }
            };
            let ty = match self.parse_type_ref() {
                Some(ty) => ty,
                None => {
                    self.error("E0206", "invalid parameter type", self.current().span);
                    self.synchronize_statement();
                    break;
                }
            };
            let span = param_name.span.join(ty.span);
            params.push(Param {
                name: param_name.lexeme,
                ty,
                span,
            });
        }
        if self.expect(TokenKind::Arrow).is_none() {
            self.error("E0202", "missing return type", self.current().span);
            self.synchronize_item();
            return None;
        }
        let ret = match self.parse_type_ref() {
            Some(ty) => ty,
            None => {
                self.error("E0202", "missing return type", self.current().span);
                self.synchronize_item();
                return None;
            }
        };
        self.consume_statement_end();
        let body_start = self.current().span;
        let body = self.parse_block();
        if self.expect(TokenKind::End).is_none() {
            self.error("E0203", "expected end", body_start);
        }
        let end = self.previous_span();
        self.consume_statement_end();
        Some(FnDecl {
            name: name_tok.lexeme,
            params,
            ret,
            body,
            span: start.join(end),
            is_unsafe,
        })
    }

    fn parse_block(&mut self) -> Block {
        self.skip_newlines_and_comments();
        let start = self.current().span;
        let mut statements = Vec::new();
        while !self.at(TokenKind::Eof) && !self.at(TokenKind::End) && !self.at(TokenKind::Else) {
            let before = self.index;
            if let Some(stmt) = self.parse_statement() {
                statements.push(stmt);
            }
            if self.index == before {
                let span = self.bump().span;
                self.error("E0207", "parser made no progress", span);
            }
            self.skip_newlines_and_comments();
        }
        let end = statements.last().map(Stmt::span).unwrap_or(start);
        Block {
            statements,
            span: start.join(end),
        }
    }

    fn parse_statement(&mut self) -> Option<Stmt> {
        self.skip_newlines_and_comments();
        match self.current().kind {
            TokenKind::Let => self.parse_var(false),
            TokenKind::Mut => self.parse_var(true),
            TokenKind::Ret => Some(self.parse_ret()),
            TokenKind::If => Some(self.parse_if()),
            TokenKind::Loop => Some(self.parse_loop()),
            TokenKind::While => Some(self.parse_while()),
            TokenKind::Break => {
                let span = self.bump().span;
                self.consume_statement_end();
                Some(Stmt::Break { span })
            }
            TokenKind::Continue => {
                let span = self.bump().span;
                self.consume_statement_end();
                Some(Stmt::Continue { span })
            }
            TokenKind::Unsafe if self.peek_kind(1) == TokenKind::Arrow => Some(self.parse_unsafe_block()),
            TokenKind::Else => {
                let span = self.bump().span;
                self.error("E0205", "else without matching if", span);
                Some(Stmt::Error { span })
            }
            TokenKind::Ident if self.peek_kind(1) == TokenKind::Eq => Some(self.parse_assign()),
            TokenKind::Eof | TokenKind::End => None,
            _ => Some(self.parse_expr_stmt()),
        }
    }

    fn parse_var(&mut self, mutable: bool) -> Option<Stmt> {
        let start = self.bump().span;
        let name = self.expect(TokenKind::Ident)?;
        let ty = self.parse_type_ref()?;
        self.expect(TokenKind::Eq)?;
        let expr = self.parse_expr(0);
        let span = start.join(expr.span());
        self.consume_statement_end();
        if mutable {
            Some(Stmt::Mut {
                name: name.lexeme,
                ty,
                expr,
                span,
            })
        } else {
            Some(Stmt::Let {
                name: name.lexeme,
                ty,
                expr,
                span,
            })
        }
    }

    fn parse_assign(&mut self) -> Stmt {
        let name = self.bump();
        self.expect(TokenKind::Eq);
        let expr = self.parse_expr(0);
        let span = name.span.join(expr.span());
        self.consume_statement_end();
        Stmt::Assign {
            name: name.lexeme,
            expr,
            span,
        }
    }

    fn parse_ret(&mut self) -> Stmt {
        let start = self.bump().span;
        let expr = if self.is_statement_boundary() {
            None
        } else {
            Some(self.parse_expr(0))
        };
        let span = expr.as_ref().map(|e| start.join(e.span())).unwrap_or(start);
        self.consume_statement_end();
        Stmt::Ret { expr, span }
    }

    fn parse_if(&mut self) -> Stmt {
        let start = self.bump().span;
        let cond = self.parse_expr(0);
        self.expect(TokenKind::Arrow);
        self.consume_statement_end();
        let then_block = self.parse_block();
        let else_block = if self.at(TokenKind::Else) {
            self.bump();
            self.expect(TokenKind::Arrow);
            self.consume_statement_end();
            Some(self.parse_block())
        } else {
            None
        };
        if self.expect(TokenKind::End).is_none() {
            self.error("E0203", "expected end", then_block.span);
        }
        let span = start.join(self.previous_span());
        self.consume_statement_end();
        Stmt::If {
            cond,
            then_block,
            else_block,
            span,
        }
    }

    fn parse_loop(&mut self) -> Stmt {
        let start = self.bump().span;
        self.expect(TokenKind::Arrow);
        self.consume_statement_end();
        let body = self.parse_block();
        if self.expect(TokenKind::End).is_none() {
            self.error("E0203", "expected end", body.span);
        }
        let span = start.join(self.previous_span());
        self.consume_statement_end();
        Stmt::Loop { body, span }
    }

    fn parse_while(&mut self) -> Stmt {
        let start = self.bump().span;
        let cond = self.parse_expr(0);
        self.expect(TokenKind::Arrow);
        self.consume_statement_end();
        let body = self.parse_block();
        if self.expect(TokenKind::End).is_none() {
            self.error("E0203", "expected end", body.span);
        }
        let span = start.join(self.previous_span());
        self.consume_statement_end();
        Stmt::While { cond, body, span }
    }

    fn parse_unsafe_block(&mut self) -> Stmt {
        let start = self.bump().span;
        self.expect(TokenKind::Arrow);
        self.consume_statement_end();
        let body = self.parse_block();
        if self.expect(TokenKind::End).is_none() {
            self.error("E0203", "expected end", body.span);
        }
        let span = start.join(self.previous_span());
        self.consume_statement_end();
        Stmt::UnsafeBlock { body, span }
    }

    fn parse_expr_stmt(&mut self) -> Stmt {
        let expr = self.parse_expr(0);
        let span = expr.span();
        self.consume_statement_end();
        Stmt::Expr { expr, span }
    }

    fn parse_expr(&mut self, min_bp: u8) -> Expr {
        let mut lhs = self.parse_prefix();
        lhs = self.finish_call(lhs);
        while let Some((op, left_bp, right_bp)) = self.current_binop() {
            if left_bp < min_bp {
                break;
            }
            self.bump();
            let rhs = self.parse_expr(right_bp);
            let span = lhs.span().join(rhs.span());
            lhs = Expr::Binary {
                op,
                left: Box::new(lhs),
                right: Box::new(rhs),
                span,
            };
        }
        lhs
    }

    fn parse_prefix(&mut self) -> Expr {
        match self.current().kind {
            TokenKind::Not => {
                let start = self.bump().span;
                let expr = self.parse_expr(8);
                let span = start.join(expr.span());
                Expr::Unary {
                    op: UnaryOp::Not,
                    expr: Box::new(expr),
                    span,
                }
            }
            TokenKind::Minus => {
                let start = self.bump().span;
                let expr = self.parse_expr(8);
                let span = start.join(expr.span());
                Expr::Unary {
                    op: UnaryOp::Neg,
                    expr: Box::new(expr),
                    span,
                }
            }
            _ => self.parse_primary(),
        }
    }

    fn finish_call(&mut self, lhs: Expr) -> Expr {
        let callee = match &lhs {
            Expr::Ident { name, span } => Some(Path {
                segments: vec![name.clone()],
                sep: PathSep::Single,
                span: *span,
            }),
            Expr::Path { path, .. } => Some(path.clone()),
            _ => None,
        };
        let Some(callee) = callee else {
            return lhs;
        };
        if !self.starts_arg() {
            return lhs;
        }
        let mut args = Vec::new();
        let mut end = lhs.span();
        while self.starts_arg() {
            let arg = self.parse_prefix();
            end = arg.span();
            args.push(arg);
        }
        Expr::Call {
            callee,
            args,
            span: lhs.span().join(end),
        }
    }

    fn parse_primary(&mut self) -> Expr {
        match self.current().kind {
            TokenKind::IntLit => {
                let tok = self.bump();
                let value = parse_int_value(&tok.lexeme).unwrap_or(0);
                Expr::IntLit {
                    raw: tok.lexeme,
                    value,
                    span: tok.span,
                }
            }
            TokenKind::StrLit => {
                let tok = self.bump();
                let bytes = decode_string(&tok.lexeme);
                Expr::StrLit {
                    raw: tok.lexeme,
                    bytes,
                    span: tok.span,
                }
            }
            TokenKind::True | TokenKind::False => {
                let tok = self.bump();
                Expr::BoolLit {
                    value: tok.kind == TokenKind::True,
                    span: tok.span,
                }
            }
            TokenKind::Ident => {
                let path = self.parse_path().unwrap();
                if path.segments.len() == 1 {
                    Expr::Ident {
                        name: path.segments[0].clone(),
                        span: path.span,
                    }
                } else {
                    Expr::Path {
                        span: path.span,
                        path,
                    }
                }
            }
            TokenKind::LParen => {
                self.bump();
                let expr = self.parse_expr(0);
                self.expect(TokenKind::RParen);
                expr
            }
            _ => {
                let span = self.bump().span;
                self.error("E0206", "invalid expression", span);
                Expr::Error { span }
            }
        }
    }

    fn parse_path(&mut self) -> Option<Path> {
        let first = self.expect(TokenKind::Ident)?;
        let mut segments = vec![first.lexeme];
        let mut sep = PathSep::Single;
        let mut end = first.span;
        loop {
            let next_sep = if self.at(TokenKind::Dot) {
                Some(PathSep::Dot)
            } else if self.at(TokenKind::Slash) {
                Some(PathSep::Slash)
            } else {
                None
            };
            let Some(next_sep) = next_sep else { break };
            if sep != PathSep::Single && sep != next_sep {
                self.error("E0206", "mixed path separators are forbidden", self.current().span);
                break;
            }
            sep = next_sep;
            self.bump();
            let seg = match self.expect(TokenKind::Ident) {
                Some(tok) => tok,
                None => break,
            };
            end = seg.span;
            segments.push(seg.lexeme);
        }
        Some(Path {
            segments,
            sep,
            span: first.span.join(end),
        })
    }

    fn parse_type_ref(&mut self) -> Option<TypeRef> {
        let start = self.current().span;
        if self.at(TokenKind::Star) {
            self.bump();
            let name = self.expect(TokenKind::Ident)?;
            return Some(TypeRef {
                name: format!("*{}", name.lexeme),
                span: start.join(name.span),
            });
        }
        let tok = self.expect(TokenKind::Ident)?;
        Some(TypeRef {
            name: tok.lexeme,
            span: tok.span,
        })
    }

    fn current_binop(&self) -> Option<(BinaryOp, u8, u8)> {
        let op = match self.current().kind {
            TokenKind::Star => (BinaryOp::Mul, 7, 8),
            TokenKind::Slash => (BinaryOp::Div, 7, 8),
            TokenKind::Percent => (BinaryOp::Mod, 7, 8),
            TokenKind::Plus => (BinaryOp::Add, 6, 7),
            TokenKind::Minus => (BinaryOp::Sub, 6, 7),
            TokenKind::Lt => (BinaryOp::Lt, 5, 6),
            TokenKind::LtEq => (BinaryOp::LtEq, 5, 6),
            TokenKind::Gt => (BinaryOp::Gt, 5, 6),
            TokenKind::GtEq => (BinaryOp::GtEq, 5, 6),
            TokenKind::EqEq => (BinaryOp::Eq, 4, 5),
            TokenKind::BangEq => (BinaryOp::NotEq, 4, 5),
            TokenKind::And => (BinaryOp::And, 3, 4),
            TokenKind::Or => (BinaryOp::Or, 2, 3),
            _ => return None,
        };
        Some(op)
    }

    fn starts_arg(&self) -> bool {
        matches!(
            self.current().kind,
            TokenKind::IntLit
                | TokenKind::StrLit
                | TokenKind::True
                | TokenKind::False
                | TokenKind::Ident
                | TokenKind::LParen
                | TokenKind::Not
                | TokenKind::Minus
        )
    }

    fn current(&self) -> &Token {
        &self.tokens[self.index]
    }

    fn previous_span(&self) -> Span {
        if self.index == 0 {
            self.current().span
        } else {
            self.tokens[self.index - 1].span
        }
    }

    fn bump(&mut self) -> Token {
        let tok = self.tokens[self.index].clone();
        if self.index + 1 < self.tokens.len() {
            self.index += 1;
        }
        tok
    }

    fn at(&self, kind: TokenKind) -> bool {
        self.current().kind == kind
    }

    fn peek_kind(&self, offset: usize) -> TokenKind {
        self.tokens
            .get(self.index + offset)
            .map(|t| t.kind)
            .unwrap_or(TokenKind::Eof)
    }

    fn expect(&mut self, kind: TokenKind) -> Option<Token> {
        if self.at(kind) {
            Some(self.bump())
        } else {
            let span = self.current().span;
            self.error("E0206", format!("expected {:?}", kind), span);
            None
        }
    }

    fn is_statement_boundary(&self) -> bool {
        matches!(
            self.current().kind,
            TokenKind::Newline | TokenKind::End | TokenKind::Else | TokenKind::Eof
        )
    }

    fn consume_statement_end(&mut self) {
        while self.at(TokenKind::Comment) || self.at(TokenKind::Newline) {
            self.bump();
        }
    }

    fn skip_newlines_and_comments(&mut self) {
        self.consume_statement_end();
    }

    fn synchronize_statement(&mut self) {
        while !matches!(
            self.current().kind,
            TokenKind::Newline
                | TokenKind::End
                | TokenKind::Else
                | TokenKind::Fn
                | TokenKind::Let
                | TokenKind::Mut
                | TokenKind::If
                | TokenKind::Loop
                | TokenKind::While
                | TokenKind::Ret
                | TokenKind::Eof
        ) {
            self.bump();
        }
    }

    fn synchronize_item(&mut self) {
        while !matches!(self.current().kind, TokenKind::Fn | TokenKind::Use | TokenKind::Eof) {
            self.bump();
        }
    }

    fn error(&mut self, code: &'static str, message: impl Into<String>, span: Span) {
        if self.diagnostics.len() < 100 {
            self.diagnostics.push(Diagnostic::error(
                code,
                message,
                &self.file_path,
                self.source_file_id,
                span,
            ));
        } else if self.diagnostics.len() == 100 {
            self.diagnostics.push(Diagnostic::error(
                "E9999",
                "too many errors, stopping",
                &self.file_path,
                self.source_file_id,
                span,
            ));
        }
    }
}

fn parse_int_value(raw: &str) -> Option<u128> {
    let (base, body) = if raw.starts_with("0x") || raw.starts_with("0X") {
        (16, &raw[2..])
    } else if raw.starts_with("0b") || raw.starts_with("0B") {
        (2, &raw[2..])
    } else if raw.starts_with("0o") || raw.starts_with("0O") {
        (8, &raw[2..])
    } else {
        (10, raw)
    };
    u128::from_str_radix(&body.replace('_', ""), base).ok()
}

fn decode_string(raw: &str) -> Vec<u8> {
    let inner = raw.strip_prefix('"').and_then(|s| s.strip_suffix('"')).unwrap_or(raw);
    let mut out = Vec::new();
    let bytes = inner.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] != b'\\' {
            out.push(bytes[i]);
            i += 1;
            continue;
        }
        i += 1;
        if i >= bytes.len() {
            break;
        }
        match bytes[i] {
            b'n' => out.push(b'\n'),
            b't' => out.push(b'\t'),
            b'r' => out.push(b'\r'),
            b'\\' => out.push(b'\\'),
            b'"' => out.push(b'"'),
            b'\'' => out.push(b'\''),
            b'0' => out.push(0),
            b'x' if i + 2 < bytes.len() => {
                let hex = &inner[i + 1..i + 3];
                if let Ok(v) = u8::from_str_radix(hex, 16) {
                    out.push(v);
                }
                i += 2;
            }
            other => out.push(other),
        }
        i += 1;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;
    use crate::source::SourceFile;

    fn parse(text: &str) -> (SourceAst, Vec<Diagnostic>) {
        let source = SourceFile {
            id: 0,
            path: PathBuf::from("test.snapsurf"),
            bytes: text.as_bytes().to_vec(),
            text: text.to_string(),
        };
        let (tokens, lex_diags) = Lexer::new(&source).lex();
        assert!(lex_diags.is_empty(), "{lex_diags:?}");
        Parser::new(&tokens, &source.path, source.id).parse()
    }

    #[test]
    fn parses_main_and_precedence() {
        let (ast, diags) = parse("fn main -> i32\n    let x i32 = 1 + 2 * 3\n    ret x\nend\n");
        assert!(diags.is_empty(), "{diags:?}");
        assert_eq!(ast.items.len(), 1);
    }

    #[test]
    fn reports_else_without_if() {
        let (_, diags) = parse("else ->\nend\n");
        assert!(diags.iter().any(|d| d.code == "E0205"));
    }
}
