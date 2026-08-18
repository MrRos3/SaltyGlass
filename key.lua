local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system.lua")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key-system.lua failed to compile: "..tostring(compileError))
local KeySystem=chunk()
assert(type(KeySystem)=="table" and type(KeySystem.Open)=="function","SaltyGlass key system did not return a valid API table")
KeySystem.Open({
    Title="SALTYGLASS",
    Subtitle="SECURE ACCESS",
    Description="Enter your access key to unlock the interface.",
    Keys={"SALTY-ACCESS"},
    Sounds=true,
    Blur=true,
    ReduceMotion=false,
    OnSuccess=function()
        local guiSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua")
        local guiChunk,guiCompileError=loadstring(guiSource)
        assert(guiChunk,"SaltyGlass feature-pack.lua failed to compile: "..tostring(guiCompileError))
        guiChunk()
    end,
})
