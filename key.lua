local HttpService=game:GetService("HttpService")
local Players=game:GetService("Players")

local player=Players.LocalPlayer
assert(player,"SaltyGlass key gate must run on the client")

local CONFIG={
    SaveFile="SaltyGlass/key-auth.json",
    RememberKey=true,
    AutoVerifySaved=true,

    -- Roblox does not expose a real HWID to normal LocalScripts.
    -- SaltyGlass uses a persisted install ID + per-run session ID instead.
    -- If your own environment provides a trusted identifier, return it here.
    BindingProvider=nil,

    -- Set this to your deployed validator URL and Enabled=true.
    Remote={
        Enabled=false,
        Url="",
        Headers={},
        Timeout=12,
    },

    -- Local fallback while Remote.Enabled=false.
    LocalKeys={
        ["SALTY-ACCESS"]={
            enabled=true,
            expiresAt=nil,
        },
    },
}

local function parseExpiry(value)
    if value==nil then return nil end
    if type(value)=="number" then return math.floor(value) end
    if type(value)~="string" then return nil end

    local numeric=tonumber(value)
    if numeric then return math.floor(numeric) end

    local y,m,d,h,min,s=value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
    if not y then return nil end

    return DateTime.fromUniversalTime(
        tonumber(y),tonumber(m),tonumber(d),
        tonumber(h),tonumber(min),tonumber(s)
    ).UnixTimestamp
end

local function expired(value)
    local timestamp=parseExpiry(value)
    return timestamp~=nil and os.time()>=timestamp,timestamp
end

local persistence={available=false}
if type(readfile)=="function" and type(writefile)=="function" then
    persistence.available=true
    persistence.read=readfile
    persistence.write=writefile
    persistence.isfile=type(isfile)=="function" and isfile or nil
    persistence.makefolder=type(makefolder)=="function" and makefolder or nil
    persistence.isfolder=type(isfolder)=="function" and isfolder or nil
    persistence.delete=type(delfile)=="function" and delfile or nil
end

local function ensureFolder()
    if not persistence.available or not persistence.makefolder then return end
    local folder=CONFIG.SaveFile:match("^(.+)/[^/]+$")
    if not folder then return end
    pcall(function()
        if not persistence.isfolder or not persistence.isfolder(folder) then
            persistence.makefolder(folder)
        end
    end)
end

local function readSaved()
    if not CONFIG.RememberKey then return nil end

    if persistence.available then
        local ok,raw=pcall(function()
            if persistence.isfile and not persistence.isfile(CONFIG.SaveFile) then return nil end
            return persistence.read(CONFIG.SaveFile)
        end)
        if ok and type(raw)=="string" and raw~="" then
            local decodeOk,data=pcall(HttpService.JSONDecode,HttpService,raw)
            if decodeOk and type(data)=="table" then return data end
        end
    end

    local raw=player:GetAttribute("SaltyKeySessionCache")
    if type(raw)=="string" and raw~="" then
        local ok,data=pcall(HttpService.JSONDecode,HttpService,raw)
        if ok and type(data)=="table" then return data end
    end

    return nil
end

local function writeSaved(data)
    if not CONFIG.RememberKey then return end
    local raw=HttpService:JSONEncode(data)

    if persistence.available then
        ensureFolder()
        pcall(persistence.write,CONFIG.SaveFile,raw)
    else
        player:SetAttribute("SaltyKeySessionCache",raw)
    end
end

local function clearSaved()
    if persistence.available and persistence.delete then
        pcall(function()
            if not persistence.isfile or persistence.isfile(CONFIG.SaveFile) then
                persistence.delete(CONFIG.SaveFile)
            end
        end)
    end
    player:SetAttribute("SaltyKeySessionCache",nil)
end

local function resolveRequest()
    if type(request)=="function" then return request end
    if type(http_request)=="function" then return http_request end

    local env=nil
    pcall(function()
        if type(getgenv)=="function" then env=getgenv() end
    end)

    if type(env)=="table" then
        if type(env.request)=="function" then return env.request end
        if type(env.http_request)=="function" then return env.http_request end
        if type(env.syn)=="table" and type(env.syn.request)=="function" then
            return env.syn.request
        end
    end

    return nil
end

local saved=readSaved()
if type(saved)=="table" and saved.expiresAt~=nil then
    local isExpired=expired(saved.expiresAt)
    if isExpired then
        clearSaved()
        saved=nil
    end
end

local installId=type(saved)=="table" and saved.installId or nil
if type(installId)~="string" or installId=="" then
    installId=HttpService:GenerateGUID(false)
end

local customBinding=nil
if type(CONFIG.BindingProvider)=="function" then
    local ok,value=pcall(CONFIG.BindingProvider)
    if ok and value~=nil then customBinding=tostring(value) end
end

