local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Variables état
local flying = false
local noclip = false
local fogOff = false
local showPlayers = false
local showFruits = false

local flySpeed = 500
local acceleration = 30
local deceleration = 40

local velocityVector = Vector3.new(0, 0, 0)

-- Sauvegarde éclairage original
local originalFogStart = Lighting.FogStart
local originalFogEnd = Lighting.FogEnd
local originalFogColor = Lighting.FogColor
local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalColorShiftBottom = Lighting.ColorShift_Bottom
local originalColorShiftTop = Lighting.ColorShift_Top
local originalExposure = Lighting.ExposureCompensation
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalGlobalShadows = Lighting.GlobalShadows

local function clearFogEffects()
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("Sky") then
            effect:Destroy()
        end
    end
end

local function applyNoFogSettings()
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
    Lighting.ExposureCompensation = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.GlobalShadows = true
end

local function restoreOriginalLighting()
    Lighting.FogStart = originalFogStart
    Lighting.FogEnd = originalFogEnd
    Lighting.FogColor = originalFogColor
    Lighting.Ambient = originalAmbient
    Lighting.Brightness = originalBrightness
    Lighting.ClockTime = originalClockTime
    Lighting.ColorShift_Bottom = originalColorShiftBottom
    Lighting.ColorShift_Top = originalColorShiftTop
    Lighting.ExposureCompensation = originalExposure
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.GlobalShadows = originalGlobalShadows
end

-- Highlight + Billboard pour joueurs
local function applyHighlightAndBillboard(plr)
    if not plr.Character then return end
    local char = plr.Character
    if char:FindFirstChild("RedHighlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RedHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp and not head then return end

    local attachPoint = head or hrp

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerNameBillboard"
    billboard.Adornee = attachPoint
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Text = plr.Name
    textLabel.TextWrapped = true
end

local function removeHighlightAndBillboard(plr)
    if not plr.Character then return end
    local char = plr.Character
    local highlight = char:FindFirstChild("RedHighlight")
    if highlight then highlight:Destroy() end

    local billboard = char:FindFirstChild("PlayerNameBillboard")
    if billboard then billboard:Destroy() end
end

-- Highlight pour fruits
local function applyFruitHighlight(fruit)
    if fruit:FindFirstChild("FruitHighlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "FruitHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = fruit
end

local function removeFruitHighlight(fruit)
    local highlight = fruit:FindFirstChild("FruitHighlight")
    if highlight then highlight:Destroy() end
end

-- UI Création

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "FlyNoclipFogUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 230, 0, 360)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = false
frame.AnchorPoint = Vector2.new(0, 0)
frame.Name = "MainFrame"
frame.ZIndex = 10
frame.AutomaticSize = Enum.AutomaticSize.None

local uicornerFrame = Instance.new("UICorner", frame)
uicornerFrame.CornerRadius = UDim.new(0, 14)

local function createButton(parent, posY, text, color, textColor)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9, 0, 0, 45)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.BackgroundColor3 = color
    btn.TextColor3 = textColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = text
    btn.AutoButtonColor = false
    btn.ZIndex = 11

    local uicorner = Instance.new("UICorner", btn)
    uicorner.CornerRadius = UDim.new(0, 18)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.15)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)

    return btn
end

local btnFly = createButton(frame, 10, "Activer Fly", Color3.fromRGB(50, 220, 90), Color3.fromRGB(255, 255, 255))
local btnNoclip = createButton(frame, 65, "Activer Noclip", Color3.fromRGB(50, 140, 220), Color3.fromRGB(255, 255, 255))
local btnFog = createButton(frame, 120, "Enlever Brouillard", Color3.fromRGB(220, 220, 70), Color3.fromRGB(0, 0, 0))
local btnShowPlayers = createButton(frame, 175, "Afficher Joueurs", Color3.fromRGB(220, 70, 70), Color3.fromRGB(255, 255, 255))
local btnShowFruits = createButton(frame, 230, "Afficher Fruits", Color3.fromRGB(150, 50, 220), Color3.fromRGB(255, 255, 255))

-- Label vitesse fly (juste affichage)
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(0.9, 0, 0, 30)
speedLabel.Position = UDim2.new(0.05, 0, 0, 285)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 18
speedLabel.Text = "Vitesse Fly: " .. flySpeed
speedLabel.ZIndex = 15

-- TextBox pour modifier la vitesse fly
local speedInput = Instance.new("TextBox", frame)
speedInput.Size = UDim2.new(0.9, 0, 0, 35)
speedInput.Position = UDim2.new(0.05, 0, 0, 320)
speedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 18
speedInput.ClearTextOnFocus = false
speedInput.Text = tostring(flySpeed)
speedInput.ZIndex = 15
speedInput.PlaceholderText = "Entrez vitesse fly (ex: 500)"

speedInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(speedInput.Text)
        if val and val > 0 and val <= 5000 then
            flySpeed = val
            speedLabel.Text = "Vitesse Fly: " .. flySpeed
        else
            speedInput.Text = tostring(flySpeed)
        end
    end
end)

-- Fonction vol

local function flyUpdate(dt)
    if not flying then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local moveVector = Vector3.new()

    if UIS:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + hrp.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - hrp.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - hrp.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + hrp.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        moveVector = moveVector + Vector3.new(0,1,0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveVector = moveVector - Vector3.new(0,1,0)
    end

    if moveVector.Magnitude > 0 then
        velocityVector = velocityVector + moveVector.Unit * acceleration
        if velocityVector.Magnitude > flySpeed then
            velocityVector = velocityVector.Unit * flySpeed
        end
    else
        -- freiner la vitesse
        if velocityVector.Magnitude > 0 then
            velocityVector = velocityVector - velocityVector.Unit * deceleration
            if velocityVector.Magnitude < 0 then velocityVector = Vector3.new(0,0,0) end
        end
    end

    hrp.Velocity = velocityVector
end

-- Noclip

local function noclipUpdate()
    if not noclip then return end
    local char = player.Character
    if not char then return end

    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.CanCollide == true then
            part.CanCollide = false
        end
    end
end

-- Toggle functions & buttons

btnFly.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        btnFly.Text = "Désactiver Fly"
        btnFly.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    else
        btnFly.Text = "Activer Fly"
        btnFly.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(0,0,0)
            end
        end
    end
end)

