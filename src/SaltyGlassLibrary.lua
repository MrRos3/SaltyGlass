-- SaltyGlass UI Library v1.1.0
-- Reusable Roblox client UI library by MrRos3.
--
-- Stable raw URL:
-- https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/library.lua
--
-- This file returns the SaltyGlass library table.
-- It does not create a window until SaltyGlass:CreateWindow(...) is called.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("SaltyGlass Library must be executed on the Roblox client.", 0)
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SaltyGlass = {
    Version = "1.1.0",
    Name = "SaltyGlass",
}

SaltyGlass.Themes = {
    Violet = Color3.fromRGB(139, 124, 255),
    Blue = Color3.fromRGB(92, 156, 255),
    Cyan = Color3.fromRGB(93, 231, 255),
    Pink = Color3.fromRGB(255, 114, 215),
    Green = Color3.fromRGB(109, 255, 168),
    Orange = Color3.fromRGB(255, 177, 92),
    Red = Color3.fromRGB(255, 107, 122),
}

SaltyGlass.Icons = {
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

local COLORS = {
    GlassBase = Color3.fromRGB(9, 13, 24),
    GlassMid = Color3.fromRGB(17, 24, 42),
    GlassLight = Color3.fromRGB(27, 36, 64),
    Card = Color3.fromRGB(19, 27, 47),
    CardHover = Color3.fromRGB(27, 37, 62),
    Edge = Color3.new(1, 1, 1),
    Text = Color3.new(1, 1, 1),
    SubText = Color3.fromRGB(181, 188, 211),
    Muted = Color3.fromRGB(111, 120, 149),
    Success = Color3.fromRGB(109, 255, 168),
    Warning = Color3.fromRGB(255, 209, 102),
    Danger = Color3.fromRGB(255, 107, 122),
}

local DEFAULTS = {
    Accent = SaltyGlass.Themes.Violet,
    Size = UDim2.fromOffset(640, 470),
    MinSize = Vector2.new(420, 360),
    MaxSize = Vector2.new(1000, 800),
    ToggleKey = Enum.KeyCode.RightShift,
    ReduceMotion = false,
}

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabMethods = {}
TabMethods.__index = TabMethods

local ControlMethods = {}
ControlMethods.__index = ControlMethods

local MusicMethods = {}
MusicMethods.__index = MusicMethods

local function copyTable(source)
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function merge(base, overrides)
    local result = copyTable(base)
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

local function apply(instance, properties)
    local parent = properties and properties.Parent
    for key, value in pairs(properties or {}) do
        if key ~= "Parent" then
            instance[key] = value
        end
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function make(className, properties)
    return apply(Instance.new(className), properties or {})
end

local function round(instance, radius)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
        Parent = instance,
    })
end

local function stroke(instance, thickness, transparency)
    return make("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0.78,
        Color = COLORS.Edge,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = instance,
    })
end

local function padding(instance, left, right, top, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = instance,
    })
end

local function listLayout(instance, spacing)
    return make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, spacing or 8),
        Parent = instance,
    })
end

local function textLabel(parent, text, size, color, font, alignment)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or COLORS.Text,
        TextSize = size or 12,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
        Parent = parent,
    })
end

local function icon(parent, name, size, color, zIndex)
    local image = SaltyGlass.Icons[name or ""]
    if not image then
        return nil
    end

    return make("ImageLabel", {
        BackgroundTransparency = 1,
        Image = image,
        ImageColor3 = color or COLORS.Text,
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.fromOffset(size or 16, size or 16),
        ZIndex = zIndex or 1,
        Parent = parent,
    })
end

local function normalizeSize(value, fallback)
    if typeof(value) == "UDim2" then
        return value
    end
    if typeof(value) == "Vector2" then
        return UDim2.fromOffset(value.X, value.Y)
    end
    return fallback
end

local function normalizePosition(value)
    if typeof(value) == "UDim2" then
        return value
    end
    if typeof(value) == "Vector2" then
        return UDim2.fromOffset(value.X, value.Y)
    end
    return UDim2.fromScale(0.5, 0.5)
end

local function normalizeAudioId(value)
    local source = tostring(value or "")
    local best = nil
    for digits in string.gmatch(source, "%d+") do
        if not best or #digits > #best then
            best = digits
        end
    end
    return best
end

local function formatClock(seconds)
    local value = math.max(0, tonumber(seconds) or 0)
    local minutes = math.floor(value / 60)
    local secs = math.floor(value % 60)
    return string.format("%d:%02d", minutes, secs)
end

local function keyName(key)
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    return tostring(key or "")
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return true
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[SaltyGlass] Callback error: " .. tostring(err))
    end
    return ok
end

local function setTextPair(titleLabel, descriptionLabel, name, description)
    if titleLabel then
        titleLabel.Text = tostring(name or "")
    end
    if descriptionLabel then
        local desc = tostring(description or "")
        descriptionLabel.Text = desc
        descriptionLabel.Visible = desc ~= ""
    end
end

function SaltyGlass.GetIconAsset(name)
    return SaltyGlass.Icons[name]
end

function SaltyGlass.CreateIcon(parent, name, size, color, zIndex)
    return icon(parent, name, size, color, zIndex)
end

function WindowMethods:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function WindowMethods:_tween(instance, duration, properties, style, direction)
    if self._destroyed or not instance then
        return nil
    end

    if self._reduceMotion then
        for key, value in pairs(properties) do
            instance[key] = value
        end
        return nil
    end

    local tween = TweenService:Create(
        instance,
        TweenInfo.new(
            duration or 0.16,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
    tween:Play()
    return tween
end

function WindowMethods:_bindAccent(instance, property)
    table.insert(self._accentBindings, {
        Instance = instance,
        Property = property or "BackgroundColor3",
    })
    instance[property or "BackgroundColor3"] = self._accent
end

function WindowMethods:_newCard(parent, height)
    local frame = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 62),
        BackgroundColor3 = COLORS.Card,
        BackgroundTransparency = 0.34,
        BorderSizePixel = 0,
        Parent = parent,
    })
    round(frame, 13)
    stroke(frame, 1, 0.82)
    return frame
end

function WindowMethods:_hover(frame, hitbox)
    if not frame or not hitbox then
        return
    end

    self:_connect(hitbox.MouseEnter, function()
        self:_tween(frame, 0.12, { BackgroundTransparency = 0.20 })
    end)

    self:_connect(hitbox.MouseLeave, function()
        self:_tween(frame, 0.14, { BackgroundTransparency = 0.34 })
    end)
end

function WindowMethods:_renderContext(tab)
    if not self._contextFrame then
        return
    end

    if not tab then
        self._contextText.Text = "READY"
        self._contextText.TextColor3 = COLORS.SubText
        self._contextText.Position = UDim2.fromOffset(32, 0)
        self._contextText.Size = UDim2.new(1, -42, 1, 0)
        if self._contextSub then
            self._contextSub.Visible = false
        end
        if self._contextIcon then
            self._contextIcon.Visible = false
        end
        return
    end

    self._contextText.Text = string.upper(tab.Name)
    self._contextText.TextColor3 = COLORS.SubText
    self._contextText.Position = UDim2.fromOffset(32, 0)
    self._contextText.Size = UDim2.new(1, -42, 1, 0)
    if self._contextSub then
        self._contextSub.Visible = false
    end

    local asset = SaltyGlass.Icons[tab.Icon or ""]
    if asset and self._contextIcon then
        self._contextIcon.Image = asset
        self._contextIcon.Visible = true
    elseif self._contextIcon then
        self._contextIcon.Visible = false
    end
end

function WindowMethods:_setContext(tab)
    self._contextTab = tab
    if not self._statusActive then
        self:_renderContext(tab)
    end
end

function WindowMethods:ShowStatus(titleOrOptions, subtitle, duration, color)
    if self._destroyed or not self._contextFrame or self._options.StatusIsland == false then
        return
    end

    local options
    if type(titleOrOptions) == "table" then
        options = titleOrOptions
    else
        options = {
            Title = titleOrOptions,
            Subtitle = subtitle,
            Duration = duration,
            Color = color,
        }
    end

    self._statusToken = (self._statusToken or 0) + 1
    local token = self._statusToken
    self._statusActive = true

    local statusTitle = tostring(options.Title or "SALTY")
    local statusSub = tostring(options.Subtitle or options.Message or "")
    local statusColor = typeof(options.Color) == "Color3" and options.Color or self._accent
    local statusIcon = options.Icon or "home"

    if self._contextIcon then
        local asset = SaltyGlass.Icons[statusIcon]
        if asset then
            self._contextIcon.Image = asset
            self._contextIcon.ImageColor3 = statusColor
            self._contextIcon.Visible = true
        else
            self._contextIcon.Visible = false
        end
    end

    self._contextText.Text = statusTitle
    self._contextText.TextColor3 = COLORS.Text
    self._contextText.Position = UDim2.fromOffset(34, 3)
    self._contextText.Size = UDim2.new(1, -44, 0, 15)

    if self._contextSub then
        self._contextSub.Text = statusSub
        self._contextSub.Visible = statusSub ~= ""
    end

    local targetSize = UDim2.fromOffset(statusSub ~= "" and 206 or 174, statusSub ~= "" and 38 or 32)
    if self._reduceMotion then
        self._contextFrame.Size = targetSize
    else
        self:_tween(self._contextFrame, 0.16, { Size = targetSize })
    end

    task.delay(math.max(0.25, tonumber(options.Duration) or 1.6), function()
        if self._destroyed or token ~= self._statusToken then
            return
        end

        self._statusActive = false
        if self._contextSub then
            self._contextSub.Visible = false
        end
        if self._contextIcon then
            self._contextIcon.ImageColor3 = self._accent
        end

        local normalSize = self._contextBaseSize or UDim2.fromOffset(138, 32)
        if self._reduceMotion then
            self._contextFrame.Size = normalSize
        else
            self:_tween(self._contextFrame, 0.15, { Size = normalSize })
        end
        self:_renderContext(self._contextTab or self._activeTab)
    end)
end

function WindowMethods:_refreshTabs()
    for _, tab in ipairs(self._tabs) do
        local selected = self._activeTab == tab
        local targetTransparency = selected and 0.76 or 1
        local targetText = selected and COLORS.Text or COLORS.SubText
        local iconColor = selected and self._accent or COLORS.Muted

        self:_tween(tab._buttonFill, 0.13, {
            BackgroundTransparency = targetTransparency,
        })
        self:_tween(tab._buttonText, 0.13, {
            TextColor3 = targetText,
        })
        if tab._buttonIcon then
            self:_tween(tab._buttonIcon, 0.13, {
                ImageColor3 = iconColor,
            })
        end
    end
end

