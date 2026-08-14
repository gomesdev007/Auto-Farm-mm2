-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║        MURDER MYSTERY 2 - AUTO FARM COINS COMPLETO v3.0              ║
-- ║                  Desenvolvido por Gomes.wqq                          ║
-- ║              100% Funcional - Sem Posições Fixas                     ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES GlOBAIS
-- ═══════════════════════════════════════════════════════════════════════

local SETTINGS = {
	SPEED = 21,
	TELEPORT_HEIGHT = 50,
	ANTI_AFK_TICK = 1,
	COIN_DETECTION_RADIUS = 500,
	PICKUP_RANGE = 4,
	NOCLIP_ENABLED = true
}

-- ═══════════════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════

local isRunning = false
local isGuiMinimized = false
local coinsInGame = {}
local coinsCollected = {}
local targetCoin = nil
local lastAntiAFKTick = 0
local mainLoop = nil
local antiAfkLoop = nil
local noclipLoop = nil

-- ═══════════════════════════════════════════════════════════════════════
-- CRIAR GUI COMPACTA (100x100)
-- ═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2FarmGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Container Principal (Pequeno)
local containerFrame = Instance.new("Frame")
containerFrame.Name = "Container"
containerFrame.Size = UDim2.new(0, 100, 0, 100)
containerFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
containerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
containerFrame.BorderSizePixel = 0
containerFrame.Parent = screenGui

-- Bordas arredondadas
local cornerRadius = Instance.new("UICorner")
cornerRadius.CornerRadius = UDim.new(0, 12)
cornerRadius.Parent = containerFrame

-- Borda branca
local strokeBorder = Instance.new("UIStroke")
strokeBorder.Color = Color3.fromRGB(255, 255, 255)
strokeBorder.Thickness = 2
strokeBorder.Parent = containerFrame

-- ═══════════════════════════════════════════════════════════════════════
-- BOTÃO ON/OFF (No centro da GUI)
-- ═══════════════════════════════════════════════════════════════════════

local statusButton = Instance.new("TextButton")
statusButton.Name = "StatusButton"
statusButton.Size = UDim2.new(0, 90, 0, 90)
statusButton.Position = UDim2.new(0.5, -45, 0.5, -45)
statusButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
statusButton.TextScaled = true
statusButton.TextSize = 16
statusButton.Font = Enum.Font.GothamBold
statusButton.Text = "OFF"
statusButton.BorderSizePixel = 0
statusButton.ClipsDescendants = true
statusButton.Parent = containerFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = statusButton

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE ARRASTE
-- ═══════════════════════════════════════════════════════════════════════

local isDragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = true
		dragStart = input.Position
		startPos = containerFrame.Position
	end
end

local function onInputChanged(input, gameProcessed)
	if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		containerFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
	end
end

