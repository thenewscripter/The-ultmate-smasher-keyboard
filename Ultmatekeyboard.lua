local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] Force Input Function (For L, ESC, ENT)
local function GamePress(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.05) -- Time needed for Roblox to register
    VIM:SendKeyEvent(false, key, false, game)
end

-- [2] Anti-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Smasher_V27_Stable"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10 -- Make sure UI is on top

-- States
local reachValue, autoClicker, reachMode, pickingMode, deleteMode = 15, false, false, false, false
local keyLock = false
local isRecording, macroData, lastActionTime = false, {}, 0
local externalKeys = {}

-- [3] MAIN FRAME
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

-- [4] POPUP SETTINGS
local PopupMenu = Instance.new("Frame")
PopupMenu.Size = UDim2.new(1, 0, 0, 90)
PopupMenu.Position = UDim2.new(0, 0, 0, -95)
PopupMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PopupMenu.Visible = false
PopupMenu.ZIndex = 10
PopupMenu.Parent = MainFrame
Instance.new("UICorner", PopupMenu)

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, 75, 0, 28)
Grid.CellPadding = UDim2.new(0, 5, 0, 5)
Grid.Parent = PopupMenu

local function createMenuBtn(text, color, callback)
    local b = Instance.new("TextButton")
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 8
    b.ZIndex = 11
    b.Parent = PopupMenu
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

createMenuBtn("PICK KEY", Color3.fromRGB(120, 120, 0), function(b) pickingMode = not pickingMode b.Text = pickingMode and "PICKING..." or "PICK KEY" end)
createMenuBtn("DEL KEY", Color3.fromRGB(120, 0, 0), function(b) deleteMode = not deleteMode b.Text = deleteMode and "DEL: ON" or "DEL KEY" end)
local rchT = createMenuBtn("REACH: OFF", Color3.fromRGB(100, 0, 150), function() reachMode = not reachMode end)
local clkT = createMenuBtn("AUTO: OFF", Color3.fromRGB(0, 100, 100), function() autoClicker = not autoClicker end)
local recT = createMenuBtn("REC", Color3.fromRGB(180, 0, 0), function() isRecording = not isRecording if isRecording then macroData = {} lastActionTime = tick() end end)
createMenuBtn("PLAY", Color3.fromRGB(0, 150, 0), function()
    task.spawn(function()
        for _, d in ipairs(macroData) do task.wait(d.delay) VIM:SendKeyEvent(d.state, d.key, false, game) end
    end)
end)
createMenuBtn("CLOSE GUI", Color3.fromRGB(60, 0, 0), function() ScreenGui:Destroy() end)

-- [5] KEYBOARD ENGINE
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -10, 1, -10)
Container.Position = UDim2.new(0, 5, 0, 5)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 4)

local function createRow()
    local r = Instance.new("Frame") r.Size = UDim2.new(1, 0, 0, 38) r.BackgroundTransparency = 1 r.Parent = Container
    local l = Instance.new("UIListLayout") l.FillDirection = Enum.FillDirection.Horizontal l.Padding = UDim.new(0, 4) l.HorizontalAlignment = Enum.HorizontalAlignment.Center l.Parent = r
    return r
end

local function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, width or 42, 0, 34)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.ZIndex = 5
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
end

-- Construction
local r1 = createRow()
local menuBtn = Instance.new("TextButton", r1)
menuBtn.Size = UDim2.new(0, 45, 0, 34); menuBtn.Text = "MENU"; menuBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200); menuBtn.ZIndex = 6; menuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", menuBtn)
menuBtn.MouseButton1Click:Connect(function() PopupMenu.Visible = not PopupMenu.Visible end)

makeKey("Escape", r1, 45, "ESC")
for i=1, 9 do makeKey(tostring(i), r1, 38, tostring(i)) end; makeKey("Zero", r1, 38, "0")

local r2 = createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3 = createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
makeKey("Return", r3, 50, "ENT")

local r4 = createRow() makeKey("LeftShift", r4, 60, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
makeKey("L", r4, 42, "L") 

local r5 = createRow() makeKey("Space", r5, 250, "SPACE")

-- [6] RENDER & REACH
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
    while task.wait(0.1) do if autoClicker then VirtualUser:ClickButton1(Vector2.new(0,0)) end end
end)
