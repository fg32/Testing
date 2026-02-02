local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Grand Game 2" ,
	SubTitle = "For PNEUMA with love",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
	Notifies = Window:AddTab({ Title = "Notifies", Icon = "" }),
	ESPs = Window:AddTab({ Title = "ESPs", Icon = "camera" }),
	Chests = Window:AddTab({ Title = "Chests", Icon = "package" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- VARIABLES
local RS = game:GetService("ReplicatedStorage")
local WorldFolder = workspace.World
local MarkersFolder = RS.Markers

local Players = game:GetService("Players")


local ESPBGUIs = {} -- Stores BillboardGui instances

--[[
ESPBGUIs[char] = {
				["BGUI"] = BGUI,
			}
]]

local ChestBGUIs = {}
--[[
ChestBGUIS[handPart : Instance] = 
{ "BGUI" = BGUI : Instance,
	"Type" = "Rare/Common"
}
]]




-- Chest Connections
local Chest_Conn = nil

-- Chest ESP settings
local IsChestESPActive = false


-- Player ESP Connections
local PlayerESP_Main_Conns = {
	Join = nil,
	Leave = nil
}

local CharactersLoadingConnections = {}
local CharactersRemovingConnections = {}

-- Player ESP Variables
local DistancesThread 

local Chars_To_Load = {} -- Array of characters not loaded cuz of Streaming issue
local LoadAfterThread = nil



-- Player ESP settings
local IsPlayer_ESP_Active = false
local IsHP = false
local IsDistance = false
local IsNickname = true -- Cuz its start setting, so on true
local IsColorByHP = false
local IsDisplayName = false



do


	-- Admins Notify
	local Admins_Join_Connection

	local AdminNotifyToggle = Tabs.Notifies:AddToggle("AdminsNotifyToggle", { Title = "Notify when Admin+ joins", Default = true })

	AdminNotifyToggle:OnChanged(function()
		if Admins_Join_Connection then
			Admins_Join_Connection:Disconnect()
			Admins_Join_Connection = nil
		end

		if Options.AdminsNotifyToggle.Value == true then
			Admins_Join_Connection = Players.PlayerAdded:Connect(function(plr)
				if plr:GetRankInGroupAsync(15216379) >= 3 then
					Fluent:Notify({
						Title = `{plr:GetRoleInGroupAsync(15216379)} JOINED`,
						Content = `His nickname is {tostring(plr.Name)}`,
						SubContent = "",
						Duration = 5 -- Set to nil to make the notification not disappear
					})
				end
			end)
		end
	end)


	-- Chests

	local function ClearChestBGUI(handPart)
		if ChestBGUIs[handPart] then
			local BGUI = ChestBGUIs[handPart].BGUI
			ChestBGUIs[handPart].BGUI = nil
			ChestBGUIs[handPart].Type = nil
			for index, connection in ChestBGUIs[handPart].Conns do
				connection:Disconnect()
				table.remove(ChestBGUIs[handPart].Conns, table.find(ChestBGUIs[handPart].Conns, connection))
			end

			ChestBGUIs[handPart].Conns = nil
			ChestBGUIs[handPart] = nil
			BGUI:Destroy()
			handPart = nil
		end
	end

	local function ChestGarbageCollector()
		for handPart, Data in ChestBGUIs do
			if handPart.Parent == nil or Data["BGUI"].Parent == nil then
				ClearChestBGUI(handPart)
			end
		end
	end

	local GoldChest_ESP_ColorPicker = Tabs.Chests:AddColorpicker("GoldChest_ESP_ColorPicker", {
		Title = "Choose color of Gold chest ESP",
		Default = Color3.fromRGB(244, 81, 230)
	})

	GoldChest_ESP_ColorPicker:OnChanged(function()
		ChestGarbageCollector()

		for handPart : Instance , Data in ChestBGUIs do
			if Data["BGUI"]:FindFirstChild("Text") then
				if Data["Type"] == "Common" then
					Data["BGUI"].Text.TextColor3 = Options.Chest_ESP_ColorPicker.Value
				else
					Data["BGUI"].Text.TextColor3 = Options.GoldChest_ESP_ColorPicker.Value
				end
			else
				ClearChestBGUI(handPart)
			end
		end
	end)

	local Chest_ESP_ColorPicker = Tabs.Chests:AddColorpicker("Chest_ESP_ColorPicker", {
		Title = "Choose color of Common chest ESP",
		Default = Color3.fromRGB(70, 166, 255)
	})

	Chest_ESP_ColorPicker:OnChanged(function()
		ChestGarbageCollector()

		for handPart : Instance , Data in ChestBGUIs do
			if Data["BGUI"]:FindFirstChild("Text") then
				if Data["Type"] == "Common" then
					Data["BGUI"].Text.TextColor3 = Options.Chest_ESP_ColorPicker.Value
				else
					Data["BGUI"].Text.TextColor3 = Options.GoldChest_ESP_ColorPicker.Value
				end
			else
				ClearChestBGUI(handPart)
			end
		end
	end)

	-- Returns BGUI, handPart
	local function AddChestGui(handPart : Instance, Type : string)
		local Text

		local BGUI

		if handPart and handPart:IsA("Part") then
			BGUI = handPart:FindFirstChild("ChestESPBGUI")






			local function InitiateBGUI()
				local BiGUI = Instance.new("BillboardGui")
				BiGUI.Name = "ChestESPBGUI"
				BiGUI.AlwaysOnTop = true
				BiGUI.LightInfluence = 1
				BiGUI.Size = UDim2.new(0.00, 200.00, 0.00, 50.00)
				BiGUI.ResetOnSpawn = false
				BiGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				BiGUI.StudsOffset = Vector3.new(0.00, 3.50, 0.00)
				BiGUI.Parent = handPart
				return BiGUI
			end

			local function InitiateText()

				local TText = Instance.new("TextLabel")
				TText.Name = "Text"
				TText.TextStrokeTransparency = 0.4399999976158142
				TText.BorderSizePixel = 0
				TText.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
				TText.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				TText.TextSize = 14
				TText.Size = UDim2.new(0.00, 200.00, 0.00, 50.00)
				TText.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
				TText.Text = "Chest unknown"
				TText.TextColor3 = Options.Chest_ESP_ColorPicker.Value

				TText.BackgroundTransparency = 1
				TText.Parent = BGUI
				return TText
			end

			if BGUI then
				Text = BGUI:FindFirstChild("Text")

				if not Text then
					Text = InitiateText()
				end

			else
				BGUI = InitiateBGUI()

				Text = InitiateText()

			end



			ChestBGUIs[handPart] = {}
			ChestBGUIs[handPart]["BGUI"] = BGUI
			ChestBGUIs[handPart]["Type"] = Type
			ChestBGUIs[handPart]["Conns"] = {}

			if Type == "Rare" then
				Text.Text = "GOLDEN CHEST 777"
				Text.TextColor3 = Options.GoldChest_ESP_ColorPicker.Value
				if handPart.Parent:IsAncestorOf(WorldFolder) then
					Fluent:Notify({
						Title = "GOLD CHEST SPAWNED",
						Content = "FIND IT",
						Duration = nil
					})
				end
				table.insert(ChestBGUIs[handPart]["Conns"], handPart.Parent:GetPropertyChangedSignal("Parent"):Connect(function()
					if handPart.Parent:IsAncestorOf(WorldFolder) then
						Fluent:Notify({
							Title = "GOLD CHEST SPAWNED",
							Content = "FIND IT",
							Duration = nil
						})
					end
				end))
			elseif Type == "Common" then
				Text.Text = "Chest"
			end

			BGUI.Enabled = IsChestESPActive
		end
		return BGUI, handPart
	end

	local Chest_ESP = Tabs.Chests:AddToggle("Chest_ESP", { Title = "ESP for chests", Default = IsChestESPActive })

	Chest_ESP:OnChanged(function()
		IsChestESPActive = Options.Chest_ESP.Value
		ChestGarbageCollector()

		if Chest_Conn then
			Chest_Conn:Disconnect()
			Chest_Conn = nil
		end

		for handPart : Instance , Data in ChestBGUIs do
			Data["BGUI"].Enabled = Options.Chest_ESP.Value 
		end

		if Options.Chest_ESP.Value == true then
			local function AttachESP(handPart)
				local Type = "Common"
				for modelindex, probmodel in handPart.Parent:GetChildren() do
					if probmodel:IsA("Model") then
						if probmodel:FindFirstChildOfClass("UnionOperation") then
							Type = "Rare"
							break
						end
					end
				end

				AddChestGui(handPart, Type)
			end

			Chest_Conn = WorldFolder.DescendantAdded:Connect(function(object)
				if object:IsA("Part") then
					if object.Material == Enum.Material.Neon and object.Color == Color3.fromRGB(245, 167, 41) then
						AttachESP(object)
					end
				end
			end)

			for index, object : Instance in WorldFolder:GetDescendants() do
				if object:IsA("Part") then
					if object.Material == Enum.Material.Neon and object.Color == Color3.fromRGB(245, 167, 41) then
						AttachESP(object)
					end
				end
			end
		end
	end)


	-- Player ESP MENU

	-- Clears ESPBGUIs and delete BGUI Instance
	local function ClearBGUI(char)
		if ESPBGUIs[char] then
			local LBGUI = ESPBGUIs[char].BGUI

			ESPBGUIs[char].BGUI = nil



			for i, v in ESPBGUIs[char] do
				pcall(function()
					ESPBGUIs[char][i]:Disconnect()
				end)

				ESPBGUIs[char][i] = nil
			end

			ESPBGUIs[char] = nil

			LBGUI:Destroy()

			LBGUI = nil
		end
	end

	local function GarbageCollectESPBGUIs()
		for char, data in ESPBGUIs do
			if char.Parent == nil or data.BGUI == nil or data.BGUI.Parent == nil then
				ClearBGUI(char)
			end
		end
	end

	local Player_ESP_ColorPicker = Tabs.ESPs:AddColorpicker("Player_ESP_ColorPicker", {
		Title = "Choose color of ESP",
		Default = Color3.fromRGB(41, 255, 8)
	})

	Player_ESP_ColorPicker:OnChanged(function()
		GarbageCollectESPBGUIs()

		if IsColorByHP == false then
			for char, data in ESPBGUIs do
				if ESPBGUIs[char].BGUI then
					if ESPBGUIs[char].BGUI:FindFirstChild("Text") then
						ESPBGUIs[char].BGUI.Text.TextColor3 = Options.Player_ESP_ColorPicker.Value
					end
				end
			end
		end
	end)





	-- returns BGUI Instance
	local function AddPlayerGui(char)
		local Text

		local BGUI
		local head = char:WaitForChild("Head") 
		if head then 
			BGUI = head:FindFirstChild("ESPBGUI")


			local function InitiateBGUI()
				local BiGUI = Instance.new("BillboardGui")
				BiGUI.Name = "ESPBGUI"
				BiGUI.AlwaysOnTop = true
				BiGUI.LightInfluence = 1
				BiGUI.Size = UDim2.new(0.00, 200.00, 0.00, 50.00)
				BiGUI.ResetOnSpawn = false
				BiGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				BiGUI.StudsOffset = Vector3.new(0.00, 3.50, 0.00)
				BiGUI.Parent = head
				return BiGUI
			end

			local function InitiateText()

				local TText = Instance.new("TextLabel")
				TText.Name = "Text"
				TText.TextStrokeTransparency = 0.4399999976158142
				TText.BorderSizePixel = 0
				TText.BackgroundColor3 = Color3.new(1.00, 1.00, 1.00)
				TText.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				TText.TextSize = 14
				TText.Size = UDim2.new(0.00, 200.00, 0.00, 50.00)
				TText.BorderColor3 = Color3.new(0.00, 0.00, 0.00)
				TText.Text = "???"
				TText.TextColor3 = Options.Player_ESP_ColorPicker.Value

				TText.BackgroundTransparency = 1
				TText.Parent = BGUI
				return TText
			end

			if BGUI then
				Text = BGUI:FindFirstChild("Text")

				if not Text then
					Text = InitiateText()
				end

			else
				BGUI = InitiateBGUI()

				Text = InitiateText()

			end

			ESPBGUIs[char] = {
				["BGUI"] = BGUI,
			}

			BGUI.Enabled = IsPlayer_ESP_Active
		end
		return BGUI, char
	end



	local function UpdateGUI(BGUI : Instance)
		if BGUI and BGUI:FindFirstChild("Text") and BGUI.Parent and BGUI.Parent.Parent and BGUI.Parent.Parent.Parent ~= nil then
			local Text = BGUI:FindFirstChild("Text")
			local head = BGUI.Parent
			local char = head.Parent
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				
				local DisplayNameText
				if IsDisplayName then
					local plr = Players:GetPlayerFromCharacter(char) 
					if plr then
						if plr.DisplayName ~= char.Name or IsNickname == false then
							DisplayNameText = `\n {plr.DisplayName}`
						else
							DisplayNameText = ""
						end
					else
						DisplayNameText = "\n NPC?"
					end
				else
					DisplayNameText = ""
				end
				
				local NicknameText
				if IsNickname then
					NicknameText = `\n {char.Name}`
				else
					NicknameText = ""
				end

				local HPText
				if IsHP then
					HPText = `\n {math.floor(hum.Health)}/{math.floor(hum.MaxHealth)}`

					-- HP handler if it not applied before somehow
					if not ESPBGUIs[char]["HP"] then
						ESPBGUIs[char]["HP"] = char:FindFirstChild("Humanoid").HealthChanged:Connect(function()
							UpdateGUI(ESPBGUIs[char].BGUI)
						end)
					end
				else
					HPText = ""
				end

				local DistanceText
				if IsDistance then
					local HRP = char:FindFirstChild("HumanoidRootPart")
					local SelfHRP = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

					-- Distances handler if it not applied before somehow
					if not DistancesThread then
						DistancesThread = task.spawn(function()
							local count = 0
							while IsDistance == true and IsPlayer_ESP_Active == true do
								for char,bgui in ESPBGUIs do
									count += 1
									if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
										UpdateGUI(ESPBGUIs[char].BGUI)
									else
										ClearBGUI(char)
									end
								end
								if count <= 0 then
									break
								else
									count = 0
								end
								task.wait(4)
							end
						end)
					end

					if HRP and SelfHRP then
						local Distance = math.floor((HRP.Position - SelfHRP.Position).Magnitude) 

						DistanceText = `\n {tostring(Distance)}s `
					else
						DistanceText = ""
					end
				else
					DistanceText = ""
				end

				if IsColorByHP == true then

					-- HP handler if it not applied before somehow
					if not ESPBGUIs[char]["HP"] then
						ESPBGUIs[char]["HP"] = char:FindFirstChild("Humanoid").HealthChanged:Connect(function()
							UpdateGUI(ESPBGUIs[char].BGUI)
						end)
					end

					local FullHpColor = Color3.fromRGB(41, 255, 8)
					local HalfHpColor = Color3.fromRGB(251, 255, 16)
					local LowHpColor = Color3.fromRGB(255, 17, 17)

					if (hum.Health / hum.MaxHealth) >= 0.66  then
						Text.TextColor3 = FullHpColor
					elseif (hum.Health / hum.MaxHealth) < 0.63 and (hum.Health / hum.MaxHealth) >= 0.33 then
						Text.TextColor3 = HalfHpColor
					elseif (hum.Health / hum.MaxHealth) < 0.33 then
						Text.TextColor3 = LowHpColor
					end
				end

				local fulltext = `{DisplayNameText} {NicknameText} {HPText} {DistanceText}`

				Text.Text = fulltext
			end

		else
			local char 
			for i,v in ESPBGUIs do
				if ESPBGUIs[i].BGUI == BGUI then
					char = i
					break
				end
			end
			if char then
				ClearBGUI(char)
			else
				-- warn("Couldn't find character for BGUI")
			end

		end		
	end



	-- Processes only Esp instances create (WITHOUT CONNECTIONS!!!)
	local function AttachEsp(char : Instance, head : Instance)

		local function AddToLoadAfter(char)
			if not table.find(Chars_To_Load, char) then
				table.insert(Chars_To_Load, char)
			end


			for index, char in Chars_To_Load do
				if char.Parent == nil then
					table.remove(Chars_To_Load, table.find(Chars_To_Load, char))
				end
			end

			char = nil

			if #Chars_To_Load > 0 and LoadAfterThread == nil then
				-- Check for loadafter if it may be loaded
				LoadAfterThread = task.spawn(function()
					while #Chars_To_Load > 0 do
						for falseindex, char in Chars_To_Load do
							if char.Parent == nil then
								ClearBGUI(char)
								table.remove(Chars_To_Load, table.find(Chars_To_Load, char))
							else
								local head = char:FindFirstChild("Head")
								if head then
									AttachEsp(char, head)
									table.remove(Chars_To_Load, table.find(Chars_To_Load, char))
									print("created by delay for " .. char.Name)
								end
							end
						end
						task.wait(8)
					end
				end)
			end
		end

		local plr = Players:GetPlayerFromCharacter(char)

		if char:IsA("Model") and plr then

			-- Function to safely apply any other function
			local function SafeApply(func : thread, MaxTries : number, ToDelay : number, Args : SharedTable)
				if Args then
					local success, result = pcall(function()
						return table.unpack(Args)
					end)
					if not success then
						Args = {}
					end
				else
					Args = {}
				end

				if typeof(func) ~= "function" or typeof(MaxTries) ~= "number" or typeof(ToDelay) ~= "number"  then
					return false
				end
				local count = 0
				local result = false
				repeat
					count += 1
					result = func(table.unpack(Args))
					if count > 1 then
						task.wait(ToDelay)
					end
				until count > MaxTries or (result ~= false and result ~= nil)

				if result == nil then
					result = false
				end

				return result
			end

			local head = head or char:FindFirstChild("Head")
			-- Repeat try
			if not head then
				local function FindHead()
					return char:FindFirstChild("Head")
				end

				local result = SafeApply(FindHead, 20, 0.1)

				if result == false then
					AddToLoadAfter(char)
					print("Delayed for" .. char.Name)
					return
				else
					head = result
					result = nil
				end
			end
			--

			local result = SafeApply(AddPlayerGui, 20, 0.1, {char})

			if not result then
				AddToLoadAfter(char)
				print("delayed for " .. char.Name)
			else
				UpdateGUI(result)
				print("created for" .. char.Name)
			end
		end
	end


	local Player_ESP_Toggle = Tabs.ESPs:AddToggle("Player_ESP_Toggle", { Title = "Player ESP", Default = false })

	Player_ESP_Toggle:OnChanged(function()
		IsPlayer_ESP_Active = Options.Player_ESP_Toggle.Value

		-- Clear Join/Leave connections
		for name, value in PlayerESP_Main_Conns do
			PlayerESP_Main_Conns[name]:Disconnect()
			PlayerESP_Main_Conns[name] = nil
		end

		GarbageCollectESPBGUIs()




		if IsPlayer_ESP_Active then

			-- Processes new ESP fully
			local function ProcessNewESPCreate(plr : Instance)
				if not CharactersLoadingConnections[plr.UserId] then
					CharactersLoadingConnections[plr.UserId] = plr.CharacterAdded:Connect(function(char)
						AttachEsp(char)
					end) 
				end

				if not CharactersRemovingConnections[plr.UserId] then
					CharactersRemovingConnections[plr.UserId] = plr.CharacterRemoving:Connect(function(char)
						ClearBGUI(char)
					end)
				end

				if plr.Character then
					AttachEsp(plr.Character)
				end
			end

			PlayerESP_Main_Conns["Join"] = Players.PlayerAdded:Connect(function(plr)
				ProcessNewESPCreate(plr)
			end)

			PlayerESP_Main_Conns["Leave"] = Players.PlayerRemoving:Connect(function(plr)
				CharactersLoadingConnections[plr.UserId]:Disconnect()
				CharactersLoadingConnections[plr.UserId] = nil
				CharactersRemovingConnections[plr.UserId]:Disconnect()
				CharactersRemovingConnections[plr.UserId] = nil

				local char = plr.Character
				if char then
					ClearBGUI(char)
				end



			end)
			for char, data in ESPBGUIs do
				-- Data:
				-- char = {"BGUI" =  : Instance}
				local LBGUI = data["BGUI"]
				if LBGUI then
					LBGUI.Enabled = true
				end
			end

			for index, player in Players:GetChildren() do
				if player == Players.LocalPlayer then
					continue
				end
				ProcessNewESPCreate(player)
			end
		else
			for char, data in ESPBGUIs do
				-- Data:
				-- char = {"BGUI" =  : Instance}
				local LBGUI = data["BGUI"]
				if LBGUI then
					LBGUI.Enabled = false
				end
			end
		end
	end)

	local Player_Esp_Keybind = Tabs.ESPs:AddKeybind("Player_Esp_Keybind", {
		Title = "Keybind to Enable/Disable Player ESP",
		Mode = "Toggle", -- Always, Toggle, Hold
		Default = "RightControl", -- String as the name of the keybind (MB1, MB2 for mouse buttons)

		-- Occurs when the keybind is clicked, Value is `true`/`false`
	})

	-- OnClick is only fired when you press the keybind and the mode is Toggle
	-- Otherwise, you will have to use Keybind:GetState()
	Player_Esp_Keybind:OnClick(function()
		if Options.Player_Esp_Keybind.Value == true then
			Player_Esp_Keybind:SetValue(false)
		else
			Player_Esp_Keybind:SetValue(true)
		end
	end)

	-- Paragraphs

	Tabs.ESPs:AddParagraph({
		Title = "Settings",
		Content = "Setup your Player ESP"
	})


	local PNickNameToggle = Tabs.ESPs:AddToggle("PNicknamesToggle", { Title = "Nicknames", Default = true })

	PNickNameToggle:OnChanged(function()
		GarbageCollectESPBGUIs()
		if Options.PNicknamesToggle.Value == true then

			IsNickname = true
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearBGUI(i)
				end
			end
		else
			IsNickname = false
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearBGUI(i)
				end
			end
		end
	end)
	
	local PlayerESP_Displayes_Toggle = Tabs.ESPs:AddToggle("PlayerESP_Displayes_Toggle", { Title = "Displays", Default = true })

	PlayerESP_Displayes_Toggle:OnChanged(function()
		GarbageCollectESPBGUIs()
		if Options.PlayerESP_Displayes_Toggle.Value == true then

			IsDisplayName = true
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearBGUI(i)
				end
			end
		else
			IsDisplayName = false
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearBGUI(i)
				end
			end
		end
	end)

	local PHPToggle = Tabs.ESPs:AddToggle("PHPsToggle", { Title = "HPs", Default = false })

	PHPToggle:OnChanged(function()
		GarbageCollectESPBGUIs()
		if Options.PHPsToggle.Value == true then
			IsHP = true
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					if not ESPBGUIs[i]["HP"] then
						ESPBGUIs[i]["HP"] = i:FindFirstChild("Humanoid").HealthChanged:Connect(function()
							UpdateGUI(ESPBGUIs[i].BGUI)
						end)
					end
				else
					ClearBGUI(i)
				end
			end
		else
			IsHP = false
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					if IsHP == false and IsColorByHP == false then
						if ESPBGUIs[i]["HP"] then
							ESPBGUIs[i]["HP"]:Disconnect()
							ESPBGUIs[i]["HP"] = nil
						end
					end
					UpdateGUI(ESPBGUIs[i].BGUI)
				else
					ClearBGUI(i)
				end
			end
		end
	end)

	local PDistanceToggle = Tabs.ESPs:AddToggle("PDistancesToggle", { Title = "Distances", Default = false })

	PDistanceToggle:OnChanged(function()
		GarbageCollectESPBGUIs()
		if Options.PDistancesToggle.Value == true then
			IsDistance = true

			if DistancesThread then
				task.cancel(DistancesThread)
				DistancesThread = nil
			end

			DistancesThread = task.spawn(function()
				local count = 0
				while IsDistance == true and IsPlayer_ESP_Active == true do
					for char,bgui in ESPBGUIs do
						count += 1
						if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
							UpdateGUI(ESPBGUIs[char].BGUI)
						else
							ClearBGUI(char)
						end
					end
					if count <= 0 then
						break
					else
						count = 0
					end
					task.wait(4)
				end
			end)

			for char,v in ESPBGUIs do
				if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[char].BGUI)
				else
					ClearBGUI(char)
				end
			end
		else
			IsDistance = false

			if DistancesThread then
				task.cancel(DistancesThread)
				DistancesThread = nil
			end

			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
				else
					ClearBGUI(i)
				end
			end
		end
	end)


	local PColorByHPToggle = Tabs.ESPs:AddToggle("PCByHPToggle", { Title = "Color by Enemy HP", Default = false })

	PColorByHPToggle:OnChanged(function()
		GarbageCollectESPBGUIs()
		if Options.PCByHPToggle.Value == true then
			IsColorByHP = true
			for char,table in ESPBGUIs do
				if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
					if not ESPBGUIs[char]["HP"] then
						ESPBGUIs[char]["HP"] = char:FindFirstChild("Humanoid").HealthChanged:Connect(function()
							UpdateGUI(ESPBGUIs[char].BGUI)
						end)
					end

					UpdateGUI(ESPBGUIs[char].BGUI)
				else
					ClearBGUI(char)
				end
			end
		else
			IsColorByHP = false
			for char,table in ESPBGUIs do
				if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
					if IsColorByHP == false then
						local Text = ESPBGUIs[char].BGUI:FindFirstChild("Text")
						if Text then
							Text.TextColor3 = Options.Player_ESP_ColorPicker.Value
						end
						if IsColorByHP == false and IsHP == false then
							if ESPBGUIs[char]["HP"] then
								ESPBGUIs[char]["HP"]:Disconnect()
								ESPBGUIs[char]["HP"] = nil
							end
						end
					end
				else
					ClearBGUI(char)
				end
			end
		end
	end)




end


-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/SLLol")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
	Title = "Fluent",
	Content = "The script has been loaded.",
	Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()


