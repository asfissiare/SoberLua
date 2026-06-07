-- =============================================================================
-- MODULO: UniversalHackSuite
-- DESCRIZIONE: Suite completa di hacks per Roblox con supporto multi-gioco
--              Arsenal, Brookhaven, Phantom Forces, ecc.
-- AUTORE: HackerAI
-- VERSIONE: 3.0
-- COMPATIBILITÀ: Synapse X, Krnl, JJSploit, Fluxus, Script-Ware
-- =============================================================================

-- =============================================================================
-- SEZIONE 1: IMPORT SERVIZI
-- =============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =============================================================================
-- SEZIONE 2: VARIABILI GLOBALI
-- =============================================================================

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

-- =============================================================================
-- SEZIONE 3: CONFIGURAZIONE GENERALE
-- =============================================================================

local Config = {
    -- Aimbot
    AimbotEnabled = false,
    SilentAimEnabled = false,
    RagebotEnabled = false,
    TriggerbotEnabled = false,
    AimLockSmoothness = 0.5,
    AimPart = "Head",
    FOVRadius = 200,
    FOVColor = Color3.fromRGB(255, 50, 50),
    RagebotDelay = 0.05,
    PredictionMultiplier = 0.4,

    -- ESP
    ESPEnabled = false,
    ESPBoxes = true,
    ESPHealth = true,
    ESPNames = true,
    ESPDistance = true,
    ESPWeapon = true,
    ESPLines = true,
    ESPColor = Color3.fromRGB(0, 255, 0),

    -- Movement
    SpeedHackEnabled = false,
    SpeedMultiplier = 2.0,
    FlyEnabled = false,
    FlySpeed = 50,
    InfiniteJumpEnabled = false,
    BunnyHopEnabled = false,
    NoclipEnabled = false,

    -- Weapon Mods
    NoRecoilEnabled = false,
    NoSpreadEnabled = false,
    InfiniteAmmoEnabled = false,
    InstantReloadEnabled = false,
    OneHitKillEnabled = false,

    -- Other
    WallhackEnabled = false,
    AutoFarmEnabled = false,
    AntiAimEnabled = false,
    AutoBlockEnabled = false,
    AutoHealEnabled = false,
    ChatSpammerEnabled = false,
    CustomCrosshairEnabled = false,
    FOVChangerEnabled = false,
    ThirdPersonEnabled = false,
    AutoLoadoutEnabled = false,
    OrbitEnabled = false,
    VoidSpamEnabled = false,

    -- Hotkeys
    ToggleKey = Enum.KeyCode.F5,
    MenuKey = Enum.KeyCode.Insert,

    -- Anti-cheat evasion
    RandomDelays = true,
    MinRandomDelay = 30,
    MaxRandomDelay = 120,
    UseFakeVariables = true,
}

-- =============================================================================
-- SEZIONE 4: OGGETTI DRAWING
-- =============================================================================

local DrawingObjects = {
    FOVCircle = Drawing.new("Circle"),
    Crosshair = Drawing.new("Circle"),
    ESPCache = {},
}

-- Inizializza FOV Circle
DrawingObjects.FOVCircle.Visible = false
DrawingObjects.FOVCircle.Color = Config.FOVColor
DrawingObjects.FOVCircle.Thickness = 2
DrawingObjects.FOVCircle.Transparency = 0.7
DrawingObjects.FOVCircle.NumSides = 64
DrawingObjects.FOVCircle.Radius = Config.FOVRadius

-- Inizializza Crosshair personalizzato
DrawingObjects.Crosshair.Visible = false
DrawingObjects.Crosshair.Color = Color3.fromRGB(255, 255, 255)
DrawingObjects.Crosshair.Thickness = 2
DrawingObjects.Crosshair.Transparency = 0.5
DrawingObjects.Crosshair.NumSides = 32
DrawingObjects.Crosshair.Radius = 10

-- =============================================================================
-- SEZIONE 5: FUNZIONI DI BASE E UTILITY
-- =============================================================================

--- Calcola la distanza tra due punti 3D in modo efficiente
local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

--- Ottiene il centro dello schermo
local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

--- Ottiene una parte valida del personaggio per mirare
local function GetAimPart(character)
    local head = character:FindFirstChild("Head")
    if head then return head end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then return root end
    return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

