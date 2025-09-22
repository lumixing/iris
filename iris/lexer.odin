package iris

import "core:strconv"

Lexer :: struct {
	input: []u8,
	tokens: [dynamic]Token,
	span: Span,
}

lexer_add_token :: proc(lexer: ^Lexer, type: TokenType, value: TokenValue = nil) {
	append(&lexer.tokens, Token {
		type = type,
		value = value,
		span = lexer.span,
	})
}

lexer_scan :: proc(lexer: ^Lexer, input: []u8) {
	lexer.input = input

	for !lexer_end(lexer) {
		lexer.span.lo = lexer.span.hi
		char := lexer_eat(lexer)

		switch char {
		case ' ', '\t', '\r': // ignore whitespace
		case '\n': lexer_add_token(lexer, .Newline)
		case ';':
			for lexer_peek(lexer) != '\n' {
				lexer_eat(lexer)
			}
			lexer_eat(lexer)
		case '=':  lexer_add_token(lexer, .Equals)
		case ',':  lexer_add_token(lexer, .Comma)
		case '{':  lexer_add_token(lexer, .LBrace)
		case '}':  lexer_add_token(lexer, .RBrace)
		case '(':  lexer_add_token(lexer, .LParen)
		case ')':  lexer_add_token(lexer, .RParen)
		case '$':
			for is_ident_char(lexer_peek(lexer)) {
				lexer_eat(lexer)
			}
			name := string(lexer.input[lexer.span.lo+1:lexer.span.hi])
			lexer_add_token(lexer, .Global, name)
		case '%':
			for is_ident_char(lexer_peek(lexer)) {
				lexer_eat(lexer)
			}
			name := string(lexer.input[lexer.span.lo+1:lexer.span.hi])
			lexer_add_token(lexer, .Local, name)
		case '"':
			for lexer_peek(lexer) != '"' {
				lexer_eat(lexer)
			}
			lexer_eat(lexer) // eat second quote
			lexeme := string(lexer.input[lexer.span.lo:lexer.span.hi])
			unquoted, _, ok := strconv.unquote_string(lexeme)
			assertf(ok, "invalid string: %q\n", lexeme)
			lexer_add_token(lexer, .String, unquoted)
		case:
			if is_ident_char(char, allow_digits = false) {
				for is_ident_char(lexer_peek(lexer)) {
					lexer_eat(lexer)
				}
				lexeme := string(lexer.input[lexer.span.lo:lexer.span.hi])
				switch lexeme {
				case "extern":   lexer_add_token(lexer, .KW_extern)
				case "variadic": lexer_add_token(lexer, .KW_variadic)
				case "data":     lexer_add_token(lexer, .KW_data)
				case "func":     lexer_add_token(lexer, .KW_func)
				case "ptr":      lexer_add_token(lexer, .Type, .ptr)
				case "void":     lexer_add_token(lexer, .Type, .void)
				case "u8":       lexer_add_token(lexer, .Type, .u8)
				case "i32":      lexer_add_token(lexer, .Type, .i32)
				case "copy":     lexer_add_token(lexer, .Instruction, .copy)
				case "call":     lexer_add_token(lexer, .Instruction, .call)
				case "point":    lexer_add_token(lexer, .Instruction, .point)
				case "ret":      lexer_add_token(lexer, .Instruction, .ret)
				case "load":     lexer_add_token(lexer, .Instruction, .load)
				case "store":    lexer_add_token(lexer, .Instruction, .store)
				case "add":      lexer_add_token(lexer, .Instruction, .add)
				case:
					panicf("unknown lexeme: %q\n", lexeme)
				}
			} else if is_digit(char) {
				for is_digit(lexer_peek(lexer)) {
					lexer_eat(lexer)
				}
				lexeme := string(lexer.input[lexer.span.lo:lexer.span.hi])
				value, ok := strconv.parse_int(lexeme)
				assertf(ok, "invalid integer: %q\n", lexeme)
				lexer_add_token(lexer, .Int, value)
			} else {
				panicf("unknown char: %c (%d)\n", char, char)
			}
		}
	}
}

is_ident_char :: proc(char: u8, allow_digits := true) -> bool {
	switch char {
	case 'a'..='z',
		 'A'..='Z',
		 '_', '.':
		return true
	}

	if allow_digits && is_digit(char) {
		return true
	}

	return false
}

is_digit :: proc(char: u8) -> bool {
	switch char {
	case '0'..='9':
		return true
	}

	return false
}

lexer_eat :: proc(lexer: ^Lexer, loc := #caller_location) -> u8 {
	assert(!lexer_end(lexer), loc = loc)
	defer lexer.span.hi += 1
	return lexer_peek(lexer)
}

lexer_peek :: proc(lexer: ^Lexer, loc := #caller_location) -> u8 {
	assert(!lexer_end(lexer), loc = loc)
	return lexer.input[lexer.span.hi]
}

lexer_end :: proc(lexer: ^Lexer) -> bool {
	return lexer.span.hi >= len(lexer.input)
}
