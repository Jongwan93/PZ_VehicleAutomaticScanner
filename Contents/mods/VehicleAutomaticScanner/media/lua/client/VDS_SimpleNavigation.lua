-- Simple Navigation: when Vehicle Diagnostic Scanner is equipped and the player has
-- a map_house (house) marker on the map, show distance to the nearest such marker on the minimap.

local VDS = _G.VDS
if not VDS then return end

-- Symbol IDs we treat as "house" markers (map_house.png and common variants)
local function isHouseSymbol(symbol)
    if not symbol or not symbol.isTexture or not symbol:isTexture() then return false end
    local id = symbol.getSymbolID and symbol:getSymbolID()
    if not id or type(id) ~= "string" then return false end
    return id == "map_house" or string.find(id:lower(), "house") ~= nil
end

-- 2D distance in world tiles (same scale as player getX/getY and symbol getWorldX/getWorldY)
local function worldDistance(px, py, wx, wy)
    return math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2)
end

-- Find nearest house marker and return worldX, worldY and distance in tiles; or nil
local function getNearestHouseMarker(mapAPI, player)
    if not mapAPI or not player then return nil end
    local symbolsAPI = mapAPI.getSymbolsAPI and mapAPI:getSymbolsAPI()
    if not symbolsAPI or not symbolsAPI.getSymbolCount then return nil end
    local n = symbolsAPI:getSymbolCount()
    if n == 0 then return nil end
    local px, py = player:getX(), player:getY()
    local bestWx, bestWy, bestDist = nil, nil, 1/0
    for i = 0, n - 1 do
        local sym = symbolsAPI.getSymbolByIndex and symbolsAPI:getSymbolByIndex(i)
        if sym and isHouseSymbol(sym) then
            local wx = sym.getWorldX and sym:getWorldX() or 0
            local wy = sym.getWorldY and sym:getWorldY() or 0
            local d = worldDistance(px, py, wx, wy)
            if d < bestDist then
                bestDist = d
                bestWx, bestWy = wx, wy
            end
        end
    end
    if bestWx then
        return { worldX = bestWx, worldY = bestWy, distance = bestDist }
    end
    return nil
end

-- Prefer the world map's mapAPI for symbol data when it exists (it has the just-edited symbols).
-- The minimap's API caches symbols and doesn't update after add/remove on the full map.
local function getMapAPIForSymbols(minimapInnerMapAPI)
    if ISWorldMap_instance and ISWorldMap_instance.mapAPI then
        return ISWorldMap_instance.mapAPI
    end
    return minimapInnerMapAPI
end

-- Draw distance text and direction arrow on the minimap
local PAD = 4
local FONT = UIFont.Small
-- Tweak so cursor finger points exactly at house (cursor_white finger is ~down-right in texture)
local ARROW_ANGLE_OFFSET_DEG = -55
local arrowTex = nil   -- cached

local function drawNavigationOnMinimap(self)
    if not VDS or not VDS.isScannerEquipped then return end
    local player = getSpecificPlayer and getSpecificPlayer(self.playerNum)
    if not player then return end
    if not VDS.isScannerEquipped(player) then return end
    if player.getPerkLevel and player:getPerkLevel(Perks.Mechanics) < 8 then return end
    local inner = self.inner
    if not inner or not inner.mapAPI then return end
    local mapAPI = getMapAPIForSymbols(inner.mapAPI)
    local nearest = getNearestHouseMarker(mapAPI, player)
    if not nearest then return end

    -- Minimap center (player position on map) in outer-panel coords
    local centerX = inner:getX() + inner:getWidth() / 2
    local centerY = inner:getY() + inner:getHeight() / 2
    -- House position in minimap UI coords, then in outer coords
    local houseUIX = inner.mapAPI:worldToUIX(nearest.worldX, nearest.worldY)
    local houseUIY = inner.mapAPI:worldToUIY(nearest.worldX, nearest.worldY)
    local houseOuterX = inner:getX() + houseUIX
    local houseOuterY = inner:getY() + houseUIY
    -- Angle from center toward house (radians then degrees; 0 = right, 90 = down in screen space)
    local angleRad = math.atan2(houseOuterY - centerY, houseOuterX - centerX)
    -- +180 so cursor_white (and similar “pointing” textures) face toward the house, not away
    local angleDeg = math.deg(angleRad) + 180 + ARROW_ANGLE_OFFSET_DEG

    -- Draw direction arrow at center of minimap (player position), rotated toward house
    if self.DrawTextureAngle then
        if not arrowTex then
            arrowTex = getTexture("VDSArrowNav.png")
            if not arrowTex then
                arrowTex = getTexture("media/ui/cursor_white.png")
            end
        end
        if arrowTex then
            self:DrawTextureAngle(arrowTex, centerX, centerY, angleDeg)
        end
    end

    -- Distance text at bottom-left
    local distM = math.floor(nearest.distance)
    local text = string.format("House: %dm", distM)
    local fontHgt = getTextManager and getTextManager():getFontHeight(FONT) or 14
    local y = self:getHeight() - fontHgt - PAD
    if self.bottomPanel and self.bottomPanel:getIsVisible() then
        y = y - (self.bottomPanel:getHeight() or 0)
    end
    if y < PAD then y = PAD end
    self:drawText(text, PAD, y, 0, 0, 0, 1, FONT)
end

-- Hook ISMiniMapOuter:render to draw our distance when scanner is equipped
local hooked = false
local function installMinimapHook()
    if hooked then return end
    if not ISMiniMapOuter or not ISMiniMapOuter.render then return end
    local oldRender = ISMiniMapOuter.render
    function ISMiniMapOuter:render()
        oldRender(self)
        drawNavigationOnMinimap(self)
    end
    hooked = true
end

-- Install hook once the minimap exists (game creates it when player is created)
local installTicks = 0
local MAX_TICKS = 120
local function tryInstallHook()
    installTicks = installTicks + 1
    if installTicks > MAX_TICKS then
        Events.OnTick.Remove(tryInstallHook)
        return
    end
    if getPlayerMiniMap and getPlayerMiniMap(0) then
        installMinimapHook()
        Events.OnTick.Remove(tryInstallHook)
    end
end
Events.OnTick.Add(tryInstallHook)

-- Also try when a player is created (minimap is created then)
Events.OnCreatePlayer.Add(function(playerNum, player)
    if getPlayerMiniMap and getPlayerMiniMap(playerNum or 0) then
        installMinimapHook()
    end
end)

