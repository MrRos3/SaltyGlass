local source = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/latest.lua")
local chunk, compileError = loadstring(source)

if not chunk then
    error("SaltyGlass failed to compile: " .. tostring(compileError), 0)
end

chunk()

local Services = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    TextService = game:GetService("TextService"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    Stats = game:GetService("Stats"),
    SoundService = game:GetService("SoundService"),
}

local player = Services.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("SaltyGlassGui", 10)

if not screenGui then
    error("SaltyGlassGui was not created.", 0)
end

local LUCIDE = {}
do
    local ok, result = pcall(function()
        local iconSource = game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/icons/Lucide.lua")
        local iconChunk, iconError = loadstring(iconSource)
        if not iconChunk then
            error(iconError, 0)
        end
        return iconChunk()
    end)
    if ok and type(result) == "table" then
        LUCIDE = result
    end
end

local lucideCount = 0
for _ in pairs(LUCIDE) do
    lucideCount = lucideCount + 1
end
screenGui:SetAttribute("LucideCatalogCount", lucideCount)
screenGui:SetAttribute("LucideCatalogSource", "icons/Lucide.lua")

local function uiSoundsEnabled()
    return screenGui:GetAttribute("UISoundsEnabled") ~= false
end

local function playInjectedSound(soundId, volume)
    if not uiSoundsEnabled() or not soundId or soundId == "" then
        return
    end

    pcall(function()
        local sound = Instance.new("Sound")
        sound.Name = "SaltyUISound"
        sound.SoundId = soundId
        sound.Volume = volume or 0.2
        sound.Parent = Services.SoundService
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

local function playInjectedClick()
    playInjectedSound("rbxassetid://4307186075", 0.28)
end

local function playInjectedHover()
    playInjectedSound("rbxassetid://408524543", 0.10)
end

local mainFrame = screenGui:WaitForChild("MainFrame", 10)
local contentArea = mainFrame and mainFrame:WaitForChild("ContentArea", 10)

local pages = {
    Player = contentArea and contentArea:WaitForChild("PlayerPage", 10),
    Visuals = contentArea and contentArea:WaitForChild("VisualsPage", 10),
}

local bodies = {
    Player = pages.Player and pages.Player:WaitForChild("PageBody", 10),
    Visuals = pages.Visuals and pages.Visuals:WaitForChild("PageBody", 10),
}

if not bodies.Player or not bodies.Visuals then
    error("Could not find the original Salty Player/Visuals pages.", 0)
end

local COLORS = {
    GlassBase = Color3.fromRGB(9, 13, 24),
    GlassMid = Color3.fromRGB(17, 24, 42),
    GlassLight = Color3.fromRGB(27, 36, 64),
    Edge = Color3.new(1, 1, 1),
    Accent = Color3.fromRGB(139, 124, 255),
    Text = Color3.new(1, 1, 1),
    SubText = Color3.fromRGB(181, 188, 211),
    Muted = Color3.fromRGB(111, 120, 149),
    Success = Color3.fromRGB(109, 255, 168),
    Danger = Color3.fromRGB(255, 107, 122),
}

local state = {
    destroyed = false,
    connections = {},
    player = {
        movementOverride = false,
        walkSpeed = 16,
        jumpStrength = 50,
        humanoidDefaults = {},
        fov = 70,
        originalFov = 70,
        zoom = player.CameraMaxZoomDistance,
        originalZoom = player.CameraMaxZoomDistance,
        sprintEnabled = false,
        sprinting = false,
        sprintSpeed = 28,
        mouseSensitivity = Services.UserInputService.MouseDeltaSensitivity,
        originalMouseSensitivity = Services.UserInputService.MouseDeltaSensitivity,
        cameraOffsetY = 0,
    },
    world = {
        fullbright = false,
        disableFog = false,
        saturation = 0,
        contrast = 0,
        brightness = 1,
        exposure = 0,
        bloom = false,
        bloomIntensity = 0.7,
        sunRays = false,
        original = {},
    },
    utility = {
        crosshair = false,
        centerDot = true,
        crosshairSize = 12,
        crosshairOpacity = 92,
        fps = false,
        sessionStart = os.clock(),
    },
}

local ui = {
    controls = {},
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(state.connections, connection)
    return connection
end

local function tween(instance, duration, properties)
    if not instance or not instance.Parent then
        return nil
    end

    local result = Services.TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    result:Play()
    return result
end

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = instance
    return corner
end

local function stroke(instance, transparency)
    local item = Instance.new("UIStroke")
    item.Thickness = 1
    item.Transparency = transparency or 0.82
    item.Color = COLORS.Edge
    item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    item.Parent = instance
    return item
end

local function makeHeader(parent, text, order)
    local holder = Instance.new("Frame")
    holder.Name = "InjectedSection_" .. text:gsub("%s+", "")
    holder.Size = UDim2.new(1, 0, 0, 28)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order
    holder.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local width = Services.TextService:GetTextSize(
        text,
        10,
        Enum.Font.GothamBold,
        Vector2.new(1000, 20)
    ).X

    local line = Instance.new("Frame")
    line.Position = UDim2.fromOffset(0, 22)
    line.Size = UDim2.fromOffset(math.max(18, math.floor(width + 0.5)), 1)
    line.BackgroundColor3 = COLORS.Edge
    line.BackgroundTransparency = 0.42
    line.BorderSizePixel = 0
    line.Parent = holder

    return holder
end

local function makeCard(parent, height, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 54)
    card.BackgroundColor3 = COLORS.GlassBase
    card.BackgroundTransparency = 0.56
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    round(card, 13)
    stroke(card, 0.82)

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 35
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.GlassMid),
        ColorSequenceKeypoint.new(1, COLORS.GlassBase),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.48),
        NumberSequenceKeypoint.new(1, 0.84),
    })
    gradient.Parent = card

    return card
