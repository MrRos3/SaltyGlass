-- SaltyGlass Key System v1.2.0
-- Premium liquid-glass access gate. The main SaltyGlass GUI is not modified.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then error("SaltyGlass Key System must run on the Roblox client.", 0) end
local playerGui = player:WaitForChild("PlayerGui")

local KeySystem = { Version = "1.2.0" }

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
    SuccessDelay = 0.42,
    ToggleKey = Enum.KeyCode.RightShift,
    ClickSoundId = "rbxassetid://4307186075",
    HoverSoundId = "rbxassetid://408524543",
}

local C = {
    Ink = Color3.fromRGB(6, 9, 17),
    Deep = Color3.fromRGB(10, 14, 27),
    Glass = Color3.fromRGB(20, 27, 49),
    Raised = Color3.fromRGB(29, 38, 67),
    White = Color3.new(1, 1, 1),
    Text = Color3.fromRGB(246, 247, 255),
    Sub = Color3.fromRGB(174, 181, 207),
    Muted = Color3.fromRGB(102, 111, 142),
    Success = Color3.fromRGB(105, 255, 174),
    Danger = Color3.fromRGB(255, 102, 124),
    Cyan = Color3.fromRGB(98, 226, 255),
}

local function merge(options)
    local out = {}
    for k, v in pairs(DEFAULTS) do out[k] = v end
    if type(options) == "table" then
        for k, v in pairs(options) do out[k] = v end
    end
    return out
end

local function corner(parent, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius)
    value.Parent = parent
    return value
end

local function stroke(parent, transparency, thickness, color)
    local value = Instance.new("UIStroke")
    value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    value.Color = color or C.White
    value.Transparency = transparency or 0.75
    value.Thickness = thickness or 1
    value.Parent = parent
    return value
end

local function gradient(parent, colors, transparencies, rotation)
    local value = Instance.new("UIGradient")
    value.Color = colors
    value.Transparency = transparencies or NumberSequence.new(0)
    value.Rotation = rotation or 0
    value.Parent = parent
    return value
end

local function scale(parent)
    local value = Instance.new("UIScale")
    value.Parent = parent
    return value
end

