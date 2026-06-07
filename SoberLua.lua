-- =============================================================================
-- MODULO: UniversalHackSuite v4.0
-- DESCRIZIONE: Suite completa di hacks per Roblox con GUI interattiva
--              Supporto: Arsenal, Brookhaven, Phantom Forces, ecc.
-- AUTORE: HackerAI
-- VERSIONE: 4.0
-- TOGGLE KEY: Ctrl+Destro (tasto destro del mouse + Control)
-- =============================================================================

-- =============================================================================
-- SEZIONE 1: IMPORT SERVIZI
-- =============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

-- =============================================================================
-- SEZIONE 2: VARIABILI GLOBALI
-- =============================================================================

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
local RandomGen = Random.new()
local MenuOpen = false

-- =============================================================================
-- SEZIONE 3: CONFIGURAZIONE COMPLETA (TUTTO PERSONALIZZABILE)
-- =============================================================================

local Config = {
    -- === STILE DEL MENU ===
    MenuStyle = {
        Theme = "Dark",              -- "Dark", "Light", "Blue", "Red", "Green", "Purple", "Orange", "Custom"
        AccentColor = Color3.fromRGB(50, 150, 255),
        BackgroundColor = Color3.fromRGB(25, 25, 35),
        TextColor = Color3.fromRGB(220, 220, 220),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(50, 200, 80),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(50, 150, 255),
        BorderColor = Color3.fromRGB(60, 60, 80),
        Transparency = 0.9,
        FontSize = 14,
        TitleSize = 22,
        SectionSize = 16,
        Width = 350,
        Height = 500,
        X = 50,
        Y = 50,
        AnimationSpeed = 0.2,       -- Velocità animazione apertura/chiusura
    },

    -- === HOTKEY ===
    Hotkeys = {
        MenuToggle = {Key = Enum.UserInputType.MouseButton2, Modifier = Enum.KeyCode.LeftControl},
        -- Alternativa: MenuToggle = {Key = Enum.KeyCode.F5, Modifier = nil},
    },

    -- === AIMBOT ===
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        Ragebot = false,
        Triggerbot = false,
        AimPart = "Head",           -- "Head", "Random", "Nearest"
        Smoothness = 0.5,           -- 0 = istantaneo, 1 = molto smooth
        FOVRadius = 200,
        FOVVisible = true,
        FOVColor = Color3.fromRGB(255, 50, 50),
        FOVTransparency = 0.7,
        FOVThickness = 2,
        RagebotDelay = 0.05,
        PredictionMultiplier = 0.4,
        RandomDelayMin = 30,
        RandomDelayMax = 120,
    },

    -- === ESP ===
    ESP = {
        Enabled = false,
        Boxes = true,
        Health = true,
        Names = true,
        Distance = true,
        Weapon = true,
        Lines = true,
        Color = Color3.fromRGB(0, 255, 0),
        HealthColorHigh = Color3.fromRGB(0, 255, 0),
        HealthColorMid = Color3.fromRGB(255, 255, 0),
        HealthColorLow = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        Transparency = 0.7,
        FontSize = 14,
    },

    -- === MOVEMENT ===
    Movement = {
        SpeedHack = false,
        SpeedMultiplier = 2.0,
        Fly = false,
        FlySpeed = 50,
        InfiniteJump = false,
        JumpPower = 100,
        BunnyHop = false,
        Noclip = false,
    },

    -- === WEAPON MODS ===
    Weapon = {
        NoRecoil = false,
        NoSpread = false,
        InfiniteAmmo = false,
        InstantReload = false,
        OneHitKill = false,
        AutoLoadout = false,
        LoadoutWeapon = "Sniper",
    },

    -- === ESPLORAZIONE ===
    Exploration = {
        Wallhack = false,
        WallhackTransparency = 0.7,
        AntiAim = false,
        AutoBlock = false,
        AutoHeal = false,
        AutoHealThreshold = 0.5,
        AutoFarm = false,
        FarmRange = 50,
        ChatSpammer = false,
        ChatMessage = "EZ",
        ChatInterval = 5,
    },

    -- === MISC ===
    Misc = {
        CustomCrosshair = false,
        CrosshairColor = Color3.fromRGB(255, 255, 255),
        CrosshairSize = 10,
        CrosshairThickness = 2,
        FOVChanger = false,
        FOVValue = 120,
        ThirdPerson = false,
        ThirdPersonDistance = 10,
        Orbit = false,
        OrbitRadius = 15,
        OrbitSpeed = 2,
        VoidSpam = false,
    },
}

-- =============================================================================
-- SEZIONE 4: TEMA DEL MENU (PERSONALIZZABILE)
-- =============================================================================

