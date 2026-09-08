# 🐧 penguscript-nvim

**Soporte completo de PenguScript para Neovim** — LSP integrado, filetype,
resaltado de sintaxis, comandos `:Pengu*` y snippets. Ligero, sin dependencias
obligatorias y compatible con Neovim **0.8+** en Windows, Linux y macOS.

</div>

---

## ✨ Características

- **Servidor LSP automático**: registra el servidor `pengus` (`pengu lsp --stdio`)
  y lo arranca solo al abrir un `.pengu` / `.d.pengu` — sin necesitar
  nvim-lspconfig (aunque se integra con él si lo tienes).
- **Detección de raíz de proyecto** con `root_pattern`: busca `pengu.yaml`,
  `pengu.toml`, `Pengu.toml` y `.git` hacia arriba desde el archivo.
- **Filetype `pengus`** para `.pengu` y `.d.pengu` (doble mecanismo:
  `vim.filetype.add` + `ftdetect`).
- **Resaltado de sintaxis**: Treesitter si hay un parser `pengus` (Neovim
  ≥ 0.10) y archivo `syntax/pengus.vim` como respaldo clásico.
- **Comandos**: `:PenguBuild`, `:PenguRun`, `:PenguCheck`, `:PenguFmt`,
  `:PenguLspStart`, `:PenguLspRestart`, `:PenguLspLog`.
- **Formato al guardar** opcional (`pengu fmt`) con paso seguro por archivo
  temporal (no pierde cambios sin guardar).
- **Snippets** opcionales para LuaSnip (`weave`, `rune`, `omen`, `if`,
  `unless`, `while`, `for`, `judge`, `let`, `var`, `const`).
- **Sin dependencias externas**: solo necesitas el binario `pengu`.
  nvim-lspconfig, cmp-nvim-lsp y LuaSnip se usan únicamente si están
  instalados.

## 📦 Requisitos

