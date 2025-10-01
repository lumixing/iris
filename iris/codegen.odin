package iris

import "core:strings"
import "../nasm"

codegen :: proc(top_stmts: []TopStmt, info: Info) -> string {
	lines: [dynamic]string

	nasm.global(&lines, "main")
	nasm.newline(&lines)

	// externs
	for top_stmt in top_stmts {
		#partial switch tstmt in top_stmt {
		case Extern:
			nasm.extern(&lines, tstmt.name)
		}
	}
	nasm.newline(&lines)

	// datas
	nasm.section(&lines, "data")
	for top_stmt in top_stmts {
		#partial switch tstmt in top_stmt {
		case Data:
			nasm.label(&lines, tstmt.name)
			for arg in tstmt.args {
				// todo: remove partial
				#partial switch arg.type {
				case .u8:
					switch value in arg.value {
					case string: nasm.db(&lines, {value})
					case int:    nasm.db(&lines, {value})
					}
				}
			}
		}
	}
	nasm.newline(&lines)

	// funcs
	nasm.section(&lines, "text")
	for top_stmt in top_stmts {
		#partial switch tstmt in top_stmt {
		case Func:
			rsp_size: uint = 0
			for name, local_def in info.func_info[tstmt.name].locals {
				rsp_size += type_size[local_def.type]
			}
			nasm.sub_reg_int(&lines, .rsp, int(rsp_size))

			nasm.label(&lines, tstmt.name)
			for stmt in tstmt.body {
				#partial switch s in stmt {
				case Instr:
					codegen_instr(&lines, s)
				}
			}
			nasm.newline(&lines)
		}
	}

	lines_str := strings.join(lines[:], "\n")

	return lines_str
}

codegen_instr :: proc(lines: ^[dynamic]string, instr: Instr) {
	switch s in instr {
	case Call:
		assert(len(s.args) <= 6)
		for arg, arg_idx in s.args {
			// todo: remove partial
			#partial switch a in arg.value {
			case Global:
				nasm.mov_reg_label(lines, caller_args_regs[arg_idx], string(a))
			}
		}
		nasm.call(lines, s.name)
	case Ret:
		if value, ok := s.value.?; ok {
			#partial switch value in s.value.?.value {
			case ConstValue:
				#partial switch v in value {
				case int:
					nasm.mov_reg_int(lines, .rax, v)
				case: unimplemented()
				}
			case: unimplemented()
			}
		}
		nasm.ret(lines)
	case Copy:
		#partial switch value in s.value.value {
		case ConstValue:
			#partial switch v in value {
			// case int:
			case: unimplemented()
			}
		case: unimplemented()
		}
	}
}

@(rodata)
caller_args_regs := [?]nasm.Register {
	.rdi,
	.rsi,
	.rdx,
	.rcx,
	.r8,
	.r9,
}
