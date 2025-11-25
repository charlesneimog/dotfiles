local vim = vim

-- ─────────────────────────────────────
local function setmytheme(switcher)
	vim.g.wezterm_theme = switcher
	vim.env.WEZTERM_THEME = switcher
	if switcher == "dark" then
		vim.cmd.colorscheme("catppuccin-mocha")
	else
		vim.cmd.colorscheme("catppuccin-latte")
	end
end

-- ─────────────────────────────────────
vim.api.nvim_create_user_command(
	"SetMyTheme",
	function(opts)
		vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
		setmytheme(opts.args)
	end,
	{ nargs = 1 } -- This specifies that the command takes exactly 1 argument
)

-- ─────────────────────────────────────
return {
	"catppuccin/nvim",
	name = "catppuccin",
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			background = {
				light = "latte",
				dark = "mocha",
			},
			transparent_background = true,
			float = {
				transparent = true,
				solid = false,
			},
			show_end_of_buffer = false,
			term_colors = true,
			styles = {
				comments = { "italic" },
				conditionals = { "bold" },
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
			},
			lsp_styles = {
				virtual_text = {
					errors = { "italic" },
					hints = { "italic" },
					warnings = { "italic" },
					information = { "italic" },
					ok = { "italic" },
				},
				underlines = {
					errors = { "underline" },
					hints = { "underline" },
					warnings = { "underline" },
					information = { "underline" },
					ok = { "underline" },
				},
				inlay_hints = {
					background = true,
				},
			},
			color_overrides = {
				latte = {
					bg = "#ff0000",
				},
				frappe = {},
				macchiato = {},
				mocha = {},
			},

			custom_highlights = {},
			default_integrations = true,
			auto_integrations = false,
			integrations = {
				aerial = true,
				alpha = true,
				cmp = true,
				indent_blankline = {
					enabled = true,
				},
				gitsigns = true,
				nvimtree = true,
				notify = true,
				noice = true,
				mason = true,
				mini = {
					enabled = true,
					indentscope_color = "",
				},
				telescope = {
					enabled = true,
				},
				lsp_trouble = true,
				which_key = true,
			},
		})

		if vim.loop.os_uname().sysname == "Linux" then
			local theme = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
			if theme:match("'prefer%-dark'") then
				vim.cmd.colorscheme("catppuccin-mocha")
			else
				vim.cmd.colorscheme("catppuccin-latte")
			end
		end
	end,
	priority = 1000,
}
