# 🐧 penguscript-nvim

**Soporte completo de PenguScript para Neovim** — LSP integrado, detección de
filetype, resaltado de sintaxis, comandos `:Pengu*` y snippets. Ligero, sin
dependencias obligatorias y compatible con Neovim **0.8+** en Windows, Linux y
macOS.

> Cubre el lenguaje y el toolchain **PenguScript 2.0.x** (referencia del lenguaje
> y guía de estilo Pengunic).

---

## ✨ Características

- **Servidor LSP automático**: registra el servidor `pengus` (`pengu lsp --stdio`)
  y lo arranca al abrir un archivo `.pengu` / `.d.pengu`, sin necesidad de
  nvim-lspconfig (y se integra con él si está instalado).
- **Detección de la raíz del proyecto** (`root_pattern`): `pengu.yaml`,
  `pengu.toml`, `Pengu.toml`, `pengu.lock`, `.pengufmt.toml` y `.git`.
- **Filetype `pengus`** para `.pengu` y `.d.pengu` (mecanismo doble:
  `vim.filetype.add` + `ftdetect`).
- **Resaltado de sintaxis completo de 2.0** en `syntax/pengus.vim`: palabras
  clave (incluidas `antiquus`, `unsafe:`, `do:`, `many`, `shard`, `where`),
  palabras clave blandas (`frozen`, `inline`, `ritual`), los 12 conceptos
  integrados (`Num`, `Integrum`, `Real`, `Par`, `Ordo`, `Vinculum`, `Imago`,
  `Nexus`, `Forma`, `Iterabilis`, `Donum`, `Any`), todos los alias de primitivos
  (`int8_t`…`uint64_t`, `short`, `long`, `uint`, `usize`, `isize`, `intptr_t`…),
  contenedores (`list`, `slice`, `map`, `maybe`, `result`, `array`, `ref`), los
  **27 módulos de la biblioteca estándar** y `arca`, atributos
  (`@noreturn`, `@export`, `@deprecated`, `@inline`, `@cold`, `@packed`,
  `@align`), interpolación `"{var}"`, cadenas raw `r"..."`, triples
  `"""..."""` (y sus variantes raw) y operadores (incluidas las
  asignaciones compuestas y el postfijo `at`). Si hay un parser Treesitter
  `pengus` y Neovim ≥ 0.10, el plugin lo usa automáticamente.
- **Sangría automática consciente de la sintaxis** (`indent/pengus.vim`):
  bloques por `:` (incluidos `with:`, `do:`, `or:`, `unsafe:`, `antiquus`),
  alineación de ramas (`else`, `else when`, `when … ->`, `or:`), continuación de
  cadenas de métodos (`.eslabón` / `->eslabón`) y **cuerpos de C literales a
  columna 0** dentro de literales triples.
- **Comandos** para todo el toolchain `pengu`: compilación, ejecución, tests,
  formato, documentación, bindings, assets, benchmarks y mantenimiento del
  proyecto (ver la tabla de comandos).
- **Formato al guardar** (`pengu fmt --stdin`) sin archivos temporales y sin
  perder cambios sin guardar.
- **161 snippets** en formato VS Code (`snippets/pengus.json`), válidos para
  LuaSnip, LazyVim, blink.cmp, mini.snippets, etc.
- **Sin dependencias externas**: solo necesitas el binario `pengu`.
  nvim-lspconfig, cmp-nvim-lsp y LuaSnip se usan únicamente si están instalados.

## 📦 Requisitos

