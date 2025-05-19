local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local flying = false
local noclip = false
local fogOff = false
local showPlayers = false

local flySpeed = 500
local acceleration = 30
local deceleration = 40

local velocityVector = Vector3.new(0, 0, 0)

-- Sauvegarde de l’éclairage original
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

-- UI Création

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "FlyNoclipFogUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 230, 0, 320) -- hauteur augmentée pour la textbox
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = false -- très important pour ne pas couper textbox
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

-- Label vitesse fly (juste affichage)
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(0.9, 0, 0, 30)
speedLabel.Position = UDim2.new(0.05, 0, 0, 230)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 18
speedLabel.Text = "Vitesse Fly: " .. flySpeed
speedLabel.ZIndex = 15

-- TextBox pour modifier la vitesse fly
local speedInput = Instance.new("TextBox", frame)
speedInput.Size = UDim2.new(0.9, 0, 0, 30)
speedInput.Position = UDim2.new(0.05, 0, 0, 265)
speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 18
speedInput.PlaceholderText = "Entrer vitesse Fly (ex: 500)"
speedInput.Text = tostring(flySpeed)
speedInput.ClearTextOnFocus = false
speedInput.ZIndex = 20

speedInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(speedInput.Text)
        if val and val > 0 then
            flySpeed = val
            speedLabel.Text = "Vitesse Fly: " .. flySpeed
        else
            speedInput.Text = tostring(flySpeed) -- reset si invalide
        end
    end
end)

-- Fonction Fly + Noclip

local bodyVelocity = nil
local runConnection = nil

local function enableFly()
    if flying then return end
    flying = true
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp

    local function updateVelocity()
        if not flying then return end
        local moveDirection = Vector3.new(0, 0, 0)

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + workspace.CurrentCamera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - workspace.CurrentCamera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - workspace.CurrentCamera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + workspace.CurrentCamera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            velocityVector = velocityVector:Lerp(moveDirection.Unit * flySpeed, acceleration * RunService.RenderStepped:Wait())
        else
            velocityVector = velocityVector:Lerp(Vector3.new(0, 0, 0), deceleration * RunService.RenderStepped:Wait())
        end

        bodyVelocity.Velocity = velocityVector
    end

    runConnection = RunService.RenderStepped:Connect(updateVelocity)
end

local function disableFly()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if runConnection then
        runConnection:Disconnect()
        runConnection = nil
    end
    velocityVector = Vector3.new(0, 0, 0)
end

local function toggleFly()
    if flying then
        disableFly()
        btnFly.Text = "Activer Fly"
        btnFly.BackgroundColor3 = Color3.fromRGB(50, 220, 90)
    else
        enableFly()
        btnFly.Text = "Désactiver Fly"
        btnFly.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
end

btnFly.MouseButton1Click:Connect(toggleFly)

-- Noclip

local function noclipLoop()
    if not noclip then return end
    local character = player.Character
    if not character then return end
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.CanCollide == true then
            part.CanCollide = false
        end
    end
end

local noclipConnection = nil

local function enableNoclip()
    if noclip then return end
    noclip = true
    noclipConnection = RunService.Stepped:Connect(noclipLoop)
end

local function disableNoclip()
    noclip = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local character = player.Character
    if not character then return end
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

local function toggleNoclip()
    if noclip then
        disableNoclip()
        btnNoclip.Text = "Activer Noclip"
        btnNoclip.BackgroundColor3 = Color3.fromRGB(50, 140, 220)
    else
        enableNoclip()
        btnNoclip.Text = "Désactiver Noclip"
        btnNoclip.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
end

btnNoclip.MouseButton1Click:Connect(toggleNoclip)

-- Fog toggle

local function toggleFog()
    if fogOff then
        restoreOriginalLighting()
        clearFogEffects()
        fogOff = false
        btnFog.Text = "Enlever Brouillard"
        btnFog.BackgroundColor3 = Color3.fromRGB(220, 220, 70)
    else
        applyNoFogSettings()
        fogOff = true
        btnFog.Text = "Remettre Brouillard"
        btnFog.BackgroundColor3 = Color3.fromRGB(180, 180, 30)
    end
end

btnFog.MouseButton1Click:Connect(toggleFog)

-- Show players toggle

local function toggleShowPlayers()
    if showPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                removeHighlightAndBillboard(plr)
            end
        end
        showPlayers = false
        btnShowPlayers.Text = "Afficher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                applyHighlightAndBillboard(plr)
            end
        end
        showPlayers = true
        btnShowPlayers.Text = "Cacher Joueurs"
        btnShowPlayers.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end

btnShowPlayers.MouseButton1Click:Connect(toggleShowPlayers)

-- Nettoyage lors du respawn
player.CharacterAdded:Connect(function()
    if flying then disableFly() end
    if noclip then disableNoclip() end
    if fogOff then
        restoreOriginalLighting()
        fogOff = false
    end
    if showPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            removeHighlightAndBillboard(plr)
        end
        showPlayers = false
    end
end)
