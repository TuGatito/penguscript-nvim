" Vim syntax file
" Language: PenguScript
" Filetype: pengus
" Extensions: .pengu, .d.pengu
" Maintainer: TuGatito <53541345+TuGatito@users.noreply.github.com>
" License: MIT
"
" Resaltado de sintaxis clásico de respaldo. Si existe un parser Treesitter
" `pengus` y Neovim >= 0.10, el plugin intenta usar Treesitter y este archivo
" actúa como red de seguridad para los nodos no cubiertos por las queries.

if exists("b:current_syntax")
  finish
endif

" ---------------------------------------------------------------------------
" Palabras clave
" ---------------------------------------------------------------------------
syn keyword pengusConditional if unless when judge
syn keyword pengusRepeat    while for
syn keyword pengusKeyword   weave rune omen as is into calling with let var const
                            \ set defer errdefer banish return break continue in
syn keyword pengusBoolean   true false null
syn keyword pengusType      int i32 i64 float f32 f64 bool string void opaque

" ---------------------------------------------------------------------------
" Comentarios  (# normal, ## documentación)
" ---------------------------------------------------------------------------
syn match pengusComment "#.*$" contains=@Spell,pengusTodo
syn match pengusDocComment "##.*$" contains=@Spell,pengusTodo
syn keyword pengusTodo TODO FIXME XXX HACK NOTE contained

" ---------------------------------------------------------------------------
" Números
" ---------------------------------------------------------------------------
syn match pengusNumber "\<0[xX][0-9a-fA-F_]\+\>"
syn match pengusNumber "\<0[bB][01_]\+\>"
syn match pengusNumber "\<0[oO][0-7_]\+\>"
syn match pengusNumber "\<\d[0-9_]*\(\.[0-9_]*\)\?\([eE][+-]\?[0-9_]\+\)\?\>"

" ---------------------------------------------------------------------------
" Cadenas
" ---------------------------------------------------------------------------
syn region pengusString start=+"+ skip=+\\\\"\\\\|\\\\$+ excludenl end=+"+ end=+$+
      \ contains=pengusEscape
syn region pengusString start=+'+ skip=+\\\\'\\\\|\\\\$+ excludenl end=+'+ end=+$+
      \ contains=pengusEscape
syn match pengusEscape contained display "\\\(.\|x\x\{2}\|u\x\{4}\)"

" ---------------------------------------------------------------------------
" Operadores y delimitadores
" ---------------------------------------------------------------------------
" Operadores de dos caracteres (primero) y un solo carácter (la clase como
" alternativa final). Dentro de una misma alternativa, Vim intenta los
" operadores largos antes que la clase genérica.
syn match pengusOperator "->\|=>\|::\|:=\|==\|!=\|<=\|>=\|&&\|||\|<<\|>>\|\.\.\|[-+*/%=<>!&|^~?]"
syn match pengusDelimiter "[(){}\[\];,]"

" ---------------------------------------------------------------------------
" Enlaces a grupos estándar
" ---------------------------------------------------------------------------
hi def link pengusConditional Conditional
hi def link pengusRepeat    Repeat
hi def link pengusKeyword   Keyword
hi def link pengusBoolean   Boolean
hi def link pengusType      Type
hi def link pengusComment   Comment
hi def link pengusDocComment SpecialComment
hi def link pengusTodo      Todo
hi def link pengusNumber    Number
hi def link pengusString    String
hi def link pengusEscape    SpecialChar
hi def link pengusOperator  Operator
hi def link pengusDelimiter Delimiter

let b:current_syntax = "pengus"
