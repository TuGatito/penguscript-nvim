--- pengus.commands
-- Implementación de los comandos del plugin:
--   :PenguBuild, :PenguRun, :PenguCheck, :PenguFmt
-- y del formateo opcional al guardar (format_on_save).
--
-- Todas las funciones aceptan un número variable de argumentos (igual que
-- <f-args> de Vim) o una única tabla de argumentos si se llaman por API.
local M = {}

local config = require("pengus.config")
local util = require("pengus.util")

local function cfg()
  return config.get()
end

local function notify(msg, level)
  return util.notify(msg, level)
end

--- Normaliza los argumentos: variádicos o una sola tabla.
local function normalize_args(...)
  local n = select("#", ...)
  if n == 1 and type(select(1, ...)) == "table" then
    return select(1, ...)
  end
  local out = {}
  for i = 1, n do
    out[i] = select(i, ...)
  end
  return out
end

--- Añade `tail` al final de la lista `head` (devuelve una lista nueva).
local function append(head, tail)
  local out = {}
  for _, v in ipairs(head or {}) do
    table.insert(out, v)
  end
  for _, v in ipairs(tail or {}) do
    table.insert(out, v)
  end
  return out
end

--- Directorio de trabajo según `commands.cwd` (project|buffer|cwd).
local function work_dir(bufnr)
  local c = cfg()
  local mode = (c.commands and c.commands.cwd) or "cwd"
  if mode == "project" then
    return require("pengus.lsp").find_root(bufnr)
  elseif mode == "buffer" then
    return util.buffer_dir(bufnr)
  end
  return vim.fn.getcwd()
end

--- Resuelve y valida el binario `pengu`; notifica y devuelve nil si falta.
local function get_bin()
  local c = cfg()
  local bin = util.resolve_bin(c)
  if not util.bin_available(bin) then
    notify(
      "Binario `" .. bin
        .. "` no encontrado. Instala PenguScript o configura vim.g.pengus_bin_path "
        .. "($PENGU_BIN_PATH).",
      vim.log.levels.ERROR
    )
    return nil
  end
  return bin
end

--------------------------------------------------------------------------------
-- Ventana quickfix
--------------------------------------------------------------------------------

local function qf_items(lines)
  local items = {}
  for _, l in ipairs(lines or {}) do
    if l ~= "" then
      table.insert(items, { text = l })
    end
  end
  return items
end

local function set_qf(title, items)
  vim.fn.setqflist({}, " ", { title = title, items = items })
end

