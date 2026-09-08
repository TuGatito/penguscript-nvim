--- pengus.util
-- Utilidades internas compartidas: notificaciones, resolución del binario,
-- búsqueda de la raíz del proyecto, ejecución de trabajos y lectura/escritura
-- de archivos. No forma parte de la API pública del plugin.
local M = {}

local uv = vim.uv or vim.loop -- vim.uv existe desde 0.10; vim.loop en 0.8/0.9
local is_win = vim.fn.has("win32") == 1

M.is_win = is_win

--------------------------------------------------------------------------------
-- Notificaciones
--------------------------------------------------------------------------------

local function notify_raw(msg, level)
  vim.notify("[pengus] " .. msg, level, { title = "PenguScript" })
end

--- Notifica si la configuración lo permite.
function M.notify(msg, level)
  local cfg = require("pengus.config").get()
  if cfg.notify == false then
    return
  end
  notify_raw(msg, level or vim.log.levels.INFO)
end

--- Notifica una única vez por `key` (evita repetir avisos de binario ausente).
local notified_keys = {}

function M.notify_once(key, msg, level)
  if notified_keys[key] then
    return
  end
  notified_keys[key] = true
  M.notify(msg, level or vim.log.levels.WARN)
end

--------------------------------------------------------------------------------
-- Binario `pengu`
--------------------------------------------------------------------------------

local function path_exists(p)
  return uv.fs_stat(p) ~= nil
end

--- Resuelve la ruta efectiva del binario `pengu`.
function M.resolve_bin(cfg)
  cfg = cfg or require("pengus.config").get()
  local bin = cfg.bin_path
  if not bin or bin == "" then
    bin = vim.g.pengus_bin_path
  end
  if not bin or bin == "" then
    bin = vim.env.PENGU_BIN_PATH
  end
  if not bin or bin == "" then
    bin = "pengu"
  end
  bin = vim.fn.expand(bin)
  -- Windows: si no tiene extensión y `pengu` no está en el PATH pero sí
  -- `pengu.exe`, usamos la variante con extensión.
  if is_win and not bin:match("%.([%w]+)$") then
    if not M.bin_available(bin) and M.bin_available(bin .. ".exe") then
      bin = bin .. ".exe"
    end
  end
  return bin
end

--- ¿Existe el binario indicado (ruta absoluta o ejecutable en el PATH)?
function M.bin_available(bin)
  if not bin or bin == "" then
    return false
  end
  if bin:find("[/\\]") then
    return path_exists(bin)
  end
  if vim.fn.executable(bin) == 1 then
    return true
  end
  if is_win then
    return vim.fn.executable(bin .. ".exe") == 1
  end
  return false
end

--------------------------------------------------------------------------------
-- Rutas y raíz del proyecto
--------------------------------------------------------------------------------

local function join(dir, name)
  if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
    return dir .. name
  end
  return dir .. "/" .. name
end

--- Busca `markers` hacia arriba desde el directorio de `fname`.
-- Devuelve el directorio que contiene el primer marcador encontrado o nil.
function M.root_pattern(fname, markers)
  markers = markers or {}
  if #markers == 0 then
    return nil
  end
  local dir = vim.fn.fnamemodify(fname, ":p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = uv.cwd()
  end
  if not dir then
    return nil
  end
  local steps = 0
  while true do
    for _, m in ipairs(markers) do
      if path_exists(join(dir, m)) then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break -- llegamos a la raíz del sistema de archivos
    end
    dir = parent
    steps = steps + 1
    if steps > 100 then
      break
    end
  end
  return nil
end

--- Directorio del buffer (o el cwd si el buffer no tiene nombre).
function M.buffer_dir(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" then
    return vim.fn.fnamemodify(name, ":p:h")
  end
  return uv.cwd() or vim.fn.getcwd()
end

--- Devuelve la ruta absoluta del buffer o nil.
function M.buffer_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return vim.fn.fnamemodify(name, ":p")
end

--------------------------------------------------------------------------------
-- Archivos
--------------------------------------------------------------------------------

--- Lee un archivo y devuelve sus líneas (sin el separador de fin de línea).
-- Devuelve nil si no se puede leer. Normaliza CRLF.
function M.read_file_lines(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
  local lines = vim.split(content, "\n")
  if lines[#lines] == "" then
    lines[#lines] = nil -- quitar la línea vacía que deja el \n final
  end
  return lines
end

--- Escribe `lines` en un archivo (unión con \n). Devuelve true/false.
function M.write_file_lines(path, lines)
  local content = table.concat(lines, "\n")
  if #lines > 0 then
    content = content .. "\n"
  end
  local f = io.open(path, "wb")
  if not f then
    return false
  end
  f:write(content)
  f:close()
  return true
end

--------------------------------------------------------------------------------
-- Ejecución de trabajos
--------------------------------------------------------------------------------

--- Ejecuta `cmd` (lista) recogiendo stdout+stderr en `lines`.
-- Devuelve el job id (nil si no pudo arrancar). `on_exit(lines, code)` se
-- invoca al terminar; `on_error(job_id)` si el arranque falló.
function M.job(cmd, opts)
  opts = opts or {}
  local lines = {}
  local function collect(_, data)
    if not data then
      return
    end
    for _, l in ipairs(data) do
      if l ~= "" then
        table.insert(lines, l)
      end
    end
  end
  local jobopts = {
    cwd = opts.cwd,
    env = opts.env,
    on_stdout = collect,
    on_stderr = collect,
    on_exit = function(job_id, code)
      if opts.on_exit then
        opts.on_exit(lines, code, job_id)
      end
    end,
  }
  local jid = vim.fn.jobstart(cmd, jobopts)
  if jid <= 0 then
    if opts.on_error then
      opts.on_error(jid)
    end
    return nil
  end
  return jid
end

--- Espera (bloqueando el flujo) a que termine un job.
-- Devuelve el código de salida; -1 si expiró el timeout.
function M.job_wait(jid, timeout_ms)
  local res = vim.fn.jobwait({ jid }, timeout_ms or 30000)
  return res[1]
end

return M
