" Vim syntax file
" Language:     PenguScript
" Filetype:     pengus
" Extensions:   .pengu, .d.pengu
" Maintainer:   TuGatito <53541345+TuGatito@users.noreply.github.com>
" License:      MIT
"
" Resaltado de sintaxis clásico para PenguScript 2.0.x.
" Basado en la referencia oficial del lenguaje (LANGUAGE.md, 2.0.x) y en la
" Guía de Estilo Pengunic (PenguScriptGuideSpanish.md).
"
" Si existe un parser Treesitter `pengus` y Neovim >= 0.10, el plugin intenta
" usar Treesitter y este archivo actúa como red de seguridad y respaldo.

if exists("b:current_syntax")
  finish
endif

" El lenguaje tiene cuerpos de C literales dentro de cadenas triples y cadenas
" multilínea, así que sincronizamos hacia atrás una cantidad generosa de líneas.
syn sync minlines=200

" ---------------------------------------------------------------------------
" Atributos de declaración: @noreturn, @export("..."), @packed, @align(N)
" ---------------------------------------------------------------------------
syn match pengusAttribute "@[A-Za-z_][A-Za-z0-9_]*"

" ---------------------------------------------------------------------------
" Palabras clave de control de flujo
" ---------------------------------------------------------------------------
syn keyword pengusConditional if unless else when judge then

syn keyword pengusRepeat      while for in from to step

" ---------------------------------------------------------------------------
" Palabras clave de declaración y modificadores
" ---------------------------------------------------------------------------
syn keyword pengusKeyword     weave declare antiquus enchanting
                            \ rune echo omen concept bind alias seal
                            \ derive cyclus donum shard where
                            \ test var let const static set

" Palabras clave blandas: solo son especiales en posiciones concretas
" (`frozen int`, `weave inline f`, `weave ritual make`).
syn keyword pengusSoftKeyword frozen inline ritual

" ---------------------------------------------------------------------------
" Palabras clave de sentencia / expresión
" ---------------------------------------------------------------------------
syn keyword pengusStatement   calling with into as is many of
                            \ return break continue defer errdefer banish
                            \ some ord chr bytes essence sigil transmute size
                            \ try defined not and or lambda

" `do:` (bloque de valor) y `unsafe:` (opt-out de comprobaciones de límites) son
" sentencias que solo se reconocen cuando van seguidas de dos puntos.
syn match   pengusStatement   "\<do\ze\s*:"
syn match   pengusStatement   "\<unsafe\ze\s*:"

" ---------------------------------------------------------------------------
" Conceptos integrados (nombres reservados del ámbito global, no palabras clave)
" ---------------------------------------------------------------------------
syn keyword pengusConcept     Num Integrum Real Par Ordo Vinculum Imago
                            \ Nexus Forma Iterabilis Donum Any

" ---------------------------------------------------------------------------
" Constantes y valores especiales
" ---------------------------------------------------------------------------
syn keyword pengusBoolean     true false
syn keyword pengusConstant    null none error
syn keyword pengusSpecial     self

" Variables de comptime (evaluadas bajo `when`).
syn keyword pengusCompileConst main debug os arch compiler

" `is present` / `is not present` / `is true` / `is false`
syn keyword pengusWordTest    present

" ---------------------------------------------------------------------------
" Tipos primitivos, alias C y contenedores
" ---------------------------------------------------------------------------
" Enteros con signo (grafías canónicas + alias C)
syn keyword pengusType        int i8 i16 i32 i64 int8 int16 int32 int64
                            \ short long int8_t int16_t int32_t int64_t
" Enteros sin signo
syn keyword pengusType        byte u8 u16 u32 u64 uint
                            \ uint8 uint16 uint32 uint64 ushort ulong
                            \ uint8_t uint16_t uint32_t uint64_t
" Tamaños e índices
syn keyword pengusType        usize isize size_t intptr_t
" Flotantes
syn keyword pengusType        float f32 f64 double
" Otros primitivos
syn keyword pengusType        bool char string void opaque va_list
" Contenedores y tipos compuestos
syn keyword pengusType        array list slice map maybe result range ref

