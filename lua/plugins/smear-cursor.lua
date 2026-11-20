---@module "plugins.smear-cursor"
--- Animación suave del cursor (deshabilitada en Kitty porque kitty.conf ya usa cursor_trail nativo)
return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  cond = function()
    -- Kitty ya provee cursor_trail acelerado por GPU; activar ambos genera doble estela y parpadeos
    return vim.env.KITTY_WINDOW_ID == nil and vim.env.KITTY_PID == nil and vim.env.TERM ~= "xterm-kitty"
  end,
  opts = {
    -- Velocidad, rigidez y amortiguación de la animación en terminales sin cursor_trail nativo
    stiffness = 0.6,
    trailing_stiffness = 0.3,
    distance_stop_animating = 0.1,
    hide_target_hack = false,
  },
}
