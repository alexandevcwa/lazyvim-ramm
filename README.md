# 🚀 Neovim & LazyVim Configuration

Configuración personalizada de **Neovim** basada en la distribución moderna y modular **[LazyVim](https://lazyvim.github.io/)**, optimizada para desarrollo backend (Java / .NET / SQL / Docker), frontend/web (Live Server), integración con GitHub y asistencia por inteligencia artificial mediante **Antigravity CLI (AGY)**.

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
        ├── colorscheme.lua  # Tema visual OneDark (estilo 'darker')
        ├── dadbod.lua       # Explorador y cliente de bases de datos (vim-dadbod-ui)
        ├── dashboard.lua    # Banner personalizado en ASCII para Snacks Dashboard
        ├── java.lua         # LSP Java (JDTLS con SDKMAN + Lombok) y generador de clases
        ├── live-server.lua  # Servidor local con recarga en vivo (live-server.nvim)
        ├── lualine.lua      # Barra de estado con indicador en vivo de AGY
        ├── octo.lua         # Gestión de Issues, PRs y Notificaciones de GitHub
        ├── smear-cursor.lua # Animaciones fluidas del cursor
        └── snacks.lua       # Configuración del picker de Snacks (archivos ocultos)
```

---

## ⚡ Requisitos y Dependencias

Para el funcionamiento completo de todos los módulos:

1. **Neovim**: `>= 0.10.0` (Probado en `0.12+`).
2. **Nerd Font**: Requerido para iconos en Lualine, Dadbod UI y Snacks.
3. **Java & SDKMAN**:
   - JDK 21 configurado en: `/home/rmachicm/.sdkman/candidates/java/21.0.12-oracle/`
   - Soporte automático para **Lombok** integrado a través de `mason.nvim`.
4. **Node.js & npm**:
   - Requerido para utilidades web como `live-server`.
5. **Antigravity CLI (`agy`)**:
   - Instalado en `$PATH` para comandos interactivos y análisis de código.
6. **GitHub CLI (`gh`)**:
   - Autenticado (`gh auth login`) para el funcionamiento de `octo.nvim`.
7. **StyLua / Formatters**: Gestionados automáticamente mediante `mason.nvim` y `conform.nvim`.

---

## 🧩 Extras de LazyVim Habilitados (`lazyvim.json`)

| Extra | Descripción |
|---|---|
| `lazyvim.plugins.extras.lang.java` | Soporte completo para Java mediante `nvim-jdtls`, DAP y testing |
| `lazyvim.plugins.extras.lang.sql` | Integración SQL con `vim-dadbod`, linters (`sqlfluff`) y formateo |
| `lazyvim.plugins.extras.lang.docker` | Soporte para Dockerfile y Docker Compose |
| `lazyvim.plugins.extras.lang.dotnet` | Soporte para C# y .NET (Omnisharp/Roslyn) |
| `lazyvim.plugins.extras.lang.json` | Soporte de esquemas JSON con `SchemaStore` |
| `lazyvim.plugins.extras.lang.yaml` | Validación y autocompletado para YAML |
| `lazyvim.plugins.extras.coding.yanky` | Historial avanzado de portapapeles y pegado cíclico |
| `lazyvim.plugins.extras.util.mini-hipatterns` | Resaltado de colores hexadecimales e hiperpatrones |

---

## ⌨️ Guía de Atajos de Teclado (Cheat Sheet)

### 🚀 Antigravity (AGY CLI)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>ag` | Normal / Terminal | Abrir/Cerrar terminal interactiva de **AGY CLI** |
| `<leader>af` | Normal | Analizar el archivo actual en una ventana flotante de AGY |
| `<leader>as` | Visual | Enviar el fragmento de código seleccionado a AGY |

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

### 🗄️ Base de Datos (`vim-dadbod-ui`)
| Atajo | Modo | Descripción |
|---|---|---|
| `<leader>D` | Normal | Alternar (Toggle) panel de **DBUI** |
| `:DBUI` | Comando | Abrir explorador de bases de datos |
| `<leader>S` | Normal (en buffer SQL) | Ejecutar consulta SQL bajo el cursor |

---

## ✨ Características y Ajustes Destacados

### 🔄 Autorecarga Inteligente de Búfers
En [lua/config/autocmds.lua](file:///home/rmachicm/.config/nvim/lua/config/autocmds.lua), el autocomando `AgentAutoRead` ejecuta `checktime` al recuperar foco (`FocusGained`), salir de la terminal (`TermLeave`/`TermClose`) o al pausar el cursor (`CursorHold`). Esto asegura que cualquier cambio realizado por un agente de IA o proceso externo se refleje al instante en tu búfer sin riesgo de sobreescritura accidental.

### 💾 Autoguardado No Intrusivo
Con [lua/plugins/auto-save.lua](file:///home/rmachicm/.config/nvim/lua/plugins/auto-save.lua), los cambios se guardan automáticamente al salir del modo inserción (`InsertLeave`) o modificar texto (`TextChanged`). Utiliza `noautocmd = true` para evitar disparar formateadores pesados (como Conform) en cada tipeo, manteniendo un flujo de escritura ágil.

### ☕ Soporte Java con Lombok
En [lua/plugins/java.lua](file:///home/rmachicm/.config/nvim/lua/plugins/java.lua), se detecta automáticamente la presencia de `lombok.jar` descargado por Mason y se inyecta como `-javaagent` al iniciar el servidor de lenguaje **JDTLS**, permitiendo el reconocimiento instantáneo de anotaciones como `@Getter`, `@Setter`, `@Builder`, etc.

### 🔍 Snacks Picker y Dashboard Personalizado
- **Picker** ([lua/plugins/snacks.lua](file:///home/rmachicm/.config/nvim/lua/plugins/snacks.lua)): Búsqueda de archivos configurada para incluir dotfiles/archivos ocultos (`hidden = true`).
- **Dashboard** ([lua/plugins/dashboard.lua](file:///home/rmachicm/.config/nvim/lua/plugins/dashboard.lua)): Pantalla de bienvenida personalizada con arte ASCII.

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
