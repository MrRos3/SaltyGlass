local base=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/releases/feature-pack-v1.0.0.lua")
local baseChunk,baseError=loadstring(base)
assert(baseChunk,"SaltyGlass base feature pack failed to compile: "..tostring(baseError))
baseChunk()

local frameworkSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/releases/framework-v1.0.0.lua")
local frameworkChunk,frameworkError=loadstring(frameworkSource)
assert(frameworkChunk,"SaltyGlass framework v1.0.0 failed to compile: "..tostring(frameworkError))
frameworkChunk()
