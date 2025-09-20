package iris

import "core:os"
import "core:fmt"

log :: fmt.println
panicf :: fmt.panicf
assertf :: fmt.assertf

main :: proc() {
	file := #load("../examples/hello.iris")

	lexer: Lexer
	lexer_scan(&lexer, file)

	parser: Parser
	parse_err := prs_parse(&parser, lexer.tokens[:])
	if parse_err != nil {
		fmt.println("parse error", parse_err)
		return
	}
	fmt.printfln("%#v", parser.top_stmts)

	code := codegen(parser.top_stmts[:])
	log(code)

	os.write_entire_file("codegen.asm", transmute([]u8)code)
}
