-- SaltyGlass stable loader
-- Requires an environment that permits HttpGet + loadstring on the Roblox client.

local URL = "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/latest.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)

if not ok then
    error("SaltyGlass: failed to download latest.lua: " .. tostring(source), 0)
end

local chunk, compileError = loadstring(source)
if not chunk then
    error("SaltyGlass: downloaded source failed to compile: " .. tostring(compileError), 0)
end

return chunk()
