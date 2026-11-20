---@module "plugins.auto-save"
--- Guardado automático no intrusivo limitado a archivos reales en disco
return {
  "okuuva/auto-save.nvim",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = true,
    -- Fundamental: evita disparar el formateador (Conform) en cada autoguardado
    noautocmd = true,
    condition = function(buf)
      buf = buf or vim.api.nvim_get_current_buf()
      if not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly then
        return false
      end
      local excluded_ft = { gitcommit = true, gitrebase = true, octo = true }
      if excluded_ft[vim.bo[buf].filetype] then
        return false
      end
      return vim.api.nvim_buf_get_name(buf) ~= ""
    end,
  },
  keys = {
    { "<leader>ua", "<cmd>ASToggle<cr>", desc = "Alternar AutoSave" },
  },
}
