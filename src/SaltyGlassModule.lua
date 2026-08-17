-- SaltyGlass ModuleScript wrapper
-- Version: 3.6.2 RC
-- Usage (client): local SaltyGlass = require(path.To.SaltyGlass); SaltyGlass.Start()

local SaltyGlass = {
    Version = "3.6.2 RC",
}

function SaltyGlass.Start()
    -- SaltyGlass v3.6.2 RC — GitHub Distribution Build
    -- Client-only. Can run as a StarterGui LocalScript or from a compatible client-side loader.
    -- IMPORTANT: this file contains Lua only. Do not add ```lua or ``` around it.
    --
    -- real Lucide ImageLabels, draggable + resizable window, live telemetry,
    -- custom music player, Reduce Motion, Reset UI, smooth tab transitions, and release-candidate polish.
    -- No gameplay/exploit features are included — cosmetic UI only.
    -- Distribution: https://github.com/MrRos3/SaltyGlass
    -- Stable raw entry: https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/latest.lua

    local CONFIG = {
        ToggleKey = Enum.KeyCode.RightShift,
        ReduceMotion = false,
        Tabs = { "Home", "Player", "Settings", "Visuals" },
        Colors = {
            GlassBase = Color3.fromHex("090D18"),
            GlassMid = Color3.fromHex("11182A"),
            GlassLight = Color3.fromHex("1B2440"),
            Edge = Color3.fromHex("FFFFFF"),
            Accent = Color3.fromHex("8B7CFF"),
            AccentAlt = Color3.fromHex("FF72D7"),
            Cyan = Color3.fromHex("5DE7FF"),
            Text = Color3.fromHex("FFFFFF"),
            SubText = Color3.fromHex("B5BCD3"),
            Muted = Color3.fromHex("6F7895"),
            Success = Color3.fromHex("6DFFA8"),
            Warning = Color3.fromHex("FFD166"),
            Danger = Color3.fromHex("FF6B7A"),
        },
        ClickSoundId = "rbxassetid://4307186075",
        HoverSoundId = "rbxassetid://408524543",
        MinSize = Vector2.new(360, 400),
        MaxSize = Vector2.new(920, 780),
    }

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local TextService = game:GetService("TextService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local RunService = game:GetService("RunService")
    local TeleportService = game:GetService("TeleportService")

    local player = Players.LocalPlayer
    if not player then
        error("SaltyGlass must be executed on the Roblox client.", 0)
    end

    local playerGui = player:WaitForChild("PlayerGui")

    -- Remember Reduce Motion across script rebuilds during the same client session.
    CONFIG.ReduceMotion = player:GetAttribute("SaltyReduceMotion") == true

    -- Cleanup previous copy.
    do
        local oldGui = playerGui:FindFirstChild("SaltyGlassGui")
        if oldGui then
            oldGui:Destroy()
        end

        local oldBlur = Lighting:FindFirstChild("SaltyBackgroundBlur")
        if oldBlur then
            oldBlur:Destroy()
        end

        local oldMusicBlur = Lighting:FindFirstChild("SaltyMusicPlayerBlur")
        if oldMusicBlur then
            oldMusicBlur:Destroy()
        end
    end

    local strokeGradient
    local indicatorGradient
    local badgeStrokeGradient
    local badgeAccentLine
    local badgeMusicIcon
    local badgeIconGlow
    local tabIndicator
    local tabGlow

    local sliderFills = {}
    local toggleTracks = {}
    local tabButtons = {}
    local tabPages = {}
    local tabStrokes = {}
    local tabScales = {}

    local premiumFx = {
        tabIcons = {},
        edgeGlow = {},
        musicPlaying = false,
        statusToken = 0,
        reduceMotion = CONFIG.ReduceMotion,
        blurEnabled = true,
        uiSoundsEnabled = true,
        defaults = {
            accent = Color3.fromHex("8B7CFF"),
            windowSize = UDim2.new(0.38, 0, 0.52, 0),
            windowPosition = UDim2.new(0.5, 0, 0.5, 0),
            toggleKey = Enum.KeyCode.RightShift,
            clickSound = "rbxassetid://4307186075",
            hoverSound = "rbxassetid://408524543",
        },
        controls = {
            blurToggles = {},
            soundToggles = {},
            accentSliders = {},
        },
    }

    local activeTab = nil
    local selectTab
    local restorePanel
    local musicPlayer = {}

    local isOpen = true
    local isMinimized = false
    local isShuttingDown = false
    local openSize
    local openPosition

    local sessionStart = os.clock()

    local function tween(instance, duration, style, direction, properties)
        local info = TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        )
        local result = TweenService:Create(instance, info, properties)
        result:Play()
        return result
    end

    local function scaleUDim2(u, factor)
        return UDim2.new(
            u.X.Scale * factor, u.X.Offset * factor,
            u.Y.Scale * factor, u.Y.Offset * factor
        )
    end

    local function round(instance, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = instance
        return corner
    end

    local function addStroke(instance, thickness, transparency, color)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thickness or 1
        stroke.Transparency = transparency or 0.5
        -- v3.2: all GUI/button borders start white by default.
        stroke.Color = CONFIG.Colors.Edge
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = instance
        return stroke
    end

    local function addScale(instance)
        local scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = instance
        return scale
    end

    local function playSound(id, volume)
        if id == "" then
            return
        end

        pcall(function()
            local sound = Instance.new("Sound")
            sound.Name = "SaltyUISound"
            sound.SoundId = id
            sound.Volume = volume or 0.3
            sound.Parent = SoundService
            sound:Play()
            sound.Ended:Connect(function()
                if sound.Parent then
                    sound:Destroy()
                end
            end)
            task.delay(3, function()
                if sound.Parent then
                    sound:Destroy()
                end
            end)
        end)
    end

    local function playClickSound()
        playSound(CONFIG.ClickSoundId, 0.28)
    end

    local function playHoverSound()
        playSound(CONFIG.HoverSoundId, 0.10)
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "SaltyBackgroundBlur"
    blur.Size = 0
    blur.Parent = Lighting

    local function setBlur(enabled)
        premiumFx.blurEnabled = enabled == true
        local targetSize = enabled and 16 or 0

        if premiumFx.reduceMotion then
            blur.Size = targetSize
            return
        end

        tween(blur, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Size = targetSize,
        })
    end

    -- Dedicated blur used only while the music palette is open.
    -- Lighting blur softens the 3D scene; the palette backdrop below also
    -- heavily dims the ScreenGui underneath so text cannot bleed through.
    local musicBlur = Instance.new("BlurEffect")
    musicBlur.Name = "SaltyMusicPlayerBlur"
    musicBlur.Size = 0
    musicBlur.Parent = Lighting

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SaltyGlassGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    screenGui.Destroying:Connect(function()
        if musicBlur and musicBlur.Parent then
            musicBlur:Destroy()
        end
    end)

    -- Main window.
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Size = premiumFx.defaults.windowSize
    mainFrame.Position = premiumFx.defaults.windowPosition
    mainFrame.BackgroundColor3 = CONFIG.Colors.GlassBase
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.ZIndex = 3
    mainFrame.Parent = screenGui

    openSize = mainFrame.Size
    openPosition = mainFrame.Position

    round(mainFrame, 28)
    local mainScale = addScale(mainFrame)

    local mainStroke = addStroke(mainFrame, 1.5, 0.45, CONFIG.Colors.Edge)

    strokeGradient = Instance.new("UIGradient")
    strokeGradient.Rotation = 20
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.Edge),
        ColorSequenceKeypoint.new(0.5, CONFIG.Colors.Edge),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.Edge),
    })
    strokeGradient.Parent = mainStroke

    local glassGradient = Instance.new("UIGradient")
    glassGradient.Rotation = 55
    glassGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("283454")),
        ColorSequenceKeypoint.new(0.34, CONFIG.Colors.GlassMid),
        ColorSequenceKeypoint.new(0.72, CONFIG.Colors.GlassBase),
        ColorSequenceKeypoint.new(1, Color3.fromHex("070A11")),
    })
    glassGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.4, 0.56),
        NumberSequenceKeypoint.new(1, 0.88),
    })
    glassGradient.Parent = mainFrame

    task.spawn(function()
        while glassGradient.Parent do
            if premiumFx.reduceMotion then
                glassGradient.Rotation = 55
                task.wait(0.25)
            else
                tween(glassGradient, 8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Rotation = 75 })
                task.wait(8)
                if glassGradient.Parent and not premiumFx.reduceMotion then
                    tween(glassGradient, 8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Rotation = 35 })
                    task.wait(8)
                end
            end
        end
    end)

    task.spawn(function()
        while strokeGradient.Parent do
            if premiumFx.reduceMotion then
                strokeGradient.Rotation = 20
                task.wait(0.25)
            else
                local result = tween(strokeGradient, 8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, { Rotation = 380 })
                result.Completed:Wait()
                if strokeGradient.Parent then
                    strokeGradient.Rotation = 20
                end
            end
        end
    end)

    local innerBorder = Instance.new("Frame")
    innerBorder.Name = "InnerBorder"
    innerBorder.Position = UDim2.fromOffset(1, 1)
    innerBorder.Size = UDim2.new(1, -2, 1, -2)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 0
    innerBorder.ZIndex = 4
    innerBorder.Parent = mainFrame
    round(innerBorder, 27)
    local innerStroke = addStroke(innerBorder, 1, 0.84, CONFIG.Colors.Edge)

    local shine = Instance.new("Frame")
    -- Keep the top highlight away from the 28px rounded corners. A full-width
    -- rectangular child can visually cut through UICorner edges in Roblox.
    shine.Size = UDim2.new(1, -64, 0, 1)
    shine.Position = UDim2.new(0, 32, 0, 1)
    shine.BackgroundColor3 = Color3.new(1, 1, 1)
    shine.BackgroundTransparency = 0.94
    shine.BorderSizePixel = 0
    shine.ZIndex = 7
    shine.Parent = mainFrame
    round(shine, 2)

    local shineGradient = Instance.new("UIGradient")
    shineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.Accent),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.AccentAlt),
    })
    shineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.10, 0.45),
        NumberSequenceKeypoint.new(0.5, 0.05),
        NumberSequenceKeypoint.new(0.90, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    shineGradient.Parent = shine

    ----------------------------------------------------------------
    -- NEW: Confetti burst (screen-space, used once on intro)
    ----------------------------------------------------------------
    local function spawnConfetti()
        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local palette = { CONFIG.Colors.Accent, CONFIG.Colors.AccentAlt, CONFIG.Colors.Cyan, CONFIG.Colors.Success, CONFIG.Colors.Warning }

        for i = 1, 26 do
            local piece = Instance.new("Frame")
            local size = math.random(5, 9)
            piece.Size = UDim2.fromOffset(size, size * (math.random(6, 12) / 6))
            piece.Position = UDim2.fromOffset(math.random(0, math.floor(viewport.X)), -20)
            piece.BackgroundColor3 = palette[math.random(1, #palette)]
            piece.BorderSizePixel = 0
            piece.Rotation = math.random(0, 360)
            piece.ZIndex = 200
            piece.Parent = screenGui
            round(piece, 2)

            local fallY = viewport.Y * (0.35 + math.random() * 0.5)
            local drift = math.random(-60, 60)
            local duration = 1.4 + math.random() * 1.1

            tween(piece, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In, {
                Position = piece.Position + UDim2.fromOffset(drift, fallY),
                Rotation = piece.Rotation + math.random(120, 420) * (math.random(0, 1) == 0 and -1 or 1),
                BackgroundTransparency = 1,
            })

            task.delay(duration + 0.05, function()
                if piece.Parent then
                    piece:Destroy()
                end
            end)
        end
    end


    ----------------------------------------------------------------
    -- REAL LUCIDE ICON RENDERER
    --
    -- Actual Roblox ImageLabel assets from the Lucide icon mapping used by
    -- this single-file build. Tooltips remain removed in v3.2.1.
    ----------------------------------------------------------------
    local LUCIDE_IMAGES = {
        ["music"] = "rbxassetid://7734020554",
        ["play"] = "rbxassetid://7743871480",
        ["pause"] = "rbxassetid://7734021897",
        ["square"] = "rbxassetid://7743872181",
        ["repeat"] = "rbxassetid://7734051454",
        ["repeat-2"] = "rbxassetid://7734051454",
        ["volume-2"] = "rbxassetid://7743877250",
        ["x"] = "rbxassetid://7743878857",
        ["minus"] = "rbxassetid://7734000129",
        ["plus"] = "rbxassetid://7734042071",
        ["move-diagonal-2"] = "rbxassetid://7734013178",
        ["chevron-down"] = "rbxassetid://7733717447",
        ["skip-back"] = "rbxassetid://7734058404",
        ["skip-forward"] = "rbxassetid://7734058495",
        ["log-out"] = "rbxassetid://7733992677",
        ["home"] = "rbxassetid://7733960981",
        ["user"] = "rbxassetid://7743875962",
        ["settings"] = "rbxassetid://7734053495",
        ["eye"] = "rbxassetid://7733774602",
    }

    local function renderLucideIcon(icon, iconName, color)
        if not icon or not icon:IsA("ImageLabel") then
            return
        end

        local image = LUCIDE_IMAGES[string.lower(iconName or "")]
        if not image then
            warn("Salty Lucide: unknown icon '" .. tostring(iconName) .. "'")
            icon.Image = ""
            return
        end

        icon:SetAttribute("LucideName", iconName)
        icon.Image = image
        icon.ImageColor3 = color or CONFIG.Colors.Text
        icon.ImageTransparency = 0
    end

    local function createLucideIcon(parent, iconName, size, color, zIndex)
        local icon = Instance.new("ImageLabel")
        icon.Name = "LucideIcon_" .. tostring(iconName)
        icon.Size = UDim2.fromOffset(size, size)
        icon.BackgroundTransparency = 1
        icon.BorderSizePixel = 0
        icon.Image = ""
        icon.ImageColor3 = color or CONFIG.Colors.Text
        icon.ImageTransparency = 0
        icon.ScaleType = Enum.ScaleType.Fit
        icon.ZIndex = zIndex or ((parent and parent.ZIndex or 1) + 1)
        icon.Parent = parent
        icon:SetAttribute("LucideSize", size)
        renderLucideIcon(icon, iconName, color)
        return icon
    end

    -- Top bar.
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 62)
    titleBar.BackgroundTransparency = 1
    titleBar.ZIndex = 10
    titleBar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(200, 30)
    title.Position = UDim2.new(0, 22, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "SALTY"
    title.TextColor3 = CONFIG.Colors.Text
    title.TextSize = 21
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = titleBar

    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new(CONFIG.Colors.Text, CONFIG.Colors.Accent)
    titleGradient.Parent = title

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.fromOffset(230, 18)
    subtitle.Position = UDim2.new(0, 23, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Text = "v1.0.0"
    subtitle.TextColor3 = CONFIG.Colors.Muted
    subtitle.TextSize = 9
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 11
    subtitle.Parent = titleBar

    -- Tiny startup "sharpen" ghosts. They only exist for the first ~0.2s.
    premiumFx.titleGhostA = title:Clone()
    premiumFx.titleGhostA.Name = "SaltySharpenGhostA"
    premiumFx.titleGhostA.Position = UDim2.new(0, 20, 0, 10)
    premiumFx.titleGhostA.TextTransparency = 1
    premiumFx.titleGhostA.ZIndex = 10
    premiumFx.titleGhostA.Parent = titleBar

    premiumFx.titleGhostB = title:Clone()
    premiumFx.titleGhostB.Name = "SaltySharpenGhostB"
    premiumFx.titleGhostB.Position = UDim2.new(0, 24, 0, 10)
    premiumFx.titleGhostB.TextTransparency = 1
    premiumFx.titleGhostB.ZIndex = 10
    premiumFx.titleGhostB.Parent = titleBar

    -- Screen-edge glow used only while the main window is being dragged.
    function premiumFx.setupEdgeGlow()
        if premiumFx.edgeGlow.Left then
            return
        end

        local definitions = {
            Left = {
                position = UDim2.fromOffset(0, 0),
                size = UDim2.new(0, 3, 1, 0),
                rotation = 90,
            },
            Right = {
                position = UDim2.new(1, -3, 0, 0),
                size = UDim2.new(0, 3, 1, 0),
                rotation = 90,
            },
            Top = {
                position = UDim2.fromOffset(0, 0),
                size = UDim2.new(1, 0, 0, 3),
                rotation = 0,
            },
            Bottom = {
                position = UDim2.new(0, 0, 1, -3),
                size = UDim2.new(1, 0, 0, 3),
                rotation = 0,
            },
        }

        for name, data in pairs(definitions) do
            local edge = Instance.new("Frame")
            edge.Name = "DragEdgeGlow_" .. name
            edge.Position = data.position
            edge.Size = data.size
            edge.BackgroundColor3 = CONFIG.Colors.Edge
            edge.BackgroundTransparency = 1
            edge.BorderSizePixel = 0
            edge.Active = false
            edge.ZIndex = 250
            edge.Parent = screenGui

            local gradient = Instance.new("UIGradient")
            gradient.Rotation = data.rotation
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.16, 0.48),
                NumberSequenceKeypoint.new(0.5, 0.10),
                NumberSequenceKeypoint.new(0.84, 0.48),
                NumberSequenceKeypoint.new(1, 1),
            })
            gradient.Parent = edge

            premiumFx.edgeGlow[name] = edge
        end
    end

    function premiumFx.updateEdgeGlow(active)
        premiumFx.setupEdgeGlow()

        if premiumFx.reduceMotion then
            active = false
        end

        if not active then
            for _, edge in pairs(premiumFx.edgeGlow) do
                if edge and edge.Parent then
                    tween(edge, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                        BackgroundTransparency = 1,
                    })
                end
            end
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local pos = mainFrame.AbsolutePosition
        local size = mainFrame.AbsoluteSize
        local threshold = 42

        local distances = {
            Left = pos.X,
            Right = viewport.X - (pos.X + size.X),
            Top = pos.Y,
            Bottom = viewport.Y - (pos.Y + size.Y),
        }

        for name, edge in pairs(premiumFx.edgeGlow) do
            local distance = math.max(distances[name] or threshold, 0)
            local strength = math.clamp(1 - distance / threshold, 0, 1)
            edge.BackgroundTransparency = 1 - (0.58 * strength)
        end
    end

    premiumFx.setupEdgeGlow()

    ----------------------------------------------------------------
    -- NEW: drag handle (left portion of title bar, avoids buttons)
    ----------------------------------------------------------------
    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, -150, 1, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Active = true
    dragHandle.ZIndex = 9
    dragHandle.Parent = titleBar

    do
        local dragging = false
        local dragStart, startPos

        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                premiumFx.updateEdgeGlow(true)

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        premiumFx.updateEdgeGlow(false)
                        if not isMinimized then
                            openPosition = mainFrame.Position
                        end
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
                premiumFx.updateEdgeGlow(true)
            end
        end)
    end

    local function makeCircleButton(text, offset, accent)
        local button = Instance.new("TextButton")
        button.AnchorPoint = Vector2.new(1, 0.5)
        button.Position = UDim2.new(1, offset, 0.5, 0)
        button.Size = UDim2.fromOffset(30, 30)
        button.BackgroundColor3 = CONFIG.Colors.GlassLight
        button.BackgroundTransparency = 0.72
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamBold
        button.Text = text
        button.TextColor3 = CONFIG.Colors.Text
        button.TextSize = 13
        button.ZIndex = 12
        button.Parent = titleBar
        round(button, 15)

        local stroke = addStroke(button, 1, 0.78, accent or CONFIG.Colors.Edge)

        button.MouseEnter:Connect(function()
            playHoverSound()
            tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.52,
            })
            tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.35,
            })
        end)

        button.MouseLeave:Connect(function()
            tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.72,
            })
            tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.78,
            })
        end)

        return button
    end

    local minimizeButton = makeCircleButton("", -64, CONFIG.Colors.Warning)
    local closeButton = makeCircleButton("", -24, CONFIG.Colors.Danger)
    local musicTopButton = makeCircleButton("", -104, CONFIG.Colors.Accent)

    local minimizeIcon = createLucideIcon(minimizeButton, "minus", 15, CONFIG.Colors.Text, 14)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.Position = UDim2.fromScale(0.5, 0.5)

    local closeTopIcon = createLucideIcon(closeButton, "x", 15, CONFIG.Colors.Text, 14)
    closeTopIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeTopIcon.Position = UDim2.fromScale(0.5, 0.5)

    local musicTopIcon = createLucideIcon(musicTopButton, "music", 16, CONFIG.Colors.Text, 14)
    musicTopIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    musicTopIcon.Position = UDim2.fromScale(0.5, 0.5)

    -- Clean playing-state feedback: the music icon alone takes the accent color.
    function premiumFx.setMusicPlaying(playing)
        premiumFx.musicPlaying = playing == true

        if musicTopIcon and musicTopIcon.Parent then
            tween(musicTopIcon, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                ImageColor3 = premiumFx.musicPlaying and CONFIG.Colors.Accent or CONFIG.Colors.Text,
            })
        end
    end

    musicTopButton.MouseButton1Click:Connect(function()
        playClickSound()
        if musicPlayer and musicPlayer.Toggle then
            musicPlayer.Toggle()
        end
    end)

    ----------------------------------------------------------------
    -- Context-aware top bar
    -- Shows the active section on wider layouts and hides automatically
    -- when the window is too narrow to keep the title/control spacing clean.
    ----------------------------------------------------------------
    local TAB_CONTEXT = {
        Home = {
            icon = "home",
            title = "HOME",
            subtitle = "OVERVIEW",
        },
        Player = {
            icon = "user",
            title = "PLAYER",
            subtitle = "LOCAL PROFILE",
        },
        Settings = {
            icon = "settings",
            title = "SETTINGS",
            subtitle = "PREFERENCES",
        },
        Visuals = {
            icon = "eye",
            title = "VISUALS",
            subtitle = "INTERFACE",
        },
    }

    local contextPill = Instance.new("Frame")
    contextPill.Name = "TabContextPill"
    contextPill.AnchorPoint = Vector2.new(1, 0.5)
    contextPill.Position = UDim2.new(1, -144, 0.5, 0)
    contextPill.Size = UDim2.fromOffset(150, 34)
    contextPill.BackgroundColor3 = CONFIG.Colors.GlassBase
    contextPill.BackgroundTransparency = 0.58
    contextPill.BorderSizePixel = 0
    contextPill.Active = false
    contextPill.ZIndex = 12
    contextPill.Parent = titleBar
    round(contextPill, 12)

    local contextStroke = addStroke(contextPill, 1, 0.82, CONFIG.Colors.Edge)

    local contextGlass = Instance.new("UIGradient")
    contextGlass.Rotation = 28
    contextGlass.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.GlassLight),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.GlassBase),
    })
    contextGlass.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 0.68),
    })
    contextGlass.Parent = contextPill

    local contextIconWell = Instance.new("Frame")
    contextIconWell.Position = UDim2.fromOffset(7, 6)
    contextIconWell.Size = UDim2.fromOffset(22, 22)
    contextIconWell.BackgroundColor3 = CONFIG.Colors.GlassLight
    contextIconWell.BackgroundTransparency = 0.50
    contextIconWell.BorderSizePixel = 0
    contextIconWell.ZIndex = 13
    contextIconWell.Parent = contextPill
    round(contextIconWell, 8)
    addStroke(contextIconWell, 1, 0.84, CONFIG.Colors.Edge)

    local contextIcon = createLucideIcon(contextIconWell, "home", 13, CONFIG.Colors.Accent, 15)
    contextIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    contextIcon.Position = UDim2.fromScale(0.5, 0.5)

    local contextTitle = Instance.new("TextLabel")
    contextTitle.BackgroundTransparency = 1
    contextTitle.Position = UDim2.fromOffset(37, 4)
    contextTitle.Size = UDim2.new(1, -44, 0, 14)
    contextTitle.Font = Enum.Font.GothamBold
    contextTitle.Text = "HOME"
    contextTitle.TextColor3 = CONFIG.Colors.Text
    contextTitle.TextSize = 9
    contextTitle.TextXAlignment = Enum.TextXAlignment.Left
    contextTitle.ZIndex = 14
    contextTitle.Parent = contextPill

    local contextSubtitle = Instance.new("TextLabel")
    contextSubtitle.BackgroundTransparency = 1
    contextSubtitle.Position = UDim2.fromOffset(37, 17)
    contextSubtitle.Size = UDim2.new(1, -44, 0, 11)
    contextSubtitle.Font = Enum.Font.GothamMedium
    contextSubtitle.Text = "OVERVIEW"
    contextSubtitle.TextColor3 = CONFIG.Colors.Muted
    contextSubtitle.TextSize = 6
    contextSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    contextSubtitle.ZIndex = 14
    contextSubtitle.Parent = contextPill

    local contextSequence = 0

    local function updateContextResponsive()
        if not contextPill or not contextPill.Parent then
            return
        end

        -- Keeps the chip from ever colliding with SALTY/subtitle or the right controls.
        contextPill.Visible = mainFrame.AbsoluteSize.X >= 560
    end

    local function updateTopContext(tabName, instant)
        local data = TAB_CONTEXT[tabName]
        if not data then
            return
        end

        contextSequence += 1
        local sequence = contextSequence

        local function applyContext()
            if sequence ~= contextSequence or not contextPill.Parent then
                return
            end

            renderLucideIcon(contextIcon, data.icon, CONFIG.Colors.Accent)
            contextTitle.Text = data.title
            contextSubtitle.Text = data.subtitle

            contextIcon.Position = UDim2.new(0.5, 3, 0.5, 0)
            contextTitle.Position = UDim2.fromOffset(40, 4)
            contextSubtitle.Position = UDim2.fromOffset(40, 17)

            tween(contextIcon, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                ImageTransparency = 0,
                Position = UDim2.fromScale(0.5, 0.5),
            })
            tween(contextTitle, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                TextTransparency = 0,
                Position = UDim2.fromOffset(37, 4),
            })
            tween(contextSubtitle, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                TextTransparency = 0,
                Position = UDim2.fromOffset(37, 17),
            })
            tween(contextStroke, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.72,
            })

            task.delay(0.14, function()
                if sequence == contextSequence and contextStroke.Parent then
                    tween(contextStroke, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                        Transparency = 0.82,
                    })
                end
            end)
        end

        if instant or premiumFx.reduceMotion then
            renderLucideIcon(contextIcon, data.icon, CONFIG.Colors.Accent)
            contextTitle.Text = data.title
            contextSubtitle.Text = data.subtitle
            contextIcon.ImageTransparency = 0
            contextTitle.TextTransparency = 0
            contextSubtitle.TextTransparency = 0
            contextIcon.Position = UDim2.fromScale(0.5, 0.5)
            contextTitle.Position = UDim2.fromOffset(37, 4)
            contextSubtitle.Position = UDim2.fromOffset(37, 17)
            contextStroke.Transparency = 0.82
            return
        end

        tween(contextIcon, 0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            ImageTransparency = 1,
        })
        tween(contextTitle, 0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 1,
        })
        tween(contextSubtitle, 0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 1,
        })

        task.delay(0.055, applyContext)
    end

    -- The existing context chip temporarily expands into a tiny Dynamic-Island
    -- style status surface, then returns to the active tab context.
    function premiumFx.showStatus(iconName, titleText, subtitleText, duration, accentColor)
        premiumFx.statusToken += 1
        local token = premiumFx.statusToken
        local color = accentColor or CONFIG.Colors.Accent

        contextSequence += 1

        if mainFrame.AbsoluteSize.X < 560 then
            return
        end

        contextPill.Visible = true

        if premiumFx.reduceMotion then
            contextPill.Size = UDim2.fromOffset(204, 34)
            contextPill.BackgroundTransparency = 0.48
            contextStroke.Transparency = 0.58

            renderLucideIcon(contextIcon, iconName or "home", color)
            contextTitle.Text = string.upper(tostring(titleText or "SALTY"))
            contextSubtitle.Text = string.upper(tostring(subtitleText or ""))
            contextIcon.ImageTransparency = 0
            contextTitle.TextTransparency = 0
            contextSubtitle.TextTransparency = 0
            contextIcon.Position = UDim2.fromScale(0.5, 0.5)
            contextTitle.Position = UDim2.fromOffset(37, 4)
            contextSubtitle.Position = UDim2.fromOffset(37, 17)

            task.delay(duration or 1.25, function()
                if token ~= premiumFx.statusToken or not contextPill.Parent then
                    return
                end

                contextPill.Size = UDim2.fromOffset(150, 34)
                contextPill.BackgroundTransparency = 0.58
                contextStroke.Transparency = 0.82
                updateTopContext(activeTab or "Home", true)
            end)
            return
        end

        tween(contextPill, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Size = UDim2.fromOffset(204, 34),
            BackgroundTransparency = 0.48,
        })
        tween(contextStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Transparency = 0.58,
        })

        renderLucideIcon(contextIcon, iconName or "home", color)
        contextTitle.Text = string.upper(tostring(titleText or "SALTY"))
        contextSubtitle.Text = string.upper(tostring(subtitleText or ""))

        contextIcon.ImageTransparency = 1
        contextTitle.TextTransparency = 1
        contextSubtitle.TextTransparency = 1
        contextIcon.Position = UDim2.new(0.5, 3, 0.5, 0)
        contextTitle.Position = UDim2.fromOffset(40, 4)
        contextSubtitle.Position = UDim2.fromOffset(40, 17)

        tween(contextIcon, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            ImageTransparency = 0,
            Position = UDim2.fromScale(0.5, 0.5),
        })
        tween(contextTitle, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 0,
            Position = UDim2.fromOffset(37, 4),
        })
        tween(contextSubtitle, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 0,
            Position = UDim2.fromOffset(37, 17),
        })

        task.delay(duration or 1.25, function()
            if token ~= premiumFx.statusToken or not contextPill.Parent then
                return
            end

            tween(contextPill, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Size = UDim2.fromOffset(150, 34),
                BackgroundTransparency = 0.58,
            })
            tween(contextStroke, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.82,
            })

            task.delay(0.05, function()
                if token == premiumFx.statusToken then
                    updateTopContext(activeTab or "Home", false)
                end
            end)
        end)
    end

    -- One-shot light sweep used only when a new tab arrives.
    function premiumFx.pageSweep(page)
        if premiumFx.reduceMotion or not page or not page.Parent then
            return
        end

        local sweep = Instance.new("Frame")
        sweep.Name = "TabGlassSweep"
        sweep.Position = UDim2.new(0, -54, 0, 0)
        sweep.Size = UDim2.new(0, 46, 1, 0)
        sweep.BackgroundColor3 = CONFIG.Colors.Edge
        sweep.BackgroundTransparency = 0.82
        sweep.BorderSizePixel = 0
        sweep.Active = false
        sweep.ZIndex = 30
        sweep.Parent = page

        local gradient = Instance.new("UIGradient")
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.52),
            NumberSequenceKeypoint.new(1, 1),
        })
        gradient.Parent = sweep

        tween(sweep, 0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Position = UDim2.new(1, 10, 0, 0),
            BackgroundTransparency = 0.92,
        })

        task.delay(0.32, function()
            if sweep.Parent then
                sweep:Destroy()
            end
        end)
    end

    mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateContextResponsive)
    task.defer(updateContextResponsive)

    -- Side rail.
    local tabRail = Instance.new("Frame")
    tabRail.Name = "TabRail"
    tabRail.Size = UDim2.new(0.25, 0, 0.72, 0)
    tabRail.Position = UDim2.new(0, 0, 0, 76)
    tabRail.BackgroundTransparency = 1
    tabRail.ZIndex = 10
    tabRail.Parent = mainFrame

    local railPadding = Instance.new("UIPadding")
    railPadding.PaddingTop = UDim.new(0, 6)
    railPadding.PaddingLeft = UDim.new(0, 13)
    railPadding.PaddingRight = UDim.new(0, 12)
    railPadding.Parent = tabRail

    local railLayout = Instance.new("UIListLayout")
    railLayout.SortOrder = Enum.SortOrder.LayoutOrder
    railLayout.Padding = UDim.new(0, 8)
    railLayout.Parent = tabRail

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 1, 0.72, 0)
    divider.Position = UDim2.new(0.25, 0, 0, 76)
    divider.BackgroundColor3 = CONFIG.Colors.Edge
    divider.BackgroundTransparency = 0.88
    divider.BorderSizePixel = 0
    divider.ZIndex = 9
    divider.Parent = mainFrame

    tabIndicator = Instance.new("Frame")
    tabIndicator.Size = UDim2.fromOffset(2, 22)
    tabIndicator.Position = UDim2.new(0, 9, 0, 92)
    tabIndicator.BackgroundColor3 = CONFIG.Colors.Accent
    tabIndicator.BorderSizePixel = 0
    tabIndicator.ZIndex = 15
    tabIndicator.Parent = mainFrame
    round(tabIndicator, 3)

    indicatorGradient = Instance.new("UIGradient")
    indicatorGradient.Rotation = 90
    indicatorGradient.Color = ColorSequence.new(CONFIG.Colors.Accent, CONFIG.Colors.AccentAlt)
    indicatorGradient.Parent = tabIndicator

    tabGlow = Instance.new("Frame")
    tabGlow.Size = UDim2.fromOffset(8, 30)
    tabGlow.Position = UDim2.new(0, 6, 0, 88)
    tabGlow.BackgroundColor3 = CONFIG.Colors.Accent
    tabGlow.BackgroundTransparency = 0.94
    tabGlow.BorderSizePixel = 0
    tabGlow.ZIndex = 8
    tabGlow.Parent = mainFrame
    round(tabGlow, 10)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(0.75, -12, 0.78, 0)
    contentArea.Position = UDim2.new(0.25, 12, 0, 76)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.ZIndex = 7
    contentArea.Parent = mainFrame

    -- Player card.
    local playerCard = Instance.new("Frame")
    playerCard.Size = UDim2.new(0.25, -12, 0, 52)
    playerCard.Position = UDim2.new(0, 12, 1, -66)
    playerCard.BackgroundColor3 = CONFIG.Colors.GlassBase
    playerCard.BackgroundTransparency = 0.58
    playerCard.BorderSizePixel = 0
    playerCard.ZIndex = 20
    playerCard.Parent = mainFrame
    round(playerCard, 16)
    addStroke(playerCard, 1, 0.84, CONFIG.Colors.Edge)

    local playerCardGradient = Instance.new("UIGradient")
    playerCardGradient.Rotation = 35
    playerCardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.GlassMid),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.GlassBase),
    })
    playerCardGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 0.82),
    })
    playerCardGradient.Parent = playerCard

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(38, 38)
    avatar.Position = UDim2.new(0, 7, 0.5, -19)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 22
    avatar.Parent = playerCard
    round(avatar, 20)

    pcall(function()
        avatar.Image = Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48
        )
    end)

    local cardName = Instance.new("TextLabel")
    cardName.BackgroundTransparency = 1
    cardName.Position = UDim2.new(0, 52, 0, 7)
    cardName.Size = UDim2.new(1, -96, 0, 17)
    cardName.Font = Enum.Font.GothamBold
    cardName.Text = player.DisplayName
    cardName.TextColor3 = CONFIG.Colors.Text
    cardName.TextSize = 11
    cardName.TextXAlignment = Enum.TextXAlignment.Left
    cardName.ZIndex = 22
    cardName.Parent = playerCard

    local cardUser = Instance.new("TextLabel")
    cardUser.BackgroundTransparency = 1
    cardUser.Position = UDim2.new(0, 52, 0, 25)
    cardUser.Size = UDim2.new(1, -96, 0, 14)
    cardUser.Font = Enum.Font.GothamMedium
    cardUser.Text = "@" .. player.Name
    cardUser.TextColor3 = CONFIG.Colors.Muted
    cardUser.TextSize = 9
    cardUser.TextXAlignment = Enum.TextXAlignment.Left
    cardUser.ZIndex = 22
    cardUser.Parent = playerCard

    -- ALT + F4 style exit control.
    -- Roblox LocalScripts cannot close the desktop Roblox process itself,
    -- so this performs Salty cleanup and exits the current experience.
    local altF4Button = Instance.new("TextButton")
    altF4Button.Name = "AltF4Button"
    altF4Button.AnchorPoint = Vector2.new(1, 0.5)
    altF4Button.Position = UDim2.new(1, -7, 0.5, 0)
    altF4Button.Size = UDim2.fromOffset(38, 38)
    altF4Button.BackgroundColor3 = CONFIG.Colors.GlassLight
    altF4Button.BackgroundTransparency = 0.68
    altF4Button.BorderSizePixel = 0
    altF4Button.AutoButtonColor = false
    altF4Button.Text = ""
    altF4Button.ZIndex = 24
    altF4Button.Parent = playerCard
    round(altF4Button, 12)

    local altF4Stroke = addStroke(altF4Button, 1, 0.72, CONFIG.Colors.Edge)
    local altF4Scale = addScale(altF4Button)

    local altF4Icon = createLucideIcon(
        altF4Button,
        "log-out",
        18,
        CONFIG.Colors.Text,
        25
    )
    altF4Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    altF4Icon.Position = UDim2.fromScale(0.5, 0.46)

    local altF4Accent = Instance.new("Frame")
    altF4Accent.AnchorPoint = Vector2.new(0.5, 1)
    altF4Accent.Position = UDim2.new(0.5, 0, 1, -5)
    altF4Accent.Size = UDim2.new(1, -14, 0, 2)
    altF4Accent.BackgroundColor3 = CONFIG.Colors.Danger
    altF4Accent.BackgroundTransparency = 0.42
    altF4Accent.BorderSizePixel = 0
    altF4Accent.ZIndex = 25
    altF4Accent.Parent = altF4Button
    round(altF4Accent, 2)

    altF4Button.MouseEnter:Connect(function()
        tween(altF4Button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.48,
        })
        tween(altF4Stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Transparency = 0.42,
        })
        tween(altF4Accent, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.08,
            Size = UDim2.new(1, -10, 0, 2),
        })
        tween(altF4Icon, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            ImageColor3 = CONFIG.Colors.Danger,
        })
        tween(altF4Scale, 0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Scale = 1.04,
        })
    end)

    altF4Button.MouseLeave:Connect(function()
        tween(altF4Button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.68,
        })
        tween(altF4Stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Transparency = 0.72,
        })
        tween(altF4Accent, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.42,
            Size = UDim2.new(1, -14, 0, 2),
        })
        tween(altF4Icon, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            ImageColor3 = CONFIG.Colors.Text,
        })
        tween(altF4Scale, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Scale = 1,
        })
    end)

    ----------------------------------------------------------------
    -- Clean resize grip (bottom-right corner)
    --
    -- Large invisible grab area, single Lucide icon, no box/chrome/readout.
    ----------------------------------------------------------------
    premiumFx.resize = {}

    premiumFx.resize.handle = Instance.new("TextButton")
    premiumFx.resize.handle.Name = "ResizeHandle"
    premiumFx.resize.handle.AnchorPoint = Vector2.new(1, 1)
    premiumFx.resize.handle.Position = UDim2.new(1, 0, 1, 0)
    premiumFx.resize.handle.Size = UDim2.fromOffset(42, 42)
    premiumFx.resize.handle.BackgroundTransparency = 1
    premiumFx.resize.handle.AutoButtonColor = false
    premiumFx.resize.handle.Text = ""
    premiumFx.resize.handle.ZIndex = 60
    premiumFx.resize.handle.Parent = mainFrame

    premiumFx.resize.icon = createLucideIcon(
        premiumFx.resize.handle,
        "move-diagonal-2",
        14,
        CONFIG.Colors.Muted,
        61
    )
    premiumFx.resize.icon.AnchorPoint = Vector2.new(1, 1)
    premiumFx.resize.icon.Position = UDim2.new(1, -9, 1, -9)
    premiumFx.resize.icon.ImageTransparency = 0.30

    premiumFx.resize.hovering = false
    premiumFx.resize.resizing = false
    premiumFx.resize.start = nil
    premiumFx.resize.startSize = nil

    local function setResizeVisual(active)
        local targetColor = active and CONFIG.Colors.Accent or CONFIG.Colors.Muted
        local targetTransparency = active and 0 or 0.30

        if premiumFx.reduceMotion then
            premiumFx.resize.icon.ImageColor3 = targetColor
            premiumFx.resize.icon.ImageTransparency = targetTransparency
            return
        end

        tween(premiumFx.resize.icon, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            ImageColor3 = targetColor,
            ImageTransparency = targetTransparency,
        })
    end

    premiumFx.resize.handle.MouseEnter:Connect(function()
        premiumFx.resize.hovering = true
        setResizeVisual(true)
    end)

    premiumFx.resize.handle.MouseLeave:Connect(function()
        premiumFx.resize.hovering = false
        if not premiumFx.resize.resizing then
            setResizeVisual(false)
        end
    end)

    premiumFx.resize.handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            premiumFx.resize.resizing = true
            premiumFx.resize.start = input.Position
            premiumFx.resize.startSize = mainFrame.AbsoluteSize
            setResizeVisual(true)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    premiumFx.resize.resizing = false

                    if not isMinimized then
                        openSize = mainFrame.Size
                    end

                    setResizeVisual(premiumFx.resize.hovering)
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if premiumFx.resize.resizing
            and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then

            local delta = input.Position - premiumFx.resize.start
            local newX = math.clamp(
                premiumFx.resize.startSize.X + delta.X,
                CONFIG.MinSize.X,
                CONFIG.MaxSize.X
            )
            local newY = math.clamp(
                premiumFx.resize.startSize.Y + delta.Y,
                CONFIG.MinSize.Y,
                CONFIG.MaxSize.Y
            )

            mainFrame.Size = UDim2.fromOffset(newX, newY)
        end
    end)


    -- Notifications.
    local notifContainer = Instance.new("Frame")
    notifContainer.Name = "NotifContainer"
    notifContainer.Size = UDim2.fromOffset(290, 420)
    notifContainer.Position = UDim2.new(1, -310, 0, 28)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex = 100
    notifContainer.Parent = screenGui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Padding = UDim.new(0, 10)
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.Parent = notifContainer

    local function showNotification(text, duration, kind)
        duration = duration or 3
        kind = kind or "default"

        local accent = CONFIG.Colors.Accent
        if kind == "success" then
            accent = CONFIG.Colors.Success
        elseif kind == "warning" then
            accent = CONFIG.Colors.Warning
        elseif kind == "danger" then
            accent = CONFIG.Colors.Danger
        end

        local n = Instance.new("Frame")
        n.Size = UDim2.fromOffset(0, 56)
        n.BackgroundColor3 = CONFIG.Colors.GlassBase
        n.BackgroundTransparency = 0.08
        n.BorderSizePixel = 0
        n.ClipsDescendants = true
        n.ZIndex = 101
        n.Parent = notifContainer
        round(n, 15)
        local stroke = addStroke(n, 1, 0.45, accent)

        local glow = Instance.new("Frame")
        glow.Size = UDim2.fromOffset(3, 34)
        glow.Position = UDim2.new(0, 8, 0.5, -17)
        glow.BackgroundColor3 = accent
        glow.BorderSizePixel = 0
        glow.ZIndex = 102
        glow.Parent = n
        round(glow, 4)

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 20, 0, 0)
        label.Size = UDim2.new(1, -32, 1, -8)
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.TextColor3 = CONFIG.Colors.Text
        label.TextSize = 12
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 103
        label.Parent = n

        -- Depletion progress underline inset to match rounded glass card.
        local progressTrack = Instance.new("Frame")
        progressTrack.AnchorPoint = Vector2.new(0, 1)
        progressTrack.Position = UDim2.new(0, 12, 1, -6)
        progressTrack.Size = UDim2.new(1, -24, 0, 2)
        progressTrack.BackgroundColor3 = accent
        progressTrack.BackgroundTransparency = 0.78
        progressTrack.BorderSizePixel = 0
        progressTrack.ZIndex = 103
        progressTrack.Parent = n
        round(progressTrack, 2)

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BackgroundColor3 = accent
        progressFill.BorderSizePixel = 0
        progressFill.ZIndex = 104
        progressFill.Parent = progressTrack
        round(progressFill, 2)

        tween(n, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Size = UDim2.fromOffset(290, 56),
        })
        tween(progressFill, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
            Size = UDim2.new(0, 0, 1, 0),
        })

        task.delay(duration, function()
            if not n.Parent then
                return
            end
            tween(n, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                Size = UDim2.fromOffset(0, 56),
                BackgroundTransparency = 1,
            })
            tween(stroke, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Transparency = 1 })
            task.delay(0.32, function()
                if n.Parent then
                    n:Destroy()
                end
            end)
        end)
    end

    -- Component builders.
    local function createSectionHeader(parent, text)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 24)
        container.BackgroundTransparency = 1
        container.ZIndex = 8
        container.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.TextColor3 = CONFIG.Colors.SubText
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 8
        label.Parent = container

        local line = Instance.new("Frame")
        local textWidth = TextService:GetTextSize(
            text,
            label.TextSize,
            label.Font,
            Vector2.new(1000, container.AbsoluteSize.Y > 0 and container.AbsoluteSize.Y or 24)
        ).X
        line.Size = UDim2.fromOffset(math.ceil(textWidth), 2)
        line.Position = UDim2.new(0, 0, 1, -2)
        line.BackgroundColor3 = CONFIG.Colors.Accent
        line.BackgroundTransparency = 0.25
        line.BorderSizePixel = 0
        line.ZIndex = 9
        line.Parent = container
        round(line, 2)

        return container
    end

    local function createLabel(parent, text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 19)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.Text = text
        label.TextColor3 = CONFIG.Colors.Text
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 8
        label.Parent = parent
        return label
    end

    local function createButton(parent, text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -2, 0, 38)
        button.BackgroundColor3 = CONFIG.Colors.GlassLight
        button.BackgroundTransparency = 0.65
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamBold
        button.Text = text
        button.TextColor3 = CONFIG.Colors.Text
        button.TextSize = 12
        button.ZIndex = 8
        button.Parent = parent
        round(button, 11)

        local stroke = addStroke(button, 1, 0.68, CONFIG.Colors.Edge)

        button.MouseEnter:Connect(function()
            playHoverSound()
            tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.52,
            })
            tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.58,
            })
        end)

        button.MouseLeave:Connect(function()
            tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.65,
            })
            tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.68,
            })
        end)

        button.MouseButton1Up:Connect(function()
            playClickSound()
            if callback then
                callback()
            end
        end)

        return button
    end

    local function createToggle(parent, text, defaultState, callback)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 36)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 8
        holder.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -54, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.TextColor3 = CONFIG.Colors.Text
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 8
        label.Parent = holder

        local track = Instance.new("Frame")
        track.Size = UDim2.fromOffset(42, 22)
        track.Position = UDim2.new(1, -42, 0.5, -11)
        track.BackgroundColor3 = defaultState and CONFIG.Colors.Accent or Color3.fromHex("2B334A")
        track.BorderSizePixel = 0
        track.ZIndex = 9
        track.Parent = holder
        round(track, 12)

        local trackStroke = addStroke(track, 1, 0.72, CONFIG.Colors.Edge)

        -- Thin separator under each toggle row.
        local separator = Instance.new("Frame")
        separator.AnchorPoint = Vector2.new(0, 1)
        separator.Position = UDim2.new(0, 0, 1, -1)
        separator.Size = UDim2.new(1, 0, 0, 1)
        separator.BackgroundColor3 = CONFIG.Colors.Edge
        separator.BackgroundTransparency = 0.90
        separator.BorderSizePixel = 0
        separator.ZIndex = 8
        separator.Parent = holder

        local separatorGradient = Instance.new("UIGradient")
        separatorGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.92),
            NumberSequenceKeypoint.new(0.08, 0.35),
            NumberSequenceKeypoint.new(0.92, 0.35),
            NumberSequenceKeypoint.new(1, 0.92),
        })
        separatorGradient.Parent = separator

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(16, 16)
        thumb.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 10
        thumb.Parent = track
        round(thumb, 8)

        local enabled = defaultState
        local data = { enabled = enabled, track = track }
        table.insert(toggleTracks, data)

        local function setState(state, silent)
            local reduceBefore = premiumFx.reduceMotion

            enabled = state
            data.enabled = state

            if callback and not silent then
                callback(state)
            end

            local targetColor = state and CONFIG.Colors.Accent or Color3.fromHex("2B334A")
            local targetPosition = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            local targetTransparency = state and 0.35 or 0.72

            if reduceBefore or premiumFx.reduceMotion then
                track.BackgroundColor3 = targetColor
                thumb.Position = targetPosition
                trackStroke.Transparency = targetTransparency
            else
                tween(track, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                    BackgroundColor3 = targetColor,
                })
                tween(thumb, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                    Position = targetPosition,
                })
                tween(trackStroke, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = targetTransparency,
                })
            end
        end

        holder.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                playClickSound()
                setState(not enabled)
            end
        end)

        return {
            set = function(state, silent)
                setState(state, silent)
            end,
            get = function() return enabled end,
        }
    end

    function premiumFx.syncToggleGroup(group, state, source)
        for _, control in ipairs(group) do
            if control ~= source then
                control.set(state, true)
            end
        end
    end

    function premiumFx.setUiSounds(enabled)
        premiumFx.uiSoundsEnabled = enabled == true

        if enabled then
            CONFIG.ClickSoundId = premiumFx.defaults.clickSound
            CONFIG.HoverSoundId = premiumFx.defaults.hoverSound
        else
            CONFIG.ClickSoundId = ""
            CONFIG.HoverSoundId = ""
        end
    end

    function premiumFx.setReduceMotion(enabled)
        premiumFx.reduceMotion = enabled == true
        CONFIG.ReduceMotion = premiumFx.reduceMotion

        pcall(function()
            player:SetAttribute("SaltyReduceMotion", premiumFx.reduceMotion)
        end)

        if premiumFx.reduceMotion then
            premiumFx.updateEdgeGlow(false)
            innerBorder.Position = UDim2.fromOffset(1, 1)
            glassGradient.Rotation = 55
            strokeGradient.Rotation = 20
        end
    end

    local function createSlider(parent, labelText, min, max, default, callback)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 48)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 8
        holder.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 0, 18)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = labelText
        label.TextColor3 = CONFIG.Colors.Text
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 8
        label.Parent = holder

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 18)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Enum.Font.GothamMedium
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = CONFIG.Colors.SubText
        valueLabel.TextSize = 11
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.ZIndex = 8
        valueLabel.Parent = holder

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 6)
        track.Position = UDim2.new(0, 0, 0, 27)
        track.BackgroundColor3 = Color3.fromHex("242D43")
        track.BorderSizePixel = 0
        track.ZIndex = 8
        track.Parent = holder
        round(track, 5)

        local ratio = math.clamp((default - min) / (max - min), 0, 1)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        fill.BackgroundColor3 = CONFIG.Colors.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 9
        fill.Parent = track
        round(fill, 5)
        table.insert(sliderFills, fill)

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(15, 15)
        thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.BorderSizePixel = 0
        thumb.ZIndex = 10
        thumb.Parent = track
        round(thumb, 8)

        local thumbStroke = addStroke(thumb, 2, 0.65, CONFIG.Colors.Accent)

        local bubble = Instance.new("Frame")
        bubble.AnchorPoint = Vector2.new(0.5, 1)
        bubble.Position = UDim2.new(ratio, 0, 0, 25)
        bubble.Size = UDim2.fromOffset(42, 17)
        bubble.BackgroundColor3 = CONFIG.Colors.GlassBase
        bubble.BackgroundTransparency = 1
        bubble.BorderSizePixel = 0
        bubble.Visible = false
        bubble.ZIndex = 14
        bubble.Parent = holder
        round(bubble, 8)

        local bubbleStroke = addStroke(bubble, 1, 1, CONFIG.Colors.Edge)

        local bubbleText = Instance.new("TextLabel")
        bubbleText.Size = UDim2.fromScale(1, 1)
        bubbleText.BackgroundTransparency = 1
        bubbleText.Font = Enum.Font.GothamBold
        bubbleText.Text = tostring(default)
        bubbleText.TextColor3 = CONFIG.Colors.Text
        bubbleText.TextTransparency = 1
        bubbleText.TextSize = 8
        bubbleText.ZIndex = 15
        bubbleText.Parent = bubble

        local dragging = false

        local function formatValue(value)
            local rounded = math.floor(value + 0.5)
            if math.abs(value - rounded) < 0.001 then
                return tostring(rounded)
            end
            return string.format("%.1f", value)
        end

        local function showBubble(value, newRatio)
            bubble.Position = UDim2.new(newRatio, 0, 0, 25)
            bubbleText.Text = formatValue(value)

            if premiumFx.reduceMotion then
                bubble.Visible = true
                bubble.BackgroundTransparency = 0.16
                bubbleText.TextTransparency = 0
                bubbleStroke.Transparency = 0.52
                return
            end

            if not bubble.Visible then
                bubble.Visible = true
                bubble.BackgroundTransparency = 1
                bubbleText.TextTransparency = 1
                bubbleStroke.Transparency = 1
            end

            tween(bubble, 0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.16,
            })
            tween(bubbleText, 0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                TextTransparency = 0,
            })
            tween(bubbleStroke, 0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.52,
            })
        end

        local function hideBubble()
            if premiumFx.reduceMotion then
                bubble.Visible = false
                bubble.BackgroundTransparency = 1
                bubbleText.TextTransparency = 1
                bubbleStroke.Transparency = 1
                return
            end

            tween(bubble, 0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 1,
            })
            tween(bubbleText, 0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                TextTransparency = 1,
            })
            tween(bubbleStroke, 0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 1,
            })

            task.delay(0.12, function()
                if not dragging and bubble.Parent then
                    bubble.Visible = false
                end
            end)
        end

        local function updateFromInput(input)
            local trackX = track.AbsolutePosition.X
            local trackWidth = track.AbsoluteSize.X
            if trackWidth <= 0 then
                return
            end

            local newRatio = math.clamp((input.Position.X - trackX) / trackWidth, 0, 1)
            local value = min + (max - min) * newRatio
            value = math.floor(value * 10 + 0.5) / 10

            fill.Size = UDim2.new(newRatio, 0, 1, 0)
            thumb.Position = UDim2.new(newRatio, -7, 0.5, -7)
            valueLabel.Text = formatValue(value)

            if dragging then
                showBubble(value, newRatio)
            end

            if callback then
                callback(value)
            end
        end

        local function beginDrag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                playClickSound()
                updateFromInput(input)
            end
        end

        track.InputBegan:Connect(beginDrag)
        thumb.InputBegan:Connect(beginDrag)

        thumb.MouseEnter:Connect(function()
            tween(thumbStroke, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.1 })
        end)

        thumb.MouseLeave:Connect(function()
            if not dragging then
                tween(thumbStroke, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.65 })
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                tween(thumbStroke, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.65 })
                hideBubble()
            end
        end)

        return {
            set = function(value)
                local newRatio = math.clamp((value - min) / (max - min), 0, 1)
                fill.Size = UDim2.new(newRatio, 0, 1, 0)
                thumb.Position = UDim2.new(newRatio, -7, 0.5, -7)
                valueLabel.Text = formatValue(value)
                bubble.Position = UDim2.new(newRatio, 0, 0, 25)
                bubbleText.Text = formatValue(value)
            end,
        }
    end

    local function updateAccentColor(color)
        CONFIG.Colors.Accent = color

        if strokeGradient then
            strokeGradient.Color = ColorSequence.new(CONFIG.Colors.Edge, CONFIG.Colors.Edge)
        end

        if indicatorGradient then
            indicatorGradient.Color = ColorSequence.new(color, CONFIG.Colors.AccentAlt)
        end

        if badgeStrokeGradient then
            badgeStrokeGradient.Color = ColorSequence.new(CONFIG.Colors.Edge, CONFIG.Colors.Edge)
        end

        if badgeAccentLine and badgeAccentLine.Parent then
            badgeAccentLine.BackgroundColor3 = color
        end

        if badgeMusicIcon and badgeMusicIcon.Parent then
            badgeMusicIcon.ImageColor3 = color
        end

        if badgeIconGlow and badgeIconGlow.Parent then
            badgeIconGlow.BackgroundColor3 = color
        end

        if tabIndicator then
            tabIndicator.BackgroundColor3 = color
        end

        if tabGlow then
            tabGlow.BackgroundColor3 = color
        end

        if contextIcon and contextIcon.Parent then
            contextIcon.ImageColor3 = color
        end

        for name, icon in pairs(premiumFx.tabIcons) do
            if icon and icon.Parent then
                icon.ImageColor3 = name == activeTab and color or CONFIG.Colors.SubText
            end
        end


        if premiumFx.musicPlaying and musicTopIcon and musicTopIcon.Parent then
            musicTopIcon.ImageColor3 = color
        end

        if premiumFx.resize
            and premiumFx.resize.icon
            and premiumFx.resize.icon.Parent
            and (premiumFx.resize.hovering or premiumFx.resize.resizing) then
            premiumFx.resize.icon.ImageColor3 = color
        end

        if activeTab and tabStrokes[activeTab] then
            tabStrokes[activeTab].Color = CONFIG.Colors.Edge
        end

        for _, fill in ipairs(sliderFills) do
            if fill and fill.Parent then
                fill.BackgroundColor3 = color
            end
        end

        for _, data in ipairs(toggleTracks) do
            if data.enabled and data.track and data.track.Parent then
                data.track.BackgroundColor3 = color
            end
        end
    end

    local function createTab(name, order)
        local button = Instance.new("TextButton")
        button.Name = name .. "Tab"
        button.Size = UDim2.new(1, 0, 0, 42)
        button.BackgroundColor3 = CONFIG.Colors.GlassLight
        button.BackgroundTransparency = 0.91
        button.AutoButtonColor = false
        button.Text = ""
        button.LayoutOrder = order
        button.ZIndex = 12
        button.Parent = tabRail
        round(button, 13)

        local stroke = addStroke(button, 1, 0.84, CONFIG.Colors.Edge)
        tabStrokes[name] = stroke

        local buttonScale = addScale(button)
        tabScales[name] = buttonScale

        local softGlass = Instance.new("UIGradient")
        softGlass.Rotation = 35
        softGlass.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.Colors.GlassLight),
            ColorSequenceKeypoint.new(1, CONFIG.Colors.GlassBase),
        })
        softGlass.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 0.72),
        })
        softGlass.Parent = button

        local tabIconName = (TAB_CONTEXT[name] and TAB_CONTEXT[name].icon) or "home"
        local tabIcon = createLucideIcon(button, tabIconName, 12, CONFIG.Colors.SubText, 14)
        tabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        tabIcon.Position = UDim2.new(0, 17, 0.5, 0)
        tabIcon.ImageTransparency = 0.18
        premiumFx.tabIcons[name] = tabIcon

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 34, 0, 0)
        label.Size = UDim2.new(1, -42, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.Text = name
        label.TextColor3 = CONFIG.Colors.Text
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 14
        label.Parent = button

        button.MouseEnter:Connect(function()
            playHoverSound()
            if activeTab ~= name then
                tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 0.80,
                })
                tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = 0.68,
                })
                tween(buttonScale, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Scale = 1.018,
                })
            end
        end)

        button.MouseLeave:Connect(function()
            if activeTab ~= name then
                tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 0.91,
                })
                tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = 0.84,
                })
                tween(buttonScale, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Scale = 1,
                })
            end
        end)

        button.MouseButton1Click:Connect(function()
            playClickSound()
            if selectTab then
                selectTab(name)
            end
        end)

        tabButtons[name] = button

        local page = Instance.new("CanvasGroup")
        page.Name = name .. "Page"
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.GroupTransparency = 0
        page.ClipsDescendants = true
        page.Visible = false
        page.ZIndex = 7
        page.Parent = contentArea

        local pageTitle = Instance.new("TextLabel")
        pageTitle.Size = UDim2.new(1, 0, 0, 30)
        pageTitle.BackgroundTransparency = 1
        pageTitle.Font = Enum.Font.GothamBlack
        pageTitle.Text = string.upper(name)
        pageTitle.TextColor3 = CONFIG.Colors.Text
        pageTitle.TextSize = 18
        pageTitle.TextXAlignment = Enum.TextXAlignment.Left
        pageTitle.ZIndex = 8
        pageTitle.Parent = page

        local pageLine = Instance.new("Frame")
        pageLine.Size = UDim2.new(1, 0, 0, 1)
        pageLine.Position = UDim2.new(0, 0, 0, 32)
        pageLine.BackgroundColor3 = CONFIG.Colors.Edge
        pageLine.BackgroundTransparency = 0.92
        pageLine.BorderSizePixel = 0
        pageLine.ZIndex = 8
        pageLine.Parent = page

        local body = Instance.new("ScrollingFrame")
        body.Name = "PageBody"
        body.Size = UDim2.new(1, 0, 1, -44)
        body.Position = UDim2.new(0, 0, 0, 44)
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.ScrollBarThickness = 2
        body.ScrollBarImageColor3 = CONFIG.Colors.Accent
        body.CanvasSize = UDim2.new(0, 0, 0, 0)
        body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        body.ZIndex = 8
        body.Parent = page

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 5)
        padding.PaddingRight = UDim.new(0, 7)
        padding.Parent = body

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        layout.Parent = body

        tabPages[name] = page
        return body
    end

    for i, name in ipairs(CONFIG.Tabs) do
        createTab(name, i)
    end

    selectTab = function(tabName)
        if activeTab == tabName then
            return
        end

        local previous = activeTab
        local previousPage = previous and tabPages[previous] or nil
        local targetPage = tabPages[tabName]

        if not targetPage then
            return
        end

        local oldIndex = previous and table.find(CONFIG.Tabs, previous) or nil
        local newIndex = table.find(CONFIG.Tabs, tabName) or 1
        local direction = 1

        if oldIndex and newIndex < oldIndex then
            direction = -1
        end

        activeTab = tabName
        updateTopContext(tabName, previous == nil)

        if premiumFx.reduceMotion then
            for name, button in pairs(tabButtons) do
                local selected = name == tabName
                local stroke = tabStrokes[name]
                local buttonScale = tabScales[name]
                local tabIcon = premiumFx.tabIcons[name]

                button.BackgroundTransparency = selected and 0.70 or 0.91
                button.BackgroundColor3 = CONFIG.Colors.GlassLight

                if stroke then
                    stroke.Transparency = selected and 0.38 or 0.84
                    stroke.Color = CONFIG.Colors.Edge
                end

                if buttonScale then
                    buttonScale.Scale = selected and 1.018 or 1
                end

                if tabIcon and tabIcon.Parent then
                    tabIcon.ImageColor3 = selected and CONFIG.Colors.Accent or CONFIG.Colors.SubText
                    tabIcon.ImageTransparency = selected and 0 or 0.18
                end
            end

            if newIndex then
                local targetY = 92 + (newIndex - 1) * 50
                tabIndicator.Position = UDim2.new(0, 9, 0, targetY)
                tabGlow.Position = UDim2.new(0, 6, 0, targetY - 4)
            end

            for _, page in pairs(tabPages) do
                page.Visible = false
                page.GroupTransparency = 0
                page.Position = UDim2.fromOffset(0, 0)
            end

            targetPage.Visible = true
            return
        end

        for name, button in pairs(tabButtons) do
            local selected = name == tabName
            local stroke = tabStrokes[name]
            local buttonScale = tabScales[name]
            local tabIcon = premiumFx.tabIcons[name]

            if tabIcon and tabIcon.Parent then
                tween(tabIcon, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    ImageColor3 = selected and CONFIG.Colors.Accent or CONFIG.Colors.SubText,
                    ImageTransparency = selected and 0 or 0.18,
                })
            end

            tween(button, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = selected and 0.70 or 0.91,
                BackgroundColor3 = CONFIG.Colors.GlassLight,
            })

            if stroke then
                tween(stroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = selected and 0.38 or 0.84,
                    Color = CONFIG.Colors.Edge,
                })
            end

            if buttonScale then
                tween(buttonScale, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Scale = selected and 1.018 or 1,
                })
            end
        end

        if newIndex then
            local targetY = 92 + (newIndex - 1) * 50

            tween(tabIndicator, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.new(0, 9, 0, targetY),
            })
            tween(tabGlow, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.new(0, 6, 0, targetY - 4),
            })
        end

        -- Hide any stale pages immediately, but let the previous page finish
        -- a tiny exit fade so the transition feels connected rather than abrupt.
        for name, page in pairs(tabPages) do
            if page ~= targetPage and page ~= previousPage then
                page.Visible = false
                page.GroupTransparency = 0
                page.Position = UDim2.fromOffset(0, 0)
            end
        end

        if previousPage and previousPage ~= targetPage then
            previousPage.Visible = true

            tween(previousPage, 0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(-4 * direction, 0),
            })

            local pageToHide = previousPage
            local previousName = previous

            task.delay(0.105, function()
                if activeTab ~= previousName and pageToHide and pageToHide.Parent then
                    pageToHide.Visible = false
                    pageToHide.GroupTransparency = 0
                    pageToHide.Position = UDim2.fromOffset(0, 0)
                end
            end)
        end

        targetPage.Visible = true
        targetPage.GroupTransparency = 1
        targetPage.Position = UDim2.fromOffset(6 * direction, 0)

        tween(targetPage, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            GroupTransparency = 0,
            Position = UDim2.fromOffset(0, 0),
        })

        if previous then
            premiumFx.pageSweep(targetPage)
        end
    end

    -- HOME PAGE.
    do
        local body = tabPages.Home:FindFirstChild("PageBody")
        createLabel(body, "Welcome back, " .. player.DisplayName .. ".")
        createLabel(body, "Salty is running in premium mode.")

        createSectionHeader(body, "LIVE TELEMETRY")

        local fpsLabel = createLabel(body, "FPS: --")
        local pingLabel = createLabel(body, "Ping: --")
        local playtimeLabel = createLabel(body, "Session: 00:00")

        local fpsTime = 0
        local fpsFrames = 0

        RunService.RenderStepped:Connect(function(dt)
            fpsTime += dt
            fpsFrames += 1

            if fpsTime >= 0.5 then
                local fps = math.floor(fpsFrames / fpsTime + 0.5)
                fpsLabel.Text = "FPS: " .. tostring(fps)
                fpsTime = 0
                fpsFrames = 0

            end
        end)

        task.spawn(function()
            while pingLabel.Parent do
                local ping = 0
                pcall(function()
                    ping = player:GetNetworkPing() * 1000
                end)
                pingLabel.Text = "Ping: " .. tostring(math.floor(ping)) .. " ms"
                task.wait(1.5)
            end
        end)

        -- NEW: session playtime counter.
        task.spawn(function()
            while playtimeLabel.Parent do
                local elapsed = math.floor(os.clock() - sessionStart)
                local mins = math.floor(elapsed / 60)
                local secs = elapsed % 60
                playtimeLabel.Text = string.format("Session: %02d:%02d", mins, secs)
                task.wait(1)
            end
        end)

        createSectionHeader(body, "SESSION")

        createButton(body, "Rejoin Server", function()
            showNotification("Rejoining server...", 3, "warning")
            task.delay(1.2, function()
                TeleportService:Teleport(game.PlaceId, player)
            end)
        end)

        createButton(body, "Refresh Interface", function()
            showNotification("Interface refreshed.", 2, "success")
        end)

    end

    -- PLAYER PAGE.
    do
        local body = tabPages.Player:FindFirstChild("PageBody")
        createSectionHeader(body, "PROFILE")
        createLabel(body, "Display Name: " .. player.DisplayName)
        createLabel(body, "Username: @" .. player.Name)
        createLabel(body, "User ID: " .. tostring(player.UserId))

        createSectionHeader(body, "STATUS")
        createLabel(body, "Salty is running safely with gameplay modifications disabled.")
    end

    -- SETTINGS PAGE.
    local rebindButton
    do
        local body = tabPages.Settings:FindFirstChild("PageBody")
        createSectionHeader(body, "THEME")

        local themes = {
            { name = "Violet", color = Color3.fromHex("8B7CFF") },
            { name = "Pink", color = Color3.fromHex("FF72D7") },
            { name = "Cyan", color = Color3.fromHex("5DE7FF") },
            { name = "Mint", color = Color3.fromHex("70FFD2") },
            { name = "Orange", color = Color3.fromHex("FF9F68") },
            { name = "Red", color = Color3.fromHex("FF6476") },
        }

        local dropdownHolder = Instance.new("Frame")
        dropdownHolder.Size = UDim2.new(1, 0, 0, 64)
        dropdownHolder.BackgroundTransparency = 1
        dropdownHolder.ZIndex = 20
        dropdownHolder.Parent = body

        local dropdownLabel = Instance.new("TextLabel")
        dropdownLabel.BackgroundTransparency = 1
        dropdownLabel.Size = UDim2.new(1, 0, 0, 17)
        dropdownLabel.Font = Enum.Font.GothamBold
        dropdownLabel.Text = "Theme Color"
        dropdownLabel.TextColor3 = CONFIG.Colors.Text
        dropdownLabel.TextSize = 11
        dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
        dropdownLabel.ZIndex = 20
        dropdownLabel.Parent = dropdownHolder

        local dropdownButton = Instance.new("TextButton")
        dropdownButton.Position = UDim2.fromOffset(0, 24)
        dropdownButton.Size = UDim2.new(1, -2, 0, 32)
        dropdownButton.BackgroundColor3 = CONFIG.Colors.GlassLight
        dropdownButton.BackgroundTransparency = 0.52
        dropdownButton.AutoButtonColor = false
        dropdownButton.Font = Enum.Font.GothamBold
        dropdownButton.Text = themes[1].name
        dropdownButton.TextColor3 = CONFIG.Colors.Text
        dropdownButton.TextSize = 11
        dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        dropdownButton.ZIndex = 21
        dropdownButton.Parent = dropdownHolder

        local dropdownTextPadding = Instance.new("UIPadding")
        dropdownTextPadding.PaddingLeft = UDim.new(0, 14)
        dropdownTextPadding.PaddingRight = UDim.new(0, 54)
        dropdownTextPadding.Parent = dropdownButton

        round(dropdownButton, 10)
        local dropdownStroke = addStroke(dropdownButton, 1, 0.78, CONFIG.Colors.Edge)
        local dropdownOpen = false

        dropdownButton.MouseEnter:Connect(function()
            tween(dropdownButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.44,
            })
            tween(dropdownStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.58,
            })
        end)

        dropdownButton.MouseLeave:Connect(function()
            if not dropdownOpen then
                tween(dropdownButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 0.52,
                })
                tween(dropdownStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = 0.78,
                })
            end
        end)

        local dropdownDot = Instance.new("Frame")
        premiumFx.controls.themeButton = dropdownButton
        premiumFx.controls.themeDot = dropdownDot
        dropdownDot.AnchorPoint = Vector2.new(1, 0.5)
        dropdownDot.Size = UDim2.fromOffset(9, 9)
        -- Sibling of dropdownButton so UIPadding cannot pull it left.
        dropdownDot.Position = UDim2.new(1, -18, 0, 40)
        dropdownDot.BackgroundColor3 = CONFIG.Colors.Accent
        dropdownDot.BorderSizePixel = 0
        dropdownDot.ZIndex = 22
        dropdownDot.Parent = dropdownHolder
        round(dropdownDot, 10)

        local optionList = Instance.new("Frame")
        optionList.Size = UDim2.new(1, -2, 0, #themes * 30 + 10)
        optionList.Position = UDim2.fromOffset(0, 62)
        optionList.BackgroundColor3 = CONFIG.Colors.GlassBase
        optionList.BackgroundTransparency = 0.05
        optionList.BorderSizePixel = 0
        optionList.Visible = false
        optionList.ZIndex = 40
        optionList.Parent = dropdownHolder
        round(optionList, 12)
        addStroke(optionList, 1, 0.62, CONFIG.Colors.Edge)

        local optionPadding = Instance.new("UIPadding")
        optionPadding.PaddingTop = UDim.new(0, 5)
        optionPadding.PaddingBottom = UDim.new(0, 5)
        optionPadding.Parent = optionList

        local optionLayout = Instance.new("UIListLayout")
        optionLayout.Padding = UDim.new(0, 2)
        optionLayout.Parent = optionList

        local function setDropdown(state)
            dropdownOpen = state
            optionList.Visible = state

            if premiumFx.reduceMotion then
                dropdownButton.BackgroundTransparency = state and 0.42 or 0.52
                return
            end

            tween(dropdownButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = state and 0.42 or 0.52,
            })
        end

        for _, theme in ipairs(themes) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, -2, 0, 28)
            option.BackgroundTransparency = 1
            option.AutoButtonColor = false
            option.Font = Enum.Font.GothamBold
            option.Text = theme.name
            option.TextColor3 = CONFIG.Colors.Text
            option.TextSize = 10
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.ZIndex = 41
            option.Parent = optionList
            round(option, 8)

            local optionTextPadding = Instance.new("UIPadding")
            optionTextPadding.PaddingLeft = UDim.new(0, 8)
            optionTextPadding.PaddingRight = UDim.new(0, 42)
            optionTextPadding.Parent = option

            local optionDot = Instance.new("Frame")
            optionDot.AnchorPoint = Vector2.new(1, 0.5)
            optionDot.Size = UDim2.fromOffset(8, 8)
            -- Option has 42px right padding; +22 places the dot 20px from true edge.
            optionDot.Position = UDim2.new(1, 22, 0.5, 0)
            optionDot.BackgroundColor3 = theme.color
            optionDot.BorderSizePixel = 0
            optionDot.ZIndex = 42
            optionDot.Parent = option
            round(optionDot, 8)

            option.MouseEnter:Connect(function()
                tween(option, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.78 })
            end)

            option.MouseLeave:Connect(function()
                tween(option, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
            end)

            option.MouseButton1Click:Connect(function()
                playClickSound()
                dropdownButton.Text = theme.name
                dropdownDot.BackgroundColor3 = theme.color
                updateAccentColor(theme.color)
                setDropdown(false)
                premiumFx.showStatus(
                    "settings",
                    "Theme changed",
                    theme.name,
                    1.35,
                    theme.color
                )
            end)
        end

        dropdownButton.MouseEnter:Connect(function()
            playHoverSound()
        end)

        dropdownButton.MouseButton1Click:Connect(function()
            playClickSound()
            setDropdown(not dropdownOpen)
        end)

        createSectionHeader(body, "APPEARANCE")

        local r = math.floor(CONFIG.Colors.Accent.R * 255)
        local g = math.floor(CONFIG.Colors.Accent.G * 255)
        local b = math.floor(CONFIG.Colors.Accent.B * 255)

        premiumFx.controls.accentSliders[1] = createSlider(body, "Accent R", 0, 255, r, function(value)
            updateAccentColor(Color3.fromRGB(math.floor(value), math.floor(CONFIG.Colors.Accent.G * 255), math.floor(CONFIG.Colors.Accent.B * 255)))
        end)

        premiumFx.controls.accentSliders[2] = createSlider(body, "Accent G", 0, 255, g, function(value)
            updateAccentColor(Color3.fromRGB(math.floor(CONFIG.Colors.Accent.R * 255), math.floor(value), math.floor(CONFIG.Colors.Accent.B * 255)))
        end)

        premiumFx.controls.accentSliders[3] = createSlider(body, "Accent B", 0, 255, b, function(value)
            updateAccentColor(Color3.fromRGB(math.floor(CONFIG.Colors.Accent.R * 255), math.floor(CONFIG.Colors.Accent.G * 255), math.floor(value)))
        end)

        createSectionHeader(body, "BEHAVIOR")

        premiumFx.controls.settingsBlur = createToggle(body, "Background Blur", true, function(state)
            setBlur(state)
            premiumFx.syncToggleGroup(premiumFx.controls.blurToggles, state, premiumFx.controls.settingsBlur)
        end)
        table.insert(premiumFx.controls.blurToggles, premiumFx.controls.settingsBlur)

        premiumFx.controls.settingsSounds = createToggle(body, "UI Sounds", true, function(state)
            premiumFx.setUiSounds(state)
            premiumFx.syncToggleGroup(premiumFx.controls.soundToggles, state, premiumFx.controls.settingsSounds)
        end)
        table.insert(premiumFx.controls.soundToggles, premiumFx.controls.settingsSounds)

        premiumFx.controls.reduceMotion = createToggle(body, "Reduce Motion", premiumFx.reduceMotion, function(state)
            premiumFx.setReduceMotion(state)
            premiumFx.showStatus(
                "settings",
                "Reduce motion",
                state and "Enabled" or "Disabled",
                1.0,
                state and CONFIG.Colors.Success or CONFIG.Colors.Accent
            )
        end)

        -- NEW: rebindable toggle hotkey.
        createSectionHeader(body, "HOTKEY")
        createLabel(body, "Click below, then press any key to rebind the panel toggle.")

        local capturing = false
        rebindButton = createButton(body, "Toggle Key: " .. CONFIG.ToggleKey.Name, function()
            if capturing then
                return
            end
            capturing = true
            rebindButton.Text = "Press any key..."
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not capturing then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            capturing = false
            CONFIG.ToggleKey = input.KeyCode
            rebindButton.Text = "Toggle Key: " .. input.KeyCode.Name
            premiumFx.showStatus("settings", "Hotkey updated", input.KeyCode.Name, 1.15, CONFIG.Colors.Success)
        end)

        createSectionHeader(body, "RESET")
        createLabel(body, "Restore interface defaults without touching music playback.")

        premiumFx.controls.resetRow = Instance.new("Frame")
        premiumFx.controls.resetRow.Size = UDim2.new(1, 0, 0, 36)
        premiumFx.controls.resetRow.BackgroundTransparency = 1
        premiumFx.controls.resetRow.ZIndex = 8
        premiumFx.controls.resetRow.Parent = body

        premiumFx.controls.resetHint = Instance.new("TextLabel")
        premiumFx.controls.resetHint.Size = UDim2.new(1, -126, 1, 0)
        premiumFx.controls.resetHint.BackgroundTransparency = 1
        premiumFx.controls.resetHint.Font = Enum.Font.GothamMedium
        premiumFx.controls.resetHint.Text = "Theme • layout • preferences"
        premiumFx.controls.resetHint.TextColor3 = CONFIG.Colors.Muted
        premiumFx.controls.resetHint.TextSize = 9
        premiumFx.controls.resetHint.TextXAlignment = Enum.TextXAlignment.Left
        premiumFx.controls.resetHint.ZIndex = 8
        premiumFx.controls.resetHint.Parent = premiumFx.controls.resetRow

        premiumFx.controls.resetButton = Instance.new("TextButton")
        premiumFx.controls.resetButton.AnchorPoint = Vector2.new(1, 0.5)
        premiumFx.controls.resetButton.Position = UDim2.new(1, 0, 0.5, 0)
        premiumFx.controls.resetButton.Size = UDim2.fromOffset(112, 30)
        premiumFx.controls.resetButton.BackgroundColor3 = CONFIG.Colors.GlassLight
        premiumFx.controls.resetButton.BackgroundTransparency = 0.62
        premiumFx.controls.resetButton.AutoButtonColor = false
        premiumFx.controls.resetButton.Font = Enum.Font.GothamBold
        premiumFx.controls.resetButton.Text = "RESET UI"
        premiumFx.controls.resetButton.TextColor3 = CONFIG.Colors.Text
        premiumFx.controls.resetButton.TextSize = 10
        premiumFx.controls.resetButton.ZIndex = 9
        premiumFx.controls.resetButton.Parent = premiumFx.controls.resetRow
        round(premiumFx.controls.resetButton, 10)
        premiumFx.controls.resetStroke = addStroke(premiumFx.controls.resetButton, 1, 0.70, CONFIG.Colors.Edge)

        premiumFx.controls.resetButton.MouseEnter:Connect(function()
            playHoverSound()
            if premiumFx.reduceMotion then
                premiumFx.controls.resetButton.BackgroundTransparency = 0.50
                premiumFx.controls.resetStroke.Transparency = 0.52
            else
                tween(premiumFx.controls.resetButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 0.50,
                })
                tween(premiumFx.controls.resetStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = 0.52,
                })
            end
        end)

        premiumFx.controls.resetButton.MouseLeave:Connect(function()
            if premiumFx.reduceMotion then
                premiumFx.controls.resetButton.BackgroundTransparency = 0.62
                premiumFx.controls.resetStroke.Transparency = 0.70
            else
                tween(premiumFx.controls.resetButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 0.62,
                })
                tween(premiumFx.controls.resetStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    Transparency = 0.70,
                })
            end
        end)

        premiumFx.controls.resetButton.MouseButton1Click:Connect(function()
            playClickSound()

            -- Preferences.
            premiumFx.setReduceMotion(false)
            premiumFx.controls.reduceMotion.set(false, true)

            setBlur(true)
            premiumFx.syncToggleGroup(premiumFx.controls.blurToggles, true)
            premiumFx.setUiSounds(true)
            premiumFx.syncToggleGroup(premiumFx.controls.soundToggles, true)

            CONFIG.ToggleKey = premiumFx.defaults.toggleKey
            rebindButton.Text = "Toggle Key: " .. CONFIG.ToggleKey.Name

            -- Theme / RGB controls.
            updateAccentColor(premiumFx.defaults.accent)
            if premiumFx.controls.themeButton then
                premiumFx.controls.themeButton.Text = "Violet"
            end
            if premiumFx.controls.themeDot then
                premiumFx.controls.themeDot.BackgroundColor3 = premiumFx.defaults.accent
            end
            premiumFx.controls.accentSliders[1].set(139)
            premiumFx.controls.accentSliders[2].set(124)
            premiumFx.controls.accentSliders[3].set(255)
            setDropdown(false)

            -- Window / navigation.
            isOpen = true
            isMinimized = false
            openSize = premiumFx.defaults.windowSize
            openPosition = premiumFx.defaults.windowPosition
            mainFrame.Visible = true
            mainFrame.Size = openSize
            mainFrame.Position = openPosition
            mainScale.Scale = 1
            mainFrame.BackgroundTransparency = 0.08
            innerBorder.Position = UDim2.fromOffset(1, 1)

            local resetBadge = screenGui:FindFirstChild("MinimizedBadge")
            local resetBadgeGlow = screenGui:FindFirstChild("MinimizedBadgeGlow")
            if resetBadge then
                resetBadge.Visible = false
            end
            if resetBadgeGlow then
                resetBadgeGlow.Visible = false
            end

            for _, page in pairs(tabPages) do
                local pageBody = page:FindFirstChild("PageBody")
                if pageBody and pageBody:IsA("ScrollingFrame") then
                    pageBody.CanvasPosition = Vector2.zero
                end
            end

            selectTab("Home")
            body.CanvasPosition = Vector2.zero

            premiumFx.showStatus("settings", "UI reset", "Defaults restored", 1.35, CONFIG.Colors.Success)
        end)
    end

    -- VISUALS PAGE.
    do
        local body = tabPages.Visuals:FindFirstChild("PageBody")
        createSectionHeader(body, "INTERFACE")
        createLabel(body, "Premium glass effects are enabled.")
        createLabel(body, "Gameplay / exploit features have been removed.")

        createSectionHeader(body, "SAFE CONTROLS")
        premiumFx.controls.visualsBlur = createToggle(body, "Background Blur", premiumFx.blurEnabled, function(state)
            setBlur(state)
            premiumFx.syncToggleGroup(premiumFx.controls.blurToggles, state, premiumFx.controls.visualsBlur)
        end)
        table.insert(premiumFx.controls.blurToggles, premiumFx.controls.visualsBlur)

        premiumFx.controls.visualsSounds = createToggle(body, "UI Sounds", premiumFx.uiSoundsEnabled, function(state)
            premiumFx.setUiSounds(state)
            premiumFx.syncToggleGroup(premiumFx.controls.soundToggles, state, premiumFx.controls.visualsSounds)
        end)
        table.insert(premiumFx.controls.soundToggles, premiumFx.controls.visualsSounds)

        createSectionHeader(body, "EFFECTS")
    end

    -- Minimized badge — Liquid Glass mini-player style.
    local badgeGlow = Instance.new("Frame")
    badgeGlow.Name = "MinimizedBadgeGlow"
    badgeGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    badgeGlow.Size = UDim2.fromOffset(198, 62)
    badgeGlow.Position = UDim2.new(0.5, 0, 0, 68)
    badgeGlow.BackgroundColor3 = CONFIG.Colors.Accent
    badgeGlow.BackgroundTransparency = 0.965
    badgeGlow.BorderSizePixel = 0
    badgeGlow.Visible = false
    badgeGlow.ZIndex = 78
    badgeGlow.Parent = screenGui
    round(badgeGlow, 31)

    local badge = Instance.new("TextButton")
    badge.Name = "MinimizedBadge"
    badge.AnchorPoint = Vector2.new(0.5, 0.5)
    badge.Size = UDim2.fromOffset(184, 54)
    badge.Position = UDim2.new(0.5, 0, 0, 68)
    badge.BackgroundColor3 = CONFIG.Colors.GlassBase
    badge.BackgroundTransparency = 0.10
    badge.AutoButtonColor = false
    badge.Text = ""
    badge.Visible = false
    badge.ClipsDescendants = true
    badge.ZIndex = 80
    badge.Parent = screenGui
    round(badge, 27)

    local badgeGlass = Instance.new("UIGradient")
    badgeGlass.Rotation = 120
    badgeGlass.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("202A42")),
        ColorSequenceKeypoint.new(0.48, CONFIG.Colors.GlassMid),
        ColorSequenceKeypoint.new(1, Color3.fromHex("070A12")),
    })
    badgeGlass.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.20),
        NumberSequenceKeypoint.new(0.55, 0.48),
        NumberSequenceKeypoint.new(1, 0.12),
    })
    badgeGlass.Parent = badge

    local badgeStroke = addStroke(badge, 1.25, 0.44, CONFIG.Colors.Edge)
    badgeStrokeGradient = Instance.new("UIGradient")
    badgeStrokeGradient.Rotation = 18
    badgeStrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.Edge),
        ColorSequenceKeypoint.new(0.5, CONFIG.Colors.Edge),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.Edge),
    })
    badgeStrokeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.5, 0.42),
        NumberSequenceKeypoint.new(1, 0.10),
    })
    badgeStrokeGradient.Parent = badgeStroke

    -- Moving specular highlight.
    local badgeShine = Instance.new("Frame")
    badgeShine.Size = UDim2.new(1, -24, 0, 2)
    badgeShine.Position = UDim2.fromOffset(12, 1)
    badgeShine.BackgroundColor3 = Color3.new(1, 1, 1)
    badgeShine.BackgroundTransparency = 0.82
    badgeShine.BorderSizePixel = 0
    badgeShine.ZIndex = 81
    badgeShine.Parent = badge
    round(badgeShine, 2)

    local badgeShineGradient = Instance.new("UIGradient")
    badgeShineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CONFIG.Colors.Accent),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, CONFIG.Colors.Cyan),
    })
    badgeShineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.25, 0.45),
        NumberSequenceKeypoint.new(0.55, 0.18),
        NumberSequenceKeypoint.new(0.82, 0.58),
        NumberSequenceKeypoint.new(1, 1),
    })
    badgeShineGradient.Parent = badgeShine

    local badgeIcon = Instance.new("Frame")
    badgeIcon.Size = UDim2.fromOffset(38, 38)
    badgeIcon.Position = UDim2.new(0, 8, 0.5, -19)
    badgeIcon.BackgroundColor3 = CONFIG.Colors.GlassLight
    badgeIcon.BackgroundTransparency = 0.46
    badgeIcon.BorderSizePixel = 0
    badgeIcon.ZIndex = 82
    badgeIcon.Parent = badge
    round(badgeIcon, 19)
    addStroke(badgeIcon, 1, 0.62, CONFIG.Colors.Edge)

    badgeIconGlow = Instance.new("Frame")
    badgeIconGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    badgeIconGlow.Position = UDim2.fromScale(0.5, 0.5)
    badgeIconGlow.Size = UDim2.fromOffset(29, 29)
    badgeIconGlow.BackgroundColor3 = CONFIG.Colors.Accent
    badgeIconGlow.BackgroundTransparency = 0.88
    badgeIconGlow.BorderSizePixel = 0
    badgeIconGlow.ZIndex = 82
    badgeIconGlow.Parent = badgeIcon
    round(badgeIconGlow, 16)

    badgeMusicIcon = createLucideIcon(badgeIcon, "music", 18, CONFIG.Colors.Accent, 84)
    badgeMusicIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    badgeMusicIcon.Position = UDim2.fromScale(0.5, 0.5)

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.BackgroundTransparency = 1
    badgeLabel.Position = UDim2.new(0, 56, 0, 7)
    badgeLabel.Size = UDim2.new(1, -94, 0, 20)
    badgeLabel.Font = Enum.Font.GothamBlack
    badgeLabel.Text = "SALTY"
    badgeLabel.TextColor3 = CONFIG.Colors.Text
    badgeLabel.TextSize = 12
    badgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    badgeLabel.ZIndex = 83
    badgeLabel.Parent = badge

    local badgeSubLabel = Instance.new("TextLabel")
    badgeSubLabel.BackgroundTransparency = 1
    badgeSubLabel.Position = UDim2.new(0, 56, 0, 27)
    badgeSubLabel.Size = UDim2.new(1, -94, 0, 14)
    badgeSubLabel.Font = Enum.Font.GothamMedium
    badgeSubLabel.Text = "MINIMIZED • RESTORE"
    badgeSubLabel.TextColor3 = CONFIG.Colors.Muted
    badgeSubLabel.TextSize = 6
    badgeSubLabel.TextXAlignment = Enum.TextXAlignment.Left
    badgeSubLabel.ZIndex = 83
    badgeSubLabel.Parent = badge

    -- Tiny animated visualizer.
    local badgeViz = Instance.new("Frame")
    badgeViz.AnchorPoint = Vector2.new(1, 0.5)
    badgeViz.Position = UDim2.new(1, -13, 0.5, 0)
    badgeViz.Size = UDim2.fromOffset(26, 20)
    badgeViz.BackgroundTransparency = 1
    badgeViz.ZIndex = 83
    badgeViz.Parent = badge

    local badgeBars = {}
    for i = 1, 3 do
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0.5, 1)
        bar.Position = UDim2.new(0, 4 + (i - 1) * 8, 1, -2)
        bar.Size = UDim2.fromOffset(3, 6 + i * 2)
        bar.BackgroundColor3 = (i == 2) and CONFIG.Colors.Cyan or CONFIG.Colors.Accent
        bar.BackgroundTransparency = 0.12
        bar.BorderSizePixel = 0
        bar.ZIndex = 84
        bar.Parent = badgeViz
        round(bar, 2)
        badgeBars[i] = bar
    end

    badgeAccentLine = Instance.new("Frame")
    badgeAccentLine.AnchorPoint = Vector2.new(0.5, 1)
    badgeAccentLine.Position = UDim2.new(0.5, 0, 1, -4)
    badgeAccentLine.Size = UDim2.new(1, -30, 0, 2)
    badgeAccentLine.BackgroundColor3 = CONFIG.Colors.Accent
    badgeAccentLine.BackgroundTransparency = 0.40
    badgeAccentLine.BorderSizePixel = 0
    badgeAccentLine.ZIndex = 84
    badgeAccentLine.Parent = badge
    round(badgeAccentLine, 2)

    local badgeAccentGradient = Instance.new("UIGradient")
    badgeAccentGradient.Color = ColorSequence.new(CONFIG.Colors.Accent, CONFIG.Colors.Cyan)
    badgeAccentGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.20, 0.20),
        NumberSequenceKeypoint.new(0.80, 0.20),
        NumberSequenceKeypoint.new(1, 1),
    })
    badgeAccentGradient.Parent = badgeAccentLine

    local badgeScale = addScale(badge)

    badge.MouseEnter:Connect(function()
        tween(badge, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.02,
        })
        tween(badgeScale, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Scale = 1.045,
        })
        tween(badgeGlow, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.925,
            Size = UDim2.fromOffset(208, 68),
        })
    end)

    badge.MouseLeave:Connect(function()
        tween(badge, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.10,
        })
        tween(badgeScale, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Scale = 1,
        })
        tween(badgeGlow, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0.965,
            Size = UDim2.fromOffset(198, 62),
        })
    end)

    badge.MouseButton1Click:Connect(function()
        if isMinimized then
            playClickSound()
            restorePanel()
        end
    end)

    -- Ambient badge movement. Only animates while visible.
    task.spawn(function()
        local t = 0
        while badge.Parent do
            local dt = RunService.RenderStepped:Wait()
            t += dt

            if badge.Visible then
                if premiumFx.reduceMotion then
                    badgeShineGradient.Offset = Vector2.zero
                    badgeStrokeGradient.Rotation = 18
                    badgeIconGlow.BackgroundTransparency = 0.90

                    for _, bar in ipairs(badgeBars) do
                        bar.Size = UDim2.fromOffset(3, 7)
                    end
                else
                    badgeShineGradient.Offset = Vector2.new(math.sin(t * 0.52) * 0.35, 0)
                    badgeStrokeGradient.Rotation = 18 + math.sin(t * 0.30) * 8

                    local pulse = 0.5 + 0.5 * math.sin(t * 2.2)
                    badgeIconGlow.BackgroundTransparency = 0.90 - pulse * 0.07

                    for i, bar in ipairs(badgeBars) do
                        local h = 5 + (0.5 + 0.5 * math.sin(t * (2.8 + i * 0.32) + i * 1.7)) * 12
                        bar.Size = UDim2.fromOffset(3, h)
                    end
                end
            end
        end
    end)

    -- Open/close/minimize controls.
    local function setVisible(visible)
        if isShuttingDown then
            return
        end

        if visible then
            isOpen = true
            mainFrame.Visible = true
            setBlur(true)

            if premiumFx.reduceMotion then
                mainScale.Scale = 1
                mainFrame.Position = openPosition
                return
            end

            mainScale.Scale = 0.965
            mainFrame.Position = UDim2.new(
                openPosition.X.Scale, openPosition.X.Offset,
                openPosition.Y.Scale - 0.018, openPosition.Y.Offset
            )

            tween(mainScale, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Scale = 1 })
            tween(mainFrame, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = openPosition,
            })
        else
            isOpen = false
            setBlur(false)

            if premiumFx.reduceMotion then
                mainFrame.Visible = false
                mainScale.Scale = 1
                mainFrame.Position = openPosition
                return
            end

            tween(mainScale, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Scale = 0.97 })
            local closeTween = tween(mainFrame, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                Position = UDim2.new(
                    openPosition.X.Scale, openPosition.X.Offset,
                    openPosition.Y.Scale - 0.015, openPosition.Y.Offset
                ),
            })

            closeTween.Completed:Connect(function()
                if not isOpen and not isShuttingDown and mainFrame.Parent then
                    mainFrame.Visible = false
                    mainScale.Scale = 1
                    mainFrame.Position = openPosition
                end
            end)
        end
    end

    local function minimizeToBadge()
        if isMinimized then
            return
        end

        isMinimized = true
        premiumFx.showStatus("minus", "Minimizing", "Salty to badge", 0.55, CONFIG.Colors.Warning)
        setBlur(false)

        if premiumFx.reduceMotion then
            badge.Visible = true
            badgeGlow.Visible = true
            badge.Size = UDim2.fromOffset(184, 54)
            badgeGlow.Size = UDim2.fromOffset(198, 62)
            badge.BackgroundTransparency = 0.10
            badgeGlow.BackgroundTransparency = 0.965
            badgeStroke.Transparency = 0.44
            badgeLabel.TextTransparency = 0
            badgeSubLabel.TextTransparency = 0
            mainFrame.Visible = false
            return
        end

        badge.Visible = true
        badgeGlow.Visible = true
        badge.Size = UDim2.fromOffset(20, 20)
        badgeGlow.Size = UDim2.fromOffset(24, 24)
        badge.BackgroundTransparency = 1
        badgeGlow.BackgroundTransparency = 1
        badgeStroke.Transparency = 1
        badgeLabel.TextTransparency = 1
        badgeSubLabel.TextTransparency = 1

        tween(badgeGlow, 0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Size = UDim2.fromOffset(198, 62),
            BackgroundTransparency = 0.965,
        })
        tween(badge, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Size = UDim2.fromOffset(184, 54),
            BackgroundTransparency = 0.10,
        })
        tween(badgeStroke, 0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.44 })
        tween(badgeLabel, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { TextTransparency = 0 })
        tween(badgeSubLabel, 0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { TextTransparency = 0 })
        tween(mainFrame, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(12, 12),
        })

        task.delay(0.27, function()
            if isMinimized then
                mainFrame.Visible = false
            end
        end)
    end

    restorePanel = function()
        if not isMinimized then
            return
        end

        isMinimized = false
        isOpen = true
        mainFrame.Visible = true
        mainScale.Scale = 1
        mainFrame.Size = UDim2.fromOffset(12, 12)
        mainFrame.Position = badge.Position
        setBlur(true)

        if premiumFx.reduceMotion then
            mainFrame.Size = openSize
            mainFrame.Position = openPosition
            badge.Visible = false
            badgeGlow.Visible = false
            badge.Size = UDim2.fromOffset(184, 54)
            badgeGlow.Size = UDim2.fromOffset(198, 62)
            premiumFx.showStatus("home", "Welcome back", "Salty restored", 1.15, CONFIG.Colors.Accent)
            return
        end

        task.delay(0.24, function()
            if not isMinimized and mainFrame.Parent then
                premiumFx.showStatus("home", "Welcome back", "Salty restored", 1.15, CONFIG.Colors.Accent)
            end
        end)

        tween(mainFrame, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Size = openSize,
            Position = openPosition,
        })

        tween(badge, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
        })
        tween(badgeGlow, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 1,
        })
        tween(badgeStroke, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Transparency = 1 })
        tween(badgeLabel, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { TextTransparency = 1 })
        tween(badgeSubLabel, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { TextTransparency = 1 })

        task.delay(0.22, function()
            if not isMinimized then
                badge.Visible = false
                badgeGlow.Visible = false
            end
        end)
    end

    local function shutdownGui()
        if isShuttingDown then
            return
        end

        isShuttingDown = true
        isOpen = false
        isMinimized = false

        -- Stop all Salty-owned features before the GUI disappears.
        if musicPlayer and musicPlayer.Shutdown then
            pcall(musicPlayer.Shutdown)
        end

        CONFIG.ClickSoundId = ""
        CONFIG.HoverSoundId = ""

        for _, child in ipairs(SoundService:GetChildren()) do
            if child:IsA("Sound") and (child.Name == "SaltyUISound" or child.Name == "SaltyMusicPlayerSound") then
                pcall(function()
                    child:Stop()
                end)
                child:Destroy()
            end
        end

        if blur and blur.Parent then
            tween(blur, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Size = 0 })
        end
        if musicBlur and musicBlur.Parent then
            tween(musicBlur, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Size = 0 })
        end

        badge.Visible = false
        badgeGlow.Visible = false

        local targetPosition = UDim2.new(
            mainFrame.Position.X.Scale, mainFrame.Position.X.Offset,
            mainFrame.Position.Y.Scale - 0.012, mainFrame.Position.Y.Offset
        )

        tween(mainScale, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Scale = 0.94 })
        tween(mainStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Transparency = 1 })
        tween(innerStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Transparency = 1 })
        local closeTween = tween(mainFrame, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
            Position = targetPosition,
            BackgroundTransparency = 1,
        })

        closeTween.Completed:Connect(function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            if blur and blur.Parent then
                blur:Destroy()
            end
            if musicBlur and musicBlur.Parent then
                musicBlur:Destroy()
            end
            pcall(function()
                if typeof(script) == "Instance" then
                    script:Destroy()
                end
            end)
        end)
    end

    closeButton.MouseButton1Click:Connect(function()
        playClickSound()
        task.defer(shutdownGui)
    end)

    altF4Button.MouseButton1Click:Connect(function()
        if isShuttingDown then
            return
        end

        playClickSound()

        -- Start the same polished feature cleanup/close animation first,
        -- then leave the current Roblox experience.
        task.spawn(function()
            shutdownGui()
            task.wait(0.12)

            pcall(function()
                if player and player.Parent then
                    player:Kick("You have been kicked!")
                end
            end)
        end)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        playClickSound()
        minimizeToBadge()
    end)

    ----------------------------------------------------------------
    -- NEW: Music player ui.palette (Ctrl+M) — Liquid Glass / custom audio
    ----------------------------------------------------------------
    do
        -- Store cross-callback UI references in one table to stay below Luau's 200-register limit.
        local ui = {}

        ui.musicOverlay = Instance.new("Frame")
        ui.musicOverlay.Name = "MusicPaletteOverlay"
        ui.musicOverlay.Size = UDim2.fromScale(1, 1)
        ui.musicOverlay.BackgroundTransparency = 1
        ui.musicOverlay.BorderSizePixel = 0
        ui.musicOverlay.Visible = false
        ui.musicOverlay.ZIndex = 600
        ui.musicOverlay.Parent = screenGui

        -- Full-screen modal input sink.
        -- It has no click action; its only job is to prevent input reaching the GUI behind the player.
        ui.backdrop = Instance.new("TextButton")
        ui.backdrop.Name = "BackdropInputSink"
        ui.backdrop.Size = UDim2.fromScale(1, 1)
        ui.backdrop.BackgroundColor3 = Color3.fromHex("03050A")
        ui.backdrop.BackgroundTransparency = 1
        ui.backdrop.BorderSizePixel = 0
        ui.backdrop.AutoButtonColor = false
        ui.backdrop.Text = ""
        ui.backdrop.Active = true
        ui.backdrop.Selectable = false
        ui.backdrop.ZIndex = 600
        ui.backdrop.Parent = ui.musicOverlay

        ui.palette = Instance.new("Frame")
        ui.palette.Name = "MusicPalette"
        ui.palette.AnchorPoint = Vector2.new(0.5, 0)
        ui.palette.Position = UDim2.new(0.5, 0, 0.14, 0)
        ui.palette.Size = UDim2.fromOffset(500, 420)
        ui.palette.BackgroundColor3 = CONFIG.Colors.GlassBase
        ui.palette.BackgroundTransparency = 0.08
        ui.palette.BorderSizePixel = 0
        ui.palette.ClipsDescendants = true
        ui.palette.Active = true
        ui.palette.ZIndex = 601
        ui.palette.Parent = ui.musicOverlay
        round(ui.palette, 28)

        -- Blank areas inside the palette also consume input instead of clicking through.
        ui.inputShield = Instance.new("TextButton")
        ui.inputShield.Name = "PaletteInputShield"
        ui.inputShield.Size = UDim2.fromScale(1, 1)
        ui.inputShield.BackgroundTransparency = 1
        ui.inputShield.AutoButtonColor = false
        ui.inputShield.Text = ""
        ui.inputShield.Active = true
        ui.inputShield.Selectable = false
        ui.inputShield.ZIndex = 602
        ui.inputShield.Parent = ui.palette
        round(ui.inputShield, 28)

        ui.paletteScale = addScale(ui.palette)

        local paletteStroke = addStroke(ui.palette, 1.25, 0.48, CONFIG.Colors.Edge)
        ui.paletteStrokeGradient = Instance.new("UIGradient")
        ui.paletteStrokeGradient.Rotation = 24
        ui.paletteStrokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.Colors.Edge),
            ColorSequenceKeypoint.new(0.5, CONFIG.Colors.Edge),
            ColorSequenceKeypoint.new(1, CONFIG.Colors.Edge),
        })
        ui.paletteStrokeGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.5, 0.36),
            NumberSequenceKeypoint.new(1, 0.10),
        })
        ui.paletteStrokeGradient.Parent = paletteStroke

        local paletteGlass = Instance.new("UIGradient")
        paletteGlass.Rotation = 120
        paletteGlass.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("202B45")),
            ColorSequenceKeypoint.new(0.42, CONFIG.Colors.GlassMid),
            ColorSequenceKeypoint.new(1, Color3.fromHex("070A12")),
        })
        paletteGlass.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.45, 0.35),
            NumberSequenceKeypoint.new(1, 0.08),
        })
        paletteGlass.Parent = ui.palette

        -- Soft top specular highlight for a Liquid Glass feel.
        local specular = Instance.new("Frame")
        specular.Size = UDim2.new(1, -40, 0, 2)
        specular.Position = UDim2.fromOffset(20, 1)
        specular.BackgroundColor3 = Color3.new(1, 1, 1)
        specular.BackgroundTransparency = 0.82
        specular.BorderSizePixel = 0
        specular.ZIndex = 602
        specular.Parent = ui.palette
        round(specular, 2)

        ui.specularGradient = Instance.new("UIGradient")
        ui.specularGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.Colors.Accent),
            ColorSequenceKeypoint.new(0.48, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, CONFIG.Colors.Cyan),
        })
        ui.specularGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.18, 0.35),
            NumberSequenceKeypoint.new(0.82, 0.45),
            NumberSequenceKeypoint.new(1, 1),
        })
        ui.specularGradient.Parent = specular

        local header = Instance.new("TextLabel")
        header.BackgroundTransparency = 1
        header.Position = UDim2.fromOffset(24, 17)
        header.Size = UDim2.new(1, -84, 0, 25)
        header.Font = Enum.Font.GothamBlack
        header.Text = "MUSIC"
        header.TextColor3 = CONFIG.Colors.Text
        header.TextSize = 18
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 606
        header.Parent = ui.palette

        local subHeader = Instance.new("TextLabel")
        subHeader.BackgroundTransparency = 1
        subHeader.Position = UDim2.fromOffset(25, 42)
        subHeader.Size = UDim2.new(1, -86, 0, 15)
        subHeader.Font = Enum.Font.GothamMedium
        subHeader.Text = "CTRL + M  •  CUSTOM AUDIO"
        subHeader.TextColor3 = CONFIG.Colors.Muted
        subHeader.TextSize = 8
        subHeader.TextXAlignment = Enum.TextXAlignment.Left
        subHeader.ZIndex = 606
        subHeader.Parent = ui.palette

        ui.close = Instance.new("TextButton")
        ui.close.AnchorPoint = Vector2.new(1, 0)
        ui.close.Position = UDim2.new(1, -18, 0, 17)
        ui.close.Size = UDim2.fromOffset(34, 34)
        ui.close.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.close.BackgroundTransparency = 0.66
        ui.close.AutoButtonColor = false
        ui.close.Text = ""
        ui.close.ZIndex = 607
        ui.close.Parent = ui.palette
        round(ui.close, 17)
        local closeStroke = addStroke(ui.close, 1, 0.68, CONFIG.Colors.Edge)

        local closeIcon = createLucideIcon(ui.close, "x", 16, CONFIG.Colors.Text, 608)
        closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        closeIcon.Position = UDim2.fromScale(0.5, 0.5)

        ui.close.MouseEnter:Connect(function()
            tween(ui.close, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.48 })
            tween(closeStroke, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.44 })
        end)
        ui.close.MouseLeave:Connect(function()
            tween(ui.close, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.66 })
            tween(closeStroke, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.68 })
        end)

        -- Now-playing glass card.
        local nowCard = Instance.new("Frame")
        nowCard.Position = UDim2.fromOffset(18, 68)
        nowCard.Size = UDim2.new(1, -36, 0, 126)
        nowCard.BackgroundColor3 = CONFIG.Colors.GlassLight
        nowCard.BackgroundTransparency = 0.73
        nowCard.BorderSizePixel = 0
        nowCard.ZIndex = 603
        nowCard.Parent = ui.palette
        round(nowCard, 26)
        local nowCardStroke = addStroke(nowCard, 1, 0.80, CONFIG.Colors.Edge)

        local nowCardGradient = Instance.new("UIGradient")
        nowCardGradient.Rotation = 25
        nowCardGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.Colors.GlassLight),
            ColorSequenceKeypoint.new(0.56, CONFIG.Colors.GlassMid),
            ColorSequenceKeypoint.new(1, CONFIG.Colors.GlassBase),
        })
        nowCardGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(1, 0.72),
        })
        nowCardGradient.Parent = nowCard

        ui.artwork = Instance.new("Frame")
        ui.artwork.Position = UDim2.fromOffset(12, 12)
        ui.artwork.Size = UDim2.fromOffset(102, 102)
        ui.artwork.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.artwork.BackgroundTransparency = 0.32
        ui.artwork.BorderSizePixel = 0
        ui.artwork.ZIndex = 604
        ui.artwork.Parent = nowCard
        round(ui.artwork, 24)
        local artworkStroke = addStroke(ui.artwork, 1, 0.52, CONFIG.Colors.Edge)

        local artworkGradient = Instance.new("UIGradient")
        artworkGradient.Rotation = 135
        artworkGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, CONFIG.Colors.Accent),
            ColorSequenceKeypoint.new(0.55, CONFIG.Colors.GlassLight),
            ColorSequenceKeypoint.new(1, CONFIG.Colors.AccentAlt),
        })
        artworkGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.52, 0.52),
            NumberSequenceKeypoint.new(1, 0.25),
        })
        artworkGradient.Parent = ui.artwork

        ui.artworkMusicIcon = createLucideIcon(ui.artwork, "music", 38, CONFIG.Colors.Text, 605)
        ui.artworkMusicIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        ui.artworkMusicIcon.Position = UDim2.fromScale(0.5, 0.5)

        ui.trackName = Instance.new("TextLabel")
        ui.trackName.Position = UDim2.fromOffset(132, 18)
        ui.trackName.Size = UDim2.new(1, -150, 0, 23)
        ui.trackName.BackgroundTransparency = 1
        ui.trackName.Font = Enum.Font.GothamBlack
        ui.trackName.Text = "Custom Audio"
        ui.trackName.TextColor3 = CONFIG.Colors.Text
        ui.trackName.TextSize = 15
        ui.trackName.TextXAlignment = Enum.TextXAlignment.Left
        ui.trackName.TextTruncate = Enum.TextTruncate.AtEnd
        ui.trackName.ZIndex = 605
        ui.trackName.Parent = nowCard

        ui.artistName = Instance.new("TextLabel")
        ui.artistName.Position = UDim2.fromOffset(132, 42)
        ui.artistName.Size = UDim2.new(1, -150, 0, 17)
        ui.artistName.BackgroundTransparency = 1
        ui.artistName.Font = Enum.Font.GothamMedium
        ui.artistName.Text = "Paste a Roblox audio asset ID"
        ui.artistName.TextColor3 = CONFIG.Colors.SubText
        ui.artistName.TextSize = 9
        ui.artistName.TextXAlignment = Enum.TextXAlignment.Left
        ui.artistName.ZIndex = 605
        ui.artistName.Parent = nowCard

        ui.stateLabel = Instance.new("TextLabel")
        ui.stateLabel.Position = UDim2.fromOffset(132, 62)
        ui.stateLabel.Size = UDim2.new(1, -150, 0, 16)
        ui.stateLabel.BackgroundTransparency = 1
        ui.stateLabel.Font = Enum.Font.GothamBold
        ui.stateLabel.Text = "WAITING FOR ID"
        ui.stateLabel.TextColor3 = CONFIG.Colors.Warning
        ui.stateLabel.TextSize = 8
        ui.stateLabel.TextXAlignment = Enum.TextXAlignment.Left
        ui.stateLabel.ZIndex = 605
        ui.stateLabel.Parent = nowCard

        ui.progressTrack = Instance.new("Frame")
        ui.progressTrack.Position = UDim2.fromOffset(132, 86)
        ui.progressTrack.Size = UDim2.new(1, -148, 0, 5)
        ui.progressTrack.BackgroundColor3 = Color3.fromHex("273148")
        ui.progressTrack.BackgroundTransparency = 0.22
        ui.progressTrack.BorderSizePixel = 0
        ui.progressTrack.Active = true
        ui.progressTrack.ZIndex = 605
        ui.progressTrack.Parent = nowCard
        round(ui.progressTrack, 5)

        ui.progressFill = Instance.new("Frame")
        ui.progressFill.Size = UDim2.new(0, 0, 1, 0)
        ui.progressFill.BackgroundColor3 = CONFIG.Colors.Accent
        ui.progressFill.BorderSizePixel = 0
        ui.progressFill.ZIndex = 606
        ui.progressFill.Parent = ui.progressTrack
        round(ui.progressFill, 5)

        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new(CONFIG.Colors.Accent, CONFIG.Colors.Cyan)
        progressGradient.Parent = ui.progressFill

        -- Static progress dot: position follows playback, size never animates.
        ui.progressThumb = Instance.new("Frame")
        ui.progressThumb.AnchorPoint = Vector2.new(0.5, 0.5)
        ui.progressThumb.Position = UDim2.new(0, 0, 0.5, 0)
        ui.progressThumb.Size = UDim2.fromOffset(10, 10)
        ui.progressThumb.BackgroundColor3 = CONFIG.Colors.Text
        ui.progressThumb.BackgroundTransparency = 0
        ui.progressThumb.BorderSizePixel = 0
        ui.progressThumb.Active = false
        ui.progressThumb.Visible = false
        ui.progressThumb.ZIndex = 608
        ui.progressThumb.Parent = ui.progressTrack
        round(ui.progressThumb, 6)
        addStroke(ui.progressThumb, 1, 0.70, CONFIG.Colors.Edge)

        ui.progressBubble = Instance.new("Frame")
        ui.progressBubble.AnchorPoint = Vector2.new(0.5, 1)
        ui.progressBubble.Position = UDim2.new(0, 0, 0, -7)
        ui.progressBubble.Size = UDim2.fromOffset(50, 19)
        ui.progressBubble.BackgroundColor3 = CONFIG.Colors.GlassBase
        ui.progressBubble.BackgroundTransparency = 0.14
        ui.progressBubble.BorderSizePixel = 0
        ui.progressBubble.Visible = false
        ui.progressBubble.ZIndex = 612
        ui.progressBubble.Parent = ui.progressTrack
        round(ui.progressBubble, 9)
        addStroke(ui.progressBubble, 1, 0.50, CONFIG.Colors.Edge)

        ui.progressBubbleText = Instance.new("TextLabel")
        ui.progressBubbleText.Size = UDim2.fromScale(1, 1)
        ui.progressBubbleText.BackgroundTransparency = 1
        ui.progressBubbleText.Font = Enum.Font.GothamBold
        ui.progressBubbleText.Text = "00:00"
        ui.progressBubbleText.TextColor3 = CONFIG.Colors.Text
        ui.progressBubbleText.TextSize = 8
        ui.progressBubbleText.ZIndex = 613
        ui.progressBubbleText.Parent = ui.progressBubble

        ui.currentTime = Instance.new("TextLabel")
        ui.currentTime.Position = UDim2.fromOffset(132, 96)
        ui.currentTime.Size = UDim2.fromOffset(50, 14)
        ui.currentTime.BackgroundTransparency = 1
        ui.currentTime.Font = Enum.Font.GothamMedium
        ui.currentTime.Text = "00:00"
        ui.currentTime.TextColor3 = CONFIG.Colors.Muted
        ui.currentTime.TextSize = 8
        ui.currentTime.TextXAlignment = Enum.TextXAlignment.Left
        ui.currentTime.ZIndex = 605
        ui.currentTime.Parent = nowCard

        ui.totalTime = Instance.new("TextLabel")
        ui.totalTime.AnchorPoint = Vector2.new(1, 0)
        ui.totalTime.Position = UDim2.new(1, -16, 0, 96)
        ui.totalTime.Size = UDim2.fromOffset(50, 14)
        ui.totalTime.BackgroundTransparency = 1
        ui.totalTime.Font = Enum.Font.GothamMedium
        ui.totalTime.Text = "00:00"
        ui.totalTime.TextColor3 = CONFIG.Colors.Muted
        ui.totalTime.TextSize = 8
        ui.totalTime.TextXAlignment = Enum.TextXAlignment.Right
        ui.totalTime.ZIndex = 605
        ui.totalTime.Parent = nowCard

        -- Audio ID entry group.
        local idLabel = Instance.new("TextLabel")
        idLabel.Position = UDim2.fromOffset(24, 207)
        idLabel.Size = UDim2.new(1, -48, 0, 14)
        idLabel.BackgroundTransparency = 1
        idLabel.Font = Enum.Font.GothamBold
        idLabel.Text = "ROBLOX AUDIO ID"
        idLabel.TextColor3 = CONFIG.Colors.Muted
        idLabel.TextSize = 8
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.ZIndex = 606
        idLabel.Parent = ui.palette

        ui.idBox = Instance.new("TextBox")
        ui.idBox.Name = "AudioIdBox"
        ui.idBox.Position = UDim2.fromOffset(20, 226)
        ui.idBox.Size = UDim2.new(1, -174, 0, 42)
        ui.idBox.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.idBox.BackgroundTransparency = 0.62
        ui.idBox.BorderSizePixel = 0
        ui.idBox.ClearTextOnFocus = false
        ui.idBox.Font = Enum.Font.GothamMedium
        ui.idBox.PlaceholderText = "Paste audio ID or rbxassetid://..."
        ui.idBox.PlaceholderColor3 = CONFIG.Colors.Muted
        ui.idBox.Text = ""
        ui.idBox.TextColor3 = CONFIG.Colors.Text
        ui.idBox.TextSize = 10
        ui.idBox.TextXAlignment = Enum.TextXAlignment.Left
        ui.idBox.ZIndex = 606
        ui.idBox.Parent = ui.palette
        round(ui.idBox, 15)
        local idStroke = addStroke(ui.idBox, 1, 0.78, CONFIG.Colors.Edge)

        local idPadding = Instance.new("UIPadding")
        idPadding.PaddingLeft = UDim.new(0, 14)
        idPadding.PaddingRight = UDim.new(0, 10)
        idPadding.Parent = ui.idBox

        ui.loadIdButton = Instance.new("TextButton")
        ui.loadIdButton.AnchorPoint = Vector2.new(1, 0)
        ui.loadIdButton.Position = UDim2.new(1, -20, 0, 226)
        ui.loadIdButton.Size = UDim2.fromOffset(124, 42)
        ui.loadIdButton.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.loadIdButton.BackgroundTransparency = 0.50
        ui.loadIdButton.AutoButtonColor = false
        ui.loadIdButton.Font = Enum.Font.GothamBold
        ui.loadIdButton.Text = "LOAD + PLAY"
        ui.loadIdButton.TextColor3 = CONFIG.Colors.Text
        ui.loadIdButton.TextSize = 9
        ui.loadIdButton.ZIndex = 606
        ui.loadIdButton.Parent = ui.palette
        round(ui.loadIdButton, 15)
        local loadIdStroke = addStroke(ui.loadIdButton, 1, 0.42, CONFIG.Colors.Accent)

        ui.idBox.Focused:Connect(function()
            tween(idStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.38,
                Color = CONFIG.Colors.Edge,
            })
        end)
        ui.idBox.FocusLost:Connect(function()
            tween(idStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = 0.78,
                Color = CONFIG.Colors.Edge,
            })
        end)

        ui.loadIdButton.MouseEnter:Connect(function()
            playHoverSound()
            tween(ui.loadIdButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.30 })
            tween(loadIdStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.18 })
        end)
        ui.loadIdButton.MouseLeave:Connect(function()
            tween(ui.loadIdButton, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.50 })
            tween(loadIdStroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.42 })
        end)

        -- Floating transport group.
        ui.transportGlass = Instance.new("Frame")
        ui.transportGlass.Position = UDim2.fromOffset(20, 282)
        ui.transportGlass.Size = UDim2.fromOffset(206, 54)
        ui.transportGlass.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.transportGlass.BackgroundTransparency = 0.72
        ui.transportGlass.BorderSizePixel = 0
        ui.transportGlass.ZIndex = 604
        ui.transportGlass.Parent = ui.palette
        round(ui.transportGlass, 20)
        addStroke(ui.transportGlass, 1, 0.82, CONFIG.Colors.Edge)

        local function makeMusicButton(iconName, x, width, accent)
            local button = Instance.new("TextButton")
            button.Position = UDim2.fromOffset(x, 7)
            button.Size = UDim2.fromOffset(width, 40)
            button.BackgroundColor3 = CONFIG.Colors.GlassLight
            button.BackgroundTransparency = 0.66
            button.AutoButtonColor = false
            button.Text = ""
            button.ZIndex = 606
            button.Parent = ui.transportGlass
            round(button, 16)
            local stroke = addStroke(button, 1, 0.72, accent or CONFIG.Colors.Edge)

            local icon = createLucideIcon(button, iconName, 17, CONFIG.Colors.Text, 607)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.fromScale(0.5, 0.5)

            button.MouseEnter:Connect(function()
                playHoverSound()
                tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.42 })
                tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.38 })
            end)
            button.MouseLeave:Connect(function()
                tween(button, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { BackgroundTransparency = 0.66 })
                tween(stroke, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.72 })
            end)

            return button, icon, stroke
        end

        ui.playButton, ui.playIcon = makeMusicButton("play", 7, 58, CONFIG.Colors.Accent)
        do
            local stopIcon
            ui.stopButton, stopIcon = makeMusicButton("square", 73, 54, CONFIG.Colors.Danger)
        end
        ui.loopButton, ui.loopIcon, ui.loopStroke = makeMusicButton("repeat-2", 135, 54)

        ui.loopButtonScale = addScale(ui.loopButton)

        -- Repeat 1 badge: appears on the second repeat click.
        ui.loopOneBadge = Instance.new("TextLabel")
        ui.loopOneBadge.AnchorPoint = Vector2.new(0.5, 0.5)
        ui.loopOneBadge.Position = UDim2.new(1, -7, 0, 7)
        ui.loopOneBadge.Size = UDim2.fromOffset(14, 14)
        ui.loopOneBadge.BackgroundColor3 = CONFIG.Colors.Accent
        ui.loopOneBadge.BackgroundTransparency = 0.02
        ui.loopOneBadge.BorderSizePixel = 0
        ui.loopOneBadge.Font = Enum.Font.GothamBlack
        ui.loopOneBadge.Text = "1"
        ui.loopOneBadge.TextColor3 = Color3.new(1, 1, 1)
        ui.loopOneBadge.TextSize = 8
        ui.loopOneBadge.Visible = false
        ui.loopOneBadge.ZIndex = 611
        ui.loopOneBadge.Parent = ui.loopButton
        round(ui.loopOneBadge, 7)
        addStroke(ui.loopOneBadge, 1, 0.45, CONFIG.Colors.Edge)
        ui.loopOneScale = addScale(ui.loopOneBadge)

        -- Volume group.
        ui.volumeGlass = Instance.new("Frame")
        ui.volumeGlass.Position = UDim2.fromOffset(236, 282)
        ui.volumeGlass.Size = UDim2.new(1, -256, 0, 54)
        ui.volumeGlass.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.volumeGlass.BackgroundTransparency = 0.72
        ui.volumeGlass.BorderSizePixel = 0
        ui.volumeGlass.ZIndex = 604
        ui.volumeGlass.Parent = ui.palette
        round(ui.volumeGlass, 20)
        addStroke(ui.volumeGlass, 1, 0.82, CONFIG.Colors.Edge)

        local volumeIcon = createLucideIcon(ui.volumeGlass, "volume-2", 15, CONFIG.Colors.SubText, 606)
        volumeIcon.Position = UDim2.fromOffset(14, 19)

        ui.volumeText = Instance.new("TextLabel")
        ui.volumeText.Position = UDim2.fromOffset(36, 7)
        ui.volumeText.Size = UDim2.new(1, -48, 0, 14)
        ui.volumeText.BackgroundTransparency = 1
        ui.volumeText.Font = Enum.Font.GothamBold
        ui.volumeText.Text = "VOLUME 50%"
        ui.volumeText.TextColor3 = CONFIG.Colors.Muted
        ui.volumeText.TextSize = 7
        ui.volumeText.TextXAlignment = Enum.TextXAlignment.Left
        ui.volumeText.ZIndex = 606
        ui.volumeText.Parent = ui.volumeGlass

        ui.volumeTrack = Instance.new("Frame")
        ui.volumeTrack.Position = UDim2.fromOffset(36, 28)
        ui.volumeTrack.Size = UDim2.new(1, -52, 0, 7)
        ui.volumeTrack.BackgroundColor3 = Color3.fromHex("273148")
        ui.volumeTrack.BackgroundTransparency = 0.20
        ui.volumeTrack.BorderSizePixel = 0
        ui.volumeTrack.Active = true
        ui.volumeTrack.ZIndex = 606
        ui.volumeTrack.Parent = ui.volumeGlass
        round(ui.volumeTrack, 5)

        ui.volumeFill = Instance.new("Frame")
        ui.volumeFill.Size = UDim2.new(0.5, 0, 1, 0)
        ui.volumeFill.BackgroundColor3 = CONFIG.Colors.Accent
        ui.volumeFill.BorderSizePixel = 0
        ui.volumeFill.ZIndex = 607
        ui.volumeFill.Parent = ui.volumeTrack
        round(ui.volumeFill, 5)

        local volumeGradient = Instance.new("UIGradient")
        volumeGradient.Color = ColorSequence.new(CONFIG.Colors.Accent, CONFIG.Colors.Cyan)
        volumeGradient.Parent = ui.volumeFill

        -- Static volume dot: fixed size, no pulse/scale animation.
        ui.volumeThumb = Instance.new("Frame")
        ui.volumeThumb.AnchorPoint = Vector2.new(0.5, 0.5)
        ui.volumeThumb.Position = UDim2.new(0.5, 0, 0.5, 0)
        ui.volumeThumb.Size = UDim2.fromOffset(12, 12)
        ui.volumeThumb.BackgroundColor3 = CONFIG.Colors.Text
        ui.volumeThumb.BackgroundTransparency = 0
        ui.volumeThumb.BorderSizePixel = 0
        ui.volumeThumb.Active = false
        ui.volumeThumb.ZIndex = 608
        ui.volumeThumb.Parent = ui.volumeTrack
        round(ui.volumeThumb, 7)
        addStroke(ui.volumeThumb, 1, 0.68, CONFIG.Colors.Edge)

        ui.volumeBubble = Instance.new("Frame")
        ui.volumeBubble.AnchorPoint = Vector2.new(0.5, 1)
        ui.volumeBubble.Position = UDim2.new(0.5, 0, 0, -7)
        ui.volumeBubble.Size = UDim2.fromOffset(44, 19)
        ui.volumeBubble.BackgroundColor3 = CONFIG.Colors.GlassBase
        ui.volumeBubble.BackgroundTransparency = 0.14
        ui.volumeBubble.BorderSizePixel = 0
        ui.volumeBubble.Visible = false
        ui.volumeBubble.ZIndex = 612
        ui.volumeBubble.Parent = ui.volumeTrack
        round(ui.volumeBubble, 9)
        addStroke(ui.volumeBubble, 1, 0.50, CONFIG.Colors.Edge)

        ui.volumeBubbleText = Instance.new("TextLabel")
        ui.volumeBubbleText.Size = UDim2.fromScale(1, 1)
        ui.volumeBubbleText.BackgroundTransparency = 1
        ui.volumeBubbleText.Font = Enum.Font.GothamBold
        ui.volumeBubbleText.Text = "50%"
        ui.volumeBubbleText.TextColor3 = CONFIG.Colors.Text
        ui.volumeBubbleText.TextSize = 8
        ui.volumeBubbleText.ZIndex = 613
        ui.volumeBubbleText.Parent = ui.volumeBubble

        -- Playback speed glass group.
        ui.speedGlass = Instance.new("Frame")
        ui.speedGlass.Position = UDim2.fromOffset(20, 348)
        ui.speedGlass.Size = UDim2.new(1, -40, 0, 52)
        ui.speedGlass.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.speedGlass.BackgroundTransparency = 0.74
        ui.speedGlass.BorderSizePixel = 0
        ui.speedGlass.ZIndex = 604
        ui.speedGlass.Parent = ui.palette
        round(ui.speedGlass, 20)
        ui.speedGlassStroke = addStroke(ui.speedGlass, 1, 0.82, CONFIG.Colors.Edge)

        local speedTitle = Instance.new("TextLabel")
        speedTitle.Position = UDim2.fromOffset(16, 7)
        speedTitle.Size = UDim2.fromOffset(110, 16)
        speedTitle.BackgroundTransparency = 1
        speedTitle.Font = Enum.Font.GothamBold
        speedTitle.Text = "PLAYBACK SPEED"
        speedTitle.TextColor3 = CONFIG.Colors.SubText
        speedTitle.TextSize = 8
        speedTitle.TextXAlignment = Enum.TextXAlignment.Left
        speedTitle.ZIndex = 606
        speedTitle.Parent = ui.speedGlass

        local speedHint = Instance.new("TextLabel")
        speedHint.Position = UDim2.fromOffset(16, 24)
        speedHint.Size = UDim2.fromOffset(150, 14)
        speedHint.BackgroundTransparency = 1
        speedHint.Font = Enum.Font.GothamMedium
        speedHint.Text = "0.50× — 2.00×"
        speedHint.TextColor3 = CONFIG.Colors.Muted
        speedHint.TextSize = 7
        speedHint.TextXAlignment = Enum.TextXAlignment.Left
        speedHint.ZIndex = 606
        speedHint.Parent = ui.speedGlass

        local speedControl = Instance.new("Frame")
        speedControl.AnchorPoint = Vector2.new(1, 0.5)
        speedControl.Position = UDim2.new(1, -10, 0.5, 0)
        speedControl.Size = UDim2.fromOffset(188, 38)
        speedControl.BackgroundColor3 = CONFIG.Colors.GlassBase
        speedControl.BackgroundTransparency = 0.42
        speedControl.BorderSizePixel = 0
        speedControl.ZIndex = 606
        speedControl.Parent = ui.speedGlass
        round(speedControl, 19)
        addStroke(speedControl, 1, 0.72, CONFIG.Colors.Edge)

        ui.speedDown = Instance.new("TextButton")
        ui.speedDown.Position = UDim2.fromOffset(4, 4)
        ui.speedDown.Size = UDim2.fromOffset(38, 30)
        ui.speedDown.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.speedDown.BackgroundTransparency = 0.70
        ui.speedDown.AutoButtonColor = false
        ui.speedDown.Text = ""
        ui.speedDown.ZIndex = 607
        ui.speedDown.Parent = speedControl
        round(ui.speedDown, 15)
        local speedDownIcon = createLucideIcon(ui.speedDown, "minus", 14, CONFIG.Colors.Text, 608)
        speedDownIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        speedDownIcon.Position = UDim2.fromScale(0.5, 0.5)

        ui.speedValue = Instance.new("TextButton")
        ui.speedValue.Position = UDim2.fromOffset(48, 4)
        ui.speedValue.Size = UDim2.fromOffset(92, 30)
        ui.speedValue.BackgroundTransparency = 1
        ui.speedValue.AutoButtonColor = false
        ui.speedValue.Font = Enum.Font.GothamBlack
        ui.speedValue.Text = "1.00×"
        ui.speedValue.TextColor3 = CONFIG.Colors.Text
        ui.speedValue.TextSize = 12
        ui.speedValue.ZIndex = 607
        ui.speedValue.Parent = speedControl

        ui.speedUp = Instance.new("TextButton")
        ui.speedUp.Position = UDim2.fromOffset(146, 4)
        ui.speedUp.Size = UDim2.fromOffset(38, 30)
        ui.speedUp.BackgroundColor3 = CONFIG.Colors.GlassLight
        ui.speedUp.BackgroundTransparency = 0.70
        ui.speedUp.AutoButtonColor = false
        ui.speedUp.Text = ""
        ui.speedUp.ZIndex = 607
        ui.speedUp.Parent = speedControl
        round(ui.speedUp, 15)

        ui.speedBubble = Instance.new("Frame")
        ui.speedBubble.AnchorPoint = Vector2.new(0.5, 1)
        ui.speedBubble.Position = UDim2.new(0.5, 0, 0, -4)
        ui.speedBubble.Size = UDim2.fromOffset(56, 20)
        ui.speedBubble.BackgroundColor3 = CONFIG.Colors.GlassBase
        ui.speedBubble.BackgroundTransparency = 0.14
        ui.speedBubble.BorderSizePixel = 0
        ui.speedBubble.Visible = false
        ui.speedBubble.ZIndex = 612
        ui.speedBubble.Parent = speedControl
        round(ui.speedBubble, 9)
        addStroke(ui.speedBubble, 1, 0.50, CONFIG.Colors.Edge)

        ui.speedBubbleText = Instance.new("TextLabel")
        ui.speedBubbleText.Size = UDim2.fromScale(1, 1)
        ui.speedBubbleText.BackgroundTransparency = 1
        ui.speedBubbleText.Font = Enum.Font.GothamBold
        ui.speedBubbleText.Text = "1.00×"
        ui.speedBubbleText.TextColor3 = CONFIG.Colors.Text
        ui.speedBubbleText.TextSize = 8
        ui.speedBubbleText.ZIndex = 613
        ui.speedBubbleText.Parent = ui.speedBubble
        ui.speedBubbleToken = 0

        local speedUpIcon = createLucideIcon(ui.speedUp, "plus", 14, CONFIG.Colors.Text, 608)
        speedUpIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        speedUpIcon.Position = UDim2.fromScale(0.5, 0.5)

        ui.sound = Instance.new("Sound")
        ui.sound.Name = "SaltyMusicPlayerSound"
        ui.sound.Volume = 0.5
        ui.sound.Looped = false
        ui.sound.PlaybackSpeed = 1
        ui.sound.Parent = SoundService

        -- repeatMode: 0 = off, 1 = repeat, 2 = repeat one
        local repeatMode = 0
        local musicOpen = false
        local volumeDragging = false
        local progressDragging = false
        local loadedNumericId = nil
        local lastMissingIdNotification = 0
        local playbackSpeed = 1

        local function formatTime(seconds)
            seconds = math.max(0, math.floor(seconds or 0))
            return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
        end

        local function normalizeAudioId(raw)
            raw = tostring(raw or "")
            raw = string.gsub(raw, "%s+", "")
            if raw == "" then
                return nil
            end

            local numeric = string.match(raw, "^rbxassetid://(%d+)$")
                or string.match(raw, "^https?://www%.roblox%.com/library/(%d+)")
                or string.match(raw, "^https?://create%.roblox%.com/store/asset/(%d+)")
                or string.match(raw, "(%d+)")

            if not numeric or numeric == "" then
                return nil
            end

            return "rbxassetid://" .. numeric, numeric
        end

        local function setPlaybackSpeed(value)
            playbackSpeed = math.clamp(math.floor(value * 100 + 0.5) / 100, 0.50, 2.00)
            ui.sound.PlaybackSpeed = playbackSpeed
            ui.speedValue.Text = string.format("%.2f×", playbackSpeed)

            tween(ui.speedGlassStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = playbackSpeed == 1 and 0.82 or 0.48,
                Color = CONFIG.Colors.Edge,
            })
        end

        local function showSpeedBubble()
            ui.speedBubbleToken += 1
            local token = ui.speedBubbleToken

            ui.speedBubble.Visible = true
            ui.speedBubbleText.Text = ui.speedValue.Text
            ui.speedBubble.BackgroundTransparency = 0.14
            ui.speedBubbleText.TextTransparency = 0

            task.delay(0.72, function()
                if token ~= ui.speedBubbleToken or not ui.speedBubble.Parent then
                    return
                end

                if premiumFx.reduceMotion then
                    ui.speedBubble.Visible = false
                    return
                end

                tween(ui.speedBubble, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    BackgroundTransparency = 1,
                })
                tween(ui.speedBubbleText, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                    TextTransparency = 1,
                })

                task.delay(0.13, function()
                    if token == ui.speedBubbleToken and ui.speedBubble.Parent then
                        ui.speedBubble.Visible = false
                        ui.speedBubble.BackgroundTransparency = 0.14
                        ui.speedBubbleText.TextTransparency = 0
                    end
                end)
            end)
        end

        local function repeatText()
            if repeatMode == 2 then
                return " • REPEAT 1"
            elseif repeatMode == 1 then
                return " • REPEAT"
            end
            return ""
        end

        local function setPlayingUI(playing)
            renderLucideIcon(ui.playIcon, playing and "pause" or "play", CONFIG.Colors.Text)
            premiumFx.setMusicPlaying(playing)

            if playing then
                ui.stateLabel.Text = "PLAYING" .. repeatText() .. " • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Success
            else
                ui.stateLabel.Text = "PAUSED" .. repeatText() .. " • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Warning
            end
        end

        local function playCurrent()
            if not loadedNumericId or ui.sound.SoundId == "" then
                ui.stateLabel.Text = "WAITING FOR ID"
                ui.stateLabel.TextColor3 = CONFIG.Colors.Warning

                local now = os.clock()
                if now - lastMissingIdNotification > 1.2 then
                    lastMissingIdNotification = now
                    showNotification("Paste a Roblox audio ID, then press LOAD + PLAY.", 2.6, "warning")
                end
                return
            end

            ui.sound.PlaybackSpeed = playbackSpeed
            ui.sound.Looped = repeatMode > 0
            ui.sound:Play()
            setPlayingUI(true)
            premiumFx.showStatus(
                "music",
                "Now playing",
                "Audio " .. tostring(loadedNumericId) .. " • " .. ui.speedValue.Text,
                1.35,
                CONFIG.Colors.Accent
            )

            task.delay(1.2, function()
                if ui.sound.Parent and loadedNumericId and not ui.sound.IsPlaying and ui.sound.TimeLength <= 0 then
                    ui.stateLabel.Text = "CHECK AUDIO ID / PERMISSION"
                    ui.stateLabel.TextColor3 = CONFIG.Colors.Danger
                    renderLucideIcon(ui.playIcon, "play", CONFIG.Colors.Text)
                    premiumFx.setMusicPlaying(false)
                end
            end)
        end

        local function applyInsertedAudioId(autoPlay)
            local normalized, numeric = normalizeAudioId(ui.idBox.Text)
            if not normalized then
                ui.stateLabel.Text = "INVALID AUDIO ID"
                ui.stateLabel.TextColor3 = CONFIG.Colors.Danger
                showNotification("Enter a valid Roblox audio asset ID.", 2.6, "danger")
                return
            end

            ui.sound:Stop()
            premiumFx.setMusicPlaying(false)
            ui.sound.SoundId = normalized
            ui.sound.PlaybackSpeed = playbackSpeed
            loadedNumericId = numeric
            ui.idBox.Text = numeric
            ui.trackName.Text = "Audio " .. numeric
            ui.artistName.Text = "Custom Roblox Audio"
            ui.stateLabel.Text = "READY • " .. ui.speedValue.Text
            ui.stateLabel.TextColor3 = CONFIG.Colors.Success
            ui.currentTime.Text = "00:00"
            ui.totalTime.Text = "00:00"
            ui.progressFill.Size = UDim2.new(0, 0, 1, 0)
            ui.progressThumb.Position = UDim2.new(0, 0, 0.5, 0)
            ui.progressThumb.Visible = true
            renderLucideIcon(ui.playIcon, "play", CONFIG.Colors.Text)

            if autoPlay then
                playCurrent()
            end
        end

        local function pauseCurrent()
            ui.sound:Pause()
            setPlayingUI(false)
            premiumFx.showStatus(
                "pause",
                "Music paused",
                loadedNumericId and ("Audio " .. loadedNumericId) or "Custom audio",
                1.00,
                CONFIG.Colors.Warning
            )
        end

        local function stopCurrent()
            ui.sound:Stop()
            renderLucideIcon(ui.playIcon, "play", CONFIG.Colors.Text)
            ui.stateLabel.Text = loadedNumericId and ("STOPPED • " .. ui.speedValue.Text) or "WAITING FOR ID"
            ui.stateLabel.TextColor3 = loadedNumericId and CONFIG.Colors.Muted or CONFIG.Colors.Warning
            ui.currentTime.Text = "00:00"
            ui.progressFill.Size = UDim2.new(0, 0, 1, 0)
            ui.progressThumb.Position = UDim2.new(0, 0, 0.5, 0)
            premiumFx.setMusicPlaying(false)

            if loadedNumericId then
                premiumFx.showStatus("square", "Music stopped", "Audio " .. loadedNumericId, 0.95, CONFIG.Colors.Muted)
            end
        end

        local function setRepeatMode(mode)
            repeatMode = mode % 3
            ui.sound.Looped = repeatMode > 0

            local enabled = repeatMode > 0
            local repeatOne = repeatMode == 2

            ui.loopOneBadge.Visible = repeatOne

            if repeatOne then
                ui.loopOneScale.Scale = 0.35
                tween(ui.loopOneScale, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                    Scale = 1,
                })
            end

            ui.loopButtonScale.Scale = 0.92
            tween(ui.loopButtonScale, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Scale = 1,
            })

            tween(ui.loopButton, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = enabled and 0.38 or 0.66,
            })

            tween(ui.loopStroke, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Transparency = enabled and 0.22 or 0.72,
                Color = CONFIG.Colors.Edge,
            })

            ui.loopIcon.ImageColor3 = enabled and CONFIG.Colors.Accent or CONFIG.Colors.Text

            if ui.sound.IsPlaying then
                setPlayingUI(true)
            elseif loadedNumericId then
                if repeatMode == 2 then
                    ui.stateLabel.Text = "REPEAT 1 • " .. ui.speedValue.Text
                    ui.stateLabel.TextColor3 = CONFIG.Colors.Accent
                elseif repeatMode == 1 then
                    ui.stateLabel.Text = "REPEAT ON • " .. ui.speedValue.Text
                    ui.stateLabel.TextColor3 = CONFIG.Colors.Accent
                else
                    ui.stateLabel.Text = "READY • " .. ui.speedValue.Text
                    ui.stateLabel.TextColor3 = CONFIG.Colors.Success
                end
            else
                ui.stateLabel.Text = "WAITING FOR ID"
                ui.stateLabel.TextColor3 = CONFIG.Colors.Warning
            end

            if repeatMode == 2 then
                premiumFx.showStatus("repeat-2", "Repeat 1", "Current audio", 0.95, CONFIG.Colors.Accent)
            elseif repeatMode == 1 then
                premiumFx.showStatus("repeat-2", "Repeat on", "Loop current audio", 0.95, CONFIG.Colors.Accent)
            elseif loadedNumericId then
                premiumFx.showStatus("repeat-2", "Repeat off", "Normal playback", 0.85, CONFIG.Colors.Muted)
            end
        end

        local function updateVolumeFromX(x)
            local width = ui.volumeTrack.AbsoluteSize.X
            if width <= 0 then
                return
            end

            local ratio = math.clamp((x - ui.volumeTrack.AbsolutePosition.X) / width, 0, 1)
            ui.sound.Volume = ratio
            ui.volumeFill.Size = UDim2.new(ratio, 0, 1, 0)
            ui.volumeThumb.Position = UDim2.new(ratio, 0, 0.5, 0)
            ui.volumeText.Text = "VOLUME " .. tostring(math.floor(ratio * 100 + 0.5)) .. "%"

            if volumeDragging then
                ui.volumeBubble.Visible = true
                ui.volumeBubble.Position = UDim2.new(ratio, 0, 0, -7)
                ui.volumeBubbleText.Text = tostring(math.floor(ratio * 100 + 0.5)) .. "%"
            end
        end

        local function seekFromX(x)
            if ui.sound.TimeLength <= 0 then
                return
            end

            local width = ui.progressTrack.AbsoluteSize.X
            if width <= 0 then
                return
            end

            local ratio = math.clamp((x - ui.progressTrack.AbsolutePosition.X) / width, 0, 1)
            ui.sound.TimePosition = ui.sound.TimeLength * ratio

            if progressDragging then
                ui.progressBubble.Visible = true
                ui.progressBubble.Position = UDim2.new(ratio, 0, 0, -7)
                ui.progressBubbleText.Text = formatTime(ui.sound.TimeLength * ratio)
            end
        end

        ui.loadIdButton.MouseButton1Click:Connect(function()
            playClickSound()
            applyInsertedAudioId(true)
        end)

        ui.idBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                applyInsertedAudioId(true)
            end
        end)

        ui.playButton.MouseButton1Click:Connect(function()
            playClickSound()
            if ui.sound.IsPlaying then
                pauseCurrent()
            else
                playCurrent()
            end
        end)

        ui.stopButton.MouseButton1Click:Connect(function()
            playClickSound()
            stopCurrent()
        end)

        ui.loopButton.MouseButton1Click:Connect(function()
            playClickSound()
            setRepeatMode(repeatMode + 1)
        end)

        ui.speedDown.MouseButton1Click:Connect(function()
            playClickSound()
            setPlaybackSpeed(playbackSpeed - 0.10)
            showSpeedBubble()
            premiumFx.showStatus("music", "Playback speed", ui.speedValue.Text, 0.85, CONFIG.Colors.Accent)
            if ui.sound.IsPlaying then
                setPlayingUI(true)
            elseif loadedNumericId then
                ui.stateLabel.Text = "READY • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Success
            end
        end)

        ui.speedUp.MouseButton1Click:Connect(function()
            playClickSound()
            setPlaybackSpeed(playbackSpeed + 0.10)
            showSpeedBubble()
            premiumFx.showStatus("music", "Playback speed", ui.speedValue.Text, 0.85, CONFIG.Colors.Accent)
            if ui.sound.IsPlaying then
                setPlayingUI(true)
            elseif loadedNumericId then
                ui.stateLabel.Text = "READY • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Success
            end
        end)

        ui.speedValue.MouseButton1Click:Connect(function()
            playClickSound()
            setPlaybackSpeed(1)
            showSpeedBubble()
            premiumFx.showStatus("music", "Playback speed", "Reset to " .. ui.speedValue.Text, 0.85, CONFIG.Colors.Accent)
            if ui.sound.IsPlaying then
                setPlayingUI(true)
            elseif loadedNumericId then
                ui.stateLabel.Text = "READY • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Success
            end
        end)

        ui.progressTrack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                progressDragging = true
                ui.progressBubble.Visible = true
                seekFromX(input.Position.X)
            end
        end)

        ui.volumeTrack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                volumeDragging = true
                ui.volumeBubble.Visible = true
                updateVolumeFromX(input.Position.X)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if progressDragging then
                    seekFromX(input.Position.X)
                end
                if volumeDragging then
                    updateVolumeFromX(input.Position.X)
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                progressDragging = false
                volumeDragging = false
                ui.progressBubble.Visible = false
                ui.volumeBubble.Visible = false
            end
        end)

        ui.sound.Ended:Connect(function()
            if repeatMode == 0 then
                renderLucideIcon(ui.playIcon, "play", CONFIG.Colors.Text)
                ui.stateLabel.Text = "FINISHED • " .. ui.speedValue.Text
                ui.stateLabel.TextColor3 = CONFIG.Colors.Muted
                premiumFx.setMusicPlaying(false)
                premiumFx.showStatus("music", "Playback finished", "Custom audio", 1.00, CONFIG.Colors.Muted)
            end
        end)

        local liveMotionTime = 0

        RunService.RenderStepped:Connect(function(dt)
            liveMotionTime += dt

            if ui.sound.TimeLength > 0 then
                local ratio = math.clamp(ui.sound.TimePosition / ui.sound.TimeLength, 0, 1)

                if not progressDragging then
                    ui.progressFill.Size = UDim2.new(ratio, 0, 1, 0)
                    ui.progressThumb.Position = UDim2.new(ratio, 0, 0.5, 0)
                end

                ui.progressThumb.Visible = loadedNumericId ~= nil
                ui.currentTime.Text = formatTime(ui.sound.TimePosition)
                ui.totalTime.Text = formatTime(ui.sound.TimeLength)
            else
                ui.progressThumb.Visible = false
            end

            if musicOpen then
                if premiumFx.reduceMotion then
                    ui.paletteStrokeGradient.Rotation = 24
                    ui.specularGradient.Offset = Vector2.zero
                else
                    -- Subtle glass motion only; no decorative glow blobs.
                    ui.paletteStrokeGradient.Rotation = 24 + math.sin(liveMotionTime * 0.22) * 10
                    ui.specularGradient.Offset = Vector2.new(math.sin(liveMotionTime * 0.28) * 0.28, 0)
                end
            end
        end)

        local function openMusicPalette()
            if musicOpen then
                return
            end

            musicOpen = true
            ui.musicOverlay.Visible = true
            ui.backdrop.BackgroundTransparency = 1
            ui.paletteScale.Scale = 0.94
            ui.palette.Position = UDim2.new(0.5, 0, 0.14, -10)
            ui.palette.BackgroundTransparency = 0.20
            ui.transportGlass.Position = UDim2.fromOffset(20, 290)
            ui.volumeGlass.Position = UDim2.fromOffset(236, 290)
            ui.speedGlass.Position = UDim2.fromOffset(20, 356)

            tween(ui.backdrop, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0.18,
            })
            tween(musicBlur, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Size = 32,
            })
            tween(ui.paletteScale, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Scale = 1,
            })
            tween(ui.palette, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.new(0.5, 0, 0.14, 0),
                BackgroundTransparency = 0.08,
            })
            tween(ui.transportGlass, 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.fromOffset(20, 282),
            })
            tween(ui.volumeGlass, 0.29, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.fromOffset(236, 282),
            })
            tween(ui.speedGlass, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.fromOffset(20, 348),
            })
        end

        local function closeMusicPalette()
            if not musicOpen then
                return
            end

            musicOpen = false
            progressDragging = false
            volumeDragging = false
            ui.idBox:ReleaseFocus()

            tween(ui.backdrop, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                BackgroundTransparency = 1,
            })
            tween(musicBlur, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                Size = 0,
            })
            tween(ui.paletteScale, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                Scale = 0.96,
            })
            tween(ui.palette, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
                Position = UDim2.new(0.5, 0, 0.14, -8),
                BackgroundTransparency = 0.22,
            })

            task.delay(0.17, function()
                if not musicOpen and ui.musicOverlay.Parent then
                    ui.musicOverlay.Visible = false

                    if ui.sound.IsPlaying and loadedNumericId then
                        premiumFx.showStatus(
                            "music",
                            "Now playing",
                            "Audio " .. tostring(loadedNumericId) .. " • " .. ui.speedValue.Text,
                            1.30,
                            CONFIG.Colors.Accent
                        )
                    end
                end
            end)
        end

        ui.close.MouseButton1Click:Connect(function()
            playClickSound()
            closeMusicPalette()
        end)

        musicPlayer.Open = openMusicPalette
        musicPlayer.Close = closeMusicPalette
        musicPlayer.Toggle = function()
            if musicOpen then
                closeMusicPalette()
            else
                openMusicPalette()
            end
        end
        musicPlayer.Play = playCurrent
        musicPlayer.Pause = pauseCurrent
        musicPlayer.Stop = stopCurrent
        musicPlayer.SetSpeed = setPlaybackSpeed
        musicPlayer.SetRepeatMode = setRepeatMode
        musicPlayer.Shutdown = function()
            musicOpen = false
            progressDragging = false
            volumeDragging = false
            premiumFx.setMusicPlaying(false)

            pcall(function()
                ui.idBox:ReleaseFocus()
            end)
            pcall(function()
                ui.sound:Stop()
                ui.sound.Volume = 0
                ui.sound.PlaybackSpeed = 1
            end)

            if ui.sound.Parent then
                ui.sound:Destroy()
            end
            if musicBlur and musicBlur.Parent then
                musicBlur.Size = 0
            end
            if ui.musicOverlay and ui.musicOverlay.Parent then
                ui.musicOverlay.Visible = false
            end
        end

        setPlaybackSpeed(1)
        setRepeatMode(0)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if isShuttingDown then
            return
        end

        local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

        if input.KeyCode == Enum.KeyCode.M and ctrlDown then
            if musicPlayer and musicPlayer.Toggle then
                musicPlayer.Toggle()
            end
            return
        end


        if gameProcessed then
            return
        end

        if input.KeyCode == CONFIG.ToggleKey then
            if isMinimized then
                restorePanel()
            else
                setVisible(not isOpen)
            end
        end
    end)

    -- Subtle idle breathing.
    task.spawn(function()
        while mainFrame.Parent do
            if premiumFx.reduceMotion then
                innerBorder.Position = UDim2.fromOffset(1, 1)
                task.wait(0.35)
            elseif mainFrame.Visible and not isMinimized then
                tween(innerBorder, 2.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Position = UDim2.fromOffset(1.5, 1.5) })
                task.wait(2.3)
                if not premiumFx.reduceMotion then
                    tween(innerBorder, 2.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Position = UDim2.fromOffset(1, 1) })
                    task.wait(2.3)
                end
            else
                task.wait(0.5)
            end
        end
    end)

    -- Clean, fast intro animation.
    -- Reduce Motion can be remembered across script rebuilds in this client session.
    selectTab("Home")

    titleBar.Visible = true
    tabRail.Visible = true
    divider.Visible = true
    contentArea.Visible = true
    tabIndicator.Visible = true
    tabGlow.Visible = true
    playerCard.Visible = true

    mainFrame.Visible = true
    mainFrame.Size = openSize
    mainFrame.BackgroundTransparency = 0.08
    mainScale.Scale = 1
    setBlur(true)

    if premiumFx.reduceMotion then
        title.TextTransparency = 0
        premiumFx.titleGhostA.TextTransparency = 1
        premiumFx.titleGhostB.TextTransparency = 1
        mainFrame.Position = openPosition
        mainStroke.Transparency = 0.45
        innerStroke.Transparency = 0.84

        premiumFx.titleGhostA:Destroy()
        premiumFx.titleGhostB:Destroy()

        task.delay(0.05, function()
            if screenGui.Parent and not isShuttingDown then
                premiumFx.showStatus("home", "Salty ready", "Reduced motion", 1.25, CONFIG.Colors.Success)
            end
        end)
    else
        -- SALTY sharpens from two faint 2px ghost layers into the crisp title.
        title.TextTransparency = 0.20
        premiumFx.titleGhostA.TextTransparency = 0.68
        premiumFx.titleGhostB.TextTransparency = 0.68

        mainFrame.Position = UDim2.new(
            openPosition.X.Scale, openPosition.X.Offset,
            openPosition.Y.Scale - 0.018, openPosition.Y.Offset
        )
        mainFrame.BackgroundTransparency = 0.16
        mainScale.Scale = 0.965
        mainStroke.Transparency = 0.72
        innerStroke.Transparency = 0.92

        tween(mainScale, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Scale = 1 })
        tween(mainFrame, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Position = openPosition,
            BackgroundTransparency = 0.08,
        })
        tween(mainStroke, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.45 })
        tween(innerStroke, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Transparency = 0.84 })

        tween(title, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 0,
        })
        tween(premiumFx.titleGhostA, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 1,
            Position = title.Position,
        })
        tween(premiumFx.titleGhostB, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            TextTransparency = 1,
            Position = title.Position,
        })

        task.delay(0.20, function()
            if premiumFx.titleGhostA and premiumFx.titleGhostA.Parent then
                premiumFx.titleGhostA:Destroy()
            end
            if premiumFx.titleGhostB and premiumFx.titleGhostB.Parent then
                premiumFx.titleGhostB:Destroy()
            end

            if screenGui.Parent and not isShuttingDown then
                premiumFx.showStatus("home", "Salty ready", "Release candidate", 1.45, CONFIG.Colors.Success)
            end
        end)
    end

    return screenGui
end

return SaltyGlass
