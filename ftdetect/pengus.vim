" ftdetect/pengus.vim
" Detección clásica de filetype para PenguScript.
" Complementaria a vim.filetype.add() (cargada desde lua/pengus/init.lua);
" ambos mecanismos conviven sin conflicto y esto garantiza la detección en
" cualquier Neovim 0.8+.
augroup pengus_ftdetect
  autocmd!
  autocmd BufRead,BufNewFile *.pengu,*.d.pengu setfiletype pengus
augroup END
