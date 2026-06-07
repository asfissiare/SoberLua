--[[ SoberHook v3.0 - Roblox Universal Script ]]
-- Config
local Cfg = {
  Aimbot={E=true,M="SilentAim",FOV=120,Smooth=0.5,Pred=0.35,Parts={"Head","Torso"},Key="MouseButton2",Vis=false},
  Trigger={E=true,Delay=0.05,Range=250,Key="MouseButton1"},
  ESP={E=true,Boxes=true,HBars=true,Names=true,Dist=true,Weapon=true,Lines=false,MaxD=5000,Rate=0.1},
  Weapon={NoRecoil=true,NoSpread=true,InfAmmo=true,InstReload=true,InfDmg=false,DmgMult=1},
  Move={Spd={E=false,S=32},Fly={E=false,S=50},InfJ={E=false},BH={E=false},Noclip={E=false}},
  Wallhack={E=false,Trans=0.7},AntiAim={E=false,Mode="Spin"},
  AutoFarm={E=false,Meth="Collect",Rad=50},AutoHeal={E=false,Thresh=30,Item="MedKit"},
  AutoBlock={E=false,Mode="Always"},Spammer={E=false,Msg={"SoberHook!","gg"},Int=5},
  Crosshair={E=false,Style="Dot",Col=Color3.fromRGB(255,0,0),Size=10},
  FOV={E=false,FOV=90},ThirdP={E=false,Dist=10},
  Loadout={E=false,Guns={"AK47","M4A1","Sniper"}},AC={Safe=true},
}
-- Utility
local U={}
function U.Players()
  local p=game:GetService("Players")local l=p.LocalPlayer local r={}
  for _,v in ipairs(p:GetPlayers())do
    if v~=l and v.Character and v.Character:FindFirstChild("HumanoidRootPart")then
      table.insert(r,v)end end
  return r end
function U.HRP(p)local c=p and p.Character;return c and c:FindFirstChild("HumanoidRootPart")end
function U.Hum(p)local c=p and p.Character;return c and c:FindFirstChildOfClass("Humanoid")end
function U.Dist(a,b)return(a-b).Magnitude end
function U.W2S(pos)local pt,on=workspace.CurrentCamera:WorldToScreenPoint(pos)return Vector2.new(pt.X,pt.Y),on and pt.Z>0 end
function U.Closest()
  local m=game:GetService("Players").LocalPlayer:GetMouse()
  local cam=workspace.CurrentCamera;local B,BD=nil,Cfg.Aimbot.FOV
  for _,p in ipairs(U.Players())do
    local h=U.HRP(p)if h then
      local sp,on=U.W2S(h.Position)if on then
        local d=(m.X-sp.X)^2+(m.Y-sp.Y)^2
        local dd=math.deg(math.atan(math.sqrt(d)/cam.ViewportSize.Y*2))
        if dd<BD then B=p;BD=dd end end end end
  return B,BD end
function U.Pred(p,f)local h=U.HRP(p)if not h then return nil end;return h.Position+(h.Velocity or Vector3.new())*f end


