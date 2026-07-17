-- ui/Games.lua | Games tab: lists supported games + load buttons
local M = {}

-- Game registry. name -> { path, label, description, placeIds }
local REGISTRY = {
    { key = "adoptme",    label = "Adopt Me",                description = "Pet trades, dupe methods, GUI tools", path = "Games/AdoptMe.lua",    placeIds = {920587237} },
    { key = "bloxfruits", label = "Blox Fruits",             description = "Auto farm, fruit ESP, level scripts",  path = "Games/BloxFruits.lua", placeIds = {2753915549, 4442272183, 7449423635} },
    { key = "gag2",       label = "Grow A Garden 2",         description = "Scanner, sell helper, garden tools",  path = "Games/GrowAGarden2.lua", placeIds = {126884695634067} },
    { key = "kbdescape",  label = "Keyboard Escape (Universal)", description = "Force-leave any game with one click", path = "Games/keyboardEscape.lua", placeIds = {} },
}

function M.Build(parent, UI, ctx)
    -- Search + filter
    local search = UI.Input(parent, "Search games...", "", 0)
    search.LayoutOrder = 1
    local REPO = "https://raw.githubusercontent.com/levox00/RobloxHub/main"

    local listHolder = Instance.new("Frame", parent)
    listHolder.Name = "GameList"
    listHolder.Size = UDim2.new(1, 0, 1, -50)
    listHolder.Position = UDim2.fromOffset(0, 50)
    listHolder.BackgroundTransparency = 1
    listHolder.ClipsDescendants = true

    local list = Instance.new("UIListLayout", listHolder)
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    local function supportsHere(entry)
        if not entry.placeIds or #entry.placeIds == 0 then return true end  -- universal
        for _, pid in ipairs(entry.placeIds) do
            if pid == game.PlaceId then return true end
        end
        return false
    end

    local function render(filter)
        for _, c in ipairs(listHolder:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local i = 0
        for _, entry in ipairs(REGISTRY) do
            if not filter or filter == "" or entry.label:lower():find(filter:lower(), 1, true) then
                i = i + 1
                local card = UI.GlassCard(listHolder, {
                    Size = UDim2.new(1, 0, 0, 86),
                    Name = "Game_" .. entry.key,
                })
                card.LayoutOrder = i

                local supported = supportsHere(entry)
                local tagText = supported and "Supported" or "Not this game"
                local tagColor = supported and UI.Theme.Success or UI.Theme.Warn
                UI.Pill(card.Pad, tagText, tagColor, {Position = UDim2.new(1, -100, 0, 0)})

                local t = Instance.new("TextLabel", card.Pad)
                t.Size = UDim2.new(1, -110, 0, 22)
                t.BackgroundTransparency = 1
                t.Font = Enum.Font.GothamBold
                t.Text = entry.label
                t.TextColor3 = UI.Theme.TextPrimary
                t.TextSize = 15
                t.TextXAlignment = Enum.TextXAlignment.Left

                local d = Instance.new("TextLabel", card.Pad)
                d.Size = UDim2.new(1, 0, 0, 16)
                d.Position = UDim2.fromOffset(0, 24)
                d.BackgroundTransparency = 1
                d.Font = Enum.Font.Gotham
                d.Text = entry.description
                d.TextColor3 = UI.Theme.TextSub
                d.TextSize = 12
                d.TextXAlignment = Enum.TextXAlignment.Left

                local loadBtn = UI.GlassButton(card.Pad, "Load", function()
                    local src = ctx.httpGet(REPO .. "/" .. entry.path)
                    if not src or src == "" then
                        UI.Notify("Failed to fetch " .. entry.label, "error")
                        return
                    end
                    local fn, err = loadstring(src)
                    if not fn then
                        UI.Notify("Script error: " .. tostring(err):sub(1, 60), "error")
                        return
                    end
                    local ok, runErr = pcall(fn)
                    if ok then
                        UI.Notify(entry.label .. " loaded!", "success")
                    else
                        UI.Notify("Run error: " .. tostring(runErr):sub(1, 60), "error")
                    end
                end, {Position = UDim2.new(1, -90, 1, -40), Size = UDim2.fromOffset(80, 32), TextSize = 13})

                if not supported then
                    loadBtn.BackgroundColor3 = UI.Theme.Warn
                    loadBtn.BackgroundTransparency = 0.30
                end
            end
        end
        if i == 0 then
            local empty = Instance.new("TextLabel", listHolder)
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.Text = "No games match \"" .. tostring(filter) .. "\""
            empty.TextColor3 = UI.Theme.TextMuted
            empty.TextSize = 13
        end
    end

    render("")
    search:GetPropertyChangedSignal("Text"):Connect(function() render(search.Text) end)
end

return M
