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
    LockRange = 250,
    SmoothSpeed = 0.3,
}

-- ============================================
-- VARIABLES
-- ============================================

local LockedTarget = nil
local CameraLocked = Settings.CameraLock
local MenuFrame = nil

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function Notify(text)
    print("[Speed Script] " .. text)
end

-- ============================================
-- GET NEAREST ENEMY (БЕЗ ОГРАНИЧЕНИЙ)
-- ============================================

local function GetNearestEnemy()
    local nearest = nil
    local nearestDistance = Settings.LockRange
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            local otherHum = otherChar:FindFirstChild("Humanoid")
            
            if otherHRP and otherHum and otherHum.Health > 0 then
                -- Проверяем команду (враг = другая команда ИЛИ нет команды)
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
-- CAMERA LOCK (ВСЕГДА РАБОТАЕТ)
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
    
    -- Целимся в голову
    local targetPos = targetHead.Position + Vector3.new(0, 0.5, 0)
    local cameraPos = Camera.CFrame.Position
    
    -- Вычисляем направление
    local direction = (targetPos - cameraPos)
    if direction.Magnitude > 0 then
        direction = direction.Unit
        local newCFrame = CFrame.new(cameraPos, cameraPos + direction)
        
        -- Плавная интерполяция (БЫСТРАЯ)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.SmoothSpeed)
    end
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
    
    -- Применяем блокировку (ВЕЗДЕ, даже в safe zone)
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
    -- Main Screen Gui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Menu Frame
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
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
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
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    -- ON/OFF Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.65, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.35, 0)
    ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = CameraLocked and "ON" or "OFF"
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

Notify("Скрипт загружен! Аим работает ВЕЗДЕ (даже в safe zone).")
