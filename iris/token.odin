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

@(rodata)
type_size: [Type]uint = {
	.void = 0,
	.u8   = 1,
	.i32  = 4,
	.ptr  = 8,
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
