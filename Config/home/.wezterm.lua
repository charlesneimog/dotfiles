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
--│               Themes                │
--╰─────────────────────────────────────╯
local dark_theme = {
	background = "#303030",
	foreground = "#ffffff",
	brights = { "#ffffff", "#DB0000", "#339933", "#F3F04E", "#1868B8", "#FF3CFF", "#6DADEF", "#ffe100" },
	ansi = { "#6a6a6a", "#e05661", "#1da912", "#eea825", "#118dc3", "#9a77cf", "#56b6c2", "#fafafa" },
	cursor_bg = "#919191",
	cursor_fg = "#ffffff",
	selection_bg = "#494949",
	tab_bar = {
		background = "#303030",
		active_tab = {
			bg_color = "#383838",
			fg_color = "#ffffff",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#303030",
			fg_color = "#fafafa",
		},
		inactive_tab_hover = {
			bg_color = "#303030",
			fg_color = "#8c8b8b",
		},
		new_tab = {
			bg_color = "#303030",
			fg_color = "#ff0000",
		},
		new_tab_hover = {
			bg_color = "#292929",
			fg_color = "#ff0000",
		},
	},
}

local light_theme = {
	background = "#ffffff",
	foreground = "#000000",
	cursor_bg = "#000000",
	cursor_fg = "#ffffff",
	selection_bg = "#cccccc",
	selection_fg = "#000000",
	brights = { "#000000", "#cc0000", "#339933", "#bdb23e", "#040499", "#FF3CFF", "#0884FF", "#ffffff" },
	ansi = { "#6a6a6a", "#e05661", "#1da912", "#eea825", "#118dc3", "#9a77cf", "#56b6c2", "#fafafa" },
	tab_bar = {
		background = "#ffffff",
		active_tab = {
			bg_color = "#e7e7e7",
			fg_color = "#000000",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#ffffff",
			fg_color = "#000000",
		},
		inactive_tab_hover = {
			bg_color = "#f1f1f1",
			fg_color = "#000000",
		},
	},
}

config.tab_bar_style = {
	new_tab = wezterm.format({
		{ Background = { Color = "#ffffff" } },
		{ Foreground = { Color = "#ff0000" } },
		{ Text = " + " },
	}),

	new_tab_hover = wezterm.format({
		"ResetAttributes",
		{ Attribute = { Italic = false } },
		{ Attribute = { Intensity = "Bold" } },
		{ Background = { Color = "#f1f1f1" } },
		{ Foreground = { Color = "#ff0000" } },
		{ Text = " + " },
	}),
}

config.color_schemes = {
	["Dark"] = dark_theme,
	["Light"] = light_theme,
}

--╭─────────────────────────────────────╮
--│                Tabs                 │
--╰─────────────────────────────────────╯
local function get_process_icon(tab)
	local process_icons = {
		["nvim"] = {
			{ Foreground = { Color = dark_theme.colors.ansi[3] } },
			{ Text = " " .. wezterm.nerdfonts.custom_vim },
		},
		["zsh"] = {
			{ Foreground = { Color = dark_theme.colors.ansi[4] } },
			{ Text = " " .. wezterm.nerdfonts.dev_terminal },
		},
		["paru"] = {
			{ Foreground = { Color = "#E6E6FA" } },
			{ Text = " " .. wezterm.nerdfonts.linux_archlinux },
		},
		["git"] = {
			{ Foreground = { Color = "#FFE5B4" } },
			{ Text = " " .. wezterm.nerdfonts.dev_git },
		},
	}
	print(tab.active_pane.foreground_process_name)

	-- return wezterm.format(process_icons[process_name] or {
	-- 	{ Foreground = { Color = dark_theme.colors.ansi[5] } },
	-- 	{ Text = " " .. wezterm.nerdfonts.fa_linux },
	-- })
end

--╭─────────────────────────────────────╮
--│             Listerners              │
--╰─────────────────────────────────────╯
wezterm.on("update-status", function(window, _)
	window:set_right_status(wezterm.format({
		{ Text = wezterm.strftime(" %H:%M:%S ") },
	}))
end)

wezterm.on("window-config-reloaded", function(window, _)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	if appearance:find("Dark") then
		overrides.color_scheme = "Dark"
	else
		overrides.color_scheme = "Light"
	end
	window:set_config_overrides(overrides)
end)

wezterm.on("format-tab-title", function(tab)
	local myconfig = config
	return wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = string.format(" %s", tab.tab_index + 1) },
		"ResetAttributes",
		{ Text = get_process_icon(tab, myconfig) },
		{ Text = "▕" },
	})
end)

return config
