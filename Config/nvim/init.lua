local vim = vim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.python3_host_prog = "/home/neimog/.config/miniconda3.dir/bin/python3"

require("lazy").setup("config.plugins", {
	install = {
		colorscheme = {
			vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme"):match("prefer-dark") and "onedark"
				or "onelight",
		},
	},
	checker = {
		enabled = true,
		notify = true,
		frequency = 86400,
	},
})

require("config.keymaps")
require("config.keepupdate")
require("config.vimconfigs")
