--- pengus.commands
-- Implementación de los comandos del plugin. Todos giran alrededor del
-- toolchain unificado `pengu` (PenguScript 2.0.x):
--
--   proyecto:  init, add, update, clean, doctor
--   build:     build, check, run, watch, expand, time, eval, test
--   calidad:   fmt, doc, bind, assets, benchmark, gc
--
-- Las funciones aceptan varargs (igual que `<f-args>` de Vim) o una única
-- tabla de argumentos cuando se llaman por la API Lua.
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

--- Añade `tail` al final de `head` (devuelve una lista nueva).
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

--- Argumentos por defecto configurados para un subcomando (`commands.<sub>`).
local function default_args(sub)
  local c = cfg()
  local entry = c.commands and c.commands[sub]
  return type(entry) == "table" and entry.args or nil
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
-- Con `opts.quiet` no abre la quickfix si el comando termina bien (útil para
-- comandos de acción como `init`, `add` o `clean`).
local function run_to_qf(title, cmd, dir, opts)
  opts = opts or {}
  local jid = util.job(cmd, {
    cwd = dir,
    on_exit = function(lines, code)
      local items = qf_items(lines)
      set_qf(title, items)
      if code == 0 then
        if #items > 0 and not opts.quiet then
          notify(("`%s` completado con %d aviso(s)."):format(title, #items), vim.log.levels.WARN)
          open_qf_if_any(items)
        elseif #items > 0 then
          notify(("`%s` completado."):format(title))
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
-- Salida de jobs en un buffer de solo lectura
--------------------------------------------------------------------------------

--- Ejecuta un comando y muestra su salida en un split nuevo (código C generado
-- por `pengu expand`, documentación, bindings...). `filetype` ajusta el
-- resaltado del resultado.
local function run_to_scratch(title, cmd, dir, filetype)
  local jid = util.job(cmd, {
    cwd = dir,
    on_exit = function(lines, code)
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end
      if #lines == 0 then
        notify(("`%s` no produjo salida (código %d)."):format(title, code), vim.log.levels.WARN)
        return
      end
      vim.cmd("botright new")
      local buf = vim.api.nvim_get_current_buf()
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      if filetype and filetype ~= "" then
        vim.bo[buf].filetype = filetype
      end
      pcall(vim.api.nvim_buf_set_name, buf, title)
      vim.bo[buf].modifiable = false
      notify(("`%s` completado (código %d)."):format(title, code))
    end,
  })
  if not jid then
    notify(("No se pudo lanzar `%s`."):format(title), vim.log.levels.ERROR)
  end
  return jid
end

--------------------------------------------------------------------------------
-- Terminal (run / watch)
--------------------------------------------------------------------------------

local function run_in_terminal(title, cmd, dir, opts)
  opts = opts or {}
  local split = opts.split or "botright"
  local size = math.max(3, opts.size or 15)
  local vertical = split == "vnew" or split == "vsplit" or split == "vertical"
  local position = (split == "topleft" or split == "leftabove") and "topleft" or "botright"

  vim.cmd(position .. (vertical and " vnew" or " new"))
  vim.cmd((vertical and "vertical resize " or "resize ") .. size)

  local buf = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_name, buf, title)
  local pid = vim.fn.termopen(cmd, { cwd = dir })
  if pid == 0 then
    vim.cmd("bwipeout!")
    notify(("No se pudo abrir la terminal para `%s`."):format(title), vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
  return pid
end

--------------------------------------------------------------------------------
-- :PenguBuild / :PenguCheck / :PenguTest / :PenguDoc / ...
--------------------------------------------------------------------------------

--- Ejecuta `pengu <sub> [args...]` volcando la salida en la quickfix.
local function exec_qf(sub, title, opts, ...)
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(default_args(sub), normalize_args(...))
  local cmd = append({ bin, sub }, args)
  run_to_qf(title or ("pengu " .. sub), cmd, work_dir(vim.api.nvim_get_current_buf()), opts)
end

--- Comandos de diagnóstico: la quickfix se abre si hay avisos o errores.
local function diag(sub, title, ...)
  exec_qf(sub, title, nil, ...)
end

--- Comandos de acción (escriben en disco): solo se abre la quickfix al fallar.
local function action(sub, title, ...)
  exec_qf(sub, title, { quiet = true }, ...)
end

function M.build(...)
  diag("build", "pengu build", ...)
end

function M.check(...)
  diag("check", "pengu check", ...)
end

function M.test(...)
  diag("test", "pengu test", ...)
end

function M.doc(...)
  action("doc", "pengu doc", ...)
end

--- `pengu bind <header>`: muestra el binding `.d.pengu` generado en un split.
function M.bind(...)
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(default_args("bind"), normalize_args(...))
  if #args == 0 then
    notify("Uso: :PenguBind <cabecera.h> [--output FILE]", vim.log.levels.WARN)
    return
  end
  local cmd = append({ bin, "bind" }, args)
  return run_to_scratch("pengu bind", cmd, work_dir(vim.api.nvim_get_current_buf()), "pengus")
end

function M.assets(...)
  diag("assets", "pengu assets", ...)
end

function M.benchmark(...)
  diag("benchmark", "pengu benchmark", ...)
end

function M.time(...)
  diag("time", "pengu time", ...)
end

function M.doctor(...)
  diag("doctor", "pengu doctor", ...)
end

function M.init(...)
  action("init", "pengu init", ...)
end

function M.add(...)
  action("add", "pengu add", ...)
end

function M.update(...)
  action("update", "pengu update", ...)
end

function M.clean(...)
  action("clean", "pengu clean", ...)
end

function M.gc(...)
  action("gc", "pengu gc", ...)
end

--------------------------------------------------------------------------------
-- :PenguRun (terminal) y :PenguWatch
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
  return run_in_terminal("pengu run", cmd, work_dir(vim.api.nvim_get_current_buf()), runopts)
end

--- `pengu watch [script]`: recompila y reejecuta al cambiar cualquier fuente.
function M.watch(...)
  local c = cfg()
  local bin = get_bin()
  if not bin then
    return
  end
  local wopts = (c.commands and c.commands.watch) or {}
  local args = append(wopts.args, normalize_args(...))
  if #args == 0 then
    -- Sin argumentos, `watch` necesita un archivo: usa el buffer actual.
    local file = util.buffer_path(vim.api.nvim_get_current_buf())
    if file then
      args = { file }
    end
  end
  local cmd = append({ bin, "watch" }, args)
  return run_in_terminal("pengu watch", cmd, work_dir(vim.api.nvim_get_current_buf()), wopts)
end

--- `pengu expand FILE`: imprime el `bundle.c` generado en un split.
function M.expand(...)
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(default_args("expand"), normalize_args(...))
  if #args == 0 then
    local file = util.buffer_path(vim.api.nvim_get_current_buf())
    if not file then
      notify("El buffer actual no tiene archivo asociado.", vim.log.levels.ERROR)
      return
    end
    args = { file }
  end
  local cmd = append({ bin, "expand" }, args)
  return run_to_scratch("pengu expand", cmd, work_dir(vim.api.nvim_get_current_buf()), "c")
end

--- `pengu eval "EXPR"`: evalúa una expresión y notifica el resultado.
-- Acepta la expresión como varargs (`:PenguEval 10 + 32`) o como tabla.
function M.eval(...)
  local bin = get_bin()
  if not bin then
    return
  end
  local raw = normalize_args(...)
  if #raw == 0 then
    notify("Uso: :PenguEval <expresión>", vim.log.levels.WARN)
    return
  end
  local expr = table.concat(raw, " ")
  local cmd = append({ bin, "eval" }, append(default_args("eval"), { expr }))
  local out = vim.fn.system(cmd)
  local code = vim.v.shell_error
  out = (out or ""):gsub("%s+$", "")
  if code ~= 0 then
    notify(("`pengu eval` falló (código %d): %s"):format(code, out), vim.log.levels.ERROR)
    return
  end
  notify("pengu eval → " .. out)
  return out
end

--- `pengu -V`: notifica la versión del toolchain.
function M.version()
  local bin = get_bin()
  if not bin then
    return
  end
  local out = vim.fn.system({ bin, "-V" })
  out = (out or ""):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 then
    notify("No se pudo obtener la versión de `pengu`.", vim.log.levels.ERROR)
    return
  end
  notify(out)
  return out
end

--------------------------------------------------------------------------------
-- :PenguFmt (a través de `pengu fmt --stdin`)
--------------------------------------------------------------------------------

--- Formatea `lines` con `pengu fmt --stdin`.
-- Devuelve la lista de líneas formateadas o `nil, error`.
local function fmt_via_stdin(bin, args, lines, timeout_ms)
  local cmd = append({ bin, "fmt", "--stdin" }, args)
  local input = table.concat(lines, "\n")
  if #lines > 0 then
    input = input .. "\n"
  end

  local stdout, stderr = {}, {}
  local jid = vim.fn.jobstart(cmd, {
    stdin = "pipe",
    on_stdout = function(_, data)
      for _, l in ipairs(data or {}) do
        stdout[#stdout + 1] = l
      end
    end,
    on_stderr = function(_, data)
      for _, l in ipairs(data or {}) do
        stderr[#stderr + 1] = l
      end
    end,
  })
  if jid <= 0 then
    return nil, "No se pudo ejecutar `pengu fmt`."
  end
  vim.fn.chansend(jid, input)
  vim.fn.chanclose(jid, "stdin")

  local code = vim.fn.jobwait({ jid }, timeout_ms or -1)[1]
  if code == -1 then
    pcall(vim.fn.jobstop, jid)
    return nil, "`pengu fmt` excedió el tiempo de espera."
  end

  local function trim_tail(list)
    while #list > 0 and list[#list] == "" do
      table.remove(list)
    end
  end
  trim_tail(stdout)
  trim_tail(stderr)

  if code ~= 0 then
    local detail = #stderr > 0 and table.concat(stderr, "\n") or table.concat(stdout, "\n")
    return nil, ("`pengu fmt` falló (código %d). %s"):format(code, detail)
  end
  return stdout
end

--- Sustituye el contenido de `bufnr` conservando la vista cuando está visible.
local function replace_buffer(bufnr, lines)
  local win = vim.api.nvim_get_current_win()
  local shown = vim.api.nvim_win_get_buf(win) == bufnr
  local view = shown and vim.fn.winsaveview() or nil
  local ok = pcall(vim.api.nvim_buf_call, bufnr, function()
    pcall(vim.cmd, "silent undojoin")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modified = true
  end)
  if ok and view then
    vim.fn.winrestview(view)
  end
  return ok
end

function M.format(...)
  local buf = vim.api.nvim_get_current_buf()
  local bin = get_bin()
  if not bin then
    return
  end
  local args = append(default_args("fmt"), normalize_args(...))
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local formatted, err = fmt_via_stdin(bin, args, lines, -1)
  if not formatted then
    notify(err, vim.log.levels.ERROR)
    return
  end
  if vim.deep_equal(formatted, lines) then
    notify("El archivo ya estaba formateado.")
    return
  end
  replace_buffer(buf, formatted)
  notify("Archivo formateado con `pengu fmt`.")
end

--------------------------------------------------------------------------------
-- Formateo al guardar (format_on_save)
--------------------------------------------------------------------------------

local formatting_save = false

--- Formatea el buffer durante BufWritePre. Usa `pengu fmt --stdin`, así que
-- funciona con cambios sin guardar y nunca toca el archivo en disco.
function M._format_on_save(bufnr)
  if formatting_save then
    return
  end
  local c = cfg()
  if not c.format_on_save then
    return
  end
  if vim.bo[bufnr].filetype ~= "pengus" then
    return
  end
  local bin = get_bin()
  if not bin then
    return
  end

  local fos_args = type(c.format_on_save) == "table" and (c.format_on_save.args or {}) or {}
  local args = append(default_args("fmt"), fos_args)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  formatting_save = true
  local formatted, err = fmt_via_stdin(bin, args, lines, c.format_on_save_timeout or 30000)
  formatting_save = false

  if not formatted then
    util.notify_once("fmt-on-save-error", err or "`pengu fmt` falló al formatear en el guardado.", vim.log.levels.ERROR)
    return
  end
  if vim.deep_equal(formatted, lines) then
    return
  end
  pcall(vim.api.nvim_buf_call, bufnr, function()
    pcall(vim.cmd, "silent undojoin")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
    vim.bo[bufnr].modified = true -- el guardado en curso escribirá el contenido nuevo
  end)
  notify("Formateado con `pengu fmt` antes de guardar.")
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
  return M
end

return M
