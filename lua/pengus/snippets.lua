--- pengus.snippets
-- Snippets para LuaSnip (opcional). Se registran únicamente si LuaSnip está
-- instalado; en caso contrario el módulo es un no-op y la sintaxis/el LSP
-- siguen funcionando con normalidad. Requisito: LuaSnip cargado (p. ej. como
-- dependencia del plugin en Lazy.nvim) y la ampliación <Tab>/<C-j> configurada
-- por el usuario.
local M = {}

local registered = false

local function build(ls)
  local s = ls.snippet or ls.s
  local t = ls.text_node or ls.t
  local i = ls.insert_node or ls.i
  if not (s and t and i) then
    return nil
  end

  local function block(trigger, kw)
    -- `weave name {` \n <tab> $0 \n `}`
    return s(trigger, {
      t(kw .. " "),
      i(1, "nombre"),
      t(" {"),
      t({ "", "\t" }),
      i(0),
      t({ "", "}" }),
    })
  end

  return {
    block("weave", "weave"),
    block("rune", "rune"),
    block("omen", "omen"),
    s("if", {
      t("if "),
      i(1, "condición"),
      t(" {"),
      t({ "", "\t" }),
      i(0),
      t({ "", "}" }),
    }),
    s("unless", {
      t("unless "),
      i(1, "condición"),
      t(" {"),
      t({ "", "\t" }),
      i(0),
      t({ "", "}" }),
    }),
    s("while", {
      t("while "),
      i(1, "condición"),
      t(" {"),
      t({ "", "\t" }),
      i(0),
      t({ "", "}" }),
    }),
    s("for", {
      t("for "),
      i(1, "x"),
      t(" in "),
      i(2, "colección"),
      t(" {"),
      t({ "", "\t" }),
      i(0),
      t({ "", "}" }),
    }),
    s("judge", {
      t("judge "),
      i(1, "expresión"),
      t(" {"),
      t({ "", "\twhen " }),
      i(2, "caso"),
      t(" {"),
      t({ "", "\t\t" }),
      i(0),
      t({ "", "\t}" }),
      t({ "", "}" }),
    }),
    s("let", { t("let "), i(1, "x"), t(" = "), i(2, "valor"), i(0) }),
    s("var", { t("var "), i(1, "x"), t(" = "), i(2, "valor"), i(0) }),
    s("const", { t("const "), i(1, "X"), t(" = "), i(2, "valor"), i(0) }),
  }
end

--- Intenta registrar los snippets en LuaSnip. No-op si LuaSnip no está.
function M.setup(c)
  c = c or require("pengus.config").get()
  if registered or c.snippets == false then
    return
  end
  local ok, ls = pcall(require, "luasnip")
  if not ok then
    return
  end
  if type(ls.add_snippets) ~= "function" then
    return
  end
  local snips = build(ls)
  if not snips then
    return
  end
  local ok_add = pcall(ls.add_snippets, "pengus", snips)
  if ok_add then
    registered = true
  end
end

--- Intento diferido: se llama desde FileType pengus por si LuaSnip se cargó
-- después de la configuración del usuario.
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