function WindowMethods:SelectTab(tabOrName)
    if self._destroyed then
        return nil
    end

    local target = nil
    if type(tabOrName) == "table" and tabOrName._window == self then
        target = tabOrName
    else
        local wanted = tostring(tabOrName or "")
        for _, tab in ipairs(self._tabs) do
            if tab.Name == wanted then
                target = tab
                break
            end
        end
    end

    if not target then
        return nil
    end

    local previous = self._activeTab
    self._activeTab = target

    if previous and previous ~= target then
        local previousGroup = previous._pageGroup or previous._page
        previousGroup.Visible = true

        if self._reduceMotion or self._options.SmoothTransitions == false then
            previousGroup.Visible = false
            if previous._pageGroup then
                previous._pageGroup.GroupTransparency = 0
            end
            previous._page.Position = UDim2.fromOffset(0, 0)
        else
            if previous._pageGroup then
                self:_tween(previous._pageGroup, 0.09, { GroupTransparency = 1 })
            end
            self:_tween(previous._page, 0.09, { Position = UDim2.fromOffset(0, -4) })
            task.delay(0.095, function()
                if not self._destroyed and self._activeTab ~= previous then
                    previousGroup.Visible = false
                    if previous._pageGroup then
                        previous._pageGroup.GroupTransparency = 0
                    end
                    previous._page.Position = UDim2.fromOffset(0, 0)
                end
            end)
        end
    end

    local targetGroup = target._pageGroup or target._page
    targetGroup.Visible = true

    if self._reduceMotion or self._options.SmoothTransitions == false then
        if target._pageGroup then
            target._pageGroup.GroupTransparency = 0
        end
        target._page.Position = UDim2.fromOffset(0, 0)
        target._pageScale.Scale = 1
    else
        if target._pageGroup then
            target._pageGroup.GroupTransparency = 1
            self:_tween(target._pageGroup, 0.14, { GroupTransparency = 0 })
        end
        target._page.Position = UDim2.fromOffset(0, 6)
        target._pageScale.Scale = 0.992
        self:_tween(target._page, 0.14, { Position = UDim2.fromOffset(0, 0) })
        self:_tween(target._pageScale, 0.14, { Scale = 1 })

        if self._pageSweep then
            self._pageSweepToken = (self._pageSweepToken or 0) + 1
            local sweepToken = self._pageSweepToken
            self._pageSweep.Position = UDim2.new(-0.18, 0, 0, 0)
            self._pageSweep.Visible = true
            self:_tween(self._pageSweep, 0.20, { Position = UDim2.new(1.05, 0, 0, 0) }, Enum.EasingStyle.Sine)
            task.delay(0.21, function()
                if not self._destroyed and sweepToken == self._pageSweepToken and self._pageSweep then
                    self._pageSweep.Visible = false
                end
            end)
        end
    end

    self:_setContext(target)
    self:_refreshTabs()
    return target
end

function WindowMethods:GetTab(name)
    for _, tab in ipairs(self._tabs) do
        if tab.Name == name then
            return tab
        end
    end
    return nil
end

function WindowMethods:AddTab(nameOrOptions, iconName)
    if self._destroyed then
        return nil
    end

    local options
    if type(nameOrOptions) == "table" then
        options = nameOrOptions
    else
        options = {
            Name = nameOrOptions,
            Icon = iconName,
        }
    end

    local tab = setmetatable({
        _window = self,
        _controls = {},
        Name = tostring(options.Name or options.Title or ("Tab " .. tostring(#self._tabs + 1))),
        Icon = options.Icon,
    }, TabMethods)

    local button = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = #self._tabs + 1,
        Parent = self._tabList,
    })

    local fill = make("Frame", {
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundColor3 = self._accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = button,
    })
    round(fill, 10)
    stroke(fill, 1, 0.91)
    self:_bindAccent(fill)

    local tabIcon = icon(button, tab.Icon, 15, COLORS.Muted, 3)
    if tabIcon then
        tabIcon.AnchorPoint = Vector2.new(0, 0.5)
        tabIcon.Position = UDim2.new(0, 12, 0.5, 0)
    end

    local label = textLabel(button, tab.Name, 11, COLORS.SubText, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(tabIcon and 36 or 14, 0)
    label.Size = UDim2.new(1, -(tabIcon and 46 or 24), 1, 0)
    label.ZIndex = 3

    local pageGroup = make("CanvasGroup", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Visible = false,
        Parent = self._content,
    })

    local page = make("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self._accent,
        ScrollBarImageTransparency = 0.45,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = pageGroup,
    })
    self:_bindAccent(page, "ScrollBarImageColor3")
    padding(page, 14, 14, 14, 16)
    listLayout(page, 10)

    local pageScale = make("UIScale", {
        Scale = 1,
        Parent = page,
    })

    tab._button = button
    tab._buttonFill = fill
    tab._buttonText = label
    tab._buttonIcon = tabIcon
    tab._pageGroup = pageGroup
    tab._page = page
    tab._pageScale = pageScale

    table.insert(self._tabs, tab)

    self:_connect(button.MouseButton1Click, function()
        self:SelectTab(tab)
    end)

    self:_connect(button.MouseEnter, function()
        if self._activeTab ~= tab then
            self:_tween(label, 0.12, { TextColor3 = COLORS.Text })
        end
    end)

    self:_connect(button.MouseLeave, function()
        if self._activeTab ~= tab then
            self:_tween(label, 0.12, { TextColor3 = COLORS.SubText })
        end
    end)

    if #self._tabs == 1 then
        self:SelectTab(tab)
    end

    return tab
end

function WindowMethods:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return false
    end

    self._accent = color
    for index = #self._accentBindings, 1, -1 do
        local binding = self._accentBindings[index]
        if binding.Instance and binding.Instance.Parent then
            binding.Instance[binding.Property] = color
        else
            table.remove(self._accentBindings, index)
        end
    end

    self:_refreshTabs()
    if self._music and not self._music._destroyed then
        self._music:_refreshVisuals()
    end
    return true
end

function WindowMethods:GetAccent()
    return self._accent
end

function WindowMethods:SetTheme(theme)
    if typeof(theme) == "Color3" then
        return self:SetAccent(theme)
    end

    if type(theme) == "string" and SaltyGlass.Themes[theme] then
        return self:SetAccent(SaltyGlass.Themes[theme])
    end

    if type(theme) == "table" and typeof(theme.Accent) == "Color3" then
        return self:SetAccent(theme.Accent)
    end

    return false
end

function WindowMethods:SetReduceMotion(enabled)
    self._reduceMotion = enabled == true
    if self._backgroundBlur then
        self:_applyBackgroundBlur()
    end
    if self._music and not self._music._destroyed then
        self._music:_applyMotionState()
    end
    return self._reduceMotion
end

function WindowMethods:GetReduceMotion()
    return self._reduceMotion
end

function WindowMethods:_applyBackgroundBlur()
    if not self._backgroundBlur or not self._backgroundBlur.Parent then
        return
    end

    local target = 0
    if self._blurEnabled and not self._hidden and self._screen and self._screen.Enabled then
        target = self._blurSize
    end

    if self._reduceMotion then
        self._backgroundBlur.Size = target
    else
        self:_tween(self._backgroundBlur, 0.18, { Size = target })
    end
end

function WindowMethods:SetBlurEnabled(enabled)
    self._blurEnabled = enabled ~= false
    self:_applyBackgroundBlur()
    return self._blurEnabled
end

WindowMethods.SetBackgroundBlur = WindowMethods.SetBlurEnabled

function WindowMethods:GetBlurEnabled()
    return self._blurEnabled
end

function WindowMethods:SetBlurSize(size)
    self._blurSize = math.clamp(tonumber(size) or self._blurSize or 16, 0, 56)
    self:_applyBackgroundBlur()
    return self._blurSize
end

function WindowMethods:SetTitle(title, subtitle)
    if title ~= nil then
        self._title.Text = tostring(title)
    end
    if subtitle ~= nil then
        self._subtitle.Text = tostring(subtitle)
        self._subtitle.Visible = tostring(subtitle) ~= ""
    end
end

function WindowMethods:SetToggleKey(keyCode)
    if typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode then
        self._toggleKey = keyCode
        return true
    end
    return false
end

function WindowMethods:GetToggleKey()
    return self._toggleKey
end

function WindowMethods:Show()
    if self._destroyed then
        return
    end
    self._screen.Enabled = true
    self._hidden = false
    self:_applyBackgroundBlur()
end

function WindowMethods:Hide()
    if self._destroyed then
        return
    end
    self._hidden = true
    if self._backgroundBlur then
        if self._reduceMotion then
            self._backgroundBlur.Size = 0
        else
            self:_tween(self._backgroundBlur, 0.14, { Size = 0 })
        end
    end
    if self._music and not self._music._destroyed then
        self._music:Close()
    end
    self._screen.Enabled = false
end

function WindowMethods:Toggle()
    if self._screen.Enabled then
        self:Hide()
    else
        self:Show()
    end
end

function WindowMethods:Minimize()
    if self._destroyed or self._minimized then
        return
    end

    self._minimized = true
    self:ShowStatus({ Title = "MINIMIZED", Subtitle = "Click badge to restore", Icon = "minus", Duration = 1.1 })
    self._badge.Position = self._main.Position
    self._badge.Visible = true

    if self._reduceMotion then
        self._main.Visible = false
        self._badgeScale.Scale = 1
    else
        self:_tween(self._mainScale, 0.12, { Scale = 0.96 })
        task.delay(0.12, function()
            if not self._destroyed and self._minimized then
                self._main.Visible = false
                self._mainScale.Scale = 1
            end
        end)
        self._badgeScale.Scale = 0.94
        self:_tween(self._badgeScale, 0.16, { Scale = 1 })
    end
end

function WindowMethods:Restore()
    if self._destroyed or not self._minimized then
        return
    end

    self._minimized = false
    self._main.Visible = true
    self:ShowStatus({ Title = "RESTORED", Subtitle = "SaltyGlass is ready", Icon = "home", Duration = 1.0 })
    self._badge.Visible = false

    if self._reduceMotion then
        self._mainScale.Scale = 1
    else
        self._mainScale.Scale = 0.97
        self:_tween(self._mainScale, 0.16, { Scale = 1 })
    end
end

function WindowMethods:IsMinimized()
    return self._minimized
end

