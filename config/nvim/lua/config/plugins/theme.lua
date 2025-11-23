local vim = vim

-- ─────────────────────────────────────
local function setmytheme(switcher)
	if switcher == vim.g.wezterm_theme then
		return
	end
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
			transparent_background = false,
			float = {
				transparent = false,
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
			color_overrides = {},
			custom_highlights = {},
			default_integrations = true,
			auto_integrations = false,
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				notify = true,
				mini = {
					enabled = true,
					indentscope_color = "",
				},
			},
		})
	end,
	priority = 1000,
}
