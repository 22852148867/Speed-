-- ============================================
-- BLOX FRUITS - CAMERA LOCK SCRIPT (MOBILE COMPACT)
-- "Auto-aim camera lock with minimalist mobile UI"
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

-- ============================================
-- DEFAULT SETTINGS
-- ============================================

local Settings = {
    JoinTeam = "Pirates",
    CameraLock = true,
    LockRange = 150,
    SmoothSpeed = 0.15,
}

-- ============================================
-- VARIABLES
-- ============================================

local LockedTarget = nil
local CameraLocked = Settings.CameraLock
local MenuFrame = nil
local isDragging = false
local dragStart = nil
local frameStart = nil
local lastUpdate = 0

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function Notify(text)
    print("[Speed Script] " .. text)
end

-- ============================================
-- GET ENEMIES
-- ============================================

local function IsEnemy(otherPlayer)
    if not otherPlayer or not otherPlayer.Character then
        return false
    end
    
    if otherPlayer == Player then
        return false
    end
    
    local otherChar = otherPlayer.Character
    if not otherChar:FindFirstChild("HumanoidRootPart") or not otherChar:FindFirstChild("Humanoid") then
        return false
    end
    
    if otherChar.Humanoid.Health <= 0 then
        return false
    end
    
    if otherPlayer.Team and Player.Team and otherPlayer.Team == Player.Team then
        return false
    end
    
    return true
end

local function GetNearestEnemy()
    local nearest = nil
    local nearestDistance = Settings.LockRange
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if IsEnemy(otherPlayer) then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local distance = (otherChar.HumanoidRootPart.Position - RootPart.Position).Magnitude
                
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = otherChar
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
    
    -- Целимся в голову с небольшим смещением вверх
    local targetPos = targetHead.Position + Vector3.new(0, 0.3, 0)
    
    -- Получаем позицию камеры
    local cameraPos = Camera.CFrame.Position
    
    -- Вычисляем новое направление камеры
    local direction = (targetPos - cameraPos).Unit
    local newCFrame = CFrame.new(cameraPos, cameraPos + direction)
    
    -- Плавная интерполяция
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.SmoothSpeed)
end

local function UpdateCameraLock()
    if not CameraLocked then
        LockedTarget = nil
        return
    end
    
    -- Проверяем текущую цель
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
    
    -- Ищем новую цель если нет текущей
    if not LockedTarget then
        LockedTarget = GetNearestEnemy()
    end
    
    -- Применяем блокировку
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
-- CREATE MENU (SMALL & CENTERED)
-- ============================================

local function CreateMenu()
    -- Main Screen Gui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Menu Frame (МАЛЕНЬКОЕ И В ЦЕНТРЕ)
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 180, 0, 120)
    Menu.Position = UDim2.new(0.5, -90, 0.5, -60)
    Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Menu.BorderSizePixel = 0
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 12)
    MenuCorner.Parent = Menu
    
    -- Header (для перетаскивания)
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    -- ON/OFF Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.65, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.30, 0)
    ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = CameraLocked and "ON" or "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 16
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = Menu
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        CameraLocked = not CameraLocked
        LockedTarget = nil
        ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
        ToggleButton.Text = CameraLocked and "ON" or "OFF"
        Notify("Camera Lock: " .. (CameraLocked and "ENABLED ✅" or "DISABLED ❌"))
    end)
    
    -- ============================================
    -- DRAG FUNCTIONALITY
    -- ============================================
    
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    Header.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = Menu.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            Menu.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input == dragInput then
            dragging = false
            dragInput = nil
        end
    end)
    
    MenuFrame = ScreenGui
end

-- ============================================
-- MAIN LOOP
-- ============================================

RunService.RenderStepped:Connect(function()
    if not Character or not Character.Parent then
        return
    end
    
    pcall(function()
        UpdateCameraLock()
    end)
end)

-- ============================================
-- CHARACTER RESPAWN
-- ============================================

Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    LockedTarget = nil
end)

-- ============================================
-- INITIALIZATION
-- ============================================

JoinTeam(Settings.JoinTeam)
CreateMenu()

Notify("Скрипт загружен! Меню готово. Тащи за заголовок.")
