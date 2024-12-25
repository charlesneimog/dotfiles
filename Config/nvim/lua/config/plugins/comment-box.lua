return {
    {
        "LudoPinelli/comment-box.nvim",
        config = function()
            require("comment-box").setup({
                doc_width = 40, -- width of the document
                box_width = 40, -- width of the boxes
            })
        end,
    },
}