function WindowMethods:Notify(options)
    if self._destroyed then
        return nil
    end

    if type(options) == "string" then
        options = { Message = options }
    end
    options = options or {}

    local toast = make("Frame", {
        Size = UDim2.fromOffset(300, options.Description and 78 or 68),
        BackgroundColor3 = COLORS.GlassBase,
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        Parent = self._notifications,
    })
    round(toast, 14)
    stroke(toast, 1, 0.58)

    local line = make("Frame", {
        Position = UDim2.new(0, 12, 1, -5),
        Size = UDim2.new(1, -24, 0, 2),
        BackgroundColor3 = options.Color or self._accent,
        BorderSizePixel = 0,
        Parent = toast,
    })
    round(line, 2)
    if not options.Color then
        self:_bindAccent(line)
    end

    local title = textLabel(toast, tostring(options.Title or self._options.Title or "SaltyGlass"), 11, COLORS.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(14, 8)
    title.Size = UDim2.new(1, -28, 0, 20)

    local message = textLabel(toast, tostring(options.Message or options.Description or ""), 10, COLORS.SubText, Enum.Font.Gotham)
    message.Position = UDim2.fromOffset(14, 28)
    message.Size = UDim2.new(1, -28, 0, 28)
    message.TextWrapped = true
    message.TextYAlignment = Enum.TextYAlignment.Top

    local toastScale = make("UIScale", { Scale = 1, Parent = toast })
    if not self._reduceMotion then
        toastScale.Scale = 0.96
        toast.BackgroundTransparency = 1
        self:_tween(toastScale, 0.14, { Scale = 1 })
        self:_tween(toast, 0.14, { BackgroundTransparency = 0.10 })
    end

    local duration = tonumber(options.Duration) or 3
    task.delay(math.max(0.2, duration), function()
        if self._destroyed or not toast.Parent then
            return
        end

        if self._reduceMotion then
            toast:Destroy()
        else
            self:_tween(toast, 0.12, { BackgroundTransparency = 1 })
            self:_tween(toastScale, 0.12, { Scale = 0.97 })
            task.delay(0.13, function()
                if toast.Parent then
                    toast:Destroy()
                end
            end)
        end
    end)

    return toast
end

function WindowMethods:ResetLayout()
    if self._destroyed then
        return
    end

    self:SetAccent(self._defaultAccent)
    self:SetReduceMotion(self._defaultReduceMotion)
    self:SetBlurEnabled(self._defaultBlurEnabled)
    self:SetToggleKey(self._defaultToggleKey)
    self._main.Size = self._defaultSize
    self._main.Position = UDim2.fromScale(0.5, 0.5)
    self._mainScale.Scale = 1
    self:Show()
    if self._minimized then
        self:Restore()
    end
    if self._tabs[1] then
        self:SelectTab(self._tabs[1])
    end
end

WindowMethods.Reset = WindowMethods.ResetLayout

function WindowMethods:GetScreenGui()
    return self._screen
end

function WindowMethods:GetMainFrame()
    return self._main
end

function WindowMethods:SetSize(size)
    if self._destroyed then
        return false
    end
    local normalized = normalizeSize(size, nil)
    if not normalized then
        return false
    end
    self._main.Size = normalized
    return true
end

function WindowMethods:GetSize()
    return self._main.Size
end

function WindowMethods:SetPosition(position)
    if self._destroyed then
        return false
    end
    self._main.Position = normalizePosition(position)
    return true
end

function WindowMethods:GetPosition()
    return self._main.Position
end

function WindowMethods:SetWindowTransparency(value)
    if self._destroyed then
        return 0
    end
    local transparency = math.clamp(tonumber(value) or self._main.BackgroundTransparency, 0, 0.95)
    self._main.BackgroundTransparency = transparency
    return transparency
end

function WindowMethods:GetColors()
    local colors = copyTable(COLORS)
    colors.Accent = self._accent
    return colors
end

function WindowMethods:GetIconAsset(name)
    return SaltyGlass.Icons[name]
end

function WindowMethods:Destroy()
    if self._destroyed then
        return
    end

    if self._music and not self._music._destroyed then
        self._music:Destroy()
    end

    self._destroyed = true
    for _, connection in ipairs(self._connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self._connections)

    if self._backgroundBlur and self._backgroundBlur.Parent then
        self._backgroundBlur:Destroy()
    end

    if self._screen and self._screen.Parent then
        self._screen:Destroy()
    end
end


local function setBarRatio(fill, thumb, ratio)
    local clamped = math.clamp(tonumber(ratio) or 0, 0, 1)
    if fill then
        fill.Size = UDim2.new(clamped, 0, 1, 0)
    end
    if thumb then
        thumb.Position = UDim2.new(clamped, 0, 0.5, 0)
    end
end

function MusicMethods:_refreshVisuals()
    if self._destroyed then
        return
    end

    local ui = self._ui
    local state = self._state
    local accent = self._window._accent
    local playing = self._sound and self._sound.IsPlaying

    if ui.topIcon then
        ui.topIcon.ImageColor3 = playing and accent or COLORS.SubText
    end
    if ui.playIcon then
        ui.playIcon.Image = SaltyGlass.Icons[playing and "pause" or "play"]
        ui.playIcon.ImageColor3 = playing and accent or COLORS.Text
    end
    if ui.repeatIcon then
        ui.repeatIcon.ImageColor3 = state.repeatMode > 0 and accent or COLORS.SubText
    end
    if ui.repeatOne then
        ui.repeatOne.Visible = state.repeatMode == 2
        ui.repeatOne.BackgroundColor3 = accent
    end
    if ui.speedValue then
        ui.speedValue.Text = string.format("%.2fx", state.speed)
    end
    if ui.volumeValue then
        ui.volumeValue.Text = string.format("%d%%", math.floor(state.volume * 100 + 0.5))
    end
    if ui.idBox and state.audioId then
        ui.idBox.Text = tostring(state.audioId)
    end
end

function MusicMethods:_applyMotionState()
    if self._destroyed then
        return
    end

    if self._window._reduceMotion and self._ui.panelScale then
        self._ui.panelScale.Scale = 1
    end
end

function MusicMethods:SetAudioId(value, autoplay)
    if self._destroyed then
        return false
    end

    local audioId = normalizeAudioId(value)
    if not audioId then
        self._window:ShowStatus({
            Title = "AUDIO ERROR",
            Subtitle = "Enter a valid Roblox audio ID",
            Icon = "music",
            Color = COLORS.Danger,
            Duration = 1.7,
        })
        return false
    end

    self._state.audioId = audioId
    self._sound:Stop()
    self._sound.TimePosition = 0
    self._sound.SoundId = "rbxassetid://" .. audioId

    if self._ui.idBox then
        self._ui.idBox.Text = audioId
    end
    if self._ui.nowPlaying then
        self._ui.nowPlaying.Text = "CUSTOM AUDIO • " .. audioId
    end

    self._window:ShowStatus({
        Title = "AUDIO LOADED",
        Subtitle = audioId,
        Icon = "music",
        Duration = 1.2,
    })

    if autoplay then
        task.defer(function()
            if not self._destroyed then
                self:Play()
            end
        end)
    end

    return true
end

function MusicMethods:GetAudioId()
    return self._state.audioId
end

function MusicMethods:Play()
    if self._destroyed then
        return false
    end

    if self._sound.SoundId == "" then
        local value = self._ui.idBox and self._ui.idBox.Text or ""
        if not self:SetAudioId(value, false) then
            return false
        end
    end

    self._sound.PlaybackSpeed = self._state.speed
    self._sound.Volume = self._state.volume
    self._sound.Looped = self._state.repeatMode > 0
    self._sound:Play()
    self:_refreshVisuals()

    self._window:ShowStatus({
        Title = "NOW PLAYING",
        Subtitle = self._state.audioId and ("Audio " .. self._state.audioId) or "Custom audio",
        Icon = "music",
        Duration = 1.25,
    })
    return true
end

function MusicMethods:Pause()
    if self._destroyed then
        return
    end
    self._sound:Pause()
    self:_refreshVisuals()
    self._window:ShowStatus({
        Title = "PAUSED",
        Subtitle = "Custom audio",
        Icon = "pause",
        Duration = 1.0,
    })
end

function MusicMethods:Stop()
    if self._destroyed then
        return
    end
    self._sound:Stop()
    self._sound.TimePosition = 0
    self:_refreshVisuals()
    self._window:ShowStatus({
        Title = "STOPPED",
        Subtitle = "Playback reset",
        Icon = "square",
        Duration = 1.0,
    })
end

function MusicMethods:SetVolume(value)
    if self._destroyed then
        return 0
    end
    self._state.volume = math.clamp(tonumber(value) or self._state.volume, 0, 1)
    self._sound.Volume = self._state.volume
    setBarRatio(self._ui.volumeFill, self._ui.volumeThumb, self._state.volume)
    self:_refreshVisuals()
    return self._state.volume
end

function MusicMethods:GetVolume()
    return self._state.volume
end

function MusicMethods:SetSpeed(value, silent)
    if self._destroyed then
        return 1
    end
    self._state.speed = math.clamp(tonumber(value) or self._state.speed, 0.5, 2)
    self._state.speed = math.floor(self._state.speed * 100 + 0.5) / 100
    self._sound.PlaybackSpeed = self._state.speed
    self:_refreshVisuals()
    if not silent then
        self._window:ShowStatus({
            Title = "PLAYBACK SPEED",
            Subtitle = string.format("%.2fx", self._state.speed),
            Icon = "play",
            Duration = 0.85,
        })
    end
    return self._state.speed
end

function MusicMethods:GetSpeed()
    return self._state.speed
end

function MusicMethods:SetRepeatMode(mode, silent)
    if self._destroyed then
        return 0
    end

    local value = mode
    if type(mode) == "string" then
        local lowered = string.lower(mode)
        if lowered == "off" then
            value = 0
        elseif lowered == "one" or lowered == "repeat1" or lowered == "repeat 1" then
            value = 2
        else
            value = 1
        end
    end

    self._state.repeatMode = math.clamp(math.floor(tonumber(value) or 0), 0, 2)
    self._sound.Looped = self._state.repeatMode > 0
    self:_refreshVisuals()

    local labels = {
        [0] = "Repeat off",
        [1] = "Repeat",
        [2] = "Repeat 1",
    }
    if not silent then
        self._window:ShowStatus({
            Title = string.upper(labels[self._state.repeatMode]),
            Subtitle = self._state.repeatMode == 0 and "Looping disabled" or "Looping enabled",
            Icon = "repeat-2",
            Duration = 0.9,
        })
    end
    return self._state.repeatMode
end

function MusicMethods:GetRepeatMode()
    return self._state.repeatMode
end

function MusicMethods:Open()
    if self._destroyed or self._open then
        return
    end
    self._open = true
    self._ui.backdrop.Visible = true
    self._ui.panel.Visible = true

    if self._window._reduceMotion then
        self._ui.backdrop.BackgroundTransparency = 0.28
        self._ui.panelScale.Scale = 1
        self._musicBlur.Size = self._options.MusicBlurSize
    else
        self._ui.backdrop.BackgroundTransparency = 1
        self._ui.panelScale.Scale = 0.965
        self._window:_tween(self._ui.backdrop, 0.16, { BackgroundTransparency = 0.28 })
        self._window:_tween(self._ui.panelScale, 0.18, { Scale = 1 })
        self._window:_tween(self._musicBlur, 0.18, { Size = self._options.MusicBlurSize })
    end

    self._window:ShowStatus({
        Title = "MUSIC PLAYER",
        Subtitle = "Custom Roblox audio",
        Icon = "music",
        Duration = 1.0,
    })
end

function MusicMethods:Close()
    if self._destroyed or not self._open then
        return
    end
    self._open = false

    if self._window._reduceMotion then
        self._musicBlur.Size = 0
        self._ui.backdrop.Visible = false
        self._ui.panel.Visible = false
        self._ui.backdrop.BackgroundTransparency = 1
        self._ui.panelScale.Scale = 1
    else
        self._window:_tween(self._musicBlur, 0.15, { Size = 0 })
        self._window:_tween(self._ui.backdrop, 0.13, { BackgroundTransparency = 1 })
        self._window:_tween(self._ui.panelScale, 0.13, { Scale = 0.97 })
        task.delay(0.14, function()
            if not self._destroyed and not self._open then
                self._ui.backdrop.Visible = false
                self._ui.panel.Visible = false
                self._ui.panelScale.Scale = 1
            end
        end)
    end
end

function MusicMethods:Toggle()
    if self._open then
        self:Close()
    else
        self:Open()
    end
end

function MusicMethods:IsOpen()
    return self._open
end

function MusicMethods:GetSound()
    return self._sound
end

function MusicMethods:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self._open = false

    if self._sound and self._sound.Parent then
        self._sound:Stop()
        self._sound:Destroy()
    end
    if self._musicBlur and self._musicBlur.Parent then
        self._musicBlur:Destroy()
    end
    if self._ui and self._ui.backdrop and self._ui.backdrop.Parent then
        self._ui.backdrop:Destroy()
    end
    if self._ui and self._ui.topButton and self._ui.topButton.Parent then
        self._ui.topButton:Destroy()
    end
    if self._window and self._window._music == self then
        self._window._music = nil
    end
end

function WindowMethods:AddMusicPlayer(options)
    if self._destroyed then
        return nil
    end
    if self._music and not self._music._destroyed then
        return self._music
    end

    options = merge({
        Title = "Custom Audio",
        Subtitle = "ROBLOX AUDIO ID",
        Volume = 0.55,
        Speed = 1,
        RepeatMode = 0,
        MusicBlurSize = 30,
        Hotkey = Enum.KeyCode.M,
        RequireControl = true,
    }, options or {})

    local music = setmetatable({
        _window = self,
        _options = options,
        _ui = {},
        _state = {
            audioId = nil,
            volume = math.clamp(tonumber(options.Volume) or 0.55, 0, 1),
            speed = math.clamp(tonumber(options.Speed) or 1, 0.5, 2),
            repeatMode = math.clamp(math.floor(tonumber(options.RepeatMode) or 0), 0, 2),
            draggingProgress = false,
            draggingVolume = false,
        },
        _destroyed = false,
        _open = false,
    }, MusicMethods)
    self._music = music

    local ui = music._ui
    local state = music._state
    local screen = self._screen
    local topbar = self._topbar

    local blurName = tostring(self._options.Name) .. "_MusicBlur"
    local oldBlur = Lighting:FindFirstChild(blurName)
    if oldBlur then
        oldBlur:Destroy()
    end
    music._musicBlur = make("BlurEffect", {
        Name = blurName,
        Size = 0,
        Parent = Lighting,
    })

    music._sound = make("Sound", {
        Name = tostring(self._options.Name) .. "_Music",
        Volume = state.volume,
        PlaybackSpeed = state.speed,
        Looped = state.repeatMode > 0,
        Parent = SoundService,
    })

    ui.topButton = make("TextButton", {
        Name = "MusicButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -91, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 6,
        Parent = topbar,
    })
    ui.topIcon = icon(ui.topButton, "music", 15, COLORS.SubText, 7)
    ui.topIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.topIcon.Position = UDim2.fromScale(0.5, 0.5)

    if self._contextFrame then
        self._contextRightOffset = 130
        self._contextFrame.Position = UDim2.new(1, -130, 0.5, 0)
    end

    ui.backdrop = make("TextButton", {
        Name = "MusicBackdropInputSink",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 200,
        Parent = screen,
    })

    ui.panel = make("Frame", {
        Name = "MusicPalette",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(500, 352),
        BackgroundColor3 = COLORS.GlassBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 210,
        Parent = screen,
    })
    round(ui.panel, 24)
    stroke(ui.panel, 1.4, 0.42)
    ui.panelScale = make("UIScale", { Scale = 1, Parent = ui.panel })

    ui.panelGradient = make("UIGradient", {
        Rotation = 52,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 50, 80)),
            ColorSequenceKeypoint.new(0.42, COLORS.GlassMid),
            ColorSequenceKeypoint.new(1, COLORS.GlassBase),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.52, 0.52),
            NumberSequenceKeypoint.new(1, 0.80),
        }),
        Parent = ui.panel,
    })

    task.spawn(function()
        while not music._destroyed and ui.panelGradient.Parent do
            if self._reduceMotion then
                ui.panelGradient.Rotation = 52
                task.wait(0.25)
            else
                self:_tween(ui.panelGradient, 6.5, { Rotation = 70 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(6.5)
                if not music._destroyed and ui.panelGradient.Parent and not self._reduceMotion then
                    self:_tween(ui.panelGradient, 6.5, { Rotation = 36 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(6.5)
                end
            end
        end
    end)

    ui.inputShield = make("TextButton", {
        Name = "PaletteInputShield",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 211,
        Parent = ui.panel,
    })

    ui.headerIcon = icon(ui.panel, "music", 18, self._accent, 214)
    ui.headerIcon.Position = UDim2.fromOffset(20, 18)
    self:_bindAccent(ui.headerIcon, "ImageColor3")

    ui.title = textLabel(ui.panel, tostring(options.Title), 14, COLORS.Text, Enum.Font.GothamBold)
    ui.title.Position = UDim2.fromOffset(50, 13)
    ui.title.Size = UDim2.new(1, -110, 0, 24)
    ui.title.ZIndex = 214

    ui.subtitle = textLabel(ui.panel, tostring(options.Subtitle), 8, COLORS.SubText, Enum.Font.GothamBold)
    ui.subtitle.Position = UDim2.fromOffset(51, 35)
    ui.subtitle.Size = UDim2.new(1, -112, 0, 16)
    ui.subtitle.ZIndex = 214

    ui.close = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -18, 0, 31),
        Size = UDim2.fromOffset(30, 30),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    ui.closeIcon = icon(ui.close, "x", 14, COLORS.SubText, 217)
    ui.closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.closeIcon.Position = UDim2.fromScale(0.5, 0.5)

    ui.headerLine = make("Frame", {
        Position = UDim2.fromOffset(18, 61),
        Size = UDim2.new(1, -36, 0, 1),
        BackgroundColor3 = COLORS.Edge,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 213,
        Parent = ui.panel,
    })

    ui.idHolder = make("Frame", {
        Position = UDim2.fromOffset(18, 78),
        Size = UDim2.new(1, -134, 0, 38),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        ZIndex = 213,
        Parent = ui.panel,
    })
    round(ui.idHolder, 10)
    stroke(ui.idHolder, 1, 0.76)

    ui.idBox = make("TextBox", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Paste Roblox audio ID...",
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 216,
        Parent = ui.idHolder,
    })

    ui.loadButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 78),
        Size = UDim2.fromOffset(104, 38),
        BackgroundColor3 = self._accent,
        BackgroundTransparency = 0.70,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "LOAD + PLAY",
        TextColor3 = COLORS.Text,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.loadButton, 10)
    stroke(ui.loadButton, 1, 0.60)
    self:_bindAccent(ui.loadButton)

    ui.nowPlaying = textLabel(ui.panel, "CUSTOM AUDIO • READY", 8, COLORS.SubText, Enum.Font.GothamBold)
    ui.nowPlaying.Position = UDim2.fromOffset(20, 126)
    ui.nowPlaying.Size = UDim2.new(1, -40, 0, 17)
    ui.nowPlaying.ZIndex = 214

    ui.play = make("TextButton", {
        Position = UDim2.fromOffset(20, 151),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = self._accent,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.play, 12)
    stroke(ui.play, 1, 0.62)
    self:_bindAccent(ui.play)
    ui.playIcon = icon(ui.play, "play", 16, COLORS.Text, 217)
    ui.playIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.playIcon.Position = UDim2.fromScale(0.5, 0.5)

    ui.stop = make("TextButton", {
        Position = UDim2.fromOffset(68, 151),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.stop, 12)
    stroke(ui.stop, 1, 0.70)
    ui.stopIcon = icon(ui.stop, "square", 14, COLORS.SubText, 217)
    ui.stopIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.stopIcon.Position = UDim2.fromScale(0.5, 0.5)

    ui.repeatButton = make("TextButton", {
        Position = UDim2.fromOffset(116, 151),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.repeatButton, 12)
    stroke(ui.repeatButton, 1, 0.70)
    ui.repeatIcon = icon(ui.repeatButton, "repeat-2", 15, COLORS.SubText, 217)
    ui.repeatIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ui.repeatIcon.Position = UDim2.fromScale(0.5, 0.5)

    ui.repeatOne = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 1, 0, -2),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = self._accent,
        BorderSizePixel = 0,
        Text = "1",
        TextColor3 = COLORS.Text,
        TextSize = 7,
        Font = Enum.Font.GothamBold,
        Visible = false,
        ZIndex = 218,
        Parent = ui.repeatButton,
    })
    round(ui.repeatOne, 7)
    self:_bindAccent(ui.repeatOne)

    ui.currentTime = textLabel(ui.panel, "0:00", 8, COLORS.SubText, Enum.Font.GothamBold)
    ui.currentTime.Position = UDim2.fromOffset(174, 151)
    ui.currentTime.Size = UDim2.fromOffset(38, 20)
    ui.currentTime.ZIndex = 214

    ui.totalTime = textLabel(ui.panel, "0:00", 8, COLORS.SubText, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    ui.totalTime.AnchorPoint = Vector2.new(1, 0)
    ui.totalTime.Position = UDim2.new(1, -20, 0, 151)
    ui.totalTime.Size = UDim2.fromOffset(44, 20)
    ui.totalTime.ZIndex = 214

    ui.progress = make("TextButton", {
        Position = UDim2.fromOffset(174, 177),
        Size = UDim2.new(1, -194, 0, 6),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.46,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.progress, 3)

    ui.progressFill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self._accent,
        BorderSizePixel = 0,
        ZIndex = 217,
        Parent = ui.progress,
    })
    round(ui.progressFill, 3)
    self:_bindAccent(ui.progressFill)

    ui.progressThumb = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
        ZIndex = 218,
        Parent = ui.progress,
    })
    round(ui.progressThumb, 5)

    ui.volumeIcon = icon(ui.panel, "volume-2", 14, COLORS.SubText, 214)
    ui.volumeIcon.Position = UDim2.fromOffset(20, 214)

    ui.volume = make("TextButton", {
        Position = UDim2.fromOffset(46, 219),
        Size = UDim2.fromOffset(180, 6),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.46,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.volume, 3)

    ui.volumeFill = make("Frame", {
        Size = UDim2.new(state.volume, 0, 1, 0),
        BackgroundColor3 = self._accent,
        BorderSizePixel = 0,
        ZIndex = 217,
        Parent = ui.volume,
    })
    round(ui.volumeFill, 3)
    self:_bindAccent(ui.volumeFill)

    ui.volumeThumb = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(state.volume, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
        ZIndex = 218,
        Parent = ui.volume,
    })
    round(ui.volumeThumb, 6)

    ui.volumeValue = textLabel(ui.panel, "", 8, COLORS.SubText, Enum.Font.GothamBold)
    ui.volumeValue.Position = UDim2.fromOffset(238, 209)
    ui.volumeValue.Size = UDim2.fromOffset(44, 24)
    ui.volumeValue.ZIndex = 214

    ui.speedLabel = textLabel(ui.panel, "PLAYBACK SPEED", 8, COLORS.SubText, Enum.Font.GothamBold)
    ui.speedLabel.Position = UDim2.fromOffset(20, 251)
    ui.speedLabel.Size = UDim2.fromOffset(120, 18)
    ui.speedLabel.ZIndex = 214

    ui.speedMinus = make("TextButton", {
        Position = UDim2.fromOffset(20, 277),
        Size = UDim2.fromOffset(34, 30),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "−",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.speedMinus, 9)
    stroke(ui.speedMinus, 1, 0.72)

    ui.speedValue = make("TextButton", {
        Position = UDim2.fromOffset(62, 277),
        Size = UDim2.fromOffset(70, 30),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "1.00x",
        TextColor3 = COLORS.Text,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.speedValue, 9)
    stroke(ui.speedValue, 1, 0.72)

    ui.speedPlus = make("TextButton", {
        Position = UDim2.fromOffset(140, 277),
        Size = UDim2.fromOffset(34, 30),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "+",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 216,
        Parent = ui.panel,
    })
    round(ui.speedPlus, 9)
    stroke(ui.speedPlus, 1, 0.72)

    ui.help = textLabel(ui.panel, "Only use Roblox audio assets you have permission to play.", 8, COLORS.Muted, Enum.Font.Gotham)
    ui.help.AnchorPoint = Vector2.new(1, 0)
    ui.help.Position = UDim2.new(1, -20, 0, 262)
    ui.help.Size = UDim2.fromOffset(250, 48)
    ui.help.TextWrapped = true
    ui.help.TextXAlignment = Enum.TextXAlignment.Right
    ui.help.ZIndex = 214

    local function ratioFromInput(bar, input)
        local width = math.max(1, bar.AbsoluteSize.X)
        return math.clamp((input.Position.X - bar.AbsolutePosition.X) / width, 0, 1)
    end

    local function updateProgressFromInput(input)
        local length = music._sound.TimeLength
        if length > 0 then
            local ratio = ratioFromInput(ui.progress, input)
            music._sound.TimePosition = math.clamp(length * ratio, 0, math.max(0, length - 0.01))
            setBarRatio(ui.progressFill, ui.progressThumb, ratio)
        end
    end

    local function updateVolumeFromInput(input)
        music:SetVolume(ratioFromInput(ui.volume, input))
    end

    self:_connect(ui.topButton.MouseButton1Click, function()
        music:Toggle()
    end)
    self:_connect(ui.topButton.MouseEnter, function()
        if not music._sound.IsPlaying then
            self:_tween(ui.topIcon, 0.10, { ImageColor3 = self._accent })
        end
    end)
    self:_connect(ui.topButton.MouseLeave, function()
        music:_refreshVisuals()
    end)
    self:_connect(ui.close.MouseButton1Click, function()
        music:Close()
    end)
    self:_connect(ui.close.MouseEnter, function()
        self:_tween(ui.closeIcon, 0.10, { ImageColor3 = COLORS.Danger })
    end)
    self:_connect(ui.close.MouseLeave, function()
        self:_tween(ui.closeIcon, 0.10, { ImageColor3 = COLORS.SubText })
    end)

    self:_connect(ui.loadButton.MouseButton1Click, function()
        music:SetAudioId(ui.idBox.Text, true)
    end)
    self:_connect(ui.idBox.FocusLost, function(enterPressed)
        if enterPressed then
            music:SetAudioId(ui.idBox.Text, true)
        end
    end)

    self:_connect(ui.play.MouseButton1Click, function()
        if music._sound.IsPlaying then
            music:Pause()
        else
            music:Play()
        end
    end)
    self:_connect(ui.stop.MouseButton1Click, function()
        music:Stop()
    end)
    self:_connect(ui.repeatButton.MouseButton1Click, function()
        music:SetRepeatMode((state.repeatMode + 1) % 3)
    end)

    self:_connect(ui.speedMinus.MouseButton1Click, function()
        music:SetSpeed(state.speed - 0.10)
    end)
    self:_connect(ui.speedPlus.MouseButton1Click, function()
        music:SetSpeed(state.speed + 0.10)
    end)
    self:_connect(ui.speedValue.MouseButton1Click, function()
        music:SetSpeed(1)
    end)

    self:_connect(ui.progress.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state.draggingProgress = true
            updateProgressFromInput(input)
        end
    end)

    self:_connect(ui.volume.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state.draggingVolume = true
            updateVolumeFromInput(input)
        end
    end)

    self:_connect(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if state.draggingProgress then
                updateProgressFromInput(input)
            end
            if state.draggingVolume then
                updateVolumeFromInput(input)
            end
        end
    end)

    self:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state.draggingProgress = false
            state.draggingVolume = false
        end
    end)

    self:_connect(music._sound.Played, function()
        music:_refreshVisuals()
    end)
    self:_connect(music._sound.Paused, function()
        music:_refreshVisuals()
    end)
    self:_connect(music._sound.Ended, function()
        music:_refreshVisuals()
        if state.repeatMode == 0 then
            setBarRatio(ui.progressFill, ui.progressThumb, 0)
        end
    end)

    self:_connect(RunService.RenderStepped, function()
        if music._destroyed then
            return
        end

        local length = music._sound.TimeLength
        local position = music._sound.TimePosition
        ui.currentTime.Text = formatClock(position)
        ui.totalTime.Text = formatClock(length)

        if not state.draggingProgress and length > 0 then
            setBarRatio(ui.progressFill, ui.progressThumb, position / length)
        elseif not state.draggingProgress then
            setBarRatio(ui.progressFill, ui.progressThumb, 0)
        end
    end)

    self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if input.KeyCode == options.Hotkey then
            local controlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

            if options.RequireControl == false or controlDown then
                music:Toggle()
            end
        end
    end)

    music:SetVolume(state.volume)
    music:SetSpeed(state.speed, true)
    music:SetRepeatMode(state.repeatMode, true)
    music:_refreshVisuals()
    return music
