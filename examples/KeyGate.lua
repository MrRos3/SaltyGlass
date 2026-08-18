local keySource = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system.lua")
local keyChunk, keyCompileError = loadstring(keySource)
assert(keyChunk, "SaltyGlass key-system.lua failed to compile: " .. tostring(keyCompileError))

local KeySystem = keyChunk()
assert(
    type(KeySystem) == "table" and type(KeySystem.Open) == "function",
    "SaltyGlass key system did not return a valid API table"
)

KeySystem.Open({
    Title = "SALTYGLASS",
    Subtitle = "ACCESS GATE",
    Description = "Enter your SaltyGlass access key to continue.",
    Keys = {
        "SALTY-ACCESS",
    },
    Sounds = true,
    Blur = true,
    ReduceMotion = false,
    OnSuccess = function()
        local source = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua")
        local chunk, compileError = loadstring(source)
        assert(chunk, "SaltyGlass feature-pack.lua failed to compile: " .. tostring(compileError))
        chunk()
    end,
})

