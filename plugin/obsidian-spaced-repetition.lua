vim.api.nvim_create_user_command("ObsidianSRReview", function()
    require("obsidian-spaced-repetition").review_decks()
end, { desc = "Review Obsidian flashcards" })
