package iris

import "core:fmt"

Parser :: struct {
	tokens: []Token,
	top_stmts: [dynamic]TopStmt,
	span: Span,
}

prs_parse :: proc(prs: ^Parser, tokens: []Token) -> (err: Maybe(Error)) {
	prs.tokens = tokens

	for !prs_end(prs) {
		prs.span.lo = prs.span.hi
		token := prs_peek(prs)

		#partial switch token.type {
		case .Newline:
			prs_eat(prs) // ignore newline
		case .KW_extern:
			top_stmt := prs_extern(prs) or_return
			append(&prs.top_stmts, top_stmt)
		case .KW_data:
			top_stmt := prs_data(prs) or_return
			append(&prs.top_stmts, top_stmt)
		case .KW_func:
			top_stmt := prs_func(prs) or_return
			append(&prs.top_stmts, top_stmt)
		case:
			panicf("invalid token: %v\n", token)
		}
	}

	return
}

prs_extern :: proc(prs: ^Parser) -> (extern: Extern, err: Maybe(Error)) {
	_ = prs_expect(prs, .KW_extern) or_return
	name := prs_expect(prs, .Global) or_return
	_ = prs_expect(prs, .Newline) or_return

	// append(&prs.top_stmts, Extern {
	// 	name = name,
	// })

	extern = {
		name = name.(string),
	}
	return
}

prs_data :: proc(prs: ^Parser) -> (data: Data, err: Maybe(Error)) {
	_ = prs_expect(prs, .KW_data) or_return
	name := prs_expect(prs, .Global) or_return
	_ = prs_expect(prs, .Equals) or_return

	args: [dynamic]ConstExpr

	_ = prs_expect(prs, .LBrace) or_return

	const_expr := prs_const_expr(prs) or_return
	append(&args, const_expr)

	for prs_peek(prs).type != .RBrace {
		_ = prs_expect(prs, .Comma) or_return
		const_expr := prs_const_expr(prs) or_return
		append(&args, const_expr)
	}

	_ = prs_expect(prs, .RBrace) or_return
	_ = prs_expect(prs, .Newline) or_return

	data = {
		name = name.(string),
		args = args[:],
	}
	return
}

prs_func :: proc(prs: ^Parser) -> (func: Func, err: Maybe(Error)) {
	_ = prs_expect(prs, .KW_func) or_return
	ret_type := prs_expect(prs, .Type) or_return
	name := prs_expect(prs, .Global) or_return

	_ = prs_expect(prs, .LParen) or_return
	_ = prs_expect(prs, .RParen) or_return

	stmts: [dynamic]Stmt

	_ = prs_expect(prs, .LBrace) or_return
	_ = prs_expect(prs, .Newline) or_return

	for prs_peek(prs).type != .RBrace {
		token := prs_peek(prs)
		// todo: do i need a partial here? just prs_expect (soft?)
		#partial switch token.type {
		case .Instruction:
			// todo: remove partial
			#partial switch token.value.(Instruction) {
			case .call:
				call := prs_call(prs) or_return
				append(&stmts, call)
			case .ret:
				ret := prs_ret(prs) or_return
				append(&stmts, ret)
			case:
				panicf("unimplemented instr: %v\n", token)
			}
		case:
			panicf("expected instruction but got %v\n", token)
		}
		_ = prs_expect(prs, .Newline) or_return
	}

	_ = prs_expect(prs, .RBrace) or_return
	_ = prs_expect(prs, .Newline) or_return

	func = {
		ret_type = ret_type.(Type),
		name = name.(string),
		// params = {},
		body = stmts[:],
	}
	return
}

prs_call :: proc(prs: ^Parser) -> (call: Call, err: Maybe(Error)) {
	prs_expect_instr(prs, .call)
	name := prs_expect(prs, .Global) or_return

	args: [dynamic]Expr

	_ = prs_expect(prs, .LParen) or_return

	// todo: optional args
	arg := prs_expr(prs) or_return
	append(&args, arg)

	// todo: more args

	_ = prs_expect(prs, .RParen) or_return

	call = {
		name = name.(string),
		args = args[:],
	}
	return
}

prs_ret :: proc(prs: ^Parser) -> (ret: Ret, err: Maybe(Error)) {
	prs_expect_instr(prs, .ret)
	// todo: optional value
	value := prs_expr(prs) or_return

	ret = {
		value = value,
	}
	return
}

prs_expr :: proc(prs: ^Parser) -> (expr: Expr, err: Maybe(Error)) {
	type := prs_expect(prs, .Type) or_return
	value := prs_value(prs)

	expr = {
		type = type.(Type),
		value = value,
	}
	return
}

prs_value :: proc(prs: ^Parser) -> Value {
	token := prs_eat(prs)
	#partial switch token.type {
	case .Global:
		return Global(token.value.(string))
	case .Local:
		return Local(token.value.(string))
	// todo: clean this up!!
	case .Int:
		return ConstValue(token.value.(int))
	}

	panicf("expected Global, Local or Int but got %v\n", token)
}

prs_expect_instr :: proc(prs: ^Parser, expected_instr: Instruction) -> (err: Maybe(Error)) {
	instr := prs_expect(prs, .Instruction) or_return

	if instr.(Instruction) != expected_instr {
		err = prs_error(prs, "Expected instruction %v but got %v", expected_instr, instr)
	}

	return
}

prs_const_expr :: proc(prs: ^Parser) -> (const_expr: ConstExpr, err: Maybe(Error)) {
	type := prs_expect(prs, .Type) or_return
	value := prs_const_value(prs) or_return

	const_expr = {
		type = type.(Type),
		value = value,
	}
	return
}

prs_const_value :: proc(prs: ^Parser) -> (const_value: ConstValue, err: Maybe(Error)) {
	token := prs_eat(prs)
	#partial switch token.type {
	case .String:
		const_value = token.value.(string)
	case .Int:
		const_value = token.value.(int)
	case:
		err = prs_error(prs, "Expected ConstValue (String or Int) but got %v", token.type)
	}

	return
}

prs_error :: proc(prs: ^Parser, fmtstr: string, args: ..any) -> Error {
	return {
		span = prs.tokens[prs.span.lo].span,
		text = fmt.aprintf(fmtstr, ..args)
	}
}

error :: proc(span: Span, fmtstr: string, args: ..any) -> Error {
	return {
		span = span,
		text = fmt.aprintf(fmtstr, ..args)
	}
}

// requiring results makes it so i dont forget or_return
// at the cost of sometimes using _ =
@(require_results)
prs_expect :: proc(prs: ^Parser, type: TokenType) -> (value: TokenValue, err: Maybe(Error)) {
	assert(!prs_end(prs))
	token := prs_eat(prs)

	if token.type == type {
		value = token.value
		return
	}

	err = error(token.span, "Expected %v but got %v", type, token.type)
	return
}

prs_eat :: proc(prs: ^Parser, loc := #caller_location) -> Token {
	assert(!prs_end(prs), loc = loc)
	defer prs.span.hi += 1
	return prs_peek(prs)
}

prs_peek :: proc(prs: ^Parser, offset: uint = 0, loc := #caller_location) -> Token {
	assert(!prs_end(prs), loc = loc)
	return prs.tokens[prs.span.hi + offset]
}

prs_end :: proc(prs: ^Parser) -> bool {
	return prs.span.hi >= len(prs.tokens)
}