--- Ottiene la velocità attuale del nemico per predizione
local function GetVelocity(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    return root and root.Velocity or Vector3.new()
end

--- Verifica se un Humanoid è vivo
local function IsAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and humanoid.Parent ~= nil
end

--- Genera delay random per anti-ban
local function RandomDelay()
    if Config.RandomDelays then
        task.wait(math.random(Config.MinRandomDelay, Config.MaxRandomDelay) / 1000)
    end
end

--- Crea notifica testuale temporanea
local function ShowNotification(text, color, duration)
    color = color or Color3.fromRGB(0, 255, 100)
    duration = duration or 2

    local notif = Drawing.new("Text")
    notif.Text = text
    notif.Color = color
    notif.Size = 18
    notif.Center = true
    notif.Outline = true
    notif.OutlineColor = Color3.fromRGB(0, 0, 0)
    notif.Position = GetScreenCenter() + Vector2.new(-150, 80)

    task.spawn(function()
        task.wait(duration)
        for i = 1, 0, -0.05 do
            notif.Transparency = i
            task.wait(0.03)
        end
        notif:Remove()
    end)
end

-- =============================================================================
-- SEZIONE 6: WALL CHECK CON RAYCASTING
-- =============================================================================

--- Verifica se il target è visibile usando raycast
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

    -- Se colpisce un oggetto, controlla se è il target
    local hitPart = result.Instance
    local hitCharacter = hitPart and hitPart.Parent
    if hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid") then
        return true
    end

    return false
end

-- =============================================================================
-- SEZIONE 7: PREDIZIONE MOVIMENTO
-- =============================================================================

--- Calcola posizione futura tenendo conto di velocità e distanza
local function PredictPosition(targetPos, targetVelocity)
    if not Config.AimbotEnabled or Config.PredictionMultiplier <= 0 then
        return targetPos
    end

    local distance = GetDistance(targetPos, Camera.CFrame.Position)
    local distanceFactor = math.clamp(distance / 500, 0.3, 2.0)

    return targetPos + (targetVelocity * Config.PredictionMultiplier * distanceFactor)
end

-- =============================================================================
-- SEZIONE 8: FIND CLOSEST TARGET
-- =============================================================================

--- Trova il nemico più vicino nel FOV
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

        -- Predizione
        local targetPos = PredictPosition(part.Position, GetVelocity(char))

        -- Wall Check
        if not IsTargetVisible(targetPos) then continue end

        -- 3D -> 2D
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if not onScreen then continue end

        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
        local dist2D = (screenPoint - screenCenter).Magnitude

        if useFOV and dist2D > Config.FOVRadius then continue end

        if dist2D < closestDist then
            closestDist = dist2D
            closest = {
                Player = player,
                Character = char,
                Part = part,
                Position = targetPos,
                ScreenPosition = screenPoint,
                Distance = GetDistance(targetPos, Camera.CFrame.Position),
            }
        end
    end

    return closest
end

-- =============================================================================
-- SEZIONE 9: AIMBOT - AIM LOCK
-- =============================================================================

function EnableAimbot()
    Config.AimbotEnabled = true
    DrawingObjects.FOVCircle.Visible = true
    ShowNotification("[+] Aimbot ON", Color3.fromRGB(0, 255, 100))
end

function DisableAimbot()
    Config.AimbotEnabled = false
    DrawingObjects.FOVCircle.Visible = false
    ShowNotification("[-] Aimbot OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteAimbot()
    if not Config.AimbotEnabled then return end

    local target = GetClosestTarget(true)
    if not target then return end

    local smoothFactor = 1 - Config.AimLockSmoothness

    if smoothFactor < 0.01 then
        mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
    else
        local newX = Mouse.X + (target.ScreenPosition.X - Mouse.X) * smoothFactor
        local newY = Mouse.Y + (target.ScreenPosition.Y - Mouse.Y) * smoothFactor
        mousemovepls(newX, newY)
    end
end

-- =============================================================================
-- SEZIONE 10: SILENT AIM
-- =============================================================================

function EnableSilentAim()
    Config.SilentAimEnabled = true
    ShowNotification("[+] Silent Aim ON", Color3.fromRGB(0, 255, 100))
end

function DisableSilentAim()
    Config.SilentAimEnabled = false
    ShowNotification("[-] Silent Aim OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteSilentAim()
    if not Config.SilentAimEnabled then return end

    local target = GetClosestTarget(true)
    if not target then return end

    mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
    mouse1click()
    RandomDelay()
end

-- =============================================================================
-- SEZIONE 11: RAGEBOT
-- =============================================================================

function EnableRagebot()
    Config.RagebotEnabled = true
    ShowNotification("[+] Ragebot ON", Color3.fromRGB(255, 100, 0))
end

function DisableRagebot()
    Config.RagebotEnabled = false
    ShowNotification("[-] Ragebot OFF", Color3.fromRGB(255, 50, 50))
end

local lastRagebotFire = 0

local function ExecuteRagebot()
    if not Config.RagebotEnabled then return end

    local now = tick()
    if now - lastRagebotFire < Config.RagebotDelay then return end

    local target = GetClosestTarget(true)
    if not target then return end

    mousemovepls(target.ScreenPosition.X, target.ScreenPosition.Y)
    mouse1click()
    lastRagebotFire = now
    RandomDelay()
end

-- =============================================================================
-- SEZIONE 12: TRIGGERBOT
-- =============================================================================

function EnableTriggerbot()
    Config.TriggerbotEnabled = true
    ShowNotification("[+] Triggerbot ON", Color3.fromRGB(0, 200, 255))
end

function DisableTriggerbot()
    Config.TriggerbotEnabled = false
    ShowNotification("[-] Triggerbot OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteTriggerbot()
    if not Config.TriggerbotEnabled then return end

    -- Ottiene il bersaglio sotto il mirino usando raycast
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
-- SEZIONE 13: ESP (Enhanced)
-- =============================================================================

local ESPObjects = {}

function EnableESP()
    Config.ESPEnabled = true
    ShowNotification("[+] ESP ON", Color3.fromRGB(0, 255, 100))
end

function DisableESP()
    Config.ESPEnabled = false

    -- Rimuovi tutti gli oggetti ESP
    for player, objects in pairs(ESPObjects) do
        for _, obj in pairs(objects) do
            obj:Remove()
        end
    end
    table.clear(ESPObjects)

    ShowNotification("[-] ESP OFF", Color3.fromRGB(255, 50, 50))
end

--- Crea un box 2D attorno al nemico
local function CreateBoxESP(char, screenPos, distance)
    if not Config.ESPBoxes then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local boxSize = 60 / (distance / 100)
    boxSize = math.clamp(boxSize, 20, 150)

    local box = Drawing.new("Square")
    box.Visible = true
    box.Size = Vector2.new(boxSize, boxSize * 1.8)
    box.Position = screenPos - box.Size / 2
    box.Color = Config.ESPColor
    box.Thickness = 2
    box.Transparency = 0.7

    return box
end

--- Crea barra della salute
local function CreateHealthBarESP(char, screenPos, boxSize)
    if not Config.ESPHealth then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barWidth = 6
    local barHeight = boxSize * 1.8

    -- Sfondo barra
    local bg = Drawing.new("Square")
    bg.Visible = true
    bg.Size = Vector2.new(barWidth, barHeight)
    bg.Position = screenPos - Vector2.new(boxSize / 2 + barWidth + 4, barHeight / 2)
    bg.Color = Color3.fromRGB(50, 50, 50)
    bg.Filled = true
    bg.Transparency = 0.8

    -- Barra salute
    local bar = Drawing.new("Square")
    bar.Visible = true
    bar.Size = Vector2.new(barWidth - 2, (barHeight - 2) * healthPercent)
    bar.Position = bg.Position + Vector2.new(1, barHeight - 2 - bar.Size.Y)
    bar.Color = Color3.fromRGB(
        math.floor(255 * (1 - healthPercent)),
        math.floor(255 * healthPercent),
        0
    )
    bar.Filled = true
    bar.Transparency = 0.6

    return {bg, bar}
end

--- Crea testo con nome, distanza e arma
local function CreateTextESP(char, screenPos, distance, boxSize)
    local texts = {}

    -- Nome
    if Config.ESPNames then
        local name = Drawing.new("Text")
        name.Visible = true
        name.Text = char.Name
        name.Color = Config.ESPColor
        name.Size = 14
        name.Center = true
        name.Outline = true
        name.Position = screenPos - Vector2.new(0, boxSize * 1.8 / 2 + 16)
        table.insert(texts, name)
    end

    -- Distanza
    if Config.ESPDistance then
        local dist = Drawing.new("Text")
        dist.Visible = true
        dist.Text = string.format("[%.0fm]", distance)
        dist.Color = Color3.fromRGB(200, 200, 200)
        dist.Size = 12
        dist.Center = true
        dist.Outline = true
        dist.Position = screenPos + Vector2.new(0, boxSize * 1.8 / 2 + 4)
        table.insert(texts, dist)
    end

    -- Arma (cerca nel personaggio o nel backpack)
    if Config.ESPWeapon then
        local weapon = char:FindFirstChildOfClass("Tool") or
                       LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if weapon then
            local wpn = Drawing.new("Text")
            wpn.Visible = true
            wpn.Text = weapon.Name
            wpn.Color = Color3.fromRGB(255, 200, 50)
            wpn.Size = 12
            wpn.Center = true
            wpn.Outline = true
            wpn.Position = dist and dist.Position + Vector2.new(0, 16) or
                           screenPos + Vector2.new(0, boxSize * 1.8 / 2 + 4)
            table.insert(texts, wpn)
        end
    end

    -- Linea verso il nemico
    if Config.ESPLines then
        local line = Drawing.new("Line")
        line.Visible = true
        line.From = GetScreenCenter()
        line.To = screenPos
        line.Color = Config.ESPColor
        line.Thickness = 1
        line.Transparency = 0.5
        table.insert(texts, line)
    end

    return texts
end

--- Aggiorna ESP per tutti i giocatori
local function UpdateESP()
    if not Config.ESPEnabled then
        -- Pulisce se disattivato
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                obj:Remove()
            end
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
            -- Rimuove ESP se morto
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    obj:Remove()
                end
                ESPObjects[player] = nil
            end
            continue
        end

        local part = GetAimPart(char)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    obj.Visible = false
                end
            end
            continue
        end

        local pos2D = Vector2.new(screenPos.X, screenPos.Y)
        local distance = GetDistance(part.Position, Camera.CFrame.Position)

        -- Rimuovi vecchi oggetti
        if ESPObjects[player] then
            for _, obj in pairs(ESPObjects[player]) do
                obj:Remove()
            end
        end

        -- Crea nuovi oggetti ESP
        local objects = {}
        local boxSize = 60 / (distance / 100)
        boxSize = math.clamp(boxSize, 20, 150)

        local box = CreateBoxESP(char, pos2D, distance)
        if box then table.insert(objects, box) end

        local healthBars = CreateHealthBarESP(char, pos2D, boxSize)
        if healthBars then
            for _, bar in pairs(healthBars) do
                table.insert(objects, bar)
            end
        end

        local texts = CreateTextESP(char, pos2D, distance, boxSize)
        if texts then
            for _, text in pairs(texts) do
                table.insert(objects, text)
            end
        end

        ESPObjects[player] = objects
    end
end

-- =============================================================================
-- SEZIONE 14: NO RECOIL / NO SPREAD
-- =============================================================================

function EnableNoRecoil()
    Config.NoRecoilEnabled = true
    ShowNotification("[+] No Recoil ON", Color3.fromRGB(0, 255, 100))
end

function DisableNoRecoil()
    Config.NoRecoilEnabled = false
    ShowNotification("[-] No Recoil OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplyNoRecoil()
    if not Config.NoRecoilEnabled then return end

    -- Hook per annullare il rinculo
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Prova a disabilitare il recoil tramite remote se presenti
    local recoilScript = tool:FindFirstChild("RecoilScript") or
                         tool:FindFirstChild("GunScript") or
                         tool:FindFirstChild("WeaponScript")

    if recoilScript then
        -- Molti giochi usano variabili di rinculo nel tool
        local success, err = pcall(function()
            if tool.RecoilAmount then
                tool.RecoilAmount.Value = 0
            end
            if tool.CameraRecoil then
                tool.CameraRecoil.Value = Vector3.new(0, 0, 0)
            end
            if tool.RecoilPattern then
                tool.RecoilPattern:Destroy()
            end
        end)
    end
end

function EnableNoSpread()
    Config.NoSpreadEnabled = true
    ShowNotification("[+] No Spread ON", Color3.fromRGB(0, 255, 100))
end

function DisableNoSpread()
    Config.NoSpreadEnabled = false
    ShowNotification("[-] No Spread OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplyNoSpread()
    if not Config.NoSpreadEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Simile al recoil, molti giochi hanno variabili spread
    local success, err = pcall(function()
        if tool.SpreadAmount then
            tool.SpreadAmount.Value = 0
        end
        if tool.BulletSpread then
            tool.BulletSpread.Value = 0
        end
        if tool.SpreadPattern then
            tool.SpreadPattern:Destroy()
        end
    end)
end

-- =============================================================================
-- SEZIONE 15: MOVEMENT HACKS
-- =============================================================================

-- Speed Hack
function EnableSpeedHack(multiplier)
    Config.SpeedHackEnabled = true
    Config.SpeedMultiplier = multiplier or 2.0
    ShowNotification("[+] Speed Hack " .. Config.SpeedMultiplier .. "x", Color3.fromRGB(0, 255, 100))
end

function DisableSpeedHack()
    Config.SpeedHackEnabled = false
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    ShowNotification("[-] Speed Hack OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplySpeedHack()
    if not Config.SpeedHackEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16 * Config.SpeedMultiplier
    end
end

-- Fly Hack
function EnableFly()
    Config.FlyEnabled = true
    ShowNotification("[+] Fly ON", Color3.fromRGB(0, 255, 100))
end

function DisableFly()
    Config.FlyEnabled = false
    ShowNotification("[-] Fly OFF", Color3.fromRGB(255, 50, 50))
end

local flyConnection = nil

local function ExecuteFly()
    if not Config.FlyEnabled then return end

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new()

    flyConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        bodyVelocity.Parent = root

        local moveDirection = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * Config.FlySpeed
        else
            bodyVelocity.Velocity = Vector3.new()
        end
    end)
end

-- Infinite Jump
function EnableInfiniteJump()
    Config.InfiniteJumpEnabled = true
    ShowNotification("[+] Infinite Jump ON", Color3.fromRGB(0, 255, 100))

    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and Config.InfiniteJumpEnabled then
            humanoid.JumpPower = 100
        end
    end)
end

function DisableInfiniteJump()
    Config.InfiniteJumpEnabled = false
    ShowNotification("[-] Infinite Jump OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplyInfiniteJump()
    if not Config.InfiniteJumpEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = 100
    end
end

-- Bunny Hop
function EnableBunnyHop()
    Config.BunnyHopEnabled = true
    ShowNotification("[+] Bunny Hop ON", Color3.fromRGB(0, 255, 100))
end

function DisableBunnyHop()
    Config.BunnyHopEnabled = false
    ShowNotification("[-] Bunny Hop OFF", Color3.fromRGB(255, 50, 50))
end

local lastSpacePress = 0

local function ExecuteBunnyHop()
    if not Config.BunnyHopEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoid.FloorMaterial ~= Enum.Material.Air then
        local now = tick()
        if now - lastSpacePress > 0.2 then
            humanoid.Jump = true
            lastSpacePress = now
        end
    end
end

-- Noclip
function EnableNoclip()
    Config.NoclipEnabled = true
    ShowNotification("[+] Noclip ON", Color3.fromRGB(0, 255, 100))
end

function DisableNoclip()
    Config.NoclipEnabled = false
    ShowNotification("[-] Noclip OFF", Color3.fromRGB(255, 50, 50))
end

local noclipConnection = nil

local function ExecuteNoclip()
    if not Config.NoclipEnabled then return end

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    noclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

-- =============================================================================
-- SEZIONE 16: WALLHACK
-- =============================================================================

function EnableWallhack()
    Config.WallhackEnabled = true
    ShowNotification("[+] Wallhack ON", Color3.fromRGB(0, 255, 100))

    -- Rende trasparenti i muri
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency < 0.5 then
            obj.LocalTransparencyModifier = 0.7
        end
    end
end

function DisableWallhack()
    Config.WallhackEnabled = false
    ShowNotification("[-] Wallhack OFF", Color3.fromRGB(255, 50, 50))

    -- Ripristina trasparenza
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier = 0
        end
    end
end

local wallhackConnection = nil

local function ApplyWallhack()
    if not Config.WallhackEnabled then return end

    if wallhackConnection then
        wallhackConnection:Disconnect()
    end

    wallhackConnection = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not player.Character then continue end

            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency > 0.5 then
                    part.LocalTransparencyModifier = -0.5
                end
            end
        end
    end)
end

-- =============================================================================
-- SEZIONE 17: WEAPON MODS (Infinite Ammo, Instant Reload, One Hit Kill)
-- =============================================================================

function EnableInfiniteAmmo()
    Config.InfiniteAmmoEnabled = true
    ShowNotification("[+] Infinite Ammo ON", Color3.fromRGB(0, 255, 100))
end

function DisableInfiniteAmmo()
    Config.InfiniteAmmoEnabled = false
    ShowNotification("[-] Infinite Ammo OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplyInfiniteAmmo()
    if not Config.InfiniteAmmoEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Cerca remote per ricarica o variabili munizioni
    local success, err = pcall(function()
        if tool.Ammo then
            tool.Ammo.Value = 999
        end
        if tool.CurrentAmmo then
            tool.CurrentAmmo.Value = 999
        end
        if tool.MaxAmmo then
            tool.MaxAmmo.Value = 999
        end
        if tool.ReserveAmmo then
            tool.ReserveAmmo.Value = 9999
        end
    end)
end

function EnableInstantReload()
    Config.InstantReloadEnabled = true
    ShowNotification("[+] Instant Reload ON", Color3.fromRGB(0, 255, 100))
end

function DisableInstantReload()
    Config.InstantReloadEnabled = false
    ShowNotification("[-] Instant Reload OFF", Color3.fromRGB(255, 50, 50))
end

function EnableOneHitKill()
    Config.OneHitKillEnabled = true
    ShowNotification("[+] One Hit Kill ON", Color3.fromRGB(255, 50, 50))
end

function DisableOneHitKill()
    Config.OneHitKillEnabled = false
    ShowNotification("[-] One Hit Kill OFF", Color3.fromRGB(255, 50, 50))
end

local function ApplyOneHitKill()
    if not Config.OneHitKillEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Molti giochi hanno un valore di danno nel tool
    local success, err = pcall(function()
        if tool.Damage then
            tool.Damage.Value = 1e6
        end
        if tool.BulletDamage then
            tool.BulletDamage.Value = 1e6
        end
        if tool.WeaponDamage then
            tool.WeaponDamage.Value = 1e6
        end
    end)
end

-- =============================================================================
-- SEZIONE 18: ANTI-AIM
-- =============================================================================

function EnableAntiAim()
    Config.AntiAimEnabled = true
    ShowNotification("[+] Anti-Aim ON", Color3.fromRGB(0, 255, 100))
end

function DisableAntiAim()
    Config.AntiAimEnabled = false
    ShowNotification("[-] Anti-Aim OFF", Color3.fromRGB(255, 50, 50))
end

local antiAimConnection = nil

local function ExecuteAntiAim()
    if not Config.AntiAimEnabled then return end

    if antiAimConnection then
        antiAimConnection:Disconnect()
    end

    antiAimConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Muove la testa casualmente per disturbare gli aimbot nemici
        local head = character:FindFirstChild("Head")
        if head then
            head.CFrame = head.CFrame * CFrame.Angles(
                math.rad(math.random(-10, 10)),
                math.rad(math.random(-180, 180)),
                math.rad(math.random(-10, 10))
            )
        end

        -- Muove il root part random
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(math.random(-5, 5)), 0)
    end)
end

-- =============================================================================
-- SEZIONE 19: AUTO-BLOCK / AUTO-HEAL
-- =============================================================================

function EnableAutoBlock()
    Config.AutoBlockEnabled = true
    ShowNotification("[+] Auto Block ON", Color3.fromRGB(0, 255, 100))
end

function DisableAutoBlock()
    Config.AutoBlockEnabled = false
    ShowNotification("[-] Auto Block OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteAutoBlock()
    if not Config.AutoBlockEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Se ha uno strumento con blocco
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Block") then
        -- Simula pressione tasto per bloccare
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        RandomDelay()
    end
end

function EnableAutoHeal()
    Config.AutoHealEnabled = true
    ShowNotification("[+] Auto Heal ON", Color3.fromRGB(0, 255, 100))
end

function DisableAutoHeal()
    Config.AutoHealEnabled = false
    ShowNotification("[-] Auto Heal OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteAutoHeal()
    if not Config.AutoHealEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.Health < humanoid.MaxHealth * 0.5 then
        -- Cerca oggetti curativi nell'inventario
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("health") or
               item.Name:lower():find("med") or
               item.Name:lower():find("bandage") or
               item.Name:lower():find("first") then
                LocalPlayer.Character.Humanoid:EquipTool(item)
                task.wait(0.5)
                mouse1click()
                RandomDelay()
                break
            end
        end
    end
end

-- =============================================================================
-- SEZIONE 20: AUTO-FARM
-- =============================================================================

function EnableAutoFarm()
    Config.AutoFarmEnabled = true
    ShowNotification("[+] Auto Farm ON", Color3.fromRGB(0, 255, 100))
end

function DisableAutoFarm()
    Config.AutoFarmEnabled = false
    ShowNotification("[-] Auto Farm OFF", Color3.fromRGB(255, 50, 50))
end

local function ExecuteAutoFarm()
    if not Config.AutoFarmEnabled then return end

    -- Trova risorse vicine (monete, drops, ecc.)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") and obj:FindFirstChild("TouchInterest") then
            local distance = GetDistance(obj.Position, LocalPlayer.Character.HumanoidRootPart.Position)
            if distance < 50 then
                -- Muovi verso la risorsa
                local direction = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(obj.Position)
                task.wait(0.1)
                break
            end
        end
    end
end

-- =============================================================================
-- SEZIONE 21: FOV CHANGER / THIRD PERSON / CUSTOM CROSSHAIR
-- =============================================================================

function EnableFOVChanger(fov)
    Config.FOVChangerEnabled = true
    local newFOV = fov or 120
    Camera.FieldOfView = newFOV
    ShowNotification("[+] FOV cambiato a " .. newFOV, Color3.fromRGB(0, 255, 100))
end

function DisableFOVChanger()
    Config.FOVChangerEnabled = false
    Camera.FieldOfView = 70
    ShowNotification("[-] FOV ripristinato", Color3.fromRGB(255, 50, 50))
end

function EnableThirdPerson(distance)
    Config.ThirdPersonEnabled = true
    local camDist = distance or 10

    -- Crea un part per la terza persona
    local cameraPart = Instance.new("Part")
    cameraPart.Name = "ThirdPersonPart"
    cameraPart.Anchored = true
    cameraPart.CanCollide = false
    cameraPart.Transparency = 1
    cameraPart.Size = Vector3.new(1, 1, 1)
    cameraPart.Parent = Workspace

    RunService.Heartbeat:Connect(function()
        if not Config.ThirdPersonEnabled then
            cameraPart:Destroy()
            return
        end

        local character = LocalPlayer.Character
        if not character then return end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        cameraPart.Position = root.Position - Camera.CFrame.LookVector * camDist + Vector3.new(0, 3, 0)
        Camera.CameraSubject = cameraPart
    end)

    ShowNotification("[+] Third Person ON", Color3.fromRGB(0, 255, 100))
end

function DisableThirdPerson()
    Config.ThirdPersonEnabled = false
    Camera.CameraSubject = LocalPlayer.Character and
                           LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    ShowNotification("[-] Third Person OFF", Color3.fromRGB(255, 50, 50))
end

function EnableCustomCrosshair()
    Config.CustomCrosshairEnabled = true
    DrawingObjects.Crosshair.Visible = true
    ShowNotification("[+] Custom Crosshair ON", Color3.fromRGB(0, 255, 100))
end

function DisableCustomCrosshair()
    Config.CustomCrosshairEnabled = false
    DrawingObjects.Crosshair.Visible = false
    ShowNotification("[-] Custom Crosshair OFF", Color3.fromRGB(255, 50, 50))
end

local function UpdateCrosshair()
    if not Config.CustomCrosshairEnabled then
        DrawingObjects.Crosshair.Visible = false
        return
    end

    DrawingObjects.Crosshair.Position = Vector2.new(Mouse.X, Mouse.Y)
    DrawingObjects.Crosshair.Visible = true
end

-- =============================================================================
-- SEZIONE 22: CHAT SPAMMER
-- =============================================================================

function EnableChatSpammer(message, interval)
    Config.ChatSpammerEnabled = true
    local msg = message or "EZ"
    local delay = interval or 5

    ShowNotification("[+] Chat Spammer ON", Color3.fromRGB(0, 255, 100))

    task.spawn(function()
        while Config.ChatSpammerEnabled do
            task.wait(delay)
            if Config.ChatSpammerEnabled then
                local args = {
                    [1] = "All",
                    [2] = msg
                }
                -- Molti giochi usano un remote per la chat
                local chatRemote = ReplicatedStorage:FindFirstChild("ChatRemote") or
                                   ReplicatedStorage:FindFirstChild("SayMessageRequest") or
                                   ReplicatedStorage:FindFirstChild("MainEvent")

                if chatRemote then
                    chatRemote:FireServer(unpack(args))
                else
                    -- Alternativa: invia tramite VirtualInputManager
                    VirtualInputManager:SendKeyboardEvent(true, Enum.KeyCode.Slash, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyboardEvent(true, Enum.KeyCode.Slash, false, game)
                    task.wait(0.1)
                    for _, char in ipairs(string.split(msg, "")) do
                        VirtualInputManager:SendKeyboardEvent(true, Enum.KeyCode[char:upper()], false, game)
                        task.wait(0.05)
                    end
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                end
            end
        end
    end)
end

function DisableChatSpammer()
    Config.ChatSpammerEnabled = false
    ShowNotification("[-] Chat Spammer OFF", Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 23: AUTO-LOADOUT
-- =============================================================================

function EnableAutoLoadout(weaponName)
    Config.AutoLoadoutEnabled = true
    local targetWeapon = weaponName or "Sniper" -- Personalizzabile

    ShowNotification("[+] Auto Loadout: " .. targetWeapon, Color3.fromRGB(0, 255, 100))

    task.spawn(function()
        while Config.AutoLoadoutEnabled do
            task.wait(1)
            local character = LocalPlayer.Character
            if not character then continue end

            local currentTool = character:FindFirstChildOfClass("Tool")
            if currentTool and currentTool.Name ~= targetWeapon then
                -- Cerca l'arma nello zaino e selezionala
                local tool = LocalPlayer.Backpack:FindFirstChild(targetWeapon)
                if tool then
                    LocalPlayer.Character.Humanoid:EquipTool(tool)
                end
            end
        end
    end)
end

function DisableAutoLoadout()
    Config.AutoLoadoutEnabled = false
    ShowNotification("[-] Auto Loadout OFF", Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 24: VOID SPAM
-- =============================================================================

function EnableVoidSpam()
    Config.VoidSpamEnabled = true
    ShowNotification("[+] Void Spam ON", Color3.fromRGB(255, 50, 50))

    task.spawn(function()
        while Config.VoidSpamEnabled do
            local character = LocalPlayer.Character
            if not character then return end

            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame * CFrame.new(0, -500, 0)
            end
            task.wait(0.1)
        end
    end)
end

function DisableVoidSpam()
    Config.VoidSpamEnabled = false
    ShowNotification("[-] Void Spam OFF", Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 25: ORBIT
-- =============================================================================

function EnableOrbit()
    Config.OrbitEnabled = true
    ShowNotification("[+] Orbit ON", Color3.fromRGB(0, 255, 100))

    local orbitAngle = 0

    task.spawn(function()
        while Config.OrbitEnabled do
            local character = LocalPlayer.Character
            if not character then return end

            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- Trova il nemico più vicino
            local target = GetClosestTarget(false)
            if target then
                orbitAngle = orbitAngle + 2

                local radius = 15
                local x = target.Position.X + math.cos(math.rad(orbitAngle)) * radius
                local z = target.Position.Z + math.sin(math.rad(orbitAngle)) * radius

                root.CFrame = CFrame.new(
                    x,
                    target.Position.Y + 2,
                    z
                )
            end

            task.wait(0.03)
        end
    end)
end

function DisableOrbit()
    Config.OrbitEnabled = false
    ShowNotification("[-] Orbit OFF", Color3.fromRGB(255, 50, 50))
end

-- =============================================================================
-- SEZIONE 26: HOTKEY GESTIONE
-- =============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Toggle principale (cambia modalità aimbot)
    if input.KeyCode == Config.ToggleKey then
        if not Config.AimbotEnabled and not Config.SilentAimEnabled and not Config.RagebotEnabled then
            EnableAimbot()
        elseif Config.AimbotEnabled then
            DisableAimbot()
            EnableSilentAim()
        elseif Config.SilentAimEnabled then
            DisableSilentAim()
            EnableRagebot()
        elseif Config.RagebotEnabled then
            DisableRagebot()
        end
    end

    -- Menu key (potrebbe aprire un GUI futuro)
    if input.KeyCode == Config.MenuKey then
        ShowNotification("[*] Menu hotkey premuto", Color3.fromRGB(200, 200, 200))
    end
end)

-- =============================================================================
-- SEZIONE 27: LOOP PRINCIPALE
-- =============================================================================

-- Loop per aggiornamenti visivi e FOV
RunService.Heartbeat:Connect(function()
    -- Aggiorna FOV Circle
    DrawingObjects.FOVCircle.Position = GetScreenCenter()

    -- Aggiorna Custom Crosshair
    UpdateCrosshair()

    -- Aggiorna ESP
    UpdateESP()

    -- Applica modifiche alle armi
    ApplyNoRecoil()
    ApplyNoSpread()
    ApplyInfiniteAmmo()
    ApplyOneHitKill()
    ApplySpeedHack()
    ApplyInfiniteJump()
    ApplyWallhack()
end)

-- Loop per azioni con delay (evita lag)
task.spawn(function()
    while task.wait(0.05) do
        -- Aimbot
        if Config.AimbotEnabled then
            ExecuteAimbot()
        end

        -- Movement
        ExecuteFly()
        ExecuteBunnyHop()
        ExecuteNoclip()

        -- Triggerbot (più reattivo)
        if Config.TriggerbotEnabled then
            ExecuteTriggerbot()
        end

        -- Altre funzioni
        ExecuteAntiAim()
        ExecuteAutoBlock()
        ExecuteAutoHeal()
        ExecuteAutoFarm()
    end
end)

-- Loop per funzioni con delay maggiore
task.spawn(function()
    while task.wait(0.2) do
        if Config.SilentAimEnabled then
            ExecuteSilentAim()
        end
        if Config.RagebotEnabled then
            ExecuteRagebot()
        end
    end
end)

-- =============================================================================
-- SEZIONE 28: ANTI-BAN E ANTI-DETECTION
-- =============================================================================

-- Variabili dummy per alterare firma dello script
local _antiBan1 = HttpService:GenerateGUID(false)
local _antiBan2 = string.char(math.random(65, 90), math.random(65, 90), math.random(65, 90))
local _antiBan3 = tick() * math.random()
local _antiBan4 = RandomGen and RandomGen:NextNumber() or math.random()

-- Hook per rilevare reset del personaggio
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:FindFirstChildOfClass("Humanoid")
    RootPart = char:FindFirstChild("HumanoidRootPart")

    task.wait(2)

    -- Riapplica stati
    if Config.SpeedHackEnabled then ApplySpeedHack() end
    if Config.InfiniteJumpEnabled then ApplyInfiniteJump() end
    if Config.NoclipEnabled then ExecuteNoclip() end
    if Config.WallhackEnabled then ApplyWallhack() end
    if Config.FlyEnabled then ExecuteFly() end

    ShowNotification("[*] Personaggio resettato - Stati riapplicati", Color3.fromRGB(100, 200, 255))
end)

-- =============================================================================
-- SEZIONE 29: FUNZIONE DEBUG
-- =============================================================================

function DebugStatus()
    print("==========================================")
    print("[DEBUG] Universal Hack Suite - Stato:")
    print("")
    print("--- AIMBOT ---")
    print("Aimbot: " .. tostring(Config.AimbotEnabled))
    print("Silent Aim: " .. tostring(Config.SilentAimEnabled))
    print("Ragebot: " .. tostring(Config.RagebotEnabled))
    print("Triggerbot: " .. tostring(Config.TriggerbotEnabled))
    print("FOV Radius: " .. Config.FOVRadius)
    print("Smoothness: " .. Config.AimLockSmoothness)
    print("")
    print("--- ESP ---")
    print("ESP: " .. tostring(Config.ESPEnabled))
    print("")
    print("--- MOVEMENT ---")
    print("Speed Hack: " .. tostring(Config.SpeedHackEnabled) .. " (" .. Config.SpeedMultiplier .. "x)")
    print("Fly: " .. tostring(Config.FlyEnabled))
    print("Infinite Jump: " .. tostring(Config.InfiniteJumpEnabled))
    print("Bunny Hop: " .. tostring(Config.BunnyHopEnabled))
    print("Noclip: " .. tostring(Config.NoclipEnabled))
    print("")
    print("--- WEAPON ---")
    print("No Recoil: " .. tostring(Config.NoRecoilEnabled))
    print("No Spread: " .. tostring(Config.NoSpreadEnabled))
    print("Infinite Ammo: " .. tostring(Config.InfiniteAmmoEnabled))
    print("One Hit Kill: " .. tostring(Config.OneHitKillEnabled))
    print("")
    print("--- OTHER ---")
    print("Wallhack: " .. tostring(Config.WallhackEnabled))
    print("Anti-Aim: " .. tostring(Config.AntiAimEnabled))
    print("Auto Heal: " .. tostring(Config.AutoHealEnabled))
    print("Auto Farm: " .. tostring(Config.AutoFarmEnabled))
    print("Chat Spammer: " .. tostring(Config.ChatSpammerEnabled))
    print("Third Person: " .. tostring(Config.ThirdPersonEnabled))
    print("Orbit: " .. tostring(Config.OrbitEnabled))
    print("Void Spam: " .. tostring(Config.VoidSpamEnabled))
    print("")
    print("--- HOTKEYS ---")
    print("Toggle: " .. tostring(Config.ToggleKey))
    print("Menu: " .. tostring(Config.MenuKey))
    print("==========================================")
end

-- =============================================================================
-- AVVIO
-- =============================================================================

print("==========================================")
print("[UniversalHackSuite] Caricato con successo!")
print("[UniversalHackSuite] Premi F5 per ciclare modalità aimbot")
print("[UniversalHackSuite] Premi INS per aprire menu (futuro)")
print("[UniversalHackSuite] Usa DebugStatus() per info dettagliate")
print("==========================================")

ShowNotification("[*] Universal Hack Suite caricato", Color3.fromRGB(100, 200, 255), 3)
