--[[
  SoberHook v4.0 - Roblox Universal Script Hub
  Features: Aimbot, Triggerbot, ESP, WeaponMods, Movement Suite,
  Wallhack, AntiAim, Automation, ChatSpammer, CustomCrosshair,
  FOVChanger, ThirdPerson, AntiCheat Bypass
  Total: ~3500 lines | Works on Synapse X, Krnl, Fluxus, JJSploit
]]

-- =====================================================
-- [SECTION 0] CONFIGURATION TABLE
-- =====================================================
local Cfg = {
  Aimbot   = { E = false, Method = "SilentAim", FOV = 120, Smooth = 0.5, Pred = 0.35, Parts = {"Head","Torso"}, Key = "MouseButton2", VisCheck = false, TeamCheck = false },
  Trigger  = { E = false, Delay = 0.05, Range = 250, Key = "MouseButton1", Whitelist = {"Head","Torso"} },
  ESP      = { E = false, Boxes = true, BoxOutline = true, HealthBars = true, HealthText = true, Names = true, Distance = true, Weapon = true, Tracers = false, TracerFrom = "Bottom", MaxDist = 5000, RefreshRate = 0.1, TeamCheck = false, UseTeamColor = false },
  Weapon   = { E = false, NoRecoil = true, NoSpread = true, InfAmmo = true, InstReload = true, InfDmg = false, DmgMult = 1 },
  Speed    = { E = false, Speed = 32, ToggleMode = "Hold" },
  Fly      = { E = false, Speed = 50, Key = "F", ToggleKey = "F" },
  InfJump  = { E = false },
  BunnyHop = { E = false, JumpDelay = 0.0 },
  Noclip   = { E = false, OnEvenIfDead = false },
  Wallhack = { E = false, Transparency = 0.7, IgnoreTeam = true },
  AntiAim  = { E = false, Mode = "Spin", Pitch = 0, YawSpeed = 360 },
  AutoFarm = { E = false, Method = "Collect", Radius = 50, CollectItems = true, CollectCurrency = true },
  AutoHeal = { E = false, Threshold = 30, Item = "MedKit", CheckBackpack = true },
  AutoBlock= { E = false, Mode = "Always", BlockOnDamage = true },
  Spammer  = { E = false, Messages = {"SoberHook v4.0!","gg wp","ez","trash team","1v1 me"}, Interval = 5, RandomOrder = false },
  Crosshair= { E = false, Style = "Dot", Color = Color3.fromRGB(255,0,0), Size = 10, Thickness = 2, Outline = true, OutlineColor = Color3.fromRGB(0,0,0) },
  FOV      = { E = false, FOV = 90, Transition = false, TransitionSpeed = 1 },
  ThirdP   = { E = false, Distance = 10, SmoothTransition = true },
  Loadout  = { E = false, Guns = {"AK47","M4A1","Sniper","Shotgun","RPG"}, AutoSwitch = true, SwitchDelay = 0.5 },
  AC       = { E = true, BlockKick = true, BlockTeleport = true, BlockRemove = true, BlockDestroy = true, MuteWarn = true }
}

-- =====================================================
-- [SECTION 1] UTILITY FUNCTIONS
-- =====================================================
local U = {}
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local UIS = game:GetService("UserInputService")
local RunSvc = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local RenderStepped = RunSvc.RenderStepped
local Heartbeat = RunSvc.Heartbeat
local Stepped = RunSvc.Stepped
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VirtualInput = game:GetService("VirtualInputManager")
local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local Workspace = workspace
local GameId = game.GameId
local PlaceId = game.PlaceId
local JobId = game.JobId

-- ---- Health Check ----
local function IsAlive(p)
  if not p then return false end
  local c = p.Character
  if not c then return false end
  local h = c:FindFirstChildOfClass("Humanoid")
  if not h then return false end
  if h.Health <= 0 then return false end
  if h:GetState() == Enum.HumanoidStateType.Dead then return false end
  return true
end
U.IsAlive = IsAlive

-- ---- Get Valid Players ----
function U.GetPlayers(includeDead)
  local list = {}
  for _, p in ipairs(Players:GetPlayers()) do
    if p == LP then goto continue end
    if not IsAlive(p) and not includeDead then goto continue end
    local c = p.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
      table.insert(list, p)
    end
    ::continue::
  end
  return list
end

-- ---- Get HumanoidRootPart ----
function U.GetHRP(p)
  if not p then return nil end
  local c = p.Character
  if not c then return nil end
  return c:FindFirstChild("HumanoidRootPart")
end

-- ---- Get Humanoid ----
function U.GetHum(p)
  if not p then return nil end
  local c = p.Character
  if not c then return nil end
  return c:FindFirstChildOfClass("Humanoid")
end

-- ---- Distance ----
function U.Dist(a, b)
  if not a or not b then return 9e9 end
  return (a - b).Magnitude
end

-- ---- World to Screen ----
function U.W2S(pos)
  local pt, vis = Camera:WorldToScreenPoint(pos)
  return Vector2.new(pt.X, pt.Y), vis and pt.Z > 0
end

-- ---- Closest Player to Mouse (for aimbot) ----
function U.ClosestPlayerToMouse()
  local best, bestDist = nil, Cfg.Aimbot.FOV
  local mPos = Vector2.new(Mouse.X, Mouse.Y)
  for _, p in ipairs(U.GetPlayers()) do
    if Cfg.Aimbot.TeamCheck and p.Team == LP.Team then goto continue end
    local hrp = U.GetHRP(p)
    if hrp then
      -- Try each target part
      local targetPos = hrp.Position
      for _, partName in ipairs(Cfg.Aimbot.Parts) do
        local c = p.Character
        if c then
          local part = c:FindFirstChild(partName)
          if part and part:IsA("BasePart") then
            targetPos = part.Position
            break
          end
        end
      end
      local sp, onScreen = U.W2S(targetPos)
      if onScreen then
        local dist = (mPos - sp).Magnitude
        local degDist = math.deg(math.atan(dist / Camera.ViewportSize.Y * 2))
        if degDist < bestDist then
          best = p
          bestDist = degDist
        end
      end
    end
    ::continue::
  end
  return best, bestDist
end

-- ---- Prediction ----
function U.Predict(p, factor)
  local hrp = U.GetHRP(p)
  if not hrp then return nil end
  local vel = hrp.Velocity or Vector3.new()
  return hrp.Position + vel * (factor or 0)
end

-- ---- Get Character ----
function U.GetChar()
  return LP.Character
end

-- ---- Get Tool ----
function U.GetTool()
  local c = U.GetChar()
  if not c then return nil end
  return c:FindFirstChildOfClass("Tool")
end

-- ---- Get Nearest Part ----
function U.GetNearestPart(pos, radius, filterClass)
  local nearest, nearestDist = nil, radius or 50
  for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("BasePart") and (not filterClass or v:IsA(filterClass)) then
      local d = U.Dist(pos, v.Position)
      if d < nearestDist then
        nearest = v
        nearestDist = d
      end
    end
  end
  return nearest, nearestDist
end

-- ---- Get Nearest Player ----
function U.GetNearestPlayer(pos, maxDist)
  local nearest, nearestDist = nil, maxDist or 9e9
  for _, p in ipairs(U.GetPlayers()) do
    local hrp = U.GetHRP(p)
    if hrp then
      local d = U.Dist(pos, hrp.Position)
      if d < nearestDist then
        nearest = p
        nearestDist = d
      end
    end
  end
  return nearest, nearestDist
end

-- ---- Raycast ----
function U.Raycast(startPos, direction, maxDist, ignoreList)
  local ray = Ray.new(startPos, direction.Unit * (maxDist or 9999))
  local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList or {LP.Character})
  return hit, pos
end

-- ---- Table Clone ----
function U.CloneTable(t)
  local out = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      out[k] = U.CloneTable(v)
    else
      out[k] = v
    end
  end
  return out
end

-- ---- String Split ----
function U.Split(str, sep)
  if not sep then sep = "%s" end
  local t = {}
  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(t, s)
  end
  return t
end

