local vim = vim

local function getGnomeThemeMode()
	local cmd = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme")
	vim.g.gnome_theme_mode = cmd:match("dark") and "dark" or "light"
	return cmd:match("dark") and "dark" or "light"
end

local function setmytheme(switcher)
	local lualinetheme
	if switcher == "dark" then
		vim.cmd("colorscheme onedark")
		lualinetheme = require("lualine.themes.onedark")
		lualinetheme.normal.c.bg = "#303030"
	else
		vim.cmd("colorscheme onelight")
		lualinetheme = require("lualine.themes.onelight")
		lualinetheme.normal.c.bg = "#ffffff"
	end
	require("lualine").setup({
		options = {
			theme = lualinetheme,
		},
	})
end

vim.api.nvim_create_user_command(
	"SetMyTheme",
	function(opts)
		vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
		setmytheme(opts.args)
	end,
	{ nargs = 1 } -- This specifies that the command takes exactly 1 argument
)

return {
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
		config = function()
			local theme = getGnomeThemeMode()
			require("onedarkpro").setup({
				colors = {
					onedark = { bg = "#303030", fg = "#ffffff", float_bg = "#2e2e2e" },
					onelight = { bg = "#FFFFFF", fg = "#000000", float_bg = "#fcfcfc" },
				},
			})
			if theme == "dark" then
				vim.cmd("colorscheme onedark")
			else
				vim.cmd("colorscheme onelight")
			end
		end,
	},
	{
		"catppuccin/nvim",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "auto",
				background = {
					light = "latte",
					dark = "mocha",
				},
				color_overrides = {
					mocha = { bg = "#303030", fg = "#ffffff", fg_gutter = "#ffffff" },
				},
			})
		end,
	},
}
