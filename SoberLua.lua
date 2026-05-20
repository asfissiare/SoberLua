-- // Secure Environment Setup
local gethui = gethui or function() return game:GetService("CoreGui") end
local CoreGui = gethui()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Safe Anti-Detection Guard (Targeted service metatable hooking)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if checkcaller() then return oldIndex(self, key) end
    if key == "DescendantAdded" or key == "ChildAdded" then return function() end end
    return oldIndex(self, key)
end)

-- // Configuration Dictionary (Merged SilentAim, Orbit, Anti-Aim, VoidSpam, Sound)
local Config = {
    -- SilentAim
    SilentAim = {
        Enabled = false,
        FOV = 150,
        Smoothing = 0,
        HitPart = "Head",
        TeamCheck = true,
        VisibleCheck = true
    },
    FOVCircle = Drawing.new("Circle"),
    -- Anti-Aim
    AntiAim = {
        Enabled = false,
        Mode = "None",
        Speed = 15,
        JitterRange = 45,
        Pitch = "None"
    },
    -- VoidHide
    VoidHide = {
        Enabled = false,
        DistancePercent = 5,
        HeightOffset = 0,
        Mode = "None",
        SpinSpeed = 10,
        OrbitSpeed = 1.5,
        OrbitRadius = 25,
        FloatSpeed = 2,
        FloatIntensity = 5,
        DesyncSpeed = 50
    },
    -- Sounds
    Sounds = {
        Enabled = true,
        SoundId = "rbxassetid://719384308",
        Volume = 0.5
    }
}

-- // Initialize FOVCircle
Config.FOVCircle.Radius = Config.SilentAim.FOV
Config.FOVCircle.Color = Color3.fromRGB(0, 255, 204)
Config.FOVCircle.Thickness = 1.5
Config.FOVCircle.Visible = false

-- // Type-Safe Raycast Hooking (Fixed parameter dropping)
local OldRaycast
OldRaycast = hookfunction(workspace.Raycast, function(origin, direction, raycastParams, ...)
    if not checkcaller() and Config.SilentAim.Enabled then
        local ClosestPlayer = GetClosestPlayer()
        if ClosestPlayer and ClosestPlayer.Character then
            local HitPart = ClosestPlayer.Character:FindFirstChild(Config.SilentAim.HitPart)
            if HitPart then
                direction = (HitPart.Position - origin).Unit * 1000
            end
        end
    end
    return OldRaycast(origin, direction, raycastParams, ...)
end)

-- // Optimized Target Acquisition Pipeline
local function GetClosestPlayer()
    local ClosestDistance = math.huge
    local ClosestPlayer = nil
    local CameraCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if Config.SilentAim.TeamCheck and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end

        local Head = Character:FindFirstChild("Head")
        if not Head then continue end

        local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Head.Position)
        if not OnScreen then continue end

        local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - CameraCenter).Magnitude
        if Distance < ClosestDistance and Distance <= Config.SilentAim.FOV then
            ClosestPlayer = Player
            ClosestDistance = Distance
        end
    end
    return ClosestPlayer
end

-- // Character State Validation
local function IsCharacterValid()
    local Character = LocalPlayer.Character
    if not Character then return false end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end

    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end

    return true
end

-- // State Tracking
local CurrentCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = CurrentCharacter:WaitForChild("HumanoidRootPart")
local Humanoid = CurrentCharacter:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
    CurrentCharacter = NewCharacter
    RootPart = NewCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

-- // Placeholder for Module 2 continuation

-- // MODULE 2: COMBAT & PHYSICS ENGINE
-- // Combat Engine (SilentAim, TriggerBot, HitChams)
local Combat = {
    SilentAim = Config.SilentAim,
    TriggerBot = {
        Enabled = false,
        Delay = 0.1,
        HitPart = "Head"
    },
    HitChams = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Duration = 0.5
    }
}

-- // Physics Engine (VoidHide, AntiAim, Desync)
local Physics = {
    VoidHide = Config.VoidHide,
    AntiAim = Config.AntiAim,
    Desync = {
        Enabled = false,
        Intensity = 10,
        Mode = "Horizontal"
    }
}