end

local function makeTextPair(card, titleText, descText, rightSpace)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 8)
    title.Size = UDim2.new(1, -(rightSpace or 100), 0, 18)
    title.Font = Enum.Font.GothamMedium
    title.Text = titleText
    title.TextColor3 = COLORS.Text
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.fromOffset(14, 27)
    desc.Size = UDim2.new(1, -(rightSpace or 100), 0, 16)
    desc.Font = Enum.Font.Gotham
    desc.Text = descText or ""
    desc.TextColor3 = COLORS.SubText
    desc.TextSize = 9
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    return title, desc
end

ui.statusCard = Instance.new("Frame")
ui.statusCard.AnchorPoint = Vector2.new(0.5, 1)
ui.statusCard.Position = UDim2.new(0.5, 0, 1, -22)
ui.statusCard.Size = UDim2.fromOffset(230, 34)
ui.statusCard.BackgroundColor3 = COLORS.GlassBase
ui.statusCard.BackgroundTransparency = 1
ui.statusCard.BorderSizePixel = 0
ui.statusCard.Visible = false
ui.statusCard.ZIndex = 320
ui.statusCard.Parent = screenGui
round(ui.statusCard, 12)
ui.statusStroke = stroke(ui.statusCard, 1)

ui.statusLabel = Instance.new("TextLabel")
ui.statusLabel.Size = UDim2.fromScale(1, 1)
ui.statusLabel.BackgroundTransparency = 1
ui.statusLabel.Font = Enum.Font.GothamMedium
ui.statusLabel.Text = ""
ui.statusLabel.TextColor3 = COLORS.Text
ui.statusLabel.TextTransparency = 1
ui.statusLabel.TextSize = 10
ui.statusLabel.ZIndex = 321
ui.statusLabel.Parent = ui.statusCard

state.statusToken = 0

local function showStatus(text)
    state.statusToken = state.statusToken + 1
    local token = state.statusToken

    ui.statusLabel.Text = tostring(text)
    ui.statusCard.Visible = true

    tween(ui.statusCard, 0.12, { BackgroundTransparency = 0.14 })
    tween(ui.statusStroke, 0.12, { Transparency = 0.56 })
    tween(ui.statusLabel, 0.12, { TextTransparency = 0 })

    task.delay(1.35, function()
        if state.destroyed or token ~= state.statusToken then
            return
        end

        tween(ui.statusCard, 0.12, { BackgroundTransparency = 1 })
        tween(ui.statusStroke, 0.12, { Transparency = 1 })
        tween(ui.statusLabel, 0.12, { TextTransparency = 1 })

        task.delay(0.13, function()
            if not state.destroyed and token == state.statusToken and ui.statusCard.Parent then
                ui.statusCard.Visible = false
            end
        end)
    end)
end

local function makeToggle(parent, titleText, descText, defaultState, callback, order)
    local card = makeCard(parent, 54, order)
    makeTextPair(card, titleText, descText, 88)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.fromScale(1, 1)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.ZIndex = 5
    hitbox.Parent = card

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -14, 0.5, 0)
    track.Size = UDim2.fromOffset(38, 20)
    track.BackgroundColor3 = defaultState and COLORS.Accent or COLORS.GlassLight
    track.BackgroundTransparency = defaultState and 0.12 or 0.28
    track.BorderSizePixel = 0
    track.ZIndex = 6
    track.Parent = card
    round(track, 10)
    stroke(track, 0.72)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = defaultState and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = COLORS.Edge
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    knob.Parent = track
    round(knob, 8)

    local control = {
        Value = defaultState == true,
    }

    function control:Set(value, silent)
        self.Value = value == true
        tween(track, 0.14, {
            BackgroundColor3 = self.Value and COLORS.Accent or COLORS.GlassLight,
            BackgroundTransparency = self.Value and 0.12 or 0.28,
        })
        tween(knob, 0.14, {
            Position = self.Value and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
        })

        if not silent and type(callback) == "function" then
            callback(self.Value)
        end
    end

    function control:Get()
        return self.Value
    end

    connect(hitbox.MouseEnter, function()
        playInjectedHover()
        tween(card, 0.12, { BackgroundTransparency = 0.44 })
    end)

    connect(hitbox.MouseLeave, function()
        tween(card, 0.12, { BackgroundTransparency = 0.56 })
    end)

    connect(hitbox.MouseButton1Click, function()
        playInjectedClick()
        control:Set(not control.Value, false)
    end)

    return control
end

