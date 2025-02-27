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
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

		parser_config.scofo = {
			install_info = {
				url = "/home/neimog/Documents/Git/OScofo/Resources/tree-sitter-scofo",
				files = { "src/parser.c" },
				generate_requires_npm = false,
				requires_generate_from_grammar = false,
			},
			filetype = "scofo",
		}

		vim.filetype.add({
			pattern = {
				[".*%.scofo%.txt"] = "scofo", -- Matches any file ending in .scofo.txt
			},
		})

        vim.treesitter.query.set("scofo", "injections", "(comment) @comment")
		--
		-- vim.treesitter.query.set("scofo", "injections", "(comment) @comment")
		--
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
				-- "html",
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
