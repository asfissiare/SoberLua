local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Roblox Studio compatibility mock (for development/testing only)
-- In real exploit executors (Synapse, Krnl, Fluxus, etc.), Drawing and file APIs are injected globally.
-- This prevents the "attempt to index nil with 'new'" error when testing in Studio.
if not Drawing then
    warn("[SoberLua] Drawing API not found (Roblox Studio mode). ESP drawings will be mocked and NOT visible on screen.")
    Drawing = setmetatable({}, {
        __index = function(_, key)
            if key == "new" then
                return function(typ)
                    local mock = {
                        Visible = false,
                        Thickness = 1,
                        Filled = false,
                        Size = 13,
                        Center = true,
                        Outline = true,
                        Color = Color3.new(1,1,1),
                        OutlineColor = Color3.new(0,0,0),
                        Text = "",
                        Position = Vector2.new(0,0),
                        From = Vector2.new(0,0),
                        To = Vector2.new(0,0),
                        Remove = function() end
                    }
                    return mock
                end
            end
            return nil
        end
    })
end

local Framework = {
    Config = {},
    Modules = {},
    UI = {
        Accent = Color3.fromRGB(255, 0, 252),
        Toggled = true,
        Font = Enum.Font.Gotham
    }
}

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.FileName = "SoberLua.json"
    self.Defaults = {
        ["Misc/Character/WalkSpeed"] = true,
        ["Misc/Character/WalkSpeed/Value"] = 30,
        ["Misc/Character/JumpPower"] = true,
        ["Misc/Character/JumpPower/Value"] = 100,
        ["Visuals/ThirdPerson"] = true,
        ["Visuals/ThirdPerson/Z"] = 7.5,
        ["Visuals/ThirdPerson/HideCharacter"] = true,
        ["Visuals/World/Brightness"] = 14,
        ["Visuals/World/Exposure"] = 35,
        ["Visuals/World/Fog/Enabled"] = true,
        ["Visuals/World/Fog/Density"] = 4,
        ["Visuals/World/Fog/Distance"] = 0,
        ["Visuals/World/Fog/Color"] = {alpha=0, rgb={1,0,0.929999828338623}},
        ["Visuals/Effects/ColorCorrection"] = true,
        ["Visuals/Effects/ColorCorrection/Preset"] = "Vibrant",
        ["Visuals/Effects/ColorCorrection/Brightness"] = 50,
        ["Visuals/Effects/ColorCorrection/Contrast"] = 50,
        ["Visuals/Effects/ColorCorrection/Saturation"] = 50,
        ["Visuals/Effects/Bloom"] = true,
        ["Visuals/Effects/Bloom/Intensity"] = 50,
        ["Visuals/Effects/Bloom/Size"] = 24,
        ["Visuals/Effects/Bloom/Threshold"] = 40,
        ["Visuals/Effects/SunRays"] = true,
        ["Visuals/Effects/SunRays/Intensity"] = 22,
        ["Visuals/Effects/SunRays/Spread"] = 51,
        ["Visuals/Effects/DepthOfField"] = true,
        ["Visuals/Effects/CameraMotionBlur"] = true,
        ["Visuals/Effects/CameraMotionBlur/Intensity"] = 100,
        ["Esp/Enemy/Enabled"] = true,
        ["Esp/Enemy/Box"] = true,
        ["Esp/Enemy/Name"] = true,
        ["Esp/Enemy/HealthBar"] = true,
        ["Esp/Enemy/Distance"] = false,
        ["Esp/Enemy/WeaponText"] = true,
        ["Esp/Enemy/KatanaStatus"] = false,
        ["Esp/Enemy/Ammo"] = true,
        ["Esp/Enemy/Box/Type"] = "Corner",
        ["Esp/Enemy/Box/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Enemy/Box/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/Name/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Enemy/Name/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/HealthBar/Color0"] = {alpha=1, rgb={1,0,0}},
        ["Esp/Enemy/HealthBar/Color1"] = {alpha=1, rgb={0,1,0}},
        ["Esp/Enemy/HealthBar/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/Distance/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Enemy/Distance/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/WeaponText/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Enemy/WeaponText/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/KatanaStatus/Color"] = {alpha=1, rgb={1,0,0}},
        ["Esp/Enemy/KatanaStatus/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/Ammo/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Enemy/Ammo/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Enemy/Chams"] = false,
        ["Esp/Enemy/Chams/Color"] = {alpha=0.5, rgb={0,1,0.09999990463256836}},
        ["Esp/Enemy/Chams/OutlineColor"] = {alpha=0.5, rgb={0,1,0.25}},
        ["Esp/Enemy/ChamsOccluded"] = false,
        ["Esp/Enemy/ChamsOccluded/Color"] = {alpha=1, rgb={0,1,0.09999990463256836}},
        ["Esp/Enemy/ChamsOccluded/OutlineColor"] = {alpha=1, rgb={0.08000004291534424,1,0}},
        ["Esp/Team/Enabled"] = false,
        ["Esp/Team/Box"] = true,
        ["Esp/Team/Name"] = true,
        ["Esp/Team/HealthBar"] = true,
        ["Esp/Team/WeaponText"] = true,
        ["Esp/Team/Ammo"] = true,
        ["Esp/Team/KatanaStatus"] = false,
        ["Esp/Team/Box/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Team/Box/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/Name/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Team/Name/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/HealthBar/Color0"] = {alpha=1, rgb={1,0,0}},
        ["Esp/Team/HealthBar/Color1"] = {alpha=1, rgb={0,1,0}},
        ["Esp/Team/HealthBar/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/WeaponText/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Team/WeaponText/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/Ammo/Color"] = {alpha=1, rgb={1,1,1}},
        ["Esp/Team/Ammo/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/KatanaStatus/Color"] = {alpha=1, rgb={1,0,0}},
        ["Esp/Team/KatanaStatus/OutlineColor"] = {alpha=1, rgb={0,0,0}},
        ["Esp/Team/Chams"] = false,
        ["Esp/Team/Chams/Color"] = {alpha=0.5, rgb={0,1,0.309999942779541}},
        ["Esp/Team/Chams/OutlineColor"] = {alpha=0.5, rgb={0.34999990463256838,1,0}},
        ["Esp/Team/ChamsOccluded"] = false,
        ["Esp/Team/ChamsOccluded/Color"] = {alpha=1, rgb={0,1,0.039999961853027347}},
        ["Esp/Team/ChamsOccluded/OutlineColor"] = {alpha=1, rgb={0.28999996185302737,1,0}},
        ["Esp/Extra/Size"] = false,
        ["Esp/Extra/Size/Width"] = 10,
        ["Esp/Extra/Size/Height"] = 10,
        ["Esp/Extra/HPBarThickness"] = 2,
        ["Esp/Extra/DrawDistance"] = false,
        ["Esp/Extra/DrawDistance/Limit"] = 1050,
        ["Esp/Extra/UseDisplayName"] = false,
        ["settings/menu/accent"] = {alpha=1, rgb={1,0,0.9900002479553223}},
        ["settings/menu/font"] = "Ubuntu",
        ["settings/menu/font_size"] = 11,
        ["settings/menu/keybind"] = {key={"KeyCode","RightShift"}, mode="Tap"},
        ["settings/menu/keybind_label"] = false,
        ["settings/menu/accent_label"] = false,
        ["settings/config/list"] = "RCR Rivals Blatant 6.1.json",
        ["Visuals/ArmChams/Enabled"] = true,
        ["Visuals/ArmChams/Material"] = "ForceField",
        ["Visuals/ArmChams/Reflectance"] = 0,
        ["Visuals/ArmChams/Animation"] = "None",
        ["Visuals/ArmChams/Enabled/Color"] = {alpha=0.07589285714285714, rgb={0,1,0.06999993324279785}},
        ["Visuals/GunChams/Enabled"] = true,
        ["Visuals/GunChams/Material"] = "ForceField",
        ["Visuals/GunChams/Reflectance"] = 0,
        ["Visuals/GunChams/Animation"] = "None",
        ["Visuals/GunChams/Enabled/Color"] = {alpha=1, rgb={0.7289002537727356,0,0.9850000143051148}},
        ["Visuals/BT/Enabled"] = true,
        ["Visuals/BT/Texture"] = "Interstellar",
        ["Visuals/BT/Size"] = 1,
        ["Visuals/BT/Speed"] = 1,
        ["Visuals/BT/Lifetime"] = 0.87,
        ["Visuals/BT/Length"] = 5,
        ["Visuals/BT/ShowImpacts"] = true,
        ["Visuals/BT/ServerImpacts"] = true,
        ["Visuals/BT/FaceCamera"] = false,
        ["Visuals/BT/HideGameImpacts"] = false,
        ["Visuals/BT/InitialCol"] = {alpha=0, rgb={0.9200000762939453,0,1}},
        ["Visuals/BulletTracers/FinalCol"] = {alpha=0, rgb={0.7699999809265137,0,1}},
        ["Visuals/ViewmodelOffset/Enabled"] = true,
        ["Visuals/ViewmodelOffset/X"] = 1,
        ["Visuals/ViewmodelOffset/Y"] = -0.5,
        ["Visuals/ViewmodelOffset/Z"] = -1,
        ["Visuals/ThirdPerson/X"] = 3,
        ["Visuals/ThirdPerson/Y"] = 1.5,
        ["Visuals/ThirdPerson/Z"] = 7.5,
        ["Visuals/ThirdPerson/Key"] = {mode="Toggle"},
        ["Visuals/Asus/Enabled"] = false,
        ["Visuals/Asus/ColorEnabled"] = true,
        ["Visuals/Asus/Transparency"] = 25,
        ["Visuals/Asus/Color"] = {alpha=1, rgb={0,0,0}},
        ["Visuals/Removables/FlashEffect"] = true,
        ["Visuals/Removables/FireVisual"] = true,
        ["Visuals/World/Shadows"] = false,
        ["Visuals/World/ShadowSoftness"] = 65,
        ["Visuals/World/Reflections"] = 25,
        ["Visuals/World/ColorShift"] = true,
        ["Visuals/World/ColorShift/Top"] = {alpha=0, rgb={1,0,0.7499995231628418}},
        ["Visuals/World/ColorShift/Bottom"] = {alpha=0, rgb={0.9499998092651367,0,1}},
        ["Visuals/World/AmbientColor"] = {alpha=0, rgb={0.9200000762939453,0,1}},
        ["Visuals/World/OutdoorAmbientColor"] = {alpha=0, rgb={0.8299999237060547,0,1}},
        ["Visuals/World/Fog/Enabled"] = true,
        ["Visuals/World/Fog/Color"] = {alpha=0, rgb={1,0,0.929999828338623}},
        ["Visuals/World/Fog/Density"] = 4,
        ["Visuals/World/Fog/Distance"] = 0,
        ["settings/menu/font_label"] = false
    }
    return self
