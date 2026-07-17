-- @name: Blox Fruits
-- @description: Auto-Farm Features
-- Loads into PussyHub WindUI window

local Window = getgenv().PussyHub_Window
local WindUI = getgenv().PussyHub_WindUI
if not Window or not WindUI then
	warn("[BloxFruits] Load via PussyHub hub")
	return
end

print("[BloxFruits] Loading features...")

local Tab = Window:Tab({Title = "Blox Fruits", Icon = "solar:sword-bold"})
Tab:Section({Title = "Info"})
Tab:Paragraph({Title = "Blox Fruits Module", Desc = "Placeholder — features coming soon"})
Tab:Button({Title = "Test Load", Callback = function()
	WindUI:Notify({Title = "BloxFruits", Content = "Module loaded!", Duration = 3})
end})
