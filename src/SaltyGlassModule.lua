local SaltyGlass = { Version = "3.6.3 RC" }

function SaltyGlass.Start()
    -- SaltyGlass v3.6.3 RC — GitHub Distribution Build
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
    screenGui:SetAttribute("UISoundsEnabled", premiumFx.uiSoundsEnabled)
    screenGui:SetAttribute("LucideCatalogCount", 1716)
    screenGui:SetAttribute("LucideCatalogSource", "icons/Lucide.lua")

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
        ["a-arrow-down"] = "rbxassetid://92867583610071",
        ["a-arrow-up"] = "rbxassetid://132318504999733",
        ["a-large-small"] = "rbxassetid://111491496660216",
        ["accessibility"] = "rbxassetid://114029945302017",
        ["activity"] = "rbxassetid://94212016861936",
        ["air-vent"] = "rbxassetid://81517226012329",
        ["airplay"] = "rbxassetid://115020759309179",
        ["alarm-clock"] = "rbxassetid://126259032907535",
        ["alarm-clock-check"] = "rbxassetid://76437352099157",
        ["alarm-clock-minus"] = "rbxassetid://77364179863205",
        ["alarm-clock-off"] = "rbxassetid://97904885874823",
        ["alarm-clock-plus"] = "rbxassetid://80468822979214",
        ["alarm-smoke"] = "rbxassetid://96965448419685",
        ["album"] = "rbxassetid://127358331163602",
        ["align-center-horizontal"] = "rbxassetid://81570549209434",
        ["align-center-vertical"] = "rbxassetid://118470463752466",
        ["align-end-horizontal"] = "rbxassetid://139502909745427",
        ["align-end-vertical"] = "rbxassetid://96528869059554",
        ["align-horizontal-distribute-center"] = "rbxassetid://97220086126656",
        ["align-horizontal-distribute-end"] = "rbxassetid://106128590702022",
        ["align-horizontal-distribute-start"] = "rbxassetid://76074660002997",
        ["align-horizontal-justify-center"] = "rbxassetid://75732302772427",
        ["align-horizontal-justify-end"] = "rbxassetid://129167626402283",
        ["align-horizontal-justify-start"] = "rbxassetid://130161830325281",
        ["align-horizontal-space-around"] = "rbxassetid://91646106782950",
        ["align-horizontal-space-between"] = "rbxassetid://103886093046990",
        ["align-start-horizontal"] = "rbxassetid://125674804697729",
        ["align-start-vertical"] = "rbxassetid://105020230154823",
        ["align-vertical-distribute-center"] = "rbxassetid://93791183635525",
        ["align-vertical-distribute-end"] = "rbxassetid://139354223511433",
        ["align-vertical-distribute-start"] = "rbxassetid://74961997822126",
        ["align-vertical-justify-center"] = "rbxassetid://134754696166569",
        ["align-vertical-justify-end"] = "rbxassetid://92569381441969",
        ["align-vertical-justify-start"] = "rbxassetid://99692844572718",
        ["align-vertical-space-around"] = "rbxassetid://96206012459190",
        ["align-vertical-space-between"] = "rbxassetid://124998077349706",
        ["ambulance"] = "rbxassetid://78599995190651",
        ["ampersand"] = "rbxassetid://75272915739209",
        ["ampersands"] = "rbxassetid://126947193455996",
        ["amphora"] = "rbxassetid://137370389604364",
        ["anchor"] = "rbxassetid://92181172123618",
        ["angry"] = "rbxassetid://74237056000103",
        ["annoyed"] = "rbxassetid://80064369052011",
        ["antenna"] = "rbxassetid://99628923540956",
        ["anvil"] = "rbxassetid://100203029845919",
        ["aperture"] = "rbxassetid://83396154449972",
        ["app-window"] = "rbxassetid://93142176757189",
        ["app-window-mac"] = "rbxassetid://79587216113811",
        ["apple"] = "rbxassetid://104349242902442",
        ["archive"] = "rbxassetid://122180020814574",
        ["archive-restore"] = "rbxassetid://78956681942188",
        ["archive-x"] = "rbxassetid://75830115088395",
        ["armchair"] = "rbxassetid://105384358373973",
        ["arrow-big-down"] = "rbxassetid://81081164158885",
        ["arrow-big-down-dash"] = "rbxassetid://137987229582002",
        ["arrow-big-left"] = "rbxassetid://85973092492641",
        ["arrow-big-left-dash"] = "rbxassetid://97827621354677",
        ["arrow-big-right"] = "rbxassetid://82960676755590",
        ["arrow-big-right-dash"] = "rbxassetid://117825834972403",
        ["arrow-big-up"] = "rbxassetid://93136954756149",
        ["arrow-big-up-dash"] = "rbxassetid://99260194327483",
        ["arrow-down"] = "rbxassetid://98764963621439",
        ["arrow-down-0-1"] = "rbxassetid://120961896217875",
        ["arrow-down-1-0"] = "rbxassetid://93474255891850",
        ["arrow-down-a-z"] = "rbxassetid://99554596207900",
        ["arrow-down-from-line"] = "rbxassetid://132045845807798",
        ["arrow-down-left"] = "rbxassetid://102899325237364",
        ["arrow-down-narrow-wide"] = "rbxassetid://129105261655061",
        ["arrow-down-right"] = "rbxassetid://123109928624974",
        ["arrow-down-to-dot"] = "rbxassetid://101675355931221",
        ["arrow-down-to-line"] = "rbxassetid://87050478931254",
        ["arrow-down-up"] = "rbxassetid://85780258549577",
        ["arrow-down-wide-narrow"] = "rbxassetid://88461733425991",
        ["arrow-down-z-a"] = "rbxassetid://76115279362232",
        ["arrow-left"] = "rbxassetid://102531941843733",
        ["arrow-left-from-line"] = "rbxassetid://87857914437603",
        ["arrow-left-right"] = "rbxassetid://131324733048447",
        ["arrow-left-to-line"] = "rbxassetid://118645136026970",
        ["arrow-right"] = "rbxassetid://113692007244654",
        ["arrow-right-from-line"] = "rbxassetid://74073639809355",
        ["arrow-right-left"] = "rbxassetid://77015754304300",
        ["arrow-right-to-line"] = "rbxassetid://78632510329852",
        ["arrow-up"] = "rbxassetid://89282378235317",
        ["arrow-up-0-1"] = "rbxassetid://105257823943016",
        ["arrow-up-1-0"] = "rbxassetid://134175521693798",
        ["arrow-up-a-z"] = "rbxassetid://77763416595160",
        ["arrow-up-down"] = "rbxassetid://81019887641527",
        ["arrow-up-from-dot"] = "rbxassetid://124408496673275",
        ["arrow-up-from-line"] = "rbxassetid://95777664626453",
        ["arrow-up-left"] = "rbxassetid://123490598231261",
        ["arrow-up-narrow-wide"] = "rbxassetid://73006024672636",
        ["arrow-up-right"] = "rbxassetid://129280608535523",
        ["arrow-up-to-line"] = "rbxassetid://108818207813537",
        ["arrow-up-wide-narrow"] = "rbxassetid://87437426951568",
        ["arrow-up-z-a"] = "rbxassetid://107546173611884",
        ["arrows-up-from-line"] = "rbxassetid://133710016938621",
        ["asterisk"] = "rbxassetid://88552752106723",
        ["at-sign"] = "rbxassetid://79059152889146",
        ["atom"] = "rbxassetid://73167696981648",
        ["audio-lines"] = "rbxassetid://70930641819242",
        ["audio-waveform"] = "rbxassetid://86462036665209",
        ["award"] = "rbxassetid://132740088158419",
        ["axe"] = "rbxassetid://132405197863294",
        ["axis-3d"] = "rbxassetid://122438676546804",
        ["baby"] = "rbxassetid://93472926933440",
        ["backpack"] = "rbxassetid://140420225386018",
        ["badge"] = "rbxassetid://116620312917084",
        ["badge-alert"] = "rbxassetid://101829200081951",
        ["badge-cent"] = "rbxassetid://133345018873154",
        ["badge-check"] = "rbxassetid://76078495178149",
        ["badge-dollar-sign"] = "rbxassetid://127139803581141",
        ["badge-euro"] = "rbxassetid://120016477674659",
        ["badge-indian-rupee"] = "rbxassetid://75659682309981",
        ["badge-info"] = "rbxassetid://131995373201472",
        ["badge-japanese-yen"] = "rbxassetid://99081574588615",
        ["badge-minus"] = "rbxassetid://140321561183881",
        ["badge-percent"] = "rbxassetid://121359224294885",
        ["badge-plus"] = "rbxassetid://100325578561866",
        ["badge-pound-sterling"] = "rbxassetid://119688217279444",
        ["badge-question-mark"] = "rbxassetid://121464963737502",
        ["badge-russian-ruble"] = "rbxassetid://108839463659864",
        ["badge-swiss-franc"] = "rbxassetid://91447608372740",
        ["badge-turkish-lira"] = "rbxassetid://137839965873529",
        ["badge-x"] = "rbxassetid://122931434733842",
        ["baggage-claim"] = "rbxassetid://86922213051957",
        ["balloon"] = "rbxassetid://97489111621526",
        ["ban"] = "rbxassetid://90767043015246",
        ["banana"] = "rbxassetid://140713420056179",
        ["bandage"] = "rbxassetid://129660129590770",
        ["banknote"] = "rbxassetid://104840231536668",
        ["banknote-arrow-down"] = "rbxassetid://139366449345199",
        ["banknote-arrow-up"] = "rbxassetid://133758343082529",
        ["banknote-x"] = "rbxassetid://95348701438065",
        ["barcode"] = "rbxassetid://118473018143689",
        ["barrel"] = "rbxassetid://130647115622774",
        ["baseline"] = "rbxassetid://124677132511270",
        ["bath"] = "rbxassetid://76031400297942",
        ["battery"] = "rbxassetid://70765800346189",
        ["battery-charging"] = "rbxassetid://80139357470047",
        ["battery-full"] = "rbxassetid://70906718268972",
        ["battery-low"] = "rbxassetid://139659256984314",
        ["battery-medium"] = "rbxassetid://105934079398915",
        ["battery-plus"] = "rbxassetid://91931341486966",
        ["battery-warning"] = "rbxassetid://115230083817257",
        ["beaker"] = "rbxassetid://80902539995520",
        ["bean"] = "rbxassetid://89491967076869",
        ["bean-off"] = "rbxassetid://98164436608714",
        ["bed"] = "rbxassetid://97726529032925",
        ["bed-double"] = "rbxassetid://73820193212911",
        ["bed-single"] = "rbxassetid://113423940880634",
        ["beef"] = "rbxassetid://105850162318915",
        ["beef-off"] = "rbxassetid://99869959725200",
        ["beer"] = "rbxassetid://116404978807744",
        ["beer-off"] = "rbxassetid://120333134736361",
        ["bell"] = "rbxassetid://97392696311902",
        ["bell-dot"] = "rbxassetid://93161277118810",
        ["bell-electric"] = "rbxassetid://100277767266983",
        ["bell-minus"] = "rbxassetid://126334890449727",
        ["bell-off"] = "rbxassetid://78560046118930",
        ["bell-plus"] = "rbxassetid://77014333795836",
        ["bell-ring"] = "rbxassetid://94612128913941",
        ["between-horizontal-end"] = "rbxassetid://81602774794322",
        ["between-horizontal-start"] = "rbxassetid://76112384929846",
        ["between-vertical-end"] = "rbxassetid://72817612571631",
        ["between-vertical-start"] = "rbxassetid://85278312190301",
        ["biceps-flexed"] = "rbxassetid://82004462003936",
        ["bike"] = "rbxassetid://102930322246035",
        ["binary"] = "rbxassetid://91751953950088",
        ["binoculars"] = "rbxassetid://101460003267896",
        ["biohazard"] = "rbxassetid://95956532900432",
        ["bird"] = "rbxassetid://132284145117371",
        ["birdhouse"] = "rbxassetid://83999157401433",
        ["bitcoin"] = "rbxassetid://95459240442938",
        ["blend"] = "rbxassetid://111679612185257",
        ["blinds"] = "rbxassetid://71164165283925",
        ["blocks"] = "rbxassetid://72212693357737",
        ["bluetooth"] = "rbxassetid://90506573139443",
        ["bluetooth-connected"] = "rbxassetid://96315134002985",
        ["bluetooth-off"] = "rbxassetid://80600044218117",
        ["bluetooth-searching"] = "rbxassetid://100673019606426",
        ["bold"] = "rbxassetid://116141470019166",
        ["bolt"] = "rbxassetid://102881251417484",
        ["bomb"] = "rbxassetid://139223800924636",
        ["bone"] = "rbxassetid://111242153474115",
        ["book"] = "rbxassetid://125383279695672",
        ["book-a"] = "rbxassetid://104067275658465",
        ["book-alert"] = "rbxassetid://124159928044853",
        ["book-audio"] = "rbxassetid://109208148317037",
        ["book-check"] = "rbxassetid://115999656081696",
        ["book-copy"] = "rbxassetid://108543407492005",
        ["book-dashed"] = "rbxassetid://127430784795958",
        ["book-down"] = "rbxassetid://101011730128222",
        ["book-headphones"] = "rbxassetid://108670200799574",
        ["book-heart"] = "rbxassetid://112788845135284",
        ["book-image"] = "rbxassetid://80808285757226",
        ["book-key"] = "rbxassetid://116024426170705",
        ["book-lock"] = "rbxassetid://118765061220571",
        ["book-marked"] = "rbxassetid://73211024251780",
        ["book-minus"] = "rbxassetid://112724962046282",
        ["book-open"] = "rbxassetid://129845326810392",
        ["book-open-check"] = "rbxassetid://130848362492667",
        ["book-open-text"] = "rbxassetid://100629528672195",
        ["book-plus"] = "rbxassetid://140267785051233",
        ["book-search"] = "rbxassetid://132585409504950",
        ["book-text"] = "rbxassetid://94011772484232",
        ["book-type"] = "rbxassetid://97817304725443",
        ["book-up"] = "rbxassetid://98640174079190",
        ["book-up-2"] = "rbxassetid://130161620853665",
        ["book-user"] = "rbxassetid://128489189240523",
        ["book-x"] = "rbxassetid://118754548186537",
        ["bookmark"] = "rbxassetid://121093149326239",
        ["bookmark-check"] = "rbxassetid://93940443347986",
        ["bookmark-minus"] = "rbxassetid://96807096039910",
        ["bookmark-plus"] = "rbxassetid://121469724491615",
        ["bookmark-x"] = "rbxassetid://112272342584706",
        ["boom-box"] = "rbxassetid://99901322535868",
        ["bot"] = "rbxassetid://80451686744860",
        ["bot-message-square"] = "rbxassetid://96145330292478",
        ["bot-off"] = "rbxassetid://140417690560013",
        ["bottle-wine"] = "rbxassetid://131675403196921",
        ["bow-arrow"] = "rbxassetid://124089655150375",
        ["box"] = "rbxassetid://101768155599700",
        ["boxes"] = "rbxassetid://136372617578355",
        ["braces"] = "rbxassetid://117761094704041",
        ["brackets"] = "rbxassetid://74368995728099",
        ["brain"] = "rbxassetid://92424107303177",
        ["brain-circuit"] = "rbxassetid://70547962410202",
        ["brain-cog"] = "rbxassetid://132039205501538",
        ["brick-wall"] = "rbxassetid://112878522258821",
        ["brick-wall-fire"] = "rbxassetid://92980588705520",
        ["brick-wall-shield"] = "rbxassetid://75954432775071",
        ["briefcase"] = "rbxassetid://96754188164225",
        ["briefcase-business"] = "rbxassetid://129135125207283",
        ["briefcase-conveyor-belt"] = "rbxassetid://108665725653714",
        ["briefcase-medical"] = "rbxassetid://119917756334087",
        ["bring-to-front"] = "rbxassetid://132975903553748",
        ["brush"] = "rbxassetid://127035535799640",
        ["brush-cleaning"] = "rbxassetid://71728977448805",
        ["bubbles"] = "rbxassetid://106183424168227",
        ["bug"] = "rbxassetid://83626408925438",
        ["bug-off"] = "rbxassetid://88020025049245",
        ["bug-play"] = "rbxassetid://80107955888092",
        ["building"] = "rbxassetid://110616258983082",
        ["building-2"] = "rbxassetid://77873775611951",
        ["bus"] = "rbxassetid://133798469717463",
        ["bus-front"] = "rbxassetid://89863432456045",
        ["cable"] = "rbxassetid://128449944504901",
        ["cable-car"] = "rbxassetid://128643682205596",
        ["cake"] = "rbxassetid://103131590503275",
        ["cake-slice"] = "rbxassetid://136769828413242",
        ["calculator"] = "rbxassetid://74915716529646",
        ["calendar"] = "rbxassetid://114792700814035",
        ["calendar-1"] = "rbxassetid://98458364171044",
        ["calendar-arrow-down"] = "rbxassetid://108415736543437",
        ["calendar-arrow-up"] = "rbxassetid://70574654109118",
        ["calendar-check"] = "rbxassetid://71551019465748",
        ["calendar-check-2"] = "rbxassetid://120231170248276",
        ["calendar-clock"] = "rbxassetid://119132152594595",
        ["calendar-cog"] = "rbxassetid://122402172360287",
        ["calendar-days"] = "rbxassetid://99072017568595",
        ["calendar-fold"] = "rbxassetid://117368871270394",
        ["calendar-heart"] = "rbxassetid://88839008103676",
        ["calendar-minus"] = "rbxassetid://137354318924383",
        ["calendar-minus-2"] = "rbxassetid://98846170279891",
        ["calendar-off"] = "rbxassetid://109726151749217",
        ["calendar-plus"] = "rbxassetid://125266115249843",
        ["calendar-plus-2"] = "rbxassetid://112264562093883",
        ["calendar-range"] = "rbxassetid://103641849247576",
        ["calendar-search"] = "rbxassetid://92010083223634",
        ["calendar-sync"] = "rbxassetid://78082218499697",
        ["calendar-x"] = "rbxassetid://106703374806500",
        ["calendar-x-2"] = "rbxassetid://107518051061147",
        ["calendars"] = "rbxassetid://130944763042289",
        ["camera"] = "rbxassetid://79950339943067",
        ["camera-off"] = "rbxassetid://81057636835256",
        ["candy"] = "rbxassetid://107812129154678",
        ["candy-cane"] = "rbxassetid://71689468772492",
        ["candy-off"] = "rbxassetid://110232752314832",
        ["cannabis"] = "rbxassetid://98792006538601",
        ["cannabis-off"] = "rbxassetid://101938500363812",
        ["captions"] = "rbxassetid://104960225031445",
        ["captions-off"] = "rbxassetid://105223545364193",
        ["car"] = "rbxassetid://121065933462582",
        ["car-front"] = "rbxassetid://87380942739063",
        ["car-taxi-front"] = "rbxassetid://122455403384057",
        ["caravan"] = "rbxassetid://120070979471783",
        ["card-sim"] = "rbxassetid://134490550095771",
        ["carrot"] = "rbxassetid://119118221444304",
        ["case-lower"] = "rbxassetid://129303130603241",
        ["case-sensitive"] = "rbxassetid://125410273293056",
        ["case-upper"] = "rbxassetid://111633433531325",
        ["cassette-tape"] = "rbxassetid://137065788934157",
        ["cast"] = "rbxassetid://98202245922071",
        ["castle"] = "rbxassetid://119275077187784",
        ["cat"] = "rbxassetid://124252153404931",
        ["cctv"] = "rbxassetid://99979894766624",
        ["cctv-off"] = "rbxassetid://75925370187295",
        ["chart-area"] = "rbxassetid://123446436762366",
        ["chart-bar"] = "rbxassetid://105389816384108",
        ["chart-bar-big"] = "rbxassetid://72336824986044",
        ["chart-bar-decreasing"] = "rbxassetid://107217459044963",
        ["chart-bar-increasing"] = "rbxassetid://88268905998571",
        ["chart-bar-stacked"] = "rbxassetid://98478751113024",
        ["chart-candlestick"] = "rbxassetid://125676898615697",
        ["chart-column"] = "rbxassetid://97915995538580",
        ["chart-column-big"] = "rbxassetid://98598733210787",
        ["chart-column-decreasing"] = "rbxassetid://73586137373563",
        ["chart-column-increasing"] = "rbxassetid://120421615068601",
        ["chart-column-stacked"] = "rbxassetid://86031449675105",
        ["chart-gantt"] = "rbxassetid://88811660555940",
        ["chart-line"] = "rbxassetid://101833156055618",
        ["chart-network"] = "rbxassetid://104027882693561",
        ["chart-no-axes-column"] = "rbxassetid://94078751170351",
        ["chart-no-axes-column-decreasing"] = "rbxassetid://123371717192542",
        ["chart-no-axes-column-increasing"] = "rbxassetid://140383830943049",
        ["chart-no-axes-combined"] = "rbxassetid://121424233161912",
        ["chart-no-axes-gantt"] = "rbxassetid://131936541106368",
        ["chart-pie"] = "rbxassetid://113412261630136",
        ["chart-scatter"] = "rbxassetid://108217585014571",
        ["chart-spline"] = "rbxassetid://90307460742494",
        ["check"] = "rbxassetid://93898873302694",
        ["check-check"] = "rbxassetid://95183312173858",
        ["check-line"] = "rbxassetid://115122343485290",
        ["chef-hat"] = "rbxassetid://121744015002573",
        ["cherry"] = "rbxassetid://139519182403183",
        ["chess-bishop"] = "rbxassetid://121701705580238",
        ["chess-king"] = "rbxassetid://90885687223462",
        ["chess-knight"] = "rbxassetid://96467707042169",
        ["chess-pawn"] = "rbxassetid://111318574652751",
        ["chess-queen"] = "rbxassetid://98304702099749",
        ["chess-rook"] = "rbxassetid://76223925830262",
        ["chevron-down"] = "rbxassetid://134243273101015",
        ["chevron-first"] = "rbxassetid://105243363790238",
        ["chevron-last"] = "rbxassetid://89268452603731",
        ["chevron-left"] = "rbxassetid://73780377692148",
        ["chevron-right"] = "rbxassetid://92473583511724",
        ["chevron-up"] = "rbxassetid://122444883127455",
        ["chevrons-down"] = "rbxassetid://100524612205956",
        ["chevrons-down-up"] = "rbxassetid://139404716013205",
        ["chevrons-left"] = "rbxassetid://82617201744347",
        ["chevrons-left-right"] = "rbxassetid://87910685945204",
        ["chevrons-left-right-ellipsis"] = "rbxassetid://125035817741526",
        ["chevrons-right"] = "rbxassetid://139121276490483",
        ["chevrons-right-left"] = "rbxassetid://87149546686569",
        ["chevrons-up"] = "rbxassetid://100467452364672",
        ["chevrons-up-down"] = "rbxassetid://131833120209646",
        ["chromium"] = "rbxassetid://128165143739006",
        ["church"] = "rbxassetid://113714744350666",
        ["cigarette"] = "rbxassetid://137149549886852",
        ["cigarette-off"] = "rbxassetid://77797883078452",
        ["circle"] = "rbxassetid://130359823580534",
        ["circle-alert"] = "rbxassetid://83898160590116",
        ["circle-arrow-down"] = "rbxassetid://95901860261344",
        ["circle-arrow-left"] = "rbxassetid://102148876968988",
        ["circle-arrow-out-down-left"] = "rbxassetid://140598097856694",
        ["circle-arrow-out-down-right"] = "rbxassetid://119952801379305",
        ["circle-arrow-out-up-left"] = "rbxassetid://132858212688303",
        ["circle-arrow-out-up-right"] = "rbxassetid://81783743753173",
        ["circle-arrow-right"] = "rbxassetid://70786767999559",
        ["circle-arrow-up"] = "rbxassetid://84395128546494",
        ["circle-check"] = "rbxassetid://85262178816537",
        ["circle-check-big"] = "rbxassetid://93202927221730",
        ["circle-chevron-down"] = "rbxassetid://137069490345718",
        ["circle-chevron-left"] = "rbxassetid://130250009740827",
        ["circle-chevron-right"] = "rbxassetid://125943696958495",
        ["circle-chevron-up"] = "rbxassetid://111223574026321",
        ["circle-dashed"] = "rbxassetid://126799443883746",
        ["circle-divide"] = "rbxassetid://106398997754208",
        ["circle-dollar-sign"] = "rbxassetid://91106238890387",
        ["circle-dot"] = "rbxassetid://82947033619201",
        ["circle-dot-dashed"] = "rbxassetid://111451232827180",
        ["circle-ellipsis"] = "rbxassetid://91687150884779",
        ["circle-equal"] = "rbxassetid://95133963751438",
        ["circle-fading-arrow-up"] = "rbxassetid://104648212910336",
        ["circle-fading-plus"] = "rbxassetid://91847890443490",
        ["circle-gauge"] = "rbxassetid://108157549473765",
        ["circle-minus"] = "rbxassetid://133556159576809",
        ["circle-off"] = "rbxassetid://97923456918886",
        ["circle-parking"] = "rbxassetid://124034962915196",
        ["circle-parking-off"] = "rbxassetid://128369410981252",
        ["circle-pause"] = "rbxassetid://139337739700879",
        ["circle-percent"] = "rbxassetid://133311912860256",
        ["circle-pile"] = "rbxassetid://116353155251541",
        ["circle-play"] = "rbxassetid://120408917249739",
        ["circle-plus"] = "rbxassetid://113157136350384",
        ["circle-pound-sterling"] = "rbxassetid://105476153083828",
        ["circle-power"] = "rbxassetid://140676030155098",
        ["circle-question-mark"] = "rbxassetid://97516698664325",
        ["circle-slash"] = "rbxassetid://125206439913049",
        ["circle-slash-2"] = "rbxassetid://136766902186549",
        ["circle-small"] = "rbxassetid://73685402843600",
        ["circle-star"] = "rbxassetid://120318414957104",
        ["circle-stop"] = "rbxassetid://87400503942659",
        ["circle-user"] = "rbxassetid://136220511671311",
        ["circle-user-round"] = "rbxassetid://95489465399880",
        ["circle-x"] = "rbxassetid://76821953846248",
        ["circuit-board"] = "rbxassetid://107695264369312",
        ["citrus"] = "rbxassetid://139018222976433",
        ["clapperboard"] = "rbxassetid://132660667070200",
        ["clipboard"] = "rbxassetid://89601995828423",
        ["clipboard-check"] = "rbxassetid://92649798577170",
        ["clipboard-clock"] = "rbxassetid://123957515687745",
        ["clipboard-copy"] = "rbxassetid://125851897718493",
        ["clipboard-list"] = "rbxassetid://96460215958908",
        ["clipboard-minus"] = "rbxassetid://107968008485671",
        ["clipboard-paste"] = "rbxassetid://74382068849983",
        ["clipboard-pen"] = "rbxassetid://75290966822953",
        ["clipboard-pen-line"] = "rbxassetid://77711589791615",
        ["clipboard-plus"] = "rbxassetid://134285318675662",
        ["clipboard-type"] = "rbxassetid://89949374318028",
        ["clipboard-x"] = "rbxassetid://102222456890103",
        ["clock"] = "rbxassetid://121808839832144",
        ["clock-1"] = "rbxassetid://129363225422045",
        ["clock-10"] = "rbxassetid://104332695855541",
        ["clock-11"] = "rbxassetid://119023205186105",
        ["clock-12"] = "rbxassetid://117789618723068",
        ["clock-2"] = "rbxassetid://134710777209413",
        ["clock-3"] = "rbxassetid://136385631189327",
        ["clock-4"] = "rbxassetid://121808839832144",
        ["clock-5"] = "rbxassetid://85082019959457",
        ["clock-6"] = "rbxassetid://71009733505593",
        ["clock-7"] = "rbxassetid://103111188546225",
        ["clock-8"] = "rbxassetid://110059272125337",
        ["clock-9"] = "rbxassetid://77610027126437",
        ["clock-alert"] = "rbxassetid://97157344465162",
        ["clock-arrow-down"] = "rbxassetid://92349314416042",
        ["clock-arrow-up"] = "rbxassetid://111484286332629",
        ["clock-check"] = "rbxassetid://85231630218857",
        ["clock-fading"] = "rbxassetid://93205297285245",
        ["clock-plus"] = "rbxassetid://93367709263150",
        ["closed-caption"] = "rbxassetid://99832644030788",
        ["cloud"] = "rbxassetid://121226497050352",
        ["cloud-alert"] = "rbxassetid://91967273658626",
        ["cloud-backup"] = "rbxassetid://111649579696132",
        ["cloud-check"] = "rbxassetid://97318598202432",
        ["cloud-cog"] = "rbxassetid://96497764065749",
        ["cloud-download"] = "rbxassetid://121435581993566",
        ["cloud-drizzle"] = "rbxassetid://139525315752605",
        ["cloud-fog"] = "rbxassetid://76650233148776",
        ["cloud-hail"] = "rbxassetid://72320462748242",
        ["cloud-lightning"] = "rbxassetid://133517088924849",
        ["cloud-moon"] = "rbxassetid://71938114737914",
        ["cloud-moon-rain"] = "rbxassetid://127667837827018",
        ["cloud-off"] = "rbxassetid://131907154501444",
        ["cloud-rain"] = "rbxassetid://105547081967408",
        ["cloud-rain-wind"] = "rbxassetid://107414583736721",
        ["cloud-snow"] = "rbxassetid://72307126270226",
        ["cloud-sun"] = "rbxassetid://86114208148727",
        ["cloud-sun-rain"] = "rbxassetid://99041604425705",
        ["cloud-sync"] = "rbxassetid://79393911188593",
        ["cloud-upload"] = "rbxassetid://93307473217005",
        ["cloudy"] = "rbxassetid://105360479023346",
        ["clover"] = "rbxassetid://74925550436750",
        ["club"] = "rbxassetid://108490365816628",
        ["code"] = "rbxassetid://107380207681249",
        ["code-xml"] = "rbxassetid://130150477351734",
        ["codepen"] = "rbxassetid://135643965971885",
        ["codesandbox"] = "rbxassetid://106911852964823",
        ["coffee"] = "rbxassetid://106864403231093",
        ["cog"] = "rbxassetid://116544501716299",
        ["coins"] = "rbxassetid://116510979641930",
        ["columns-2"] = "rbxassetid://113004100221850",
        ["columns-3"] = "rbxassetid://115223357399375",
        ["columns-3-cog"] = "rbxassetid://121589691981064",
        ["columns-4"] = "rbxassetid://130807991968419",
        ["combine"] = "rbxassetid://79908476334048",
        ["command"] = "rbxassetid://93648221906330",
        ["compass"] = "rbxassetid://115123411028382",
        ["component"] = "rbxassetid://110027788875080",
        ["computer"] = "rbxassetid://77480056459407",
        ["concierge-bell"] = "rbxassetid://140384259310436",
        ["cone"] = "rbxassetid://97759550688437",
        ["construction"] = "rbxassetid://106539489968173",
        ["contact"] = "rbxassetid://75868297719012",
        ["contact-round"] = "rbxassetid://71907624112229",
        ["container"] = "rbxassetid://91507237573499",
        ["contrast"] = "rbxassetid://112796643981497",
        ["cookie"] = "rbxassetid://73159504540002",
        ["cooking-pot"] = "rbxassetid://94959783129799",
        ["copy"] = "rbxassetid://78979572434545",
        ["copy-check"] = "rbxassetid://91177247988892",
        ["copy-minus"] = "rbxassetid://109524509933035",
        ["copy-plus"] = "rbxassetid://113618379616952",
        ["copy-slash"] = "rbxassetid://93805787810390",
        ["copy-x"] = "rbxassetid://106557557978061",
        ["copyleft"] = "rbxassetid://78559055698593",
        ["copyright"] = "rbxassetid://129433635747111",
        ["corner-down-left"] = "rbxassetid://90473561177832",
        ["corner-down-right"] = "rbxassetid://86512767702085",
        ["corner-left-down"] = "rbxassetid://139876989150630",
        ["corner-left-up"] = "rbxassetid://126228268096099",
        ["corner-right-down"] = "rbxassetid://89237035551302",
        ["corner-right-up"] = "rbxassetid://112851237026705",
        ["corner-up-left"] = "rbxassetid://84669279763024",
        ["corner-up-right"] = "rbxassetid://115099889693145",
        ["cpu"] = "rbxassetid://77549309870247",
        ["creative-commons"] = "rbxassetid://90408210735312",
        ["credit-card"] = "rbxassetid://99163352872346",
        ["croissant"] = "rbxassetid://130710485559420",
        ["crop"] = "rbxassetid://116344601101413",
        ["cross"] = "rbxassetid://101833377863588",
        ["crosshair"] = "rbxassetid://134242818164054",
        ["crown"] = "rbxassetid://127843403295538",
        ["cuboid"] = "rbxassetid://75618807946111",
        ["cup-soda"] = "rbxassetid://121098640829562",
        ["currency"] = "rbxassetid://90551250119972",
        ["cylinder"] = "rbxassetid://90569677179169",
        ["dam"] = "rbxassetid://76874486231393",
        ["database"] = "rbxassetid://126791525623846",
        ["database-backup"] = "rbxassetid://103403210984699",
        ["database-search"] = "rbxassetid://92017137080138",
        ["database-zap"] = "rbxassetid://131199921258418",
        ["decimals-arrow-left"] = "rbxassetid://120198500638749",
        ["decimals-arrow-right"] = "rbxassetid://118263047146797",
        ["delete"] = "rbxassetid://126279426372342",
        ["dessert"] = "rbxassetid://71508133278830",
        ["diameter"] = "rbxassetid://97429051503783",
        ["diamond"] = "rbxassetid://105846996304890",
        ["diamond-minus"] = "rbxassetid://128989071438290",
        ["diamond-percent"] = "rbxassetid://107717860105959",
        ["diamond-plus"] = "rbxassetid://134701163723675",
        ["dice-1"] = "rbxassetid://112650149591038",
        ["dice-2"] = "rbxassetid://112278274566793",
        ["dice-3"] = "rbxassetid://118526270626312",
        ["dice-4"] = "rbxassetid://113365650364004",
        ["dice-5"] = "rbxassetid://72768312430593",
        ["dice-6"] = "rbxassetid://85376239182543",
        ["dices"] = "rbxassetid://81268120302865",
        ["diff"] = "rbxassetid://135052708609715",
        ["disc"] = "rbxassetid://101908120120777",
        ["disc-2"] = "rbxassetid://91419420404185",
        ["disc-3"] = "rbxassetid://135470554736048",
        ["disc-album"] = "rbxassetid://74693460404344",
        ["divide"] = "rbxassetid://136678191878278",
        ["dna"] = "rbxassetid://74007982981741",
        ["dna-off"] = "rbxassetid://89612426361540",
        ["dock"] = "rbxassetid://121997427160252",
        ["dog"] = "rbxassetid://71920105558570",
        ["dollar-sign"] = "rbxassetid://127320961224019",
        ["donut"] = "rbxassetid://72204922742657",
        ["door-closed"] = "rbxassetid://136249099949073",
        ["door-closed-locked"] = "rbxassetid://74027613267551",
        ["door-open"] = "rbxassetid://91306356501736",
        ["dot"] = "rbxassetid://137321056643916",
        ["download"] = "rbxassetid://134814648082393",
        ["drafting-compass"] = "rbxassetid://99701976182841",
        ["drama"] = "rbxassetid://110297795801577",
        ["dribbble"] = "rbxassetid://80231809663849",
        ["drill"] = "rbxassetid://108644821412796",
        ["drone"] = "rbxassetid://117299095794783",
        ["droplet"] = "rbxassetid://100597455015098",
        ["droplet-off"] = "rbxassetid://119365002225172",
        ["droplets"] = "rbxassetid://140111846025180",
        ["drum"] = "rbxassetid://136979060344890",
        ["drumstick"] = "rbxassetid://104662462521709",
        ["dumbbell"] = "rbxassetid://80277236776212",
        ["ear"] = "rbxassetid://121894949934209",
        ["ear-off"] = "rbxassetid://87421916192807",
        ["earth"] = "rbxassetid://76231597751076",
        ["earth-lock"] = "rbxassetid://88814147073745",
        ["eclipse"] = "rbxassetid://114829622118222",
        ["egg"] = "rbxassetid://117851493400222",
        ["egg-fried"] = "rbxassetid://90622538210545",
        ["egg-off"] = "rbxassetid://92288321309285",
        ["ellipse"] = "rbxassetid://71559658267482",
        ["ellipsis"] = "rbxassetid://140019550645825",
        ["ellipsis-vertical"] = "rbxassetid://117978708573781",
        ["equal"] = "rbxassetid://123467780715624",
        ["equal-approximately"] = "rbxassetid://105382689698323",
        ["equal-not"] = "rbxassetid://76864449458032",
        ["eraser"] = "rbxassetid://133957773112410",
        ["ethernet-port"] = "rbxassetid://75391715149314",
        ["euro"] = "rbxassetid://72229646524456",
        ["ev-charger"] = "rbxassetid://97906158859623",
        ["expand"] = "rbxassetid://137492887754537",
        ["external-link"] = "rbxassetid://129331830773832",
        ["eye"] = "rbxassetid://100033680381365",
        ["eye-closed"] = "rbxassetid://111063268625789",
        ["eye-off"] = "rbxassetid://135928786788378",
        ["facebook"] = "rbxassetid://72098528632192",
        ["factory"] = "rbxassetid://102170024318039",
        ["fan"] = "rbxassetid://78391400440696",
        ["fast-forward"] = "rbxassetid://121615540167909",
        ["feather"] = "rbxassetid://91872927606406",
        ["fence"] = "rbxassetid://123451565578029",
        ["ferris-wheel"] = "rbxassetid://79729205796176",
        ["figma"] = "rbxassetid://134182122852301",
        ["file"] = "rbxassetid://74748492079329",
        ["file-archive"] = "rbxassetid://77018106869967",
        ["file-axis-3d"] = "rbxassetid://133912328009885",
        ["file-badge"] = "rbxassetid://74564895394477",
        ["file-box"] = "rbxassetid://119264004071690",
        ["file-braces"] = "rbxassetid://95314128621234",
        ["file-braces-corner"] = "rbxassetid://77253337986109",
        ["file-chart-column"] = "rbxassetid://82048481252560",
        ["file-chart-column-increasing"] = "rbxassetid://134449481172067",
        ["file-chart-line"] = "rbxassetid://71954360551345",
        ["file-chart-pie"] = "rbxassetid://81072193564497",
        ["file-check"] = "rbxassetid://82604001452455",
        ["file-check-corner"] = "rbxassetid://76295552859171",
        ["file-clock"] = "rbxassetid://102325208830990",
        ["file-code"] = "rbxassetid://130978036895504",
        ["file-code-corner"] = "rbxassetid://78293841184371",
        ["file-cog"] = "rbxassetid://101385347151368",
        ["file-diff"] = "rbxassetid://96147216772241",
        ["file-digit"] = "rbxassetid://89220220354580",
        ["file-down"] = "rbxassetid://120650154178290",
        ["file-exclamation-point"] = "rbxassetid://102821865889635",
        ["file-headphone"] = "rbxassetid://100533735901986",
        ["file-heart"] = "rbxassetid://132214916401696",
        ["file-image"] = "rbxassetid://123334057511782",
        ["file-input"] = "rbxassetid://124728604166044",
        ["file-key"] = "rbxassetid://118790255921100",
        ["file-lock"] = "rbxassetid://72170228691242",
        ["file-minus"] = "rbxassetid://111014798459222",
        ["file-minus-corner"] = "rbxassetid://119263271735124",
        ["file-music"] = "rbxassetid://134948051536671",
        ["file-output"] = "rbxassetid://92146832572911",
        ["file-pen"] = "rbxassetid://79556179730240",
        ["file-pen-line"] = "rbxassetid://104622936345006",
        ["file-play"] = "rbxassetid://89006821567838",
        ["file-plus"] = "rbxassetid://78881710800060",
        ["file-plus-corner"] = "rbxassetid://76544604043974",
        ["file-question-mark"] = "rbxassetid://127617422859576",
        ["file-scan"] = "rbxassetid://129480105228213",
        ["file-search"] = "rbxassetid://97780235974933",
        ["file-search-corner"] = "rbxassetid://90974165234008",
        ["file-signal"] = "rbxassetid://122070252538165",
        ["file-sliders"] = "rbxassetid://85787771732439",
        ["file-spreadsheet"] = "rbxassetid://134501869359270",
        ["file-stack"] = "rbxassetid://138929929862605",
        ["file-symlink"] = "rbxassetid://91865722036510",
        ["file-terminal"] = "rbxassetid://116757454755476",
        ["file-text"] = "rbxassetid://90496405707281",
        ["file-type"] = "rbxassetid://115272552799361",
        ["file-type-corner"] = "rbxassetid://124902230275209",
        ["file-up"] = "rbxassetid://131173039312748",
        ["file-user"] = "rbxassetid://99552018455009",
        ["file-video-camera"] = "rbxassetid://81719056173960",
        ["file-volume"] = "rbxassetid://111264764438958",
        ["file-x"] = "rbxassetid://107333775515154",
        ["file-x-corner"] = "rbxassetid://87554136773609",
        ["files"] = "rbxassetid://102806336233202",
        ["film"] = "rbxassetid://120978945609706",
        ["fingerprint"] = "rbxassetid://112173305232811",
        ["fingerprint-pattern"] = "rbxassetid://80934710831288",
        ["fire-extinguisher"] = "rbxassetid://111643493006960",
        ["fish"] = "rbxassetid://124360663785796",
        ["fish-off"] = "rbxassetid://89756724887508",
        ["fish-symbol"] = "rbxassetid://118475177681618",
        ["fishing-hook"] = "rbxassetid://121038780855899",
        ["fishing-rod"] = "rbxassetid://71754848048049",
        ["flag"] = "rbxassetid://78183383236196",
        ["flag-off"] = "rbxassetid://112944528856799",
        ["flag-triangle-left"] = "rbxassetid://88045221285272",
        ["flag-triangle-right"] = "rbxassetid://108292480304566",
        ["flame"] = "rbxassetid://98218034436456",
        ["flame-kindling"] = "rbxassetid://139728976917928",
        ["flashlight"] = "rbxassetid://100286985600444",
        ["flashlight-off"] = "rbxassetid://79780362871740",
        ["flask-conical"] = "rbxassetid://128406680901165",
        ["flask-conical-off"] = "rbxassetid://112597970025298",
        ["flask-round"] = "rbxassetid://127508287324940",
        ["flip-horizontal"] = "rbxassetid://122937530107837",
        ["flip-horizontal-2"] = "rbxassetid://103726993598186",
        ["flip-vertical"] = "rbxassetid://108003917346888",
        ["flip-vertical-2"] = "rbxassetid://103836358956328",
        ["flower"] = "rbxassetid://86129438272762",
        ["flower-2"] = "rbxassetid://72934574245145",
        ["focus"] = "rbxassetid://87493973153317",
        ["fold-horizontal"] = "rbxassetid://92835712442240",
        ["fold-vertical"] = "rbxassetid://108873727253656",
        ["folder"] = "rbxassetid://80846616596607",
        ["folder-archive"] = "rbxassetid://97312009460206",
        ["folder-check"] = "rbxassetid://128492920904557",
        ["folder-clock"] = "rbxassetid://111964836738545",
        ["folder-closed"] = "rbxassetid://118286209350843",
        ["folder-code"] = "rbxassetid://70624096349370",
        ["folder-cog"] = "rbxassetid://85299519462846",
        ["folder-dot"] = "rbxassetid://138687772725278",
        ["folder-down"] = "rbxassetid://118044108459225",
        ["folder-git"] = "rbxassetid://121885778095158",
        ["folder-git-2"] = "rbxassetid://101394054141166",
        ["folder-heart"] = "rbxassetid://79104747211105",
        ["folder-input"] = "rbxassetid://90699920697871",
        ["folder-kanban"] = "rbxassetid://78313285104072",
        ["folder-key"] = "rbxassetid://85270407596791",
        ["folder-lock"] = "rbxassetid://119201572260567",
        ["folder-minus"] = "rbxassetid://85648718999010",
        ["folder-open"] = "rbxassetid://76018996254888",
        ["folder-open-dot"] = "rbxassetid://74741494767354",
        ["folder-output"] = "rbxassetid://101532447937612",
        ["folder-pen"] = "rbxassetid://112770491173911",
        ["folder-plus"] = "rbxassetid://91865663406119",
        ["folder-root"] = "rbxassetid://103333751154693",
        ["folder-search"] = "rbxassetid://110568075123861",
        ["folder-search-2"] = "rbxassetid://71276453442655",
        ["folder-symlink"] = "rbxassetid://127485747227189",
        ["folder-sync"] = "rbxassetid://91544602659796",
        ["folder-tree"] = "rbxassetid://85577554337861",
        ["folder-up"] = "rbxassetid://72008269765857",
        ["folder-x"] = "rbxassetid://91699618247635",
        ["folders"] = "rbxassetid://110351216219061",
        ["footprints"] = "rbxassetid://139192589041315",
        ["forklift"] = "rbxassetid://72030930983101",
        ["form"] = "rbxassetid://72999643971000",
        ["forward"] = "rbxassetid://97545944739523",
        ["frame"] = "rbxassetid://109080612832751",
        ["framer"] = "rbxassetid://108384807262391",
        ["frown"] = "rbxassetid://124407301067982",
        ["fuel"] = "rbxassetid://106447647274511",
        ["fullscreen"] = "rbxassetid://77793665526178",
        ["funnel"] = "rbxassetid://108829540827529",
        ["funnel-plus"] = "rbxassetid://100780233821928",
        ["funnel-x"] = "rbxassetid://70984385812555",
        ["gallery-horizontal"] = "rbxassetid://80004001442122",
        ["gallery-horizontal-end"] = "rbxassetid://74672430161161",
        ["gallery-thumbnails"] = "rbxassetid://136219289862706",
        ["gallery-vertical"] = "rbxassetid://119299431466725",
        ["gallery-vertical-end"] = "rbxassetid://106461402088317",
        ["gamepad"] = "rbxassetid://121607283959010",
        ["gamepad-2"] = "rbxassetid://92483947987410",
        ["gamepad-directional"] = "rbxassetid://84342305212226",
        ["gauge"] = "rbxassetid://110273524101447",
        ["gavel"] = "rbxassetid://78952298198456",
        ["gem"] = "rbxassetid://112904952151156",
        ["georgian-lari"] = "rbxassetid://98084432591687",
        ["ghost"] = "rbxassetid://113822048130017",
        ["gift"] = "rbxassetid://109855212076373",
        ["git-branch"] = "rbxassetid://90490195516649",
        ["git-branch-minus"] = "rbxassetid://97385010649411",
        ["git-branch-plus"] = "rbxassetid://125944221134316",
        ["git-commit-horizontal"] = "rbxassetid://133646041800147",
        ["git-commit-vertical"] = "rbxassetid://122098032990350",
        ["git-compare"] = "rbxassetid://91945124438792",
        ["git-compare-arrows"] = "rbxassetid://84874426520216",
        ["git-fork"] = "rbxassetid://89954992404765",
        ["git-graph"] = "rbxassetid://86166832019304",
        ["git-merge"] = "rbxassetid://131833355158059",
        ["git-merge-conflict"] = "rbxassetid://85677801675703",
        ["git-pull-request"] = "rbxassetid://138463010991471",
        ["git-pull-request-arrow"] = "rbxassetid://94507974577439",
        ["git-pull-request-closed"] = "rbxassetid://78070600389091",
        ["git-pull-request-create"] = "rbxassetid://105929577383926",
        ["git-pull-request-create-arrow"] = "rbxassetid://127422677061091",
        ["git-pull-request-draft"] = "rbxassetid://76173459869943",
        ["github"] = "rbxassetid://120349554354380",
        ["gitlab"] = "rbxassetid://114054627192933",
        ["glass-water"] = "rbxassetid://115526102400988",
        ["glasses"] = "rbxassetid://87936407455373",
        ["globe"] = "rbxassetid://114238209622913",
        ["globe-lock"] = "rbxassetid://134065526704402",
        ["globe-off"] = "rbxassetid://77775243585824",
        ["globe-x"] = "rbxassetid://109268097029296",
        ["goal"] = "rbxassetid://120517954878160",
        ["gpu"] = "rbxassetid://95577823614219",
        ["graduation-cap"] = "rbxassetid://93771896340220",
        ["grape"] = "rbxassetid://134760640415561",
        ["grid-2x2"] = "rbxassetid://99050491897640",
        ["grid-2x2-check"] = "rbxassetid://138468840220821",
        ["grid-2x2-plus"] = "rbxassetid://91811610580247",
        ["grid-2x2-x"] = "rbxassetid://72407303981388",
        ["grid-3x2"] = "rbxassetid://95528684210010",
        ["grid-3x3"] = "rbxassetid://70419024781206",
        ["grip"] = "rbxassetid://109058783556768",
        ["grip-horizontal"] = "rbxassetid://136255899715930",
        ["grip-vertical"] = "rbxassetid://137183678565296",
        ["group"] = "rbxassetid://107643418926671",
        ["guitar"] = "rbxassetid://75915531867926",
        ["ham"] = "rbxassetid://74465607934635",
        ["hamburger"] = "rbxassetid://93086916815495",
        ["hammer"] = "rbxassetid://83545120140895",
        ["hand"] = "rbxassetid://130703864968637",
        ["hand-coins"] = "rbxassetid://126990543175462",
        ["hand-fist"] = "rbxassetid://83341608917591",
        ["hand-grab"] = "rbxassetid://88867162163985",
        ["hand-heart"] = "rbxassetid://117507367668412",
        ["hand-helping"] = "rbxassetid://89897738419446",
        ["hand-metal"] = "rbxassetid://113619498548713",
        ["hand-platter"] = "rbxassetid://88594727743168",
        ["handbag"] = "rbxassetid://135675846264061",
        ["handshake"] = "rbxassetid://78442115255814",
        ["hard-drive"] = "rbxassetid://88183305858463",
        ["hard-drive-download"] = "rbxassetid://73913801230614",
        ["hard-drive-upload"] = "rbxassetid://85762133615118",
        ["hard-hat"] = "rbxassetid://128050846767382",
        ["hash"] = "rbxassetid://82890331678520",
        ["hat-glasses"] = "rbxassetid://101165538224815",
        ["haze"] = "rbxassetid://108857561768901",
        ["hd"] = "rbxassetid://71682790698278",
        ["hdmi-port"] = "rbxassetid://103693661037020",
        ["heading"] = "rbxassetid://129254312067735",
        ["heading-1"] = "rbxassetid://118129315662110",
        ["heading-2"] = "rbxassetid://110209069670094",
        ["heading-3"] = "rbxassetid://90267885237062",
        ["heading-4"] = "rbxassetid://129625620307602",
        ["heading-5"] = "rbxassetid://120386663181267",
        ["heading-6"] = "rbxassetid://90959079775093",
        ["headphone-off"] = "rbxassetid://85038251615641",
        ["headphones"] = "rbxassetid://118833729589183",
        ["headset"] = "rbxassetid://129269236787694",
        ["heart"] = "rbxassetid://116559368303288",
        ["heart-crack"] = "rbxassetid://110987638564119",
        ["heart-handshake"] = "rbxassetid://111483078692002",
        ["heart-minus"] = "rbxassetid://96827380163326",
        ["heart-off"] = "rbxassetid://89748414415617",
        ["heart-plus"] = "rbxassetid://94877796283249",
        ["heart-pulse"] = "rbxassetid://129352925579546",
        ["heater"] = "rbxassetid://140478466880916",
        ["helicopter"] = "rbxassetid://111557171735930",
        ["hexagon"] = "rbxassetid://127592089339199",
        ["highlighter"] = "rbxassetid://77411555641113",
        ["history"] = "rbxassetid://123980022019922",
        ["home"] = "rbxassetid://7733960981",
        ["hop"] = "rbxassetid://82778923997672",
        ["hop-off"] = "rbxassetid://103386036934034",
        ["hospital"] = "rbxassetid://105868763850707",
        ["hotel"] = "rbxassetid://132283390859718",
        ["hourglass"] = "rbxassetid://86160434939203",
        ["house"] = "rbxassetid://98755624629571",
        ["house-heart"] = "rbxassetid://136054771868597",
        ["house-plug"] = "rbxassetid://71438263712075",
        ["house-plus"] = "rbxassetid://118495165208309",
        ["house-wifi"] = "rbxassetid://126495519725698",
        ["ice-cream-bowl"] = "rbxassetid://124867218454386",
        ["ice-cream-cone"] = "rbxassetid://90751397288639",
        ["id-card"] = "rbxassetid://75354294622640",
        ["id-card-lanyard"] = "rbxassetid://90761480469224",
        ["image"] = "rbxassetid://112751259236831",
        ["image-down"] = "rbxassetid://78972295741235",
        ["image-minus"] = "rbxassetid://101066016918565",
        ["image-off"] = "rbxassetid://81934811700938",
        ["image-play"] = "rbxassetid://129501806784210",
        ["image-plus"] = "rbxassetid://70391970623917",
        ["image-up"] = "rbxassetid://126610009605241",
        ["image-upscale"] = "rbxassetid://106963545024679",
        ["images"] = "rbxassetid://79350649395557",
        ["import"] = "rbxassetid://116545008906029",
        ["inbox"] = "rbxassetid://112591360302868",
        ["indian-rupee"] = "rbxassetid://113038778381805",
        ["infinity"] = "rbxassetid://98083086936965",
        ["info"] = "rbxassetid://124560466474914",
        ["inspection-panel"] = "rbxassetid://70905313146088",
        ["instagram"] = "rbxassetid://119864798614855",
        ["italic"] = "rbxassetid://96220378864282",
        ["iteration-ccw"] = "rbxassetid://140221832794083",
        ["iteration-cw"] = "rbxassetid://95534489554662",
        ["japanese-yen"] = "rbxassetid://106362863465813",
        ["joystick"] = "rbxassetid://99416790224739",
        ["kanban"] = "rbxassetid://125934100055431",
        ["kayak"] = "rbxassetid://136107544609389",
        ["key"] = "rbxassetid://96510194465420",
        ["key-round"] = "rbxassetid://83619031955390",
        ["key-square"] = "rbxassetid://94621420033649",
        ["keyboard"] = "rbxassetid://121474456068237",
        ["keyboard-music"] = "rbxassetid://121058541758636",
        ["keyboard-off"] = "rbxassetid://92466375369772",
        ["lamp"] = "rbxassetid://110730830653382",
        ["lamp-ceiling"] = "rbxassetid://80032758469141",
        ["lamp-desk"] = "rbxassetid://85290686983238",
        ["lamp-floor"] = "rbxassetid://104585881375892",
        ["lamp-wall-down"] = "rbxassetid://91271394132073",
        ["lamp-wall-up"] = "rbxassetid://132141464337445",
        ["land-plot"] = "rbxassetid://96449039620294",
        ["landmark"] = "rbxassetid://76885079756393",
        ["languages"] = "rbxassetid://90816903776498",
        ["laptop"] = "rbxassetid://111387063244975",
        ["laptop-minimal"] = "rbxassetid://136705765566068",
        ["laptop-minimal-check"] = "rbxassetid://114352019833865",
        ["lasso"] = "rbxassetid://121072936884007",
        ["lasso-select"] = "rbxassetid://105609719912753",
        ["laugh"] = "rbxassetid://104491311361166",
        ["layers"] = "rbxassetid://81973586053257",
        ["layers-2"] = "rbxassetid://70536710516357",
        ["layers-plus"] = "rbxassetid://77587765623057",
        ["layout-dashboard"] = "rbxassetid://139929981863901",
        ["layout-grid"] = "rbxassetid://81344910161871",
        ["layout-list"] = "rbxassetid://87462136296578",
        ["layout-panel-left"] = "rbxassetid://125092469751491",
        ["layout-panel-top"] = "rbxassetid://91943941515944",
        ["layout-template"] = "rbxassetid://115564446417985",
        ["leaf"] = "rbxassetid://119951075637174",
        ["leafy-green"] = "rbxassetid://105146290493154",
        ["lectern"] = "rbxassetid://106166425183862",
        ["lens-concave"] = "rbxassetid://94819631937027",
        ["lens-convex"] = "rbxassetid://74736504195474",
        ["library"] = "rbxassetid://114334671982047",
        ["library-big"] = "rbxassetid://106794530191412",
        ["life-buoy"] = "rbxassetid://81168450671956",
        ["ligature"] = "rbxassetid://111397873269411",
        ["lightbulb"] = "rbxassetid://103871245626488",
        ["lightbulb-off"] = "rbxassetid://83795722296178",
        ["line-dot-right-horizontal"] = "rbxassetid://104718593155221",
        ["line-squiggle"] = "rbxassetid://109555164424447",
        ["line-style"] = "rbxassetid://90176717785772",
        ["link"] = "rbxassetid://131607023382430",
        ["link-2"] = "rbxassetid://86072351557466",
        ["link-2-off"] = "rbxassetid://76885956296867",
        ["linkedin"] = "rbxassetid://132842789255788",
        ["list"] = "rbxassetid://113179976918783",
        ["list-check"] = "rbxassetid://72374358471156",
        ["list-checks"] = "rbxassetid://99809353635593",
        ["list-chevrons-down-up"] = "rbxassetid://137409641500711",
        ["list-chevrons-up-down"] = "rbxassetid://81825351389084",
        ["list-collapse"] = "rbxassetid://124505247702401",
        ["list-end"] = "rbxassetid://77650610048119",
        ["list-filter"] = "rbxassetid://103321376129527",
        ["list-filter-plus"] = "rbxassetid://96385120752336",
        ["list-indent-decrease"] = "rbxassetid://137879979228193",
        ["list-indent-increase"] = "rbxassetid://79051053161201",
        ["list-minus"] = "rbxassetid://138507965142671",
        ["list-music"] = "rbxassetid://126380635781840",
        ["list-ordered"] = "rbxassetid://83212528113913",
        ["list-plus"] = "rbxassetid://112384738137814",
        ["list-restart"] = "rbxassetid://91703153577421",
        ["list-start"] = "rbxassetid://84828348299727",
        ["list-todo"] = "rbxassetid://132980603752108",
        ["list-tree"] = "rbxassetid://97685396239010",
        ["list-video"] = "rbxassetid://93648525452489",
        ["list-x"] = "rbxassetid://113025303988861",
        ["loader"] = "rbxassetid://78408734580845",
        ["loader-circle"] = "rbxassetid://116535712789945",
        ["loader-pinwheel"] = "rbxassetid://108513357940900",
        ["locate"] = "rbxassetid://84467676590391",
        ["locate-fixed"] = "rbxassetid://137367361548433",
        ["locate-off"] = "rbxassetid://73729216338137",
        ["lock"] = "rbxassetid://134724289526879",
        ["lock-keyhole"] = "rbxassetid://78672912777756",
        ["lock-keyhole-open"] = "rbxassetid://110863509313073",
        ["lock-open"] = "rbxassetid://93597915325122",
        ["log-in"] = "rbxassetid://103768533135201",
        ["log-out"] = "rbxassetid://84895399304975",
        ["logs"] = "rbxassetid://89772091251787",
        ["lollipop"] = "rbxassetid://84681611583044",
        ["luggage"] = "rbxassetid://76619236486400",
        ["magnet"] = "rbxassetid://135162361226972",
        ["mail"] = "rbxassetid://103945161245599",
        ["mail-check"] = "rbxassetid://86921536259917",
        ["mail-minus"] = "rbxassetid://81989813236553",
        ["mail-open"] = "rbxassetid://122785416858638",
        ["mail-plus"] = "rbxassetid://104886401588341",
        ["mail-question-mark"] = "rbxassetid://126540170949819",
        ["mail-search"] = "rbxassetid://135616173775287",
        ["mail-warning"] = "rbxassetid://81495303676089",
        ["mail-x"] = "rbxassetid://74607841705644",
        ["mailbox"] = "rbxassetid://82765503320335",
        ["mails"] = "rbxassetid://90673453450080",
        ["map"] = "rbxassetid://95107167260947",
        ["map-minus"] = "rbxassetid://129525760577747",
        ["map-pin"] = "rbxassetid://84279202219901",
        ["map-pin-check"] = "rbxassetid://118110914690154",
        ["map-pin-check-inside"] = "rbxassetid://107130529843809",
        ["map-pin-house"] = "rbxassetid://80546885029816",
        ["map-pin-minus"] = "rbxassetid://74518762643623",
        ["map-pin-minus-inside"] = "rbxassetid://79005529692964",
        ["map-pin-off"] = "rbxassetid://82474689391020",
        ["map-pin-pen"] = "rbxassetid://113515395277504",
        ["map-pin-plus"] = "rbxassetid://91875228967029",
        ["map-pin-plus-inside"] = "rbxassetid://134639656514430",
        ["map-pin-search"] = "rbxassetid://89065012915078",
        ["map-pin-x"] = "rbxassetid://101085273547316",
        ["map-pin-x-inside"] = "rbxassetid://126235934252379",
        ["map-pinned"] = "rbxassetid://103963788475034",
        ["map-plus"] = "rbxassetid://129388826743495",
        ["mars"] = "rbxassetid://111287112372511",
        ["mars-stroke"] = "rbxassetid://131973193186828",
        ["martini"] = "rbxassetid://82977695401058",
        ["maximize"] = "rbxassetid://76045941763188",
        ["maximize-2"] = "rbxassetid://73085922906397",
        ["medal"] = "rbxassetid://79016002264450",
        ["megaphone"] = "rbxassetid://118759541854879",
        ["megaphone-off"] = "rbxassetid://124280774193935",
        ["meh"] = "rbxassetid://132197867028557",
        ["memory-stick"] = "rbxassetid://93212591343119",
        ["menu"] = "rbxassetid://77021539815611",
        ["merge"] = "rbxassetid://126201866476775",
        ["message-circle"] = "rbxassetid://127255077587058",
        ["message-circle-check"] = "rbxassetid://132772297689418",
        ["message-circle-code"] = "rbxassetid://112865244991651",
        ["message-circle-dashed"] = "rbxassetid://81525157881897",
        ["message-circle-heart"] = "rbxassetid://101990756073677",
        ["message-circle-more"] = "rbxassetid://92856823884663",
        ["message-circle-off"] = "rbxassetid://134955643890328",
        ["message-circle-plus"] = "rbxassetid://106562979649273",
        ["message-circle-question-mark"] = "rbxassetid://107700302759934",
        ["message-circle-reply"] = "rbxassetid://137071749508334",
        ["message-circle-warning"] = "rbxassetid://119020096067894",
        ["message-circle-x"] = "rbxassetid://126843387725536",
        ["message-square"] = "rbxassetid://83881670383280",
        ["message-square-check"] = "rbxassetid://125789987055668",
        ["message-square-code"] = "rbxassetid://110968863152123",
        ["message-square-dashed"] = "rbxassetid://107653455516238",
        ["message-square-diff"] = "rbxassetid://75472190472625",
        ["message-square-dot"] = "rbxassetid://127806382463916",
        ["message-square-heart"] = "rbxassetid://75612811742074",
        ["message-square-lock"] = "rbxassetid://81268215619563",
        ["message-square-more"] = "rbxassetid://120139782405970",
        ["message-square-off"] = "rbxassetid://99961019005789",
        ["message-square-plus"] = "rbxassetid://76934450256199",
        ["message-square-quote"] = "rbxassetid://116670768629340",
        ["message-square-reply"] = "rbxassetid://130985622754637",
        ["message-square-share"] = "rbxassetid://131017005324026",
        ["message-square-text"] = "rbxassetid://94899503194205",
        ["message-square-warning"] = "rbxassetid://138432903962261",
        ["message-square-x"] = "rbxassetid://137285463279462",
        ["messages-square"] = "rbxassetid://97532166733358",
        ["metronome"] = "rbxassetid://101991829345965",
        ["mic"] = "rbxassetid://89640799126523",
        ["mic-off"] = "rbxassetid://82123034444822",
        ["mic-vocal"] = "rbxassetid://99082286164362",
        ["microchip"] = "rbxassetid://73937907669903",
        ["microscope"] = "rbxassetid://116875530102782",
        ["microwave"] = "rbxassetid://108411735353008",
        ["milestone"] = "rbxassetid://101618292325920",
        ["milk"] = "rbxassetid://96221903896918",
        ["milk-off"] = "rbxassetid://72388480962742",
        ["minimize"] = "rbxassetid://121304296213645",
        ["minimize-2"] = "rbxassetid://116269596042539",
        ["minus"] = "rbxassetid://118026365011536",
        ["mirror-rectangular"] = "rbxassetid://109046769760336",
        ["mirror-round"] = "rbxassetid://121534049429097",
        ["monitor"] = "rbxassetid://72664649203050",
        ["monitor-check"] = "rbxassetid://86651948439229",
        ["monitor-cloud"] = "rbxassetid://85931096038318",
        ["monitor-cog"] = "rbxassetid://94345128715799",
        ["monitor-dot"] = "rbxassetid://130394010063680",
        ["monitor-down"] = "rbxassetid://97466933743423",
        ["monitor-off"] = "rbxassetid://74395526657953",
        ["monitor-pause"] = "rbxassetid://76002184067562",
        ["monitor-play"] = "rbxassetid://133018824306217",
        ["monitor-smartphone"] = "rbxassetid://84335680433378",
        ["monitor-speaker"] = "rbxassetid://81744810060380",
        ["monitor-stop"] = "rbxassetid://98708958984757",
        ["monitor-up"] = "rbxassetid://96035360858377",
        ["monitor-x"] = "rbxassetid://126265210441423",
        ["moon"] = "rbxassetid://83380517901735",
        ["moon-star"] = "rbxassetid://82782200506348",
        ["motorbike"] = "rbxassetid://94580787368233",
        ["mountain"] = "rbxassetid://73269957566415",
        ["mountain-snow"] = "rbxassetid://105315495740588",
        ["mouse"] = "rbxassetid://73096068864710",
        ["mouse-left"] = "rbxassetid://99144293708743",
        ["mouse-off"] = "rbxassetid://75267871697595",
        ["mouse-pointer"] = "rbxassetid://72322454962935",
        ["mouse-pointer-2"] = "rbxassetid://117093892862228",
        ["mouse-pointer-2-off"] = "rbxassetid://104701076865632",
        ["mouse-pointer-ban"] = "rbxassetid://106849413057133",
        ["mouse-pointer-click"] = "rbxassetid://107150227368485",
        ["mouse-right"] = "rbxassetid://88331710212594",
        ["move"] = "rbxassetid://116138709011735",
        ["move-3d"] = "rbxassetid://103365982054003",
        ["move-diagonal"] = "rbxassetid://101433481954184",
        ["move-diagonal-2"] = "rbxassetid://117298577948096",
        ["move-down"] = "rbxassetid://70510115135583",
        ["move-down-left"] = "rbxassetid://102819433534567",
        ["move-down-right"] = "rbxassetid://101479760041877",
        ["move-horizontal"] = "rbxassetid://88513523439149",
        ["move-left"] = "rbxassetid://137614740247980",
        ["move-right"] = "rbxassetid://132455779472989",
        ["move-up"] = "rbxassetid://84505444262658",
        ["move-up-left"] = "rbxassetid://139079815540148",
        ["move-up-right"] = "rbxassetid://105885140592646",
        ["move-vertical"] = "rbxassetid://86234730730899",
        ["music"] = "rbxassetid://113343203848535",
        ["music-2"] = "rbxassetid://134397426600888",
        ["music-3"] = "rbxassetid://94466120066498",
        ["music-4"] = "rbxassetid://132459323665838",
        ["navigation"] = "rbxassetid://79308213542922",
        ["navigation-2"] = "rbxassetid://81889066747907",
        ["navigation-2-off"] = "rbxassetid://116569611780763",
        ["navigation-off"] = "rbxassetid://87003270290777",
        ["network"] = "rbxassetid://127410729922644",
        ["newspaper"] = "rbxassetid://123479530460544",
        ["nfc"] = "rbxassetid://76822396542242",
        ["non-binary"] = "rbxassetid://78442360386235",
        ["notebook"] = "rbxassetid://136132108664987",
        ["notebook-pen"] = "rbxassetid://140380614761023",
        ["notebook-tabs"] = "rbxassetid://127371085570083",
        ["notebook-text"] = "rbxassetid://93061585217270",
        ["notepad-text"] = "rbxassetid://93404682958966",
        ["notepad-text-dashed"] = "rbxassetid://135793446376219",
        ["nut"] = "rbxassetid://127146410705656",
        ["nut-off"] = "rbxassetid://78795397311573",
        ["octagon"] = "rbxassetid://120803515514852",
        ["octagon-alert"] = "rbxassetid://140438367956051",
        ["octagon-minus"] = "rbxassetid://74720436795421",
        ["octagon-pause"] = "rbxassetid://103161463909039",
        ["octagon-x"] = "rbxassetid://90498161006311",
        ["omega"] = "rbxassetid://70414080018786",
        ["option"] = "rbxassetid://100776883894054",
        ["orbit"] = "rbxassetid://108926136860562",
        ["origami"] = "rbxassetid://136020626667101",
        ["package"] = "rbxassetid://97261141732706",
        ["package-2"] = "rbxassetid://70394974762575",
        ["package-check"] = "rbxassetid://102374216055130",
        ["package-minus"] = "rbxassetid://114492858789692",
        ["package-open"] = "rbxassetid://132890233237818",
        ["package-plus"] = "rbxassetid://129261988138366",
        ["package-search"] = "rbxassetid://95465120894145",
        ["package-x"] = "rbxassetid://70818501607442",
        ["paint-bucket"] = "rbxassetid://124275586663284",
        ["paint-roller"] = "rbxassetid://115248074358348",
        ["paintbrush"] = "rbxassetid://125572663700289",
        ["paintbrush-vertical"] = "rbxassetid://105151296591292",
        ["palette"] = "rbxassetid://86350350950064",
        ["panda"] = "rbxassetid://132509022802512",
        ["panel-bottom"] = "rbxassetid://132127145048511",
        ["panel-bottom-close"] = "rbxassetid://74287004071159",
        ["panel-bottom-dashed"] = "rbxassetid://131084651621603",
        ["panel-bottom-open"] = "rbxassetid://107768659586540",
        ["panel-left"] = "rbxassetid://97419752870313",
        ["panel-left-close"] = "rbxassetid://126579818823552",
        ["panel-left-dashed"] = "rbxassetid://75536606374585",
        ["panel-left-open"] = "rbxassetid://111075816195767",
        ["panel-left-right-dashed"] = "rbxassetid://110100707973959",
        ["panel-right"] = "rbxassetid://116365035443156",
        ["panel-right-close"] = "rbxassetid://139528655524132",
        ["panel-right-dashed"] = "rbxassetid://94959793877311",
        ["panel-right-open"] = "rbxassetid://118114419142794",
        ["panel-top"] = "rbxassetid://75838479462875",
        ["panel-top-bottom-dashed"] = "rbxassetid://134737235653344",
        ["panel-top-close"] = "rbxassetid://83578325777808",
        ["panel-top-dashed"] = "rbxassetid://70522913169237",
        ["panel-top-open"] = "rbxassetid://137959875507454",
        ["panels-left-bottom"] = "rbxassetid://72996856149149",
        ["panels-right-bottom"] = "rbxassetid://90659068960726",
        ["panels-top-left"] = "rbxassetid://79858853850600",
        ["paperclip"] = "rbxassetid://92088291163453",
        ["parentheses"] = "rbxassetid://78950955173096",
        ["parking-meter"] = "rbxassetid://84652733960568",
        ["party-popper"] = "rbxassetid://111626795712193",
        ["pause"] = "rbxassetid://74873705394436",
        ["paw-print"] = "rbxassetid://112218825427601",
        ["pc-case"] = "rbxassetid://122978648019101",
        ["pen"] = "rbxassetid://72037878096321",
        ["pen-line"] = "rbxassetid://109108135755303",
        ["pen-off"] = "rbxassetid://84807123119438",
        ["pen-tool"] = "rbxassetid://106145404953445",
        ["pencil"] = "rbxassetid://137986121120732",
        ["pencil-line"] = "rbxassetid://88392917053533",
        ["pencil-off"] = "rbxassetid://103330927652832",
        ["pencil-ruler"] = "rbxassetid://110120288284597",
        ["pentagon"] = "rbxassetid://79184802179890",
        ["percent"] = "rbxassetid://130155041032013",
        ["person-standing"] = "rbxassetid://125020872044147",
        ["philippine-peso"] = "rbxassetid://91173798254675",
        ["phone"] = "rbxassetid://128804946640049",
        ["phone-call"] = "rbxassetid://70555587592860",
        ["phone-forwarded"] = "rbxassetid://113269614319737",
        ["phone-incoming"] = "rbxassetid://82863576359288",
        ["phone-missed"] = "rbxassetid://130156165198376",
        ["phone-off"] = "rbxassetid://133318623553383",
        ["phone-outgoing"] = "rbxassetid://104576478735825",
        ["pi"] = "rbxassetid://74936036243146",
        ["piano"] = "rbxassetid://85008880789520",
        ["pickaxe"] = "rbxassetid://105888023317688",
        ["picture-in-picture"] = "rbxassetid://80579597835123",
        ["picture-in-picture-2"] = "rbxassetid://112803319544468",
        ["piggy-bank"] = "rbxassetid://79498575790721",
        ["pilcrow"] = "rbxassetid://139512780392871",
        ["pilcrow-left"] = "rbxassetid://103803000849583",
        ["pilcrow-right"] = "rbxassetid://104881733911870",
        ["pill"] = "rbxassetid://73280534813448",
        ["pill-bottle"] = "rbxassetid://118394692404597",
        ["pin"] = "rbxassetid://120978111007514",
        ["pin-off"] = "rbxassetid://127696372451750",
        ["pipette"] = "rbxassetid://133167932934404",
        ["pizza"] = "rbxassetid://126964453193501",
        ["plane"] = "rbxassetid://126985561580989",
        ["plane-landing"] = "rbxassetid://122555692211889",
        ["plane-takeoff"] = "rbxassetid://117179478829575",
        ["play"] = "rbxassetid://135609604299893",
        ["plug"] = "rbxassetid://99782373064495",
        ["plug-2"] = "rbxassetid://97912386476366",
        ["plug-zap"] = "rbxassetid://74506269884055",
        ["plus"] = "rbxassetid://111774323017047",
        ["pocket"] = "rbxassetid://136686762542964",
        ["pocket-knife"] = "rbxassetid://134075428063965",
        ["podcast"] = "rbxassetid://109577075549215",
        ["pointer"] = "rbxassetid://92615117311099",
        ["pointer-off"] = "rbxassetid://95488389312794",
        ["popcorn"] = "rbxassetid://139446511232750",
        ["popsicle"] = "rbxassetid://112696318077073",
        ["pound-sterling"] = "rbxassetid://127482649469130",
        ["power"] = "rbxassetid://96479131758775",
        ["power-off"] = "rbxassetid://118768311012214",
        ["presentation"] = "rbxassetid://106134583757890",
        ["printer"] = "rbxassetid://76080649734247",
        ["printer-check"] = "rbxassetid://130273549443689",
        ["printer-x"] = "rbxassetid://103002721801548",
        ["projector"] = "rbxassetid://103281856385283",
        ["proportions"] = "rbxassetid://130046855997237",
        ["puzzle"] = "rbxassetid://136837798892463",
        ["pyramid"] = "rbxassetid://107811442374127",
        ["qr-code"] = "rbxassetid://105329945723350",
        ["quote"] = "rbxassetid://103271711590001",
        ["rabbit"] = "rbxassetid://98580518804206",
        ["radar"] = "rbxassetid://138528222906635",
        ["radiation"] = "rbxassetid://104499586848433",
        ["radical"] = "rbxassetid://132758286926047",
        ["radio"] = "rbxassetid://85611589536956",
        ["radio-off"] = "rbxassetid://80359258046586",
        ["radio-receiver"] = "rbxassetid://129598303378835",
        ["radio-tower"] = "rbxassetid://93958663130054",
        ["radius"] = "rbxassetid://89814505307129",
        ["rail-symbol"] = "rbxassetid://134295386306962",
        ["rainbow"] = "rbxassetid://132488862841895",
        ["rat"] = "rbxassetid://127400975953159",
        ["ratio"] = "rbxassetid://126369423897295",
        ["receipt"] = "rbxassetid://77877895901792",
        ["receipt-cent"] = "rbxassetid://91557573925201",
        ["receipt-euro"] = "rbxassetid://94015722210295",
        ["receipt-indian-rupee"] = "rbxassetid://89718170439990",
        ["receipt-japanese-yen"] = "rbxassetid://132472560758851",
        ["receipt-pound-sterling"] = "rbxassetid://73934967569625",
        ["receipt-russian-ruble"] = "rbxassetid://105164576936853",
        ["receipt-swiss-franc"] = "rbxassetid://72503668620116",
        ["receipt-text"] = "rbxassetid://138483536013737",
        ["receipt-turkish-lira"] = "rbxassetid://91950765836342",
        ["rectangle-circle"] = "rbxassetid://100642423153903",
        ["rectangle-ellipsis"] = "rbxassetid://112919953980965",
        ["rectangle-goggles"] = "rbxassetid://98605436666727",
        ["rectangle-horizontal"] = "rbxassetid://90224199814966",
        ["rectangle-vertical"] = "rbxassetid://117277050590967",
        ["recycle"] = "rbxassetid://140417023381961",
        ["redo"] = "rbxassetid://116150342119054",
        ["redo-2"] = "rbxassetid://70451039017914",
        ["redo-dot"] = "rbxassetid://94252981719732",
        ["refresh-ccw"] = "rbxassetid://117913330389477",
        ["refresh-ccw-dot"] = "rbxassetid://106702246753270",
        ["refresh-cw"] = "rbxassetid://138133190015277",
        ["refresh-cw-off"] = "rbxassetid://140179498843054",
        ["refrigerator"] = "rbxassetid://102614042652753",
        ["regex"] = "rbxassetid://100727200791841",
        ["remove-formatting"] = "rbxassetid://112833162022628",
        ["repeat"] = "rbxassetid://121886242955173",
        ["repeat-1"] = "rbxassetid://130144534857095",
        ["repeat-2"] = "rbxassetid://85927537182704",
        ["replace"] = "rbxassetid://128404082279430",
        ["replace-all"] = "rbxassetid://127862728198635",
        ["reply"] = "rbxassetid://109788633497028",
        ["reply-all"] = "rbxassetid://71723137343562",
        ["rewind"] = "rbxassetid://95205297521988",
        ["ribbon"] = "rbxassetid://94265331526851",
        ["road"] = "rbxassetid://120251329173530",
        ["rocket"] = "rbxassetid://87412317685854",
        ["rocking-chair"] = "rbxassetid://110420269495360",
        ["roller-coaster"] = "rbxassetid://112426178972099",
        ["rose"] = "rbxassetid://126336840238769",
        ["rotate-3d"] = "rbxassetid://76300551576392",
        ["rotate-ccw"] = "rbxassetid://110116685948665",
        ["rotate-ccw-key"] = "rbxassetid://74976035240976",
        ["rotate-ccw-square"] = "rbxassetid://90515853170424",
        ["rotate-cw"] = "rbxassetid://84183336178654",
        ["rotate-cw-square"] = "rbxassetid://77095448159303",
        ["route"] = "rbxassetid://89968303228953",
        ["route-off"] = "rbxassetid://106350402024079",
        ["router"] = "rbxassetid://102130331994471",
        ["rows-2"] = "rbxassetid://112556185960101",
        ["rows-3"] = "rbxassetid://117215586961375",
        ["rows-4"] = "rbxassetid://125646021959055",
        ["rss"] = "rbxassetid://131789058984793",
        ["ruler"] = "rbxassetid://81432445547423",
        ["ruler-dimension-line"] = "rbxassetid://70673861371412",
        ["russian-ruble"] = "rbxassetid://126357936542156",
        ["sailboat"] = "rbxassetid://87110567187540",
        ["salad"] = "rbxassetid://128864507821603",
        ["sandwich"] = "rbxassetid://104573187458917",
        ["satellite"] = "rbxassetid://134967053164645",
        ["satellite-dish"] = "rbxassetid://136742443888305",
        ["saudi-riyal"] = "rbxassetid://102282769104635",
        ["save"] = "rbxassetid://126116963775616",
        ["save-all"] = "rbxassetid://116946975799440",
        ["save-off"] = "rbxassetid://87085435778560",
        ["scale"] = "rbxassetid://108203682317477",
        ["scale-3d"] = "rbxassetid://72414199620352",
        ["scaling"] = "rbxassetid://122360365318466",
        ["scan"] = "rbxassetid://123104789658180",
        ["scan-barcode"] = "rbxassetid://96889457154761",
        ["scan-eye"] = "rbxassetid://99244790601968",
        ["scan-face"] = "rbxassetid://109959345069668",
        ["scan-heart"] = "rbxassetid://106280819776142",
        ["scan-line"] = "rbxassetid://126544908146540",
        ["scan-qr-code"] = "rbxassetid://105409149549927",
        ["scan-search"] = "rbxassetid://80009010551347",
        ["scan-text"] = "rbxassetid://73702396787766",
        ["school"] = "rbxassetid://76351530290068",
        ["scissors"] = "rbxassetid://118665510911274",
        ["scissors-line-dashed"] = "rbxassetid://122237447974173",
        ["scooter"] = "rbxassetid://100035452787934",
        ["screen-share"] = "rbxassetid://85137895705653",
        ["screen-share-off"] = "rbxassetid://107677572669805",
        ["scroll"] = "rbxassetid://74072101474951",
        ["scroll-text"] = "rbxassetid://97321022666868",
        ["search"] = "rbxassetid://121018724060431",
        ["search-alert"] = "rbxassetid://127597984617505",
        ["search-check"] = "rbxassetid://75442076191356",
        ["search-code"] = "rbxassetid://117114794592802",
        ["search-slash"] = "rbxassetid://96483932261041",
        ["search-x"] = "rbxassetid://137319957522951",
        ["section"] = "rbxassetid://91732188298948",
        ["send"] = "rbxassetid://127751956873796",
        ["send-horizontal"] = "rbxassetid://111734392411664",
        ["send-to-back"] = "rbxassetid://75340312862253",
        ["separator-horizontal"] = "rbxassetid://84864453699927",
        ["separator-vertical"] = "rbxassetid://84031801478581",
        ["server"] = "rbxassetid://92188766517878",
        ["server-cog"] = "rbxassetid://138470287250966",
        ["server-crash"] = "rbxassetid://132810618000212",
        ["server-off"] = "rbxassetid://114048751507723",
        ["settings"] = "rbxassetid://80758916183665",
        ["settings-2"] = "rbxassetid://135684703553372",
        ["shapes"] = "rbxassetid://129989433311409",
        ["share"] = "rbxassetid://87340985053299",
        ["share-2"] = "rbxassetid://71210767962065",
        ["sheet"] = "rbxassetid://134902122480171",
        ["shell"] = "rbxassetid://140212943563599",
        ["shelving-unit"] = "rbxassetid://80116568514793",
        ["shield"] = "rbxassetid://110987169760162",
        ["shield-alert"] = "rbxassetid://114995877719925",
        ["shield-ban"] = "rbxassetid://108765041044649",
        ["shield-check"] = "rbxassetid://87354736164608",
        ["shield-cog"] = "rbxassetid://129235695057857",
        ["shield-cog-corner"] = "rbxassetid://111694066132698",
        ["shield-ellipsis"] = "rbxassetid://114794739892123",
        ["shield-half"] = "rbxassetid://117842634172647",
        ["shield-minus"] = "rbxassetid://89965059528921",
        ["shield-off"] = "rbxassetid://133426959132690",
        ["shield-plus"] = "rbxassetid://100664857995498",
        ["shield-question-mark"] = "rbxassetid://135722075265150",
        ["shield-user"] = "rbxassetid://124832775645347",
        ["shield-x"] = "rbxassetid://73370117343811",
        ["ship"] = "rbxassetid://83995100553930",
        ["ship-wheel"] = "rbxassetid://130797795829448",
        ["shirt"] = "rbxassetid://106579555405966",
        ["shopping-bag"] = "rbxassetid://71885477293226",
        ["shopping-basket"] = "rbxassetid://138646411956433",
        ["shopping-cart"] = "rbxassetid://128420521375441",
        ["shovel"] = "rbxassetid://102465000512056",
        ["shower-head"] = "rbxassetid://75884944024117",
        ["shredder"] = "rbxassetid://122125164414463",
        ["shrimp"] = "rbxassetid://102625900815307",
        ["shrink"] = "rbxassetid://90953687918880",
        ["shrub"] = "rbxassetid://127326280714343",
        ["shuffle"] = "rbxassetid://132382786975101",
        ["sigma"] = "rbxassetid://126884244870899",
        ["signal"] = "rbxassetid://78424889355261",
        ["signal-high"] = "rbxassetid://130436670012270",
        ["signal-low"] = "rbxassetid://73674683500458",
        ["signal-medium"] = "rbxassetid://125003021367019",
        ["signal-zero"] = "rbxassetid://130045332414754",
        ["signature"] = "rbxassetid://114402748013000",
        ["signpost"] = "rbxassetid://106584743791433",
        ["signpost-big"] = "rbxassetid://115780185675001",
        ["siren"] = "rbxassetid://134210267818039",
        ["skip-back"] = "rbxassetid://70466132711334",
        ["skip-forward"] = "rbxassetid://124844823753990",
        ["skull"] = "rbxassetid://137726256442333",
        ["slack"] = "rbxassetid://96089719516736",
        ["slash"] = "rbxassetid://117792185664263",
        ["slice"] = "rbxassetid://95810504278179",
        ["sliders-horizontal"] = "rbxassetid://85538382643347",
        ["sliders-vertical"] = "rbxassetid://101190569086853",
        ["smartphone"] = "rbxassetid://96623008834511",
        ["smartphone-charging"] = "rbxassetid://102837532613995",
        ["smartphone-nfc"] = "rbxassetid://82326425754446",
        ["smile"] = "rbxassetid://105880397565283",
        ["smile-plus"] = "rbxassetid://131981881472144",
        ["snail"] = "rbxassetid://70904536548363",
        ["snowflake"] = "rbxassetid://101235206534566",
        ["soap-dispenser-droplet"] = "rbxassetid://77258480479465",
        ["sofa"] = "rbxassetid://114427687218324",
        ["solar-panel"] = "rbxassetid://132448188047921",
        ["soup"] = "rbxassetid://115092551871618",
        ["space"] = "rbxassetid://87072088914178",
        ["spade"] = "rbxassetid://131444449466462",
        ["sparkle"] = "rbxassetid://111044800239623",
        ["sparkles"] = "rbxassetid://138635884129147",
        ["speaker"] = "rbxassetid://96227183003618",
        ["speech"] = "rbxassetid://87013139446349",
        ["spell-check"] = "rbxassetid://91913483031334",
        ["spell-check-2"] = "rbxassetid://81556731785534",
        ["spline"] = "rbxassetid://129406685807412",
        ["spline-pointer"] = "rbxassetid://84842840956804",
        ["split"] = "rbxassetid://105112438805988",
        ["spool"] = "rbxassetid://124541981347743",
        ["sport-shoe"] = "rbxassetid://120495992692630",
        ["spotlight"] = "rbxassetid://77571742539344",
        ["spray-can"] = "rbxassetid://128372039366326",
        ["sprout"] = "rbxassetid://100091687832508",
        ["square"] = "rbxassetid://86304921356806",
        ["square-activity"] = "rbxassetid://89496630185293",
        ["square-arrow-down"] = "rbxassetid://135962519626588",
        ["square-arrow-down-left"] = "rbxassetid://108194680296901",
        ["square-arrow-down-right"] = "rbxassetid://99403846801050",
        ["square-arrow-left"] = "rbxassetid://111671474549238",
        ["square-arrow-out-down-left"] = "rbxassetid://125714881756353",
        ["square-arrow-out-down-right"] = "rbxassetid://89971003001390",
        ["square-arrow-out-up-left"] = "rbxassetid://103759986579087",
        ["square-arrow-out-up-right"] = "rbxassetid://91221896066807",
        ["square-arrow-right"] = "rbxassetid://113920471701361",
        ["square-arrow-right-enter"] = "rbxassetid://138867831495334",
        ["square-arrow-right-exit"] = "rbxassetid://133688575845430",
        ["square-arrow-up"] = "rbxassetid://106998604646718",
        ["square-arrow-up-left"] = "rbxassetid://112424670290693",
        ["square-arrow-up-right"] = "rbxassetid://76602291406940",
        ["square-asterisk"] = "rbxassetid://89186832353625",
        ["square-bottom-dashed-scissors"] = "rbxassetid://79076980104803",
        ["square-centerline-dashed-horizontal"] = "rbxassetid://77780104374341",
        ["square-centerline-dashed-vertical"] = "rbxassetid://107878435803525",
        ["square-chart-gantt"] = "rbxassetid://104034017316411",
        ["square-check"] = "rbxassetid://134682053539509",
        ["square-check-big"] = "rbxassetid://115320390907184",
        ["square-chevron-down"] = "rbxassetid://91032307924592",
        ["square-chevron-left"] = "rbxassetid://73143404829510",
        ["square-chevron-right"] = "rbxassetid://90612077729930",
        ["square-chevron-up"] = "rbxassetid://85565910197337",
        ["square-code"] = "rbxassetid://81604576616881",
        ["square-dashed"] = "rbxassetid://136905537847606",
        ["square-dashed-bottom"] = "rbxassetid://101102319625624",
        ["square-dashed-bottom-code"] = "rbxassetid://100354801563230",
        ["square-dashed-kanban"] = "rbxassetid://90388067649847",
        ["square-dashed-mouse-pointer"] = "rbxassetid://121016142178467",
        ["square-dashed-top-solid"] = "rbxassetid://117157577548540",
        ["square-divide"] = "rbxassetid://99894657101970",
        ["square-dot"] = "rbxassetid://116613421354866",
        ["square-equal"] = "rbxassetid://110283363706707",
        ["square-function"] = "rbxassetid://86075219551088",
        ["square-kanban"] = "rbxassetid://114537101260131",
        ["square-library"] = "rbxassetid://73810931222081",
        ["square-m"] = "rbxassetid://117662700410577",
        ["square-menu"] = "rbxassetid://104067089444415",
        ["square-minus"] = "rbxassetid://116764432015770",
        ["square-mouse-pointer"] = "rbxassetid://76141850603920",
        ["square-parking"] = "rbxassetid://133116656122387",
        ["square-parking-off"] = "rbxassetid://100857293535141",
        ["square-pause"] = "rbxassetid://86608552787615",
        ["square-pen"] = "rbxassetid://120239476110475",
        ["square-percent"] = "rbxassetid://87111930314567",
        ["square-pi"] = "rbxassetid://75383328781618",
        ["square-pilcrow"] = "rbxassetid://131854284699367",
        ["square-play"] = "rbxassetid://108186325238481",
        ["square-plus"] = "rbxassetid://114713264461873",
        ["square-power"] = "rbxassetid://129240437805187",
        ["square-radical"] = "rbxassetid://132645931868292",
        ["square-round-corner"] = "rbxassetid://104592745113567",
        ["square-scissors"] = "rbxassetid://110601255612411",
        ["square-sigma"] = "rbxassetid://113231244246816",
        ["square-slash"] = "rbxassetid://105477013908757",
        ["square-split-horizontal"] = "rbxassetid://76095370148660",
        ["square-split-vertical"] = "rbxassetid://88589192032058",
        ["square-square"] = "rbxassetid://136555087357875",
        ["square-stack"] = "rbxassetid://100463396619394",
        ["square-star"] = "rbxassetid://94506958703720",
        ["square-stop"] = "rbxassetid://80018708472943",
        ["square-terminal"] = "rbxassetid://83969264476798",
        ["square-user"] = "rbxassetid://70771214183445",
        ["square-user-round"] = "rbxassetid://86484997229302",
        ["square-x"] = "rbxassetid://125136183850190",
        ["squares-exclude"] = "rbxassetid://102345385822324",
        ["squares-intersect"] = "rbxassetid://120869602570119",
        ["squares-subtract"] = "rbxassetid://131484650948795",
        ["squares-unite"] = "rbxassetid://96673080107843",
        ["squircle"] = "rbxassetid://82426632573807",
        ["squircle-dashed"] = "rbxassetid://129936702532522",
        ["squirrel"] = "rbxassetid://112864252085343",
        ["stamp"] = "rbxassetid://92370779813368",
        ["star"] = "rbxassetid://136141469398409",
        ["star-half"] = "rbxassetid://117449275562979",
        ["star-off"] = "rbxassetid://75742832732503",
        ["step-back"] = "rbxassetid://108672750005121",
        ["step-forward"] = "rbxassetid://126131872136145",
        ["stethoscope"] = "rbxassetid://122331031702148",
        ["sticker"] = "rbxassetid://79938203791608",
        ["sticky-note"] = "rbxassetid://111894074643919",
        ["stone"] = "rbxassetid://135161057497830",
        ["store"] = "rbxassetid://90338129673705",
        ["stretch-horizontal"] = "rbxassetid://87665042192343",
        ["stretch-vertical"] = "rbxassetid://95265463417122",
        ["strikethrough"] = "rbxassetid://103417324549613",
        ["subscript"] = "rbxassetid://74553514785183",
        ["sun"] = "rbxassetid://110150589884127",
        ["sun-dim"] = "rbxassetid://129141645592715",
        ["sun-medium"] = "rbxassetid://130278807964710",
        ["sun-moon"] = "rbxassetid://75752898854559",
        ["sun-snow"] = "rbxassetid://112791898014579",
        ["sunrise"] = "rbxassetid://134705665494098",
        ["sunset"] = "rbxassetid://75904872203588",
        ["superscript"] = "rbxassetid://96887696590118",
        ["swatch-book"] = "rbxassetid://126786244872453",
        ["swiss-franc"] = "rbxassetid://113497920041625",
        ["switch-camera"] = "rbxassetid://76841154349737",
        ["sword"] = "rbxassetid://124448418211665",
        ["swords"] = "rbxassetid://81872698913435",
        ["syringe"] = "rbxassetid://123891270479254",
        ["table"] = "rbxassetid://109109148250737",
        ["table-2"] = "rbxassetid://95751552281545",
        ["table-cells-merge"] = "rbxassetid://95363715175258",
        ["table-cells-split"] = "rbxassetid://114799086088649",
        ["table-columns-split"] = "rbxassetid://111011625447949",
        ["table-of-contents"] = "rbxassetid://135044763275414",
        ["table-properties"] = "rbxassetid://125062886015372",
        ["table-rows-split"] = "rbxassetid://96443733673997",
        ["tablet"] = "rbxassetid://128403991264386",
        ["tablet-smartphone"] = "rbxassetid://133680859813404",
        ["tablets"] = "rbxassetid://80835787970735",
        ["tag"] = "rbxassetid://129104970103940",
        ["tags"] = "rbxassetid://107179263080798",
        ["tally-1"] = "rbxassetid://115301298241643",
        ["tally-2"] = "rbxassetid://110363186864027",
        ["tally-3"] = "rbxassetid://97655344572540",
        ["tally-4"] = "rbxassetid://102633494371890",
        ["tally-5"] = "rbxassetid://88031817475886",
        ["tangent"] = "rbxassetid://123263132981724",
        ["target"] = "rbxassetid://87563802520297",
        ["telescope"] = "rbxassetid://91755049143647",
        ["tent"] = "rbxassetid://109779587826330",
        ["tent-tree"] = "rbxassetid://76698322463977",
        ["terminal"] = "rbxassetid://106783148545356",
        ["test-tube"] = "rbxassetid://98801015650164",
        ["test-tube-diagonal"] = "rbxassetid://75662704378840",
        ["test-tubes"] = "rbxassetid://92555361447433",
        ["text-align-center"] = "rbxassetid://84051028246390",
        ["text-align-end"] = "rbxassetid://130041738343555",
        ["text-align-justify"] = "rbxassetid://80279880143030",
        ["text-align-start"] = "rbxassetid://134489585487649",
        ["text-cursor"] = "rbxassetid://115984654447300",
        ["text-cursor-input"] = "rbxassetid://107551944047171",
        ["text-initial"] = "rbxassetid://129458097472087",
        ["text-quote"] = "rbxassetid://139278366448736",
        ["text-search"] = "rbxassetid://92345384671606",
        ["text-select"] = "rbxassetid://117087320884956",
        ["text-wrap"] = "rbxassetid://114804318314018",
        ["theater"] = "rbxassetid://108558145549163",
        ["thermometer"] = "rbxassetid://106546011492311",
        ["thermometer-snowflake"] = "rbxassetid://121876188028425",
        ["thermometer-sun"] = "rbxassetid://106693240074310",
        ["thumbs-down"] = "rbxassetid://87794009914015",
        ["thumbs-up"] = "rbxassetid://111137070767020",
        ["ticket"] = "rbxassetid://126527071492145",
        ["ticket-check"] = "rbxassetid://105428777212507",
        ["ticket-minus"] = "rbxassetid://78966299769328",
        ["ticket-percent"] = "rbxassetid://80834774406405",
        ["ticket-plus"] = "rbxassetid://110086734392189",
        ["ticket-slash"] = "rbxassetid://89045681172265",
        ["ticket-x"] = "rbxassetid://88674114109926",
        ["tickets"] = "rbxassetid://135268612687833",
        ["tickets-plane"] = "rbxassetid://100367018248695",
        ["timer"] = "rbxassetid://85473888890506",
        ["timer-off"] = "rbxassetid://110916370767271",
        ["timer-reset"] = "rbxassetid://110052125369932",
        ["toggle-left"] = "rbxassetid://85887872573050",
        ["toggle-right"] = "rbxassetid://90411952142550",
        ["toilet"] = "rbxassetid://80930782432931",
        ["tool-case"] = "rbxassetid://87533537832522",
        ["toolbox"] = "rbxassetid://85341033903792",
        ["tornado"] = "rbxassetid://88358291515768",
        ["torus"] = "rbxassetid://70855707283051",
        ["touchpad"] = "rbxassetid://74882354908014",
        ["touchpad-off"] = "rbxassetid://78784008075456",
        ["towel-rack"] = "rbxassetid://125223915620991",
        ["tower-control"] = "rbxassetid://95937619060532",
        ["toy-brick"] = "rbxassetid://86293483924633",
        ["tractor"] = "rbxassetid://103376704722051",
        ["traffic-cone"] = "rbxassetid://74110220470369",
        ["train-front"] = "rbxassetid://125237934215370",
        ["train-front-tunnel"] = "rbxassetid://105194827005114",
        ["train-track"] = "rbxassetid://77451032453723",
        ["tram-front"] = "rbxassetid://93315182364998",
        ["transgender"] = "rbxassetid://135530817673639",
        ["trash"] = "rbxassetid://106723740584310",
        ["trash-2"] = "rbxassetid://109843431391323",
        ["tree-deciduous"] = "rbxassetid://123124389219004",
        ["tree-palm"] = "rbxassetid://103846705893963",
        ["tree-pine"] = "rbxassetid://124662547202594",
        ["trees"] = "rbxassetid://121203841375919",
        ["trello"] = "rbxassetid://130987241149527",
        ["trending-down"] = "rbxassetid://139309232226438",
        ["trending-up"] = "rbxassetid://81819858538839",
        ["trending-up-down"] = "rbxassetid://85083293981691",
        ["triangle"] = "rbxassetid://126330486745540",
        ["triangle-alert"] = "rbxassetid://125920361880643",
        ["triangle-dashed"] = "rbxassetid://124324079103935",
        ["triangle-right"] = "rbxassetid://116930791412791",
        ["trophy"] = "rbxassetid://131545003268773",
        ["truck"] = "rbxassetid://86662707764771",
        ["truck-electric"] = "rbxassetid://111873446387359",
        ["turkish-lira"] = "rbxassetid://114589876174070",
        ["turntable"] = "rbxassetid://129870346487856",
        ["turtle"] = "rbxassetid://118295081560334",
        ["tv"] = "rbxassetid://135687724791776",
        ["tv-minimal"] = "rbxassetid://100382201729427",
        ["tv-minimal-play"] = "rbxassetid://99201833426972",
        ["twitch"] = "rbxassetid://71383308134888",
        ["twitter"] = "rbxassetid://88791703276842",
        ["type"] = "rbxassetid://133543553793564",
        ["type-outline"] = "rbxassetid://80108627791690",
        ["umbrella"] = "rbxassetid://127502210274589",
        ["umbrella-off"] = "rbxassetid://72395143739955",
        ["underline"] = "rbxassetid://123709229216544",
        ["undo"] = "rbxassetid://111258459077271",
        ["undo-2"] = "rbxassetid://113885292059932",
        ["undo-dot"] = "rbxassetid://132055277744844",
        ["unfold-horizontal"] = "rbxassetid://117128358526398",
        ["unfold-vertical"] = "rbxassetid://116593025265499",
        ["ungroup"] = "rbxassetid://106674800451003",
        ["university"] = "rbxassetid://84652528263642",
        ["unlink"] = "rbxassetid://139835795227752",
        ["unlink-2"] = "rbxassetid://128131898892572",
        ["unplug"] = "rbxassetid://90171381619874",
        ["upload"] = "rbxassetid://138212042425501",
        ["usb"] = "rbxassetid://117230058949613",
        ["user"] = "rbxassetid://81589895647169",
        ["user-check"] = "rbxassetid://81775205032725",
        ["user-cog"] = "rbxassetid://92795491530865",
        ["user-key"] = "rbxassetid://105403041782190",
        ["user-lock"] = "rbxassetid://78892639693821",
        ["user-minus"] = "rbxassetid://126976941957511",
        ["user-pen"] = "rbxassetid://87445472574836",
        ["user-plus"] = "rbxassetid://118514469915884",
        ["user-round"] = "rbxassetid://136485052187963",
        ["user-round-check"] = "rbxassetid://118794737621941",
        ["user-round-cog"] = "rbxassetid://78239503290053",
        ["user-round-key"] = "rbxassetid://124547549008939",
        ["user-round-minus"] = "rbxassetid://98944176636447",
        ["user-round-pen"] = "rbxassetid://108155244324878",
        ["user-round-plus"] = "rbxassetid://113301899567470",
        ["user-round-search"] = "rbxassetid://71565774381870",
        ["user-round-x"] = "rbxassetid://122367980560930",
        ["user-search"] = "rbxassetid://101335649828115",
        ["user-star"] = "rbxassetid://98777846316000",
        ["user-x"] = "rbxassetid://139748155894754",
        ["users"] = "rbxassetid://115398113982385",
        ["users-round"] = "rbxassetid://103005444008339",
        ["utensils"] = "rbxassetid://139952569804235",
        ["utensils-crossed"] = "rbxassetid://109520762270383",
        ["utility-pole"] = "rbxassetid://101965541238242",
        ["van"] = "rbxassetid://122066377022942",
        ["variable"] = "rbxassetid://104743088438151",
        ["vault"] = "rbxassetid://108049164599845",
        ["vector-square"] = "rbxassetid://86713728565344",
        ["vegan"] = "rbxassetid://119489190688082",
        ["venetian-mask"] = "rbxassetid://102636443033920",
        ["venus"] = "rbxassetid://82891342220859",
        ["venus-and-mars"] = "rbxassetid://120227752103771",
        ["vibrate"] = "rbxassetid://108330910738733",
        ["vibrate-off"] = "rbxassetid://113446447326246",
        ["video"] = "rbxassetid://107587444636945",
        ["video-off"] = "rbxassetid://132239189859305",
        ["videotape"] = "rbxassetid://114816894323398",
        ["view"] = "rbxassetid://118717253976805",
        ["voicemail"] = "rbxassetid://134313454010227",
        ["volleyball"] = "rbxassetid://83889351124153",
        ["volume"] = "rbxassetid://103236289817396",
        ["volume-1"] = "rbxassetid://98514588731639",
        ["volume-2"] = "rbxassetid://89344380902620",
        ["volume-off"] = "rbxassetid://103047478058767",
        ["volume-x"] = "rbxassetid://139252359189540",
        ["vote"] = "rbxassetid://89409762851246",
        ["wallet"] = "rbxassetid://132331555762628",
        ["wallet-cards"] = "rbxassetid://129728715308337",
        ["wallet-minimal"] = "rbxassetid://137800448816116",
        ["wallpaper"] = "rbxassetid://74682121235494",
        ["wand"] = "rbxassetid://114580617777835",
        ["wand-sparkles"] = "rbxassetid://82546429942392",
        ["warehouse"] = "rbxassetid://78388887451080",
        ["washing-machine"] = "rbxassetid://104194127573858",
        ["watch"] = "rbxassetid://130544621618405",
        ["waves"] = "rbxassetid://96340135183647",
        ["waves-arrow-down"] = "rbxassetid://129215220911792",
        ["waves-arrow-up"] = "rbxassetid://102314705716217",
        ["waves-ladder"] = "rbxassetid://101808619355514",
        ["waypoints"] = "rbxassetid://102450133666017",
        ["webcam"] = "rbxassetid://104148487911129",
        ["webhook"] = "rbxassetid://112812457747322",
        ["webhook-off"] = "rbxassetid://96370548093471",
        ["weight"] = "rbxassetid://103860559844854",
        ["weight-tilde"] = "rbxassetid://112081212176951",
        ["wheat"] = "rbxassetid://85261952080359",
        ["wheat-off"] = "rbxassetid://133294844612307",
        ["whole-word"] = "rbxassetid://90111083954485",
        ["wifi"] = "rbxassetid://104669375183960",
        ["wifi-cog"] = "rbxassetid://110500263326209",
        ["wifi-high"] = "rbxassetid://81954601342139",
        ["wifi-low"] = "rbxassetid://138217335635913",
        ["wifi-off"] = "rbxassetid://74113634330106",
        ["wifi-pen"] = "rbxassetid://91290205064712",
        ["wifi-sync"] = "rbxassetid://84043971055177",
        ["wifi-zero"] = "rbxassetid://124286465246123",
        ["wind"] = "rbxassetid://114551690399915",
        ["wind-arrow-down"] = "rbxassetid://127753987414870",
        ["wine"] = "rbxassetid://115743721332829",
        ["wine-off"] = "rbxassetid://108294164302317",
        ["workflow"] = "rbxassetid://99186544029189",
        ["worm"] = "rbxassetid://115752311548091",
        ["wrench"] = "rbxassetid://112148279212860",
        ["x"] = "rbxassetid://110786993356448",
        ["x-line-top"] = "rbxassetid://140592656289509",
        ["youtube"] = "rbxassetid://123663668456341",
        ["zap"] = "rbxassetid://130551565616516",
        ["zap-off"] = "rbxassetid://81385483183652",
        ["zodiac-aquarius"] = "rbxassetid://74560047770362",
        ["zodiac-aries"] = "rbxassetid://73255859670234",
        ["zodiac-cancer"] = "rbxassetid://131985162532947",
        ["zodiac-capricorn"] = "rbxassetid://97859568140652",
        ["zodiac-gemini"] = "rbxassetid://80997588122992",
        ["zodiac-leo"] = "rbxassetid://75509406718106",
        ["zodiac-libra"] = "rbxassetid://113222735060218",
        ["zodiac-ophiuchus"] = "rbxassetid://129180108892480",
        ["zodiac-pisces"] = "rbxassetid://95845819440327",
        ["zodiac-sagittarius"] = "rbxassetid://82651026742181",
        ["zodiac-scorpio"] = "rbxassetid://113640924054631",
        ["zodiac-taurus"] = "rbxassetid://123053219704400",
        ["zodiac-virgo"] = "rbxassetid://99462994613661",
        ["zoom-in"] = "rbxassetid://127956924984803",
        ["zoom-out"] = "rbxassetid://108334162607319",
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
        if screenGui and screenGui.Parent then
            screenGui:SetAttribute("UISoundsEnabled", premiumFx.uiSoundsEnabled)
        end

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