local Themes = {
    Dark = {
        AccentColor = Color3.fromRGB(50, 150, 255),
        BackgroundColor = Color3.fromRGB(20, 20, 30),
        TextColor = Color3.fromRGB(200, 200, 200),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(50, 200, 80),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(50, 150, 255),
        BorderColor = Color3.fromRGB(50, 50, 70),
    },
    Light = {
        AccentColor = Color3.fromRGB(0, 120, 255),
        BackgroundColor = Color3.fromRGB(240, 240, 250),
        TextColor = Color3.fromRGB(30, 30, 40),
        TitleColor = Color3.fromRGB(0, 0, 0),
        ToggleOnColor = Color3.fromRGB(0, 180, 50),
        ToggleOffColor = Color3.fromRGB(220, 50, 50),
        SliderColor = Color3.fromRGB(0, 120, 255),
        BorderColor = Color3.fromRGB(180, 180, 200),
    },
    Blue = {
        AccentColor = Color3.fromRGB(30, 100, 255),
        BackgroundColor = Color3.fromRGB(15, 25, 50),
        TextColor = Color3.fromRGB(180, 200, 255),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(50, 200, 255),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(30, 100, 255),
        BorderColor = Color3.fromRGB(40, 60, 120),
    },
    Red = {
        AccentColor = Color3.fromRGB(255, 50, 50),
        BackgroundColor = Color3.fromRGB(40, 15, 15),
        TextColor = Color3.fromRGB(255, 180, 180),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(255, 80, 80),
        ToggleOffColor = Color3.fromRGB(150, 50, 50),
        SliderColor = Color3.fromRGB(255, 50, 50),
        BorderColor = Color3.fromRGB(100, 40, 40),
    },
    Green = {
        AccentColor = Color3.fromRGB(50, 255, 80),
        BackgroundColor = Color3.fromRGB(15, 40, 20),
        TextColor = Color3.fromRGB(180, 255, 190),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(50, 255, 80),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(50, 255, 80),
        BorderColor = Color3.fromRGB(40, 100, 50),
    },
    Purple = {
        AccentColor = Color3.fromRGB(180, 50, 255),
        BackgroundColor = Color3.fromRGB(30, 15, 45),
        TextColor = Color3.fromRGB(210, 180, 255),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(180, 80, 255),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(180, 50, 255),
        BorderColor = Color3.fromRGB(80, 40, 120),
    },
    Orange = {
        AccentColor = Color3.fromRGB(255, 150, 30),
        BackgroundColor = Color3.fromRGB(45, 30, 15),
        TextColor = Color3.fromRGB(255, 210, 160),
        TitleColor = Color3.fromRGB(255, 255, 255),
        ToggleOnColor = Color3.fromRGB(255, 180, 50),
        ToggleOffColor = Color3.fromRGB(200, 50, 50),
        SliderColor = Color3.fromRGB(255, 150, 30),
        BorderColor = Color3.fromRGB(120, 80, 30),
    },
}

-- =============================================================================
-- SEZIONE 5: FUNZIONI DI TEMA
-- =============================================================================

--- Applica un tema al menu
function SetTheme(themeName)
    if Themes[themeName] then
        Config.MenuStyle.Theme = themeName
        for k, v in pairs(Themes[themeName]) do
            Config.MenuStyle[k] = v
        end
        if MenuOpen then
            RebuildMenu()
        end
        ShowNotification("[Tema] " .. themeName, Color3.fromRGB(0, 255, 100))
    end
end

--- Imposta colore personalizzato
function SetCustomAccentColor(color)
    Config.MenuStyle.Theme = "Custom"
    Config.MenuStyle.AccentColor = color
    if MenuOpen then RebuildMenu() end
end

--- Imposta trasparenza del menu
function SetMenuTransparency(transparency)
    Config.MenuStyle.Transparency = math.clamp(transparency, 0, 1)
    if MenuOpen then RebuildMenu() end
end

--- Imposta la posizione del menu
function SetMenuPosition(x, y)
    Config.MenuStyle.X = x
    Config.MenuStyle.Y = y
    if MenuOpen then RebuildMenu() end
end

-- =============================================================================
-- SEZIONE 6: OGGETTI DRAWING + GUI
-- =============================================================================

-- Oggetti del menu
local MenuObjects = {}
local TabButtons = {}
local CurrentTab = "Aimbot"
local IsDragging = false
local DragOffset = Vector2.new(0, 0)

-- Oggetti disegno permanenti
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Config.Aimbot.FOVColor
FOVCircle.Thickness = Config.Aimbot.FOVThickness
FOVCircle.Transparency = Config.Aimbot.FOVTransparency
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.Aimbot.FOVRadius

local CrosshairCircle = Drawing.new("Circle")
CrosshairCircle.Visible = false
CrosshairCircle.Color = Config.Misc.CrosshairColor
CrosshairCircle.Thickness = Config.Misc.CrosshairThickness
CrosshairCircle.Transparency = 0.5
CrosshairCircle.NumSides = 32
CrosshairCircle.Radius = Config.Misc.CrosshairSize

-- =============================================================================
-- SEZIONE 7: NOTIFICHE
-- =============================================================================

local Notifications = {}

local function ShowNotification(text, color, duration)
    color = color or Color3.fromRGB(0, 255, 100)
    duration = duration or 2

    local notif = Drawing.new("Text")
    notif.Text = text
    notif.Color = color
    notif.Size = Config.MenuStyle.FontSize + 4
    notif.Center = true
    notif.Outline = true
    notif.OutlineColor = Color3.fromRGB(0, 0, 0)
    notif.Position = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2 + 100 + (#Notifications * 30)
    )

    table.insert(Notifications, notif)

    task.spawn(function()
        task.wait(duration)
        for i = 1, 0, -0.05 do
            notif.Transparency = i
            notif.Position = notif.Position + Vector2.new(0, -1)
            task.wait(0.03)
        end
        notif:Remove()
        for idx, n in ipairs(Notifications) do
            if n == notif then
                table.remove(Notifications, idx)
                break
            end
        end
    end)
end

