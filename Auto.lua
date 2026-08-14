-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║        MURDER MYSTERY 2 - AUTO FARM COINS COMPLETO v4.0              ║
-- ║                  Desenvolvido por Gomes.wqq                          ║
-- ║              SEN BUGS - FORÇA INFINITA - FUNCIONAL 100%              ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════

local SETTINGS = {
	SPEED = 40,
	PICKUP_RANGE = 5,
	NOCLIP_ENABLED = true,
	ANTI_GRAVITY = true
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
local noclipLoop = nil
local gravityLoop = nil
local lastCoinCheckTime = 0

-- ═══════════════════════════════════════════════════════════════════════
-- CRIAR GUI MINI (70x70)
-- ═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2FarmGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.Enabled = true
screenGui.Parent = playerGui

local containerFrame = Instance.new("Frame")
containerFrame.Name = "Container"
containerFrame.Size = UDim2.new(0, 70, 0, 70)
containerFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
containerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
containerFrame.BorderSizePixel = 0
containerFrame.Parent = screenGui

local cornerRadius = Instance.new("UICorner")
cornerRadius.CornerRadius = UDim.new(0, 12)
cornerRadius.Parent = containerFrame

local strokeBorder = Instance.new("UIStroke")
strokeBorder.Color = Color3.fromRGB(255, 255, 255)
strokeBorder.Thickness = 2
strokeBorder.Parent = containerFrame

-- ═══════════════════════════════════════════════════════════════════════
-- BOTÃO INTERRUPTOR MINI
-- ═══════════════════════════════════════════════════════════════════════

local statusButton = Instance.new("TextButton")
statusButton.Name = "StatusButton"
statusButton.Size = UDim2.new(0, 60, 0, 60)
statusButton.Position = UDim2.new(0.5, -30, 0.5, -30)
statusButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
statusButton.TextScaled = true
statusButton.TextSize = 14
statusButton.Font = Enum.Font.GothamBold
statusButton.Text = "●"
statusButton.BorderSizePixel = 0
statusButton.ClipsDescendants = true
statusButton.Parent = containerFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = statusButton

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE ARRASTE
-- ═══════════════════════════════════════════════════════════════════════

local isDragging = false
local dragStart = nil
local startPos = nil

containerFrame.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = true
		dragStart = input.Position
		startPos = containerFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		containerFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════

local function debugLog(text)
	print("🎮 [MM2 FARM] " .. tostring(text))
end

local function isCoin(instance)
	if not instance or not instance.Parent then return false end
	
	local name = instance.Name:lower()
	if name:find("coin") or name:find("money") or name:find("cash") or name:find("dollar") then
		return true
	end
	
	return false
end

local function scanForCoins()
	local newCoins = {}
	local totalCoins = 0
	
	-- Varre TODO o workspace buscando moedas
	for _, obj in pairs(workspace:GetDescendants()) do
		if isCoin(obj) then
			if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
				table.insert(newCoins, obj)
				totalCoins = totalCoins + 1
			end
		end
	end
	
	coinsInGame = newCoins
	
	debugLog("✓ Encontradas " .. totalCoins .. " moedas no mapa")
	return totalCoins
end

local function findNearestCoin()
	local nearest = nil
	local nearestDistance = math.huge
	
	for _, coin in ipairs(coinsInGame) do
		if coin and coin.Parent then
			pcall(function()
				local coinPos = nil
				
				if coin:IsA("Model") then
					if coin:FindFirstChild("PrimaryPart") and coin.PrimaryPart then
						coinPos = coin.PrimaryPart.Position
					else
						coinPos = coin:FindFirstChildOfClass("BasePart").Position
					end
				else
					coinPos = coin.Position
				end
				
				if coinPos then
					local playerPos = humanoidRootPart.Position
					local distance = (coinPos - playerPos).Magnitude
					
					if distance < nearestDistance then
						nearestDistance = distance
						nearest = coin
					end
				end
			end)
		end
	end
	
	return nearest, nearestDistance
end

local function getCoinPosition(coin)
	if coin:IsA("Model") then
		if coin:FindFirstChild("PrimaryPart") and coin.PrimaryPart then
			return coin.PrimaryPart.Position
		else
			local part = coin:FindFirstChildOfClass("BasePart")
			if part then
				return part.Position
			end
		end
	else
		return coin.Position
	end
	return nil
end

local function moveTowardsCoin(coinPos)
	if not character or not humanoidRootPart then return end
	
	local direction = (coinPos - humanoidRootPart.Position)
	local distance = direction.Magnitude
	
	if distance > SETTINGS.PICKUP_RANGE then
		local unitDirection = direction.Unit
		local newPosition = humanoidRootPart.Position + (unitDirection * SETTINGS.SPEED * 0.016)
		
		humanoidRootPart.CFrame = CFrame.new(newPosition, newPosition + unitDirection)
	end
end

local function applyForceUp()
	if not humanoidRootPart then return end
	
	-- Força infinita para cima (anti-gravidade)
	local currentVelocity = humanoidRootPart.AssemblyLinearVelocity
	humanoidRootPart.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, 50, currentVelocity.Z)
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
	
	if currentTick - lastAntiAFKTick >= 1 then
		pcall(function()
			mouse:Move(math.random(100, 1820), math.random(100, 980))
		end)
		
		if humanoid then
			humanoid:Move(Vector3.new(math.random(-1, 1) * 0.02, 0, math.random(-1, 1) * 0.02))
		end
		
		lastAntiAFKTick = currentTick
	end
