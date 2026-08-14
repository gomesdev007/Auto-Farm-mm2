-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║        MURDER MYSTERY 2 - AUTO FARM COINS ADVANCED v2.0              ║
-- ║                  Desenvolvido por Gomes.wqq                          ║
-- ║              Sistema Inteligente + Anti-Detecção                     ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════════════

local CONFIG = {
	SPEED = 21,
	TELEPORT_HEIGHT = 50,
	ANTI_AFK_INTERVAL = 1,
	MIN_DISTANCE = 3,
	SEARCH_RADIUS = 500,
	RAYCAST_CHECK = true
}

-- ═══════════════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════════════

local farmActive = false
local guiMinimized = false
local coinsList = {}
local collectedCoins = {}
local currentTarget = nil
local lastAntiAFKTime = 0
local farmConnection = nil
local heartbeatConnection = nil

-- ═══════════════════════════════════════════════════════════════════════
-- CRIAR GUI (PRETO TOTAL COM LETRAS BRANCAS)
-- ═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2AutoFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame Principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 180, 0, 180)
mainFrame.Position = UDim2.new(0.5, -90, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Bordas Arredondadas
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainFrame

-- Stroke (Borda)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- ═══════════════════════════════════════════════════════════════════════
-- BOTÃO ON/OFF (NO MEIO)
-- ═══════════════════════════════════════════════════════════════════════

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 130, 0, 130)
toggleButton.Position = UDim2.new(0.5, -65, 0.5, -65)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "OFF"
toggleButton.BorderSizePixel = 0
toggleButton.Parent = mainFrame

-- Bordas Arredondadas no Botão
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 15)
btnCorner.Parent = toggleButton

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE ARRASTE
-- ═══════════════════════════════════════════════════════════════════════

local dragging = false
local dragStart = nil
local frameStart = nil

mainFrame.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		frameStart = mainFrame.Position
	end
end)

mainFrame.InputChanged:Connect(function(input, gameProcessed)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
	end
end)

mainFrame.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- FUNÇÕES PRINCIPAIS
-- ═══════════════════════════════════════════════════════════════════════

local function log(text)
	print("🔹 [MM2 FARM] " .. text)
end

local function findAllCoins()
	coinsList = {}
	collectedCoins = {}
	
	local coinsFound = 0
	
	-- Procura por todas as moedas no workspace
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("Part") or descendant:IsA("MeshPart") or descendant:IsA("Model") then
			local name = descendant.Name:lower()
			
			-- Detecta moedas por nome
			if name:find("coin") or name:find("money") or name:find("cash") or 
			   (name:find("part") and descendant:FindFirstChild("Humanoid") == nil) then
				
				-- Verifica se está perto do jogador
				if descendant:FindFirstChild("BodyVelocity") == nil then
					if not table.find(coinsList, descendant) then
						table.insert(coinsList, descendant)
						coinsFound = coinsFound + 1
					end
				end
			end
		end
	end
	
	log("✓ Encontradas " .. coinsFound .. " moedas no mapa")
	return coinsFound
end

local function getClosestCoin()
	local closest = nil
	local closestDistance = math.huge
	
	for _, coin in pairs(coinsList) do
		if coin and coin.Parent and not collectedCoins[coin] then
			pcall(function()
				local distance = (coin.Position - humanoidRootPart.Position).Magnitude
				
				if distance < closestDistance and distance < CONFIG.SEARCH_RADIUS then
					closestDistance = distance
					closest = coin
				end
			end)
		end
	end
	
	return closest
end

local function canReachCoin(coinPos)
	-- Verifica se consegue chegar na moeda
	local direction = (coinPos - humanoidRootPart.Position)
	local distance = direction.Magnitude
	
	if distance < CONFIG.MIN_DISTANCE then
		return true
	end
	
	return distance < CONFIG.SEARCH_RADIUS
end

local function movementLogic(targetPos)
	if not character or not humanoidRootPart then return end
	
	local direction = (targetPos - humanoidRootPart.Position)
	local distance = direction.Magnitude
	
	if distance > CONFIG.MIN_DISTANCE then
		-- Calcula velocidade baseada na distância
		local moveDirection = direction.Unit
		
		-- Move com velocidade configurada
		humanoid:Move(moveDirection * CONFIG.SPEED)
	else
		humanoid:Move(Vector3.new(0, 0, 0))
	end
end

