# SnapSurf Token List

Foundation subset implemented by the ASM compiler:

- `use`
- `fn`
- `ret`
- `end`
- `let`
- `mut`
- `true`
- `false`
- identifiers
- decimal integer literals
- string literals
- `->`
- `/`
- `.`
- `,`
- `=`
- `+`
- `-`
- `*`
- `%`
- `(`
- `)`
- newline
- EOF
- `//` and `/* ... */` comments are skipped

The source lexer stores tokens in a fixed token buffer:

- capacity: 4096 tokens
- fields: type, start offset, length, line, column, payload offset or value
- overflow diagnostic: `E0105`

Foundation debug command:

```sh
./build/surf dump-tokens examples/hello
```

Package-file words recognized by the ASM compiler:

- `package`
- `version`
- `type`
- `target`
- `runtime`
- `entry`
- `requires`
- `dep`
- `end`