-- ---- Random String ----
function U.RandomStr(len)
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local out = ""
  for i = 1, len or 8 do
    out = out .. chars:sub(math.random(1, #chars), math.random(1, #chars))
  end
  return out
end

-- ---- Network Ping ----
function U.GetPing()
  local s = Stats
  if s then
    local net = s:FindFirstChild("Network")
    if net then
      return net:GetValue() or 0
    end
  end
  return 0
end

-- ---- Safe Pcall ----
function U.Safe(fn, ...)
  local args = {...}
  local succ, err = pcall(function()
    fn(unpack(args))
  end)
  if not succ then
    warn("[SH][WARN] Pcall error: " .. tostring(err))
  end
  return succ, err
end

-- ---- Get Team Name ----
function U.GetTeamName(p)
  if not p then return "" end
  local team = p.Team
  if team then
    return team.Name
  end
  return "NoTeam"
end-- =====================================================
-- [SECTION 2] DRAWING-BASED GUI SYSTEM
-- =====================================================
-- Complete menu with tabs, toggles, sliders, dropdowns
-- Uses Roblox Drawing API (compatible with all executors)

do
  local GUI = {}
  GUI.Elements = {}
  GUI.Open = true
  GUI.Drag = { Dragging = false, Offset = Vector2.new(0,0) }
  GUI.Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    Primary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(0, 120, 255),
    AccentDark = Color3.fromRGB(0, 80, 200),
    Text = Color3.fromRGB(220, 220, 220),
    TextDim = Color3.fromRGB(140, 140, 140),
    ToggleOn = Color3.fromRGB(60, 180, 60),
    ToggleOff = Color3.fromRGB(80, 80, 80),
    Border = Color3.fromRGB(50, 50, 50),
    Highlight = Color3.fromRGB(50, 50, 80),
    Red = Color3.fromRGB(220, 50, 50),
    Green = Color3.fromRGB(50, 220, 50),
    Yellow = Color3.fromRGB(220, 220, 50)
  }
  GUI.WindowSize = Vector2.new(600, 420)
  GUI.WindowPos = Vector2.new(100, 60)
  GUI.TabHeight = 28
  GUI.ElementSpacing = 4
  GUI.CurrentTab = ""
  GUI.Tabs = {}
  GUI.Sections = {}
  GUI.ToggleKey = Enum.KeyCode.RightShift

  ---- Create Base Drawing Objects ----
  function GUI:Init()
    -- Main window frame
    self.Main = {}
    self.Main.BG = Drawing.new("Square")
    self.Main.BG.Size = self.WindowSize
    self.Main.BG.Position = self.WindowPos
    self.Main.BG.Color = self.Colors.Background
    self.Main.BG.Thickness = 1
    self.Main.BG.Filled = true
    self.Main.BG.Visible = true

    -- Border
    self.Main.Border = Drawing.new("Square")
    self.Main.Border.Size = self.WindowSize + Vector2.new(2,2)
    self.Main.Border.Position = self.WindowPos - Vector2.new(1,1)
    self.Main.Border.Color = self.Colors.Accent
    self.Main.Border.Thickness = 1
    self.Main.Border.Filled = false
    self.Main.Border.Visible = true

    -- Title bar
    self.Main.TitleBG = Drawing.new("Square")
    self.Main.TitleBG.Size = Vector2.new(self.WindowSize.X, self.TabHeight)
    self.Main.TitleBG.Position = self.WindowPos
    self.Main.TitleBG.Color = self.Colors.Primary
    self.Main.TitleBG.Filled = true
    self.Main.TitleBG.Visible = true

    -- Title text
    self.Main.Title = Drawing.new("Text")
    self.Main.Title.Text = "SoberHook v4.0"
    self.Main.Title.Position = self.WindowPos + Vector2.new(8, 4)
    self.Main.Title.Color = self.Colors.Accent
    self.Main.Title.Size = 16
    self.Main.Title.Center = false
    self.Main.Title.Outline = true
    self.Main.Title.Visible = true

    -- Close button (X)
    self.Main.CloseBG = Drawing.new("Square")
    self.Main.CloseBG.Size = Vector2.new(20, 20)
    self.Main.CloseBG.Position = self.WindowPos + Vector2.new(self.WindowSize.X - 24, 4)
    self.Main.CloseBG.Color = self.Colors.Red
    self.Main.CloseBG.Filled = true
    self.Main.CloseBG.Visible = true

    self.Main.CloseText = Drawing.new("Text")
    self.Main.CloseText.Text = "X"
    self.Main.CloseText.Position = self.WindowPos + Vector2.new(self.WindowSize.X - 19, 4)
    self.Main.CloseText.Color = Color3.fromRGB(255,255,255)
    self.Main.CloseText.Size = 14
    self.Main.CloseText.Visible = true

    -- Tab bar background
    self.Main.TabBar = Drawing.new("Square")
    self.Main.TabBar.Size = Vector2.new(self.WindowSize.X, self.TabHeight + 4)
    self.Main.TabBar.Position = self.WindowPos + Vector2.new(0, self.TabHeight)
    self.Main.TabBar.Color = self.Colors.Primary
    self.Main.TabBar.Filled = true
    self.Main.TabBar.Visible = true

    -- Content area background
    self.Main.ContentBG = Drawing.new("Square")
    self.Main.ContentBG.Size = Vector2.new(self.WindowSize.X - 8, self.WindowSize.Y - self.TabHeight * 2 - 20)
    self.Main.ContentBG.Position = self.WindowPos + Vector2.new(4, self.TabHeight * 2 + 8)
    self.Main.ContentBG.Color = self.Colors.Background
    self.Main.ContentBG.Filled = true
    self.Main.ContentBG.Visible = true

    -- Status bar
    self.Main.StatusBG = Drawing.new("Square")
    self.Main.StatusBG.Size = Vector2.new(self.WindowSize.X, 18)
    self.Main.StatusBG.Position = self.WindowPos + Vector2.new(0, self.WindowSize.Y - 18)
    self.Main.StatusBG.Color = self.Colors.Primary
    self.Main.StatusBG.Filled = true
    self.Main.StatusBG.Visible = true

    self.Main.StatusText = Drawing.new("Text")
    self.Main.StatusText.Text = "Status: Ready | ESC to toggle"
    self.Main.StatusText.Position = self.WindowPos + Vector2.new(6, self.WindowSize.Y - 16)
    self.Main.StatusText.Color = self.Colors.TextDim
    self.Main.StatusText.Size = 12
    self.Main.StatusText.Visible = true
  end

  ---- Add Tab ----
  function GUI:AddTab(name)
    if not name then return end
    local tab = {
      Name = name,
      Buttons = {}
    }
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
      self.CurrentTab = name
    end
    return tab
  end

  ---- Draw Tab Buttons ----
  function GUI:DrawTabs()
    -- First, clear old tab button objects
    for _, tab in ipairs(self.Tabs) do
      if tab.BG then tab.BG:Remove() end
      if tab.Text then tab.Text:Remove() end
    end

    local xOffset = self.WindowPos.X + 4
    local yPos = self.WindowPos.Y + self.TabHeight + 4
    local tabWidth = math.min(120, (self.WindowSize.X - 8) / #self.Tabs)

    for i, tab in ipairs(self.Tabs) do
      local isActive = tab.Name == self.CurrentTab

      tab.BG = Drawing.new("Square")
      tab.BG.Size = Vector2.new(tabWidth - 2, self.TabHeight)
      tab.BG.Position = Vector2.new(xOffset, yPos)
      tab.BG.Color = isActive and self.Colors.Accent or self.Colors.Primary
      tab.BG.Filled = true
      tab.BG.Visible = self.Open

      tab.Text = Drawing.new("Text")
      tab.Text.Text = tab.Name
      tab.Text.Position = Vector2.new(xOffset + 4, yPos + 4)
      tab.Text.Color = isActive and Color3.fromRGB(255,255,255) or self.Colors.Text
      tab.Text.Size = 13
      tab.Text.Visible = self.Open

      tab.Hitbox = {
        Min = Vector2.new(xOffset, yPos),
        Max = Vector2.new(xOffset + tabWidth - 2, yPos + self.TabHeight)
      }

      xOffset = xOffset + tabWidth
    end
  end

  ---- Add Section ----
  function GUI:AddSection(tabName, sectionName)
    if not self.Sections[tabName] then
      self.Sections[tabName] = {}
    end
    local section = {
      Name = sectionName,
      Elements = {},
      Y = 0
    }
    table.insert(self.Sections[tabName], section)
    return section
  end

  ---- Add Toggle ----
  function GUI:AddToggle(tabName, sectionName, label, varPath, defaultValue)
    local elem = {
      Type = "Toggle",
      Label = label,
      VarPath = varPath,
      Value = defaultValue or false,
      BG = nil,
      Text = nil,
      Indicator = nil,
      Y = 0,
      Height = 24,
      Hitbox = nil
    }
    
    -- Find section
    for _, sec in ipairs(self.Sections[tabName] or {}) do
      if sec.Name == sectionName then
        table.insert(sec.Elements, elem)
        break
      end
    end
    
    table.insert(self.Elements, elem)
    return elem
  end

  ---- Add Slider ----
  function GUI:AddSlider(tabName, sectionName, label, varPath, min, max, default, format)
    local elem = {
      Type = "Slider",
      Label = label,
      VarPath = varPath,
      Min = min or 0,
      Max = max or 100,
      Value = default or min or 0,
      Format = format or "%.1f",
      BG = nil,
      Fill = nil,
      Text = nil,
      ValueText = nil,
      Y = 0,
      Height = 28,
      Dragging = false,
      Hitbox = nil
    }
    
    for _, sec in ipairs(self.Sections[tabName] or {}) do
      if sec.Name == sectionName then
        table.insert(sec.Elements, elem)
        break
      end
    end
    
    table.insert(self.Elements, elem)
    return elem
  end

  ---- Add Dropdown ----
  function GUI:AddDropdown(tabName, sectionName, label, varPath, options, default)
    local elem = {
      Type = "Dropdown",
      Label = label,
      VarPath = varPath,
      Options = options or {},
      Value = default or (options and options[1]) or "",
      Expanded = false,
      BG = nil,
      Text = nil,
      ValueText = nil,
      OptionsBG = {},
      OptionsText = {},
      Y = 0,
      Height = 24,
      ExpandedHeight = 0,
      Hitbox = nil
    }
    
    for _, sec in ipairs(self.Sections[tabName] or {}) do
      if sec.Name == sectionName then
        table.insert(sec.Elements, elem)
        break
      end
    end
    
    table.insert(self.Elements, elem)
    return elem
  end

  ---- Add Button ----
  function GUI:AddButton(tabName, sectionName, label, callback)
    local elem = {
      Type = "Button",
      Label = label,
      Callback = callback or function() end,
      BG = nil,
      Text = nil,
      Y = 0,
      Height = 24,
      Hitbox = nil
    }
    
    for _, sec in ipairs(self.Sections[tabName] or {}) do
      if sec.Name == sectionName then
        table.insert(sec.Elements, elem)
        break
      end
    end
    
    table.insert(self.Elements, elem)
    return elem
  end

  ---- Add Label ----
  function GUI:AddLabel(tabName, sectionName, text, color)
    local elem = {
      Type = "Label",
      Label = text,
      Color = color or self.Colors.TextDim,
      Text = nil,
      Y = 0,
      Height = 18
    }
    
    for _, sec in ipairs(self.Sections[tabName] or {}) do
      if sec.Name == sectionName then
        table.insert(sec.Elements, elem)
        break
      end
    end
    
    table.insert(self.Elements, elem)
    return elem
  end

  ---- Layout Elements ----
  function GUI:Layout()
    local contentStart = self.WindowPos + Vector2.new(8, self.TabHeight * 2 + 12)
    local contentWidth = self.WindowSize.X - 16
    local y = contentStart.Y

    for _, tab in ipairs(self.Tabs) do
      local sections = self.Sections[tab.Name] or {}
      for _, sec in ipairs(sections) do
        sec.Y = y
        -- Section header
        y = y + 20
        for _, elem in ipairs(sec.Elements) do
          if tab.Name == self.CurrentTab then
            elem.Y = y
            y = y + elem.Height + self.ElementSpacing
            if elem.Type == "Dropdown" and elem.Expanded then
              y = y + #elem.Options * 18 + 4
            end
          end
        end
        y = y + 8
      end
    end
  end

  ---- Draw All Elements ----
  function GUI:DrawElements()
    if not self.Open then return end

    local contentStart = self.WindowPos + Vector2.new(8, self.TabHeight * 2 + 12)
    local contentWidth = self.WindowSize.X - 16

    for _, tab in ipairs(self.Tabs) do
      local sections = self.Sections[tab.Name] or {}
      for _, sec in ipairs(sections) do
        if tab.Name ~= self.CurrentTab then goto continue end
        local y = sec.Y

        -- Section header
        if sec.BG then sec.BG:Remove() end
        sec.BG = Drawing.new("Square")
        sec.BG.Size = Vector2.new(contentWidth, 18)
        sec.BG.Position = Vector2.new(contentStart.X, y)
        sec.BG.Color = self.Colors.AccentDark
        sec.BG.Filled = true

        if sec.Text then sec.Text:Remove() end
        sec.Text = Drawing.new("Text")
        sec.Text.Text = sec.Name
        sec.Text.Position = Vector2.new(contentStart.X + 4, y + 1)
        sec.Text.Color = Color3.fromRGB(255,255,255)
        sec.Text.Size = 13
        sec.Text.Outline = true

        y = y + 22

        for _, elem in ipairs(sec.Elements) do
          if not elem.Y then elem.Y = y end
          elem:Draw(contentStart.X, elem.Y, contentWidth)
          y = elem.Y + elem.Height + self.ElementSpacing
          if elem.Type == "Dropdown" and elem.Expanded then
            y = y + #elem.Options * 18 + 4
          end
        end
        ::continue::
      end
    end
  end

  ---- Element Draw Methods ----
  -- Toggle Draw
  function GUI:DrawToggle(x, y, width, elem)
    if elem.BG then elem.BG:Remove() end
    elem.BG = Drawing.new("Square")
    elem.BG.Size = Vector2.new(width, elem.Height)
    elem.BG.Position = Vector2.new(x, y)
    elem.BG.Color = self.Colors.Background
    elem.BG.Filled = true
    elem.BG.Visible = self.Open

    -- Toggle indicator
    if elem.Indicator then elem.Indicator:Remove() end
    elem.Indicator = Drawing.new("Square")
    elem.Indicator.Size = Vector2.new(16, 16)
    elem.Indicator.Position = Vector2.new(x + width - 22, y + 4)
    elem.Indicator.Color = elem.Value and self.Colors.ToggleOn or self.Colors.ToggleOff
    elem.Indicator.Filled = true
    elem.Indicator.Visible = self.Open

    -- Label
    if elem.Text then elem.Text:Remove() end
    elem.Text = Drawing.new("Text")
    elem.Text.Text = elem.Label
    elem.Text.Position = Vector2.new(x + 4, y + 3)
    elem.Text.Color = self.Colors.Text
    elem.Text.Size = 13
    elem.Text.Visible = self.Open

    elem.Hitbox = {
      Min = Vector2.new(x, y),
      Max = Vector2.new(x + width, y + elem.Height)
    }
  end

  -- Slider Draw
  function GUI:DrawSlider(x, y, width, elem)
    if elem.BG then elem.BG:Remove() end
    elem.BG = Drawing.new("Square")
    elem.BG.Size = Vector2.new(width, elem.Height)
    elem.BG.Position = Vector2.new(x, y)
    elem.BG.Color = self.Colors.Background
    elem.BG.Filled = true
    elem.BG.Visible = self.Open

    -- Slider track
    local trackX = x + 4
    local trackW = width - 100
    local trackY = y + elem.Height / 2 - 3

    if elem.Track then elem.Track:Remove() end
    elem.Track = Drawing.new("Square")
    elem.Track.Size = Vector2.new(trackW, 6)
    elem.Track.Position = Vector2.new(trackX, trackY)
    elem.Track.Color = self.Colors.Primary
    elem.Track.Filled = true
    elem.Track.Visible = self.Open

    -- Slider fill
    local fillRatio = (elem.Value - elem.Min) / (elem.Max - elem.Min)
    local fillWidth = trackW * math.min(math.max(fillRatio, 0), 1)

    if elem.Fill then elem.Fill:Remove() end
    elem.Fill = Drawing.new("Square")
    elem.Fill.Size = Vector2.new(fillWidth, 6)
    elem.Fill.Position = Vector2.new(trackX, trackY)
    elem.Fill.Color = self.Colors.Accent
    elem.Fill.Filled = true
    elem.Fill.Visible = self.Open

    -- Label
    if elem.Text then elem.Text:Remove() end
    elem.Text = Drawing.new("Text")
    elem.Text.Text = elem.Label
    elem.Text.Position = Vector2.new(x + 4, y + elem.Height / 2 - 9)
    elem.Text.Color = self.Colors.Text
    elem.Text.Size = 13
    elem.Text.Visible = self.Open

    -- Value
    if elem.ValueText then elem.ValueText:Remove() end
    elem.ValueText = Drawing.new("Text")
    elem.ValueText.Text = string.format(elem.Format, elem.Value)
    elem.ValueText.Position = Vector2.new(x + trackW + 10, y + elem.Height / 2 - 9)
    elem.ValueText.Color = self.Colors.Accent
    elem.ValueText.Size = 13
    elem.ValueText.Visible = self.Open

    elem.Hitbox = {
      Min = Vector2.new(x, y),
      Max = Vector2.new(x + width, y + elem.Height)
    }
  end

  ---- Toggle UI visibility ----
  function GUI:Toggle()
    self.Open = not self.Open
    -- Hide all elements
    for k, v in pairs(self.Main) do
      if type(v) == "table" and v.Visible ~= nil then
        v.Visible = self.Open
      end
    end
  end

  ---- Check mouse click hitboxes ----
  function GUI:HandleClick(mPos)
    if not self.Open then
      -- Check if click is anywhere to open
      return false
    end

    -- Check close button
    local closeMin = self.WindowPos + Vector2.new(self.WindowSize.X - 24, 4)
    local closeMax = closeMin + Vector2.new(20, 20)
    if mPos.X >= closeMin.X and mPos.X <= closeMax.X and
       mPos.Y >= closeMin.Y and mPos.Y <= closeMax.Y then
      self:Toggle()
      return true
    end

    -- Check tab clicks
    for _, tab in ipairs(self.Tabs) do
      if tab.Hitbox then
        if mPos.X >= tab.Hitbox.Min.X and mPos.X <= tab.Hitbox.Max.X and
           mPos.Y >= tab.Hitbox.Min.Y and mPos.Y <= tab.Hitbox.Max.Y then
          self.CurrentTab = tab.Name
          return true
        end
      end
    end

    -- Check title bar drag
    local titleMin = self.WindowPos
    local titleMax = self.WindowPos + Vector2.new(self.WindowSize.X, self.TabHeight)
    if mPos.X >= titleMin.X and mPos.X <= titleMax.X and
       mPos.Y >= titleMin.Y and mPos.Y <= titleMax.Y then
      self.Drag.Dragging = true
      self.Drag.Offset = mPos - self.WindowPos
      return true
    end

    -- Check element clicks
    for _, tab in ipairs(self.Tabs) do
      local sections = self.Sections[tab.Name] or {}
      for _, sec in ipairs(sections) do
        for _, elem in ipairs(sec.Elements) do
          if tab.Name ~= self.CurrentTab then goto continue end
          if elem.Hitbox then
            local h = elem.Hitbox
            if mPos.X >= h.Min.X and mPos.X <= h.Max.X and
               mPos.Y >= h.Min.Y and mPos.Y <= h.Max.Y then
              
              if elem.Type == "Toggle" then
                elem.Value = not elem.Value
                -- Update config
                self:UpdateConfig(elem.VarPath, elem.Value)
                return true
              
              elseif elem.Type == "Button" then
                task.spawn(elem.Callback)
                return true

              elseif elem.Type == "Dropdown" then
                local relY = mPos.Y - (h.Min.Y + elem.Height)
                if elem.Expanded and relY > 0 then
                  local idx = math.floor(relY / 18) + 1
                  if idx >= 1 and idx <= #elem.Options then
                    elem.Value = elem.Options[idx]
                    self:UpdateConfig(elem.VarPath, elem.Value)
                  end
                end
                elem.Expanded = not elem.Expanded
                return true

              elseif elem.Type == "Slider" then
                elem.Dragging = true
                return true
              end
            end
          end
          ::continue::
        end
      end
    end

    return false
  end

  ---- Update config from GUI ----
  function GUI:UpdateConfig(path, value)
    -- Parse path like "Aimbot.E" or "Speed.Speed"
    if not path then return end
    local parts = U.Split(path, ".")
    if #parts < 2 then return end
    local cat = Cfg[parts[1]]
    if cat then
      cat[parts[2]] = value
    end
  end

  ---- Mouse move handler (for sliders and drag) ----
  function GUI:HandleMove(mPos)
    if self.Drag.Dragging then
      self.WindowPos = mPos - self.Drag.Offset
      return
    end

    -- Handle slider drag
    for _, elem in ipairs(self.Elements) do
      if elem.Type == "Slider" and elem.Dragging then
        if not elem.Hitbox then goto continue end
        local h = elem.Hitbox
        local relX = mPos.X - (h.Min.X + 4)
        local trackW = (h.Max.X - h.Min.X) - 100
        if trackW > 0 then
          local ratio = math.min(math.max(relX / trackW, 0), 1)
          elem.Value = elem.Min + (elem.Max - elem.Min) * ratio
          self:UpdateConfig(elem.VarPath, elem.Value)
        end
        ::continue::
      end
    end
  end

  ---- Mouse release handler ----
  function GUI:HandleRelease()
    self.Drag.Dragging = false
    for _, elem in ipairs(self.Elements) do
      if elem.Type == "Slider" then
        elem.Dragging = false
      end
    end
  end

  ---- Render Loop ----
  function GUI:RenderLoop()
    task.spawn(function()
      while task.wait() do
        if self.Open then
          self:Layout()
          self:DrawTabs()
          self:DrawElements()
        end
      end
    end)
  end

  ---- Input Handler ----
  function GUI:InputHandler()
    UIS.InputBegan:Connect(function(input, gameProcessed)
      if gameProcessed then return end
      
      -- Toggle GUI key (RightShift or custom)
      if input.KeyCode == self.ToggleKey or input.KeyCode == Enum.KeyCode.RightShift then
        self:Toggle()
        return
      end

      if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mPos = Vector2.new(Mouse.X, Mouse.Y)
        self:HandleClick(mPos)
      end
    end)

    UIS.InputChanged:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement then
        local mPos = Vector2.new(Mouse.X, Mouse.Y)
        self:HandleMove(mPos)
      end
    end)

    UIS.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then
        self:HandleRelease()
      end
    end)
  end

  ---- Init All ----
  function GUI:Start()
    self:Init()
    self:RenderLoop()
    self:InputHandler()
    print("[SH][GUI] SoberHook v4.0 GUI initialized. Press RightShift to toggle.")
  end

  -- Store global reference
  getgenv().SoberGUI = GUI
  _G.SoberGUI = GUI
  return GUI