local function teleportUp()
	if not humanoidRootPart then return end
	
	-- Teleporta para cima
	local newPos = humanoidRootPart.CFrame + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)
	humanoidRootPart.CFrame = newPos
	
	wait(0.8)
	log("📍 Teleportado 50 studs para cima!")
end

local function antiAFKSystem()
	local currentTime = tick()
	
	if currentTime - lastAntiAFKTime > CONFIG.ANTI_AFK_INTERVAL then
		-- Move mouse aleatoriamente
		local randomX = math.random(0, 1920)
		local randomY = math.random(0, 1080)
		mouse:Move(randomX, randomY)
		
		-- Movimento pequeno
		if humanoid then
			humanoid:Move(Vector3.new(math.random(-2, 2) * 0.1, 0, math.random(-2, 2) * 0.1))
		end
		
		lastAntiAFKTime = currentTime
	end
end

local function startFarm()
	if farmActive then return end
	
	farmActive = true
	toggleButton.Text = "ON"
	toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	
	log("✓ Farm ATIVADO!")
	
	-- Encontra moedas inicialmente
	findAllCoins()
	
	-- Inicia o loop de farm
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end
	
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not farmActive then return end
		
		-- Anti-AFK
		antiAFKSystem()
		
		-- Processa farm se personagem existe
		if character and humanoid and humanoidRootPart then
			currentTarget = getClosestCoin()
			
			if currentTarget and currentTarget.Parent then
				-- Move em direção à moeda
				movementLogic(currentTarget.Position)
				
				-- Verifica se coletou
				local distance = (currentTarget.Position - humanoidRootPart.Position).Magnitude
				
				if distance < CONFIG.MIN_DISTANCE then
					collectedCoins[currentTarget] = true
					log("💰 Moeda coletada! (" .. countTable(collectedCoins) .. ")")
					
					-- Toca som (opcional)
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://12222058"
					sound.Volume = 0.3
					sound.Parent = humanoidRootPart
					game:GetService("Debris"):AddItem(sound, 0.5)
					pcall(function()
						sound:Play()
					end)
				end
			else
				-- Sem moedas, teleporta para cima
				humanoid:Move(Vector3.new(0, 0, 0))
				log("🎯 Ciclo completo! Teletransportando...")
				
				teleportUp()
				
				-- Recarrega moedas
				wait(1)
				findAllCoins()
			end
		end
	end)
end

local function stopFarm()
	if not farmActive then return end
	
	farmActive = false
	toggleButton.Text = "OFF"
	toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	
	if character and humanoid then
		humanoid:Move(Vector3.new(0, 0, 0))
	end
	
	log("✗ Farm DESATIVADO!")
end

local function minimizeGui()
	guiMinimized = not guiMinimized
	
	if guiMinimized then
		mainFrame:TweenSize(UDim2.new(0, 50, 0, 50), "Out", "Quad", 0.3, true)
		toggleButton.Visible = false
		mainFrame.Position = mainFrame.Position + UDim2.new(0, 65, 0, 65)
	else
		toggleButton.Visible = true
		mainFrame:TweenSize(UDim2.new(0, 180, 0, 180), "Out", "Quad", 0.3, true)
		mainFrame.Position = mainFrame.Position - UDim2.new(0, 65, 0, 65)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- FUNÇÃO AUXILIAR
-- ═══════════════════════════════════════════════════════════════════════

function countTable(tbl)
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

-- ═══════════════════════════════════════════════════════════════════════
-- EVENT LISTENERS
-- ═══════════════════════════════════════════════════════════════════════

-- Botão ON/OFF
toggleButton.MouseButton1Click:Connect(function()
	if farmActive then
		stopFarm()
	else
		startFarm()
	end
end)

-- Tecla X para Minimizar/Maximizar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.X then
		minimizeGui()
	end
end)

-- Atualizar quando morre/respawna
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	if farmActive then
		log("⚠️  Personagem respawnou! Reiniciando farm...")
		stopFarm()
		wait(2)
		startFarm()
	end
end)

-- Cleanup quando sair do jogo
player.AncestryChanged:Connect(function()
	if player.Parent == nil then
		if farmActive then
			stopFarm()
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════

log("═════════════════════════════════════════")
log("✓ MM2 Auto Farm v2.0 Carregado com Sucesso!")
log("✓ Clique no botão para iniciar/parar")
log("✓ Pressione X para minimizar/maximizar GUI")
log("═════════════════════════════════════════")
