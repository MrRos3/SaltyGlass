-- Put src/SaltyGlassLibrary.lua into ReplicatedStorage as a ModuleScript named SaltyGlassLibrary.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Salty = require(ReplicatedStorage:WaitForChild("SaltyGlassLibrary"))

local Window = Salty:CreateOriginalWindow({
    Title = "Studio Custom Hub",
    Subtitle = "SALTYGLASS LIBRARY",
    MusicPlayer = true,
})

local Main = Window:AddTab("Main", "home")

Main:AddButton({
    Name = "Open Music",
    Icon = "music",
    Callback = function()
        Window:GetMusicPlayer():Open()
    end,
})

Main:AddButton({
    Name = "Hello",
    Callback = function()
        Window:Notify({
            Title = "SaltyGlass",
            Message = "Studio library works!",
        })
    end,
})
