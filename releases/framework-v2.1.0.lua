-- SaltyGlass Future Framework v2.1.0
-- Loads after the original-looking Feature Pack base.
-- Keeps the original Salty visual language: no blobs, white borders, violet default accent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    error("SaltyGlass Framework must run on the Roblox client.", 0)
end

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("SaltyGlassGui", 10)
if not screenGui then
    error("SaltyGlass Framework requires SaltyGlassGui.", 0)
end

if screenGui:GetAttribute("FrameworkReady") then
    return _G.SaltyGlass
end

local mainFrame = screenGui:WaitForChild("MainFrame", 10)
local contentArea = mainFrame:WaitForChild("ContentArea", 10)

local pages = {
    Home = contentArea:FindFirstChild("HomePage"),
    Player = contentArea:FindFirstChild("PlayerPage"),
    Settings = contentArea:FindFirstChild("SettingsPage"),
    Visuals = contentArea:FindFirstChild("VisualsPage"),
    World = contentArea:FindFirstChild("WorldPage"),
}

local bodies = {}
for name, page in pairs(pages) do
    bodies[name] = page and page:FindFirstChild("PageBody")
end

local C = {
    Base = Color3.fromRGB(9, 13, 24),
    Mid = Color3.fromRGB(17, 24, 42),
    Light = Color3.fromRGB(27, 36, 64),
    Edge = Color3.new(1, 1, 1),
    Accent = Color3.fromRGB(139, 124, 255),
    Text = Color3.new(1, 1, 1),
    Sub = Color3.fromRGB(181, 188, 211),
    Muted = Color3.fromRGB(111, 120, 149),
    Success = Color3.fromRGB(109, 255, 168),
    Danger = Color3.fromRGB(255, 107, 122),
}

local ROLE_LEVELS = { user = 1, beta = 2, admin = 3, owner = 4 }
local state = {
    connections = {},
    role = string.lower(tostring(player:GetAttribute("SaltyRole") or "user")),
    channel = string.lower(tostring(player:GetAttribute("SaltyUpdateChannel") or "stable")),
    flags = {}, controls = {}, features = {}, modules = {}, commands = {}, built = {},
    profiles = {}, backup = nil, notifications = {}, telemetryEnabled = false,
    telemetrySink = nil, profileName = "Default", destroyed = false,
}

if not ROLE_LEVELS[state.role] then state.role = "user" end
if state.channel ~= "stable" and state.channel ~= "beta" and state.channel ~= "dev" then state.channel = "stable" end

do
    local raw = player:GetAttribute("SaltyFeatureFlags")
    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok and type(decoded) == "table" then state.flags = decoded end
    end
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(state.connections, connection)
    return connection
end

local function tw(item, duration, props)
    if not item or not item.Parent then return nil end
    local motion = TweenService:Create(item, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    motion:Play()
    return motion
end

local function round(item, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = item
    return corner
end

local function stroke(item, transparency, color)
    local value = Instance.new("UIStroke")
    value.Thickness = 1
    value.Transparency = transparency or 0.82
    value.Color = color or C.Edge
    value.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    value.Parent = item
    return value
end

local function playSound(id, volume)
    if screenGui:GetAttribute("UISoundsEnabled") == false then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.Name = "SaltyUISound"
        sound.SoundId = id
        sound.Volume = volume or 0.15
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() if sound.Parent then sound:Destroy() end end)
        task.delay(3, function() if sound.Parent then sound:Destroy() end end)
    end)
end

local function click() playSound("rbxassetid://4307186075", 0.26) end
local function hover() playSound("rbxassetid://408524543", 0.09) end

local function colorToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function hexToColor(value)
    value = tostring(value or ""):gsub("#", ""):gsub("%s+", "")
    if #value == 3 then
        value = value:sub(1,1):rep(2) .. value:sub(2,2):rep(2) .. value:sub(3,3):rep(2)
    end
    if #value ~= 6 or value:find("[^%x]") then return nil end
    return Color3.fromRGB(tonumber(value:sub(1,2),16), tonumber(value:sub(3,4),16), tonumber(value:sub(5,6),16))
end

local function header(parent, text, order)
    local holder = Instance.new("Frame")
    holder.Name = "FrameworkHeader_" .. text:gsub("%s+", "")
    holder.Size = UDim2.new(1,0,0,28)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order
    holder.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder
    local width = TextService:GetTextSize(text,10,Enum.Font.GothamBold,Vector2.new(1000,20)).X
    local line = Instance.new("Frame")
    line.Position = UDim2.fromOffset(0,22)
    line.Size = UDim2.fromOffset(math.max(18,math.ceil(width)),1)
    line.BackgroundColor3 = C.Edge
    line.BackgroundTransparency = 0.42
    line.BorderSizePixel = 0
    line.Parent = holder
    return holder