local function makeSlider(parent, titleText, descText, minimum, maximum, defaultValue, increment, suffix, callback, order)
    local card = makeCard(parent, 66, order)
    makeTextPair(card, titleText, descText, 88)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -14, 0, 8)
    valueLabel.Size = UDim2.fromOffset(64, 18)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextSize = 10
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 5
    valueLabel.Parent = card

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 14, 1, -15)
    bar.Size = UDim2.new(1, -28, 0, 3)
    bar.BackgroundColor3 = COLORS.GlassLight
    bar.BackgroundTransparency = 0.20
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = card
    round(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = bar
    round(fill, 4)

    local thumb = Instance.new("Frame")
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.Size = UDim2.fromOffset(10, 10)
    thumb.BackgroundColor3 = COLORS.Edge
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 7
    thumb.Parent = bar
    round(thumb, 6)

    local hitbox = Instance.new("TextButton")
    hitbox.Position = UDim2.new(0, 8, 1, -28)
    hitbox.Size = UDim2.new(1, -16, 0, 26)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.ZIndex = 8
    hitbox.Parent = card

    local control = {
        Value = defaultValue,
        Dragging = false,
    }

    local step = tonumber(increment) or 1

    local function formatValue(value)
        if step < 1 then
            return string.format("%.1f%s", value, suffix or "")
        end
        return tostring(math.floor(value + 0.5)) .. (suffix or "")
    end

    function control:Set(newValue, silent)
        newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
        newValue = math.floor((newValue / step) + 0.5) * step
        newValue = math.clamp(newValue, minimum, maximum)
        self.Value = newValue

        local alpha = 0
        if maximum > minimum then
            alpha = (newValue - minimum) / (maximum - minimum)
        end

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = formatValue(newValue)

        if not silent and type(callback) == "function" then
            callback(newValue)
        end
    end

    function control:Get()
        return self.Value
    end

    local function updateFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        control:Set(minimum + (maximum - minimum) * alpha, false)
    end

    connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            playInjectedClick()
            control.Dragging = true
            updateFromX(input.Position.X)
        end
    end)

    connect(hitbox.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            control.Dragging = false
        end
    end)

    connect(Services.UserInputService.InputChanged, function(input)
        if control.Dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updateFromX(input.Position.X)
        end
    end)

    control:Set(defaultValue, true)
    return control
end

local function makeButton(parent, titleText, descText, buttonText, callback, order)
    local card = makeCard(parent, 54, order)
    makeTextPair(card, titleText, descText, 112)

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -14, 0.5, 0)
    button.Size = UDim2.fromOffset(90, 30)
    button.BackgroundColor3 = COLORS.GlassLight
    button.BackgroundTransparency = 0.38
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.Text = buttonText
    button.TextColor3 = COLORS.Text
    button.TextSize = 9
    button.ZIndex = 6
    button.Parent = card
    round(button, 9)
    stroke(button, 0.68)

    connect(button.MouseEnter, function()
        playInjectedHover()
        tween(button, 0.12, { BackgroundTransparency = 0.20 })
    end)

    connect(button.MouseLeave, function()
        tween(button, 0.12, { BackgroundTransparency = 0.38 })
    end)

    connect(button.MouseButton1Click, function()
        playInjectedClick()
        if type(callback) == "function" then
            callback()
        end
    end)

    return button
end

local function currentCamera()
    return Services.Workspace.CurrentCamera
end

local function currentHumanoid()
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function captureHumanoidDefaults(humanoid)
    if not humanoid then
        return
    end

    state.player.humanoidDefaults = {
        WalkSpeed = humanoid.WalkSpeed,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        CameraOffset = humanoid.CameraOffset,
    }

    if not state.player.movementOverride then
        state.player.walkSpeed = humanoid.WalkSpeed
        state.player.jumpStrength = humanoid.JumpPower
    end
end

local function applyMovement()
    local humanoid = currentHumanoid()
    local defaults = state.player.humanoidDefaults
    if not humanoid then
        return
    end

    pcall(function()
        if state.player.sprintEnabled and state.player.sprinting then
            humanoid.WalkSpeed = state.player.sprintSpeed
        elseif state.player.movementOverride then
            humanoid.WalkSpeed = state.player.walkSpeed
        elseif defaults and defaults.WalkSpeed ~= nil then
            humanoid.WalkSpeed = defaults.WalkSpeed
        end
    end)

    if state.player.movementOverride then
        pcall(function()
            humanoid.JumpPower = state.player.jumpStrength
        end)
        pcall(function()
            humanoid.JumpHeight = math.max(1, state.player.jumpStrength / 7.2)
        end)
    elseif defaults then
        pcall(function()
            humanoid.JumpPower = defaults.JumpPower
            humanoid.JumpHeight = defaults.JumpHeight
        end)
    end

    if defaults and defaults.CameraOffset then
        pcall(function()
            humanoid.CameraOffset = defaults.CameraOffset + Vector3.new(0, state.player.cameraOffsetY, 0)
        end)
    end
end

local function restoreMovement()
    local humanoid = currentHumanoid()
    local defaults = state.player.humanoidDefaults
    if not humanoid or not defaults then
        return
    end

    pcall(function()
        humanoid.WalkSpeed = defaults.WalkSpeed
        humanoid.JumpPower = defaults.JumpPower
        humanoid.JumpHeight = defaults.JumpHeight
        humanoid.CameraOffset = defaults.CameraOffset
    end)
end

local camera = currentCamera()
if camera then
    state.player.originalFov = camera.FieldOfView
    state.player.fov = camera.FieldOfView
end
state.player.originalZoom = player.CameraMaxZoomDistance
state.player.zoom = player.CameraMaxZoomDistance

local lighting = Services.Lighting
state.world.original = {
    Ambient = lighting.Ambient,
    OutdoorAmbient = lighting.OutdoorAmbient,
    Brightness = lighting.Brightness,
    ExposureCompensation = lighting.ExposureCompensation,
    ClockTime = lighting.ClockTime,
    FogStart = lighting.FogStart,
    FogEnd = lighting.FogEnd,
    FogColor = lighting.FogColor,
    GlobalShadows = lighting.GlobalShadows,
}
state.world.brightness = lighting.Brightness
state.world.exposure = lighting.ExposureCompensation

ui.worldEffect = lighting:FindFirstChild("SaltyInjectedWorldColor")
if ui.worldEffect then
    ui.worldEffect:Destroy()
end

