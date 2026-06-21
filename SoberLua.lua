
local CONFIG = {
    -- === Paintball / FPS Killer Settings ===
    Paintball = {
        Enabled             = true,
        FireRate            = 0.15,       -- Seconds between shots
        ProjectileSpeed     = 350,        -- Studs/sec
        Range               = 500,        -- Max shot range (studs)
        BeamColor           = Color3.fromRGB(255, 50, 50),   -- Red paintball beam
        BeamTransparency    = 0.3,
        BeamWidth           = 0.5,
        ImpactParticleSize  = 2.0,
        SoundId_Shoot       = "rbxassetid://154441356",      -- Placeholder: gunshot sound
        SoundId_Impact      = "rbxassetid://169380553",      -- Placeholder: impact sound
        SoundId_Steal       = "rbxassetid://9120385684",     -- Placeholder: steal success sound
        ParticleId_Impact   = "rbxassetid://14276418951",    -- Placeholder: impact particle
    },
    
    -- === FPS Devourer Settings ===
    FPSDevourer = {
        Enabled             = false,
        LagIntensity        = 0.8,        -- 0.0 to 1.0 lag severity
        LagRadius           = 150,        -- Studs around target affected
        SpamRate            = 0.05,       -- How fast to spam lag packets
        TargetMethod        = "Nearest",  -- "Nearest", "MouseTarget", "Specific"
    },
    
    -- === Stealing Settings ===
    Stealing = {
        InstantSteal        = false,
        AutoSteal           = false,
        StealRange          = 30,         -- Studs to detect brainrots
        StealCooldown       = 0.5,        -- Seconds between steal attempts
        PriorityRarity      = "Highest",  -- "Highest", "Lowest", "Nearest"
        StealMethod         = "ClickDetector", -- "ClickDetector", "ProximityPrompt", "Hybrid"
        AntiTheftReturn     = false,      -- Return stolen brainrots to your base
    },
    
    -- === Movement Settings ===
    Movement = {
        SpeedBoost          = false,
        SpeedMultiplier     = 3.5,
        FlySpeed            = 75,
        FloatMode           = false,      -- Hover in place
        FloatV2             = false,      -- Advanced float with directional control
        NoClip              = false,
        InfiniteJump        = false,
    },
    
    -- === Visual / ESP Settings ===
    Visual = {
        ESP_Enabled         = false,
        ESP_BrainrotColor   = Color3.fromRGB(0, 255, 100),
        ESP_PlayerColor     = Color3.fromRGB(255, 50, 50),
        ESP_ShowDistance    = true,
        ESP_ShowValue       = true,
        ESP_MaxDistance     = 500,
        SemiInvisible       = false,
        SemiInvisibleTransparency = 0.85,
    },
    
    -- === Defense Settings ===
    Defense = {
        AntiHit             = false,      -- Prevent being ragdolled/hit
        AntiRagdoll         = false,      -- Instant recovery from ragdoll
        AutoLockBase        = false,
        AutoLockDelay       = 2.0,        -- Seconds before auto-locking after unlock
        AntiGrab            = false,      -- Prevent others from grabbing you
    },
    
    -- === Utility Settings ===
    Utility = {
        TeleportToBase      = false,
        CollectCash         = false,
        CollectCashRange    = 50,
        AutoRebirth         = false,
        AutoBuyBrainrot     = false,
        ServerHopOnSteal    = false,
        Notifications       = true,
    },
    
    -- === Keybinds ===
    Keybinds = {
        ToggleMenu          = Enum.KeyCode.RightControl,
        InstantSteal        = Enum.KeyCode.T,
        TeleportToBase      = Enum.KeyCode.B,
        SpeedBoost          = Enum.KeyCode.LeftShift,
        NoClip              = Enum.KeyCode.N,
        InfiniteJump        = Enum.KeyCode.Space,
    },
    
    -- === GUI Settings ===
    GUI = {
        ThemeColor          = Color3.fromRGB(25, 25, 35),
        AccentColor         = Color3.fromRGB(255, 70, 70),
        TextColor           = Color3.fromRGB(235, 235, 235),
        FontSize            = 14,
        Opacity             = 0.92,
        ToggleKey           = Enum.KeyCode.RightControl,
    },
}

-- ====================================================================
-- SECTION 2: SERVICES & INITIALIZATION
-- ====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Internal state tracking
local State = {
    MenuOpen            = true,
    FPSKillerActive     = false,
    CurrentTarget       = nil,
    LastShotTime        = 0,
    LastStealTime       = 0,
    IsFloating          = false,
    IsFloatingV2        = false,
    IsFlying            = false,
    IsSemiInvisible     = false,
    OriginalCFrame      = nil,
    OriginalTransparency = {},
    ESP_Instances       = {},
    ESP_Connections     = {},
    AutoStealLoop       = nil,
    FPSKillerLoop       = nil,
    StealQueue          = {},
    OriginalWalkSpeed   = 16,
    OriginalJumpPower   = 50,
    TargetPlayer        = nil,
    TargetBrainrot      = nil,
    Connections         = {},
    LoopConnections     = {},
    ScreenGUI           = nil,
    MainFrame           = nil,
    Tabs                = {},
    ActiveTab           = nil,
    BrainrotCache       = {},
    BaseLocation        = nil,
    IsNoClipping        = false,
    IsSpeedBoosting     = false,
    AntiHitActive       = false,
    AntiRagdollActive   = false,
    TeleportCooldown    = false,
    NotificationQueue   = {},
}

-- ====================================================================
-- SECTION 3: UTILITY FUNCTIONS
-- ====================================================================

-- 3.1: Safe wrapper for pcall operations
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[PaintballFPS] Error: " .. tostring(result))
    end
    return result
end

-- 3.2: Console logging with formatting
local function log(message, level)
    level = level or "INFO"
    local prefix = "[PaintballFPS-" .. level .. "]"
    if level == "ERROR" then
        warn(prefix .. " " .. tostring(message))
    elseif level == "WARN" then
        warn(prefix .. " " .. tostring(message))
    else
        print(prefix .. " " .. tostring(message))
    end
end