end

local function card(parent, height, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,height or 54)
    frame.BackgroundColor3 = C.Base
    frame.BackgroundTransparency = 0.56
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parent
    round(frame,13)
    stroke(frame,0.82)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 35
    gradient.Color = ColorSequence.new(C.Mid,C.Base)
    gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.48),NumberSequenceKeypoint.new(1,0.84)})
    gradient.Parent = frame
    return frame
end

local function textPair(parent,titleText,descText,rightSpace)
    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(14,8)
    title.Size = UDim2.new(1,-(rightSpace or 100),0,18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamMedium
    title.Text = titleText
    title.TextColor3 = C.Text
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = parent
    local desc = Instance.new("TextLabel")
    desc.Position = UDim2.fromOffset(14,27)
    desc.Size = UDim2.new(1,-(rightSpace or 100),0,16)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.Text = descText or ""
    desc.TextColor3 = C.Sub
    desc.TextSize = 9
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = parent
    return title,desc
end

local status = Instance.new("Frame")
status.AnchorPoint = Vector2.new(0.5,1)
status.Position = UDim2.new(0.5,0,1,-22)
status.Size = UDim2.fromOffset(270,34)
status.BackgroundColor3 = C.Base
status.BackgroundTransparency = 1
status.BorderSizePixel = 0
status.Visible = false
status.ZIndex = 340
status.Parent = screenGui
round(status,12)
local statusStroke = stroke(status,1)
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.fromScale(1,1)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.GothamMedium
statusText.TextColor3 = C.Text
statusText.TextTransparency = 1
statusText.TextSize = 10
statusText.ZIndex = 341
statusText.Parent = status
local statusToken = 0

local function notify(message,kind)
    statusToken += 1
    local token = statusToken
    local tint = kind == "success" and C.Success or kind == "error" and C.Danger or C.Text
    table.insert(state.notifications,{text=tostring(message),kind=kind or "info",timestamp=os.time()})
    while #state.notifications > 50 do table.remove(state.notifications,1) end
    statusText.Text = tostring(message)
    statusText.TextColor3 = tint
    status.Visible = true
    tw(status,0.12,{BackgroundTransparency=0.14})
    tw(statusStroke,0.12,{Transparency=0.56,Color=kind == "error" and C.Danger or C.Edge})
    tw(statusText,0.12,{TextTransparency=0})
    task.delay(1.5,function()
        if token ~= statusToken or not status.Parent then return end
        tw(status,0.12,{BackgroundTransparency=1})
        tw(statusStroke,0.12,{Transparency=1})
        tw(statusText,0.12,{TextTransparency=1})
        task.delay(0.13,function() if token == statusToken and status.Parent then status.Visible=false end end)
    end)
end

local function makeButton(parent,options,order)
    local frame = card(parent,54,order)
    textPair(frame,options.Name or "Button",options.Description or "",112)
    local button = Instance.new("TextButton")
    button.AnchorPoint=Vector2.new(1,0.5)
    button.Position=UDim2.new(1,-14,0.5,0)
    button.Size=UDim2.fromOffset(90,30)
    button.BackgroundColor3=C.Light
    button.BackgroundTransparency=0.38
    button.BorderSizePixel=0
    button.AutoButtonColor=false
    button.Font=Enum.Font.GothamBold
    button.Text=options.ButtonText or "RUN"
    button.TextColor3=C.Text
    button.TextSize=9
    button.ZIndex=6
    button.Parent=frame
    round(button,9)
    stroke(button,0.68)
    connect(button.MouseEnter,function() hover(); tw(button,0.12,{BackgroundTransparency=0.20}) end)
    connect(button.MouseLeave,function() tw(button,0.12,{BackgroundTransparency=0.38}) end)
    connect(button.MouseButton1Click,function() click(); if type(options.Callback)=="function" then task.spawn(options.Callback) end end)
    return button
end

local function makeToggle(parent,options,order)
    local frame=card(parent,54,order)
    textPair(frame,options.Name or "Toggle",options.Description or "",88)
    local track=Instance.new("Frame")
    track.AnchorPoint=Vector2.new(1,0.5)
    track.Position=UDim2.new(1,-14,0.5,0)
    track.Size=UDim2.fromOffset(38,20)
    track.BackgroundColor3=options.Default and C.Accent or C.Light
    track.BackgroundTransparency=options.Default and 0.12 or 0.28
    track.BorderSizePixel=0
    track.ZIndex=6
    track.Parent=frame
    round(track,10); stroke(track,0.72)
    local knob=Instance.new("Frame")
    knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=options.Default and UDim2.new(1,-10,0.5,0) or UDim2.new(0,10,0.5,0)
    knob.Size=UDim2.fromOffset(14,14)
    knob.BackgroundColor3=C.Edge
    knob.BorderSizePixel=0
    knob.ZIndex=7
    knob.Parent=track
    round(knob,8)
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.fromScale(1,1); hit.BackgroundTransparency=1; hit.Text=""; hit.AutoButtonColor=false; hit.ZIndex=8; hit.Parent=frame
    local control={Value=options.Default==true}
    function control:Set(value,silent)
        self.Value=value==true
        tw(track,0.14,{BackgroundColor3=self.Value and C.Accent or C.Light,BackgroundTransparency=self.Value and 0.12 or 0.28})
        tw(knob,0.14,{Position=self.Value and UDim2.new(1,-10,0.5,0) or UDim2.new(0,10,0.5,0)})
        if not silent and type(options.Callback)=="function" then task.spawn(options.Callback,self.Value) end
    end
    function control:Get() return self.Value end
    connect(hit.MouseEnter,hover)
    connect(hit.MouseButton1Click,function() click(); control:Set(not control.Value,false) end)
    return control
end

local function makeSlider(parent,options,order)
    local frame=card(parent,66,order)
    textPair(frame,options.Name or "Slider",options.Description or "",88)
    local valueLabel=Instance.new("TextLabel")
    valueLabel.AnchorPoint=Vector2.new(1,0); valueLabel.Position=UDim2.new(1,-14,0,8); valueLabel.Size=UDim2.fromOffset(64,18)
    valueLabel.BackgroundTransparency=1; valueLabel.Font=Enum.Font.GothamBold; valueLabel.TextColor3=C.Text; valueLabel.TextSize=10; valueLabel.TextXAlignment=Enum.TextXAlignment.Right; valueLabel.ZIndex=6; valueLabel.Parent=frame
    local bar=Instance.new("Frame")
    bar.Position=UDim2.new(0,14,1,-15); bar.Size=UDim2.new(1,-28,0,3); bar.BackgroundColor3=C.Light; bar.BackgroundTransparency=0.20; bar.BorderSizePixel=0; bar.ZIndex=6; bar.Parent=frame; round(bar,4)
    local fill=Instance.new("Frame")
    fill.BackgroundColor3=C.Accent; fill.BorderSizePixel=0; fill.ZIndex=7; fill.Parent=bar; round(fill,4)
    local thumb=Instance.new("Frame")
    thumb.AnchorPoint=Vector2.new(0.5,0.5); thumb.Size=UDim2.fromOffset(10,10); thumb.BackgroundColor3=C.Edge; thumb.BorderSizePixel=0; thumb.ZIndex=8; thumb.Parent=bar; round(thumb,6)
    local hit=Instance.new("TextButton")
    hit.Position=UDim2.new(0,8,1,-28); hit.Size=UDim2.new(1,-16,0,26); hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=9; hit.Parent=frame
    local minimum=tonumber(options.Min) or 0
    local maximum=tonumber(options.Max) or 100
    local step=tonumber(options.Increment) or 1
    local control={Value=tonumber(options.Default) or minimum,Dragging=false}
    local function formatValue(value) return step<1 and string.format("%.1f%s",value,options.Suffix or "") or tostring(math.floor(value+0.5))..(options.Suffix or "") end
    function control:Set(value,silent)
        value=math.clamp(tonumber(value) or minimum,minimum,maximum)
        value=math.floor(value/step+0.5)*step
        self.Value=math.clamp(value,minimum,maximum)
        local alpha=maximum>minimum and (self.Value-minimum)/(maximum-minimum) or 0
        fill.Size=UDim2.new(alpha,0,1,0); thumb.Position=UDim2.new(alpha,0,0.5,0); valueLabel.Text=formatValue(self.Value)
        if not silent and type(options.Callback)=="function" then task.spawn(options.Callback,self.Value) end
    end
    function control:Get() return self.Value end
    local function update(x)
        local alpha=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
        control:Set(minimum+(maximum-minimum)*alpha,false)
    end
    connect(hit.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then click(); control.Dragging=true; update(input.Position.X) end end)
    connect(hit.InputEnded,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then control.Dragging=false end end)
    connect(UserInputService.InputChanged,function(input) if control.Dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input.Position.X) end end)
    control:Set(control.Value,true)
    return control
