local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] Anti-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Smasher_V32_Ultimate"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999

-- Global Variables
local pickingMode, reachMode, autoClicker, keyLock, delMode = false, false, false, false, false
local reachValue = 15
local isRecording, macroData, lastActionTime = false, {}, 0

-- [2] OPEN BUTTON
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 70, 0, 40)
OpenBtn.Position = UDim2.new(0, 5, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
OpenBtn.Text = "OPEN UI"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn)

-- [3] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 650, 0, 310)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.new(0, 1, 0)

-- [4] FULL FEATURES MENU (The Hidden Menu)
local FullMenu = Instance.new("Frame")
FullMenu.Size = UDim2.new(0.96, 0, 0, 95)
FullMenu.Position = UDim2.new(0.02, 0, 0.15, 0)
FullMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FullMenu.Visible = false
FullMenu.ZIndex = 15
FullMenu.Parent = MainFrame
Instance.new("UICorner", FullMenu)

local Grid = Instance.new("UIGridLayout", FullMenu)
Grid.CellSize = UDim2.new(0, 85, 0, 28)
Grid.CellPadding = UDim2.new(0, 5, 0, 5)

function createMenuBtn(txt, clr, func)
    local b = Instance.new("TextButton")
    b.Text = txt
    b.BackgroundColor3 = clr
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = FullMenu
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

-- Adding All Missing Features
createMenuBtn("AUTO: OFF", Color3.fromRGB(0, 100, 100), function(b) autoClicker = not autoClicker b.Text = autoClicker and "AUTO: ON" or "AUTO: OFF" end)
createMenuBtn("KEY LOCK", Color3.fromRGB(100, 100, 0), function(b) keyLock = not keyLock b.Text = keyLock and "LOCKED" or "KEY LOCK" end)
createMenuBtn("DEL MODE", Color3.fromRGB(150, 0, 0), function(b) delMode = not delMode b.Text = delMode and "DEL: ON" or "DEL MODE" end)
createMenuBtn("FPS BOOST", Color3.fromRGB(50, 50, 50), function() for _,v in pairs(game:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end end end)
createMenuBtn("REC", Color3.fromRGB(180, 0, 0), function(b) 
    isRecording = not isRecording 
    if isRecording then macroData = {} lastActionTime = tick() b.Text = "STOP" else b.Text = "REC" end 
end)
createMenuBtn("PLAY", Color3.fromRGB(0, 150, 0), function()
    task.spawn(function() for _, d in ipairs(macroData) do task.wait(d.delay) VIM:SendKeyEvent(d.state, d.key, false, game) end end)
end)
createMenuBtn("SAVE", Color3.fromRGB(40, 40, 40), function() if not isfolder("KBD") then makefolder("KBD") end writefile("KBD/macro.json", game:GetService("HttpService"):JSONEncode(macroData)) end)
createMenuBtn("LOAD", Color3.fromRGB(40, 40, 40), function() if isfile("KBD/macro.json") then macroData = game:GetService("HttpService"):JSONDecode(readfile("KBD/macro.json")) end end)
createMenuBtn("CLR MACRO", Color3.fromRGB(80, 0, 0), function() macroData = {} end)

-- [5] TOP BAR
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundTransparency = 1
local TLayout = Instance.new("UIListLayout", TopBar)
TLayout.FillDirection = Enum.FillDirection.Horizontal
TLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TLayout.Padding = UDim.new(0, 8)

function createTop(txt, clr, func)
    local b = Instance.new("TextButton", TopBar)
    b.Size = UDim2.new(0, 90, 0, 32)
    b.Text = txt
    b.BackgroundColor3 = clr
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

createTop("MENU", Color3.fromRGB(0, 120, 255), function() FullMenu.Visible = not FullMenu.Visible end)
createTop("PICK KEY", Color3.fromRGB(150, 150, 0), function(b) pickingMode = not pickingMode b.Text = pickingMode and "SELECT..." or "PICK KEY" end)
createTop("REACH: OFF", Color3.fromRGB(120, 0, 180), function(b) reachMode = not reachMode b.Text = reachMode and "REACH: ON" or "REACH: OFF" end)
createTop("HIDE UI", Color3.fromRGB(60, 60, 60), function() MainFrame.Visible = false OpenBtn.Visible = true end)
createTop("CLOSE", Color3.fromRGB(180, 0, 0), function() ScreenGui:Destroy() end)

OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true OpenBtn.Visible = false end)

-- [6] KEYBOARD ENGINE
local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -65)
Container.Position = UDim2.new(0, 10, 0, 60)
Container.BackgroundTransparency = 1
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 5)

function makeRow()
    local r = Instance.new("Frame", Container)
    r.Size = UDim2.new(1, 0, 0, 38)
    r.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", r)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Padding = UDim.new(0, 4)
    return r
end

function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton", row)
    k.Size = UDim2.new(0, width or 42, 0, 35)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", k)
    
    k.MouseButton1Down:Connect(function()
        if keyLock then return end
        if pickingMode then
            local fk = Instance.new("TextButton", ScreenGui)
            fk.Size = UDim2.new(0, 50, 0, 50)
            fk.Position = UDim2.new(0.5, 0, 0.4, 0)
            fk.Text = name; fk.Draggable = true; fk.BackgroundColor3 = Color3.fromRGB(40,40,40); fk.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", fk)
            fk.MouseButton1Down:Connect(function() if delMode then fk:Destroy() else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) end end)
            fk.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
            pickingMode = false
        else
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = true, delay = tick() - lastActionTime}) lastActionTime = tick() end
        end
    end)
    k.MouseButton1Up:Connect(function()
        if keyLock then return end
        VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game)
        if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], state = false, delay = tick() - lastActionTime}) lastActionTime = tick() end
    end)
end

-- Layout Build
local r1 = makeRow()
makeKey("Escape", r1, 50, "ESC")
for i=1,9 do makeKey(tostring(i), r1, 38, tostring(i)) end; makeKey("Zero", r1, 38, "0")

local r2 = makeRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3 = makeRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
makeKey("Return", r3, 55, "ENTER")

local r4 = makeRow() makeKey("LeftShift", r4, 60, "SHIFT") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5 = makeRow() makeKey("Space", r5, 250, "SPACE")

-- [7] LOOPS
RunService.RenderStepped:Connect(function()
    if reachMode then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(reachValue, reachValue, reachValue)
                p.Character.HumanoidRootPart.Transparency = 0.8
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do if autoClicker then VirtualUser:ClickButton1(Vector2.new()) end end
end)
