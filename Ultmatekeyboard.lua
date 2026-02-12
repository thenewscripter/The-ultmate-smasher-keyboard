local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] Anti-AFK
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Final_V18_Keyboard"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- States
local reachValue, speedValue = 10, 16
local autoClicker, reachMode, pickingMode, deleteMode = false, false, false, false
local kbdLock, keyLock = false, false
local isRecording, macroData, lastActionTime = false, {}, 0
local externalKeys = {}

-- [2] Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 360)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.new(1, 1, 1)
UIStroke.Parent = MainFrame

task.spawn(function()
    while true do 
        UIStroke.Color = Color3.fromHSV(tick() % 5 / 5, 0.8, 1) 
        task.wait() 
    end
end)

-- [3] Control Panel (Top Section)
local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, -10, 0, 100)
Controls.Position = UDim2.new(0, 5, 0, 5)
Controls.BackgroundTransparency = 1
Controls.Parent = MainFrame

local UIGrid = Instance.new("UIGridLayout")
UIGrid.CellSize = UDim2.new(0, 78, 0, 28)
UIGrid.CellPadding = UDim2.new(0, 5, 0, 5)
UIGrid.Parent = Controls

local function createBtn(text, color, callback)
    local b = Instance.new("TextButton")
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = Controls
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

-- Functions
local pickBtn = createBtn("Pick Key", Color3.fromRGB(150, 150, 0), function(b) pickingMode = not pickingMode end)
local delBtn = createBtn("Del Mode", Color3.fromRGB(150, 0, 0), function(b) deleteMode = not deleteMode end)
local rchBtn = createBtn("Reach: OFF", Color3.fromRGB(100, 0, 150), function(b) reachMode = not reachMode end)
local clkBtn = createBtn("Auto: OFF", Color3.fromRGB(0, 100, 100), function(b) autoClicker = not autoClicker end)
local recBtn = createBtn("REC", Color3.fromRGB(200, 0, 0), function(b) 
    isRecording = not isRecording 
    if isRecording then macroData = {} lastActionTime = tick() end
end)
createBtn("PLAY", Color3.fromRGB(0, 150, 0), function()
    task.spawn(function()
        for _, d in ipairs(macroData) do
            task.wait(d.delay)
            VIM:SendKeyEvent(true, d.key, false, game)
            task.wait(0.02)
            VIM:SendKeyEvent(false, d.key, false, game)
        end
    end)
end)
createBtn("CLR MACRO", Color3.fromRGB(50, 50, 50), function() macroData = {} end)
createBtn("KBD LOCK", Color3.fromRGB(0, 80, 150), function() kbdLock = not kbdLock MainFrame.Draggable = not kbdLock end)
createBtn("KEY LOCK", Color3.fromRGB(0, 120, 50), function() keyLock = not keyLock end)
createBtn("FPS BOOST", Color3.fromRGB(20, 20, 20), function()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("PostProcessEffect") then v:Destroy() end
    end
end)
createBtn("SAVE", Color3.fromRGB(70, 70, 70), function()
    local data = {}
    for _, k in pairs(externalKeys) do
        if k.Parent then table.insert(data, {Name = k.Name, Pos = {k.Position.X.Scale, k.Position.X.Offset, k.Position.Y.Scale, k.Position.Y.Offset}}) end
    end
    writefile("V18_Layout.json", HttpService:JSONEncode(data))
end)
createBtn("LOAD", Color3.fromRGB(70, 70, 70), function()
    pcall(function()
        local data = HttpService:JSONDecode(readfile("V18_Layout.json"))
        for _, v in pairs(externalKeys) do v:Destroy() end
        externalKeys = {}
        for _, info in pairs(data) do spawnExternal(info.Name, UDim2.new(info.Pos[1], info.Pos[2], info.Pos[3], info.Pos[4])) end
    end)
end)
createBtn("CLOSE", Color3.fromRGB(150, 0, 0), function() MainFrame.Visible = false end)

-- [4] Key Spawner Logic
function spawnExternal(name, pos)
    local k = Instance.new("TextButton")
    k.Name = name k.Text = name:sub(1,1) k.Size = UDim2.new(0, 45, 0, 45)
    k.Position = pos or UDim2.new(0.5, 0, 0.4, 0)
    k.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Draggable = not keyLock
    k.Parent = ScreenGui
    Instance.new("UICorner", k)
    local s = Instance.new("UIStroke") s.Parent = k
    k.MouseButton1Down:Connect(function()
        if deleteMode then k:Destroy() else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) end
    end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
    table.insert(externalKeys, k)
end

-- [5] Keyboard Layout
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -120)
Container.Position = UDim2.new(0, 10, 0, 110)
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
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Font = Enum.Font.GothamBold
    k.Parent = row
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function()
        if pickingMode then spawnExternal(name) pickingMode = false else
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
            k.BackgroundColor3 = UIStroke.Color
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], delay = tick() - lastActionTime}) lastActionTime = tick() end
        end
    end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) k.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)
end

local r1=createRow() local n={"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero"} local nD={"1","2","3","4","5","6","7","8","9","0"} for i,v in ipairs(n) do makeKey(v, r1, 45, nD[i]) end
local r2=createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3=createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
local r4=createRow() makeKey("LeftShift", r4, 70, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5=createRow() makeKey("Space", r5, 300, "SPACE")

-- [6] Logic Loop
RunService.RenderStepped:Connect(function()
    rchBtn.Text = reachMode and "Reach: ON" or "Reach: OFF"
    clkBtn.Text = autoClicker and "Auto: ON" or "Auto: OFF"
    recBtn.Text = isRecording and "STOP" or "REC"
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

-- Toggle Button
local ShowBtn = Instance.new("TextButton")
ShowBtn.Size = UDim2.new(0, 80, 0, 35)
ShowBtn.Position = UDim2.new(0, 20, 0, 20)
ShowBtn.Text = "OPEN"
ShowBtn.Parent = ScreenGui
ShowBtn.Visible = false
ShowBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true ShowBtn.Visible = false end)
MainFrame:GetPropertyChangedSignal("Visible"):Connect(function() ShowBtn.Visible = not MainFrame.Visible end)
