-- Global so other mod scripts can access it (set first for load order)
_G.VDS = _G.VDS or {}
local VDS = _G.VDS
local tickCounter = 0
-- Last scan result: shown on device UI (Engine %, Gas %, Battery %)
VDS.lastScanData = nil  -- { engine, fuel, battery, vehicleName } or nil when no vehicle
-- When true, the scanner info panel (top-left) is shown; toggled by the sidebar button
VDS.scannerPanelOpen = false

-- Return r, g, b (0-1) for percentage display: 1-39% red, 40-69% yellow, 70-100% green.
function VDS.getPercentColor(percent)
    local p = (tonumber(percent) and math.floor(percent)) or 0
    if p <= 39 then return 1, 0.25, 0.25 end      -- red
    if p <= 69 then return 1, 1, 0.25 end         -- yellow
    return 0.25, 1, 0.25                          -- green
end

-- Check if scanner is equipped (in hands or on hotbar/belt per ISHotbar)
function VDS.isScannerEquipped(player)
    -- Check primary or secondary hand
    local primary = player:getPrimaryHandItem()
    if primary and primary:getType() == "VehicleScanner" then return true end

    local secondary = player:getSecondaryHandItem()
    if secondary and secondary:getType() == "VehicleScanner" then return true end

    -- Check hotbar/belt: getPlayerHotbar and attachedItems (see ISHotbar.lua)
    if getPlayerHotbar then
        local hotbar = getPlayerHotbar(player:getPlayerNum())
        if hotbar and hotbar.attachedItems then
            for _, item in pairs(hotbar.attachedItems) do
                if item and item:getType() == "VehicleScanner" then
                    return true
                end
            end
        end
    end

    return false
end

-- Distance in tiles (2D) between player and vehicle (vanilla has no getDistTo on IsoPlayer)
local function distToVehicle(player, vehicle)
    if not player or not vehicle then return 999 end
    local px, py = player:getX(), player:getY()
    local vx, vy = vehicle:getX(), vehicle:getY()
    return math.sqrt((vx - px) ^ 2 + (vy - py) ^ 2)
end

-- Find vehicle within 5 tiles. Uses same order as ISVehicleMenu.getVehicleToInteractWith:
-- getVehicle() -> getUseableVehicle() -> getNearVehicle(); then getCell():getVehicles() fallback.
function VDS.scanNearbyVehicle(player)
    if not player then return nil end
    local vehicle = nil
    -- 1) In vehicle (vanilla: playerObj:getVehicle())
    if player.getVehicle then
        vehicle = player:getVehicle()
    end
    -- 2) Useable vehicle nearby (vanilla: playerObj:getUseableVehicle())
    if not vehicle and player.getUseableVehicle then
        vehicle = player:getUseableVehicle()
    end
    -- 3) Near vehicle (vanilla: playerObj:getNearVehicle())
    if not vehicle and player.getNearVehicle then
        vehicle = player:getNearVehicle()
    end
    if vehicle and distToVehicle(player, vehicle) <= 5 then
        return vehicle
    end
    -- 4) Fallback: scan cell vehicles (vanilla: getCell():getVehicles() in ISVehicleBloodUI.lua)
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end
    local vehicles = cell:getVehicles()
    if not vehicles then return nil end
    local best, bestDist = nil, 6
    for i = 1, vehicles:size() do
        local v = vehicles:get(i - 1)
        if v then
            local d = distToVehicle(player, v)
            if d <= 5 and d < bestDist then
                best, bestDist = v, d
            end
        end
    end
    return best
end

