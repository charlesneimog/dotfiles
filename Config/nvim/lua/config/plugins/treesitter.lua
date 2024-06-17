return {
	"nvim-treesitter/nvim-treesitter", -- Highlighting
	build = function()
		pcall(require("nvim-treesitter.install").update)
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"nvim-treesitter/nvim-treesitter-context",
		"nvim-treesitter/playground",
	},
	tag = "v0.9.2",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-treesitter.configs").setup({
			auto_install = true,
			highlight = { enable = true },
			ignore_install = { "latex" },
			disable = { "latex" },
			indent = {
				enable = true,
			},
			ensure_installed = {
				"c",
				"lua",
				"javascript",
				"vim",
				"bash",
				"html",
				"regex",
				"markdown",
				"markdown_inline",
				"vimdoc",
				"query",
			},
		})

		require("treesitter-context").setup({
			enable = true,
			max_lines = 0,
			min_window_height = 0,
			line_numbers = true,
			multiline_threshold = 10,
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
			on_attach = nil,
		})
	end,
}