- Neovim ≥ 0.8 (se recomienda 0.10+ para Treesitter nativo).
- El binario [`pengu`](https://github.com/TuGatito/penguscript) en el `$PATH`
  (o su ruta configurada, ver más abajo), versión **2.0.x**.

## 🚀 Instalación

### Lazy.nvim

Crea el archivo `~/.config/nvim/lua/plugins/pengus.lua` (en Windows:
`~/AppData/Local/nvim/lua/plugins/pengus.lua`). Lazy.nvim carga automáticamente
todos los archivos dentro de `lua/plugins/`:

```lua
-- ~/.config/nvim/lua/plugins/pengus.lua
return {
  "TuGatito/penguscript-nvim", -- Sustituye por tu usuario/repositorio
  -- Añade LuaSnip como dependencia SOLO si quieres los snippets:
  dependencies = {
    "L3MON4D3/LuaSnip", -- opcional, solo para snippets
  },
  config = function()
    require("pengus").setup {
      -- Todas las opciones son opcionales:
      -- bin_path = "C:/tools/pengu.exe", -- si `pengu` no está en el PATH
      -- format_on_save = true,           -- formatear al guardar
      -- snippets = true,                 -- snippets en LuaSnip (por defecto: true)
      -- lsp = {
      --   on_attach = function(client, bufnr)
      --     -- tus keymaps de LSP aquí
      --   end,
      -- },
    }
  end,
}
```

### LazyVim

Si usas [LazyVim](https://lazyvim.org), crea `~/.config/nvim/lua/plugins/pengus.lua`:

```lua
return {
  -- Plugin PenguScript
  {
    "TuGatito/penguscript-nvim",
    ft = { "pengus", "c", "cpp" },
    opts = {
      format_on_save = false, -- En LazyVim se delega a conform.nvim
    },
  },

  -- Servidor LSP mediante nvim-lspconfig
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

  -- Formateo automático con conform.nvim
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

  -- Atajos contextuales con which-key
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cp", group = "PenguScript", icon = "🐧" },
        { "<leader>cpb", "<cmd>PenguBuild<cr>", desc = "Compilar (build)" },
        { "<leader>cpr", "<cmd>PenguRun<cr>", desc = "Ejecutar (run)" },
        { "<leader>cpt", "<cmd>PenguTest<cr>", desc = "Tests" },
        { "<leader>cpw", "<cmd>PenguTestWatch<cr>", desc = "Tests continuos (watch)" },
        { "<leader>cpc", "<cmd>PenguCheck<cr>", desc = "Comprobar tipos (check)" },
        { "<leader>cpB", "<cmd>PenguBind<cr>", desc = "Generar Binding C (.h)" },
        { "<leader>cpe", "<cmd>PenguExpand<cr>", desc = "Expandir a C (expand)" },
      },
    },
  },
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

" Opcional: genera las etiquetas de ayuda para que :help pengus funcione
Plug 'TuGatito/penguscript-nvim', { 'do': ':helptags ALL' }
```

```lua
-- En tu configuración Lua (init.lua / tras plug#begin):
require("pengus").setup {}
```

### Manual (sin gestor de plugins)

```bash
git clone https://github.com/TuGatito/penguscript-nvim.git \
  ~/.local/share/nvim/site/pack/vendor/start/penguscript-nvim
nvim --headless "+helptags ALL" +qa
```

Añade esto a tu configuración y el plugin queda activo con sus valores por
defecto (no hace falta llamar a `setup()` si te sirven):

```lua
require("pengus").setup {} -- opcional
```

## ⚙️ Configuración

La configuración es opcional: sin `setup()` el plugin funciona con sus valores
por defecto (LSP automático incluido).

```lua
require("pengus").setup {
  -- Ruta al binario `pengu`. Si no se indica, se resuelve en este orden:
  --   vim.g.pengus_bin_path  ->  $PENGU_BIN_PATH  ->  "pengu" (PATH)
  bin_path = nil,

  -- Filetypes que gestiona el plugin.
  filetypes = { "pengus" },

  -- Arranca el LSP automáticamente al abrir un archivo PenguScript.
  auto_attach = true,

  -- Registra `pengus` en lspconfig.configs cuando nvim-lspconfig está disponible.
  register_lspconfig = true,

  -- Marcadores para detectar la raíz del proyecto (root_pattern).
  root_markers = { "pengu.yaml", "pengu.toml", "Pengu.toml", "build.pengu", "pengu.lock", ".pengufmt.toml", ".git" },

  lsp = {
    name = "pengus",
    args = { "lsp", "--stdio" },
    settings = {},                      -- ajustes enviados al servidor
    handlers = nil,                     -- handlers LSP adicionales
    on_attach = function(client, bufnr) -- tu on_attach (keymaps, etc.)
      -- vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    end,
    capabilities = nil,   -- si no se indica: make_client_capabilities()
                          -- ampliado con cmp-nvim-lsp (si está instalado)
    flags = { debounce_text_changes = 150 },
    env = nil,            -- variables de entorno extra para el servidor
    log_level = nil,      -- p. ej. vim.lsp.log_levels.DEBUG
  },

  commands = {
    -- Directorio donde se ejecutan los comandos:
    --   "project" -> raíz del proyecto del buffer
    --   "buffer"  -> directorio del archivo actual
    --   "cwd"     -> directorio actual de Neovim (por defecto)
    cwd = "cwd",
    run = { split = "botright", size = 15, args = nil },
    watch = { split = "botright", size = 15, args = nil },
    build = { args = nil },
    check = { args = nil },
    test = { args = nil },
    fmt = { args = nil },
    -- Cualquier otro subcomando acepta también `args = { ... }` aquí
    -- (doc, bind, assets, benchmark, expand, time, doctor, init, add,
    --  update, clean, gc, eval).
  },

  -- Formatea con `pengu fmt --stdin` al guardar. true, false o { args = {...} }.
  format_on_save = false,
  format_on_save_timeout = 5000, -- ms (máximo para evitar bloqueos)

  highlight = {
    treesitter = "auto",  -- true | false | "auto" (usa el parser si existe)
    colors = {},          -- sobrescritura de grupos, p. ej.:
    -- colors = { PengusKeyword = { fg = "#c586c0", bold = true } }
  },

  -- Registra los snippets en LuaSnip si está instalado.
  snippets = true,

  -- Mensajes mediante vim.notify.
  notify = true,
}
```

> **Atajos**: también puedes pasar `on_attach`, `capabilities` y `settings` en el
> nivel superior de `opts`; el plugin los reenvía a la sección `lsp`.

### Cambiar la ruta del binario

```lua
-- Opción 1: dentro de setup()
require("pengus").setup { bin_path = "/ruta/a/pengu" }

-- Opción 2: variable global (clásica)
vim.g.pengus_bin_path = "C:/tools/pengu.exe"

-- Opción 3: variable de entorno
--   export PENGU_BIN_PATH=/ruta/a/pengu
```

## ⌨️ Comandos

| Comando | Descripción |
| ------- | ----------- |
| `:PenguBuild [args...]` | `pengu build [args...]`; la salida va a la quickfix. |
| `:PenguRun [script] [args...]` | `pengu run` en una terminal (modo proyecto o script). |
| `:PenguCheck [args...]` | `pengu check [args...]`; diagnósticos navegables en quickfix. |
| `:PenguTest [args...]` | `pengu test [args...]`; resultado navegable en quickfix. |
| `:PenguTestWatch [args...]` | `pengu test --watch`; ejecuta tests de forma continua ante cambios. |
| `:PenguWatch [script]` | `pengu watch`: recompila y reejecuta al cambiar fuentes. |
| `:PenguTime [script]` | `pengu time`: tiempos por fase (imports, check, codegen, C, ejecución). |
| `:PenguEval <expr>` | `pengu eval "<expr>"`: evalúa una expresión y la notifica. |
| `:PenguExpand [file]` | `pengu expand`: muestra el `bundle.c` generado en un split. |
| `:PenguFmt [args...]` | Formatea el buffer con `pengu fmt --stdin` de forma eficiente. |
| `:PenguDoc [args...]` | `pengu doc`: genera la documentación Markdown del proyecto. |
| `:PenguBind [header]` | `pengu bind`: genera `.d.pengu` desde cabeceras C (auto-detecta `.h` activo y abre split). |
| `:PenguAssets [--list]` | `pengu assets`: inspecciona o regenera los assets embebidos. |
| `:PenguBench [args...]` | `pengu benchmark`: arnés de benchmarks del proyecto. |
| `:PenguInit <name>` | `pengu init`: crea un proyecto nuevo. |
| `:PenguAdd <url>` | `pengu add`: instala un módulo o binding externo. |
| `:PenguUpdate` | `pengu update`: actualiza las dependencias. |
| `:PenguClean` | `pengu clean`: limpia `build/` y las cachés. |
| `:PenguGc` | `pengu gc`: recoge los binarios de script en caché. |
| `:PenguDoctor` | `pengu doctor`: diagnóstico del toolchain y del proyecto. |
| `:PenguVersion` | `pengu -V`: muestra la versión del toolchain. |
| `:PenguLspStart` | Arranca el LSP en el buffer actual. |
| `:PenguLspRestart` | Reinicia el servidor LSP. |
| `:PenguLspLog` | Abre el archivo de log del LSP. |

También hay equivalentes Lua (`require("pengus").build()`, `.run()`,
`.check()`, `.test()`, `.watch()`, `.time()`, `.eval()`, `.expand()`,
`.format()`, `.doc()`, `.bind()`, `.assets()`, `.benchmark()`, `.init()`,
`.add()`, `.update()`, `.clean()`, `.gc()`, `.doctor()`, `.version()`,
`.restart()`, `.open_log()`), que aceptan una tabla de argumentos o varargs.

## 🧠 LSP

- El servidor se registra con el nombre **`pengus`**.
- El arranque es **automático** al abrir archivos con filetype `pengus`
  (desactívalo con `auto_attach = false` y usa `:PenguLspStart`).
- Las capacidades del cliente habilitan completado, hover, definición,
  referencias, renombrado, diagnósticos, símbolos, acciones de código y formato
  de documento, tal como los anuncia el servidor. Añade tus keymaps con
  `lsp.on_attach`.
- Si **nvim-lspconfig** está instalado, `require("lspconfig").pengus.setup {}`
  también funciona (el plugin lo registra por su cuenta). Puedes gestionar el
  servidor con lspconfig y desactivar el arranque automático del plugin:

```lua
-- Usuario que prefiere gestionarlo todo con lspconfig:
require("pengus").setup { auto_attach = false }
require("lspconfig").pengus.setup {
  on_attach = function(client, bufnr) ... end,
}
```

## 📐 Filetype, sintaxis y sangría

| Extensión | Filetype |
| --------- | -------- |
| `foo.pengu` | `pengus` |
| `foo.d.pengu` | `pengus` |

- **Sintaxis** (`syntax/pengus.vim`): cobertura de PenguScript 2.0.x — palabras
  clave y blandas, conceptos integrados, alias de primitivos y contenedores, los
  27 módulos de `std.*` y `arca`, atributos, comentarios `#` / `##`,
  interpolación `"{expr}"`, cadenas raw y triples, caracteres, números
  (hex/binarios/flotantes) y operadores. Con un parser Treesitter `pengus`
  instalado y Neovim ≥ 0.10, el plugin puede usarlo automáticamente
  (`highlight.treesitter = "auto"`).
- **Sangría** (`indent/pengus.vim`): **4 espacios**, nunca tabuladores (la
  convención oficial y lo que impone `pengu fmt`). Abre un nivel tras cualquier
  `:` de bloque; alinea `else`, `else when`, `else ->`, `when … ->` y `or:`;
  sangra las continuaciones de cadenas de métodos; y deja el **C de los bloques
  `antiquus` a columna 0**.
- **Comentarios**: `#` normal, `##` de documentación (los usa `pengu doc` y el
  hover del LSP).

## ✂️ Snippets

Los snippets están en **formato VS Code** en `snippets/pengus.json` (una única
fuente de verdad) y los carga cualquiera de los motores habituales: LuaSnip
(mediante el cargador de VS Code, que respeta el `package.json` del plugin),
LazyVim, `blink.cmp`, `mini.snippets`, etc. `lua/pengus/snippets.lua` solo
conecta ese catálogo con LuaSnip y, si su cargador de VS Code no estuviera
disponible, registra el mismo catálogo con un conversor propio.

Los cuerpos usan 4 espacios, la indentación oficial de PenguScript.

| Trigger | Expansión / Descripción |
| ------- | ----------------------- |
| `main` | Punto de entrada `main` con retorno int |
| `mainv` | Punto de entrada `main` sin retorno (void) |
| `weave` | Declaración de función con parámetros y tipo de retorno |
| `weaveno` | Declaración de función sin parámetros |
| `weavein` | Función con modificador `inline` (always_inline en C) |
| `inlineweave` | Función con `inline` antepuesto a `weave` |
| `weaverit` | Método ritual estático (constructor `new`, `from_*`, `with_*`) |
| `weaveshard` | Función genérica con un parámetro `shard` |
| `weaveshardwhere` | Función genérica con bounds `where T: Concept` |
| `weaveshard2` | Función genérica con dos parámetros de tipo |
| `weavemany` | Función variádica segura respaldada por slice (`many T`) |
| `declare` | Prototipo de función externa de C (sin cuerpo y sin `:`) |
| `declarevar` | Prototipo de C con argumentos variádicos crudos (`...`, solo en `declare`) |
| `lambda` | Función anónima con parámetros tipados |
| `lambdano` | Función anónima sin parámetros |
| `antiquus` | Función con cuerpo C literal (el C va a columna 0) |
| `antiquusexport` | `antiquus` con símbolo C estable, raíz del DCE |
| `rune` | Definición de estructura (rune / struct de C) |
| `runeshard` | Estructura genérica con parámetro `shard` |
| `runederive` | `rune` con implementaciones automáticas de concepts |
| `runecyclus` | `cyclus` recursivo con indirección por puntero |
| `runecyclusg` | `cyclus` genérico (lista enlazada / árbol) |
| `runepacked` | `rune` sin relleno: solo para fronteras binarias |
| `runealign` | `rune` con alineación explícita (SIMD, DMA, ...) |
| `echo` | Unión de C (`echo`); leerla emite el warning W0002 |
| `omen` | Enum numérico con valores explícitos |
| `omenstr` | Omen cuyas variantes evalúan a su propio nombre (sin payloads) |
| `omenpayload` | Tipo suma con cargas útiles por variante |
| `concept` | Contrato de compile-time (los miembros no llevan cuerpo ni `:`) |
| `conceptshard` | Contrato genérico parametrizado con `shard` |
| `conceptwhere` | Concept genérico restringido por otro concept |
| `bind` | Implementación de un concept para un tipo |
| `enchanting` | Bloque `enchanting` con un método de instancia y un `ritual` |
| `enchantingshard` | `enchanting` genérico sobre un contenedor estándar (monomorfizado) |
| `enchantingprim` | `enchanting` genérico de primitivos; aquí `self` es un valor |
| `enchantingconcrete` | Bloque concreto que tiene prioridad sobre el genérico |
| `alias` | Alias estructural transparente |
| `seal` | Newtype fuerte: exige conversiones explícitas con `to` |
| `opaque` | Handle C incompleto, usado siempre tras `ref to` |
| `fnalias` | Alias de tipo función (`FnType`) |
| `let` | Binding local inmutable con tipo explícito |
| `letin` | Binding local inmutable con tipo inferido |
| `var` | Variable local mutable con tipo explícito |
| `varin` | Variable local mutable con tipo inferido |
| `letmaybe` | Binding de un `maybe T` presente (el tipo lo infiere el valor) |
| `destructlet` | Desestructuración de rune, array, slice o list |
| `destructvar` | Desestructuración mutable con tipo por elemento |
| `destructtuple` | Desestructuración de un retorno múltiple (tupla) |
| `const` | Constante top-level plegada en compile-time (nunca `let`/`var`) |
| `static` | Estado persistente entre llamadas (patrón de módulo con estado) |
| `some` | Constructor de `maybe T` con valor presente |
| `maybenone` | Constructor de `maybe T` vacío |
| `donum` | Valor cero/por defecto de un tipo (compound literal de C) |
| `set` | Reasignación de un objetivo mutable |
| `setdot` | Asignación de campo dentro de un bloque `with:` |
| `setarrow` | Mutación de un campo de `self` dentro de un método |
| `setat` | Asignación a un contenedor indexado (los paréntesis del índice importan) |
| `setessence` | Escritura a través de un puntero (`*ptr = valor`) |
| `setadd` | Asignación compuesta numérica (+=); nunca con strings |
| `setsub` | Asignación compuesta numérica (-=) |
| `setmul` | Asignación compuesta numérica (*=) |
| `setdiv` | Asignación compuesta numérica (/=) |
| `setmod` | Asignación compuesta de módulo (%=), solo enteros |
| `setband` | Asignación compuesta bit a bit (&=) |
| `setbor` | Asignación compuesta bit a bit (|=) |
| `setbxor` | Asignación compuesta bit a bit (^=) |
| `setshl` | Asignación compuesta de desplazamiento (<<=) |
| `setshr` | Asignación compuesta de desplazamiento (>>=) |
| `if` | Condicional `if` |
| `ifelse` | Condicional `if` / `else` |
| `ifmaybe` | Desempaqueta un `maybe T` con binding tipado (forma Pengunic) |
| `ifexpr` | Expresión `if ... then ... else ...` en una línea |
| `ifvalue` | Bloque `if` que produce un valor |
| `unless` | `unless` equivale a `if not cond` |
| `unlesselse` | `unless` con rama `else` |
| `while` | Bucle `while` |
| `for` | Iteración sobre array, list, slice, string, map o rango |
| `forin` | Iteración sobre una colección |
| `foridx` | Iteración con índice (o `_` para descartarlo) |
| `forfrom` | Rango numérico semiabierto `[0, 10)` |
| `forstep` | Rango numérico con paso (admite `step` negativo) |
| `forrange` | Iteración sobre un rango `a to b` |
| `forcomp` | List comprehension `for ... then ...` |
| `forcompwhen` | List comprehension filtrada `for ... when ... then ...` |
| `judge` | Coincidencia de patrones exhaustiva |
| `when` | Rama de un `judge` (también sirve para literales) |
| `whenpayload` | Extrae la carga útil de una variante de `omen` |
| `whenguard` | Patrón con guarda `if <cond>` |
| `do` | Bloque de valor: evalúa a su última expresión |
| `unsafe` | Opt-out de comprobaciones de límites (emite el warning W0007) |
| `withblock` | Construcción de un `rune` con bloque `with:` |
| `withtarget` | Mutación in-place de un valor o colección existente |
| `withcol` | Bloque `with` con métodos abreviados de contenedor |
| `withnested` | Constructor `with:` anidado (infiere el tipo destino) |
| `withlit` | Literal de struct con campos explícitos |
| `withshort` | Forma corta: el campo toma el binding del mismo nombre (no convierte tipos) |
| `mapindent` | Literal de mapa con sintaxis de bloque indentado |
| `structindent` | Literal de struct con sintaxis de bloque indentado |
| `arrayindent` | Array multidimensional con sintaxis de bloque indentado |
| `calling` | Llamada a función o método con argumentos |
| `call` | Llamada sin argumentos (`calling` es obligatorio) |
| `callingof` | Argumento de tipo explícito cuando la inferencia no puede verlo |
| `callingnamed` | Argumentos con nombre (`name is valor`) |
| `chain` | Cadena de métodos: un eslabón por línea; el `with` es del último |
| `banish` | Liberación explícita de memoria del heap (nunca sobre vistas) |
| `defer` | Ejecución diferida al salir del ámbito (LIFO) |
| `deferbanish` | Libera al salir del ámbito (el idioma canónico de limpieza) |
| `defercall` | Recursos de C se liberan con SU cleanup, no con `banish` |
| `errdefer` | Limpieza solo en la ruta de retorno de error |
| `errdeferbanish` | Libera solo si la función termina devolviendo error |
| `try` | Desempaqueta o propaga el fallo; exige retorno `maybe`/`result` |
| `orelse` | Valor o alternativa perezosa si falta o falla |
| `orreturn` | Devuelve de inmediato y ejecuta `defer`/`errdefer` |
| `orblock` | Manejo rico del fallo; `error` solo existe dentro del bloque |
| `sigil` | Toma la dirección de un lvalue (`&x`) |
| `essence` | Desreferencia un puntero (`*ptr`) |
| `bytesof` | Préstamo de bytes: `ref to frozen byte` para string, `ref to byte` para arrays |
| `transmute` | Reinterpretación a nivel de bits; siempre emite el warning W0001 |
| `sizeof` | Tamaño en bytes en compile-time (devuelve `usize`) |
| `ord` | Valor del byte de una cadena de un carácter |
| `chr` | Cadena de un carácter a partir de un código 0–255 |
| `memalloc` | Reserva un valor del heap con `std.memoria` (zeroed por defecto) |
| `memallocarray` | Array del heap con liberación diferida |
| `memfill` | Relleno tipado de un búfer reservado con `std.memoria` |
| `test` | Bloque de prueba unitaria nativo (`pengu test`) |
| `testassert` | Aserción de `std.ward` dentro de un bloque `test` |
| `whencc` | `when` de compile-time (declaraciones o sentencias) |
| `whenchain` | Cadena de compilación condicional con rama de reserva |
| `whenexpr` | Ternario evaluado en compile-time |
| `whendebug` | Bloque compilado solo con el perfil `debug` |
| `whendefined` | Compilación condicional según un `-D NAME` |
| `attrnoreturn` | Weave `into void` que nunca retorna (exige garantía real) |
| `attrexport` | Fija el símbolo C emitido; usa prefijo `pengu_<módulo>_` |
| `attrdeprecated` | Marca un símbolo como obsoleto con motivo y reemplazo |
| `attrinline` | Fuerza la inclusión en línea en el C generado |
| `attrcold` | Marca una ruta fría para el optimizador de C |
| `attrpacked` | Elimina el relleno del `rune` (solo en fronteras binarias) |
| `attralign` | Fija la alineación (potencia de dos entre 1 y 128) |
| `import` | Importación de módulo |
| `importas` | Importación con alias (solo si colisiona o es muy largo) |
| `include` | Inclusión de cabecera de C (`#include`) |
| `link` | Directiva de enlazado de una librería de C |
| `insignia` | Prefija los símbolos C del módulo (evita colisiones) |
| `print` | Builtin `print` del compilador (se traduce a `printf`) |
| `println` | Imprime con salto de línea mediante `std.spark` |
| `printspark` | Imprime sin salto de línea mediante `std.spark` |
| `eprintln` | Imprime en stderr mediante `std.spark` |
| `interp` | Interpolación `{expr}`: la única forma de componer strings |
| `arcastr` | Copia con posesión del recurso embebido (libérala con `banish`) |
| `arcaptr` | Puntero directo a `.rodata` (vista: nunca `banish`) |
| `arcabytes` | Vista `slice of byte` sin posesión (nunca `banish`) |
| `arcasize` | Tamaño en bytes del recurso embebido (0 si no existe) |
| `ffislice` | Vista `slice` sobre un búfer de C (no propietaria) |
| `ffistr` | Convierte un `char*` terminado en NUL en un `string` propio |
| `fficstr` | Obtiene un `ref to char` sin posesión desde un `string` |
| `ffibytes` | Vista de bytes sobre un `string` de PenguScript |
| `docmod` | Docstring de módulo obligatorio, antes de cualquier directiva |
| `docfn` | Docstring de función con las secciones canónicas |
| `doctype` | Docstring de `rune` / `omen` / `seal` con invariantes y memoria |
| `docmem` | Sección de memoria para documentar la propiedad |
| `docantiquus` | Docstring obligatorio de un `antiquus` público |

## 📁 Estructura del repositorio

```
penguscript-nvim/
├── README.md
├── LICENSE            (MIT)
├── package.json       (manifiesto para el descubrimiento de snippets)
├── doc/pengus.txt     (documentación :help)
├── snippets/
│   └── pengus.json    (snippets en formato VS Code, 4 espacios)
├── indent/
│   └── pengus.vim     (sangría automática)
├── lua/pengus/
│   ├── init.lua       (punto de entrada / API pública)
│   ├── config.lua     (opciones por defecto y mezcla)
│   ├── lsp.lua        (configuración del LSP)
│   ├── commands.lua   (comandos :Pengu* y formato)
│   ├── highlights.lua (Treesitter opcional y colores)
│   ├── snippets.lua   (carga del catálogo de snippets)
│   └── util.lua       (utilidades internas)
├── plugin/pengus.vim  (comandos y carga automática)
├── ftdetect/pengus.vim
├── ftplugin/pengus.vim
└── syntax/pengus.vim  (resaltado de sintaxis)
```

## 🤝 Contribuir

Las issues y los pull requests son bienvenidos en el repositorio. Abre una issue
antes de cambios grandes.

## 📄 Licencia

MIT — consulta el archivo [LICENSE](./LICENSE). © 2026 TuGatito.
