local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system-v1.3.0.lua")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key-system-v1.3.0.lua failed to compile: "..tostring(compileError))

local KeySystem=chunk()
assert(type(KeySystem)=="table" and type(KeySystem.Open)=="function","SaltyGlass key system did not return a valid API table")

local handle=KeySystem.Open({
    Title="SALTYGLASS",
    Subtitle="SECURE ACCESS",
    Description="Enter your access key to unlock the interface.",
    Keys={"SALTY-ACCESS"},
    Sounds=true,
    Blur=true,
    ReduceMotion=false,
    OnSuccess=function()
        local guiSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua?keygate=1.3.1")
        local guiChunk,guiCompileError=loadstring(guiSource)
        assert(guiChunk,"SaltyGlass feature-pack.lua failed to compile: "..tostring(guiCompileError))
        guiChunk()
    end,
})

local gui=handle and handle.GetScreenGui and handle:GetScreenGui()
if gui then
    for _,child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") and child.ZIndex==2 and child.Size.X.Offset==522 and child.Size.Y.Offset==352 then
            child:Destroy()
        end
    end

    local footer
    local footerIcon
    for _,item in ipairs(gui:GetDescendants()) do
        if item:IsA("TextLabel") and item.Text=="ENCRYPTED SESSION   •   RIGHT SHIFT TO HIDE" then
            footer=item
        elseif item:IsA("ImageLabel") and item:GetAttribute("LucideName")=="shield" then
            footerIcon=item
        end
    end

    if footer then
        footer.AnchorPoint=Vector2.new(0.5,0)
        footer.Position=UDim2.new(0.5,8,1,-15)
        footer.Size=UDim2.fromOffset(230,18)
        footer.TextXAlignment=Enum.TextXAlignment.Center
    end

    if footerIcon then
        footerIcon.AnchorPoint=Vector2.new(0.5,0.5)
        footerIcon.Position=UDim2.new(0.5,-116,1,-6)
    end
end