end-- =====================================================
-- [SECTION 3] MODULE SYSTEM — ALL FEATURES WITH TOGGLES
-- =====================================================

local Modules = {}
local ModuleStates = {}

-- ---- Module Registration Helper ----
function Modules:Register(name, func)
  self[name] = func
  ModuleStates[name] = { Running = false, Thread = nil }
end

-- ---- Module Toggle Helper ----
function Modules:Toggle(name, enable)
  local mod = ModuleStates[name]
  if not mod then return end
  
  if enable and not mod.Running then
    mod.Running = true
    mod.Thread = coroutine.create(function()
      self[name](true)
      mod.Running = false
    end)
    local succ = coroutine.resume(mod.Thread)
    if not succ then
      warn("[SH][ERROR] Module '" .. name .. "' crashed: " .. tostring(succ))
      mod.Running = false
    end
  elseif not enable and mod.Running then
    mod.Running = false
    -- Thread will check running state and exit
  end
end

-- ---- Update all modules based on config ----
function Modules:UpdateAll()
  -- We handle toggles in the main loop instead of coroutines
  -- for better performance and stability
end

print("[SH][Modules] System initialized")

-- =====================================================
-- [MODULE 1] AIMBOT
-- =====================================================
local AimbotModule = {
  Active = false,
  CurrentTarget = nil,
  OldFindPartOnRay = nil,
  Connection = nil
}

function AimbotModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Aimbot] Starting Aimbot with method: " .. Cfg.Aimbot.Method)
  
  if Cfg.Aimbot.Method == "SilentAim" then
    -- Hook the FindPartOnRayWithIgnoreList to redirect bullets
    self.OldFindPartOnRay = Workspace.FindPartOnRayWithIgnoreList
    Workspace.FindPartOnRayWithIgnoreList = function(...)
      if not Cfg.Aimbot.E or not self.Active then
        return self.OldFindPartOnRay(unpack({...}))
      end
      
      local target = U.ClosestPlayerToMouse()
      if target then
        -- Check visibility if enabled
        if Cfg.Aimbot.VisCheck then
          local hrp = U.GetHRP(target)
          if hrp then
            local camPos = Camera.CFrame.Position
            local dir = (hrp.Position - camPos).Unit
            local ray = Ray.new(camPos, dir * 9999)
            local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character})
            if hit and not hit:IsDescendantOf(target.Character) then
              return self.OldFindPartOnRay(unpack({...}))
            end
          end
        end
        
        -- Get predicted position
        local predPos = U.Predict(target, Cfg.Aimbot.Pred)
        if predPos then
          -- Return the target as the hit part for silent aim
          local args = {...}
          local ray = args[1]
          if ray and type(ray) == "Ray" then
            -- Redirect to target
            local startPos = ray.Origin
            local dir = (predPos - startPos).Unit
            local newRay = Ray.new(startPos, dir * 9999)
            local newArgs = {newRay, args[2]}
            -- Call original
            return target.Character.HumanoidRootPart, predPos
          end
        end
      end
      
      return self.OldFindPartOnRay(unpack({...}))
    end
    
    -- Silent aim also needs to hook bullet creation in some games
    -- Generic approach: hook fire function on local player's tools
    self.Connection = LP.ChildAdded:Connect(function(child)
      if child:IsA("Tool") then
        -- Hook the tool's fire/attack function
        coroutine.wrap(function()
          task.wait(0.1)
          local handle = child:FindFirstChild("Handle") or child:FindFirstChildOfClass("Part")
          if handle and handle:FindFirstChildOfClass("TouchTransmitter") then
            -- Already hooked
            return
          end
        end)()
      end
    end)
    
  elseif Cfg.Aimbot.Method == "CFrame" then
    -- CFrame aimbot: directly set camera CFrame to look at target
    self.Connection = RenderStepped:Connect(function()
      if not Cfg.Aimbot.E or not self.Active then return end
      
      local target = U.ClosestPlayerToMouse()
      if not target then return end
      
      -- Check if key is held
      local isKeyPressed = false
      if Cfg.Aimbot.Key == "MouseButton2" then
        isKeyPressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
      elseif Cfg.Aimbot.Key:sub(1, 4) == "Key_" then
        local keyCode = Enum.KeyCode[Cfg.Aimbot.Key:sub(5)]
        if keyCode then
          isKeyPressed = UIS:IsKeyDown(keyCode)
        end
      end
      
      if not isKeyPressed then return end
      
      local hrp = U.GetHRP(target)
      if not hrp then return end
      
      local predPos = U.Predict(target, Cfg.Aimbot.Pred)
      if not predPos then return end
      
      -- Smooth aiming
      if Cfg.Aimbot.Smooth > 0 then
        local currentLook = Camera.CFrame.LookVector
        local targetLook = (predPos - Camera.CFrame.Position).Unit
        local smoothed = currentLook:Lerp(targetLook, 1 - Cfg.Aimbot.Smooth)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothed)
      else
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predPos)
      end
    end)
  end
  
  print("[SH][Aimbot] Active - Method: " .. Cfg.Aimbot.Method .. ", FOV: " .. Cfg.Aimbot.FOV .. " degrees")
end

function AimbotModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  -- Restore original hook
  if self.OldFindPartOnRay then
    Workspace.FindPartOnRayWithIgnoreList = self.OldFindPartOnRay
    self.OldFindPartOnRay = nil
  end
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  print("[SH][Aimbot] Deactivated")
end

-- =====================================================
-- [MODULE 2] TRIGGERBOT
-- =====================================================
local TriggerModule = {
  Active = false,
  Connection = nil,
  LastFireTime = 0
}

function TriggerModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Triggerbot] Starting...")
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.Trigger.E or not self.Active then return end
    
    -- Rate limit
    local now = tick()
    if now - self.LastFireTime < Cfg.Trigger.Delay then return end
    
    -- Raycast from camera center
    local camPos = Camera.CFrame.Position
    local dir = Camera.CFrame.LookVector
    local ray = Ray.new(camPos, dir * Cfg.Trigger.Range)
    local ignoreList = {LP.Character}
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    
    if hit and hit.Parent then
      local player = Players:GetPlayerFromCharacter(hit.Parent)
      if not player then
        -- Check if part of a player's character
        local model = hit.Parent
        if model:IsA("Model") then
          player = Players:GetPlayerFromCharacter(model)
        end
      end
      
      if player and player ~= LP then
        -- Check if aiming at allowed parts
        local partName = hit.Name
        local allowed = false
        for _, wp in ipairs(Cfg.Trigger.Whitelist) do
          if partName == wp then
            allowed = true
            break
          end
        end
        if not allowed then
          -- Fallback: any body part
          if hit:IsA("BasePart") and player.Character and hit:IsDescendantOf(player.Character) then
            allowed = true
          end
        end
        
        if allowed then
          -- Simulate mouse click
          VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
          task.wait(0.01)
          VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
          self.LastFireTime = now
        end
      end
    end
  end)
  
  print("[SH][Triggerbot] Active - Range: " .. Cfg.Trigger.Range .. ", Delay: " .. Cfg.Trigger.Delay * 1000 .. "ms")
end

function TriggerModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  print("[SH][Triggerbot] Deactivated")
end

-- =====================================================
-- [MODULE 3] ESP (Extra Sensory Perception)
-- =====================================================
local ESPModule = {
  Active = false,
  Objects = {},
  Connection = nil,
  LastRefresh = 0
}

function ESPModule:CreateObjects(p)
  if self.Objects[p] then
    self:RemoveObjects(p)
  end
  
  local data = {}
  
  -- Box
  if Cfg.ESP.Boxes then
    data.Box = Drawing.new("Square")
    data.Box.Filled = false
    data.Box.Thickness = 1.5
    data.Box.Visible = false
    
    if Cfg.ESP.BoxOutline then
      data.BoxOutline = Drawing.new("Square")
      data.BoxOutline.Filled = false
      data.BoxOutline.Thickness = 3
      data.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
      data.BoxOutline.Visible = false
    end
  end
  
  -- Health Bar
  if Cfg.ESP.HealthBars then
    data.HealthBarBG = Drawing.new("Square")
    data.HealthBarBG.Filled = true
    data.HealthBarBG.Color = Color3.fromRGB(0, 0, 0)
    data.HealthBarBG.Thickness = 0
    data.HealthBarBG.Visible = false
    
    data.HealthBar = Drawing.new("Square")
    data.HealthBar.Filled = true
    data.HealthBar.Thickness = 0
    data.HealthBar.Visible = false
  end
  
  -- Name
  if Cfg.ESP.Names then
    data.Name = Drawing.new("Text")
    data.Name.Size = 13
    data.Name.Outline = true
    data.Name.Center = true
    data.Name.Visible = false
  end
  
  -- Distance
  if Cfg.ESP.Distance then
    data.Distance = Drawing.new("Text")
    data.Distance.Size = 11
    data.Distance.Outline = true
    data.Distance.Center = true
    data.Distance.Visible = false
  end
  
  -- Weapon
  if Cfg.ESP.Weapon then
    data.Weapon = Drawing.new("Text")
    data.Weapon.Size = 11
    data.Weapon.Outline = true
    data.Weapon.Center = true
    data.Weapon.Visible = false
  end
  
  -- Tracers
  if Cfg.ESP.Tracers then
    data.Tracer = Drawing.new("Line")
    data.Tracer.Thickness = 1.5
    data.Tracer.Visible = false
  end
  
  -- Health Text
  if Cfg.ESP.HealthText then
    data.HealthText = Drawing.new("Text")
    data.HealthText.Size = 11
    data.HealthText.Outline = true
    data.HealthText.Center = true
    data.HealthText.Visible = false
  end
  
  self.Objects[p] = data
  return data
end

function ESPModule:RemoveObjects(p)
  local data = self.Objects[p]
  if not data then return end
  
  for _, obj in pairs(data) do
    pcall(function() obj:Remove() end)
  end
  
  self.Objects[p] = nil
end

function ESPModule:UpdatePlayer(p, data)
  if not p or not data then return end
  if not IsAlive(p) then
    -- Hide all
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  local hrp = U.GetHRP(p)
  if not hrp then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  local hum = U.GetHum(p)
  if not hum then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  local c = p.Character
  local head = c and c:FindFirstChild("Head")
  if not head then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  -- Get screen positions
  local headPos, headVis = U.W2S(head.Position + Vector3.new(0, 0.5, 0))
  local footPos, footVis = U.W2S(hrp.Position - Vector3.new(0, 3, 0))
  
  if not headVis or not footVis then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  -- Check distance
  local dist = U.Dist(Camera.CFrame.Position, hrp.Position)
  if dist > Cfg.ESP.MaxDist then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  -- Check team
  if Cfg.ESP.TeamCheck and p.Team == LP.Team then
    for _, obj in pairs(data) do
      pcall(function() obj.Visible = false end)
    end
    return
  end
  
  local boxHeight = (headPos - footPos).Magnitude
  local boxWidth = boxHeight * 0.6
  local boxTopLeft = Vector2.new((headPos.X + footPos.X) / 2 - boxWidth / 2, math.min(headPos.Y, footPos.Y))
  
  -- Team color
  local teamColor = Cfg.ESP.UseTeamColor and (p.Team and p.Team.Color or Color3.fromRGB(255,255,255)) or Color3.fromRGB(255, 80, 80)
  
  -- Draw Box
  if data.Box then
    data.Box.Size = Vector2.new(boxWidth, boxHeight)
    data.Box.Position = boxTopLeft
    data.Box.Color = teamColor
    data.Box.Visible = true
  end
  
  if data.BoxOutline then
    data.BoxOutline.Size = Vector2.new(boxWidth + 2, boxHeight + 2)
    data.BoxOutline.Position = boxTopLeft - Vector2.new(1, 1)
    data.BoxOutline.Visible = true
  end
  
  -- Draw Health Bar
  if data.HealthBar and data.HealthBarBG then
    local healthPercent = hum.Health / hum.MaxHealth
    local barWidth = 4
    local barHeight = boxHeight
    local barX = boxTopLeft.X - barWidth - 3
    local barY = boxTopLeft.Y
    
    data.HealthBarBG.Size = Vector2.new(barWidth + 2, barHeight + 2)
    data.HealthBarBG.Position = Vector2.new(barX - 1, barY - 1)
    data.HealthBarBG.Visible = true
    
    local healthColor = Color3.fromRGB(
      math.floor(255 * (1 - healthPercent)),
      math.floor(255 * healthPercent),
      0
    )
    
    data.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
    data.HealthBar.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
    data.HealthBar.Color = healthColor
    data.HealthBar.Visible = true
  end
  
  -- Draw Name
  if data.Name then
    data.Name.Text = p.Name
    data.Name.Position = Vector2.new(boxTopLeft.X + boxWidth / 2, boxTopLeft.Y - 15)
    data.Name.Color = teamColor
    data.Name.Visible = true
  end
  
  -- Draw Distance
  if data.Distance then
    data.Distance.Text = tostring(math.floor(dist)) .. " studs"
    data.Distance.Position = Vector2.new(boxTopLeft.X + boxWidth / 2, boxTopLeft.Y + boxHeight + 2)
    data.Distance.Color = Color3.fromRGB(200, 200, 200)
    data.Distance.Visible = true
  end
  
  -- Draw Weapon
  if data.Weapon then
    local tool = c:FindFirstChildOfClass("Tool")
    local weaponName = tool and tool.Name or "None"
    data.Weapon.Text = weaponName
    data.Weapon.Position = Vector2.new(boxTopLeft.X + boxWidth / 2, boxTopLeft.Y + boxHeight + 16)
    data.Weapon.Color = Color3.fromRGB(200, 200, 50)
    data.Weapon.Visible = true
  end
  
  -- Draw Tracer
  if data.Tracer then
    local screenCenter = Camera.ViewportSize / 2
    local origin = Vector2.new(screenCenter.X, screenCenter.Y)
    if Cfg.ESP.TracerFrom == "Bottom" then
      origin = Vector2.new(screenCenter.X, Camera.ViewportSize.Y)
    end
    data.Tracer.From = origin
    data.Tracer.To = Vector2.new((headPos.X + footPos.X) / 2, math.min(headPos.Y, footPos.Y))
    data.Tracer.Color = teamColor
    data.Tracer.Visible = true
  end
  
  -- Draw Health Text
  if data.HealthText then
    data.HealthText.Text = tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
    data.HealthText.Position = Vector2.new(boxTopLeft.X + boxWidth / 2, boxTopLeft.Y + boxHeight - 12)
    data.HealthText.Color = Color3.fromRGB(255, 255, 255)
    data.HealthText.Visible = true
  end
end

function ESPModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][ESP] Starting...")
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.ESP.E or not self.Active then return end
    
    -- Refresh rate limiting
    local now = tick()
    if now - self.LastRefresh < Cfg.ESP.RefreshRate then return end
    self.LastRefresh = now
    
    -- Cleanup disconnected players
    for p in pairs(self.Objects) do
      if not Players:FindFirstChild(p.Name) then
        self:RemoveObjects(p)
      end
    end
    
    -- Update all players
    for _, p in ipairs(U.GetPlayers(true)) do
      local data = self.Objects[p]
      if not data then
        data = self:CreateObjects(p)
      end
      self:UpdatePlayer(p, data)
    end
  end)
  
  print("[SH][ESP] Active - MaxDist: " .. Cfg.ESP.MaxDist)
