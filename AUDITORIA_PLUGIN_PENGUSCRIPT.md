# 🐧 Auditoría Técnica Completa: `penguscript-nvim`

> **Documento de Diagnóstico y Plan de Optimización**  
> **Proyecto:** `penguscript-nvim` (Soporte oficial para Neovim y LazyVim)  
> **Versión del Toolchain detectada:** PenguScript `2.16.4`  
> **Estado:** 🔍 Auditoría completada — *Sin cambios aplicados en código (Fase de diagnóstico)*  

---

## 📑 Tabla de Contenidos
1. [Resumen Ejecutivo y Diagnóstico Global](#1-resumen-ejecutivo-y-diagnóstico-global)
2. [Rendimiento y Optimización para Archivos Grandes](#2-rendimiento-y-optimización-para-archivos-grandes)
3. [Auditoría del Language Server Protocol (LSP)](#3-auditoría-del-language-server-protocol-lsp)
4. [Auditoría de Sintaxis y Resaltado](#4-auditoría-de-sintaxis-y-resaltado)
5. [Auditoría de Snippets y Estilo Pengunic](#5-auditoría-de-snippets-y-estilo-pengunic)
6. [Auditoría de Comandos: Run, Build, Test, Bind y Formateo](#6-auditoría-de-comandos-run-build-test-bind-y-formateo)
7. [Integración de Primer Nivel con LazyVim](#7-integración-de-primer-nivel-con-lazyvim)
8. [Matriz de Prioridades y Hoja de Ruta de Implementación](#8-matriz-de-prioridades-y-hoja-de-ruta-de-implementación)

---

## 1. 📊 Resumen Ejecutivo y Diagnóstico Global

El plugin `penguscript-nvim` cuenta con una arquitectura base limpia y bien modularizada en Lua (`pengus.init`, `pengus.config`, `pengus.lsp`, `pengus.commands`, `pengus.highlights`, `pengus.snippets`, `pengus.util`) combinada con scripts VimL clásicos (`syntax`, `indent`, `ftdetect`, `ftplugin`).

Sin embargo, tras analizar el código fuente del plugin y contrastarlo con las especificaciones de **`LANGUAGE_Spanish.md`**, **`README-PenguScript.md`** y **`PenguScriptGuideSpanish.md`**, se identifican **6 cuellos de botella y desalineaciones críticas**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       HALLAZGOS PRINCIPALES DE LA AUDITORÍA                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🚨 QUICKFIX CIEGA: Los errores de compilación se insertan como texto plano; │
│    presionar Enter NO salta al archivo, línea ni columna del fallo.         │
│ 🐢 CONGELAMIENTO EN ARCHIVOS LARGOS: Indentación con bucles O(N) sin budget,│
│    syn sync minlines=200 y formateo sincrónico bloqueante (jobwait 30s).     │
│ 🧩 LIBRERÍA ESTÁNDAR OBSOLETA: Faltan 14 de los 40 módulos de la stdlib en  │
│    el archivo de sintaxis (std.json, std.petitio, std.filum, etc.).         │
│ 🔌 FRICCIÓN EN LAZYVIM Y LSP: Doble arranque de clientes, conflicto con    │
│    lspconfig, omisión de blink.cmp (nuevo estándar en LazyVim) y build.pengu│
│ 🪄 PENGU BIND INACCESIBLE: Falla con cabeceras .h al no detectar el archivo │
│    activo ni tener comandos/mapeos en buffers de C/C++.                     │
│ ✂️ SNIPPETS DESALINEADOS: Usan patrones obsoletos o anti-patrones según la   │
│    guía Pengunic (falta or else, or return, with: builders, test con trial).│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. ⚡ Rendimiento y Optimización para Archivos Grandes

> **Contexto:** PenguScript es un lenguaje de sistemas que compila a C. Sus archivos de código fuente y los módulos generados por `pengu expand` (`bundle.c`) suelen tener **miles de líneas**. El editor debe ser instantáneo y no degradarse bajo buffers de 5.000 a 30.000 líneas.

### 2.1 ⚠️ Cuello de Botella en el Cálculo de Indentación (`indent/pengus.vim`)
* **Problema:** En las funciones `s:ChainIndent` (línea 135) y `s:ChainBaseIndent` (línea 157) existen bucles `while l:lnum > 0` que retroceden línea a línea buscando declaraciones padre o el receptor del método. **No existe ningún límite ("budget") de líneas hacia atrás**.
* **Impacto:** En un archivo largo, al presionar `Enter` o `o` dentro de una función en la línea 4.000, Vim puede recorrer miles de líneas hacia arriba en cada salto de línea, causando **micro-congelamientos ("lag") perceptibles al escribir**.
* **Problema secundario:** `s:InTripleStringWindow` (línea 98) lee `getline(l:first, l:last)` de hasta 200 líneas hacia atrás y ejecuta `stridx` en bucle cada vez que se evalúa una línea sin sintaxis.
* **Solución recomendada:**
  1. Imponer un límite de búsqueda estricto (`budget = 50` líneas) en `s:ChainIndent` y `s:ChainBaseIndent`. Si no se encuentra en 50 líneas, asumir la indentación de la línea base previa.
  2. Implementar queries de indentación nativas de Tree-sitter (`queries/pengus/indents.scm`) para Neovim $\ge$ 0.10, reduciendo el cálculo de indentación a tiempo $O(1)$.

### 2.2 ⚠️ Cuello de Botella en el Motor de Sintaxis Clásico (`syntax/pengus.vim`)
* **Problema:**
  - `syn sync minlines=200`: Obliga al motor de sintaxis de Vim a re-evaluar al menos 200 líneas antes de la ventana visible en cada redibujado de pantalla (`scroll`, `jump`).
  - Uso de **lookbehinds costosos**: `syn match pengusFunctionCall "\(\<calling\s\+\)\@<=\<[A-Za-z_][A-Za-z0-9_]*\>"`. Las expresiones regulares con lookbehind hacia atrás (`\@<=`) obligan al motor NFA a rebobinar caracteres continuamente.
  - Regiones anidadas recursivas en `pengusInterpolation`:
    `syn region pengusInterpolation contained matchgroup=pengusInterpolationDelimiter start="{" end="}" contains=...`
    Al contener 18 grupos anidados dentro de comillas dobles y triples, el análisis sintáctico se vuelve exponencial en archivos grandes con muchas plantillas de texto o shaders C en `antiquus`.
* **Solución recomendada:**
  1. Optimizar `syn sync` para sincronizar mediante palabras clave de nivel superior (`syn sync match pengusSync grouphere NONE "^\%(weave\|rune\|echo\|omen\|concept\|bind\|enchanting\)\>"`).
  2. Eliminar el lookbehind costoso en `pengusFunctionCall` transformándolo en un `match` compuesto o delegándolo a Semantic Tokens del LSP.
  3. Promover Tree-sitter como el motor primario con queries optimizadas en `queries/pengus/highlights.scm`.

### 2.3 ⚠️ Cuello de Botella en el Formateo al Guardar (`lua/pengus/commands.lua`)
* **Problema:** `fmt_via_stdin` ejecuta `vim.fn.jobwait({ jid }, timeout_ms)` de manera **completamente sincrónica** en `BufWritePre` con un timeout por defecto de 30 segundos (`format_on_save_timeout = 30000`).
* **Impacto:** Si el archivo tiene 10.000 líneas o el sistema está bajo carga de CPU, Neovim se congela por completo esperando a que el proceso `pengu fmt --stdin` finalice antes de poder guardar.
* **Problema en el reemplazo del buffer:** `replace_buffer` hace:
  ```lua
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  ```
  Sustituir todo el buffer línea a línea destruye los folds, resetea marcas internas, desincroniza el árbol de undo si `undojoin` falla, y provoca parpadeo visual (*flicker*).
* **Solución recomendada:**
  1. Usar formateo basado en diffs de texto mínimos (o delegar a `conform.nvim` / LSP `textDocument/formatting`).
  2. Aplicar los cambios solo en las líneas modificadas (`vim.lsp.util.apply_text_edits`).

---

## 3. 🧠 Auditoría del Language Server Protocol (LSP)

> **Contexto:** El usuario confirmó que el binario de PenguScript está en el PATH (`/home/brackie/pengu/pengu`). El comando para iniciar el servidor es `pengu lsp --stdio`.

### 3.1 🚨 Conflicto Crítico de Clientes Duplicados y LazyVim
* **Diagnóstico actual:** En `lua/pengus/lsp.lua`, el plugin registra un autocomando en `FileType` para arrancar manualmente el cliente mediante `vim.lsp.start` o `vim.lsp.start_client` (`M.maybe_start`). Pero además, `M.register_lspconfig()` registra el servidor en `lspconfig.configs.pengus`.
* **El problema en LazyVim:**
  - LazyVim gestiona todos los servidores LSP a través de `nvim-lspconfig` mediante la tabla `opts.servers`.
  - Si `penguscript-nvim` inicia un cliente por su cuenta en el evento `FileType`, y luego LazyVim inicializa `lspconfig.pengus.setup({})`:
    1. Se pueden instanciar **dos procesos del LSP** para el mismo proyecto.
    2. O peor: el cliente arrancado por `maybe_start` no recibe los keymaps estándar de LazyVim (como `K` para hover, `gd` para definición, `<leader>cr` para rename, diagnósticos integrados en `trouble.nvim`, etc.) porque su callback `on_attach` es independiente del de LazyVim.
* **Solución recomendada:**
  - Detectar si `lspconfig` está presente y delegar el ciclo de vida del cliente a `lspconfig` cuando el usuario esté en LazyVim.
  - Ofrecer una integración nativa en LazyVim mediante un archivo de configuración que simplemente defina `opts.servers.pengus = {}`.

### 3.2 ❌ Marcadores de Raíz Incompletos (`root_markers`)
* **Diagnóstico actual:**
  ```lua
  root_markers = {
    "pengu.yaml",
    "pengu.toml",
    "Pengu.toml",
    "pengu.lock",
    ".pengufmt.toml",
    ".git",
  }
  ```
* **Faltante clave:** En PenguScript $\ge$ 2.16 (documentado en `README-PenguScript.md`, §es-cli), el sistema de construcción de dependencias y proyectos adopta **`build.pengu`** como el archivo preferido de configuración nativa. Muchos paquetes de librerías y bindings C solo contienen `build.pengu`.
* **Solución:** Añadir `"build.pengu"` a la lista de `root_markers`.

### 3.3 🧩 Soporte para Autocompletado Moderno (`blink.cmp` vs `nvim-cmp`)
* **Diagnóstico actual:** En `lua/pengus/lsp.lua` (línea 102), `make_capabilities` únicamente busca `cmp_nvim_lsp`:
  ```lua
  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  if ok and type(cmp.default_capabilities) == "function" then
    caps = cmp.default_capabilities()
  end
  ```
* **El problema:** En las versiones modernas de **LazyVim**, el motor de autocompletado por defecto ya no es `nvim-cmp`, sino **`blink.cmp`**.
* **Impacto:** Al editar PenguScript en LazyVim moderno, las capacidades de completado extendidas (snippets, documentación markdown, resolución de items LSP) **se pierden** porque el plugin no consulta `blink.cmp`.
* **Solución recomendada:**
  ```lua
  local function make_capabilities(user_caps)
    if user_caps then return user_caps end
    local caps = vim.lsp.protocol.make_client_capabilities()
    local ok_blink, blink = pcall(require, "blink.cmp")
    if ok_blink and blink.get_lsp_capabilities then
      return blink.get_lsp_capabilities(caps)
    end
    local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp and cmp.default_capabilities then
      return cmp.default_capabilities(caps)
    end
    return caps
  end
  ```

### 3.4 🚀 Sincronización Incremental de Documentos (`TextDocumentSync`)
* **Diagnóstico:** Para soportar archivos grandes sin latencia en la edición, es fundamental que el cliente solicite y maneje sincronización incremental (`TextDocumentSyncKind.Incremental = 2`).
* En `c.lsp.flags`, la opción `debounce_text_changes = 150` está marcada como deprecada en Neovim 0.10/0.11 en favor del manejo nativo de `vim.lsp`. Debe actualizarse para evitar advertencias de Neovim al iniciar.

---

## 4. 🎨 Auditoría de Sintaxis y Resaltado

### 4.1 🚨 14 Módulos de la Biblioteca Estándar Faltantes
De acuerdo con `README-PenguScript.md` (§es-stdlib), PenguScript 2.x cuenta con **40 módulos en la biblioteca estándar**. En `syntax/pengus.vim` (línea 131) solo hay registrados **26 módulos**.

| Módulo Estándar | Presente en `syntax/pengus.vim` | Categoría | Descripción oficial |
| :--- | :---: | :--- | :--- |
| `std.builder` | ❌ **FALTA** | Texto y datos | `StringBuilder` O(1) amortizado |
| `std.json` | ❌ **FALTA** | Texto y datos | Parser/serializador estricto RFC 8259 y DOM JSON |
| `std.jsonrpc` | ❌ **FALTA** | Texto y datos | JSON-RPC 2.0 y framing LSP `Content-Length` |
| `std.sourcemap` | ❌ **FALTA** | Texto y datos | Traductor offset byte $\leftrightarrow$ (línea, columna) |
| `std.diagnostic`| ❌ **FALTA** | Texto y datos | Spans, labels y renderizado estilo Rust / LSP |
| `std.bitset` | ❌ **FALTA** | Colecciones | Conjunto denso de bits y álgebra booleana |
| `std.arena` | ❌ **FALTA** | Colecciones | Bump allocator para grafos temporales de objetos |
| `std.web` | ❌ **FALTA** | FFI / Web | Puente Emscripten/JS (`eval_js`, consola, timers) |
| `std.petitio` | ❌ **FALTA** | Red / HTTP | Cliente HTTP/1.1 y HTTP/2 con API tipo `requests` |
| `std.compressus`| ❌ **FALTA** | Compresión | gzip, zlib y deflate crudo sobre miniz |
| `std.lingua` | ❌ **FALTA** | Texto | Manejo de codepoints UTF-8 |
| `std.regulus` | ❌ **FALTA** | Regex | Expresiones regulares explícitas (tiny-regex-c) |
| `std.functor` | ❌ **FALTA** | Callbacks | Funciones gruesas (`Fn0`–`Fn3`) con contexto explícito |
| `arca` | ❌ **FALTA** | Assets | Gestor de recursos embebidos |

> [!IMPORTANT]
> Un desarrollador que escriba `import std.json`, `import std.petitio` o `import std.builder` actualmente ve esos módulos sin resaltado de módulo estándar (aparecen en blanco o como identificadores normales).

### 4.2 🔤 Palabras Clave y Operadores Desalineados con `LANGUAGE_Spanish.md`
1. **Bloque `or:`**:
   - En PenguScript, `or:` actúa como manejador estructurado de error/recuperación con bloque propio (similar a `do:` y `unsafe:`).
   - Actualmente `syntax/pengus.vim` solo tiene `do\ze\s*:` y `unsafe\ze\s*:`. Debe añadirse `or\ze\s*:`.
2. **Operadores de expresión y palabras compuestas:**
   - `or else` (operador de fallback con descarte).
   - `or return` (retorno temprano ante `none`/`error`).
   - `is present` / `is not present` (comprobación de presencia en `maybe`).
   - `not in` (pertenencia negada en colecciones).
3. **Conversión de tipos con `to`:**
   - La palabra `to` se usa en conversión de expresiones (`x to string`, `ptr to int`, `val to f64`) y en la definición de `result of T to E`. Actualmente solo está clasificada bajo bucles `pengusRepeat` (`from ... to ... step`).
4. **Atributos y Directivas del Compilador:**
   - En `syntax/pengus.vim`: `syn match pengusAttribute "@[A-Za-z_][A-Za-z0-9_]*"`
   - Atributos oficiales a destacar: `@export("...")`, `@packed`, `@align(N)`, `@noreturn`, `@inline`, `@deprecated`, `@must_use`, `@section("...")`.
5. **Identificadores Privados (`_simbolo`):**
   - Según la especificación (§3.3 de `LANGUAGE_Spanish.md`), cualquier identificador o campo que comience con `_` es estrictamente privado y tiene restricciones de acceso (`E0043`). Destacar estos identificadores mejora enormemente la legibilidad del código de sistemas.

---

## 5. ✂️ Auditoría de Snippets y Estilo Pengunic

### 5.1 ❌ Desalineación con `PenguScriptGuideSpanish.md`
La guía de estilo oficial de PenguScript establece principios claros que los snippets actuales contradicen o ignoran:

| Característica | Práctica en Snippets Actuales | Guía de Estilo Pengunic Oficial | Diagnóstico |
| :--- | :--- | :--- | :--- |
| **Inmutabilidad** | Abusa de `var` mutable en la mayoría de ejemplos. | **§2.6 y §4.3:** Preferir `let` inmutable por defecto. Usar `var` solo si se muta con `set`. | ⚠️ Inconsistente |
| **Inicialización de structs** | Asignaciones campo a campo. | **§4.6:** Usar constructores de expresión `with: campo is val` o `with target:` para mutar. | ❌ Obsoleto |
| **Manejo de errores** | Ramas `if`/`else` manuales para comprobar errores. | **§5:** Usar `or else <val>`, `or return <err>`, o bloques `or:`. | ❌ Anti-patrón |
| **Desempaque de `maybe`** | Comparación manual con `none`. | **§4.8:** Sintaxis idiomática `if v as T is opt:`. | ❌ Falta snippet |
| **C literal (`antiquus`)** | No incluye `@export` de C. | **§20.7:** Bloques `antiquus` en módulos deben llevar `@export` para no ser podados por DCE. | ⚠️ Riesgo de poda |
| **Tests integrados** | Estructura vacía `test "name":`. | **§17:** Usar aserciones de `std.trial` (`trial.assert_eq`, `trial.assert_true`). | ❌ Incompleto |

### 5.2 📦 Snippets Esenciales Faltantes
Faltan snippets para los módulos más utilizados de la biblioteca estándar:
* **`std.spark`**: `spark.println("{var}")`, `spark.print`, `spark.read_line`.
* **`std.json`**: parseo con `json.parse(str)`, serialización con `json.stringify(val)`.
* **`std.petitio`**: peticiones HTTP `Request.new(url) -> send()`.
* **`std.filum`**: creación de hilos y canales tipados (`filum.spawn`, `Channel of T`).
* **`std.builder`**: creación y acumulación eficiente con `StringBuilder`.
* **`std.memoria`**: alocación manual segura con `memoria.alloc` y `defer banish`.

### 5.3 🔌 Soporte de Motores de Snippets en Neovim
* `lua/pengus/snippets.lua` está rígidamente ligado a **LuaSnip**.
* Neovim 0.10+ incorpora **`vim.snippet`** nativo.
* En configuraciones modernas de LazyVim que emplean `blink.cmp` sin LuaSnip, los snippets del plugin no se cargan automáticamente por Lua.
* **Solución:** Aprovechar `package.json` para que `blink.cmp` y `friendly-snippets` descubran `snippets/pengus.json` de forma transparente, y añadir adaptador para `vim.snippet.expand`.

---

## 6. 🛠️ Auditoría de Comandos: Run, Build, Test, Bind y Formateo

### 6.1 🚨 Problema Crítico en Quickfix (`build`, `check`, `test`)
* **Ubicación:** `lua/pengus/commands.lua`:
  ```lua
  local function qf_items(lines)
    local items = {}
    for _, l in ipairs(lines or {}) do
      if l ~= "" then
        table.insert(items, { text = l }) -- ❌ SOLO INSERTA TEXTO PLANO
      end
    end
    return items
  end
  ```
* **Consecuencia:** Cuando `pengu build` o `pengu check` fallan con un error como:
  ```text
  src/main.pengu:14:5 [E0002] Type mismatch: expected 'int', got 'string'
  ```
  La ventana Quickfix de Neovim muestra la línea, pero **NO reconoce el archivo, la línea ni la columna**. Al pulsar `Enter` sobre el error, Neovim **no puede saltar a la ubicación del fallo**.
* **Solución:**
  1. Configurar un `errorformat` (`efm`) adecuado para la salida del compilador de PenguScript:
     ```vim
     %f:%l:%c\ [%t%n]\ %m,%f:%l:%c:\ %m,%E\ \ %f:%l:%c\ %m,%C\ \ \ \ %m,%Z
     ```
  2. O parsear las líneas en Lua mediante expresiones regulares (`filename`, `lnum`, `col`, `text`, `type = "E"|"W"`) antes de poblar la Quickfix.

### 6.2 🏃 Comando `:PenguRun`
* **Diagnóstico actual:** Utiliza `run_in_terminal`, que invoca `vim.fn.termopen(cmd, { cwd = dir })` en un split nuevo (`botright 15new`).
* **Puntos de mejora:**
  1. **Buffers huérfanos:** Cada ejecución de `:PenguRun` abre una nueva ventana terminal sin cerrar ni reutilizar la terminal previa del mismo proceso.
  2. **Configuración de perfil:** `pengu run` soporta `--profile release` y `--profile debug`. El plugin debería facilitar alternar entre perfiles de compilación.
  3. **Integración con LazyVim:** En LazyVim, las terminales se gestionan fluidamente mediante `snacks.terminal` o `toggleterm`.

### 6.3 🧪 Comando `:PenguTest`
* **Diagnóstico actual:** Ejecuta `pengu test` y vuelca la salida en la Quickfix.
* **Oportunidades desaprovechadas del CLI de PenguScript:**
  1. `pengu test --json`: Emite líneas JSON máquina-legibles con resultados detallados de cada bloque `test`. Esto permite renderizar resultados con iconos de éxito/fallo (✅ / ❌) en Neovim.
  2. `pengu test --watch`: Permite modo continuo de tests mientras se guardan archivos. Actualmente el plugin no tiene comando `:PenguTestWatch`.
  3. Integración futura con **`neotest`** (el framework estándar de testing en Neovim).

### 6.4 🪄 Comando `:PenguBind` sobre Cabeceras `.h` (Requisito Específico del Usuario)
* **El usuario solicita:**
  > *"Estaria bien poder ejecutar pengu bind sobre archivos .h que estes editando."*
* **Diagnóstico actual:**
  ```lua
  function M.bind(...)
    local args = append(default_args("bind"), normalize_args(...))
    if #args == 0 then
      notify("Uso: :PenguBind <cabecera.h> [--output FILE]", vim.log.levels.WARN)
      return
    end
    ...
  ```
  - Si el usuario está editando un archivo `include/raylib.h` (cuyo filetype es `c` o `cpp`) y escribe `:PenguBind`:
    1. El plugin lanza una advertencia `"Uso: :PenguBind <cabecera.h>"` y se detiene porque `#args == 0`.
    2. El comando `:PenguBind` solo existe globalmente en `plugin/pengus.vim`, pero no hay autocomandos ni mapeos contextuales para archivos `*.h`.
* **Solución requerida para un desarrollo placentero:**
  1. **Inferencia automática:** Si se ejecuta `:PenguBind` sin argumentos y el buffer actual tiene extensión `.h` o `.hpp`, tomar automáticamente la ruta de dicho archivo:
     ```lua
     local current_file = vim.api.nvim_buf_get_name(0)
     if #args == 0 and current_file:match("%.h$") then
       args = { current_file }
     end
     ```
  2. **Acción dual:**
     - **Modo Inspección (por defecto):** Ejecuta `pengu bind <archivo.h>` y muestra el `.d.pengu` resultante en un split vertical o flotante con resaltado `pengus` para revisarlo al vuelo.
     - **Modo Guardado (`:PenguBindWrite` o flag `--output`):** Genera `<archivo>.d.pengu` en el directorio de cabeceras o en `src/` y lo abre automáticamente para editar.
  3. **Comando disponible en C/C++:** Registrar un atajo o comando contextual (`ftplugin/c.lua` o autocomando para `*.h`) que permita invocar `PenguBind` con un solo toque (ej. `<leader>cb`).

### 6.5 💾 Formateo al Guardar (`format_on_save`)
* **Diagnóstico:**
  - Actualmente `format_on_save` está desactivado por defecto (`false`) en `config.lua`.
  - Al activarse, engancha un autocomando en `BufWritePre` que ejecuta `pengu fmt --stdin` de forma síncrona.
  - En LazyVim, el formateo se realiza mediante **`conform.nvim`**. Un plugin moderno de lenguaje debe proveer la definición del formateador para `conform` para que el formateo al guardar (`<leader>uf` en LazyVim) funcione sin conflictos y de manera asíncrona.

---

## 7. 💤 Integración de Primer Nivel con LazyVim

Para que la experiencia de desarrollo en LazyVim sea inmediata y sin fricciones, el plugin debe poder consumirse como un módulo estándar de LazyVim.

### 7.1 Especificación Recomendada para LazyVim (`plugins/pengu.lua`)
```lua
return {
  -- 1. Plugin base PenguScript
  {
    "TuGatito/penguscript-nvim",
    ft = { "pengus", "c" },
    opts = {
      format_on_save = false, -- En LazyVim se delega a conform.nvim
      lsp = {
        auto_attach = false, -- LazyVim gestiona el LSP a través de nvim-lspconfig
      },
    },
  },

  -- 2. Integración con nvim-lspconfig en LazyVim
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pengus = {
          cmd = { "pengu", "lsp", "--stdio" },
          filetypes = { "pengus" },
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern("pengu.yaml", "pengu.toml", "build.pengu", ".git")(fname)
          end,
        },
      },
    },
  },

  -- 3. Formateo asíncrono con conform.nvim
  {
    "stevearc/conform.nvim",
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

  -- 4. Keymaps organizados con Which-Key
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cp", group = "PenguScript", icon = "🐧" },
        { "<leader>cpb", "<cmd>PenguBuild<cr>", desc = "Compilar (build)" },
        { "<leader>cpr", "<cmd>PenguRun<cr>", desc = "Ejecutar (run)" },
        { "<leader>cpt", "<cmd>PenguTest<cr>", desc = "Ejecutar Tests" },
        { "<leader>cpc", "<cmd>PenguCheck<cr>", desc = "Comprobar tipos (check)" },
        { "<leader>cpB", "<cmd>PenguBind<cr>", desc = "Generar Binding (.h -> .d.pengu)" },
        { "<leader>cpe", "<cmd>PenguExpand<cr>", desc = "Expandir a C (expand)" },
      },
    },
  },
}
```

---

## 8. 🗺️ Matriz de Prioridades y Hoja de Ruta de Implementación

A continuación se resume la matriz de tareas clasificadas por impacto y esfuerzo para la fase de implementación:

| Prioridad | Área | Tarea Diagnóstica | Beneficio |
| :---: | :--- | :--- | :--- |
| **P0 (Urgente)** | **Quickfix** | Parsear la salida del compilador con `efm` o Regex para saltar a línea/columna en `build`, `check` y `test`. | Permite navegar y corregir errores instantáneamente en Neovim. |
| **P0 (Urgente)** | **Rendimiento** | Añadir `budget` a los bucles hacia atrás en `indent/pengus.vim` y evitar `syn sync minlines=200` indiscriminado. | Elimina cuelgues y lag al escribir en archivos largos de miles de líneas. |
| **P1 (Alta)** | **Comandos** | Implementar `PenguBind` inteligente para buffers `.h` (auto-detección y split de previsualización). | Cumple el requerimiento de editar cabeceras C y generar bindings al vuelo. |
| **P1 (Alta)** | **LSP & LazyVim** | Integración con `blink.cmp`, añadir `build.pengu` a `root_markers`, y evitar duplicación de procesos LSP en LazyVim. | Compleción rica, diagnósticos y navegación fluida en LazyVim moderno. |
| **P1 (Alta)** | **Sintaxis** | Incorporar los 14 módulos faltantes de la biblioteca estándar (`json`, `petitio`, `filum`, `builder`, etc.) y palabras clave (`or:`, `or else`). | Resaltado fiel al 100% de la versión oficial del compilador (2.16+). |
| **P2 (Media)** | **Snippets** | Actualizar `snippets/pengus.json` al estilo Pengunic (inmutabilidad `let`, `with:` builders, aserciones `trial`, etc.). | Código idiomático y productividad acelerada al programar. |
| **P2 (Media)** | **Formateo** | Proveer adaptador para `conform.nvim` y formateo asíncrono no destructivo en guardado. | Formateo instantáneo sin congelar la interfaz de Neovim. |
| **P3 (Futuro)** | **Tree-sitter** | Empaquetar gramática Tree-sitter y queries (`highlights.scm`, `indents.scm`). | Rendimiento sub-milisegundo en archivos de más de 50.000 líneas. |

---

> 🐧 **Conclusión de la Auditoría:**  
> El plugin cuenta con una excelente base modular, pero sufre de fricciones típicas de plugins en evolución: falta de parser de errores en la Quickfix, sintaxis desfasada frente al rápido avance de la biblioteca estándar (14 módulos faltantes) y ausencia de optimizaciones para archivos extensos propios de un lenguaje que compila a C. Implementar las mejoras de esta auditoría posicionará a `penguscript-nvim` como un plugin de primer nivel para Neovim y LazyVim.
