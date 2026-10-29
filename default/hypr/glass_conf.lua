-- Liquid Glass settings, kept in ~/.config/skein/glass.conf by skein-glass (Settings > Appearance).
-- Off unless the file says enabled=1.
local M = { enabled = false, blur = 1.0 }

local conf = io.open(os.getenv("HOME") .. "/.config/skein/glass.conf", "r")
if conf then
  for line in conf:lines() do
    local key, value = line:match("^(%w+)=(.+)$")
    if key == "enabled" then
      M.enabled = value == "1"
    elseif key == "blur" then
      M.blur = tonumber(value) or M.blur
    end
  end
  conf:close()
end

return M