-- // Sound Engine
local SoundEngine = {
    Enabled = Config.Sounds.Enabled,
    SoundId = Config.Sounds.SoundId,
    Volume = Config.Sounds.Volume,
    SoundInstance = nil
}

-- // Initialize Sound Engine
if SoundEngine.Enabled then
    SoundEngine.SoundInstance = Instance.new("Sound", game:GetService("SoundService"))
    SoundEngine.SoundInstance.SoundId = SoundEngine.SoundId
    SoundEngine.SoundInstance.Volume = SoundEngine.Volume
    SoundEngine.SoundInstance:Play()
end

-- // SilentAim Visualization
local function UpdateFOVCircle()
    Config.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    Config.FOVCircle.Visible = Combat.SilentAim.Enabled
end

RunService.RenderStepped:Connect(UpdateFOVCircle)

-- // Optimized Target Acquisition with Caching
local TargetCache = {
    LastTarget = nil,
    LastUpdate = 0,
    CacheDuration = 0.1
}

local function GetCachedClosestPlayer()
    if tick() - TargetCache.LastUpdate < TargetCache.CacheDuration and TargetCache.LastTarget then
        return TargetCache.LastTarget
    end

    local ClosestPlayer = GetClosestPlayer()
    if ClosestPlayer then
        TargetCache.LastTarget = ClosestPlayer
        TargetCache.LastUpdate = tick()
    end
    return ClosestPlayer
end

-- // TriggerBot Implementation
local function TriggerBot()
    if not Combat.TriggerBot.Enabled or not IsCharacterValid() then return end

    local ClosestPlayer = GetCachedClosestPlayer()
    if not ClosestPlayer then return end

    local Character = ClosestPlayer.Character
    if not Character then return end

    local HitPart = Character:FindFirstChild(Combat.TriggerBot.HitPart)
    if not HitPart then return end

    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(HitPart.Position)
    if not OnScreen then return end

    local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
    if Distance <= 10 then
        task.wait(Combat.TriggerBot.Delay)
        mouse1click()
    end
end

-- // HitChams Implementation
local function ApplyHitChams(Player)
    if not Combat.HitChams.Enabled or not Player.Character then return end

    local HitPart = Player.Character:FindFirstChild("Head")
    if not HitPart then return end

    local Cham = Instance.new("BoxHandleAdornment")
    Cham.Adornee = HitPart
    Cham.Color3 = Combat.HitChams.Color
    Cham.AlwaysOnTop = true
    Cham.ZIndex = 10
    Cham.Size = Vector3.new(2, 2, 2)
    Cham.Transparency = 0.5
    Cham.Parent = HitPart

    task.delay(Combat.HitChams.Duration, function()
        Cham:Destroy()
    end)
end

-- // AntiAim Engine
local function ApplyAntiAim()
    if not Physics.AntiAim.Enabled or not IsCharacterValid() then return end

    local PitchAngle = 0
    local YawAngle = 0

    -- // Pitch Control
    if Physics.AntiAim.Pitch == "Down" then
        PitchAngle = math.rad(-90)
    elseif Physics.AntiAim.Pitch == "Up" then
        PitchAngle = math.rad(90)
    elseif Physics.AntiAim.Pitch == "Flip" then
        PitchAngle = math.rad(-180)
    end

    -- // Yaw Control
    if Physics.AntiAim.Mode == "Jitter" then
        YawAngle = math.rad(math.random(-Physics.AntiAim.JitterRange, Physics.AntiAim.JitterRange))
    elseif Physics.AntiAim.Mode == "Sway" then
        YawAngle = math.sin(tick() * (Physics.AntiAim.Speed / 5)) * math.rad(Physics.AntiAim.JitterRange)
    elseif Physics.AntiAim.Mode == "Inverter" then
        YawAngle = (math.floor(tick() * 2) % 2 == 0) and 0 or math.rad(180)
    end

    RootPart.CFrame = RootPart.CFrame * CFrame.Angles(PitchAngle, YawAngle, 0)
end

