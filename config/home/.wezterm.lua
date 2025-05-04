local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

wezterm.warn_about_missing_glyphs = false
config.hide_tab_bar_if_only_one_tab = true
config.enable_wayland = false
config.font_size = 18
config.initial_cols = 110
config.initial_rows = 30
config.tab_bar_at_bottom = true
config.set_environment_variables = { WEZTERM_THEME = wezterm.gui.get_appearance():lower() }

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
	"Noto Color Emoji",
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
		background = "rgba(0,0,0,0)",
		active_tab = {
			bg_color = "rgba(0,0,0,0)",
			fg_color = "#ffffff",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "rgba(0,0,0,0)",
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
		background = "rgba(0,0,0,0)",
		active_tab = {
			bg_color = "#f1f1f1",
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

config.color_schemes = {
	["Dark"] = dark_theme,
	["Light"] = light_theme,
}

--╭─────────────────────────────────────╮
--│                Tabs                 │
--╰─────────────────────────────────────╯
local function url_decode(str)
	str = str:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end)
	return str
end

local function get_process_icon(tab)
	local pane = tab.active_pane
	local dir = tostring(pane["current_working_dir"])
	dir = url_decode(dir) -- utr-8 decode
	local last_folder = ""
	if dir ~= nil then
		local path = dir:gsub("file://[^/]+", "")
		last_folder = path:match(".*/(.*)/$")
	end

	if last_folder == nil then
		last_folder = " "
	end

	local process_icons = {
		["ssh"] = {
			{ Foreground = { Color = "#AA00F2" } },
			{ Text = " " .. " " .. last_folder },
		},
		["nvim"] = {
			{ Foreground = { Color = dark_theme.ansi[3] } },
			{ Text = " " .. wezterm.nerdfonts.custom_vim .. " " .. last_folder },
		},
		["zsh"] = {
			{ Foreground = { Color = dark_theme.ansi[4] } },
			{ Text = " " .. wezterm.nerdfonts.dev_terminal .. " " .. last_folder },
		},
		["paru"] = {
			{ Foreground = { Color = "#eb4034" } },
			{ Text = " " .. wezterm.nerdfonts.linux_archlinux .. " " .. last_folder },
		},
		["python"] = {
			{ Foreground = { Color = "#4B90C6" } },
			{ Text = " " .. wezterm.nerdfonts.dev_python .. " " .. last_folder },
		},
		["cmake"] = {
			{ Foreground = { Color = "#4B90C6" } },
			{ Text = " " .. wezterm.nerdfonts.custom_cpp .. " " .. last_folder },
		},
		["pip"] = {
			{ Foreground = { Color = "#4B90C6" } },
			{ Text = " " .. wezterm.nerdfonts.dev_python .. " " .. last_folder },
		},
		["git"] = {
			{ Foreground = { Color = "#fcba03" } },
			{ Text = " " .. wezterm.nerdfonts.dev_git .. " " .. last_folder },
		},
	}

	local title = pane.user_vars.WEZTERM_PROG or ""
	local process = title:match("^[^%s]+")

	if process_icons[process] then
		return wezterm.format(process_icons[process])
	else
		return wezterm.format({
			{ Foreground = { Color = "#cc0000" } },
			{ Text = " " .. wezterm.nerdfonts.dev_terminal },
			"ResetAttributes",
			{ Text = " " .. last_folder .. " " },
		})
	end
end

--╭─────────────────────────────────────╮
--│             Listerners              │
--╰─────────────────────────────────────╯
local function update_theme(window, path)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local my_theme = appearance:lower()
	local files = wezterm.glob("/run/user/1000/*")
	for _, file in ipairs(files) do
		if file:match("nvim") then
			local command = "nvim --server " .. file .. " --remote-send '<Cmd>SetMyTheme " .. my_theme .. "<CR>'"
			os.execute(command)
		end
	end




	if appearance:find("Dark") then
		os.execute(
			'export FZF_DEFAULT_OPTS="--color=bg+:#383838,bg:#303030,spinner:#303030,hl:#e78284 --color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#ff0000 --color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 --color=selected-bg:#51576d --multi"'
		)
	    os.execute("export OMP_GIT_SEPARATOR_COLOR=white")

		overrides.color_scheme = "Dark"
		overrides.tab_bar_style = {
			new_tab = wezterm.format({
				{ Background = { Color = "rgba(0,0,0,0)" } },
				{ Foreground = { Color = "#ffffff" } },
				{ Text = " + " },
			}),
			new_tab_hover = wezterm.format({
				"ResetAttributes",
				{ Attribute = { Italic = false } },
				{ Attribute = { Intensity = "Bold" } },
				{ Background = { Color = "rgba(0,0,0,0)" } },
				{ Foreground = { Color = "#ff0000" } },
				{ Text = " + " },
			}),
		}
	else
        os.execute(
            'export FZF_DEFAULT_OPTS="--color=bg+:#f5f5f5,bg:#e0e0e0,spinner:#e0e0e0,hl:#ff6f61 --color=fg:#2e2e2e,header:#ff6f61,info:#ff9f4f,pointer:#ff0000 --color=marker:#6a6a6a,fg+:#2e2e2e,prompt:#ff9f4f,hl+:#ff6f61 --color=selected-bg:#d4d4d4 --multi"'
        )

	    os.execute("export OMP_GIT_SEPARATOR_COLOR=black")
		overrides.color_scheme = "Light"
		overrides.tab_bar_style = {
			new_tab = wezterm.format({
				{ Background = { Color = "#ffffff" } },
				{ Foreground = { Color = "#ff0000" } },
				{ Text = " + " },
			}),
			new_tab_hover = wezterm.format({
				"ResetAttributes",
				{ Attribute = { Italic = false } },
				{ Attribute = { Intensity = "Bold" } },
				{ Background = { Color = "#ffffff" } },
				{ Foreground = { Color = "#ff0000" } },
				{ Text = " + " },
			}),
		}
	end
	window:set_config_overrides(overrides)
end

-- ──────────────────────────────────────────
wezterm.on("update-status", function(window, _)
	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = wezterm.nerdfonts.md_battery .. " " .. string.format("%.0f%%", b.state_of_charge * 100)
	end

	local appearance = window:get_appearance()
	local foreground_color = appearance:find("Dark") and "#ffffff" or "#000000"
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = foreground_color } },
		{ Text = wezterm.strftime(" %H:%M:%S ") },
		{ Text = "▕ " },
		{ Text = bat .. "   " },
	}))
end)

wezterm.on("user-var-changed", function(window, pane, name, value)
	if value == "true" and name == "IS_NVIM" then
		update_theme(window, pane)
		local overrides = window:get_config_overrides() or {}
		window:set_config_overrides(overrides)
	elseif value == "false" and name == "IS_NVIM" then
		local overrides = window:get_config_overrides() or {}
		window:set_config_overrides(overrides)
	end
end)

wezterm.on("window-config-reloaded", function(window, pane)
	update_theme(window, pane)
end)

wezterm.on("format-tab-title", function(tab)
	return wezterm.format({
		{ Text = string.format(" %s:", tab.tab_index + 1) },
		{ Text = get_process_icon(tab) },
		{ Text = "▕" },
	})
end)

return config
