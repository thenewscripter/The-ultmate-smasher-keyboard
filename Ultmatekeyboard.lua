local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- [1] Anti-AFK (Basic & Safe)
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- [2] GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Smasher_V30_Final"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999 -- Ensures UI is always on top

-- Variables
local pickingMode = false
local reachMode = false
local reachValue = 15

-- [3] OPEN BUTTON (The Savior Button)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenButton"
OpenBtn.Size = UDim2.new(0, 70, 0, 40)
OpenBtn.Position = UDim2.new(0, 5, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
OpenBtn.Text = "OPEN UI"
OpenBtn.TextColor3 = Color3.new(1, 1, 1)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 14
OpenBtn.Visible = false -- Hidden by default
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn)

-- [4] MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 650, 0, 290)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Draggable = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame)
Instance.new("UIStroke", MainFrame).Color = Color3.new(0, 1, 0)

-- [5] TOP MENU BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local MenuLayout = Instance.new("UIListLayout")
MenuLayout.Parent = TopBar
MenuLayout.FillDirection = Enum.FillDirection.Horizontal
MenuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
MenuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
MenuLayout.Padding = UDim.new(0, 8)

-- Helper: Create Menu Button
function createMenuBtn(text, color, func)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 90, 0, 30)
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = TopBar
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

-- Menu Logic
createMenuBtn("PICK KEY", Color3.fromRGB(140, 140, 0), function(b) 
    pickingMode = not pickingMode 
    b.Text = pickingMode and "TAP A KEY..." or "PICK KEY"
end)

createMenuBtn("REACH: OFF", Color3.fromRGB(100, 0, 150), function(b) 
    reachMode = not reachMode 
    b.Text = reachMode and "REACH: ON" or "REACH: OFF"
end)

createMenuBtn("HIDE UI", Color3.fromRGB(60, 60, 60), function() 
    MainFrame.Visible = false 
    OpenBtn.Visible = true -- Show the Open Button immediately
end)

createMenuBtn("CLOSE", Color3.fromRGB(160, 0, 0), function() 
    ScreenGui:Destroy() 
end)

-- Open Button Logic
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

-- [6] FLOATING KEY SPAWNER
function spawnFloatingKey(keyCodeName)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, 50, 0, 50)
    k.Position = UDim2.new(0.5, 0, 0.3, 0)
    k.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    k.Text = keyCodeName
    k.TextColor3 = Color3.new(1,1,1)
    k.Draggable = true
    k.Parent = ScreenGui -- Parent to ScreenGui so it floats freely
    Instance.new("UICorner", k)
    
    k.MouseButton1Down:Connect(function()
        VIM:SendKeyEvent(true, Enum.KeyCode[keyCodeName], false, game)
    end)
    k.MouseButton1Up:Connect(function()
        VIM:SendKeyEvent(false, Enum.KeyCode[keyCodeName], false, game)
    end)
end

-- [7] KEYBOARD LAYOUT ENGINE
local KeysContainer = Instance.new("Frame")
KeysContainer.Size = UDim2.new(1, -20, 1, -55)
KeysContainer.Position = UDim2.new(0, 10, 0, 50)
KeysContainer.BackgroundTransparency = 1
KeysContainer.Parent = MainFrame
Instance.new("UIListLayout", KeysContainer).Padding = UDim.new(0, 5)

function makeRow()
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 38)
    r.BackgroundTransparency = 1
    r.Parent = KeysContainer
    local l = Instance.new("UIListLayout", r)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Padding = UDim.new(0, 4)
    return r
end

function makeKey(name, row, width, display)
    local k = Instance.new("TextButton")
    k.Size = UDim2.new(0, width or 42, 0, 35)
    k.Text = display or name
    k.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    k.TextColor3 = Color3.new(1,1,1)
    k.Parent = row
    Instance.new("UICorner", k)
    
    k.MouseButton1Down:Connect(function()
        if pickingMode then
            spawnFloatingKey(name)
            pickingMode = false -- Reset immediately
            -- We don't press the key in-game when picking
        else
            VIM:SendKeyEvent(true, Enum.KeyCode[name], false, game)
        end
    end)
    
    k.MouseButton1Up:Connect(function()
        if not pickingMode then
            VIM:SendKeyEvent(false, Enum.KeyCode[name], false, game)
        end
    end)
end

-- Building Rows
local r1 = makeRow()
makeKey("Escape", r1, 50, "ESC")
for i=1,9 do makeKey(tostring(i), r1, 38, tostring(i)) end
makeKey("Zero", r1, 38, "0")

local r2 = makeRow()
for _,v in ipairs({"Q","W","E","R","T","Y","U","I","O","P"}) do makeKey(v, r2) end

local r3 = makeRow()
for _,v in ipairs({"A","S","D","F","G","H","J","K","L"}) do makeKey(v, r3) end
makeKey("Return", r3, 55, "ENTER")

local r4 = makeRow()
makeKey("LeftShift", r4, 60, "SHIFT")
for _,v in ipairs({"Z","X","C","V","B","N","M"}) do makeKey(v, r4) end

local r5 = makeRow()
makeKey("Space", r5, 250, "SPACE")

-- [8] REACH LOOP
RunService.RenderStepped:Connect(function()
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

