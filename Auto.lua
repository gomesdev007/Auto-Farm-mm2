-- [[ MM2 AUTO FARM COINS - PERFECT SPEED 21 & DARK GUI ]] --

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local SPEED = 21 -- Velocidade cravada em 21 studs/s (evita kick)
local FarmEnabled = false

---------------------------------------------------------
-- 1. INTERFACE GRÁFICA (GUI DARK COMPACTA E ARRASTÁVEL)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Farm_Hub"
ScreenGui.ResetOnSpawn = false

-- Suporte de exibição segura para Executors
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

-- Janela Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 210, 0, 120)
MainFrame.Position = UDim2.new(0.5, -105, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18) -- Deep Dark
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Arrastável
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(140, 0, 35) -- Borda Vermelha
MainStroke.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "MM2 AUTO FARM"
Title.TextColor3 = Color3.fromRGB(180, 140, 240)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Botão On/Off Centralizado
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 150, 0, 42)
ToggleBtn.Position = UDim2.new(0.5, -75, 0.55, -21)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 30)
ToggleBtn.Text = "FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(220, 70, 70)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Thickness = 1
BtnStroke.Color = Color3.fromRGB(180, 0, 40)
BtnStroke.Parent = ToggleBtn

---------------------------------------------------------
-- 2. BUSCA DE MOEDAS E NAVEGAÇÃO (TWEEN SPEED 21)
---------------------------------------------------------
local function tweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = distance / SPEED
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if not FarmEnabled then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end
end

local function getCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin" or obj.Name == "CoinContainer" then
            if obj:IsA("BasePart") then
                table.insert(coins, obj)
            elseif obj:IsA("Model") and obj.PrimaryPart then
                table.insert(coins, obj.PrimaryPart)
            end
        end
    end
    return coins
end

---------------------------------------------------------
-- 3. ANTI-AFK & MICRO-MOVIMENTO (A CADA 1 SEGUNDO)
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1)
        if FarmEnabled then
            -- Clique virtual na tela
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            
            -- Micro-movimento no personagem para evitar travamento de render do PC/client
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local hum = character.Humanoid
                if hum.MoveDirection.Magnitude == 0 then
                    hum:Move(Vector3.new(0.01, 0, 0.01), false)
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 4. LOOP PRINCIPAL DE COLETA
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if FarmEnabled then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local coins = getCoins()
                
                if #coins > 0 then
                    for _, coin in ipairs(coins) do
                        if not FarmEnabled then break end
                        if coin and coin.Parent then
                            tweenTo(coin.CFrame)
                            task.wait(0.1)
                        end
                    end
                else
                    -- Quando acabam as moedas: Teleporta 50 studs para cima
                    local hrp = character.HumanoidRootPart
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
                    task.wait(3)
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 5. CONTROLE DO BOTÃO ON/OFF
---------------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    FarmEnabled = not FarmEnabled
    
    if FarmEnabled then
        ToggleBtn.Text = "FARM: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 130)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 50, 25)
        BtnStroke.Color = Color3.fromRGB(0, 180, 80)
    else
        ToggleBtn.Text = "FARM: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(220, 70, 70)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 30)
        BtnStroke.Color = Color3.fromRGB(180, 0, 40)
    end
end)
