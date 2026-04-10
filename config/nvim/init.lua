vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.diagnostic.config({ virtual_text = true })

require("config.vimconfigs")
require("config.term")
-- require("vim._core.ui2").enable({})

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "nvim-treesitter" and kind == "update" then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add({
	-- GUI
	"https://github.com/nvim-tree/nvim-web-devicons",

	-- Quality of Live
	"https://github.com/folke/snacks.nvim",

	-- Treesitter
	"https://github.com/nvim-treesitter/nvim-treesitter", -- Highlighting
	"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	-- "https://github.com/nvim-treesitter/playground",

	"https://github.com/goolord/alpha-nvim",
	-- telescope
	"https://github.com/nvim-telescope/telescope-file-browser.nvim",
	"https://github.com/nvim-telescope/telescope-project.nvim",
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	"https://github.com/debugloop/telescope-undo.nvim",
	"https://github.com/nvim-telescope/telescope-file-browser.nvim",

	-- cmp
	"https://github.com/hrsh7th/cmp-buffer",
	"https://github.com/hrsh7th/cmp-path",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/lukas-reineke/cmp-under-comparator",
	"https://github.com/hrsh7th/cmp-cmdline",

	"https://github.com/micangl/cmp-vimtex",

	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/onsails/lspkind.nvim",
	"https://github.com/saadparwaiz1/cmp_luasnip",
	"https://github.com/rafamadriz/friendly-snippets",

	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/stevearc/aerial.nvim",
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/LudoPinelli/comment-box.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/m4xshen/hardtime.nvim",
	"https://github.com/mfussenegger/nvim-lint",
	"https://github.com/linrongbin16/lsp-progress.nvim",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/rcarriga/nvim-notify",
	"https://github.com/nacro90/numb.nvim",
	"https://github.com/brenoprata10/nvim-highlight-colors",
	"https://github.com/mfussenegger/nvim-lint",
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/charlesneimog/Concentrate",
	"https://github.com/luisjure/csound-vim",
	"https://github.com/mcauley-penney/visual-whitespace.nvim",
	"https://github.com/catppuccin/nvim",
	"https://github.com/folke/todo-comments.nvim",
	"https://github.com/akinsho/toggleterm.nvim",

	-- LSP
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/linrongbin16/lsp-progress.nvim",
	"https://github.com/neovim/nvim-lspconfig",

	-- treesitter
	"https://github.com/nvim-treesitter/nvim-treesitter",

	-- Debug
	"https://github.com/folke/trouble.nvim",

	-- undo tree
	"https://github.com/mbbill/undotree",
	"https://github.com/mg979/vim-visual-multi",
	"https://github.com/gbprod/yanky.nvim",

	-- noice
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/folke/noice.nvim",

	-- render tabs
	"https://github.com/lukas-reineke/indent-blankline.nvim",
})

require("config.keys")
require("config.config")
require("config.lsp")
