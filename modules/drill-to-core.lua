-- NOVA DRILL v0.1 / Drill to Earth's Core (Roblox)
-- Independent script: no obfuscation, no remote-event guessing.
-- Tested statically only; game-specific actions need on-device tests.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local VirtualUser=game:GetService("VirtualUser")
local player=Players.LocalPlayer
if not player then return end
local env=(getgenv and getgenv()) or _G
if type(env.NOVA_DRILL_UNLOAD)=="function" then pcall(env.NOVA_DRILL_UNLOAD) end
local alive=true
local connections={}
local tracked={}
local promptIndex={}
local originalSpeeds={}
local cfg={
  oreESP=false,lootESP=false,npcESP=false,
  autoSwing=false,autoCollect=false,antiAFK=false,
  speed=false,walkSpeed=24,espRange=200,swingInterval=.43
}
local counts={ore=0,loot=0,npc=0,prompts=0,swings=0,collects=0}
local function track(c) connections[#connections+1]=c return c end
local function getChar() return player.Character end
local function getRoot()
  local c=getChar()
  return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
  local c=getChar()
  return c and c:FindFirstChildOfClass("Humanoid")
end
local function instance(t,props,parent)
  local x=Instance.new(t)
  for k,v in pairs(props or {}) do x[k]=v end
  x.Parent=parent
  return x
end
local function corner(obj,r)
  return instance("UICorner",{CornerRadius=UDim.new(0,r or 9)},obj)
end
local function stroke(obj,col)
  return instance("UIStroke",{Color=col,Thickness=1,Transparency=.35},obj)
end
local R=Color3.fromRGB(225,58,78)
local BG=Color3.fromRGB(15,13,19)
local PANEL=Color3.fromRGB(30,25,33)
local WHITE=Color3.fromRGB(244,240,246)
local MUTED=Color3.fromRGB(175,164,179)
local gui=instance("ScreenGui",{
 Name="NOVA_DRILL_V01",ResetOnSpawn=false,IgnoreGuiInset=true,
 ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1200
},player:WaitForChild("PlayerGui"))
local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900,500)
local height=math.max(235,math.min(468,viewport.Y-28))
local panel=instance("Frame",{
 Name="Panel",BackgroundColor3=BG,BorderSizePixel=0,
 Size=UDim2.fromOffset(314,height),Position=UDim2.new(0,25,.5,-height/2),
 Active=true
},gui)
corner(panel,14);stroke(panel,R)
local title=instance("Frame",{
 BackgroundTransparency=1,Size=UDim2.new(1,-18,0,42),
 Position=UDim2.fromOffset(9,6),Active=true
},panel)
instance("TextLabel",{
 BackgroundTransparency=1,Size=UDim2.new(1,-74,0,24),
 Position=UDim2.fromOffset(6,1),
 Text="NOVA / DRILL",TextColor3=WHITE,Font=Enum.Font.GothamBold,
 TextSize=19,TextXAlignment=Enum.TextXAlignment.Left
},title)
instance("TextLabel",{
 BackgroundTransparency=1,Size=UDim2.new(1,-80,0,15),
 Position=UDim2.fromOffset(6,24),Text="EARTH CORE   •   v0.1 TEST",
 TextColor3=R,Font=Enum.Font.Gotham,TextSize=10,
 TextXAlignment=Enum.TextXAlignment.Left
},title)
local function tiny(text,x,callback)
 local b=instance("TextButton",{
  BackgroundColor3=PANEL,BorderSizePixel=0,Text=text,
  TextColor3=WHITE,Font=Enum.Font.GothamBold,TextSize=16,
  Size=UDim2.fromOffset(31,30),Position=UDim2.new(1,x,0,4)
 },title)
 corner(b,7)
 track(b.MouseButton1Click:Connect(callback))
 return b