-- 1) Aimbot
do if Cfg.Aimbot.E then
  if Cfg.Aimbot.M=="SilentAim" then
    local old=workspace.FindPartOnRayWithIgnoreList
    workspace.FindPartOnRayWithIgnoreList=function(...)
      local a={...}if not Cfg.Aimbot.E then return old(unpack(a))end
      local t=U.Closest()if t then
        local h=U.HRP(t)local hu=U.Hum(t)
        if h and hu and hu.Health>0 then
          local tp=h
          for _,n in ipairs(Cfg.Aimbot.Parts)do
            local part=t.Character:FindFirstChild(n)if part then tp=part;break end end
          a[2]=(tp.Position-a[1].Origin).Unit*9999 end end
      return old(unpack(a))end
  elseif Cfg.Aimbot.M=="AimLock" then
    game:GetService("RunService").RenderStepped:Connect(function()
      if not Cfg.Aimbot.E or Cfg.Aimbot.M~="AimLock"then return end
      local lp=game:GetService("Players").LocalPlayer
      local m=lp:GetMouse()
      if not m:IsButtonPressed(Enum.UserInputType[Cfg.Aimbot.Key])then return end
      local t=U.Closest()if t then
        local h=U.HRP(t)if h then
          local tp=h
          for _,n in ipairs(Cfg.Aimbot.Parts)do
            local part=t.Character:FindFirstChild(n)if part then tp=part;break end end
          workspace.CurrentCamera.CFrame=workspace.CurrentCamera.CFrame:Lerp(
            CFrame.lookAt(workspace.CurrentCamera.CFrame.Position,tp.Position),Cfg.Aimbot.Smooth)end end
    end)
  elseif Cfg.Aimbot.M=="Ragebot" then
    game:GetService("RunService").RenderStepped:Connect(function()
      if not Cfg.Aimbot.E or Cfg.Aimbot.M~="Ragebot"then return end
      local t=U.Closest()
      if t and U.Hum(t)and U.Hum(t).Health>0 then
        local h=U.HRP(t)if h then
          local tp=h
          for _,n in ipairs(Cfg.Aimbot.Parts)do
            local part=t.Character:FindFirstChild(n)if part then tp=part;break end end
          workspace.CurrentCamera.CFrame=CFrame.lookAt(workspace.CurrentCamera.CFrame.Position,tp.Position)
          mouse1click()end end
    end)end
  print("[SH] Aimbot")end end

-- 2) Triggerbot
do if Cfg.Trigger.E then
  game:GetService("RunService").RenderStepped:Connect(function()
    if not Cfg.Trigger.E then return end
    local lp=game:GetService("Players").LocalPlayer
    local m=lp:GetMouse()
    if not m:IsButtonPressed(Enum.UserInputType[Cfg.Trigger.Key])then return end
    local t=U.Closest()
    if t and U.Hum(t)and U.Hum(t).Health>0 then
      local h=U.HRP(t)local lh=U.HRP(lp)
      if h and lh and U.Dist(lh.Position,h.Position)<=Cfg.Trigger.Range then
        task.wait(Cfg.Trigger.Delay)mouse1click()end end end)
  print("[SH] Triggerbot")end end