end

function ConfigManager:Load()
    if isfile and isfile(self.FileName) then
        local content = readfile(self.FileName)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        if success then
            for k,v in pairs(decoded) do
                Framework.Config[k] = v
            end
            return true
        end
    end
    for k,v in pairs(self.Defaults) do
        if Framework.Config[k] == nil then
            Framework.Config[k] = v
        end
    end
    return false
end

function ConfigManager:Get(key)
    if Framework.Config[key] ~= nil then return Framework.Config[key] end
    if self.Defaults[key] ~= nil then return self.Defaults[key] end
    return nil
end

function ConfigManager:Set(key, value)
    Framework.Config[key] = value
end

function ConfigManager:Save()
    if writefile then
        local success, err = pcall(function()
            writefile(self.FileName, HttpService:JSONEncode(Framework.Config))
        end)
        return success
    end
    return false
end

local function rgbToColor3(tbl)
    if type(tbl) == "table" and tbl.rgb and #tbl.rgb == 3 then
        return Color3.new(tbl.rgb[1], tbl.rgb[2], tbl.rgb[3])
    end
    return Color3.new(1, 1, 1)
end

local VisualsEngine = {
    Drawings = {},
    Connections = {},
    Enabled = true
}

function VisualsEngine:CleanupPlayer(player)
    if self.Drawings[player] then
        for _, drawing in pairs(self.Drawings[player]) do
            if drawing and drawing.Remove then drawing:Remove() end
        end
        self.Drawings[player] = nil
    end
