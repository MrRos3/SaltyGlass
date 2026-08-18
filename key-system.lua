local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    error("SaltyGlass Key System must run on the Roblox client.", 0)
end

local playerGui = player:WaitForChild("PlayerGui")

local KeySystem = {
    Version = "1.3.0",
}

local DEFAULTS = {
    Title = "SALTYGLASS",
    Subtitle = "SECURE ACCESS",
    Description = "Enter your access key to unlock the interface.",
    Placeholder = "Enter access key...",
    Accent = Color3.fromRGB(139, 124, 255),
    Keys = { "SALTY-ACCESS" },
    Sounds = true,
    Blur = true,
    ReduceMotion = false,
    MaxAttempts = 0,
    SuccessDelay = 0.34,
    ToggleKey = Enum.KeyCode.RightShift,
    ClickSoundId = "rbxassetid://4307186075",
    HoverSoundId = "rbxassetid://408524543",
}

local C = {
    Base = Color3.fromRGB(9, 13, 24),
    Mid = Color3.fromRGB(17, 24, 42),
    Light = Color3.fromRGB(27, 36, 64),
    Edge = Color3.new(1, 1, 1),
    Text = Color3.fromRGB(248, 249, 255),
    Sub = Color3.fromRGB(190, 197, 221),
    Muted = Color3.fromRGB(125, 134, 165),
    Success = Color3.fromRGB(109, 255, 168),
    Danger = Color3.fromRGB(255, 107, 122),
}

local function merge(options)
    local result = {}
    for key, value in pairs(DEFAULTS) do
        result[key] = value
    end
    if type(options) == "table" then
        for key, value in pairs(options) do
            result[key] = value
        end
    end
    return result
end