btnNoclip.MouseButton1Click:Connect(function()
    noclip = not noclip
    if noclip then
        btnNoclip.Text = "Désactiver Noclip"
        btnNoclip.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    else
        btnNoclip.Text = "Activer Noclip"
        btnNoclip.BackgroundColor3 = Color3.fromRGB(50, 140, 220)
        local char = player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

btnFog.MouseButton1Click:Connect(function()
    fogOff = not fogOff
    if fogOff then
        btnFog.Text = "Restaurer Brouillard"
        btnFog.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        applyNoFogSettings()
        clearFogEffects()
    else
        btnFog.Text = "Enlever Brouillard"
        btnFog.BackgroundColor3 = Color3.fromRGB(220, 220, 70)
        restoreOriginalLighting()
    end
end)

btnShowPlayers.MouseButton1Click:Connect(function()
    showPlayers = not showPlayers

    if showPlayers then
        btnShowPlayers.Text = "Cacher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                applyHighlightAndBillboard(plr)
            end
        end
    else
        btnShowPlayers.Text = "Afficher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
        for _, plr in pairs(Players:GetPlayers()) do
            removeHighlightAndBillboard(plr)
        end
    end
end)

-- ESP Fruits

local fruitsToESP = {
  "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike", "Flame", 
  "Ice", "Sand", "Dark", "Eagle", "Diamond", "Light", "Rubber", "Ghost", 
  "Magma", "Quake", "Buddha", "Love", "Creation", "Spider", "Sound", "Phoenix", 
  "Portal", "Rumble", "Pain", "Blizzard", "Gravity", "Mammoth", "T-Rex", 
  "Dough", "Shadow", "Venom", "Control", "Gas", "Spirit", "Leopard", "Yeti", 
  "Kitsune", "Dragon"
}
btnShowPlayers.MouseButton1Click:Connect(function()
    showPlayers = not showPlayers

    if showPlayers then
        btnShowPlayers.Text = "Cacher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        -- Appliquer highlight à tous les joueurs
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                applyHighlightAndBillboard(plr)
            end
        end
        -- Quand un nouveau joueur rejoint, lui appliquer aussi
        Players.PlayerAdded:Connect(function(plr)
            if showPlayers and plr ~= player then
                plr.CharacterAdded:Connect(function()
                    wait(1) -- attendre que le personnage soit bien chargé
                    applyHighlightAndBillboard(plr)
                end)
            end
        end)
        -- Quand un joueur part, nettoyer
        Players.PlayerRemoving:Connect(function(plr)
            removeHighlightAndBillboard(plr)
        end)
    else
        btnShowPlayers.Text = "Afficher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
        -- Retirer les highlights et billboards de tous
        for _, plr in pairs(Players:GetPlayers()) do
            removeHighlightAndBillboard(plr)
        end
    end
end)

btnShowFruits.MouseButton1Click:Connect(function()
    showFruits = not showFruits

    if showFruits then
        btnShowFruits.Text = "Cacher Fruits"
        btnShowFruits.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        -- Appliquer highlight à tous les fruits dans workspace (supposé fruits dans Workspace.Fruits)
        local fruitsFolder = Workspace:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in pairs(fruitsFolder:GetChildren()) do
                applyFruitHighlight(fruit)
            end
            fruitsFolder.ChildAdded:Connect(function(fruit)
                if showFruits then
                    applyFruitHighlight(fruit)
                end
            end)
            fruitsFolder.ChildRemoved:Connect(function(fruit)
                removeFruitHighlight(fruit)
            end)
        end
    else
        btnShowFruits.Text = "Afficher Fruits"
        btnShowFruits.BackgroundColor3 = Color3.fromRGB(150, 50, 220)
        -- Retirer les highlights de tous les fruits
        local fruitsFolder = Workspace:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in pairs(fruitsFolder:GetChildren()) do
                removeFruitHighlight(fruit)
            end
        end
    end
end)

-- Lancer les updates dans RunService pour fly et noclip
RunService.RenderStepped:Connect(function(dt)
    if flying then
        flyUpdate(dt)
    end
    if noclip then
        noclipUpdate()
    end
end)


local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Variables
local flying = false
local taxiActive = false
local flySpeed = 500
local velocityVector = Vector3.zero
local acceleration = 30
local currentDestinationName = nil

-- Destinations
local taxiDestinations = {
    {name = "café", pos = Vector3.new(-384.1, 73.1, 339.0)},
    {name = "royaume de rosse", pos = Vector3.new(-12.2, 29.3, 2770.0)},
    {name = "zone végétale", pos = Vector3.new(-1924.3, 6.5, -2561.1)},
    {name = "cimetière", pos = Vector3.new(-5482.3, 48.5, -800.5)},
    {name = "navire maudit", pos = Vector3.new(908.5, 125.1, 32888.1)},
    {name = "froid", pos = Vector3.new(-5923.5, 16.9, -5140.4)},
    {name = "chaud", pos = Vector3.new(-5425.8, 16.0, -5232.4)},
    {name = "raid", pos = Vector3.new(-6449.4, 249.6, -4495.7)},
    {name = "ile au crane", pos = Vector3.new(-2797.1, 2.3, -9471.1)},
    {name = "ile enneiger", pos = Vector3.new(585.5, 401.5, -5356.5)},
    {name = "barbe noire", pos = Vector3.new(3667.8, 13.8, -3480.9)},
    {name = "chateau iverballe", pos = Vector3.new(5652.7, 28.4, -6371.2)},
}

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "TaxiUI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 350)
frame.Position = UDim2.new(0, 30, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 0, 30)
label.Text = "🚁 Menu Taxi Fly"
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 20

local scrolling = Instance.new("ScrollingFrame", frame)
scrolling.Position = UDim2.new(0, 10, 0, 40)
scrolling.Size = UDim2.new(1, -20, 1, -90)
scrolling.CanvasSize = UDim2.new(0, 0, 0, #taxiDestinations * 45)
scrolling.ScrollBarThickness = 6
scrolling.BackgroundTransparency = 1

local speedBox = Instance.new("TextBox", frame)
speedBox.Position = UDim2.new(0, 10, 1, -40)
speedBox.Size = UDim2.new(1, -20, 0, 30)
speedBox.PlaceholderText = "Vitesse (ex: 500)"
speedBox.Text = tostring(flySpeed)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 16
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

-- Noclip
local function enableNoclip()
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- Fly Cancel
local function cancelFly()
    RunService:UnbindFromRenderStep("TaxiFly")
    if hrp then hrp.Velocity = Vector3.zero end
    velocityVector = Vector3.zero
    flying = false
    taxiActive = false
    currentDestinationName = nil
end

-- Fly to destination
local function flyTo(destination)
    RunService:BindToRenderStep("TaxiFly", Enum.RenderPriority.Character.Value + 1, function(dt)
        if flying and taxiActive and character and hrp then
            local direction = destination - hrp.Position
            local dist = direction.Magnitude

            if dist < 5 then
                hrp.CFrame = CFrame.new(destination)
                hrp.Velocity = Vector3.zero
                cancelFly()
                return
            end

            enableNoclip()
            local moveDir = direction.Unit
            velocityVector = velocityVector:Lerp(moveDir * flySpeed, acceleration * dt)
            hrp.Velocity = velocityVector
            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + moveDir)
        end
    end)
end

-- Create destination buttons
for i, dest in ipairs(taxiDestinations) do
    local btn = Instance.new("TextButton", scrolling)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (i - 1) * 45)
    btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Text = dest.name
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        character = player.Character or player.CharacterAdded:Wait()
        hrp = character:WaitForChild("HumanoidRootPart")

        if currentDestinationName == dest.name then
            cancelFly()
            return
        end

        local inputSpeed = tonumber(speedBox.Text)
        if inputSpeed then flySpeed = inputSpeed end

        cancelFly()
        currentDestinationName = dest.name
        flying = true
        taxiActive = true
        velocityVector = Vector3.zero
        flyTo(dest.pos)
    end)
end
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Dollar then -- $ = Shift + 4 sur la plupart des claviers FR
		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then return end

		for _, gui in pairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				gui.Enabled = not gui.Enabled
			end
		end
	end
end)