-- // Desync Engine (Subtle Replication Desynchronization)
local function ApplyDesync()
    if not Physics.Desync.Enabled or not IsCharacterValid() then return end

    local DesyncOffset = Vector3.new(
        math.sin(tick() * Physics.Desync.Intensity) * 2,
        0,
        math.cos(tick() * Physics.Desync.Intensity) * 2
    )

    if Physics.Desync.Mode == "Horizontal" then
        RootPart.CFrame = RootPart.CFrame + DesyncOffset
    elseif Physics.Desync.Mode == "Vertical" then
        RootPart.CFrame = RootPart.CFrame + Vector3.new(0, DesyncOffset.Y, 0)
    end
end

-- // VoidHide Engine (Subtle Replication Desynchronization)
local function ApplyVoidHide()
    if not Physics.VoidHide.Enabled or not IsCharacterValid() then return end

    local Time = tick()
    local VoidDistance = Physics.VoidHide.DistancePercent * 250000
    local HeightOffset = Physics.VoidHide.HeightOffset

    local CFrameOffset = CFrame.new(0, VoidDistance + HeightOffset, 0)

    if Physics.VoidHide.Mode == "Spin" then
        RootPart.CFrame = CFrameOffset * CFrame.Angles(0, Time * Physics.VoidHide.SpinSpeed, 0)
    elseif Physics.VoidHide.Mode == "Orbit" then
        local X = math.cos(Time * Physics.VoidHide.OrbitSpeed) * Physics.VoidHide.OrbitRadius
        local Z = math.sin(Time * Physics.VoidHide.OrbitSpeed) * Physics.VoidHide.OrbitRadius
        RootPart.CFrame = CFrame.new(X, VoidDistance + HeightOffset, Z)
    elseif Physics.VoidHide.Mode == "Desync" then
        local DesyncOffset = Vector3.new(
            math.sin(Time * Physics.VoidHide.DesyncSpeed) * 10,
            0,
            math.cos(Time * Physics.VoidHide.DesyncSpeed) * 10
        )
        RootPart.CFrame = CFrameOffset * CFrame.new(DesyncOffset)
    end
end

-- // Main Execution Loop
RunService.Heartbeat:Connect(function()
    if not IsCharacterValid() then return end

    -- // Combat Systems
    TriggerBot()
    if Combat.SilentAim.Enabled then
        local ClosestPlayer = GetCachedClosestPlayer()
        if ClosestPlayer then
            ApplyHitChams(ClosestPlayer)
        end
    end

    -- // Physics Systems
    if Physics.VoidHide.Enabled then
        ApplyVoidHide()
    end

    if Physics.AntiAim.Enabled then
        ApplyAntiAim()
    end

    if Physics.Desync.Enabled then
        ApplyDesync()
    end
end)

-- // Placeholder for Module 3 continuation

-- // MODULE 3: VISUALS & UI INTEGRATION
-- // Visual Engine (ESP, Chams, Tracers, Crosshair)
local Visuals = {
    ESP = {
        Enabled = false,
        TeamCheck = true,
        Boxes = true,
        HealthBars = true,
        Names = true,
        Distance = true,
        Tracers = true,
        Chams = true,
        Color = {
            Enemy = Color3.fromRGB(255, 0, 0),
            Ally = Color3.fromRGB(0, 255, 0),
            Visible = Color3.fromRGB(255, 255, 0)
        }
    },
    Crosshair = {
        Enabled = false,
        Size = 10,
        Gap = 5,
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255)
    },
    World = {
        Fullbright = false,
        Ambient = Color3.fromRGB(100, 100, 100),
        Outlines = false
    }
}

-- // UI Engine (Window, Tabs, Groupboxes)
local UI = {
    Window = nil,
    Tabs = {},
    Config = {}
}

-- // Initialize UI Library (Assuming Kavo UI Library)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
UI.Window = Library.CreateLib("Rivals HvH Suite", "DarkTheme")

