package nasm

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"

ff :: fmt.aprintf

@(private)
main :: proc() {
	lines: [dynamic]string

	global(&lines, "main")
	newline(&lines)

	extern(&lines, "puts")
	newline(&lines)

	section(&lines, "data")
	label(&lines, "str")
	db(&lines, {"hello, world", 0})
	newline(&lines)

	section(&lines, "text")
	label(&lines, "main")

	mov(&lines, .rdi, "str")
	call(&lines, "puts")
	newline(&lines)

	mov(&lines, .rax, 1)
	mov(&lines, .rdi, 1)
	mov(&lines, .rsi, "str")
	mov(&lines, .rdx, 5)
	syscall(&lines)
	newline(&lines)

	mov(&lines, .rax, 0)
	ret(&lines)

	for line in lines {
		fmt.println(line)
	}

	lines_str := strings.join(lines[:], "\n")
	os.write_entire_file("out.asm", transmute([]u8)lines_str)
}

newline :: proc(lines: ^[dynamic]string) {
	append(lines, "")
}

global :: proc(lines: ^[dynamic]string, name: string) {
	append(lines, ff("global %s", name))
}

extern :: proc(lines: ^[dynamic]string, name: string) {
	append(lines, ff("extern %s", name))
}

section :: proc(lines: ^[dynamic]string, name: string) {
	append(lines, ff("section .%s", name))
}

label :: proc(lines: ^[dynamic]string, name: string) {
	append(lines, ff("%s:", name))
}

db :: proc(lines: ^[dynamic]string, args: []ConstExpr) {
	append(lines, ff("\tdb %s", const_args_str(args)))
}

call :: proc(lines: ^[dynamic]string, name: string) {
	append(lines, ff("\tcall %s", name))
}

ret :: proc(lines: ^[dynamic]string) {
	append(lines, "\tret")
}

syscall :: proc(lines: ^[dynamic]string) {
	append(lines, "\tsyscall")
}

mov :: proc {
	mov_reg_label,
	mov_reg_int,
}

mov_reg_label :: proc(lines: ^[dynamic]string, reg: Register, label: string) {
	append(lines, ff("\tmov %s, %s", reg, label))
}

mov_reg_int :: proc(lines: ^[dynamic]string, reg: Register, value: int) {
	append(lines, ff("\tmov %s, %d", reg, value))
}

ConstExpr :: union #no_nil {
	string,
	int,
}

@(private)
const_expr_str :: proc(expr: ConstExpr) -> string {
	switch e in expr {
	case string:
		return ff("%q", e)
	case int:
		return ff("%d", e)
	}

	unreachable()
}

@(private)
const_args_str :: proc(args: []ConstExpr) -> string {
	args_str := slice.mapper(args, const_expr_str)

	return strings.join(args_str, ", ")
}

Register :: enum {
	rax,
	rdi,
	rsi,
	rdx,
	rcx,
	r8,
	r9,
}
