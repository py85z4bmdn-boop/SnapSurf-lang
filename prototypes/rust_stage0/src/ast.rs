use crate::diagnostic::Span;

#[derive(Debug, Clone)]
pub struct SourceAst {
    pub items: Vec<Item>,
    pub span: Span,
}

#[derive(Debug, Clone)]
pub enum Item {
    Use(UseDecl),
    Fn(FnDecl),
}

#[derive(Debug, Clone)]
pub struct UseDecl {
    pub path: Path,
    pub span: Span,
}

#[derive(Debug, Clone)]
pub struct FnDecl {
    pub name: String,
    pub params: Vec<Param>,
    pub ret: TypeRef,
    pub body: Block,
    pub span: Span,
    pub is_unsafe: bool,
}

#[derive(Debug, Clone)]
pub struct Param {
    pub name: String,
    pub ty: TypeRef,
    pub span: Span,
}

#[derive(Debug, Clone)]
pub struct Block {
    pub statements: Vec<Stmt>,
    pub span: Span,
}

#[derive(Debug, Clone)]
pub enum Stmt {
    Let {
        name: String,
        ty: TypeRef,
        expr: Expr,
        span: Span,
    },
    Mut {
        name: String,
        ty: TypeRef,
        expr: Expr,
        span: Span,
    },
    Assign {
        name: String,
        expr: Expr,
        span: Span,
    },
    Ret {
        expr: Option<Expr>,
        span: Span,
    },
    If {
        cond: Expr,
        then_block: Block,
        else_block: Option<Block>,
        span: Span,
    },
    Loop {
        body: Block,
        span: Span,
    },
    While {
        cond: Expr,
        body: Block,
        span: Span,
    },
    Break {
        span: Span,
    },
    Continue {
        span: Span,
    },
    UnsafeBlock {
        body: Block,
        span: Span,
    },
    Expr {
        expr: Expr,
        span: Span,
    },
    Error {
        span: Span,
    },
}

impl Stmt {
    pub fn span(&self) -> Span {
        match self {
            Stmt::Let { span, .. }
            | Stmt::Mut { span, .. }
            | Stmt::Assign { span, .. }
            | Stmt::Ret { span, .. }
            | Stmt::If { span, .. }
            | Stmt::Loop { span, .. }
            | Stmt::While { span, .. }
            | Stmt::Break { span }
            | Stmt::Continue { span }
            | Stmt::UnsafeBlock { span, .. }
            | Stmt::Expr { span, .. }
            | Stmt::Error { span } => *span,
        }
    }
}

#[derive(Debug, Clone)]
pub enum Expr {
    IntLit {
        raw: String,
        value: u128,
        span: Span,
    },
    StrLit {
        raw: String,
        bytes: Vec<u8>,
        span: Span,
    },
    BoolLit {
        value: bool,
        span: Span,
    },
    Ident {
        name: String,
        span: Span,
    },
    Path {
        path: Path,
        span: Span,
    },
    Binary {
        op: BinaryOp,
        left: Box<Expr>,
        right: Box<Expr>,
        span: Span,
    },
    Unary {
        op: UnaryOp,
        expr: Box<Expr>,
        span: Span,
    },
    Call {
        callee: Path,
        args: Vec<Expr>,
        span: Span,
    },
    Error {
        span: Span,
    },
}

impl Expr {
    pub fn span(&self) -> Span {
        match self {
            Expr::IntLit { span, .. }
            | Expr::StrLit { span, .. }
            | Expr::BoolLit { span, .. }
            | Expr::Ident { span, .. }
            | Expr::Path { span, .. }
            | Expr::Binary { span, .. }
            | Expr::Unary { span, .. }
            | Expr::Call { span, .. }
            | Expr::Error { span } => *span,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BinaryOp {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Eq,
    NotEq,
    Lt,
    LtEq,
    Gt,
    GtEq,
    And,
    Or,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnaryOp {
    Neg,
    Not,
}

#[derive(Debug, Clone)]
pub struct TypeRef {
    pub name: String,
    pub span: Span,
}

#[derive(Debug, Clone)]
pub struct Path {
    pub segments: Vec<String>,
    pub sep: PathSep,
    pub span: Span,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PathSep {
    Dot,
    Slash,
    Single,
}

impl Path {
    pub fn display(&self) -> String {
        let sep = match self.sep {
            PathSep::Dot => ".",
            PathSep::Slash => "/",
            PathSep::Single => "",
        };
        self.segments.join(sep)
    }
}

