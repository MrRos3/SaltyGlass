# Changelog

## SaltyGlass UI Library v1.1.0

Premium/original-style library pass.

### Library
- Added `CreateOriginalWindow` / `CreatePremiumWindow`.
- Added opt-in background blur with `SetBlurEnabled` and `SetBlurSize`.
- Added animated glass and white rotating outer stroke treatment.
- Upgraded tab switching to smooth fade + slide transitions.
- Added one-shot page light sweep.
- Added a Dynamic-Island-style temporary status API with `ShowStatus`.
- Upgraded the minimized badge with a Lucide music icon.
- Added size, position, and glass-transparency APIs.
- Added responsive top context visibility for smaller window widths.

### Reusable music player
- Added `AddMusicPlayer` / `CreateMusicPlayer`.
- Custom Roblox audio ID input only; no bundled song presets.
- Play, pause, stop.
- Repeat off / Repeat / Repeat 1.
- Seek progress with a static thumb.
- Volume slider with a static thumb.
- Playback speed from 0.50x to 2.00x.
- Dedicated heavy music blur and click-through input shield.
- Top-bar Lucide music control and Ctrl+M toggle.
- Full music/sound/blur cleanup on window destroy.

### Examples
- Added root `showcase.lua` for direct execution.
- Replaced the basic library example with an original-style Home / Player / Settings / Visuals showcase.
- Added live FPS / ping / session telemetry.

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
