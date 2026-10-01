" indent/pengus.vim
" Cálculo de sangría automática para PenguScript (lenguaje sensible a la indentación).
" Idioma: PenguScript
" Mantenedor: TuGatito <53541345+TuGatito@users.noreply.github.com>
" Licencia: MIT

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal autoindent
setlocal indentexpr=GetPengusIndent()
setlocal indentkeys+=<:>,0=else:,0=else\ ->,0=else\ when,0=when\ 

let b:undo_indent = "setlocal autoindent< indentexpr< indentkeys<"

if exists("*GetPengusIndent")
  finish
endif

function! GetPengusIndent()
  let l:prevlnum = prevnonblank(v:lnum - 1)
  if l:prevlnum == 0
    return 0
  endif

  let l:prevline = getline(l:prevlnum)
  let l:curline = getline(v:lnum)
  let l:ind = indent(l:prevlnum)

  " Quitar comentarios de fin de línea de la línea previa
  let l:prevclean = substitute(l:prevline, '#.*$', '', '')
  let l:prevclean = substitute(l:prevclean, '\s\+$', '', '')

  " Si la línea anterior termina en ':' (abre un bloque: weave, if, else, while, for, rune, with, etc.)
  if l:prevclean =~ ':\s*$'
    let l:ind += shiftwidth()
  endif

  " Si la línea actual es 'else:', 'else ->', 'else when ...', o 'when ...', reducir sangría
  let l:curclean = substitute(l:curline, '^\s*', '', '')
  if l:curclean =~ '^\%(else:\|else\s*->\|else\s\+when\|when\s\+\)'
    let l:ind -= shiftwidth()
  endif

  return l:ind < 0 ? 0 : l:ind
endfunction
