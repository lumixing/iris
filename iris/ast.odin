package iris

TopStmt :: union #no_nil {
	Extern,
	Data,
	Func,
}

Extern :: struct {
	name: string,
	variadic: bool,
}

Data :: struct {
	name: string,
	args: []ConstExpr,
}

ConstExpr :: struct {
	type: Type,
	value: ConstValue,
}

ConstValue :: union #no_nil {
	string,
	int,
}

Expr :: struct {
	type: Type,
	value: Value,
}

Value :: union #no_nil {
	Global,
	Local,
	ConstValue, // change this to int bc string doesnt make sense?
}

Global :: distinct string
Local :: distinct string

Func :: struct {
	ret_type: Type,
	name: string,
	params: []Param,
	body: []Stmt,
}

Param :: struct {
	type: Type,
	name: string,
}

Stmt :: union #no_nil {
	Instr,
	LocalDef,
}

Instr :: union #no_nil {
	Call,
	Ret,
	Copy,
}

Call :: struct {
	name: string,
	args: []Expr,
}

Ret :: struct {
	value: Maybe(Expr),
}

Copy :: struct {
	value: Expr,
}

LocalDef :: struct {
	type: Type,
	name: string,
	value: Instr,
}