local function onInputEnded(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end

containerFrame.InputBegan:Connect(onInputBegan)
UserInputService.InputChanged:Connect(onInputChanged)
UserInputService.InputEnded:Connect(onInputEnded)

-- ═══════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════

local function debugLog(text)
	print("🎮 [MM2 FARM] " .. tostring(text))
end

local function getCoinModel(part)
	-- Tenta encontrar a moeda (pode ser um modelo pai)
	if part:FindFirstAncestorOfClass("Model") then
		local model = part:FindFirstAncestorOfClass("Model")
		if not model:FindFirstChildOfClass("Humanoid") then
			return model
		end
	end
	return part
end

local function isCoin(instance)
	if not instance or not instance.Parent then return false end
	
	-- Verifica o nome da instância
	local name = instance.Name:lower()
	if name:find("coin") or name:find("money") or name:find("cash") or name:find("dollar") then
		return true
	end
	
	-- Verifica descrição se houver
	pcall(function()
		if instance:IsA("Part") or instance:IsA("MeshPart") then
			if instance.Name == "Part" or instance.Name == "MeshPart" then
				-- Pode ser uma moeda se estiver em um modelo com nome de moeda
				local parent = instance.Parent
				if parent then
					local parentName = parent.Name:lower()
					if parentName:find("coin") or parentName:find("money") then
						return true
					end
				end
			end
		end
	end)
	
	return false
end

local function scanForCoins()
	coinsInGame = {}
	coinsCollected = {}
	
	-- Varre TUDO no workspace
	for _, obj in pairs(workspace:GetDescendants()) do
		if isCoin(obj) then
			-- Evita duplicatas
			local alreadyAdded = false
			for _, coin in pairs(coinsInGame) do
				if coin == obj then
					alreadyAdded = true
					break
				end
			end
			
			if not alreadyAdded and obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
				table.insert(coinsInGame, obj)
			end
		end
	end
	
	debugLog("✓ Encontradas " .. #coinsInGame .. " moedas no mapa")
	return #coinsInGame
end

local function findNearestCoin()
	local nearest = nil
	local nearestDistance = math.huge
	
	for _, coin in ipairs(coinsInGame) do
		if coin and coin.Parent and not coinsCollected[coin] then
			pcall(function()
				local coinPos = coin:IsA("Model") and coin:FindFirstChild("PrimaryPart") and coin.PrimaryPart.Position or coin.Position
				local playerPos = humanoidRootPart.Position
				local distance = (coinPos - playerPos).Magnitude
				
				if distance < nearestDistance and distance < SETTINGS.COIN_DETECTION_RADIUS then
					nearestDistance = distance
					nearest = coin
				end
			end)
		end
	end
	
	return nearest, nearestDistance
end

local function moveTowards(targetPos)
	if not character or not humanoidRootPart or not humanoid then return end
	
	local direction = (targetPos - humanoidRootPart.Position)
	local distance = direction.Magnitude
	
	if distance > SETTINGS.PICKUP_RANGE then
		local unitDirection = direction.Unit
		humanoidRootPart.CFrame = humanoidRootPart.CFrame + (unitDirection * SETTINGS.SPEED * 0.016)
	end
end

local function noclipCharacter()
	if not character then return end
	
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function antiAFKTick()
	local currentTick = tick()
	
	if currentTick - lastAntiAFKTick >= SETTINGS.ANTI_AFK_TICK then
		-- Move mouse
		pcall(function()
			mouse:Move(math.random(100, 1820), math.random(100, 980))
		end)
		
		-- Movimento leve
		if humanoid then
			humanoid:Move(Vector3.new(math.random(-1, 1) * 0.05, 0, math.random(-1, 1) * 0.05))
		end
		
		lastAntiAFKTick = currentTick
	end
end

local function teleportUp()
	if not humanoidRootPart then return end
	
	humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, SETTINGS.TELEPORT_HEIGHT, 0)
	wait(1)
end

-- ═══════════════════════════════════════════════════════════════════════
-- MINIMIZAR/MAXIMIZAR GUI (Tecla X)
-- ═══════════════════════════════════════════════════════════════════════

local function toggleGuiSize()
	isGuiMinimized = not isGuiMinimized
	
	if isGuiMinimized then
		containerFrame:TweenSize(UDim2.new(0, 50, 0, 50), "Out", "Quad", 0.2, true)
		statusButton.Visible = false
	else
		statusButton.Visible = true
		containerFrame:TweenSize(UDim2.new(0, 100, 0, 100), "Out", "Quad", 0.2, true)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.X then
		toggleGuiSize()
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- INICIAR FARM
-- ═══════════════════════════════════════════════════════════════════════

local function startFarmingCoins()
	if isRunning then return end
	
	isRunning = true
	statusButton.Text = "ON"
	statusButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
	
	debugLog("✓ FARM INICIADO!")
	
	-- Escaneia moedas inicialmente
	scanForCoins()
	
	-- Loop principal de coleta
	if mainLoop then mainLoop:Disconnect() end
	mainLoop = RunService.Heartbeat:Connect(function()
		if not isRunning then return end
		
		if not character or not humanoid or not humanoidRootPart then return end
		
		-- Noclip
		if SETTINGS.NOCLIP_ENABLED then
			noclipCharacter()
		end
		
		-- Anti AFK
		antiAFKTick()
		
		-- Encontra moeda mais próxima
		targetCoin, targetDistance = findNearestCoin()
		
		if targetCoin then
			-- Pega posição da moeda
			local coinPosition = targetCoin:IsA("Model") and targetCoin:FindFirstChild("PrimaryPart") and targetCoin.PrimaryPart.Position or targetCoin.Position
			
			-- Move na direção da moeda
			moveTowards(coinPosition)
			
			-- Verifica se coletou
			if (coinPosition - humanoidRootPart.Position).Magnitude < SETTINGS.PICKUP_RANGE then
				coinsCollected[targetCoin] = true
				debugLog("💰 Moeda coletada!")
				
				-- Som
				pcall(function()
					local som = Instance.new("Sound")
					som.SoundId = "rbxassetid://12222058"
					som.Volume = 0.2
					som.Parent = humanoidRootPart
					game:GetService("Debris"):AddItem(som, 0.5)
					som:Play()
				end)
			end
		else
			-- Sem moedas, teleporta e recarrega
			debugLog("🎯 Ciclo completo! Teletransportando...")
			teleportUp()
			wait(1)
			scanForCoins()
		end
	end)
	
	-- Loop de noclip constante
	if noclipLoop then noclipLoop:Disconnect() end
	noclipLoop = RunService.Heartbeat:Connect(function()
		if not isRunning or not character then return end
		noclipCharacter()
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- PARAR FARM
-- ═══════════════════════════════════════════════════════════════════════

local function stopFarmingCoins()
	if not isRunning then return end
	
	isRunning = false
	statusButton.Text = "OFF"
	statusButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	
	if mainLoop then
		mainLoop:Disconnect()
		mainLoop = nil
	end
	
	if noclipLoop then
		noclipLoop:Disconnect()
		noclipLoop = nil
	end
	
	-- Reativa colisão
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	if humanoid then
		humanoid:Move(Vector3.new(0, 0, 0))
	end
	
	debugLog("✗ FARM PARADO")
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOTÃO CLICÁVEL
-- ═══════════════════════════════════════════════════════════════════════

statusButton.MouseButton1Click:Connect(function()
	if isRunning then
		stopFarmingCoins()
	else
		startFarmingCoins()
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- RESPAWN DO PERSONAGEM
-- ═══════════════════════════════════════════════════════════════════════

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	if isRunning then
		debugLog("⚠️  Personagem respawnou!")
		stopFarmingCoins()
		wait(2)
		startFarmingCoins()
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- LIMPEZA
-- ═══════════════════════════════════════════════════════════════════════

player.AncestryChanged:Connect(function()
	if player.Parent == nil then
		if isRunning then stopFarmingCoins() end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO FINAL
-- ═══════════════════════════════════════════════════════════════════════

debugLog("════════════════════════════════════════")
debugLog("✓ MM2 Auto Farm v3.0 Carregado!")
debugLog("✓ Clique no botão para ativar/desativar")
debugLog("✓ Pressione X para minimizar a GUI")
debugLog("════════════════════════════════════════")