end

function ESPModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  -- Remove all drawing objects
  for p in pairs(self.Objects) do
    self:RemoveObjects(p)
  end
  
  print("[SH][ESP] Deactivated")
end

-- =====================================================
-- [MODULE 4] WEAPON MODIFICATIONS
-- =====================================================
local WeaponModule = {
  Active = false,
  Hooks = {},
  Connections = {}
}

function WeaponModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][WeaponMods] Starting...")
  
  -- Hook key weapon functions
  -- No Recoil / No Spread hook
  if Cfg.Weapon.NoRecoil or Cfg.Weapon.NoSpread then
    self.Connections.Render = RenderStepped:Connect(function()
      if not Cfg.Weapon.E or not self.Active then return end
      
      local tool = U.GetTool()
      if not tool then return end
      
      -- Find recoil/spread values and zero them
      local gunScripts = tool:GetDescendants()
      for _, s in ipairs(gunScripts) do
        if s:IsA("LocalScript") or s:IsA("ModuleScript") then
          -- Look for recoil-related values in the script's environment
          local env = getfenv and getfenv(s)
          if env then
            -- Generic approach: modify common recoil/spread variables
            if Cfg.Weapon.NoRecoil then
              for _, name in ipairs({"Recoil", "recoil", "RecoilAmount", "recoilAmount", "RecoilForce", "recoilForce", "spread", "Spread", "CameraShake"}) do
                if env[name] ~= nil then
                  env[name] = 0
                end
              end
            end
            
            if Cfg.Weapon.NoSpread then
              for _, name in ipairs({"Spread", "spread", "Accuracy", "accuracy", "Inaccuracy", "inaccuracy"}) do
                if env[name] ~= nil then
                  env[name] = 0
                end
              end
            end
          end
        end
      end
      
      -- Also try to hook the mouse's Delta property for recoil
      if Cfg.Weapon.NoRecoil and Mouse and Mouse.Origin then
        -- Some games use Mouse.Origin changes for recoil
      end
    end)
  end
  
  -- Infinite Ammo
  if Cfg.Weapon.InfAmmo then
    self.Connections.Ammo = RenderStepped:Connect(function()
      if not Cfg.Weapon.E or not self.Active then return end
      
      local c = U.GetChar()
      if not c then return end
      
      -- Find ammo-related IntValues and set them high
      for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("IntValue") then
          local name = v.Name:lower()
          if name:find("ammo") or name:find("bullet") or name:find("clip") or name:find("mag") then
            v.Value = 9999
          end
        end
        if v:IsA("NumberValue") then
          local name = v.Name:lower()
          if name:find("ammo") or name:find("bullet") or name:find("clip") or name:find("mag") then
            v.Value = 9999
          end
        end
      end
      
      -- Also check backpack
      local bp = LP:FindFirstChild("Backpack")
      if bp then
        for _, v in ipairs(bp:GetDescendants()) do
          if v:IsA("IntValue") and v.Name:lower():find("ammo") then
            v.Value = 9999
          end
        end
      end
    end)
  end
  
  -- Instant Reload
  if Cfg.Weapon.InstReload then
    self.Connections.Reload = RenderStepped:Connect(function()
      if not Cfg.Weapon.E or not self.Active then return end
      
      local c = U.GetChar()
      if not c then return end
      
      for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("BoolValue") and v.Name:lower():find("reload") then
          v.Value = false
        end
        if v:IsA("NumberValue") and v.Name:lower():find("reloadtime") then
          v.Value = 0
        end
      end
    end)
  end
  
  -- Infinite Damage
  if Cfg.Weapon.InfDmg then
    self.Connections.Damage = RenderStepped:Connect(function()
      if not Cfg.Weapon.E or not self.Active then return end
      
      local tool = U.GetTool()
      if not tool then return end
      
      for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") then
          local name = v.Name:lower()
          if name:find("damage") or name:find("dmg") or name:find("attackdamage") then
            v.Value = v.Value * Cfg.Weapon.DmgMult
          end
        end
      end
    end)
  end
  
  print("[SH][WeaponMods] Active - Recoil:" .. tostring(Cfg.Weapon.NoRecoil) .. " Spread:" .. tostring(Cfg.Weapon.NoSpread) .. " Ammo:" .. tostring(Cfg.Weapon.InfAmmo))
end

function WeaponModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  for _, conn in pairs(self.Connections) do
    conn:Disconnect()
  end
  self.Connections = {}
  
  print("[SH][WeaponMods] Deactivated")
end

-- =====================================================
-- [MODULE 5] MOVEMENT SUITE
-- =====================================================
local MovementModule = {
  Active = false,
  Connections = {},
  FlyBody = nil,
  FlyGyro = nil,
  FlyPartsCreated = false
}

function MovementModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Movement] Starting...")
  
  ---- Speed Hack ----
  if Cfg.Speed.E then
    self.Connections.Speed = Heartbeat:Connect(function()
      if not Cfg.Speed.E then return end
      local c = U.GetChar()
      if not c then return end
      local h = c:FindFirstChildOfClass("Humanoid")
      if h then
        h.WalkSpeed = Cfg.Speed.Speed
      end
    end)
    print("  [SH][Move] SpeedHack - Speed: " .. Cfg.Speed.Speed)
  end
  
  ---- Fly Hack (BodyVelocity + BodyGyro method) ----
  if Cfg.Fly.E then
    -- Create fly parts attached to local player
    local function createFlyParts()
      local c = U.GetChar()
      if not c then return end
      local hrp = c:FindFirstChild("HumanoidRootPart")
      if not hrp then return end
      
      -- Remove old parts if any
      if self.FlyBody then self.FlyBody:Destroy() end
      if self.FlyGyro then self.FlyGyro:Destroy() end
      
      self.FlyBody = Instance.new("BodyVelocity")
      self.FlyBody.Velocity = Vector3.new(0, 0, 0)
      self.FlyBody.MaxForce = Vector3.new(1, 1, 1) * 4000
      self.FlyBody.P = 2000
      self.FlyBody.Parent = hrp
      
      self.FlyGyro = Instance.new("BodyGyro")
      self.FlyGyro.MaxTorque = Vector3.new(1, 1, 1) * 4000
      self.FlyGyro.P = 2000
      self.FlyGyro.D = 500
      self.FlyGyro.Parent = hrp
      
      self.FlyPartsCreated = true
    end
    
    createFlyParts()
    
    -- Connect to character added for respawn
    self.Connections.FlyCharAdded = LP.CharacterAdded:Connect(function()
      task.wait(0.5)
      if Cfg.Fly.E then
        createFlyParts()
      end
    end)
    
    self.Connections.Fly = Heartbeat:Connect(function()
      if not Cfg.Fly.E then
        -- Clean up fly parts if disabled
        if self.FlyPartsCreated then
          if self.FlyBody then pcall(function() self.FlyBody:Destroy() end) end
          if self.FlyGyro then pcall(function() self.FlyGyro:Destroy() end) end
          self.FlyBody = nil
          self.FlyGyro = nil
          self.FlyPartsCreated = false
        end
        return
      end
      
      -- Ensure fly parts exist
      if not self.FlyPartsCreated then
        local c = U.GetChar()
        if c and c:FindFirstChild("HumanoidRootPart") then
          createFlyParts()
        end
        return
      end
      
      local c = U.GetChar()
      if not c then return end
      local hrp = c:FindFirstChild("HumanoidRootPart")
      if not hrp then return end
      local h = c:FindFirstChildOfClass("Humanoid")
      if not h then return end
      
      -- Disable gravity on humanoid
      h.PlatformStand = true
      
      -- Set gyro to camera direction
      if self.FlyGyro then
        self.FlyGyro.CFrame = Camera.CFrame
      end
      
      -- Movement direction
      local dir = Vector3.new(0, 0, 0)
      if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
      if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir + Vector3.new(0, -1, 0) end
      
      if dir.Magnitude > 0 then
        dir = dir.Unit * Cfg.Fly.Speed
      end
      
      if self.FlyBody then
        self.FlyBody.Velocity = dir
      end
    end)
    
    print("  [SH][Move] FlyHack - Speed: " .. Cfg.Fly.Speed)
  end
  
  ---- Infinite Jump ----
  if Cfg.InfJump.E then
    self.Connections.InfJump = UIS.JumpRequest:Connect(function()
      if not Cfg.InfJump.E then return end
      local c = U.GetChar()
      if not c then return end
      local h = c:FindFirstChildOfClass("Humanoid")
      if h then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
      end
    end)
    print("  [SH][Move] InfiniteJump")
  end
  
  ---- Bunny Hop ----
  if Cfg.BunnyHop.E then
    self.Connections.BunnyHop = Heartbeat:Connect(function()
      if not Cfg.BunnyHop.E then return end
      if UIS:IsKeyDown(Enum.KeyCode.Space) then
        local c = U.GetChar()
        if c then
          local h = c:FindFirstChildOfClass("Humanoid")
          if h and h.FloorMaterial ~= Enum.Material.Air then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
          end
        end
      end
    end)
    print("  [SH][Move] BunnyHop")
  end
  
  ---- Noclip ----
  if Cfg.Noclip.E then
    self.Connections.Noclip = Stepped:Connect(function()
      if not Cfg.Noclip.E then return end
      local c = U.GetChar()
      if not c then return end
      for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
          p.CanCollide = false
        end
      end
    end)
    print("  [SH][Move] Noclip")
  end
end

function MovementModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  -- Restore walk speed
  local c = U.GetChar()
  if c then
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
      pcall(function() h.WalkSpeed = 16 end)
      pcall(function() h.PlatformStand = false end)
    end
  end
  
  -- Destroy fly parts
  if self.FlyBody then pcall(function() self.FlyBody:Destroy() end) end
  if self.FlyGyro then pcall(function() self.FlyGyro:Destroy() end) end
  self.FlyBody = nil
  self.FlyGyro = nil
  self.FlyPartsCreated = false
  
  -- Disconnect all connections
  for _, conn in pairs(self.Connections) do
    pcall(function() conn:Disconnect() end)
  end
  self.Connections = {}
  
  print("[SH][Movement] Deactivated")
end-- =====================================================
-- [MODULE 6] WALLHACK
-- =====================================================
local WallhackModule = {
  Active = false,
  Connection = nil,
  OriginalTransparencies = {}
}

function WallhackModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Wallhack] Starting...")
  
  self.Connection = Stepped:Connect(function()
    if not Cfg.Wallhack.E or not self.Active then return end
    
    for _, v in ipairs(Workspace:GetDescendants()) do
      if v:IsA("BasePart") and not v:IsDescendantOf(Players) then
        -- Skip parts that are already transparent or invisible
        if v.Transparency < Cfg.Wallhack.Transparency then
          -- Store original if not already stored
          if not self.OriginalTransparencies[v] then
            self.OriginalTransparencies[v] = v.Transparency
          end
          v.LocalTransparencyModifier = Cfg.Wallhack.Transparency
        end
      end
    end
  end)
  
  print("[SH][Wallhack] Active - Transparency: " .. Cfg.Wallhack.Transparency)
end

function WallhackModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  -- Restore original transparencies
  for v, trans in pairs(self.OriginalTransparencies) do
    pcall(function()
      v.LocalTransparencyModifier = 0
    end)
  end
  self.OriginalTransparencies = {}
  
  print("[SH][Wallhack] Deactivated")
end

-- =====================================================
-- [MODULE 7] ANTI-AIM
-- =====================================================
local AntiAimModule = {
  Active = false,
  Connection = nil,
  YawAngle = 0
}

function AntiAimModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][AntiAim] Starting with mode: " .. Cfg.AntiAim.Mode)
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.AntiAim.E or not self.Active then return end
    
    local cam = Camera
    if not cam then return end
    
    local mode = Cfg.AntiAim.Mode
    
    if mode == "Spin" then
      -- Continuous spin
      self.YawAngle = (self.YawAngle + (Cfg.AntiAim.YawSpeed * 0.016)) % 360
      local pitch = math.rad(Cfg.AntiAim.Pitch or 0)
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(pitch, math.rad(self.YawAngle), 0)
      
    elseif mode == "Jitter" then
      -- Random jitter
      local pitch = math.random(-89, 89)
      local yaw = math.random(-180, 180)
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
      
    elseif mode == "Backwards" then
      -- Look backwards
      local pitch = math.rad(Cfg.AntiAim.Pitch or 0)
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(pitch, math.rad(180), 0)
      
    elseif mode == "Down" then
      -- Look straight down
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(89), 0, 0)
      
    elseif mode == "Up" then
      -- Look straight up
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(-89), 0, 0)
      
    elseif mode == "SpinSlow" then
      -- Slow spin
      self.YawAngle = (self.YawAngle + 30 * 0.016) % 360
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(0, math.rad(self.YawAngle), 0)
      
    elseif mode == "SpinFast" then
      -- Fast spin
      self.YawAngle = (self.YawAngle + 720 * 0.016) % 360
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(-10), math.rad(self.YawAngle), 0)
      
    elseif mode == "Random" then
      -- Random each tick
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(math.random(-89, 89)), math.rad(math.random(-180, 180)), 0)
      
    elseif mode == "Lisp" then
      -- Side to side
      self.YawAngle = math.sin(tick() * 3) * 60
      cam.CFrame = CFrame.new(cam.CFrame.Position) * 
                   CFrame.Angles(math.rad(10), math.rad(self.YawAngle), 0)
    end
  end)
  
  print("[SH][AntiAim] Active - Mode: " .. mode)
end

function AntiAimModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  print("[SH][AntiAim] Deactivated")
end

-- =====================================================
-- [MODULE 8] AUTOMATION (AutoFarm, AutoHeal, AutoBlock, AutoLoadout)
-- =====================================================
local AutomationModule = {
  Active = false,
  Connections = {},
  Threads = {}
}

function AutomationModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Automation] Starting...")
  
  ---- AutoFarm ----
  if Cfg.AutoFarm.E then
    self.Threads.AutoFarm = coroutine.create(function()
      while self.Active and Cfg.AutoFarm.E do
        task.wait(0.3)
        
        local c = U.GetChar()
        if not c then goto continue_af end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then goto continue_af end
        
        local method = Cfg.AutoFarm.Method
        local radius = Cfg.AutoFarm.Radius
        
        if method == "Collect" then
          -- Collect TouchInterest parts (coins, items)
          for _, v in ipairs(Workspace:GetDescendants()) do
            if not self.Active or not Cfg.AutoFarm.E then break end
            if v:IsA("BasePart") and v:FindFirstChildOfClass("TouchTransmitter") then
              local dist = U.Dist(hrp.Position, v.Position)
              if dist <= radius then
                pcall(function()
                  firetouchinterest(hrp, v, 0)
                  task.wait(0.01)
                  firetouchinterest(hrp, v, 1)
                end)
              end
            end
          end
          
        elseif method == "Click" then
          -- Fire ClickDetectors
          for _, v in ipairs(Workspace:GetDescendants()) do
            if not self.Active or not Cfg.AutoFarm.E then break end
            if v:IsA("ClickDetector") and v.Parent and v.Parent:IsA("BasePart") then
              local dist = U.Dist(hrp.Position, v.Parent.Position)
              if dist <= radius then
                pcall(function() fireclickdetector(v) end)
              end
            end
          end
          
        elseif method == "Proximity" then
          -- Fire ProximityPrompts
          for _, v in ipairs(Workspace:GetDescendants()) do
            if not self.Active or not Cfg.AutoFarm.E then break end
            if v:IsA("ProximityPrompt") then
              local dist = U.Dist(hrp.Position, v.Parent and v.Parent.Position or hrp.Position)
              if dist <= radius then
                pcall(function() fireproximityprompt(v) end)
              end
            end
          end
          
        elseif method == "Kill" then
          -- Attack nearest enemy
          local nearest, ndist = U.GetNearestPlayer(hrp.Position, radius)
          if nearest and IsAlive(nearest) then
            -- Equip best weapon and attack
            local tool = U.GetTool()
            if tool then
              -- Click to attack
              VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
              task.wait(0.05)
              VirtualInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
            end
          end
        end
        
        ::continue_af::
      end
    end)
    coroutine.resume(self.Threads.AutoFarm)
    print("  [SH][Auto] AutoFarm - Method: " .. Cfg.AutoFarm.Method)
  end
  
  ---- AutoHeal ----
  if Cfg.AutoHeal.E then
    self.Threads.AutoHeal = coroutine.create(function()
      while self.Active and Cfg.AutoHeal.E do
        task.wait(0.5)
        
        if not IsAlive(LP) then goto continue_ah end
        
        local c = LP.Character
        if not c then goto continue_ah end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then goto continue_ah end
        
        local healthPercent = (h.Health / h.MaxHealth) * 100
        if healthPercent <= Cfg.AutoHeal.Threshold then
          -- Search backpack for healing item
          local bp = LP:FindFirstChild("Backpack")
          if bp then
            for _, item in ipairs(bp:GetChildren()) do
              if not self.Active or not Cfg.AutoHeal.E then break end
              local itemName = item.Name:lower()
              local healName = Cfg.AutoHeal.Item:lower()
              if itemName:find(healName) or itemName == healName then
                -- Equip the item
                pcall(function()
                  h:EquipTool(item)
                  task.wait(0.2)
                  -- Try to use the item (find heal/use function)
                  for _, child in ipairs(item:GetDescendants()) do
                    if child:IsA("BindableFunction") then
                      local childName = child.Name:lower()
                      if childName:find("heal") or childName:find("use") or childName:find("activate") then
                        child:Invoke()
                        break
                      end
                    end
                  end
                  -- Also try RemoteFunction/RemoteEvent
                  for _, child in ipairs(item:GetDescendants()) do
                    if child:IsA("RemoteFunction") and child.Name:lower():find("heal") then
                      child:InvokeServer()
                      break
                    end
                    if child:IsA("RemoteEvent") and child.Name:lower():find("heal") then
                      child:FireServer()
                      break
                    end
                  end
                end)
                break
              end
            end
          end
        end
        
        ::continue_ah::
      end
    end)
    coroutine.resume(self.Threads.AutoHeal)
    print("  [SH][Auto] AutoHeal - Threshold: " .. Cfg.AutoHeal.Threshold .. "%")
  end
  
  ---- AutoBlock ----
  if Cfg.AutoBlock.E then
    self.Connections.AutoBlock = RenderStepped:Connect(function()
      if not Cfg.AutoBlock.E or not self.Active then return end
      
      local c = U.GetChar()
      if not c then return end
      local tool = c:FindFirstChildOfClass("Tool")
      if not tool then return end
      
      -- Find block/parry/deflect function
      for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("BindableFunction") then
          local cn = child.Name:lower()
          if cn:find("block") or cn:find("parry") or cn:find("deflect") or cn:find("guard") then
            if Cfg.AutoBlock.Mode == "Always" then
              pcall(function() child:Invoke() end)
            elseif Cfg.AutoBlock.Mode == "OnDamage" and Cfg.AutoBlock.BlockOnDamage then
              -- Check if recently damaged
              local h = c:FindFirstChildOfClass("Humanoid")
              if h then
                pcall(function() child:Invoke() end)
              end
            end
            break
          end
        end
        if child:IsA("RemoteFunction") and child.Name:lower():find("block") then
          pcall(function() child:InvokeServer() end)
          break
        end
        if child:IsA("RemoteEvent") and child.Name:lower():find("block") then
          pcall(function() child:FireServer() end)
          break
        end
      end
    end)
    print("  [SH][Auto] AutoBlock - Mode: " .. Cfg.AutoBlock.Mode)
  end
  
  ---- AutoLoadout ----
  if Cfg.Loadout.E then
    self.Threads.Loadout = coroutine.create(function()
      while self.Active and Cfg.Loadout.E do
        task.wait(Cfg.Loadout.SwitchDelay or 0.5)
        
        if not IsAlive(LP) then goto continue_lo end
        
        local c = LP.Character
        if not c then goto continue_lo end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then goto continue_lo end
        
        local currentTool = c:FindFirstChildOfClass("Tool")
        local currentName = currentTool and currentTool.Name or ""
        
        local bp = LP:FindFirstChild("Backpack")
        if not bp then goto continue_lo end
        
        -- Try to equip each gun in order
        for _, gunName in ipairs(Cfg.Loadout.Guns) do
          if currentName ~= gunName then
            local tool = bp:FindFirstChild(gunName)
            if tool then
              pcall(function() h:EquipTool(tool) end)
              break
            end
          end
        end
        
        ::continue_lo::
      end
    end)
    coroutine.resume(self.Threads.Loadout)
    print("  [SH][Auto] AutoLoadout - Guns: " .. table.concat(Cfg.Loadout.Guns, ", "))
  end
end

function AutomationModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  for _, conn in pairs(self.Connections) do
    pcall(function() conn:Disconnect() end)
  end
  self.Connections = {}
  
  -- Coroutines will naturally stop since self.Active is false
  self.Threads = {}
  
  print("[SH][Automation] Deactivated")
end

-- =====================================================
-- [MODULE 9] CHAT SPAMMER
-- =====================================================
local SpammerModule = {
  Active = false,
  Thread = nil,
  Index = 1
}

function SpammerModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][ChatSpammer] Starting...")
  
  self.Thread = coroutine.create(function()
    self.Index = 1
    while self.Active and Cfg.Spammer.E do
      task.wait(Cfg.Spammer.Interval)
      
      if not Cfg.Spammer.E then break end
      
      local msg = ""
      if Cfg.Spammer.RandomOrder then
        msg = Cfg.Spammer.Messages[math.random(1, #Cfg.Spammer.Messages)]
      else
        msg = Cfg.Spammer.Messages[self.Index]
        self.Index = self.Index % #Cfg.Spammer.Messages + 1
      end
      
      if msg and msg ~= "" then
        pcall(function()
          LP:Chat(msg)
        end)
        -- Also try alternative chat methods
        pcall(function()
          local chat = LP:FindFirstChildOfClass("Chat")
          if chat then
            chat:Chat(msg)
          end
        end)
        -- Try remote events for chat
        pcall(function()
          for _, v in ipairs(Players:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("chat") then
              v:FireServer(msg)
            end
          end
        end)
      end
    end
  end)
  coroutine.resume(self.Thread)
  
  print("[SH][ChatSpammer] Active - Interval: " .. Cfg.Spammer.Interval .. "s | Messages: " .. #Cfg.Spammer.Messages)
end

function SpammerModule:Stop()
  if not self.Active then return end
  self.Active = false
  self.Thread = nil
  
  print("[SH][ChatSpammer] Deactivated")
end

-- =====================================================
-- [MODULE 10] CUSTOM CROSSHAIR
-- =====================================================
local CrosshairModule = {
  Active = false,
  Objects = {},
  Connection = nil
}

function CrosshairModule:CreateObjects()
  -- Remove old objects
  self:DestroyObjects()
  
  local style = Cfg.Crosshair.Style
  local col = Cfg.Crosshair.Color
  local sz = Cfg.Crosshair.Size
  local thick = Cfg.Crosshair.Thickness
  
  if style == "Cross" then
    -- 4 lines forming a cross
    self.Objects.H1 = Drawing.new("Line")
    self.Objects.H1.Thickness = thick
    self.Objects.H1.Color = col
    
    self.Objects.H2 = Drawing.new("Line")
    self.Objects.H2.Thickness = thick
    self.Objects.H2.Color = col
    
    self.Objects.V1 = Drawing.new("Line")
    self.Objects.V1.Thickness = thick
    self.Objects.V1.Color = col
    
    self.Objects.V2 = Drawing.new("Line")
    self.Objects.V2.Thickness = thick
    self.Objects.V2.Color = col
    
    -- Gap in center (4 small lines)
    self.Objects.GapH1 = Drawing.new("Line")
    self.Objects.GapH1.Thickness = thick
    self.Objects.GapH1.Color = col
    
    self.Objects.GapH2 = Drawing.new("Line")
    self.Objects.GapH2.Thickness = thick
    self.Objects.GapH2.Color = col
    
    self.Objects.GapV1 = Drawing.new("Line")
    self.Objects.GapV1.Thickness = thick
    self.Objects.GapV1.Color = col
    
    self.Objects.GapV2 = Drawing.new("Line")
    self.Objects.GapV2.Thickness = thick
    self.Objects.GapV2.Color = col
    
    -- Outline versions
    if Cfg.Crosshair.Outline then
      local oCol = Cfg.Crosshair.OutlineColor
      self.Objects.OH1 = Drawing.new("Line"); self.Objects.OH1.Thickness = thick + 2; self.Objects.OH1.Color = oCol
      self.Objects.OH2 = Drawing.new("Line"); self.Objects.OH2.Thickness = thick + 2; self.Objects.OH2.Color = oCol
      self.Objects.OV1 = Drawing.new("Line"); self.Objects.OV1.Thickness = thick + 2; self.Objects.OV1.Color = oCol
      self.Objects.OV2 = Drawing.new("Line"); self.Objects.OV2.Thickness = thick + 2; self.Objects.OV2.Color = oCol
      self.Objects.OGH1 = Drawing.new("Line"); self.Objects.OGH1.Thickness = thick + 2; self.Objects.OGH1.Color = oCol
      self.Objects.OGH2 = Drawing.new("Line"); self.Objects.OGH2.Thickness = thick + 2; self.Objects.OGH2.Color = oCol
      self.Objects.OGV1 = Drawing.new("Line"); self.Objects.OGV1.Thickness = thick + 2; self.Objects.OGV1.Color = oCol
      self.Objects.OGV2 = Drawing.new("Line"); self.Objects.OGV2.Thickness = thick + 2; self.Objects.OGV2.Color = oCol
    end
    
  elseif style == "Dot" then
    self.Objects.Dot = Drawing.new("Circle")
    self.Objects.Dot.Radius = 3
    self.Objects.Dot.Color = col
    self.Objects.Dot.Filled = true
    self.Objects.Dot.Thickness = 0
    self.Objects.Dot.NumSides = 32
    
    if Cfg.Crosshair.Outline then
      self.Objects.DotOutline = Drawing.new("Circle")
      self.Objects.DotOutline.Radius = 5
      self.Objects.DotOutline.Color = Cfg.Crosshair.OutlineColor
      self.Objects.DotOutline.Filled = false
      self.Objects.DotOutline.Thickness = 1.5
      self.Objects.DotOutline.NumSides = 32
    end
    
  elseif style == "Circle" then
    self.Objects.Circle = Drawing.new("Circle")
    self.Objects.Circle.Radius = sz
    self.Objects.Circle.Color = col
    self.Objects.Circle.Filled = false
    self.Objects.Circle.Thickness = thick
    self.Objects.Circle.NumSides = 32
    
    -- Crosshair inside circle
    self.Objects.InnerH = Drawing.new("Line")
    self.Objects.InnerH.Thickness = thick
    self.Objects.InnerH.Color = col
    
    self.Objects.InnerV = Drawing.new("Line")
    self.Objects.InnerV.Thickness = thick
    self.Objects.InnerV.Color = col
    
  elseif style == "T" then
    self.Objects.Top = Drawing.new("Line")
    self.Objects.Top.Thickness = thick
    self.Objects.Top.Color = col
    
    self.Objects.Left = Drawing.new("Line")
    self.Objects.Left.Thickness = thick
    self.Objects.Left.Color = col
    
    self.Objects.Right = Drawing.new("Line")
    self.Objects.Right.Thickness = thick
    self.Objects.Right.Color = col
    
    self.Objects.Down = Drawing.new("Line")
    self.Objects.Down.Thickness = thick
    self.Objects.Down.Color = col
    
  elseif style == "Triangle" then
    -- 3 lines forming a triangle
    for i = 1, 3 do
      self.Objects["T" .. i] = Drawing.new("Line")
      self.Objects["T" .. i].Thickness = thick
      self.Objects["T" .. i].Color = col
    end
    
  elseif style == "Plus" then
    -- Full cross (no gap)
    self.Objects.H = Drawing.new("Line")
    self.Objects.H.Thickness = thick
    self.Objects.H.Color = col
    
    self.Objects.V = Drawing.new("Line")
    self.Objects.V.Thickness = thick
    self.Objects.V.Color = col
    
    if Cfg.Crosshair.Outline then
      self.Objects.OH = Drawing.new("Line"); self.Objects.OH.Thickness = thick + 2; self.Objects.OH.Color = Cfg.Crosshair.OutlineColor
      self.Objects.OV = Drawing.new("Line"); self.Objects.OV.Thickness = thick + 2; self.Objects.OV.Color = Cfg.Crosshair.OutlineColor
    end
  end
end

function CrosshairModule:DestroyObjects()
  for _, obj in pairs(self.Objects) do
    pcall(function() obj:Remove() end)
  end
  self.Objects = {}
end

function CrosshairModule:Update()
  local center = Camera.ViewportSize / 2
  local col = Cfg.Crosshair.Color
  local sz = Cfg.Crosshair.Size
  local thick = Cfg.Crosshair.Thickness
  local gap = 4  -- gap size for cross
  local style = Cfg.Crosshair.Style
  
  -- Hide all first
  local function setAllVisible(visible)
    for _, obj in pairs(self.Objects) do
      pcall(function() obj.Visible = visible end)
    end
  end
  
  if style == "Cross" then
    -- Gap cross with outline
    if Cfg.Crosshair.Outline then
      local oCol = Cfg.Crosshair.OutlineColor
      local function drawOutline(hName, vName, hOff1, hOff2, vOff1, vOff2, fromH, toH, fromV, toV)
        -- We'll handle outline by drawing behind
      end
    end
    
    -- Horizontal left
    self.Objects.GapH1.From = Vector2.new(center.X - sz, center.Y)
    self.Objects.GapH1.To = Vector2.new(center.X - gap, center.Y)
    self.Objects.GapH1.Visible = true
    
    -- Horizontal right
    self.Objects.GapH2.From = Vector2.new(center.X + gap, center.Y)
    self.Objects.GapH2.To = Vector2.new(center.X + sz, center.Y)
    self.Objects.GapH2.Visible = true
    
    -- Vertical top
    self.Objects.GapV1.From = Vector2.new(center.X, center.Y - sz)
    self.Objects.GapV1.To = Vector2.new(center.X, center.Y - gap)
    self.Objects.GapV1.Visible = true
    
    -- Vertical bottom
    self.Objects.GapV2.From = Vector2.new(center.X, center.Y + gap)
    self.Objects.GapV2.To = Vector2.new(center.X, center.Y + sz)
    self.Objects.GapV2.Visible = true
    
    -- Hide the full lines (they exist for other modes)
    if self.Objects.H1 then self.Objects.H1.Visible = false end
    if self.Objects.H2 then self.Objects.H2.Visible = false end
    if self.Objects.V1 then self.Objects.V1.Visible = false end
    if self.Objects.V2 then self.Objects.V2.Visible = false end
    
    -- Outlines
    if Cfg.Crosshair.Outline and self.Objects.OGH1 then
      local oCol = Cfg.Crosshair.OutlineColor
      -- We'll skip full outlines for gap cross to keep it clean
    end
    
  elseif style == "Dot" then
    if self.Objects.Dot then
      self.Objects.Dot.Position = center
      self.Objects.Dot.Radius = 3
      self.Objects.Dot.Color = col
      self.Objects.Dot.Visible = true
    end
    if self.Objects.DotOutline then
      self.Objects.DotOutline.Position = center
      self.Objects.DotOutline.Visible = true
    end
    
  elseif style == "Circle" then
    if self.Objects.Circle then
      self.Objects.Circle.Position = center
      self.Objects.Circle.Radius = sz
      self.Objects.Circle.Color = col
      self.Objects.Circle.Visible = true
    end
    if self.Objects.InnerH then
      self.Objects.InnerH.From = Vector2.new(center.X - sz/2, center.Y)
      self.Objects.InnerH.To = Vector2.new(center.X + sz/2, center.Y)
      self.Objects.InnerH.Visible = true
    end
    if self.Objects.InnerV then
      self.Objects.InnerV.From = Vector2.new(center.X, center.Y - sz/2)
      self.Objects.InnerV.To = Vector2.new(center.X, center.Y + sz/2)
      self.Objects.InnerV.Visible = true
    end
    
  elseif style == "T" then
    -- T-shape crosshair (like Valorant)
    if self.Objects.Top then
      self.Objects.Top.From = Vector2.new(center.X - sz, center.Y)
      self.Objects.Top.To = Vector2.new(center.X + sz, center.Y)
      self.Objects.Top.Visible = true
    end
    if self.Objects.Left then
      self.Objects.Left.From = Vector2.new(center.X - sz, center.Y)
      self.Objects.Left.To = Vector2.new(center.X - gap, center.Y)
      self.Objects.Left.Visible = true
    end
    if self.Objects.Right then
      self.Objects.Right.From = Vector2.new(center.X + gap, center.Y)
      self.Objects.Right.To = Vector2.new(center.X + sz, center.Y)
      self.Objects.Right.Visible = true
    end
    if self.Objects.Down then
      self.Objects.Down.From = Vector2.new(center.X, center.Y + gap)
      self.Objects.Down.To = Vector2.new(center.X, center.Y + sz)
      self.Objects.Down.Visible = true
    end
    
  elseif style == "Triangle" then
    local halfBase = sz * 0.5
    local height = sz * 0.866
    if self.Objects.T1 then
      self.Objects.T1.From = Vector2.new(center.X, center.Y - height * 0.5)
      self.Objects.T1.To = Vector2.new(center.X - halfBase, center.Y + height * 0.5)
      self.Objects.T1.Visible = true
    end
    if self.Objects.T2 then
      self.Objects.T2.From = Vector2.new(center.X - halfBase, center.Y + height * 0.5)
      self.Objects.T2.To = Vector2.new(center.X + halfBase, center.Y + height * 0.5)
      self.Objects.T2.Visible = true
    end
    if self.Objects.T3 then
      self.Objects.T3.From = Vector2.new(center.X + halfBase, center.Y + height * 0.5)
      self.Objects.T3.To = Vector2.new(center.X, center.Y - height * 0.5)
      self.Objects.T3.Visible = true
    end
    
  elseif style == "Plus" then
    if self.Objects.H then
      self.Objects.H.From = Vector2.new(center.X - sz, center.Y)
      self.Objects.H.To = Vector2.new(center.X + sz, center.Y)
      self.Objects.H.Visible = true
    end
    if self.Objects.V then
      self.Objects.V.From = Vector2.new(center.X, center.Y - sz)
      self.Objects.V.To = Vector2.new(center.X, center.Y + sz)
      self.Objects.V.Visible = true
    end
    if Cfg.Crosshair.Outline then
      if self.Objects.OH then
        self.Objects.OH.From = Vector2.new(center.X - sz, center.Y)
        self.Objects.OH.To = Vector2.new(center.X + sz, center.Y)
        self.Objects.OH.Visible = true
      end
      if self.Objects.OV then
        self.Objects.OV.From = Vector2.new(center.X, center.Y - sz)
        self.Objects.OV.To = Vector2.new(center.X, center.Y + sz)
        self.Objects.OV.Visible = true
      end
    end
  end
end

function CrosshairModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][Crosshair] Starting with style: " .. Cfg.Crosshair.Style)
  
  self:CreateObjects()
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.Crosshair.E or not self.Active then
      self:DestroyObjects()
      return
    end
    self:Update()
  end)
  
  print("[SH][Crosshair] Active")
end

function CrosshairModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  self:DestroyObjects()
  
  print("[SH][Crosshair] Deactivated")
end-- =====================================================
-- [MODULE 11] FOV CHANGER
-- =====================================================
local FOVModule = {
  Active = false,
  Connection = nil,
  OriginalFOV = 70
}

function FOVModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][FOVChanger] Starting...")
  
  self.OriginalFOV = Camera.FieldOfView
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.FOV.E or not self.Active then return end
    Camera.FieldOfView = Cfg.FOV.FOV
  end)
  
  print("[SH][FOVChanger] Active - FOV: " .. Cfg.FOV.FOV)
