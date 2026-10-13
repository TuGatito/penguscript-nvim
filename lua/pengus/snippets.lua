--- pengus.snippets
-- Integración de los snippets de PenguScript con el motor disponible.
--
-- `snippets/pengus.json` (formato VS Code) es la **única fuente de verdad**;
-- este módulo solo la conecta:
--
--   1. **LuaSnip (vía oficial).** `luasnip.loaders.from_vscode.lazy_load`
--      respeta el `package.json` del plugin y aporta la semántica completa de
--      VS Code: placeholders, mirrors (`${1:x}` repetido), choices
--      (`${1|a,b|}`), escapes e indentación relativa a la línea actual.
--
--   2. **Respaldo nativo.** Si el cargador de VS Code no estuviera disponible,
--      se lee el mismo JSON y se registran los snippets con un conversor del
--      subconjunto que usa el plugin (`$N`, `${N:def}`, `${N|a,b,c|}`).
--
-- Los cuerpos del JSON usan **4 espacios** —la indentación oficial de
-- PenguScript, que `pengu fmt` impone— porque tanto LuaSnip como VS Code
-- añaden además la indentación de la línea donde se expande el snippet.
local M = {}

local registered = false

--- Ruta raíz del plugin (este archivo vive en lua/pengus/snippets.lua).
local function get_plugin_root()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return vim.fn.fnamemodify(src, ":h:h:h")
end

--- Ruta del catálogo de snippets.
local function snippets_path()
  return get_plugin_root() .. "/snippets/pengus.json"
end

--- Lee y decodifica `snippets/pengus.json`. Devuelve nil si no se puede.
local function read_catalog()
  local path = snippets_path()
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok or type(data) ~= "table" then
    return nil
  end
  return data
end

--------------------------------------------------------------------------------
-- Conversor mínimo del formato VS Code (solo el respaldo nativo)
--------------------------------------------------------------------------------

--- Devuelve el texto entre `start` y el `}` que lo cierra, respetando anidamiento.
local function read_braced(body, start)
  local depth = 0
  local pos = start
  while pos <= #body do
    local c = body:sub(pos, pos)
    if c == "\\" then
      pos = pos + 2
    elseif c == "{" then
      depth = depth + 1
      pos = pos + 1
    elseif c == "}" then
      if depth == 0 then
        return body:sub(start, pos - 1), pos + 1
      end
      depth = depth - 1
      pos = pos + 1
    else
      pos = pos + 1
    end
  end
  return body:sub(start), #body + 1
end

