--╭─────────────────────────────────────╮
--│                ALPHA                │
--╰─────────────────────────────────────╯
require("telescope").load_extension("project")
local _, alpha = pcall(require, "alpha")
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
	[[                               __                ]],
	[[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
	[[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
	[[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
	[[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
	[[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
}

dashboard.section.buttons.val = {
	dashboard.button("<" .. vim.g.cmdkey .. "P>", "󰱼  Find file", ":Telescope find_files <CR>"),
	dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("p", "  Find project", ":Telescope project <CR>"),
	dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
	dashboard.button("<" .. vim.g.cmdkey .. "S-F>", "󱘢  Find text", ":Telescope live_grep <CR>"),
	dashboard.button("c", "  Configuration", ":e ~/.config/nvim/init.lua <CR>"),
	dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
}

dashboard.section.footer.val = "Charles K. Neimog"
dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"
dashboard.opts.opts.noautocmd = true
alpha.setup(dashboard.opts)

--╭─────────────────────────────────────╮
--│               AERIAL                │
--╰─────────────────────────────────────╯
-- Definitions of functions in <leader>a
require("aerial").setup({
	backends = { "lsp", "markdown", "man", "treesitter" },
})

--╭─────────────────────────────────────╮
--│             Black Line              │
--╰─────────────────────────────────────╯
-- render tabs
require("ibl").setup({
	indent = {
		char = "▏",
	},
})

--╭─────────────────────────────────────╮
--│             COMPLETION              │
--╰─────────────────────────────────────╯
local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

require("cmp_vimtex").setup({})
require("cmp_buffer")
require("cmp.config.compare")
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./snippets" } })

cmp.setup.cmdline("/", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{
			name = "cmdline",
			option = {
				ignore_cmds = { "Man", "!" },
			},
		},
	}),
})

cmp.setup({
	snippet = { -- configure how nvim-cmp interacts with snippet engine
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},

	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol", -- show only symbol annotations
			maxwidth = {
				menu = 50,
				abbr = 50,
			},
			ellipsis_char = "...",
			show_labelDetails = true,
			before = function(_, vim_item)
				return vim_item
			end,
		}),
	},

	window = {
		completion = require("cmp.config.window").bordered(),
		documentation = require("cmp.config.window").bordered(),
	},

	mapping = cmp.mapping.preset.insert({
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "n" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(1) then
				luasnip.jump(1)
			else
				fallback()
			end
		end, { "i", "n" }),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),

	sources = cmp.config.sources({
		{ name = "luasnip" },
		{ name = "buffer" },
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "vimtext" },
	}),

	sorting = {
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,
			require("cmp-under-comparator").under,
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
})

--╭─────────────────────────────────────╮
--│             Comment Box             │
--╰─────────────────────────────────────╯
require("comment-box").setup({
	doc_width = 40, -- width of the document
	box_width = 40, -- width of the boxes
})

--╭─────────────────────────────────────╮
--│              FORMARTING             │
--╰─────────────────────────────────────╯
FILES_TO_FORMAT = {}

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
	},
	format_on_save = function(bufnr)
		local file = vim.api.nvim_buf_get_name(bufnr)
		local dir = vim.fn.fnamemodify(file, ":h")

		if FILES_TO_FORMAT[dir] == nil then
			local choice = vim.fn.confirm("Format this file?", "&Yes\n&No", 2)
			FILES_TO_FORMAT[dir] = (choice == 1)
		end
		if FILES_TO_FORMAT[dir] then
			return {
				timeout_ms = 500,
				lsp_format = "fallback",
			}
		else
			return false
		end
	end,
})

--╭─────────────────────────────────────╮
--│                Lint                 │
--╰─────────────────────────────────────╯
local lint = require("lint")
lint.linters_by_ft = {
	javascript = { "eslint_d" },
	typescript = { "eslint_d" },
	json = { "jsonlint" },
	lua = { "luacheck" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		lint.try_lint()
	end,
})

--╭─────────────────────────────────────╮
--│                 LSP                 │
--╰─────────────────────────────────────╯
require("mason-lspconfig").setup({
	automatic_enable = false,
})

vim.api.nvim_set_keymap(
	"n",
	"<leader>rn",
	"<cmd>lua vim.lsp.buf.rename()<CR>",
	{ noremap = true, silent = true, desc = "[R]ename [N]ode" }
)

vim.api.nvim_set_keymap(
	"n",
	"<leader>v",
	"<cmd>lua vim.diagnostic.open_float()<CR>",
	{ noremap = true, silent = true, desc = "[V]iew [D]iagnostics" }
)

vim.api.nvim_set_keymap(
	"n",
	"ca",
	"<cmd>lua vim.lsp.buf.code_action()<CR>",
	{ noremap = true, silent = true, desc = "Code [A]ction" }
)

require("lsp-progress").setup()

--╭─────────────────────────────────────╮
--│               LUALINE               │
--╰─────────────────────────────────────╯
local function mylocation()
	local line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	return string.format("%3d-%-2d", line, total_lines)