- Neovim ≥ 0.8 (0.10+ recomendado para Treesitter nativo).
- El binario [`pengu`](https://github.com/TuGatito/penguscript) en el `$PATH`
  (o configura su ruta, ver más abajo).

> 💡 Las capturas de pantalla llegarán cuando el ecosistema PenguScript esté
> listo. El resaltado funciona desde el primer día con la sintaxis de respaldo.

## 🚀 Instalación

### Lazy.nvim

```lua
{
  "TuGatito/penguscript-nvim",
  main = "pengus",
  opts = {
    -- bin_path = "C:/tools/pengu.exe",  -- opcional
    -- format_on_save = true,            -- opcional
  },
  -- Añade LuaSnip como dependencia SOLO si quieres los snippets:
  -- dependencies = { "L3MON4D3/LuaSnip" },
}
```

### Packer.nvim

```lua
use {
  "TuGatito/penguscript-nvim",
  config = function()
    require("pengus").setup {
      -- format_on_save = true,
    }
  end,
}
```

### vim-plug

```vim
" Tras añadir el plugin, ejecuta :PlugInstall
Plug 'TuGatito/penguscript-nvim'

" Opcional: helptags para :help pengus
Plug 'TuGatito/penguscript-nvim', { 'do': ':helptags ALL' }
```

```lua
-- En tu configuración Lua (init.lua / después de plug#begin):
require("pengus").setup {}
```

### Manual (sin gestor)

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

Añade esto a tu configuración y el plugin queda activo con los valores por
defecto (no hace falta llamar a `setup()` si te sirven):

```lua
require("pengus").setup {} -- opcional
```

## ⚙️ Configuración

La configuración es opcional: sin `setup()` el plugin funciona con los
valores por defecto (LSP automático incluido).

```lua
require("pengus").setup {
  -- Ruta al binario `pengu`. Si no se indica se usa, en orden:
  --   vim.g.pengus_bin_path  ->  $PENGU_BIN_PATH  ->  "pengu" (PATH)
  bin_path = nil,

  -- Filetypes gestionados por el plugin.
  filetypes = { "pengus" },

  -- Arranca el LSP automáticamente al abrir un archivo PenguScript.
  auto_attach = true,

  -- Registra `pengus` en lspconfig.configs si nvim-lspconfig está disponible.
  register_lspconfig = true,

  -- Marcadores para detectar la raíz del proyecto (root_pattern).
  root_markers = { "pengu.yaml", "pengu.toml", "Pengu.toml", ".git" },

  lsp = {
    name = "pengus",
    args = { "lsp", "--stdio" },
    settings = {},                      -- ajustes enviados al servidor
    handlers = nil,                     -- handlers LSP adicionales
    on_attach = function(client, bufnr) -- tu on_attach (keymaps, etc.)
      -- vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    end,
    capabilities = nil,   -- si no se indica: make_client_capabilities()
                          -- ampliadas con cmp-nvim-lsp (si existe)
    flags = { debounce_text_changes = 150 },
    env = nil,            -- variables de entorno extra para el servidor
    log_level = nil,      -- p. ej. vim.lsp.log_levels.DEBUG
  },

  commands = {
    -- Directorio en el que corren build/check/run:
    --   "project" -> raíz del proyecto del buffer
    --   "buffer"  -> carpeta del archivo actual
    --   "cwd"     -> directorio actual de Neovim (por defecto)
    cwd = "cwd",
    run = { split = "botright", size = 15, args = nil },
    build = { args = nil },
    check = { args = nil },
    fmt = { args = nil },
  },

  -- Formatea con `pengu fmt` al guardar. true, false o { args = {...} }.
  format_on_save = false,
  format_on_save_timeout = 30000, -- ms

  highlight = {
    treesitter = "auto",  -- true | false | "auto" (usa el parser si existe)
    colors = {},          -- sobrescrituras de grupos, p. ej.:
    -- colors = { PengusKeyword = { fg = "#c586c0", bold = true } }
  },

  -- Registra los snippets en LuaSnip si está instalado.
  snippets = true,

  -- Mensajes a través de vim.notify.
  notify = true,
}
```

> **Atajos**: también puedes pasar `on_attach`, `capabilities` y `settings`
> directamente en el nivel superior de `opts`; el plugin los reenvía a la
> sección `lsp`.

### Cambiar la ruta del binario

```lua
-- Opción 1: dentro de setup()
require("pengus").setup { bin_path = "/ruta/a/pengu" }

-- Opción 2: variable global (clásica)
vim.g.pengus_bin_path = "C:/herramientas/pengu.exe"

-- Opción 3: variable de entorno
--   export PENGU_BIN_PATH=/ruta/a/pengu
```

## ⌨️ Comandos

| Comando                  | Descripción                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `:PenguBuild [args...]`  | Ejecuta `pengu build [args...]`; salida en la quickfix si falla.   |
| `:PenguRun [args...]`    | Ejecuta `pengu run [args...]` en una terminal nueva.               |
| `:PenguCheck [args...]`  | Ejecuta `pengu check [args...]` y muestra el resultado.            |
| `:PenguFmt [args...]`    | Formatea el archivo actual con `pengu fmt`.                        |
| `:PenguLspStart`         | Arranca el LSP en el buffer actual.                                |
| `:PenguLspRestart`       | Reinicia el servidor LSP.                                          |
| `:PenguLspLog`           | Abre el archivo de log del LSP.                                    |

También hay equivalentes Lua (`require("pengus").build()`, `.run()`,
`.check()`, `.format()`, `.restart()`, `.open_log()`).

## 🧠 LSP

- El servidor se registra con el nombre **`pengus`**.
- El arranque es **automático** al abrir archivos con filetype `pengus`
  (desactívalo con `auto_attach = false` y usa `:PenguLspStart`).
- Las capacidades del cliente habilitan completion, hover, definición,
  referencias, renombrado, diagnósticos, etc., tal como las anuncie el
  servidor. Añade tus propios keymaps con `lsp.on_attach`.
- Si **nvim-lspconfig** está instalado, `require("lspconfig").pengus.setup {}`
  también funciona (el plugin lo registra solo). Puedes gestionar el servidor
  con lspconfig y desactivar el arranque automático del plugin:

```lua
-- Usuario que prefiere gestionar todo con lspconfig:
require("pengus").setup { auto_attach = false }
require("lspconfig").pengus.setup {
  on_attach = function(client, bufnr) ... end,
}
```

## 📐 Filetype y resaltado

| Extensión      | Filetype |
| -------------- | -------- |
| `foo.pengu`    | `pengus` |
| `foo.d.pengu`  | `pengus` |

El archivo `syntax/pengus.vim` colorea de forma clásica (palabras clave,
tipos, comentarios `#`/`##`, cadenas, números, operadores, delimitadores…).
Cuando existe un parser **Treesitter** `pengus` y Neovim ≥ 0.10, el plugin
intenta usarlo automáticamente (`highlight.treesitter = "auto"`).

## ✂️ Snippets (LuaSnip)

Con LuaSnip instalado y su expansión configurada, están disponibles:

| Disparador | Expansión                            |
| ---------- | ------------------------------------ |
| `weave`    | bloque `weave nombre { … }`          |
| `rune`     | bloque `rune nombre { … }`           |
| `omen`     | bloque `omen nombre { … }`           |
| `if`       | `if condición { … }`                 |
| `unless`   | `unless condición { … }`             |
| `while`    | `while condición { … }`              |
| `for`      | `for x in colección { … }`           |
| `judge`    | `judge expr { when caso { … } }`     |
| `let`      | declaración `let x = valor`          |
| `var`      | declaración `var x = valor`          |
| `const`    | declaración `const X = valor`        |

En Lazy.nvim añade `"L3MON4D3/LuaSnip"` como dependencia del plugin.

## 🩺 Solución de problemas

- **«Binario pengu no encontrado»**: instala PenguScript o define
  `vim.g.pengus_bin_path` / `$PENGU_BIN_PATH`.
- **El LSP no arranca**: ejecuta `:PenguLspRestart` y mira `:PenguLspLog`.
  Comprueba que el filetype es `pengus` (`:set ft?`) y que `pengu lsp --stdio`
  responde en la terminal.
- **Sin resaltado**: `:syntax on` y comprueba los grupos con
  `:hi PengusKeyword`. Para Treesitter instala el parser
  `pengus` (`require("nvim-treesitter.install").update { with_sync = true }`).
- **Los comandos no existen**: asegúrate de que el plugin está en el
  `runtimepath` y recarga con `:source $MYVIMRC` o reinicia Neovim.

## 📁 Estructura del repositorio

```
penguscript-nvim/
├── README.md
├── LICENSE            (MIT)
├── doc/pengus.txt     (ayuda de :help)
├── lua/pengus/
│   ├── init.lua       (punto de entrada / API pública)
│   ├── config.lua     (opciones por defecto y merge)
│   ├── lsp.lua        (configuración del LSP)
│   ├── commands.lua   (comandos :Pengu* y formateo)
│   ├── highlights.lua (Treesitter opcional y colores)
│   ├── snippets.lua   (snippets LuaSnip opcionales)
│   └── util.lua       (utilidades internas)
├── plugin/pengus.vim  (comandos y carga automática)
├── ftdetect/pengus.vim
├── ftplugin/pengus.vim
└── syntax/pengus.vim  (resaltado de respaldo)
```

## 🤝 Contribuciones

Los issues y pull requests son bienvenidos en el repositorio. Por favor, abre
un issue antes de cambios grandes.

## 📄 Licencia

MIT — ver el archivo [LICENSE](./LICENSE). © 2026 TuGatito.
