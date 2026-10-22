# 🐧 penguscript-nvim

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-blue.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)](https://neovim.io)
[![PenguScript](https://img.shields.io/badge/PenguScript-2.16+-orange.svg)](https://github.com/TuGatito/PenguScript)

**Soporte oficial y de primer nivel de PenguScript para Neovim y LazyVim** — LSP integrado, diagnósticos navegables en Quickfix, detección de filetype, resaltado de sintaxis completo, sangría automática optimizada para archivos grandes, comandos `:Pengu*` y catálogo de snippets Pengunic. 

Ligero, sin dependencias obligatorias y compatible con Neovim **0.8+** en Linux, macOS y Windows.

> [!NOTE]
> Diseñado específicamente para el toolchain y especificación oficial de **PenguScript 2.0+** (cubriendo `LANGUAGE_Spanish.md` y la Guía de Estilo Pengunic).

---

## ✨ Características

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

## 📦 Requisitos

- **Neovim** $\ge$ 0.8 (recomendado 0.10+ para Treesitter nativo).
- Binario [`pengu`](https://github.com/TuGatito/penguscript) en tu `$PATH` (o configurado vía `bin_path`).

---

## 🚀 Instalación

Dirección del repositorio:  
`https://github.com/TuGatito/penguscript-nvim`

### 💤 LazyVim

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

### ⚡ Lazy.nvim (Neovim independiente)

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

### 📦 Packer.nvim

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

### 🔌 vim-plug

```vim
Plug 'TuGatito/penguscript-nvim'
```

Y en tu archivo `init.lua`:
```lua
require("pengus").setup {}
```

### 📁 Manual

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

---

## ⚙️ Configuración

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

## ⌨️ Comandos

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

## 🪄 Generación de Bindings C (`:PenguBind`)

El flujo de trabajo con cabeceras de C está totalmente optimizado:

1. Abre cualquier archivo de cabecera C (`.h` o `.hpp`), por ejemplo `include/raylib.h`.
2. Ejecuta `:PenguBind` (sin argumentos) o pásale opciones adicionales como `:PenguBind --prefix raylib_`.
3. El plugin invoca `pengu bind`, detecta automáticamente el archivo activo y abre el binding `.d.pengu` generado en un **split vertical** listo para programar.

---

## 📐 Filetype y Sangría

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

## ✂️ Catálogo de Snippets

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

## 📁 Estructura del Repositorio

```
penguscript-nvim/
├── README.md                          # Guía de uso e instalación
├── AUDITORIA_PLUGIN_PENGUSCRIPT.md    # Reporte de auditoría y diagnóstico técnico
├── LICENSE                            # Licencia MIT
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

## 📄 Licencia

Distribuido bajo la licencia **MIT**. Consulta el archivo [`LICENSE`](./LICENSE) para más información.  
© 2026 TuGatito.