local function open_qf_if_any(items)
  if #items == 0 then
    return
  end
  vim.cmd("botright copen " .. math.max(2, math.min(#items, 10)))
end

--------------------------------------------------------------------------------
-- Salida de jobs en la quickfix
--------------------------------------------------------------------------------

--- Ejecuta un comando y vuelca su salida en la quickfix.
local function run_to_qf(title, cmd, dir, opts)
  opts = opts or {}
  local jid = util.job(cmd, {
    cwd = dir,
    on_exit = function(lines, code)
      local items = qf_items(lines)
      set_qf(title, items)
      if code == 0 then
        if #items > 0 then
          notify(("`%s` completado con %d aviso(s)."):format(title, #items), vim.log.levels.WARN)
          open_qf_if_any(items)
        else
          notify(("`%s` completado correctamente."):format(title))
        end
        return
      end
      open_qf_if_any(items)
      notify(("`%s` falló (código %d). Salida en la quickfix."):format(title, code), vim.log.levels.ERROR)
      if opts.on_fail then
        opts.on_fail(code)
      end
    end,
    on_error = function()
      notify(("No se pudo ejecutar `%s`."):format(title), vim.log.levels.ERROR)
    end,
  })
  if not jid then
    notify(("No se pudo lanzar `%s`."):format(title), vim.log.levels.ERROR)
  end
  return jid
end

--------------------------------------------------------------------------------
-- :PenguBuild / :PenguCheck
--------------------------------------------------------------------------------

function M.build(...)
  local c = cfg()
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(c.commands.build.args, normalize_args(...))
  local cmd = append({ bin, "build" }, args)
  run_to_qf("pengu build", cmd, work_dir(vim.api.nvim_get_current_buf()))
end

function M.check(...)
  local c = cfg()
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(c.commands.check.args, normalize_args(...))
  local cmd = append({ bin, "check" }, args)
  run_to_qf("pengu check", cmd, work_dir(vim.api.nvim_get_current_buf()))
end

--------------------------------------------------------------------------------
-- :PenguRun (terminal)
--------------------------------------------------------------------------------

function M.run(...)
  local c = cfg()
  local bin = get_bin()
  if not bin then
    return
  end
  local runopts = (c.commands and c.commands.run) or {}
  local args = append(runopts.args, normalize_args(...))
  local cmd = append({ bin, "run" }, args)
  local dir = work_dir(vim.api.nvim_get_current_buf())

  local split = runopts.split or "botright"
  local size = math.max(3, runopts.size or 15)
  local vertical = split == "vnew" or split == "vsplit" or split == "vertical"
  local position = (split == "topleft" or split == "leftabove") and "topleft" or "botright"

  vim.cmd(position .. (vertical and " vnew" or " new"))
  vim.cmd((vertical and "vertical resize " or "resize ") .. size)

  local buf = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_name, buf, "pengu run")
  local pid = vim.fn.termopen(cmd, { cwd = dir })
  if pid == 0 then
    vim.cmd("bwipeout!")
    notify("No se pudo abrir la terminal para `pengu run`.", vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
  return pid
end

--------------------------------------------------------------------------------
-- :PenguFmt
--------------------------------------------------------------------------------

--- Sustituye el contenido del buffer por las líneas del archivo en disco,
-- conservando el cursor cuando el buffer se muestra en la ventana actual.
local function replace_buffer_from_file(bufnr, path)
  local lines = util.read_file_lines(path)
  if not lines then
    return false
  end
  local win = vim.api.nvim_get_current_win()
  local shown = vim.api.nvim_win_get_buf(win) == bufnr
  local view = shown and vim.fn.winsaveview() or nil
  local ok = pcall(vim.api.nvim_buf_call, bufnr, function()
    pcall(vim.cmd, "silent undojoin")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modified = false
  end)
  if ok and view then
    vim.fn.winrestview(view)
  end
  return ok
end

function M.format(...)
  local buf = vim.api.nvim_get_current_buf()
  local file = util.buffer_path(buf)
  if not file then
    notify("El buffer actual no tiene archivo asociado.", vim.log.levels.ERROR)
    return
  end
  if vim.bo[buf].modified then
    notify(
      "El buffer tiene cambios sin guardar: guarda primero con :write y vuelve a ejecutar :PenguFmt.",
      vim.log.levels.WARN
    )
    return
  end
  local c = cfg()
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(c.commands.fmt.args, normalize_args(...))
  local cmd = append({ bin, "fmt" }, args)
  table.insert(cmd, file)

  util.job(cmd, {
    cwd = vim.fn.fnamemodify(file, ":h"),
    on_exit = function(lines, code)
      if code ~= 0 then
        local extra = (#lines > 0 and " — " .. lines[1]) or ""
        notify(("`pengu fmt` falló (código %d).%s"):format(code, extra), vim.log.levels.ERROR)
        return
      end
      replace_buffer_from_file(buf, file)
      notify("Archivo formateado con `pengu fmt`.")
    end,
    on_error = function()
      notify("No se pudo ejecutar `pengu fmt`.", vim.log.levels.ERROR)
    end,
  })
end

--------------------------------------------------------------------------------
-- Formateo al guardar (format_on_save)
--------------------------------------------------------------------------------

local formatting_save = false

--- Formatea el buffer durante BufWritePre de forma síncrona y segura:
-- vuelca el contenido del buffer a un archivo temporal (extensión .pengu),
-- ejecuta `pengu fmt` sobre el temporal, espera el resultado y reemplaza el
-- buffer con la salida formateada. Así no se pierden cambios sin guardar.
function M._format_on_save(bufnr)
  if formatting_save then
    return
  end
  local c = cfg()
  if not c.format_on_save then
    return
  end
  local ft = vim.bo[bufnr].filetype
  if ft ~= "pengus" then
    return
  end
  local bin = get_bin()
  if not bin then
    return
  end
  local file = util.buffer_path(bufnr)
  if not file then
    return
  end

  local ext = vim.fn.fnamemodify(file, ":e")
  local tmp = vim.fn.tempname()
  if ext ~= "" then
    tmp = tmp .. "." .. ext
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if not util.write_file_lines(tmp, lines) then
    notify("No se pudo crear el archivo temporal para formatear.", vim.log.levels.ERROR)
    return
  end

  local extra = append(c.commands.fmt.args, {})
  local fos_args = type(c.format_on_save) == "table" and (c.format_on_save.args or {}) or {}
  local cmd = append({ bin, "fmt" }, append(extra, append(fos_args, { tmp })))

  formatting_save = true
  local jid = util.job(cmd, { cwd = vim.fn.fnamemodify(tmp, ":h") })
  local code = -1
  if jid then
    code = util.job_wait(jid, c.format_on_save_timeout or 30000)
    if code == -1 then
      vim.fn.jobstop(jid)
      vim.fn.jobwait({ jid }, 2000)
    end
  end
  formatting_save = false

  if code == 0 then
    local formatted = util.read_file_lines(tmp)
    if formatted then
      pcall(vim.api.nvim_buf_call, bufnr, function()
        pcall(vim.cmd, "silent undojoin")
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
        vim.bo[bufnr].modified = true -- el guardado en curso escribirá el contenido nuevo
      end)
      notify("Formateado con `pengu fmt` antes de guardar.")
    end
  elseif code == -1 then
    util.notify_once("fmt-on-save-timeout", "`pengu fmt` al guardar excedió el tiempo.", vim.log.levels.WARN)
  else
    util.notify_once("fmt-on-save-error", "`pengu fmt` falló al formatear en el guardado.", vim.log.levels.ERROR)
  end

  os.remove(tmp)
end

--------------------------------------------------------------------------------
-- setup(): autocomandos
--------------------------------------------------------------------------------

function M.setup()
  local c = cfg()
  local group = vim.api.nvim_create_augroup("pengus_commands", { clear = true })
  if c.format_on_save then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      pattern = { "*.pengu", "*.d.pengu" },
      callback = function(args)
        M._format_on_save(args.buf)
      end,
    })
  end
end

return M
