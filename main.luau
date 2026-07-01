-- ============================================
-- BLOX FRUITS - SMART CAMERA LOCK (FIXED DISTANCE)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

-- НАСТРОЙКА ДАЛЬНОСТИ (Только в пределах текущей зоны/острова)
local MaxLockDistance = 300 
local SmoothSpeed = 0.3 -- Плавность наводки

local CameraLocked = true
local LockedTarget = nil

-- ПОИСК БЛИЖАЙШЕГО ВРАГА НА ОСТРОВЕ
local function GetNearestEnemy()
    if not RootPart then return nil end
    
    local nearest = nil
    local nearestDistance = MaxLockDistance
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            local otherHum = otherChar:FindFirstChild("Humanoid")
            
            if otherHRP and otherHum and otherHum.Health > 0 then
                -- Проверка команды (только соперники)
                local isEnemy = false
                if not Player.Team or not otherPlayer.Team then
                    isEnemy = true
                elseif otherPlayer.Team ~= Player.Team then
                    isEnemy = true
                end
                
                if isEnemy then
                    local distance = (otherHRP.Position - RootPart.Position).Magnitude
                    
                    -- Проверяем, входит ли враг в наш радиус
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearest = otherChar
                    end
                end
            end
        end
    end
    
    return nearest
end

-- ОБНОВЛЕНИЕ НАВОДКИ
local function UpdateCameraLock()
    if not CameraLocked then
        LockedTarget = nil
        return
    end
    
    if LockedTarget then
        local hum = LockedTarget:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 or not LockedTarget.Parent then
            LockedTarget = nil
        else
            -- Если цель убежала за пределы 300 метров, сбрасываем её
            local targetHRP = LockedTarget:FindFirstChild("HumanoidRootPart")
            if targetHRP and RootPart then
                local dist = (targetHRP.Position - RootPart.Position).Magnitude
                if dist > MaxLockDistance then
                    LockedTarget = nil
                end
            end
        end
    end
    
    if not LockedTarget then
        LockedTarget = GetNearestEnemy()
    end
    
    if LockedTarget and LockedTarget:FindFirstChild("Head") then
        local targetPos = LockedTarget.Head.Position + Vector3.new(0, 0.5, 0)
        local cameraPos = Camera.CFrame.Position
        
        local direction = (targetPos - cameraPos)
        if direction.Magnitude > 0 then
            direction = direction.Unit
            local newCFrame = CFrame.new(cameraPos, cameraPos + direction)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, SmoothSpeed)
        end
    end
end

-- СОЗДАНИЕ МИНИМАЛИСТИЧНОГО МЕНЮ
local function CreateMenu()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 180, 0, 80)
    Menu.Position = UDim2.new(0.5, -90, 0.2, 0)
    Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Menu.BorderSizePixel = 0
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 12)
    MenuCorner.Parent = Menu
    
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED AIM"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.45, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    ToggleButton.Text = "AIM: ON"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = Menu
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        CameraLocked = not CameraLocked
        LockedTarget = nil
        ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
        ToggleButton.Text = CameraLocked and "AIM: ON" or "AIM: OFF"
    end)
    
    -- ПЕРЕТАСКИВАНИЕ ПАЛЬЦЕМ
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    Header.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Menu.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- СТАРТ
task.spawn(function()
    CreateMenu()
    RunService.RenderStepped:Connect(UpdateCameraLock)
end)
-- ============================================

local LockedTarget = nil
local CameraLocked = Settings.CameraLock

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function Notify(text)
    print("[Speed Script] " .. text)
end

-- ============================================
-- GET NEAREST ENEMY
-- ============================================

local function GetNearestEnemy()
    if not RootPart then return nil end
    local nearest = nil
    local nearestDistance = Settings.LockRange
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            local otherHum = otherChar:FindFirstChild("Humanoid")
            
            if otherHRP and otherHum and otherHum.Health > 0 then
                local isEnemy = false
                
                if not Player.Team or not otherPlayer.Team then
                    isEnemy = true
                elseif otherPlayer.Team ~= Player.Team then
                    isEnemy = true
                end
                
                if isEnemy then
                    local distance = (otherHRP.Position - RootPart.Position).Magnitude
                    
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearest = otherChar
                    end
                end
            end
        end
    end
    
    return nearest
end

-- ============================================
-- CAMERA LOCK
-- ============================================

local function LockCameraOnTarget(targetChar)
    if not targetChar or not targetChar.Parent then
        LockedTarget = nil
        return
    end
    
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHead = targetChar:FindFirstChild("Head")
    local targetHum = targetChar:FindFirstChild("Humanoid")
    
    if not targetHRP or not targetHead or not targetHum or targetHum.Health <= 0 then
        LockedTarget = nil
        return
    end
    
    local targetPos = targetHead.Position + Vector3.new(0, 0.5, 0)
    local cameraPos = Camera.CFrame.Position
    
    local direction = (targetPos - cameraPos)
    if direction.Magnitude > 0 then
        direction = direction.Unit
        local newCFrame = CFrame.new(cameraPos, cameraPos + direction)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.SmoothSpeed)
    end
end

local function UpdateCameraLock()
    if not CameraLocked then
        LockedTarget = nil
        return
    end
    
    if LockedTarget then
        if not LockedTarget.Parent then
            LockedTarget = nil
        else
            local hum = LockedTarget:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then
                LockedTarget = nil
            end
        end
    end
    
    if not LockedTarget then
        LockedTarget = GetNearestEnemy()
    end
    
    if LockedTarget then
        LockCameraOnTarget(LockedTarget)
    end
end

-- ============================================
-- TEAM SELECTION
-- ============================================

local function JoinTeam(teamName)
    if not teamName then return false end
    local Teams = game:GetService("Teams"):GetChildren()
    for _, team in pairs(Teams) do
        if team.Name == teamName then
            Player.Team = team
            return true
        end
    end
    return false
end

-- ============================================
-- CREATE MENU
-- ============================================

local function CreateMenu()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 180, 0, 80)
    Menu.Position = UDim2.new(0.5, -90, 0.5, -40)
    Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Menu.BorderSizePixel = 0
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 12)
    MenuCorner.Parent = Menu
    
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.45, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = CameraLocked and "AIM: ON" or "AIM: OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = Menu
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        CameraLocked = not CameraLocked
        LockedTarget = nil
        ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
        ToggleButton.Text = CameraLocked and "AIM: ON" or "AIM: OFF"
        Notify("Camera Lock: " .. (CameraLocked and "ENABLED ✅" or "DISABLED ❌"))
    end)
    
    -- ============================================
    -- ДОБАВЛЕННЫЙ ДВИЖОК ДЛЯ ПЕРЕТАСКИВАНИЯ НА ТЕЛЕФОНЕ
    -- ============================================
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    Header.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Menu.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ============================================
-- ЗАПУСК СКРИПТА
-- ============================================
task.spawn(function()
    JoinTeam(Settings.JoinTeam)
    CreateMenu()
    
    -- Подключение постоянного цикла слежения за целью
    RunService.RenderStepped:Connect(UpdateCameraLock)
    Notify("Скрипт успешно запущен!")
end)