-- =============================================================================
-- SEZIONE 8: FUNZIONI DI UTILITÀ
-- =============================================================================

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetAimPart(character)
    if not character then return nil end

    local partName = Config.Aimbot.AimPart
    if partName == "Random" then
        local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end

    local head = character:FindFirstChild("Head")
    if head then return head end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then return root end
    return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function GetVelocity(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root.Velocity or Vector3.new()
end

local function IsAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and humanoid.Parent ~= nil
end

local function RandomDelay()
    task.wait(math.random(Config.Aimbot.RandomDelayMin, Config.Aimbot.RandomDelayMax) / 1000)
end

-- =============================================================================
-- SEZIONE 9: WALL CHECK (RAYCAST)
-- =============================================================================

local function IsTargetVisible(targetPosition)
    if not targetPosition then return false end

    local ignoreList = {
        LocalPlayer.Character,
        Camera,
        Workspace.Terrain,
    }

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList

    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit
    local maxDist = GetDistance(targetPosition, origin)

    local result = Workspace:Raycast(origin, direction * maxDist, params)
    if not result then return true end

    local hitPart = result.Instance
    local hitCharacter = hitPart and hitPart.Parent
    if hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

-- =============================================================================
-- SEZIONE 10: PREDIZIONE MOVIMENTO
-- =============================================================================

local function PredictPosition(targetPos, targetVelocity)
    if Config.Aimbot.PredictionMultiplier <= 0 then return targetPos end

    local distance = GetDistance(targetPos, Camera.CFrame.Position)
    local factor = math.clamp(distance / 500, 0.3, 2.0)

    return targetPos + (targetVelocity * Config.Aimbot.PredictionMultiplier * factor)
end

-- =============================================================================
-- SEZIONE 11: GET CLOSEST TARGET
-- =============================================================================

local function GetClosestTarget(useFOV)
    local closest = nil
    local closestDist = math.huge
    local screenCenter = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local char = player.Character
        if not IsAlive(char) then continue end

        local part = GetAimPart(char)
        if not part then continue end

        local targetPos = PredictPosition(part.Position, GetVelocity(char))

        if not IsTargetVisible(targetPos) then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if not onScreen then continue end

        local sp = Vector2.new(screenPos.X, screenPos.Y)
        local d2 = (sp - screenCenter).Magnitude

        if useFOV and d2 > Config.Aimbot.FOVRadius then continue end

        if d2 < closestDist then
            closestDist = d2
            closest = {
                Player = player,
                Character = char,
                Part = part,
                Position = targetPos,
                ScreenPosition = sp,
                Distance = GetDistance(targetPos, Camera.CFrame.Position),
            }
        end
    end
    return closest
end

-- =============================================================================
-- SEZIONE 12: AIMBOT FUNCTIONS
-- =============================================================================

function ToggleAimbot()
    Config.Aimbot.Enabled = not Config.Aimbot.Enabled
    FOVCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.FOVVisible
    ShowNotification(Config.Aimbot.Enabled and "[+] Aimbot ON" or "[-] Aimbot OFF",
                     Config.Aimbot.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleSilentAim()
    Config.Aimbot.SilentAim = not Config.Aimbot.SilentAim
    ShowNotification(Config.Aimbot.SilentAim and "[+] Silent Aim ON" or "[-] Silent Aim OFF",
                     Config.Aimbot.SilentAim and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleRagebot()
    Config.Aimbot.Ragebot = not Config.Aimbot.Ragebot
    ShowNotification(Config.Aimbot.Ragebot and "[+] Ragebot ON" or "[-] Ragebot OFF",
                     Config.Aimbot.Ragebot and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 50, 50))
end

function ToggleTriggerbot()
    Config.Aimbot.Triggerbot = not Config.Aimbot.Triggerbot
    ShowNotification(Config.Aimbot.Triggerbot and "[+] Triggerbot ON" or "[-] Triggerbot OFF",
                     Config.Aimbot.Triggerbot and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 50, 50))
end

local lastRagebotFire = 0

local function ExecuteAimbot()
    if not Config.Aimbot.Enabled then return end

    local target = GetClosestTarget(true)
    if not target then return end

    if Config.Aimbot.Ragebot then
        local now = tick()
        if now - lastRagebotFire >= Config.Aimbot.RagebotDelay then
            mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
            mouse1click()
            lastRagebotFire = now
            RandomDelay()
        end
        return
    end

    if Config.Aimbot.SilentAim then
        mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
        mouse1click()
        RandomDelay()
        return
    end

    -- Aim Lock normale
    local smooth = Config.Aimbot.Smoothness
    if smooth <= 0.01 then
        mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
    else
        local sf = 1 - smooth
        local nx = Mouse.X + (target.ScreenPosition.X - Mouse.X) * sf
        local ny = Mouse.Y + (target.ScreenPosition.Y - Mouse.Y) * sf
        mousemovepls(nx, ny)
    end
end

-- =============================================================================
-- SEZIONE 13: TRIGGERBOT
-- =============================================================================

local function ExecuteTriggerbot()
    if not Config.Aimbot.Triggerbot then return end

    local mouseRay = Mouse.UnitRay
    local origin = mouseRay.Origin
    local direction = mouseRay.Direction * 1000

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local result = Workspace:Raycast(origin, direction, params)
    if result then
        local hitChar = result.Instance and result.Instance.Parent
        if hitChar and hitChar:FindFirstChildOfClass("Humanoid") and hitChar ~= LocalPlayer.Character then
            mouse1click()
            RandomDelay()
        end
    end
end

-- =============================================================================
-- SEZIONE 14: ESP
-- =============================================================================

local ESPObjects = {}

function ToggleESP()
    Config.ESP.Enabled = not Config.ESP.Enabled
    if not Config.ESP.Enabled then
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do obj:Remove() end
        end
        table.clear(ESPObjects)
    end
    ShowNotification(Config.ESP.Enabled and "[+] ESP ON" or "[-] ESP OFF",
                     Config.ESP.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do obj:Remove() end
        end
        table.clear(ESPObjects)
        return
    end

    local screenCenter = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local char = player.Character
        if not IsAlive(char) then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do obj:Remove() end
                ESPObjects[player] = nil
            end
            continue
        end

        local part = GetAimPart(char)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do obj.Visible = false end
            end
            continue
        end

        local pos2D = Vector2.new(screenPos.X, screenPos.Y)
        local distance = GetDistance(part.Position, Camera.CFrame.Position)

        if ESPObjects[player] then
            for _, obj in pairs(ESPObjects[player]) do obj:Remove() end
        end

        local objects = {}
        local boxSize = math.clamp(60 / (distance / 100), 20, 150)

        -- Box
        if Config.ESP.Boxes then
            local box = Drawing.new("Square")
            box.Visible = true
            box.Size = Vector2.new(boxSize, boxSize * 1.8)
            box.Position = pos2D - box.Size / 2
            box.Color = Config.ESP.Color
            box.Thickness = Config.ESP.Thickness
            box.Transparency = Config.ESP.Transparency
            table.insert(objects, box)
        end

        -- Health Bar
        if Config.ESP.Health then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local barW, barH = 6, boxSize * 1.8

                local bg = Drawing.new("Square")
                bg.Visible = true
                bg.Size = Vector2.new(barW, barH)
                bg.Position = pos2D - Vector2.new(boxSize / 2 + barW + 4, barH / 2)
                bg.Color = Color3.fromRGB(50, 50, 50)
                bg.Filled = true
                bg.Transparency = 0.8
                table.insert(objects, bg)

                local bar = Drawing.new("Square")
                bar.Visible = true
                bar.Size = Vector2.new(barW - 2, (barH - 2) * hp)
                bar.Position = bg.Position + Vector2.new(1, barH - 2 - bar.Size.Y)
                bar.Filled = true
                bar.Transparency = 0.6

                if hp > 0.6 then
                    bar.Color = Config.ESP.HealthColorHigh
                elseif hp > 0.3 then
                    bar.Color = Config.ESP.HealthColorMid
                else
                    bar.Color = Config.ESP.HealthColorLow
                end
                table.insert(objects, bar)
            end
        end

        -- Nome
        if Config.ESP.Names then
            local name = Drawing.new("Text")
            name.Visible = true
            name.Text = player.Name
            name.Color = Config.ESP.Color
            name.Size = Config.ESP.FontSize
            name.Center = true
            name.Outline = true
            name.Position = pos2D - Vector2.new(0, boxSize * 1.8 / 2 + 16)
            table.insert(objects, name)
        end

        -- Distanza
        if Config.ESP.Distance then
            local dist = Drawing.new("Text")
            dist.Visible = true
            dist.Text = string.format("[%.0fm]", distance)
            dist.Color = Color3.fromRGB(200, 200, 200)
            dist.Size = Config.ESP.FontSize - 2
            dist.Center = true
            dist.Outline = true
            dist.Position = pos2D + Vector2.new(0, boxSize * 1.8 / 2 + 4)
            table.insert(objects, dist)
        end

        -- Arma
        if Config.ESP.Weapon then
            local tool = char:FindFirstChildOfClass("Tool") or
                         LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if tool then
                local wpn = Drawing.new("Text")
                wpn.Visible = true
                wpn.Text = tool.Name
                wpn.Color = Color3.fromRGB(255, 200, 50)
                wpn.Size = Config.ESP.FontSize - 2
                wpn.Center = true
                wpn.Outline = true
                wpn.Position = pos2D + Vector2.new(0, boxSize * 1.8 / 2 + 22)
                table.insert(objects, wpn)
            end
        end

        -- Linee
        if Config.ESP.Lines then
            local line = Drawing.new("Line")
            line.Visible = true
            line.From = screenCenter
            line.To = pos2D
            line.Color = Config.ESP.Color
            line.Thickness = 1
            line.Transparency = 0.4
            table.insert(objects, line)
        end

        ESPObjects[player] = objects
    end
end

-- =============================================================================
-- SEZIONE 15: MOVEMENT FUNCTIONS
-- =============================================================================

function ToggleSpeedHack()
    Config.Movement.SpeedHack = not Config.Movement.SpeedHack
    if not Config.Movement.SpeedHack and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    ShowNotification(Config.Movement.SpeedHack and "[+] Speed Hack ON" or "[-] Speed Hack OFF",
                     Config.Movement.SpeedHack and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleFly()
    Config.Movement.Fly = not Config.Movement.Fly
    if not Config.Movement.Fly and flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    ShowNotification(Config.Movement.Fly and "[+] Fly ON" or "[-] Fly OFF",
                     Config.Movement.Fly and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleInfiniteJump()
    Config.Movement.InfiniteJump = not Config.Movement.InfiniteJump
    ShowNotification(Config.Movement.InfiniteJump and "[+] Infinite Jump ON" or "[-] Infinite Jump OFF",
                     Config.Movement.InfiniteJump and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleBunnyHop()
    Config.Movement.BunnyHop = not Config.Movement.BunnyHop
    ShowNotification(Config.Movement.BunnyHop and "[+] Bunny Hop ON" or "[-] Bunny Hop OFF",
                     Config.Movement.BunnyHop and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleNoclip()
    Config.Movement.Noclip = not Config.Movement.Noclip
    if not Config.Movement.Noclip and noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    ShowNotification(Config.Movement.Noclip and "[+] Noclip ON" or "[-] Noclip OFF",
                     Config.Movement.Noclip and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

local flyConnection = nil
local noclipConnection = nil
local lastSpacePress = 0

local function ExecuteFly()
    if not Config.Movement.Fly then
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        return
    end

    if flyConnection then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)

    flyConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        bv.Parent = root
        local dir = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        bv.Velocity = dir.Magnitude > 0 and dir.Unit * Config.Movement.FlySpeed or Vector3.new()
    end)
end

local function ApplyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.Movement.SpeedHack then
        hum.WalkSpeed = 16 * Config.Movement.SpeedMultiplier
    end

    if Config.Movement.InfiniteJump then
        hum.JumpPower = Config.Movement.JumpPower
    end
end

local function ExecuteBunnyHop()
    if not Config.Movement.BunnyHop then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
        local now = tick()
        if now - lastSpacePress > 0.2 then
            hum.Jump = true
            lastSpacePress = now
        end
    end
end

local function ExecuteNoclip()
    if not Config.Movement.Noclip then
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        return
    end

    if noclipConnection then return end

    noclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

-- =============================================================================
-- SEZIONE 16: WEAPON FUNCTIONS
-- =============================================================================

function ToggleNoRecoil()
    Config.Weapon.NoRecoil = not Config.Weapon.NoRecoil
    ShowNotification(Config.Weapon.NoRecoil and "[+] No Recoil ON" or "[-] No Recoil OFF",
                     Config.Weapon.NoRecoil and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleNoSpread()
    Config.Weapon.NoSpread = not Config.Weapon.NoSpread
    ShowNotification(Config.Weapon.NoSpread and "[+] No Spread ON" or "[-] No Spread OFF",
                     Config.Weapon.NoSpread and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleInfiniteAmmo()
    Config.Weapon.InfiniteAmmo = not Config.Weapon.InfiniteAmmo
    ShowNotification(Config.Weapon.InfiniteAmmo and "[+] Infinite Ammo ON" or "[-] Infinite Ammo OFF",
                     Config.Weapon.InfiniteAmmo and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleOneHitKill()
    Config.Weapon.OneHitKill = not Config.Weapon.OneHitKill
    ShowNotification(Config.Weapon.OneHitKill and "[+] One Hit Kill ON" or "[-] One Hit Kill OFF",
                     Config.Weapon.OneHitKill and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 50, 50))
end

function ToggleAutoLoadout()
    Config.Weapon.AutoLoadout = not Config.Weapon.AutoLoadout
    ShowNotification(Config.Weapon.AutoLoadout and "[+] Auto Loadout ON" or "[-] Auto Loadout OFF",
                     Config.Weapon.AutoLoadout and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local success, err = pcall(function()
        if Config.Weapon.NoRecoil and tool.RecoilAmount then tool.RecoilAmount.Value = 0 end
        if Config.Weapon.NoRecoil and tool.CameraRecoil then tool.CameraRecoil.Value = Vector3.new() end
        if Config.Weapon.NoSpread and tool.SpreadAmount then tool.SpreadAmount.Value = 0 end
        if Config.Weapon.NoSpread and tool.BulletSpread then tool.BulletSpread.Value = 0 end
        if Config.Weapon.InfiniteAmmo and tool.Ammo then tool.Ammo.Value = 999 end
        if Config.Weapon.InfiniteAmmo and tool.CurrentAmmo then tool.CurrentAmmo.Value = 999 end
        if Config.Weapon.InfiniteAmmo and tool.ReserveAmmo then tool.ReserveAmmo.Value = 9999 end
        if Config.Weapon.OneHitKill and tool.Damage then tool.Damage.Value = 1e6 end
        if Config.Weapon.OneHitKill and tool.BulletDamage then tool.BulletDamage.Value = 1e6 end
    end)

    -- Auto Loadout
    if Config.Weapon.AutoLoadout then
        local current = char:FindFirstChildOfClass("Tool")
        if current and current.Name ~= Config.Weapon.LoadoutWeapon then
            local target = LocalPlayer.Backpack:FindFirstChild(Config.Weapon.LoadoutWeapon)
            if target then
                hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(target) end
            end
        end
    end
end

-- =============================================================================
-- SEZIONE 17: EXPLORATION FUNCTIONS
-- =============================================================================

function ToggleWallhack()
    Config.Exploration.Wallhack = not Config.Exploration.Wallhack
    ShowNotification(Config.Exploration.Wallhack and "[+] Wallhack ON" or "[-] Wallhack OFF",
                     Config.Exploration.Wallhack and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleAntiAim()
    Config.Exploration.AntiAim = not Config.Exploration.AntiAim
    ShowNotification(Config.Exploration.AntiAim and "[+] Anti-Aim ON" or "[-] Anti-Aim OFF",
                     Config.Exploration.AntiAim and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleAutoHeal()
    Config.Exploration.AutoHeal = not Config.Exploration.AutoHeal
    ShowNotification(Config.Exploration.AutoHeal and "[+] Auto Heal ON" or "[-] Auto Heal OFF",
                     Config.Exploration.AutoHeal and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleAutoFarm()
    Config.Exploration.AutoFarm = not Config.Exploration.AutoFarm
    ShowNotification(Config.Exploration.AutoFarm and "[+] Auto Farm ON" or "[-] Auto Farm OFF",
                     Config.Exploration.AutoFarm and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleChatSpammer()
    Config.Exploration.ChatSpammer = not Config.Exploration.ChatSpammer
    ShowNotification(Config.Exploration.ChatSpammer and "[+] Chat Spammer ON" or "[-] Chat Spammer OFF",
                     Config.Exploration.ChatSpammer and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 18: MISC FUNCTIONS
-- =============================================================================

function ToggleCustomCrosshair()
    Config.Misc.CustomCrosshair = not Config.Misc.CustomCrosshair
    CrosshairCircle.Visible = Config.Misc.CustomCrosshair
    ShowNotification(Config.Misc.CustomCrosshair and "[+] Custom Crosshair ON" or "[-] Custom Crosshair OFF",
                     Config.Misc.CustomCrosshair and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleFOVChanger()
    Config.Misc.FOVChanger = not Config.Misc.FOVChanger
    if Config.Misc.FOVChanger then
        Camera.FieldOfView = Config.Misc.FOVValue
    else
        Camera.FieldOfView = 70
    end
    ShowNotification(Config.Misc.FOVChanger and "[+] FOV Changer ON" or "[-] FOV Changer OFF",
                     Config.Misc.FOVChanger and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleThirdPerson()
    Config.Misc.ThirdPerson = not Config.Misc.ThirdPerson
    if not Config.Misc.ThirdPerson then
        local char = LocalPlayer.Character
        if char then
            Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
        end
    end
    ShowNotification(Config.Misc.ThirdPerson and "[+] Third Person ON" or "[-] Third Person OFF",
                     Config.Misc.ThirdPerson and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleOrbit()
    Config.Misc.Orbit = not Config.Misc.Orbit
    ShowNotification(Config.Misc.Orbit and "[+] Orbit ON" or "[-] Orbit OFF",
                     Config.Misc.Orbit and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50))
end

function ToggleVoidSpam()
    Config.Misc.VoidSpam = not Config.Misc.VoidSpam
    ShowNotification(Config.Misc.VoidSpam and "[+] Void Spam ON" or "[-] Void Spam OFF",
                     Config.Misc.VoidSpam and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 19: WALLHACK APPLICAZIONE
-- =============================================================================

local wallhackConnection = nil

local function ApplyWallhack()
    if Config.Exploration.Wallhack then
        if wallhackConnection then return end
        wallhackConnection = RunService.Heartbeat:Connect(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if obj.Transparency < 0.5 then
                        obj.LocalTransparencyModifier = Config.Exploration.WallhackTransparency
                    end
                end
            end
            -- Rendi visibili i player attraverso i muri
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                if not player.Character then continue end
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency > 0.5 then
                        part.LocalTransparencyModifier = -0.8
                    end
                end
            end
        end)
    else
        if wallhackConnection then
            wallhackConnection:Disconnect()
            wallhackConnection = nil
        end
        -- Ripristina
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 0
            end
        end
    end
end

-- =============================================================================
-- SEZIONE 20: ALTRE FUNZIONI SECONDARIE
-- =============================================================================

local orbitAngle = 0

local function ExecuteOrbit()
    if not Config.Misc.Orbit then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local target = GetClosestTarget(false)
    if target then
        orbitAngle = orbitAngle + Config.Misc.OrbitSpeed
        local rad = math.rad(orbitAngle)
        root.CFrame = CFrame.new(
            target.Position.X + math.cos(rad) * Config.Misc.OrbitRadius,
            target.Position.Y + 2,
            target.Position.Z + math.sin(rad) * Config.Misc.OrbitRadius
        )
    end
end

local function ExecuteVoidSpam()
    if not Config.Misc.VoidSpam then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = root.CFrame * CFrame.new(0, -500, 0)
    end
end

local function ExecuteAutoHeal()
    if not Config.Exploration.AutoHeal then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if hum.Health < hum.MaxHealth * Config.Exploration.AutoHealThreshold then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            local name = item.Name:lower()
            if name:find("health") or name:find("med") or name:find("bandage") or name:find("first") then
                hum:EquipTool(item)
                task.wait(0.3)
                mouse1click()
                RandomDelay()
                break
            end
        end
    end
end

local function ExecuteAutoFarm()
    if not Config.Exploration.AutoFarm then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") and obj:FindFirstChild("TouchInterest") then
            local dist = GetDistance(obj.Position, root.Position)
            if dist < Config.Exploration.FarmRange then
                root.CFrame = CFrame.new(obj.Position)
                task.wait(0.1)
                break
            end
        end
    end
end

local function ExecuteAntiAim()
    if not Config.Exploration.AntiAim then return end

    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if head then
        head.CFrame = head.CFrame * CFrame.Angles(
            math.rad(math.random(-15, 15)),
            math.rad(math.random(-180, 180)),
            math.rad(math.random(-15, 15))
        )
    end
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-5, 5)), 0)
    end
end

-- =============================================================================
-- SEZIONE 21: COSTRUZIONE DEL MENU GUI
-- =============================================================================

local menuBuildVersion = 0

function RebuildMenu()
    menuBuildVersion = menuBuildVersion + 1
    local version = menuBuildVersion

    -- Pulisce vecchi oggetti
    for _, obj in pairs(MenuObjects) do
        if obj.Remove then obj:Remove() end
    end
    table.clear(MenuObjects)
    table.clear(TabButtons)

    if not MenuOpen then return end

    local style = Config.MenuStyle
    local w, h = style.Width, style.Height
    local x, y = style.X, style.Y
    local fs = style.FontSize
    local padding = 10
    local tabHeight = 35

    -- === BACKGROUND ===
    local bg = Drawing.new("Square")
    bg.Visible = true
    bg.Size = Vector2.new(w, h)
    bg.Position = Vector2.new(x, y)
    bg.Color = style.BackgroundColor
    bg.Filled = true
    bg.Transparency = style.Transparency
    table.insert(MenuObjects, bg)

    -- === BORDERS ===
    local border = Drawing.new("Square")
    border.Visible = true
    border.Size = Vector2.new(w, h)
    border.Position = Vector2.new(x, y)
    border.Color = style.BorderColor
    border.Thickness = 2
    border.Transparency = 0
    table.insert(MenuObjects, border)

    -- === TITLE BAR ===
    local titleBg = Drawing.new("Square")
    titleBg.Visible = true
    titleBg.Size = Vector2.new(w, tabHeight)
    titleBg.Position = Vector2.new(x, y)
    titleBg.Color = style.AccentColor
    titleBg.Filled = true
    titleBg.Transparency = 0.2
    table.insert(MenuObjects, titleBg)

    local title = Drawing.new("Text")
    title.Visible = true
    title.Text = "Universal Hack Suite v4.0"
    title.Color = style.TitleColor
    title.Size = style.TitleSize
    title.Font = 2
    title.Center = true
    title.Position = Vector2.new(x + w / 2, y + tabHeight / 2 - title.Size / 2)
    table.insert(MenuObjects, title)

    -- === TABS ===
    local tabs = {"Aimbot", "ESP", "Movement", "Weapon", "Exploration", "Misc", "Settings"}
    local tabW = (w - padding * 2) / #tabs
    local tabY = y + tabHeight

    for i, tabName in ipairs(tabs) do
        local tabX = x + padding + (i - 1) * tabW

        local tabBg = Drawing.new("Square")
        tabBg.Visible = true
        tabBg.Size = Vector2.new(tabW - 4, 25)
        tabBg.Position = Vector2.new(tabX + 2, tabY + 5)
        tabBg.Color = (tabName == CurrentTab) and style.AccentColor or style.BorderColor
        tabBg.Filled = true
        tabBg.Transparency = (tabName == CurrentTab) and 0.3 or 0.7
        table.insert(MenuObjects, tabBg)

        local tabText = Drawing.new("Text")
        tabText.Visible = true
        tabText.Text = tabName
        tabText.Color = style.TextColor
        tabText.Size = fs
        tabText.Center = true
        tabText.Position = Vector2.new(tabX + tabW / 2, tabY + 17 - fs / 2)
        table.insert(MenuObjects, tabText)

        table.insert(TabButtons, {
            Name = tabName,
            X = tabX,
            Y = tabY,
            Width = tabW,
            Height = 25,
        })
    end

    -- === CONTENUTO TAB ===
    local contentY = tabY + 40
    local contentX = x + padding
    local contentW = w - padding * 2
    local itemY = contentY

    local function CreateToggle(text, value, toggleFunc, yPos)
        local bg = Drawing.new("Square")
        bg.Visible = true
        bg.Size = Vector2.new(contentW, 28)
        bg.Position = Vector2.new(contentX, yPos)
        bg.Color = value and style.ToggleOnColor or style.ToggleOffColor
        bg.Filled = true
        bg.Transparency = 0.8
        table.insert(MenuObjects, bg)

        local txt = Drawing.new("Text")
        txt.Visible = true
        txt.Text = text .. ": " .. (value and "ON" or "OFF")
        txt.Color = style.TextColor
        txt.Size = fs
        txt.Position = Vector2.new(contentX + 10, yPos + 6)
        table.insert(MenuObjects, txt)

        return {Type = "toggle", Y = yPos, Height = 28, Func = toggleFunc, Bg = bg, Text = txt, Ref = value}
    end

    local function CreateSlider(text, value, min, max, step, suffix, onChange, yPos)
        local bg = Drawing.new("Square")
        bg.Visible = true
        bg.Size = Vector2.new(contentW, 28)
        bg.Position = Vector2.new(contentX, yPos)
        bg.Color = Color3.fromRGB(40, 40, 50)
        bg.Filled = true
        bg.Transparency = 0.8
        table.insert(MenuObjects, bg)

        local fillW = ((value - min) / (max - min)) * (contentW - 20)
        local fill = Drawing.new("Square")
        fill.Visible = true
        fill.Size = Vector2.new(fillW, 24)
        fill.Position = Vector2.new(contentX + 4, yPos + 2)
        fill.Color = style.SliderColor
        fill.Filled = true
        fill.Transparency = 0.6
        table.insert(MenuObjects, fill)

        local txt = Drawing.new("Text")
        txt.Visible = true
        txt.Text = text .. ": " .. string.format("%.1f", value) .. (suffix or "")
        txt.Color = style.TextColor
        txt.Size = fs
        txt.Position = Vector2.new(contentX + 12, yPos + 6)
        table.insert(MenuObjects, txt)

        return {Type = "slider", Y = yPos, Height = 28, Value = value, Min = min, Max = max, Step = step, OnChange = onChange, Bg = fill, Text = txt}
    end

    if CurrentTab == "Aimbot" then
        itemY = CreateToggle("Aimbot", Config.Aimbot.Enabled, ToggleAimbot, itemY).Y + 32
        itemY = CreateToggle("Silent Aim", Config.Aimbot.SilentAim, ToggleSilentAim, itemY).Y + 32
        itemY = CreateToggle("Ragebot", Config.Aimbot.Ragebot, ToggleRagebot, itemY).Y + 32
        itemY = CreateToggle("Triggerbot", Config.Aimbot.Triggerbot, ToggleTriggerbot, itemY).Y + 32
        itemY = CreateSlider("Smoothness", Config.Aimbot.Smoothness, 0, 1, 0.05, "", function(v) Config.Aimbot.Smoothness = v end, itemY).Y + 32
        itemY = CreateSlider("FOV Radius", Config.Aimbot.FOVRadius, 20, 500, 5, "px", function(v) Config.Aimbot.FOVRadius = v; FOVCircle.Radius = v end, itemY).Y + 32
        itemY = CreateSlider("Prediction", Config.Aimbot.PredictionMultiplier, 0, 1, 0.05, "", function(v) Config.Aimbot.PredictionMultiplier = v end, itemY).Y + 32
        itemY = CreateSlider("Delay Min (ms)", Config.Aimbot.RandomDelayMin, 10, 500, 5, "ms", function(v) Config.Aimbot.RandomDelayMin = v end, itemY).Y + 32
        itemY = CreateSlider("Delay Max (ms)", Config.Aimbot.RandomDelayMax, 10, 500, 5, "ms", function(v) Config.Aimbot.RandomDelayMax = v end, itemY).Y + 32

    elseif CurrentTab == "ESP" then
        itemY = CreateToggle("ESP", Config.ESP.Enabled, ToggleESP, itemY).Y + 32
        itemY = CreateToggle("Boxes", Config.ESP.Boxes, function() Config.ESP.Boxes = not Config.ESP.Boxes end, itemY).Y + 32
        itemY = CreateToggle("Health", Config.ESP.Health, function() Config.ESP.Health = not Config.ESP.Health end, itemY).Y + 32
        itemY = CreateToggle("Names", Config.ESP.Names, function() Config.ESP.Names = not Config.ESP.Names end, itemY).Y + 32
        itemY = CreateToggle("Distance", Config.ESP.Distance, function() Config.ESP.Distance = not Config.ESP.Distance end, itemY).Y + 32
        itemY = CreateToggle("Weapon", Config.ESP.Weapon, function() Config.ESP.Weapon = not Config.ESP.Weapon end, itemY).Y + 32
        itemY = CreateToggle("Lines", Config.ESP.Lines, function() Config.ESP.Lines = not Config.ESP.Lines end, itemY).Y + 32
        itemY = CreateSlider("Font Size", Config.ESP.FontSize, 10, 24, 1, "", function(v) Config.ESP.FontSize = v end, itemY).Y + 32

    elseif CurrentTab == "Movement" then
        itemY = CreateToggle("Speed Hack", Config.Movement.SpeedHack, ToggleSpeedHack, itemY).Y + 32
        itemY = CreateSlider("Speed Multiplier", Config.Movement.SpeedMultiplier, 1, 10, 0.5, "x", function(v) Config.Movement.SpeedMultiplier = v end, itemY).Y + 32
        itemY = CreateToggle("Fly", Config.Movement.Fly, ToggleFly, itemY).Y + 32
        itemY = CreateSlider("Fly Speed", Config.Movement.FlySpeed, 10, 200, 5, "", function(v) Config.Movement.FlySpeed = v end, itemY).Y + 32
        itemY = CreateToggle("Infinite Jump", Config.Movement.InfiniteJump, ToggleInfiniteJump, itemY).Y + 32
        itemY = CreateToggle("Bunny Hop", Config.Movement.BunnyHop, ToggleBunnyHop, itemY).Y + 32
        itemY = CreateToggle("Noclip", Config.Movement.Noclip, ToggleNoclip, itemY).Y + 32

    elseif CurrentTab == "Weapon" then
        itemY = CreateToggle("No Recoil", Config.Weapon.NoRecoil, ToggleNoRecoil, itemY).Y + 32
        itemY = CreateToggle("No Spread", Config.Weapon.NoSpread, ToggleNoSpread, itemY).Y + 32
        itemY = CreateToggle("Infinite Ammo", Config.Weapon.InfiniteAmmo, ToggleInfiniteAmmo, itemY).Y + 32
        itemY = CreateToggle("One Hit Kill", Config.Weapon.OneHitKill, ToggleOneHitKill, itemY).Y + 32
        itemY = CreateToggle("Auto Loadout", Config.Weapon.AutoLoadout, ToggleAutoLoadout, itemY).Y + 32

    elseif CurrentTab == "Exploration" then
        itemY = CreateToggle("Wallhack", Config.Exploration.Wallhack, ToggleWallhack, itemY).Y + 32
        itemY = CreateToggle("Anti-Aim", Config.Exploration.AntiAim, ToggleAntiAim, itemY).Y + 32
        itemY = CreateToggle("Auto Heal", Config.Exploration.AutoHeal, ToggleAutoHeal, itemY).Y + 32
        itemY = CreateToggle("Auto Farm", Config.Exploration.AutoFarm, ToggleAutoFarm, itemY).Y + 32
        itemY = CreateToggle("Chat Spammer", Config.Exploration.ChatSpammer, ToggleChatSpammer, itemY).Y + 32

    elseif CurrentTab == "Misc" then
        itemY = CreateToggle("Custom Crosshair", Config.Misc.CustomCrosshair, ToggleCustomCrosshair, itemY).Y + 32
        itemY = CreateToggle("FOV Changer", Config.Misc.FOVChanger, ToggleFOVChanger, itemY).Y + 32
        itemY = CreateToggle("Third Person", Config.Misc.ThirdPerson, ToggleThirdPerson, itemY).Y + 32
        itemY = CreateToggle("Orbit", Config.Misc.Orbit, ToggleOrbit, itemY).Y + 32
        itemY = CreateToggle("Void Spam", Config.Misc.VoidSpam, ToggleVoidSpam, itemY).Y + 32

    elseif CurrentTab == "Settings" then
        -- Temi
        local themeLabel = Drawing.new("Text")
        themeLabel.Visible = true
        themeLabel.Text = "Tema: " .. Config.MenuStyle.Theme
        themeLabel.Color = style.TextColor
        themeLabel.Size = fs + 2
        themeLabel.Position = Vector2.new(contentX + 10, itemY + 5)
        table.insert(MenuObjects, themeLabel)
        itemY = itemY + 25

        local themeNames = {"Dark", "Light", "Blue", "Red", "Green", "Purple", "Orange"}
        local btnW = (contentW - 20) / 3
        for i, tn in ipairs(themeNames) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local bx = contentX + 10 + col * (btnW + 5)
            local by = itemY + row * 30

            local btn = Drawing.new("Square")
            btn.Visible = true
            btn.Size = Vector2.new(btnW, 25)
            btn.Position = Vector2.new(bx, by)
            btn.Color = tn == Config.MenuStyle.Theme and style.AccentColor or style.BorderColor
            btn.Filled = true
            btn.Transparency = 0.5
            table.insert(MenuObjects, btn)

            local btxt = Drawing.new("Text")
            btxt.Visible = true
            btxt.Text = tn
            btxt.Color = style.TextColor
            btxt.Size = fs - 2
            btxt.Center = true
            btxt.Position = Vector2.new(bx + btnW / 2, by + 6)
            table.insert(MenuObjects, btxt)
        end
        itemY = itemY + math.ceil(#themeNames / 3) * 30 + 10

        -- Trasparenza
        itemY = CreateSlider("Trasparenza", Config.MenuStyle.Transparency, 0.2, 1, 0.05, "", function(v) Config.MenuStyle.Transparency = v; RebuildMenu() end, itemY).Y + 32
    end
end

-- =============================================================================
-- SEZIONE 22: TOGGLE MENU (CTRL + DESTRO)
-- =============================================================================

function ToggleMenu()
    MenuOpen = not MenuOpen
    if MenuOpen then
        RebuildMenu()
    else
        for _, obj in pairs(MenuObjects) do
            if obj.Remove then obj:Remove() end
        end
        table.clear(MenuObjects)
        table.clear(TabButtons)
    end
end

-- =============================================================================
-- SEZIONE 23: INPUT HANDLING COMPLETO
-- =============================================================================

-- Toggle menu con Ctrl+Destro
local menuTogglePressed = false
local menuToggleCtrl = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Gestione toggle menu: Ctrl + Destro
    if input.KeyCode == Config.Hotkeys.MenuToggle.Modifier then
        menuToggleCtrl = true
    end

    if input.UserInputType == Config.Hotkeys.MenuToggle.Key and menuToggleCtrl then
        ToggleMenu()
        return
    end

    -- Se il menu è aperto, gestisci click sulle tabs
    if MenuOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mx, my = Mouse.X, Mouse.Y

        -- Controlla tabs
        for _, tab in ipairs(TabButtons) do
            if