end

local function makeTextbox(parent,options,order)
    local frame=card(parent,62,order)
    textPair(frame,options.Name or "Input",options.Description or "",180)
    local box=Instance.new("TextBox")
    box.AnchorPoint=Vector2.new(1,0.5); box.Position=UDim2.new(1,-14,0.5,0); box.Size=UDim2.fromOffset(154,34); box.BackgroundColor3=C.Mid; box.BackgroundTransparency=0.30; box.BorderSizePixel=0; box.ClearTextOnFocus=false; box.Font=Enum.Font.GothamMedium; box.PlaceholderText=options.Placeholder or ""; box.PlaceholderColor3=C.Muted; box.Text=tostring(options.Default or ""); box.TextColor3=C.Text; box.TextSize=9; box.TextXAlignment=Enum.TextXAlignment.Center; box.ZIndex=6; box.Parent=frame; round(box,9)
    local outline=stroke(box,0.70)
    local control={Value=box.Text,Box=box}
    function control:Set(value,silent) self.Value=tostring(value or ""); box.Text=self.Value; if not silent and type(options.Callback)=="function" then task.spawn(options.Callback,self.Value) end end
    function control:Get() return self.Value end
    connect(box.Focused,function() hover(); outline.Color=C.Accent; outline.Transparency=0.34 end)
    connect(box.FocusLost,function(enterPressed) outline.Color=C.Edge; outline.Transparency=0.70; control:Set(box.Text,false); if enterPressed and type(options.OnEnter)=="function" then task.spawn(options.OnEnter,control.Value) end end)
    return control
