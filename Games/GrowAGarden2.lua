--[[
	PussyHub — Grow a Garden 2 Module
	WindUI-integrated version: adds tabs/features into the hub window.
	Receives `Window` and `WindUI` from the hub loader.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local WS = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local P = Players.LocalPlayer
if not P then P = Players.PlayerAdded:Wait() end

local Window = getgenv().PussyHub_Window
local WindUI = getgenv().PussyHub_WindUI
if not Window or not WindUI then
	warn("[GAG2] Missing Window/WindUI — load via hub")
	return
end

print("[GAG2] Loading GAG2 features into hub...")

------------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------------
local CFG = {
	AutoHarvest = true, AutoSell = false, AutoCollect = true,
	AutoSteal = false, SpeedHack = false, JumpHack = false, Noclip = false,
	AutoSellWhenFull = true, SpoofMode = true, SellTeleport = true,
	WalkSpeed = 80, JumpPower = 120,
	PlantESP = false, StealESP = false, ValueESP = false, PerfMode = false,
	Running = true, ActiveTab = nil,
	HarvestCount = 0, StealCount = 0, SellCount = 0, ValueCollected = 0,
	HarvestDelay = 0.05, FullInventoryThreshold = 10,
	MY_USER_ID = tostring(P.UserId),
	_collectCooldown = {}, _harvestCooldown = {},
	FruitValues = {
		Blueberry = 10, Strawberry = 15, Raspberry = 20, Tomato = 25,
		Corn = 30, Pumpkin = 40, Melon = 50, Watermelon = 60,
		Grape = 35, Apple = 22, Orange = 28, Lemon = 32,
		Cherry = 45, Peach = 38, Pear = 42, Banana = 55,
		Kiwi = 48, Mango = 65, Pineapple = 80,
		Sunflower = 12, Acorn = 8, Beanstalk = 70, Cactus = 35,
		Coconut = 45,
		["Poison Apple"] = 20, ["Venus Fly Trap"] = 55,
		["Thorn Rose"] = 60, Pomegranate = 40, Lotus = 50,
		["Poison Ivy"] = 25, ["Ghost Pepper"] = 90, Romanesco = 30,
		["Baby Cactus"] = 18, ["Glow Mushroom"] = 75, ["Horned Melon"] = 85,
		Pinetree = 15, ["Moon Bloom"] = 95, ["Dragon Fruit"] = 100,
		["Dragon's Breath"] = 95, ["Green Bean"] = 22, ["Venom Spitter"] = 65,
		["Briar Rose"] = 70, ["Hypno Bloom"] = 88, ["Fire Fern"] = 92,
		["Sun Bloom"] = 78, ["Eclipse Bloom"] = 130, ["Star Fruit"] = 150,
	},
}

------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------
local function isUtilityTool(tool)
	local n = tool.Name:lower()
	if n:find("shovel") or n:find("build") or n:find("giftholder") or n:find("mail")
		or n:find("gift") or n:find("water") or n:find("can") or n:find("trowel")
		or n:find("rake") or n:find("spray") or n:find("wrench") or n:find("hammer")
		or n:find("lantern") or n:find("teleport") or n:find("megaphone")
		or n:find("boombox") or n:find("crowbar") or n:find("hose")
		or n:find("staff") or n:find("carpet") or n:find("magnet")
		or n:find("grappling") or n:find("spring") or n:find("freeze") then
		return true
	end
	local hf = tool:GetAttribute("HarvestedFruit")
	local fn = tool:GetAttribute("Fruit") or tool:GetAttribute("FruitName")
	if hf == true or (type(fn) == "string" and fn ~= "") then return false end
	return true
end

local function getToolFruitValue(tool)
	if not tool or not tool:IsA("Tool") then return 0, "", 1 end
	local fname = tool:GetAttribute("Fruit") or tool:GetAttribute("FruitName") or ""
	local weight = tool:GetAttribute("Weight")
	if type(weight) ~= "number" then
		local w = tool.Name:match("%[(%d+%.?%d*)%s*k?g%]")
		weight = tonumber(w) or 1
	end
	local clean = fname
	if clean == "" then
		clean = tool.Name:gsub("%[.-%]", ""):gsub("%s+$", ""):gsub("^%s+", "")
	end
	local base = CFG.FruitValues[clean] or 0
	local value = base * weight
	if tool.Name:find("%[Gold%]") then value = value * 1.3 end
	return math.floor(value), (fname ~= "" and fname or clean), weight
end

local function getFruitCount()
	local count = 0
	local function scan(container)
		if not container then return end
		for _, v in pairs(container:GetChildren()) do
			if v:IsA("Tool") and not isUtilityTool(v) then count = count + 1 end
		end
	end
	scan(P:FindFirstChild("Backpack"))
	scan(P.Character)
	return count
end

local function getInventoryWithValues()
	local items = {}
	local function scan(cont, label)
		if not cont then return end
		for _, v in pairs(cont:GetChildren()) do
			if v:IsA("Tool") and not isUtilityTool(v) then
				local val, fruitName, weight = getToolFruitValue(v)
				table.insert(items, {name = v.Name, value = val, inst = v, fruitName = fruitName, weight = weight, source = label})
			end
		end
	end
	scan(P:FindFirstChild("Backpack"), "Backpack")
	scan(P.Character, "Character")
	table.sort(items, function(a, b) return a.value > b.value end)
	return items
end

local function checkCooldown(tbl, key, cd)
	local now = tick()
	if now - (tbl[key] or 0) >= cd then tbl[key] = now; return true end
	return false
end

local function firePrompt(prompt)
	if not prompt then return end
	if prompt:IsA("ProximityPrompt") then
		pcall(function() fireproximityprompt(prompt) end)
		pcall(function()
			prompt:InputHoldBegin()
			task.wait(math.max(0.05, prompt.HoldDuration or 0.05))
			prompt:InputHoldEnd()
		end)
	elseif prompt:IsA("ClickDetector") then
		pcall(function() fireclickdetector(prompt) end)
	end
end

local function spoofCFire(part, prompt)
	pcall(function()
		if CFG.SpoofMode then
			firePrompt(prompt)
		else
			local char = P.Character
			if char and char:FindFirstChild("HumanoidRootPart") and part then
				local hrp = char.HumanoidRootPart
				local orig = hrp.CFrame
				hrp.CFrame = part.CFrame + Vector3.new(0, 0.5, 0)
				task.wait(0.05)
				firePrompt(prompt)
				hrp.CFrame = orig
			end
		end
	end)
end

local function clickGuiButton(btn)
	if not btn then return false end
	pcall(function()
		if type(firesignal) == "function" then
			firesignal(btn.MouseButton1Click)
			firesignal(btn.Activated)
		end
		if type(getconnections) == "function" then
			for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
				pcall(function() c:Fire() end)
			end
		end
		btn.MouseButton1Click:Fire()
		btn.Activated:Fire()
		local vim2 = game:GetService("VirtualInputManager")
		local inset = GuiService:GetGuiInset()
		local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
		local x = pos.X + size.X / 2
		local y = pos.Y + size.Y / 2 + inset.Y
		vim2:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(0.05)
		vim2:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
	return true
end

------------------------------------------------------------------------
-- GARDEN / PLOT
------------------------------------------------------------------------
local function isMyPlot(plot)
	for _, a in ipairs({"Owner", "UserId", "OwnerId", "OwnerUserId", "PlayerId"}) do
		local v = plot:GetAttribute(a)
		if tonumber(v) and tonumber(v) == P.UserId then return true end
		if type(v) == "string" and v == P.Name then return true end
	end
	local plants = plot:FindFirstChild("Plants")
	if plants then
		for _, pl in pairs(plants:GetChildren()) do
			if tonumber(pl:GetAttribute("UserId")) == P.UserId then return true end
			if pl.Name:match("^(%d+)_") == CFG.MY_USER_ID then return true end
		end
	end
	local signs = plot:FindFirstChild("Signs")
	if signs then
		local cp = signs:FindFirstChild("Garden")
		if cp then
			local cp2 = cp:FindFirstChild("CorePart")
			if cp2 then
				for _, d in pairs(cp2:GetDescendants()) do
					if d:IsA("ProximityPrompt") and d.Enabled and d.Name == "CustomiseTheme" then
						return true
					end
				end
			end
		end
	end
	return false
end

local function getMyGarden()
	local gardens = WS:FindFirstChild("Gardens")
	if not gardens then return nil end
	for _, plot in pairs(gardens:GetChildren()) do
		if plot:IsA("Model") and isMyPlot(plot) then return plot end
	end
	return nil
end

------------------------------------------------------------------------
-- HARVEST
------------------------------------------------------------------------
local function isHarvestPrompt(d)
	if not d:IsA("ProximityPrompt") or not d.Enabled then return false end
	local at = (d.ActionText or ""):lower()
	return d.Name == "HarvestPrompt" or at == "collect" or at == "harvest"
end

local function getMyHarvestTargets()
	local plot = getMyGarden()
	if not plot then return {} end
	local plants = plot:FindFirstChild("Plants")
	if not plants then return {} end
	local targets, seen = {}, {}
	for _, plant in pairs(plants:GetChildren()) do
		local seedName = plant:GetAttribute("SeedName") or "?"
		local sm = 1
		local fruits = plant:FindFirstChild("Fruits")
		if fruits then
			local fr = fruits:GetChildren()[1]
			if fr then sm = tonumber(fr:GetAttribute("SizeMulti")) or 1 end
		end
		local ev = math.floor((CFG.FruitValues[seedName] or 10) * sm)
		for _, d in pairs(plant:GetDescendants()) do
			if isHarvestPrompt(d) then
				local part = d.Parent
				if part and part:IsA("BasePart") and not seen[d] then
					seen[d] = true
					table.insert(targets, {part = part, prompt = d, key = d:GetFullName(), value = ev, seed = seedName})
				end
			end
		end
	end
	table.sort(targets, function(a, b) return a.value > b.value end)
	return targets
end

local function DoHarvest(quiet)
	local ok, err = pcall(function()
		local targets = getMyHarvestTargets()
		if #targets == 0 then return end
		local h = 0
		for _, t in ipairs(targets) do
			if checkCooldown(CFG._harvestCooldown, t.key, 0.4) then
				spoofCFire(t.part, t.prompt)
				h = h + 1
				CFG.HarvestCount = CFG.HarvestCount + 1
			end
			task.wait(CFG.HarvestDelay)
		end
		if h > 0 and not quiet then
			WindUI:Notify({Title = "GAG2", Content = "Harvested " .. h .. " fruits", Duration = 3})
		end
	end)
end

------------------------------------------------------------------------
-- SELL (FIXED: NPC selection + dialog detection)
------------------------------------------------------------------------
local SELL_NPC_ORDER = {"Steven", "Sam", "Charlotte", "Gilbert"}

local function findSellNPC()
	local npcs = WS:FindFirstChild("NPCS")
	if not npcs then return nil, nil, nil end
	local candidates = {}
	local function consider(npcModel, npcLabel)
		if not npcModel then return end
		local labelLower = npcLabel:lower()
		if labelLower:find("george") then return end
		for _, d in pairs(npcModel:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				local at = (d.ActionText or ""):lower()
				local nm = d.Name:lower()
				if not (nm:find("exit") or at:find("exit")) and (at == "talk" or at:find("sell")) then
					local parent = d.Parent
					if parent and parent:IsA("BasePart") then
						local score = 10
						if at:find("sell") then score = score + 200 end
						if at == "talk" then score = score + 50 end
						for i, pref in ipairs(SELL_NPC_ORDER) do
							if labelLower:find(pref:lower()) then score = score + (120 - i * 10) end
						end
						table.insert(candidates, {part = parent, prompt = d, name = npcLabel, score = score})
					end
				end
			end
		end
	end
	for _, name in ipairs(SELL_NPC_ORDER) do
		consider(npcs:FindFirstChild(name), name)
	end
	for _, npc in pairs(npcs:GetChildren()) do
		if not npc.Name:lower():find("model") then
			consider(npc, npc.Name)
		end
	end
	if #candidates == 0 then return nil, nil, nil end
	table.sort(candidates, function(a, b) return a.score > b.score end)
	local best = candidates[1]
	return best.part, best.prompt, best.name
end

local function findDialogGui()
	local m = P.PlayerGui:FindFirstChild("Message")
	if m and m:IsA("ScreenGui") and m.Enabled then return m end
	for _, gui in pairs(P.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled then
			local gn = gui.Name:lower()
			if gn:find("dialog") or (gn:find("npc") and not gn:find("pussyhub") and not gn:find("miku")) then
				return gui
			end
		end
	end
	return nil
end

local function clickSellAllButton()
	local dlg = findDialogGui()
	if not dlg then return false end
	local options = {}
	for _, d in pairs(dlg:GetDescendants()) do
		if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible ~= false then
			local tx = pcall(function() return d.Text or "" end) and d.Text or ""
			local ln = (tx .. " " .. d.Name):lower()
			local bad = ln:find("exit") or ln:find("close") or ln:find("cancel")
				or ln:find("nevermind") or ln:find("buy") or ln:find("gift")
				or ln:find("friend") or ln:find("decline")
			if not bad then
				local sellHit = 0
				for _, pat in ipairs({"sell all", "sellall", "sell inventory", "sell crops",
				                      "sell fruit", "sell items", "sell everything", "sell"}) do
					if ln:find(pat) then sellHit = 100 break end
				end
				local lo = 999
				pcall(function() lo = d.LayoutOrder end)
				table.insert(options, {btn = d, sell = sellHit, lo = lo, tx = tx})
			end
		end
	end
	if #options == 0 then return false end
	table.sort(options, function(a, b)
		if a.sell ~= b.sell then return a.sell > b.sell end
		return a.lo < b.lo
	end)
	return clickGuiButton(options[1].btn)
end

local function pressTeleportSellButton()
	local tb = P.PlayerGui:FindFirstChild("TeleportButtons")
	if not tb then return false end
	for _, d in pairs(tb:GetDescendants()) do
		if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Name:lower():find("sell") then
			clickGuiButton(d)
			return true
		end
	end
	return false
end

local function DoSell()
	local ok, err = pcall(function()
		local items = getInventoryWithValues()
		local fc = getFruitCount()
		if #items == 0 and fc == 0 then return end
		local totalVal = 0
		for _, it in ipairs(items) do totalVal = totalVal + it.value end

		local char = P.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local hrp = char.HumanoidRootPart
		local origCFrame = hrp.CFrame

		if CFG.SellTeleport then
			pressTeleportSellButton()
			task.wait(1.0)
		end

		local nhrp, prompt, npcName = findSellNPC()
		if nhrp and prompt then
			if CFG.SellTeleport then
				pcall(function() hrp.CFrame = nhrp.CFrame * CFrame.new(0, 0, 3) end)
				task.wait(0.4)
			end
			firePrompt(prompt)
			task.wait(0.25)
			firePrompt(prompt)
		end

		local clicked = false
		for attempt = 1, 10 do
			task.wait(0.45)
			local gear = P.PlayerGui:FindFirstChild("GearShop")
			if gear and gear.Enabled then
				for _, d in pairs(gear:GetDescendants()) do
					if d:IsA("TextButton") and d.Name:lower():find("exit") then
						clickGuiButton(d); break
					end
				end
				break
			end
			if findDialogGui() then
				clicked = clickSellAllButton()
				if clicked then
					for chain = 1, 3 do
						task.wait(0.5)
						if findDialogGui() then clickSellAllButton() else break end
					end
					break
				end
			end
		end

		task.wait(0.8)
		local fcMid = getFruitCount()
		if fcMid >= fc then
			local npcs = WS:FindFirstChild("NPCS")
			if npcs then
				for _, name in ipairs(SELL_NPC_ORDER) do
					if getFruitCount() < fc then break end
					local node = npcs:FindFirstChild(name)
					if node then
						local pr, part
						for _, d in pairs(node:GetDescendants()) do
							if d:IsA("ProximityPrompt") and (d.ActionText or ""):lower() == "talk"
								and not d.Name:lower():find("exit") then
								pr, part = d, d.Parent; break
							end
						end
						if pr and part and part:IsA("BasePart") then
							if CFG.SellTeleport then
								pcall(function() hrp.CFrame = part.CFrame * CFrame.new(0, 0, 2.5) end)
								task.wait(0.35)
							end
							firePrompt(pr)
							task.wait(0.8)
							clickSellAllButton()
							task.wait(0.7)
						end
					end
				end
			end
		end

		if CFG.SellTeleport then pcall(function() hrp.CFrame = origCFrame end) end
		task.wait(0.2)

		local fcAfter = getFruitCount()
		if fcAfter < fc then
			CFG.SellCount = CFG.SellCount + (fc - fcAfter)
			CFG.ValueCollected = CFG.ValueCollected + totalVal
			WindUI:Notify({Title = "GAG2 Sold", Content = (fc - fcAfter) .. " fruits (~" .. totalVal .. "c)", Duration = 3})
		end
	end)
end

------------------------------------------------------------------------
-- COLLECT
------------------------------------------------------------------------
local COLLECT_NAMES = {"sheckle", "coin", "orb", "pickup", "drop", "collect"}
local function doCollect()
	pcall(function()
		local char = P.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local hrp = char.HumanoidRootPart
		local perPass = 0
		for _, v in pairs(WS:GetDescendants()) do
			if perPass >= 40 then break end
			if v:IsA("BasePart") then
				local n = v.Name:lower()
				local match = false
				for _, kw in ipairs(COLLECT_NAMES) do
					if n:find(kw) then match = true break end
				end
				if match and (hrp.Position - v.Position).Magnitude <= 250 then
					local key = v:GetFullName()
					if checkCooldown(CFG._collectCooldown, key, 0.6) then
						local fired = false
						for _, d in pairs(v:GetDescendants()) do
							if d:IsA("ProximityPrompt") and d.Enabled then firePrompt(d); fired = true; break end
						end
						if not fired then pcall(function() v.CFrame = hrp.CFrame end) end
						perPass = perPass + 1
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- STEAL
------------------------------------------------------------------------
local function getStealTargets()
	local gardens = WS:FindFirstChild("Gardens")
	if not gardens then return {} end
	local targets = {}
	for _, plot in pairs(gardens:GetChildren()) do
		if plot:IsA("Model") and not isMyPlot(plot) then
			local plants = plot:FindFirstChild("Plants")
			if plants then
				for _, pl in pairs(plants:GetChildren()) do
					for _, d in pairs(pl:GetDescendants()) do
						if d:IsA("ProximityPrompt") and d.Enabled
							and (d.ActionText or ""):lower() == "steal" then
							local part = d.Parent
							if part and part:IsA("BasePart") then
								table.insert(targets, {part = part, prompt = d, key = pl.Name .. d:GetFullName()})
							end
							break
						end
					end
				end
			end
		end
	end
	return targets
end

local function DoSteal(forceNight)
	pcall(function()
		local ct = Lighting.ClockTime
		if not forceNight and not (ct < 6 or ct > 18) then
			WindUI:Notify({Title = "GAG2", Content = "Not night (" .. math.floor(ct) .. ":00)", Duration = 3})
			return
		end
		local targets = getStealTargets()
		if #targets == 0 then
			WindUI:Notify({Title = "GAG2", Content = "No stealable fruits", Duration = 3})
			return
		end
		local stolen = 0
		for _, t in ipairs(targets) do
			if checkCooldown(CFG._harvestCooldown, t.key, 0.4) then
				spoofCFire(t.part, t.prompt)
				stolen = stolen + 1
				CFG.StealCount = CFG.StealCount + 1
			end
			task.wait(CFG.HarvestDelay)
		end
		if stolen > 0 then
			WindUI:Notify({Title = "GAG2 Steal", Content = stolen .. " fruits stolen", Duration = 3})
		end
	end)
end

------------------------------------------------------------------------
-- TELEPORT
------------------------------------------------------------------------
local function TeleportToMyGarden()
	pcall(function()
		local plot = getMyGarden()
		if not plot then return end
		local char = P.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local ref = plot:FindFirstChildWhichIsA("BasePart")
		if ref then char.HumanoidRootPart.CFrame = ref.CFrame + Vector3.new(0, 5, 0) end
	end)
end

local function TeleportToNPC(name)
	pcall(function()
		local npcs = WS:FindFirstChild("NPCS")
		if not npcs then return end
		local npc = npcs:FindFirstChild(name)
		if not npc then
			local m = npcs:FindFirstChild("Model")
			if m then npc = m:FindFirstChild(name) end
		end
		if not npc then return end
		local char = P.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local nhrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
		if nhrp then char.HumanoidRootPart.CFrame = nhrp.CFrame + Vector3.new(0, 3, 4) end
	end)
end

local function TeleportToSellStand()
	pcall(function()
		local char = P.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local hrp = char.HumanoidRootPart
		local map = WS:FindFirstChild("Map")
		if map then
			local stands = map:FindFirstChild("Stands")
			if stands then
				local sell = stands:FindFirstChild("Sell")
				if sell then
					local ref = sell:FindFirstChildWhichIsA("BasePart") or sell.PrimaryPart
					if ref then hrp.CFrame = ref.CFrame + Vector3.new(0, 3, 3); return end
				end
			end
		end
		hrp.CFrame = CFrame.new(268.4, 148, -127.5)
	end)
end

------------------------------------------------------------------------
-- PERFORMANCE
------------------------------------------------------------------------
local function ApplyPerfMode(enabled)
	pcall(function()
		if enabled then
			pcall(function() settings().Rendering.QualityLevel = 1 end)
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 999999
			Lighting.Brightness = 0
			for _, v in pairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") then v.Enabled = false end
			end
		else
			pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level09 end)
			Lighting.GlobalShadows = true
			Lighting.FogEnd = 100000
			Lighting.Brightness = 2
			for _, v in pairs(Lighting:GetChildren()) do
				if v:IsA("PostEffect") then v.Enabled = true end
			end
		end
	end)
end

local function DebugRemotes()
	local found = 0
	local function scan2(v, path, depth)
		if found >= 60 or depth > 8 then return end
		for _, c in pairs(v:GetChildren()) do
			if found >= 60 then return end
			if c:IsA("RemoteEvent") or c:IsA("RemoteFunction") then
				found = found + 1
			end
			scan2(c, path .. "." .. c.Name, depth + 1)
		end
	end
	scan2(RS, "RS", 0)
	WindUI:Notify({Title = "GAG2 Remotes", Content = found .. " remotes found", Duration = 3})
end

------------------------------------------------------------------------
-- ESP
------------------------------------------------------------------------
local espObjs = {}
local function clearESP()
	for _, e in pairs(espObjs) do pcall(function() e:Destroy() end) end
	espObjs = {}
end

local function makeESP(part, txt, col, h)
	if not part or part:FindFirstChild("_PH_ESP") then return end
	h = h or 16
	local bg = Instance.new("BillboardGui")
	bg.Name = "_PH_ESP"; bg.Size = UDim2.new(0, 90, 0, h + 4)
	bg.StudsOffset = Vector3.new(0, 2.5, 0); bg.AlwaysOnTop = true
	bg.MaxDistance = 500; bg.Parent = part
	local lb = Instance.new("TextLabel")
	lb.Size = UDim2.new(1, 0, 1, 0); lb.BackgroundTransparency = 1
	lb.Text = txt; lb.TextColor3 = col; lb.TextScaled = true
	lb.Font = Enum.Font.GothamBold; lb.Parent = bg
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 4); lc.Parent = lb
	table.insert(espObjs, bg)
end

local function valueToColor(val)
	if val >= 100 then return Color3.fromRGB(150, 90, 255) end
	if val >= 60  then return Color3.fromRGB(255, 45, 120) end
	if val >= 30  then return Color3.fromRGB(255, 200, 40) end
	return Color3.fromRGB(0, 229, 255)
end

local function doESP()
	if not CFG.PlantESP and not CFG.StealESP and not CFG.ValueESP then
		if #espObjs > 0 then clearESP() end
		return
	end
	pcall(function()
		clearESP()
		local gardens = WS:FindFirstChild("Gardens")
		if not gardens then return end
		for _, plot in pairs(gardens:GetChildren()) do
			if plot:IsA("Model") then
				local mine = isMyPlot(plot)
				local plants = plot:FindFirstChild("Plants")
				if plants then
					for _, pl in pairs(plants:GetChildren()) do
						local basePart = pl:FindFirstChild("Base") or pl:FindFirstChildWhichIsA("BasePart")
						local seedName = pl:GetAttribute("SeedName") or "?"
						local ready = pl:GetAttribute("PlantGrowthReady")
						local age = tonumber(pl:GetAttribute("Age")) or 0
						local maxAge = tonumber(pl:GetAttribute("MaxAge")) or 0
						local readyText = (ready == true or (maxAge > 0 and age >= maxAge)) and "READY" or "growing"
						if basePart then
							if mine and CFG.PlantESP then
								makeESP(basePart, "HARVEST " .. seedName .. " (" .. readyText .. ")", Color3.fromRGB(170, 255, 60), 18)
							elseif not mine and CFG.StealESP then
								makeESP(basePart, "STEAL " .. seedName .. " (" .. readyText .. ")", Color3.fromRGB(255, 45, 120), 18)
							end
						end
						if CFG.ValueESP then
							local fruits = pl:FindFirstChild("Fruits")
							if fruits then
								for _, fr in pairs(fruits:GetChildren()) do
									if fr:IsA("Model") then
										local part = fr:FindFirstChildWhichIsA("BasePart")
										local fname = fr:GetAttribute("CorePartName") or seedName
										local sm = tonumber(fr:GetAttribute("SizeMulti")) or 1
										local value = math.floor((CFG.FruitValues[fname] or 10) * sm)
										if part then makeESP(part, fname .. " " .. value .. "$", valueToColor(value), 14) end
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- WINDUI TABS
------------------------------------------------------------------------

-- AUTO TAB
local AutoTab = Window:Tab({Title = "Auto (GAG2)", Icon = "solar:autoplay-bold"})
local AutoSection = AutoTab:Section({Title = "Master"})
AutoTab:Toggle({Title = "AUTO PROGRESS", Desc = "Master toggle for all automation", Callback = function(v)
	CFG.AutoProgress = v
	WindUI:Notify({Title = "GAG2", Content = v and "Auto progress enabled" or "Auto progress paused", Duration = 3})
end})

local AutoFeatures = AutoTab:Section({Title = "Features"})
AutoTab:Toggle({Title = "Auto Harvest", Desc = "Collect ready fruits", Value = true, Callback = function(v) CFG.AutoHarvest = v end})
AutoTab:Toggle({Title = "Auto Sell", Desc = "Sell every cycle", Callback = function(v) CFG.AutoSell = v end})
AutoTab:Toggle({Title = "Sell When Full", Desc = "Auto sell at inventory limit", Value = true, Callback = function(v) CFG.AutoSellWhenFull = v end})
AutoTab:Toggle({Title = "Auto Collect", Desc = "Pick up sheckles/drops", Value = true, Callback = function(v) CFG.AutoCollect = v end})
AutoTab:Toggle({Title = "Spoof Mode", Desc = "Remote fire without teleporting", Value = true, Callback = function(v) CFG.SpoofMode = v end})
AutoTab:Toggle({Title = "Sell: Teleport to NPC", Value = true, Callback = function(v) CFG.SellTeleport = v end})

local AutoTuning = AutoTab:Section({Title = "Tuning"})
AutoTab:Slider({Title = "Per-Plant Delay", Step = 0.01, Value = {Min = 0.01, Max = 0.5, Default = 0.05}, Callback = function(v) CFG.HarvestDelay = v end})
AutoTab:Slider({Title = "Full Inventory At", Step = 1, Value = {Min = 2, Max = 50, Default = 10}, Callback = function(v) CFG.FullInventoryThreshold = v end})

local AutoActions = AutoTab:Section({Title = "Actions"})
AutoTab:Button({Title = "Harvest Now (value order)", Callback = function() task.spawn(DoHarvest) end})
AutoTab:Button({Title = "Sell Now", Callback = function() task.spawn(DoSell) end})
AutoTab:Button({Title = "Scan Garden", Callback = function()
	local plot = getMyGarden()
	if plot then
		local plants = plot:FindFirstChild("Plants")
		local count = plants and #plants:GetChildren() or 0
		WindUI:Notify({Title = "GAG2", Content = count .. " plants in " .. plot.Name, Duration = 3})
	else
		WindUI:Notify({Title = "GAG2", Content = "No garden found", Duration = 3})
	end
end})

-- STEAL TAB
local StealTab = Window:Tab({Title = "Steal", Icon = "solar:thief-bold"})
StealTab:Toggle({Title = "Auto Steal (night only)", Callback = function(v) CFG.AutoSteal = v end})
StealTab:Button({Title = "Find Stealable", Callback = function()
	local targets = getStealTargets()
	WindUI:Notify({Title = "GAG2", Content = #targets .. " stealable fruits", Duration = 3})
end})
StealTab:Button({Title = "Steal Now (force night)", Callback = function() task.spawn(function() DoSteal(true) end) end})

-- PLAYER TAB
local PlayerTab = Window:Tab({Title = "Player", Icon = "solar:user-bold"})
PlayerTab:Slider({Title = "Walk Speed", Step = 1, Value = {Min = 16, Max = 500, Default = 80}, Callback = function(v) CFG.WalkSpeed = v end})
PlayerTab:Slider({Title = "Jump Power", Step = 1, Value = {Min = 50, Max = 500, Default = 120}, Callback = function(v) CFG.JumpPower = v end})
PlayerTab:Toggle({Title = "Speed Hack", Callback = function(v)
	CFG.SpeedHack = v
	pcall(function()
		local c = P.Character
		if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v and CFG.WalkSpeed or 16 end
	end)
end})
PlayerTab:Toggle({Title = "Jump Hack", Callback = function(v)
	CFG.JumpHack = v
	pcall(function()
		local c = P.Character
		if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v and CFG.JumpPower or 50 end
	end)
end})
PlayerTab:Toggle({Title = "Noclip", Callback = function(v)
	CFG.Noclip = v
	if not v then
		pcall(function()
			local c = P.Character
			if c then
				for _, part in pairs(c:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = true end
				end
			end
		end)
	end
end})

-- ESP TAB
local ESPTab = Window:Tab({Title = "ESP", Icon = "solar:eye-bold"})
ESPTab:Toggle({Title = "Plant ESP (my garden)", Callback = function(v) CFG.PlantESP = v end})
ESPTab:Toggle({Title = "Steal ESP (other gardens)", Callback = function(v) CFG.StealESP = v end})
ESPTab:Toggle({Title = "Value ESP (fruit prices)", Callback = function(v) CFG.ValueESP = v end})

-- TELEPORT TAB
local TPTab = Window:Tab({Title = "Teleport", Icon = "solar:map-arrow-up-bold"})
TPTab:Button({Title = "My Garden", Callback = TeleportToMyGarden})
TPTab:Button({Title = "Sell Stand", Callback = TeleportToSellStand})
TPTab:Button({Title = "Steven (SELL)", Callback = function() TeleportToNPC("Steven") end})
TPTab:Button({Title = "Sam", Callback = function() TeleportToNPC("Sam") end})
TPTab:Button({Title = "Charlotte", Callback = function() TeleportToNPC("Charlotte") end})
TPTab:Button({Title = "Gilbert", Callback = function() TeleportToNPC("Gilbert") end})
TPTab:Button({Title = "George (GEAR)", Callback = function() TeleportToNPC("George") end})

-- PERF TAB
local PerfTab = Window:Tab({Title = "Perf", Icon = "solar:ram-bold"})
PerfTab:Toggle({Title = "Perf Mode", Callback = function(v) CFG.PerfMode = v; ApplyPerfMode(v) end})
PerfTab:Button({Title = "FPS Boost", Callback = function() ApplyPerfMode(true) end})
PerfTab:Button({Title = "Restore Quality", Callback = function() ApplyPerfMode(false) end})
PerfTab:Button({Title = "Debug Remotes", Callback = DebugRemotes})

------------------------------------------------------------------------
-- MAIN AUTO LOOP
------------------------------------------------------------------------
WindUI:Notify({Title = "GAG2", Content = "Grow a Garden 2 loaded!", Duration = 3})

task.spawn(function()
	while CFG.Running do
		task.wait(0.5)
		if CFG.AutoProgress and CFG.Running then
			if CFG.AutoHarvest then DoHarvest(true) end
			if CFG.AutoCollect then doCollect() end
			local fc = getFruitCount()
			if CFG.AutoSell and CFG.Running then
				DoSell()
			elseif CFG.AutoSellWhenFull and CFG.Running and fc >= CFG.FullInventoryThreshold then
				DoSell()
			end
			if CFG.AutoSteal then DoSteal(false) end
		end
		-- Movement hacks
		if CFG.SpeedHack then
			pcall(function()
				local c = P.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = CFG.WalkSpeed end
			end)
		end
		if CFG.JumpHack then
			pcall(function()
				local c = P.Character
				if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = CFG.JumpPower end
			end)
		end
		if CFG.Noclip then
			pcall(function()
				local c = P.Character
				if c then
					for _, part in pairs(c:GetDescendants()) do
						if part:IsA("BasePart") then part.CanCollide = false end
					end
				end
			end)
		end
		if CFG.PlantESP or CFG.StealESP or CFG.ValueESP then doESP() end
		task.wait(0.8)
	end
end)

-- Auto-reapply on respawn
P.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	if CFG.SpeedHack then
		local hum = char:WaitForChild("Humanoid", 3)
		if hum then hum.WalkSpeed = CFG.WalkSpeed end
	end
end)

print("[GAG2] Module loaded on " .. P.Name)
