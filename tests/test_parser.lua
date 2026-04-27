-- Mock vim for standalone testing
_G.vim = {
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
    startswith = function(s, prefix) return s:sub(1, #prefix) == prefix end,
    fn = {
        fnamemodify = function(f, mod) return f:match("([^/]+)%.md$") end
    },
    tbl_deep_extend = function(behavior, ...)
        local result = {}
        local tables = {...}
        for i, t in ipairs(tables) do
            for k, v in pairs(t) do
                result[k] = v
            end
        end
        return result
    end
}

local config = require("obsidian-spaced-repetition.config")
config.setup({
    vault_path = "/Users/leezhengjing/Github/obsidian-spaced-repetition.nvim/tests/vault",
    flashcard_tags = { "#flashcards" }
})

local deck_mod = require("obsidian-spaced-repetition.deck")
local decks = deck_mod.get_decks()

print("Decks found:")
for name, deck in pairs(decks) do
    print(string.format("Deck: %s, Due: %d, New: %d, Total: %d", name, deck.due, deck.new, deck.total))
    for i, card in ipairs(deck.cards) do
        print(string.format("  Card %d: %s -> %s (Type: %s, Side: %d)", i, card.question, card.answer, card.type, card.side))
        if card.scheduling then
            for _, s in ipairs(card.scheduling) do
                print(string.format("    Sched: Due=%s, Ivl=%s, Ease=%s", s.due_date, s.interval, s.ease))
            end
        end
    end
end
