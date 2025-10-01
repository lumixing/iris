package iris

import "core:os"
import "core:fmt"

log :: fmt.println
panicf :: fmt.panicf
assertf :: fmt.assertf

PATH :: "examples/hello.iris"

main :: proc() {
	file := #load("../" + PATH)

	lexer: Lexer
	lexer_scan(&lexer, file)

	parser: Parser
	parse_err := prs_parse(&parser, lexer.tokens[:])
	if err, ok := parse_err.?; ok {
		line, col := span_to_line_col(file, err.span)
		fmt.printfln("Error at %s:%d:%d: %s", PATH, line, col, err.text)
		return
	}
	// fmt.printfln("%#v", parser.top_stmts)

	info, check_err := check(parser.top_stmts[:])
	if err, ok := check_err.?; ok {
		line, col := span_to_line_col(file, err.span)
		fmt.printfln("Error at %s:%d:%d: %s", PATH, line, col, err.text)
		return
	}
	fmt.printfln("%#v", info.func_info)

	code := codegen(parser.top_stmts[:], info)
	log(code)

	// os.write_entire_file("codegen.asm", transmute([]u8)code)
}