end

function FOVModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  -- Restore original FOV
  pcall(function() Camera.FieldOfView = self.OriginalFOV end)
  
  print("[SH][FOVChanger] Deactivated")
end

-- =====================================================
-- [MODULE 12] THIRD PERSON
-- =====================================================
local ThirdPersonModule = {
  Active = false,
  Connection = nil
}

function ThirdPersonModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][ThirdPerson] Starting...")
  
  -- Set camera subject
  local c = LP.Character
  if c then
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
      Camera.CameraSubject = h
    end
  end
  
  -- Re-apply on respawn
  LP.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if self.Active and Cfg.ThirdP.E then
      local h = c:FindFirstChildOfClass("Humanoid")
      if h then
        Camera.CameraSubject = h
      end
    end
  end)
  
  self.Connection = RenderStepped:Connect(function()
    if not Cfg.ThirdP.E or not self.Active then
      pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
      return
    end
    
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    
    -- Set camera distance
    LP.CameraMinZoomDistance = Cfg.ThirdP.Distance
    LP.CameraMaxZoomDistance = Cfg.ThirdP.Distance
    
    -- Force camera position if needed
    if Cfg.ThirdP.SmoothTransition then
      -- Smooth is handled by Roblox's built-in camera system
    end
  end)
  
  print("[SH][ThirdPerson] Active - Distance: " .. Cfg.ThirdP.Distance)
end

function ThirdPersonModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
  
  pcall(function()
    Camera.CameraType = Enum.CameraType.Custom
    LP.CameraMinZoomDistance = 0.5
    LP.CameraMaxZoomDistance = 128
  end)
  
  print("[SH][ThirdPerson] Deactivated")
end

-- =====================================================
-- [MODULE 13] ANTI-CHEAT BYPASS
-- =====================================================
local AntiCheatModule = {
  Active = false,
  Hooked = false,
  OldNamecall = nil,
  OldIndex = nil,
  OldNewIndex = nil,
  Connections = {}
}

function AntiCheatModule:Start()
  if self.Active then return end
  self.Active = true
  
  print("[SH][AntiCheat] Starting...")
  
  -- Suppress warn function
  if Cfg.AC.MuteWarn then
    warn = function() end
  end
  
  -- Hook __namecall to block destructive methods
  local mt = getmetatable and getmetatable(game)
  if mt and type(mt) == "table" then
    local old = mt.__namecall
    if old then
      self.OldNamecall = old
      mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod()
        if method then
          -- Block kick
          if Cfg.AC.BlockKick and method == "Kick" then
            return
          end
          -- Block remove/destroy
          if Cfg.AC.BlockRemove and (method == "Remove" or method == "Destroy") then
            -- Allow if it's our own objects
            return
          end
          -- Block teleport
          if Cfg.AC.BlockTeleport and method == "Teleport" then
            return
          end
        end
        return old(self, ...)
      end)
      self.Hooked = true
    end
  end
  
  -- Block RemoteEvents that detect exploits
  self.Connections.RemoteBlock = RenderStepped:Connect(function()
    if not self.Active or not Cfg.AC.E then return end
    
    -- Scan for detection remotes and block them
    for _, v in ipairs(Players:GetDescendants()) do
      if v:IsA("RemoteEvent") then
        local name = v.Name:lower()
        -- Common anti-cheat remote names
        if name:find("detect") or name:find("anticheat") or name:find("anti.cheat") or
           name:find("checksum") or name:find("integrity") or name:find("validation") or
           name:find("security") or name:find("exploit") or name:find("bypass") or
           name:find("kick") or name:find("ban") or name:find("report") then
          -- Disconnect all connections to this remote
          pcall(function()
            v:FireServer = function() end
          end)
        end
      end
    end
  end)
  
  -- Hook __index to hide exploit indicators
  local mt2 = getrawmetatable and getrawmetatable(game)
  if mt2 and type(mt2) == "table" then
    self.OldIndex = mt2.__index
    mt2.__index = newcclosure(function(t, k)
      if type(k) == "string" then
        -- Hide things that check for exploits
        if k:lower():find("exploit") or k:lower():find("cheat") then
          return nil
        end
      end
      return self.OldIndex and self.OldIndex(t, k) or nil
    end)
  end
  
  print("[SH][AntiCheat] Active - Namecall hooked: " .. tostring(self.Hooked))
end

function AntiCheatModule:Stop()
  if not self.Active then return end
  self.Active = false
  
  -- Restore namecall
  if self.Hooked and self.OldNamecall then
    local mt = getmetatable and getmetatable(game)
    if mt and type(mt) == "table" then
      mt.__namecall = self.OldNamecall
    end
    self.OldNamecall = nil
    self.Hooked = false
  end
  
  -- Restore index
  if self.OldIndex then
    local mt2 = getrawmetatable and getrawmetatable(game)
    if mt2 and type(mt2) == "table" then
      mt2.__index = self.OldIndex
    end
    self.OldIndex = nil
  end
  
  for _, conn in pairs(self.Connections) do
    pcall(function() conn:Disconnect() end)
  end
  self.Connections = {}
  
  print("[SH][AntiCheat] Deactivated")
end

-- =====================================================
-- [SECTION 4] MODULE REGISTRY & MAIN CONTROLLER
-- =====================================================

local SoberHook = {
  Modules = {
    Aimbot = AimbotModule,
    Triggerbot = TriggerModule,
    ESP = ESPModule,
    Weapon = WeaponModule,
    Movement = MovementModule,
    Wallhack = WallhackModule,
    AntiAim = AntiAimModule,
    Automation = AutomationModule,
    Spammer = SpammerModule,
    Crosshair = CrosshairModule,
    FOV = FOVModule,
    ThirdPerson = ThirdPersonModule,
    AntiCheat = AntiCheatModule
  },
  Running = {},
  InitTime = os.time()
}

function SoberHook:StartModule(name)
  local mod = self.Modules[name]
  if not mod then
    warn("[SH][ERROR] Unknown module: " .. name)
    return
  end
  if self.Running[name] then
    -- Already running, skip
    return
  end
  pcall(function()
    mod:Start()
    self.Running[name] = true
    print("[SH][+] " .. name .. " started")
  end)
end

function SoberHook:StopModule(name)
  local mod = self.Modules[name]
  if not mod then return end
  if not self.Running[name] then return end
  pcall(function()
    mod:Stop()
    self.Running[name] = false
    print("[SH][-] " .. name .. " stopped")
  end)
end

function SoberHook:ToggleModule(name)
  if self.Running[name] then
    self:StopModule(name)
  else
    self:StartModule(name)
  end
end

function SoberHook:StartAll()
  print("[SH] Starting all enabled modules...")
  for name, mod in pairs(self.Modules) do
    self:StartModule(name)
    task.wait(0.02)
  end
  print("[SH] All modules initialized")
end

function SoberHook:StopAll()
  print("[SH] Stopping all modules...")
  for name in pairs(self.Running) do
    self:StopModule(name)
  end
  print("[SH] All modules stopped")
end

function SoberHook:RestartModule(name)
  self:StopModule(name)
  task.wait(0.1)
  self:StartModule(name)
end

function SoberHook:GetStatus()
  local status = {}
  for name, running in pairs(self.Running) do
    status[name] = running
  end
  return status
end

function SoberHook:GetUptime()
  return os.time() - self.InitTime
end

-- =====================================================
-- [SECTION 5] CONFIG WATCHER — Auto-toggle modules
-- =====================================================

local ConfigWatcher = {
  Active = false,
  Connection = nil,
  Previous = {}
}

function ConfigWatcher:Start()
  if self.Active then return end
  self.Active = true
  
  -- Store initial config state
  self:Snapshot()
  
  self.Connection = Heartbeat:Connect(function()
    if not self.Active then return end
    self:CheckChanges()
  end)
end

function ConfigWatcher:Snapshot()
  for catName, cat in pairs(Cfg) do
    if type(cat) == "table" and cat.E ~= nil then
      self.Previous[catName] = cat.E
    end
  end
end

function ConfigWatcher:CheckChanges()
  for catName, cat in pairs(Cfg) do
    if type(cat) == "table" and cat.E ~= nil then
      local prev = self.Previous[catName]
      if prev ~= nil and prev ~= cat.E then
        -- Config changed, toggle corresponding module
        local moduleMap = {
          Aimbot = "Aimbot",
          Trigger = "Triggerbot",
          ESP = "ESP",
          Weapon = "Weapon",
          Speed = "Movement",
          Fly = "Movement",
          InfJump = "Movement",
          BunnyHop = "Movement",
          Noclip = "Movement",
          Wallhack = "Wallhack",
          AntiAim = "AntiAim",
          AutoFarm = "Automation",
          AutoHeal = "Automation",
          AutoBlock = "Automation",
          Loadout = "Automation",
          Spammer = "Spammer",
          Crosshair = "Crosshair",
          FOV = "FOV",
          ThirdP = "ThirdPerson",
          AC = "AntiCheat"
        }
        local moduleName = moduleMap[catName]
        if moduleName then
          if cat.E then
            SoberHook:StartModule(moduleName)
          else
            SoberHook:StopModule(moduleName)
          end
        end
        self.Previous[catName] = cat.E
      end
    end
  end
end

function ConfigWatcher:Stop()
  self.Active = false
  if self.Connection then
    self.Connection:Disconnect()
    self.Connection = nil
  end
end

-- =====================================================
-- [SECTION 6] GUI SETUP & BINDING
-- =====================================================

