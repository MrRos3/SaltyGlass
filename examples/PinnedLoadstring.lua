-- SaltyGlass pinned loader — v3.6.2 RC
-- This URL never tracks future releases.

local URL = "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/releases/v3.6.2.lua"
local source = game:HttpGet(URL)
local chunk, compileError = loadstring(source)

if not chunk then
    error("SaltyGlass v3.6.2: compile failed: " .. tostring(compileError), 0)
end

return chunk()
