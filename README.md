## iris, intermediate representation

somewhere between qbe and llvm ir  
currently compiles down to nasm

```iris
extern $printf variadic

data $fmt = { b "hello world %d", b 10, b 0 }

func i32 $main() {
    i32 %r = call $add(w 34, w 35)
    call $printf(ptr $fmt, i32 %r)
    ret i32 0
}

func i32 $add(i32 %a, i32 %b) {
    i32 %c = add i32 %a, i32 %b
    ret i32 %c
}
```

runes: `$global` `%local` `@label` `#const(?)` `&struct`

<!-- ```iris
extern $printf variadic

data $fmt = { b "(%.2f, %.2f)", b 10, b 0 }

struct @point = { 2 f32 }

func i32 $main() {
    @point %point = alloc @point
    fieldstore, @point %point, 0, f32 13
    fieldstore, @point %point, 1, f32 37
    call $point.print(@point %point)
    ret i32 0
}

func void $point.print(@point %point) {
    f32 %x = fieldload @point %point, 0
    f32 %y = fieldload @point %point, 1
    call $printf(ptr $fmt, f32 %x, f32 %y)
    ret
}
``` -->