-- // Create Tabs
UI.Tabs.Combat = UI.Window:NewTab("Combat")
UI.Tabs.Visuals = UI.Window:NewTab("Visuals")
UI.Tabs.Physics = UI.Window:NewTab("Physics")
UI.Tabs.Config = UI.Window:NewTab("Configuration")

-- // Combat Tab
local CombatTab = {
    SilentAim = UI.Tabs.Combat:NewSection("SilentAim"),
    TriggerBot = UI.Tabs.Combat:NewSection("TriggerBot"),
    HitChams = UI.Tabs.Combat:NewSection("HitChams")
}

-- // SilentAim Configuration
CombatTab.SilentAim:AddToggle("SilentAimToggle", {
    Text = "Enable SilentAim",
    Default = Combat.SilentAim.Enabled,
    Callback = function(state)
        Combat.SilentAim.Enabled = state
    end
})

CombatTab.SilentAim:AddSlider("SilentAimFOV", {
    Text = "FOV Radius",
    Min = 10,
    Max = 500,
    Default = Combat.SilentAim.FOV,
    Callback = function(value)
        Combat.SilentAim.FOV = value
        Config.FOVCircle.Radius = value
    end
})

CombatTab.SilentAim:AddDropdown("SilentAimHitPart", {
    Text = "Hit Part",
    Values = {"Head", "Torso", "Random"},
    Default = Combat.SilentAim.HitPart,
    Callback = function(value)
        Combat.SilentAim.HitPart = value
    end
})

CombatTab.SilentAim:AddToggle("SilentAimTeamCheck", {
    Text = "Team Check",
    Default = Combat.SilentAim.TeamCheck,
    Callback = function(state)
        Combat.SilentAim.TeamCheck = state
    end
})

-- // TriggerBot Configuration
CombatTab.TriggerBot:AddToggle("TriggerBotToggle", {
    Text = "Enable TriggerBot",
    Default = Combat.TriggerBot.Enabled,
    Callback = function(state)
        Combat.TriggerBot.Enabled = state
    end
})

CombatTab.TriggerBot:AddSlider("TriggerBotDelay", {
    Text = "Trigger Delay (s)",
    Min = 0,
    Max = 1,
    Default = Combat.TriggerBot.Delay,
    Decimals = 2,
    Callback = function(value)
        Combat.TriggerBot.Delay = value
    end
})

-- // HitChams Configuration
CombatTab.HitChams:AddToggle("HitChamsToggle", {
    Text = "Enable HitChams",
    Default = Combat.HitChams.Enabled,
    Callback = function(state)
        Combat.HitChams.Enabled = state
    end
})

CombatTab.HitChams:AddColorPicker("HitChamsColor", {
    Text = "Cham Color",
    Default = Combat.HitChams.Color,
    Callback = function(color)
        Combat.HitChams.Color = color
    end
})

-- // Visuals Tab
local VisualsTab = {
    ESP = UI.Tabs.Visuals:NewSection("ESP"),
    Crosshair = UI.Tabs.Visuals:NewSection("Crosshair"),
    World = UI.Tabs.Visuals:NewSection("World")
}

-- // ESP Configuration
VisualsTab.ESP:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = Visuals.ESP.Enabled,
    Callback = function(state)
        Visuals.ESP.Enabled = state
    end
})

VisualsTab.ESP:AddToggle("ESPBoxes", {
    Text = "Boxes",
    Default = Visuals.ESP.Boxes,
    Callback = function(state)
        Visuals.ESP.Boxes = state
    end
})

VisualsTab.ESP:AddToggle("ESPHealthBars", {
    Text = "Health Bars",
    Default = Visuals.ESP.HealthBars,
    Callback = function(state)
        Visuals.ESP.HealthBars = state
    end
})

VisualsTab.ESP:AddToggle("ESPNames", {
    Text = "Names",
    Default = Visuals.ESP.Names,
    Callback = function(state)
        Visuals.ESP.Names = state
    end
})

VisualsTab.ESP:AddToggle("ESPDistance", {
    Text = "Distance",
    Default = Visuals.ESP.Distance,
    Callback = function(state)
        Visuals.ESP.Distance = state
    end
})