function SetupGUI()
  print("[SH][GUI] Setting up menu...")
  
  local gui = getgenv().SoberGUI
  
  if not gui then
    warn("[SH][GUI] GUI system not initialized!")
    return
  end
  
  -- Add Tabs
  gui:AddTab("Aimbot")
  gui:AddTab("Visuals")
  gui:AddTab("Movement")
  gui:AddTab("Weapons")
  gui:AddTab("Automation")
  gui:AddTab("Misc")
  gui:AddTab("Settings")
  
  ---- TAB 1: AIMBOT ----
  gui:AddLabel("Aimbot", "Aim Assist", "--- Aim Assist Settings ---", gui.Colors.Accent)
  gui:AddToggle("Aimbot", "Aim Assist", "Enable Aimbot", "Aimbot.E", Cfg.Aimbot.E)
  gui:AddDropdown("Aimbot", "Aim Assist", "Method", "Aimbot.Method", {"SilentAim", "CFrame"}, Cfg.Aimbot.Method)
  gui:AddSlider("Aimbot", "Aim Assist", "FOV (degrees)", "Aimbot.FOV", 10, 360, Cfg.Aimbot.FOV, "%.0f")
  gui:AddSlider("Aimbot", "Aim Assist", "Smoothing", "Aimbot.Smooth", 0, 1, Cfg.Aimbot.Smooth, "%.2f")
  gui:AddSlider("Aimbot", "Aim Assist", "Prediction", "Aimbot.Pred", 0, 1, Cfg.Aimbot.Pred, "%.2f")
  gui:AddToggle("Aimbot", "Aim Assist", "Visibility Check", "Aimbot.VisCheck", Cfg.Aimbot.VisCheck)
  gui:AddToggle("Aimbot", "Aim Assist", "Team Check", "Aimbot.TeamCheck", Cfg.Aimbot.TeamCheck)
  
  gui:AddLabel("Aimbot", "Triggerbot", "--- Triggerbot ---", gui.Colors.Accent)
  gui:AddToggle("Aimbot", "Triggerbot", "Enable Triggerbot", "Trigger.E", Cfg.Trigger.E)
  gui:AddSlider("Aimbot", "Triggerbot", "Delay (ms)", "Trigger.Delay", 0, 500, Cfg.Trigger.Delay * 1000, "%.0f")
  gui:AddSlider("Aimbot", "Triggerbot", "Range", "Trigger.Range", 50, 1000, Cfg.Trigger.Range, "%.0f")
  
  ---- TAB 2: VISUALS ----
  gui:AddLabel("Visuals", "ESP", "--- ESP Settings ---", gui.Colors.Accent)
  gui:AddToggle("Visuals", "ESP", "Enable ESP", "ESP.E", Cfg.ESP.E)
  gui:AddToggle("Visuals", "ESP", "Boxes", "ESP.Boxes", Cfg.ESP.Boxes)
  gui:AddToggle("Visuals", "ESP", "Box Outline", "ESP.BoxOutline", Cfg.ESP.BoxOutline)
  gui:AddToggle("Visuals", "ESP", "Health Bars", "ESP.HealthBars", Cfg.ESP.HealthBars)
  gui:AddToggle("Visuals", "ESP", "Health Text", "ESP.HealthText", Cfg.ESP.HealthText)
  gui:AddToggle("Visuals", "ESP", "Names", "ESP.Names", Cfg.ESP.Names)
  gui:AddToggle("Visuals", "ESP", "Distance", "ESP.Distance", Cfg.ESP.Distance)
  gui:AddToggle("Visuals", "ESP", "Weapon", "ESP.Weapon", Cfg.ESP.Weapon)
  gui:AddToggle("Visuals", "ESP", "Tracers", "ESP.Tracers", Cfg.ESP.Tracers)
  gui:AddDropdown("Visuals", "ESP", "Tracer From", "ESP.TracerFrom", {"Bottom", "Center"}, Cfg.ESP.TracerFrom)
  gui:AddSlider("Visuals", "ESP", "Max Distance", "ESP.MaxDist", 100, 10000, Cfg.ESP.MaxDist, "%.0f")
  gui:AddToggle("Visuals", "ESP", "Team Check", "ESP.TeamCheck", Cfg.ESP.TeamCheck)
  gui:AddToggle("Visuals", "ESP", "Team Color", "ESP.UseTeamColor", Cfg.ESP.UseTeamColor)
  
  gui:AddLabel("Visuals", "Crosshair", "--- Custom Crosshair ---", gui.Colors.Accent)
  gui:AddToggle("Visuals", "Crosshair", "Enable Crosshair", "Crosshair.E", Cfg.Crosshair.E)
  gui:AddDropdown("Visuals", "Crosshair", "Style", "Crosshair.Style", {"Dot", "Cross", "Circle", "Plus", "T", "Triangle"}, Cfg.Crosshair.Style)
  gui:AddSlider("Visuals", "Crosshair", "Size", "Crosshair.Size", 2, 50, Cfg.Crosshair.Size, "%.0f")
  gui:AddSlider("Visuals", "Crosshair", "Thickness", "Crosshair.Thickness", 1, 5, Cfg.Crosshair.Thickness, "%.0f")
  gui:AddToggle("Visuals", "Crosshair", "Outline", "Crosshair.Outline", Cfg.Crosshair.Outline)
  
  gui:AddLabel("Visuals", "Wallhack", "--- Wallhack ---", gui.Colors.Accent)
  gui:AddToggle("Visuals", "Wallhack", "Enable Wallhack", "Wallhack.E", Cfg.Wallhack.E)
  gui:AddSlider("Visuals", "Wallhack", "Transparency", "Wallhack.Transparency", 0, 1, Cfg.Wallhack.Transparency, "%.2f")
  
  gui:AddLabel("Visuals", "Camera", "--- Camera ---", gui.Colors.Accent)
  gui:AddToggle("Visuals", "Camera", "FOV Changer", "FOV.E", Cfg.FOV.E)
  gui:AddSlider("Visuals", "Camera", "FOV Value", "FOV.FOV", 20, 180, Cfg.FOV.FOV, "%.0f")
  gui:AddToggle("Visuals", "Camera", "Third Person", "ThirdP.E", Cfg.ThirdP.E)
  gui:AddSlider("Visuals", "Camera", "Third Person Distance", "ThirdP.Dist", 3, 50, Cfg.ThirdP.Distance, "%.0f")
  
  ---- TAB 3: MOVEMENT ----
  gui:AddLabel("Movement", "Speed", "--- Speed Hack ---", gui.Colors.Accent)
  gui:AddToggle("Movement", "Speed", "Speed Hack", "Speed.E", Cfg.Speed.E)
  gui:AddSlider("Movement", "Speed", "Speed Value", "Speed.Speed", 16, 250, Cfg.Speed.Speed, "%.0f")
  
  gui:AddLabel("Movement", "Fly", "--- Fly Hack ---", gui.Colors.Accent)
  gui:AddToggle("Movement", "Fly", "Fly Hack", "Fly.E", Cfg.Fly.E)
  gui:AddSlider("Movement", "Fly", "Fly Speed", "Fly.Speed", 10, 200, Cfg.Fly.Speed, "%.0f")
  
  gui:AddLabel("Movement", "Jumps", "--- Jumps ---", gui.Colors.Accent)
  gui:AddToggle("Movement", "Jumps", "Infinite Jump", "InfJump.E", Cfg.InfJump.E)
  gui:AddToggle("Movement", "Jumps", "Bunny Hop", "BunnyHop.E", Cfg.BunnyHop.E)
  
  gui:AddLabel("Movement", "Other", "--- Other ---", gui.Colors.Accent)
  gui:AddToggle("Movement", "Other", "Noclip", "Noclip.E", Cfg.Noclip.E)
  
  ---- TAB 4: WEAPONS ----
  gui:AddLabel("Weapons", "Mods", "--- Weapon Modifications ---", gui.Colors.Accent)
  gui:AddToggle("Weapons", "Mods", "Enable Weapon Mods", "Weapon.E", Cfg.Weapon.E)
  gui:AddToggle("Weapons", "Mods", "No Recoil", "Weapon.NoRecoil", Cfg.Weapon.NoRecoil)
  gui:AddToggle("Weapons", "Mods", "No Spread", "Weapon.NoSpread", Cfg.Weapon.NoSpread)
  gui:AddToggle("Weapons", "Mods", "Infinite Ammo", "Weapon.InfAmmo", Cfg.Weapon.InfAmmo)
  gui:AddToggle("Weapons", "Mods", "Instant Reload", "Weapon.InstReload", Cfg.Weapon.InstReload)
  gui:AddToggle("Weapons", "Mods", "Infinite Damage", "Weapon.InfDmg", Cfg.Weapon.InfDmg)
  gui:AddSlider("Weapons", "Mods", "Damage Multiplier", "Weapon.DmgMult", 1, 100, Cfg.Weapon.DmgMult, "%.1f")
  
  gui:AddLabel("Weapons", "AntiAim", "--- Anti-Aim ---", gui.Colors.Accent)
  gui:AddToggle("Weapons", "AntiAim", "Enable Anti-Aim", "AntiAim.E", Cfg.AntiAim.E)
  gui:AddDropdown("Weapons", "AntiAim", "Mode", "AntiAim.Mode", {"Spin", "SpinSlow", "SpinFast", "Jitter", "Backwards", "Down", "Up", "Random", "Lisp"}, Cfg.AntiAim.Mode)
  
  ---- TAB 5: AUTOMATION ----
  gui:AddLabel("Automation", "Farm", "--- Auto Farm ---", gui.Colors.Accent)
  gui:AddToggle("Automation", "Farm", "Auto Farm", "AutoFarm.E", Cfg.AutoFarm.E)
  gui:AddDropdown("Automation", "Farm", "Method", "AutoFarm.Method", {"Collect", "Click", "Proximity", "Kill"}, Cfg.AutoFarm.Method)
  gui:AddSlider("Automation", "Farm", "Radius", "AutoFarm.Rad", 10, 200, Cfg.AutoFarm.Radius, "%.0f")
  
  gui:AddLabel("Automation", "Heal", "--- Auto Heal ---", gui.Colors.Accent)
  gui:AddToggle("Automation", "Heal", "Auto Heal", "AutoHeal.E", Cfg.AutoHeal.E)
  gui:AddSlider("Automation", "Heal", "Health Threshold %", "AutoHeal.Thresh", 5, 100, Cfg.AutoHeal.Threshold, "%.0f")
  
  gui:AddLabel("Automation", "Block", "--- Auto Block ---", gui.Colors.Accent)
  gui:AddToggle("Automation", "Block", "Auto Block", "AutoBlock.E", Cfg.AutoBlock.E)
  gui:AddDropdown("Automation", "Block", "Mode", "AutoBlock.Mode", {"Always", "OnDamage"}, Cfg.AutoBlock.Mode)
  
  gui:AddLabel("Automation", "Loadout", "--- Auto Loadout ---", gui.Colors.Accent)
  gui:AddToggle("Automation", "Loadout", "Auto Loadout", "Loadout.E", Cfg.Loadout.E)
  
  ---- TAB 6: MISC ----
  gui:AddLabel("Misc", "Chat", "--- Chat Spammer ---", gui.Colors.Accent)
  gui:AddToggle("Misc", "Chat", "Chat Spammer", "Spammer.E", Cfg.Spammer.E)
  gui:AddSlider("Misc", "Chat", "Interval (s)", "Spammer.Int", 1, 60, Cfg.Spammer.Interval, "%.0f")
  gui:AddToggle("Misc", "Chat", "Random Order", "Spammer.RandomOrder", Cfg.Spammer.RandomOrder)
  
  gui:AddLabel("Misc", "AntiCheat", "--- Anti-Cheat Bypass ---", gui.Colors.Accent)
  gui:AddToggle("Misc", "AntiCheat", "Enable Bypass", "AC.E", Cfg.AC.E)
  gui:AddToggle("Misc", "AntiCheat", "Block Kick", "AC.BlockKick", Cfg.AC.BlockKick)
  gui:AddToggle("Misc", "AntiCheat", "Block Teleport", "AC.BlockTeleport", Cfg.AC.BlockTeleport)
  gui:AddToggle("Misc", "AntiCheat", "Block Remove/Destroy", "AC.BlockRemove", Cfg.AC.BlockRemove)
  gui:AddToggle("Misc", "AntiCheat", "Mute Warnings", "AC.MuteWarn", Cfg.AC.MuteWarn)
  
  ---- TAB 7: SETTINGS ----
  gui:AddLabel("Settings", "Info", "--- SoberHook v4.0 ---", gui.Colors.Accent)
  gui:AddButton("Settings", "Info", "Start All Modules", function()
    SoberHook:StartAll()
  end)
  gui:AddButton("Settings", "Info", "Stop All Modules", function()
    SoberHook:StopAll()
  end)
  gui:AddButton("Settings", "Info", "Restart All Modules", function()
    SoberHook:StopAll()
    task.wait(0.3)
    SoberHook:StartAll()
  end)
  gui:AddButton("Settings", "Info", "Print Config", function()
    print("=== SoberHook Config ===")
    for k, v in pairs(Cfg) do
      if type(v) == "table" then
        print("  " .. k .. ": E=" .. tostring(v.E))
      end
    end
  end)
  gui:AddLabel("Settings", "Info", "Press RIGHT SHIFT to toggle this menu", gui.Colors.Text)
  
  gui:Start()
  print("[SH][GUI] Setup complete!")
end

-- =====================================================
-- [SECTION 7] MAIN ENTRY POINT
-- =====================================================

print("=== SoberHook v4.0 Loading ===")
print("[SH] Initializing on Game: " .. GameId .. " | Place: " .. PlaceId)

-- Start config watcher
ConfigWatcher:Start()

-- Start anti-cheat by default
if Cfg.AC.E then
  SoberHook:StartModule("AntiCheat")
end

-- Start auto-enabled modules based on config
for catName, cat in pairs(Cfg) do
  if type(cat) == "table" and cat.E then
    local autoStartMap = {
      Aimbot = "Aimbot",
      Trigger = "Triggerbot",
      ESP = "ESP",
      Weapon = "Weapon",
      Speed = "Movement",
      Fly = "Movement",
      InfJump = "Movement",
      BunnyHop = "Movement",
      Noclip = "Movement",
      Wallhack = "Wallhack",
      AntiAim = "AntiAim",
      AutoFarm = "Automation",
      AutoHeal = "Automation",
      AutoBlock = "Automation",
      Loadout = "Automation",
      Spammer = "Spammer",
      Crosshair = "Crosshair",
      FOV = "FOV",
      ThirdP = "ThirdPerson"
    }
    local modName = autoStartMap[catName]
    if modName and not SoberHook.Running[modName] then
      SoberHook:StartModule(modName)
    end
  end
end

-- Setup GUI
task.spawn(function()
  task.wait(1)
  --[COM] SetupGUI()
end)

-- Status indicator
local statusConn = Heartbeat:Connect(function()
  if not SoberHook.Running then return end
  local count = 0
  for _ in pairs(SoberHook.Running) do count = count + 1 end
end)

