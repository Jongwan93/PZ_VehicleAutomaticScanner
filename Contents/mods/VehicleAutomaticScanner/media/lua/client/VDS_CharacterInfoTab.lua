-- Vehicle Diagnostic Scanner: tab on the Character Info panel (info/skills/health/...).
-- Hooks ISCharacterInfoWindow:createChildren to add a "Vehicle Scanner" tab.

require "ISUI/ISPanel"

local PAD = 8
local LINE_H = 18
local SEPARATOR_GAP = 4
local FONT = UIFont.Small
local TIRE_IDS = { "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }
local TIRE_LABELS = {
    TireFrontLeft = "FL",
    TireFrontRight = "FR",
    TireRearLeft = "RL",
    TireRearRight = "RR",
}

local function drawSeparator(panel, y, width)
    local w = width and (width - 2 * PAD) or (panel:getWidth() - 2 * PAD)
    if w > 0 then
        panel:drawRect(PAD, y, w, 1, 0.45, 0.5, 0.6, 0.85)
    end
end

VDS_CharacterInfoTab = ISPanel:derive("VDS_CharacterInfoTab")

function VDS_CharacterInfoTab:initialise()
    ISPanel.initialise(self)
end

function VDS_CharacterInfoTab:createChildren()
end

function VDS_CharacterInfoTab:render()
    ISPanel.render(self)
    local VDS = _G.VDS
    if not VDS then
        self:drawText("Vehicle Scanner (VDS not loaded)", PAD, PAD, 0.7, 0.7, 0.7, 1, FONT)
        return
    end
    local data = VDS.lastScanData
    local y = PAD
    if not data then
        self:drawText("Equip scanner near a vehicle.", PAD, y, 0.75, 0.75, 0.75, 1, FONT)
        y = y + LINE_H
        self:drawText("(Mechanics 4+ required)", PAD, y, 0.6, 0.6, 0.6, 1, FONT)
        return
    end
    local eng = tonumber(data.engine) or 0
    local gas = tonumber(data.fuel) or 0
    local bat = tonumber(data.battery) or 0
    local r, g, b = 0.85, 0.85, 0.9

    -- Section 1: Vehicle name
    self:drawText(data.vehicleName or "?", PAD, y, 0.9, 0.9, 0.9, 1, FONT)
    y = y + LINE_H + SEPARATOR_GAP
    drawSeparator(self, y, self:getWidth())
    y = y + 1 + SEPARATOR_GAP

    -- Section 2: Gas, Engine, Battery
    if VDS.getPercentColor then r, g, b = VDS.getPercentColor(gas) end
    self:drawText(string.format("Gas: %d%%", math.floor(gas)), PAD, y, r, g, b, 1, FONT)
    y = y + LINE_H
    r, g, b = 0.85, 0.85, 0.9
    if VDS.getPercentColor then r, g, b = VDS.getPercentColor(eng) end
    self:drawText(string.format("Engine: %d%%", math.floor(eng)), PAD, y, r, g, b, 1, FONT)
    y = y + LINE_H
    r, g, b = 0.85, 0.85, 0.9
    if VDS.getPercentColor then r, g, b = VDS.getPercentColor(bat) end
    self:drawText(string.format("Battery: %d%%", math.floor(bat)), PAD, y, r, g, b, 1, FONT)
    y = y + LINE_H + SEPARATOR_GAP
    drawSeparator(self, y, self:getWidth())
    y = y + 1 + SEPARATOR_GAP

    -- Section 3: Tires
    if data.tires then
        for _, id in ipairs(TIRE_IDS) do
            local cond = data.tires[id]
            if cond ~= nil then
                r, g, b = 0.85, 0.85, 0.9
                if VDS.getPercentColor then r, g, b = VDS.getPercentColor(cond) end
                local label = TIRE_LABELS[id] or id
                self:drawText(string.format("%s: %d%%", label, math.floor(cond)), PAD, y, r, g, b, 1, FONT)
                y = y + LINE_H
            end
        end
    end
    y = y + SEPARATOR_GAP
    drawSeparator(self, y, self:getWidth())
    y = y + 1 + SEPARATOR_GAP

    -- Section 4: Locked or Unlocked
    if data.locked ~= nil then
        if data.locked then
            self:drawText("Locked", PAD, y, 1, 0.4, 0.4, 1, FONT)
        else
            self:drawText("Unlocked", PAD, y, 0.4, 1, 0.4, 1, FONT)
        end
    end
end

function VDS_CharacterInfoTab:new(x, y, width, height, playerNum)
    local o = ISPanel.new(self, x, y, width, height)
    o.playerNum = playerNum or 0
    o:noBackground()
    return o
end

-- Tab title for the info panel (tooltip / window title when torn off)
local function getTabTitle()
    if getTextOrNull and getTextOrNull("IGUI_VDS_Tab") then
        return getTextOrNull("IGUI_VDS_Tab")
    end
    return "Vehicle Scanner"
end

-- Add our tab to an existing ISCharacterInfoWindow (hook or late inject)
function VDS_CharacterInfoTab.AddTabToWindow(win)
    if not win or not win.panel then return end
    if win.vdsView then return end -- already added
    local title = getTabTitle()
    local vdsView = VDS_CharacterInfoTab:new(0, 8, win.width, win.height - 8, win.playerNum)
    vdsView:initialise()
    vdsView.infoText = title
    win.panel:addView(title, vdsView)
    win.vdsView = vdsView
end

-- Hook ISCharacterInfoWindow:createChildren so new windows get our tab
local function hookCharacterInfoWindow()
    if not ISCharacterInfoWindow or not ISCharacterInfoWindow.createChildren then return end
    local oldCreateChildren = ISCharacterInfoWindow.createChildren
    function ISCharacterInfoWindow:createChildren()
        oldCreateChildren(self)
        VDS_CharacterInfoTab.AddTabToWindow(self)
    end
end

-- Inject tab into already-created window (e.g. mod loaded after game start)
local function injectExistingWindows()
    local n = (getNumActivePlayers and getNumActivePlayers()) or 0
    for i = 0, n - 1 do
        local win = getPlayerInfoPanel and getPlayerInfoPanel(i)
        if win then
            VDS_CharacterInfoTab.AddTabToWindow(win)
        end
    end
end

-- Run hook when script loads (game may have already defined ISCharacterInfoWindow)
hookCharacterInfoWindow()

-- When a new player is created, ensure their info window has our tab (backup if hook ran before window init)
Events.OnCreatePlayer.Add(function(playerNum, player)
    local id = (player and player.getPlayerNum and player:getPlayerNum()) or playerNum or 0
    local win = getPlayerInfoPanel and getPlayerInfoPanel(id)
    if win then
        VDS_CharacterInfoTab.AddTabToWindow(win)
    end
end)

-- One-time delayed inject for existing windows (covers load-order edge cases)
local injectTicks = 0
local function delayedInject()
    injectTicks = injectTicks + 1
    if injectTicks >= 30 then
        injectExistingWindows()
        Events.OnTick.Remove(delayedInject)
    end
end
Events.OnTick.Add(delayedInject)
