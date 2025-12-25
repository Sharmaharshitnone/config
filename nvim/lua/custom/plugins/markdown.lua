return{
{
        "MeanderingProgrammer/render-markdown.nvim",
        enabled = true, -- Temporarily disabled to check for conflicts with image.nvim
        ft = { "markdown", "codecompanion" }, -- works with AI plugins too
        opts = {
            code = {
                sign = false,
                width = "block",
                right_pad = 1,
            },
            heading = {
                sign = false,
                icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
            },
        },
    },
}
