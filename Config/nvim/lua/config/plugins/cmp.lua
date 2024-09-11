return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp",
		"L3MON4D3/LuaSnip",
		"micangl/cmp-vimtex",
		"onsails/lspkind.nvim",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
		"lukas-reineke/cmp-under-comparator",
		"hrsh7th/cmp-cmdline",
	},
	config = function()
		local cmp = require("cmp")
		local cmp_buffer = require("cmp_buffer")
		local compare = require("cmp.config.compare")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")
		require("luasnip.loaders.from_vscode").lazy_load()

		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		-- `:` cmdline setup.
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

		local icons = {
			Array = "  ",
			Boolean = "  ",
			Class = "  ",
			Copilot = "  ",
			Codeium = "  ",
			Color = "  ",
			Constant = "  ",
			Constructor = "  ",
			Enum = "  ",
			EnumMember = "  ",
			Event = "  ",
			Field = "  ",
			File = "  ",
			Folder = "  ",
			Function = "  ",
			Interface = "  ",
			Key = "  ",
			Keyword = "  ",
			Method = "  ",
			Module = "  ",
			Namespace = "  ",
			Null = " ﳠ ",
			Number = "  ",
			Object = "  ",
			Operator = "  ",
			Package = "  ",
			Property = "  ",
			Reference = "  ",
			Snippet = "  ",
			String = "  ",
			Struct = "  ",
			Text = "  ",
			TypeParameter = "  ",
			Unit = "  ",
			Value = "  ",
			Variable = "  ",
		}

		cmp.setup({
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			snippet = { -- configure how nvim-cmp interacts with snippet engine
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			formatting = {
				fields = { "kind", "abbr", "menu" },
				format = function(entry, item)
					item.kind = string.format("%s", icons[item.kind])
					item.menu = ({
						buffer = "[Buffer]",
						nvim_lsp = "[LSP]",
						nvim_lua = "[API]",
						copilot = "[Copilot]",
						path = "[Path]",
						rg = "[RG]",
					})[entry.source.name]
					return item
				end,
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

			sources = {
				{
					name = "codeium",
					max_item_count = 3,
				},
				{
					name = "copilot",
					max_item_count = 3,
				},
				{ name = "nvim_lsp" },
				{ name = "luasnip" }, -- snippets
				{ name = "buffer" }, -- text within current buffer
				{ name = "path" }, -- file system paths
				{ name = "vimtext" },
				-- { name = "treesitter" },
			},
			sorting = {
				comparators = {
					function(...)
						return cmp_buffer:compare_locality(...)
					end,
					compare.offset,
					compare.exact,
					compare.score,
					require("cmp-under-comparator").under,
					compare.recently_used,
					compare.locality,
					compare.kind,
					compare.sort_text,
					compare.length,
					compare.order,
				},
			},
		})
	end,
}
