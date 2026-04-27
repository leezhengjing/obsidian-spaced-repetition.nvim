local M = {}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local deck_mod = require("obsidian-spaced-repetition.deck")

function M.show_decks()
    local decks = deck_mod.get_decks()
    local results = {}
    for _, deck in pairs(decks) do
        table.insert(results, deck)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 30 }, -- Deck name
            { width = 10 }, -- Due
            { width = 10 }, -- New
            { width = 10 }, -- Total
        },
    })

    local make_display = function(entry)
        return displayer({
            entry.value.name,
            { "Due: " .. entry.value.due, "DiagnosticInfo" },
            { "New: " .. entry.value.new, "DiagnosticWarn" },
            { "Total: " .. entry.value.total, "Comment" },
        })
    end

    pickers.new({}, {
        prompt_title = "Obsidian Flashcard Decks",
        finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = make_display,
                    ordinal = entry.name,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- review_ui will be implemented next
                require("obsidian-spaced-repetition.ui.review").start_review(selection.value)
            end)
            return true
        end,
    }):find()
end

return M