" Tipos definidos por el usuario (PascalCase: convención PenguScript)
syn match   pengusCustomType  "\<[A-Z][a-zA-Z0-9_]*\>"

" ---------------------------------------------------------------------------
" Nombres de declaraciones (funciones, declares, antiquus y tipos)
" ---------------------------------------------------------------------------
" `weave [inline] [ritual] nombre ...`
syn match   pengusFunction    "\<weave\s\+\%(\%(inline\|ritual\)\s\+\)*\zs[A-Za-z_][A-Za-z0-9_]*\>"
" `inline weave nombre ...` / `ritual weave nombre ...`
syn match   pengusFunction    "\<\%(inline\|ritual\)\s\+weave\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"
" `declare [inline] [ritual] nombre ...`
syn match   pengusDeclare     "\<declare\s\+\%(\%(inline\|ritual\)\s\+\)*\zs[A-Za-z_][A-Za-z0-9_]*\>"
" `antiquus nombre ...`
syn match   pengusFunction    "\<antiquus\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"
" `rune|echo|omen|concept|bind|alias|seal Nombre`
syn match   pengusTypeDef     "\<\%(rune\|echo\|omen\|concept\|bind\|alias\|seal\)\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"
" `bind Tipo with Concepto:`
syn match   pengusTypeDef     "\<bind\s\+[A-Za-z_][A-Za-z0-9_]*\s\+with\s\+\zs[A-Za-z_][A-Za-z0-9_]*\>"
" Nombre de función/método en una llamada. Se usa un lookbehind para que el
" resaltado empiece en el nombre: `calling` ya lo consume la palabra clave y el
" motor de sintaxis no vuelve a examinar el prefijo.
syn match   pengusFunctionCall "\(\<calling\s\+\)\@<=\<[A-Za-z_][A-Za-z0-9_]*\>"

" ---------------------------------------------------------------------------
" Módulos, directivas e inclusión
" ---------------------------------------------------------------------------
syn keyword pengusInclude     import include link insignia

" Módulos de la biblioteca estándar (27 módulos puros) + `arca`.
" Tras `import std.spark` el código usa la forma corta (`spark.println`), así que
" se resaltan por nombre. Los módulos satélite instalados con `pengu add` se
" resaltan en la propia sentencia `import`.
syn match   pengusModule      "\<std\.[a-z_][a-z0-9_]*\>"
syn keyword pengusModule      spark scrolls oracle compass archivum cipher
                            \ chronicle lot rites whisper ward trial tally atlas
                            \ coven filum fractio integrum littera logica numerus
                            \ loom memoria invoke ffi ledger arithmancy arca
syn match   pengusModule      "\<import\s\+\zs[A-Za-z_][A-Za-z0-9_.]*"

" Funciones integradas del compilador
syn keyword pengusBuiltin     print

" ---------------------------------------------------------------------------
" Comentarios (# normal, ## documentación)
" ---------------------------------------------------------------------------
" Los comentarios de documentación se definen primero para que `##` no se
" interprete como dos comentarios normales.
syn match   pengusDocComment  "##.*$" contains=@Spell,pengusTodo,pengusAttribute
syn match   pengusComment     "#.*$"  contains=@Spell,pengusTodo
syn keyword pengusTodo        TODO FIXME XXX HACK NOTE BUG WARN contained

" ---------------------------------------------------------------------------
" Números (enteros decimales/hex/binarios y flotantes con exponente)
" ---------------------------------------------------------------------------
syn match   pengusNumber      "\<0[xX][0-9a-fA-F_]\+\>"
syn match   pengusNumber      "\<0[bB][01_]\+\>"
syn match   pengusNumber      "\<\d[0-9_]*\.\%([0-9_]\+\%([eE][+-]\?[0-9_]\+\)\?\)\>"
syn match   pengusNumber      "\<\d[0-9_]*[eE][+-]\?[0-9_]\+\>"
syn match   pengusNumber      "\<\d[0-9_]*\>"

" ---------------------------------------------------------------------------
" Escapes e interpolación dentro de cadenas
" ---------------------------------------------------------------------------
syn match   pengusEscape contained display
          \ "\\\%(.\|x\x\{2}\|u{\x\{1,6}}\|u\x\{4}\|U\x\{8}\)"

