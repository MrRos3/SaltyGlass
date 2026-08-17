local LIBRARY_URL = "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/library.lua"

local source = game:HttpGet(LIBRARY_URL)
local chunk, compileError = loadstring(source)

if not chunk then
    error("SaltyGlass library failed to compile: " .. tostring(compileError), 0)
end

local Salty = chunk()
if type(Salty) ~= "table" or type(Salty.CreateOriginalWindow) ~= "function" then
    error("SaltyGlass library returned an invalid API table.", 0)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local localPlayer = Players.LocalPlayer
local sessionStart = os.clock()

local Window = Salty:CreateOriginalWindow({
    Name = "SaltyGlassOriginalStyleShowcase",
    Title = "SALTY",
    Subtitle = "LIBRARY SHOWCASE",
    Accent = Salty.Themes.Violet,
    ToggleKey = Enum.KeyCode.RightShift,
    CloseBehavior = "Destroy",
})

local Music = Window:GetMusicPlayer()

local Home = Window:AddTab("Home", "home")
local Player = Window:AddTab("Player", "user")
local Settings = Window:AddTab("Settings", "settings")
local Visuals = Window:AddTab("Visuals", "eye")

Home:AddSection("OVERVIEW")

Home:AddLabel({
    Name = "SaltyGlass Library",
    Description = "Original-style glass UI with blur, smooth transitions, status island, resize, minimize, and reusable controls.",
    Icon = "home",
})

local telemetry = Home:AddLabel({
    Name = "FPS  --   |   PING  --   |   SESSION  0:00",
    Description = "Live client telemetry",
})

Home:AddButton({
    Name = "Open Music Player",
    Description = "Open the reusable custom-audio palette.",
    Icon = "music",
    Callback = function()
        if Music then
            Music:Open()
        end
    end,
})

Home:AddButton({
    Name = "Status Island Demo",
    Description = "Shows temporary context-aware feedback in the top bar.",
    Icon = "home",
    Callback = function()
        Window:ShowStatus({
            Title = "SALTY READY",
            Subtitle = "Dynamic status island",
            Icon = "home",
            Duration = 1.6,
        })
    end,
})

Player:AddSection("LOCAL PROFILE")

Player:AddLabel({
    Name = localPlayer and localPlayer.DisplayName or "Player",
    Description = localPlayer and ("@" .. localPlayer.Name) or "Local player",
    Icon = "user",
})

Player:AddLabel({
    Name = "User ID",
    Description = localPlayer and tostring(localPlayer.UserId) or "--",
})

Player:AddLabel({
    Name = "Account Age",
    Description = localPlayer and (tostring(localPlayer.AccountAge) .. " days") or "--",
})

Player:AddButton({
    Name = "Copy Profile Details",
    Description = "Prints safe local profile information to the console.",
    Icon = "user",
    Callback = function()
        if localPlayer then
            print("DisplayName:", localPlayer.DisplayName)
            print("Username:", localPlayer.Name)
            print("UserId:", localPlayer.UserId)
        end
        Window:ShowStatus({
            Title = "PROFILE",
            Subtitle = "Details printed to console",
            Icon = "user",
            Duration = 1.2,
        })
    end,
})

Settings:AddSection("THEME")

local ThemeDropdown = Settings:AddDropdown({
    Name = "Theme",
    Description = "Switch the SaltyGlass accent preset.",
    Options = {
        "Violet",
        "Blue",
        "Cyan",
        "Pink",
        "Green",
        "Orange",
        "Red",
    },
    Default = "Violet",
    Callback = function(theme)
        Window:SetTheme(theme)
        Window:ShowStatus({
            Title = string.upper(theme),
            Subtitle = "Theme applied",
            Icon = "settings",
            Duration = 1.0,
        })
    end,
})