local binding={
    installId=installId,
    sessionId=HttpService:GenerateGUID(false),
    custom=customBinding,
    userId=player.UserId,
    placeId=game.PlaceId,
    jobId=game.JobId,
}

local authState=nil
local lastError="Invalid key"

local function remoteValidate(key)
    local requestFn=resolveRequest()
    if not requestFn then
        return false,{message="No supported HTTP request function is available"}
    end

    if CONFIG.Remote.Url=="" then
        return false,{message="Remote validator URL is empty"}
    end

    local headers={
        ["Content-Type"]="application/json",
        ["Accept"]="application/json",
    }
    for name,value in pairs(CONFIG.Remote.Headers or {}) do
        headers[tostring(name)]=tostring(value)
    end

    local payload=HttpService:JSONEncode({
        key=key,
        binding=binding,
        sessionToken=type(saved)=="table" and saved.sessionToken or nil,
        client={name="SaltyGlass",version="1.4.0"},
    })

    local ok,response=pcall(requestFn,{
        Url=CONFIG.Remote.Url,
        Method="POST",
        Headers=headers,
        Body=payload,
        Timeout=CONFIG.Remote.Timeout,
    })

    if not ok or type(response)~="table" then
        return false,{message="Remote validation request failed"}
    end

    local status=tonumber(response.StatusCode or response.Status or response.status_code or response.status) or 0
    if status<200 or status>=300 then
        local message="Validator returned HTTP "..tostring(status)
        local body=response.Body or response.body
        if type(body)=="string" then
            local decodeOk,data=pcall(HttpService.JSONDecode,HttpService,body)
            if decodeOk and type(data)=="table" and data.message then message=tostring(data.message) end
        end
        return false,{message=message}
    end

    local body=response.Body or response.body or ""
    local decodeOk,data=pcall(HttpService.JSONDecode,HttpService,body)
    if not decodeOk or type(data)~="table" then
        return false,{message="Validator returned invalid JSON"}
    end

    if data.expiresAt~=nil then
        local isExpired=expired(data.expiresAt)
        if isExpired then
            data.valid=false
            data.message=data.message or "Key expired"
        end
    end

    return data.valid==true,data
end

local function localValidate(key)
    local record=CONFIG.LocalKeys[key]
    if type(record)~="table" or record.enabled~=true then
        return false,{message="Invalid key"}
    end

    if record.expiresAt~=nil then
        local isExpired=expired(record.expiresAt)
        if isExpired then
            return false,{message="Key expired",expiresAt=record.expiresAt}
        end
    end

    return true,{
        valid=true,
        message="Access granted",
        expiresAt=record.expiresAt,
        sessionToken=HttpService:GenerateGUID(false),
    }
end

local function validator(key)
    local valid,result
    if CONFIG.Remote.Enabled then
        valid,result=remoteValidate(key)
    else
        valid,result=localValidate(key)
    end

    authState=result
    lastError=type(result)=="table" and tostring(result.message or "Invalid key") or "Invalid key"

    if valid then
        writeSaved({
            key=key,
            installId=installId,
            sessionToken=result.sessionToken,
            expiresAt=result.expiresAt,
            savedAt=os.time(),
        })
    elseif type(saved)=="table" and saved.key==key then
        clearSaved()
        saved=nil
    end

    return valid
end

local keySource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/key-system.lua?ui=stable")
local keyChunk,keyCompileError=loadstring(keySource)
assert(keyChunk,"SaltyGlass key-system.lua failed to compile: "..tostring(keyCompileError))
local KeySystem=keyChunk()
assert(type(KeySystem)=="table" and type(KeySystem.Open)=="function","SaltyGlass key system did not return a valid API table")

local handle=KeySystem.Open({
    Title="SALTYGLASS",
    Subtitle="SECURE ACCESS",
    Description="Enter your access key to unlock the interface.",
    Keys={},
    Validator=validator,
    Sounds=true,
    Blur=true,
    ReduceMotion=false,
    OnSuccess=function()
        local guiSource=game:HttpGet("https://raw.githubusercontent.com/MrRos3/SaltyGlass/main/feature-pack.lua?auth=1.4.0")
        local guiChunk,guiCompileError=loadstring(guiSource)
        assert(guiChunk,"SaltyGlass feature-pack.lua failed to compile: "..tostring(guiCompileError))
        guiChunk()
    end,
})

if CONFIG.AutoVerifySaved and type(saved)=="table" and type(saved.key)=="string" and saved.key~="" then
    local gui=handle and handle:GetScreenGui()
    if gui then
        local input=nil
        for _,item in ipairs(gui:GetDescendants()) do
            if item:IsA("TextBox") then
                input=item
                break
            end
        end
        if input then
            input.Text=saved.key
            task.defer(function()
                if handle then handle:Verify() end
            end)
        end
    end
end
