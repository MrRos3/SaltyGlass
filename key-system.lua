local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
if not player then error("SaltyGlass Key System must run on the Roblox client.",0) end
local playerGui=player:WaitForChild("PlayerGui")

local KeySystem={Version="1.0.1"}

local DEFAULTS={
    Title="SALTYGLASS",
    Subtitle="ACCESS GATE",
    Description="Enter your access key to continue.",
    Placeholder="Enter access key...",
    Accent=Color3.fromRGB(139,124,255),
    Keys={"SALTY-ACCESS"},
    Sounds=true,
    Blur=true,
    ReduceMotion=false,
    MaxAttempts=0,
    SuccessDelay=0.25,
    ToggleKey=Enum.KeyCode.RightShift,
    ClickSoundId="rbxassetid://4307186075",
    HoverSoundId="rbxassetid://408524543",
}

local COLORS={
    GlassBase=Color3.fromRGB(9,13,24),
    GlassMid=Color3.fromRGB(17,24,42),
    GlassLight=Color3.fromRGB(27,36,64),
    Edge=Color3.new(1,1,1),
    Text=Color3.new(1,1,1),
    SubText=Color3.fromRGB(181,188,211),
    Muted=Color3.fromRGB(111,120,149),
    Success=Color3.fromRGB(109,255,168),
    Danger=Color3.fromRGB(255,107,122),
}

local function merge(options)
    local out={}
    for k,v in pairs(DEFAULTS) do out[k]=v end
    if type(options)=="table" then
        for k,v in pairs(options) do out[k]=v end
    end
    return out
end

local function round(obj,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,r)
    c.Parent=obj
    return c
end

local function addStroke(obj,t,thickness)
    local s=Instance.new("UIStroke")
    s.Color=COLORS.Edge
    s.Transparency=t or 0.7
    s.Thickness=thickness or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Parent=obj
    return s
end