ui.worldEffect = Instance.new("ColorCorrectionEffect")
ui.worldEffect.Name = "SaltyInjectedWorldColor"
ui.worldEffect.Saturation = 0
ui.worldEffect.Contrast = 0
ui.worldEffect.Brightness = 0
ui.worldEffect.TintColor = Color3.new(1, 1, 1)
ui.worldEffect.Parent = lighting

ui.worldBloom = lighting:FindFirstChild("SaltyInjectedBloom")
if ui.worldBloom then
    ui.worldBloom:Destroy()
end
ui.worldBloom = Instance.new("BloomEffect")
ui.worldBloom.Name = "SaltyInjectedBloom"
ui.worldBloom.Enabled = false
ui.worldBloom.Intensity = 0.7
ui.worldBloom.Size = 24
ui.worldBloom.Threshold = 1
ui.worldBloom.Parent = lighting

ui.worldSunRays = lighting:FindFirstChild("SaltyInjectedSunRays")
if ui.worldSunRays then
    ui.worldSunRays:Destroy()
end
ui.worldSunRays = Instance.new("SunRaysEffect")
ui.worldSunRays.Name = "SaltyInjectedSunRays"
ui.worldSunRays.Enabled = false
ui.worldSunRays.Intensity = 0.08
ui.worldSunRays.Spread = 0.85
ui.worldSunRays.Parent = lighting

local function applyFullbright(enabled)
    state.world.fullbright = enabled == true

    if state.world.fullbright then
        lighting.Ambient = Color3.fromRGB(190, 190, 190)
        lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    else
        lighting.Ambient = state.world.original.Ambient
        lighting.OutdoorAmbient = state.world.original.OutdoorAmbient
    end
end

local function applyFogDisabled(enabled)
    state.world.disableFog = enabled == true

    if state.world.disableFog then
        lighting.FogStart = 100000
        lighting.FogEnd = 1000000
    else
        lighting.FogStart = state.world.original.FogStart
        lighting.FogEnd = state.world.original.FogEnd
        lighting.FogColor = state.world.original.FogColor
    end
end

local function restoreWorld()
    local original = state.world.original

    lighting.Ambient = original.Ambient
    lighting.OutdoorAmbient = original.OutdoorAmbient
    lighting.Brightness = original.Brightness
    lighting.ExposureCompensation = original.ExposureCompensation
    lighting.ClockTime = original.ClockTime
    lighting.FogStart = original.FogStart
    lighting.FogEnd = original.FogEnd
    lighting.FogColor = original.FogColor
    lighting.GlobalShadows = original.GlobalShadows

    if ui.worldEffect and ui.worldEffect.Parent then
        ui.worldEffect.Saturation = 0
        ui.worldEffect.Contrast = 0
        ui.worldEffect.Brightness = 0
        ui.worldEffect.TintColor = Color3.new(1, 1, 1)
    end

    if ui.worldBloom and ui.worldBloom.Parent then
        ui.worldBloom.Enabled = false
        ui.worldBloom.Intensity = 0.7
    end

    if ui.worldSunRays and ui.worldSunRays.Parent then
        ui.worldSunRays.Enabled = false
    end

    state.world.fullbright = false
    state.world.disableFog = false
    state.world.saturation = 0
    state.world.contrast = 0
    state.world.brightness = original.Brightness
    state.world.exposure = original.ExposureCompensation
    state.world.bloom = false
    state.world.bloomIntensity = 0.7
    state.world.sunRays = false
end

ui.crosshair = Instance.new("Frame")
ui.crosshair.Name = "SaltyFeatureCrosshair"
ui.crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
ui.crosshair.Position = UDim2.fromScale(0.5, 0.5)
ui.crosshair.Size = UDim2.fromOffset(64, 64)
ui.crosshair.BackgroundTransparency = 1
ui.crosshair.Visible = false
ui.crosshair.ZIndex = 300
ui.crosshair.Parent = screenGui

ui.crosshairParts = {}

local function newCrosshairPart()
    local part = Instance.new("Frame")
    part.BackgroundColor3 = COLORS.Edge
    part.BackgroundTransparency = 1 - (state.utility.crosshairOpacity / 100)
    part.BorderSizePixel = 0
    part.ZIndex = 301
    part.Parent = ui.crosshair
    table.insert(ui.crosshairParts, part)
    return part
end

ui.crosshairTop = newCrosshairPart()
ui.crosshairBottom = newCrosshairPart()
ui.crosshairLeft = newCrosshairPart()
ui.crosshairRight = newCrosshairPart()

ui.centerDot = Instance.new("Frame")
ui.centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
ui.centerDot.Position = UDim2.fromScale(0.5, 0.5)
ui.centerDot.Size = UDim2.fromOffset(3, 3)
ui.centerDot.BackgroundColor3 = COLORS.Accent
ui.centerDot.BorderSizePixel = 0
ui.centerDot.ZIndex = 302
ui.centerDot.Parent = ui.crosshair
round(ui.centerDot, 4)

