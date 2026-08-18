local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-v1.3.2.lua")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key-v1.3.2.lua failed to compile: "..tostring(compileError))
chunk()