-- 3.3: Notification system (in-game)
local function notify(message, duration, style)
    duration = duration or 3
    style = style or "info"
    spawn(function()
        -- Attempt to use the game's built-in notification if available
        local success, err = pcall(function()
            if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
                local chatEvent = ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if chatEvent then
                    chatEvent:FireServer("[PaintballFPS] " .. message, Enum.ChatColor.Blue)
                end
            end
        end)
        if not success then
            -- Fallback: screen notification via BillboardGui
            local notificationGui = Instance.new("BillboardGui")
            notificationGui.Name = "PaintballNotification"
            notificationGui.Size = UDim2.new(0, 350, 0, 50)
            notificationGui.StudsOffset = Vector3.new(0, 3, 0)
            notificationGui.Adornee = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            notificationGui.AlwaysOnTop = true
            
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
            bg.BackgroundTransparency = 0.2
            bg.BorderSizePixel = 0
            bg.Parent = notificationGui
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = bg
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = CONFIG.GUI.AccentColor
            stroke.Thickness = 1.5
            stroke.Parent = bg
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -10, 1, 0)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = CONFIG.GUI.TextColor
            label.Text = "[PaintballFPS] " .. message
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = CONFIG.GUI.FontSize
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Parent = bg
            
            notificationGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or CoreGui
            
            -- Fade out animation
            local fadeOut = TweenService:Create(bg, TweenInfo.new(duration - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            local fadeLabel = TweenService:Create(label, TweenInfo.new(duration - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 1
            })
            
            task.wait(duration - 0.5)
            fadeOut:Play()
            fadeLabel:Play()
            task.wait(0.5)
            notificationGui:Destroy()
        end
    end)
end

-- 3.4: Deep copy table
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- 3.5: Clamp utility
local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- 3.6: Vector3 distance ignoring Y
local function distanceXZ(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

-- 3.7: Get character of a player
local function getCharacter(player)
    if player and player.Character then
        return player.Character
    end
    return nil
end

-- 3.8: Get humanoid root part
local function getRootPart(character)
    if character then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    end
    return nil
end

-- 3.9: Get humanoid
local function getHumanoid(character)
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- 3.10: Check if a player is valid target
local function isValidTarget(player)
    if not player then return false end
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local humanoid = getHumanoid(player.Character)
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    return true
end

-- 3.11: Find nearest player
local function getNearestPlayer(maxDistance)
    maxDistance = maxDistance or CONFIG.Paintball.Range
    local nearestDist = maxDistance
    local nearestPlayer = nil
    local myPos = Camera and Camera.CFrame.Position or Vector3.new(0, 0, 0)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local root = getRootPart(player.Character)
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
end

-- 3.12: Get mouse target player (whoever is under cursor)
local function getMouseTargetPlayer()
    local target = Mouse.Target
    if not target then return nil end
    local character = target:FindFirstAncestorOfClass("Model")
    if not character then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == character and isValidTarget(player) then
            return player
        end
    end
    return nil
end

-- ====================================================================
-- SECTION 4: BRAINROT DETECTION SYSTEM
-- ====================================================================

-- 4.1: Scan workspace for brainrot objects
local function scanBrainrots()
    local brainrots = {}
    local myPos = Camera and Camera.CFrame.Position or Vector3.new(0, 0, 0)
    
    -- Search for ClickDetectors (typical brainrot interaction)
    for _, detector in ipairs(Workspace:GetDescendants()) do
        if detector:IsA("ClickDetector") then
            local parent = detector.Parent
            if parent and parent:IsA("BasePart") or (parent and parent:IsA("Model")) then
                local dist = (parent:IsA("BasePart") and parent.Position or 
                    (parent:FindFirstChild("PrimaryPart") and parent.PrimaryPart.Position or 
                    parent:GetBoundingBox().Position)) - myPos
                
                if dist.Magnitude <= CONFIG.Stealing.StealRange * 3 then
                    local valueLabel = parent:FindFirstChild("Value") or 
                                      parent:FindFirstChild("BrainrotValue") or
                                      parent:FindFirstChild("Price")
                    local nameLabel = parent:FindFirstChild("NameDisplay") or
                                      parent:FindFirstChild("BrainrotName")
                    
                    table.insert(brainrots, {
                        Object = parent,
                        Detector = detector,
                        Position = parent:IsA("BasePart") and parent.Position or parent:GetBoundingBox().Position,
                        Distance = dist.Magnitude,
                        Name = nameLabel and (nameLabel:IsA("TextLabel") and nameLabel.Text or "Unknown") or "Unknown",
                        Value = valueLabel and tonumber(valueLabel:IsA("TextLabel") and valueLabel.Text or "0") or 0,
                        Type = "ClickDetector",
                    })
                end
            end
        end
    end
    
    -- Search for ProximityPrompts
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local parent = prompt.Parent
            if parent then
                local part = parent:IsA("BasePart") and parent or 
                            (parent:FindFirstChildWhichIsA("BasePart"))
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist <= CONFIG.Stealing.StealRange * 3 then
                        table.insert(brainrots, {
                            Object = parent,
                            Prompt = prompt,
                            Position = part.Position,
                            Distance = dist,
                            Name = "Brainrot (Prompt)",
                            Value = 0,
                            Type = "ProximityPrompt",
                        })
                    end
                end
            end
        end
    end
    
    -- Search for models with "Brainrot" in name or tags
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and (string.find(model.Name, "Brainrot") or 
           string.find(model.Name, "brainrot") or 
           model:GetAttribute("IsBrainrot") or
           model:FindFirstChild("BrainrotTag")) then
            local primaryPart = model:FindFirstChild("PrimaryPart") or 
                               model:FindFirstChild("HumanoidRootPart") or
                               model:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local dist = (primaryPart.Position - myPos).Magnitude
                if dist <= CONFIG.Stealing.StealRange * 3 then
                    local alreadyFound = false
                    for _, br in ipairs(brainrots) do
                        if br.Object == model then
                            alreadyFound = true
                            break
                        end
                    end
                    if not alreadyFound then
                        table.insert(brainrots, {
                            Object = model,
                            Position = primaryPart.Position,
                            Distance = dist,
                            Name = model.Name,
                            Value = model:GetAttribute("Value") or 0,
                            Type = "Model",
                        })
                    end
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(brainrots, function(a, b)
        if CONFIG.Stealing.PriorityRarity == "Highest" then
            return (a.Value or 0) > (b.Value or 0)
        elseif CONFIG.Stealing.PriorityRarity == "Lowest" then
            return (a.Value or 0) < (b.Value or 0)
        else
            return a.Distance < b.Distance
        end
    end)
    
    return brainrots
end

-- 4.2: Attempt to steal a brainrot by interacting with it
local function attemptStealBrainrot(brainrotData)
    if not brainrotData then return false end
    
    local success = false
    
    -- Method 1: ClickDetector
    if brainrotData.Detector and brainrotData.Detector:IsA("ClickDetector") then
        success = pcall(function()
            fireclickdetector(brainrotData.Detector)
        end)
    end
    
    -- Method 2: ProximityPrompt
    if not success and brainrotData.Prompt and brainrotData.Prompt:IsA("ProximityPrompt") then
        success = pcall(function()
            fireproximityprompt(brainrotData.Prompt)
        end)
    end
    
    -- Method 3: Try to find any interaction method on the object
    if not success then
        success = pcall(function()
            local obj = brainrotData.Object
            if obj then
                -- Look for any ClickDetector child
                local detector = obj:FindFirstChildOfClass("ClickDetector")
                if detector then
                    fireclickdetector(detector)
                    success = true
                end
                -- Look for any ProximityPrompt child
                if not success then
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        fireproximityprompt(prompt)
                        success = true
                    end
                end
            end
        end)
    end
    
    return success
end

-- 4.3: Perform instant steal - scan and steal nearest/richest brainrot
local function performInstantSteal()
    if State.LastStealTime + CONFIG.Stealing.StealCooldown > tick() then
        notify("Steal on cooldown!", 1, "warn")
        return false
    end
    
    local brainrots = scanBrainrots()
    if #brainrots == 0 then
        notify("No brainrots found nearby!", 2, "warn")
        return false
    end
    
    -- Try to steal the highest priority brainrot
    for _, br in ipairs(brainrots) do
        if br.Distance <= CONFIG.Stealing.StealRange then
            local stolen = attemptStealBrainrot(br)
            if stolen then
                State.LastStealTime = tick()
                notify("Stole: " .. br.Name .. "!", 2, "success")
                
                -- Play steal sound
                pcall(function()
                    local sound = Instance.new("Sound")
                    sound.SoundId = CONFIG.Paintball.SoundId_Steal
                    sound.Volume = 0.8
                    sound.Parent = Camera
                    sound:Play()
                    Debris:AddItem(sound, 3)
                end)
                
                return true
            end
        end
    end
    
    notify("Could not steal - no brainrots in range!", 1, "warn")
    return false
end

-- 4.4: Find the player's own base location
local function findPlayerBase()
    -- Try common base naming conventions
    local baseNames = {
        LocalPlayer.Name .. "'s Base",
        LocalPlayer.Name .. "s Base",
        LocalPlayer.Name .. "_Base",
        LocalPlayer.Name .. "Base",
        "Base_" .. LocalPlayer.Name,
        tostring(LocalPlayer.UserId) .. "_Base",
    }
    
    for _, name in ipairs(baseNames) do
        local base = Workspace:FindFirstChild(name, true)
        if base then
            return base
        end
    end
    
    -- Try to find by checking parts with player ownership attributes
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Model") then
            local ownerAttr = part:GetAttribute("Owner") or part:GetAttribute("owner")
            if ownerAttr and (ownerAttr == LocalPlayer.Name or ownerAttr == LocalPlayer.UserId) then
                return part
            end
        end
    end
    
    -- Try to find the base door/spawn
    if LocalPlayer.Character then
        local root = getRootPart(LocalPlayer.Character)
        if root then
            -- Look for large flat parts near spawn
            local spawnPos = Workspace:FindFirstChild("SpawnLocation")
            if spawnPos and spawnPos:IsA("SpawnLocation") then
                return spawnPos
            end
        end
    end
    
    return nil
end

-- 4.5: Teleport to player's base
local function teleportToBase()
    if State.TeleportCooldown then
        notify("Teleport on cooldown!", 1, "warn")
        return
    end
    
    State.TeleportCooldown = true
    
    local base = findPlayerBase() or 
                 Workspace:FindFirstChild("Base") or 
                 Workspace:FindFirstChild("SpawnLocation")
    
    if base then
        local targetPos = base:IsA("BasePart") and base.Position or 
                         (base:FindFirstChild("PrimaryPart") and base.PrimaryPart.Position) or
                         base:GetBoundingBox().Position
        
        if LocalPlayer.Character then
            local root = getRootPart(LocalPlayer.Character)
            if root then
                root.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
                notify("Teleported to base!", 2, "success")
            end
        end
    else
        notify("Could not find base location!", 2, "error")
    end
    
    task.wait(1)
    State.TeleportCooldown = false
end

-- 4.6: Fly to a high-value brainrot
local function flyToHighBrainrot()
    local brainrots = scanBrainrots()
    if #brainrots == 0 then
        notify("No brainrots found!", 2, "warn")
        return
    end
    
    -- Find the highest value brainrot
    local best = brainrots[1]
    for _, br in ipairs(brainrots) do
        if (br.Value or 0) > (best.Value or 0) then
            best = br
        end
    end
    
    if best then
        -- Tween the character to the brainrot position
        if LocalPlayer.Character then
            local root = getRootPart(LocalPlayer.Character)
            if root then
                local tween = TweenService:Create(root, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
                })
                tween:Play()
                notify("Flying to: " .. best.Name, 2, "info")
            end
        end
    end
end

-- ====================================================================
-- SECTION 5: FPS KILLER / LAG SYSTEM
-- ====================================================================

-- 5.1: FPS Devourer - Send lag-inducing packets to target
local function executeFPSKiller(targetPlayer)
    if not targetPlayer or not isValidTarget(targetPlayer) then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local root = getRootPart(character)
    if not root then return end
    
    -- Method 1: Stream lag by spamming proximity prompts
    pcall(function()
        local prompts = character:GetDescendants()
        for _, v in ipairs(prompts) do
            if v:IsA("ProximityPrompt") then
                fireproximityprompt(v)
            end
        end
    end)
    
    -- Method 2: Force replication of many small objects near target
    for i = 1, 5 do
        pcall(function()
            local part = Instance.new("Part")
            part.Size = Vector3.new(0.1, 0.1, 0.1)
            part.CFrame = root.CFrame * CFrame.new(math.random(-5, 5), math.random(-3, 3), math.random(-5, 5))
            part.Transparency = 1
            part.CanCollide = false
            part.Anchored = true
            part.Parent = Workspace
            Debris:AddItem(part, 0.5)
        end)
    end
    
    -- Method 3: Spam sound replication near target
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.Paintball.SoundId_Shoot
        sound.Volume = 1.0
        sound.Pitch = math.random(5, 20) / 10
        sound.Parent = root
        sound:Play()
        Debris:AddItem(sound, 0.3)
    end)
    
    -- Method 4: Force character animation updates (causes network spam)
    pcall(function()
        local humanoid = getHumanoid(character)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.wait(0.01)
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

-- 5.2: Paintball projectile system
local function firePaintballProjectile(targetPosition)
    if not Camera or not LocalPlayer.Character then return end
    
    local root = getRootPart(LocalPlayer.Character)
    if not root then return end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit
    local distance = math.min((targetPosition - origin).Magnitude, CONFIG.Paintball.Range)
    local endpoint = origin + direction * distance
    
    -- Create the beam visual
    local beamPart = Instance.new("Part")
    beamPart.Name = "PaintballBeam"
    beamPart.Size = Vector3.new(CONFIG.Paintball.BeamWidth, CONFIG.Paintball.BeamWidth, distance)
    beamPart.CFrame = CFrame.new(origin, endpoint) * CFrame.new(0, 0, -distance / 2)
    beamPart.BrickColor = BrickColor.new(CONFIG.Paintball.BeamColor)
    beamPart.Color = CONFIG.Paintball.BeamColor
    beamPart.Transparency = CONFIG.Paintball.BeamTransparency
    beamPart.Material = Enum.Material.Neon
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Parent = Workspace
    
    -- Beam glow effect
    local glowPart = beamPart:Clone()
    glowPart.Size = Vector3.new(CONFIG.Paintball.BeamWidth * 3, CONFIG.Paintball.BeamWidth * 3, distance)
    glowPart.Transparency = CONFIG.Paintball.BeamTransparency + 0.3
    glowPart.Color = Color3.new(1, 1, 1)
    glowPart.Parent = Workspace
    Debris:AddItem(glowPart, 0.2)
    
    -- Fade out the beam
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(beamPart, tweenInfo, {Transparency = 1})
    tween:Play()
    Debris:AddItem(beamPart, 0.3)
    
    -- Impact effect
    local impact = Instance.new("Part")
    impact.Name = "PaintballImpact"
    impact.Size = Vector3.new(1, 1, 1)
    impact.Shape = Enum.PartType.Ball
    impact.BrickColor = BrickColor.new(CONFIG.Paintball.BeamColor)
    impact.Color = CONFIG.Paintball.BeamColor
    impact.Transparency = 0.2
    impact.Material = Enum.Material.Neon
    impact.Anchored = true
    impact.CanCollide = false
    impact.CFrame = CFrame.new(endpoint)
    impact.Parent = Workspace
    
    -- Impact grow and fade
    local impactTween = TweenService:Create(impact, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(CONFIG.Paintball.ImpactParticleSize, CONFIG.Paintball.ImpactParticleSize, CONFIG.Paintball.ImpactParticleSize),
        Transparency = 1
    })
    impactTween:Play()
    Debris:AddItem(impact, 0.5)
    
    -- Impact sound
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.Paintball.SoundId_Impact
        sound.Volume = 0.6
        sound.Pitch = math.random(8, 12) / 10
        sound.Parent = impact
        sound:Play()
        Debris:AddItem(sound, 2)
    end)
    
    -- Shoot sound at origin
    pcall(function()
        local shootSound = Instance.new("Sound")
        shootSound.SoundId = CONFIG.Paintball.SoundId_Shoot
        shootSound.Volume = 0.4
        shootSound.Parent = root
        shootSound:Play()
        Debris:AddItem(shootSound, 2)
    end)
    
    return endpoint, direction
