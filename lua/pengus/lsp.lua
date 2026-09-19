--- pengus.lsp
-- Configuración del servidor LSP de PenguScript:
--   * registra el servidor `pengus` en lspconfig.configs (si nvim-lspconfig
--     está instalado) para integración con `:LspInfo` y flujos gestionados
--     por lspconfig;
--   * arranca el cliente por su cuenta (`pengu lsp --stdio`) usando la raíz
--     del proyecto detectada con root_pattern, sin depender de ningún plugin
--     externo (compatible con Neovim 0.8+, con `vim.lsp.start` en 0.11+).
local M = {}

local config = require("pengus.config")
local util = require("pengus.util")

local function cfg()
  return config.get()
end

--- Nombre del servidor LSP.
function M.server_name()
  return cfg().lsp.name or "pengus"
end

--- Lista de argumentos que convierten `pengu` en servidor LSP.
function M.get_cmd()
  local c = cfg()
  local cmd = { util.resolve_bin(c) }
  local args = c.lsp.args or { "lsp", "--stdio" }
  for _, a in ipairs(args) do
    table.insert(cmd, a)
  end
  return cmd
end

--------------------------------------------------------------------------------
-- Raíz del proyecto (root_pattern)
--------------------------------------------------------------------------------

--- Busca la raíz del proyecto a partir de una ruta de archivo.
function M.root_for(fname)
  local c = cfg()
  return util.root_pattern(fname, c.root_markers or {})
end

--- Busca la raíz del proyecto para un buffer (usa el cwd si no tiene nombre).
function M.find_root(bufnr)
  local path = util.buffer_path(bufnr)
  if path then
    local root = M.root_for(path)
    if root then
      return root
    end
    -- Sin marcadores: usamos el directorio del propio archivo.
    return vim.fn.fnamemodify(path, ":p:h")
  end
  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local root = M.root_for(cwd .. "/__pengus__.pengu")
  return root or cwd
end

--------------------------------------------------------------------------------
-- Clientes activos
--------------------------------------------------------------------------------

--- Clientes `pengus` (opcionalmente solo los adjuntos a `bufnr`).
function M.active_clients(bufnr)
  local name = M.server_name()
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  local clients = get_clients()
  local out = {}
  for _, cl in ipairs(clients) do
    if cl.name == name then
      local attached = false
      if bufnr ~= nil then
        local ab = cl.attached_buffers
        if type(ab) == "table" then
          if ab[bufnr] then
            attached = true
          elseif vim.tbl_contains(ab, bufnr) then
            attached = true -- versiones antiguas guardaban una lista
          end
        end
      else
        attached = true
      end
      if attached then
        table.insert(out, cl)
      end
    end
  end
  return out
end

--------------------------------------------------------------------------------
-- Capacidades del cliente
--------------------------------------------------------------------------------

local function make_capabilities(user_caps)
  if user_caps then
    return user_caps
  end
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  if ok and type(cmp.default_capabilities) == "function" then
    caps = cmp.default_capabilities()
  end
  return caps
end

--------------------------------------------------------------------------------
-- Arranque del cliente
--------------------------------------------------------------------------------

local function build_config(bufnr, root)
  local c = cfg()
  return {
    name = M.server_name(),
    cmd = M.get_cmd(),
    root_dir = root,
    cmd_cwd = root,
    capabilities = make_capabilities(c.lsp.capabilities),
    settings = c.lsp.settings or {},
    flags = c.lsp.flags or { debounce_text_changes = 150 },
    env = c.lsp.env,
    handlers = c.lsp.handlers,
    on_attach = function(client, b)
      -- Utilidades por buffer cuando el servidor las anuncia.
      local caps = client.server_capabilities or {}
      if caps.completionProvider then
        vim.bo[b].omnifunc = "v:lua.vim.lsp.omnifunc"
      end
      if caps.hoverProvider and vim.bo[b].tagfunc == "" then
        vim.bo[b].tagfunc = "v:lua.vim.lsp.tagfunc"
      end
      -- Callback del usuario.
      if type(c.lsp.on_attach) == "function" then
        local ok, err = pcall(c.lsp.on_attach, client, b)
        if not ok then
          util.notify("error en on_attach: " .. tostring(err), vim.log.levels.ERROR)
        end
      end
    end,
  }
end

