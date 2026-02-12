local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] ANTI-AFK SYSTEM
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Final_Modern_Keyboard_v12"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Variables
local pickingMode = false
local deleteMode = false
local reachMode = false
local autoClicker = false
local isRecording = false
local macroData = {}
local lastActionTime = 0
local ReachSize = 5

-- [2] MAIN FRAME WITH RGB
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 350)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 3
UIStroke.Parent = MainFrame

-- Smooth RGB Animation
task.spawn(function()
    while true do
        local hue = tick() % 5 / 5
        UIStroke.Color = Color3.fromHSV(hue, 0.8, 1)
        task.wait()
    end
end)

-- [3] BUTTON CREATOR (Optimized)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local function createBtn(text, color, xPos, width, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, width or 65, 0, 30)
    b.Position = UDim2.new(0, xPos, 0, 8)
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = TopBar
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() callback(b) end)
    return b
end

-- Layout for Top Buttons (No Overlapping)
local pickBtn = createBtn("PICK", Color3.fromRGB(160, 140, 0), 10, 50, function() pickingMode = not pickingMode deleteMode = false end)
local delBtn = createBtn("DEL: OFF", Color3.fromRGB(130, 0, 0), 65, 65, function() deleteMode = not deleteMode pickingMode = false end)
local reachBtn = createBtn("REACH: OFF", Color3.fromRGB(90, 0, 150), 135, 85, function() reachMode = not reachMode end)
local clickBtn = createBtn("AUTO: OFF", Color3.fromRGB(0, 100, 100), 225, 75, function() autoClicker = not autoClicker end)
local recBtn = createBtn("REC", Color3.fromRGB(180, 0, 0), 305, 50, function() 
    isRecording = not isRecording 
    if isRecording then macroData = {} lastActionTime = tick() end
end)
local playBtn = createBtn("PLAY", Color3.fromRGB(0, 140, 0), 360, 50, function()
    if #macroData == 0 or isRecording then return end
    task.spawn(function()
        for _, data in ipairs(macroData) do
            task.wait(data.delay)
            VIM:SendKeyEvent(true, data.key, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, data.key, false, game)
        end
    end)
end)
createBtn("CLR", Color3.fromRGB(50, 50, 50), 415, 45, function() macroData = {} end)
createBtn("FPS", Color3.fromRGB(0, 80, 0), 465, 45, function()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("PostProcessEffect") or v:IsA("ParticleEmitter") then v.Enabled = false end
    end
end)
createBtn("HIDE", Color3.fromRGB(180, 0, 0), 610, 60, function() MainFrame.Visible = false end)

-- [4] UPDATE LOOP
RunService.RenderStepped:Connect(function()
    delBtn.Text = deleteMode and "DEL: ON" or "DEL: OFF"
    reachBtn.Text = reachMode and "REACH: ON" or "REACH: OFF"
    clickBtn.Text = autoClicker and "AUTO: ON" or "AUTO: OFF"
    recBtn.Text = isRecording and "STOP" or "REC"
    recBtn.BackgroundColor3 = isRecording and Color3.new(1, 0.5, 0) or Color3.fromRGB(180, 0, 0)
    
    if reachMode then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then
                pcall(function() p.Character.HumanoidRootPart.Size = Vector3.new(ReachSize, ReachSize, ReachSize) p.Character.HumanoidRootPart.Transparency = 1 end)
            end
        end
    end
end)

-- AutoClicker Thread
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoClicker then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.02)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- [5] KEYBOARD ENGINE
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -65)
Container.Position = UDim2.new(0, 10, 0, 55)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local function makeKey(name, row, width, disp)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, width or 48, 0, 38)
    k.Text = disp or name
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1, 1, 1)
    k.Font = Enum.Font.GothamBold
    k.Parent = row
    Instance.new("UICorner", k)
    
    k.MouseButton1Down:Connect(function()
        local key = Enum.KeyCode[name] or Enum.KeyCode.Space
        if pickingMode then
            -- External Key Logic
            local ek = k:Clone() ek.Parent = ScreenGui ek.Position = UDim2.new(0.5,0,0.4,0) ek.Draggable = true
            ek.MouseButton1Down:Connect(function() if deleteMode then ek:Destroy() else VIM:SendKeyEvent(true, key, false, game) end end)
            ek.MouseButton1Up:Connect(function() VIM:SendKeyEvent(false, key, false, game) end)
            pickingMode = false
        else
            VIM:SendKeyEvent(true, key, false, game)
            k.BackgroundColor3 = UIStroke.Color
            if isRecording then
                local now = tick()
                table.insert(macroData, {key = key, delay = now - lastActionTime})
                lastActionTime = now
            end
        end
    end)
    k.MouseButton1Up:Connect(function()
        VIM:SendKeyEvent(false, Enum.KeyCode[name] or Enum.KeyCode.Space, false, game)
        k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        GuiService.SelectedObject = nil
    end)
end

local function createRow()
    local r = Instance.new("Frame") r.Size = UDim2.new(1, 0, 0, 42) r.BackgroundTransparency = 1 r.Parent = Container
    local l = Instance.new("UIListLayout") l.FillDirection = Enum.FillDirection.Horizontal l.Padding = UDim.new(0, 5) l.HorizontalAlignment = Enum.HorizontalAlignment.Center l.Parent = r
    return r
end

local UIList = Instance.new("UIListLayout") UIList.Parent = Container UIList.Padding = UDim.new(0, 5)

-- Final Layout Build
local r1=createRow() for i=1,10 do makeKey("F"..i, r1, 45) end
local r2=createRow() local nums={"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Zero"} local nD={"1","2","3","4","5","6","7","8","9","0"} for i,v in ipairs(nums) do makeKey(v, r2, 45, nD[i]) end
local r3=createRow() for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r3) end
local r4=createRow() for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r4) end
local r5=createRow() makeKey("LeftShift", r5, 75, "Shift") for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r5) end
local r6=createRow() makeKey("LeftControl", r6, 70, "Ctrl") makeKey("Space", r6, 300, "SPACE")

-- [6] OPEN BUTTON
local ShowBtn = Instance.new("TextButton")
ShowBtn.Size = UDim2.new(0, 80, 0, 35)
ShowBtn.Position = UDim2.new(0, 20, 0, 20)
ShowBtn.Text = "OPEN UI"
ShowBtn.BackgroundColor3 = Color3.new(0,0,0)
ShowBtn.TextColor3 = Color3.new(1,1,1)
ShowBtn.Parent = ScreenGui
ShowBtn.Visible = false
Instance.new("UICorner", ShowBtn)
local SS = Instance.new("UIStroke") SS.Color = Color3.new(1,1,1) SS.Parent = ShowBtn

ShowBtn.MouseButton1Click:Connect(function() MainFrame.Visible = true ShowBtn.Visible = false end)
MainFrame:GetPropertyChangedSignal("Visible"):Connect(function() ShowBtn.Visible = not MainFrame.Visible end)