local function tween(reduceMotion, target, duration, properties, style)
    if reduceMotion then
        for property, value in pairs(properties) do target[property] = value end
        return
    end
    local value = TweenService:Create(target, TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    value:Play()
    return value
end

local function playSound(config, id, volume)
    if not config.Sounds or not id or id == "" then return end
    pcall(function()
        local value = Instance.new("Sound")
        value.Name = "SaltyUISound"
        value.SoundId = id
        value.Volume = volume or 0.18
        value.Parent = SoundService
        value:Play()
        value.Ended:Once(function() if value.Parent then value:Destroy() end end)
        task.delay(4, function() if value.Parent then value:Destroy() end end)
    end)
end

local function loadIcons()
    local ok, result = pcall(function()
        local source = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/icons/Lucide.lua")
        local chunk, compileError = loadstring(source)
        if not chunk then error(compileError, 0) end
        return chunk()
    end)
    return ok and type(result) == "table" and result or {}
end

local function icon(parent, icons, name, size, color, zIndex)
    local value = Instance.new("ImageLabel")
    value.Name = "Lucide_" .. name
    value.BackgroundTransparency = 1
    value.Size = UDim2.fromOffset(size, size)
    value.Image = icons[name] or ""
    value.ImageColor3 = color or C.Text
    value.ScaleType = Enum.ScaleType.Fit
    value.ZIndex = zIndex or 20
    value:SetAttribute("LucideName", name)
    value.Parent = parent
    return value
end

local function keySet(config)
    local result = {}
    if type(config.Key) == "string" then result[config.Key] = true end
    if type(config.Keys) == "table" then
        for _, key in ipairs(config.Keys) do
            if type(key) == "string" then result[key] = true end
        end
    end
    return result
end

function KeySystem.Open(options)
    local config = merge(options)
    local icons = loadIcons()
    local validKeys = keySet(config)
    local oldGui = playerGui:FindFirstChild("SaltyKeySystemGui")
    local oldBlur = Lighting:FindFirstChild("SaltyKeySystemBlur")
    if oldGui then oldGui:Destroy() end
    if oldBlur then oldBlur:Destroy() end

    local state = { destroyed = false, busy = false, attempts = 0, connections = {} }
    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(state.connections, connection)
        return connection
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "SaltyKeySystemBlur"
    blur.Size = config.Blur and 24 or 0
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
    backdrop.BackgroundTransparency = 0.27
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.Active = true
    backdrop.ZIndex = 1
    backdrop.Parent = gui
    gradient(backdrop, ColorSequence.new(C.Ink, Color3.new(0, 0, 0)), NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.42),
    }), 90)

    local aura = Instance.new("Frame")
    aura.Name = "CornerAura"
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.Size = UDim2.fromOffset(602, 446)
    aura.BackgroundColor3 = config.Accent
    aura.BackgroundTransparency = 0.95
    aura.BorderSizePixel = 0
    aura.ZIndex = 2
    aura.Parent = gui
    corner(aura, 44)

    local shadow = Instance.new("Frame")
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 12)
    shadow.Size = UDim2.fromOffset(558, 402)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.34
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 3
    shadow.Parent = gui
    corner(shadow, 34)

    local card = Instance.new("CanvasGroup")
    card.Name = "KeyCard"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(548, 392)
    card.BackgroundColor3 = C.Deep
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 4
    card.Parent = gui
    corner(card, 32)
    stroke(card, 0.42, 1.25)
    local cardScale = scale(card)
    local cardGlass = gradient(card, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 53, 88)),
        ColorSequenceKeypoint.new(0.36, C.Glass),
        ColorSequenceKeypoint.new(0.74, C.Deep),
        ColorSequenceKeypoint.new(1, C.Ink),
    }), NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.10), NumberSequenceKeypoint.new(0.38, 0.46), NumberSequenceKeypoint.new(1, 0.84),
    }), 42)

    local innerGlass = Instance.new("Frame")
    innerGlass.Position = UDim2.fromOffset(8, 8)
    innerGlass.Size = UDim2.new(1, -16, 1, -16)
    innerGlass.BackgroundColor3 = C.White
    innerGlass.BackgroundTransparency = 0.988
    innerGlass.BorderSizePixel = 0
    innerGlass.ZIndex = 5
    innerGlass.Parent = card
    corner(innerGlass, 25)
    stroke(innerGlass, 0.91, 1)

    local glowA = Instance.new("Frame")
    glowA.AnchorPoint = Vector2.new(0.5, 0.5)
    glowA.Position = UDim2.fromOffset(62, 38)
    glowA.Size = UDim2.fromOffset(230, 230)
    glowA.BackgroundColor3 = config.Accent
    glowA.BackgroundTransparency = 0.91
    glowA.BorderSizePixel = 0
    glowA.ZIndex = 5
    glowA.Parent = card
    corner(glowA, 120)
    gradient(glowA, ColorSequence.new(config.Accent, C.Cyan), NumberSequence.new(0.28), 35)

    local glowB = Instance.new("Frame")
    glowB.AnchorPoint = Vector2.new(0.5, 0.5)
    glowB.Position = UDim2.new(1, 18, 1, 28)
    glowB.Size = UDim2.fromOffset(285, 285)
    glowB.BackgroundColor3 = C.Cyan
    glowB.BackgroundTransparency = 0.965
    glowB.BorderSizePixel = 0
    glowB.ZIndex = 5
    glowB.Parent = card
    corner(glowB, 145)

    -- Soft diagonal flecks supply depth without using an external noise asset.
    for i = 1, 14 do
        local fleck = Instance.new("Frame")
        fleck.Position = UDim2.new((i * 0.173) % 1, 0, (i * 0.307) % 1, 0)
        fleck.Size = UDim2.fromOffset(i % 3 == 0 and 2 or 1, i % 4 == 0 and 2 or 1)
        fleck.BackgroundColor3 = C.White
        fleck.BackgroundTransparency = 0.90 + (i % 3) * 0.025
        fleck.BorderSizePixel = 0
        fleck.ZIndex = 6
        fleck.Parent = card
        corner(fleck, 2)
    end

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(30, 26)
    content.Size = UDim2.new(1, -60, 1, -52)
    content.BackgroundTransparency = 1
    content.ZIndex = 8
    content.Parent = card

    local emblemAura = Instance.new("Frame")
    emblemAura.Size = UDim2.fromOffset(60, 60)
    emblemAura.BackgroundColor3 = config.Accent
    emblemAura.BackgroundTransparency = 0.90
    emblemAura.BorderSizePixel = 0
    emblemAura.ZIndex = 9
    emblemAura.Parent = content
    corner(emblemAura, 19)

    local emblem = Instance.new("Frame")
    emblem.AnchorPoint = Vector2.new(0.5, 0.5)
    emblem.Position = UDim2.fromScale(0.5, 0.5)
    emblem.Size = UDim2.fromOffset(48, 48)
    emblem.BackgroundColor3 = C.Raised
    emblem.BackgroundTransparency = 0.13
    emblem.BorderSizePixel = 0
    emblem.ZIndex = 10
    emblem.Parent = emblemAura
    corner(emblem, 15)
    local emblemStroke = stroke(emblem, 0.46, 1)
    local keyIcon = icon(emblem, icons, "key-round", 21, config.Accent, 12)
    if keyIcon.Image == "" then keyIcon.Image = icons.key or "" end
    keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    keyIcon.Position = UDim2.fromScale(0.5, 0.5)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(78, 2)
    title.Size = UDim2.new(1, -214, 0, 25)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = config.Title
    title.TextColor3 = C.Text
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 10
    title.Parent = content

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(78, 30)
    subtitle.Size = UDim2.new(1, -214, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = string.upper(config.Subtitle)
    subtitle.TextColor3 = config.Accent
    subtitle.TextSize = 8
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 10
    subtitle.Parent = content

    local protected = Instance.new("Frame")
    protected.AnchorPoint = Vector2.new(1, 0)
    protected.Position = UDim2.new(1, 0, 0, 8)
    protected.Size = UDim2.fromOffset(118, 32)
    protected.BackgroundColor3 = C.Raised
    protected.BackgroundTransparency = 0.45
    protected.BorderSizePixel = 0
    protected.ZIndex = 10
    protected.Parent = content
    corner(protected, 11)
    stroke(protected, 0.72, 1)
    local protectedIcon = icon(protected, icons, "shield-check", 13, config.Accent, 12)
    protectedIcon.AnchorPoint = Vector2.new(0, 0.5)
    protectedIcon.Position = UDim2.new(0, 11, 0.5, 0)
    local protectedText = Instance.new("TextLabel")
    protectedText.Position = UDim2.fromOffset(32, 0)
    protectedText.Size = UDim2.new(1, -39, 1, 0)
    protectedText.BackgroundTransparency = 1
    protectedText.Font = Enum.Font.GothamBold
    protectedText.Text = "PROTECTED"
    protectedText.TextColor3 = C.Sub
    protectedText.TextSize = 8
    protectedText.TextXAlignment = Enum.TextXAlignment.Left
    protectedText.ZIndex = 12
    protectedText.Parent = protected

    local description = Instance.new("TextLabel")
    description.Position = UDim2.fromOffset(0, 78)
    description.Size = UDim2.new(1, 0, 0, 18)
    description.BackgroundTransparency = 1
    description.Font = Enum.Font.Gotham
    description.Text = config.Description
    description.TextColor3 = C.Sub
    description.TextSize = 10
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.ZIndex = 10
    description.Parent = content

    local focusAura = Instance.new("Frame")
    focusAura.Position = UDim2.fromOffset(-4, 107)
    focusAura.Size = UDim2.new(1, 8, 0, 66)
    focusAura.BackgroundColor3 = config.Accent
    focusAura.BackgroundTransparency = 1
    focusAura.BorderSizePixel = 0
    focusAura.ZIndex = 8
    focusAura.Parent = content
    corner(focusAura, 20)

    local inputShell = Instance.new("Frame")
    inputShell.Position = UDim2.fromOffset(0, 111)
    inputShell.Size = UDim2.new(1, 0, 0, 58)
    inputShell.BackgroundColor3 = C.Glass
    inputShell.BackgroundTransparency = 0.23
    inputShell.BorderSizePixel = 0
    inputShell.ZIndex = 10
    inputShell.Parent = content
    corner(inputShell, 16)
    local inputStroke = stroke(inputShell, 0.64, 1)
    gradient(inputShell, ColorSequence.new(C.Glass, C.Deep), NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.52),
    }), 0)

    local lockIcon = icon(inputShell, icons, "lock-keyhole", 17, C.Muted, 12)
    if lockIcon.Image == "" then lockIcon.Image = icons.lock or "" end
    lockIcon.AnchorPoint = Vector2.new(0, 0.5)
    lockIcon.Position = UDim2.new(0, 18, 0.5, 0)
    local lockScale = scale(lockIcon)

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(51, 0)
    input.Size = UDim2.new(1, -133, 1, 0)
    input.BackgroundTransparency = 1
    input.ClearTextOnFocus = false
    input.Font = Enum.Font.GothamMedium
    input.PlaceholderText = config.Placeholder
    input.PlaceholderColor3 = C.Muted
    input.Text = ""
    input.TextColor3 = C.Text
    input.TextSize = 11
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ZIndex = 12
    input.Parent = inputShell

    local keyChip = Instance.new("Frame")
    keyChip.AnchorPoint = Vector2.new(1, 0.5)
    keyChip.Position = UDim2.new(1, -12, 0.5, 0)
    keyChip.Size = UDim2.fromOffset(66, 28)
    keyChip.BackgroundColor3 = config.Accent
    keyChip.BackgroundTransparency = 0.86
    keyChip.BorderSizePixel = 0
    keyChip.ZIndex = 12
    keyChip.Parent = inputShell
    corner(keyChip, 10)
    stroke(keyChip, 0.78, 1, config.Accent)
    local keyChipText = Instance.new("TextLabel")
    keyChipText.Size = UDim2.fromScale(1, 1)
    keyChipText.BackgroundTransparency = 1
    keyChipText.Font = Enum.Font.GothamBold
    keyChipText.Text = "ACCESS"
    keyChipText.TextColor3 = config.Accent
    keyChipText.TextSize = 7
    keyChipText.ZIndex = 13
    keyChipText.Parent = keyChip

    local statusIsland = Instance.new("Frame")
    statusIsland.Position = UDim2.fromOffset(0, 181)
    statusIsland.Size = UDim2.new(1, 0, 0, 34)
    statusIsland.BackgroundColor3 = C.Raised
    statusIsland.BackgroundTransparency = 0.62
    statusIsland.BorderSizePixel = 0
    statusIsland.ZIndex = 10
    statusIsland.Parent = content
    corner(statusIsland, 12)
    local statusStroke = stroke(statusIsland, 0.84, 1)
    local statusIcon = icon(statusIsland, icons, "sparkles", 12, config.Accent, 12)
    statusIcon.AnchorPoint = Vector2.new(0, 0.5)
    statusIcon.Position = UDim2.new(0, 13, 0.5, 0)
    local statusText = Instance.new("TextLabel")
    statusText.Position = UDim2.fromOffset(34, 0)
    statusText.Size = UDim2.new(1, -46, 1, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.GothamMedium
    statusText.Text = "Ready for verification"
    statusText.TextColor3 = C.Sub
    statusText.TextSize = 9
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 12
    statusText.Parent = statusIsland

    local verifyGlow = Instance.new("Frame")
    verifyGlow.Position = UDim2.fromOffset(-3, 227)
    verifyGlow.Size = UDim2.new(1, 6, 0, 60)
    verifyGlow.BackgroundColor3 = config.Accent
    verifyGlow.BackgroundTransparency = 0.89
    verifyGlow.BorderSizePixel = 0
    verifyGlow.ZIndex = 9
    verifyGlow.Parent = content
    corner(verifyGlow, 19)

    local verify = Instance.new("TextButton")
    verify.Position = UDim2.fromOffset(0, 230)
    verify.Size = UDim2.new(1, 0, 0, 54)
    verify.BackgroundColor3 = config.Accent
    verify.BackgroundTransparency = 0.06
    verify.BorderSizePixel = 0
    verify.AutoButtonColor = false
    verify.Text = ""
    verify.ZIndex = 10
    verify.Parent = content
    corner(verify, 16)
    stroke(verify, 0.42, 1)
    local verifyScale = scale(verify)
    local verifyGradient = gradient(verify, ColorSequence.new({
        ColorSequenceKeypoint.new(0, config.Accent:Lerp(Color3.new(0, 0, 0), 0.08)),
        ColorSequenceKeypoint.new(0.52, config.Accent:Lerp(C.White, 0.12)),
        ColorSequenceKeypoint.new(1, config.Accent:Lerp(C.Cyan, 0.18)),
    }), nil, 0)

    local buttonSheen = Instance.new("Frame")
    buttonSheen.AnchorPoint = Vector2.new(0.5, 0.5)
    buttonSheen.Position = UDim2.new(-0.25, 0, 0.5, 0)
    buttonSheen.Size = UDim2.fromOffset(78, 110)
    buttonSheen.Rotation = 16
    buttonSheen.BackgroundColor3 = C.White
    buttonSheen.BackgroundTransparency = 0.77
    buttonSheen.BorderSizePixel = 0
    buttonSheen.ZIndex = 11
    buttonSheen.Parent = verify
    gradient(buttonSheen, ColorSequence.new(C.White), NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 1),
    }))

    local verifyText = Instance.new("TextLabel")
    verifyText.AnchorPoint = Vector2.new(0.5, 0.5)
    verifyText.Position = UDim2.new(0.5, -9, 0.5, 0)
    verifyText.Size = UDim2.fromOffset(158, 24)
    verifyText.BackgroundTransparency = 1
    verifyText.Font = Enum.Font.GothamBold
    verifyText.Text = "VERIFY ACCESS"
    verifyText.TextColor3 = C.White
    verifyText.TextSize = 10
    verifyText.ZIndex = 13
    verifyText.Parent = verify
    local actionIcon = icon(verify, icons, "arrow-right", 15, C.White, 13)
    actionIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    actionIcon.Position = UDim2.new(0.5, 65, 0.5, 0)

    local footerIcon = icon(content, icons, "shield", 10, C.Muted, 10)
    footerIcon.AnchorPoint = Vector2.new(0, 0.5)
    footerIcon.Position = UDim2.new(0, 0, 1, -7)
    local footer = Instance.new("TextLabel")
    footer.Position = UDim2.new(0, 18, 1, -16)
    footer.Size = UDim2.new(1, -18, 0, 18)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.Text = "ENCRYPTED SESSION   •   RIGHT SHIFT TO HIDE"
    footer.TextColor3 = C.Muted
    footer.TextSize = 7
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.ZIndex = 10
    footer.Parent = content

    local function setStatus(text, color, iconName)
        local tint = color or C.Sub
        statusText.Text = text
        statusText.TextColor3 = tint
        statusIcon.ImageColor3 = tint
        if iconName and icons[iconName] then
            statusIcon.Image = icons[iconName]
            statusIcon:SetAttribute("LucideName", iconName)
        end
        tween(config.ReduceMotion, statusIcon, 0.16, { Rotation = statusIcon.Rotation + 12 })
        tween(config.ReduceMotion, statusStroke, 0.16, { Color = tint, Transparency = 0.66 })
        task.delay(0.32, function()
            if not state.destroyed and statusStroke.Parent then
                tween(config.ReduceMotion, statusStroke, 0.22, { Transparency = 0.84 })
            end
        end)
    end

    local function destroy()
        if state.destroyed then return end
        state.destroyed = true
        for _, connection in ipairs(state.connections) do pcall(function() connection:Disconnect() end) end
        if blur.Parent then tween(config.ReduceMotion, blur, 0.18, { Size = 0 }) end
        if gui.Parent then gui:Destroy() end
        task.delay(0.2, function() if blur.Parent then blur:Destroy() end end)
    end

    local function fail(message)
        state.busy = false
        setStatus(message or "Invalid key", C.Danger, "circle-alert")
        inputStroke.Color, inputStroke.Transparency = C.Danger, 0.24
        lockIcon.ImageColor3 = C.Danger
        tween(config.ReduceMotion, lockScale, 0.12, { Scale = 1.12 })
        playSound(config, config.ClickSoundId, 0.22)
        if not config.ReduceMotion then
            local base = card.Position
            tween(false, card, 0.055, { Position = base + UDim2.fromOffset(-7, 0) })
            task.delay(0.055, function() if card.Parent then tween(false, card, 0.055, { Position = base + UDim2.fromOffset(7, 0) }) end end)
            task.delay(0.11, function() if card.Parent then tween(false, card, 0.07, { Position = base }) end end)
        end
        task.delay(0.7, function()
            if state.destroyed then return end
            inputStroke.Color, inputStroke.Transparency = C.White, 0.64
            lockIcon.ImageColor3 = C.Muted
            tween(config.ReduceMotion, lockScale, 0.12, { Scale = 1 })
        end)
    end

    local function success()
        state.busy = true
        setStatus("Access granted  •  opening SaltyGlass", C.Success, "badge-check")
        inputStroke.Color, inputStroke.Transparency = C.Success, 0.22
        lockIcon.Image = icons["lock-open"] or lockIcon.Image
        lockIcon.ImageColor3 = C.Success
        keyIcon.Image = icons.check or icons["circle-check-big"] or keyIcon.Image
        keyIcon.ImageColor3 = C.Success
        verify.BackgroundColor3 = C.Success
        verifyGradient.Enabled = false
        verifyText.Text = "ACCESS GRANTED"
        verifyText.TextColor3 = C.Ink
        actionIcon.Image = icons.check or actionIcon.Image
        actionIcon.ImageColor3 = C.Ink
        playSound(config, config.ClickSoundId, 0.30)
        tween(config.ReduceMotion, emblemAura, 0.18, { BackgroundTransparency = 0.74 })
        tween(config.ReduceMotion, verifyScale, 0.14, { Scale = 1.018 })
        task.delay(0.14, function() if verifyScale.Parent then tween(config.ReduceMotion, verifyScale, 0.14, { Scale = 1 }) end end)
        task.delay(config.SuccessDelay, function()
            if state.destroyed then return end
            local callback = config.OnSuccess
            destroy()
            if type(callback) == "function" then task.spawn(callback) end
        end)
    end

    local function verifyKey()
        if state.busy then return end
        if input.Text == "" then
            fail("Enter an access key first")
            return
        end
        state.busy = true
        state.attempts = state.attempts + 1
        setStatus("Verifying encrypted access...", config.Accent, "loader-circle")
        playSound(config, config.ClickSoundId, 0.28)
        tween(config.ReduceMotion, verifyScale, 0.08, { Scale = 0.985 })
        tween(config.ReduceMotion, statusIcon, 0.32, { Rotation = statusIcon.Rotation + 120 }, Enum.EasingStyle.Linear)
        task.delay(config.ReduceMotion and 0 or 0.18, function()
            if state.destroyed then return end
            tween(config.ReduceMotion, verifyScale, 0.10, { Scale = 1 })
            local valid = validKeys[input.Text] == true
            if type(config.Validator) == "function" then
                local ok, result = pcall(config.Validator, input.Text)
                valid = ok and result == true
            end
            if valid then
                success()
                return
            end
            if config.MaxAttempts > 0 and state.attempts >= config.MaxAttempts then
                fail("Access locked  •  maximum attempts reached")
                verify.Active = false
                input.TextEditable = false
                return
            end
            fail("Invalid key  •  please try again")
        end)
    end

    connect(input.Focused, function()
        inputStroke.Color, inputStroke.Transparency = config.Accent, 0.18
        lockIcon.ImageColor3 = config.Accent
        tween(config.ReduceMotion, focusAura, 0.18, { BackgroundTransparency = 0.90 })
        tween(config.ReduceMotion, inputShell, 0.18, { BackgroundTransparency = 0.12 })
        tween(config.ReduceMotion, lockScale, 0.18, { Scale = 1.08 })
    end)
    connect(input.FocusLost, function(enterPressed)
        if not state.busy then
            inputStroke.Color, inputStroke.Transparency = C.White, 0.64
            lockIcon.ImageColor3 = C.Muted
            tween(config.ReduceMotion, focusAura, 0.18, { BackgroundTransparency = 1 })
            tween(config.ReduceMotion, inputShell, 0.18, { BackgroundTransparency = 0.23 })
            tween(config.ReduceMotion, lockScale, 0.18, { Scale = 1 })
        end
        if enterPressed then verifyKey() end
    end)
    connect(verify.MouseEnter, function()
        playSound(config, config.HoverSoundId, 0.10)
        if state.busy then return end
        tween(config.ReduceMotion, verifyScale, 0.14, { Scale = 1.012 })
        tween(config.ReduceMotion, verify, 0.14, { BackgroundTransparency = 0 })
        tween(config.ReduceMotion, verifyGlow, 0.14, { BackgroundTransparency = 0.82 })
        tween(config.ReduceMotion, actionIcon, 0.14, { Position = UDim2.new(0.5, 70, 0.5, 0) })
        if not config.ReduceMotion then
            buttonSheen.Position = UDim2.new(-0.25, 0, 0.5, 0)
            tween(false, buttonSheen, 0.56, { Position = UDim2.new(1.25, 0, 0.5, 0) })
        end
    end)
    connect(verify.MouseLeave, function()
        if state.busy then return end
        tween(config.ReduceMotion, verifyScale, 0.14, { Scale = 1 })
        tween(config.ReduceMotion, verify, 0.14, { BackgroundTransparency = 0.06 })
        tween(config.ReduceMotion, verifyGlow, 0.14, { BackgroundTransparency = 0.89 })
        tween(config.ReduceMotion, actionIcon, 0.14, { Position = UDim2.new(0.5, 65, 0.5, 0) })
    end)
    connect(verify.MouseButton1Click, verifyKey)
    connect(emblem.MouseEnter, function()
        playSound(config, config.HoverSoundId, 0.08)
        tween(config.ReduceMotion, emblemAura, 0.16, { BackgroundTransparency = 0.80 })
        tween(config.ReduceMotion, emblemStroke, 0.16, { Transparency = 0.24 })
        tween(config.ReduceMotion, keyIcon, 0.16, { Rotation = 8 })
    end)
    connect(emblem.MouseLeave, function()
        tween(config.ReduceMotion, emblemAura, 0.16, { BackgroundTransparency = 0.90 })
        tween(config.ReduceMotion, emblemStroke, 0.16, { Transparency = 0.46 })
        tween(config.ReduceMotion, keyIcon, 0.16, { Rotation = 0 })
    end)
    connect(UserInputService.InputBegan, function(userInput, processed)
        if processed or state.destroyed or userInput.KeyCode ~= config.ToggleKey then return end
        local visible = not card.Visible
        for _, item in ipairs({ card, aura, shadow, backdrop }) do item.Visible = visible end
        if config.Blur then blur.Size = visible and 24 or 0 end
    end)

    local camera = workspace.CurrentCamera
    local function fitToViewport()
        if not camera then return end
        local viewport = camera.ViewportSize
        cardScale.Scale = math.min(1, math.max(0.72, math.min(viewport.X / 620, viewport.Y / 470)))
        aura.Size = UDim2.fromOffset(602 * cardScale.Scale, 446 * cardScale.Scale)
        shadow.Size = UDim2.fromOffset(558 * cardScale.Scale, 402 * cardScale.Scale)
    end
    fitToViewport()
    if camera then connect(camera:GetPropertyChangedSignal("ViewportSize"), fitToViewport) end

    if not config.ReduceMotion then
        local finalPosition = card.Position
        card.Position = finalPosition + UDim2.fromOffset(0, 14)
        card.GroupTransparency = 1
        cardScale.Scale = cardScale.Scale * 0.975
        aura.BackgroundTransparency = 1
        shadow.BackgroundTransparency = 1
        tween(false, card, 0.30, { Position = finalPosition, GroupTransparency = 0 })
        tween(false, cardScale, 0.30, { Scale = math.min(1, cardScale.Scale / 0.975) })
        tween(false, aura, 0.40, { BackgroundTransparency = 0.95 })
        tween(false, shadow, 0.30, { BackgroundTransparency = 0.34 })
        task.delay(0.16, function()
            if state.destroyed then return end
            buttonSheen.Position = UDim2.new(-0.25, 0, 0.5, 0)
            tween(false, buttonSheen, 0.72, { Position = UDim2.new(1.25, 0, 0.5, 0) })
        end)
        task.spawn(function()
            while not state.destroyed and cardGlass.Parent do
                tween(false, cardGlass, 9, { Rotation = 60 }, Enum.EasingStyle.Sine)
                task.wait(9)
                if state.destroyed or not cardGlass.Parent then break end
                tween(false, cardGlass, 9, { Rotation = 38 }, Enum.EasingStyle.Sine)
                task.wait(9)
            end
        end)
    end

    local handle = {}
    function handle:Destroy() destroy() end
    function handle:Verify() verifyKey() end
    function handle:SetStatus(text, color) setStatus(text, color) end
    function handle:GetScreenGui() return gui end
    function handle:SetAccent(color)
        if typeof(color) ~= "Color3" then return end
        config.Accent = color
        for _, item in ipairs({ aura, glowA, emblemAura, focusAura, keyChip, verifyGlow }) do item.BackgroundColor3 = color end
        for _, item in ipairs({ keyIcon, protectedIcon }) do item.ImageColor3 = color end
        subtitle.TextColor3 = color
        keyChipText.TextColor3 = color
        verify.BackgroundColor3 = color
    end
    return handle
end

return KeySystem

