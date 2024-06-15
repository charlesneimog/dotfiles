local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
wezterm.warn_about_missing_glyphs = false

local function basename(str)
	if str then
		return string.gsub(str, "(.*/)(.*)", "%2")
	end
end

local function get_current_working_dir(tab)
	local current_dir = tab.active_pane.current_working_dir.file_path
	print(current_dir)
	local hostname = tab.active_pane.user_vars.WEZTERM_HOST
	local HOME_DIR = string.format("file://%s%s/", hostname, os.getenv("HOME"))
	return current_dir == HOME_DIR and " ~" or string.format(" %s", string.gsub(current_dir, "(.*/)(.*)/", "%2/"))
end

local function get_process_icon(tab, myconfig)
	local process_icons = {
		["nvim"] = {
			{ Foreground = { Color = myconfig.colors.ansi[3] } },
			{ Text = " " .. wezterm.nerdfonts.custom_vim },
		},
		["zsh"] = {
			{ Foreground = { Color = myconfig.colors.ansi[4] } },
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
	local process_name = basename(tab.active_pane.foreground_process_name)
	return wezterm.format(process_icons[process_name] or {
		{ Foreground = { Color = myconfig.colors.ansi[5] } },
		{ Text = " " .. wezterm.nerdfonts.fa_linux },
	})
end

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

local function getTheme(myconfig)
	local success, stdout, _ =
		wezterm.run_child_process({ "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" })
	if success then
		if stdout:match("dark") then
			myconfig.colors = {
				background = "#303030",
				foreground = "#ffffff",
				brights = {
					"#ffffff", -- preto
					"#DB0000", -- vermelho
					"#339933", -- verde
					"#F3F04E", -- amarelo
					"#1868B8", -- azul
					"#FF3CFF", -- rosa
					"#6DADEF", -- azul claro
					"#ffe100", -- branco
				},
				ansi = {
					"#6a6a6a",
					"#e05661",
					"#1da912",
					"#eea825",
					"#118dc3",
					"#9a77cf",
					"#56b6c2",
					"#fafafa",
				},

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
		else
			myconfig.colors = {
				background = "#ffffff",
				foreground = "#000000",
				cursor_bg = "#000000",
				cursor_fg = "#ffffff",
				selection_bg = "#cccccc",
				selection_fg = "#000000",
				brights = {
					"#000000", -- preto
					"#cc0000", -- vermelho
					"#339933", -- verde
					"#bdb23e", -- amarelo
					"#040499", -- azul
					"#FF3CFF", -- rosa
					"#0884FF", -- azul claro
					"#ffffff", -- branco
				},
				ansi = {
					"#6a6a6a",
					"#e05661",
					"#1da912",
					"#eea825",
					"#118dc3",
					"#9a77cf",
					"#56b6c2",
					"#fafafa",
				},
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
			myconfig.tab_bar_style = {
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
		end
	end
end

config.enable_wayland = false
config.font_size = 17
config.initial_cols = 110
config.initial_rows = 30

-- config.font = wezterm.font_with_fallback({
-- 	"JetBrainsMonoNerdFont",
-- 	"DengXian",
-- })
-- config.font = wezterm.font("JetBrainsMonoNerdFont")

-- config.hide_tab_bar_if_only_one_tab = true
getTheme(config)
config.tab_max_width = 32
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}
config.use_fancy_tab_bar = false
config.adjust_window_size_when_changing_font_size = false

wezterm.on("update-status", function(window, _)
	local hour = tonumber(wezterm.strftime("%H"))
	local minutes = tonumber(wezterm.strftime("%M"))
	local seconds = tonumber(wezterm.strftime("%S"))
	local waterSymbol = " "
	local lunch = " "
	if hour == 12 and minutes == 0 then
		lunch = "🥗  "
	end
	if minutes % 7 == 0 and seconds % 2 == 0 and seconds < 30 then
		waterSymbol = "💧 "
	end

	window:set_right_status(wezterm.format({
		{ Text = lunch },
		{ Text = waterSymbol },
	}))
end)

wezterm.on("format-tab-title", function(tab)
	local myconfig = config
	return wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = string.format(" %s", tab.tab_index + 1) },
		"ResetAttributes",
		{ Text = get_process_icon(tab, myconfig) },
		{ Text = get_current_working_dir(tab) },
		{ Text = "▕" },
	})
end)

return config
