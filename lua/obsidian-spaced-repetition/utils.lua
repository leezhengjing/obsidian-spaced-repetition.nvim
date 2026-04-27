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

---Resolve an Obsidian image path to an absolute path
---@param vault_path string
---@param current_file string
---@param link_text string e.g. "Pasted image 123.png" or "path/to/img.png"
---@return string|nil
function M.resolve_image_path(vault_path, current_file, link_text)
    -- 1. Check if it's an absolute path already
    if link_text:sub(1, 1) == "/" then
        if vim.fn.filereadable(link_text) == 1 then return link_text end
    end

    -- 2. Check relative to current file
    local current_dir = current_file:match("(.*)/")
    if current_dir then
        local rel_path = current_dir .. "/" .. link_text
        if vim.fn.filereadable(rel_path) == 1 then return rel_path end
    end

    -- 3. Search in the whole vault (Obsidian's default behavior for [[links]])
    -- We can use find or just check if it's a simple filename
    local cmd = string.format('find "%s" -name "%s"', vault_path, link_text)
    local p = io.popen(cmd)
    if p then
        local first_match = p:read("*l")
        p:close()
        if first_match then return first_match end
    end

    return nil
end

return M
