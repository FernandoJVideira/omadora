-- Liquid Glass. With the HyprGlass plugin loaded (https://github.com/hyprnux/hyprglass) windows and the shell's
-- layers get real glass: blur, edge refraction, specular and fresnel highlights. Without it, the shell's
-- translucent surfaces are only blurred.
local namespaces = {
  -- namespace = alpha above which the surface counts as glass (lower for near-clear surfaces)
  ["skein-bar"] = 0.1,
  ["skein-panel"] = 0.15,
  ["skein-osd"] = 0.1,
  ["skein-notifications"] = 0.1,
  ["skein-dock"] = 0.1,
  -- Full-screen layers with a dimming backdrop (alpha 0.35): only their window is glass
  ["skein-settings"] = 0.5,
  ["skein-share-picker"] = 0.5,
  ["skein-picker"] = 0.5,
}

-- Settings > Appearance > Liquid Glass (skein-glass): ~/.config/skein/glass.conf, key=value lines
local enabled, blur = true, 2.0
local conf = io.open(os.getenv("HOME") .. "/.config/skein/glass.conf", "r")
if conf then
  for line in conf:lines() do
    local key, value = line:match("^(%w+)=(.+)$")
    if key == "enabled" then
      enabled = value ~= "0"
    elseif key == "blur" then
      blur = tonumber(value) or blur
    end
  end
  conf:close()
end

if hl.plugin and hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  hg.config({
    enabled = enabled,
    blur_strength = blur,
    default_theme = "dark",
    default_preset = "clear",
    layers = { enabled = true },
    -- Clearer than the dark default: no dimming of bright backgrounds, a faint white tint, strong edge light
    tint_color = 0xffffff14,
    refraction_strength = 0.8,
    specular_strength = 0.9,
    fresnel_strength = 0.7,
    dark = { brightness = 1.0, contrast = 1.0, saturation = 1.15, vibrancy = 0.3, adaptive_dim = 0.0 },
  })

  for namespace, threshold in pairs(namespaces) do
    hg.layer(namespace, { mask_threshold = threshold })
  end
  -- Layers that only exist to catch clicks must never be glass
  hg.layer("skein-panel-dismiss", { exclude = true })
elseif enabled then
  for namespace, threshold in pairs(namespaces) do
    hl.layer_rule({ match = { namespace = namespace }, blur = true, blur_popups = true, ignore_alpha = math.max(threshold, 0.1) })
  end
end