end
local minimized=false
local buttonOpen=instance("TextButton",{
 Name="Reopen",Visible=false,BackgroundColor3=R,BorderSizePixel=0,
 Position=UDim2.new(0,18,.45,0),Size=UDim2.fromOffset(104,36),
 Text="NOVA DRILL",TextColor3=WHITE,TextSize=12,Font=Enum.Font.GothamBold
},gui)
corner(buttonOpen,9)
track(buttonOpen.MouseButton1Click:Connect(function()
 minimized=false panel.Visible=true buttonOpen.Visible=false
end))
local stop
tiny("—",-70,function()
 minimized=true panel.Visible=false buttonOpen.Visible=true
end)
tiny("×",-35,function() if stop then stop() end end)
local sub=instance("TextLabel",{
 BackgroundTransparency=1,Position=UDim2.fromOffset(17,50),
 Size=UDim2.new(1,-34,0,34),
 Text="Автокирка • сбор • ESP • диагностика\nДля Arceus X NEO / Android",
 TextColor3=MUTED,TextSize=11,Font=Enum.Font.Gotham,
 TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top
},panel)
local status=instance("TextLabel",{
 BackgroundColor3=PANEL,BorderSizePixel=0,
 Size=UDim2.new(1,-22,0,65),Position=UDim2.new(0,11,1,-74),
 Text="Загрузка...",TextColor3=MUTED,TextSize=11,
 Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
 TextYAlignment=Enum.TextYAlignment.Center
},panel)
corner(status,8)
local scroll=instance("ScrollingFrame",{
 Name="Controls",BackgroundTransparency=1,BorderSizePixel=0,
 Size=UDim2.new(1,-18,1,-174),Position=UDim2.fromOffset(9,91),
 ScrollBarThickness=3,ScrollBarImageColor3=R,
 CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y
},panel)
local layout=instance("UIListLayout",{
 Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder
},scroll)
instance("UIPadding",{
 PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,5),
 PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,6)
},scroll)
local function row(label,click)
 local b=instance("TextButton",{
  Size=UDim2.new(1,-4,0,36),BackgroundColor3=PANEL,BorderSizePixel=0,
  Text=label,TextSize=12,Font=Enum.Font.GothamMedium,
  TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Left,
  AutoButtonColor=true
 },scroll)
 corner(b,8)
 instance("UIPadding",{PaddingLeft=UDim.new(0,11)},b)
 track(b.MouseButton1Click:Connect(function()
  local ok,e=pcall(click)
  if not ok then status.Text="Ошибка кнопки: "..tostring(e):sub(1,120) end
 end))
 return b
end
local function toggle(label,key)
 local b
 local function draw()
  b.Text=(cfg[key] and "●  " or "○  ")..label
  b.TextColor3=cfg[key] and Color3.fromRGB(255,129,143) or WHITE
 end
 b=row("",function()cfg[key]=not cfg[key] draw() end)
 draw()
 return b
end
local function section(name)
 local l=instance("TextLabel",{
  Size=UDim2.new(1,-4,0,23),BackgroundTransparency=1,
  Text=name,TextColor3=R,Font=Enum.Font.GothamBold,TextSize=11,
  TextXAlignment=Enum.TextXAlignment.Left
 },scroll)
 instance("UIPadding",{PaddingLeft=UDim.new(0,8)},l)
