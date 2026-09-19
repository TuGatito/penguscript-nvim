" Vim syntax file
" Language: PenguScript
" Filetype: pengus
" Extensions: .pengu, .d.pengu
" Maintainer: TuGatito <53541345+TuGatito@users.noreply.github.com>
" License: MIT
"
" Resaltado de sintaxis clásico para PenguScript (versión 0.10+).
" Basado en la especificación oficial de LANGUAGE.md.
" Si existe un parser Treesitter `pengus` y Neovim >= 0.10, el plugin intenta
" usar Treesitter y este archivo actúa como red de seguridad y respaldo.

if exists("b:current_syntax")
  finish
endif

" ---------------------------------------------------------------------------
" Palabras clave de control de flujo
" ---------------------------------------------------------------------------
syn keyword pengusConditional if unless else when judge then
syn keyword pengusRepeat    while for in from to step
syn keyword pengusKeyword   weave declare ritual inline lambda test
                            \ rune echo omen concept bind enchanting alias seal
                            \ shard where of calling with into as is many
                            \ let var const static set
                            \ return break continue defer errdefer banish
                            \ some ord chr bytes essence sigil transmute size try defined
                            \ not and or do

" Soft keywords (actúan como modificadores en posiciones específicas)
syn keyword pengusSoftKeyword frozen borrowed

" ---------------------------------------------------------------------------
" Constantes y valores especiales
" ---------------------------------------------------------------------------
syn keyword pengusBoolean   true false null none error
syn keyword pengusSpecial   self

" Variables en tiempo de compilación (cuando se evalúan bajo 'when')
syn keyword pengusCompileConst main debug os arch compiler

" ---------------------------------------------------------------------------
" Tipos primitivos, alias C y contenedores
" ---------------------------------------------------------------------------
syn keyword pengusType      int i8 i16 i32 i64
syn keyword pengusType      u8 u16 u32 u64 byte
syn keyword pengusType      usize isize
syn keyword pengusType      float f32 f64 double
syn keyword pengusType      bool char string void opaque
syn keyword pengusType      size_t int8_t int16_t int32_t int64_t
syn keyword pengusType      uint8_t uint16_t uint32_t uint64_t va_list
syn keyword pengusType      array list slice map maybe result range ref

" Tipos definidos por el usuario (PascalCase: convencion PenguScript)
syn match pengusCustomType  "\<[A-Z][a-zA-Z0-9_]*\>"

" Nombres de declaraciones (funciones, tipos, declares)
syn match pengusFunction   "\<weave\s\+\%(inline\s\+\)\?\%(ritual\s\+\)\?\zs[A-Za-z_][A-Za-z0-9_]*\>"
syn match pengusDeclare    "\<declare\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"
syn match pengusTypeDef    "\<\%(rune\|echo\|omen\|concept\|bind\|enchanting\|alias\|seal\)\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"

" Módulos e inclusión
syn keyword pengusInclude   import include link insignia

" Módulos comunes de la librería estándar (std.*)
syn keyword pengusModule    spark oracle scrolls compass archivum cipher chronicle
                            \ lot rites whisper ward trial tally atlas coven
                            \ regulus parchment seal precis filum loom invoke ffi
                            \ raylib sqlite3 webui miniaudio tomlum uuid yaml

" Built-in print
syn keyword pengusBuiltin   print

" ---------------------------------------------------------------------------
" Comentarios (# normal, ## documentación)
" ---------------------------------------------------------------------------
syn match pengusComment    "#.*$" contains=@Spell,pengusTodo
syn match pengusDocComment "##.*$" contains=@Spell,pengusTodo
syn keyword pengusTodo     TODO FIXME XXX HACK NOTE BUG WARN contained

" ---------------------------------------------------------------------------
" Números (enteros, hex, bin, oct, flotantes con notación científica)
" ---------------------------------------------------------------------------
syn match pengusNumber "\<0[xX][0-9a-fA-F_]\+\>"
syn match pengusNumber "\<0[bB][01_]\+\>"
syn match pengusNumber "\<0[oO][0-7_]\+\>"
syn match pengusNumber "\<\d[0-9_]*\.[0-9_]\+\%([eE][+-]\?[0-9_]\+\)\?\>"
syn match pengusNumber "\<\d[0-9_]*[eE][+-]\?[0-9_]\+\>"
syn match pengusNumber "\<\d[0-9_]*\>"

