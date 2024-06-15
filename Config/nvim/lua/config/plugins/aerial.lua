return {
	"stevearc/aerial.nvim",
	event = "VeryLazy",
	lazy = true,
	-- enabled = function()
	-- 	print(vim.inspect(vim.bo.filetype))
	-- 	return false
	-- end,
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
			backends = { "lsp", "markdown", "man" }, -- TODO: reactivate treesitter
			on_attach = function(bufnr) end,
		})
		require("telescope").load_extension("aerial")
	end,
}