end

-- 5.3: Handle paintball shot on mouse click
local function handlePaintballShot()
    if not CONFIG.Paintball.Enabled then return end
    if State.LastShotTime + CONFIG.Paintball.FireRate > tick() then return end
    State.LastShotTime = tick()
    
    local target = Mouse.Target
    local hitPos = Mouse.Hit.Position
    
    -- Fire the projectile
    local endpoint, direction = firePaintballProjectile(hitPos)
    
    -- Check if we hit a player
    if target then
        local hitCharacter = target:FindFirstAncestorOfClass("Model")
        if hitCharacter then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character == hitCharacter and isValidTarget(player) then
                    -- Apply FPS killer effect on hit player
                    if CONFIG.FPSDevourer.Enabled then
                        for i = 1, 3 do
                            executeFPSKiller(player)
                        end
                        notify("FPS KILLER hit on " .. player.DisplayName .. "!", 2, "info")
                    end
                    
                    -- Attempt to steal a brainrot from the hit player's base
                    if CONFIG.Stealing.InstantSteal then
                        task.wait(0.1)
                        performInstantSteal()
                    end
                    
                    break
                end
            end
        end
    end
end

-- ====================================================================
-- SECTION 6: MOVEMENT SYSTEMS (FLY, FLOAT, NOCLIP, SPEED)
-- ====================================================================

-- 6.1: Infinite Jump system
local function setupInfiniteJump()
    local connection
    connection = UserInputService.JumpRequest:Connect(function()
        if CONFIG.Movement.InfiniteJump and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.05)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    table.insert(State.Connections, connection)
end

