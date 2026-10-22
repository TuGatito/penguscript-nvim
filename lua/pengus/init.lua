--- pengus
-- Punto de entrada del plugin PenguScript para Neovim.
--
-- Uso básico:
--   require("pengus").setup {
--     bin_path = "/ruta/a/pengu",   -- opcional
--     format_on_save = true,        -- opcional
--     lsp = {
--       on_attach = function(client, bufnr) ... end,
--     },
--   }
--
-- Registra (al cargar) la detección de filetype para .pengu / .d.pengu y, en
-- setup(), los autocomandos de LSP, comandos y formateo al guardar.
local M = {}

-- Detección de filetype moderna (Neovim 0.7+): el patrón `pengu` cubre tanto
-- `.pengu` como `.d.pengu`. Complementa a ftdetect/pengus.vim.
vim.filetype.add({
  extension = {
    pengu = "pengus",
  },
})

local function setup_submodules()
  local config = require("pengus.config")
  local c = config.get()

  require("pengus.lsp").setup()
  require("pengus.commands").setup()
  require("pengus.highlights").setup(c)
  require("pengus.snippets").setup(c)
end

--- Configura el plugin. Puede llamarse varias veces (p. ej. para recargar
-- opciones en caliente); cada llamada re-lee la configuración.
function M.setup(opts)
  require("pengus.config").setup(opts or {})
  setup_submodules()
  return M
end

--- Configuración efectiva actual.
function M.config()
  return require("pengus.config").get()
end

--------------------------------------------------------------------------------
-- API programática (equivalentes Lua de los comandos :Pengu*)
--
-- Todas aceptan una tabla de argumentos o varargs:
--   require("pengus").build()                     -- pengu build
--   require("pengus").run({ "main.pengu", "-v" }) -- pengu run main.pengu -v
--------------------------------------------------------------------------------

local function cmd(name)
  return function(...)
    return require("pengus.commands")[name](...)
  end
end

--- Compila el proyecto (`pengu build`).
M.build = cmd("build")
--- Comprueba los tipos (`pengu check`).
M.check = cmd("check")
--- Ejecuta los tests (`pengu test`).
M.test = cmd("test")
--- Ejecuta los tests de forma continua ante cambios (`pengu test --watch`).
M.test_watch = cmd("test_watch")
--- Ejecuta el proyecto o un script en una terminal (`pengu run`).
M.run = cmd("run")
--- Reejecuta al cambiar fuentes (`pengu watch`).
M.watch = cmd("watch")
--- Compila y ejecuta mostrando los tiempos por fase (`pengu time`).
M.time = cmd("time")
--- Evalúa una expresión (`pengu eval`).
M.eval = cmd("eval")
--- Muestra el C generado en un split (`pengu expand`).
M.expand = cmd("expand")
--- Formatea el buffer actual (`pengu fmt --stdin`).
M.format = cmd("format")
--- Genera la documentación Markdown (`pengu doc`).
M.doc = cmd("doc")
--- Genera un binding `.d.pengu` desde una cabecera de C (`pengu bind`).
M.bind = cmd("bind")
--- Inspecciona o regenera los assets embebidos (`pengu assets`).
M.assets = cmd("assets")
--- Ejecuta el arnés de benchmarks (`pengu benchmark`).
M.benchmark = cmd("benchmark")
--- Crea un proyecto nuevo (`pengu init`).
M.init = cmd("init")
--- Instala un módulo o binding externo (`pengu add`).
M.add = cmd("add")
--- Actualiza las dependencias (`pengu update`).
M.update = cmd("update")
--- Limpia `build/` y las cachés (`pengu clean`).
M.clean = cmd("clean")
--- Recoge los binarios de script en caché (`pengu gc`).
M.gc = cmd("gc")
--- Diagnóstico del toolchain y del proyecto (`pengu doctor`).
M.doctor = cmd("doctor")
--- Versión del toolchain (`pengu -V`).
M.version = cmd("version")

--- Reinicia / inicia el servidor LSP (equivalente a :PenguLspRestart).
function M.restart()
  return require("pengus.lsp").restart()
end

--- Abre el log del LSP (equivalente a :PenguLspLog).
function M.open_log()
  return require("pengus.lsp").open_log()
end

--- Acceso perezoso al submódulo lsp (require("pengus.lsp")).
M.lsp = setmetatable({}, {
  __index = function(_, k)
    return require("pengus.lsp")[k]
  end,
})

return M