-- Get vehicle part data
function VDS.getVehicleData(vehicle)
    local data = {}

    -- Engine condition
    local engine = vehicle:getPartById("Engine")
    data.engineCondition = engine and engine:getCondition() or 0

    -- Battery: show "amount of battery available to run the vehicle" = first % in mechanics UI (94%) = remaining charge (getUsedDelta*100), not the (77%) condition in parentheses.
    local battery = vehicle:getPartById("Battery")
    if battery and battery:getInventoryItem() and battery:getInventoryItem().getUsedDelta then
        data.batteryCondition = battery:getInventoryItem():getUsedDelta() * 100
    else
        data.batteryCondition = battery and battery:getCondition() or 0
    end

    -- Fuel level (%); avoid division by zero if capacity is 0
    local gasTank = vehicle:getPartById("GasTank")
    if gasTank then
        local current = gasTank:getContainerContentAmount()
        local capacity = gasTank:getContainerCapacity()
        if capacity and capacity > 0 then
            data.fuelLevel = (current / capacity) * 100
        else
            data.fuelLevel = 0
        end
    else
        data.fuelLevel = 0
    end

    -- Tire status: all 4 tires separately (API uses getPartById per tire, no helper; IDs from ISCarMechanicsOverlay / ISVehicleMenu)
    data.tires = {}
    local tireIds = { "TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight" }
    for _, id in ipairs(tireIds) do
        local part = vehicle.getPartById and vehicle:getPartById(id)
        if part and part.getCondition then
            data.tires[id] = part:getCondition()
        end
    end

    -- Locked: any door or trunk locked
    data.isLocked = (vehicle.isAnyDoorLocked and vehicle:isAnyDoorLocked()) or (vehicle.isTrunkLocked and vehicle:isTrunkLocked())

    return data
end

-- Main tick handler (runs every ~1 second)
function VDS.OnTick()
    -- Update scanner window when open (height/content)
    if VDS.scannerPanelOpen and VDS_ScannerWindow and VDS_ScannerWindow.instance then
        VDS_ScannerWindow.instance:update()
    end

    -- Run every ~60 ticks (1 sec) to avoid heavy per-frame work
    tickCounter = tickCounter + 1
    if tickCounter < 60 then return end
    tickCounter = 0

    local player = getSpecificPlayer(0)
    if not player then return end

    -- 1) Scanner equipped check
    if not VDS.isScannerEquipped(player) then
        VDS.lastScanData = nil
        if VDS.scannerPanelOpen and VDS_ScannerWindow and VDS_ScannerWindow.instance then
            VDS.scannerPanelOpen = false
            VDS_ScannerWindow.instance:close()
        end
        return
    end

    -- 2) Mechanics level 4 required
    local level = player:getPerkLevel(Perks.Mechanics)
    if level < 4 then return end

    -- 3) Find nearby vehicle and update scan data
    local vehicle = VDS.scanNearbyVehicle(player)
    if vehicle then
        local data = VDS.getVehicleData(vehicle)
        local name = "Vehicle"
        if vehicle.getScriptName then
            local ok, n = pcall(function() return vehicle:getScriptName() end)
            if ok and n and type(n) == "string" then name = n end
        end
        VDS.lastScanData = {
            engine = type(data.engineCondition) == "number" and data.engineCondition or 0,
            fuel = type(data.fuelLevel) == "number" and data.fuelLevel or 0,
            battery = type(data.batteryCondition) == "number" and data.batteryCondition or 0,
            tires = data.tires,
            locked = data.isLocked,
            vehicleName = name
        }
    else
        VDS.lastScanData = nil
    end
end

-- Register tick event
Events.OnTick.Add(VDS.OnTick)

-- Right-click VehicleScanner in inventory: add "Scanner: On" / "Scanner: Off" to toggle simple navigation
local function onFillInventoryContextMenu(player, context, items)
    if not items or #items == 0 then return end
    local slot = items[1]
    if not slot then return end
    local item = slot.getItem and slot:getItem() or slot
    if not item or not item.getType then return end
    if item:getType() ~= "VehicleScanner" then return end
    local label = VDS.scannerOn and "Scanner: On" or "Scanner: Off"
    context:addOption(label, player, function()
        VDS.scannerOn = not VDS.scannerOn
    end)
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)