end

function VisualsEngine:CreateESP(target)
    if target == LocalPlayer then return end
    if target:IsA("Model") and LocalPlayer.Character and target == LocalPlayer.Character then return end
    self:CleanupPlayer(target)
    local drawings = {}
    drawings.Box = Drawing.new("Square")
    drawings.Box.Visible = false
    drawings.Box.Thickness = 1
    drawings.Box.Filled = false
    drawings.Name = Drawing.new("Text")
    drawings.Name.Visible = false
    drawings.Name.Size = 13
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.HealthBar = Drawing.new("Line")
    drawings.HealthBar.Visible = false
    drawings.HealthBar.Thickness = Framework.Config["Esp/Extra/HPBarThickness"] or 2
    drawings.HealthText = Drawing.new("Text")
    drawings.HealthText.Visible = false
    drawings.HealthText.Size = 11
    drawings.HealthText.Center = true
    drawings.HealthText.Outline = true
    drawings.Distance = Drawing.new("Text")
    drawings.Distance.Visible = false
    drawings.Distance.Size = 11
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Weapon = Drawing.new("Text")
    drawings.Weapon.Visible = false
    drawings.Weapon.Size = 11
    drawings.Weapon.Center = true
    drawings.Weapon.Outline = true
    drawings.Katana = Drawing.new("Text")
    drawings.Katana.Visible = false
    drawings.Katana.Size = 11
    drawings.Katana.Center = true
    drawings.Katana.Outline = true
    drawings.Ammo = Drawing.new("Text")
    drawings.Ammo.Visible = false
    drawings.Ammo.Size = 11
    drawings.Ammo.Center = true
    drawings.Ammo.Outline = true

    local conn = RunService.RenderStepped:Connect(function()
        if not self.Enabled or not target or not target.Parent then
            for _, d in pairs(drawings) do if d then d.Visible = false end end
            return
        end
        local char = target:IsA("Player") and target.Character or target
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChildOfClass("Humanoid") then
            for _, d in pairs(drawings) do if d then d.Visible = false end end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char.HumanoidRootPart
        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if onScreen then
            local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y
            local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y
            local sizeY = math.abs(top - bottom)
            local sizeX = sizeY * 0.6
            local boxPos = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
            local isEnemy = true
            local boxEnabled = isEnemy and Framework.Config["Esp/Enemy/Box"] or Framework.Config["Esp/Team/Box"]
            local nameEnabled = isEnemy and Framework.Config["Esp/Enemy/Name"] or Framework.Config["Esp/Team/Name"]
            local hbEnabled = isEnemy and Framework.Config["Esp/Enemy/HealthBar"] or Framework.Config["Esp/Team/HealthBar"]
            local distEnabled = isEnemy and Framework.Config["Esp/Enemy/Distance"] or Framework.Config["Esp/Team/Distance"]
            local wepEnabled = isEnemy and Framework.Config["Esp/Enemy/WeaponText"] or Framework.Config["Esp/Team/WeaponText"]
            local katEnabled = isEnemy and Framework.Config["Esp/Enemy/KatanaStatus"] or Framework.Config["Esp/Team/KatanaStatus"]
            local ammoEnabled = isEnemy and Framework.Config["Esp/Enemy/Ammo"] or Framework.Config["Esp/Team/Ammo"]
            drawings.Box.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Box/Color"] or Framework.Config["Esp/Team/Box/Color"])
            drawings.Box.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Box/OutlineColor"] or Framework.Config["Esp/Team/Box/OutlineColor"])
            drawings.Box.Size = Vector2.new(sizeX, sizeY)
            drawings.Box.Position = boxPos
            drawings.Box.Visible = boxEnabled and Framework.Config["Esp/Enemy/Enabled"]
            drawings.Name.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Name/Color"] or Framework.Config["Esp/Team/Name/Color"])
            drawings.Name.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Name/OutlineColor"] or Framework.Config["Esp/Team/Name/OutlineColor"])
            drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 16)
            local displayName = target:IsA("Player") and (Framework.Config["Esp/Extra/UseDisplayName"] and target.DisplayName or target.Name) or target.Name
            drawings.Name.Text = displayName
            drawings.Name.Visible = nameEnabled and Framework.Config["Esp/Enemy/Enabled"]
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local hbColor = Color3.new(1 - hp, hp, 0)
            drawings.HealthBar.Color = hbColor
            drawings.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + sizeY)
            drawings.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + sizeY * (1 - hp))
            drawings.HealthBar.Visible = hbEnabled and Framework.Config["Esp/Enemy/Enabled"]
            drawings.HealthText.Color = Color3.new(1,1,1)
            drawings.HealthText.Position = Vector2.new(boxPos.X - 25, boxPos.Y + sizeY * (1 - hp) - 8)
            drawings.HealthText.Text = math.floor(hum.Health)
            drawings.HealthText.Visible = hbEnabled and Framework.Config["Esp/Enemy/Enabled"]
            local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
            drawings.Distance.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Distance/Color"] or Framework.Config["Esp/Team/Distance/Color"])
            drawings.Distance.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Distance/OutlineColor"] or Framework.Config["Esp/Team/Distance/OutlineColor"])
            drawings.Distance.Position = Vector2.new(pos.X, boxPos.Y + sizeY + 5)
            drawings.Distance.Text = dist .. "m"
            drawings.Distance.Visible = distEnabled and Framework.Config["Esp/Enemy/Enabled"]
            drawings.Weapon.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/WeaponText/Color"] or Framework.Config["Esp/Team/WeaponText/Color"])
            drawings.Weapon.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/WeaponText/OutlineColor"] or Framework.Config["Esp/Team/WeaponText/OutlineColor"])
            drawings.Weapon.Position = Vector2.new(pos.X, boxPos.Y + sizeY + 18)
            drawings.Weapon.Text = "WEP"
            drawings.Weapon.Visible = wepEnabled and Framework.Config["Esp/Enemy/Enabled"]
            drawings.Katana.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/KatanaStatus/Color"] or Framework.Config["Esp/Team/KatanaStatus/Color"])
            drawings.Katana.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/KatanaStatus/OutlineColor"] or Framework.Config["Esp/Team/KatanaStatus/OutlineColor"])
            drawings.Katana.Position = Vector2.new(pos.X, boxPos.Y + sizeY + 31)
            drawings.Katana.Text = "KATANA"
            drawings.Katana.Visible = katEnabled and Framework.Config["Esp/Enemy/Enabled"]
            drawings.Ammo.Color = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Ammo/Color"] or Framework.Config["Esp/Team/Ammo/Color"])
            drawings.Ammo.OutlineColor = rgbToColor3(isEnemy and Framework.Config["Esp/Enemy/Ammo/OutlineColor"] or Framework.Config["Esp/Team/Ammo/OutlineColor"])
            drawings.Ammo.Position = Vector2.new(pos.X, boxPos.Y + sizeY + 44)
            drawings.Ammo.Text = "30/90"
            drawings.Ammo.Visible = ammoEnabled and Framework.Config["Esp/Enemy/Enabled"]
        else
            for _, d in pairs(drawings) do if d then d.Visible = false end end
        end
    end)
    table.insert(self.Connections, conn)
    self.Drawings[target] = drawings
    if target:IsA("Model") then
        target.AncestryChanged:Connect(function()
            if not target.Parent then
                VisualsEngine:CleanupPlayer(target)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p) VisualsEngine:CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) VisualsEngine:CleanupPlayer(p) end)