local function refreshCrosshair()
    local length = math.clamp(math.floor(state.utility.crosshairSize + 0.5), 6, 24)
    local gap = 5
    local thickness = 1

    ui.crosshairTop.AnchorPoint = Vector2.new(0.5, 1)
    ui.crosshairTop.Position = UDim2.new(0.5, 0, 0.5, -gap)
    ui.crosshairTop.Size = UDim2.fromOffset(thickness, length)

    ui.crosshairBottom.AnchorPoint = Vector2.new(0.5, 0)
    ui.crosshairBottom.Position = UDim2.new(0.5, 0, 0.5, gap)
    ui.crosshairBottom.Size = UDim2.fromOffset(thickness, length)

    ui.crosshairLeft.AnchorPoint = Vector2.new(1, 0.5)
    ui.crosshairLeft.Position = UDim2.new(0.5, -gap, 0.5, 0)
    ui.crosshairLeft.Size = UDim2.fromOffset(length, thickness)

    ui.crosshairRight.AnchorPoint = Vector2.new(0, 0.5)
    ui.crosshairRight.Position = UDim2.new(0.5, gap, 0.5, 0)
    ui.crosshairRight.Size = UDim2.fromOffset(length, thickness)

    local transparency = 1 - (state.utility.crosshairOpacity / 100)
    for _, part in ipairs(ui.crosshairParts) do
        part.BackgroundTransparency = transparency
    end
    ui.centerDot.BackgroundTransparency = transparency
    ui.centerDot.Visible = state.utility.centerDot
    ui.crosshair.Visible = state.utility.crosshair
end

ui.fpsCard = Instance.new("Frame")
ui.fpsCard.Name = "SaltyFeatureFPS"
ui.fpsCard.Position = UDim2.fromOffset(18, 18)
ui.fpsCard.Size = UDim2.fromOffset(184, 34)
ui.fpsCard.BackgroundColor3 = COLORS.GlassBase
ui.fpsCard.BackgroundTransparency = 0.16
ui.fpsCard.BorderSizePixel = 0
ui.fpsCard.Visible = false
ui.fpsCard.ZIndex = 300
ui.fpsCard.Parent = screenGui
round(ui.fpsCard, 12)
stroke(ui.fpsCard, 0.62)

ui.fpsLabel = Instance.new("TextLabel")
ui.fpsLabel.Size = UDim2.fromScale(1, 1)
ui.fpsLabel.BackgroundTransparency = 1
ui.fpsLabel.Font = Enum.Font.GothamBold
ui.fpsLabel.Text = "FPS --   |   PING --   |   0:00"
ui.fpsLabel.TextColor3 = COLORS.Text
ui.fpsLabel.TextSize = 10
ui.fpsLabel.ZIndex = 301
ui.fpsLabel.Parent = ui.fpsCard

refreshCrosshair()


local function findOriginalTabButton(name)
    local tabRail = mainFrame:FindFirstChild("TabRail")
    return tabRail and tabRail:FindFirstChild(name .. "Tab")
end

local function setInjectedTabVisual(button, selected)
    if not button then
        return
    end

    tween(button, 0.14, {
        BackgroundTransparency = selected and 0.70 or 0.91,
        BackgroundColor3 = COLORS.GlassLight,
    })

    local itemStroke = button:FindFirstChildOfClass("UIStroke")
    if itemStroke then
        tween(itemStroke, 0.14, {
            Transparency = selected and 0.38 or 0.84,
            Color = COLORS.Edge,
        })
    end

    local itemScale = button:FindFirstChildOfClass("UIScale")
    if itemScale then
        tween(itemScale, 0.14, {
            Scale = selected and 1.018 or 1,
        })
    end

    local itemIcon = button:FindFirstChildOfClass("ImageLabel")
    if itemIcon then
        tween(itemIcon, 0.14, {
            ImageColor3 = selected and COLORS.Accent or COLORS.SubText,
            ImageTransparency = selected and 0 or 0.18,
        })
    end
end