end

local API={Version="2.1.0"}

local function serializeValue(value)
    if typeof(value)=="Color3" then return {__type="Color3",hex=colorToHex(value)} end
    return value
end
local function deserializeValue(value)
    if type(value)=="table" and value.__type=="Color3" and type(value.hex)=="string" then return hexToColor(value.hex) end
    return value
end

local function saveProfiles()
    local raw=HttpService:JSONEncode(state.profiles)
    if type(writefile)=="function" then
        pcall(function() if type(makefolder)=="function" and (type(isfolder)~="function" or not isfolder("SaltyGlass")) then makefolder("SaltyGlass") end end)
        local ok=pcall(writefile,"SaltyGlass/profiles.json",raw)
        if ok then return true end
    end
    player:SetAttribute("SaltyProfilesSession",raw)
    return false
end

local function loadProfiles()
    local raw=nil
    if type(readfile)=="function" then
        local ok,value=pcall(function() if type(isfile)=="function" and not isfile("SaltyGlass/profiles.json") then return nil end return readfile("SaltyGlass/profiles.json") end)
        if ok and type(value)=="string" then raw=value end
    end
    if not raw then raw=player:GetAttribute("SaltyProfilesSession") end
    if type(raw)~="string" or raw=="" then return end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,raw)
    if ok and type(data)=="table" then state.profiles=data end
end
loadProfiles()

local function snapshot()
    local result={accent=colorToHex(C.Accent),channel=state.channel,telemetry=state.telemetryEnabled,controls={},flags=state.flags}
    for id,control in pairs(state.controls) do
        if type(control.Get)=="function" then local ok,value=pcall(control.Get,control); if ok then result.controls[id]=serializeValue(value) end end
    end
    return result
end

local function applySnapshot(data)
    if type(data)~="table" then return false end
    if type(data.accent)=="string" then local color=hexToColor(data.accent); if color then API:SetAccent(color) end end
    if data.channel then API:SetUpdateChannel(data.channel) end
    if type(data.telemetry)=="boolean" then API:SetTelemetryEnabled(data.telemetry) end
    if type(data.flags)=="table" then state.flags=data.flags; player:SetAttribute("SaltyFeatureFlags",HttpService:JSONEncode(state.flags)) end
    if type(data.controls)=="table" then for id,value in pairs(data.controls) do local control=state.controls[id]; if control and type(control.Set)=="function" then pcall(control.Set,control,deserializeValue(value),false) end end end
    return true
end