-- 3) ESP
do if Cfg.ESP.E then
  local objs={}
  game:GetService("RunService").RenderStepped:Connect(function()
    if not Cfg.ESP.E then for _,o in pairs(objs)do for _,d in pairs(o)do pcall(function()d:Remove()end)end end;objs={}return end
    local cam=workspace.CurrentCamera
    local lp=game:GetService("Players").LocalPlayer
    for _,p in ipairs(U.Players())do
      local h=U.HRP(p)local hu=U.Hum(p)
      if not h or not hu or hu.Health<=0 then
        if objs[p]then for _,o in pairs(objs[p])do pcall(function()o:Remove()end)end;objs[p]=nil end
        continue end
      if not objs[p]then objs[p]={Box=Drawing.new("Square"),Name=Drawing.new("Text"),HP=Drawing.new("Text"),Dist=Drawing.new("Text"),Wep=Drawing.new("Text"),Line=Drawing.new("Line")}end
      local o=objs[p]if not o then continue end
      local pos,on=U.W2S(h.Position)local d=U.Dist(cam.CFrame.Position,h.Position)
      if d>Cfg.ESP.MaxD or not on then for _,obj in pairs(o)do if obj.Visible~=nil then obj.Visible=false end end;continue end
      local sz=Vector2.new(40,60)/(d*0.005)local bsz=Vector2.new(math.max(sz.X,5),math.max(sz.Y,10))
      if Cfg.ESP.Boxes and o.Box then
        o.Box.Visible=true;o.Box.Position=pos-bsz/2;o.Box.Size=bsz
        o.Box.Color=p.TeamColor~=lp.TeamColor and Color3.fromRGB(255,50,50)or Color3.fromRGB(50,255,50)
        o.Box.Thickness=1.5;o.Box.Transparency=0.7 end
      if Cfg.ESP.HBars and o.HP then
        o.HP.Visible=true;local hp=math.floor(hu.Health)local mh=math.floor(hu.MaxHealth)local pct=hp/math.max(mh,1)
        o.HP.Position=Vector2.new(pos.X-bsz.X/2-30,pos.Y-bsz.Y/2)
        o.HP.Text="["..hp.."/"..mh.."]"
        o.HP.Color=Color3.fromRGB(math.floor(255*(1-pct)),math.floor(255*pct),0);o.HP.Size=12 end
      if Cfg.ESP.Names and o.Name then
        o.Name.Visible=true;o.Name.Position=Vector2.new(pos.X,pos.Y-bsz.Y/2-15)
        o.Name.Text=p.Name;o.Name.Color=Color3.fromRGB(255,255,255);o.Name.Size=13
        o.Name.Center=true;o.Name.Outline=true end
      if Cfg.ESP.Dist and o.Dist then
        o.Dist.Visible=true;o.Dist.Position=Vector2.new(pos.X,pos.Y+bsz.Y/2+2)
        o.Dist.Text=string.format("%.0f studs",d);o.Dist.Color=Color3.fromRGB(200,200,200);o.Dist.Size=11;o.Dist.Center=true end
      if Cfg.ESP.Weapon and o.Wep then
        o.Wep.Visible=true
        local tool=p.Character and p.Character:FindFirstChildOfClass("Tool")
        o.Wep.Text=tool and tool.Name or"None"
        o.Wep.Position=Vector2.new(pos.X,pos.Y+bsz.Y/2+14)
        o.Wep.Color=Color3.fromRGB(255,200,0);o.Wep.Size=10;o.Wep.Center=true end
      if Cfg.ESP.Lines and o.Line then
        o.Line.Visible=true;o.Line.From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
        o.Line.To=pos;o.Line.Color=Color3.fromRGB(0,255,0);o.Line.Thickness=1 end end end)
  print("[SH] ESP")end end


-- 4) Weapon Mods
do
  local LP=game:GetService("Players").LocalPlayer
  game:GetService("RunService").Stepped:Connect(function()
    local c=LP.Character if not c then return end
    local tool=c:FindFirstChildOfClass("Tool")if not tool then return end
    for _,ch in ipairs(tool:GetDescendants())do
      if(ch:IsA("NumberValue")or ch:IsA("IntValue"))then
        local n=ch.Name:lower()
        if Cfg.Weapon.NoSpread and(n:find("spread")or n:find("bloom")or n:find("accura"))then pcall(function()ch.Value=0 end)end
        if Cfg.Weapon.InfAmmo and(n:find("ammo")or n:find("bullet")or n:find("magazine"))then pcall(function()ch.Value=999 end)end
        if Cfg.Weapon.InstReload and(n:find("reload"))then pcall(function()ch.Value=0 end)end
        if(Cfg.Weapon.InfDmg or Cfg.Weapon.DmgMult>1)and(n:find("damage")or n:find("dmg"))then
          pcall(function()ch.Value=Cfg.Weapon.InfDmg and 999999 or(ch.Value*Cfg.Weapon.DmgMult)end)end end end end)
  print("[SH] WeaponMods")end

