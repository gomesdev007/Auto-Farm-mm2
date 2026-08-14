-- [[ MM2 AUTO FARM + ANTI-AFK WITH CUSTOM DARK GUI ]] --

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local SPEED = 21 -- Velocidade fixa (21 studs/s)
local FarmEnabled = false

---------------------------------------------------------
-- 1. CRIAÇÃO DA GUI FLUTUANTE (DARK PURPLE & RED)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Farm_Gui"
ScreenGui.ResetOnSpawn = false

-- Suporte para Executors (CoreGui) ou PlayerGui caso falhar
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
MainFrame.Size = UDim2.new(0, 220, 0, 130)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 22) -- Deep Black/Purple
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Arrastável
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(130, 0, 30) -- Bordas Vermelhas Accent
MainStroke.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "MM2 AUTO FARM"
Title.TextColor3 = Color3.fromRGB(200, 150, 255) -- Purple Accent
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Botão ON / OFF no Centro
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 160, 0, 45)
ToggleBtn.Position = UDim2.new(0.5, -80, 0.55, -22)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 40) -- Desativado
ToggleBtn.Text = "FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Thickness = 1
BtnStroke.Color = Color3.fromRGB(200, 0, 50)
BtnStroke.Parent = ToggleBtn

---------------------------------------------------------
-- 2. LÓGICA DE MOVIMENTO E COLETA
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
    
    -- Interrompe o tween caso desative a função no meio do caminho
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
-- 3. LOOP DE ANTI-AFK REFORÇADO (DENTRO DA FUNÇÃO)
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1)
        if FarmEnabled then
            -- Anti-AFK Roblox padrão
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            
            -- Clique na tela + micro-movimento manual para não travar PC/client
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local hum = character.Humanoid
                -- Força micro passos se o boneco estiver parado
                if hum.MoveDirection.Magnitude == 0 then
                    hum:Move(Vector3.new(0.01, 0, 0.01), false)
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 4. LOOP PRINCIPAL DO AUTO FARM
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
                    -- Sem moedas: Sobe 50 studs e aguarda
                    local hrp = character.HumanoidRootPart
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
                    task.wait(3)
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 5. EVENTO DE TOGGLE DO BOTÃO
---------------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    FarmEnabled = not FarmEnabled
    
    if FarmEnabled then
        ToggleBtn.Text = "FARM: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
        BtnStroke.Color = Color3.fromRGB(0, 200, 100)
    else
        ToggleBtn.Text = "FARM: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 40)
        BtnStroke.Color = Color3.fromRGB(200, 0, 50)
    end
end)
