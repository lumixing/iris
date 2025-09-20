package iris

import "core:c"
Parser :: struct {
	tokens: []Token,
	top_stmts: [dynamic]TopStmt,
	span: Span,
}

prs_parse :: proc(prs: ^Parser, tokens: []Token) {
	prs.tokens = tokens

	for !prs_end(prs) {
		prs.span.lo = prs.span.hi
		token := prs_peek(prs)

		#partial switch token.type {
		case .Newline:
			prs_eat(prs) // ignore newline
		case .KW_extern:
			prs_extern(prs)
		case .KW_data:
			prs_data(prs)
		case .KW_func:
			prs_func(prs)
		case:
			panicf("invalid token: %v\n", token)
		}
	}
}

prs_extern :: proc(prs: ^Parser) {
	prs_expect(prs, .KW_extern)
	name := prs_expect(prs, .Global).(string)
	prs_expect(prs, .Newline)

	append(&prs.top_stmts, Extern {
		name = name,
	})
}

prs_data :: proc(prs: ^Parser) {
	prs_expect(prs, .KW_data)
	name := prs_expect(prs, .Global).(string)
	prs_expect(prs, .Equals)

	args: [dynamic]ConstExpr

	prs_expect(prs, .LBrace)

	const_expr := prs_const_expr(prs)
	append(&args, const_expr)

	for prs_peek(prs).type != .RBrace {
		prs_expect(prs, .Comma)
		const_expr := prs_const_expr(prs)
		append(&args, const_expr)
	}

	prs_expect(prs, .RBrace)
	prs_expect(prs, .Newline)

	append(&prs.top_stmts, Data {
		name = name,
		args = args[:],
	})
}

prs_func :: proc(prs: ^Parser) {
	prs_expect(prs, .KW_func)
	ret_type := prs_expect(prs, .Type).(Type)
	name := prs_expect(prs, .Global).(string)

	prs_expect(prs, .LParen)
	prs_expect(prs, .RParen)

	stmts: [dynamic]Stmt

	prs_expect(prs, .LBrace)
	prs_expect(prs, .Newline)

	for prs_peek(prs).type != .RBrace {
		token := prs_peek(prs)
		#partial switch token.type {
		case .Instruction:
			// todo: remove partial
			#partial switch token.value.(Instruction) {
			case .call:
				append(&stmts, prs_call(prs))
			case .ret:
				append(&stmts, prs_ret(prs))
			case:
				panicf("unimplemented instr: %v\n", token)
			}
		case:
			panicf("expected instruction but got %v\n", token)
		}
		prs_expect(prs, .Newline)
	}

	prs_expect(prs, .RBrace)
	prs_expect(prs, .Newline)

	append(&prs.top_stmts, Func {
		ret_type = ret_type,
		name = name,
		// params = {},
		body = stmts[:],
	})
}

prs_call :: proc(prs: ^Parser) -> Call {
	prs_expect_instr(prs, .call)
	name := prs_expect(prs, .Global).(string)

	args: [dynamic]Expr

	prs_expect(prs, .LParen)

	// todo: optional args
	arg := prs_expr(prs)
	append(&args, arg)

	// todo: more args

	prs_expect(prs, .RParen)

	return {
		name = name,
		args = args[:],
	}
}

prs_ret :: proc(prs: ^Parser) -> Ret {
	prs_expect_instr(prs, .ret)
	// todo: optional value
	value := prs_expr(prs)

	return {
		value = value,
	}
}

prs_expr :: proc(prs: ^Parser) -> Expr {
	type := prs_expect(prs, .Type).(Type)
	value := prs_value(prs)

	return {
		type = type,
		value = value,
	}
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

prs_expect_instr :: proc(prs: ^Parser, exp_instr: Instruction) {
	instr := prs_expect(prs, .Instruction).(Instruction)
	assert(instr == exp_instr)
}

prs_const_expr :: proc(prs: ^Parser) -> ConstExpr {
	type := prs_expect(prs, .Type).(Type)
	value := prs_const_value(prs)

	return {
		type = type,
		value = value,
	}
}

prs_const_value :: proc(prs: ^Parser) -> ConstValue {
	token := prs_eat(prs)
	#partial switch token.type {
	case .String:
		return token.value.(string)
	case .Int:
		return token.value.(int)
	}

	panicf("expected String or Int but got %v\n", token)
}

prs_expect :: proc(prs: ^Parser, type: TokenType, loc := #caller_location) -> TokenValue {
	assert(!prs_end(prs), loc = loc)
	token := prs_eat(prs)
	if token.type == type {
		return token.value
	}
	panicf("expected %v but got %v\n", type, token.type, loc = loc)
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
