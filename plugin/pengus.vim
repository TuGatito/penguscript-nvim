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
" Compilación, ejecución y diagnóstico
" ---------------------------------------------------------------------------

" Compila el proyecto (pengu build [args...])
command! -nargs=* -complete=file PenguBuild lua require("pengus.commands").build(<f-args>)

" Ejecuta el proyecto o un script (pengu run [script] [args...]) en una terminal
command! -nargs=* -complete=file PenguRun lua require("pengus.commands").run(<f-args>)

" Comprueba los tipos del proyecto (pengu check [args...]) en la quickfix
command! -nargs=* -complete=file PenguCheck lua require("pengus.commands").check(<f-args>)

" Ejecuta los tests del proyecto (pengu test [args...]) en la quickfix
command! -nargs=* -complete=file PenguTest lua require("pengus.commands").test(<f-args>)

" Ejecuta los tests de forma continua ante cambios (pengu test --watch) en una terminal
command! -nargs=* -complete=file PenguTestWatch lua require("pengus.commands").test_watch(<f-args>)

" Reejecuta al cambiar cualquier fuente (pengu watch [script]) en una terminal
command! -nargs=* -complete=file PenguWatch lua require("pengus.commands").watch(<f-args>)

" Compila y ejecuta un script mostrando los tiempos por fase
command! -nargs=* -complete=file PenguTime lua require("pengus.commands").time(<f-args>)

" Evalúa una expresión de PenguScript (pengu eval "EXPR")
command! -nargs=* PenguEval lua require("pengus.commands").eval(<f-args>)

" Imprime el C generado por `pengu expand` en un split
command! -nargs=* -complete=file PenguExpand lua require("pengus.commands").expand(<f-args>)

" ---------------------------------------------------------------------------
" Formato, documentación, bindings y assets
" ---------------------------------------------------------------------------

" Formatea el archivo actual (pengu fmt --stdin [args...])
command! -nargs=* PenguFmt lua require("pengus.commands").format(<f-args>)

" Genera la documentación Markdown del proyecto (pengu doc)
command! -nargs=* -complete=file PenguDoc lua require("pengus.commands").doc(<f-args>)

" Genera un binding .d.pengu desde cabeceras de C (pengu bind)
command! -nargs=* -complete=file PenguBind lua require("pengus.commands").bind(<f-args>)

" Inspecciona o regenera los assets embebidos (pengu assets [--list])
command! -nargs=* PenguAssets lua require("pengus.commands").assets(<f-args>)

" Ejecuta el arnés de benchmarks (pengu benchmark)
command! -nargs=* PenguBench lua require("pengus.commands").benchmark(<f-args>)

" ---------------------------------------------------------------------------
" Proyecto y mantenimiento
" ---------------------------------------------------------------------------

" Crea un proyecto nuevo (pengu init <name>)
command! -nargs=* PenguInit lua require("pengus.commands").init(<f-args>)

" Instala un módulo o binding externo (pengu add <url>)
command! -nargs=* PenguAdd lua require("pengus.commands").add(<f-args>)

" Actualiza las dependencias del proyecto (pengu update)
command! -nargs=* PenguUpdate lua require("pengus.commands").update(<f-args>)

" Limpia el directorio build/ y las cachés (pengu clean)
command! -nargs=* PenguClean lua require("pengus.commands").clean(<f-args>)

" Recoge los binarios de script en caché (pengu gc)
command! -nargs=* PenguGc lua require("pengus.commands").gc(<f-args>)

" Diagnóstico del toolchain y del proyecto (pengu doctor)
command! -nargs=* PenguDoctor lua require("pengus.commands").doctor(<f-args>)

" Muestra la versión del toolchain (pengu -V)
command! -nargs=0 PenguVersion lua require("pengus.commands").version()

" ---------------------------------------------------------------------------
" LSP
" ---------------------------------------------------------------------------

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
