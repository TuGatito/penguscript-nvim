--- pengus
-- Punto de entrada del plugin PenguScript para Neovim.
--
-- Uso básico:
--   require("pengus").setup {
--     bin_path = "C:/herramientas/pengu.exe", -- opcional
--     format_on_save = true,                  -- opcional
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

--- API de comandos programáticos (equivalentes Lua de :Pengu*).
-- Aceptan una tabla de argumentos o varargs:
--   require("pengus").build()            -- pengu build
--   require("pengus").run({ "main.pengu" })
function M.build(...)
  return require("pengus.commands").build(...)
end

function M.run(...)
  return require("pengus.commands").run(...)
end

function M.check(...)
  return require("pengus.commands").check(...)
end

function M.format(...)
  return require("pengus.commands").format(...)
end

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
