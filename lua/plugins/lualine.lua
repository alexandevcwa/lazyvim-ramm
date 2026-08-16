---@module "plugins.lualine"
--- Personalización de la barra de estado (Lualine) con indicador de estado de Antigravity
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    --- Obtiene el estado del agente desde el archivo temporal /tmp/ag_status.json
    ---@return string
    local function agent_status()
      local file = io.open("/tmp/ag_status.json", "r")
      if not file then
        return ""
      end
      local content = file:read("*a")
      file:close()

      local ok, data = pcall(vim.fn.json_decode, content)
      if ok and type(data) == "table" and data.state then
        return "🚀 " .. data.state
      end
      return "🚀 AGY"
    end

    -- Inyectar el estado del agente al inicio de la sección X (junto a diagnósticos/LSP)
    table.insert(opts.sections.lualine_x, 1, { agent_status, color = { fg = "#ff9e64" } })
  end,
}
