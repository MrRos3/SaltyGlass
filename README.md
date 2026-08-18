# SaltyGlass

Original-look Roblox glass UI by **MrRos3**. SaltyGlass keeps the original glass/white-border/Lucide visual language and avoids decorative blobs.

## Original
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/latest.lua"))()
```

## Feature Pack 2.0
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua"))()
```

Feature Pack 2.0 loads the original-looking Player/World/Utility pack plus `framework.lua`.

Framework **v2.1** adds:
- RGB + HEX accent picker
- feature/module registry
- permission-aware command bridge
- profiles with file persistence + session fallback
- user/beta/admin/owner roles
- stable/beta/dev update channels
- feature flags
- notification history
- opt-in telemetry hooks
- backup/recovery snapshots

## Key gate
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key.lua"))()
```

The key launcher supports expiration, remembered keys, install/session binding, remote validation, roles, update channels, and feature flags. Roblox LocalScripts do not expose a genuine HWID, so SaltyGlass uses a generated persistent install ID and per-run session ID instead.

## Extension API
After Feature Pack 2.0 loads, use `_G.SaltyGlass` (and `getgenv().SaltyGlass` where available).

```lua
local Salty = _G.SaltyGlass

Salty:RegisterFeature({
    Id = "weather-tools",
    Name = "Weather Tools",
    Tab = "World",
    Section = "WEATHER",
    Role = "beta",
    Flag = "newWorldTools",
    Build = function(section)
        section:AddToggle({
            Id = "weather.enabled",
            Name = "Weather",
            Description = "Example future feature.",
            Default = false,
            Callback = function(enabled)
                print("Weather:", enabled)
            end,
        })
    end,
})
```

Modules can be registered with `RegisterModule()` or loaded with `LoadModule()`.

Commands can be added with `RegisterCommand()` and run with `ExecuteCommand()` or `RunCommandLine()`:

```lua
Salty:RegisterCommand("hello", function(api, name)
    api:Notify("Hello " .. tostring(name or "Salty"))
end, {
    Role = "user",
})

Salty:RunCommandLine("hello MrRos3")
```

See `examples/FutureModule.lua` for a complete feature + command extension example.

## Remote validator
`server/validator-worker.js` is a Cloudflare Workers + KV example. Key records may include `expiresAt`, `role`, `updateChannel`, `featureFlags`, and the binding/session fields managed by the worker.
