-- The dock is frosted glass: blur what is behind it, but only where its own fill is translucent
hl.layer_rule({ match = { namespace = "skein-dock" }, blur = true, ignore_alpha = 0.1 })
