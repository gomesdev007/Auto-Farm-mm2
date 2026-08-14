local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local AutoFarmActive = false

-- Interface Grafica
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2FarmGUI"
ScreenGui.ResetOnSpawn = false

-- Suporte para executores comuns
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 50)
MainFrame.Position = UDim2.new(0.5, -80, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -10, 1, -10)
ToggleButton.Position = UDim2.new(0, 5, 0, 5)
ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
ToggleButton.Text = "FARM: DESLIGADO"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 14
ToggleButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ToggleButton

-- Notificacoes Nativas
local function Notify(text)
    StarterGui:SetCore("SendNotification", {
        Title = "MM2 Auto Farm",
        Text = text,
        Duration = 3
    })
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Identificacao do Container de Moedas
local function GetCoinContainer()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:FindFirstChild("CoinContainer") then
            return child.CoinContainer
        end
    end
    return Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Normal", true)
end

-- Localizador de Moeda Mais Proxima
local function GetClosestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local container = GetCoinContainer()
    
    if not container then return nil end
    
    local closest, shortest = nil, math.huge
    for _, coin in ipairs(container:GetChildren()) do
        if (coin.Name == "Coin" or coin.Name == "MainCoin") and coin:IsA("BasePart") then
            -- Verifica se a moeda ainda está disponível para coleta
            if coin.Transparency < 1 then
                local dist = (hrp.Position - coin.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = coin
                end
            end
        end
    end
    return closest
end

-- Loop de Coleta (Voo / Teleporte de Curta Distancia)
task.spawn(function()
    while true do
        task.wait(0.05)
        if AutoFarmActive then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Noclip Ativo durante o Farm
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                
                local targetCoin = GetClosestCoin()
                if targetCoin then
                    -- Movimento continuo direto na posicao da moeda
                    hrp.CFrame = targetCoin.CFrame
                end
            end
        end
    end
end)

-- Alternancia via Interface Grafica
ToggleButton.MouseButton1Click:Connect(function()
    AutoFarmActive = not AutoFarmActive
    if AutoFarmActive then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        ToggleButton.Text = "FARM: LIGADO"
        Notify("Auto Farm Ativado")
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        ToggleButton.Text = "FARM: DESLIGADO"
        Notify("Auto Farm Desativado")
        
        -- Restaura colisao ao desativar
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end)

-- Controles Globais de Teclado (X, V, P)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        ToggleButton.MouseButton1Click:Fire()
    elseif input.KeyCode == Enum.KeyCode.V then
        if AutoFarmActive then
            ToggleButton.MouseButton1Click:Fire()
        end
    elseif input.KeyCode == Enum.KeyCode.P then
        Notify("Sistema Operacional")
    end
end)
