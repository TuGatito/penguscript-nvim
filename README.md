# 🐧 penguscript-nvim

**Full PenguScript support for Neovim** — built-in LSP, filetype detection,
syntax highlighting, `:Pengu*` commands and snippets. Lightweight, no mandatory
dependencies, compatible with Neovim **0.8+** on Windows, Linux and macOS.

---

## ✨ Features

- **Automatic LSP server**: registers the `pengus` server (`pengu lsp --stdio`)
  and starts it automatically when opening a `.pengu` / `.d.pengu` file — no
  nvim-lspconfig required (it integrates with it when installed).
- **Project root detection** via `root_pattern`: looks for `pengu.yaml`,
  `pengu.toml`, `Pengu.toml` and `.git` walking up from the file.
- **`pengus` filetype** for `.pengu` and `.d.pengu` files (dual mechanism:
  `vim.filetype.add` + `ftdetect`).
- **Syntax highlighting**: Full support for PenguScript 0.10+ in `syntax/pengus.vim`
  (all keywords, soft keywords `frozen`/`borrowed`, primitive & container types,
  interpolation `"{var}"`, raw strings `r"..."`, multiline triples `"""`, and operators)
  plus automatic Treesitter when a `pengus` parser is available (Neovim ≥ 0.10).
- **Smart indentation**: automatic indentation calculation for colon-based blocks
  (`indent/pengus.vim`).
- **Commands**: `:PenguBuild`, `:PenguRun`, `:PenguCheck`, `:PenguTest`, `:PenguFmt`,
  `:PenguLspStart`, `:PenguLspRestart`, `:PenguLspLog`.
- **Optional format on save** (`pengu fmt`) using a safe temporary-file step
  (never loses unsaved changes).
- **Comprehensive snippets**: 50+ rich snippets available both as standard
  VS Code format (`snippets/pengus.json` for LazyVim, blink.cmp, mini.snippets, etc.)
  and native LuaSnip integration (`lua/pengus/snippets.lua`).
- **No external dependencies**: you only need the `pengu` binary.
  nvim-lspconfig, cmp-nvim-lsp and LuaSnip are used only when installed.

## 📦 Requirements