VisualsTab.ESP:AddToggle("ESPTracers", {
    Text = "Tracers",
    Default = Visuals.ESP.Tracers,
    Callback = function(state)
        Visuals.ESP.Tracers = state
    end
})

VisualsTab.ESP:AddToggle("ESPChams", {
    Text = "Chams",
    Default = Visuals.ESP.Chams,
    Callback = function(state)
        Visuals.ESP.Chams = state
    end
})

-- // Crosshair Configuration
VisualsTab.Crosshair:AddToggle("CrosshairEnabled", {
    Text = "Enable Crosshair",
    Default = Visuals.Crosshair.Enabled,
    Callback = function(state)
        Visuals.Crosshair.Enabled = state
    end
})

VisualsTab.Crosshair:AddSlider("CrosshairSize", {
    Text = "Size",
    Min = 5,
    Max = 20,
    Default = Visuals.Crosshair.Size,
    Callback = function(value)
        Visuals.Crosshair.Size = value
    end
})

VisualsTab.Crosshair:AddSlider("CrosshairGap", {
    Text = "Gap",
    Min = 0,
    Max = 20,
    Default = Visuals.Crosshair.Gap,
    Callback = function(value)
        Visuals.Crosshair.Gap = value
    end
})

VisualsTab.Crosshair:AddSlider("CrosshairThickness", {
    Text = "Thickness",
    Min = 1,
    Max = 5,
    Default = Visuals.Crosshair.Thickness,
    Callback = function(value)
        Visuals.Crosshair.Thickness = value
    end
})

-- // World Configuration
VisualsTab.World:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = Visuals.World.Fullbright,
    Callback = function(state)
        Visuals.World.Fullbright = state
        if state then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").ClockTime = 0
            game:GetService("Lighting").FogEnd = 1000
        end
    end
})

VisualsTab.World:AddColorPicker("AmbientColor", {
    Text = "Ambient Color",
    Default = Visuals.World.Ambient,
    Callback = function(color)
        Visuals.World.Ambient = color
        game:GetService("Lighting").Ambient = color
    end
})

-- // Physics Tab
local PhysicsTab = {
    VoidHide = UI.Tabs.Physics:NewSection("VoidHide"),
    AntiAim = UI.Tabs.Physics:NewSection("AntiAim"),
    Desync = UI.Tabs.Physics:NewSection("Desync")
}

-- // VoidHide Configuration
PhysicsTab.VoidHide:AddToggle("VoidHideEnabled", {
    Text = "Enable VoidHide",
    Default = Physics.VoidHide.Enabled,
    Callback = function(state)
        Physics.VoidHide.Enabled = state
    end
})

PhysicsTab.VoidHide:AddDropdown("VoidHideMode", {
    Text = "Movement Pattern",
    Values = {"Spin", "Orbit", "Desync", "None"},
    Default = Physics.VoidHide.Mode,
    Callback = function(value)
        Physics.VoidHide.Mode = value
    end
})

PhysicsTab.VoidHide:AddSlider("VoidHideDistance", {
    Text = "Distance Percent",
    Min = 1,
    Max = 100,
    Default = Physics.VoidHide.DistancePercent,
    Callback = function(value)
        Physics.VoidHide.DistancePercent = value
    end
})

-- // AntiAim Configuration
PhysicsTab.AntiAim:AddToggle("AntiAimEnabled", {
    Text = "Enable AntiAim",
    Default = Physics.AntiAim.Enabled,
    Callback = function(state)
        Physics.AntiAim.Enabled = state
    end
})

PhysicsTab.AntiAim:AddDropdown("AntiAimPitch", {
    Text = "Pitch Angle",
    Values = {"None", "Up", "Down", "Flip"},
    Default = Physics.AntiAim.Pitch,
    Callback = function(value)
        Physics.AntiAim.Pitch = value
    end
})

PhysicsTab.AntiAim:AddDropdown("AntiAimMode", {
    Text = "AntiAim Type",
    Values = {"None", "Jitter", "Sway", "Inverter"},
    Default = Physics.AntiAim.Mode,
    Callback = function(value)
        Physics.AntiAim.Mode = value
    end
})

