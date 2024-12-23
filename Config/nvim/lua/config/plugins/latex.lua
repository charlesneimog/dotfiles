local vim = vim

return {
	"micangl/cmp-vimtex",
	{
		"lervag/vimtex",
		ft = { "tex", "latex", "bib" },
		event = { "BufEnter *.tex,*.bib" },
		config = function()
			vim.g.vimtex_view_general_viewer = "xdg-open"
			vim.g.vimtex_view_general_options = [[--unique file:@pdf\#src:@line@tex]]
			vim.g.vimtex_compiler_latexmk = {
				backend = "nvim",
				build_dir = ".build",
				background = 1,
				callback = 1,
				continuous = 1,
				executable = "latexmk",
				options = {
					"-pdflua",
					-- "-pdflatex=lualatex",
					"-shell-escape",
					"-verbose",
					"-file-line-error",
					"-synctex=1",
					"-interaction=nonstopmode",
					"-auxdir=.build",
				},
			}
			vim.g.vimtex_quickfix_ignore_filters = {
				"Command terminated with space",
				"LaTeX Font Warning: Font shape",
				"Overfull",
				"Underfull",
				"Package caption Warning: The option",
				[[Underfull \\hbox (badness [0-9]*) in]],
				"Package enumitem Warning: Negative labelwidth",
				[[Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in]],
				[[Package caption Warning: Unused \\captionsetup]],
				"Package typearea Warning: Bad type area settings!",
				[[Package fancyhdr Warning: \\headheight is too small]],
				[[Underfull \\hbox (badness [0-9]*) in paragraph at lines]],
				"Package hyperref Warning: Token not allowed in a PDF string",
				[[Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in paragraph at lines]],
			}
			-- -- Check if the global variable doesn't exist
			-- if not vim.g.vim_window_id then
			-- 	-- Set the global variable using the result of the system command
			-- 	vim.g.vim_window_id = vim.fn.system("xdotool getactivewindow")
			-- end
			--
			-- -- Define a Lua function for TexFocusVim
			-- local function TexFocusVim()
			-- 	-- Give window manager time to recognize focus moved to Zathura
			-- 	-- Tweak the delay (200) as needed for your hardware and window manager
			-- 	vim.fn.sleep(200)
			--
			-- 	-- Refocus Vim and redraw the screen
			-- 	vim.fn.system("!xdotool windowfocus " .. vim.fn.expand(vim.g.vim_window_id))
			-- 	vim.cmd("redraw!")
			-- end
			--
			-- -- Make the Lua function accessible within Vimscript
			-- vim.api.nvim_set_var("TexFocusVim", TexFocusVim)
			--
			-- -- Map the function to a command (optional)
			-- vim.cmd("command! TexFocusVim lua TexFocusVim()")
		end,
	},
}
