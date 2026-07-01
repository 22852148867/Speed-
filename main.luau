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
local MenuOpen = false
local Icon = nil
local MenuFrame = nil

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
            local distance = (otherChar.HumanoidRootPart.Position - RootPart.Position).Magnitude
            
            if distance < nearestDistance then
                nearestDistance = distance
                nearest = otherChar
            end
        end
    end
    
    return nearest
end

-- ============================================
-- CAMERA LOCK
-- ============================================

local function LockCameraOnTarget(targetChar)
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        LockedTarget = nil
        return
    end
    
    local targetPos = targetChar.HumanoidRootPart.Position
    local targetHead = targetChar:FindFirstChild("Head")
    
    if targetHead then
        targetPos = targetHead.Position
    end
    
    local currentCFrame = Camera.CFrame
    local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
    
    Camera.CFrame = currentCFrame:Lerp(newCFrame, Settings.SmoothSpeed)
end

local function UpdateCameraLock()
    if not CameraLocked then
        return
    end
    
    if not LockedTarget or not LockedTarget.Parent or LockedTarget.Humanoid.Health <= 0 then
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
-- CREATE ICON
-- ============================================

local function CreateIcon()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "IconGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Icon Button
    local IconButton = Instance.new("TextButton")
    IconButton.Name = "IconButton"
    IconButton.Size = UDim2.new(0, 50, 0, 50)
    IconButton.Position = UDim2.new(1, -70, 1, -70)
    IconButton.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
    IconButton.BorderSizePixel = 0
    IconButton.Text = "⚡"
    IconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    IconButton.TextSize = 24
    IconButton.Font = Enum.Font.GothamBold
    IconButton.Parent = ScreenGui
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 25)
    IconCorner.Parent = IconButton
    
    IconButton.MouseButton1Click:Connect(function()
        if MenuOpen and MenuFrame then
            MenuFrame:Destroy()
            MenuFrame = nil
            MenuOpen = false
        else
            CreateMenu(ScreenGui, IconButton)
            MenuOpen = true
        end
    end)
    
    Icon = IconButton
    return ScreenGui
end

-- ============================================
-- CREATE MENU
-- ============================================

function CreateMenu(parentGui, iconButton)
    -- Menu Frame
    local MenuBackgroundGui = Instance.new("ScreenGui")
    MenuBackgroundGui.Name = "MenuGui"
    MenuBackgroundGui.ResetOnSpawn = false
    MenuBackgroundGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MenuBackgroundGui.Parent = PlayerGui
    
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 200, 0, 140)
    Menu.Position = UDim2.new(1, -250, 1, -220)
    Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Menu.BorderSizePixel = 0
    Menu.Parent = MenuBackgroundGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 12)
    MenuCorner.Parent = Menu
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Title.BorderSizePixel = 0
    Title.Text = "⚡ SPEED"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Menu
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = Title
    
    -- ON/OFF Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.85, 0, 0.55, 0)
    ToggleButton.Position = UDim2.new(0.075, 0, 0.35, 0)
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
        Icon.BackgroundColor3 = CameraLocked and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(100, 100, 110)
        Notify("Camera Lock: " .. (CameraLocked and "ENABLED" or "DISABLED"))
    end)
    
    MenuFrame = MenuBackgroundGui
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
CreateIcon()

Notify("Скрипт загружен! Тапни иконку ⚡")
