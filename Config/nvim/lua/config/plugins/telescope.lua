local vim = vim

return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"folke/noice.nvim",
        "ibhagwan/fzf-lua",
		"nvim-telescope/telescope-project.nvim",
		"nvim-telescope/telescope-file-browser.nvim",
		"debugloop/telescope-undo.nvim",
		{
			"nvim-telescope/telescope-project.nvim",
			keys = {
				{ "<leader>sf", "<cmd>Telescope find_files<cr>", mode = { "i", "n" }, desc = "[S]earch [F]iles" },
				{ "<leader>sg", "<cmd>Telescope git_files<cr>", mode = { "i", "n" }, desc = "[S]earch [G]it Files" },
				{ "<leader>ss", "<cmd>Telescope live_grep<cr>", mode = { "i", "n" }, desc = "[S]earch [S]tring" },
				{
					"<leader>si",
					require("telescope.builtin").lsp_implementations,
					mode = { "i", "n" },
					desc = "[S]earch [D]efiniion",
				},
				{
					"<leader>sd",
					require("telescope.builtin").lsp_definitions,
					mode = { "i", "n" },
					desc = "[S]earch [D]efiniion",
				},
			},
		},
	},
	keys = {
		{
			"<leader>bf",
			":Telescope file_browser<CR>",
			mode = { "n", "i" },
			desc = "[F]ile [B]rowser",
		},
	},
	config = function()
		require("telescope").setup({
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				file_browser = {
					theme = "ivy",
					hidden = true,
					dir_icon = "",
					git_status = true,
					use_fd = true,
					hijack_netrw = true,
					mappings = {
						["i"] = {
							vim.keymap.set("i", "jk", "<Esc>", { desc = "[S]earch [F]iles" }),
						},
					},
				},

				project = {
					base_dirs = {
						"~/Documents/Git",
					},
					hidden_files = true, 
					theme = "dropdown",
					order_by = "asc",
					search_by = "title",
					sync_with_nvim_tree = true, -- default false
				},
				undo = {},
			},
		})
		require("telescope").load_extension("file_browser")
		require("telescope").load_extension("project")
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("noice")
		require("telescope").load_extension("undo")
	end,
}
