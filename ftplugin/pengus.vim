" ftplugin/pengus.vim
" Opciones por buffer para archivos PenguScript (filetype pengus).
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Comentarios: `#` normal y `##` documentación (`pengu doc`, hover del LSP).
setlocal commentstring=#\ %s
setlocal comments=:##,:#

" Formato de texto: sin auto-wrap, con continuación de comentarios y `gq`.
setlocal formatoptions-=t
setlocal formatoptions+=croql

" Convención oficial de PenguScript: 4 espacios, nunca tabuladores.
" `.pengufmt.toml` usa `tab_size = 4`, `pengu fmt` es idempotente con esa
" configuración y la guía de estilo la exige (§3.1, §15).
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal tabstop=4
setlocal expandtab

" Ayuda a `gf` para resolver módulos .pengu y archivos de binding .d.pengu.
setlocal suffixesadd+=.pengu,.d.pengu

" Compilación nativa con :make y parseo de diagnósticos de PenguScript
setlocal makeprg=pengu\ build
setlocal errorformat=\ \ \ %f:%l:%c\ [%t%n]\ %m,%f:%l:%c:\ %m,%-G%.%#

let b:undo_ftplugin = "setlocal commentstring< comments< formatoptions< shiftwidth< softtabstop< tabstop< expandtab< suffixesadd< makeprg< errorformat<"
