local source=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system-v1.3.1.lua")
local chunk,compileError=loadstring(source)
assert(chunk,"SaltyGlass key-system-v1.3.1.lua failed to compile: "..tostring(compileError))
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
        local guiSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua?keygate=1.3.2")
        local guiChunk,guiCompileError=loadstring(guiSource)
        assert(guiChunk,"SaltyGlass feature-pack.lua failed to compile: "..tostring(guiCompileError))
        guiChunk()
    end,
})

local gui=handle and handle:GetScreenGui()
if gui then
    local TextService=game:GetService("TextService")
    local shield
    for _,item in ipairs(gui:GetDescendants()) do
        if item:IsA("ImageLabel") and item:GetAttribute("LucideName")=="shield" then
            shield=item
        end
    end
    if shield and shield.Parent then
        local group=shield.Parent
        local footer
        for _,item in ipairs(group:GetChildren()) do
            if item:IsA("TextLabel") and string.find(item.Text,"ENCRYPTED SESSION",1,true) then
                footer=item
                break
            end
        end
        if footer then
            local width=TextService:GetTextSize(footer.Text,footer.TextSize,footer.Font,Vector2.new(500,18)).X
            group.AnchorPoint=Vector2.new(0.5,1)
            group.Position=UDim2.new(0.5,0,1,0)
            group.Size=UDim2.fromOffset(math.ceil(width)+18,18)
            shield.AnchorPoint=Vector2.new(0,0.5)
            shield.Position=UDim2.new(0,0,0.5,0)
            footer.Position=UDim2.fromOffset(18,0)
            footer.Size=UDim2.fromOffset(math.ceil(width),18)
            footer.TextXAlignment=Enum.TextXAlignment.Left
        end
    end
end
