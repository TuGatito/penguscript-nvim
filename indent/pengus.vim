" indent/pengus.vim
" Cálculo de sangría automática para PenguScript 2.0.x (lenguaje sensible a la
" indentación).
" Idioma: PenguScript
" Mantenedor: TuGatito <53541345+TuGatito@users.noreply.github.com>
" Licencia: MIT
"
" Bloques que abren un nivel: cualquier línea que termina en `:` (weave, rune,
" echo, omen, concept, bind, enchanting, if/else, while, for, judge, test,
" with:, do:, or:, unsafe:, antiquus, literales indentados, ...).
" Ramas que se alinean con su cadena: `else`, `else when`, `else ->`, `when`
" (ramas de `judge` y de `when` de comptime) y `or:`.

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal autoindent
setlocal indentexpr=GetPengusIndent()
setlocal indentkeys+=<:>,0=else:,0=else\ ->,0=else\ when,0=when\ ,0=or:,0=.,0=->

let b:undo_indent = "setlocal autoindent< indentexpr< indentkeys<"

if exists("*GetPengusIndent")
  finish
endif

" ---------------------------------------------------------------------------
" Utilidades
" ---------------------------------------------------------------------------

" Devuelve la línea sin comentario de fin de línea y sin espacios finales.
" El `#` final solo se elimina si está fuera de una cadena `"..."`.
" El camino rápido (la inmensa mayoría de las líneas no llevan `#`) evita el
" recorrido carácter a carácter.
function! s:Clean(line)
  if stridx(a:line, '#') < 0
    return substitute(a:line, '\s\+$', '', '')
  endif

  let l:out = ''
  let l:in_str = 0
  let l:i = 0
  let l:len = strlen(a:line)
  while l:i < l:len
    let l:c = a:line[l:i]
    if l:in_str
      let l:out .= l:c
      if l:c ==# '\'
        " conservar también el carácter escapado
        let l:i += 1
        if l:i < l:len
          let l:out .= a:line[l:i]
        endif
      elseif l:c ==# '"'
        let l:in_str = 0
      endif
    elseif l:c ==# '"'
      let l:in_str = 1
      let l:out .= l:c
    elseif l:c ==# '#'
      break
    else
      let l:out .= l:c
    endif
    let l:i += 1
  endwhile
  return substitute(l:out, '\s\+$', '', '')
endfunction

" ¿La línea `lnum` está dentro de un literal triple (`"""` / `r"""`)?
" El contenido es literal (cuerpos `antiquus`, shaders), así que se deja a
" columna 0, como exige la guía de estilo.
"
" Cuando el resaltado de sintaxis de este plugin está activo se pregunta al
" motor de sintaxis, que ya sabe en qué región está cada línea: es exacto y
" barato. La línea que ABRE el literal no está dentro de la región, así que se
" indenta con la regla normal; las interiores y la de cierre sí lo están y van
" a columna 0.
"
" Si no hay sintaxis activa (p. ej. con Treesitter), se aproxima contando la
" paridad de `"""` en una ventana hacia atrás.
function! s:InTripleString(lnum)
  if exists('b:current_syntax') && has('syntax_items')
    let l:name = synIDattr(synID(a:lnum, 1, 1), 'name')
    if l:name =~# 'TripleString'
      return 1
    endif
    if b:current_syntax ==# 'pengus'
      return 0
    endif
  endif
  return s:InTripleStringWindow(a:lnum, 60)
endfunction

" Aproximación sin sintaxis: paridad de `"""` en las últimas `budget` líneas.
function! s:InTripleStringWindow(lnum, budget)
  let l:last = a:lnum - 1
  if l:last < 1
    return 0
  endif
  let l:first = l:last - a:budget
  if l:first < 1
    let l:first = 1
  endif

  let l:count = 0
  for l:line in getline(l:first, l:last)
    " Los comentarios no abren ni cierran literales.
    if l:line =~# '^\s*#'
      continue
    endif
    let l:idx = 0
    while 1
      let l:idx = stridx(l:line, '"""', l:idx)
      if l:idx < 0
        break
      endif
      let l:count += 1
      let l:idx += 3
    endwhile
  endfor
  return l:count % 2 == 1