-- 5) Movement
do
  local LP=game:GetService("Players").LocalPlayer
  local UIS=game:GetService("UserInputService")
  if Cfg.Move.Spd.E then
    LP.CharacterAdded:Connect(function(c)task.wait(0.5)local h=c:WaitForChild("Humanoid")if h then h.WalkSpeed=Cfg.Move.Spd.S end end)
    game:GetService("RunService").Stepped:Connect(function()
      local c=LP.Character if c and c:FindFirstChildOfClass("Humanoid")then c:FindFirstChildOfClass("Humanoid").WalkSpeed=Cfg.Move.Spd.S end end)
    print("  [Move] SpeedHack")end
  if Cfg.Move.Fly.E then
    local fly={Active=false,GV=nil,BV=nil}
    UIS.InputBegan:Connect(function(in,gp)if gp then return end
      if in.KeyCode==Enum.KeyCode.F and Cfg.Move.Fly.E then
        fly.Active=not fly.Active;local c=LP.Character
        if c and c:FindFirstChild("HumanoidRootPart")then
          local r=c.HumanoidRootPart
          if fly.Active then
            fly.GV=Instance.new("BodyGyro");fly.GV.Parent=r;fly.GV.MaxTorque=Vector3.new(9e9,9e9,9e9);fly.GV.CFrame=r.CFrame
            fly.BV=Instance.new("BodyVelocity");fly.BV.Parent=r;fly.BV.MaxForce=Vector3.new(9e9,9e9,9e9)
            if c:FindFirstChildOfClass("Humanoid")then c:FindFirstChildOfClass("Humanoid").PlatformStand=true end
          else
            if fly.GV then fly.GV:Destroy();fly.GV=nil end
            if fly.BV then fly.BV:Destroy();fly.BV=nil end
            if c and c:FindFirstChildOfClass("Humanoid")then c:FindFirstChildOfClass("Humanoid").PlatformStand=false end end end end end)
    game:GetService("RunService").Heartbeat:Connect(function()
      if not fly.Active or not Cfg.Move.Fly.E then return end
      local c=LP.Character if not c or not c:FindFirstChild("HumanoidRootPart")or not fly.BV then return end
      local cam=workspace.CurrentCamera;local dir=Vector3.new()
      if UIS:IsKeyDown(Enum.KeyCode.W)then dir=dir+cam.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.S)then dir=dir-cam.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.A)then dir=dir-cam.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.D)then dir=dir+cam.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.Space)then dir=dir+Vector3.new(0,1,0)end
      if UIS:IsKeyDown(Enum.KeyCode.LeftShift)then dir=dir+Vector3.new(0,-1,0)end
      if dir.Magnitude>0 then dir=dir.Unit*Cfg.Move.Fly.S end
      fly.BV.Velocity=dir;fly.GV.CFrame=cam.CFrame end)
    print("  [Move] FlyHack")end
  if Cfg.Move.InfJ.E then
    UIS.JumpRequest:Connect(function()
      if not Cfg.Move.InfJ.E then return end
      local c=LP.Character if c and c:FindFirstChildOfClass("Humanoid")then c:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)end end)
    print("  [Move] InfiniteJump")end
  if Cfg.Move.BH.E then
    game:GetService("RunService").Heartbeat:Connect(function()
      if not Cfg.Move.BH.E then return end
      if UIS:IsKeyDown(Enum.KeyCode.Space)then
        local c=LP.Character
        if c and c:FindFirstChildOfClass("Humanoid")then
          local h=c:FindFirstChildOfClass("Humanoid")
          if h and h.FloorMaterial~=Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping)end end end end)
    print("  [Move] BunnyHop")end
  if Cfg.Move.Noclip.E then
    game:GetService("RunService").Stepped:Connect(function()
      if not Cfg.Move.Noclip.E then return end
      local c=LP.Character if c then for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=false end end end end)
    print("  [Move] Noclip")end end

-- 6) Wallhack
do if Cfg.Wallhack.E then
  game:GetService("RunService").Stepped:Connect(function()
    if not Cfg.Wallhack.E then return end
    for _,p in ipairs(workspace:GetDescendants())do
      if p:IsA("BasePart")and not p:IsDescendantOf(game:GetService("Players"))then
        if p.Transparency<Cfg.Wallhack.Trans then p.LocalTransparencyModifier=Cfg.Wallhack.Trans end end end end)
  print("[SH] Wallhack")end end

