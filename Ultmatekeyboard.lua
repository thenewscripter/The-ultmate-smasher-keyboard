local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] ANTI-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Final_Ultra_KBD"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- Global States
local reachValue, speedValue = 5, 16
local autoClicker, reachMode, pickingMode, deleteMode = false, false, false, false
local isRecording, macroData, lastActionTime = false, {}, 0
local externalKeys = {}

-- [2] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 320)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Parent = MainFrame
task.spawn(function()
    while true do Stroke.Color = Color3.fromHSV(tick() % 5 / 5, 0.8, 1) task.wait() end
end)

-- [3] SIDEBAR MENU
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.Position = UDim2.new(1, 10, 0, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar)

local function createToggle(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = Sidebar
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

-- Save/Load Logic
local function saveProfile()
    local data = {}
    for _, k in pairs(externalKeys) do
        if k.Parent then
            table.insert(data, {Name = k.Name, Pos = {k.Position.X.Scale, k.Position.X.Offset, k.Position.Y.Scale, k.Position.Y.Offset}})
        end
    end
    pcall(function() writefile("KBD_Layout.json", HttpService:JSONEncode(data)) end)
end

local function spawnExternal(name, pos)
    local k = Instance.new("TextButton")
    k.Name = name k.Text = name k.Size = UDim2.new(0, 50, 0, 50)
    k.Position = pos or UDim2.new(0.5, 0, 0.4, 0)
    k.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    k.TextColor3 = Color3.new(1,1,1)
    k.Draggable = true k.Parent = ScreenGui
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function()
        if deleteMode then k:Destroy() else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) end
    end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
    table.insert(externalKeys, k)
end

createToggle("Pick Key", 40, function() pickingMode = not pickingMode end)
createToggle("Del Mode", 75, function() deleteMode = not deleteMode end)
createToggle("SAVE Layout", 110, function() saveProfile() end)
createToggle("LOAD Layout", 145, function()
    pcall(function()
        local data = HttpService:JSONDecode(readfile("KBD_Layout.json"))
        for _, v in pairs(externalKeys) do v:Destroy() end externalKeys = {}
        for _, info in pairs(data) do spawnExternal(info.Name, UDim2.new(info.Pos[1], info.Pos[2], info.Pos[3], info.Pos[4])) end
    end)
end)
createToggle("Reach: OFF", 180, function(b) reachMode = not reachMode end)
createToggle("Auto: OFF", 215, function(b) autoClicker = not autoClicker end)
createToggle("FPS Boost", 250, function()
    for _, v in pairs(game:GetDescendants()) do if v:IsA("ParticleEmitter") then v.Enabled = false end end
end)

-- [4] MENU BUTTON (☰)
local MenuBtn = Instance.new("TextButton")
MenuBtn.Size = UDim2.new(0, 40, 0, 40)
MenuBtn.Position = UDim2.new(0, -50, 0, 0)
MenuBtn.Text = "☰"
MenuBtn.Parent = MainFrame
Instance.new("UICorner", MenuBtn)
local mOpen = false
MenuBtn.MouseButton1Click:Connect(function()
    mOpen = not mOpen
    Sidebar:TweenPosition(mOpen and UDim2.new(1, 5, 0, 0) or UDim2.new(1, 10, 0, 0), "Out", "Quad", 0.3, true)
end)

-- [5] KEYBOARD ENGINE
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -20)
Container.Position = UDim2.new(0, 10, 0, 10)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, width or 50, 0, 40)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Font = Enum.Font.GothamBold
    k.Parent = row
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function()
        if pickingMode then spawnExternal(name) pickingMode = false 
        else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) k.BackgroundColor3 = Stroke.Color end
    end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) k.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end)
end

local function createRow()
    local r = Instance.new("Frame") r.Size = UDim2.new(1, 0, 0, 45) r.BackgroundTransparency = 1 r.Parent = Container
    local l = Instance.new("UIListLayout") l.FillDirection = Enum.FillDirection.Horizontal l.Padding = UDim.new(0, 5) l.HorizontalAlignment = Enum.HorizontalAlignment.Center l.Parent = r
    return r
end
local UIList = Instance.new("UIListLayout") UIList.Parent = Container UIList.Padding = UDim.new(0, 5)

local r1=createRow() for i=1,10 do makeKey("One", r1, 50, i==10 and "0" or tostring(i)) end
local r2=createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3=createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
local r4=createRow() makeKey("LeftShift", r4, 80, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5=createRow() makeKey("LeftControl", r5, 80, "Ctrl") makeKey("Space", r5, 350, "SPACE")

-- [6] FINAL LOOP
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
    while task.wait(0.1) do
        if autoClicker then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)