local function createWorldTab()
    local tabRail = mainFrame:FindFirstChild("TabRail")
    local visualsTab = findOriginalTabButton("Visuals")
    local visualsPage = pages.Visuals

    if not tabRail or not visualsTab or not visualsPage then
        error("Could not create the World tab from the original Salty chrome.", 0)
    end

    local oldTab = tabRail:FindFirstChild("WorldTab")
    if oldTab then
        oldTab:Destroy()
    end

    local oldPage = contentArea:FindFirstChild("WorldPage")
    if oldPage then
        oldPage:Destroy()
    end

    local worldTabButton = visualsTab:Clone()
    worldTabButton.Name = "WorldTab"
    worldTabButton.LayoutOrder = 5
    worldTabButton.Parent = tabRail

    for _, child in ipairs(worldTabButton:GetChildren()) do
        if child:IsA("TextLabel") then
            child.Text = "World"
        elseif child:IsA("ImageLabel") then
            local globeAsset = LUCIDE["globe-2"] or LUCIDE["globe"]
            if globeAsset then
                child.Image = globeAsset
                child:SetAttribute("LucideName", LUCIDE["globe-2"] and "globe-2" or "globe")
            end
        end
    end

    local worldPage = visualsPage:Clone()
    worldPage.Name = "WorldPage"
    worldPage.Visible = false
    worldPage.GroupTransparency = 0
    worldPage.Position = UDim2.fromOffset(0, 0)
    worldPage.Parent = contentArea

    for _, child in ipairs(worldPage:GetChildren()) do
        if child:IsA("TextLabel") then
            child.Text = "WORLD"
            break
        end
    end

    local worldBody = worldPage:FindFirstChild("PageBody")
    if not worldBody then
        error("WorldPage is missing PageBody.", 0)
    end

    for _, child in ipairs(worldBody:GetChildren()) do
        if not child:IsA("UIPadding") and not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    pages.World = worldPage
    bodies.World = worldBody
    ui.worldTab = worldTabButton
    ui.worldPage = worldPage
    state.worldTabActive = false

    local indicator = nil
    local indicatorGlow = nil
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("Frame") then
            if child.Size.X.Offset == 2 and child.Size.Y.Offset == 22 and child.Position.X.Offset == 9 then
                indicator = child
            elseif child.Size.X.Offset == 8 and child.Size.Y.Offset == 30 and child.Position.X.Offset == 6 then
                indicatorGlow = child
            end
        end
    end

    local titleBar = mainFrame:FindFirstChild("TitleBar")
    local contextPill = titleBar and titleBar:FindFirstChild("TabContextPill")

    local function renderWorldContext()
        if not contextPill then
            return
        end
        for _, item in ipairs(contextPill:GetDescendants()) do
            if item:IsA("TextLabel") then
                item.Text = item.TextSize >= 8 and "WORLD" or "ENVIRONMENT"
            end
        end
    end

    local function showWorld()
        state.worldTabActive = true

        for _, item in ipairs(contentArea:GetChildren()) do
            if item:IsA("CanvasGroup") and string.sub(item.Name, -4) == "Page" then
                item.Visible = false
                item.GroupTransparency = 0
                item.Position = UDim2.fromOffset(0, 0)
            end
        end

        for _, item in ipairs(tabRail:GetChildren()) do
            if item:IsA("TextButton") then
                setInjectedTabVisual(item, item == worldTabButton)
            end
        end

        worldPage.Visible = true
        worldPage.GroupTransparency = 1
        worldPage.Position = UDim2.fromOffset(0, 6)
        tween(worldPage, 0.14, {
            GroupTransparency = 0,
            Position = UDim2.fromOffset(0, 0),
        })

        if indicator then
            tween(indicator, 0.18, { Position = UDim2.new(0, 9, 0, 292) })
        end
        if indicatorGlow then
            tween(indicatorGlow, 0.18, { Position = UDim2.new(0, 6, 0, 288) })
        end

        renderWorldContext()
    end

    connect(worldTabButton.MouseEnter, function()
        playInjectedHover()
        if not state.worldTabActive then
            tween(worldTabButton, 0.14, { BackgroundTransparency = 0.80 })
        end
    end)

    connect(worldTabButton.MouseLeave, function()
        if not state.worldTabActive then
            tween(worldTabButton, 0.14, { BackgroundTransparency = 0.91 })
        end
    end)

    connect(worldTabButton.MouseButton1Click, function()
        playInjectedClick()
        showWorld()
    end)

    for _, name in ipairs({ "Home", "Player", "Settings", "Visuals" }) do
        local originalButton = findOriginalTabButton(name)
        local originalPage = contentArea:FindFirstChild(name .. "Page")

        if originalButton then
            connect(originalButton.MouseButton1Click, function()
                if state.worldTabActive then
                    state.worldTabActive = false
                    worldPage.Visible = false
                    setInjectedTabVisual(worldTabButton, false)

                    if originalPage then
                        originalPage.Visible = true
                        originalPage.GroupTransparency = 0
                        originalPage.Position = UDim2.fromOffset(0, 0)
                    end
                end
            end)
        end
    end
end

createWorldTab()

makeHeader(bodies.Player, "PLAYER FEATURES", 500)

ui.controls.movementOverride = makeToggle(
    bodies.Player,
    "Movement Override",
    "Apply the custom WalkSpeed and Jump Strength values.",
    false,
    function(enabled)
        state.player.movementOverride = enabled
        applyMovement()
        showStatus(enabled and "Movement override enabled" or "Movement override disabled")
    end,
    501
)

ui.controls.walkSpeed = makeSlider(
    bodies.Player, "WalkSpeed", "Local humanoid movement speed.",
    8, 50, state.player.walkSpeed, 1, "",
    function(value)
        state.player.walkSpeed = value
        applyMovement()
    end,
    502
)

ui.controls.jumpStrength = makeSlider(
    bodies.Player, "Jump Strength", "Adjust local JumpPower/JumpHeight.",
    20, 100, state.player.jumpStrength, 1, "",
    function(value)
        state.player.jumpStrength = value
        applyMovement()
    end,
    503
)

ui.controls.sprint = makeToggle(
    bodies.Player,
    "Hold Shift to Sprint",
    "Uses Sprint Speed while LeftShift is held.",
    false,
    function(enabled)
        state.player.sprintEnabled = enabled
        if not enabled then
            state.player.sprinting = false
        end
        applyMovement()
        showStatus(enabled and "Sprint enabled" or "Sprint disabled")
    end,
    504
)

ui.controls.sprintSpeed = makeSlider(
    bodies.Player, "Sprint Speed", "WalkSpeed used while sprinting.",
    18, 60, 28, 1, "",
    function(value)
        state.player.sprintSpeed = value
        applyMovement()
    end,
    505
)

ui.controls.fov = makeSlider(
    bodies.Player, "Camera FOV", "Adjust the local camera field of view.",
    50, 120, state.player.fov, 1, " deg",
    function(value)
        state.player.fov = value
        local activeCamera = currentCamera()
        if activeCamera then
            activeCamera.FieldOfView = value
        end
    end,
    506
)

ui.controls.zoom = makeSlider(
    bodies.Player, "Max Camera Zoom", "Set maximum third-person camera distance.",
    5, 40, math.clamp(state.player.zoom, 5, 40), 1, "",
    function(value)
        state.player.zoom = value
        player.CameraMaxZoomDistance = value
    end,
    507
)

ui.controls.mouseSensitivity = makeSlider(
    bodies.Player, "Mouse Sensitivity", "Adjust Roblox client mouse sensitivity.",
    0.2, 3, state.player.mouseSensitivity, 0.1, "x",
    function(value)
        state.player.mouseSensitivity = value
        Services.UserInputService.MouseDeltaSensitivity = value
    end,
    508
)

ui.controls.cameraOffset = makeSlider(
    bodies.Player, "Camera Height Offset", "Raise or lower the humanoid camera.",
    -2, 2, 0, 0.1, "",
    function(value)
        state.player.cameraOffsetY = value
        applyMovement()
    end,
    509
)