function API:Notify(message,kind) notify(message,kind) end
function API:GetNotificationHistory() local output={}; for i,item in ipairs(state.notifications) do output[i]={text=item.text,kind=item.kind,timestamp=item.timestamp} end return output end
function API:ClearNotificationHistory() table.clear(state.notifications) end
function API:GetRole() return state.role end
function API:HasRole(required) required=string.lower(tostring(required or "user")); return (ROLE_LEVELS[state.role] or 1)>=(ROLE_LEVELS[required] or 1) end
function API:SetRole(role) role=string.lower(tostring(role or "user")); if not ROLE_LEVELS[role] then return false end; state.role=role; player:SetAttribute("SaltyRole",role); screenGui:SetAttribute("FeatureRole",role); return true end
function API:SetFeatureFlag(name,enabled) name=tostring(name); state.flags[name]=enabled==true; player:SetAttribute("SaltyFeatureFlags",HttpService:JSONEncode(state.flags)); return state.flags[name] end
function API:IsFeatureEnabled(name,defaultValue) local value=state.flags[tostring(name)]; if value==nil then return defaultValue~=false end; return value==true end
function API:GetFeatureFlags() local copy={}; for name,value in pairs(state.flags) do copy[name]=value end; return copy end
function API:GetUpdateChannel() return state.channel end
function API:SetUpdateChannel(channel) channel=string.lower(tostring(channel)); if channel~="stable" and channel~="beta" and channel~="dev" then return false end; state.channel=channel; player:SetAttribute("SaltyUpdateChannel",channel); screenGui:SetAttribute("UpdateChannel",channel); return true end
function API:SetTelemetryEnabled(enabled) state.telemetryEnabled=enabled==true end
function API:IsTelemetryEnabled() return state.telemetryEnabled end
function API:SetTelemetrySink(callback) state.telemetrySink=type(callback)=="function" and callback or nil end
function API:EmitTelemetry(eventName,data) if not state.telemetryEnabled or type(state.telemetrySink)~="function" then return false end; task.spawn(function() pcall(state.telemetrySink,tostring(eventName),data or {}) end); return true end