PhysicsTab.AntiAim:AddSlider("AntiAimSpeed", {
    Text = "Speed",
    Min = 1,
    Max = 50,
    Default = Physics.AntiAim.Speed,
    Callback = function(value)
        Physics.AntiAim.Speed = value
    end
})

-- // Desync Configuration
PhysicsTab.Desync:AddToggle("DesyncEnabled", {
    Text = "Enable Desync",
    Default = Physics.Desync.Enabled,
    Callback = function(state)
        Physics.Desync.Enabled = state
    end
})

PhysicsTab.Desync:AddDropdown("DesyncMode", {
    Text = "Desync Mode",
    Values = {"Horizontal", "Vertical"},
    Default = Physics.Desync.Mode,
    Callback = function(value)
        Physics.Desync.Mode = value
    end
})

PhysicsTab.Desync:AddSlider("DesyncIntensity", {
    Text = "Intensity",
    Min = 1,
    Max = 50,
    Default = Physics.Desync.Intensity,
    Callback = function(value)
        Physics.Desync.Intensity = value
    end
})

-- // Configuration Tab
local ConfigTab = UI.Tabs.Config:NewSection("Configuration")

ConfigTab:AddButton("Save Configuration", function()
    local ConfigData = {
        SilentAim = Combat.SilentAim,
        TriggerBot = Combat.TriggerBot,
        HitChams = Combat.HitChams,
        VoidHide = Physics.VoidHide,
        AntiAim = Physics.AntiAim,
        Desync = Physics.Desync,
        Visuals = Visuals
    }

    writefile("RivalsHvHConfig.json", game:GetService("HttpService"):JSONEncode(ConfigData))
end)

ConfigTab:AddButton("Load Configuration", function()
    if not isfile("RivalsHvHConfig.json") then return end

    local ConfigData = game:GetService("HttpService"):JSONDecode(readfile("RivalsHvHConfig.json"))

    Combat.SilentAim = ConfigData.SilentAim
    Combat.TriggerBot = ConfigData.TriggerBot
    Combat.HitChams = ConfigData.HitChams
    Physics.VoidHide = ConfigData.VoidHide
    Physics.AntiAim = ConfigData.AntiAim
    Physics.Desync = ConfigData.Desync
    Visuals = ConfigData.Visuals

    -- // Update UI to match loaded config
    Library:UpdateAll()
end)

-- // ESP Engine
local ESPObjects = {}

local function CreateESP(Player)
    if ESPObjects[Player] then return end

    local ESP = {
        Box = nil,
        HealthBar = nil,
        NameLabel = nil,
        DistanceLabel = nil,
        Tracer = nil,
        Cham = nil
    }

    -- // Box
    if Visuals.ESP.Boxes then
        ESP.Box = Drawing.new("Square")
        ESP.Box.Color = Visuals.ESP.Color.Enemy
        ESP.Box.Thickness = 1.5
        ESP.Box.Filled = false
        ESP.Box.Visible = false
    end

    -- // Health Bar
    if Visuals.ESP.HealthBars then
        ESP.HealthBar = Drawing.new("Square")
        ESP.HealthBar.Color = Color3.fromRGB(0, 255, 0)
        ESP.HealthBar.Thickness = 1.5
        ESP.HealthBar.Filled = true
        ESP.HealthBar.Visible = false
    end

    -- // Name Label
    if Visuals.ESP.Names then
        ESP.NameLabel = Drawing.new("Text")
        ESP.NameLabel.Color = Color3.fromRGB(255, 255, 255)
        ESP.NameLabel.Size = 16
        ESP.NameLabel.Center = true
        ESP.NameLabel.Outline = true
        ESP.NameLabel.Visible = false
    end

    -- // Distance Label
    if Visuals.ESP.Distance then
        ESP.DistanceLabel = Drawing.new("Text")
        ESP.DistanceLabel.Color = Color3.fromRGB(255, 255, 255)
        ESP.DistanceLabel.Size = 14
        ESP.DistanceLabel.Center = true
        ESP.DistanceLabel.Outline = true
        ESP.DistanceLabel.Visible = false
    end

    -- // Tracer
    if Visuals.ESP.Tracers then
        ESP.Tracer = Drawing.new("Line")
        ESP.Tracer.Color = Visuals.ESP.Color.Enemy
        ESP.Tracer.Thickness = 1.5
        ESP.Tracer.Visible = false
    end

    -- // Cham
    if Visuals.ESP.Chams then
        ESP.Cham = Instance.new("BoxHandleAdornment")
        ESP.Cham.Color3 = Visuals.ESP.Color.Enemy
        ESP.Cham.AlwaysOnTop = true
        ESP.Cham.ZIndex = 10
        ESP.Cham.Size = Vector3.new(4, 6, 2)
        ESP.Cham.Transparency = 0.5
    end

    ESPObjects[Player] = ESP
