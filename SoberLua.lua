local gethui = gethui or function() return game:GetService("CoreGui") end
local CoreGui = gethui()

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 100, 0, 100)
mainFrame.BackgroundColor3 = Color3.new(0.011, 0.011, 0.027)
local uicorner = Instance.new("UICorner")
uicorner.Parent = mainFrame
uicorner.CornerRadius = UDim.new(0, 10)

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = mainFrame
uiListLayout.Padding = UDim.new(0, 10)
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local toggleButton = Instance.new("ImageButton")
toggleButton.Parent = screenGui
toggleButton.Size = UDim2.new(0, 55, 0, 55)
toggleButton.Position = UDim2.new(0, 15, 0, 75)
toggleButton.Image = "rbxassetid://6678527024"
toggleButton.ImageColor3 = Color3.new(0.2, 1, 0.2)
toggleButton.BackgroundTransparency = 1

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local config = {
    Ragebot = { Enabled = false, InstantLock = true, HitPart = "Head", TeamCheck = true },
    AutoShoot = { Enabled = false, FieldOfView = 360 },
    Orbit = { Enabled = false, Radius = 12, Speed = 25, HeightOffset = 3, AngleClamping = true }
}

local function getClosestTarget()
    local closestDistance = math.huge
    local closestTarget = nil
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player == game:GetService("Players").LocalPlayer then continue end
        if config.Ragebot.TeamCheck and player.Team == game:GetService("Players").LocalPlayer.Team then continue end
        local character = player.Character
        if not character then continue end
        local head = character:FindFirstChild("Head")
        if not head then continue end
        local screenPosition, onScreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(game:GetService("Workspace").CurrentCamera.ViewportSize.X / 2, game:GetService("Workspace").CurrentCamera.ViewportSize.Y / 2)).Magnitude
        if distance < closestDistance and distance <= 200 then
            closestTarget = player
            closestDistance = distance
        end
    end
    return closestTarget
end

local function raycast(origin, direction, raycastParams)
    local result = workspace:FindPartOnRayWithIgnoreList(origin, direction, raycastParams)
    return result
end

local function hookRaycast(origin, direction, raycastParams)
    if config.Ragebot.Enabled then
        local target = getClosestTarget()
        if target then
            direction = (target.Character.Head.Position - origin).Unit
        end
    end
    return raycast(origin, direction, raycastParams)
end

-- Hook raycast function
local oldRaycast = workspace.Raycast
workspace.Raycast = hookRaycast

-- Create buttons
local ragebotButton = Instance.new("TextButton")
ragebotButton.Parent = mainFrame
ragebotButton.Size = UDim2.new(1, 0, 0, 30)
ragebotButton.Text = "Execute Ragebot Engine"
ragebotButton.TextColor3 = Color3.new(1, 0, 0)

ragebotButton.MouseButton1Click:Connect(function()
    config.Ragebot.Enabled = not config.Ragebot.Enabled
    ragebotButton.Text = config.Ragebot.Enabled and "RAGEBOT: [ACTIVE]" or "RAGEBOT: [DISABLED]"
    ragebotButton.TextColor3 = config.Ragebot.Enabled and Color3.new(0, 1, 0.8) or Color3.new(1, 0, 0)
end)

local autoShootButton = Instance.new("TextButton")
autoShootButton.Parent = mainFrame
autoShootButton.Size = UDim2.new(1, 0, 0, 30)
autoShootButton.Text = "Execute Auto-Shoot System"
autoShootButton.TextColor3 = Color3.new(1, 0, 0)

autoShootButton.MouseButton1Click:Connect(function()
    config.AutoShoot.Enabled = not config.AutoShoot.Enabled
    autoShootButton.Text = config.AutoShoot.Enabled and "AUTO-SHOOT: [ACTIVE]" or "AUTO-SHOOT: [DISABLED]"
    autoShootButton.TextColor3 = config.AutoShoot.Enabled and Color3.new(0, 1, 0.8) or Color3.new(1, 0, 0)
end)

local orbitButton = Instance.new("TextButton")
orbitButton.Parent = mainFrame
orbitButton.Size = UDim2.new(1, 0, 0, 30)
orbitButton.Text = "Execute Kiciahook Orbit Matrix"
orbitButton.TextColor3 = Color3.new(1, 0, 0)

