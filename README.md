# 🚀 Neovim & LazyVim Configuration

Configuración personalizada de **Neovim** basada en la distribución moderna y modular **[LazyVim](https://lazyvim.github.io/)**, optimizada para desarrollo backend y de sistemas (**Rust** / **Java & Spring Boot** / **Python** / Go / .NET / Docker), frontend/web (Live Server), integración con GitHub y asistencia por inteligencia artificial mediante **Antigravity CLI (AGY)** y **Kiro CLI**.

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
        ├── antigravity.lua  # Integración dual (flotante/split) para Antigravity CLI (agy)
        ├── auto-save.lua    # Guardado automático inteligente (auto-save.nvim)
        ├── colorscheme.lua  # Esquema de color principal (bamboo.nvim)
        ├── java.lua         # Ecosistema Java & Spring Boot (JDTLS, STS4, Motor .env, DAP, Neotest, Initializr)
        ├── kiro.lua         # Integración y terminal flotante para Kiro CLI (+ indicador en Lualine)
        ├── live-server.lua  # Servidor local con recarga en vivo (live-server.nvim)
        ├── lualine.lua      # Barra de estado con indicador asíncrono de AGY y Kiro
        ├── octo.lua         # Gestión de Issues, PRs y Notificaciones de GitHub
        ├── python.lua       # Ecosistema Python (basedpyright, ruff, debugpy, pytest, neogen)
        ├── render-markdown.lua # Renderizado enriquecido de Markdown en el búfer
        ├── rust.lua         # Ecosistema Rust (rustaceanvim, crates.nvim, codelldb, neotest y blindajes)
        ├── smear-cursor.lua # Animaciones del cursor (deshabilitadas en Kitty)
        └── snacks.lua       # Configuración centralizada de Snacks (Dashboard, Explorer y Picker)
```

---

## ⚡ Requisitos y Dependencias

Para el funcionamiento completo de todos los módulos:

1. **Neovim**: `>= 0.10.0` (Probado en `0.12+`).
2. **Nerd Font**: Requerido para iconos en Lualine, Which-Key y Snacks.
3. **Rust & Cargo (`rustup`)**:
   - Toolchain `stable` con `rustc`, `cargo`, `clippy`, `rustfmt` y `rust-src`.
   - `rust-analyzer` instalado vía `rustup component add rust-analyzer` (nunca desde Mason para evitar incompatibilidades de ABI en *proc-macros*).
   - `codelldb` gestionado automáticamente mediante `mason.nvim` para depuración DAP; opcionalmente `cargo-nextest` para ejecución paralela de tests.
4. **Java, Spring Boot & SDKMAN**:
   - JDK principal detectado dinámicamente desde `JAVA_HOME`, `$SDKMAN_DIR/candidates/java/current` (ej. Java 21 LTS) o `PATH`, con descubrimiento automático de múltiples JDKs instalados en `~/.sdkman/candidates/java/*`.
   - Herramientas gestionadas automáticamente vía `mason.nvim`: `jdtls` (con soporte automático para **Lombok**), `vscode-spring-boot-tools` (Spring Tools 4 LSP), `java-debug-adapter`, `java-test` y `google-java-format`.
   - `curl` y `unzip` instalados en el sistema para la generación de proyectos desde `start.spring.io` con `spring-initializr.nvim`.
5. **Node.js & npm**:
   - Requerido para utilidades web como `live-server`.
6. **Antigravity CLI (`agy`) & Kiro CLI (`kiro-cli`)**:
   - Disponibles en `$PATH` para sesiones interactivas de IA, edición contextual y análisis de diagnósticos LSP.
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

### 🚀 Antigravity (`agy` CLI — `lua/plugins/antigravity.lua`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>ag` | Normal / Terminal | Mostrar / Ocultar terminal **AGY Flotante** |
| `<leader>av` | Normal / Terminal | Mostrar / Ocultar terminal **AGY en Split Lateral Derecho** |
| `<leader>ae` | Normal / Visual | Editar selección o línea actual con instrucción en AGY |
| `<leader>aa` | Normal / Visual | Preguntar a AGY sobre la selección o línea actual |
| `<leader>at` | Normal / Visual | Generar y ejecutar tests unitarios para la selección o función |
| `<leader>af` | Normal | Enviar el archivo actual completo a AGY (con instrucción opcional) |
| `<leader>ad` | Normal | Enviar diagnósticos LSP activos ordenados por severidad a AGY |
| `<leader>aq` | Normal | Enviar elementos de la lista Quickfix o todos los búferes abiertos |
| `<leader>ar` | Normal | Menú de flujos Git con AGY (*Code Review* de diff, *Conventional Commit*, conflictos) |
| `<leader>as` | Normal / Visual | Selector interactivo de *Slash Commands* (`/plan`, `/boost`, `/grill-me`, `/goal`...) |

### 🤖 Kiro CLI (`lua/plugins/kiro.lua`)
Integración independiente de Antigravity. Usa una terminal flotante propia (`count = 2`) con `kiro-cli chat --trust-workspace` y muestra el indicador `🤖 Kiro` en Lualine mientras la sesión está activa.

| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>kk` | Normal / Terminal | Abrir/Cerrar terminal interactiva de **Kiro CLI** |
| `<leader>ke` | Normal / Visual | Editar la selección o línea actual con una instrucción |
| `<leader>ka` | Normal / Visual | Preguntar a Kiro sobre la selección o línea actual |
| `<leader>kf` | Normal | Enviar el archivo actual (instrucción opcional) |
| `<leader>kd` | Normal | Enviar los diagnósticos LSP del archivo para su corrección |
| `<leader>kr` | Normal | Abrir Kiro reanudando la última conversación del directorio (`--resume`) |

### ☕ Java & Spring Boot (`nvim-jdtls`, `spring-boot.nvim`, Motor `.env`, `spring-initializr.nvim`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>jr` | Normal | **▶️ Ejecutar Spring Boot (`spring-boot:run` / `bootRun`) con carga automática de `.env`** |
| `<leader>jp` | Normal | **🌱 Ejecutar Spring Boot seleccionando Perfil (`SPRING_PROFILES_ACTIVE`) + `.env`** |
| `<leader>jd` | Normal | **🐞 Depurar Spring Boot (DAP) con inyección automática de variables `.env`** |
| `<leader>js` | Normal / Terminal | Mostrar / Ocultar la consola inferior de Spring Boot |
| `<leader>jS` | Normal | Detener el proceso activo de Spring Boot |
| `<leader>je` | Normal | **🔐 Inspeccionar variables `.env` detectadas** (enmascara secretos automáticamente) |
| `<leader>jo` | Normal | **📄 Abrir (o crear) el archivo `.env`** en la raíz del proyecto |
| `<leader>jm` | Normal | **🔨 Ejecutar tareas Maven / Gradle** (`clean compile`, `test`, `package`, etc.) con `.env` |
| `<leader>jI` | Normal | **🌱 Abrir Spring Initializr TUI** (`:SpringInitializr`) para configurar un nuevo proyecto |
| `<leader>jG` | Normal | **🏗️ Generar y descargar proyecto Spring Boot** (`:SpringGenerateProject`) |
| `<leader>jO` / `<leader>co` | Normal (`.java`) | Organizar imports con JDTLS (sin colapsar en `import *`) |
| `<leader>ju` | Normal (`.java`) | Actualizar configuración del proyecto Maven/Gradle en JDTLS |
| `<leader>jt` / `<leader>jT` | Normal (`.java`) | Depurar método de test bajo el cursor / clase de test completa (JDTLS + `.env`) |
| `<leader>tr` / `<leader>tt` / `<leader>td` | Normal (`.java`) | Ejecutar test cercano / archivo / depurar test con Neotest (`neotest-java`) |
| `<leader>jn` | Normal (`.java`) | Menú general de nuevo artefacto Java (`java-creator-nvim`) |
| `<leader>jc` / `<leader>ji` | Normal (`.java`) | Crear nueva `Class` / nueva `Interface` |
| `<leader>jR` / `<leader>jE` | Normal (`.java`) | Crear nuevo `Record` / nuevo `Enum` |
| `<leader>cn` | Normal (`.java`) | Generar comentario de documentación Javadoc (`neogen`) |
| `<leader>cxv` / `<leader>cxc` | Normal / Visual | Extraer variable / extraer constante (JDTLS) |
| `<leader>cxm` | Visual | Extraer método (JDTLS) |

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

### ☕ Ecosistema Profesional de Java, Spring Boot y Motor Nativo de `.env`
En [lua/plugins/java.lua](file:///home/rmachicm/.config/nvim/lua/plugins/java.lua), se configura una suite integral para desarrollo empresarial con **Java 21+** y **Spring Boot**:
1. **LSP Avanzado (`mfussenegger/nvim-jdtls`) + Multi-JDK (SDKMAN)**:
   - Resuelve dinámicamente `JAVA_HOME` (priorizando `vim.env.JAVA_HOME`, `$SDKMAN_DIR/candidates/java/current` y `PATH`) y escanea `~/.sdkman/candidates/java/*` para registrar automáticamente todos los JDKs instalados en `java.configuration.runtimes`.
   - Inyecta `lombok.jar` (`-javaagent`), optimiza la JVM (`-Xmx4G`, `-XX:+UseG1GC`), activa *Inlay Hints* de nombres de parámetros, evita imports comodín (`starThreshold = 9999`) y preconfigura *static imports* favoritos para **JUnit 5, AssertJ, Mockito y Spring MockMvc**.
2. **Spring Tools 4 Oficial (`JavaHello/spring-boot.nvim`)**:
   - Conecta `vscode-spring-boot-tools` con JDTLS para ofrecer autocompletado, validación y documentación en `application.properties` y `application.yml`, además de navegación inteligente por anotaciones y beans de Spring (`@RestController`, `@Bean`, `@Value`, etc.).
3. **Motor Nativo de Carga Automática de `.env`**:
   - **Lectura en caliente**: Busca y fusiona automáticamente `.env`, `.env.local` y `.env.<profile>` tanto en la raíz del proyecto como en subdirectorios `backend/`. Soporta `export KEY=VAL`, comentarios `#`, comillas simples/dobles e interpolación `${VAR}`.
   - **Inyección transparente en `nvim-dap`**: Un hook en `dap.listeners.on_config` intercepta cualquier sesión de depuración Java (`<leader>dc`, `<leader>jd`, `<leader>jt`) e inyecta todas las variables del `.env` directamente en el proceso JVM.
   - **Spring Boot Runner en `Snacks.terminal`**: Ejecuta `./mvnw spring-boot:run` o `./gradlew bootRun` en una consola dedicada inyectando tanto las variables del `.env` como el `JAVA_HOME` activo.
4. **Testing, Scaffolding y Spring Initializr**:
   - **Testing**: `rcasia/neotest-java` integrado en `neotest` (`<leader>tr`, `<leader>tt`, `<leader>td`) + runners de JDTLS (`<leader>jt`, `<leader>jT`).
   - **Spring Initializr**: Interfaz TUI con `jkeresman01/spring-initializr.nvim` (`<leader>jI` para configurar dependencias desde `start.spring.io` y `<leader>jG` para generar el proyecto).
   - **Scaffolding & Javadoc**: `java-creator-nvim` con detección automática de estructuras estándar (`src/main/java`) o monorepo (`backend/src/main/java`), y generación de Javadoc con `neogen` (`<leader>cn`).

#### ▶️ Flujo Rápido para Crear, Ejecutar y Depurar un Proyecto Spring Boot (con `.env`)
1. **Crear un proyecto nuevo desde Neovim**: Presiona **`<leader>jI`** (`:SpringInitializr`), selecciona versión de Spring Boot, Java, metadatos y dependencias, y luego presiona **`<leader>jG`** (`:SpringGenerateProject`) para descargarlo en tu directorio actual.
2. **Configurar y verificar variables `.env`**:
   - Presiona **`<leader>jo`** para abrir o crear el archivo `.env` en la raíz del proyecto.
   - Presiona **`<leader>je`** en cualquier momento para inspeccionar qué archivos `.env` y qué variables están siendo detectadas (las claves con `SECRET`, `PASSWORD`, `TOKEN` o `KEY` se muestran enmascaradas).
3. **Arrancar Spring Boot con `.env`**:
   - **Arranque directo**: Presiona **`<leader>jr`** para iniciar `spring-boot:run` o `bootRun` con todas las variables del `.env` inyectadas.
   - **Arranque por perfil**: Presiona **`<leader>jp`** para elegir el perfil activo (`dev`, `local`, `test`, `staging`, `prod` o personalizado); Neovim definirá `SPRING_PROFILES_ACTIVE` y cargará además `.env.<perfil>` si existe.
   - **Control de consola**: Usa **`<leader>js`** para ocultar/mostrar la consola de Spring Boot y **`<leader>jS`** para detener el servidor.
4. **Depurar paso a paso con `.env` (`nvim-dap`)**:
   - Coloca un breakpoint con **`<leader>db`** y presiona **`<leader>jd`** (o **`<leader>dc`**). Neovim descubrirá la clase `@SpringBootApplication`, inyectará las variables del `.env` en la JVM y abrirá `nvim-dap-ui`.

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

### 🔍 Snacks Picker, Explorer y Dashboard Personalizado
En [lua/plugins/snacks.lua](file:///home/rmachicm/.config/nvim/lua/plugins/snacks.lua):
- **Explorador lateral (`<leader>e`)**: Oculta archivos ignorados por defecto pero mantiene una lista blanca (`include`) que muestra siempre dotfiles esenciales de configuración como **`.env*`**, `.cargo`, `.github`, `.gitignore` y `.dockerignore`.
- **Buscador de archivos (`<leader><space>`)**: Muestra dotfiles (`hidden = true`) excluyendo directorios de caché, entornos virtuales y artefactos de compilación o metadatos de IDE (`target`, `build`, `.gradle`, `.settings`, `.classpath`, `.project`, `.factorypath`, `node_modules`, `.venv`).
- **Dashboard**: Pantalla de bienvenida personalizada con arte ASCII.

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
