package iris

Info :: struct {
	externs: map[string]Extern,
	datas: map[string]Data,
	funcs: map[string]Func,
	func_info: map[string]FuncInfo,
}

FuncInfo :: struct {
	locals: map[string]LocalDef,
}

check :: proc(top_stmts: []TopStmt) -> (info: Info, err: Maybe(Error)) {
	// first pass: declarations
	for top_stmt in top_stmts {
		switch tstmt in top_stmt {
		case Extern:
			check_global_name_duplicate(&info, tstmt.name) or_return
			info.externs[tstmt.name] = tstmt
		case Data:
			check_global_name_duplicate(&info, tstmt.name) or_return
			info.datas[tstmt.name] = tstmt
		case Func:
			check_global_name_duplicate(&info, tstmt.name) or_return
			info.funcs[tstmt.name] = tstmt
			info.func_info[tstmt.name] = {}
		}
	}

	if "main" not_in info.funcs {
		err = error({}, "Main function is not defined")
		return
	}

	for top_stmt in top_stmts {
		#partial switch tstmt in top_stmt {
		case Func:
			if len(tstmt.body) == 0 {
				err = error({}, "Function %q has an empty body", tstmt.name)
				return
			}

			// this is a fucking mess lol
			// ensure last stmt is ret
			last_stmt := tstmt.body[len(tstmt.body) - 1]
			if instr, ok := last_stmt.(Instr); ok {
				if ret, ok := instr.(Ret); ok {
					// ensure ret type is matching
					if ret_value, ok := ret.value.?; ok {
						if tstmt.ret_type != ret_value.type {
							err = error(
								{}, "Function %q expected to return %v but returned %v",
								tstmt.name, tstmt.ret_type, ret_value.type
							)
							return
						}
					} else {
						if tstmt.ret_type != .void {
							err = error(
								{}, "Function %q expected to return %v but returned nothing",
								tstmt.name, tstmt.ret_type
							)
							return
						}
					}
				} else {
					err = error({}, "Function %q does not end with ret", tstmt.name)
					return
				}
			} else {
				err = error({}, "Function %q does not end with ret", tstmt.name)
				return
			}

			for stmt in tstmt.body {
				#partial switch s in stmt {
				case Instr:
					#partial switch i in s {
					case Call:
						name_found := false
	
						if i.name in info.externs {
							name_found = true
						}
	
						if i.name in info.funcs {
							name_found = true
						}
	
						if !name_found {
							err = error({}, "Global %q is not defined", i.name)
							return
						}
					}
				case LocalDef:
					func_info := &info.func_info[tstmt.name]
					locals := &func_info.locals
					locals[s.name] = s
				// case: unimplemented()
				}
			}
		// case: unimplemented()
		}
	}
	
	return
}

@(require_results)
check_global_name_duplicate :: proc(info: ^Info, name: string) -> (err: Maybe(Error)) {
	if name in info.externs {
		err = error({}, "Global %q is already defined as an externed function", name)
		return
	}

	if name in info.datas {
		err = error({}, "Global %q is already defined as data", name)
		return
	}

	if name in info.funcs {
		err = error({}, "Global %q is already defined as a function", name)
		return
	}

	return
}
