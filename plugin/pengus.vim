" plugin/pengus.vim
" Carga automática: define los comandos :Pengu* y activa los autocomandos del
" plugin (LSP + Treesitter + formateo opcional) al arrancar Neovim, incluso si
" el usuario nunca llama a require("pengus").setup() (en ese caso se usan los
" valores por defecto).
if exists("g:loaded_pengus_plugin")
  finish
endif
let g:loaded_pengus_plugin = 1

" ---------------------------------------------------------------------------
" Comandos del usuario
" ---------------------------------------------------------------------------

" Compila el proyecto (pengu build [args...])
command! -nargs=* PenguBuild lua require("pengus.commands").build(<f-args>)

" Ejecuta el proyecto/archivo (pengu run [args...]) en una terminal
command! -nargs=* PenguRun lua require("pengus.commands").run(<f-args>)

" Comprueba el proyecto y muestra el resultado en la quickfix
command! -nargs=* PenguCheck lua require("pengus.commands").check(<f-args>)

" Formatea el archivo actual (pengu fmt [args...])
command! -nargs=* PenguFmt lua require("pengus.commands").format(<f-args>)

" Inicia el servidor LSP en el buffer actual
command! -nargs=0 PenguLspStart lua require("pengus.lsp").start_current()

" Reinicia el servidor LSP
command! -nargs=0 PenguLspRestart lua require("pengus.lsp").restart()

" Abre el log del LSP
command! -nargs=0 PenguLspLog lua require("pengus.lsp").open_log()

" ---------------------------------------------------------------------------
" Autocomandos (LSP, Treesitter, formato al guardar) con la configuración
" efectiva: si el usuario ejecutó setup() antes, esta llamada reutiliza sus
" opciones; si no, aplica los valores por defecto.
" ---------------------------------------------------------------------------
lua require("pengus.lsp").setup()
lua require("pengus.commands").setup()
lua require("pengus.highlights").setup(require("pengus.config").get())
lua require("pengus.snippets").setup(require("pengus.config").get())