-- 6.2: NoClip system
local function setupNoClip()
    local connection
    connection = RunService.Stepped:Connect(function()
        if CONFIG.Movement.NoClip and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- 6.3: Speed Boost system
local function setupSpeedBoost()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Movement.SpeedBoost and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then
                local targetSpeed = CONFIG.Movement.SpeedMultiplier * State.OriginalWalkSpeed
                if humanoid.WalkSpeed ~= targetSpeed then
                    humanoid.WalkSpeed = targetSpeed
                end
            end
        else
            -- Reset to original when disabled
            local humanoid = LocalPlayer.Character and getHumanoid(LocalPlayer.Character)
            if humanoid and humanoid.WalkSpeed ~= State.OriginalWalkSpeed then
                humanoid.WalkSpeed = State.OriginalWalkSpeed
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- 6.4: Float Mode - Hover in place
local function setupFloatMode()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Movement.FloatMode and LocalPlayer.Character then
            local root = getRootPart(LocalPlayer.Character)
            local humanoid = getHumanoid(LocalPlayer.Character)
            if root and humanoid then
                -- Apply upward force to hover
                local currentPos = root.Position
                local floatHeight = currentPos.Y
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
                
                -- Allow slight movement with WASD
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    root.CFrame = root.CFrame * CFrame.new(0, 0, -CONFIG.Movement.FlySpeed * 0.05)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    root.CFrame = root.CFrame * CFrame.new(0, 0, CONFIG.Movement.FlySpeed * 0.05)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    root.CFrame = root.CFrame * CFrame.new(-CONFIG.Movement.FlySpeed * 0.05, 0, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    root.CFrame = root.CFrame * CFrame.new(CONFIG.Movement.FlySpeed * 0.05, 0, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    root.CFrame = root.CFrame * CFrame.new(0, CONFIG.Movement.FlySpeed * 0.05, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    root.CFrame = root.CFrame * CFrame.new(0, -CONFIG.Movement.FlySpeed * 0.05, 0)
                end
            end
        elseif CONFIG.Movement.FloatMode == false and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then
                humanoid.WalkSpeed = State.OriginalWalkSpeed
                humanoid.JumpPower = State.OriginalJumpPower
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- 6.5: Float V2 - Advanced float with rotation control
local function setupFloatV2()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Movement.FloatV2 and LocalPlayer.Character then
            local root = getRootPart(LocalPlayer.Character)
            local humanoid = getHumanoid(LocalPlayer.Character)
            if root and humanoid then
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
                humanoid.AutoRotate = false
                
                -- Match camera direction for movement
                local cameraCF = Camera.CFrame
                local forward = cameraCF.LookVector * Vector3.new(1, 0, 1).Unit
                local right = cameraCF.RightVector * Vector3.new(1, 0, 1).Unit
                
                local moveVec = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveVec = moveVec + forward
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveVec = moveVec - forward
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveVec = moveVec - right
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveVec = moveVec + right
                end
                
                if moveVec.Magnitude > 0 then
                    moveVec = moveVec.Unit * CONFIG.Movement.FlySpeed * 0.08
                end
                
                -- Vertical movement
                local verticalVec = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    verticalVec = Vector3.new(0, CONFIG.Movement.FlySpeed * 0.05, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    verticalVec = Vector3.new(0, -CONFIG.Movement.FlySpeed * 0.05, 0)
                end
                
                root.CFrame = root.CFrame + moveVec + verticalVec
                root.Velocity = Vector3.new()
                root.RotVelocity = Vector3.new()
            end
        elseif CONFIG.Movement.FloatV2 == false and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then
                humanoid.WalkSpeed = State.OriginalWalkSpeed
                humanoid.JumpPower = State.OriginalJumpPower
                humanoid.AutoRotate = true
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- 6.6: Semi-Invisible mode
local function setupSemiInvisible()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Visual.SemiInvisible and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = CONFIG.Visual.SemiInvisibleTransparency
                end
            end
        elseif not CONFIG.Visual.SemiInvisible and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- ====================================================================
-- SECTION 7: ANTI-HIT / DEFENSE SYSTEMS
-- ====================================================================

-- 7.1: Anti-Hit - Prevent being hit/ragdolled
local function setupAntiHit()
    local connection
    connection = LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if CONFIG.Defense.AntiHit then
            local humanoid = getHumanoid(character)
            if humanoid then
                -- Prevent state changes to ragdoll
                humanoid.StateChanged:Connect(function(oldState, newState)
                    if newState == Enum.HumanoidStateType.FallingDown or 
                       newState == Enum.HumanoidStateType.Ragdoll then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
            end
        end
    end)
    table.insert(State.Connections, connection)
    
    -- Also apply to current character
    if LocalPlayer.Character then
        local humanoid = getHumanoid(LocalPlayer.Character)
        if humanoid then
            humanoid.StateChanged:Connect(function(oldState, newState)
                if CONFIG.Defense.AntiHit and 
                   (newState == Enum.HumanoidStateType.FallingDown or 
                    newState == Enum.HumanoidStateType.Ragdoll) then
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end
    end
end

-- 7.2: Anti-Ragdoll - Instant recovery
local function setupAntiRagdoll()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Defense.AntiRagdoll and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid and (humanoid:GetState() == Enum.HumanoidStateType.FallingDown or
               humanoid:GetState() == Enum.HumanoidStateType.Ragdoll) then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- 7.3: Auto Lock Base
local function setupAutoLockBase()
    -- Find base lock button
    local function findLockButton()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Model") then
                -- Look for buttons related to locking
                local detector = v:FindFirstChildOfClass("ClickDetector")
                if detector and (string.find(v.Name, "Lock") or string.find(v.Name, "lock") or
                   string.find(v.Name, "Button") or string.find(v.Name, "button")) then
                    return detector
                end
            end
            -- Look in PlayerGui
            if v:IsA("TextButton") and (string.find(v.Text, "Lock") or string.find(v.Text, "lock")) then
                return v
            end
        end
        return nil
    end
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Defense.AutoLockBase then
            local lockButton = findLockButton()
            if lockButton then
                if lockButton:IsA("ClickDetector") then
                    pcall(function() fireclickdetector(lockButton) end)
                elseif lockButton:IsA("TextButton") then
                    pcall(function() lockButton:Fire("MouseButton1Click") end)
                end
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- ====================================================================
-- SECTION 8: AUTO-STEAL LOOP SYSTEM
-- ====================================================================

-- 8.1: Start auto-steal loop
local function startAutoStealLoop()
    if State.AutoStealLoop then
        State.AutoStealLoop:Disconnect()
        State.AutoStealLoop = nil
    end
    
    State.AutoStealLoop = RunService.Heartbeat:Connect(function()
        if CONFIG.Stealing.AutoSteal then
            if State.LastStealTime + CONFIG.Stealing.StealCooldown < tick() then
                performInstantSteal()
            end
        end
    end)
    table.insert(State.LoopConnections, State.AutoStealLoop)
end

-- 8.2: Start FPS killer loop
local function startFPSKillerLoop()
    if State.FPSKillerLoop then
        State.FPSKillerLoop:Disconnect()
        State.FPSKillerLoop = nil
    end
    
    State.FPSKillerLoop = RunService.Heartbeat:Connect(function()
        if CONFIG.FPSDevourer.Enabled then
            local target = nil
            
            if CONFIG.FPSDevourer.TargetMethod == "Nearest" then
                target = getNearestPlayer(CONFIG.FPSDevourer.LagRadius)
            elseif CONFIG.FPSDevourer.TargetMethod == "MouseTarget" then
                target = getMouseTargetPlayer()
            end
            
            if target then
                executeFPSKiller(target)
            end
        end
    end)
    table.insert(State.LoopConnections, State.FPSKillerLoop)
end

-- ====================================================================
-- SECTION 9: ESP SYSTEM
-- ====================================================================

-- 9.1: Create ESP for a brainrot or player
local function createESP(instance, label, color, value)
    if State.ESP_Instances[instance] then
        return
    end
    
    local espGui = Instance.new("BillboardGui")
    espGui.Name = "PaintballESP"
    espGui.Size = UDim2.new(0, 200, 0, 60)
    espGui.StudsOffset = Vector3.new(0, 2.5, 0)
    espGui.AlwaysOnTop = true
    espGui.Adornee = instance
    espGui.MaxDistance = CONFIG.Visual.ESP_MaxDistance
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel = 0
    bg.Parent = espGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = bg
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = bg
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = color
    nameLabel.Text = label
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = CONFIG.GUI.FontSize
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.Parent = bg
    
    if CONFIG.Visual.ESP_ShowValue and value then
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, -10, 0.5, 0)
        valueLabel.Position = UDim2.new(0, 5, 0.5, -2)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        valueLabel.Text = "$" .. tostring(value)
        valueLabel.Font = Enum.Font.GothamMedium
        valueLabel.TextSize = CONFIG.GUI.FontSize - 2
        valueLabel.TextXAlignment = Enum.TextXAlignment.Center
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.Parent = bg
    end
    
    espGui.Parent = CoreGui
    State.ESP_Instances[instance] = espGui
    State.ESP_Connections[instance] = espGui
    
    return espGui
end

-- 9.2: Remove ESP for an instance
local function removeESP(instance)
    if State.ESP_Instances[instance] then
        State.ESP_Instances[instance]:Destroy()
        State.ESP_Instances[instance] = nil
        State.ESP_Connections[instance] = nil
    end
end

-- 9.3: Clear all ESP
local function clearAllESP()
    for instance, gui in pairs(State.ESP_Instances) do
        pcall(function() gui:Destroy() end)
    end
    State.ESP_Instances = {}
    State.ESP_Connections = {}
end

-- 9.4: ESP update loop
local function setupESPLoop()
    local espConnection
    espConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.Visual.ESP_Enabled then
            if next(State.ESP_Instances) then
                clearAllESP()
            end
            return
        end
        
        -- ESP for brainrots
        local brainrots = scanBrainrots()
        local currentEspTargets = {}
        for _, br in ipairs(brainrots) do
            if br.Distance <= CONFIG.Visual.ESP_MaxDistance then
                local instance = br.Object
                currentEspTargets[instance] = true
                if not State.ESP_Instances[instance] then
                    createESP(instance, br.Name, CONFIG.Visual.ESP_BrainrotColor, br.Value)
                end
                -- Update distance label if shown
                if CONFIG.Visual.ESP_ShowDistance and State.ESP_Instances[instance] then
                    local distLabel = State.ESP_Instances[instance]:FindFirstChild("DistanceLabel", true)
                    if distLabel then
                        distLabel.Text = math.floor(br.Distance) .. " studs"
                    end
                end
            end
        end
        
        -- ESP for players (other players' bases/brainrots)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = getRootPart(player.Character)
                if root then
                    local dist = (root.Position - Camera.CFrame.Position).Magnitude
                    if dist <= CONFIG.Visual.ESP_MaxDistance then
                        local instance = root
                        currentEspTargets[instance] = true
                        if not State.ESP_Instances[instance] then
                            createESP(instance, player.DisplayName .. " [" .. math.floor(dist) .. "]", 
                                      CONFIG.Visual.ESP_PlayerColor, nil)
                        end
                    end
                end
            end
        end
        
        -- Clean up stale ESP
        for instance, gui in pairs(State.ESP_Instances) do
            if not currentEspTargets[instance] then
                removeESP(instance)
            end
        end
    end)
    table.insert(State.LoopConnections, espConnection)
end

-- ====================================================================
-- SECTION 10: COLLECTION / AUTO COLLECT CASH
-- ====================================================================

-- 10.1: Collect cash from base
local function collectCash()
    local collected = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent then
                local part = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
                if part and LocalPlayer.Character then
                    local root = getRootPart(LocalPlayer.Character)
                    if root and (part.Position - root.Position).Magnitude <= CONFIG.Utility.CollectCashRange then
                        if v:IsA("ClickDetector") then
                            pcall(function() fireclickdetector(v) end)
                            collected = collected + 1
                        elseif v:IsA("ProximityPrompt") then
                            pcall(function() fireproximityprompt(v) end)
                            collected = collected + 1
                        end
                    end
                end
            end
        end
    end
    
    -- Also try to find cash pickup objects
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (string.find(v.Name, "Cash") or string.find(v.Name, "cash") or
           string.find(v.Name, "Money") or string.find(v.Name, "money") or
           string.find(v.Name, "Coin") or string.find(v.Name, "coin")) then
            if LocalPlayer.Character then
                local root = getRootPart(LocalPlayer.Character)
                if root and (v.Position - root.Position).Magnitude <= CONFIG.Utility.CollectCashRange then
                    -- Try to touch the cash
                    local touchConnection = v.Touched:Connect(function() end)
                    local rootPart = getRootPart(LocalPlayer.Character)
                    if rootPart then
                        -- Fire the touch manually
                        pcall(function()
                            v.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
                        end)
                    end
                    touchConnection:Disconnect()
                    collected = collected + 1
                end
            end
        end
    end
    
    return collected
end

-- 10.2: Auto collect cash loop
local function setupAutoCollectCash()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if CONFIG.Utility.CollectCash then
            local collected = collectCash()
            if collected > 0 and math.random(1, 30) == 1 then
                -- Only notify occasionally to avoid spam
                notify("Collected cash from " .. collected .. " sources!", 1, "info")
            end
        end
    end)
    table.insert(State.LoopConnections, connection)
end

-- ====================================================================
-- SECTION 11: GUI SYSTEM
-- ====================================================================

-- 11.1: Create main GUI
local function createGUI()
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PaintballFPSKiller"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui
    
    State.ScreenGUI = screenGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = CONFIG.GUI.ThemeColor
    mainFrame.BackgroundTransparency = 1 - CONFIG.GUI.Opacity
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    State.MainFrame = mainFrame
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.GUI.AccentColor
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = CONFIG.GUI.AccentColor
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners not being rounded by creating a cover
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 10)
    titleCover.Position = UDim2.new(0, 0, 0, 30)
    titleCover.BackgroundColor3 = CONFIG.GUI.AccentColor
    titleCover.BackgroundTransparency = 0.2
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = CONFIG.GUI.TextColor
    titleLabel.Text = "🔫 PAINTBALL FPS KILLER ~ Steal a Brainrot"
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = CONFIG.GUI.FontSize + 4
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = titleBar
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.TextColor3 = CONFIG.GUI.TextColor
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = CONFIG.GUI.FontSize + 2
    closeButton.Parent = titleBar
    
    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    tabContainer.BackgroundTransparency = 0.3
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -95)
    contentArea.Position = UDim2.new(0, 10, 0, 80)
    contentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    contentArea.BackgroundTransparency = 0.4
    contentArea.BorderSizePixel = 0
    contentArea.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentArea
    
    -- Content ScrollingFrame
    local contentScrolling = Instance.new("ScrollingFrame")
    contentScrolling.Name = "ContentScrolling"
    contentScrolling.Size = UDim2.new(1, -10, 1, -10)
    contentScrolling.Position = UDim2.new(0, 5, 0, 5)
    contentScrolling.BackgroundTransparency = 1
    contentScrolling.BorderSizePixel = 0
    contentScrolling.ScrollBarThickness = 4
    contentScrolling.ScrollBarImageColor3 = CONFIG.GUI.AccentColor
    contentScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScrolling.Parent = contentArea
    
    -- Tab definitions
    local tabs = {
        {Name = "Main", Icon = "🎯"},
        {Name = "Steal", Icon = "💰"},
        {Name = "FPS", Icon = "💣"},        -- FPS Killer / Paintball
        {Name = "Move", Icon = "🚀"},       -- Movement
        {Name = "Visual", Icon = "👁️"},    -- ESP / Invis
        {Name = "Defense", Icon = "🛡️"},   -- Anti-Hit / Lock
        {Name = "Utils", Icon = "⚙️"},     -- Utility
        {Name = "Config", Icon = "🔧"},     -- Config
    }
    
    local tabButtons = {}
    local activeTab = nil
    
    for i, tabData in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabData.Name .. "Tab"
        tabButton.Size = UDim2.new(0, 85, 1, -6)
        tabButton.Position = UDim2.new(0, 3 + (i - 1) * 88, 0, 3)
        tabButton.BackgroundColor3 = CONFIG.GUI.AccentColor
        tabButton.BackgroundTransparency = 0.8
        tabButton.BorderSizePixel = 0
        tabButton.TextColor3 = CONFIG.GUI.TextColor
        tabButton.Text = tabData.Icon .. " " .. tabData.Name
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.TextSize = CONFIG.GUI.FontSize - 1
        tabButton.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tabButton
        
        tabButtons[tabData.Name] = tabButton
        
        tabButton.MouseButton1Click:Connect(function()
            -- Update active tab
            activeTab = tabData.Name
            -- Clear content
            for _, child in ipairs(contentScrolling:GetChildren()) do
                child:Destroy()
            end
            
            -- Update all tab visuals
            for _, btn in pairs(tabButtons) do
                btn.BackgroundTransparency = 0.8
                btn.TextTransparency = 0.3
            end
            tabButton.BackgroundTransparency = 0.3
            tabButton.TextTransparency = 0
            
            -- Populate content based on tab
            if tabData.Name == "Main" then
                createMainTabContent(contentScrolling)
            elseif tabData.Name == "Steal" then
                createStealTabContent(contentScrolling)
            elseif tabData.Name == "FPS" then
                createFPSTabContent(contentScrolling)
            elseif tabData.Name == "Move" then
                createMoveTabContent(contentScrolling)
            elseif tabData.Name == "Visual" then
                createVisualTabContent(contentScrolling)
            elseif tabData.Name == "Defense" then
                createDefenseTabContent(contentScrolling)
            elseif tabData.Name == "Utils" then
                elseif tabData.Name == "Utils" then
                createUtilsTabContent(contentScrolling)
            elseif tabData.Name == "Config" then
                createConfigTabContent(contentScrolling)
            end
        end)
    end
    
    -- Activate first tab by default
    if tabButtons["Main"] then
        tabButtons["Main"]:Fire("MouseButton1Click")
    end
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        State.MenuOpen = false
        screenGui:Destroy()
        State.ScreenGUI = nil
        State.MainFrame = nil
    end)
    
    -- Toggle menu visibility
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == CONFIG.GUI.ToggleKey then
            State.MenuOpen = not State.MenuOpen
            if State.ScreenGUI then
                State.ScreenGUI.Enabled = State.MenuOpen
            end
        end
    end)