end

WindowMethods.CreateMusicPlayer = WindowMethods.AddMusicPlayer

function WindowMethods:GetMusicPlayer()
    return self._music
end

local function buildTitleBlock(window, card, options, rightInset)
    local title = textLabel(card, tostring(options.Name or options.Title or "Control"), 11, COLORS.Text, Enum.Font.GothamMedium)
    title.Position = UDim2.fromOffset(14, options.Description and 8 or 0)
    title.Size = UDim2.new(1, -(rightInset or 28), options.Description and 0 or 1, options.Description and 22 or 0)

    local description = textLabel(card, tostring(options.Description or ""), 9, COLORS.SubText, Enum.Font.Gotham)
    description.Position = UDim2.fromOffset(14, 29)
    description.Size = UDim2.new(1, -(rightInset or 28), 0, 18)
    description.Visible = tostring(options.Description or "") ~= ""

    return title, description
end

local function newControl(tab, kind, root, state)
    local control = setmetatable({
        Type = kind,
        Root = root,
        _tab = tab,
        _window = tab._window,
        _state = state or {},
    }, ControlMethods)
    table.insert(tab._controls, control)
    return control
end

function ControlMethods:SetVisible(visible)
    if self.Root then
        self.Root.Visible = visible ~= false
    end
    return self
