-- ============================================
-- BLOX FRUITS - PERMANENT ESP + TOGGLE AIMBOT
-- ============================================

print("!!! SCRIPT LOADED: ESP IS ALWAYS ON !!!")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 15)
if not PlayerGui then return end

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 10)
local RootPart = Character:WaitForChild("HumanoidRootPart", 10)

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 10)
    RootPart = char:WaitForChild("HumanoidRootPart", 10)
end)

-- НАСТРОЙКИ
local MaxLockDistance = 800 -- Радиус аима
local MaxLockDistanceESP = 5000 -- Радиус ВХ (5000 метров)
local SmoothSpeed = 0.7 -- Скорость прилипания аима
local CameraLocked = false -- АИМБОТ ИЗНАЧАЛЬНО ВЫКЛЮЧЕН

local LockedTarget = nil

-- Проверка на друзей в Roblox (не подсвечивает и не лочит друзей)
local function IsValidEnemy(otherPlayer)
    if not otherPlayer or otherPlayer == Player then return false end
    local isFriend = false
    pcall(function()
        isFriend = Player:IsFriendsWith(otherPlayer.UserId)
    end)
    if isFriend then return false end
    return true
end

-- ============================================
-- СИСТЕМА ПОСТОЯННОГО ВХ (ВКЛЮЧАЕТСЯ СРАЗУ И НАВСЕГДА)
-- ============================================
local function CreateESP(targetPlayer)
    if not IsValidEnemy(targetPlayer) then return end

    local function ApplyESP(char)
        task.wait(0.5)
        if not char or not char.Parent then return end
        local head = char:WaitForChild("Head", 10)
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if not head or not hum or not hrp then return end

        if head:FindFirstChild("EnemyESP") then head.EnemyESP:Destroy() end

        -- Создаем 3D текст над головой врага
        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = "EnemyESP"
        BillboardGui.Size = UDim2.new(0, 160, 0, 55)
        BillboardGui.AlwaysOnTop = true
        BillboardGui.ExtentsOffset = Vector3.new(0, 3, 0)
        BillboardGui.Enabled = true -- ВСЕГДА ВКЛЮЧЕНО ПРИ СТАРТЕ
        BillboardGui.Parent = head

        -- Ник челика
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, 0, 0.33, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = targetPlayer.DisplayName or targetPlayer.Name
        NameLabel.TextColor3 = Color3.fromRGB(255, 60, 60) -- Красный ник врага
        NameLabel.TextSize = 12
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextStrokeTransparency = 0
        NameLabel.Parent = BillboardGui

        -- Здоровье (ХП)
        local HealthLabel = Instance.new("TextLabel")
        HealthLabel.Size = UDim2.new(1, 0, 0.33, 0)
        HealthLabel.Position = UDim2.new(0, 0, 0.33, 0)
        HealthLabel.BackgroundTransparency = 1
        HealthLabel.Text = "HP: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
        HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        HealthLabel.TextSize = 10
        HealthLabel.Font = Enum.Font.GothamBold
        HealthLabel.TextStrokeTransparency = 0
        HealthLabel.Parent = BillboardGui

        -- Дистанция в метрах
        local DistLabel = Instance.new("TextLabel")
        DistLabel.Size = UDim2.new(1, 0, 0.33, 0)
        DistLabel.Position = UDim2.new(0, 0, 0.66, 0)
        DistLabel.BackgroundTransparency = 1
        DistLabel.Text = "0m"
        DistLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        DistLabel.TextSize = 10
        DistLabel.Font = Enum.Font.GothamBold
        DistLabel.TextStrokeTransparency = 0
        DistLabel.Parent = BillboardGui

        -- Динамическое обновление ХП при ударах
        local healthConn
        healthConn = hum.HealthChanged:Connect(function(health)
            if BillboardGui and BillboardGui.Parent and hum and hum.Parent then
                HealthLabel.Text = "HP: " .. math.floor(health) .. " / " .. math.floor(hum.MaxHealth)
                if health < (hum.MaxHealth * 0.3) then
                    HealthLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Краснеет, если мало лоу хп
                else
                    HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
                end
            else
                healthConn:Disconnect()
            end
        end)

        -- Динамический просчет расстояния до 5000 метров
        local renderConn
        renderConn = RunService.RenderStepped:Connect(function()
            if BillboardGui and BillboardGui.Parent and RootPart and hrp and hrp.Parent then
                local distance = (hrp.Position - RootPart.Position).Magnitude
                
                -- Если челик ближе 5000м, показываем инфу и обновляем метры
                if distance <= MaxLockDistanceESP then
                    BillboardGui.Enabled = true
                    DistLabel.Text = "[" .. math.floor(distance) .. "m]"
                else
                    BillboardGui.Enabled = false -- Прячем, если улетел дальше 5000м
                end
            else
                renderConn:Disconnect()
            end
        end)
    end

    if targetPlayer.Character then task.spawn(ApplyESP, targetPlayer.Character) end
    targetPlayer.CharacterAdded:Connect(function(char) task.spawn(ApplyESP, char) end)
end

