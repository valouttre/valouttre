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

local velocity = Vector3.new(0,0,0)

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
    Lighting.FogColor = Color3.fromRGB(255,255,255)
    Lighting.Ambient = Color3.fromRGB(255,255,255)
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255)
    Lighting.ColorShift_Top = Color3.fromRGB(255,255,255)
    Lighting.ExposureCompensation = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
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
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextStrokeColor3 = Color3.new(0,0,0)
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
frame.Size = UDim2.new(0, 230, 0, 310)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(24,24,24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = false -- <- corrigé ici
frame.AnchorPoint = Vector2.new(0,0)
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
        btn.BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.15)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)

    return btn
end

local btnFly = createButton(frame, 10, "Activer Fly", Color3.fromRGB(50, 220, 90), Color3.fromRGB(255,255,255))
local btnNoclip = createButton(frame, 65, "Activer Noclip", Color3.fromRGB(50, 140, 220), Color3.fromRGB(255,255,255))
local btnFog = createButton(frame, 120, "Enlever Brouillard", Color3.fromRGB(220, 220, 70), Color3.fromRGB(0,0,0))
local btnShowPlayers = createButton(frame, 175, "Afficher Joueurs", Color3.fromRGB(220, 70, 70), Color3.fromRGB(255,255,255))

-- Label vitesse fly
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(0.9, 0, 0, 30)
speedLabel.Position = UDim2.new(0.05, 0, 0, 230)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 18
speedLabel.Text = "Vitesse Fly: " .. flySpeed
speedLabel.ZIndex = 12 -- <- ajouté

-- TextBox vitesse fly
local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(0.9, 0, 0, 40)
speedBox.Position = UDim2.new(0.05, 0, 0, 265)
speedBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedBox.TextColor3 = Color3.fromRGB(255,255,255)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 20
speedBox.Text = tostring(flySpeed)
speedBox.ClearTextOnFocus = false
speedBox.PlaceholderText = "Entrer vitesse fly"
speedBox.ZIndex = 12 -- <- ajouté

local uicornerSpeedBox = Instance.new("UICorner", speedBox)
uicornerSpeedBox.CornerRadius = UDim.new(0, 10)

speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newSpeed = tonumber(speedBox.Text)
        if newSpeed and newSpeed > 0 then
            flySpeed = newSpeed
            speedLabel.Text = "Vitesse Fly: " .. flySpeed
        else
            speedBox.Text = tostring(flySpeed)
        end
    end
end)

-- Connexions boutons

btnFly.MouseButton1Click:Connect(function()
    flying = not flying
    btnFly.Text = flying and "Désactiver Fly" or "Activer Fly"
    if not flying then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(0,0,0)
                velocity = Vector3.new(0,0,0)
            end
        end
    end
end)

btnNoclip.MouseButton1Click:Connect(function()
    noclip = not noclip
    btnNoclip.Text = noclip and "Désactiver Noclip" or "Activer Noclip"
end)

btnFog.MouseButton1Click:Connect(function()
    fogOff = not fogOff
    if fogOff then
        applyNoFogSettings()
        clearFogEffects()
        btnFog.Text = "Remettre Brouillard"
    else
        restoreOriginalLighting()
        btnFog.Text = "Enlever Brouillard"
    end
end)

btnShowPlayers.MouseButton1Click:Connect(function()
    showPlayers = not showPlayers
    btnShowPlayers.Text = showPlayers and "Cacher Joueurs" or "Afficher Joueurs"

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            if showPlayers then
                applyHighlightAndBillboard(plr)
            else
                removeHighlightAndBillboard(plr)
            end
        end
    end
end)

-- Fly + Noclip Logic

local function noclipLoop()
    if noclip then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end

local function flyLoop(delta)
    if flying then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.new(0,0,0)
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0,1,0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0,1,0)
                end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    velocity = velocity:Lerp(moveDir * flySpeed, acceleration * delta)
                else
                    velocity = velocity:Lerp(Vector3.new(0,0,0), deceleration * delta)
                end

                hrp.Velocity = velocity
            end
        end
    else
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(0,0,0)
            end
        end
    end
end

RunService.Stepped:Connect(function(time, delta)
    noclipLoop()
    flyLoop(delta)
end)

-- Nettoyer au respawn
player.CharacterAdded:Connect(function()
    wait(1)
    if showPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                applyHighlightAndBillboard(plr)
            end
        end
    end
end)
