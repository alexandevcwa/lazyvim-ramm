return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local function agent_status()
      local file = io.open("/tmp/ag_status.json", "r")
      if not file then
        return ""
      end
      local content = file:read("*a")
      file:close()

      local ok, data = pcall(vim.fn.json_decode, content)
      if ok and data.state then
        return "🚀 " .. data.state
      end
      return "🚀 AGY"
    end

    -- Inyectar el estado al lado de los diagnósticos
    table.insert(opts.sections.lualine_x, 1, { agent_status, color = { fg = "#ff9e64" } })
  end,
}
