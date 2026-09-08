--- pengus.highlights
-- Resaltado opcional gestionado desde Lua:
--   * integración con Treesitter cuando existe un parser `pengus`
--     (Neovim 0.10+; en versiones anteriores el resaltado de sintaxis clásico
--     de syntax/pengus.vim actúa como respaldo automático);
--   * sobrescrituras de grupos de color del usuario (`highlight.colors`),
--   re-aplicadas al cambiar de colorscheme.
local M = {}

local api = vim.api

--- Comprueba si hay un parser `pengus` cargable.
local function parser_available(bufnr, lang)
  if not vim.treesitter or not vim.treesitter.get_parser then
    return false
  end
  local ok = pcall(vim.treesitter.get_parser, bufnr, lang)
  return ok
end

--- Activa Treesitter para el buffer si hay parser y Neovim >= 0.10.
-- Devuelve true si se consiguió; si no, se mantiene la sintaxis clásica.
function M.enable_treesitter(bufnr)
  if vim.fn.has("nvim-0.10") ~= 1 then
    return false
  end
  if not vim.treesitter or not vim.treesitter.start then
    return false
  end
  if not parser_available(bufnr, "pengus") then
    return false
  end
  local ok = pcall(vim.treesitter.start, "pengus", bufnr)
  return ok
end

--- Aplica las sobrescrituras de color del usuario.
local function apply_colors(colors)
  for group, spec in pairs(colors or {}) do
    if type(spec) == "table" then
      pcall(api.nvim_set_hl, 0, group, spec)
    elseif type(spec) == "string" then
      pcall(api.nvim_set_hl, 0, group, { link = spec })
    end
  end
end

function M.setup(c)
  c = c or require("pengus.config").get()

  local colors = c.highlight and c.highlight.colors
  if colors and next(colors) then
    apply_colors(colors)
    local group = api.nvim_create_augroup("pengus_colors", { clear = true })
    api.nvim_create_autocmd("ColorScheme", {
      group = group,
      callback = function()
        apply_colors(colors)
      end,
    })
  end

  local want_ts = c.highlight and c.highlight.treesitter
  if want_ts and want_ts ~= false then
    local group = api.nvim_create_augroup("pengus_treesitter", { clear = true })
    api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "pengus",
      callback = function(args)
        if want_ts == "auto" or want_ts == true then
          M.enable_treesitter(args.buf)
        end
      end,
    })
  end
end

return M