" ---------------------------------------------------------------------------
" Escapes e interpolación dentro de cadenas
" ---------------------------------------------------------------------------
syn match pengusEscape contained display "\\\(.\|x\x\{2}\|u\x\{4}\|U\x\{8}\)"
syn region pengusInterpolation contained matchgroup=pengusInterpolationDelimiter start="{" end="}"
      \ contains=pengusKeyword,pengusConditional,pengusRepeat,pengusBoolean,pengusSpecial,pengusType,pengusCustomType,pengusNumber,pengusOperator,pengusDelimiter,pengusBuiltin,pengusModule

" ---------------------------------------------------------------------------
" Cadenas y caracteres
" ---------------------------------------------------------------------------
" Cadenas crudas multilínea triple comilla: r"""...""" o r'''...'''
syn region pengusRawTripleString start=+[rR]"""+ end=+"""+ contains=@Spell
syn region pengusRawTripleString start=+[rR]'''+ end=+'''+ contains=@Spell

" Cadenas multilínea triple comilla: """...""" o '''...'''
syn region pengusTripleString start=+"""+ end=+"""+ contains=pengusEscape,pengusInterpolation,@Spell
syn region pengusTripleString start=+'''+ end=+'''+ contains=pengusEscape,pengusInterpolation,@Spell

" Cadenas crudas de una línea: r"..." o r'...'
syn region pengusRawString start=+[rR]"+ skip=+\\\\\|\\"+ end=+"+ contains=@Spell
syn region pengusRawString start=+[rR]'+ skip=+\\\\\|\\'+ end=+'+ contains=@Spell

" Cadenas normales de una línea: "..." (con interpolación y escapes)
syn region pengusString start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=pengusEscape,pengusInterpolation,@Spell

" Caracteres literales: 'A', '\n', '\x41'
syn match pengusCharacter "'\([^'\\]\|\\\(.\|x\x\{2}\|u\x\{4}\)\)'" contains=pengusEscape

" ---------------------------------------------------------------------------
" Operadores, flechas y delimitadores
" ---------------------------------------------------------------------------
" Operadores compuestos, flechas y símbolos
syn match pengusOperator "->\|=>\|::\|:=\|==\|!=\|<=\|>=\|&&\|||\|<<\|>>\|\.\."
syn match pengusOperator "+=\|-=\|\*=\|/=\|%=\|&=\||=\|\^=\|<<=\|>>="
syn match pengusOperator "[-+*/%=<>!&|^~?]"

" Predicados especiales (word tests)
syn match pengusWordTest "\<is\s\+\%(not\s\+\)\?present\>"
syn match pengusWordTest "\<is\s\+\%(true\|false\)\>"
syn match pengusWordTest "\<not\s\+in\>"

" Campos y miembros (.campo y self->campo)
syn match pengusField "\.\<[a-zA-Z_][a-zA-Z0-9_]*\>"
syn match pengusArrowField "->\<[a-zA-Z_][a-zA-Z0-9_]*\>"

syn match pengusDelimiter "[()[\]:,]"

" ---------------------------------------------------------------------------
" Enlaces a grupos estándar de Vim
" ---------------------------------------------------------------------------
hi def link pengusConditional          Conditional
hi def link pengusRepeat               Repeat
hi def link pengusKeyword              Keyword
hi def link pengusSoftKeyword          Keyword
hi def link pengusBoolean              Boolean
hi def link pengusSpecial              Special
hi def link pengusCompileConst         Constant
hi def link pengusType                 Type
hi def link pengusCustomType           Type
hi def link pengusFunction             Function
hi def link pengusDeclare              Function
hi def link pengusTypeDef              TypeDef
hi def link pengusInclude              Include
hi def link pengusModule               Structure
hi def link pengusBuiltin              Function
hi def link pengusComment              Comment
hi def link pengusDocComment           SpecialComment
hi def link pengusTodo                 Todo
hi def link pengusNumber               Number
hi def link pengusString               String
hi def link pengusTripleString         String
hi def link pengusRawString            String
hi def link pengusRawTripleString      String
hi def link pengusCharacter            Character
hi def link pengusEscape               SpecialChar
hi def link pengusInterpolationDelimiter Delimiter
hi def link pengusOperator             Operator
hi def link pengusWordTest             Operator
hi def link pengusField                Identifier
hi def link pengusArrowField           Identifier
hi def link pengusDelimiter            Delimiter

let b:current_syntax = "pengus"
