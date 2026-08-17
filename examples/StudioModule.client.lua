-- StarterPlayerScripts / StarterGui LocalScript example
-- Put SaltyGlassModule.lua into ReplicatedStorage as a ModuleScript named "SaltyGlass".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaltyGlass = require(ReplicatedStorage:WaitForChild("SaltyGlass"))

local gui = SaltyGlass.Start()
print("SaltyGlass started:", gui and gui.Name)