end

function ControlMethods:SetLayoutOrder(order)
    if self.Root and tonumber(order) then
        self.Root.LayoutOrder = tonumber(order)
    end
    return self
end

function ControlMethods:Destroy()
    if self.Root and self.Root.Parent then
        self.Root:Destroy()
    end
end

function TabMethods:AddSection(titleOrOptions)
    local options = type(titleOrOptions) == "table" and titleOrOptions or { Name = titleOrOptions }
    local root = make("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self._page,
    })

    local name = string.upper(tostring(options.Name or options.Title or "SECTION"))
    local title = textLabel(root, name, 9, COLORS.SubText, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(2, 2)
    title.Size = UDim2.new(1, -4, 0, 16)

    local width = TextService:GetTextSize(name, 9, Enum.Font.GothamBold, Vector2.new(1000, 20)).X
    local underline = make("Frame", {
        Position = UDim2.fromOffset(2, 23),
        Size = UDim2.fromOffset(math.max(14, width), 1),
        BackgroundColor3 = self._window._accent,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
        Parent = root,
    })
    self._window:_bindAccent(underline)

    local control = newControl(self, "Section", root, {})
    control.TitleLabel = title
    function control:SetText(value)
        local text = string.upper(tostring(value or ""))
        self.TitleLabel.Text = text
        local measured = TextService:GetTextSize(text, 9, Enum.Font.GothamBold, Vector2.new(1000, 20)).X
        underline.Size = UDim2.fromOffset(math.max(14, measured), 1)
        return self
    end
    return control
end

function TabMethods:AddLabel(options)
    if type(options) == "string" then
        options = { Name = options }
    end
    options = options or {}

    local height = options.Description and 64 or 48
    local card = self._window:_newCard(self._page, height)
    local title, description = buildTitleBlock(self._window, card, options, 26)

    if options.Icon and SaltyGlass.Icons[options.Icon] then
        title.Position = UDim2.fromOffset(40, options.Description and 8 or 0)
        title.Size = UDim2.new(1, -54, options.Description and 0 or 1, options.Description and 22 or 0)
        description.Position = UDim2.fromOffset(40, 29)
        description.Size = UDim2.new(1, -54, 0, 18)
        local itemIcon = icon(card, options.Icon, 16, self._window._accent, 2)
        itemIcon.AnchorPoint = Vector2.new(0, 0.5)
        itemIcon.Position = UDim2.new(0, 14, 0.5, 0)
        self._window:_bindAccent(itemIcon, "ImageColor3")
    end

    local control = newControl(self, "Label", card, {})
    control.TitleLabel = title
    control.DescriptionLabel = description

    function control:SetText(name, desc)
        setTextPair(self.TitleLabel, self.DescriptionLabel, name, desc)
        return self
    end

    return control
end

TabMethods.AddParagraph = TabMethods.AddLabel

function TabMethods:AddDivider()
    local root = make("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self._page,
    })
    make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundColor3 = COLORS.Edge,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Parent = root,
    })
    return newControl(self, "Divider", root, {})
end

