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

return M