makeButton(
    bodies.Player,
    "Reset Player Features",
    "Restore movement, camera, zoom, sprint, and input settings.",
    "RESET",
    function()
        state.player.movementOverride = false
        state.player.sprintEnabled = false
        state.player.sprinting = false
        state.player.sprintSpeed = 28
        state.player.cameraOffsetY = 0

        ui.controls.movementOverride:Set(false, true)
        ui.controls.sprint:Set(false, true)
        ui.controls.sprintSpeed:Set(28, true)
        ui.controls.cameraOffset:Set(0, true)

        restoreMovement()

        local activeCamera = currentCamera()
        if activeCamera then
            activeCamera.FieldOfView = state.player.originalFov
        end
        state.player.fov = state.player.originalFov
        ui.controls.fov:Set(state.player.originalFov, true)

        player.CameraMaxZoomDistance = state.player.originalZoom
        state.player.zoom = state.player.originalZoom
        ui.controls.zoom:Set(math.clamp(state.player.originalZoom, 5, 40), true)

        Services.UserInputService.MouseDeltaSensitivity = state.player.originalMouseSensitivity
        state.player.mouseSensitivity = state.player.originalMouseSensitivity
        ui.controls.mouseSensitivity:Set(state.player.originalMouseSensitivity, true)

        local humanoid = currentHumanoid()
        if humanoid then
            state.player.walkSpeed = humanoid.WalkSpeed
            state.player.jumpStrength = humanoid.JumpPower
            ui.controls.walkSpeed:Set(humanoid.WalkSpeed, true)
            ui.controls.jumpStrength:Set(humanoid.JumpPower, true)
        end

        showStatus("Player features reset")
    end,
    510
)

makeHeader(bodies.World, "ENVIRONMENT", 500)

ui.controls.fullbright = makeToggle(
    bodies.World, "Fullbright", "Brighten ambient lighting locally.",
    false,
    function(enabled)
        applyFullbright(enabled)
        showStatus(enabled and "Fullbright enabled" or "Fullbright disabled")
    end,
    501
)

ui.controls.disableFog = makeToggle(
    bodies.World, "Disable Fog", "Push local fog far into the distance.",
    false,
    function(enabled)
        applyFogDisabled(enabled)
        showStatus(enabled and "Fog disabled" or "Fog restored")
    end,
    502
)

ui.controls.shadows = makeToggle(
    bodies.World, "Global Shadows", "Toggle Lighting.GlobalShadows locally.",
    state.world.original.GlobalShadows,
    function(enabled)
        lighting.GlobalShadows = enabled
    end,
    503
)

ui.controls.clockTime = makeSlider(
    bodies.World, "Time of Day", "Adjust local Lighting clock.",
    0, 24, state.world.original.ClockTime, 0.5, "h",
    function(value)
        lighting.ClockTime = value
    end,
    504
)

ui.controls.brightness = makeSlider(
    bodies.World, "Brightness", "Adjust local Lighting brightness.",
    0, 5, math.clamp(state.world.original.Brightness, 0, 5), 0.1, "",
    function(value)
        state.world.brightness = value
        lighting.Brightness = value
    end,
    505
)

ui.controls.exposure = makeSlider(
    bodies.World, "Exposure", "Adjust exposure compensation.",
    -3, 3, math.clamp(state.world.original.ExposureCompensation, -3, 3), 0.1, "",
    function(value)
        state.world.exposure = value
        lighting.ExposureCompensation = value
    end,
    506
)

ui.controls.saturation = makeSlider(
    bodies.World, "Saturation", "Adjust world color intensity.",
    -100, 100, 0, 5, "%",
    function(value)
        state.world.saturation = value
        ui.worldEffect.Saturation = value / 100
    end,
    507
)

ui.controls.contrast = makeSlider(
    bodies.World, "Contrast", "Adjust world contrast.",
    -100, 100, 0, 5, "%",
    function(value)
        state.world.contrast = value
        ui.worldEffect.Contrast = value / 100
    end,
    508
)

ui.controls.bloom = makeToggle(
    bodies.World, "Salty Bloom", "Enable a dedicated local bloom effect.",
    false,
    function(enabled)
        state.world.bloom = enabled
        ui.worldBloom.Enabled = enabled
        showStatus(enabled and "Bloom enabled" or "Bloom disabled")
    end,
    509
)

ui.controls.bloomIntensity = makeSlider(
    bodies.World, "Bloom Intensity", "Control Salty Bloom strength.",
    0, 3, 0.7, 0.1, "",
    function(value)
        state.world.bloomIntensity = value
        ui.worldBloom.Intensity = value
    end,
    510
)

ui.controls.sunRays = makeToggle(
    bodies.World, "Sun Rays", "Enable subtle dedicated local sun rays.",
    false,
    function(enabled)
        state.world.sunRays = enabled
        ui.worldSunRays.Enabled = enabled
        showStatus(enabled and "Sun rays enabled" or "Sun rays disabled")
    end,
    511
)

makeButton(
    bodies.World,
    "Reset World",
    "Restore lighting, fog, effects, color, and time.",
    "RESET",
    function()
        restoreWorld()
        ui.controls.fullbright:Set(false, true)
        ui.controls.disableFog:Set(false, true)
        ui.controls.shadows:Set(state.world.original.GlobalShadows, true)
        ui.controls.clockTime:Set(state.world.original.ClockTime, true)
        ui.controls.brightness:Set(math.clamp(state.world.original.Brightness, 0, 5), true)
        ui.controls.exposure:Set(math.clamp(state.world.original.ExposureCompensation, -3, 3), true)
        ui.controls.saturation:Set(0, true)
        ui.controls.contrast:Set(0, true)
        ui.controls.bloom:Set(false, true)
        ui.controls.bloomIntensity:Set(0.7, true)
        ui.controls.sunRays:Set(false, true)
        showStatus("World settings reset")
    end,
    512
)