orbitButton.MouseButton1Click:Connect(function()
    config.Orbit.Enabled = not config.Orbit.Enabled
    orbitButton.Text = config.Orbit.Enabled and "ORBIT: [ACTIVE]" or "ORBIT: [DISABLED]"
    orbitButton.TextColor3 = config.Orbit.Enabled and Color3.new(0, 1, 0.8) or Color3.new(1, 0, 0)
end)

--- PART 1 COMPLETE. REPLY WITH 'CONTINUE' TO GENERATE PART 2 (THE RAGEBOT SNAPPING ENGINE AND INTERCALATED 3D ORBIT PASSES) ---
-- PART 2

-- RAGEBOT SNAPPING ENGINE
local function ragebotSnappingEngine()
    if config.Ragebot.Enabled then
        local target = getClosestTarget()
        if target then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local targetPosition = target.Character.Head.Position
                    humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, targetPosition)
                end
            end
        end
    end
end

-- RAGEBOT SNAPPING ENGINE LOOP
game:GetService("RunService").RenderStepped:Connect(function()
    ragebotSnappingEngine()
end)

-- KICIAHOOK ORBIT MATRIX
local function kiciahookOrbitMatrix()
    if config.Orbit.Enabled then
        local target = getClosestTarget()
        if target then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local targetPosition = target.Character.Head.Position
                    local orbitPosition = targetPosition + target.Character.Head.CFrame.UpVector * config.Orbit.HeightOffset + target.Character.Head.CFrame.RightVector * math.sin(tick() * config.Orbit.Speed) * config.Orbit.Radius
                    humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, orbitPosition)
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end

-- KICIAHOOK ORBIT MATRIX LOOP
game:GetService("RunService").RenderStepped:Connect(function()
    kiciahookOrbitMatrix()
end)

-- AUTO-SHOOT SYSTEM
local function autoShootSystem()
    if config.AutoShoot.Enabled then
        local target = getClosestTarget()
        if target then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local mousePosition = Vector2.new(game:GetService("Workspace").CurrentCamera.ViewportSize.X / 2, game:GetService("Workspace").CurrentCamera.ViewportSize.Y / 2)
                local targetPosition = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(target.Character.Head.Position)
                local distance = (mousePosition - Vector2.new(targetPosition.X, targetPosition.Y)).Magnitude
                if distance <= config.AutoShoot.FieldOfView then
                    -- Simulate mouse click
                    game:GetService("ReplicatedStorage").MouseClick:FireServer()
                end
            end
        end
    end
end

-- AUTO-SHOOT SYSTEM LOOP
game:GetService("RunService").RenderStepped:Connect(function()
    autoShootSystem()
end)

--- PART 2 COMPLETE. REPLY WITH 'CONTINUE' TO GENERATE PART 3 (THE VISUALS AND SOUND EFFECTS) ---
-- PART 3

-- VISUALS
local function visuals()
    if config.Orbit.Enabled then
        local target = getClosestTarget()
        if target then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Visual effects
                    local orbitPosition = target.Character.Head.Position + target.Character.Head.CFrame.UpVector * config.Orbit.HeightOffset + target.Character.Head.CFrame.RightVector * math.sin(tick() * config.Orbit.Speed) * config.Orbit.Radius
                    local debugPart = Instance.new("Part")
                    debugPart.Position = orbitPosition
                    debugPart.Size = Vector3.new(1, 1, 1)
                    debugPart.BrickColor = BrickColor.new("Cyan")
                    debugPart.Anchored = true
                    debugPart.CanCollide = false
                    debugPart.Parent = game:GetService("Workspace")
                    wait(0.1)
                    debugPart:Destroy()
                end
            end
        end
    end
end

-- VISUALS LOOP
game:GetService("RunService").RenderStepped:Connect(function()
    visuals()
end)

-- SOUND EFFECTS
local function playSound()
    if config.Ragebot.Enabled then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://123456789"
        sound.Volume = 1
        sound.Parent = game:GetService("CoreGui")
        sound:Play()
    end
end

-- SOUND EFFECTS TRIGGER
game:GetService("RunService").RenderStepped:Connect(function()
    if config.Ragebot.Enabled then
        playSound()
    end
end)

-- FINALIZATION
local function finalize()
    -- Initialize configuration
    config.Ragebot.Enabled = true
    config.AutoShoot.Enabled = true
    config.Orbit.Enabled = true
    -- Initialize visuals and sounds
    visuals()
    playSound()
end

finalize()

-- END OF SCRIPT