Settings:AddColorPicker({
    Name = "Custom Accent",
    Description = "Fine-tune the accent color.",
    Default = Salty.Themes.Violet,
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Settings:AddSection("BEHAVIOR")

local BlurToggle = Settings:AddToggle({
    Name = "Background Blur",
    Description = "Blur the 3D scene behind the interface.",
    Default = true,
    Callback = function(enabled)
        Window:SetBlurEnabled(enabled)
        Window:ShowStatus({
            Title = "BACKGROUND BLUR",
            Subtitle = enabled and "Enabled" or "Disabled",
            Icon = "eye",
            Duration = 0.9,
        })
    end,
})

local MotionToggle = Settings:AddToggle({
    Name = "Reduce Motion",
    Description = "Disables the premium ambient and transition motion.",
    Default = false,
    Callback = function(enabled)
        Window:SetReduceMotion(enabled)
        Window:ShowStatus({
            Title = "REDUCE MOTION",
            Subtitle = enabled and "Enabled" or "Disabled",
            Icon = "settings",
            Duration = 0.9,
        })
    end,
})

Settings:AddSlider({
    Name = "Glass Transparency",
    Description = "Adjust the main window glass transparency.",
    Min = 0,
    Max = 60,
    Default = 8,
    Increment = 1,
    Suffix = "%",
    Callback = function(value)
        Window:SetWindowTransparency(value / 100)
    end,
})

Settings:AddKeybind({
    Name = "Example Feature Key",
    Description = "Shows how custom feature keybinds can be added.",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        Window:Notify({
            Title = "Keybind",
            Message = "Feature key pressed",
            Duration = 1.4,
        })
    end,
})

Settings:AddSection("RESET")

Settings:AddButton({
    Name = "Reset UI",
    Description = "Restore SaltyGlass window defaults.",
    Icon = "settings",
    ButtonWidth = 92,
    Callback = function()
        Window:Reset()
        Window:ShowStatus({
            Title = "UI RESET",
            Subtitle = "Defaults restored",
            Icon = "settings",
            Duration = 1.3,
        })
    end,
})

Visuals:AddSection("INTERFACE")

Visuals:AddToggle({
    Name = "Background Blur",
    Description = "Second control demonstrating that your scripts can wire multiple controls to the same feature.",
    Default = true,
    Callback = function(enabled)
        Window:SetBlurEnabled(enabled)
    end,
})

Visuals:AddButton({
    Name = "Minimize",
    Description = "Collapse into the premium SaltyGlass badge.",
    Icon = "minus",
    Callback = function()
        Window:Minimize()
    end,
})

Visuals:AddButton({
    Name = "Notification",
    Description = "Show a glass notification card.",
    Icon = "home",
    Callback = function()
        Window:Notify({
            Title = "SaltyGlass",
            Message = "Reusable notifications are working <3",
            Duration = 2.5,
        })
    end,
})

Visuals:AddCustom({
    Height = 82,
    Builder = function(container, ui)
        local iconImage = ui.Icon(container, "music", 17, ui.Window:GetAccent(), 3)
        if iconImage then
            iconImage.Position = UDim2.fromOffset(16, 17)
        end

        local heading = ui.TextLabel(container, "CUSTOM CONTENT", 10, ui.Colors.Text, Enum.Font.GothamBold)
        heading.Position = UDim2.fromOffset(44, 10)
        heading.Size = UDim2.new(1, -58, 0, 22)

        local body = ui.TextLabel(
            container,
            "AddCustom gives your script a styled container for any extra UI or feature you want to build.",
            9,
            ui.Colors.SubText,
            Enum.Font.Gotham
        )
        body.Position = UDim2.fromOffset(16, 35)
        body.Size = UDim2.new(1, -32, 0, 34)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
    end,
})

local frameCount = 0
local fps = 0
local lastSample = os.clock()
local telemetryConnection

local function getPing()
    local result = "--"
    pcall(function()
        local item = Stats.Network.ServerStatsItem["Data Ping"]
        local value = item:GetValue()
        result = tostring(math.floor(value + 0.5)) .. " ms"
    end)
    return result
end

telemetryConnection = RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1

    local now = os.clock()
    local elapsed = now - lastSample
    if elapsed >= 0.5 then
        fps = math.floor((frameCount / elapsed) + 0.5)
        frameCount = 0
        lastSample = now

        local session = math.floor(now - sessionStart)
        local minutes = math.floor(session / 60)
        local seconds = session % 60

        telemetry:SetText(
            string.format(
                "FPS  %d   |   PING  %s   |   SESSION  %d:%02d",
                fps,
                getPing(),
                minutes,
                seconds
            ),
            "Live client telemetry"
        )
    end
end)

Window:GetScreenGui().Destroying:Connect(function()
    if telemetryConnection then
        telemetryConnection:Disconnect()
        telemetryConnection = nil
    end
end)

Window:ShowStatus({
    Title = "SALTY READY",
    Subtitle = "Original-style library showcase",
    Icon = "home",
    Duration = 1.8,
})
