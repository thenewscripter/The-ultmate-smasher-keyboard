local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] ANTI-AFK SYSTEM
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KBD_V21_PRO"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- States
local reachValue, autoClicker, reachMode, pickingMode, deleteMode = 10, false, false, false, false
local kbdLock, keyLock = false, false
local isRecording, macroData, lastActionTime = false, {}, 0
local externalKeys = {}

-- [2] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 250)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.new(0, 1, 0)
Stroke.Parent = MainFrame
task.spawn(function() 
    while true do 
        Stroke.Color = Color3.fromHSV(tick() % 5 / 5, 0.8, 1) 
        task.wait() 
    end 
end)

-- [3] POPUP SETTINGS MENU
local PopupMenu = Instance.new("Frame")
PopupMenu.Size = UDim2.new(1, 0, 0, 80)
PopupMenu.Position = UDim2.new(0, 0, 0, -85)
PopupMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PopupMenu.Visible = false
PopupMenu.Parent = MainFrame
Instance.new("UICorner", PopupMenu)
Instance.new("UIStroke", PopupMenu).Color = Color3.new(1,1,1)

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, 70, 0, 25)
Grid.CellPadding = UDim2.new(0, 5, 0, 5)
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

-- Menu Buttons
createMenuBtn("PICK KEY", Color3.fromRGB(150, 150, 0), function() pickingMode = not pickingMode end)
createMenuBtn("DEL KEY", Color3.fromRGB(150, 0, 0), function() deleteMode = not deleteMode end)
local rchT = createMenuBtn("REACH: OFF", Color3.fromRGB(100, 0, 150), function() reachMode = not reachMode end)
local clkT = createMenuBtn("AUTO: OFF", Color3.fromRGB(0, 100, 100), function() autoClicker = not autoClicker end)
local recT = createMenuBtn("REC", Color3.fromRGB(200, 0, 0), function() isRecording = not isRecording if isRecording then macroData = {} lastActionTime = tick() end end)
createMenuBtn("PLAY", Color3.fromRGB(0, 150, 0), function()
    task.spawn(function() for _, d in ipairs(macroData) do task.wait(d.delay) VIM:SendKeyEvent(true, d.key, false, game) task.wait(0.02) VIM:SendKeyEvent(false, d.key, false, game) end end)
end)
createMenuBtn("FPS BOOST", Color3.fromRGB(30, 30, 30), function() for _, v in pairs(game:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end end end)
createMenuBtn("LOCK KEYS", Color3.fromRGB(0, 100, 50), function() keyLock = not keyLock end)
createMenuBtn("SAVE", Color3.fromRGB(60, 60, 60), function()
    local d = {} for _, k in pairs(externalKeys) do if k.Parent then table.insert(d, {Name=k.Name, Pos={k.Position.X.Scale, k.Position.X.Offset, k.Position.Y.Scale, k.Position.Y.Offset}}) end end
    writefile("Layout_V21.json", HttpService:JSONEncode(d))
end)
createMenuBtn("LOAD", Color3.fromRGB(60, 60, 60), function()
    pcall(function()
        local d = HttpService:JSONDecode(readfile("Layout_V21.json"))
        for _, v in pairs(externalKeys) do v:Destroy() end externalKeys = {}
        for _, info in pairs(d) do spawnExternal(info.Name, UDim2.new(info.Pos[1], info.Pos[2], info.Pos[3], info.Pos[4])) end
    end)
end)

-- [4] KEYBOARD SYSTEM
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
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Font = Enum.Font.SourceSansBold
    k.TextSize = 14
    k.Parent = row
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function()
        if pickingMode then spawnExternal(name) pickingMode = false else
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
            if isRecording then table.insert(macroData, {key = Enum.KeyCode[name], delay = tick() - lastActionTime}) lastActionTime = tick() end
        end
    end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
    return k
end

-- Layout Build
local r1 = createRow()
local menuToggle = makeKey("Menu", r1, 60, "MENU")
menuToggle.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
menuToggle.MouseButton1Click:Connect(function() PopupMenu.Visible = not PopupMenu.Visible end)

local n = {"One","Two","Three","Four","Five","Six","Seven","Eight","Nine"}
local nD = {"1","2","3","4","5","6","7","8","9"}
for i,v in ipairs(n) do makeKey(v, r1, 45, nD[i]) end

local r2 = createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end
local r3 = createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
local r4 = createRow() makeKey("LeftShift", r4, 70, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end
local r5 = createRow() makeKey("Space", r5, 300, "SPACE")
makeKey("X", r5, 60, "CLOSE").MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- [5] LOGIC UPDATES
RunService.RenderStepped:Connect(function()
    rchT.Text = reachMode and "REACH: ON" or "REACH: OFF"
    clkT.Text = autoClicker and "AUTO: ON" or "AUTO: OFF"
    recT.Text = isRecording and "STOP" or "REC"
    if reachMode then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(reachValue, reachValue, reachValue)
                p.Character.HumanoidRootPart.Transparency = 0.8
            end
        end
    end
end)

function spawnExternal(name, pos)
    local k = Instance.new("TextButton")
    k.Name = name k.Text = name:sub(1,1) k.Size = UDim2.new(0, 45, 0, 45)
    k.Position = pos or UDim2.new(0.5, 0, 0.4, 0)
    k.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Draggable = not keyLock
    k.Parent = ScreenGui
    Instance.new("UICorner", k)
    k.MouseButton1Down:Connect(function() if deleteMode then k:Destroy() else VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game) end end)
    k.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game) end)
    table.insert(externalKeys, k)
end

