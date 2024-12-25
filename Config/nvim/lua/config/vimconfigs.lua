local vim = vim

vim.o.hlsearch = true
vim.wo.number = true
vim.o.mouse = ""
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true -- Ignore case when searching
vim.o.smartcase = true -- Don't ignore case with capitals
vim.wo.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.wo.relativenumber = true
vim.o.wrap = true
vim.o.tabstop = 4
vim.opt.viminfo:append("!")
vim.o.viewoptions = "cursor,folds,slash,unix"
vim.o.softtabstop = 0
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.smarttab = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.o.showmode = false
vim.opt.scrolloff = 8
vim.o.termguicolors = true
vim.o.completeopt = "menuone,noselect"
vim.o.timeoutlen = 200

vim.diagnostic.config({
	virtual_text = false,
	update_in_insert = true,
	float = {
		border = "rounded",
		source = "always",
	},
})
