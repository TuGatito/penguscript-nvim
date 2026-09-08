" ftplugin/pengus.vim
" Opciones por buffer para archivos PenguScript (filetype pengus).
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Comentarios: `#` para comentarios normales y `##` para documentación.
setlocal commentstring=#\ %s
setlocal comments=:##,:#

" Ayuda a gf / include para resolver archivos .pengu
setlocal suffixesadd+=.pengu,.d.pengu

let b:undo_ftplugin = "setlocal commentstring< comments< suffixesadd<"
