local Salty = _G.SaltyGlass
assert(Salty, "Load feature-pack.lua before FutureModule.lua")

Salty:RegisterCommand("hello", function(api, name)
    name = tostring(name or "Salty")
    api:Notify("Hello " .. name .. " <3", "success")
    return name
end, {
    Description = "Example command registered by a future module.",
    Role = "user",
})

Salty:RegisterFeature({
    Id = "future-example",
    Name = "Future Example",
    Tab = "World",
    Section = "FUTURE MODULE",
    Role = "user",
    Flag = "futureExample",
    Order = 940,

    Build = function(section, api)
        section:AddToggle({
            Id = "futureExample.enabled",
            Name = "Example Feature",
            Description = "Demonstrates the reusable feature registry.",
            Default = false,
            Callback = function(enabled)
                api:Notify(
                    enabled and "Example feature enabled" or "Example feature disabled"
                )
            end,
        })

        section:AddSlider({
            Id = "futureExample.power",
            Name = "Example Power",
            Description = "Saved automatically inside Salty profiles.",
            Min = 0,
            Max = 100,
            Default = 50,
            Increment = 1,
            Callback = function(value)
                print("[FutureModule] power:", value)
            end,
        })

        section:AddButton({
            Name = "Run Command",
            Description = "Calls the permission-aware command bridge.",
            ButtonText = "HELLO",
            Callback = function()
                api:ExecuteCommand("hello", "Future Module")
            end,
        })
    end,
})

return true
