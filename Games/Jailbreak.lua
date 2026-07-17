-- @name: Jailbreak
-- @description: Teleport & Vehicle Features
-- Loads into PussyHub WindUI window

local Window = getgenv().PussyHub_Window
local WindUI = getgenv().PussyHub_WindUI
if not Window or not WindUI then
	warn("[Jailbreak] Load via PussyHub hub")
	return
end

print("[Jailbreak] Loading features...")

local Tab = Window:Tab({Title = "Jailbreak", Icon = "solar:car-bold"})
Tab:Section({Title = "Info"})
Tab:Paragraph({Title = "Jailbreak Module", Desc = "Placeholder — features coming soon"})
Tab:Button({Title = "Test Load", Callback = function()
	WindUI:Notify({Title = "Jailbreak", Content = "Module loaded!", Duration = 3})
end})
