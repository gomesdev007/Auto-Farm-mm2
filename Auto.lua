local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local AutoFarmActive = false
local FarmSpeed = 32 -- Velocidade de voo ajustada

-- Função de Notificação Nativa do Roblox
local function ShowNotification(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 5,
        Icon = "rbxassetid://4483345998" -- Ícone padrão do Roblox
    })
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Noclip para evitar travamentos
local NoclipConnection = RunService.Stepped:Connect(function()
    if AutoFarmActive then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Lógica de Busca Universal
local function GetCoinContainer()
    return Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Normal", true)
end

local function GetClosestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local container = GetCoinContainer()
    
    if not container then return nil end
    
    local closest = nil
    local shortest = math.huge
    
    for _, coin in ipairs(container:GetChildren()) do
        if coin:IsA("BasePart") and coin.Transparency < 1 then
            local dist = (hrp.Position - coin.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = coin
            end
        end
    end
    return closest
end

-- Loop de Farm
task.spawn(function()
    while true do
        task.wait(0.1)
        if AutoFarmActive then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local target = hrp and GetClosestCoin()
            
            if target and hrp then
                local dist = (hrp.Position - target.Position).Magnitude
                local tween = TweenService:Create(hrp, TweenInfo.new(dist / FarmSpeed, Enum.EasingStyle.Linear), {CFrame = target.CFrame})
                tween:Play()
                tween.Completed:Wait()
            end
        end
    end
end)

-- Controles de Teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Tecla X para Alternar
    if input.KeyCode == Enum.KeyCode.X then
        AutoFarmActive = not AutoFarmActive
        local msg = AutoFarmActive and "Auto Farm ATIVADO" or "Auto Farm DESATIVADO"
        ShowNotification("MM2 Script", msg)
    end
    
    -- Tecla P para Status
    if input.KeyCode == Enum.KeyCode.P then
        ShowNotification("MM2 Script", "Tudo funcionando perfeitamente!")
    end
end)
