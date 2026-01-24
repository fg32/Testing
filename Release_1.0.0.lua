local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/fg32/Testing/refs/heads/FluentNoUpdate/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Grand Game" ,
	SubTitle = "For PNEUMA with love",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
	Main = Window:AddTab({ Title = "Main", Icon = "" }),
	ESPs = Window:AddTab({ Title = "ESPs", Icon = "camera" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- VARIABLES
local RS = game:GetService("ReplicatedStorage")
local WorldFolder = workspace.World
local MarkersFolder = RS.Markers


-- ESP SETTINGS
local ESPBGUIs = {} -- Stores BillboardGui instances

local DistancesThread 

local JoinConnection

local LeaveConnection 

local CharactersLoadingConnections = {}

local IsHP = false

local IsDistance = false

local IsNickname = true -- Cuz its start setting, so on true


local IsColorByHP = false



do








	local PAddedAdminsCheck

	local AdminNotifyToggle = Tabs.Main:AddToggle("AdminsNotifyToggle", { Title = "Notify when Admin+ joins", Default = false })

	AdminNotifyToggle:OnChanged(function()
		if PAddedAdminsCheck then
			PAddedAdminsCheck:Disconnect()
			PAddedAdminsCheck = nil
		end

		if Options.AdminsNotifyToggle.Value == true then
			PAddedAdminsCheck = game.Players.PlayerAdded:Connect(function(plr)
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
	
	local ChestSpawnsConnection
	
	local ChestNotifyToggle = Tabs.Main:AddToggle("ChestsNotifyToggle", { Title = "Notify when Chest spawns", Default = false })

	ChestNotifyToggle:OnChanged(function()
		if ChestSpawnsConnection then
			ChestSpawnsConnection:Disconnect()
			ChestSpawnsConnection = nil
		end

		if Options.ChestsNotifyToggle.Value == true then
			
			ChestSpawnsConnection = WorldFolder.ChildAdded:Connect(function(child)
				local ChestSubModel = child:FindFirstChildOfClass("Model")
				if child:IsA("Model") and ChestSubModel then
					local NeonPart = nil
					local KeyLockPart = nil
					for key, part in ChestSubModel:GetChildren() do
						print(part)

						if part:IsA("Part") then
							if part.Material == Enum.Material.Neon and part.Color == Color3.fromRGB(245, 167, 41) and part.Transparency ~= 1 then
								NeonPart = part
								print("assignedneon")
							end

							local SpecialMesh = part:FindFirstChildOfClass("SpecialMesh")
							if SpecialMesh and SpecialMesh.MeshType == Enum.MeshType.Head then
								KeyLockPart = part
								print("assignedkey")
							end

						end
					end
					if NeonPart and KeyLockPart then
						print("started")

						local LocationName = "Unknown"
						-- Proceed Location
						for key, marker in MarkersFolder:GetChildren() do
							if marker.Name ~= "???" then
								local PartsInPart = workspace:GetPartsInPart(marker)
								if table.find(PartsInPart, NeonPart) then
									table.clear(PartsInPart)
									LocationName = marker.Name
									break
								end
								table.clear(PartsInPart)
							end
						end

						-- Function 
						Fluent:Notify({
							Title = `Chest spawned at {LocationName}`,
							Content = ``,
							SubContent = "",
							Duration = 5 -- Set to nil to make the notification not disappear
						})
					end
				end
			end)
		end
	end)
	



	-- Player ESP MENU


	-- Functions
	local function ClearConnections(char)
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

	local CurrentColor = Color3.fromRGB(41, 255, 8)

	local function AddGui(char)
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
				TText.Text = "NPC"
				TText.TextColor3 = CurrentColor

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
				["DiedConnect"] = char.AncestryChanged:Connect(function()
					if char.Parent == nil then
						ClearConnections(char)
					end
				end)
			}

			BGUI.Enabled = true
		end
		return BGUI, char
	end



	local function UpdateGUI(BGUI)
		if BGUI and BGUI:FindFirstChild("Text") and BGUI.Parent and BGUI.Parent.Parent and BGUI.Parent.Parent.Parent ~= nil then
			local Text = BGUI:FindFirstChild("Text")
			local head = BGUI.Parent
			local char = head.Parent
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local NicknameText
				if IsNickname then
					NicknameText = `\n {char.Name}`
				else
					NicknameText = ""
				end

				local HPText
				if IsHP then
					HPText = `\n {math.floor(hum.Health)}/{math.floor(hum.MaxHealth)}`

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
					local SelfHRP = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

					if not DistancesThread then
						DistancesThread = task.spawn(function()
							local count = 0
							while IsDistance == true do
								for char,bgui in ESPBGUIs do
									count += 1
									if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
										UpdateGUI(ESPBGUIs[char].BGUI)
									else
										ClearConnections(char)
									end
								end
								if count <= 0 then
									break
								else
									count = 0
								end
								task.wait(0.1)
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

				local fulltext = `{NicknameText} {HPText} {DistanceText}`

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
				ClearConnections(char)
			else
				-- warn("Couldn't find character for BGUI")
			end

		end		
	end

	-- MainTumbler

	local PESPToggle = Tabs.ESPs:AddToggle("PESPsToggle", { Title = "Player ESP", Default = false })

	PESPToggle:OnChanged(function()

		if Options.PESPsToggle.Value == true then
			-- Enable ESP for anyone alr ingame
			for i,plr in game.Players:GetChildren() do
				if plr == game.Players.LocalPlayer then
					continue
				end
				CharactersLoadingConnections[plr.UserId] = plr.CharacterAdded:Connect(function(char)
					local BGUI = AddGui(char)
					if BGUI then
						UpdateGUI(BGUI)
					end
				end)
				local BGUI = AddGui(plr.Character)
				if BGUI then
					UpdateGUI(BGUI)
				end
			end

			-- Disconnecting if there any for some reason
			if JoinConnection then 
				JoinConnection:Disconnect()
				JoinConnection = nil
			end
			if LeaveConnection then
				LeaveConnection:Disconnect()
				LeaveConnection = nil
			end

			-- AutoESP for new players
			JoinConnection = game.Players.PlayerAdded:Connect(function(plr)
				if plr == game.Players.LocalPlayer then
					return
				end
				CharactersLoadingConnections[plr.UserId] = plr.CharacterAdded:Connect(function(char)
					local BGUI 
					local count = 0
					repeat
						if count >= 30 then
							break
						end
						count += 1
						BGUI = AddGui(char)
						task.wait(1)
					until BGUI ~= false and BGUI ~= nil
					if BGUI then
						UpdateGUI(BGUI)
					end
				end)
				local BGUI 
				local count = 0

				repeat
					if count >= 30 then
						break
					end
					count += 1
					BGUI = AddGui(plr.Character)
					task.wait(1)
				until BGUI ~= false and BGUI ~= nil
				if BGUI then
					UpdateGUI(BGUI)
				end
			end)

			-- AutoClearconnections
			LeaveConnection = game.Players.PlayerRemoving:Connect(function(plr)
				if CharactersLoadingConnections[plr.UserId] then
					CharactersLoadingConnections[plr.UserId]:Disconnect()
					CharactersLoadingConnections[plr.UserId] = nil
				end

				ClearConnections(plr.Character)
			end)
		else
			if JoinConnection then 
				JoinConnection:Disconnect()
				JoinConnection = nil
			end
			if LeaveConnection then
				LeaveConnection:Disconnect()
				LeaveConnection = nil
			end

			for char,table in ESPBGUIs do
				ClearConnections(char)
			end
		end
	end)

	local PESPKeyb = Tabs.ESPs:AddKeybind("PESPsKeyb", {
		Title = "Keybind to Enable/Disable Player ESP",
		Mode = "Toggle", -- Always, Toggle, Hold
		Default = "RightControl", -- String as the name of the keybind (MB1, MB2 for mouse buttons)

		-- Occurs when the keybind is clicked, Value is `true`/`false`
	})

	-- OnClick is only fired when you press the keybind and the mode is Toggle
	-- Otherwise, you will have to use Keybind:GetState()
	PESPKeyb:OnClick(function()
		if Options.PESPsToggle.Value == true then
			PESPToggle:SetValue(false)
		else
			PESPToggle:SetValue(true)
		end
	end)

	-- Paragraphs

	Tabs.ESPs:AddParagraph({
		Title = "Settings",
		Content = "Setup your Player ESP"
	})

	-- Settings Tumblers

	local Espcolorpicker = Tabs.ESPs:AddColorpicker("ESPsColorPicker", {
		Title = "Choose color of ESP",
		Default = Color3.fromRGB(41, 255, 8)
	})

	Espcolorpicker:OnChanged(function()
		CurrentColor = Options.ESPsColorPicker.Value
		for char,table in ESPBGUIs do
			if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
				if IsColorByHP == false then
					local Text = ESPBGUIs[char].BGUI:FindFirstChild("Text")
					if Text then
						Text.TextColor3 = Options.ESPsColorPicker.Value
					end
				end
			else
				ClearConnections(char)
			end
		end
	end)

	local PNickNameToggle = Tabs.ESPs:AddToggle("PNicknamesToggle", { Title = "Nicknames", Default = true })

	PNickNameToggle:OnChanged(function()
		if Options.PNicknamesToggle.Value == true then
			IsNickname = true
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearConnections(i)
				end
			end
		else
			IsNickname = false
			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
					continue
				else
					ClearConnections(i)
				end
			end
		end
	end)

	local PHPToggle = Tabs.ESPs:AddToggle("PHPsToggle", { Title = "HPs", Default = false })

	PHPToggle:OnChanged(function()
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
					ClearConnections(i)
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
					ClearConnections(i)
				end
			end
		end
	end)

	local PDistanceToggle = Tabs.ESPs:AddToggle("PDistancesToggle", { Title = "Distances", Default = false })

	PDistanceToggle:OnChanged(function()
		if Options.PDistancesToggle.Value == true then
			IsDistance = true

			if DistancesThread then
				task.cancel(DistancesThread)
				DistancesThread = nil
			end

			DistancesThread = task.spawn(function()
				local count = 0
				while IsDistance == true do
					for char,bgui in ESPBGUIs do
						count += 1
						if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
							UpdateGUI(ESPBGUIs[char].BGUI)
						else
							ClearConnections(char)
						end
					end
					if count <= 0 then
						break
					else
						count = 0
					end
					task.wait(0.1)
				end
			end)

			for i,v in ESPBGUIs do
				if i.Parent ~= nil and ESPBGUIs[i].BGUI ~= nil then
					UpdateGUI(ESPBGUIs[i].BGUI)
				else
					ClearConnections(i)
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
					ClearConnections(i)
				end
			end
		end
	end)

	
	local PColorByHPToggle = Tabs.ESPs:AddToggle("PCByHPToggle", { Title = "Color by Enemy HP", Default = false })

	PColorByHPToggle:OnChanged(function()
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
					ClearConnections(char)
				end
			end
		else
			IsColorByHP = false
			for char,table in ESPBGUIs do
				if char.Parent ~= nil and ESPBGUIs[char].BGUI ~= nil then
					if IsColorByHP == false then
						local Text = ESPBGUIs[char].BGUI:FindFirstChild("Text")
						if Text then
							Text.TextColor3 = Options.ESPsColorPicker.Value
						end
						if IsColorByHP == false and IsHP == false then
							if ESPBGUIs[char]["HP"] then
								ESPBGUIs[char]["HP"]:Disconnect()
								ESPBGUIs[char]["HP"] = nil
							end
						end
					end
				else
					ClearConnections(char)
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
SaveManager:SetFolder("FluentScriptHub/specific-game")

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
