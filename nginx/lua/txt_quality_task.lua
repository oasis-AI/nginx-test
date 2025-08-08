local cjson = require "cjson.safe"
local file = "/usr/local/openresty/nginx/static/api/txt_quality_task.json"

local function readfile(path)
    local f = io.open(path, "r")
    if not f then
        ngx.status = 404
        ngx.say('{"msg":"file not found","code":404}')
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

local function parse_time(str)
    -- 兼容 "2024-08-01T08: 08: 08" 和 "2025-08-06 00:00"
    str = str:gsub("T", " "):gsub(":", ":", 1)
    local y, m, d, h, min, s = str:match("(%d+)%-(%d+)%-(%d+)%s+(%d+):%s*(%d+):%s*(%d+)")
    if not y then
        y, m, d, h, min = str:match("(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+)")
        s = 0
    end
    if y then
        return os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(h), min=tonumber(min), sec=tonumber(s)})
    end
    return nil
end

ngx.req.read_body()
local body = ngx.req.get_body_data()
local args = cjson.decode(body or "{}") or {}

local limit = tonumber(args.limit) or 10
local offset = tonumber(args.offset) or 0
local dateRange = args.dateRange

local content = readfile(file)
if not content then return end

local data = cjson.decode(content)
if not data or not data.data or not data.data.items then
    ngx.status = 500
    ngx.say('{"msg":"json format error","code":500}')
    return
end

local items = data.data.items
local filtered = {}

local start_time, end_time
if dateRange and #dateRange == 2 then
    start_time = parse_time(dateRange[1])
    end_time = parse_time(dateRange[2])
end

for _, item in ipairs(items) do
    local created_at = item.created_at
    if created_at and start_time and end_time then
        local t = parse_time(created_at)
        if t and t >= start_time and t <= end_time then
            table.insert(filtered, item)
        end
    else
        table.insert(filtered, item)
    end
end

local total = #filtered
local paged = {}
for i = offset + 1, math.min(offset + limit, total) do
    table.insert(paged, filtered[i])
end
setmetatable(paged, cjson.array_mt)  -- 保证空时为 []

local resp = {
    data = {
        items = paged,
        total = total,
        children_total = data.data.children_total or 0
    },
    msg = "select success",
    code = 0,
    allIPs = {"192.168.148.1"}
}
ngx.say(cjson.encode(resp))