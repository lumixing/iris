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
	ConstValue,
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
	Call,
	Ret,
}

Call :: struct {
	name: string,
	args: []Expr,
}

Ret :: struct {
	value: Maybe(Expr),
}