end

local function rescanCoins()
	local currentTime = tick()
	
	if currentTime - lastCoinCheckTime >= 2 then
		scanForCoins()
		lastCoinCheckTime = currentTime
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- MINIMIZAR/MAXIMIZAR GUI (Tecla X)
-- ═══════════════════════════════════════════════════════════════════════

local function toggleGuiSize()
	isGuiMinimized = not isGuiMinimized
	
	if isGuiMinimized then
		containerFrame:TweenSize(UDim2.new(0, 35, 0, 35), "Out", "Quad", 0.2, true)
		statusButton.Visible = false
	else
		statusButton.Visible = true
		containerFrame:TweenSize(UDim2.new(0, 70, 0, 70), "Out", "Quad", 0.2, true)
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
	statusButton.Text = "●"
	statusButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	
	debugLog("✓ FARM INICIADO!")
	
	scanForCoins()
	lastCoinCheckTime = tick()
	
	-- LOOP PRINCIPAL SEM DELAYS
	if mainLoop then mainLoop:Disconnect() end
	mainLoop = RunService.Heartbeat:Connect(function()
		if not isRunning then return end
		
		if not character or not humanoid or not humanoidRootPart then return end
		
		-- Noclip
		if SETTINGS.NOCLIP_ENABLED then
			noclipCharacter()
		end
		
		-- Anti-gravidade (força infinita para cima)
		if SETTINGS.ANTI_GRAVITY then
			applyForceUp()
		end
		
		-- Anti-AFK
		antiAFKTick()
		
		-- Rescaneia moedas a cada 2 segundos
		rescanCoins()
		
		-- Encontra moeda mais próxima SEM LIMITE DE RAIO
		targetCoin = findNearestCoin()
		
		if targetCoin then
			local coinPosition = getCoinPosition(targetCoin)
			
			if coinPosition then
				-- Move na direção da moeda com velocidade constante
				moveTowardsCoin(coinPosition)
				
				-- Verifica coleta
				local distance = (coinPosition - humanoidRootPart.Position).Magnitude
				
				if distance < SETTINGS.PICKUP_RANGE then
					-- Marca como coletada
					coinsCollected[targetCoin] = true
					debugLog("💰 Moeda coletada!")
					
					-- Som
					pcall(function()
						local som = Instance.new("Sound")
						som.SoundId = "rbxassetid://135669001382610"
						som.Volume = 0.4
						som.Parent = humanoidRootPart
						game:GetService("Debris"):AddItem(som, 1)
						som:Play()
					end)
				end
			end
		else
			-- Não faz nada, continua esperando encontrar moedas
			-- Apenas anti-AFK mantém ativo
		end
	end)
	
	-- LOOP DE NOCLIP CONTÍNUO
	if noclipLoop then noclipLoop:Disconnect() end
	noclipLoop = RunService.Heartbeat:Connect(function()
		if not isRunning or not character then return end
		noclipCharacter()
	end)
	
	-- LOOP DE GRAVIDADE CONTÍNUO
	if gravityLoop then gravityLoop:Disconnect() end
	gravityLoop = RunService.Heartbeat:Connect(function()
		if not isRunning or not humanoidRootPart then return end
		if SETTINGS.ANTI_GRAVITY then
			applyForceUp()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- PARAR FARM
-- ═══════════════════════════════════════════════════════════════════════

local function stopFarmingCoins()
	if not isRunning then return end
	
	isRunning = false
	statusButton.Text = "●"
	statusButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	
	if mainLoop then
		mainLoop:Disconnect()
		mainLoop = nil
	end
	
	if noclipLoop then
		noclipLoop:Disconnect()
		noclipLoop = nil
	end
	
	if gravityLoop then
		gravityLoop:Disconnect()
		gravityLoop = nil
	end
	
	-- Reativa colisão
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
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
debugLog("✓ MM2 Auto Farm v4.0 Carregado!")
debugLog("✓ Clique no botão para ativar/desativar")
debugLog("✓ Pressione X para minimizar a GUI")
debugLog("✓ Velocidade: 40 studs/s CONSTANTE")
debugLog("✓ Força infinita (SEM QUEDA)")
debugLog("✓ Sem limite de raio")
debugLog("════════════════════════════════════════")