end

local function UpdateESP(Player)
    if not Visuals.ESP.Enabled or not Player.Character then return end

    local ESP = ESPObjects[Player]
    if not ESP then return end

    local Character = Player.Character
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    local Head = Character:FindFirstChild("Head")

    if not RootPart or not Head then return end

    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Head.Position)
    if not OnScreen then
        ESP.Box.Visible = false
        ESP.HealthBar.Visible = false
        ESP.NameLabel.Visible = false
        ESP.DistanceLabel.Visible = false
        ESP.Tracer.Visible = false
        return
    end

    -- // Team Check
    if Visuals.ESP.TeamCheck and Player.Team == LocalPlayer.Team then
        ESP.Box.Visible = false
        ESP.HealthBar.Visible = false
        ESP.NameLabel.Visible = false
        ESP.DistanceLabel.Visible = false
        ESP.Tracer.Visible = false
        return
    end

    -- // Visibility Check
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local Direction = (Head.Position - Camera.CFrame.Position).Unit
    local RaycastResult = workspace:Raycast(Camera.CFrame.Position, Direction * 1000, RaycastParams)

    local IsVisible = not RaycastResult or RaycastResult.Instance:IsDescendantOf(Character)

    if IsVisible then
        ESP.Box.Color = Visuals.ESP.Color.Visible
        ESP.Tracer.Color = Visuals.ESP.Color.Visible
    else
        ESP.Box.Color = Visuals.ESP.Color.Enemy
        ESP.Tracer.Color = Visuals.ESP.Color.Enemy
    end

    -- // Box
    if Visuals.ESP.Boxes and ESP.Box then
        local Size = Vector2.new(3000 / RootPart.Position.Z, 4000 / RootPart.Position.Z)
        ESP.Box.Position = Vector2.new(ScreenPosition.X - Size.X / 2, ScreenPosition.Y - Size.Y / 2)
        ESP.Box.Size = Size
        ESP.Box.Visible = true
    end

    -- // Health Bar
    if Visuals.ESP.HealthBars and ESP.HealthBar then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
            ESP.HealthBar.Position = Vector2.new(ESP.Box.Position.X - 6, ESP.Box.Position.Y + ESP.Box.Size.Y * (1 - HealthPercent))
            ESP.HealthBar.Size = Vector2.new(4, ESP.Box.Size.Y * HealthPercent)
            ESP.HealthBar.Visible = true
        end
    end

    -- // Name Label
    if Visuals.ESP.Names and ESP.NameLabel then
        ESP.NameLabel.Text = Player.Name
        ESP.NameLabel.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y - 30)
        ESP.NameLabel.Visible = true
    end

    -- // Distance Label
    if Visuals.ESP.Distance and ESP.DistanceLabel then
        local Distance = (RootPart.Position - Camera.CFrame.Position).Magnitude
        ESP.DistanceLabel.Text = math.floor(Distance) .. "m"
        ESP.DistanceLabel.Position = Vector2.new(ScreenPosition.X, ScreenPosition.Y + 10)
        ESP.DistanceLabel.Visible = true
    end

    -- // Tracer
    if Visuals.ESP.Tracers and ESP.Tracer then
        ESP.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        ESP.Tracer.To = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
        ESP.Tracer.Visible = true
    end