end

-- 11.2: Helper function to create a toggle button
local function createToggle(parent, text, defaultValue, callback, yPos)
    yPos = yPos or 0
    
    local frame = Instance.new("Frame")
    frame.Name = text:gsub("[^%w]", "")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.Position = UDim2.new(0, 5, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 5)
    fCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = CONFIG.GUI.TextColor
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = CONFIG.GUI.FontSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
    toggleBtn.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = toggleBtn
    
    local isOn = defaultValue
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
        callback(isOn)
    end)
    
    return frame, toggleBtn
end

-- 11.3: Helper function to create a button
local function createActionButton(parent, text, callback, yPos, width)
    width = width or 200
    yPos = yPos or 0
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, width, 0, 35)
    button.Position = UDim2.new(0.5, -width/2, 0, yPos)
    button.BackgroundColor3 = CONFIG.GUI.AccentColor
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.TextColor3 = CONFIG.GUI.TextColor
    button.Text = text
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = CONFIG.GUI.FontSize
    button.Parent = parent
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.1
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0.3
    end)
    
    return button
end

-- 11.4: Helper function to create a slider
local function createSlider(parent, text, min, max, defaultValue, callback, yPos)
    yPos = yPos or 0
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.Position = UDim2.new(0, 5, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 5)
    fCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -10, 0.5, 0)
    label.Position = UDim2.new(0, 10, 0, 2)
    label.BackgroundTransparency = 1
    label.TextColor3 = CONFIG.GUI.TextColor
    label.Text = text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = CONFIG.GUI.FontSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, -10, 0.5, 0)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = CONFIG.GUI.AccentColor
    valueLabel.Text = tostring(defaultValue)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = CONFIG.GUI.FontSize
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 1, -12)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderBg.BackgroundTransparency = 0.3
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = CONFIG.GUI.AccentColor
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 16, 0, 16)
    sliderButton.Position = UDim2.new((defaultValue - min) / (max - min), -8, 0.5, -8)
    sliderButton.BackgroundColor3 = CONFIG.GUI.AccentColor
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderBg
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = sliderButton
    
    local currentValue = defaultValue
    local dragging = false
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
        local con1, con2
        con1 = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local mousePos = UserInputService:GetMouseLocation()
                local absPos = sliderBg.AbsolutePosition
                local absSize = sliderBg.AbsoluteSize
                local relX = clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
                currentValue = min + (max - min) * relX
                currentValue = math.floor(currentValue * 100) / 100
                sliderFill.Size = UDim2.new(relX, 0, 1, 0)
                sliderButton.Position = UDim2.new(relX, -8, 0.5, -8)
                valueLabel.Text = tostring(currentValue)
                callback(currentValue)
            end
        end)
        con2 = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragging = false
                con1:Disconnect()
                con2:Disconnect()
            end
        end)
    end)
    
    return frame