" `"{expr}"` — la única forma de composición de cadenas del lenguaje.
syn region  pengusInterpolation contained
          \ matchgroup=pengusInterpolationDelimiter
          \ start="{" end="}"
          \ contains=pengusKeyword,pengusStatement,pengusConditional,pengusRepeat
          \,pengusBoolean,pengusConstant,pengusSpecial,pengusType,pengusCustomType
          \,pengusConcept,pengusNumber,pengusOperator,pengusDelimiter,pengusBuiltin
          \,pengusModule,pengusField,pengusArrowField,pengusString,pengusWordTest

" ---------------------------------------------------------------------------
" Cadenas y caracteres
" ---------------------------------------------------------------------------
" El orden importa: las formas triples se definen DESPUÉS de las simples para
" que `"""` no se interprete como una cadena vacía seguida de comilla.

" Cadenas normales de una línea: "..." (con interpolación y escapes)
syn region  pengusString      start=+"+  skip=+\\\\\|\\"+  end=+"+
          \ contains=pengusEscape,pengusInterpolation,@Spell

" Cadenas crudas de una línea: r"..." (sin escapes ni interpolación)
syn region  pengusRawString   start=+\<[rR]"+ skip=+\\\\\|\\"+ end=+"+ contains=@Spell

" Cadenas multilínea triple comilla: """..."""
syn region  pengusTripleString start=+"""+ end=+"""+
          \ contains=pengusEscape,pengusInterpolation,@Spell

" Cadenas crudas multilínea: r"""...""" (cuerpos `antiquus`, shaders, regex)
syn region  pengusRawTripleString start=+\<[rR]"""+ end=+"""+ contains=@Spell

" Caracteres literales: 'A', '\n', '\x41'
syn match   pengusCharacter   "'\%([^'\\]\|\\\%(.\|x\x\{2}\|u{\x\{1,6}}\|u\x\{4}\|U\x\{8}\)\)'"
          \ contains=pengusEscape

" ---------------------------------------------------------------------------
" Operadores, flechas y delimitadores
" ---------------------------------------------------------------------------
" Flecha de `judge` y acceso a campo por puntero
syn match   pengusOperator    "->"

" Operadores compuestos (asignación y comparación)
syn match   pengusOperator    "<<=\|>>=\|+=\|-=\|\*=\|/=\|%=\|&=\||=\|\^="
syn match   pengusOperator    "==\|!=\|<=\|>=\|<<\|>>"

" Operadores unarios y binarios sueltos
syn match   pengusOperator    "[-+*/%=<>!&|^~]"

" Operadores postfijos de indexación y longitud: `xs at i`, `xs length`
syn match   pengusPostfix     "\<\%(at\|length\)\>"

" Pertenencia negada (`not in`): `not` e `in` ya son palabras clave.
syn match   pengusWordTest    "\<not\s\+in\>"

" Campos y miembros (.campo y self->campo)
syn match   pengusField       "\.\<[a-zA-Z_][a-zA-Z0-9_]*\>"
syn match   pengusArrowField  "->\<[a-zA-Z_][a-zA-Z0-9_]*\>"

syn match   pengusDelimiter   "[()[\]:,]"

" ---------------------------------------------------------------------------
" Enlaces a grupos estándar de Vim
" ---------------------------------------------------------------------------
hi def link pengusAttribute            PreProc
hi def link pengusConditional          Conditional
hi def link pengusRepeat               Repeat
hi def link pengusKeyword              Keyword
hi def link pengusSoftKeyword          Keyword
hi def link pengusStatement            Statement
hi def link pengusBoolean              Boolean
hi def link pengusConstant             Constant
hi def link pengusSpecial              Special
hi def link pengusWordTest             Operator
hi def link pengusCompileConst         Constant
hi def link pengusConcept              Structure
hi def link pengusType                 Type
hi def link pengusCustomType           Type
hi def link pengusFunction             Function
hi def link pengusFunctionCall         Function
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
hi def link pengusPostfix              Operator
hi def link pengusField                Identifier
hi def link pengusArrowField           Identifier
hi def link pengusDelimiter            Delimiter

let b:current_syntax = "pengus"
