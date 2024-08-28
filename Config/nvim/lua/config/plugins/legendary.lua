return {
	"mrjones2014/legendary.nvim",
	priority = 10000,
	lazy = false,
	-- dependencies = {
	-- 	"folke/which-key.nvim",
	-- },
	keys = {
		{
			"<M-h>",
			"<C-\\><C-n><C-w>h",
		},
		{
			"<M-j>",
			"<C-\\><C-n><C-w>j",
		},
		{
			"<M-k>",
			"<C-\\><C-n><C-w>k",
		},
		{
			"<M-l>",
			"<C-\\><C-n><C-w>l",
		},
		{
			"<leader>l",
			":Legendary<CR>",
			desc = "Toggle legendary.nvim scratchpad",
			mode = { "i", "n" },
		},
		{
			"<C-s>",
			"<Esc>:w<CR>",
			desc = "Save file",
			mode = { "i", "v", "n" },
		},
		{
			"<C-S>",
			"<Esc>:w<CR>",
			desc = "Save file",
			mode = { "i", "v", "n" },
		},
		{
			"<C-c>",
			'"+y',
			desc = "Copy to clipboard",
			mode = { "i", "v" },
		},
		{
			"<C-v>",
			'"+p',
			desc = "Paste from clipboard",
			mode = { "i", "v" },
		},
		{
			"<C-v>",
			'"+p',
			desc = "Paste from clipboard",
			mode = { "i", "v" },
		},
		{
			"<C-a>",
			"ggVG",
			desc = "Select all",
			mode = { "n", "v" },
		},
		{
			"<TAB>",
			">gv",
			desc = "Indent",
			mode = { "n", "v" },
		},
		{
			"<S-TAB>",
			"<gv",
			desc = "Unindent",
			mode = { "n", "v" },
		},
		{
			"jk",
			"<Esc>",
			desc = "Exit insert mode",
			mode = { "i" },
		},
		{
			"JK",
			"<Esc>",
			desc = "Exit insert mode",
			mode = { "i" },
		},
	},

	config = function()
		require("legendary").setup({
			extensions = {
				lazy_nvim = { auto_register = true },
				nvim_tree = false,
				which_key = {
					auto_register = true,
					mappings = {},
					opts = {},
					do_binding = true,
					use_groups = true,
				},
			},
			scratchpad = {
				view = "float",
				results_view = "float",
				float_border = "rounded",
				keep_contents = true,
			},
		})
	end,
}
