-- [[ MM2 AUTO FARM - FIXED NOCLIP & IMPROVED SCAN ]] --

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local SPEED = 21
local FarmEnabled = false

-- 🛡️ [NOVO] Noclip Ativo
RunService.Stepped:Connect(function()
    if FarmEnabled then
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

---------------------------------------------------------
-- 1. GUI DARK (MESMA ESTRUTURA)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Farm_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 210, 0, 120)
MainFrame.Position = UDim2.new(0.5, -105, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 150, 0, 42)
ToggleBtn.Position = UDim2.new(0.5, -75, 0.55, -21)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 30)
ToggleBtn.Text = "FARM: OFF"
ToggleBtn.Parent = MainFrame

---------------------------------------------------------
-- 2. BUSCA DE MOEDAS OTIMIZADA
---------------------------------------------------------
local function getCoins()
    local coins = {}
    -- Otimização: Procura em todo o Workspace, mas garante que são partes interativas
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- MM2 geralmente chama as moedas de "Coin" ou containers
        if (obj.Name == "Coin" or obj.Name == "CoinContainer") and obj:IsA("BasePart") then
            table.insert(coins, obj)
        end
    end
    return coins
end

local function tweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = distance / SPEED
    
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

---------------------------------------------------------
-- 3. LOOP PRINCIPAL (FIXED)
---------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.5) -- Aumentei levemente o wait para não sobrecarregar
        
        if FarmEnabled then
            -- Anti-AFK
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
            
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local coins = getCoins()
                
                if #coins > 0 then
                    for _, coin in ipairs(coins) do
                        if not FarmEnabled then break end
                        -- Verifica se a moeda ainda existe antes de ir
                        if coin and coin.Parent then
                            tweenTo(coin.CFrame)
                        end
                    end
                else
                    -- Só sobe se REALMENTE não houver moedas
                    local hrp = character.HumanoidRootPart
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
                    task.wait(3)
                end
            end
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    FarmEnabled = not FarmEnabled
    ToggleBtn.Text = FarmEnabled and "FARM: ON" or "FARM: OFF"
end)
