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
    LockRange = 100,
    SmoothSpeed = 0.1,
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
    if not otherChar:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    if otherPlayer.Team ~= Player.Team then
        return true
    end
    
    return false
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
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") or not targetChar:FindFirstChild("Head") then
        LockedTarget = nil
        return
    end
    
    if targetChar.Humanoid.Health <= 0 then
        LockedTarget = nil
        return
    end
    
    local targetHead = targetChar:FindFirstChild("Head")
    local targetPos = targetHead.Position + Vector3.new(0, 0.5, 0)
    
    local currentCFrame = Camera.CFrame
    local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
    
    Camera.CFrame = currentCFrame:Lerp(newCFrame, Settings.SmoothSpeed)
end

local function UpdateCameraLock()
    if not CameraLocked then
        return
    end
    
    if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("Humanoid") or LockedTarget.Humanoid.Health <= 0 then
        LockedTarget = nil
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
-- CREATE MENU (CENTERED WITH DRAG)
-- ============================================

local function CreateMenu()
    -- Main Screen Gui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Menu Frame (CENTERED)
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 220, 0, 160)
    Menu.Position = UDim2.new(0.5, -110, 0.5, -80)  -- Центр экрана
    Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Menu.BorderSizePixel = 0
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 15)
    MenuCorner.Parent = Menu
    
    -- Header (для перетаскивания)
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 15)
    HeaderCorner.Parent = Header
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    -- ON/OFF Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.6, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.32, 0)
    ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = CameraLocked and "ON" or "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 18
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = Menu
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        CameraLocked = not CameraLocked
        LockedTarget = nil
        ToggleButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
        ToggleButton.Text = CameraLocked and "ON" or "OFF"
        Notify("Camera Lock: " .. (CameraLocked and "ENABLED" or "DISABLED"))
    end)
    
    -- ============================================
    -- DRAG FUNCTIONALITY
    -- ============================================
    
    Header.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = UserInputService:GetMouseLocation()
            frameStart = Menu.Position
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentMouse = UserInputService:GetMouseLocation()
            local delta = currentMouse - dragStart
            
            Menu.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
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
    
    UpdateCameraLock()
end)

-- ============================================
-- CHARACTER RESPAWN
-- ============================================

Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    LockedTarget = nil
    CameraLocked = Settings.CameraLock
end)

-- ============================================
-- INITIALIZATION
-- ============================================

JoinTeam(Settings.JoinTeam)
CreateMenu()

Notify("Скрипт загружен! Меню в центре экрана. Тащи за заголовок чтобы двигать.")