local function tw(obj,d,props)
    local t=TweenService:Create(obj,TweenInfo.new(d,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
    t:Play()
    return t
end

local function sound(config,id,vol)
    if not config.Sounds or not id or id=="" then return end
    pcall(function()
        local s=Instance.new("Sound")
        s.Name="SaltyUISound"
        s.SoundId=id
        s.Volume=vol or 0.2
        s.Parent=SoundService
        s:Play()
        s.Ended:Connect(function() if s.Parent then s:Destroy() end end)
        task.delay(3,function() if s.Parent then s:Destroy() end end)
    end)
end

local function loadIcons()
    local icons={}
    local ok,result=pcall(function()
        local src=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/icons/Lucide.lua")
        local fn,err=loadstring(src)
        if not fn then error(err,0) end
        return fn()
    end)
    if ok and type(result)=="table" then icons=result end
    return icons
end

local function icon(parent,icons,name,size,color,z)
    local img=Instance.new("ImageLabel")
    img.Name="Lucide_"..name
    img.BackgroundTransparency=1
    img.Size=UDim2.fromOffset(size,size)
    img.Image=icons[name] or ""
    img.ImageColor3=color or COLORS.Text
    img.ScaleType=Enum.ScaleType.Fit
    img.ZIndex=z or 10
    img:SetAttribute("LucideName",name)
    img.Parent=parent
    return img
end

local function makeKeySet(config)
    local set={}
    if type(config.Key)=="string" then set[config.Key]=true end
    if type(config.Keys)=="table" then
        for _,value in ipairs(config.Keys) do
            if type(value)=="string" then set[value]=true end
        end
    end
    return set
end

function KeySystem.Open(options)
    local config=merge(options)
    local icons=loadIcons()
    local keySet=makeKeySet(config)

    local old=playerGui:FindFirstChild("SaltyKeySystemGui")
    if old then old:Destroy() end
    local oldBlur=Lighting:FindFirstChild("SaltyKeySystemBlur")
    if oldBlur then oldBlur:Destroy() end

    local state={destroyed=false,busy=false,attempts=0,connections={}}

    local blur=Instance.new("BlurEffect")
    blur.Name="SaltyKeySystemBlur"
    blur.Size=config.Blur and 18 or 0
    blur.Parent=Lighting

    local gui=Instance.new("ScreenGui")
    gui.Name="SaltyKeySystemGui"
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=playerGui

    local backdrop=Instance.new("TextButton")
    backdrop.Name="BackdropInputSink"
    backdrop.Size=UDim2.fromScale(1,1)
    backdrop.BackgroundColor3=Color3.new(0,0,0)
    backdrop.BackgroundTransparency=0.34
    backdrop.BorderSizePixel=0
    backdrop.Text=""
    backdrop.AutoButtonColor=false
    backdrop.Active=true
    backdrop.ZIndex=1
    backdrop.Parent=gui

    local card=Instance.new("Frame")
    card.Name="KeyCard"
    card.AnchorPoint=Vector2.new(0.5,0.5)
    card.Position=UDim2.fromScale(0.5,0.5)
    card.Size=UDim2.fromOffset(500,314)
    card.BackgroundColor3=COLORS.GlassBase
    card.BackgroundTransparency=0.08
    card.BorderSizePixel=0
    card.ClipsDescendants=true
    card.ZIndex=4
    card.Parent=gui
    round(card,28)
    local cardStroke=addStroke(card,0.42,1.5)

    local grad=Instance.new("UIGradient")
    grad.Rotation=55
    grad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(40,52,84)),
        ColorSequenceKeypoint.new(0.34,COLORS.GlassMid),
        ColorSequenceKeypoint.new(0.72,COLORS.GlassBase),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(7,10,17)),
    })
    grad.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.18),
        NumberSequenceKeypoint.new(0.4,0.56),
        NumberSequenceKeypoint.new(1,0.88),
    })
    grad.Parent=card

    local shine=Instance.new("Frame")
    shine.Position=UDim2.fromOffset(32,1)
    shine.Size=UDim2.new(1,-64,0,1)
    shine.BackgroundColor3=COLORS.Edge
    shine.BackgroundTransparency=0.83
    shine.BorderSizePixel=0
    shine.ZIndex=7
    shine.Parent=card

    local accentLine=Instance.new("Frame")
    accentLine.Position=UDim2.fromOffset(32,2)
    accentLine.Size=UDim2.new(1,-64,0,1)
    accentLine.BackgroundColor3=config.Accent
    accentLine.BackgroundTransparency=0.24
    accentLine.BorderSizePixel=0
    accentLine.ZIndex=7
    accentLine.Parent=card

    local iconHolder=Instance.new("Frame")
    iconHolder.Position=UDim2.fromOffset(28,28)
    iconHolder.Size=UDim2.fromOffset(46,46)
    iconHolder.BackgroundColor3=config.Accent
    iconHolder.BackgroundTransparency=0.84
    iconHolder.BorderSizePixel=0
    iconHolder.ZIndex=7
    iconHolder.Parent=card
    round(iconHolder,14)
    addStroke(iconHolder,0.62)

    local keyIcon=icon(iconHolder,icons,"key",20,config.Accent,8)
    keyIcon.AnchorPoint=Vector2.new(0.5,0.5)
    keyIcon.Position=UDim2.fromScale(0.5,0.5)

    local title=Instance.new("TextLabel")
    title.Position=UDim2.fromOffset(88,26)
    title.Size=UDim2.new(1,-116,0,25)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.GothamBold
    title.Text=config.Title
    title.TextColor3=COLORS.Text
    title.TextSize=18
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=8
    title.Parent=card

    local subtitle=Instance.new("TextLabel")
    subtitle.Position=UDim2.fromOffset(88,50)
    subtitle.Size=UDim2.new(1,-116,0,18)
    subtitle.BackgroundTransparency=1
    subtitle.Font=Enum.Font.GothamMedium
    subtitle.Text=config.Subtitle
    subtitle.TextColor3=config.Accent
    subtitle.TextSize=9
    subtitle.TextXAlignment=Enum.TextXAlignment.Left
    subtitle.ZIndex=8
    subtitle.Parent=card

    local desc=Instance.new("TextLabel")
    desc.Position=UDim2.fromOffset(28,88)
    desc.Size=UDim2.new(1,-56,0,20)
    desc.BackgroundTransparency=1
    desc.Font=Enum.Font.Gotham
    desc.Text=config.Description
    desc.TextColor3=COLORS.SubText
    desc.TextSize=10
    desc.TextXAlignment=Enum.TextXAlignment.Left
    desc.ZIndex=8
    desc.Parent=card

    local inputHolder=Instance.new("Frame")
    inputHolder.Position=UDim2.fromOffset(28,122)
    inputHolder.Size=UDim2.new(1,-56,0,50)
    inputHolder.BackgroundColor3=COLORS.GlassMid
    inputHolder.BackgroundTransparency=0.42
    inputHolder.BorderSizePixel=0
    inputHolder.ZIndex=7
    inputHolder.Parent=card
    round(inputHolder,13)
    local inputStroke=addStroke(inputHolder,0.72)

    local lockIcon=icon(inputHolder,icons,"lock",16,COLORS.Muted,9)
    lockIcon.AnchorPoint=Vector2.new(0,0.5)
    lockIcon.Position=UDim2.new(0,15,0.5,0)

    local input=Instance.new("TextBox")
    input.Position=UDim2.fromOffset(44,0)
    input.Size=UDim2.new(1,-58,1,0)
    input.BackgroundTransparency=1
    input.ClearTextOnFocus=false
    input.Font=Enum.Font.GothamMedium
    input.PlaceholderText=config.Placeholder
    input.PlaceholderColor3=COLORS.Muted
    input.Text=""
    input.TextColor3=COLORS.Text
    input.TextSize=11
    input.TextXAlignment=Enum.TextXAlignment.Left
    input.ZIndex=9
    input.Parent=inputHolder

    local status=Instance.new("TextLabel")
    status.Position=UDim2.fromOffset(28,181)
    status.Size=UDim2.new(1,-56,0,18)
    status.BackgroundTransparency=1
    status.Font=Enum.Font.GothamMedium
    status.Text="Ready for verification"
    status.TextColor3=COLORS.Muted
    status.TextSize=9
    status.TextXAlignment=Enum.TextXAlignment.Left
    status.ZIndex=8
    status.Parent=card

    local verify=Instance.new("TextButton")
    verify.Position=UDim2.fromOffset(28,211)
    verify.Size=UDim2.new(1,-56,0,48)
    verify.BackgroundColor3=config.Accent
    verify.BackgroundTransparency=0.12
    verify.BorderSizePixel=0
    verify.AutoButtonColor=false
    verify.Font=Enum.Font.GothamBold
    verify.Text="VERIFY KEY"
    verify.TextColor3=COLORS.Text
    verify.TextSize=10
    verify.ZIndex=8
    verify.Parent=card
    round(verify,13)
    local verifyStroke=addStroke(verify,0.52)

    local footer=Instance.new("TextLabel")
    footer.Position=UDim2.fromOffset(28,270)
    footer.Size=UDim2.new(1,-56,0,18)
    footer.BackgroundTransparency=1
    footer.Font=Enum.Font.Gotham
    footer.Text="SALTYGLASS • SECURE ACCESS"
    footer.TextColor3=COLORS.Muted
    footer.TextSize=8
    footer.TextXAlignment=Enum.TextXAlignment.Center
    footer.ZIndex=8
    footer.Parent=card

    local function connect(signal,callback)
        local c=signal:Connect(callback)
        table.insert(state.connections,c)
        return c
    end

    local function setStatus(text,color)
        status.Text=text
        status.TextColor3=color or COLORS.Muted
    end

    local function destroy()
        if state.destroyed then return end
        state.destroyed=true
        for _,c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
        if blur and blur.Parent then
            if config.ReduceMotion then blur.Size=0 else tw(blur,0.16,{Size=0}) end
        end
        if gui and gui.Parent then gui:Destroy() end
        task.delay(0.18,function() if blur and blur.Parent then blur:Destroy() end end)
    end

    local function fail(text)
        state.busy=false
        setStatus(text or "Invalid key",COLORS.Danger)
        inputStroke.Color=COLORS.Danger
        lockIcon.ImageColor3=COLORS.Danger
        sound(config,config.ClickSoundId,0.22)
        if not config.ReduceMotion then
            local base=card.Position
            tw(card,0.05,{Position=base+UDim2.fromOffset(-6,0)})
            task.delay(0.05,function() if card.Parent then tw(card,0.05,{Position=base+UDim2.fromOffset(6,0)}) end end)
            task.delay(0.10,function() if card.Parent then tw(card,0.06,{Position=base}) end end)
        end
        task.delay(0.7,function()
            if inputStroke.Parent then inputStroke.Color=COLORS.Edge end
            if lockIcon.Parent then lockIcon.ImageColor3=COLORS.Muted end
        end)
    end

    local function success()
        state.busy=true
        setStatus("Access granted • launching SaltyGlass",COLORS.Success)
        inputStroke.Color=COLORS.Success
        verify.BackgroundColor3=COLORS.Success
        verify.TextColor3=COLORS.GlassBase
        verify.Text="ACCESS GRANTED"
        sound(config,config.ClickSoundId,0.30)
        task.delay(config.SuccessDelay,function()
            if state.destroyed then return end
            local cb=config.OnSuccess
            destroy()
            if type(cb)=="function" then task.spawn(cb) end
        end)
    end

    local function verifyKey()
        if state.busy then return end
        local entered=input.Text
        if entered=="" then fail("Enter a key first") return end

        state.busy=true
        state.attempts=state.attempts+1
        setStatus("Checking key...",config.Accent)
        sound(config,config.ClickSoundId,0.28)

        task.delay(config.ReduceMotion and 0 or 0.12,function()
            if state.destroyed then return end
            local valid=keySet[entered]==true
            if type(config.Validator)=="function" then
                local ok,result=pcall(config.Validator,entered)
                valid=ok and result==true
            end
            if valid then success() return end
            if config.MaxAttempts>0 and state.attempts>=config.MaxAttempts then
                fail("Too many attempts")
                verify.Active=false
                input.TextEditable=false
                return
            end
            fail("Invalid key • try again")
        end)
    end

    connect(input.Focused,function()
        inputStroke.Color=config.Accent
        lockIcon.ImageColor3=config.Accent
    end)

    connect(input.FocusLost,function(enterPressed)
        if not state.busy then
            inputStroke.Color=COLORS.Edge
            lockIcon.ImageColor3=COLORS.Muted
        end
        if enterPressed then verifyKey() end
    end)

    connect(verify.MouseEnter,function()
        sound(config,config.HoverSoundId,0.10)
        if not state.busy then
            tw(verify,0.12,{BackgroundTransparency=0.02})
            verifyStroke.Transparency=0.34
        end
    end)

    connect(verify.MouseLeave,function()
        if not state.busy then
            tw(verify,0.12,{BackgroundTransparency=0.12})
            verifyStroke.Transparency=0.52
        end
    end)

    connect(verify.MouseButton1Click,verifyKey)

    connect(UserInputService.InputBegan,function(userInput,processed)
        if processed or state.destroyed then return end
        if userInput.KeyCode==config.ToggleKey then
            local visible=not card.Visible
            card.Visible=visible
            backdrop.Visible=visible
            if config.Blur then blur.Size=visible and 18 or 0 end
        end
    end)

    if not config.ReduceMotion then
        local final=card.Position
        card.Position=final+UDim2.fromOffset(0,10)
        card.BackgroundTransparency=1
        cardStroke.Transparency=1
        tw(card,0.22,{Position=final,BackgroundTransparency=0.08})
        tw(cardStroke,0.22,{Transparency=0.42})
    end

    local handle={}
    function handle:Destroy() destroy() end
    function handle:Verify() verifyKey() end
    function handle:SetStatus(text,color) setStatus(text,color) end
    function handle:GetScreenGui() return gui end
    return handle
end

return KeySystem
