# SaltyGlass

A polished Roblox client UI by **MrRos3**.

SaltyGlass is a cosmetic glass-style interface with a responsive window, tabs, player card, settings, visuals, music player, Lucide icons, theme controls, Reduce Motion, Reset UI, and a clean resize grip.

Current release: **v3.6.2 RC**

## Quick load

For environments that explicitly support client-side `HttpGet` and `loadstring`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/latest.lua"))()
```

`latest.lua` is the stable moving URL. It can be updated to a future release without changing your loader.

### Pin v3.6.2

Use the versioned URL when you do not want future updates:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/releases/v3.6.2.lua"))()
```

## SaltyGlass UI Library

The full GUI in `latest.lua` is still preserved. For custom scripts, use the reusable library:

```lua
local source = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/library.lua")
local chunk, err = loadstring(source)
assert(chunk, err)

local Salty = chunk()

local Window = Salty:CreateOriginalWindow({
    Title = "MY HUB",
    Subtitle = "POWERED BY SALTYGLASS",
})

local Main = Window:AddTab("Main", "home")

Main:AddButton({
    Name = "Hello",
    Callback = function()
        Window:Notify({
            Title = "SaltyGlass",
            Message = "It works!",
        })
    end,
})
```

`library.lua` intentionally **returns the API table**. Loading it by itself does not create a visible window; call `CreateWindow(...)` or `CreateOriginalWindow(...)`.

### Direct original-style showcase

If you want a file that creates a GUI immediately:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/showcase.lua"))()
```

The showcase demonstrates the original Salty feel with:

- background blur
- animated glass
- smooth fade/slide tab transitions
- one-shot page light sweep
- dynamic status island
- premium minimized badge
- clean resize grip
- reusable custom Roblox audio music player
- play / pause / stop
- Repeat / Repeat 1
- seek / volume / speed
- themes, custom accent, Reduce Motion, reset controls
- live FPS / ping / session telemetry
- custom-content builders

### Library v1.1.0 API

Window:

```text
CreateWindow
CreateOriginalWindow / CreatePremiumWindow
AddTab
AddMusicPlayer / CreateMusicPlayer
GetMusicPlayer
Notify
ShowStatus
SetAccent
SetTheme
SetBlurEnabled
SetBlurSize
SetReduceMotion
SetSize
SetPosition
SetWindowTransparency
Minimize
Restore
Show
Hide
Toggle
Reset
Destroy
```

Tab:

```text
AddSection
AddLabel / AddParagraph
AddButton
AddToggle
AddSlider
AddDropdown
AddTextbox / AddInput
AddKeybind
AddColorPicker
AddDivider
AddCustom
```

For a pinned library build:

```lua
local Salty = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/releases/library-v1.1.0.lua"
))()
```

## Roblox Studio / normal experience use

For a normal Roblox Studio project, use the included ModuleScript source instead of depending on a remote `loadstring`.

1. Create a ModuleScript named `SaltyGlass` in `ReplicatedStorage`.
2. Paste `src/SaltyGlassModule.lua` into it.
3. Start it from a client LocalScript:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SaltyGlass = require(ReplicatedStorage:WaitForChild("SaltyGlass"))

SaltyGlass.Start()
```

The UI is client-only.

## Repository layout

```text
SaltyGlass/
├── latest.lua
├── library.lua
├── showcase.lua
├── loader.lua
├── VERSION
├── src/
│   ├── SaltyGlass.client.lua
│   ├── SaltyGlassModule.lua
│   └── SaltyGlassLibrary.lua
├── releases/
│   ├── v3.6.2.lua
│   ├── library-v1.0.0.lua
│   └── library-v1.1.0.lua
├── examples/
│   ├── LibraryExample.lua
│   ├── OriginalStyleShowcase.lua
│   ├── StudioLibrary.client.lua
│   ├── Loadstring.lua
│   ├── PinnedLoadstring.lua
│   └── StudioModule.client.lua
├── README.md
├── CHANGELOG.md
├── LICENSE
└── SHA256SUMS.txt
```

## Features

- Liquid/glass interface styling
- White default borders
- Home / Player / Settings / Visuals tabs
- Context-aware top header
- Smooth tab transitions
- Player profile card
- Clean Lucide resize grip
- Custom Roblox audio ID music player
- Play / pause / stop
- Repeat / Repeat 1
- Volume and seek sliders
- Playback speed from 0.50× to 2.00×
- Static slider dots
- Dynamic status feedback
- Theme presets and RGB accent controls
- Background blur and UI sound toggles
- Reduce Motion
- Reset UI
- Minimized glass badge
- Right Shift show/hide hotkey
- Full GUI/music/blur cleanup on normal close
- ALT/F4-style in-experience exit control

## Updating `latest.lua`

When publishing a future release:

1. Add the versioned file under `releases/`.
2. Test the versioned raw URL.
3. Copy that exact tested release into `latest.lua`.
4. Update `VERSION` and `CHANGELOG.md`.
5. Keep old versioned files so existing pinned loaders do not break.

## Notes

- Audio IDs must be valid Roblox audio assets permitted for the experience/client environment.
- The project does not bundle commercial music.
- The ALT/F4-style control cannot close the operating-system Roblox window from a normal LocalScript; it performs the in-experience exit behavior implemented by SaltyGlass.
- The direct GitHub loader is intended only for client environments that explicitly expose `HttpGet` and `loadstring`. Normal Roblox experiences should use the ModuleScript/LocalScript source.

## Credits

Designed and maintained by **MrRos3**.

Lucide-style icons are used through Roblox image assets. See the source's icon mapping for the exact assets.

## License

MIT. See `LICENSE`.