function API:SetAccent(color)
    if typeof(color)~="Color3" then return false end
    local previous=C.Accent
    C.Accent=color
    for _,item in ipairs(screenGui:GetDescendants()) do
        pcall(function()
            if (item:IsA("Frame") or item:IsA("TextButton") or item:IsA("TextBox")) and item.BackgroundColor3==previous then item.BackgroundColor3=color end
            if (item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox")) and item.TextColor3==previous then item.TextColor3=color end
            if (item:IsA("ImageLabel") or item:IsA("ImageButton")) and item.ImageColor3==previous then item.ImageColor3=color end
            if item:IsA("UIStroke") and item.Color==previous then item.Color=color end
            if item:IsA("UIGradient") then
                local points={}; local changed=false
                for _,point in ipairs(item.Color.Keypoints) do local pointColor=point.Value; if pointColor==previous then pointColor=color; changed=true end; table.insert(points,ColorSequenceKeypoint.new(point.Time,pointColor)) end
                if changed then item.Color=ColorSequence.new(points) end
            end
        end)
    end
    player:SetAttribute("SaltyAccentHex",colorToHex(color))
    return true
end
function API:GetAccent() return C.Accent end
function API:GetAccentHex() return colorToHex(C.Accent) end
function API:SetAccentHex(value) local color=hexToColor(value); if not color then return false end; return self:SetAccent(color) end
function API:SaveProfile(name) name=tostring(name or "Default"); state.backup=snapshot(); state.profiles[name]=snapshot(); saveProfiles(); return true end
function API:LoadProfile(name) local data=state.profiles[tostring(name or "Default")]; if type(data)~="table" then return false end; state.backup=snapshot(); return applySnapshot(data) end
function API:DeleteProfile(name) state.profiles[tostring(name)]=nil; saveProfiles(); return true end
function API:ListProfiles() local output={}; for name in pairs(state.profiles) do table.insert(output,name) end; table.sort(output); return output end
function API:BackupConfig() state.backup=snapshot(); return state.backup end
function API:RestoreBackup() return applySnapshot(state.backup) end

function API:RegisterCommand(name,callback,options)
    name=string.lower(tostring(name or "")); assert(name~="","Command requires a name"); assert(type(callback)=="function","Command requires callback"); options=options or {}
    state.commands[name]={callback=callback,description=tostring(options.Description or ""),role=string.lower(tostring(options.Role or "user"))}
    return state.commands[name]
end
function API:ExecuteCommand(name,...)
    name=string.lower(tostring(name or "")); local command=state.commands[name]; if not command then return false,"Unknown command: "..name end; if not self:HasRole(command.role) then return false,"Permission denied" end
    local ok,result=pcall(command.callback,self,...); if not ok then warn("[SaltyGlass] command failed:",name,result); return false,tostring(result) end; return true,result
end
function API:RunCommandLine(line) local parts={}; for token in tostring(line or ""):gmatch("%S+") do table.insert(parts,token) end; local name=table.remove(parts,1); if not name then return false,"Empty command" end; return self:ExecuteCommand(name,table.unpack(parts)) end
function API:ListCommands() local output={}; for name,command in pairs(state.commands) do table.insert(output,{name=name,description=command.description,role=command.role}) end; table.sort(output,function(a,b) return a.name<b.name end); return output end

function API:RegisterModule(name,module)
    name=tostring(name or ""); assert(name~="","Module requires a name")
    if type(module)=="function" then local ok,result=pcall(module,API); if not ok then error("SaltyGlass module failed: "..tostring(result),2) end; module=result or module elseif type(module)=="table" and type(module.Init)=="function" then local ok,err=pcall(module.Init,module,API); if not ok then error("SaltyGlass module Init failed: "..tostring(err),2) end end
    state.modules[name]=module; return module
end
function API:LoadModule(sourceOrUrl,name) assert(type(sourceOrUrl)=="string","LoadModule expects source or URL"); local source=sourceOrUrl; if sourceOrUrl:match("^https?://") then source=game:HttpGet(sourceOrUrl) end; local chunk,compileError=loadstring(source); assert(chunk,"Module failed to compile: "..tostring(compileError)); local ok,module=pcall(chunk); if not ok then error("Module failed to execute: "..tostring(module),2) end; return self:RegisterModule(name or "module",module) end
function API:GetModule(name) return state.modules[tostring(name)] end

local Section={}; Section.__index=Section
function Section:Next() self.Order+=1; return self.Order end
function Section:AddButton(options) return makeButton(self.Parent,options or {},self:Next()) end
function Section:AddToggle(options) options=options or {}; local control=makeToggle(self.Parent,options,self:Next()); if options.Id then state.controls[options.Id]=control end; return control end
function Section:AddSlider(options) options=options or {}; local control=makeSlider(self.Parent,options,self:Next()); if options.Id then state.controls[options.Id]=control end; return control end
function Section:AddTextbox(options) options=options or {}; local control=makeTextbox(self.Parent,options,self:Next()); if options.Id then state.controls[options.Id]=control end; return control end

local function buildFeature(definition)
    local id=tostring(definition.Id or definition.Name); if state.built[id] then return true end; if definition.Role and not API:HasRole(definition.Role) then return false end; if definition.Flag and not API:IsFeatureEnabled(definition.Flag,true) then return false end; if type(definition.Build)~="function" then return false end
    local parent=bodies[tostring(definition.Tab or "Visuals")]; if not parent then return false end; local order=tonumber(definition.Order) or 800; header(parent,tostring(definition.Section or definition.Name),order); local section=setmetatable({Parent=parent,Order=order},Section)
    local ok,err=pcall(definition.Build,section,API); if not ok then warn("[SaltyGlass] feature build failed:",id,err); return false end; state.built[id]=true; return true
end
function API:RegisterFeature(definition) assert(type(definition)=="table","Feature must be a table"); assert(type(definition.Name)=="string","Feature requires Name"); local id=tostring(definition.Id or definition.Name); definition.Id=id; state.features[id]=definition; buildFeature(definition); return definition end
function API:GetRegisteredFeatures() local output={}; for id,definition in pairs(state.features) do output[id]=definition end; return output end
function API:GetControl(id) return state.controls[id] end

API:RegisterCommand("notify",function(self,...) self:Notify(table.concat({...}," ")); return true end,{Description="Show a Salty notification."})
API:RegisterCommand("channel",function(self,value) if value==nil then return self:GetUpdateChannel() end; if not self:SetUpdateChannel(value) then error("channel must be stable, beta, or dev") end; self:Notify("Update channel • "..string.upper(self:GetUpdateChannel())); return self:GetUpdateChannel() end,{Description="Get/set update channel."})
API:RegisterCommand("flag",function(self,name,value) if not name then error("flag requires a name") end; if value==nil then return self:IsFeatureEnabled(name,false) end; local enabled=value==true or value=="true" or value=="1" or value=="on"; self:SetFeatureFlag(name,enabled); self:Notify("Feature flag "..tostring(name).." • "..(enabled and "ON" or "OFF")); return enabled end,{Description="Get/set feature flag.",Role="beta"})
API:RegisterCommand("profile",function(self,action,name) action=string.lower(tostring(action or "list")); name=tostring(name or state.profileName); if action=="save" then self:SaveProfile(name); return "saved "..name elseif action=="load" then if not self:LoadProfile(name) then error("profile not found: "..name) end; return "loaded "..name elseif action=="delete" then self:DeleteProfile(name); return "deleted "..name elseif action=="list" then return self:ListProfiles() end; error("profile action must be save/load/delete/list") end,{Description="Manage configuration profiles."})

if bodies.Visuals then
    header(bodies.Visuals,"ACCENT COLOR",900)
    local colorState={r=math.floor(C.Accent.R*255+0.5),g=math.floor(C.Accent.G*255+0.5),b=math.floor(C.Accent.B*255+0.5),syncing=false}
    local previewCard=card(bodies.Visuals,62,901)
    textPair(previewCard,"RGB + HEX","Live SaltyGlass accent color.",220)
    local preview=Instance.new("Frame")
    preview.AnchorPoint=Vector2.new(1,0.5); preview.Position=UDim2.new(1,-176,0.5,0); preview.Size=UDim2.fromOffset(34,34); preview.BackgroundColor3=C.Accent; preview.BorderSizePixel=0; preview.ZIndex=7; preview.Parent=previewCard; round(preview,9); stroke(preview,0.48)
    local hex=Instance.new("TextBox")
    hex.AnchorPoint=Vector2.new(1,0.5); hex.Position=UDim2.new(1,-14,0.5,0); hex.Size=UDim2.fromOffset(146,34); hex.BackgroundColor3=C.Mid; hex.BackgroundTransparency=0.28; hex.BorderSizePixel=0; hex.ClearTextOnFocus=false; hex.Font=Enum.Font.GothamBold; hex.Text=colorToHex(C.Accent); hex.TextColor3=C.Text; hex.TextSize=10; hex.TextXAlignment=Enum.TextXAlignment.Center; hex.ZIndex=7; hex.Parent=previewCard; round(hex,9); local hexStroke=stroke(hex,0.68)
    local red,green,blue
    local function applyColor(color,announce)
        colorState.syncing=true; colorState.r=math.floor(color.R*255+0.5); colorState.g=math.floor(color.G*255+0.5); colorState.b=math.floor(color.B*255+0.5); preview.BackgroundColor3=color; hex.Text=colorToHex(color)
        if red then red:Set(colorState.r,true); green:Set(colorState.g,true); blue:Set(colorState.b,true) end
        API:SetAccent(color); colorState.syncing=false; if announce then notify("Accent updated • "..colorToHex(color),"success") end
    end
    local function applyRgb() if colorState.syncing then return end; applyColor(Color3.fromRGB(colorState.r,colorState.g,colorState.b),false) end
    red=makeSlider(bodies.Visuals,{Name="Red",Description="Accent red channel.",Min=0,Max=255,Default=colorState.r,Increment=1,Callback=function(value) colorState.r=value; applyRgb() end},902)
    green=makeSlider(bodies.Visuals,{Name="Green",Description="Accent green channel.",Min=0,Max=255,Default=colorState.g,Increment=1,Callback=function(value) colorState.g=value; applyRgb() end},903)
    blue=makeSlider(bodies.Visuals,{Name="Blue",Description="Accent blue channel.",Min=0,Max=255,Default=colorState.b,Increment=1,Callback=function(value) colorState.b=value; applyRgb() end},904)
    state.controls["appearance.red"]=red; state.controls["appearance.green"]=green; state.controls["appearance.blue"]=blue
    connect(hex.Focused,function() hover(); hexStroke.Color=C.Accent; hexStroke.Transparency=0.34 end)
    connect(hex.FocusLost,function() hexStroke.Color=C.Edge; hexStroke.Transparency=0.68; local color=hexToColor(hex.Text); if color then applyColor(color,true) else hex.Text=colorToHex(C.Accent); notify("Invalid HEX color","error") end end)
    makeButton(bodies.Visuals,{Name="Reset Accent",Description="Restore the original Salty violet accent.",ButtonText="RESET",Callback=function() applyColor(Color3.fromRGB(139,124,255),true) end},905)
end

if bodies.Settings then
    header(bodies.Settings,"FUTURE SYSTEMS",900)
    local roleCard=card(bodies.Settings,54,901)
    textPair(roleCard,"Permission Role","Role supplied by key validation.",130)
    local roleLabel=Instance.new("TextLabel")
    roleLabel.AnchorPoint=Vector2.new(1,0.5); roleLabel.Position=UDim2.new(1,-14,0.5,0); roleLabel.Size=UDim2.fromOffset(104,28); roleLabel.BackgroundColor3=C.Light; roleLabel.BackgroundTransparency=0.46; roleLabel.BorderSizePixel=0; roleLabel.Font=Enum.Font.GothamBold; roleLabel.Text=string.upper(state.role); roleLabel.TextColor3=C.Accent; roleLabel.TextSize=9; roleLabel.ZIndex=6; roleLabel.Parent=roleCard; round(roleLabel,9); stroke(roleLabel,0.72)
    local channelButton
    channelButton=makeButton(bodies.Settings,{Name="Update Channel",Description="Cycle stable, beta, and dev.",ButtonText=string.upper(state.channel),Callback=function() local nextChannel=({stable="beta",beta="dev",dev="stable"})[state.channel] or "stable"; API:SetUpdateChannel(nextChannel); channelButton.Text=string.upper(nextChannel); notify("Update channel • "..string.upper(nextChannel)) end},902)
    local profileName=makeTextbox(bodies.Settings,{Name="Profile Name",Description="Name used by save/load.",Placeholder="Default",Default=state.profileName,Callback=function(value) value=tostring(value):gsub("^%s+",""):gsub("%s+$",""); state.profileName=value~="" and value or "Default" end},903)
    state.controls["system.profileName"]=profileName
    makeButton(bodies.Settings,{Name="Save Profile",Description="Save framework/custom settings.",ButtonText="SAVE",Callback=function() API:SaveProfile(state.profileName); notify("Profile saved • "..state.profileName,"success") end},904)
    makeButton(bodies.Settings,{Name="Load Profile",Description="Restore a saved profile.",ButtonText="LOAD",Callback=function() if API:LoadProfile(state.profileName) then notify("Profile loaded • "..state.profileName,"success") else notify("Profile not found • "..state.profileName,"error") end end},905)
    makeButton(bodies.Settings,{Name="Delete Profile",Description="Remove the selected saved profile.",ButtonText="DELETE",Callback=function() API:DeleteProfile(state.profileName); notify("Profile deleted • "..state.profileName) end},906)
    local telemetry=makeToggle(bodies.Settings,{Name="Telemetry Hook",Description="Opt-in callback only. No built-in endpoint.",Default=false,Callback=function(enabled) API:SetTelemetryEnabled(enabled); notify(enabled and "Telemetry hook enabled" or "Telemetry hook disabled") end},907)
    state.controls["system.telemetry"]=telemetry
    makeButton(bodies.Settings,{Name="Backup Config",Description="Create a recovery snapshot.",ButtonText="BACKUP",Callback=function() API:BackupConfig(); notify("Configuration backup created","success") end},908)
    makeButton(bodies.Settings,{Name="Restore Backup",Description="Restore the latest recovery snapshot.",ButtonText="RESTORE",Callback=function() if API:RestoreBackup() then notify("Backup restored","success") else notify("No backup available","error") end end},909)
    makeButton(bodies.Settings,{Name="Notification History",Description="Print recent Salty messages.",ButtonText="HISTORY",Callback=function() print("[SaltyGlass] Notification History"); for i,entry in ipairs(API:GetNotificationHistory()) do print(i,os.date("%H:%M:%S",entry.timestamp),entry.kind,entry.text) end; notify("Notification history printed") end},910)
    makeButton(bodies.Settings,{Name="Feature Flags",Description="Print active remote/local feature flags.",ButtonText="FLAGS",Callback=function() print("[SaltyGlass] Feature Flags"); local flags=API:GetFeatureFlags(); local names={}; for name in pairs(flags) do table.insert(names,name) end; table.sort(names); for _,name in ipairs(names) do print(name,flags[name]) end; notify(tostring(#names).." feature flag(s) printed") end},911)
    header(bodies.Settings,"COMMAND BRIDGE",920)
    local commandInput=makeTextbox(bodies.Settings,{Name="Command",Description="Run registered Salty commands.",Placeholder="channel stable",Default=""},921)
    state.controls["system.command"]=commandInput
    makeButton(bodies.Settings,{Name="Run Command",Description="Execute through the permission-aware bridge.",ButtonText="RUN",Callback=function() local ok,result=API:RunCommandLine(commandInput:Get()); if ok then notify(result~=nil and "Command complete • "..tostring(result) or "Command complete","success") else notify(tostring(result),"error") end end},922)
    makeButton(bodies.Settings,{Name="List Commands",Description="Print registered framework commands.",ButtonText="LIST",Callback=function() print("[SaltyGlass] Commands"); for _,command in ipairs(API:ListCommands()) do print(command.name,"["..command.role.."]",command.description) end; notify(tostring(#API:ListCommands()).." command(s) printed") end},923)
end

_G.SaltyGlass=API
pcall(function() if type(getgenv)=="function" then getgenv().SaltyGlass=API end end)
screenGui:SetAttribute("FrameworkReady",true)
screenGui:SetAttribute("FrameworkVersion",API.Version)
screenGui:SetAttribute("FeatureRole",state.role)
screenGui:SetAttribute("UpdateChannel",state.channel)
connect(screenGui.Destroying,function()
    if state.destroyed then return end
    state.destroyed=true
    for _,connection in ipairs(state.connections) do pcall(function() connection:Disconnect() end) end
    if _G.SaltyGlass==API then _G.SaltyGlass=nil end
    pcall(function() if type(getgenv)=="function" and getgenv().SaltyGlass==API then getgenv().SaltyGlass=nil end end)
end)
notify("Framework 2.1 + RGB/HEX ready","success")
return API