function TabMethods:AddButton(options)
    if type(options) == "string" then
        options = { Name = options }
    end
    options = options or {}

    local card = self._window:_newCard(self._page, options.Description and 64 or 52)
    local title, description = buildTitleBlock(self._window, card, options, 72)
    local button = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(options.ButtonWidth or 42, 30),
        BackgroundColor3 = self._window._accent,
        BackgroundTransparency = 0.76,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = card,
    })
    round(button, 9)
    stroke(button, 1, 0.68)
    self._window:_bindAccent(button)

    local buttonIcon = icon(button, options.Icon or "play", 14, COLORS.Text, 4)
    if buttonIcon then
        buttonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        buttonIcon.Position = UDim2.fromScale(0.5, 0.5)
    else
        local go = textLabel(button, "GO", 9, COLORS.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        go.Size = UDim2.fromScale(1, 1)
    end

    self._window:_hover(card, button)

    local control = newControl(self, "Button", card, {
        Disabled = options.Disabled == true,
        Callback = options.Callback,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Button = button

    self._window:_connect(button.MouseButton1Click, function()
        if control._state.Disabled then
            return
        end
        self._window:_tween(button, 0.07, { BackgroundTransparency = 0.52 })
        task.delay(0.08, function()
            if button.Parent then
                self._window:_tween(button, 0.10, { BackgroundTransparency = 0.76 })
            end
        end)
        safeCallback(control._state.Callback)
    end)

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    function control:SetDisabled(disabled)
        self._state.Disabled = disabled == true
        self.Root.BackgroundTransparency = self._state.Disabled and 0.55 or 0.34
        self.Button.Active = not self._state.Disabled
        return self
    end

    function control:SetText(name, desc)
        setTextPair(self.TitleLabel, self.DescriptionLabel, name, desc)
        return self
    end

    control:SetDisabled(control._state.Disabled)
    return control
end

function TabMethods:AddToggle(options)
    options = options or {}
    local card = self._window:_newCard(self._page, options.Description and 64 or 54)
    local title, description = buildTitleBlock(self._window, card, options, 76)

    local hitbox = make("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = card,
    })

    local track = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(track, 11)
    stroke(track, 1, 0.72)

    local dot = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = COLORS.Muted,
        BorderSizePixel = 0,
        Parent = track,
    })
    round(dot, 8)

    local control = newControl(self, "Toggle", card, {
        Value = options.Default == true,
        Callback = options.Callback,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Track = track
    control.Dot = dot

    function control:Set(value, silent)
        local enabled = value == true
        self._state.Value = enabled
        local x = enabled and 23 or 3
        local color = enabled and self._window._accent or COLORS.Muted
        local trackTransparency = enabled and 0.68 or 0.20

        self._window:_tween(self.Dot, 0.14, {
            Position = UDim2.new(0, x, 0.5, 0),
            BackgroundColor3 = color,
        })
        self._window:_tween(self.Track, 0.14, {
            BackgroundTransparency = trackTransparency,
        })

        if not silent then
            safeCallback(self._state.Callback, enabled)
        end
        return self
    end

    function control:Get()
        return self._state.Value
    end

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    function control:SetText(name, desc)
        setTextPair(self.TitleLabel, self.DescriptionLabel, name, desc)
        return self
    end

    self._window:_connect(hitbox.MouseButton1Click, function()
        control:Set(not control:Get())
    end)
    self._window:_hover(card, hitbox)
    control:Set(control._state.Value, true)
    return control
end

function TabMethods:AddSlider(options)
    options = options or {}
    local minValue = tonumber(options.Min) or 0
    local maxValue = tonumber(options.Max) or 100
    if maxValue <= minValue then
        maxValue = minValue + 1
    end
    local increment = math.max(tonumber(options.Increment) or 1, 0.0001)

    local card = self._window:_newCard(self._page, options.Description and 88 or 78)
    local title, description = buildTitleBlock(self._window, card, options, 74)

    local valueLabel = textLabel(card, "", 9, COLORS.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -14, 0, 9)
    valueLabel.Size = UDim2.fromOffset(64, 18)

    local rail = make("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -14),
        Size = UDim2.new(1, -28, 0, 4),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(rail, 2)

    local fill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self._window._accent,
        BorderSizePixel = 0,
        Parent = rail,
    })
    round(fill, 2)
    self._window:_bindAccent(fill)

    local thumb = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = COLORS.Edge,
        BorderSizePixel = 0,
        Parent = rail,
    })
    round(thumb, 5)
    stroke(thumb, 1, 0.56)

    local hitbox = make("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -6, 0.5, 0),
        Size = UDim2.new(1, 12, 0, 26),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = rail,
    })

    local control = newControl(self, "Slider", card, {
        Min = minValue,
        Max = maxValue,
        Increment = increment,
        Value = tonumber(options.Default) or minValue,
        Callback = options.Callback,
        Dragging = false,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.ValueLabel = valueLabel
    control.Fill = fill
    control.Thumb = thumb
    control.Rail = rail

    local function snap(value)
        local steps = math.floor(((value - minValue) / increment) + 0.5)
        local snapped = minValue + (steps * increment)
        return math.clamp(snapped, minValue, maxValue)
    end

    function control:Set(value, silent)
        local numeric = snap(tonumber(value) or minValue)
        self._state.Value = numeric
        local alpha = (numeric - minValue) / (maxValue - minValue)
        self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
        self.Thumb.Position = UDim2.new(alpha, 0, 0.5, 0)

        local decimals = 0
        if increment < 1 then
            local scaled = increment
            while decimals < 4 and math.abs(scaled - math.floor(scaled + 0.5)) > 0.000001 do
                scaled = scaled * 10
                decimals = decimals + 1
            end
        end
        if decimals > 0 then
            self.ValueLabel.Text = string.format("%." .. tostring(decimals) .. "f", numeric)
        else
            self.ValueLabel.Text = tostring(math.floor(numeric + 0.5))
        end

        if not silent then
            safeCallback(self._state.Callback, numeric)
        end
        return self
    end

    function control:Get()
        return self._state.Value
    end

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    local function updateFromX(x)
        local width = math.max(1, rail.AbsoluteSize.X)
        local alpha = math.clamp((x - rail.AbsolutePosition.X) / width, 0, 1)
        control:Set(minValue + ((maxValue - minValue) * alpha))
    end

    self._window:_connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            control._state.Dragging = true
            updateFromX(input.Position.X)
        end
    end)

    self._window:_connect(UserInputService.InputChanged, function(input)
        if control._state.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    self._window:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            control._state.Dragging = false
        end
    end)

    control:Set(control._state.Value, true)
    return control
end

function TabMethods:AddDropdown(options)
    options = options or {}
    local values = options.Options or options.Values or {}
    local baseHeight = options.Description and 66 or 56

    local root = make("Frame", {
        Size = UDim2.new(1, 0, 0, baseHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self._page,
    })

    local card = self._window:_newCard(root, baseHeight)
    card.Size = UDim2.new(1, 0, 0, baseHeight)

    local title, description = buildTitleBlock(self._window, card, options, 180)

    local chooser = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(154, 32),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.34,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = card,
    })
    round(chooser, 9)
    stroke(chooser, 1, 0.70)

    local selectedLabel = textLabel(chooser, "", 9, COLORS.Text, Enum.Font.GothamMedium)
    selectedLabel.Position = UDim2.fromOffset(10, 0)
    selectedLabel.Size = UDim2.new(1, -34, 1, 0)
    selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local arrow = icon(chooser, "chevron-down", 13, COLORS.SubText, 4)
    if arrow then
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -9, 0.5, 0)
    end

    local optionsHolder = make("Frame", {
        Position = UDim2.new(0, 0, 0, baseHeight + 6),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = COLORS.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        Parent = root,
    })
    round(optionsHolder, 12)
    stroke(optionsHolder, 1, 0.82)
    padding(optionsHolder, 6, 6, 6, 6)
    local optionsLayout = listLayout(optionsHolder, 4)

    local control = newControl(self, "Dropdown", root, {
        Open = false,
        Value = options.Default,
        Options = {},
        Callback = options.Callback,
    })
    control.Card = card
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Chooser = chooser
    control.SelectedLabel = selectedLabel
    control.OptionsHolder = optionsHolder
    control.Arrow = arrow

    local function setOpen(open)
        control._state.Open = open == true
        if control._state.Open then
            local count = #control._state.Options
            local optionHeight = math.max(0, count * 34 + math.max(0, count - 1) * 4 + 12)
            optionsHolder.Visible = true
            root.Size = UDim2.new(1, 0, 0, baseHeight + 6 + optionHeight)
            optionsHolder.Size = UDim2.new(1, 0, 0, optionHeight)
            if arrow then
                self._window:_tween(arrow, 0.12, { Rotation = 180 })
            end
        else
            root.Size = UDim2.new(1, 0, 0, baseHeight)
            optionsHolder.Size = UDim2.new(1, 0, 0, 0)
            optionsHolder.Visible = false
            if arrow then
                self._window:_tween(arrow, 0.12, { Rotation = 0 })
            end
        end
    end

    local function clearOptionButtons()
        for _, child in ipairs(optionsHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    local function rebuildOptions()
        clearOptionButtons()
        for _, value in ipairs(control._state.Options) do
            local optionValue = value
            local optionButton = make("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = COLORS.GlassLight,
                BackgroundTransparency = 0.60,
                AutoButtonColor = false,
                Text = tostring(optionValue),
                TextColor3 = COLORS.SubText,
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Parent = optionsHolder,
            })
            padding(optionButton, 10, 10, 0, 0)
            round(optionButton, 8)
            stroke(optionButton, 1, 0.90)

            self._window:_connect(optionButton.MouseButton1Click, function()
                control:Set(optionValue)
                setOpen(false)
            end)

            self._window:_connect(optionButton.MouseEnter, function()
                self._window:_tween(optionButton, 0.10, { BackgroundTransparency = 0.42, TextColor3 = COLORS.Text })
            end)
            self._window:_connect(optionButton.MouseLeave, function()
                self._window:_tween(optionButton, 0.10, { BackgroundTransparency = 0.60, TextColor3 = COLORS.SubText })
            end)
        end

        if control._state.Open then
            setOpen(true)
        end
    end

    function control:Set(value, silent)
        local exists = false
        for _, candidate in ipairs(self._state.Options) do
            if candidate == value then
                exists = true
                break
            end
        end
        if not exists and #self._state.Options > 0 then
            value = self._state.Options[1]
        end
        self._state.Value = value
        self.SelectedLabel.Text = tostring(value or "Select")
        if not silent then
            safeCallback(self._state.Callback, value)
        end
        return self
    end

    function control:Get()
        return self._state.Value
    end

    function control:SetOptions(newOptions, keepValue)
        self._state.Options = {}
        for _, value in ipairs(newOptions or {}) do
            table.insert(self._state.Options, value)
        end
        rebuildOptions()
        if keepValue then
            self:Set(self._state.Value, true)
        else
            self:Set(self._state.Options[1], true)
        end
        return self
    end

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    self._window:_connect(chooser.MouseButton1Click, function()
        setOpen(not control._state.Open)
    end)

    control:SetOptions(values, true)
    control:Set(options.Default or control._state.Options[1], true)
    return control
end

