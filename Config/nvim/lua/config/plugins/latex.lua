local vim = vim

return {
	"micangl/cmp-vimtex",
	{
		"lervag/vimtex",
		ft = { "tex", "latex", "bib" },
		event = { "BufEnter *.tex,*.bib" },
		config = function() end,
	},
}
