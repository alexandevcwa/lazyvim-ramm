---@module "plugins.smear-cursor"
--- Animación suave y fluida del cursor al desplazarse
return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    -- Velocidad, rigidez y amortiguación de la animación
    stiffness = 0.6,
    trailing_stiffness = 0.3,
    distance_stop_animating = 0.1,
    hide_target_hack = false,
  },
}