end

require("lualine").setup({
	options = {
		theme = "auto",
		icons_enabled = true,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = true,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	inactive_winbar = {
		lualine_a = { "buffers" },
		lualine_z = { "os.date('%a')", "data", "require'lsp-status'.status()" },
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = {
			"branch",
			{
				"diff",
				colored = false,
				symbols = { added = "+", modified = "~", removed = "-" },
			},
			"diagnostics",
		},
		lualine_c = {
			-- {
			-- 	"filename",
			-- 	file_status = true, -- Displays file status (readonly status, modified status)
			-- 	newfile_status = false, -- Display new file status (new file means no write after created)
			-- 	path = 0, -- 0: Just the filename
			-- 	shorting_target = 10, -- Shortens path to leave 40 spaces in the window
			-- 	symbols = {
			-- 		modified = "[+]", -- Text to show when the file is modified.
			-- 		readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
			-- 		unnamed = "[No Name]", -- Text to show for unnamed buffers.
			-- 		newfile = "[New]", -- Text to show for newly created file before first write
			-- 	},
			-- },
			function()
				return require("lsp-progress").progress()
			end,
		},
		lualine_x = {
			{
				"buffers",
				buffers_color = {
					active = "lualine_b_normal",
					inactive = "lualine_b_inactive",
				},
			},
		},
		lualine_z = {
			mylocation,
		},
	},
})

--╭─────────────────────────────────────╮
--│                NOICE                │
--╰─────────────────────────────────────╯
require("noice").setup({
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
		},
	},
	-- you can enable a preset for easier configuration
	presets = {
		bottom_search = true, -- use a classic bottom cmdline for search
		command_palette = true, -- position the cmdline and popupmenu together
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = false, -- add a border to hover docs and signature help
	},
})
--╭─────────────────────────────────────╮
--│                MASON                │
--╰─────────────────────────────────────╯
require("mason").setup({})

--╭─────────────────────────────────────╮
--│             TREESITTER              │
--╰─────────────────────────────────────╯
require("nvim-treesitter").install({
	"c",
	"lua",
	"javascript",
	"vim",
	"bash",
	"kdl",
	-- "html",
	"regex",
	"markdown",
	"markdown_inline",
	"vimdoc",
	"query",
})

--╭─────────────────────────────────────╮
--│                THEME                │
--╰─────────────────────────────────────╯
require("catppuccin").setup({
	flavour = "mocha",
	background = {
		light = "latte",
		dark = "mocha",
	},
	transparent_background = true,
	float = {
		transparent = true,
		solid = false,
	},
	show_end_of_buffer = false,
	term_colors = true,
	styles = {
		comments = { "italic" },
		conditionals = { "bold" },
		loops = {},
		functions = {},
		keywords = {},
		strings = {},
		variables = {},
		numbers = {},
		booleans = {},
		properties = {},
		types = {},
		operators = {},
	},
	lsp_styles = {
		virtual_text = {
			errors = { "italic" },
			hints = { "italic" },
			warnings = { "italic" },
			information = { "italic" },
			ok = { "italic" },
		},
		underlines = {
			errors = { "underline" },
			hints = { "underline" },
			warnings = { "underline" },
			information = { "underline" },
			ok = { "underline" },
		},
		inlay_hints = {
			background = true,
		},
	},
	color_overrides = {
		latte = {
			bg = "#ff0000",
		},
		frappe = {},
		macchiato = {},
		mocha = {},
	},

	custom_highlights = {},
	default_integrations = true,
	auto_integrations = false,
	integrations = {
		aerial = true,
		alpha = true,
		cmp = true,
		indent_blankline = {
			enabled = true,
		},
		gitsigns = true,
		nvimtree = true,
		notify = true,
		noice = true,
		mason = true,
		mini = {
			enabled = true,
			indentscope_color = "",
		},
		telescope = {
			enabled = true,
		},
		lsp_trouble = true,
		which_key = true,
	},
})

local sysname = vim.loop.os_uname().sysname
if sysname == "Linux" then
	local theme = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
	if theme:match("'prefer%-dark'") then
		vim.cmd.colorscheme("catppuccin-mocha")
	else
		vim.cmd.colorscheme("catppuccin-latte")
	end
elseif sysname == "Darwin" then
	local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
	if handle ~= nil then
		local result = handle:read("*a")
		handle:close()
		if result:match("Dark") then
			vim.cmd.colorscheme("catppuccin-mocha")
		else
			vim.cmd.colorscheme("catppuccin-latte")
		end
	end
end

--╭─────────────────────────────────────╮
--│              Telescope              │
--╰─────────────────────────────────────╯
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
require("telescope").load_extension("noice")
require("telescope").load_extension("undo")

--╭─────────────────────────────────────╮
--│               TROUBLE               │
--╰─────────────────────────────────────╯
require("trouble").setup({
	position = "right",
	width = 50,
})
