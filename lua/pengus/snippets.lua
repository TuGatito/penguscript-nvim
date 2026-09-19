--- pengus.snippets
-- Snippets para PenguScript (compatible con LuaSnip, blink.cmp y Neovim 0.10+).
--
-- Soporta dos vías de integración:
--   1. Carga automática desde snippets/pengus.json (formato VSCode estándar)
--      a través de luasnip.loaders.from_vscode.
--   2. Registro programático nativo de snippets de LuaSnip con la sintaxis
--      real de PenguScript (bloques con sangría sensible y `:`, nunca `{}`).
local M = {}

local registered = false

--- Devuelve la ruta raíz del plugin.
local function get_plugin_root()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  -- src está en lua/pengus/snippets.lua -> subir 3 niveles
  return vim.fn.fnamemodify(src, ":h:h:h")
end

--- Construye la lista de snippets nativos para LuaSnip.
local function build(ls)
  local s = ls.snippet or ls.s
  local t = ls.text_node or ls.t
  local i = ls.insert_node or ls.i
  if not (s and t and i) then
    return nil
  end

  return {
    -- Funciones y ejecución
    s("main", {
      t({ "weave main into int:", "\t" }),
      i(0),
      t({ "", "\treturn 0" }),
    }),
    s("mainv", {
      t({ "weave main into void:", "\t" }),
      i(0),
    }),
    s("weave", {
      t("weave "),
      i(1, "nombre"),
      t(" with "),
      i(2, "param as type"),
      t(" into "),
      i(3, "void"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("weaveno", {
      t("weave "),
      i(1, "nombre"),
      t(" into "),
      i(2, "void"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("weavein", {
      t("weave inline "),
      i(1, "nombre"),
      t(" with "),
      i(2, "param as type"),
      t(" into "),
      i(3, "int"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("weaverit", {
      t("weave ritual "),
      i(1, "nombre"),
      t(" with "),
      i(2, "param as type"),
      t(" into "),
      i(3, "Type"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("weaveshard", {
      t("weave "),
      i(1, "nombre"),
      t(" shard "),
      i(2, "T"),
      t(" with "),
      i(3, "x as T"),
      t(" into "),
      i(4, "T"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("lambda", {
      t("lambda "),
      i(1, "x as int"),
      t(" into "),
      i(0, "x * 2"),
    }),
    s("declare", {
      t("declare "),
      i(1, "c_func"),
      t(" with "),
      i(2, "param as type"),
      t(" into "),
      i(3, "void"),
    }),
    s("declarevar", {
      t("declare "),
      i(1, "printf"),
      t(" with "),
      i(2, "fmt as ref to frozen char"),
      t(", ... into "),
      i(3, "int"),
    }),

    -- Tipos compuestos
    s("rune", {
      t("rune "),
      i(1, "Nombre"),
      t({ ":", "\t" }),
      i(2, "campo"),
      t(" as "),
      i(3, "int"),
      t({ "", "\t" }),
      i(0),
    }),
    s("runeshard", {
      t("rune "),
      i(1, "Nombre"),
      t(" shard "),
      i(2, "T"),
      t({ ":", "\t" }),
      i(3, "valor"),
      t(" as "),
      i(2, "T"),
      t({ "", "\t" }),
      i(0),
    }),
    s("echo", {
      t("echo "),
      i(1, "Nombre"),
      t({ ":", "\t" }),
      i(2, "campo1"),
      t(" as "),
      i(3, "int"),
      t({ "", "\t" }),
      i(4, "campo2"),
      t(" as "),
      i(5, "float"),
    }),
    s("omen", {
      t("omen "),
      i(1, "Nombre"),
      t({ ":", "\t" }),
      i(2, "Uno"),
      t({ "", "\t" }),
      i(0, "Dos"),
    }),
    s("omenpayload", {
      t("omen "),
      i(1, "Nombre"),
      t({ ":", "\t" }),
      i(2, "Vacio"),
      t({ "", "\t" }),
      i(3, "ConDato"),
      t(" with "),
      i(4, "valor as int"),
    }),
    s("concept", {
      t("concept "),
      i(1, "Nombre"),
      t({ ":", "\tweave " }),
      i(2, "metodo"),
      t(" with "),
      i(3, "param as type"),
      t(" into "),
      i(0, "void"),
    }),
    s("bind", {
      t("bind "),
      i(1, "Tipo"),
      t(" with "),
      i(2, "Concepto"),
      t({ ":", "\tweave " }),
      i(3, "metodo"),
      t(" with "),
      i(4, "param as type"),
      t(" into "),
      i(5, "void"),
      t({ ":", "\t\t" }),
      i(0),
    }),
    s("enchanting", {
      t("enchanting "),
      i(1, "Tipo"),
      t({ ":", "\tweave " }),
      i(2, "metodo"),
      t(" with "),
      i(3, "param as type"),
      t(" into "),
      i(4, "void"),
      t({ ":", "\t\t" }),
      i(0),
    }),
    s("alias", {
      t("alias "),
      i(1, "Nombre"),
      t(" as "),
      i(2, "Tipo"),
    }),
    s("seal", {
      t("seal "),
      i(1, "Nombre"),
      t(" as "),
      i(2, "Tipo"),
    }),

    -- Variables y asignaciones
    s("let", {
      t("let "),
      i(1, "x"),
      t(" as "),
      i(2, "int"),
      t(" is "),
      i(0, "valor"),
    }),
    s("letin", {
      t("let "),
      i(1, "x"),
      t(" is "),
      i(0, "valor"),
    }),
    s("var", {
      t("var "),
      i(1, "x"),
      t(" as "),
      i(2, "int"),
      t(" is "),
      i(0, "valor"),
    }),
    s("varin", {
      t("var "),
      i(1, "x"),
      t(" is "),
      i(0, "valor"),
    }),
    s("varb", {
      t("var borrowed "),
      i(1, "x"),
      t(" as "),
      i(2, "type"),
      t(" is "),
      i(0, "valor"),
    }),
    s("letb", {
      t("let borrowed "),
      i(1, "x"),
      t(" as "),
      i(2, "type"),
      t(" is "),
      i(0, "valor"),
    }),
    s("const", {
      t("const "),
      i(1, "NOMBRE"),
      t(" as "),
      i(2, "int"),
      t(" is "),
      i(0, "valor"),
    }),
    s("static", {
      t("static var "),
      i(1, "x"),
      t(" as "),
      i(2, "int"),
      t(" is "),
      i(0, "valor"),
    }),
    s("set", {
      t("set "),
      i(1, "x"),
      t(" is "),
      i(0, "valor"),
    }),
    s("setdot", {
      t("set ."),
      i(1, "campo"),
      t(" is "),
      i(0, "valor"),
    }),

    -- Control de flujo
    s("if", {
      t("if "),
      i(1, "condición"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("ifelse", {
      t("if "),
      i(1, "condición"),
      t({ ":", "\t" }),
      i(2),
      t({ "", "else:", "\t" }),
      i(0),
    }),
    s("ifmaybe", {
      t("if "),
      i(1, "u"),
      t(" as "),
      i(2, "Tipo"),
      t(" is "),
      i(3, "maybe_val"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("ifexpr", {
      t("if "),
      i(1, "condición"),
      t(" then "),
      i(2, "val_true"),
      t(" else "),
      i(3, "val_false"),
    }),
    s("unless", {
      t("unless "),
      i(1, "condición"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("while", {
      t("while "),
      i(1, "condición"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("for", {
      t("for "),
      i(1, "item"),
      t(" in "),
      i(2, "colección"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("forfrom", {
      t("for "),
      i(1, "i"),
      t(" from "),
      i(2, "0"),
      t(" to "),
      i(3, "10"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("forstep", {
      t("for "),
      i(1, "i"),
      t(" from "),
      i(2, "0"),
      t(" to "),
      i(3, "10"),
      t(" step "),
      i(4, "1"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("foridx", {
      t("for "),
      i(1, "i"),
      t(", "),
      i(2, "item"),
      t(" in "),
      i(3, "colección"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("judge", {
      t("judge "),
      i(1, "expresión"),
      t({ ":", "\twhen " }),
      i(2, "Patrón"),
      t(" -> "),
      i(3, "resultado"),
      t({ "", "\telse -> " }),
      i(0, "fallback"),
    }),
    s("when", {
      t("when "),
      i(1, "Patrón"),
      t(" -> "),
      i(0, "resultado"),
    }),
    s("do", {
      t({ "do:", "\t" }),
      i(0),
    }),

    -- Builders y construcciones
    s("withblock", {
      t("var "),
      i(1, "obj"),
      t(" as "),
      i(2, "Tipo"),
      t({ " with:", "\tset ." }),
      i(3, "campo"),
      t(" is "),
      i(4, "valor"),
      t({ "", "\t" }),
      i(0),
    }),
    s("withtarget", {
      t("with "),
      i(1, "target"),
      t({ ":", "\tset ." }),
      i(2, "campo"),
      t(" is "),
      i(0, "valor"),
    }),
    s("calling", {
      t("calling "),
      i(1, "funcion"),
      t(" with "),
      i(0, "args"),
    }),
    s("call", {
      t("calling "),
      i(0, "funcion"),
    }),

    -- Memoria y errores
    s("banish", {
      t("banish "),
      i(0, "ptr"),
    }),
    s("defer", {
      t("defer "),
      i(0, "sentencia"),
    }),
    s("deferbanish", {
      t("defer banish "),
      i(0, "ptr"),
    }),
    s("errdefer", {
      t("errdefer "),
      i(0, "sentencia"),
    }),
    s("try", {
      t("try calling "),
      i(1, "funcion"),
      t(" with "),
      i(0, "args"),
    }),
    s("orelse", {
      i(1, "maybe_expr"),
      t(" or else "),
      i(0, "fallback"),
    }),
    s("orreturn", {
      i(1, "expr"),
      t(" or return "),
      i(0, "error_val"),
    }),
    s("orblock", {
      i(1, "llamada_peligrosa"),
      t({ " or:", "\tlet err is error", "\t" }),
      i(0),
    }),

    -- Testing y compilación condicional
    s("test", {
      t("test \""),
      i(1, "nombre_prueba"),
      t({ "\":", "\t" }),
      i(0),
    }),
    s("whencc", {
      t("when "),
      i(1, "condición"),
      t({ ":", "\t" }),
      i(0),
    }),
    s("whendebug", {
      t({ "when debug:", "\t" }),
      i(0),
    }),

    -- I/O
    s("print", {
      t("calling print with \""),
      i(1, "mensaje\\n"),
      t("\""),
      i(0),
    }),
    s("println", {
      t("calling spark.println with \""),
      i(1, "mensaje"),
      t("\""),
      i(0),
    }),
  }
end

--- Intenta registrar los snippets en LuaSnip.
function M.setup(c)
  c = c or require("pengus.config").get()
  if registered or c.snippets == false then
    return
  end

  local ok, ls = pcall(require, "luasnip")
  if not ok then
    return
  end

  -- 1. Intentar cargar los snippets VSCode desde snippets/pengus.json
  local ok_vs, vs_loader = pcall(require, "luasnip.loaders.from_vscode")
  if ok_vs and type(vs_loader.lazy_load) == "function" then
    local root = get_plugin_root()
    pcall(vs_loader.lazy_load, { paths = { root } })
  end

  -- 2. Registrar los snippets programáticos nativos de respaldo
  if type(ls.add_snippets) == "function" then
    local snips = build(ls)
    if snips then
      pcall(ls.add_snippets, "pengus", snips)
    end
  end

  registered = true
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
