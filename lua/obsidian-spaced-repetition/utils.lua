local M = {}

---Scan directory recursively for files matching pattern
---@param path string
---@param pattern string
---@return string[]
function M.scan_dir(path, pattern)
    local files = {}
    local p = io.popen('find "' .. path .. '" -type f -name "' .. pattern .. '"')
    if p then
        for file in p:lines() do
            table.insert(files, file)
        end
        p:close()
    end
    return files
end

---Get current date in YYYY-MM-DD format
---@return string
function M.get_today()
    return os.date("%Y-%m-%d")
end

---Add days to a date string
---@param date_str string YYYY-MM-DD
---@param days number
---@return string YYYY-MM-DD
function M.add_days(date_str, days)
    local year, month, day = date_str:match("(%d+)-(%d+)-(%d+)")
    local t = os.time({ year = year, month = month, day = day })
    t = t + (days * 24 * 60 * 60)
    return os.date("%Y-%m-%d", t)
end

---Calculate difference in days between two dates
---@param date1 string YYYY-MM-DD
---@param date2 string YYYY-MM-DD
---@return number
function M.date_diff(date1, date2)
    local y1, m1, d1 = date1:match("(%d+)-(%d+)-(%d+)")
    local y2, m2, d2 = date2:match("(%d+)-(%d+)-(%d+)")
    if not y1 or not y2 then return 0 end
    local t1 = os.time({ year = y1, month = m1, day = d1 })
    local t2 = os.time({ year = y2, month = m2, day = d2 })
    return math.floor(os.difftime(t1, t2) / (24 * 60 * 60))
end

---Resolve an Obsidian image path to an absolute path
---@param vault_path string
---@param current_file string
---@param link_text string e.g. "Pasted image 123.png" or "path/to/img.png"
---@return string|nil
function M.resolve_image_path(vault_path, current_file, link_text)
    -- Remove any Obsidian-style alias/size info (e.g. [[image.png|100]])
    local parts = vim.split(link_text, "|")
    local clean_link = parts[1]
    
    -- Remove any Markdown title info (e.g. [alt](path "title"))
    clean_link = clean_link:match("^%s*([^%s]+)") or clean_link

    -- 1. Check if it's an absolute path already
    if clean_link:sub(1, 1) == "/" then
        if vim.fn.filereadable(clean_link) == 1 then return clean_link end
    end

    -- 2. Check relative to current file
    local current_dir = current_file:match("(.*)/") or "."
    local rel_path = current_dir .. "/" .. clean_link
    if vim.fn.filereadable(rel_path) == 1 then return rel_path end

    -- 3. Check relative to vault root
    local vault_rel_path = vault_path .. "/" .. clean_link
    if vim.fn.filereadable(vault_rel_path) == 1 then return vault_rel_path end

    -- 4. Search in the whole vault for the filename (Obsidian's fallback)
    local filename = clean_link:match("([^/]+)$") or clean_link
    local cmd = string.format('find "%s" -name "%s" | head -n 1', vault_path, filename)
    local p = io.popen(cmd)
    if p then
        local match = p:read("*l")
        p:close()
        if match then return match end
    end

    return nil
end

return M
