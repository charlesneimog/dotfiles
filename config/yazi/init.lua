return {
    manager = {
        keymap = {
            ["n"] = {
                run = function(state)
                    os.execute(string.format("wezterm start -- nvim '%s' &", state.cwd))
                end,
                desc = "Open current directory in Neovim",
            },
        },
    },
}

