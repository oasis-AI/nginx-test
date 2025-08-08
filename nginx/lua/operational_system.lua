local cjson = require "cjson.safe"
local file = "/usr/local/openresty/nginx/static/api/operational_system.json"

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

local args = ngx.req.get_uri_args()
local limit = tonumber(args.limit) or 10
local offset = tonumber(args.offset) or 0

local content = readfile(file)
if not content then return end

local data = cjson.decode(content)
if not data or not data.data or not data.data.items then
    ngx.status = 500
    ngx.say('{"msg":"json format error","code":500}')
    return
end

local items = data.data.items
local total = #items
local paged = {}

for i = offset + 1, math.min(offset + limit, total) do
    table.insert(paged, items[i])
end
setmetatable(paged, cjson.array_mt)  -- 保证空时为 []

local resp = {
    data = {
        total = total,
        items = paged
    },
    msg = "select success",
    code = 0
}
ngx.say(cjson.encode(resp))