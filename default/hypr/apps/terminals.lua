-- Define terminal tag to style them uniformly.
o.window("(Alacritty|kitty|com.mitchellh.ghostty|foot)", { tag = "+terminal" })
o.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = require("default.hypr.glass_conf").enabled and "0.88 0.8" or "0.985 0.96" })
