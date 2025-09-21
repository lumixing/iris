package iris

Span :: struct {
	lo, hi: uint,
}

span_to_line_col :: proc(file: []u8, span: Span) -> (line, col: uint) {
	line, col = 1, 1

	for char, idx in file {
		if uint(idx) == span.lo {
			break
		}
		if char == '\n' {
			line += 1
			col = 1
		} else {
			col += 1
		}
	}

	return
}

Error :: struct {
	span: Span,
	text: string,
}
