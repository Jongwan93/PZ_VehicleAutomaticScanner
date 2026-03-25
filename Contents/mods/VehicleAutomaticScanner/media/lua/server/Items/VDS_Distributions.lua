require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"

-- Spawn tuning: the third argument is LOOT WEIGHT (not a percent).
-- addToProcedural only works if the name exists in ProceduralDistributions.list.
-- Common mistake: names from guides (e.g. "ElectronicsStoreShelf") do not exist in vanilla.
--   car supply shelves  -> CarSupplyTools (not CarSupplyShelf)
--   electronics shelves -> ElectronicStoreMisc, ElectronicStoreComputers, etc. (Electronic* not ElectronicsStore*)
--   gas station backroom-> GasStorageMechanics, GasStorageCombo; store auto shelf lane -> StoreShelfMechanics
--   glove box           -> VehicleDistributions.GloveBox.items (NOT ProceduralDistributions)

local ITEM = "Base.VehicleScanner"

local function addToProcedural(containerName, itemFullType, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local container = ProceduralDistributions.list[containerName]
    if not container or not container.items then return end
    table.insert(container.items, itemFullType)
    table.insert(container.items, weight)
end

local function addToVehicleItems(items, itemFullType, weight)
    if not items then return end
    for i = 1, #items, 2 do
        if items[i] == itemFullType then return end
    end
    table.insert(items, itemFullType)
    table.insert(items, weight)
end

local function initVehicleScannerDistributions()
    local w = 5.0

    -- Core mechanic / garage loot
    addToProcedural("MechanicShelfTools", ITEM, w)
    addToProcedural("CrateMechanics", ITEM, w)
    addToProcedural("GarageTools", ITEM, w * 0.75)
    addToProcedural("GarageMechanics", ITEM, w)
    addToProcedural("MechanicSpecial", ITEM, w * 0.8)
    addToProcedural("ToolStoreAccessories", ITEM, w * 0.8)
    addToProcedural("CrateElectronics", ITEM, w * 0.5)
    addToProcedural("ToolStoreTools", ITEM, w * 0.4)

    -- Car supply store (see Distributions.lua carsupply)
    addToProcedural("CarSupplyTools", ITEM, 20.0)

    -- Electronics store / storage (see electronicsstore, electronicsstorage)
    addToProcedural("ElectronicStoreMisc", ITEM, 15.0)
    addToProcedural("ElectronicStoreComputers", ITEM, 10.0)

    -- Gas: back storage uses GasStorage*; shop shelf auto section uses StoreShelfMechanics
    addToProcedural("GasStorageMechanics", ITEM, 10.0)
    addToProcedural("GasStorageCombo", ITEM, 5.0)
    addToProcedural("StoreShelfMechanics", ITEM, 5.0)

    -- Glove box (all cars using VehicleDistributions.GloveBox)
    if VehicleDistributions and VehicleDistributions.GloveBox then
        addToVehicleItems(VehicleDistributions.GloveBox.items, ITEM, 10.0)
        if VehicleDistributions.GloveBox.junk and VehicleDistributions.GloveBox.junk.items then
            addToVehicleItems(VehicleDistributions.GloveBox.junk.items, ITEM, 3.0)
        end
    end
end

Events.OnPostDistributionMerge.Add(initVehicleScannerDistributions)
