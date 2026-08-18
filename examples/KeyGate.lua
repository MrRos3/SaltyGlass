local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key.lua?example=clean")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key.lua failed to compile: "..tostring(compileError))
chunk()
