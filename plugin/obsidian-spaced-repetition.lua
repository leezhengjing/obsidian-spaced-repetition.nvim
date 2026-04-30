vim.api.nvim_create_user_command("ObsidianSRReview", function()
    require("obsidian-spaced-repetition").review_decks()
end, { desc = "Review Obsidian flashcard decks" })

vim.api.nvim_create_user_command("ObsidianSRReviewNote", function()
    require("obsidian-spaced-repetition").review_note()
end, { desc = "Review flashcards in the current note" })

vim.api.nvim_create_user_command("ObsidianSRReviewNoteAll", function()
    require("obsidian-spaced-repetition").review_note_all()
end, { desc = "Review ALL flashcards in the current note" })
