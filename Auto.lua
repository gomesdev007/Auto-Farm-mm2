local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local AutoFarmActive = false
local FarmSpeed = 32
local NoclipConnection = nil
local FarmLoop = nil

-- Função de Notificação Nativa
local function ShowNotification(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3,
        Icon = "rbxassetid://4483345998"
    })
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Sistema de Noclip
local function SetNoclip(state)
    if state then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                if AutoFarmActive then
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        -- Restaura colisão
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- Busca de Moedas
local function GetClosestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local container = Workspace:FindFirstChild("CoinContainer", true) or Workspace:FindFirstChild("Normal", true)
    
    if not container then return nil end
    
    local closest, shortest = nil, math.huge
    for _, coin in ipairs(container:GetChildren()) do
        if coin:IsA("BasePart") and coin.Transparency < 1 then
            local dist = (hrp.Position - coin.Position).Magnitude
            if dist < shortest then shortest = dist; closest = coin end
        end
    end
    return closest
end

-- Loop de Farm
local function StartFarmLoop()
    FarmLoop = task.spawn(function()
        while AutoFarmActive do
            task.wait(0.1)
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
    end)
end

-- Controles
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- X: Ativa
    if input.KeyCode == Enum.KeyCode.X and not AutoFarmActive then
        AutoFarmActive = true
        SetNoclip(true)
        StartFarmLoop()
        ShowNotification("MM2 Script", "Auto Farm ATIVADO")
        
    -- V: Desativa Completamente
    elseif input.KeyCode == Enum.KeyCode.V then
        AutoFarmActive = false
        SetNoclip(false) -- Desconecta noclip e restaura colisão
        if FarmLoop then task.cancel(FarmLoop) end
        
        -- Cancela tweens ativos
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0), {CFrame = char.HumanoidRootPart.CFrame}):Play()
        end
        
        ShowNotification("MM2 Script", "Tudo desativado")
        
    -- P: Status
    elseif input.KeyCode == Enum.KeyCode.P then
        ShowNotification("MM2 Script", "Sistema pronto. Status: " .. (AutoFarmActive and "Ativo" or "Inativo"))
    end
end)
