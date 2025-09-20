package iris

Token :: struct {
	type: TokenType,
	value: TokenValue,
	span: Span,
}

TokenType :: enum {
	Newline,
	KW_extern,
	KW_variadic,
	KW_data,
	KW_func,
	Type,
	Instruction,
	Global,
	Local,
	String,
	Int,
	LParen,
	RParen,
	LBrace,
	RBrace,
	Equals,
	Comma,
}

TokenValue :: union {
	Type,
	Instruction,
	string,
	int,
}

Type :: enum {
	u8,
	i32,
	ptr,
	void,
}

Instruction :: enum {
	copy,
	call,
	point,
	ret,
	load,
	store,
	add,
}

Span :: struct {
	lo, hi: uint,
}