--- Convierte un cuerpo en formato VS Code a una lista de nodos LuaSnip.
local function parse_body(ls, body)
  local insert_node = ls.insert_node or ls.i
  local text_node = ls.text_node or ls.t
  local choice_node = ls.choice_node or ls.c
  if not (insert_node and text_node) then
    return nil
  end

  local nodes = {}
  local buffer = {}
  -- Índices ya vistos: la primera aparición es el tabstop real y las demás
  -- pasan a ser mirrors (igual que en VS Code).
  local seen = {}

  local function flush()
    if #buffer > 0 then
      -- LuaSnip representa el texto multilínea como una lista de líneas (una
      -- entrada por línea); una cadena con `\n` dentro sería rechazada por
      -- `nvim_buf_set_text`. Además, `util.indent` usa esa lista para sangrar
      -- todas las líneas menos la primera al expandir.
      nodes[#nodes + 1] = text_node(vim.split(table.concat(buffer), "\n", { plain = true }))
      buffer = {}
    end
  end

  local function push_text(s)
    buffer[#buffer + 1] = s
  end

  local function push_insert(num, default)
    flush()
    if seen[num] or default == nil then
      nodes[#nodes + 1] = insert_node(num)
    else
      seen[num] = true
      nodes[#nodes + 1] = insert_node(num, default)
    end
  end

  local pos = 1
  while pos <= #body do
    local c = body:sub(pos, pos)
    if c == "\\" and pos < #body then
      local nxt = body:sub(pos + 1, pos + 1)
      if nxt == "$" or nxt == "\\" or nxt == "{" or nxt == "}" then
        push_text(nxt)
        pos = pos + 2
      else
        push_text(c)
        pos = pos + 1
      end
    elseif c == "$" then
      local _, num_end, num = body:find("^%$(%d+)", pos)
      if num then
        push_insert(tonumber(num), nil)
        pos = num_end + 1
      else
        local _, def_start, dnum = body:find("^%${(%d+):", pos)
        if dnum then
          local default, after = read_braced(body, def_start + 1)
          push_insert(tonumber(dnum), default)
          pos = after
        else
          local _, choice_start, cnum = body:find("^%${(%d+)|", pos)
          if cnum and choice_node then
            local close = body:find("|}", choice_start + 1, true)
            if close then
              local raw = body:sub(choice_start + 1, close - 1)
              local choices = {}
              for _, item in ipairs(vim.split(raw, ",", { plain = true })) do
                choices[#choices + 1] = text_node(item)
              end
              flush()
              nodes[#nodes + 1] = choice_node(tonumber(cnum), choices)
              pos = close + 2
            else
              push_text(c)
              pos = pos + 1
            end
          else
            push_text(c)
            pos = pos + 1
          end
        end
      end
    else
      push_text(c)
      pos = pos + 1
    end
  end
  flush()

  return nodes
end

--- Construye la lista de snippets de LuaSnip a partir del catálogo JSON.
local function build(ls, data)
  local snippet = ls.snippet or ls.s
  if not snippet then
    return nil
  end

  -- Orden estable para que la lista de completado no cambie entre arranques.
  local keys = {}
  for key in pairs(data) do
    keys[#keys + 1] = key
  end
  table.sort(keys)

  local out = {}
  for _, key in ipairs(keys) do
    local spec = data[key]
    if type(spec) == "table" and type(spec.prefix) == "string" and type(spec.body) == "table" then
      local nodes = parse_body(ls, table.concat(spec.body, "\n"))
      if nodes then
        out[#out + 1] = snippet(spec.prefix, nodes, { dscr = spec.description or key })
      end
    end
  end
  return out
end

--------------------------------------------------------------------------------
-- Registro
--------------------------------------------------------------------------------

--- Registra los snippets en LuaSnip si está instalado. Idempotente.
function M.setup(c)
  c = c or require("pengus.config").get()
  if c.snippets == false then
    return
  end

  -- Reintento perezoso: con gestores como lazy.nvim, LuaSnip puede cargarse
  -- (event = "InsertEnter") después que este plugin. El reintento es barato e
  -- idempotente, así que se engancha una sola vez.
  if not M._hooked then
    M._hooked = true
    local group = vim.api.nvim_create_augroup("pengus_snippets", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "pengus",
      callback = function()
        M.maybe_register()
      end,
    })
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = group,
      pattern = { "*.pengu", "*.d.pengu" },
      callback = function()
        M.maybe_register()
      end,
    })
  end

  if registered then
    return
  end

  local ok, ls = pcall(require, "luasnip")
  if not ok then
    return
  end

  -- 1. Vía oficial: el cargador de VS Code de LuaSnip lee `package.json` y
  --    `snippets/pengus.json`, y aplica la semántica completa de VS Code.
  local loaded = false
  local ok_vs, vs = pcall(require, "luasnip.loaders.from_vscode")
  if
    ok_vs
    and type(vs.lazy_load) == "function"
    and vim.fn.filereadable(snippets_path()) == 1
  then
    loaded = pcall(vs.lazy_load, { paths = { get_plugin_root() } })
  end

  -- 2. Respaldo: mismo catálogo, conversor propio.
  if not loaded and type(ls.add_snippets) == "function" then
    local data = read_catalog()
    local snips = data and build(ls, data)
    if snips and #snips > 0 then
      pcall(ls.add_snippets, "pengus", snips)
    end
  end

  registered = true
end

--- Registro diferido: se llama desde los autocomandos FileType/InsertEnter por
-- si LuaSnip se cargó después de configurar el plugin.
function M.maybe_register()
  if registered then
    return
  end
  local c = require("pengus.config").get()
  if c.snippets == false then
    return
  end
  M.setup(c)
end

return M
