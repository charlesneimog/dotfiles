return {
    "akinsho/toggleterm.nvim", -- Terminal
    event = "VimEnter",
    config = function()
        require("toggleterm").setup({
            dir = "git_dir",
        })
    end,
}