end

-- 11.5: Helper to create a section header
local function createSectionHeader(parent, text, yPos)
    yPos = yPos or 0
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -10, 0, 30)
    header.Position = UDim2.new(0, 5, 0, yPos)
    header.BackgroundTransparency = 1
    header.TextColor3 = CONFIG.GUI.AccentColor
    header.Text = "─── " .. text .. " ───"
    header.Font = Enum.Font.GothamBlack
    header.TextSize = CONFIG.GUI.FontSize + 2
    header.TextXAlignment = Enum.TextXAlignment.Center
    header.TextYAlignment = Enum.TextYAlignment.Center
    header.Parent = parent
    return header
end

-- ====================================================================
-- SECTION 12: TAB CONTENT BUILDERS
-- ====================================================================

-- 12.1: Main Tab
local function createMainTabContent(parent)
    local y = 5
    createSectionHeader(parent, "Paintball FPS Killer ~ Status", y)
    y = y + 35
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, y)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.Text = "All systems loaded. Use RightControl to toggle menu."
    statusLabel.Font = Enum.Font.GothamLight
    statusLabel.TextSize = CONFIG.GUI.FontSize - 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = parent
    y = y + 30
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -20, 0, 60)
    statsLabel.Position = UDim2.new(0, 10, 0, y)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = CONFIG.GUI.TextColor
    statsLabel.Text = "Game: Steal A Brainrot\nServer: " .. tostring(game.JobId) .. "\nPlayer: " .. LocalPlayer.DisplayName
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextSize = CONFIG.GUI.FontSize
    statsLabel.TextXAlignment = Enum.TextXAlignment.Center
    statsLabel.TextYAlignment = Enum.TextYAlignment.Center
    statsLabel.Parent = parent
    y = y + 70
    
    createSectionHeader(parent, "Quick Actions", y)
    y = y + 35
    
    y = y + createActionButton(parent, "🎯 Instant Steal Brainrot", function()
        performInstantSteal()
    end, y) + 45
    
    y = y + createActionButton(parent, "🏠 Teleport to Base", function()
        teleportToBase()
    end, y) + 45
    
    y = y + createActionButton(parent, "🦅 Fly to Best Brainrot", function()
        flyToHighBrainrot()
    end, y) + 45
    
    y = y + createActionButton(parent, "💰 Collect All Cash", function()
        local collected = collectCash()
        notify("Collected cash!", 2, "success")
    end, y) + 45
    
    y = y + createActionButton(parent, "🔄 Reset Steal Cooldown", function()
        State.LastStealTime = 0
        notify("Steal cooldown reset!", 1, "info")
    end, y) + 45
end

