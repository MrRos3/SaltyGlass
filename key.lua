local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system.lua?clean=1.3.2")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key-system.lua failed to compile: "..tostring(compileError))
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
        local guiSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua?keygate=clean")
        local guiChunk,guiCompileError=loadstring(guiSource)
        assert(guiChunk,"SaltyGlass feature-pack.lua failed to compile: "..tostring(guiCompileError))
        guiChunk()
    end,
})

local gui=handle and handle.GetScreenGui and handle:GetScreenGui()
if gui then
    local TextService=game:GetService("TextService")

    for _,child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") and child.ZIndex==2 and child.Size.X.Offset==522 and child.Size.Y.Offset==352 then
            child:Destroy()
        end
    end

    local footer
    local shield
    for _,item in ipairs(gui:GetDescendants()) do
        if item:IsA("TextLabel") and string.find(item.Text,"ENCRYPTED SESSION",1,true) then
            footer=item
        elseif item:IsA("ImageLabel") and item:GetAttribute("LucideName")=="shield" then
            shield=item
        end
    end

    if footer and shield then
        local width=TextService:GetTextSize(footer.Text,footer.TextSize,footer.Font,Vector2.new(500,18)).X
        local total=math.ceil(width)+18
        local startX=-total/2

        shield.AnchorPoint=Vector2.new(0,0.5)
        shield.Position=UDim2.new(0.5,startX,1,-6)

        footer.AnchorPoint=Vector2.new(0,0)
        footer.Position=UDim2.new(0.5,startX+18,1,-15)
        footer.Size=UDim2.fromOffset(math.ceil(width),18)
        footer.TextXAlignment=Enum.TextXAlignment.Left
    end
end
