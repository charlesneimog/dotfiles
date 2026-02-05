return {
	{
		"linrongbin16/lsp-progress.nvim",
		config = function()
			require("lsp-progress").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"vimls",
					"clangd",
					"pyright",
					"html",
					"ltex",
					"ts_ls",
				},
				automatic_enable = {
					"lua_ls",
					"vimls",
					"clangd",
					"pyright",
					"html",
					"ltex",
					"ts_ls",
				},
			})
		end,
	},
}