-- 12.2: Steal Tab
local function createStealTabContent(parent)
    local y = 5
    createSectionHeader(parent, "Brainrot Stealing System", y)
    y = y + 35
    
    y = y + createToggle(parent, "Instant Steal", CONFIG.Stealing.InstantSteal, function(val)
        CONFIG.Stealing.InstantSteal = val
        notify("Instant Steal: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Auto Steal (Loop)", CONFIG.Stealing.AutoSteal, function(val)
        CONFIG.Stealing.AutoSteal = val
        if val then
            startAutoStealLoop()
        end
        notify("Auto Steal: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createActionButton(parent, "⚡ Manual Instant Steal", function()
        performInstantSteal()
    end, y) + 45
    
    y = y + createActionButton(parent, "🦅 Fly to Highest Value Brainrot", function()
        flyToHighBrainrot()
    end, y) + 45
    
    y = y + createSectionHeader(parent, "Steal Settings", y)
    y = y + 35
    
    -- Steal range label
    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(1, -20, 0, 25)
    rangeLabel.Position = UDim2.new(0, 10, 0, y)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.TextColor3 = CONFIG.GUI.TextColor
    rangeLabel.Text = "Steal Range: " .. CONFIG.Stealing.StealRange .. " studs"
    rangeLabel.Font = Enum.Font.GothamMedium
    rangeLabel.TextSize = CONFIG.GUI.FontSize
    rangeLabel.Parent = parent
    y = y + 30
    
    -- Priority dropdown simulation (buttons)
    local priorities = {"Highest Value", "Lowest Value", "Nearest"}
    for _, p in ipairs(priorities) do
        local btn = createActionButton(parent, p, function()
            CONFIG.Stealing.PriorityRarity = p:match("(%a+)")
            notify("Priority set to: " .. p, 1)
        end, y, 180)
        y = y + 40
    end
    
    y = y + 5
    
    y = y + createActionButton(parent, "🔍 Scan Brainrots (List)", function()
        local brainrots = scanBrainrots()
        local msg = "Found " .. #brainrots .. " brainrots nearby:\n"
        local count = math.min(#brainrots, 10)
        for i = 1, count do
            msg = msg .. brainrots[i].Name .. " ($" .. (brainrots[i].Value or 0) .. ") [" .. math.floor(brainrots[i].Distance) .. "s]\n"
        end
        if #brainrots > 10 then
            msg = msg .. "... and " .. (#brainrots - 10) .. " more"
        end
        notify(msg, 5, "info")
    end, y) + 45
end

-- 12.3: FPS Killer / Paintball Tab
local function createFPSTabContent(parent)
    local y = 5
    createSectionHeader(parent, "🎯 Paintball Gun System", y)
    y = y + 35
    
    y = y + createToggle(parent, "Paintball Gun Enabled", CONFIG.Paintball.Enabled, function(val)
        CONFIG.Paintball.Enabled = val
        notify("Paintball Gun: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createActionButton(parent, "🔫 TEST FIRE Paintball", function()
        if CONFIG.Paintball.Enabled then
            local hitPos = Mouse.Hit.Position
            firePaintballProjectile(hitPos)
            notify("Paintball fired!", 1)
        else
            notify("Enable Paintball Gun first!", 1, "warn")
        end
    end, y) + 45
    
    y = y + createSectionHeader(parent, "💣 FPS Devourer (Lag Enemy)", y)
    y = y + 35
    
    y = y + createToggle(parent, "FPS Devourer Active", CONFIG.FPSDevourer.Enabled, function(val)
        CONFIG.FPSDevourer.Enabled = val
        if val then
            startFPSKillerLoop()
            notify("FPS DEVOURER ACTIVATED! Target will lag.", 2, "info")
        else
            notify("FPS Devourer deactivated.", 1)
        end
    end, y) + 40
    
    -- Target method buttons
    y = y + 5
    local methodsLabel = Instance.new("TextLabel")
    methodsLabel.Size = UDim2.new(1, -20, 0, 25)
    methodsLabel.Position = UDim2.new(0, 10, 0, y)
    methodsLabel.BackgroundTransparency = 1
    methodsLabel.TextColor3 = CONFIG.GUI.TextColor
    methodsLabel.Text = "Target Method: " .. CONFIG.FPSDevourer.TargetMethod
    methodsLabel.Font = Enum.Font.GothamMedium
    methodsLabel.TextSize = CONFIG.GUI.FontSize
    methodsLabel.Parent = parent
    y = y + 30
    
    y = y + createActionButton(parent, "Nearest Player", function()
        CONFIG.FPSDevourer.TargetMethod = "Nearest"
        notify("FPS Target: Nearest Player", 1)
    end, y, 180) + 40
    
    y = y + createActionButton(parent, "Mouse Target", function()
        CONFIG.FPSDevourer.TargetMethod = "MouseTarget"
        notify("FPS Target: Mouse Target", 1)
    end, y, 180) + 40
    
    y = y + createSlider(parent, "Lag Intensity", 0, 1, CONFIG.FPSDevourer.LagIntensity, function(val)
        CONFIG.FPSDevourer.LagIntensity = val
    end, y) + 50
    
    y = y + createSlider(parent, "Lag Radius (studs)", 10, 300, CONFIG.FPSDevourer.LagRadius, function(val)
        CONFIG.FPSDevourer.LagRadius = val
    end, y) + 50
    
    y = y + createSectionHeader(parent, "🎨 Paintball Config", y)
    y = y + 35
    
    y = y + createSlider(parent, "Fire Rate (sec)", 0.05, 1.0, CONFIG.Paintball.FireRate, function(val)
        CONFIG.Paintball.FireRate = val
    end, y) + 50
    
    y = y + createSlider(parent, "Projectile Range", 50, 1000, CONFIG.Paintball.Range, function(val)
        CONFIG.Paintball.Range = val
    end, y) + 50
    
    y = y + createActionButton(parent, "🎨 Change Beam Color (Red)", function()
        CONFIG.Paintball.BeamColor = Color3.fromRGB(255, 50, 50)
        notify("Beam color: Red", 1)
    end, y, 180) + 40
    
    y = y + createActionButton(parent, "🎨 Change Beam Color (Blue)", function()
        CONFIG.Paintball.BeamColor = Color3.fromRGB(50, 100, 255)
        notify("Beam color: Blue", 1)
    end, y, 180) + 40
    
    y = y + createActionButton(parent, "🎨 Change Beam Color (Green)", function()
        CONFIG.Paintball.BeamColor = Color3.fromRGB(50, 255, 50)
        notify("Beam color: Green", 1)
    end, y, 180) + 40
    
    y = y + createActionButton(parent, "🎨 Change Beam Color (Purple)", function()
        CONFIG.Paintball.BeamColor = Color3.fromRGB(200, 50, 255)
        notify("Beam color: Purple", 1)
    end, y, 180) + 40
end

-- 12.4: Movement Tab
local function createMoveTabContent(parent)
    local y = 5
    createSectionHeader(parent, "🚀 Movement Hacks", y)
    y = y + 35
    
    y = y + createToggle(parent, "Speed Boost (" .. CONFIG.Movement.SpeedMultiplier .. "x)", CONFIG.Movement.SpeedBoost, function(val)
        CONFIG.Movement.SpeedBoost = val
        State.OriginalWalkSpeed = LocalPlayer.Character and (getHumanoid(LocalPlayer.Character) and getHumanoid(LocalPlayer.Character).WalkSpeed or 16) or 16
        notify("Speed Boost: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Infinite Jump", CONFIG.Movement.InfiniteJump, function(val)
        CONFIG.Movement.InfiniteJump = val
        notify("Infinite Jump: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "NoClip (Walk Through Walls)", CONFIG.Movement.NoClip, function(val)
        CONFIG.Movement.NoClip = val
        notify("NoClip: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Float Mode (Hover)", CONFIG.Movement.FloatMode, function(val)
        CONFIG.Movement.FloatMode = val
        if val then CONFIG.Movement.FloatV2 = false end
        notify("Float Mode: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Float V2 (Advanced Flight)", CONFIG.Movement.FloatV2, function(val)
        CONFIG.Movement.FloatV2 = val
        if val then CONFIG.Movement.FloatMode = false end
        notify("Float V2: " .. (val and "ON" or "OFF") .. " (WASD+Space+Shift)", 1)
    end, y) + 40
    
    y = y + createSlider(parent, "Speed Multiplier", 1, 10, CONFIG.Movement.SpeedMultiplier, function(val)
        CONFIG.Movement.SpeedMultiplier = val
    end, y) + 50
    
    y = y + createSlider(parent, "Fly Speed", 10, 200, CONFIG.Movement.FlySpeed, function(val)
        CONFIG.Movement.FlySpeed = val
    end, y) + 50
    
    y = y + createSectionHeader(parent, "Teleport Actions", y)
    y = y + 35
    
    y = y + createActionButton(parent, "🏠 Teleport to My Base", function()
        teleportToBase()
    end, y) + 45
    
    y = y + createActionButton(parent, "📌 Teleport to Mouse Position", function()
        if LocalPlayer.Character then
            local root = getRootPart(LocalPlayer.Character)
            if root then
                root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
                notify("Teleported to mouse position!", 1)
            end
        end
    end, y) + 45
end

-- 12.5: Visual Tab
local function createVisualTabContent(parent)
    local y = 5
    createSectionHeader(parent, "👁️ ESP System", y)
    y = y + 35
    
    y = y + createToggle(parent, "ESP Enabled", CONFIG.Visual.ESP_Enabled, function(val)
        CONFIG.Visual.ESP_Enabled = val
        if not val then
            clearAllESP()
        end
        notify("ESP: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Show Distance", CONFIG.Visual.ESP_ShowDistance, function(val)
        CONFIG.Visual.ESP_ShowDistance = val
    end, y) + 40
    
    y = y + createToggle(parent, "Show Value", CONFIG.Visual.ESP_ShowValue, function(val)
        CONFIG.Visual.ESP_ShowValue = val
    end, y) + 40
    
    y = y + createSlider(parent, "ESP Max Distance", 50, 1000, CONFIG.Visual.ESP_MaxDistance, function(val)
        CONFIG.Visual.ESP_MaxDistance = val
    end, y) + 50
    
    y = y + createSectionHeader(parent, "Visibility", y)
    y = y + 35
    
    y = y + createToggle(parent, "Semi-Invisible Mode", CONFIG.Visual.SemiInvisible, function(val)
        CONFIG.Visual.SemiInvisible = val
        notify("Semi-Invisible: " .. (val and "ON" .. " (" .. math.floor(CONFIG.Visual.SemiInvisibleTransparency * 100) .. "% transparent)" or "OFF"), 1)
    end, y) + 40
    
    y = y + createSlider(parent, "Invisibility Level", 0, 1, CONFIG.Visual.SemiInvisibleTransparency, function(val)
        CONFIG.Visual.SemiInvisibleTransparency = val
    end, y) + 50
end

-- 12.6: Defense Tab
local function createDefenseTabContent(parent)
    local y = 5
    createSectionHeader(parent, "🛡️ Defense Systems", y)
    y = y + 35
    
    y = y + createToggle(parent, "Anti-Hit (Prevent Ragdoll)", CONFIG.Defense.AntiHit, function(val)
        CONFIG.Defense.AntiHit = val
        notify("Anti-Hit: " .. (val and "ON - You won't be knocked down!" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Anti-Ragdoll (Instant Recovery)", CONFIG.Defense.AntiRagdoll, function(val)
        CONFIG.Defense.AntiRagdoll = val
        notify("Anti-Ragdoll: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Auto Lock Base", CONFIG.Defense.AutoLockBase, function(val)
        CONFIG.Defense.AutoLockBase = val
        notify("Auto Lock Base: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createToggle(parent, "Anti-Grab Protection", CONFIG.Defense.AntiGrab, function(val)
        CONFIG.Defense.AntiGrab = val
        notify("Anti-Grab: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createSectionHeader(parent, "Defense Actions", y)
    y = y + 35
    
    y = y + createActionButton(parent, "🔒 Lock My Base Now", function()
        -- Find and trigger lock button
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ClickDetector") then
                local parent = v.Parent
                if parent and (string.find(parent.Name, "Lock") or string.find(parent.Name, "lock")) then
                    pcall(function() fireclickdetector(v) end)
                    notify("Base locked!", 1, "success")
                    break
                end
            end
        end
    end, y) + 45
    
    y = y + createActionButton(parent, "🔄 Reset Character (Escape)", function()
        if LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid and humanoid.Health > 0 then
                humanoid.Health = 0
                notify("Character reset!", 1)
            end
        end
    end, y) + 45
end

-- 12.7: Utils Tab
local function createUtilsTabContent(parent)
    local y = 5
    createSectionHeader(parent, "⚙️ Utility Features", y)
    y = y + 35
    
    y = y + createToggle(parent, "Auto Collect Cash", CONFIG.Utility.CollectCash, function(val)
        CONFIG.Utility.CollectCash = val
        notify("Auto Collect Cash: " .. (val and "ON" or "OFF"), 1)
    end, y) + 40
    
    y = y + createActionButton(parent, "💰 Collect Cash Now", function()
        local collected = collectCash()
        notify("Collected from " .. collected .. " sources!", 2)
    end, y) + 45
    
    y = y + createActionButton(parent, "🔄 Server Hop", function()
        notify("Server hopping...", 2)
        local placeId = game.PlaceId
        local jobId = game.JobId
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end, y) + 45
    
    y = y + createSectionHeader(parent, "Info & Debug", y)
    y = y + 35
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 0, 100)
    infoLabel.Position = UDim2.new(0, 10, 0, y)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    infoLabel.Text = "Place ID: " .. game.PlaceId .. "\nJob ID: " .. game.JobId .. "\nPlayers: " .. #Players:GetPlayers() .. "\nFPS: ~" .. math.floor(1 / (RunService.Heartbeat:Wait() + 0.0001)) or "calculating..."
    infoLabel.Font = Enum.Font.GothamLight
    infoLabel.TextSize = CONFIG.GUI.FontSize - 1
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = parent
    y = y + 110
    
    y = y + createActionButton(parent, "🔄 Refresh Info", function()
        infoLabel.Text = "Place ID: " .. game.PlaceId .. "\nJob ID: " .. game.JobId .. "\nPlayers: " .. #Players:GetPlayers() .. "\nFPS: ~calculating..."
        notify("Info refreshed!", 1)
    end, y) + 45
    
    y = y + createActionButton(parent, "🎯 Targeted Player Info", function()
        local target = getMouseTargetPlayer() or getNearestPlayer(30)
        if target then
            local char = target.Character
            local root = char and getRootPart(char)
            local dist = root and (root.Position - Camera.CFrame.Position).Magnitude or 0
            notify(target.DisplayName .. " - " .. math.floor(dist) .. " studs away", 3)
        else
            notify("No target nearby!", 2)
        end
    end, y) + 45
end

-- 12.8: Config Tab
local function createConfigTabContent(parent)
    local y = 5
    createSectionHeader(parent, "🔧 Configuration", y)
    y = y + 35
    
    y = y + createActionButton(parent, "💾 Save Current Config", function()
        CONFIG._saved = deepCopy(CONFIG)
        notify("Configuration saved to memory!", 2)
    end, y) + 45
    
    y = y + createActionButton(parent, "📂 Load Saved Config", function()
        if CONFIG._saved then
            for k, v in pairs(CONFIG._saved) do
                if k ~= "_saved" then
                    CONFIG[k] = deepCopy(v)
                end
            end
            notify("Configuration loaded!", 2)
        else
            notify("No saved config found!", 2, "warn")
        end
    end, y) + 45
    
    y = y + createActionButton(parent, "🔄 Reset All to Defaults", function()
        -- Reset to hardcoded defaults (would need to store them)
        notify("Reload the script to reset defaults!", 2)
    end, y) + 45
    
    y = y + createSectionHeader(parent, "Keybinds", y)
    y = y + 35
    
    local keybindInfo = Instance.new("TextLabel")
    keybindInfo.Size = UDim2.new(1, -20, 0, 120)
    keybindInfo.Position = UDim2.new(0, 10, 0, y)
    keybindInfo.BackgroundTransparency = 1
    keybindInfo.TextColor3 = CONFIG.GUI.TextColor
    keybindInfo.Text = [[Keybinds:
  RightControl - Toggle Menu
  T - Instant Steal
  B - Teleport to Base
  LeftShift - Speed Boost
  N - Toggle NoClip
  Space - Jump / Infinite Jump]]
    keybindInfo.Font = Enum.Font.GothamMedium
    keybindInfo.TextSize = CONFIG.GUI.FontSize - 1
    keybindInfo.TextXAlignment = Enum.TextXAlignment.Left
    keybindInfo.TextYAlignment = Enum.TextYAlignment.Top
    keybindInfo.Parent = parent
    y = y + 130
    
    y = y + createSectionHeader(parent, "Status Indicators", y)
    y = y + 35
    
    local indicators = Instance.new("TextLabel")
    indicators.Size = UDim2.new(1, -20, 0, 80)
    indicators.Position = UDim2.new(0, 10, 0, y)
    indicators.BackgroundTransparency = 1
    indicators.TextColor3 = Color3.fromRGB(180, 180, 180)
    indicators.Text = "Status monitoring active...\nCheck individual tabs for toggle states."
    indicators.Font = Enum.Font.GothamLight
    indicators.TextSize = CONFIG.GUI.FontSize - 1
    indicators.TextXAlignment = Enum.TextXAlignment.Left
    indicators.TextYAlignment = Enum.TextYAlignment.Top
    indicators.Parent = parent
end

-- ====================================================================
-- SECTION 13: KEYBIND HANDLER
-- ====================================================================

-- 13.1: Setup keybind handling
local function setupKeybinds()
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- T - Instant Steal
        if input.KeyCode == CONFIG.Keybinds.InstantSteal then
            performInstantSteal()
        end
        
        -- B - Teleport to base
        if input.KeyCode == CONFIG.Keybinds.TeleportToBase then
            teleportToBase()
        end
        
        -- LeftShift - Speed Boost toggle
        if input.KeyCode == CONFIG.Keybinds.SpeedBoost then
            CONFIG.Movement.SpeedBoost = not CONFIG.Movement.SpeedBoost
            notify("Speed Boost: " .. (CONFIG.Movement.SpeedBoost and "ON" or "OFF"), 1)
        end
        
        -- N - NoClip toggle
        if input.KeyCode == CONFIG.Keybinds.NoClip then
            CONFIG.Movement.NoClip = not CONFIG.Movement.NoClip
            notify("NoClip: " .. (CONFIG.Movement.NoClip and "ON" or "OFF"), 1)
        end
        
        -- Space - Infinite Jump handled separately in setupInfiniteJump
    end)
    table.insert(State.Connections, connection)
    
    -- Mouse button handling for paintball
    local mouseConnection
    mouseConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if CONFIG.Paintball.Enabled then
                handlePaintballShot()
            end
        end
    end)
    table.insert(State.Connections, mouseConnection)
end

-- ====================================================================
-- SECTION 14: INITIALIZATION AND CLEANUP
-- ====================================================================

-- 14.1: Store original values
local function storeOriginalValues()
    if LocalPlayer.Character then
        local humanoid = getHumanoid(LocalPlayer.Character)
        if humanoid then
            State.OriginalWalkSpeed = humanoid.WalkSpeed
            State.OriginalJumpPower = humanoid.JumpPower
        end
    end
end

-- 14.2: Setup character added handler
local function setupCharacterHandler()
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        local humanoid = getHumanoid(character)
        if humanoid then
            State.OriginalWalkSpeed = humanoid.WalkSpeed
            State.OriginalJumpPower = humanoid.JumpPower
        end
    end)
end

-- 14.3: Cleanup function
local function cleanup()
    log("Cleaning up PaintballFPSKiller...", "INFO")
    
    -- Disconnect all event connections
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    
    -- Disconnect all loop connections
    for _, conn in ipairs(State.LoopConnections) do
        pcall(function() conn:Disconnect() end)
    end
    State.LoopConnections = {}
    
    -- Clear all ESP
    clearAllESP()
    
    -- Reset character properties
    if LocalPlayer.Character then
        local humanoid = getHumanoid(LocalPlayer.Character)
        if humanoid then
            humanoid.WalkSpeed = State.OriginalWalkSpeed
            humanoid.JumpPower = State.OriginalJumpPower
            humanoid.AutoRotate = true
        end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
                part.CanCollide = true
            end
        end
    end
    
    -- Destroy GUI
    if State.ScreenGUI then
        pcall(function() State.ScreenGUI:Destroy() end)
        State.ScreenGUI = nil
    end
    
    -- Reset state
    CONFIG.Movement.SpeedBoost = false
    CONFIG.Movement.FloatMode = false
    CONFIG.Movement.FloatV2 = false
    CONFIG.Movement.NoClip = false
    CONFIG.Movement.InfiniteJump = false
    CONFIG.Visual.SemiInvisible = false
    CONFIG.Visual.ESP_Enabled = false
    CONFIG.FPSDevourer.Enabled = false
    CONFIG.Stealing.AutoSteal = false
    CONFIG.Defense.AntiHit = false
    CONFIG.Defense.AutoLockBase = false
    CONFIG.Paintball.Enabled = false
    
    log("Cleanup complete!", "INFO")
end

-- 14.4: Main initialization
local function initialize()
    log("========================================", "INFO")
    log("Paintball FPS Killer ~ Steal a Brainrot", "INFO")
    log("Target: Steal A Brainrot (85576158646206)", "INFO")
    log("Initializing systems...", "INFO")
    log("========================================", "INFO")
    
    -- Verify we're in the correct game
    if game.PlaceId ~= 85576158646206 then
        warn("WARNING: This script is designed for 'Steal A Brainrot' (85576158646206)")
        warn("Current game ID: " .. game.PlaceId)
    end
    
    -- Wait for game to load
    task.wait(1)
    
    -- Store original values
    storeOriginalValues()
    
    -- Setup character handler
    setupCharacterHandler()
    
    -- Setup all systems
    setupInfiniteJump()
    setupNoClip()
    setupSpeedBoost()
    setupFloatMode()
    setupFloatV2()
    setupSemiInvisible()
    setupAntiHit()
    setupAntiRagdoll()
    setupAutoLockBase()
    setupAutoCollectCash()
    setupESPLoop()
    setupKeybinds()
    
    -- Create GUI
    createGUI()
    
    log("All systems initialized successfully!", "INFO")
    log("Press RightControl to toggle menu", "INFO")
    log("Click to fire paintball (when enabled)", "INFO")
    log("========================================", "INFO")
    
    -- Startup notification
    notify("🔫 Paintball FPS Killer loaded! RightControl to toggle menu.", 5, "info")
end

-- 14.5: Start the script
local success, err = pcall(function()
    initialize()
end)

if not success then
    warn("[PaintballFPS-CRITICAL] Failed to initialize: " .. tostring(err))
    warn("[PaintballFPS-CRITICAL] Stack trace: " .. debug and debug.traceback() or "N/A")
    
    -- Attempt fallback initialization
    pcall(function()
        storeOriginalValues()
        setupKeybinds()
        createGUI()
        notify("⚠️ Paintball FPS Killer (fallback mode) - Some features may be limited.", 5, "warn")
    end)
end

-- Return cleanup function for executor
return {
    Unload = cleanup,
    Config = CONFIG,
    State = State,
    Version = "1.0.0",
    Author = "PaintballFPSKiller",
    Description = "Paintball FPS Killer ~ Steal a Brainrot - Complete feature set from YouTube video",
    
    -- Expose functions for scripting
    Functions = {
        PerformInstantSteal = performInstantSteal,
        TeleportToBase = teleportToBase,
        FirePaintball = firePaintballProjectile,
        CollectCash = collectCash,
        ScanBrainrots = scanBrainrots,
        FlyToHighBrainrot = flyToHighBrainrot,
        ExecuteFPSKiller = executeFPSKiller,
    }
}

