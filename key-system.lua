local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
if not player then error("SaltyGlass Key System must run on the Roblox client.",0) end
local playerGui=player:WaitForChild("PlayerGui")

local KeySystem={Version="1.1.0"}

local DEFAULTS={
    Title="SALTYGLASS",
    Subtitle="SECURE ACCESS",
    Description="Enter your access key to unlock the interface.",
    Placeholder="Enter access key...",
    Accent=Color3.fromRGB(139,124,255),
    Keys={"SALTY-ACCESS"},
    Sounds=true,
    Blur=true,
    ReduceMotion=false,
    MaxAttempts=0,
    SuccessDelay=0.34,
    ToggleKey=Enum.KeyCode.RightShift,
    ClickSoundId="rbxassetid://4307186075",
    HoverSoundId="rbxassetid://408524543",
}

local COLORS={
    Base=Color3.fromRGB(9,13,24),
    Mid=Color3.fromRGB(17,24,42),
    Light=Color3.fromRGB(27,36,64),
    Edge=Color3.new(1,1,1),
    Text=Color3.new(1,1,1),
    Sub=Color3.fromRGB(181,188,211),
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

local function stroke(obj,transparency,thickness,color)
    local s=Instance.new("UIStroke")
    s.Color=color or COLORS.Edge
    s.Transparency=transparency or 0.7
    s.Thickness=thickness or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Parent=obj
    return s
end

local function scale(obj)
    local s=Instance.new("UIScale")
    s.Scale=1
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

    local state={destroyed=false,busy=false,attempts=0,connections={},statusToken=0}

    local blur=Instance.new("BlurEffect")
    blur.Name="SaltyKeySystemBlur"
    blur.Size=config.Blur and 22 or 0
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
    backdrop.BackgroundTransparency=0.30
    backdrop.BorderSizePixel=0
    backdrop.Text=""
    backdrop.AutoButtonColor=false
    backdrop.Active=true
    backdrop.ZIndex=1
    backdrop.Parent=gui

    local cardGlow=Instance.new("Frame")
    cardGlow.Name="CardGlow"
    cardGlow.AnchorPoint=Vector2.new(0.5,0.5)
    cardGlow.Position=UDim2.fromScale(0.5,0.5)
    cardGlow.Size=UDim2.fromOffset(536,376)
    cardGlow.BackgroundColor3=config.Accent
    cardGlow.BackgroundTransparency=0.93
    cardGlow.BorderSizePixel=0
    cardGlow.ZIndex=2
    cardGlow.Parent=gui
    round(cardGlow,34)

    local card=Instance.new("Frame")
    card.Name="KeyCard"
    card.AnchorPoint=Vector2.new(0.5,0.5)
    card.Position=UDim2.fromScale(0.5,0.5)
    card.Size=UDim2.fromOffset(520,360)
    card.BackgroundColor3=COLORS.Base
    card.BackgroundTransparency=0.06
    card.BorderSizePixel=0
    card.ClipsDescendants=true
    card.ZIndex=4
    card.Parent=gui
    round(card,30)
    local cardStroke=stroke(card,0.38,1.4)
    local cardScale=scale(card)

    local glass=Instance.new("UIGradient")
    glass.Rotation=48
    glass.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(42,53,86)),ColorSequenceKeypoint.new(0.32,COLORS.Mid),ColorSequenceKeypoint.new(0.72,COLORS.Base),ColorSequenceKeypoint.new(1,Color3.fromRGB(6,9,16))})
    glass.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.14),NumberSequenceKeypoint.new(0.38,0.50),NumberSequenceKeypoint.new(1,0.88)})
    glass.Parent=card

    local ambientA=Instance.new("Frame")
    ambientA.AnchorPoint=Vector2.new(0.5,0.5)
    ambientA.Position=UDim2.fromOffset(94,90)
    ambientA.Size=UDim2.fromOffset(178,178)
    ambientA.BackgroundColor3=config.Accent
    ambientA.BackgroundTransparency=0.91
    ambientA.BorderSizePixel=0
    ambientA.ZIndex=5
    ambientA.Parent=card
    round(ambientA,90)

    local ambientB=Instance.new("Frame")
    ambientB.AnchorPoint=Vector2.new(0.5,0.5)
    ambientB.Position=UDim2.new(1,-40,1,-12)
    ambientB.Size=UDim2.fromOffset(210,210)
    ambientB.BackgroundColor3=Color3.fromRGB(93,231,255)
    ambientB.BackgroundTransparency=0.965
    ambientB.BorderSizePixel=0
    ambientB.ZIndex=5
    ambientB.Parent=card
    round(ambientB,110)

    local sweep=Instance.new("Frame")
    sweep.Name="GlassSweep"
    sweep.AnchorPoint=Vector2.new(0.5,0.5)
    sweep.Position=UDim2.new(-0.25,0,0.5,0)
    sweep.Size=UDim2.fromOffset(90,620)
    sweep.Rotation=18
    sweep.BackgroundColor3=COLORS.Edge
    sweep.BackgroundTransparency=0.965
    sweep.BorderSizePixel=0
    sweep.ZIndex=6
    sweep.Parent=card
    local sweepGradient=Instance.new("UIGradient")
    sweepGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.25),NumberSequenceKeypoint.new(1,1)})
    sweepGradient.Parent=sweep

    local emblemHalo=Instance.new("Frame")
    emblemHalo.Position=UDim2.fromOffset(28,26)
    emblemHalo.Size=UDim2.fromOffset(60,60)
    emblemHalo.BackgroundColor3=config.Accent
    emblemHalo.BackgroundTransparency=0.91
    emblemHalo.BorderSizePixel=0
    emblemHalo.ZIndex=7
    emblemHalo.Parent=card
    round(emblemHalo,18)

    local emblem=Instance.new("Frame")
    emblem.AnchorPoint=Vector2.new(0.5,0.5)
    emblem.Position=UDim2.fromScale(0.5,0.5)
    emblem.Size=UDim2.fromOffset(48,48)
    emblem.BackgroundColor3=COLORS.Light
    emblem.BackgroundTransparency=0.16
    emblem.BorderSizePixel=0
    emblem.ZIndex=8
    emblem.Parent=emblemHalo
    round(emblem,15)
    local emblemStroke=stroke(emblem,0.48,1)
    local keyIcon=icon(emblem,icons,"key",21,config.Accent,10)
    keyIcon.AnchorPoint=Vector2.new(0.5,0.5)
    keyIcon.Position=UDim2.fromScale(0.5,0.5)

    local title=Instance.new("TextLabel")
    title.Position=UDim2.fromOffset(104,27)
    title.Size=UDim2.new(1,-238,0,24)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.GothamBold
    title.Text=config.Title
    title.TextColor3=COLORS.Text
    title.TextSize=18
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=9
    title.Parent=card

    local subtitle=Instance.new("TextLabel")
    subtitle.Position=UDim2.fromOffset(104,52)
    subtitle.Size=UDim2.new(1,-238,0,16)
    subtitle.BackgroundTransparency=1
    subtitle.Font=Enum.Font.GothamBold
    subtitle.Text=config.Subtitle
    subtitle.TextColor3=config.Accent
    subtitle.TextSize=8
    subtitle.TextXAlignment=Enum.TextXAlignment.Left
    subtitle.ZIndex=9
    subtitle.Parent=card

    local secureBadge=Instance.new("Frame")
    secureBadge.AnchorPoint=Vector2.new(1,0)
    secureBadge.Position=UDim2.new(1,-28,0,33)
    secureBadge.Size=UDim2.fromOffset(112,30)
    secureBadge.BackgroundColor3=COLORS.Light
    secureBadge.BackgroundTransparency=0.48
    secureBadge.BorderSizePixel=0
    secureBadge.ZIndex=8
    secureBadge.Parent=card
    round(secureBadge,10)
    stroke(secureBadge,0.70,1)
    local shieldIcon=icon(secureBadge,icons,"shield-check",13,config.Accent,10)
    shieldIcon.AnchorPoint=Vector2.new(0,0.5)
    shieldIcon.Position=UDim2.new(0,10,0.5,0)
    local badgeText=Instance.new("TextLabel")
    badgeText.Position=UDim2.fromOffset(31,0)
    badgeText.Size=UDim2.new(1,-38,1,0)
    badgeText.BackgroundTransparency=1
    badgeText.Font=Enum.Font.GothamBold
    badgeText.Text="PROTECTED"
    badgeText.TextColor3=COLORS.Sub
    badgeText.TextSize=8
    badgeText.TextXAlignment=Enum.TextXAlignment.Left
    badgeText.ZIndex=10
    badgeText.Parent=secureBadge

    local desc=Instance.new("TextLabel")
    desc.Position=UDim2.fromOffset(28,102)
    desc.Size=UDim2.new(1,-56,0,20)
    desc.BackgroundTransparency=1
    desc.Font=Enum.Font.Gotham
    desc.Text=config.Description
    desc.TextColor3=COLORS.Sub
    desc.TextSize=10
    desc.TextXAlignment=Enum.TextXAlignment.Left
    desc.ZIndex=9
    desc.Parent=card

    local inputShell=Instance.new("Frame")
    inputShell.Position=UDim2.fromOffset(28,136)
    inputShell.Size=UDim2.new(1,-56,0,56)
    inputShell.BackgroundColor3=COLORS.Mid
    inputShell.BackgroundTransparency=0.30
    inputShell.BorderSizePixel=0
    inputShell.ZIndex=8
    inputShell.Parent=card
    round(inputShell,15)
    local inputStroke=stroke(inputShell,0.66,1)
    local inputInner=Instance.new("Frame")
    inputInner.Position=UDim2.fromOffset(1,1)
    inputInner.Size=UDim2.new(1,-2,1,-2)
    inputInner.BackgroundColor3=COLORS.Base
    inputInner.BackgroundTransparency=0.54
    inputInner.BorderSizePixel=0
    inputInner.ZIndex=8
    inputInner.Parent=inputShell
    round(inputInner,14)
    local lockIcon=icon(inputInner,icons,"lock-keyhole",17,COLORS.Muted,10)
    if lockIcon.Image=="" then lockIcon.Image=icons["lock"] or "" lockIcon:SetAttribute("LucideName","lock") end
    lockIcon.AnchorPoint=Vector2.new(0,0.5)
    lockIcon.Position=UDim2.new(0,16,0.5,0)
    local input=Instance.new("TextBox")
    input.Position=UDim2.fromOffset(48,0)
    input.Size=UDim2.new(1,-128,1,0)
    input.BackgroundTransparency=1
    input.ClearTextOnFocus=false
    input.Font=Enum.Font.GothamMedium
    input.PlaceholderText=config.Placeholder
    input.PlaceholderColor3=COLORS.Muted
    input.Text=""
    input.TextColor3=COLORS.Text
    input.TextSize=11
    input.TextXAlignment=Enum.TextXAlignment.Left
    input.ZIndex=10
    input.Parent=inputInner
    local inputChip=Instance.new("Frame")
    inputChip.AnchorPoint=Vector2.new(1,0.5)
    inputChip.Position=UDim2.new(1,-10,0.5,0)
    inputChip.Size=UDim2.fromOffset(66,26)
    inputChip.BackgroundColor3=config.Accent
    inputChip.BackgroundTransparency=0.88
    inputChip.BorderSizePixel=0
    inputChip.ZIndex=10
    inputChip.Parent=inputInner
    round(inputChip,9)
    local inputChipText=Instance.new("TextLabel")
    inputChipText.Size=UDim2.fromScale(1,1)
    inputChipText.BackgroundTransparency=1
    inputChipText.Font=Enum.Font.GothamBold
    inputChipText.Text="KEY"
    inputChipText.TextColor3=config.Accent
    inputChipText.TextSize=8
    inputChipText.ZIndex=11
    inputChipText.Parent=inputChip

    local statusPill=Instance.new("Frame")
    statusPill.Position=UDim2.fromOffset(28,204)
    statusPill.Size=UDim2.new(1,-56,0,34)
    statusPill.BackgroundColor3=COLORS.Light
    statusPill.BackgroundTransparency=0.66
    statusPill.BorderSizePixel=0
    statusPill.ZIndex=8
    statusPill.Parent=card
    round(statusPill,11)
    local statusStroke=stroke(statusPill,0.83,1)
    local statusDot=Instance.new("Frame")
    statusDot.AnchorPoint=Vector2.new(0,0.5)
    statusDot.Position=UDim2.new(0,12,0.5,0)
    statusDot.Size=UDim2.fromOffset(6,6)
    statusDot.BackgroundColor3=config.Accent
    statusDot.BackgroundTransparency=0.10
    statusDot.BorderSizePixel=0
    statusDot.ZIndex=10
    statusDot.Parent=statusPill
    round(statusDot,6)
    local status=Instance.new("TextLabel")
    status.Position=UDim2.fromOffset(28,0)
    status.Size=UDim2.new(1,-40,1,0)
    status.BackgroundTransparency=1
    status.Font=Enum.Font.GothamMedium
    status.Text="Ready for verification"
    status.TextColor3=COLORS.Sub
    status.TextSize=9
    status.TextXAlignment=Enum.TextXAlignment.Left
    status.ZIndex=10
    status.Parent=statusPill

    local verify=Instance.new("TextButton")
    verify.Position=UDim2.fromOffset(28,250)
    verify.Size=UDim2.new(1,-56,0,54)
    verify.BackgroundColor3=config.Accent
    verify.BackgroundTransparency=0.10
    verify.BorderSizePixel=0
    verify.AutoButtonColor=false
    verify.Text=""
    verify.ZIndex=8
    verify.Parent=card
    round(verify,15)
    local verifyStroke=stroke(verify,0.48,1)
    local verifyScale=scale(verify)
    local verifyGradient=Instance.new("UIGradient")
    verifyGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,config.Accent),ColorSequenceKeypoint.new(0.55,config.Accent:Lerp(Color3.new(1,1,1),0.10)),ColorSequenceKeypoint.new(1,config.Accent:Lerp(Color3.fromRGB(93,231,255),0.16))})
    verifyGradient.Parent=verify
    local verifyText=Instance.new("TextLabel")
    verifyText.AnchorPoint=Vector2.new(0.5,0.5)
    verifyText.Position=UDim2.new(0.5,-8,0.5,0)
    verifyText.Size=UDim2.fromOffset(150,24)
    verifyText.BackgroundTransparency=1
    verifyText.Font=Enum.Font.GothamBold
    verifyText.Text="VERIFY KEY"
    verifyText.TextColor3=COLORS.Text
    verifyText.TextSize=10
    verifyText.ZIndex=10
    verifyText.Parent=verify
    local arrowIcon=icon(verify,icons,"arrow-right",15,COLORS.Text,10)
    arrowIcon.AnchorPoint=Vector2.new(0.5,0.5)
    arrowIcon.Position=UDim2.new(0.5,58,0.5,0)

    local footerIcon=icon(card,icons,"shield",11,COLORS.Muted,9)
    footerIcon.AnchorPoint=Vector2.new(0.5,0.5)
    footerIcon.Position=UDim2.new(0.5,-74,1,-27)
    local footer=Instance.new("TextLabel")
    footer.AnchorPoint=Vector2.new(0.5,0.5)
    footer.Position=UDim2.new(0.5,16,1,-27)
    footer.Size=UDim2.fromOffset(170,18)
    footer.BackgroundTransparency=1
    footer.Font=Enum.Font.Gotham
    footer.Text="SALTYGLASS  /  SECURE SESSION"
    footer.TextColor3=COLORS.Muted
    footer.TextSize=7
    footer.TextXAlignment=Enum.TextXAlignment.Center
    footer.ZIndex=9
    footer.Parent=card

    local function connect(signal,callback)
        local c=signal:Connect(callback)
        table.insert(state.connections,c)
        return c
    end

    local function setStatus(text,color)
        state.statusToken=state.statusToken+1
        status.Text=text
        status.TextColor3=color or COLORS.Sub
        statusDot.BackgroundColor3=color or config.Accent
        if not config.ReduceMotion then
            status.TextTransparency=0.45
            tw(status,0.14,{TextTransparency=0})
            tw(statusDot,0.14,{BackgroundTransparency=0.04})
        end
    end

    local function destroy()
        if state.destroyed then return end
        state.destroyed=true
        for _,c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
        if blur and blur.Parent then if config.ReduceMotion then blur.Size=0 else tw(blur,0.18,{Size=0}) end end
        if gui and gui.Parent then gui:Destroy() end
        task.delay(0.20,function() if blur and blur.Parent then blur:Destroy() end end)
    end

    local function fail(message)
        state.busy=false
        setStatus(message or "Invalid key",COLORS.Danger)
        inputStroke.Color=COLORS.Danger
        inputStroke.Transparency=0.28
        lockIcon.ImageColor3=COLORS.Danger
        statusStroke.Color=COLORS.Danger
        statusStroke.Transparency=0.62
        sound(config,config.ClickSoundId,0.22)
        if not config.ReduceMotion then
            local base=card.Position
            tw(card,0.055,{Position=base+UDim2.fromOffset(-7,0)})
            task.delay(0.055,function() if card.Parent then tw(card,0.055,{Position=base+UDim2.fromOffset(7,0)}) end end)
            task.delay(0.11,function() if card.Parent then tw(card,0.07,{Position=base}) end end)
        end
        task.delay(0.72,function()
            if state.destroyed then return end
            if inputStroke.Parent then inputStroke.Color=COLORS.Edge inputStroke.Transparency=0.66 end
            if lockIcon.Parent then lockIcon.ImageColor3=COLORS.Muted end
            if statusStroke.Parent then statusStroke.Color=COLORS.Edge statusStroke.Transparency=0.83 end
        end)
    end

    local function success()
        state.busy=true
        setStatus("Access granted  /  opening SaltyGlass",COLORS.Success)
        inputStroke.Color=COLORS.Success
        inputStroke.Transparency=0.28
        lockIcon.Image=icons["lock-open"] or lockIcon.Image
        lockIcon.ImageColor3=COLORS.Success
        statusStroke.Color=COLORS.Success
        statusStroke.Transparency=0.58
        verify.BackgroundColor3=COLORS.Success
        verifyText.Text="ACCESS GRANTED"
        verifyText.TextColor3=COLORS.Base
        arrowIcon.Image=icons["check"] or icons["circle-check-big"] or arrowIcon.Image
        arrowIcon.ImageColor3=COLORS.Base
        verifyGradient.Enabled=false
        sound(config,config.ClickSoundId,0.30)
        if not config.ReduceMotion then
            tw(verifyScale,0.12,{Scale=1.018})
            tw(emblemHalo,0.18,{BackgroundTransparency=0.78})
            tw(keyIcon,0.18,{ImageColor3=COLORS.Success})
            task.delay(0.13,function() if verifyScale.Parent then tw(verifyScale,0.12,{Scale=1}) end end)
        end
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
        if entered=="" then fail("Enter an access key first") return end
        state.busy=true
        state.attempts=state.attempts+1
        setStatus("Verifying encrypted access...",config.Accent)
        sound(config,config.ClickSoundId,0.28)
        if not config.ReduceMotion then
            tw(verifyScale,0.08,{Scale=0.985})
            task.delay(0.08,function() if verifyScale.Parent then tw(verifyScale,0.10,{Scale=1}) end end)
        end
        task.delay(config.ReduceMotion and 0 or 0.16,function()
            if state.destroyed then return end
            local valid=keySet[entered]==true
            if type(config.Validator)=="function" then
                local ok,result=pcall(config.Validator,entered)
                valid=ok and result==true
            end
            if valid then success() return end
            if config.MaxAttempts>0 and state.attempts>=config.MaxAttempts then
                fail("Access locked  /  maximum attempts reached")
                verify.Active=false
                input.TextEditable=false
                return
            end
            fail("Invalid key  /  please try again")
        end)
    end

    connect(input.Focused,function()
        inputStroke.Color=config.Accent
        inputStroke.Transparency=0.28
        lockIcon.ImageColor3=config.Accent
        tw(inputShell,0.14,{BackgroundTransparency=0.18})
        tw(inputChip,0.14,{BackgroundTransparency=0.80})
    end)
    connect(input.FocusLost,function(enterPressed)
        if not state.busy then
            inputStroke.Color=COLORS.Edge
            inputStroke.Transparency=0.66
            lockIcon.ImageColor3=COLORS.Muted
            tw(inputShell,0.14,{BackgroundTransparency=0.30})
            tw(inputChip,0.14,{BackgroundTransparency=0.88})
        end
        if enterPressed then verifyKey() end
    end)
    connect(verify.MouseEnter,function()
        sound(config,config.HoverSoundId,0.10)
        if not state.busy then
            tw(verify,0.12,{BackgroundTransparency=0.01})
            tw(verifyScale,0.12,{Scale=1.012})
            verifyStroke.Transparency=0.30
            tw(arrowIcon,0.12,{Position=UDim2.new(0.5,63,0.5,0)})
        end
    end)
    connect(verify.MouseLeave,function()
        if not state.busy then
            tw(verify,0.12,{BackgroundTransparency=0.10})
            tw(verifyScale,0.12,{Scale=1})
            verifyStroke.Transparency=0.48
            tw(arrowIcon,0.12,{Position=UDim2.new(0.5,58,0.5,0)})
        end
    end)
    connect(verify.MouseButton1Click,verifyKey)
    connect(emblem.MouseEnter,function()
        sound(config,config.HoverSoundId,0.08)
        tw(emblemHalo,0.14,{BackgroundTransparency=0.82})
        tw(emblemStroke,0.14,{Transparency=0.28})
    end)
    connect(emblem.MouseLeave,function()
        tw(emblemHalo,0.14,{BackgroundTransparency=0.91})
        tw(emblemStroke,0.14,{Transparency=0.48})
    end)
    connect(UserInputService.InputBegan,function(userInput,processed)
        if processed or state.destroyed then return end
        if userInput.KeyCode==config.ToggleKey then
            local visible=not card.Visible
            card.Visible=visible
            cardGlow.Visible=visible
            backdrop.Visible=visible
            if config.Blur then blur.Size=visible and 22 or 0 end
        end
    end)

    if not config.ReduceMotion then
        local final=card.Position
        card.Position=final+UDim2.fromOffset(0,12)
        card.BackgroundTransparency=1
        cardStroke.Transparency=1
        cardScale.Scale=0.975
        cardGlow.BackgroundTransparency=1
        tw(card,0.24,{Position=final,BackgroundTransparency=0.06})
        tw(cardStroke,0.24,{Transparency=0.38})
        tw(cardScale,0.24,{Scale=1})
        tw(cardGlow,0.32,{BackgroundTransparency=0.93})
        task.delay(0.12,function()
            if sweep.Parent and not state.destroyed then
                sweep.Position=UDim2.new(-0.25,0,0.5,0)
                tw(sweep,0.85,{Position=UDim2.new(1.25,0,0.5,0)})
            end
        end)
        task.spawn(function()
            while not state.destroyed and card.Parent do
                tw(glass,8,{Rotation=68})
                task.wait(8)
                if state.destroyed or not glass.Parent then break end
                tw(glass,8,{Rotation=40})
                task.wait(8)
            end
        end)
    end

    local handle={}
    function handle:Destroy() destroy() end
    function handle:Verify() verifyKey() end
    function handle:SetStatus(text,color) setStatus(text,color) end
    function handle:GetScreenGui() return gui end
    function handle:SetAccent(color)
        if typeof(color)~="Color3" then return end
        config.Accent=color
        cardGlow.BackgroundColor3=color
        emblemHalo.BackgroundColor3=color
        keyIcon.ImageColor3=color
        subtitle.TextColor3=color
        shieldIcon.ImageColor3=color
        inputChip.BackgroundColor3=color
        inputChipText.TextColor3=color
        statusDot.BackgroundColor3=color
        verify.BackgroundColor3=color
    end
    return handle
end

return KeySystem
