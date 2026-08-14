local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local AutoFarmActive = false
local FarmSpeed = 32 -- Velocidade equilibrada para voo rápido e seguro sem dar kick

-- System: Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Sistema de Noclip durante o voo
local NoclipConnection = nil
local function EnableNoclip(enable)
    if enable then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
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
    end
end

-- Busca Dinâmica Universal de Moedas
local function GetCoinContainer()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("CoinContainer") then
            return obj.CoinContainer
        elseif obj.Name == "CoinContainer" or obj.Name == "Normal" then
            return obj
        end
    end
    return Workspace:FindFirstChild("CoinContainer", true)
end

-- Busca a Moeda Mais Próxima
local function GetClosestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local hrp = char.HumanoidRootPart
    local coinContainer = GetCoinContainer()
    if not coinContainer then return nil end
    
    local closestCoin = nil
    local shortestDistance = math.huge
    
    for _, coin in ipairs(coinContainer:GetChildren()) do
        if coin:IsA("BasePart") and (coin.Name == "Coin" or coin.Name == "MainCoin") and coin.Transparency < 1 then
            local distance = (hrp.Position - coin.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestCoin = coin
            end
        end
    end
    
    return closestCoin
end

-- Loop Principal de Farm (Voo via Tween)
local currentTween = nil

local function StartAutoFarm()
    task.spawn(function()
        EnableNoclip(true)
        
        while AutoFarmActive do
            task.wait(0.05)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local targetCoin = GetClosestCoin()
                
                if targetCoin then
                    local distance = (hrp.Position - targetCoin.Position).Magnitude
                    local duration = distance / FarmSpeed
                    
                    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCoin.CFrame})
                    currentTween:Play()
                    
                    local elapsed = 0
                    while currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing and AutoFarmActive do
                        task.wait(0.05)
                        elapsed = elapsed + 0.05
                        
                        -- Se a moeda sumiu ou foi coletada por outro jogador, cancela e pega a próxima
                        if not targetCoin or not targetCoin.Parent or targetCoin.Transparency >= 1 or elapsed > duration then
                            currentTween:Cancel()
                            break
                        end
                    end
                end
            end
        end
        
        if currentTween then
            currentTween:Cancel()
        end
        EnableNoclip(false)
    end)
end

-- Controle via Tecla X
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        AutoFarmActive = not AutoFarmActive
        print("[MM2 Auto Farm] Status:", AutoFarmActive and "ATIVADO" or "DESATIVADO")
        
        if AutoFarmActive then
            StartAutoFarm()
        end
    end
end)