local UILibrary = {}

function UILibrary:CreateSlider(parent, labelText, key, minVal, maxVal, yPos, step)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -40, 0, 50)
    container.Position = UDim2.new(0, 20, 0, yPos)
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Text = labelText
    label.Size = UDim2.new(0.4, 0, 0, 25)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Framework.UI.Font
    label.TextSize = 13
    label.BackgroundTransparency = 1
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = container
    valueLabel.Text = tostring(Framework.Config[key] or minVal)
    valueLabel.Size = UDim2.new(0.2, 0, 0, 25)
    valueLabel.Position = UDim2.new(0.75, 0, 0, 0)
    valueLabel.TextColor3 = Framework.UI.Accent
    valueLabel.Font = Framework.UI.Font
    valueLabel.TextSize = 13
    valueLabel.BackgroundTransparency = 1
    local sliderBg = Instance.new("Frame")
    sliderBg.Parent = container
    sliderBg.BackgroundColor3 = Color3.fromRGB(40,40,45)
    sliderBg.Size = UDim2.new(0.7, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    local sliderFill = Instance.new("Frame")
    sliderFill.Parent = sliderBg
    sliderFill.BackgroundColor3 = Framework.UI.Accent
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Parent = sliderBg
    sliderBtn.BackgroundColor3 = Color3.new(1,1,1)
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.Position = UDim2.new(0, -8, 0, -5)
    sliderBtn.Text = ""
    Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function updateSlider(val)
        local percent = (val - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -8, 0, -5)
        valueLabel.Text = string.format("%.1f", val)
        Framework.Config[key] = val
    end
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newVal = minVal + (maxVal - minVal) * relX
            if step then newVal = math.floor(newVal / step + 0.5) * step end
            updateSlider(newVal)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    local initial = Framework.Config[key] or minVal
    updateSlider(initial)
    return container
end

function UILibrary:CreateToggle(parent, labelText, key, yPos)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -40, 0, 35)
    container.Position = UDim2.new(0, 20, 0, yPos)
    local label = Instance.new("TextLabel")
    label.Parent = container
    label.Text = labelText
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Framework.UI.Font
    label.TextSize = 13
    label.BackgroundTransparency = 1
    local tog = Instance.new("TextButton")
    tog.Parent = container
    tog.Size = UDim2.new(0, 60, 0, 26)
    tog.Position = UDim2.new(0.75, 0, 0, 4)
    tog.BackgroundColor3 = Color3.fromRGB(60,60,65)
    tog.TextColor3 = Color3.new(1,1,1)
    tog.Font = Framework.UI.Font
    tog.TextSize = 12
    tog.Text = "OFF"
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 4)
    local function refresh()
        local state = Framework.Config[key] or false
        tog.Text = state and "ON" or "OFF"
        tog.BackgroundColor3 = state and Framework.UI.Accent or Color3.fromRGB(60,60,65)
    end
    tog.MouseButton1Click:Connect(function()
        Framework.Config[key] = not (Framework.Config[key] or false)
        refresh()
    end)
    refresh()
    return container