- Neovim ≥ 0.8 (0.10+ recommended for native Treesitter).
- The [`pengu`](https://github.com/TuGatito/penguscript) binary on your
  `$PATH` (or configure its path, see below).

> 💡 Screenshots will come once the PenguScript ecosystem is ready.
> Highlighting works from day one thanks to the fallback syntax.

## 🚀 Installation

### Lazy.nvim

Create the file `~/.config/nvim/lua/plugins/pengus.lua` (on Windows:
`~/AppData/Local/nvim/lua/plugins/pengus.lua`). Lazy.nvim automatically loads
every spec file inside the `lua/plugins/` directory:

```lua
-- ~/.config/nvim/lua/plugins/pengus.lua
return {
  "TuGatito/penguscript-nvim", -- Replace with your user/repo
  -- Add LuaSnip as a dependency ONLY if you want the snippets:
  dependencies = {
    "L3MON4D3/LuaSnip", -- optional, only needed for snippets
  },
  config = function()
    require("pengus").setup {
      -- All options are optional:
      -- bin_path = "C:/tools/pengu.exe", -- if `pengu` is not on your PATH
      -- format_on_save = true,           -- format on save
      -- snippets = true,                 -- enable LuaSnip snippets (default: true)
      -- lsp = {
      --   on_attach = function(client, bufnr)
      --     -- your custom LSP keymaps here
      --   end,
      -- },
    }
  end,
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
" After adding the plugin, run :PlugInstall
Plug 'TuGatito/penguscript-nvim'

" Optional: helptags so :help pengus works
Plug 'TuGatito/penguscript-nvim', { 'do': ':helptags ALL' }
```

```lua
-- In your Lua config (init.lua / after plug#begin):
require("pengus").setup {}
```

### Manual (no plugin manager)

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

Add this to your config and the plugin is active with its defaults (you don't
need to call `setup()` if the defaults suit you):

```lua
require("pengus").setup {} -- optional
```

## ⚙️ Configuration

Configuration is optional: without `setup()` the plugin works with its default
values (automatic LSP included).

```lua
require("pengus").setup {
  -- Path to the `pengu` binary. When not set, resolved in this order:
  --   vim.g.pengus_bin_path  ->  $PENGU_BIN_PATH  ->  "pengu" (PATH)
  bin_path = nil,

  -- Filetypes handled by the plugin.
  filetypes = { "pengus" },

  -- Start the LSP automatically when opening a PenguScript file.
  auto_attach = true,

  -- Register `pengus` in lspconfig.configs when nvim-lspconfig is available.
  register_lspconfig = true,

  -- Markers used to detect the project root (root_pattern).
  root_markers = { "pengu.yaml", "pengu.toml", "Pengu.toml", ".git" },

  lsp = {
    name = "pengus",
    args = { "lsp", "--stdio" },
    settings = {},                      -- settings sent to the server
    handlers = nil,                     -- extra LSP handlers
    on_attach = function(client, bufnr) -- your on_attach (keymaps, etc.)
      -- vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    end,
    capabilities = nil,   -- when unset: make_client_capabilities()
                          -- augmented with cmp-nvim-lsp (if installed)
    flags = { debounce_text_changes = 150 },
    env = nil,            -- extra environment variables for the server
    log_level = nil,      -- e.g. vim.lsp.log_levels.DEBUG
  },

  commands = {
    -- Directory where build/check/run are executed:
    --   "project" -> project root of the buffer
    --   "buffer"  -> directory of the current file
    --   "cwd"     -> Neovim's current directory (default)
    cwd = "cwd",
    run = { split = "botright", size = 15, args = nil },
    build = { args = nil },
    check = { args = nil },
    fmt = { args = nil },
  },

  -- Format with `pengu fmt` on save. true, false or { args = {...} }.
  format_on_save = false,
  format_on_save_timeout = 30000, -- ms

  highlight = {
    treesitter = "auto",  -- true | false | "auto" (uses the parser if present)
    colors = {},          -- highlight group overrides, e.g.:
    -- colors = { PengusKeyword = { fg = "#c586c0", bold = true } }
  },

  -- Register the snippets in LuaSnip when it is installed.
  snippets = true,

  -- Messages via vim.notify.
  notify = true,
}
```

> **Shorthands**: you can also pass `on_attach`, `capabilities` and `settings`
> at the top level of `opts`; the plugin forwards them to the `lsp` section.

### Changing the binary path

```lua
-- Option 1: inside setup()
require("pengus").setup { bin_path = "/path/to/pengu" }

-- Option 2: global variable (classic)
vim.g.pengus_bin_path = "C:/tools/pengu.exe"

-- Option 3: environment variable
--   export PENGU_BIN_PATH=/path/to/pengu
```

## ⌨️ Commands

| Command                 | Description                                                     |
| ----------------------- | --------------------------------------------------------------- |
| `:PenguBuild [args...]` | Runs `pengu build [args...]`; output goes to the quickfix.      |
| `:PenguRun [args...]`   | Runs `pengu run [args...]` in a new terminal.                   |
| `:PenguCheck [args...]` | Runs `pengu check [args...]` and shows the result in quickfix.  |
| `:PenguTest [args...]`  | Runs `pengu test [args...]` and shows test results in quickfix. |
| `:PenguFmt [args...]`   | Formats the current file with `pengu fmt`.                      |
| `:PenguLspStart`        | Starts the LSP on the current buffer.                           |
| `:PenguLspRestart`      | Restarts the LSP server.                                        |
| `:PenguLspLog`          | Opens the LSP log file.                                         |

Lua equivalents are also available (`require("pengus").build()`, `.run()`,
`.check()`, `.test()`, `.format()`, `.restart()`, `.open_log()`).

## 🧠 LSP

- The server is registered under the name **`pengus`**.
- Startup is **automatic** when opening files with the `pengus` filetype
  (disable it with `auto_attach = false` and use `:PenguLspStart`).
- The client capabilities enable completion, hover, definition, references,
  rename, diagnostics, etc., as advertised by the server. Add your own
  keymaps with `lsp.on_attach`.
- If **nvim-lspconfig** is installed, `require("lspconfig").pengus.setup {}`
  also works (the plugin registers it on its own). You can manage the server
  with lspconfig and disable the plugin's auto-start:

```lua
-- User who prefers to manage everything with lspconfig:
require("pengus").setup { auto_attach = false }
require("lspconfig").pengus.setup {
  on_attach = function(client, bufnr) ... end,
}
```

## 📐 Filetype, syntax & indentation

| Extension      | Filetype |
| -------------- | -------- |
| `foo.pengu`    | `pengus` |
| `foo.d.pengu`  | `pengus` |

- **Syntax**: `syntax/pengus.vim` provides complete highlighting for PenguScript
  0.10+ (keywords, soft keywords `frozen`/`borrowed`, types, containers,
  string interpolation `"{name}"`, raw strings, triple multiline quotes, and operators).
  When a **Treesitter** `pengus` parser is installed and Neovim ≥ 0.10, the plugin
  can use it automatically (`highlight.treesitter = "auto"`).
- **Indentation**: `indent/pengus.vim` automatically indents lines after colons `:`
  and dedents on `else:` or `when`.

## ✂️ Snippets

Snippets are provided in both **standard VS Code JSON format** (`snippets/pengus.json`,
auto-discovered by LazyVim, `blink.cmp`, `mini.snippets`, etc.) and native **LuaSnip**:

| Trigger | Expansion / Description |
| ------- | ----------------------- |
| `main` | `weave main into int:` entry point |
| `mainv` | `weave main into void:` |
| `weave` | `weave name with params into type:` |
| `weaveno` | `weave name into type:` |
| `weavein` | `weave inline name with ... into ...:` |
| `weaverit`| `weave ritual name ... into ...:` static method |
| `weaveshard`| `weave name shard T with ... into ...:` generic |
| `lambda` | `lambda x as int into expr` |
| `declare` | `declare c_func with ... into ...` |
| `declarevar` | `declare printf with fmt as ref to frozen char, ... into int` |
| `rune` | `rune Name:` struct definition |
| `runeshard` | `rune Name shard T:` generic struct |
| `echo` | `echo Name:` union definition |
| `omen` | `omen Name:` enum / algebraic data type |
| `omenpayload`| `omen Name:` with variant payload |
| `concept` | `concept Name:` trait / interface definition |
| `bind` | `bind Type with Concept:` implementation |
| `enchanting` | `enchanting Type:` methods block |
| `let` / `var` | `let x as type is val` / `var x as type is val` |
| `letb` / `varb` | `let borrowed x ...` / `var borrowed x ...` non-owning |
| `const` | `const NAME as type is val` |
| `static` | `static var x as type is val` |
| `set` | `set x is val` / `set .field is val` |
| `if` / `ifelse` | `if cond:` / `else:` block |
| `ifmaybe` | `if u as User is user:` maybe unwrap binding |
| `unless` | `unless cond:` |
| `while` | `while cond:` |
| `for` | `for item in col:` |
| `forfrom` / `forstep` | `for i from 0 to 10:` |
| `judge` | `judge expr:` pattern matching |
| `withblock` | `var x as Type with:` builder block |
| `withtarget` | `with target:` edit block |
| `calling` | `calling func with args` |
| `banish` | `banish ptr` |
| `deferbanish` | `defer banish ptr` |
| `try` | `try calling func with args` |
| `orelse` / `orblock` | error handling / fallback |
| `test` | `test "name":` unit test block |
| `whencc` / `whendebug` | compile-time conditional blocks |
| `print` / `println` | console print statements |

## 📁 Repository structure

```
penguscript-nvim/
├── README.md
├── LICENSE            (MIT)
├── package.json       (manifest for VS Code / Neovim snippet discovery)
├── doc/pengus.txt     (:help docs)
├── snippets/
│   └── pengus.json    (VS Code format snippets)
├── indent/
│   └── pengus.vim     (auto-indentation)
├── lua/pengus/
│   ├── init.lua       (entry point / public API)
│   ├── config.lua     (default options and merge)
│   ├── lsp.lua        (LSP configuration)
│   ├── commands.lua   (:Pengu* commands and formatting)
│   ├── highlights.lua (optional Treesitter and colors)
│   ├── snippets.lua   (LuaSnip & VS Code loader)
│   └── util.lua       (internal utilities)
├── plugin/pengus.vim  (commands and auto-load)
├── ftdetect/pengus.vim
├── ftplugin/pengus.vim
└── syntax/pengus.vim  (comprehensive syntax highlighting)
```

## 🤝 Contributing

Issues and pull requests are welcome in the repository. Please open an issue
before large changes.

## 📄 License

MIT — see the [LICENSE](./LICENSE) file. © 2026 TuGatito.
