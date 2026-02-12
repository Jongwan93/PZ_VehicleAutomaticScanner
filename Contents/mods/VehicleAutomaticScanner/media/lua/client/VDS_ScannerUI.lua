-- Vehicle Diagnostic Scanner: popup window with vehicle info (engine, gas, battery).

require "ISUI/ISPanel"
require "ISUI/ISCollapsableWindow"

local PAD = 8
local LINE_H = 18
local FONT = UIFont.Small
local SEPARATOR_GAP = 4  -- gap above/below each divider line

-- Order and display names for the 4 tires (API part IDs from ISCarMechanicsOverlay / ISVehicleMenu)
local TIRE_IDS = { "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }
local TIRE_LABELS = { TireFrontLeft = "Front Left", TireFrontRight = "Front Right", TireRearLeft = "Rear Left", TireRearRight = "Rear Right" }

-- Content panel inside the window
VDS_ScannerDisplay = ISPanel:derive("VDS_ScannerDisplay")

function VDS_ScannerDisplay:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    o.backgroundColor = { r = 0.1, g = 0.1, b = 0.15, a = 0.85 }
    o.borderColor = { r = 0.4, g = 0.6, b = 0.9, a = 0.9 }
    return o
end

function VDS_ScannerDisplay:createChildren()
end

local function drawSeparator(panel, y, width)
    local w = width and (width - 2 * PAD) or (panel:getWidth() - 2 * PAD)
    panel:drawRect(PAD, y, w, 1, 0.45, 0.5, 0.6, 0.85)
end

function VDS_ScannerDisplay:render()
    ISPanel.render(self)
    local VDS = _G.VDS
    if not VDS then return end
    local data = VDS.lastScanData
    local y = PAD
    if data then
        -- Section 1: Vehicle type
        self:drawText("Vehicle: " .. (data.vehicleName or "?"), PAD, y, 0.9, 0.9, 0.9, 1, FONT)
        y = y + LINE_H + SEPARATOR_GAP
        drawSeparator(self, y, self:getWidth())
        y = y + 1 + SEPARATOR_GAP

        -- Section 2: Engine, Gas, Battery
        local eng = tonumber(data.engine) or 0; if eng ~= eng then eng = 0 end
        local gas = tonumber(data.fuel) or 0; if gas ~= gas then gas = 0 end
        local bat = tonumber(data.battery) or 0; if bat ~= bat then bat = 0 end
        local r, g, b = 0.85, 0.85, 0.9
        if VDS.getPercentColor then r, g, b = VDS.getPercentColor(eng) end
        self:drawText(string.format("Engine status: %d%%", math.floor(eng)), PAD, y, r, g, b, 1, FONT)
        y = y + LINE_H
        r, g, b = 0.85, 0.85, 0.9
        if VDS.getPercentColor then r, g, b = VDS.getPercentColor(gas) end
        self:drawText(string.format("Gas amount: %d%%", math.floor(gas)), PAD, y, r, g, b, 1, FONT)
        y = y + LINE_H
        r, g, b = 0.85, 0.85, 0.9
        if VDS.getPercentColor then r, g, b = VDS.getPercentColor(bat) end
        self:drawText(string.format("Battery amount: %d%%", math.floor(bat)), PAD, y, r, g, b, 1, FONT)
        y = y + LINE_H + SEPARATOR_GAP
        drawSeparator(self, y, self:getWidth())
        y = y + 1 + SEPARATOR_GAP

        -- Section 3: 4 tires
        if data.tires and type(data.tires) == "table" then
            for _, id in ipairs(TIRE_IDS) do
                local cond = data.tires[id]
                if cond ~= nil then
                    local pct = (tonumber(cond) and math.floor(cond)) or 0
                    r, g, b = 0.85, 0.85, 0.9
                    if VDS.getPercentColor then r, g, b = VDS.getPercentColor(pct) end
                    local label = TIRE_LABELS[id] or id
                    self:drawText(string.format("%s: %d%%", label, pct), PAD, y, r, g, b, 1, FONT)
                    y = y + LINE_H
                end
            end
        end
        y = y + SEPARATOR_GAP
        drawSeparator(self, y, self:getWidth())
        y = y + 1 + SEPARATOR_GAP

        -- Section 4: Locked / Unlocked
        if data.locked then
            self:drawText("LOCKED", PAD, y, 1, 0.25, 0.25, 1, FONT)
        else
            self:drawText("UNLOCKED", PAD, y, 0.25, 1, 0.25, 1, FONT)
        end
    else
        self:drawText("No vehicle in range (5 tiles)", PAD, y, 0.75, 0.75, 0.75, 1, FONT)
    end
end

-- Popup window (title bar, close button)
VDS_ScannerWindow = ISCollapsableWindow:derive("VDS_ScannerWindow")

function VDS_ScannerWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    self.contentPanel = VDS_ScannerDisplay:new(0, 0, self.width, self.height - th - rh)
    self.contentPanel:initialise()
    self:addChild(self.contentPanel)
    self.contentPanel:setY(th)
    self.contentPanel:setHeight(self.height - th - rh)
end

function VDS_ScannerWindow:update()
    if not self:getIsVisible() then return end
    if not _G.VDS then return end
    local data = _G.VDS.lastScanData
    local contentH
    if data then
        local sepH = 1 + SEPARATOR_GAP * 2  -- one line + gap above and below
        contentH = PAD + LINE_H + sepH + LINE_H * 3 + sepH  -- vehicle, sep, engine+gas+battery, sep
        if data.tires and type(data.tires) == "table" then
            for _, id in ipairs(TIRE_IDS) do
                if data.tires[id] ~= nil then contentH = contentH + LINE_H end
            end
        end
        contentH = contentH + sepH + LINE_H + PAD  -- sep, lock
    else
        contentH = PAD * 2 + LINE_H
    end
    local th = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    self:setHeight(th + contentH + rh)
    self.contentPanel:setHeight(contentH)
end

function VDS_ScannerWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if _G.VDS then _G.VDS.scannerPanelOpen = false end
end

function VDS_ScannerWindow:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:setTitle("Vehicle Diagnostic Scanner")
    o:setResizable(false)
    return o
end

-- Create window once (not added to UIManager until opened)
local function createScannerWindow()
    if VDS_ScannerWindow.instance then return end
    local w = 300
    local h = 200
    local x = getCore():getScreenWidth() / 2 - w / 2
    local y = getCore():getScreenHeight() / 2 - h / 2
    local win = VDS_ScannerWindow:new(x, y, w, h)
    win:initialise()
    win:setVisible(false)
    VDS_ScannerWindow.instance = win
end

Events.OnCreateUI.Add(createScannerWindow)