makeHeader(bodies.Visuals, "UTILITY", 520)

ui.controls.crosshair = makeToggle(
    bodies.Visuals, "Custom Crosshair", "Show a cosmetic center crosshair.",
    false,
    function(enabled)
        state.utility.crosshair = enabled
        refreshCrosshair()
        showStatus(enabled and "Crosshair enabled" or "Crosshair disabled")
    end,
    521
)

ui.controls.centerDot = makeToggle(
    bodies.Visuals, "Center Dot", "Show the accent-colored center dot.",
    true,
    function(enabled)
        state.utility.centerDot = enabled
        refreshCrosshair()
    end,
    522
)

ui.controls.crosshairSize = makeSlider(
    bodies.Visuals, "Crosshair Size", "Adjust crosshair arm length.",
    6, 24, 12, 1, "",
    function(value)
        state.utility.crosshairSize = value
        refreshCrosshair()
    end,
    523
)

ui.controls.crosshairOpacity = makeSlider(
    bodies.Visuals, "Crosshair Opacity", "Adjust crosshair visibility.",
    20, 100, 92, 1, "%",
    function(value)
        state.utility.crosshairOpacity = value
        refreshCrosshair()
    end,
    524
)

ui.controls.fps = makeToggle(
    bodies.Visuals,
    "Performance Overlay",
    "Show FPS, ping, and feature-pack session time.",
    false,
    function(enabled)
        state.utility.fps = enabled
        ui.fpsCard.Visible = enabled
        showStatus(enabled and "Performance overlay enabled" or "Performance overlay disabled")
    end,
    525
)

makeButton(
    bodies.Visuals,
    "Reset Utility",
    "Restore crosshair and overlay defaults.",
    "RESET",
    function()
        state.utility.crosshair = false
        state.utility.centerDot = true
        state.utility.crosshairSize = 12
        state.utility.crosshairOpacity = 92
        state.utility.fps = false

        ui.controls.crosshair:Set(false, true)
        ui.controls.centerDot:Set(true, true)
        ui.controls.crosshairSize:Set(12, true)
        ui.controls.crosshairOpacity:Set(92, true)
        ui.controls.fps:Set(false, true)

        refreshCrosshair()
        ui.fpsCard.Visible = false
        showStatus("Utility features reset")
    end,
    526
)

connect(Services.UserInputService.InputBegan, function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.LeftShift and state.player.sprintEnabled then
        state.player.sprinting = true
        applyMovement()
    end
end)

connect(Services.UserInputService.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        state.player.sprinting = false
        applyMovement()
    end
end)

local function onCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then
        return
    end

    task.wait(0.1)
    captureHumanoidDefaults(humanoid)

    if state.player.movementOverride or state.player.sprintEnabled or state.player.cameraOffsetY ~= 0 then
        applyMovement()
    else
        state.player.walkSpeed = humanoid.WalkSpeed
        state.player.jumpStrength = humanoid.JumpPower
        if ui.controls.walkSpeed then
            ui.controls.walkSpeed:Set(humanoid.WalkSpeed, true)
        end
        if ui.controls.jumpStrength then
            ui.controls.jumpStrength:Set(humanoid.JumpPower, true)
        end
    end
end

if player.Character then
    task.spawn(onCharacter, player.Character)
end
connect(player.CharacterAdded, onCharacter)

state.fpsFrames = 0
state.fpsElapsed = 0
connect(Services.RunService.RenderStepped, function(dt)
    if state.destroyed then
        return
    end

    state.fpsFrames = state.fpsFrames + 1
    state.fpsElapsed = state.fpsElapsed + dt

    if state.fpsElapsed >= 0.45 then
        local fps = math.floor((state.fpsFrames / state.fpsElapsed) + 0.5)
        local pingText = "--"
        pcall(function()
            local item = Services.Stats.Network.ServerStatsItem["Data Ping"]
            pingText = tostring(math.floor(item:GetValue() + 0.5))
        end)

        local session = math.floor(os.clock() - state.utility.sessionStart)
        local minutes = math.floor(session / 60)
        local seconds = session % 60

        ui.fpsLabel.Text = string.format(
            "FPS %d   |   PING %s   |   %d:%02d",
            fps,
            pingText,
            minutes,
            seconds
        )

        state.fpsFrames = 0
        state.fpsElapsed = 0
    end
end)

local function cleanup()
    if state.destroyed then
        return
    end
    state.destroyed = true

    restoreMovement()

    local activeCamera = currentCamera()
    if activeCamera then
        activeCamera.FieldOfView = state.player.originalFov
    end
    player.CameraMaxZoomDistance = state.player.originalZoom
    Services.UserInputService.MouseDeltaSensitivity = state.player.originalMouseSensitivity

    restoreWorld()

    if ui.worldEffect and ui.worldEffect.Parent then
        ui.worldEffect:Destroy()
    end
    if ui.worldBloom and ui.worldBloom.Parent then
        ui.worldBloom:Destroy()
    end
    if ui.worldSunRays and ui.worldSunRays.Parent then
        ui.worldSunRays:Destroy()
    end

    for _, connection in ipairs(state.connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(state.connections)
end

connect(screenGui.Destroying, cleanup)

showStatus("Expanded features + World tab loaded")
