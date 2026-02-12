local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- [1] Anti-AFK
task.spawn(function()
    while task.wait(60) do
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Smasher_V35_English"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10000

-- States
local pickingMode, reachMode, autoClicker, keyLock, delMode = false, false, false, false, false
local reachValue = 15
local isRecording, macroData, lastActionTime = false, {}, 0

-- [2] OPEN BUTTON
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 80, 0, 40)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
OpenBtn.Text = "OPEN UI"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.Visible = false
OpenBtn.ZIndex = 10001
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn)

-- [3] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 650, 0, 310)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.new(0, 1, 0)

-- [4] THE SUB-MENU (Hidden Features)
local SubMenu = Instance.new("Frame")
SubMenu.Size = UDim2.new(0.9, 0, 0, 120)
SubMenu.Position = UDim2.new(0.05, 0, 0.2, 0)
SubMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SubMenu.ZIndex = 50 
SubMenu.Visible = false
SubMenu.Parent = MainFrame
Instance.new("UICorner", SubMenu)
Instance.new("UIStroke", SubMenu).Color = Color3.new(0, 0.5, 1)

local Grid = Instance.new("UIGridLayout", SubMenu)
Grid.CellSize = UDim2.new(0, 110, 0, 35)
Grid.CellPadding = UDim2.new(0, 10, 0, 10)
Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
Grid.VerticalAlignment = Enum.VerticalAlignment.Center

function createSub(txt, clr, func)
    local b = Instance.new("TextButton")
    b.Text = txt
    b.BackgroundColor3 = clr
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.ZIndex = 51
    b.Parent = SubMenu
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

-- SubMenu Contents (All in English)
createSub("REACH: OFF", Color3.fromRGB(120, 0, 200), function(b) reachMode = not reachMode b.Text = reachMode and "REACH: ON" or "REACH: OFF" end)
createSub("AUTO CLICK: OFF", Color3.fromRGB(0, 120, 120), function(b) autoClicker = not autoClicker b.Text = autoClicker and "AUTO: ON" or "AUTO: OFF" end)
createSub("FPS BOOST", Color3.fromRGB(60, 60, 60), function() for _,v in pairs(game:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end end end)
createSub("REC MACRO", Color3.fromRGB(200, 0, 0), function(b) isRecording = not isRecording if isRecording then macroData = {} lastActionTime = tick() b.Text = "STOP REC" else b.Text = "REC MACRO" end end)
createSub("PLAY MACRO", Color3.fromRGB(0, 200, 0), function() task.spawn(function() for _, d in ipairs(macroData) do task.wait(d.delay) VIM:SendKeyEvent(d.state, d.key, false, game) end end) end)
createSub("SAVE MACRO", Color3.fromRGB(40, 40, 40), function() if not isfolder("KBD") then makefolder("KBD") end writefile("KBD/macro.json", HttpService:JSONEncode(macroData)) end)
createSub("LOAD MACRO", Color3.fromRGB(40, 40, 40), function() if isfile("KBD/macro.json") then macroData = HttpService:JSONDecode(readfile("KBD/macro.json")) end end)
createSub("DEL MODE: OFF", Color3.fromRGB(150, 0, 0), function(b) delMode = not delMode b.Text = delMode and "DEL: ON" or "DEL: OFF" end)

-- [5] TOP BAR
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundTransparency = 1
local TLayout = Instance.new("UIListLayout", TopBar)
TLayout.FillDirection = Enum.FillDirection.Horizontal
TLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TLayout.Padding = UDim.new(0, 12)

function createTop(txt, clr, func)
    local b = Instance.new("TextButton", TopBar)
    b.Size = UDim2.new(0, 100, 0, 35)
    b.Text = txt
    b.BackgroundColor3 = clr
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

createTop("MENU", Color3.fromRGB(0, 120, 255), function() SubMenu.Visible = not SubMenu.Visible end)
createTop("PICK KEY", Color3.fromRGB(160, 160, 0), function(b) pickingMode = not pickingMode b.Text = pickingMode and "SELECTING..." or "PICK KEY" end)
createTop("KEY LOCK: OFF", Color3.fromRGB(0, 160, 120), function(b) keyLock = not keyLock b.Text = keyLock and "LOCKED" or "KEY LOCK: OFF" end)
createTop("HIDE UI", Color3.fromRGB(70, 70, 70), function() MainFrame.Visible = false SubMenu.Visible = false OpenBtn.Visible = true end)
createTop("CLOSE", Color3.fromRGB(200, 0, 0), function() ScreenGui:Destroy() end)

OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true OpenBtn.Visible = false end)

-- [6] KEYBOARD ENGINE
local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -70)
Container.Position = UDim2.new(0, 10, 0, 60)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 5)

function makeRow()
    local r = Instance.new("Frame", Container)
    r.Size = UDim2.new(1, 0, 0, 40)
    r.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", r)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Padding = UDim.new(0, 5)
    return r
end

function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton", row)
    k.Size = UDim2.new(0, width or 45, 0, 38)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    k.TextColor3 = Color3.new(1,1,1)
    k.ZIndex = 2
    Instance.new("UICorner", k)
    
    local wasPicking = false
    k.MouseButton1Down:Connect(function()
        if keyLock then return end
        if pickingMode then
            wasPicking = true
            local fk = Instance.new("TextButton", ScreenGui)
            fk.Size = UDim2.new(0, 55, 0, 55)
            fk.Position = UDim2.new(0.5, 0, 0.4, 0)
            fk.Text = name; fk.Draggable = true; fk.BackgroundColor3 = Color3.fromRGB(45,45,45); fk.TextColor3 = Color3.new(1,1,1); fk.ZIndex = 200
            Instance.new("UICorner", fk)
            fk.MouseButton1Down:Connect(function() if delMode then fk:Destroy() else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) end end)
            fk.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
            pickingMode = false
        else
            wasPicking = false
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = true, delay = tick() - lastActionTime}) lastActionTime = tick() end
        end
    end)
    k.MouseButton1Up:Connect(function()
        if keyLock or wasPicking then return end
        VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game)
        if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = false, delay = tick() - lastActionTime}) lastActionTime = tick() end
    end)
end

-- Keyboard Construction
local r1 = makeRow()
makeKey("Escape", r1, 55, "ESC")
for i=1,9 do makeKey(tostring(i), r1, 40, tostring(i)) end; makeKey("Zero", r1, 40, "0")
local r2 = makeRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3 = makeRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
makeKey("Return", r3, 60, "ENTER")
local r4 = makeRow() makeKey("LeftShift", r4, 65, "SHIFT") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5 = makeRow() makeKey("Space", r5, 280, "SPACE")

-- [7] LOOP (Reach Logic)
RunService.Heartbeat:Connect(function()
    if reachMode then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(reachValue, reachValue, reachValue)
                p.Character.HumanoidRootPart.Transparency = 0.8
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do if autoClicker then VirtualUser:ClickButton1(Vector2.new()) end end
end)
