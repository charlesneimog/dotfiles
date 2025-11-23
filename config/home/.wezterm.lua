local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

wezterm.warn_about_missing_glyphs = false
config.hide_tab_bar_if_only_one_tab = false
config.enable_wayland = false
config.font_size = 14
config.tab_bar_at_bottom = true
config.set_environment_variables = { WEZTERM_THEME = wezterm.gui.get_appearance():lower() }
config.window_background_opacity = 1

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

config.tab_max_width = 45
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}
config.use_fancy_tab_bar = false
config.adjust_window_size_when_changing_font_size = false
config.color_scheme = "Catppuccin Latte"

--╭─────────────────────────────────────╮
--│          Helper Functions           │
--╰─────────────────────────────────────╯
local function url_decode(str)
	str = str:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end)
	return str
end

--╭─────────────────────────────────────╮
--│            Process Icon             │
--╰─────────────────────────────────────╯
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
			-- { Foreground = { Color = dark_theme.ansi[3] } },
			{ Text = " " .. wezterm.nerdfonts.custom_vim .. " " .. last_folder },
		},
		["zsh"] = {
			-- { Foreground = { Color = dark_theme.ansi[4] } },
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
			{ Text = " " .. wezterm.nerdfonts.dev_terminal },
			"ResetAttributes",
			{ Text = " " .. last_folder .. " " },
		})
	end
end

--╭─────────────────────────────────────╮
--│            Theme Update             │
--╰─────────────────────────────────────╯
local function update_theme(window, _)
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
		overrides.color_scheme = "Catppuccin Mocha"
	else
		overrides.color_scheme = "Catppuccin Latte"
	end

	local colors = wezterm.color.get_builtin_schemes()[overrides.color_scheme]
	overrides.colors = overrides.colors or {}
	overrides.colors.tab_bar = overrides.colors.tab_bar or {}
	overrides.colors.tab_bar.background = colors.background

	window:set_config_overrides(overrides)
end

--╭─────────────────────────────────────╮
--│        Neovim Theme Listener        │
--╰─────────────────────────────────────╯
wezterm.on("update-status", function(window, pane)
	local bat = ""
	for _, b in ipairs(wezterm.battery_info()) do
		bat = wezterm.nerdfonts.md_battery .. " " .. string.format("%.0f%%", b.state_of_charge * 100)
	end
	local appearance = window:get_appearance()

	local color_scheme
	if appearance:find("Dark") then
		color_scheme = "Catppuccin Mocha"
	else
		color_scheme = "Catppuccin Latte"
	end

	local colors = wezterm.color.get_builtin_schemes()[color_scheme]
	-- local cwd_uri = pane:get_current_working_dir()
	-- local cwd = cwd_uri.file_path
	-- cwd = cwd:gsub("/home/neimog", " ~")

	window:set_right_status(wezterm.format({
		{ Background = { Color = colors.background } },
		{ Foreground = { Color = colors.foreground } },
		-- { Text = cwd },
		{ Text = "▕ " },
		{ Text = wezterm.strftime(" %H:%M:%S ") },
		{ Text = "▕ " },
		{ Text = bat .. "   " },
	}))
end)

-- ─────────────────────────────────────
wezterm.on("window-config-reloaded", function(window, pane)
	update_theme(window, pane)
end)

-- ─────────────────────────────────────
wezterm.on("format-tab-title", function(tab)
	return wezterm.format({
		{ Text = string.format(" %s:", tab.tab_index + 1) },
		{ Text = get_process_icon(tab) },
		{ Text = "▕" },
	})
end)

-- ─────────────────────────────────────
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

return config
