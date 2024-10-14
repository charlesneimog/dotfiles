local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

wezterm.warn_about_missing_glyphs = false

config.hide_tab_bar_if_only_one_tab = true
config.enable_wayland = false
config.font_size = 15
config.initial_cols = 110
config.initial_rows = 30

--╭─────────────────────────────────────╮
--│              Hot Keys               │
--╰─────────────────────────────────────╯
config.keys = {}
for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "ALT",
		action = act.ActivateTab(i - 1),
	})
end

table.insert(config.keys, {
	action = wezterm.action.ToggleFullScreen,
	mods = "SHIFT|CTRL",
	key = "n",
})

--╭─────────────────────────────────────╮
--│                Font                 │
--╰─────────────────────────────────────╯
config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font", weight = "Medium" },
	{ family = "Meslo LG S", scale = 1.3 },
})

config.tab_max_width = 32
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}
config.use_fancy_tab_bar = false
config.adjust_window_size_when_changing_font_size = false

--╭─────────────────────────────────────╮
--│             Listerners              │
--╰─────────────────────────────────────╯
wezterm.on("update-status", function(window, _)
	window:set_right_status(wezterm.format({
		{ Text = wezterm.strftime(" %H:%M:%S ") },
	}))
end)

wezterm.on("window-config-reloaded", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local scheme
	if appearance:find("Dark") then
		scheme = "OneHalfDark"
	else
		scheme = "OneHalfLight"
	end
	if overrides.color_scheme ~= scheme then
		overrides.color_scheme = scheme
		window:set_config_overrides(overrides)
	end
end)

return config