-- 7) Anti-Aim
do if Cfg.AntiAim.E then
  game:GetService("RunService").RenderStepped:Connect(function()
    if not Cfg.AntiAim.E then return end
    local cam=workspace.CurrentCamera
    if Cfg.AntiAim.Mode=="Spin"then
      cam.CFrame=CFrame.new(cam.CFrame.Position)*CFrame.Angles(0,math.rad(tick()%360),0)
    elseif Cfg.AntiAim.Mode=="Jitter"then
      cam.CFrame=CFrame.new(cam.CFrame.Position)*CFrame.Angles(math.rad(-89),math.rad(math.random(-180,180)),0)
    elseif Cfg.AntiAim.Mode=="Backwards"then
      cam.CFrame=CFrame.new(cam.CFrame.Position,cam.CFrame.Position-cam.CFrame.LookVector*10)end end)
  print("[SH] AntiAim")end end


-- 8) Automation
do
  local LP=game:GetService("Players").LocalPlayer
  if Cfg.AutoFarm.E then
    coroutine.wrap(function()
      while task.wait(0.5)do
        if not Cfg.AutoFarm.E then break end
        local c=LP.Character if not c then continue end
        if Cfg.AutoFarm.Meth=="Collect"then
          for _,o in ipairs(workspace:GetDescendants())do
            if o:IsA("BasePart")and o:FindFirstChild("TouchInterest")and
              U.Dist(c.HumanoidRootPart.Position,o.Position)<=Cfg.AutoFarm.Rad then
              firetouchinterest(c.HumanoidRootPart,o,0)task.wait(0.05)firetouchinterest(c.HumanoidRootPart,o,1)end end
        elseif Cfg.AutoFarm.Meth=="Click"then
          for _,o in ipairs(workspace:GetDescendants())do
            if o:IsA("ClickDetector")and U.Dist(c.HumanoidRootPart.Position,o.Parent.Position)<=Cfg.AutoFarm.Rad then
              fireclickdetector(o)end end end end end)()
    print("  [Auto] AutoFarm")end
  if Cfg.AutoHeal.E then
    coroutine.wrap(function()
      while task.wait(1)do
        if not Cfg.AutoHeal.E then break end
        local c=LP.Character if not c then continue end
        local h=c:FindFirstChildOfClass("Humanoid")if not h then continue end
        if(h.Health/h.MaxHealth)*100<=Cfg.AutoHeal.Thresh then
          local bp=LP:FindFirstChild("Backpack")if bp then
            for _,item in ipairs(bp:GetChildren())do
              if item.Name:lower():find(Cfg.AutoHeal.Item:lower())then
                c.Humanoid:EquipTool(item)task.wait(0.2)
                local fn=item:FindFirstChild("Heal")or item:FindFirstChild("Use")
                if fn and fn:IsA("BindableFunction")then fn:Invoke()end;break end end end end end end)()
    print("  [Auto] AutoHeal")end
  if Cfg.AutoBlock.E then
    game:GetService("RunService").RenderStepped:Connect(function()
      if not Cfg.AutoBlock.E then return end
      local c=LP.Character if not c then return end
      local tool=c:FindFirstChildOfClass("Tool")
      if Cfg.AutoBlock.Mode=="Always"and tool then
        local bf=tool:FindFirstChild("Block")or tool:FindFirstChild("Parry")
        if bf and bf:IsA("BindableFunction")then bf:Invoke()end end end)
    print("  [Auto] AutoBlock")end
  if Cfg.Loadout.E then
    coroutine.wrap(function()
      while task.wait(5)do
        if not Cfg.Loadout.E then break end
        local bp=LP:FindFirstChild("Backpack")if not bp then continue end
        local c=LP.Character if not c then continue end
        local cur=c:FindFirstChildOfClass("Tool")local cn=cur and cur.Name or""
        for _,wn in ipairs(Cfg.Loadout.Guns)do
          if cn~=wn then local t=bp:FindFirstChild(wn)if t then c.Humanoid:EquipTool(t)break end end end end)()
    print("  [Auto] AutoLoadout")end end

