local M = {}
local config = require("obsidian-spaced-repetition.config")

function M.setup(opts)
    config.setup(opts)
end

function M.review_decks()
    require("obsidian-spaced-repetition.ui.picker").show_decks()
end

return M