function TabMethods:AddTextbox(options)
    options = options or {}
    local card = self._window:_newCard(self._page, options.Description and 70 or 58)
    local title, description = buildTitleBlock(self._window, card, options, 222)

    local box = make("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(options.Width or 196, 34),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.34,
        BorderSizePixel = 0,
        ClearTextOnFocus = options.ClearTextOnFocus == true,
        PlaceholderText = tostring(options.Placeholder or "Type here..."),
        PlaceholderColor3 = COLORS.Muted,
        Text = tostring(options.Default or ""),
        TextColor3 = COLORS.Text,
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })
    padding(box, 10, 10, 0, 0)
    round(box, 9)
    stroke(box, 1, 0.70)

    local control = newControl(self, "Textbox", card, {
        Value = tostring(options.Default or ""),
        Callback = options.Callback,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Box = box

    function control:Set(value, silent)
        local text = tostring(value or "")
        self._state.Value = text
        self.Box.Text = text
        if not silent then
            safeCallback(self._state.Callback, text)
        end
        return self
    end

    function control:Get()
        return self.Box.Text
    end

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    self._window:_connect(box.FocusLost, function(enterPressed)
        control._state.Value = box.Text
        safeCallback(control._state.Callback, box.Text, enterPressed)
    end)

    return control
end

TabMethods.AddInput = TabMethods.AddTextbox

function TabMethods:AddKeybind(options)
    options = options or {}
    local card = self._window:_newCard(self._page, options.Description and 66 or 56)
    local title, description = buildTitleBlock(self._window, card, options, 150)

    local bindButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(120, 32),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.34,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = card,
    })
    round(bindButton, 9)
    stroke(bindButton, 1, 0.70)

    local bindLabel = textLabel(bindButton, "", 9, COLORS.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    bindLabel.Size = UDim2.fromScale(1, 1)

    local defaultKey = options.Default
    if not (typeof(defaultKey) == "EnumItem" and defaultKey.EnumType == Enum.KeyCode) then
        defaultKey = Enum.KeyCode.Unknown
    end

    local control = newControl(self, "Keybind", card, {
        Value = defaultKey,
        Callback = options.Callback,
        Capturing = false,
        IgnoreProcessed = options.IgnoreProcessed ~= false,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Button = bindButton
    control.BindLabel = bindLabel

    function control:Set(keyCode, silent)
        if not (typeof(keyCode) == "EnumItem" and keyCode.EnumType == Enum.KeyCode) then
            return self
        end
        self._state.Value = keyCode
        self.BindLabel.Text = keyCode == Enum.KeyCode.Unknown and "NONE" or keyCode.Name
        if not silent then
            safeCallback(options.Changed, keyCode)
        end
        return self
    end

    function control:Get()
        return self._state.Value
    end

    function control:SetCallback(callback)
        self._state.Callback = callback
        return self
    end

    self._window:_connect(bindButton.MouseButton1Click, function()
        control._state.Capturing = true
        bindLabel.Text = "PRESS KEY"
        self._window:_tween(bindButton, 0.10, { BackgroundTransparency = 0.18 })
    end)

    self._window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if control._state.Capturing then
            control._state.Capturing = false
            self._window:_tween(bindButton, 0.10, { BackgroundTransparency = 0.34 })
            if input.KeyCode == Enum.KeyCode.Escape then
                control:Set(control._state.Value, true)
            elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                control:Set(Enum.KeyCode.Unknown)
            else
                control:Set(input.KeyCode)
            end
            return
        end

        if gameProcessed and control._state.IgnoreProcessed then
            return
        end

        if control._state.Value ~= Enum.KeyCode.Unknown and input.KeyCode == control._state.Value then
            safeCallback(control._state.Callback, input.KeyCode)
        end
    end)

    control:Set(defaultKey, true)
    return control
end

function TabMethods:AddColorPicker(options)
    options = options or {}
    local initial = typeof(options.Default) == "Color3" and options.Default or self._window:GetAccent()
    local card = self._window:_newCard(self._page, options.Description and 88 or 78)
    local title, description = buildTitleBlock(self._window, card, options, 118)

    local preview = make("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(34, 20),
        BackgroundColor3 = initial,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(preview, 7)
    stroke(preview, 1, 0.58)

    local rgbLabel = textLabel(card, "", 8, COLORS.SubText, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
    rgbLabel.AnchorPoint = Vector2.new(1, 0)
    rgbLabel.Position = UDim2.new(1, -56, 0, 10)
    rgbLabel.Size = UDim2.fromOffset(100, 20)

    local rails = make("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -12),
        Size = UDim2.new(1, -28, 0, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = card,
    })

    local control = newControl(self, "ColorPicker", card, {
        Value = initial,
        Callback = options.Callback,
        DragChannel = nil,
    })
    control.TitleLabel = title
    control.DescriptionLabel = description
    control.Preview = preview
    control.RGBLabel = rgbLabel

    local channelData = {}
    local channelNames = { "R", "G", "B" }

    for index, channelName in ipairs(channelNames) do
        local y = (index - 1) * 9
        local channelLabel = textLabel(rails, channelName, 7, COLORS.Muted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        channelLabel.Position = UDim2.fromOffset(0, y)
        channelLabel.Size = UDim2.fromOffset(10, 7)

        local rail = make("Frame", {
            Position = UDim2.fromOffset(14, y + 2),
            Size = UDim2.new(1, -14, 0, 3),
            BackgroundColor3 = COLORS.GlassLight,
            BackgroundTransparency = 0.24,
            BorderSizePixel = 0,
            Parent = rails,
        })
        round(rail, 2)

        local fill = make("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = COLORS.Edge,
            BorderSizePixel = 0,
            Parent = rail,
        })
        round(fill, 2)

        local hit = make("TextButton", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -4, 0.5, 0),
            Size = UDim2.new(1, 8, 0, 8),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = rail,
        })

        channelData[index] = { Rail = rail, Fill = fill, Hit = hit }
        self._window:_connect(hit.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                control._state.DragChannel = index
            end
        end)
    end

    local function setChannelFromX(index, x)
        local data = channelData[index]
        local alpha = math.clamp((x - data.Rail.AbsolutePosition.X) / math.max(1, data.Rail.AbsoluteSize.X), 0, 1)
        local color = control._state.Value
        local r, g, b = color.R, color.G, color.B
        if index == 1 then r = alpha end
        if index == 2 then g = alpha end
        if index == 3 then b = alpha end
        control:Set(Color3.new(r, g, b))
    end

    function control:Set(value, silent)
        if typeof(value) ~= "Color3" then
            return self
        end
        self._state.Value = value
        self.Preview.BackgroundColor3 = value
        local r = math.floor(value.R * 255 + 0.5)
        local g = math.floor(value.G * 255 + 0.5)
        local b = math.floor(value.B * 255 + 0.5)
        self.RGBLabel.Text = string.format("%d, %d, %d", r, g, b)
        local values = { value.R, value.G, value.B }
        for index, alpha in ipairs(values) do
            channelData[index].Fill.Size = UDim2.new(alpha, 0, 1, 0)
        end
        if not silent then
            safeCallback(self._state.Callback, value)
        end
        return self
    end

    function control:Get()
        return self._state.Value
    end

    self._window:_connect(UserInputService.InputChanged, function(input)
        if control._state.DragChannel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setChannelFromX(control._state.DragChannel, input.Position.X)
        end
    end)

    self._window:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            control._state.DragChannel = nil
        end
    end)

    control:Set(initial, true)
    return control
end

function TabMethods:AddCustom(options)
    if type(options) == "number" then
        options = { Height = options }
    end
    options = options or {}

    local root = self._window:_newCard(self._page, tonumber(options.Height) or 80)
    if options.Transparent == true then
        root.BackgroundTransparency = 1
        local foundStroke = root:FindFirstChildOfClass("UIStroke")
        if foundStroke then
            foundStroke.Transparency = 1
        end
    end

    local control = newControl(self, "Custom", root, {})
    control.Container = root

    local helpers = {
        Make = make,
        Round = round,
        Stroke = stroke,
        Padding = padding,
        TextLabel = textLabel,
        Icon = icon,
        Colors = self._window:GetColors(),
        Window = self._window,
        Tab = self,
    }

    if type(options.Builder) == "function" then
        safeCallback(options.Builder, root, helpers, control)
    end

    function control:SetHeight(height)
        local numeric = tonumber(height)
        if numeric then
            self.Root.Size = UDim2.new(1, 0, 0, numeric)
        end
        return self
    end

    return control
end

function TabMethods:GetControls()
    return self._controls
end

function TabMethods:Select()
    self._window:SelectTab(self)
    return self
end

function SaltyGlass:CreateWindow(options)
    options = options or {}
    local window = setmetatable({}, WindowMethods)

    window._options = merge({
        Title = "SALTYGLASS",
        Subtitle = "CUSTOM UI",
        Name = "SaltyGlassLibraryGui",
        Accent = DEFAULTS.Accent,
        Size = DEFAULTS.Size,
        MinSize = DEFAULTS.MinSize,
        MaxSize = DEFAULTS.MaxSize,
        ToggleKey = DEFAULTS.ToggleKey,
        ReduceMotion = DEFAULTS.ReduceMotion,
        BackgroundBlur = true,
        BlurSize = 16,
        SmoothTransitions = true,
        StatusIsland = true,
        MusicPlayer = false,
        CleanupExisting = true,
        CloseBehavior = "Destroy",
        Parent = PlayerGui,
    }, options)

    window._connections = {}
    window._accentBindings = {}
    window._tabs = {}
    window._activeTab = nil
    window._destroyed = false
    window._minimized = false
    window._hidden = false
    window._accent = typeof(window._options.Accent) == "Color3" and window._options.Accent or DEFAULTS.Accent
    window._reduceMotion = window._options.ReduceMotion == true
    window._toggleKey = typeof(window._options.ToggleKey) == "EnumItem" and window._options.ToggleKey or DEFAULTS.ToggleKey
    window._blurEnabled = window._options.BackgroundBlur ~= false
    window._blurSize = math.clamp(tonumber(window._options.BlurSize) or 16, 0, 56)
    window._statusToken = 0
    window._statusActive = false
    window._pageSweepToken = 0
    window._defaultAccent = window._accent
    window._defaultReduceMotion = window._reduceMotion
    window._defaultBlurEnabled = window._blurEnabled
    window._defaultToggleKey = window._toggleKey
    window._defaultSize = normalizeSize(window._options.Size, DEFAULTS.Size)
    window._minSize = typeof(window._options.MinSize) == "Vector2" and window._options.MinSize or DEFAULTS.MinSize
    window._maxSize = typeof(window._options.MaxSize) == "Vector2" and window._options.MaxSize or DEFAULTS.MaxSize

    local parent = window._options.Parent
    if typeof(parent) ~= "Instance" then
        parent = PlayerGui
    end

    local screenName = tostring(window._options.Name or "SaltyGlassLibraryGui")
    if window._options.CleanupExisting ~= false then
        local old = parent:FindFirstChild(screenName)
        if old then
            old:Destroy()
        end
    end

    local screen = make("ScreenGui", {
        Name = screenName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = tonumber(window._options.DisplayOrder) or 100,
        Parent = parent,
    })
    window._screen = screen

    local backgroundBlurName = screenName .. "_BackgroundBlur"
    local oldBackgroundBlur = Lighting:FindFirstChild(backgroundBlurName)
    if oldBackgroundBlur then
        oldBackgroundBlur:Destroy()
    end

    window._backgroundBlur = make("BlurEffect", {
        Name = backgroundBlurName,
        Size = 0,
        Parent = Lighting,
    })

    local main = make("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = normalizePosition(window._options.Position),
        Size = window._defaultSize,
        BackgroundColor3 = COLORS.GlassBase,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screen,
    })
    round(main, 26)
    local mainStroke = stroke(main, 1.4, 0.48)
    local mainStrokeGradient = make("UIGradient", {
        Rotation = 20,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COLORS.Edge),
            ColorSequenceKeypoint.new(0.5, COLORS.Edge),
            ColorSequenceKeypoint.new(1, COLORS.Edge),
        }),
        Parent = mainStroke,
    })
    local mainScale = make("UIScale", { Scale = 1, Parent = main })
    window._main = main
    window._mainScale = mainScale

    local gradient = make("UIGradient", {
        Rotation = 55,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 52, 84)),
            ColorSequenceKeypoint.new(0.34, COLORS.GlassMid),
            ColorSequenceKeypoint.new(0.72, COLORS.GlassBase),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 17)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.42, 0.56),
            NumberSequenceKeypoint.new(1, 0.88),
        }),
        Parent = main,
    })

    task.spawn(function()
        while not window._destroyed and gradient.Parent do
            if window._reduceMotion then
                gradient.Rotation = 55
                task.wait(0.25)
            else
                window:_tween(gradient, 7.5, { Rotation = 74 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(7.5)
                if not window._destroyed and gradient.Parent and not window._reduceMotion then
                    window:_tween(gradient, 7.5, { Rotation = 38 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(7.5)
                end
            end
        end
    end)

    task.spawn(function()
        while not window._destroyed and mainStrokeGradient.Parent do
            if window._reduceMotion then
                mainStrokeGradient.Rotation = 20
                task.wait(0.25)
            else
                window:_tween(mainStrokeGradient, 8, { Rotation = 380 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                task.wait(8)
                if mainStrokeGradient.Parent then
                    mainStrokeGradient.Rotation = 20
                end
            end
        end
    end)

    local inner = make("Frame", {
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = main,
    })
    round(inner, 25)
    stroke(inner, 1, 0.86)

    local shine = make("Frame", {
        Position = UDim2.new(0, 30, 0, 1),
        Size = UDim2.new(1, -60, 0, 1),
        BackgroundColor3 = COLORS.Edge,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Parent = main,
    })
    round(shine, 2)

    local topbar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = main,
    })
    window._topbar = topbar

    local title = textLabel(topbar, tostring(window._options.Title), 15, COLORS.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(20, 12)
    title.Size = UDim2.new(0.5, -20, 0, 26)
    window._title = title

    local subtitle = textLabel(topbar, tostring(window._options.Subtitle or ""), 8, COLORS.SubText, Enum.Font.GothamBold)
    subtitle.Position = UDim2.fromOffset(21, 38)
    subtitle.Size = UDim2.new(0.5, -20, 0, 18)
    subtitle.Visible = tostring(window._options.Subtitle or "") ~= ""
    window._subtitle = subtitle

    local dragRegion = make("TextButton", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -254, 0, 70),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = topbar,
    })

    local context = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -100, 0.5, 0),
        Size = UDim2.fromOffset(138, 32),
        BackgroundColor3 = COLORS.GlassLight,
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    round(context, 11)
    stroke(context, 1, 0.78)
    window._contextFrame = context
    window._contextBaseSize = UDim2.fromOffset(138, 32)
    window._contextRightOffset = 100

    local contextIcon = icon(context, "home", 13, window._accent, 4)
    contextIcon.AnchorPoint = Vector2.new(0, 0.5)
    contextIcon.Position = UDim2.new(0, 10, 0.5, 0)
    contextIcon.Visible = false
    window:_bindAccent(contextIcon, "ImageColor3")
    window._contextIcon = contextIcon

    local contextText = textLabel(context, "READY", 8, COLORS.SubText, Enum.Font.GothamBold)
    contextText.Position = UDim2.fromOffset(32, 0)
    contextText.Size = UDim2.new(1, -42, 1, 0)
    contextText.TextTruncate = Enum.TextTruncate.AtEnd
    window._contextText = contextText

    local contextSub = textLabel(context, "", 7, COLORS.SubText, Enum.Font.Gotham)
    contextSub.Position = UDim2.fromOffset(34, 18)
    contextSub.Size = UDim2.new(1, -44, 0, 13)
    contextSub.TextTruncate = Enum.TextTruncate.AtEnd
    contextSub.Visible = false
    window._contextSub = contextSub

    local minimizeButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -54, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = topbar,
    })
    local minimizeIcon = icon(minimizeButton, "minus", 14, COLORS.SubText, 5)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.Position = UDim2.fromScale(0.5, 0.5)

    local closeButton = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = topbar,
    })
    local closeIcon = icon(closeButton, "x", 14, COLORS.SubText, 5)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.fromScale(0.5, 0.5)

    local divider = make("Frame", {
        Position = UDim2.new(0, 18, 0, 69),
        Size = UDim2.new(1, -36, 0, 1),
        BackgroundColor3 = COLORS.Edge,
        BackgroundTransparency = 0.90,
        BorderSizePixel = 0,
        Parent = main,
    })

    local sidebar = make("Frame", {
        Position = UDim2.fromOffset(12, 82),
        Size = UDim2.new(0, 146, 1, -96),
        BackgroundColor3 = COLORS.GlassMid,
        BackgroundTransparency = 0.54,
        BorderSizePixel = 0,
        Parent = main,
    })
    round(sidebar, 16)
    stroke(sidebar, 1, 0.87)

    local tabList = make("Frame", {
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    listLayout(tabList, 6)
    window._tabList = tabList

    local content = make("Frame", {
        Position = UDim2.fromOffset(166, 76),
        Size = UDim2.new(1, -178, 1, -88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = main,
    })
    window._content = content

    local pageSweep = make("Frame", {
        Position = UDim2.new(-0.18, 0, 0, 0),
        Size = UDim2.fromOffset(74, 560),
        BackgroundColor3 = COLORS.Edge,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Rotation = 12,
        Visible = false,
        ZIndex = 80,
        Parent = content,
    })
    local pageSweepGradient = make("UIGradient", {
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.42),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = pageSweep,
    })
    window._pageSweep = pageSweep

    local resizeHandle = make("TextButton", {
        Name = "ResizeHandle",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(42, 42),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 50,
        Parent = main,
    })
    local resizeIcon = icon(resizeHandle, "move-diagonal-2", 14, COLORS.Muted, 51)
    resizeIcon.AnchorPoint = Vector2.new(1, 1)
    resizeIcon.Position = UDim2.new(1, -9, 1, -9)
    resizeIcon.ImageTransparency = 0.30

    local badge = make("TextButton", {
        Name = "MinimizedBadge",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = main.Position,
        Size = UDim2.fromOffset(188, 52),
        BackgroundColor3 = COLORS.GlassBase,
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        Parent = screen,
    })
    round(badge, 16)
    stroke(badge, 1, 0.52)
    local badgeScale = make("UIScale", { Scale = 1, Parent = badge })
    window._badge = badge
    window._badgeScale = badgeScale

    local badgeIconHolder = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = window._accent,
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
        Parent = badge,
    })
    round(badgeIconHolder, 8)
    stroke(badgeIconHolder, 1, 0.74)
    window:_bindAccent(badgeIconHolder)

    local badgeMusicIcon = icon(badgeIconHolder, "music", 13, COLORS.Text, 3)
    badgeMusicIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    badgeMusicIcon.Position = UDim2.fromScale(0.5, 0.5)

    local badgeTitle = textLabel(badge, tostring(window._options.Title), 10, COLORS.Text, Enum.Font.GothamBold)
    badgeTitle.Position = UDim2.fromOffset(40, 6)
    badgeTitle.Size = UDim2.new(1, -50, 0, 20)
    badgeTitle.TextTruncate = Enum.TextTruncate.AtEnd

    local badgeSub = textLabel(badge, "MINIMIZED • RESTORE", 7, COLORS.SubText, Enum.Font.GothamBold)
    badgeSub.Position = UDim2.fromOffset(40, 25)
    badgeSub.Size = UDim2.new(1, -50, 0, 16)

    local notifications = make("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(310, 420),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = screen,
    })
    local notificationLayout = listLayout(notifications, 8)
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    window._notifications = notifications

    local function updateResponsiveHeader()
        if window._destroyed then
            return
        end
        if window._contextFrame then
            window._contextFrame.Visible = main.AbsoluteSize.X >= 560
        end
    end

    window:_connect(main:GetPropertyChangedSignal("AbsoluteSize"), updateResponsiveHeader)
    task.defer(updateResponsiveHeader)

    window:_connect(minimizeButton.MouseButton1Click, function()
        window:Minimize()
    end)

    window:_connect(closeButton.MouseButton1Click, function()
        if window._options.CloseBehavior == "Hide" then
            window:Hide()
        else
            window:Destroy()
        end
    end)

    window:_connect(badge.MouseButton1Click, function()
        window:Restore()
    end)

    window:_connect(minimizeButton.MouseEnter, function()
        window:_tween(minimizeIcon, 0.10, { ImageColor3 = window._accent })
    end)
    window:_connect(minimizeButton.MouseLeave, function()
        window:_tween(minimizeIcon, 0.10, { ImageColor3 = COLORS.SubText })
    end)
    window:_connect(closeButton.MouseEnter, function()
        window:_tween(closeIcon, 0.10, { ImageColor3 = COLORS.Danger })
    end)
    window:_connect(closeButton.MouseLeave, function()
        window:_tween(closeIcon, 0.10, { ImageColor3 = COLORS.SubText })
    end)

    local dragging = false
    local dragStart = nil
    local dragPosition = nil

    window:_connect(dragRegion.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            dragPosition = main.Position
        end
    end)

    window:_connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                dragPosition.X.Scale,
                dragPosition.X.Offset + delta.X,
                dragPosition.Y.Scale,
                dragPosition.Y.Offset + delta.Y
            )
        end
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local resizing = false
    local resizeStart = nil
    local resizeStartSize = nil
    local resizeStartPosition = nil

    window:_connect(resizeHandle.MouseEnter, function()
        window:_tween(resizeIcon, 0.12, { ImageColor3 = window._accent, ImageTransparency = 0 })
    end)
    window:_connect(resizeHandle.MouseLeave, function()
        if not resizing then
            window:_tween(resizeIcon, 0.12, { ImageColor3 = COLORS.Muted, ImageTransparency = 0.30 })
        end
    end)

    window:_connect(resizeHandle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            resizeStartSize = main.AbsoluteSize
            resizeStartPosition = main.Position
            window:_tween(resizeIcon, 0.10, { ImageColor3 = window._accent, ImageTransparency = 0 })
        end
    end)

    window:_connect(UserInputService.InputChanged, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newX = math.clamp(resizeStartSize.X + delta.X, window._minSize.X, window._maxSize.X)
            local newY = math.clamp(resizeStartSize.Y + delta.Y, window._minSize.Y, window._maxSize.Y)
            local actualDX = newX - resizeStartSize.X
            local actualDY = newY - resizeStartSize.Y
            main.Size = UDim2.fromOffset(newX, newY)
            main.Position = UDim2.new(
                resizeStartPosition.X.Scale,
                resizeStartPosition.X.Offset + (actualDX * 0.5),
                resizeStartPosition.Y.Scale,
                resizeStartPosition.Y.Offset + (actualDY * 0.5)
            )
        end
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
            window:_tween(resizeIcon, 0.10, { ImageColor3 = COLORS.Muted, ImageTransparency = 0.30 })
        end
    end)

    window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window._toggleKey then
            window:Toggle()
        end
    end)

    if not window._reduceMotion then
        mainScale.Scale = 0.97
        main.BackgroundTransparency = 1
        window:_tween(mainScale, 0.20, { Scale = 1 })
        window:_tween(main, 0.20, { BackgroundTransparency = 0.08 })
    end

    window:_applyBackgroundBlur()

    if window._options.MusicPlayer then
        local musicOptions = type(window._options.MusicPlayer) == "table" and window._options.MusicPlayer or {}
        window:AddMusicPlayer(musicOptions)
    end

    task.defer(function()
        if not window._destroyed then
            window:ShowStatus({
                Title = tostring(window._options.Title or "SALTYGLASS"),
                Subtitle = "Ready",
                Icon = "home",
                Color = window._accent,
                Duration = 1.35,
            })
        end
    end)

    if window._options.StartTab then
        task.defer(function()
            if not window._destroyed then
                window:SelectTab(window._options.StartTab)
            end
        end)
    end

    return window
end

function SaltyGlass:CreateOriginalWindow(options)
    local original = merge({
        Title = "SALTY",
        Subtitle = "ULTRA PREMIUM GLASS",
        Accent = SaltyGlass.Themes.Violet,
        Size = UDim2.fromOffset(680, 500),
        BackgroundBlur = true,
        BlurSize = 16,
        SmoothTransitions = true,
        StatusIsland = true,
        MusicPlayer = {
            Title = "Custom Audio",
            Subtitle = "ROBLOX AUDIO ID",
            Volume = 0.55,
            Speed = 1,
            RepeatMode = 0,
            MusicBlurSize = 30,
        },
    }, options or {})
    return self:CreateWindow(original)
end

SaltyGlass.CreatePremiumWindow = SaltyGlass.CreateOriginalWindow
SaltyGlass.new = SaltyGlass.CreateWindow

return SaltyGlass
