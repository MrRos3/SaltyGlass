# Changelog

## SaltyGlass Library v1.0.0

- Added `library.lua`, a reusable custom UI builder.
- Added window, tab, section, label, button, toggle, slider, dropdown, textbox, keybind, color picker, divider, and custom-content APIs.
- Added window notifications, themes, custom accents, Reduce Motion, minimize/restore, resize, drag, hotkey show/hide, and cleanup.
- Added `releases/library-v1.0.0.lua` for a pinned library build.
- Added `examples/LibraryExample.lua`.
- Kept the finished v3.6.2 full GUI in `latest.lua` unchanged.

## v3.6.2 RC

Release-candidate UI build.

### Final polish
- Simplified resize affordance to a clean icon-only Lucide grip.
- Kept a larger invisible resize hit area for usability.
- Added Reduce Motion.
- Added Reset UI.
- Kept the context-aware header and premium status feedback.
- Removed experimental pin-art hover.
- Removed click-burst / press effects.
- Removed decorative music-player blobs.
- Removed tooltips.
- Removed command palette.
- Removed About tab.
- Removed Home FPS bar graph while keeping text telemetry.
- Standardized default GUI/button/music borders to white.

### Music
- Custom Roblox audio ID workflow only.
- Play, pause, stop.
- Repeat and Repeat 1.
- Volume and seek.
- Playback speed 0.50×–2.00×.
- Static slider dots.
- No album-cover or play-button pulse animations.

### Stability
- Loadstring distribution build safely handles the absence of a Script instance.
- Client-only guard provides a clear error if executed outside a client context.
- Existing SaltyGlass GUI and blur effects are cleaned before rebuilding.
