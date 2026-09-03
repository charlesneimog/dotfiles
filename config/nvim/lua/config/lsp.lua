require("mason-lspconfig").setup({
	ensure_installed = {
		"lua_ls",
		"pyright",
		"clangd",
		"ts_ls",
		"html",
		"cssls",
		"yamlls",
		"tinymist",
	},
})

vim.lsp.enable("lua_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("clangd")
vim.lsp.enable("ts_ls")
vim.lsp.enable("html")
vim.lsp.enable("cssls")
vim.lsp.enable("yamlls")
vim.lsp.enable("tinymist")

vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site/pack/core/opt/OpenScofo/Sources/Language/nvim")
require("openscofo").setup()
