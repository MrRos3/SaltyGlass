-- SaltyGlass Library v1.0.0 example

local Salty = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/library.lua"
))()

local Window = Salty:CreateWindow({
    Title = "My Custom Hub",
    Subtitle = "POWERED BY SALTYGLASS",
    Accent = Salty.Themes.Violet,
    ToggleKey = Enum.KeyCode.RightShift,
})

local Home = Window:AddTab("Home", "home")
local Features = Window:AddTab("Features", "eye")
local Settings = Window:AddTab("Settings", "settings")

Home:AddSection("WELCOME")

Home:AddLabel({
    Name = "SaltyGlass Library",
    Description = "Build custom scripts without recreating the UI every time.",
    Icon = "home",
})

Home:AddButton({
    Name = "Test Notification",
    Description = "Shows a SaltyGlass toast.",
    Callback = function()
        Window:Notify({
            Title = "SaltyGlass",
            Message = "Your custom script is working <3",
            Duration = 3,
        })
    end,
})

Features:AddSection("CUSTOM CONTROLS")

local Toggle = Features:AddToggle({
    Name = "Example Toggle",
    Description = "Put your enable/disable code inside this callback.",
    Default = false,
    Callback = function(enabled)
        print("Toggle:", enabled)
    end,
})

local Slider = Features:AddSlider({
    Name = "Example Power",
    Description = "A reusable numeric value control.",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        print("Power:", value)
    end,
})

local Dropdown = Features:AddDropdown({
    Name = "Example Mode",
    Options = { "Normal", "Smooth", "Fast" },
    Default = "Normal",
    Callback = function(mode)
        print("Mode:", mode)
    end,
})

Features:AddTextbox({
    Name = "Custom Message",
    Placeholder = "Type something...",
    Callback = function(text, enterPressed)
        if enterPressed then
            print("Message:", text)
        end
    end,
})

Features:AddKeybind({
    Name = "Example Keybind",
    Default = Enum.KeyCode.F,
    Callback = function()
        print("F was pressed")
    end,
})

Features:AddColorPicker({
    Name = "Custom Color",
    Description = "Use the returned Color3 however you want.",
    Default = Color3.fromRGB(139, 124, 255),
    Callback = function(color)
        print("Color:", color)
    end,
})

Features:AddCustom({
    Height = 62,
    Builder = function(container, ui)
        local label = ui.TextLabel(container, "Your own custom Roblox UI can go here.", 10, ui.Colors.Text, Enum.Font.GothamMedium)
        label.Position = UDim2.fromOffset(14, 0)
        label.Size = UDim2.new(1, -28, 1, 0)
    end,
})

Settings:AddSection("APPEARANCE")

Settings:AddDropdown({
    Name = "Theme",
    Options = { "Violet", "Blue", "Cyan", "Pink", "Green", "Orange", "Red" },
    Default = "Violet",
    Callback = function(theme)
        Window:SetTheme(theme)
    end,
})

Settings:AddColorPicker({
    Name = "Accent",
    Default = Salty.Themes.Violet,
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Settings:AddToggle({
    Name = "Reduce Motion",
    Default = false,
    Callback = function(enabled)
        Window:SetReduceMotion(enabled)
    end,
})

Settings:AddButton({
    Name = "Reset Layout",
    Callback = function()
        Window:ResetLayout()
    end,
})

Window:Notify({
    Title = "My Custom Hub",
    Message = "Loaded successfully.",
    Duration = 3,
})
