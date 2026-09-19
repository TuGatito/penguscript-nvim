--- pengus.config
-- Configuración central del plugin. `setup(opts)` mezcla los valores del
-- usuario sobre los valores por defecto. Todo el plugin lee la configuración
-- a través de `get()`, por lo que `setup()` puede llamarse en cualquier
-- momento (por ejemplo, dentro de la función `config` de Lazy.nvim).
local M = {}

local defaults = {
  --- Ruta al binario `pengu`.
  -- Si es `nil` se resuelve en este orden:
  --   1. vim.g.pengus_bin_path
  --   2. $PENGU_BIN_PATH
  --   3. "pengu" (búsqueda en $PATH)
  bin_path = nil,

  --- Filetypes a los que el plugin aplica (LSP, autocomandos, etc.).
  filetypes = { "pengus" },

  --- Arranca el LSP automáticamente al abrir un archivo PenguScript.
  auto_attach = true,

  --- Registra el servidor `pengus` en `lspconfig.configs` cuando
  -- nvim-lspconfig está disponible (integración con `:LspInfo`,
  -- `:LspInstallInfo`, etc.).
  register_lspconfig = true,

  --- Marcadores usados para localizar la raíz del proyecto (root_pattern).
  -- Se buscan de abajo hacia arriba desde el directorio del buffer.
  root_markers = {
    "pengu.yaml",
    "pengu.yml",
    "pengu.toml",
    "Pengu.toml",
    ".git",
  },

  lsp = {
    --- Nombre del servidor LSP (cliente Neovim).
    name = "pengus",
    --- Argumentos que recibe el binario para actuar como servidor LSP.
    args = { "lsp", "--stdio" },
    --- Ajustes del servidor (sección `settings` de initializationOptions).
    settings = {},
    --- Controladores de mensajes adicionales (handlers LSP).
    handlers = nil,
    --- Función `on_attach(client, bufnr)` del usuario (se llama al final del
    -- on_attach interno). También se acepta `opts.on_attach`.
    on_attach = nil,
    --- Capacidades del cliente. Si es `nil` se generan automáticamente
    -- (y se amplían con cmp-nvim-lsp si está instalado). También se acepta
    -- `opts.capabilities`.
    capabilities = nil,
    --- flags del cliente (p. ej. debounce de cambios de texto).
    flags = { debounce_text_changes = 150 },
    --- Variables de entorno adicionales para el proceso del servidor.
    env = nil,
    --- Nivel de log del LSP que aplicará `:PenguLspLog` (opcional).
    log_level = nil,
  },

  commands = {
    --- Directorio donde se ejecutan `build`/`check`/`run`:
    --   "project" -> raíz del proyecto del buffer actual
    --   "buffer"  -> directorio del archivo actual
    --   "cwd"     -> directorio actual de Neovim
    cwd = "cwd",
    run = {
      split = "botright", -- "botright" | "topleft" | "vnew" | "new"
      size = 15, -- altura (o ancho si split es vertical)
      args = nil, -- argumentos extra por defecto, p. ej. { "-v" }
    },
    build = { args = nil }, -- argumentos extra por defecto para build
    check = { args = nil }, -- argumentos extra por defecto para check
    test = { args = nil }, -- argumentos extra por defecto para test
    fmt = { args = nil }, -- argumentos extra por defecto para fmt
  },

  --- Formatea al guardar (opcional). `false` desactiva; `true` o una tabla
  -- `{ args = { ... } }` lo activa (los args se añaden tras `pengu fmt`).
  format_on_save = false,
  --- Timeout (ms) para el formateo síncrono al guardar.
  format_on_save_timeout = 30000,

  highlight = {
    --- Uso de Treesitter cuando exista un parser `pengus`:
    --   true | false | "auto"
    treesitter = "auto",
    --- Sobrescrituras de grupos de resaltado:
    --   colors = { PengusKeyword = { fg = "#c586c0", bold = true } }
    --   colors = { PengusKeyword = "Keyword" }   -- enlazar a otro grupo
    colors = {},
  },

  --- Registra snippets (weave, rune, if, for, ...) en LuaSnip si está
  -- instalado. Con Neovim 0.10+ los snippets también se pueden consultar
  -- mediante `vim.snippet` si usas una fuente que los provea.
  snippets = true,

  --- Emite avisos mediante `vim.notify`.
  notify = true,
}

--- Copia profunda simple (solo tablas; suficiente para estos valores).
local function copy(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = copy(v)
  end
  return out
end

--- Acepta atajos cómodos en el nivel superior de `opts`.
local function normalize(opts)
  opts = vim.deepcopy(opts)
  if not opts.lsp then
    opts.lsp = {}
  end
  -- opts.on_attach -> opts.lsp.on_attach
  if opts.on_attach ~= nil then
    opts.lsp.on_attach = opts.lsp.on_attach or opts.on_attach
    opts.on_attach = nil
  end
  -- opts.capabilities -> opts.lsp.capabilities
  if opts.capabilities ~= nil then
    opts.lsp.capabilities = opts.lsp.capabilities or opts.capabilities
    opts.capabilities = nil
  end
  -- opts.settings -> opts.lsp.settings
  if opts.settings ~= nil then
    opts.lsp.settings = opts.lsp.settings or opts.settings
    opts.settings = nil
  end
  return opts
end

--- Aplica la configuración del usuario. Se puede llamar varias veces.
function M.setup(opts)
  local user = normalize(opts or {})
  M.values = vim.tbl_deep_extend("force", copy(defaults), user)
  return M.values
end

--- Devuelve la configuración efectiva (por defecto si no hubo setup()).
function M.get()
  if M.values then
    return M.values
  end
  return defaults
end

return M
