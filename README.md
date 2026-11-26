# 🚀 Neovim & LazyVim Configuration

Configuración personalizada de **Neovim** basada en la distribución moderna y modular **[LazyVim](https://lazyvim.github.io/)**, optimizada para desarrollo backend y de sistemas (**Rust** / Python / Java / Go / .NET / Docker), frontend/web (Live Server), integración con GitHub y asistencia por inteligencia artificial mediante **Antigravity CLI (AGY)** y **Kiro CLI**.

---

## 📁 Estructura del Proyecto

```text
~/.config/nvim/
├── init.lua                 # Punto de entrada de Neovim
├── lazyvim.json             # Extras y módulos activos de LazyVim
├── lazy-lock.json           # Bloqueo de versiones y commits de plugins
├── stylua.toml              # Reglas de formato para código Lua (StyLua)
├── .neoconf.json            # Configuración para Neoconf (LSP & linters)
├── README.md                # Documentación de la configuración
└── lua/
    ├── config/              # Configuraciones del núcleo
    │   ├── lazy.lua         # Inicialización del gestor de paquetes lazy.nvim
    │   ├── keymaps.lua      # Atajos de teclado y registro en Which-Key
    │   ├── options.lua      # Opciones globales del editor (vim.opt / vim.g)
    │   └── autocmds.lua     # Comandos automáticos (recarga en segundo plano, etc.)
    │
    └── plugins/             # Módulos y plugins personalizados
        ├── antigravity.lua  # Integración y terminal flotante para Antigravity CLI
        ├── auto-save.lua    # Guardado automático inteligente (auto-save.nvim)
        ├── colorscheme.lua  # Tema visual OneDark (estilo 'darker', transparente para Kitty)
        ├── java.lua         # LSP Java (detección dinámica SDKMAN + Lombok) y generador
        ├── kiro.lua         # Integración y terminal flotante para Kiro CLI (+ indicador en Lualine)
        ├── live-server.lua  # Servidor local con recarga en vivo (live-server.nvim)
        ├── lualine.lua      # Barra de estado con indicador asíncrono de AGY
        ├── octo.lua         # Gestión de Issues, PRs y Notificaciones de GitHub
        ├── python.lua       # Ecosistema Python (basedpyright, ruff, debugpy, pytest, neogen)
        ├── render-markdown.lua # Renderizado enriquecido de Markdown en el búfer
        ├── rust.lua         # Ecosistema Rust (rustaceanvim, crates.nvim, codelldb, neotest y blindajes)
        ├── smear-cursor.lua # Animaciones del cursor (deshabilitadas en Kitty)
        └── snacks.lua       # Configuración centralizada de Snacks (Dashboard y Picker)
```

---

## ⚡ Requisitos y Dependencias

Para el funcionamiento completo de todos los módulos:

1. **Neovim**: `>= 0.10.0` (Probado en `0.12+`).
2. **Nerd Font**: Requerido para iconos en Lualine y Snacks.
3. **Rust & Cargo (`rustup`)**:
   - Toolchain `stable` con `rustc`, `cargo`, `clippy`, `rustfmt` y `rust-src`.
   - `rust-analyzer` instalado vía `rustup component add rust-analyzer` (nunca desde Mason para evitar incompatibilidades de ABI en *proc-macros*).
   - `codelldb` gestionado automáticamente mediante `mason.nvim` para depuración DAP; opcionalmente `cargo-nextest` para ejecución paralela de tests.
4. **Java & SDKMAN**:
   - JDK detectado dinámicamente desde `JAVA_HOME`, `$SDKMAN_DIR/candidates/java/current` o `PATH`.
   - Soporte automático para **Lombok** integrado a través de `mason.nvim`.
5. **Node.js & npm**:
   - Requerido para utilidades web como `live-server`.
6. **Antigravity CLI (`agy`)**:
   - Instalado en `$PATH` para comandos interactivos y análisis de código.
7. **GitHub CLI (`gh`)**:
   - Autenticado (`gh auth login`) para el funcionamiento de `octo.nvim`.
8. **StyLua / Formatters**: Gestionados automáticamente mediante `mason.nvim` y `conform.nvim`.

---

## 🧩 Extras de LazyVim Habilitados (`lazyvim.json`)

| Extra | Descripción |
|---|---|
| `lazyvim.plugins.extras.coding.neogen` | Generación automática de docstrings y anotaciones (`<leader>cn`) |
| `lazyvim.plugins.extras.coding.yanky` | Historial avanzado de portapapeles y pegado cíclico |
| `lazyvim.plugins.extras.dap.core` | Depuración integrada con `nvim-dap`, `nvim-dap-ui` y texto virtual |
| `lazyvim.plugins.extras.editor.refactoring` | Refactorización de código (`extract`, `inline`, debug prints) |
| `lazyvim.plugins.extras.lang.docker` | Soporte para Dockerfile y Docker Compose |
| `lazyvim.plugins.extras.lang.dotnet` | Soporte para C# y .NET (Omnisharp/Roslyn) |
| `lazyvim.plugins.extras.lang.go` | Soporte completo para Go (`gopls`, `gofumpt`, `delve`, `neotest-golang`) |
| `lazyvim.plugins.extras.lang.java` | Soporte completo para Java mediante `nvim-jdtls`, DAP y testing |
| `lazyvim.plugins.extras.lang.json` | Soporte de esquemas JSON con `SchemaStore` |
| `lazyvim.plugins.extras.lang.python` | Soporte profesional para Python (`basedpyright`, `ruff`, `venv-selector`, DAP, Neotest) |
| `lazyvim.plugins.extras.lang.rust` | Soporte profesional para Rust (`rustaceanvim`, `crates.nvim`, `codelldb` DAP y `neotest`) |
| `lazyvim.plugins.extras.lang.toml` | Validación, autocompletado y formato para `Cargo.toml` y `pyproject.toml` (`taplo`) |
| `lazyvim.plugins.extras.lang.yaml` | Validación y autocompletado para YAML |
| `lazyvim.plugins.extras.test.core` | Ejecución y depuración de tests con `neotest` + integración con `trouble.nvim` |
| `lazyvim.plugins.extras.util.mini-hipatterns` | Resaltado de colores hexadecimales e hiperpatrones |

---

## ⌨️ Guía de Atajos de Teclado (Cheat Sheet)

### 🚀 Antigravity (AGY CLI)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>ag` | Normal / Terminal | Abrir/Cerrar terminal interactiva de **AGY CLI** |
| `<leader>af` | Normal | Analizar el archivo actual en una ventana flotante de AGY |
| `<leader>as` | Visual | Enviar el fragmento de código seleccionado a AGY |

### 🤖 Kiro CLI
Integración independiente de Antigravity (`lua/plugins/kiro.lua`). Usa una terminal flotante propia con `kiro-cli chat --trust-workspace` (confía en el proyecto abierto en Neovim) y no fija `--agent` ni `--model`: se usan los valores por defecto de la herramienta.

| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>kk` | Normal / Terminal | Abrir/Cerrar terminal interactiva de **Kiro CLI** |
| `<leader>ke` | Normal / Visual | Editar la selección o línea actual con una instrucción |
| `<leader>ka` | Normal / Visual | Preguntar a Kiro sobre la selección o línea actual |
| `<leader>kf` | Normal | Enviar el archivo actual (instrucción opcional) |
| `<leader>kd` | Normal | Enviar los diagnósticos LSP del archivo para su corrección |
| `<leader>kr` | Normal | Abrir Kiro reanudando la última conversación del directorio (`--resume`) |

Lualine muestra `🤖 Kiro` mientras la sesión de Kiro está activa. Los cambios que Kiro haga en disco se recargan con el autocmd `AgentAutoRead`.

### 🦀 Rust & Gestión de Crates (`rustaceanvim` & `crates.nvim`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>cR` | Normal (`.rs`) | Acciones de código agrupadas de `rust-analyzer` (`RustLsp codeAction`) |
| `<leader>dr` | Normal (`.rs`) | Seleccionar y depurar ejecutable/test de Rust (`RustLsp debuggables`) |
| `<leader>Re` | Normal (`.rs`) | Expandir macro recursivamente (`RustLsp expandMacro`) |
| `<leader>RE` | Normal (`.rs`) | Explicar código de error actual de `rustc` (`RustLsp explainError`) |
| `<leader>Rd` | Normal (`.rs`) | Renderizar diagnóstico completo de Cargo (`RustLsp renderDiagnostic`) |
| `<leader>Rc` | Normal (`.rs`) | Abrir `Cargo.toml` del crate actual |
| `<leader>RD` | Normal (`.rs` / `Cargo.toml`) | Abrir documentación externa en `docs.rs` |
| `<leader>Rp` | Normal (`.rs`) | Navegar al módulo padre (`RustLsp parentModule`) |
| `<leader>Rm` | Normal (`.rs`) | Reconstruir *proc-macros* (`RustLsp rebuildProcMacros`) |
| `<leader>Rr` | Normal (`.rs` / `Cargo.toml`) | Ejecutar *runnables* de Cargo (`.rs`) / Recargar metadatos (`Cargo.toml`) |
| `<leader>Rl` | Normal (`.rs`) | Repetir inmediatamente el último ejecutable de Cargo (`RustLsp! runnables`) |
| `<leader>RL` | Normal (`.rs`) | Repetir inmediatamente la última sesión de depuración (`RustLsp! debuggables`) |
| `<leader>RJ` | Normal (`.rs`) | Unir líneas inteligentemente en Rust (`RustLsp joinLines`) |
| `<leader>Rv` / `<leader>Rf` | Normal (`Cargo.toml`) | Selector interactivo de versiones / *features* del crate (`crates.nvim`) |
| `<leader>Ru` / `<leader>RU` | Normal / Visual (`Cargo.toml`) | Actualizar crate(s) / todos los crates en rango compatible |
| `<leader>Ra` / `<leader>RA` | Normal / Visual (`Cargo.toml`) | Subir crate(s) / todos los crates a última versión mayor (*upgrade*) |
| `<leader>RH` / `<leader>RR` / `<leader>RC` | Normal (`Cargo.toml`) | Abrir Homepage, Repositorio Git o ficha en `crates.io` |
| `<leader>cn` | Normal (`.rs`) | Generar documentación `///` en formato `rustdoc` (`neogen`) |
| `<leader>tr` / `<leader>tt` / `<leader>td` | Normal (`.rs`) | Ejecutar test cercano / archivo / depurar test con DAP (`rustaceanvim.neotest`) |
| `<leader>uh` | Normal | Alternar *Inlay Hints* de tipos, parámetros y cadenas de métodos |

### 🐍 Python, Depuración (DAP), Testing (Neotest) y Refactoring
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>cv` | Normal (Python) | Seleccionar entorno virtual (`venv-selector.nvim`) |
| `<leader>cn` | Normal | Generar docstring en formato Google (`neogen`) |
| `<leader>cf` | Normal / Visual | Ordenar imports y formatear con Ruff (`conform.nvim`) |
| `<leader>db` / `<leader>dB` | Normal | Alternar breakpoint / breakpoint condicional |
| `<leader>dc` / `<leader>da` | Normal | Iniciar o continuar depuración / ejecutar con argumentos |
| `<leader>du` / `<leader>de` | Normal / Visual | Alternar DAP UI / evaluar expresión bajo el cursor |
| `<leader>dPt` / `<leader>dPc` | Normal (Python) | Depurar método o clase de test (`dap-python` + `pytest`) |
| `<leader>tr` / `<leader>tt` | Normal | Ejecutar test más cercano / todos los tests del archivo (`neotest`) |
| `<leader>td` | Normal | Depurar el test más cercano con DAP |
| `<leader>ts` / `<leader>to` | Normal | Panel resumen de tests / ver salida del test |
| `<leader>rf` / `<leader>rx` | Visual | Extraer función / extraer variable (`refactoring.nvim`) |

### ☕ Java & Generación de Código (`java-creator-nvim` & `jdtls`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>jn` | Normal | Crear un nuevo archivo/clase Java interactivamente |
| `<leader>jc` | Normal | Crear nueva `Class` |
| `<leader>ji` | Normal | Crear nueva `Interface` |
| `<leader>je` | Normal | Crear nuevo `Enum` |
| `<leader>jr` | Normal | Crear nuevo `Record` |
| `<leader>co` | Normal | Organizar imports con JDTLS |
| `<leader>cxv` | Normal / Visual | Extraer variable |
| `<leader>cxc` | Normal / Visual | Extraer constante |
| `<leader>cxm` | Visual | Extraer método |

### 🌐 Live Server (`live-server.nvim`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>ls` | Normal | Iniciar servidor de desarrollo en vivo (**Live Server**) |
| `<leader>lx` | Normal | Detener servidor en vivo |

### 💾 Autoguardado (`auto-save.nvim`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>ua` | Normal | Alternar (Toggle) guardado automático activado/desactivado |

### 🐙 GitHub (`octo.nvim` con Snacks Picker)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>oi` | Normal | Listar Issues del repositorio |
| `<leader>op` | Normal | Listar Pull Requests |
| `<leader>od` | Normal | Listar Discusiones de GitHub |
| `<leader>on` | Normal | Listar Notificaciones de GitHub |
| `<leader>os` | Normal | Búsqueda global en GitHub dentro del repo |

---

## ✨ Características y Ajustes Destacados

### 🔄 Autorecarga Inteligente de Búfers
En [lua/config/autocmds.lua](file:///home/rmachicm/.config/nvim/lua/config/autocmds.lua), el autocomando `AgentAutoRead` ejecuta `checktime` al recuperar foco (`FocusGained`), salir de la terminal (`TermLeave`/`TermClose`) o al pausar el cursor (`CursorHold`). Esto asegura que cualquier cambio realizado por un agente de IA o proceso externo se refleje al instante en tu búfer sin riesgo de sobreescritura accidental.

### 💾 Autoguardado No Intrusivo
Con [lua/plugins/auto-save.lua](file:///home/rmachicm/.config/nvim/lua/plugins/auto-save.lua), los cambios se guardan automáticamente al salir del modo inserción (`InsertLeave`) o modificar texto (`TextChanged`). Utiliza `noautocmd = true` para evitar disparar formateadores pesados (como Conform) en cada tipeo, manteniendo un flujo de escritura ágil.

### 🐍 Ecosistema Python Profesional (Backend, APIs y Scripting)
En [lua/plugins/python.lua](file:///home/rmachicm/.config/nvim/lua/plugins/python.lua) y [lua/config/options.lua](file:///home/rmachicm/.config/nvim/lua/config/options.lua), se integra **basedpyright** (tipado estático, *hover* e *inlay hints*) junto con **Ruff** (LSP para diagnósticos/acciones rápidas y `conform.nvim` para `ruff_organize_imports` + `ruff_format`). Además, `nvim-lint` activa **mypy** de forma condicional únicamente cuando el proyecto incluye configuración explícita y un ejecutable en su `.venv`, mientras que `nvim-dap-python` y `neotest-python` quedan listos para trabajar con `debugpy` y `pytest`.

### 🦀 Ecosistema Rust Profesional y Blindaje Anti-Colisión
En [lua/plugins/rust.lua](file:///home/rmachicm/.config/nvim/lua/plugins/rust.lua) y [lua/config/options.lua](file:///home/rmachicm/.config/nvim/lua/config/options.lua), se potencia el extra oficial de LazyVim con **mrcjkb/rustaceanvim** (`cargo clippy --no-deps` al guardar, soporte completo de *proc-macros*, *inlay hints* calibrados y directorio aislado `target/rust-analyzer` vía `cargo.targetDir = true` para evitar bloqueos de compilación frente a `cargo run`/`test` y `auto-save.nvim`), **Saecki/crates.nvim** (LSP en memoria integrado con `blink.cmp` para versiones y *features* en `Cargo.toml`), **CodeLLDB** vía Mason para depuración DAP con *pretty-printers*, **rustaceanvim.neotest** y **neogen** (`rustdoc`). Incluye además **4 capas de blindaje activo** que deshabilitan plugins conflictivos/obsoletos (`rust-tools.nvim`, `neotest-rust`, `rust.vim`), cortocircuitan `rust_analyzer` en `nvim-lspconfig` / `mason-lspconfig` / `vim.lsp.enable` para impedir servidores duplicados y resuelven el binario directamente desde `rustup`.

#### ▶️ Flujo Rápido para Ejecutar un Proyecto Rust
1. **Ejecutar binario o ejemplo (`Cargo Runnables`)**: Presiona **`<leader>Rr`** dentro de cualquier archivo `.rs` para elegir qué binario/ejemplo correr (`cargo run --bin ...`), y **`<leader>Rl`** para **repetir la última ejecución al instante** con un solo atajo.
2. **CodeLens directo sobre `fn main()`**: Coloca el cursor sobre `fn main()` o un test y presiona **`<leader>cc`** para disparar el *Run/Debug* contextual del LSP.
3. **Ejecutar tests sin salir del código**: Presiona **`<leader>tr`** sobre una función `#[test]` para correr ese test, **`<leader>tt`** para todo el archivo o **`<leader>ts`** para abrir el panel lateral de resultados (`neotest`).
4. **Depurar paso a paso (DAP + CodeLLDB)**:
   - **Paso 1 (Breakpoints)**: Coloca el cursor en la línea donde quieras detenerte y presiona **`<leader>db`** (o **`<leader>dB`** para un breakpoint condicional, ej. `x > 10`).
   - **Paso 2 (Iniciar Debug)**:
     - Para depurar el binario principal o ejemplo: presiona **`<leader>dr`** (`RustLsp debuggables`) y elige el target (usa **`<leader>RL`** para repetir la última sesión sin menú).
     - Para depurar un `#[test]` específico: coloca el cursor dentro del test y presiona **`<leader>td`**.
   - **Paso 3 (Navegar y evaluar en vivo)**: Se abrirá automáticamente `nvim-dap-ui` con los valores en línea (*virtual text*). Usa **`<leader>dO`** (*Step Over* / siguiente línea), **`<leader>di`** (*Step Into* / entrar a función), **`<leader>do`** (*Step Out* / salir de función), **`<leader>dc`** (*Continue*), **`<leader>de`** (evaluar variable/expresión bajo el cursor) y **`<leader>dt`** (terminar sesión).

### ☕ Soporte Java con Lombok
En [lua/plugins/java.lua](file:///home/rmachicm/.config/nvim/lua/plugins/java.lua), se detecta automáticamente la presencia de `lombok.jar` descargado por Mason y se inyecta como `-javaagent` al iniciar el servidor de lenguaje **JDTLS**, permitiendo el reconocimiento instantáneo de anotaciones como `@Getter`, `@Setter`, `@Builder`, etc.

### 🔍 Snacks Picker y Dashboard Personalizado
- **Picker y Dashboard** ([lua/plugins/snacks.lua](file:///home/rmachicm/.config/nvim/lua/plugins/snacks.lua)): Búsqueda de archivos configurada para incluir dotfiles/archivos ocultos (`hidden = true`) y pantalla de bienvenida personalizada con arte ASCII.

---

## 🛠️ Cómo Agregar o Modificar Plugins

Cada nuevo archivo dentro de `lua/plugins/` es cargado automáticamente por `lazy.nvim`.

Para añadir un plugin nuevo, crea un archivo en `lua/plugins/nombre-plugin.lua`:
```lua
return {
  {
    "autor/repositorio-plugin",
    event = "VeryLazy",
    opts = {
      -- opciones de configuración
    },
  },
}
```
