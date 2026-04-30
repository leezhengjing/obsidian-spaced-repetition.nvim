local M = {}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local deck_mod = require("obsidian-spaced-repetition.deck")

---Show a picker to select a deck for review
---@param filter_file string|nil
---@param review_all boolean|nil
function M.show_decks(filter_file, review_all)
    local decks = deck_mod.get_decks(filter_file)
    local results = {}
    for _, deck in pairs(decks) do
        table.insert(results, deck)
    end

    if #results == 0 then
        vim.notify("No flashcards found!", vim.log.levels.INFO)
        return
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
        prompt_title = filter_file and "Flashcards in Current Note" or "Obsidian Flashcard Decks",
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
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    require("obsidian-spaced-repetition.ui.review").start_review(selection.value, review_all)
                end
            end)
            return true
        end,
    }):find()
end

return M