-- Включаем ВХ для текущих игроков в комнате и новых зашедших
for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- ============================================
-- ЛОГИКА АИМБОТА (УПРАВЛЯЕТСЯ КНОПКОЙ)
-- ============================================
local function GetNearestEnemy()
    if not RootPart then return nil end
    local nearest = nil
    local nearestDistance = MaxLockDistance
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer.Character and IsValidEnemy(otherPlayer) then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            local otherHum = otherChar:FindFirstChild("Humanoid")
            
            if otherHRP and otherHum and otherHum.Health > 0 then
                local distance = (otherHRP.Position - RootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = otherChar
                end
            end
        end
    end
    return nearest
end

local function UpdateCameraLock()
    if not CameraLocked then
        LockedTarget = nil
        return
    end
    
    if LockedTarget then
        local hum = LockedTarget:FindFirstChild("Humanoid")
        local hrp = LockedTarget:FindFirstChild("HumanoidRootPart")
        
        if not hum or hum.Health <= 0 or not LockedTarget.Parent or not hrp then
            LockedTarget = nil
        elseif RootPart then
            local dist = (hrp.Position - RootPart.Position).Magnitude
            if dist > MaxLockDistance then LockedTarget = nil end
        end
    end
    
    if not LockedTarget then LockedTarget = GetNearestEnemy() end
    
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

-- ИНТЕРФЕЙС МЕНЮ
local function CreateMenu()
    local oldGui = PlayerGui:FindFirstChild("SpeedScriptGui")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 180, 0, 80)
    Menu.Position = UDim2.new(0.1, 0, 0.15, 0)
    Menu.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Menu.BorderSizePixel = 0
    Menu.Active = true
    Menu.Draggable = true
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 10)
    MenuCorner.Parent = Menu
    
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 28)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED SCRIPT"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.45, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
    ToggleButton.Text = "AIMBOT: DISABLED"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 12
-- Проверка: не целиться в себя и друзей из френдлиста
local function IsValidEnemy(otherPlayer)
    if not otherPlayer or otherPlayer == Player then return false end
    pcall(function()
        if Player:IsFriendsWith(otherPlayer.UserId) then 
            return false 
        end
    end)
    return true
end

-- Поиск цели
local function GetNearestEnemy()
    if not RootPart then return nil end
    local nearest = nil
    local nearestDistance = MaxLockDistance
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer.Character and IsValidEnemy(otherPlayer) then
            local otherChar = otherPlayer.Character
            local otherHRP = otherChar:FindFirstChild("HumanoidRootPart")
            local otherHum = otherChar:FindFirstChild("Humanoid")
            
            if otherHRP and otherHum and otherHum.Health > 0 then
                local distance = (otherHRP.Position - RootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = otherChar
                end
            end
        end
    end
    return nearest
end

-- Логика удержания камеры
local function UpdateCameraLock()
    if not CameraLocked then
        LockedTarget = nil
        return
    end
    
    if LockedTarget then
        local hum = LockedTarget:FindFirstChild("Humanoid")
        local hrp = LockedTarget:FindFirstChild("HumanoidRootPart")
        
        if not hum or hum.Health <= 0 or not LockedTarget.Parent or not hrp then
            LockedTarget = nil
        elseif RootPart then
            local dist = (hrp.Position - RootPart.Position).Magnitude
            if dist > MaxLockDistance then
                LockedTarget = nil
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

-- СТАБИЛЬНЫЙ ИНТЕРФЕЙС (ГАРАНТИРОВАННОЕ ОТОБРАЖЕНИЕ)
local function CreateMenu()
    -- Чистим старые дубликаты
    local oldGui = PlayerGui:FindFirstChild("SpeedScriptGui")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpeedScriptGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Главная панель (Сдвинута ближе к левой части экрана, чтобы не конфликтовать с кнопками Blox Fruits)
    local Menu = Instance.new("Frame")
    Menu.Name = "Menu"
    Menu.Size = UDim2.new(0, 190, 0, 90)
    Menu.Position = UDim2.new(0.1, 0, 0.15, 0)
    Menu.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Menu.BorderSizePixel = 0
    Menu.Active = true
    Menu.Draggable = true -- Нативный метод Roblox перетаскивания для мобилок
    Menu.Parent = ScreenGui
    
    local MenuCorner = Instance.new("UICorner")
    MenuCorner.CornerRadius = UDim.new(0, 10)
    MenuCorner.Parent = Menu
    
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 28)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Header.BorderSizePixel = 0
    Header.Parent = Menu
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 1, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ SPEED AIMBOT"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Header
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "Toggle"
    ToggleButton.Size = UDim2.new(0.9, 0, 0.45, 0)
    ToggleButton.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
    ToggleButton.Text = "AIMBOT: DISABLED"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 12
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Parent = Menu
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        CameraLocked = not CameraLocked
        LockedTarget = nil
        if CameraLocked then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 110)
            ToggleButton.Text = "AIMBOT: ACTIVE ✅"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
            ToggleButton.Text = "AIMBOT: DISABLED"
        end
    end)
    
    print("!!! GUI CREATED SUCCESSFULLY !!!")
end

-- СТАРТ
task.spawn(function()
    CreateMenu()
    RunService.RenderStepped:Connect(UpdateCameraLock)
end)
