---@module "plugins.lualine"
--- Personalización de la barra de estado (Lualine) con indicador asíncrono de estado de Antigravity

local uv = vim.uv or vim.loop
local STATUS_FILE = "/tmp/ag_status.json"
local CHECK_INTERVAL_NS = 500 * 1e6 -- Limita verificaciones fs_stat a 1 cada 500ms
local MAX_READ_BYTES = 4096

local cached_status = ""
local last_mtime_key = nil
local last_check_ns = 0
local in_flight = false

--- Parsea el contenido JSON del archivo de estado de Antigravity
---@param content string|nil
---@return string
local function parse_status(content)
  if not content or content == "" then
    return ""
  end
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == "table" and type(data.state) == "string" and data.state ~= "" then
    return "🚀 " .. data.state
  end
  return "🚀 AGY"
end

--- Actualiza la caché y solicita refresco de Lualine solo si el texto cambió
---@param new_status string
local function update_cache(new_status)
  if new_status ~= cached_status then
    cached_status = new_status
    local ok_lualine, lualine = pcall(require, "lualine")
    if ok_lualine then
      pcall(lualine.refresh)
    end
  end
end

--- Lee el estado de Antigravity de forma asíncrona y con throttling por mtime
local function refresh_status()
  if in_flight then
    return
  end

  local now = uv.hrtime()
  if last_check_ns ~= 0 and (now - last_check_ns) < CHECK_INTERVAL_NS then
    return
  end

  last_check_ns = now
  in_flight = true

  uv.fs_stat(STATUS_FILE, function(stat_err, stat)
    if stat_err or not stat then
      last_mtime_key = nil
      in_flight = false
      if cached_status ~= "" then
        vim.schedule(function()
          update_cache("")
        end)
      end
      return
    end

    local mtime_key = string.format("%d:%d:%d", stat.mtime.sec, stat.mtime.nsec, stat.size)
    if mtime_key == last_mtime_key then
      in_flight = false
      return
    end

    if stat.size == 0 then
      last_mtime_key = mtime_key
      in_flight = false
      vim.schedule(function()
        update_cache("")
      end)
      return
    end

    uv.fs_open(STATUS_FILE, "r", 438, function(open_err, fd)
      if open_err or not fd then
        in_flight = false
        return
      end

      uv.fs_read(fd, math.min(stat.size, MAX_READ_BYTES), 0, function(read_err, content)
        uv.fs_close(fd, function() end)
        in_flight = false
        if read_err then
          return
        end

        last_mtime_key = mtime_key
        vim.schedule(function()
          update_cache(parse_status(content))
        end)
      end)
    end)
  end)
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}

    refresh_status()

    local function agent_status()
      refresh_status()
      return cached_status
    end

    -- Inyectar el estado del agente al inicio de la sección X (junto a diagnósticos/LSP)
    table.insert(opts.sections.lualine_x, 1, { agent_status, color = { fg = "#ff9e64" } })
  end,
}
