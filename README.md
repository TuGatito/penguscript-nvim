# 🐧 penguscript-nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)](https://neovim.io)
[![PenguScript](https://img.shields.io/badge/PenguScript-2.16+-orange.svg)](https://github.com/TuGatito/PenguScript)

🌐 **Language / Idioma:** [🇬🇧 English](#-english) • [🇪🇸 Español](#-español)

---

<a id="english"></a><a id="-english"></a>
## 🇬🇧 English

[🇪🇸 Switch to Spanish version / Cambiar a la versión en español](#-español)

**Official, first-class PenguScript support for Neovim and LazyVim** — Integrated LSP, navigable Quickfix diagnostics, filetype detection, comprehensive syntax highlighting, bounded indentation engine optimized for large files, `:Pengu*` commands, and an idiomatic Pengunic snippet catalog.

Lightweight, zero mandatory third-party dependencies, and fully compatible with Neovim **0.8+** across Linux, macOS, and Windows.

> [!NOTE]
> Tailored for the **PenguScript 2.0+** language specification and toolchain (covering `LANGUAGE_Spanish.md` and the official Pengunic Style Guide).

---

### ✨ Features

- 🧠 **Automatic & Intelligent Language Server (LSP)**:
  - Spawns `pengu lsp --stdio` seamlessly upon opening `.pengu` or `.d.pengu` files.
  - Accurate project root detection (`root_pattern`): `pengu.yaml`, `pengu.toml`, `Pengu.toml`, `build.pengu`, `pengu.lock`, `.pengufmt.toml`, and `.git`.
  - Priority completion capabilities for **`blink.cmp`** (modern LazyVim default) and **`cmp-nvim-lsp`**.
  - Automatic registration in `nvim-lspconfig` for `:LspInfo` integration.
- 🚨 **Navigable Quickfix for Compilation and Tests**:
  - Automatically parses PenguScript diagnostics (`file:line:column [E0000] message`).
  - Pressing `<Enter>`, `:cnext`, or `:cprev` jumps directly to the exact file, line, and column.
  - Built-in `makeprg=pengu\ build` and native `errorformat` in `pengus` buffers.
- ⚡ **Extreme Performance on Large Files**:
  - As PenguScript compiles to C, source and generated files can span tens of thousands of lines.
  - **Bounded Indentation**: Search loops back-guarded with a strict budget to prevent keystroke lag on `<CR>`.
  - **Optimized Syntax**: Synchronisation anchored to top-level declarations rather than expensive backward regex backtracking.
  - **Non-destructive Formatting**: Buffer updates via slice diffs (only touching modified ranges) to preserve folds, cursor marks, and undo history.
- 🎨 **Complete Syntax Highlighting** (`syntax/pengus.vim`):
  - Full coverage of all **40 standard library modules** (`spark`, `json`, `petitio`, `filum`, `builder`, `compressus`, `lingua`, `regulus`, `sourcemap`, etc.) plus `arca`.
  - Keywords and block statements: `antiquus`, `unsafe:`, `do:`, `or:`, `many`, `shard`, `where`.
  - Soft keywords (`frozen`, `inline`, `ritual`) and built-in concepts.
  - Idiomatic expressions: `or else`, `or return`, `is present`, `is not present`, `not in`, and type conversions with `to`.
  - Visual distinction for private identifiers starting with an underscore (`_private`).
  - Automatic **Treesitter** highlighting when a parser is detected (Neovim $\ge$ 0.10).
- 🪄 **Contextual C Binding Generation** (`:PenguBind`):
  - Running `:PenguBind` while editing a C header (`.h` or `.hpp`) automatically detects the buffer and opens the generated `.d.pengu` file in a vertical split.
- 🏃 **Interactive Execution and Testing**:
  - `:PenguRun` in an integrated terminal with automatic buffer reuse (no stale terminal leaks).
  - `:PenguTest` with Quickfix results and `:PenguTestWatch` for continuous test execution on file changes.
- ✂️ **173 Idiomatic Pengunic Snippets** (`snippets/pengus.json`):
  - Standard VS Code format; compatible with LuaSnip, `blink.cmp`, LazyVim, and `vim.snippet`.
  - Covers standard modules (`std.json`, `std.petitio`, `std.filum`, `std.builder`, `std.trial`) and Pengunic patterns (`if v as T is m:`, immutable `let`, `with:` builders).

---

### 📦 Requirements

- **Neovim** $\ge$ 0.8 (0.10+ recommended for native Treesitter).
- The [`pengu`](https://github.com/TuGatito/penguscript) executable in your `$PATH` (or configured via `bin_path`).

---

### 🚀 Installation

Repository URL:  
`https://github.com/TuGatito/penguscript-nvim`

#### 💤 LazyVim

Add or edit `~/.config/nvim/lua/plugins/pengus.lua`:

```lua
return {
  -- 1. PenguScript core plugin
  {
    "TuGatito/penguscript-nvim",
    ft = { "pengus", "c", "cpp" },
    opts = {
      format_on_save = false, -- In LazyVim formatting is delegated to conform.nvim
    },
  },

  -- 2. Language Server integration (nvim-lspconfig)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pengus = {
          cmd = { "pengu", "lsp", "--stdio" },
          filetypes = { "pengus" },
        },
      },
    },
  },

  -- 3. Asynchronous formatting via conform.nvim (<leader>cf or format on save)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        pengus = { "pengu_fmt" },
      },
      formatters = {
        pengu_fmt = {
          command = "pengu",
          args = { "fmt", "--stdin" },
          stdin = true,
        },
      },
    },
  },

  -- 4. Keymaps with Which-Key under <leader>cp
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cp", group = "PenguScript", icon = "🐧" },
        { "<leader>cpb", "<cmd>PenguBuild<cr>", desc = "Build project" },
        { "<leader>cpr", "<cmd>PenguRun<cr>", desc = "Run target/script" },
        { "<leader>cpt", "<cmd>PenguTest<cr>", desc = "Run unit tests" },
        { "<leader>cpw", "<cmd>PenguTestWatch<cr>", desc = "Continuous tests (watch)" },
        { "<leader>cpc", "<cmd>PenguCheck<cr>", desc = "Type check (no codegen)" },
        { "<leader>cpB", "<cmd>PenguBind<cr>", desc = "Generate C Binding (.h -> .d.pengu)" },
        { "<leader>cpe", "<cmd>PenguExpand<cr>", desc = "Expand to C (bundle.c)" },
      },
    },
  },
}
```

#### ⚡ Lazy.nvim (Standalone Neovim)

Create `~/.config/nvim/lua/plugins/pengus.lua`:

```lua
return {
  "TuGatito/penguscript-nvim",
  dependencies = {
    "L3MON4D3/LuaSnip", -- Optional: for loading snippets if using LuaSnip
  },
  opts = {
    -- format_on_save = true, -- Optional: auto-format on save
  },
}
```

#### 📦 Packer.nvim

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

#### 🔌 vim-plug

```vim
Plug 'TuGatito/penguscript-nvim'
```

In your `init.lua`:
```lua
require("pengus").setup {}
```

#### 📁 Manual

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

---

### ⚙️ Configuration

Configuration is entirely optional. Without calling `setup()`, the plugin runs with optimized defaults:

```lua
require("pengus").setup {
  -- Path to `pengu` binary. If nil, resolved as:
  --   1. vim.g.pengus_bin_path
  --   2. $PENGU_BIN_PATH
  --   3. "pengu" (search in $PATH)
  bin_path = nil,

  -- Filetypes managed by the plugin
  filetypes = { "pengus" },

  -- Auto-start LSP on opening PenguScript files
  auto_attach = true,

  -- Register `pengus` in lspconfig.configs when nvim-lspconfig is present
  register_lspconfig = true,

  -- Root markers for project detection
  root_markers = {
    "pengu.yaml",
    "pengu.toml",
    "Pengu.toml",
    "build.pengu",
    "pengu.lock",
    ".pengufmt.toml",
    ".git",
  },

  lsp = {
    name = "pengus",
    args = { "lsp", "--stdio" },
    settings = {},                      -- Settings passed in initializationOptions
    handlers = nil,                     -- Custom LSP handlers
    on_attach = function(client, bufnr) -- User on_attach callback (keymaps, etc.)
    end,
    capabilities = nil,                 -- Autodetects blink.cmp or cmp-nvim-lsp if nil
    flags = {},
    env = nil,
    log_level = nil,
  },

  commands = {
    -- Working directory for commands:
    --   "project" -> detected project root
    --   "buffer"  -> directory of current file
    --   "cwd"     -> Neovim cwd (default)
    cwd = "cwd",
    run = { split = "botright", size = 15, args = nil },
    watch = { split = "botright", size = 15, args = nil },
    build = { args = nil },
    check = { args = nil },
    test = { args = nil },
    fmt = { args = nil },
  },

  -- Auto-format with `pengu fmt --stdin` on save
  format_on_save = false,
  format_on_save_timeout = 5000, -- ms (5s max to prevent UI freezing)

  highlight = {
    treesitter = "auto", -- "auto" | true | false
    colors = {},         -- Highlight group overrides
  },

  -- Enable snippet registration
  snippets = true,

  -- Notifications via vim.notify
  notify = true,
}
```

---

### ⌨️ Commands

All commands are accessible in Neovim and provide programmatic Lua equivalents:

| Command | Lua Equivalent | Description |
| :--- | :--- | :--- |
| `:PenguBuild [args...]` | `require("pengus").build(...)` | Compiles project (`pengu build`); navigable errors in Quickfix. |
| `:PenguRun [script] [args...]` | `require("pengus").run(...)` | Runs project or script in reusable integrated terminal. |
| `:PenguCheck [args...]` | `require("pengus").check(...)` | Fast type checking without codegen (`pengu check`); Quickfix output. |
| `:PenguTest [args...]` | `require("pengus").test(...)` | Runs integrated unit tests; failures navigable in Quickfix. |
| `:PenguTestWatch [args...]` | `require("pengus").test_watch(...)` | Continuously runs `pengu test --watch` in terminal on changes. |
| `:PenguWatch [script]` | `require("pengus").watch(...)` | Re-executes script on any source code modification. |
| `:PenguBind [header]` | `require("pengus").bind(...)` | Generates `.d.pengu` from C header (auto-detects `.h` buffer and opens split). |
| `:PenguFmt [args...]` | `require("pengus").format(...)` | Formats buffer via `pengu fmt --stdin` efficiently (slice diff). |
| `:PenguExpand [file]` | `require("pengus").expand(...)` | Compiles and prints generated `bundle.c` into a split buffer. |
| `:PenguDoc [args...]` | `require("pengus").doc(...)` | Generates Markdown API documentation (`pengu doc`). |
| `:PenguTime [script]` | `require("pengus").time(...)` | Runs script and prints per-phase timings (check, codegen, C, runtime). |
| `:PenguEval <expr>` | `require("pengus").eval(...)` | Evaluates a one-line PenguScript expression and displays result. |
| `:PenguAssets [--list]` | `require("pengus").assets(...)` | Inspects or regenerates embedded asset modules (`arca`). |
| `:PenguBench [args...]` | `require("pengus").benchmark(...)` | Runs project benchmark suite. |
| `:PenguInit <name>` | `require("pengus").init(...)` | Creates a new PenguScript project template (`pengu init`). |
| `:PenguAdd <url>` | `require("pengus").add(...)` | Installs an external package or binding into `lib/`. |
| `:PenguUpdate` | `require("pengus").update(...)` | Updates and recompiles configured dependencies. |
| `:PenguClean` | `require("pengus").clean(...)` | Removes `build/` directory and build artifacts. |
| `:PenguGc` | `require("pengus").gc(...)` | Garbage-collects global compiler caches. |
| `:PenguDoctor` | `require("pengus").doctor(...)` | Diagnoses toolchain health, C compilers, and stdlib. |
| `:PenguVersion` | `require("pengus").version()` | Prints `pengu` toolchain version. |
| `:PenguLspStart` | `require("pengus.lsp").start_current()` | Starts Language Server on the current buffer. |
| `:PenguLspRestart` | `require("pengus").restart()` | Restarts Language Server instance. |
| `:PenguLspLog` | `require("pengus").open_log()` | Opens the LSP log file for debugging. |

---

### 🪄 C Binding Generation (`:PenguBind`)

Working with native C libraries is seamless:

1. Open any C header file (`.h` or `.hpp`), e.g., `include/raylib.h`.
2. Run `:PenguBind` without arguments (or with options like `:PenguBind --prefix raylib_`).
3. The plugin executes `pengu bind`, automatically detects the active buffer, and opens the generated `.d.pengu` binding file in a **vertical split** ready for inspection.

---

### 📐 Filetype & Indentation

| Extension | Filetype | Description |
| :--- | :--- | :--- |
| `*.pengu` | `pengus` | PenguScript source modules and programs |
| `*.d.pengu` | `pengus` | External C bindings and declaration files |

- **Official Pengunic Indentation**: 4 spaces, never tabs (`expandtab`).
- **Block Handling**: Indents after `:` (`weave`, `rune`, `with:`, `do:`, `or:`, `unsafe:`, etc.).
- **Branch Alignment**: `else`, `else when`, `when ... ->`, and `or:` align with their parent header.
- **Literal C at Column 0**: Inside triple-quoted `antiquus` blocks (`r"""..."""`), literal C code is kept strictly at column 0.
- **Comments**: `#` for standard comments and `##` for API documentation (used by LSP hover and `pengu doc`).

---

### ✂️ Snippets Catalog

[`snippets/pengus.json`](./snippets/pengus.json) contains **173 snippets** aligned with the Pengunic Style Guide:

| Trigger | Expansion / Pengunic Pattern |
| :--- | :--- |
| `main` | Entry point `weave main into int:` |
| `mainv` | Entry point without return `weave main into void:` |
| `weave` | Function declaration with parameters and return type |
| `weaverit` | Static `ritual` method (constructors `new`, `with_*`) |
| `weaveshard` | Generic function with `shard T` parameter |
| `weaveshardwhere` | Generic function with concept bound `where T: Concept` |
| `antiquus` | Function with literal C body at column 0 |
| `antiquusexport` | `antiquus` function exported with `@export` (prevents DCE removal) |
| `rune` | Struct definition (`rune Name:`) |
| `runederive` | Struct with automatic concept implementations (`derive Par, Ordo`) |
| `omen` | Algebraic enum or variant with payloads (`omen Event:`) |
| `concept` | Compile-time contract (`concept Formatter:`) |
| `bind` | Concept implementation for a type (`bind T with Concept:`) |
| `enchanting` | Method block associated with a type |
| `let` / `letin` | Immutable local binding (preferred default) |
| `var` / `varin` | Mutable local variable (only when mutated with `set`) |
| `ifas` | Idiomatic `maybe` unpacking: `if v as Type is maybe_val:` |
| `letelse` | Immutable declaration with fallback: `let x is expr or else def` |
| `letret` | Early exit on error: `let x is expr or return err` |
| `orblock` | Structured error handler: `or: error ->` |
| `withblock` | Struct builder expression with `with:` block |
| `withtarget` | In-place struct/collection mutation `with target:` |
| `judge` / `when` | Pattern matching with compile-time exhaustiveness check |
| `deferbanish` | Idiomatic memory cleanup on scope exit |
| `jsonparse` | Parse strict JSON document with `std.json` |
| `jsonstr` | Serialize to JSON string with `std.json` |
| `httpreq` | Complete HTTP request with `std.petitio` and memory cleanup |
| `spawn` | Spawn concurrent thread with `std.filum` |
| `channel` | Create typed concurrency channel with `std.filum` |
| `builder` | Amortized O(1) string accumulator with `std.builder` |
| `diagbag` | Structured diagnostic bag with `std.diagnostic` |
| `asserteq` | Equality test assertion with `std.trial` |
| `asserttrue` | Boolean test assertion with `std.trial` |
| `test` | Integrated native unit test block |

---

<a id="espanol"></a><a id="-español"></a>
## 🇪🇸 Español

[🇬🇧 Switch to English version / Cambiar a la versión en inglés](#-english)

**Soporte oficial y de primer nivel de PenguScript para Neovim y LazyVim** — LSP integrado, diagnósticos navegables en Quickfix, detección de filetype, resaltado de sintaxis completo, sangría automática optimizada para archivos grandes, comandos `:Pengu*` y catálogo de snippets Pengunic. 

Ligero, sin dependencias obligatorias y compatible con Neovim **0.8+** en Linux, macOS y Windows.

> [!NOTE]
> Diseñado específicamente para el toolchain y especificación oficial de **PenguScript 2.0+** (cubriendo `LANGUAGE_Spanish.md` y la Guía de Estilo Pengunic).

---

### ✨ Características

- 🧠 **Servidor LSP automático e inteligente**:
  - Inicia `pengu lsp --stdio` automáticamente al abrir archivos `.pengu` o `.d.pengu`.
  - Detección precisa de la raíz del proyecto (`root_pattern`): `pengu.yaml`, `pengu.toml`, `Pengu.toml`, `build.pengu`, `pengu.lock`, `.pengufmt.toml` y `.git`.
  - Soporte prioritario para autocompletado en **`blink.cmp`** (estándar en LazyVim moderno) y **`cmp-nvim-lsp`**.
  - Registro automático en `nvim-lspconfig` para integración con `:LspInfo`.
- 🚨 **Quickfix navegable en compilación y tests**:
  - Parsea los diagnósticos del compilador (`archivo:línea:columna [E0000] mensaje`) permitiendo que `<Enter>`, `:cnext` y `:cprev` salten al archivo, línea y columna exactos del fallo.
  - Configuración nativa de `makeprg=pengu\ build` y `errorformat` en buffers `pengus`.
- ⚡ **Rendimiento extremo en archivos largos**:
  - Como PenguScript compila a C, los archivos de código pueden tener miles de líneas.
  - **Sangría acotada**: Búsqueda hacia atrás con límite (*budget*) para eliminar congelamientos o lag al pulsar `Enter`.
  - **Sintaxis optimizada**: Sincronización anclada en declaraciones de nivel superior en lugar de escaneos masivos hacia atrás.
  - **Formateo no destructivo**: Reemplazo de buffer por *slice diff* (solo actualiza el rango modificado), conservando folds, marcas y el historial de deshacer (*undo tree*).
- 🎨 **Resaltado de sintaxis completo** (`syntax/pengus.vim`):
  - Cobertura de los **40 módulos de la biblioteca estándar** (`spark`, `json`, `petitio`, `filum`, `builder`, `compressus`, `lingua`, `regulus`, `sourcemap`, etc.) y `arca`.
  - Palabras clave y sentencias de bloque: `antiquus`, `unsafe:`, `do:`, `or:`, `many`, `shard`, `where`.
  - Palabras clave blandas (`frozen`, `inline`, `ritual`) y conceptos integrados.
  - Expresiones idiomáticas: `or else`, `or return`, `is present`, `is not present`, `not in` y conversión con `to`.
  - Identificadores privados con prefijo `_` (`_privado`) destacados visualmente.
  - Integración automática con **Treesitter** en Neovim $\ge$ 0.10 si hay un parser disponible.
- 🪄 **Generación de Bindings C contextual** (`:PenguBind`):
  - Al ejecutar `:PenguBind` editando una cabecera `.h` o `.hpp`, detecta automáticamente el archivo y abre el `.d.pengu` generado en un split vertical (`vsplit`).
- 🏃 **Ejecución y pruebas interactivas**:
  - `:PenguRun` en terminal integrada sin dejar buffers huérfanos.
  - `:PenguTest` con salida a Quickfix y nuevo comando `:PenguTestWatch` para ejecución continua ante cambios.
- ✂️ **173 snippets idiomáticos Pengunic** (`snippets/pengus.json`):
  - Formato estándar VS Code, listos para LuaSnip, `blink.cmp`, LazyVim y `vim.snippet`.
  - Incluyen módulos estándar (`std.json`, `std.petitio`, `std.filum`, `std.builder`, `std.trial`) y patrones Pengunic (`if v as T is m:`, `let` inmutable, `with:` builders).

---

### 📦 Requisitos

- **Neovim** $\ge$ 0.8 (recomendado 0.10+ para Treesitter nativo).
- Binario [`pengu`](https://github.com/TuGatito/penguscript) en tu `$PATH` (o configurado vía `bin_path`).

---

### 🚀 Instalación

Dirección del repositorio:  
`https://github.com/TuGatito/penguscript-nvim`

#### 💤 LazyVim

Si usas [LazyVim](https://lazyvim.org), crea o edita `~/.config/nvim/lua/plugins/pengus.lua`:

```lua
return {
  -- 1. Plugin base PenguScript
  {
    "TuGatito/penguscript-nvim",
    ft = { "pengus", "c", "cpp" },
    opts = {
      format_on_save = false, -- En LazyVim el formateo se delega a conform.nvim
    },
  },

  -- 2. Integración con el Language Server (nvim-lspconfig)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pengus = {
          cmd = { "pengu", "lsp", "--stdio" },
          filetypes = { "pengus" },
        },
      },
    },
  },

  -- 3. Formateo asíncrono con conform.nvim (<leader>cf o format on save)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        pengus = { "pengu_fmt" },
      },
      formatters = {
        pengu_fmt = {
          command = "pengu",
          args = { "fmt", "--stdin" },
          stdin = true,
        },
      },
    },
  },

  -- 4. Atajos organizados con Which-Key bajo <leader>cp
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cp", group = "PenguScript", icon = "🐧" },
        { "<leader>cpb", "<cmd>PenguBuild<cr>", desc = "Compilar proyecto (build)" },
        { "<leader>cpr", "<cmd>PenguRun<cr>", desc = "Ejecutar (run)" },
        { "<leader>cpt", "<cmd>PenguTest<cr>", desc = "Ejecutar tests" },
        { "<leader>cpw", "<cmd>PenguTestWatch<cr>", desc = "Tests continuos (watch)" },
        { "<leader>cpc", "<cmd>PenguCheck<cr>", desc = "Comprobar tipos (check)" },
        { "<leader>cpB", "<cmd>PenguBind<cr>", desc = "Generar Binding C (.h -> .d.pengu)" },
        { "<leader>cpe", "<cmd>PenguExpand<cr>", desc = "Expandir C (bundle.c)" },
      },
    },
  },
}
```

#### ⚡ Lazy.nvim (Neovim independiente)

Crea `~/.config/nvim/lua/plugins/pengus.lua`:

```lua
return {
  "TuGatito/penguscript-nvim",
  dependencies = {
    "L3MON4D3/LuaSnip", -- Opcional: para cargar los snippets si usas LuaSnip
  },
  opts = {
    -- format_on_save = true, -- Opcional: activar formateo automático al guardar
  },
}
```

#### 📦 Packer.nvim

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

#### 🔌 vim-plug

```vim
Plug 'TuGatito/penguscript-nvim'
```

Y en tu archivo `init.lua`:
```lua
require("pengus").setup {}
```

#### 📁 Manual

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

---

### ⚙️ Configuración

La configuración es completamente opcional. Sin invocar `setup()`, el plugin utiliza valores por defecto optimizados:

```lua
require("pengus").setup {
  -- Ruta al ejecutable `pengu`. Si es nil, se busca en:
  --   1. vim.g.pengus_bin_path
  --   2. $PENGU_BIN_PATH
  --   3. "pengu" (búsqueda en $PATH)
  bin_path = nil,

  -- Filetypes asociados al plugin
  filetypes = { "pengus" },

  -- Arranca el LSP automáticamente al abrir archivos PenguScript
  auto_attach = true,

  -- Registra `pengus` en lspconfig.configs si nvim-lspconfig está presente
  register_lspconfig = true,

  -- Marcadores para detectar la raíz del proyecto
  root_markers = {
    "pengu.yaml",
    "pengu.toml",
    "Pengu.toml",
    "build.pengu",
    "pengu.lock",
    ".pengufmt.toml",
    ".git",
  },

  lsp = {
    name = "pengus",
    args = { "lsp", "--stdio" },
    settings = {},                      -- Ajustes enviados en initializationOptions
    handlers = nil,                     -- Handlers LSP personalizados
    on_attach = function(client, bufnr) -- Callback de usuario (keymaps, etc.)
    end,
    capabilities = nil,                 -- Si es nil, autodetecta blink.cmp o cmp-nvim-lsp
    flags = {},
    env = nil,
    log_level = nil,
  },

  commands = {
    -- Directorio de trabajo para la ejecución de comandos:
    --   "project" -> raíz detectada del proyecto
    --   "buffer"  -> carpeta del archivo actual
    --   "cwd"     -> directorio actual de Neovim (por defecto)
    cwd = "cwd",
    run = { split = "botright", size = 15, args = nil },
    watch = { split = "botright", size = 15, args = nil },
    build = { args = nil },
    check = { args = nil },
    test = { args = nil },
    fmt = { args = nil },
  },

  -- Formateo automático con `pengu fmt --stdin` al guardar
  format_on_save = false,
  format_on_save_timeout = 5000, -- ms (5s máximo para evitar bloqueos)

  highlight = {
    treesitter = "auto", -- "auto" | true | false
    colors = {},         -- Sobrescrituras de grupos de resaltado
  },

  -- Habilita el registro de snippets
  snippets = true,

  -- Notificaciones mediante vim.notify
  notify = true,
}
```

---

### ⌨️ Comandos

Todos los comandos están disponibles en Neovim y cuentan con equivalentes en la API Lua:

| Comando | Equivalente Lua | Descripción |
| :--- | :--- | :--- |
| `:PenguBuild [args...]` | `require("pengus").build(...)` | Compila el proyecto (`pengu build`); errores navegables en la Quickfix. |
| `:PenguRun [script] [args...]` | `require("pengus").run(...)` | Ejecuta el proyecto o script en terminal integrada reutilizable. |
| `:PenguCheck [args...]` | `require("pengus").check(...)` | Comprueba tipos sin generar código (`pengu check`); salida en Quickfix. |
| `:PenguTest [args...]` | `require("pengus").test(...)` | Ejecuta los bloques `test` integrados; fallos navegables en Quickfix. |
| `:PenguTestWatch [args...]` | `require("pengus").test_watch(...)` | Ejecuta `pengu test --watch` continuamente en terminal ante cambios. |
| `:PenguWatch [script]` | `require("pengus").watch(...)` | Reejecuta el script automáticamente al modificar cualquier fuente. |
| `:PenguBind [header]` | `require("pengus").bind(...)` | Genera `.d.pengu` desde cabeceras C (auto-detecta `.h` activo y abre split). |
| `:PenguFmt [args...]` | `require("pengus").format(...)` | Formatea el buffer con `pengu fmt --stdin` de forma eficiente (slice diff). |
| `:PenguExpand [file]` | `require("pengus").expand(...)` | Compila e imprime el `bundle.c` generado en un split de lectura. |
| `:PenguDoc [args...]` | `require("pengus").doc(...)` | Genera documentación Markdown del proyecto (`pengu doc`). |
| `:PenguTime [script]` | `require("pengus").time(...)` | Ejecuta midiendo tiempos por fase (check, codegen, C, runtime). |
| `:PenguEval <expr>` | `require("pengus").eval(...)` | Evalúa una expresión PenguScript y notifica el resultado. |
| `:PenguAssets [--list]` | `require("pengus").assets(...)` | Inspecciona o regenera los módulos de assets embebidos (`arca`). |
| `:PenguBench [args...]` | `require("pengus").benchmark(...)` | Ejecuta la suite de benchmarks reproducibles del proyecto. |
| `:PenguInit <name>` | `require("pengus").init(...)` | Crea la estructura de un proyecto nuevo (`pengu init`). |
| `:PenguAdd <url>` | `require("pengus").add(...)` | Instala una dependencia o binding externo en `lib/`. |
| `:PenguUpdate` | `require("pengus").update(...)` | Actualiza y recompila las dependencias configuradas. |
| `:PenguClean` | `require("pengus").clean(...)` | Limpia el directorio `build/` y los binarios en caché. |
| `:PenguGc` | `require("pengus").gc(...)` | Recolecta las cachés globales del compilador. |
| `:PenguDoctor` | `require("pengus").doctor(...)` | Diagnóstico de salud del toolchain, compiladores C y stdlib. |
| `:PenguVersion` | `require("pengus").version()` | Muestra la versión del toolchain `pengu`. |
| `:PenguLspStart` | `require("pengus.lsp").start_current()` | Inicia el Language Server en el buffer actual. |
| `:PenguLspRestart` | `require("pengus").restart()` | Reinicia el servidor LSP. |
| `:PenguLspLog` | `require("pengus").open_log()` | Abre el archivo de registro de depuración del LSP. |

---

### 🪄 Generación de Bindings C (`:PenguBind`)

El flujo de trabajo con cabeceras de C está totalmente optimizado:

1. Abre cualquier archivo de cabecera C (`.h` o `.hpp`), por ejemplo `include/raylib.h`.
2. Ejecuta `:PenguBind` (sin argumentos) o pásale opciones adicionales como `:PenguBind --prefix raylib_`.
3. El plugin invoca `pengu bind`, detecta automáticamente el archivo activo y abre el binding `.d.pengu` generado en un **split vertical** listo para programar.

---

### 📐 Filetype y Sangría

| Extensión | Filetype | Descripción |
| :--- | :--- | :--- |
| `*.pengu` | `pengus` | Módulos y programas en PenguScript |
| `*.d.pengu` | `pengus` | Archivos de binding y declaraciones externas |

- **Sangría Pengunic oficial**: 4 espacios, sin tabuladores (`expandtab`).
- **Control de bloques**: Sangra tras `:` (`weave`, `rune`, `with:`, `do:`, `or:`, `unsafe:`, etc.).
- **Alineación de ramas**: `else`, `else when`, `when ... ->` y `or:` se alinean con su cabecera.
- **C literal a columna 0**: Dentro de bloques triples `antiquus` (`r"""..."""`), el código C se preserva exactamente a columna 0.
- **Comentarios**: `#` para notas estándar y `##` para documentación de API (consumida por el hover del LSP y `pengu doc`).

---

### ✂️ Catálogo de Snippets

El archivo [`snippets/pengus.json`](./snippets/pengus.json) cuenta con **173 snippets** organizados y adaptados a las directrices de la Guía de Estilo Pengunic:

| Trigger | Expansión / Patrón Pengunic |
| :--- | :--- |
| `main` | Punto de entrada `weave main into int:` |
| `mainv` | Punto de entrada sin retorno `weave main into void:` |
| `weave` | Función con parámetros y retorno tipado |
| `weaverit` | Método estático `ritual` (constructores `new`, `with_*`) |
| `weaveshard` | Función genérica con parámetro `shard T` |
| `weaveshardwhere` | Función genérica acotada por concepto `where T: Concept` |
| `antiquus` | Función con bloque C literal a columna 0 |
| `antiquusexport` | Función `antiquus` exportada con `@export` (evita poda de DCE) |
| `rune` | Definición de struct (`rune Nombre:`) |
| `runederive` | Struct con implementaciones automáticas (`derive Par, Ordo`) |
| `omen` | Enum algebraico o con carga útil (`omen Event:`) |
| `concept` | Contrato de compile-time (`concept Formato:`) |
| `bind` | Implementación de concepto para un tipo (`bind T with Concept:`) |
| `enchanting` | Bloque de métodos asociados a un tipo |
| `let` / `letin` | Binding local inmutable (preferido por defecto) |
| `var` / `varin` | Binding local mutable (solo cuando se muta con `set`) |
| `ifas` | Desempaque idiomático de `maybe`: `if v as Tipo is maybe_val:` |
| `letelse` | Declaración inmutable con fallback: `let x is expr or else def` |
| `letret` | Salida temprana ante error: `let x is expr or return err` |
| `orblock` | Manejador estructurado de error: `or: error ->` |
| `withblock` | Constructor de structs mediante bloque de campos `with:` |
| `withtarget` | Mutación de structs o colecciones existentes `with target:` |
| `judge` / `when` | Coincidencia de patrones con comprobación de exhaustividad |
| `deferbanish` | Liberación idiomática de memoria al salir del ámbito |
| `jsonparse` | Parsear documento JSON estricto con `std.json` |
| `jsonstr` | Serializar a cadena JSON con `std.json` |
| `httpreq` | Petición HTTP completa con `std.petitio` y gestión de memoria |
| `spawn` | Lanzar hilo de ejecución concurrente con `std.filum` |
| `channel` | Crear canal de comunicación tipado con `std.filum` |
| `builder` | Acumulador de strings amortizado O(1) con `std.builder` |
| `diagbag` | Bolsa estructurada de diagnósticos con `std.diagnostic` |
| `asserteq` | Aserción de igualdad para tests con `std.trial` |
| `asserttrue` | Aserción booleana para tests con `std.trial` |
| `test` | Bloque nativo de prueba unitaria integrado |

---

## 📁 Estructura del Repositorio / Repository Structure

```
penguscript-nvim/
├── README.md                          # Documentación bilingüe / Bilingual documentation
├── AUDITORIA_PLUGIN_PENGUSCRIPT.md    # Reporte de auditoría y diagnóstico técnico
├── LICENSE                            # Licencia MIT / MIT License
├── package.json                       # Manifiesto VS Code para snippets (blink.cmp/LuaSnip)
├── doc/
│   ├── pengus.txt                     # Documentación oficial de ayuda (:help pengus)
│   └── tags                           # Índice de tags para Neovim
├── ftdetect/
│   └── pengus.vim                     # Detección clásica de filetype (.pengu / .d.pengu)
├── ftplugin/
│   └── pengus.vim                     # Ajustes por buffer, makeprg y errorformat
├── indent/
│   └── pengus.vim                     # Motor de sangría automático acotado
├── syntax/
│   └── pengus.vim                     # Resaltado clásico completo (40 módulos stdlib)
├── snippets/
│   └── pengus.json                    # Catálogo de 173 snippets en formato VS Code
└── lua/pengus/
    ├── init.lua                       # Punto de entrada y API pública en Lua
    ├── config.lua                     # Gestión de configuración y valores por defecto
    ├── lsp.lua                        # Cliente LSP, detección de raíz y blink.cmp
    ├── commands.lua                   # Comandos :Pengu*, Quickfix parser y bind inteligente
    ├── highlights.lua                 # Integración con Treesitter y temas
    ├── snippets.lua                   # Adaptador de catálogo hacia LuaSnip/vim.snippet
    └── util.lua                       # Utilidades de procesos, jobs y rutas
```

---

## 📄 Licencia / License

Distributed under the **MIT** License. See [`LICENSE`](./LICENSE) for details.  
Distribuido bajo la licencia **MIT**. Consulta el archivo [`LICENSE`](./LICENSE) para más información.  
© 2026 TuGatito.