local function round(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function stroke(parent, transparency, thickness, color)
    local value = Instance.new("UIStroke")
    value.Color = color or C.Edge
    value.Transparency = transparency or 0.72
    value.Thickness = thickness or 1
    value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    value.Parent = parent
    return value
end

local function scale(parent)
    local value = Instance.new("UIScale")
    value.Scale = 1
    value.Parent = parent
    return value
end

local function tween(reduceMotion, target, duration, properties)
    if reduceMotion then
        for property, value in pairs(properties) do
            target[property] = value
        end
        return nil
    end

    local motion = TweenService:Create(
        target,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    motion:Play()
    return motion
end

local function playSound(config, soundId, volume)
    if not config.Sounds or not soundId or soundId == "" then
        return
    end

    pcall(function()
        local sound = Instance.new("Sound")
        sound.Name = "SaltyUISound"
        sound.SoundId = soundId
        sound.Volume = volume or 0.2
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

local function loadIcons()
    local icons = {}

    local ok, result = pcall(function()
        local source = game:HttpGet(
            "https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/icons/Lucide.lua"
        )

        local chunk, compileError = loadstring(source)
        if not chunk then
            error(compileError, 0)
        end

        return chunk()
    end)

    if ok and type(result) == "table" then
        icons = result
    end

    return icons
end

local function icon(parent, icons, name, size, color, zIndex)
    local image = Instance.new("ImageLabel")
    image.Name = "Lucide_" .. name
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromOffset(size, size)
    image.Image = icons[name] or ""
    image.ImageColor3 = color or C.Text
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = zIndex or 10
    image:SetAttribute("LucideName", name)
    image.Parent = parent
    return image
end

local function makeKeySet(config)
    local keys = {}

    if type(config.Key) == "string" then
        keys[config.Key] = true
    end

    if type(config.Keys) == "table" then
        for _, key in ipairs(config.Keys) do
            if type(key) == "string" then
                keys[key] = true
            end
        end
    end

    return keys
end

function KeySystem.Open(options)
    local config = merge(options)
    local icons = loadIcons()
    local validKeys = makeKeySet(config)

    local oldGui = playerGui:FindFirstChild("SaltyKeySystemGui")
    if oldGui then
        oldGui:Destroy()
    end

    local oldBlur = Lighting:FindFirstChild("SaltyKeySystemBlur")
    if oldBlur then
        oldBlur:Destroy()
    end

    local state = {
        destroyed = false,
        busy = false,
        attempts = 0,
        connections = {},
    }

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(state.connections, connection)
        return connection
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "SaltyKeySystemBlur"
    blur.Size = config.Blur and 18 or 0
    blur.Parent = Lighting

    local gui = Instance.new("ScreenGui")
    gui.Name = "SaltyKeySystemGui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 900
    gui.Parent = playerGui

    local backdrop = Instance.new("TextButton")
    backdrop.Name = "BackdropInputSink"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.36
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.Active = true
    backdrop.ZIndex = 1
    backdrop.Parent = gui

    local shadow = Instance.new("Frame")
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 9)
    shadow.Size = UDim2.fromOffset(522, 352)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.52
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 2
    shadow.Parent = gui
    round(shadow, 30)

    local card = Instance.new("Frame")
    card.Name = "KeyCard"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(520, 350)
    card.BackgroundColor3 = C.Base
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 4
    card.Parent = gui
    round(card, 28)

    local cardStroke = stroke(card, 0.38, 1.35)
    local cardScale = scale(card)

    local glassGradient = Instance.new("UIGradient")
    glassGradient.Rotation = 52
    glassGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 48, 78)),
        ColorSequenceKeypoint.new(0.34, C.Mid),
        ColorSequenceKeypoint.new(0.72, C.Base),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 17)),
    })
    glassGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.24),
        NumberSequenceKeypoint.new(0.42, 0.52),
        NumberSequenceKeypoint.new(1, 0.82),
    })
    glassGradient.Parent = card

    local inner = Instance.new("Frame")
    inner.Position = UDim2.fromOffset(1, 1)
    inner.Size = UDim2.new(1, -2, 1, -2)
    inner.BackgroundTransparency = 1
    inner.BorderSizePixel = 0
    inner.ZIndex = 5
    inner.Parent = card
    round(inner, 27)
    stroke(inner, 0.88, 1)

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(28, 26)
    content.Size = UDim2.new(1, -56, 1, -52)
    content.BackgroundTransparency = 1
    content.ZIndex = 7
    content.Parent = card

    local emblem = Instance.new("Frame")
    emblem.Size = UDim2.fromOffset(50, 50)
    emblem.BackgroundColor3 = C.Light
    emblem.BackgroundTransparency = 0.20
    emblem.BorderSizePixel = 0
    emblem.ZIndex = 8
    emblem.Parent = content
    round(emblem, 15)
    local emblemStroke = stroke(emblem, 0.52, 1)

    local keyIcon = icon(emblem, icons, "key-round", 20, config.Accent, 10)
    if keyIcon.Image == "" then
        keyIcon.Image = icons.key or ""
        keyIcon:SetAttribute("LucideName", "key")
    end
    keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    keyIcon.Position = UDim2.fromScale(0.5, 0.5)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(68, 2)
    title.Size = UDim2.new(1, -204, 0, 24)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = config.Title
    title.TextColor3 = C.Text
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 9
    title.Parent = content

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(68, 28)
    subtitle.Size = UDim2.new(1, -204, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = string.upper(config.Subtitle)
    subtitle.TextColor3 = config.Accent
    subtitle.TextSize = 8
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 9
    subtitle.Parent = content

    local protected = Instance.new("Frame")
    protected.AnchorPoint = Vector2.new(1, 0)
    protected.Position = UDim2.new(1, 0, 0, 8)
    protected.Size = UDim2.fromOffset(112, 30)
    protected.BackgroundColor3 = C.Light
    protected.BackgroundTransparency = 0.42
    protected.BorderSizePixel = 0
    protected.ZIndex = 8
    protected.Parent = content
    round(protected, 10)
    stroke(protected, 0.72, 1)

    local protectedIcon = icon(protected, icons, "shield-check", 13, config.Accent, 10)
    protectedIcon.AnchorPoint = Vector2.new(0, 0.5)
    protectedIcon.Position = UDim2.new(0, 10, 0.5, 0)

    local protectedText = Instance.new("TextLabel")
    protectedText.Position = UDim2.fromOffset(31, 0)
    protectedText.Size = UDim2.new(1, -38, 1, 0)
    protectedText.BackgroundTransparency = 1
    protectedText.Font = Enum.Font.GothamBold
    protectedText.Text = "PROTECTED"
    protectedText.TextColor3 = C.Sub
    protectedText.TextSize = 8
    protectedText.TextXAlignment = Enum.TextXAlignment.Left
    protectedText.ZIndex = 10
    protectedText.Parent = protected

    local description = Instance.new("TextLabel")
    description.Position = UDim2.fromOffset(0, 70)
    description.Size = UDim2.new(1, 0, 0, 18)
    description.BackgroundTransparency = 1
    description.Font = Enum.Font.Gotham
    description.Text = config.Description
    description.TextColor3 = C.Sub
    description.TextSize = 10
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.ZIndex = 9
    description.Parent = content

    local inputShell = Instance.new("Frame")
    inputShell.Position = UDim2.fromOffset(0, 100)
    inputShell.Size = UDim2.new(1, 0, 0, 56)
    inputShell.BackgroundColor3 = C.Mid
    inputShell.BackgroundTransparency = 0.28
    inputShell.BorderSizePixel = 0
    inputShell.ZIndex = 8
    inputShell.Parent = content
    round(inputShell, 14)
    local inputStroke = stroke(inputShell, 0.62, 1)

    local lockIcon = icon(inputShell, icons, "lock-keyhole", 16, C.Muted, 10)
    if lockIcon.Image == "" then
        lockIcon.Image = icons.lock or ""
        lockIcon:SetAttribute("LucideName", "lock")
    end
    lockIcon.AnchorPoint = Vector2.new(0, 0.5)
    lockIcon.Position = UDim2.new(0, 17, 0.5, 0)

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(48, 0)
    input.Size = UDim2.new(1, -128, 1, 0)
    input.BackgroundTransparency = 1
    input.ClearTextOnFocus = false
    input.Font = Enum.Font.GothamMedium
    input.PlaceholderText = config.Placeholder
    input.PlaceholderColor3 = C.Muted
    input.Text = ""
    input.TextColor3 = C.Text
    input.TextSize = 11
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ZIndex = 10
    input.Parent = inputShell

    local accessChip = Instance.new("Frame")
    accessChip.AnchorPoint = Vector2.new(1, 0.5)
    accessChip.Position = UDim2.new(1, -11, 0.5, 0)
    accessChip.Size = UDim2.fromOffset(66, 28)
    accessChip.BackgroundColor3 = config.Accent
    accessChip.BackgroundTransparency = 0.86
    accessChip.BorderSizePixel = 0
    accessChip.ZIndex = 10
    accessChip.Parent = inputShell
    round(accessChip, 9)
    stroke(accessChip, 0.78, 1, config.Accent)

    local accessText = Instance.new("TextLabel")
    accessText.Size = UDim2.fromScale(1, 1)
    accessText.BackgroundTransparency = 1
    accessText.Font = Enum.Font.GothamBold
    accessText.Text = "ACCESS"
    accessText.TextColor3 = config.Accent
    accessText.TextSize = 7
    accessText.ZIndex = 11
    accessText.Parent = accessChip

    local status = Instance.new("Frame")
    status.Position = UDim2.fromOffset(0, 168)
    status.Size = UDim2.new(1, 0, 0, 34)
    status.BackgroundColor3 = C.Light
    status.BackgroundTransparency = 0.58
    status.BorderSizePixel = 0
    status.ZIndex = 8
    status.Parent = content
    round(status, 11)
    local statusStroke = stroke(status, 0.82, 1)

    local statusIcon = icon(status, icons, "shield-check", 12, config.Accent, 10)
    statusIcon.AnchorPoint = Vector2.new(0, 0.5)
    statusIcon.Position = UDim2.new(0, 12, 0.5, 0)

    local statusText = Instance.new("TextLabel")
    statusText.Position = UDim2.fromOffset(33, 0)
    statusText.Size = UDim2.new(1, -45, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Ready for verification"
    statusText.TextColor3 = C.Sub
    statusText.TextSize = 9
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 10
    statusText.Parent = status

    local verify = Instance.new("TextButton")
    verify.Position = UDim2.fromOffset(0, 214)
    verify.Size = UDim2.new(1, 0, 0, 52)
    verify.BackgroundColor3 = config.Accent
    verify.BackgroundTransparency = 0.08
    verify.BorderSizePixel = 0
    verify.AutoButtonColor = false
    verify.Text = ""
    verify.ZIndex = 8
    verify.Parent = content
    round(verify, 14)
    local verifyStroke = stroke(verify, 0.46, 1)
    local verifyScale = scale(verify)

    local verifyGradient = Instance.new("UIGradient")
    verifyGradient.Rotation = 0
    verifyGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, config.Accent:Lerp(Color3.new(0, 0, 0), 0.04)),
        ColorSequenceKeypoint.new(0.55, config.Accent),
        ColorSequenceKeypoint.new(1, config.Accent:Lerp(C.Text, 0.10)),
    })
    verifyGradient.Parent = verify

    local verifyText = Instance.new("TextLabel")
    verifyText.AnchorPoint = Vector2.new(0.5, 0.5)
    verifyText.Position = UDim2.new(0.5, -8, 0.5, 0)
    verifyText.Size = UDim2.fromOffset(150, 24)
    verifyText.BackgroundTransparency = 1
    verifyText.Font = Enum.Font.GothamBold
    verifyText.Text = "VERIFY ACCESS"
    verifyText.TextColor3 = C.Text
    verifyText.TextSize = 10
    verifyText.ZIndex = 10
    verifyText.Parent = verify

    local actionIcon = icon(verify, icons, "arrow-right", 15, C.Text, 10)
    actionIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    actionIcon.Position = UDim2.new(0.5, 62, 0.5, 0)

    local footerIcon = icon(content, icons, "shield", 10, C.Muted, 9)
    footerIcon.AnchorPoint = Vector2.new(0, 0.5)
    footerIcon.Position = UDim2.new(0, 0, 1, -6)

    local footer = Instance.new("TextLabel")
    footer.Position = UDim2.new(0, 17, 1, -15)
    footer.Size = UDim2.new(1, -17, 0, 18)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.Text = "ENCRYPTED SESSION   •   RIGHT SHIFT TO HIDE"
    footer.TextColor3 = C.Muted
    footer.TextSize = 7
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.ZIndex = 9
    footer.Parent = content

    local function setStatus(message, color, iconName)
        local tint = color or C.Sub
        statusText.Text = message
        statusText.TextColor3 = tint
        statusIcon.ImageColor3 = tint

        if iconName and icons[iconName] then
            statusIcon.Image = icons[iconName]
            statusIcon:SetAttribute("LucideName", iconName)
        end

        tween(config.ReduceMotion, statusStroke, 0.14, {
            Color = tint,
            Transparency = 0.60,
        })

        task.delay(0.28, function()
            if state.destroyed or not statusStroke.Parent then
                return
            end

            tween(config.ReduceMotion, statusStroke, 0.18, {
                Transparency = 0.82,
            })
        end)
    end

    local function destroy()
        if state.destroyed then
            return
        end

        state.destroyed = true

        for _, connection in ipairs(state.connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        if blur.Parent then
            tween(config.ReduceMotion, blur, 0.16, { Size = 0 })
        end

        if gui.Parent then
            gui:Destroy()
        end

        task.delay(0.18, function()
            if blur.Parent then
                blur:Destroy()
            end
        end)
    end

    local function fail(message)
        state.busy = false
        setStatus(message or "Invalid key", C.Danger, "circle-alert")

        inputStroke.Color = C.Danger
        inputStroke.Transparency = 0.24
        lockIcon.ImageColor3 = C.Danger
        playSound(config, config.ClickSoundId, 0.22)

        if not config.ReduceMotion then
            local base = card.Position

            tween(false, card, 0.05, {
                Position = base + UDim2.fromOffset(-6, 0),
            })

            task.delay(0.05, function()
                if card.Parent then
                    tween(false, card, 0.05, {
                        Position = base + UDim2.fromOffset(6, 0),
                    })
                end
            end)

            task.delay(0.10, function()
                if card.Parent then
                    tween(false, card, 0.07, {
                        Position = base,
                    })
                end
            end)
        end

        task.delay(0.70, function()
            if state.destroyed then
                return
            end

            inputStroke.Color = C.Edge
            inputStroke.Transparency = 0.62
            lockIcon.ImageColor3 = C.Muted
        end)
    end

    local function success()
        state.busy = true

        setStatus(
            "Access granted   •   opening SaltyGlass",
            C.Success,
            "badge-check"
        )

        inputStroke.Color = C.Success
        inputStroke.Transparency = 0.22

        lockIcon.Image = icons["lock-open"] or lockIcon.Image
        lockIcon.ImageColor3 = C.Success

        keyIcon.Image = icons.check or icons["circle-check-big"] or keyIcon.Image
        keyIcon.ImageColor3 = C.Success

        verify.BackgroundColor3 = C.Success
        verifyGradient.Enabled = false

        verifyText.Text = "ACCESS GRANTED"
        verifyText.TextColor3 = C.Base

        actionIcon.Image = icons.check or actionIcon.Image
        actionIcon.ImageColor3 = C.Base

        playSound(config, config.ClickSoundId, 0.30)

        tween(config.ReduceMotion, verifyScale, 0.14, {
            Scale = 1.015,
        })

        task.delay(0.14, function()
            if verifyScale.Parent then
                tween(config.ReduceMotion, verifyScale, 0.14, {
                    Scale = 1,
                })
            end
        end)

        task.delay(config.SuccessDelay, function()
            if state.destroyed then
                return
            end

            local callback = config.OnSuccess
            destroy()

            if type(callback) == "function" then
                task.spawn(callback)
            end
        end)
    end

    local function verifyKey()
        if state.busy then
            return
        end

        if input.Text == "" then
            fail("Enter an access key first")
            return
        end

        state.busy = true
        state.attempts = state.attempts + 1

        setStatus(
            "Verifying encrypted access...",
            config.Accent,
            "loader-circle"
        )

        playSound(config, config.ClickSoundId, 0.28)

        tween(config.ReduceMotion, verifyScale, 0.08, {
            Scale = 0.985,
        })

        task.delay(config.ReduceMotion and 0 or 0.16, function()
            if state.destroyed then
                return
            end

            tween(config.ReduceMotion, verifyScale, 0.10, {
                Scale = 1,
            })

            local valid = validKeys[input.Text] == true

            if type(config.Validator) == "function" then
                local ok, result = pcall(config.Validator, input.Text)
                valid = ok and result == true
            end

            if valid then
                success()
                return
            end

            if config.MaxAttempts > 0
                and state.attempts >= config.MaxAttempts then
                fail("Access locked   •   maximum attempts reached")
                verify.Active = false
                input.TextEditable = false
                return
            end

            fail("Invalid key   •   please try again")
        end)
    end

    connect(input.Focused, function()
        inputStroke.Color = config.Accent
        inputStroke.Transparency = 0.20
        lockIcon.ImageColor3 = config.Accent

        tween(config.ReduceMotion, inputShell, 0.14, {
            BackgroundTransparency = 0.16,
        })
    end)

    connect(input.FocusLost, function(enterPressed)
        if not state.busy then
            inputStroke.Color = C.Edge
            inputStroke.Transparency = 0.62
            lockIcon.ImageColor3 = C.Muted

            tween(config.ReduceMotion, inputShell, 0.14, {
                BackgroundTransparency = 0.28,
            })
        end

        if enterPressed then
            verifyKey()
        end
    end)

    connect(verify.MouseEnter, function()
        playSound(config, config.HoverSoundId, 0.10)

        if state.busy then
            return
        end

        tween(config.ReduceMotion, verifyScale, 0.12, {
            Scale = 1.010,
        })

        tween(config.ReduceMotion, verify, 0.12, {
            BackgroundTransparency = 0.01,
        })

        tween(config.ReduceMotion, actionIcon, 0.12, {
            Position = UDim2.new(0.5, 67, 0.5, 0),
        })

        verifyStroke.Transparency = 0.30
    end)

    connect(verify.MouseLeave, function()
        if state.busy then
            return
        end

        tween(config.ReduceMotion, verifyScale, 0.12, {
            Scale = 1,
        })

        tween(config.ReduceMotion, verify, 0.12, {
            BackgroundTransparency = 0.08,
        })

        tween(config.ReduceMotion, actionIcon, 0.12, {
            Position = UDim2.new(0.5, 62, 0.5, 0),
        })

        verifyStroke.Transparency = 0.46
    end)

    connect(verify.MouseButton1Click, verifyKey)

    connect(emblem.MouseEnter, function()
        playSound(config, config.HoverSoundId, 0.08)

        tween(config.ReduceMotion, emblemStroke, 0.14, {
            Transparency = 0.28,
        })

        tween(config.ReduceMotion, keyIcon, 0.14, {
            ImageColor3 = C.Text,
        })
    end)

    connect(emblem.MouseLeave, function()
        tween(config.ReduceMotion, emblemStroke, 0.14, {
            Transparency = 0.52,
        })

        tween(config.ReduceMotion, keyIcon, 0.14, {
            ImageColor3 = config.Accent,
        })
    end)

    connect(UserInputService.InputBegan, function(userInput, processed)
        if processed
            or state.destroyed
            or userInput.KeyCode ~= config.ToggleKey then
            return
        end

        local visible = not card.Visible

        card.Visible = visible
        shadow.Visible = visible
        backdrop.Visible = visible

        if config.Blur then
            blur.Size = visible and 18 or 0
        end
    end)

    local camera = workspace.CurrentCamera

    local function fitToViewport()
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local value = math.min(
            1,
            math.max(
                0.74,
                math.min(viewport.X / 590, viewport.Y / 420)
            )
        )

        cardScale.Scale = value
        shadow.Size = UDim2.fromOffset(522 * value, 352 * value)
    end

    fitToViewport()

    if camera then
        connect(
            camera:GetPropertyChangedSignal("ViewportSize"),
            fitToViewport
        )
    end

    if not config.ReduceMotion then
        local targetPosition = card.Position
        local targetScale = cardScale.Scale

        card.Position = targetPosition + UDim2.fromOffset(0, 10)
        cardScale.Scale = targetScale * 0.98

        tween(false, card, 0.22, {
            Position = targetPosition,
        })

        tween(false, cardScale, 0.22, {
            Scale = targetScale,
        })
    end

    local handle = {}

    function handle:Destroy()
        destroy()
    end

    function handle:Verify()
        verifyKey()
    end

    function handle:SetStatus(message, color)
        setStatus(message, color)
    end

    function handle:GetScreenGui()
        return gui
    end

    function handle:SetAccent(color)
        if typeof(color) ~= "Color3" then
            return
        end

        config.Accent = color

        keyIcon.ImageColor3 = color
        protectedIcon.ImageColor3 = color
        subtitle.TextColor3 = color

        accessChip.BackgroundColor3 = color
        accessText.TextColor3 = color

        statusIcon.ImageColor3 = color

        verify.BackgroundColor3 = color

        verifyGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                color:Lerp(Color3.new(0, 0, 0), 0.04)
            ),
            ColorSequenceKeypoint.new(0.55, color),
            ColorSequenceKeypoint.new(
                1,
                color:Lerp(C.Text, 0.10)
            ),
        })
    end

    return handle
end

return KeySystem