end

function UILibrary:CreateWindow(title)
    local gui = Instance.new("ScreenGui")
    gui.Name = "SoberLua"
    gui.Parent = CoreGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Parent = gui
    main.BackgroundColor3 = Color3.fromRGB(15,15,18)
    main.Size = UDim2.new(0, 780, 0, 560)
    main.Position = UDim2.new(0.5, -390, 0.5, -280)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Parent = main
    topbar.BackgroundColor3 = Color3.fromRGB(10,10,12)
    topbar.Size = UDim2.new(1, 0, 0, 42)
    topbar.BorderSizePixel = 0
    Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 12)
    local accent = Instance.new("Frame")
    accent.Name = "AccentLine"
    accent.Parent = main
    accent.BackgroundColor3 = Framework.UI.Accent
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.Position = UDim2.new(0, 0, 0, 42)
    accent.BorderSizePixel = 0
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = topbar
    titleLbl.Text = title:upper()
    titleLbl.Size = UDim2.new(1, -120, 1, 0)
    titleLbl.Position = UDim2.new(0, 15, 0, 0)
    titleLbl.TextColor3 = Framework.UI.Accent
    titleLbl.Font = Framework.UI.Font
    titleLbl.TextSize = 18
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = topbar
    closeBtn.Text = "CLOSE"
    closeBtn.Size = UDim2.new(0, 90, 0, 28)
    closeBtn.Position = UDim2.new(1, -100, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,45)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Framework.UI.Font
    closeBtn.TextSize = 12
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        Framework.UI.Toggled = false
    end)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = main
    sidebar.BackgroundColor3 = Color3.fromRGB(10,10,12)
    sidebar.Size = UDim2.new(0, 190, 1, -45)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BorderSizePixel = 0
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
    local tabBtnsFrame = Instance.new("Frame")
    tabBtnsFrame.Parent = sidebar
    tabBtnsFrame.BackgroundTransparency = 1
    tabBtnsFrame.Size = UDim2.new(1, -20, 1, -20)
    tabBtnsFrame.Position = UDim2.new(0, 10, 0, 10)
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Parent = main
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -200, 1, -55)
    content.Position = UDim2.new(0, 200, 0, 55)
    local tabs = {"Home", "Physics", "Visuals", "World", "Config"}
    local tabFrames = {}
    local activeTab = nil
    local function switchTab(name)
        for n, f in pairs(tabFrames) do
            f.Visible = (n == name)
        end
        for _, btn in pairs(tabBtnsFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                local isActive = btn.Name == name .. "Btn"
                btn.BackgroundColor3 = isActive and Color3.fromRGB(35,35,40) or Color3.fromRGB(20,20,24)
                if btn:FindFirstChild("AccentBar") then btn.AccentBar.Visible = isActive end
            end
        end
    end
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tabName .. "Btn"
        btn.Parent = tabBtnsFrame
        btn.Text = tabName
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 48)
        btn.BackgroundColor3 = Color3.fromRGB(20,20,24)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Framework.UI.Font
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Parent = btn
        accentBar.BackgroundColor3 = Framework.UI.Accent
        accentBar.Size = UDim2.new(0, 5, 1, 0)
        accentBar.Visible = false
        accentBar.BorderSizePixel = 0
        btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Name = tabName
        tabFrame.Parent = content
        tabFrame.BackgroundTransparency = 1
        tabFrame.Size = UDim2.new(1, -10, 1, 0)
        tabFrame.Position = UDim2.new(0, 5, 0, 0)
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 2000)
        tabFrame.ScrollBarThickness = 6
        tabFrame.Visible = false
        tabFrames[tabName] = tabFrame
        if tabName == "Home" then
            local dashTitle = Instance.new("TextLabel")
            dashTitle.Parent = tabFrame
            dashTitle.Text = "SOBERLUA DASHBOARD"
            dashTitle.Size = UDim2.new(1, -20, 0, 40)
            dashTitle.Position = UDim2.new(0, 10, 0, 10)
            dashTitle.TextColor3 = Framework.UI.Accent
            dashTitle.Font = Framework.UI.Font
            dashTitle.TextSize = 20
            dashTitle.BackgroundTransparency = 1
            local statusBox = Instance.new("Frame")
            statusBox.Parent = tabFrame
            statusBox.BackgroundColor3 = Color3.fromRGB(25,25,30)
            statusBox.Size = UDim2.new(1, -20, 0, 80)
            statusBox.Position = UDim2.new(0, 10, 0, 60)
            Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)
            local statusText = Instance.new("TextLabel")
            statusText.Parent = statusBox
            statusText.Text = "FRAMEWORK STATUS: OPERATIONAL\nCONFIG: " .. Framework.Manager.FileName .. "\nENTITIES TRACKED: " .. #Players:GetPlayers() .. " players + dummies"
            statusText.Size = UDim2.new(1, -20, 1, -10)
            statusText.Position = UDim2.new(0, 10, 0, 5)
            statusText.TextColor3 = Color3.new(0.9,0.9,0.9)
            statusText.Font = Framework.UI.Font
            statusText.TextSize = 13
            statusText.BackgroundTransparency = 1
            statusText.TextXAlignment = Enum.TextXAlignment.Left
            local logTitle = Instance.new("TextLabel")
            logTitle.Parent = tabFrame
            logTitle.Text = "SYSTEM LOG"
            logTitle.Size = UDim2.new(1, -20, 0, 30)
            logTitle.Position = UDim2.new(0, 10, 0, 155)
            logTitle.TextColor3 = Color3.new(1,1,1)
            logTitle.Font = Framework.UI.Font
            logTitle.TextSize = 14
            logTitle.BackgroundTransparency = 1
            local logScroll = Instance.new("ScrollingFrame")
            logScroll.Parent = tabFrame
            logScroll.BackgroundColor3 = Color3.fromRGB(20,20,24)
            logScroll.Size = UDim2.new(1, -20, 0, 280)
            logScroll.Position = UDim2.new(0, 10, 0, 190)
            logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            logScroll.ScrollBarThickness = 4
            Instance.new("UICorner", logScroll).CornerRadius = UDim.new(0, 6)
            Framework.UI.LogFrame = logScroll
            Framework.UI.AddLog = function(msg)
                local lbl = Instance.new("TextLabel")
                lbl.Parent = logScroll
                lbl.Text = "[" .. os.date("%H:%M:%S") .. "] " .. msg
                lbl.Size = UDim2.new(1, -8, 0, 18)
                lbl.Position = UDim2.new(0, 4, 0, #logScroll:GetChildren() * 20)
                lbl.TextColor3 = Color3.fromRGB(180,180,180)
                lbl.Font = Framework.UI.Font
                lbl.TextSize = 11
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                logScroll.CanvasSize = UDim2.new(0, 0, 0, #logScroll:GetChildren() * 20 + 10)
                if logScroll.CanvasSize.Y.Offset > logScroll.AbsoluteSize.Y then
                    logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
                end
            end
            Framework.UI.AddLog("Framework initialized | Version 1.0 | " .. #Players:GetPlayers() .. " players + mannequins tracked")
            Framework.UI.AddLog("Config loaded successfully from external JSON source")
            Framework.UI.AddLog("ESP Diagnostic module active | Drawing API ready")
            Framework.UI.AddLog("Physics & World modules bound to Heartbeat")
        elseif tabName == "Physics" then
            local physTitle = Instance.new("TextLabel")
            physTitle.Parent = tabFrame
            physTitle.Text = "PHYSICS & MOVEMENT DIAGNOSTICS"
            physTitle.Size = UDim2.new(1, -20, 0, 35)
            physTitle.Position = UDim2.new(0, 10, 0, 10)
            physTitle.TextColor3 = Framework.UI.Accent
            physTitle.Font = Framework.UI.Font
            physTitle.TextSize = 16
            physTitle.BackgroundTransparency = 1
            UILibrary:CreateToggle(tabFrame, "WalkSpeed Override", "Misc/Character/WalkSpeed", 55)
            UILibrary:CreateSlider(tabFrame, "WalkSpeed Value", "Misc/Character/WalkSpeed/Value", 16, 100, 95, 1)
            UILibrary:CreateToggle(tabFrame, "JumpPower Override", "Misc/Character/JumpPower", 155)
            UILibrary:CreateSlider(tabFrame, "JumpPower Value", "Misc/Character/JumpPower/Value", 50, 250, 195, 1)
            UILibrary:CreateToggle(tabFrame, "Third Person Camera", "Visuals/ThirdPerson", 255)
            UILibrary:CreateSlider(tabFrame, "Third Person Distance", "Visuals/ThirdPerson/Z", 3, 20, 295, 0.5)
            UILibrary:CreateToggle(tabFrame, "Hide Character In Third Person", "Visuals/ThirdPerson/HideCharacter", 355)
            local note = Instance.new("TextLabel")
            note.Parent = tabFrame
            note.Text = "These controls are for administrative physics testing and character replication diagnostics only."
            note.Size = UDim2.new(1, -20, 0, 40)
            note.Position = UDim2.new(0, 10, 0, 410)
            note.TextColor3 = Color3.fromRGB(120,120,120)
            note.Font = Framework.UI.Font
            note.TextSize = 11
            note.BackgroundTransparency = 1
            note.TextWrapped = true
        elseif tabName == "Visuals" then
            local visTitle = Instance.new("TextLabel")
            visTitle.Parent = tabFrame
            visTitle.Text = "DIAGNOSTIC OVERLAY & ESP"
            visTitle.Size = UDim2.new(1, -20, 0, 35)
            visTitle.Position = UDim2.new(0, 10, 0, 10)
            visTitle.TextColor3 = Framework.UI.Accent
            visTitle.Font = Framework.UI.Font
            visTitle.TextSize = 16
            visTitle.BackgroundTransparency = 1
            UILibrary:CreateToggle(tabFrame, "Master ESP Enabled", "Esp/Enemy/Enabled", 50)
            UILibrary:CreateToggle(tabFrame, "Box ESP", "Esp/Enemy/Box", 90)
            UILibrary:CreateToggle(tabFrame, "Name Tags", "Esp/Enemy/Name", 130)
            UILibrary:CreateToggle(tabFrame, "Health Bars", "Esp/Enemy/HealthBar", 170)
            UILibrary:CreateToggle(tabFrame, "Distance Display", "Esp/Enemy/Distance", 210)
            UILibrary:CreateToggle(tabFrame, "Weapon Text", "Esp/Enemy/WeaponText", 250)
            UILibrary:CreateToggle(tabFrame, "Katana Status", "Esp/Enemy/KatanaStatus", 290)
            UILibrary:CreateToggle(tabFrame, "Ammo Display", "Esp/Enemy/Ammo", 330)
            UILibrary:CreateToggle(tabFrame, "Extra Size Scaling", "Esp/Extra/Size", 370)
            UILibrary:CreateSlider(tabFrame, "Extra Box Width", "Esp/Extra/Size/Width", 5, 30, 410, 1)
            UILibrary:CreateSlider(tabFrame, "Extra Box Height", "Esp/Extra/Size/Height", 5, 30, 460, 1)
            UILibrary:CreateSlider(tabFrame, "HP Bar Thickness", "Esp/Extra/HPBarThickness", 1, 6, 510, 1)
            UILibrary:CreateToggle(tabFrame, "Draw Distance Limit", "Esp/Extra/DrawDistance", 560)
            UILibrary:CreateSlider(tabFrame, "Draw Distance Max", "Esp/Extra/DrawDistance/Limit", 100, 3000, 610, 50)
        elseif tabName == "World" then
            local worldTitle = Instance.new("TextLabel")
            worldTitle.Parent = tabFrame
            worldTitle.Text = "ENVIRONMENT & WORLD CONTROL"
            worldTitle.Size = UDim2.new(1, -20, 0, 35)
            worldTitle.Position = UDim2.new(0, 10, 0, 10)
            worldTitle.TextColor3 = Framework.UI.Accent
            worldTitle.Font = Framework.UI.Font
            worldTitle.TextSize = 16
            worldTitle.BackgroundTransparency = 1
            UILibrary:CreateToggle(tabFrame, "Fog Enabled", "Visuals/World/Fog/Enabled", 50)
            UILibrary:CreateSlider(tabFrame, "Fog Density", "Visuals/World/Fog/Density", 0, 10, 90, 0.1)
            UILibrary:CreateSlider(tabFrame, "Fog Distance", "Visuals/World/Fog/Distance", 0, 5000, 140, 10)
            UILibrary:CreateToggle(tabFrame, "Color Correction", "Visuals/Effects/ColorCorrection", 190)
            UILibrary:CreateSlider(tabFrame, "CC Brightness", "Visuals/Effects/ColorCorrection/Brightness", 0, 100, 230, 1)
            UILibrary:CreateSlider(tabFrame, "CC Contrast", "Visuals/Effects/ColorCorrection/Contrast", 0, 100, 280, 1)
            UILibrary:CreateSlider(tabFrame, "CC Saturation", "Visuals/Effects/ColorCorrection/Saturation", 0, 100, 330, 1)
            UILibrary:CreateToggle(tabFrame, "Bloom Effect", "Visuals/Effects/Bloom", 380)
            UILibrary:CreateSlider(tabFrame, "Bloom Intensity", "Visuals/Effects/Bloom/Intensity", 0, 100, 420, 1)
            UILibrary:CreateSlider(tabFrame, "Bloom Size", "Visuals/Effects/Bloom/Size", 0, 50, 470, 1)
            UILibrary:CreateToggle(tabFrame, "Sun Rays", "Visuals/Effects/SunRays", 520)
            UILibrary:CreateSlider(tabFrame, "Sun Rays Intensity", "Visuals/Effects/SunRays/Intensity", 0, 50, 560, 1)
            UILibrary:CreateToggle(tabFrame, "Depth Of Field", "Visuals/Effects/DepthOfField", 610)
            UILibrary:CreateToggle(tabFrame, "Camera Motion Blur", "Visuals/Effects/CameraMotionBlur", 650)
            UILibrary:CreateSlider(tabFrame, "Motion Blur Intensity", "Visuals/Effects/CameraMotionBlur/Intensity", 0, 100, 690, 1)
        elseif tabName == "Config" then
            local cfgTitle = Instance.new("TextLabel")
            cfgTitle.Parent = tabFrame
            cfgTitle.Text = "CONFIGURATION & PERSISTENCE"
            cfgTitle.Size = UDim2.new(1, -20, 0, 35)
            cfgTitle.Position = UDim2.new(0, 10, 0, 10)
            cfgTitle.TextColor3 = Framework.UI.Accent
            cfgTitle.Font = Framework.UI.Font
            cfgTitle.TextSize = 16
            cfgTitle.BackgroundTransparency = 1
            local reloadBtn = Instance.new("TextButton")
            reloadBtn.Parent = tabFrame
            reloadBtn.Text = "RELOAD FROM FILE"
            reloadBtn.Size = UDim2.new(0, 220, 0, 38)
            reloadBtn.Position = UDim2.new(0, 20, 0, 55)
            reloadBtn.BackgroundColor3 = Framework.UI.Accent
            reloadBtn.TextColor3 = Color3.new(1,1,1)
            reloadBtn.Font = Framework.UI.Font
            reloadBtn.TextSize = 13
            Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 6)
            reloadBtn.MouseButton1Click:Connect(function()
                Framework.Manager:Load()
                if Framework.UI.AddLog then Framework.UI.AddLog("Configuration reloaded from disk") end
            end)
            local saveBtn = Instance.new("TextButton")
            saveBtn.Parent = tabFrame
            saveBtn.Text = "SAVE TO FILE"
            saveBtn.Size = UDim2.new(0, 220, 0, 38)
            saveBtn.Position = UDim2.new(0, 260, 0, 55)
            saveBtn.BackgroundColor3 = Framework.UI.Accent
            saveBtn.TextColor3 = Color3.new(1,1,1)
            saveBtn.Font = Framework.UI.Font
            saveBtn.TextSize = 13
            Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
            saveBtn.MouseButton1Click:Connect(function()
                if Framework.Manager:Save() then
                    if Framework.UI.AddLog then Framework.UI.AddLog("Configuration saved to disk successfully") end
                end
            end)
            local dumpTitle = Instance.new("TextLabel")
            dumpTitle.Parent = tabFrame
            dumpTitle.Text = "LIVE CONFIG DUMP (JSON)"
            dumpTitle.Size = UDim2.new(1, -20, 0, 25)
            dumpTitle.Position = UDim2.new(0, 10, 0, 105)
            dumpTitle.TextColor3 = Color3.new(1,1,1)
            dumpTitle.Font = Framework.UI.Font
            dumpTitle.TextSize = 12
            dumpTitle.BackgroundTransparency = 1
            local jsonBox = Instance.new("TextBox")
            jsonBox.Parent = tabFrame
            jsonBox.Size = UDim2.new(1, -20, 0, 450)
            jsonBox.Position = UDim2.new(0, 10, 0, 135)
            jsonBox.BackgroundColor3 = Color3.fromRGB(18,18,22)
            jsonBox.TextColor3 = Color3.fromRGB(200,200,200)
            jsonBox.Font = Framework.UI.Font
            jsonBox.TextSize = 11
            jsonBox.Text = HttpService:JSONEncode(Framework.Config)
            jsonBox.ClearTextOnFocus = false
            jsonBox.TextWrapped = true
            jsonBox.MultiLine = true
            jsonBox.TextXAlignment = Enum.TextXAlignment.Left
            jsonBox.TextYAlignment = Enum.TextYAlignment.Top
        end
    end
    switchTab("Home")
    return main
end

Framework.Manager = ConfigManager.new()
Framework.Manager:Load()
Framework.UI.Accent = rgbToColor3(Framework.Manager:Get("settings/menu/accent")) or Framework.UI.Accent

local MainFrame = UILibrary:CreateWindow("SoberLua")

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then VisualsEngine:CreateESP(p) end
end

-- Support for mannequins / test dummies (Models with Humanoid not linked to a real Player)
-- Useful when testing with a mannequin as opponent in Roblox Studio
local function scanAndTrackDummies()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            VisualsEngine:CreateESP(obj)
        end
    end
end
scanAndTrackDummies()

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(child) then
        VisualsEngine:CreateESP(child)
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Framework.Config["Misc/Character/WalkSpeed"] then
            hum.WalkSpeed = Framework.Config["Misc/Character/WalkSpeed/Value"] or 30
        end
        if Framework.Config["Misc/Character/JumpPower"] then
            hum.JumpPower = Framework.Config["Misc/Character/JumpPower/Value"] or 100
        end
    end
    if Framework.Config["Visuals/ThirdPerson"] then
        local dist = Framework.Config["Visuals/ThirdPerson/Z"] or 7.5
        LocalPlayer.CameraMaxZoomDistance = dist
        LocalPlayer.CameraMinZoomDistance = dist
    end
    Lighting.Brightness = Framework.Config["Visuals/World/Brightness"] or 14
    Lighting.ExposureCompensation = (Framework.Config["Visuals/World/Exposure"] or 35) / 25
    if Framework.Config["Visuals/World/Fog/Enabled"] then
        Lighting.FogEnd = Framework.Config["Visuals/World/Fog/Distance"] or 1000
        Lighting.FogStart = 0
        Lighting.FogColor = rgbToColor3(Framework.Config["Visuals/World/Fog/Color"])
    else
        Lighting.FogEnd = 100000
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local kb = Framework.Config["settings/menu/keybind"]
    if kb and kb.key and kb.key[2] and input.KeyCode.Name == kb.key[2] then
        MainFrame.Visible = not MainFrame.Visible
        Framework.UI.Toggled = MainFrame.Visible
    end
end)

if Framework.UI.AddLog then
    Framework.UI.AddLog("All modules initialized | Ready for diagnostics")
end

print("SoberLua Framework v1.0 loaded successfully with external JSON config support.")