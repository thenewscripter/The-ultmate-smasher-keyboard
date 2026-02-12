local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")

-- [1] ANTI-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KBD_V24_FIXED"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- States
local reachValue, autoClicker, reachMode, pickingMode, deleteMode = 15, false, false, false, false
local keyLock = false
local isRecording, macroData, lastActionTime = false, {}, 0
local externalKeys = {}

-- [2] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 620, 0, 260)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.new(0, 1, 0)
Stroke.Parent = MainFrame

-- [3] POPUP MENU
local PopupMenu = Instance.new("Frame")
PopupMenu.Size = UDim2.new(1, 0, 0, 85)
PopupMenu.Position = UDim2.new(0, 0, 0, -90)
PopupMenu.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
PopupMenu.Visible = false
PopupMenu.Parent = MainFrame
Instance.new("UICorner", PopupMenu)

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, 75, 0, 26)
Grid.CellPadding = UDim2.new(0, 4, 0, 4)
Grid.Parent = PopupMenu

local function createMenuBtn(text, color, callback)
    local b = Instance.new("TextButton")
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 8
    b.Parent = PopupMenu
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

local ShowBtn = Instance.new("TextButton")
ShowBtn.Size = UDim2.new(0, 60, 0, 30)
ShowBtn.Position = UDim2.new(0, 10, 0.1, 0)
ShowBtn.Text = "OPEN"
ShowBtn.Visible = false
ShowBtn.Parent = ScreenGui
Instance.new("UICorner", ShowBtn)

createMenuBtn("PICK KEY", Color3.fromRGB(140, 140, 0), function(b) pickingMode = not pickingMode b.Text = pickingMode and "SELECTING..." or "PICK KEY" end)
createMenuBtn("DEL KEY", Color3.fromRGB(140, 0, 0), function(b) deleteMode = not deleteMode b.Text = deleteMode and "DEL: ON" or "DEL KEY" end)
local rchT = createMenuBtn("REACH: OFF", Color3.fromRGB(90, 0, 140), function() reachMode = not reachMode end)
local clkT = createMenuBtn("AUTO: OFF", Color3.fromRGB(0, 90, 90), function() autoClicker = not autoClicker end)
local recT = createMenuBtn("REC", Color3.fromRGB(180, 0, 0), function() isRecording = not isRecording if isRecording then macroData = {} lastActionTime = tick() end end)
createMenuBtn("PLAY", Color3.fromRGB(0, 140, 0), function()
    task.spawn(function()
        for _, d in ipairs(macroData) do
            task.wait(d.delay)
            VIM:SendKeyEvent(d.state, d.key, false, game)
        end
    end)
end)
createMenuBtn("LOCK KEYS", Color3.fromRGB(0, 90, 40), function(b) 
    keyLock = not keyLock 
    b.Text = keyLock and "LOCKED" or "LOCK KEYS"
    for _, k in pairs(externalKeys) do k.Draggable = not keyLock end
end)
createMenuBtn("HIDE UI", Color3.fromRGB(50, 50, 50), function() MainFrame.Visible = false ShowBtn.Visible = true end)
createMenuBtn("SAVE", Color3.fromRGB(50, 50, 50), function()
    local d = {} for _, k in pairs(externalKeys) do if k.Parent then table.insert(d, {Name=k.Name, Pos={k.Position.X.Scale, k.Position.X.Offset, k.Position.Y.Scale, k.Position.Y.Offset}}) end end
    writefile("Layout_V24.json", HttpService:JSONEncode(d))
end)
createMenuBtn("LOAD", Color3.fromRGB(50, 50, 50), function()
    pcall(function()
        local d = HttpService:JSONDecode(readfile("Layout_V24.json"))
        for _, v in pairs(externalKeys) do v:Destroy() end externalKeys = {}
        for _, info in pairs(d) do spawnExternal(info.Name, UDim2.new(info.Pos[1], info.Pos[2], info.Pos[3], info.Pos[4])) end
    end)
end)

ShowBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true ShowBtn.Visible = false end)

-- [4] SPAWNER
function spawnExternal(name, pos)
    local k = Instance.new("TextButton")
    k.Name = name k.Text = name:sub(1,1) k.Size = UDim2.new(0, 45, 0, 45)
    k.Position = pos or UDim2.new(0.5, 0, 0.4, 0)
    k.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Draggable = not keyLock
    k.Parent = ScreenGui
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function() 
        if deleteMode then k:Destroy() else 
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) 
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = true, delay = tick() - lastActionTime}) lastActionTime = tick() end
        end 
    end)
    k.MouseButton1Up:Connect(function() 
        VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) 
        if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = false, delay = tick() - lastActionTime}) lastActionTime = tick() end
    end)
    table.insert(externalKeys, k)
end

-- [5] KEYBOARD ENGINE
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -10, 1, -10)
Container.Position = UDim2.new(0, 5, 0, 5)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local function createRow()
    local r = Instance.new("Frame") r.Size = UDim2.new(1, 0, 0, 40) r.BackgroundTransparency = 1 r.Parent = Container
    local l = Instance.new("UIListLayout") l.FillDirection = Enum.FillDirection.Horizontal l.Padding = UDim.new(0, 4) l.HorizontalAlignment = Enum.HorizontalAlignment.Center l.Parent = r
    return r
end
local UIList = Instance.new("UIListLayout") UIList.Parent = Container UIList.Padding = UDim.new(0, 4)

local function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, width or 45, 0, 35)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Parent = row
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function()
        if pickingMode then spawnExternal(name) pickingMode = false else
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = true, delay = tick() - lastActionTime}) lastActionTime = tick() end
        end
    end)
    k.MouseButton1Up:Connect(function() 
        VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) 
        if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = false, delay = tick() - lastActionTime}) lastActionTime = tick() end
    end)
    return k
end

local r1 = createRow()
makeKey("Escape", r1, 50, "ESC")
local menuT = makeKey("Menu", r1, 50, "MENU")
menuT.BackgroundColor3 = Color3.fromRGB(0, 90, 180)
menuT.MouseButton1Click:Connect(function() PopupMenu.Visible = not PopupMenu.Visible end)
local n = {"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero"}
for i,v in ipairs(n) do makeKey(v, r1, 40, tostring(i%10)) end

local r2 = createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3 = createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
makeKey("Return", r3, 50, "ENT")

local r4 = createRow() makeKey("LeftShift", r4, 60, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5 = createRow() makeKey("Space", r5, 250, "SPACE")
makeKey("X", r5, 50, "EXIT").MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- [6] RENDER LOOP
RunService.RenderStepped:Connect(function()
    rchT.Text = reachMode and "REACH: ON" or "REACH: OFF"
    clkT.Text = autoClicker and "AUTO: ON" or "AUTO: OFF"
    recT.Text = isRecording and "STOP" or "REC"
    if reachMode then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(reachValue, reachValue, reachValue)
                p.Character.HumanoidRootPart.Transparency = 0.7
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if autoClicker then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)
