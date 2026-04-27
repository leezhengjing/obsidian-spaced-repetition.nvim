local M = {}
local parser = require("obsidian-spaced-repetition.parser")
local config = require("obsidian-spaced-repetition.config")
local utils = require("obsidian-spaced-repetition.utils")

---@class Deck
---@field name string
---@field due number
---@field new number
---@field total number
---@field cards Card[]

---Get all decks and their statistics
---@return table<string, Deck>
function M.get_decks()
    local vault_path = config.options.vault_path
    local tags = config.options.flashcard_tags
    local files = parser.find_files_with_tags(vault_path, tags)
    
    if #files == 0 then
        vim.notify("Obsidian SR: No files found with tags: " .. table.concat(tags, ", "), vim.log.levels.DEBUG)
    end

    local decks = {}
    local today = utils.get_today()

    for _, file in ipairs(files) do
        local cards = parser.parse_file(file)
        if #cards == 0 then
            vim.notify("Obsidian SR: No cards parsed in file: " .. file, vim.log.levels.DEBUG)
        end
        
        -- Try to find the specific tag in the file to determine deck name
        local file_content = ""
        local f = io.open(file, "r")
        if f then
            file_content = f:read("*all")
            f:close()
        end

        local deck_name = "Default"
        for _, tag in ipairs(tags) do
            -- Look for #tag/subdeck or #tag
            -- Escape tag for pattern
            local escaped_tag = tag:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
            local pattern = escaped_tag .. "/?([%w%-_/]*)"
            local sub = file_content:match(pattern)
            if sub then
                if sub == "" then
                    deck_name = tag:sub(2) -- remove #
                else
                    deck_name = sub
                end
                break
            end
        end

        if not decks[deck_name] then
            decks[deck_name] = { name = deck_name, due = 0, new = 0, total = 0, cards = {} }
        end

        for _, card in ipairs(cards) do
            card.deck = deck_name
            table.insert(decks[deck_name].cards, card)
            decks[deck_name].total = decks[deck_name].total + 1
            
            if not card.scheduling or #card.scheduling == 0 then
                decks[deck_name].new = decks[deck_name].new + 1
            else
                local is_due = false
                for _, s in ipairs(card.scheduling) do
                    if s.due_date <= today then
                        is_due = true
                        break
                    end
                end
                if is_due then
                    decks[deck_name].due = decks[deck_name].due + 1
                end
            end
        end
    end
    return decks
end

return M
