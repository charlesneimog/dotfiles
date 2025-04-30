return {
	"stevearc/aerial.nvim",
	event = "InsertEnter",
	lazy = true,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{
			"<leader>a",
			function()
				require("telescope").extensions.aerial.aerial()
			end,
			mode = "n",
			"Toggle all the functions",
		},
	},
	config = function()
		require("aerial").setup({
			backends = { "lsp", "markdown", "man", "treesitter" }, -- TODO: reactivate treesitter
			on_attach = function(bufnr) end,
		})
		require("telescope").load_extension("aerial")
	end,
}