end
section("АВТОМАТИЗАЦИЯ")
toggle("Автоудары киркой", "autoSwing")
toggle("Автоподбор через ProximityPrompt","autoCollect")
toggle("Анти-AFK","antiAFK")
section("ПОДСВЕТКА")
toggle("ESP руды / минералов","oreESP")
toggle("ESP сундуков / лута","lootESP")
toggle("ESP NPC","npcESP")
local rng
rng=row("Дальность ESP: "..cfg.espRange.." studs",function()
 local vals={100,200,350}
 local idx=1
 for i,v in ipairs(vals) do if v==cfg.espRange then idx=i break end end
 cfg.espRange=vals[idx%#vals+1]
 rng.Text="Дальность ESP: "..cfg.espRange.." studs"
end)
section("ПЕРСОНАЖ")
local walk
walk=row("Ускорение ходьбы: ВЫКЛ",function()
 cfg.speed=not cfg.speed
 walk.Text=cfg.speed and ("Ускорение ходьбы: "..cfg.walkSpeed) or "Ускорение ходьбы: ВЫКЛ"
 if not cfg.speed then
  local hum=getHum()
  if hum and originalSpeeds[hum] then
   hum.WalkSpeed=originalSpeeds[hum]
  end
 end
end)
local walkVal
walkVal=row("Скорость: "..cfg.walkSpeed.." (настройка)",function()
 local vals={22,24,28,34}
 local idx=1
 for i,v in ipairs(vals) do if v==cfg.walkSpeed then idx=i break end end
 cfg.walkSpeed=vals[idx%#vals+1]
 walkVal.Text="Скорость: "..cfg.walkSpeed.." (настройка)"
 if cfg.speed then walk.Text="Ускорение ходьбы: "..cfg.walkSpeed end
end)
section("ДИАГНОСТИКА")
local statusHoldUntil=0
local function report(msg,seconds)
 status.Text=msg
 statusHoldUntil=os.clock()+(seconds or 7)
end
local debug=row("Проверить предметы / объекты",function()
 local backpack=player:FindFirstChildOfClass("Backpack")
 local tools={}
 local function addTools(root)
  if root then for _,t in ipairs(root:GetChildren()) do
   if t:IsA("Tool") then tools[#tools+1]=t.Name end
  end end
 end
 addTools(getChar());addTools(backpack)
 local remotes={}
 for _,v in ipairs(RS:GetDescendants()) do
  if v:IsA("RemoteEvent") then
   local lower=v.Name:lower()
   local useful=false
   for _,term in ipairs({"mine","ore","fuel","drill","pickup","collect","harvest"}) do
    if lower:find(term,1,true) then useful=true break end
   end
   if useful then
    remotes[#remotes+1]=v.Name
    if #remotes>=5 then break end
   end
  end
 end
 report(("Tools: "..(#tools>0 and table.concat(tools,", ") or "(нет)")..
  "\nRemotes: "..(#remotes>0 and table.concat(remotes,", ") or "(не найдены)")):sub(1,235),12)
end)
local debugPrompts=row("Показать ближайшие взаимодействия",function()
 local me=getRoot()
 if not me then status.Text="Персонаж ещё не загрузился" return end
 local matches={}
 for p in pairs(promptIndex) do
  if p.Parent and p.Enabled then
   local par=p.Parent
   local part=par:IsA("Attachment") and par.Parent or par
   if part and part:IsA("BasePart") then
    local d=(part.Position-me.Position).Magnitude
    if d<35 then matches[#matches+1]={dist=d,text=(p.ActionText~="" and p.ActionText or p.Name)} end
   end
  end
 end
 table.sort(matches,function(a,b)return a.dist<b.dist end)
 local lines={}
 for i=1,math.min(#matches,4) do lines[#lines+1]=string.format("%s (%.0f)",matches[i].text,matches[i].dist) end
 report("Рядом: "..(#lines>0 and table.concat(lines," | ") or "нет ProximityPrompt"),10)
end)
local copyInfo=row("Версия игры / статус",function()
 report("PlaceId: "..tostring(game.PlaceId)..
 "\nСкрипт: v0.1 TEST • версия игры не проверена в исполнителе.",10)
end)

-- Drag by touch/mouse; never swallow game input outside the title bar.
local dragging=false
local dragOrigin,frameOrigin=nil,nil
track(title.InputBegan:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or
    input.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true dragOrigin=input.Position frameOrigin=panel.Position
 end
end))
track(UIS.InputChanged:Connect(function(input)
 if not dragging then return end
 if input.UserInputType~=Enum.UserInputType.Touch and
    input.UserInputType~=Enum.UserInputType.MouseMovement then return end
 local delta=input.Position-dragOrigin
 panel.Position=UDim2.new(frameOrigin.X.Scale,frameOrigin.X.Offset+delta.X,
   frameOrigin.Y.Scale,frameOrigin.Y.Offset+delta.Y)
end))
track(UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.Touch or
    input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end))

local function findTool()
 local ch=getChar()
 if not ch then return nil end
 local bag=player:FindFirstChildOfClass("Backpack")
 local matches={}
 for _,root in ipairs({ch,bag}) do
  if root then for _,tool in ipairs(root:GetChildren()) do
   if tool:IsA("Tool") then
    local name=tool.Name:lower()
    local score=name:find("pickaxe",1,true) and 3
      or name:find("pick",1,true) and 2
      or name:find("кирк",1,true) and 2
      or name:find("drill",1,true) and 1 or 0
    if score>0 then matches[#matches+1]={obj=tool,score=score} end
   end
  end
 end
 end
 table.sort(matches,function(a,b)return a.score>b.score end)
 return matches[1] and matches[1].obj or nil
end
local function myOrPlayerItem(v)
 if not v then return true end
 local c=v
 for _=1,6 do
  if not c then break end
  if c:IsA("Tool") or c:IsA("Accessory") then return true end
  if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") then return true end
  if c:IsA("Backpack") then return true end
  c=c.Parent
 end
 return false
end
local oreWords={"ore","coal","iron","copper","silver","gold","diamond",
 "crystal","uranium","obsidian","quartz","ruby","emerald","fossil","mineral"}
local lootWords={"chest","crate","treasure","loot","pickup","drop","supply"}
local function hasWord(n,words)
 for _,w in ipairs(words) do if n:find(w,1,true) then return true end end
 return false
end
local function classify(obj)
 if not obj or (not obj:IsA("BasePart") and not obj:IsA("Model")) then return nil end
 if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
  if Players:GetPlayerFromCharacter(obj) then return nil end
  return "npc"
 end
 if myOrPlayerItem(obj) then return nil end
 local n=obj.Name:lower()
 if hasWord(n,lootWords) then return "loot" end
 if hasWord(n,oreWords) then return "ore" end
 return nil
end
local function rootPart(obj)
 if obj:IsA("BasePart") then return obj end
 if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true) end
 return nil
end
local colors={ore=Color3.fromRGB(104,207,230),
 loot=Color3.fromRGB(249,194,86),npc=Color3.fromRGB(242,90,117)}
local espFolder=instance("Folder",{Name="NOVA_DRILL_VISUALS"},gui)
local function clearESP()
 for _,v in pairs(tracked) do
  if v.h then pcall(function()v.h:Destroy()end) end
  if v.b then pcall(function()v.b:Destroy()end) end
 end
 table.clear(tracked)
end
local function mark(obj,kind,part)
 local hi=instance("Highlight",{
  FillColor=colors[kind],OutlineColor=colors[kind],
  FillTransparency=.82,OutlineTransparency=.05,
  DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
  Adornee=obj
 },espFolder)
 local bb=instance("BillboardGui",{
  Name="NOVA_TAG",Adornee=part,AlwaysOnTop=true,
  Size=UDim2.fromOffset(155,29),StudsOffset=Vector3.new(0,3,0)
 },espFolder)
 instance("TextLabel",{
  BackgroundColor3=Color3.fromRGB(16,15,21),BackgroundTransparency=.25,
  BorderSizePixel=0,Size=UDim2.fromScale(1,1),
  Text=(kind=="ore" and "⛏ " or kind=="npc" and "NPC " or "◆ ")..obj.Name,
  TextColor3=colors[kind],Font=Enum.Font.GothamBold,
  TextSize=11,TextScaled=false,TextTruncate=Enum.TextTruncate.AtEnd
 },bb)
 tracked[obj]={h=hi,b=bb,kind=kind}
end
local function refreshESP()
 clearESP()
 counts.ore=0 counts.loot=0 counts.npc=0
 if not (cfg.oreESP or cfg.lootESP or cfg.npcESP) then return end
 local me=getRoot()
 if not me then return end
 local found={}
 for _,obj in ipairs(workspace:GetDescendants()) do
  if (obj:IsA("Model") or obj:IsA("BasePart")) and not found[obj] then
   local kind=classify(obj)
   if kind and cfg[kind.."ESP"] then
    local part=rootPart(obj)
    if part and (part.Position-me.Position).Magnitude<=cfg.espRange then
      local cap=kind=="ore" and 55 or kind=="npc" and 20 or 30
      if counts[kind]<cap then
       found[obj]=true
       counts[kind]=counts[kind]+1
       mark(obj,kind,part)
      end
    end
   end
  end
 end
end

local function indexPrompt(v)
 if v:IsA("ProximityPrompt") then promptIndex[v]=true end
end
for _,v in ipairs(workspace:GetDescendants()) do indexPrompt(v) end
track(workspace.DescendantAdded:Connect(indexPrompt))
track(workspace.DescendantRemoving:Connect(function(v)
 promptIndex[v]=nil
 if tracked[v] then
  local t=tracked[v]
  pcall(function()t.h:Destroy()end);pcall(function()t.b:Destroy()end)
  tracked[v]=nil
 end
end))
local function collectPrompt()
 if not cfg.autoCollect then return end
 if type(fireproximityprompt)~="function" then return end
 local me=getRoot()
 if not me then return end
 for p in pairs(promptIndex) do
  if p.Parent and p.Enabled then
   local name=(p.ActionText.." "..p.ObjectText.." "..p.Name):lower()
   local wants=hasWord(name,{"pick up","pickup","collect","grab","loot","take","harvest","подобрать","собрать"})
   local rejects=hasWord(name,{"buy","sell","purchase","shop","upgrade","trade","купить","продать"})
   if wants and not rejects then
    local holder=p.Parent
    local part=holder:IsA("Attachment") and holder.Parent or holder
    if part and part:IsA("BasePart") then
     local range=math.min(p.MaxActivationDistance or 8,10)
     if (part.Position-me.Position).Magnitude<=range then
      local ok=pcall(fireproximityprompt,p)
      if ok then counts.collects=counts.collects+1 end
     end
    end
   end
  end
 end
end
track(player.Idled:Connect(function()
 if cfg.antiAFK then
  pcall(function()
   VirtualUser:CaptureController()
   VirtualUser:ClickButton2(Vector2.new(0,0))
  end)
 end
end))
stop=function()
 if not alive then return end
 alive=false
 clearESP()
 for hum,speed in pairs(originalSpeeds) do
  if hum and hum.Parent then pcall(function()hum.WalkSpeed=speed end) end
 end
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
 if gui then pcall(function()gui:Destroy()end) end
 if env.NOVA_DRILL_UNLOAD==stop then env.NOVA_DRILL_UNLOAD=nil end
end
env.NOVA_DRILL_UNLOAD=stop

task.spawn(function()
 local lastESP=-100
 local lastPick=-100
 local lastCollect=-100
 while alive do
  local now=os.clock()
  local ok,e=pcall(function()
   if now-lastESP>=9 then
    lastESP=now
    refreshESP()
   end
   if cfg.autoSwing and now-lastPick>=cfg.swingInterval then
    lastPick=now
    local tool=findTool()
    if tool then
     local hum=getHum()
     if tool.Parent~=getChar() and hum then hum:EquipTool(tool) end
     if tool.Parent==getChar() then
      local success=pcall(function()tool:Activate()end)
      if success then counts.swings=counts.swings+1 end
     end
    end
   end
   if cfg.autoCollect and now-lastCollect>=.85 then
    lastCollect=now
    collectPrompt()
   end
   local hum=getHum()
   if cfg.speed and hum then
    if not originalSpeeds[hum] then originalSpeeds[hum]=hum.WalkSpeed end
    if hum.WalkSpeed~=cfg.walkSpeed then hum.WalkSpeed=cfg.walkSpeed end
   end
   local tool=findTool()
   local pickName=tool and tool.Name or "не найдена"
   local support=type(fireproximityprompt)=="function" and "есть" or "нет"
   counts.prompts=0
   for p in pairs(promptIndex) do
    if p.Parent then counts.prompts=counts.prompts+1 end
   end
   if status and os.clock()>statusHoldUntil then
    status.Text=string.format("Кирка: %s | Prompt API: %s\nESP: %d руда / %d лут / %d NPC\nУдары: %d | подбор: %d | prompts: %d",
       pickName,support,counts.ore,counts.loot,counts.npc,counts.swings,counts.collects,counts.prompts)
   end
  end)
  if not ok then status.Text="NOVA ошибка: "..tostring(e):sub(1,145) end
  task.wait(.35)
 end
end)
print("[NOVA DRILL] v0.1 running. PlaceId:",game.PlaceId)