endfunction

" ¿La línea limpia es una rama que se alinea con su cadena?
function! s:IsBranch(curclean)
  return a:curclean =~# '^\%(else\>\|when\>\|or\s*:\)'
endfunction

" Indentación de la cadena a la que pertenece una rama (`when ... ->`,
" `else ...`): la de su hermano `when`/`else` más cercano o, si no lo hay, la
" del abridor de bloque con menor indentación (acotado por budget para archivos largos).
function! s:ChainIndent(prevlnum)
  " Primera rama justo después del abridor (`judge x:`, `when ...:`, `if ...:`).
  if s:Clean(getline(a:prevlnum)) =~# ':\s*$'
    return indent(a:prevlnum) + shiftwidth()
  endif
  let l:base = indent(a:prevlnum)
  let l:lnum = a:prevlnum
  let l:budget = 80
  while l:lnum > 0 && l:budget > 0
    let l:budget -= 1
    let l:text = substitute(s:Clean(getline(l:lnum)), '^\s*', '', '')
    if l:text =~# '^\%(when\|else\)\>'
      return indent(l:lnum)
    endif
    if indent(l:lnum) < l:base
      return indent(l:lnum)
    endif
    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
  return l:base
endfunction

" Indentación de la línea que abre una cadena de métodos: se retrocede por las
" líneas de continuación (las que empiezan por `.` o `->`) hasta el receptor
" (acotado por budget para evitar bloqueos en buffers grandes).
function! s:ChainBaseIndent(prevlnum)
  let l:lnum = a:prevlnum
  let l:budget = 80
  while l:lnum > 0 && l:budget > 0
    let l:budget -= 1
    let l:text = substitute(s:Clean(getline(l:lnum)), '^\s*', '', '')
    if l:text !~# '^\%(\.\|->\)'
      return indent(l:lnum)
    endif
    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
  return 0
endfunction

" ---------------------------------------------------------------------------
" indentexpr
" ---------------------------------------------------------------------------

function! GetPengusIndent()
  let l:curlnum = v:lnum
  let l:curclean = substitute(getline(l:curlnum), '^\s*', '', '')

  " Dentro de un literal triple: contenido literal a columna 0.
  if s:InTripleString(l:curlnum)
    return 0
  endif

  let l:prevlnum = prevnonblank(l:curlnum - 1)
  if l:prevlnum == 0
    return 0
  endif

  " Continuación de una cadena de métodos: un nivel más que la cadena.
  if l:curclean =~# '^\%(\.\|->\)'
    return s:ChainBaseIndent(l:prevlnum) + shiftwidth()
  endif

  " Ramas (`else`, `when`, `or:`): alineadas con su cadena.
  if s:IsBranch(l:curclean)
    return s:ChainIndent(l:prevlnum)
  endif

  let l:prevclean = s:Clean(getline(l:prevlnum))

  " Regla general: si la línea anterior abre un bloque (`:` final) o una rama
  " de `judge` sin cuerpo en la misma línea (`when ... ->` / `else ->`), un
  " nivel más.
  if l:prevclean =~# '\%(:\|->\)\s*$'
    return indent(l:prevlnum) + shiftwidth()
  endif

  " Salida de una función o de un bucle: se sugiere desangrar un nivel, salvo
  " que la línea ya esté desangrada (entonces manda el usuario).
  if l:prevclean =~# '^\s*\%(return\|break\|continue\)\>'
    let l:after = indent(l:prevlnum) - shiftwidth()
    if indent(l:curlnum) <= l:after
      return -1
    endif
    return l:after < 0 ? 0 : l:after
  endif

  " Si la línea ya está desangrada respecto de la anterior, se respeta: el
  " bloque anterior ha terminado. Esto hace que `=` sea idempotente sobre
  " código ya bien indentado y que un desangrado manual sobreviva.
  let l:ind = indent(l:prevlnum)
  if indent(l:curlnum) < l:ind
    return -1
  endif

  return l:ind < 0 ? 0 : l:ind
endfunction