print("=== SoberHook v4.0 Loaded ===")
print("[SH] " .. #SoberHook.Modules .. " modules registered")
print("[SH] " .. tostring(#SoberHook.Running) .. " modules currently active")
print("[SH] Press RIGHT SHIFT to toggle the GUI menu")
-- [HOTFIX] WORKING TOGGLE GUI - Press RightShift to toggle
-- Cleanup old GUI Drawing objects
if _G.SoberGUI_Elements then for _,o in ipairs(_G.SoberGUI_Elements) do pcall(function() o:Remove() end) end end
if _G.SoberGUI and _G.SoberGUI.Main then for _,o in pairs(_G.SoberGUI.Main) do
  if type(o)=='table' then for _,oo in pairs(o) do if type(oo)=='userdata' then pcall(function() oo:Remove() end) end end
  elseif type(o)=='userdata' then pcall(function() o:Remove() end) end end end
local WG={}
WG.Visible=false
WG.X,WG.Y=50,50
WG.W,WG.H=520,420
WG.CurTab='Aimbot'
WG.Tabs={'Aimbot','Visuals','Movement','Weapons','Auto','Misc','Settings'}
WG.Dragging=false
WG.DragOffX,WG.DragOffY=0,0
WG.Elements={}
WG.Colors={BG=Color3.fromRGB(20,20,20),Primary=Color3.fromRGB(35,35,35),Accent=Color3.fromRGB(0,120,255),Text=Color3.fromRGB(220,220,220),Dim=Color3.fromRGB(140,140,140),Green=Color3.fromRGB(60,180,60),Red=Color3.fromRGB(220,50,50)}
_G.SoberGUI_Elements={}
function WG:New(typ,props)
  local o=Drawing.new(typ)
  for k,v in pairs(props or {}) do o[k]=v end
  table.insert(_G.SoberGUI_Elements,o)
  return o
end

function WG:Draw()
  if not self.Visible then
    for _,o in ipairs(_G.SoberGUI_Elements) do pcall(function() o.Visible=false end) end
    return
  end
  for _,o in ipairs(_G.SoberGUI_Elements) do pcall(function() o:Remove() end) end
  _G.SoberGUI_Elements={}
  local x,y,w,h=self.X,self.Y,self.W,self.H
  self:New('Square',{Size=Vector2.new(w,h),Position=Vector2.new(x,y),Color=self.Colors.BG,Filled=true,Thickness=0,Visible=true})
  self:New('Square',{Size=Vector2.new(w+2,h+2),Position=Vector2.new(x-1,y-1),Color=self.Colors.Accent,Filled=false,Thickness=1,Visible=true})
  self:New('Square',{Size=Vector2.new(w,25),Position=Vector2.new(x,y),Color=self.Colors.Primary,Filled=true,Visible=true})
  self:New('Text',{Text='SoberHook v4.0  [RightShift Toggle]',Position=Vector2.new(x+6,y+3),Color=self.Colors.Accent,Size=14,Outline=true,Visible=true})
  self:New('Square',{Size=Vector2.new(18,18),Position=Vector2.new(x+w-22,y+4),Color=self.Colors.Red,Filled=true,Visible=true})
  self:New('Text',{Text='X',Position=Vector2.new(x+w-17,y+3),Color=Color3.fromRGB(255,255,255),Size=13,Visible=true})
  local tw=(w-8)/#self.Tabs
  self:New('Square',{Size=Vector2.new(w-8,24),Position=Vector2.new(x+4,y+27),Color=self.Colors.Primary,Filled=true,Visible=true})
  for i,tn in ipairs(self.Tabs) do
    local tx=x+4+(i-1)*tw;local act=tn==self.CurTab
    self:New('Square',{Size=Vector2.new(tw-2,22),Position=Vector2.new(tx+1,y+28),Color=act and self.Colors.Accent or self.Colors.Primary,Filled=true,Visible=true})
    self:New('Text',{Text=tn,Position=Vector2.new(tx+6,y+29),Color=act and Color3.fromRGB(255,255,255) or self.Colors.Text,Size=13,Visible=true})
  end
  self:New('Square',{Size=Vector2.new(w-8,h-58),Position=Vector2.new(x+4,y+54),Color=self.Colors.BG,Filled=true,Visible=true})
  local ey=y+58;local ew=w-16;local sec=self.Elements[self.CurTab] or {}
  for _,e in ipairs(sec) do
    if ey>y+h-30 then break end
    if e.T=='L' then
      self:New('Text',{Text=e.Txt,Position=Vector2.new(x+10,ey),Color=e.Clr or self.Colors.Dim,Size=13,Outline=true,Visible=true})
      ey=ey+20
    elseif e.T=='T' then
      self:New('Square',{Size=Vector2.new(ew,22),Position=Vector2.new(x+8,ey),Color=self.Colors.Primary,Filled=true,Visible=true})
      self:New('Square',{Size=Vector2.new(14,14),Position=Vector2.new(x+ew-6,ey+4),Color=e.Val and self.Colors.Green or self.Colors.Red,Filled=true,Visible=true})
      self:New('Text',{Text=e.Lbl,Position=Vector2.new(x+14,ey+2),Color=self.Colors.Text,Size=13,Visible=true})
      self:New('Text',{Text=e.Val and 'ON' or 'OFF',Position=Vector2.new(x+ew-24,ey+2),Color=e.Val and self.Colors.Green or self.Colors.Red,Size=11,Visible=true})
      ey=ey+24
    elseif e.T=='S' then
      self:New('Square',{Size=Vector2.new(ew,22),Position=Vector2.new(x+8,ey),Color=self.Colors.Primary,Filled=true,Visible=true})
      local fw=math.max(0,(e.Val-e.Min)/(e.Max-e.Min)*(ew-80))
      self:New('Square',{Size=Vector2.new(ew-80,6),Position=Vector2.new(x+12,ey+8),Color=self.Colors.BG,Filled=true,Visible=true})
      self:New('Square',{Size=Vector2.new(fw,6),Position=Vector2.new(x+12,ey+8),Color=self.Colors.Accent,Filled=true,Visible=true})
      self:New('Text',{Text=e.Lbl..': '..string.format('%.1f',e.Val),Position=Vector2.new(x+14,ey+2),Color=self.Colors.Text,Size=12,Visible=true})
      ey=ey+24
    elseif e.T=='B' then
      self:New('Square',{Size=Vector2.new(ew-40,22),Position=Vector2.new(x+24,ey),Color=self.Colors.Accent,Filled=true,Visible=true})
      self:New('Text',{Text=e.Lbl,Position=Vector2.new(x+28,ey+2),Color=Color3.fromRGB(255,255,255),Size=13,Visible=true})
      ey=ey+24
    end
  end
  self:New('Square',{Size=Vector2.new(w,16),Position=Vector2.new(x,y+h-16),Color=self.Colors.Primary,Filled=true,Visible=true})
  self:New('Text',{Text='Ready | Tab: '..self.CurTab,Position=Vector2.new(x+6,y+h-14),Color=self.Colors.Dim,Size=11,Visible=true})
end

function WG:Label(tab,txt,clr)
  if not self.Elements[tab] then self.Elements[tab]={} end
  table.insert(self.Elements[tab],{T='L',Txt=txt,Clr=clr or self.Colors.Dim})
end
function WG:Toggle(tab,lbl,path)
  if not self.Elements[tab] then self.Elements[tab]={} end
  local parts={};for s in string.gmatch(path,'[%w_]+') do table.insert(parts,s) end
  local val=false
  if #parts>=2 and Cfg[parts[1]] then val=Cfg[parts[1]][parts[2]] or false end
  table.insert(self.Elements[tab],{T='T',Lbl=lbl,Path=path,Parts=parts,Val=val})
end
function WG:Slider(tab,lbl,path,mn,mx,def)
  if not self.Elements[tab] then self.Elements[tab]={} end
  local parts={};for s in string.gmatch(path,'[%w_]+') do table.insert(parts,s) end
  local val=def
  if #parts>=2 and Cfg[parts[1]] then val=Cfg[parts[1]][parts[2]] or def end
  table.insert(self.Elements[tab],{T='S',Lbl=lbl,Path=path,Parts=parts,Min=mn or 0,Max=mx or 100,Val=val})
end
function WG:Button(tab,lbl,cb)
  if not self.Elements[tab] then self.Elements[tab]={} end
  table.insert(self.Elements[tab],{T='B',Lbl=lbl,CB=cb or function() end})
end
function WG:SetVar(parts,val)
  if #parts>=2 and Cfg[parts[1]] then Cfg[parts[1]][parts[2]]=val end
end
function WG:GetVar(parts)
  if #parts>=2 and Cfg[parts[1]] then return Cfg[parts[1]][parts[2]] end
  return nil
end
function WG:Click(mx,my)
  if not self.Visible then return false end
  local x,y,w,h=self.X,self.Y,self.W,self.H
  if mx>=x+w-22 and mx<=x+w-4 and my>=y+4 and my<=y+22 then self.Visible=false;return true end
  if mx>=x and mx<=x+w and my>=y and my<=y+25 then self.Dragging=true;self.DragOffX=mx-x;self.DragOffY=my-y;return true end
  local tw=(w-8)/#self.Tabs
  for i,tn in ipairs(self.Tabs) do
    local tx=x+4+(i-1)*tw
    if mx>=tx+1 and mx<=tx+tw-1 and my>=y+28 and my<=y+50 then self.CurTab=tn;return true end
  end
  local ey=y+58;local ew=w-16;local sec=self.Elements[self.CurTab] or {}
  for _,e in ipairs(sec) do
    if ey>y+h-30 then break end
    if e.T=='T' then
      if mx>=x+8 and mx<=x+8+ew and my>=ey and my<=ey+22 then
        e.Val=not e.Val;self:SetVar(e.Parts,e.Val);local mp={Aimbot="Aimbot",Trigger="Triggerbot",ESP="ESP",Weapon="Weapon",Speed="Movement",Fly="Movement",InfJump="Movement",BHop="Movement",Noclip="Movement",Wallhack="Wallhack",AntiAim="AntiAim",AutoFarm="Automation",AutoHeal="Automation",AutoBlock="Automation",Loadout="Automation",Spammer="Spammer",Crosshair="Crosshair",FOV="FOV",ThirdP="ThirdPerson",Crosshair="Crosshair"};local mn=mp[e.Parts[1]];if mn and SoberHook then if e.Val then pcall(SoberHook.StartModule,SoberHook,mn)else pcall(SoberHook.StopModule,SoberHook,mn)end end
        return true
      end
    elseif e.T=='S' then
      if mx>=x+8 and mx<=x+8+ew and my>=ey and my<=ey+22 then
        local rx=mx-(x+12);local tw2=ew-80
        if tw2>0 then local r=math.min(math.max(rx/tw2,0),1);e.Val=e.Min+(e.Max-e.Min)*r;self:SetVar(e.Parts,e.Val) end
        return true
      end
    elseif e.T=='B' then
      if mx>=x+24 and mx<=x+24+ew-40 and my>=ey and my<=ey+22 then task.spawn(e.CB);return true end
    end
    ey=ey+24
  end
  return false
end
function WG:ToggleVis()
  self.Visible=not self.Visible
  if not self.Visible then for _,o in ipairs(_G.SoberGUI_Elements) do pcall(function() o.Visible=false end) end end
end

WG:Label('Aimbot','--- Aim Assist ---',WG.Colors.Accent)
WG:Toggle('Aimbot','Aimbot','Aimbot.E')
WG:Slider('Aimbot','FOV','Aimbot.FOV',10,360,120)
WG:Slider('Aimbot','Smooth','Aimbot.Smooth',0,1,0.5)
WG:Slider('Aimbot','Predict','Aimbot.Pred',0,1,0.35)
WG:Label('Aimbot','--- Triggerbot ---',WG.Colors.Accent)
WG:Toggle('Aimbot','Triggerbot','Trigger.E')
WG:Label('Visuals','--- ESP ---',WG.Colors.Accent)
WG:Toggle('Visuals','ESP','ESP.E')
WG:Toggle('Visuals','Names','ESP.Names')
WG:Toggle('Visuals','Distance','ESP.Dist')
WG:Toggle('Visuals','Weapon','ESP.Weapon')
WG:Label('Visuals','--- Crosshair ---',WG.Colors.Accent)
WG:Toggle('Visuals','Crosshair','Crosshair.E')
WG:Label('Visuals','--- Wallhack ---',WG.Colors.Accent)
WG:Toggle('Visuals','Wallhack','Wallhack.E')
WG:Label('Visuals','--- Camera ---',WG.Colors.Accent)
WG:Toggle('Visuals','FOV Changer','FOV.E')
WG:Slider('Visuals','FOV Value','FOV.FOV',20,180,90)
WG:Toggle('Visuals','Third Person','ThirdP.E')
WG:Slider('Visuals','3rd Dist','ThirdP.Dist',3,30,10)
WG:Label('Movement','--- Speed ---',WG.Colors.Accent)
WG:Toggle('Movement','Speed Hack','Speed.E')
WG:Slider('Movement','Speed','Speed.Speed',16,250,32)
WG:Label('Movement','--- Fly ---',WG.Colors.Accent)
WG:Toggle('Movement','Fly Hack','Fly.E')
WG:Slider('Movement','Fly Speed','Fly.Speed',10,200,50)
WG:Toggle('Movement','Infinite Jump','InfJump.E')
WG:Toggle('Movement','Bunny Hop','BHop.E')
WG:Toggle('Movement','Noclip','Noclip.E')
WG:Label('Weapons','--- Weapon Mods ---',WG.Colors.Accent)
WG:Toggle('Weapons','Weapon Mods','Weapon.E')
WG:Toggle('Weapons','No Recoil','Weapon.NoRecoil')
WG:Toggle('Weapons','No Spread','Weapon.NoSpread')
WG:Toggle('Weapons','Inf Ammo','Weapon.InfAmmo')
WG:Toggle('Weapons','Inst Reload','Weapon.InstReload')
WG:Label('Weapons','--- Anti-Aim ---',WG.Colors.Accent)
WG:Toggle('Weapons','Anti-Aim','AntiAim.E')
WG:Label('Auto','--- Auto Farm ---',WG.Colors.Accent)
WG:Toggle('Auto','Auto Farm','AutoFarm.E')
WG:Label('Auto','--- Auto Heal ---',WG.Colors.Accent)
WG:Toggle('Auto','Auto Heal','AutoHeal.E')
WG:Label('Auto','--- Auto Block ---',WG.Colors.Accent)
WG:Toggle('Auto','Auto Block','AutoBlock.E')
WG:Label('Auto','--- Auto Loadout ---',WG.Colors.Accent)
WG:Toggle('Auto','Auto Loadout','Loadout.E')
WG:Label('Misc','--- Chat Spammer ---',WG.Colors.Accent)
WG:Toggle('Misc','Chat Spammer','Spammer.E')
WG:Slider('Misc','Interval','Spammer.Int',1,60,5)
WG:Label('Settings','--- Controls ---',WG.Colors.Accent)
WG:Button('Settings','Enable All',function() for k,v in pairs(Cfg) do if type(v)=='table' and v.E~=nil then v.E=true end end print('[SH] All enabled') end)
WG:Button('Settings','Disable All',function() for k,v in pairs(Cfg) do if type(v)=='table' and v.E~=nil then v.E=false end end print('[SH] All disabled') end)
WG:Button('Settings','Sync Toggles',function()
  for tn,sec in pairs(WG.Elements) do
    for _,e in ipairs(sec) do
      if e.T=='T' then e.Val=WG:GetVar(e.Parts) or false end
      if e.T=='S' then local v=WG:GetVar(e.Parts);if v~=nil then e.Val=v end end
    end
  end
  print('[SH] Toggles synced')
end)

local uis = game:GetService("UserInputService")
uis.InputBegan:Connect(function(input,gp)
  if gp then return end
  if input.KeyCode==Enum.KeyCode.RightShift then WG:ToggleVis();return end
  if input.UserInputType==Enum.UserInputType.MouseButton1 then WG:Click(mouse.X,mouse.Y) end
end)
uis.InputChanged:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseMovement and WG.Dragging then
    WG.X=mouse.X-WG.DragOffX;WG.Y=mouse.Y-WG.DragOffY
  end
end)
uis.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 then WG.Dragging=false end
end)
task.spawn(function()
  while task.wait() do WG:Draw() end
end)
_G.SoberGUI=WG
print('[HOTFIX] Working GUI installed. Press RightShift to toggle.')
print('=== SoberHook v4.0 Ready ===')