--- Arranca el LSP para `bufnr` si procede (filetype correcto, auto_attach,
-- binario disponible y ningún cliente `pengus` ya adjunto).
-- Devuelve el id del cliente o nil.
function M.maybe_start(bufnr)
  local c = cfg()
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  if not c.auto_attach then
    return nil
  end
  local ft = vim.bo[bufnr].filetype
  if not vim.tbl_contains(c.filetypes or { "pengus" }, ft) then
    return nil
  end
  if #M.active_clients(bufnr) > 0 then
    return nil -- ya hay un servidor adjunto a este buffer
  end

  local bin = util.resolve_bin(c)
  if not util.bin_available(bin) then
    util.notify_once(
      "binario",
      "Binario `" .. bin .. "` no encontrado. Instala PenguScript o configura "
        .. "vim.g.pengus_bin_path (o $PENGU_BIN_PATH).",
      vim.log.levels.ERROR
    )
    return nil
  end

  local root = M.find_root(bufnr)
  local client_config = build_config(bufnr, root)
  local client_id

  if vim.lsp.start then
    -- Neovim 0.11+: vim.lsp.start adjunta automáticamente al buffer.
    client_id = vim.lsp.start(client_config, { bufnr = bufnr })
  else
    -- Neovim 0.8–0.10: arranque + adjuntado manual.
    client_id = vim.lsp.start_client(client_config)
    if client_id and client_id > 0 then
      local ok, err = pcall(vim.lsp.buf_attach_client, bufnr, client_id)
      if not ok then
        util.notify(
          "No se pudo adjuntar el cliente LSP: " .. tostring(err),
          vim.log.levels.ERROR
        )
        pcall(vim.lsp.stop_client, client_id)
        return nil
      end
    end
  end

  return client_id
end

--------------------------------------------------------------------------------
-- Registro en lspconfig (integración opcional)
--------------------------------------------------------------------------------

local owned_entry = false

--- Registra `pengus` en lspconfig.configs cuando nvim-lspconfig existe.
-- Si el usuario (u otro plugin) ya registró el servidor, se respeta su entrada.
--
-- Nota: se importa el submódulo "lspconfig.configs" directamente. Acceder a
-- `require("lspconfig").configs` dispara la metatabla del módulo raíz, que lo
-- interpreta como un servidor desconocido y emite el aviso
-- `config "configs" not found`.
function M.register_lspconfig()
  local c = cfg()
  if c.register_lspconfig == false then
    return
  end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    return
  end
  local ok_configs, configs = pcall(require, "lspconfig.configs")
  if not ok_configs or type(configs) ~= "table" then
    return
  end
  if not owned_entry and configs.pengus then
    return -- ya registrado por el usuario/terceros: no pisamos su entrada
  end
  local fts = {}
  for _, f in ipairs(c.filetypes or { "pengus" }) do
    table.insert(fts, f)
  end
  configs.pengus = {
    default_config = {
      name = M.server_name(),
      cmd = M.get_cmd(),
      filetypes = fts,
      root_dir = function(fname)
        return M.root_for(fname)
      end,
      settings = c.lsp.settings or {},
      flags = c.lsp.flags or { debounce_text_changes = 150 },
    },
    docs = {
      description = "Servidor LSP de PenguScript (`pengu lsp --stdio`). "
        .. "Registrado automáticamente por penguscript-nvim.",
      default_config = {
        root_dir = [[root_pattern("pengu.yaml", "pengu.toml", "Pengu.toml", ".git")]],
      },
    },
  }
  owned_entry = true
end

--------------------------------------------------------------------------------
-- setup() / comandos
--------------------------------------------------------------------------------

--- Registra los autocomandos y la entrada de lspconfig. Puede llamarse varias
-- veces (plugin/pengus.vim al cargar y `setup()` del usuario); cada llamada
-- re-lee la configuración efectiva.
function M.setup()
  local c = cfg()
  local group = vim.api.nvim_create_augroup("pengus_lsp", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = c.filetypes or { "pengus" },
    callback = function(args)
      M.maybe_start(args.buf)
    end,
  })
  M.register_lspconfig()
end

--- Arranca el LSP para el buffer actual (usado por :PenguLspStart y por el
-- reinicio manual cuando no hay ningún cliente activo).
function M.start_current()
  local buf = vim.api.nvim_get_current_buf()
  if #M.active_clients(buf) > 0 then
    return nil
  end
  -- Forzar arranque aunque auto_attach esté desactivado: temporalmente
  -- habilitamos auto_attach para esta llamada.
  local c = cfg()
  local prev = c.auto_attach
  c.auto_attach = true
  local id = M.maybe_start(buf)
  c.auto_attach = prev
  return id
end

--- Reinicia el servidor LSP del buffer actual.
function M.restart()
  local buf = vim.api.nvim_get_current_buf()
  local clients = M.active_clients(buf)
  if #clients == 0 then
    M.start_current()
    util.notify("No había servidor activo; LSP iniciado para el buffer actual.")
    return
  end
  for _, cl in ipairs(clients) do
    pcall(vim.lsp.stop_client, cl.id)
  end
  util.notify("Reiniciando servidor LSP de PenguScript…")
  -- Esperamos a que el cliente termine de pararse antes de relanzar.
  local attempts = 0
  local function try_start()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    attempts = attempts + 1
    local ok = M.start_current()
    if not ok and attempts < 8 then
      vim.defer_fn(try_start, 150)
    end
  end
  vim.defer_fn(try_start, 150)
end

--- Abre el archivo de log del LSP (aplicando `lsp.log_level` si se configuró).
function M.open_log()
  local c = cfg()
  if c.lsp.log_level then
    vim.lsp.set_log_level(c.lsp.log_level)
  end
  local log = vim.lsp.get_log_path()
  vim.cmd("botright split")
  vim.cmd("edit " .. vim.fn.fnameescape(log))
end

return M