-- 9) Chat Spammer
do if Cfg.Spammer.E then
  local LP=game:GetService("Players").LocalPlayer
  coroutine.wrap(function()
    local idx=1
    while task.wait(Cfg.Spammer.Int)do
      if not Cfg.Spammer.E then break end
      local msg=Cfg.Spammer.Msg[idx]if msg then pcall(function()LP:Chat(msg)end)end
      idx=idx%#Cfg.Spammer.Msg+1 end end)()
  print("[SH] ChatSpammer")end end

-- 10) Custom Crosshair
do if Cfg.Crosshair.E and Drawing then
  local obj
  if Cfg.Crosshair.Style=="Cross"then obj={HL=Drawing.new("Line"),VL=Drawing.new("Line")}
  elseif Cfg.Crosshair.Style=="Dot"then obj=Drawing.new("Circle")
  elseif Cfg.Crosshair.Style=="Circle"then obj=Drawing.new("Circle")end
  game:GetService("RunService").RenderStepped:Connect(function()
    if not Cfg.Crosshair.E then
      if obj then if type(obj)=="table"then for _,o in pairs(obj)do o.Visible=false end else obj.Visible=false end end;return end
    local c=workspace.CurrentCamera.ViewportSize/2
    local col=Cfg.Crosshair.Col;local sz=Cfg.Crosshair.Size
    if Cfg.Crosshair.Style=="Cross"and type(obj)=="table"then
      if obj.HL then obj.HL.From=Vector2.new(c.X-sz,c.Y);obj.HL.To=Vector2.new(c.X+sz,c.Y)
        obj.HL.Color=col;obj.HL.Thickness=2;obj.HL.Visible=true end
      if obj.VL then obj.VL.From=Vector2.new(c.X,c.Y-sz);obj.VL.To=Vector2.new(c.X,c.Y+sz)
        obj.VL.Color=col;obj.VL.Thickness=2;obj.VL.Visible=true end
    elseif Cfg.Crosshair.Style=="Dot"and obj then
      obj.Position=c;obj.Radius=3;obj.Color=col;obj.Filled=true;obj.Visible=true
    elseif Cfg.Crosshair.Style=="Circle"and obj then
      obj.Position=c;obj.Radius=sz;obj.Color=col;obj.Thickness=1.5;obj.NumSides=32;obj.Visible=true end end)
  print("[SH] Crosshair")end end

-- 11) FOV Changer
do if Cfg.FOV.E then
  game:GetService("RunService").RenderStepped:Connect(function()
    if Cfg.FOV.E then workspace.CurrentCamera.FieldOfView=Cfg.FOV.FOV end end)
  print("[SH] FOVChanger")end end

-- 12) Third Person
do if Cfg.ThirdP.E then
  local LP=game:GetService("Players").LocalPlayer
  workspace.CurrentCamera.CameraSubject=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  game:GetService("RunService").RenderStepped:Connect(function()
    if not Cfg.ThirdP.E then return end
    workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    LP.CameraMinZoomDistance=Cfg.ThirdP.Dist;LP.CameraMaxZoomDistance=Cfg.ThirdP.Dist end)
  print("[SH] ThirdPerson")end end

-- 13) Anti-Cheat Bypass
do
  if Cfg.AC.Safe then warn=function()end end
  local mt=getmetatable and getmetatable(game)
  if mt and type(mt)=="table"then
    local old=mt.__namecall
    if old then
      mt.__namecall=newcclosure(function(...)
        local m=getnamecallmethod and getnamecallmethod()
        if m and(m=="Kick"or m=="Remove"or m=="Destroy"or m=="Teleport")then return end
        return old(...)end)end end
  print("[SH] AntiCheat")end

print("=== SoberHook v3.0 Loaded ===")

