-- Force the Vehicle Scanner hotbar icon to draw at 40x40 when attached to the belt.
-- Hook runs after game UI is loaded (ISHotbar exists).

local VDS_HOTBAR_ICON_SIZE = 40

local function installHotbarHook()
    if not ISHotbar or not ISHotbar.render then return end
    if ISHotbar.VDS_renderHooked then return end

    function ISHotbar:render()
        if (self.playerNum > 0) or (JoypadState.players and JoypadState.players[self.playerNum+1]) then
            self:setVisible(false)
        end
        -- Keep attached items in sync so belt icons show in Equipment panel and in-world hotbar
        self:reloadIcons()
        self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

        local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
        local mouseOverSlotIndex = self:getSlotIndexAt(self:getMouseX(), self:getMouseY())

        local draggedItem = nil
        if ISMouseDrag.dragging and (mouseOverSlotIndex ~= -1) then
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
            local slot = self.availableSlot[mouseOverSlotIndex]
            for _, item in ipairs(dragging) do
                if self:canBeAttached(slot, item) then
                    draggedItem = item
                    break
                end
            end
        end

        local slotX = self.margins

        for i, slot in pairs(self.availableSlot) do
            self:drawRectBorderStatic(slotX, self.margins, self.slotWidth, self.slotHeight, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
            self:drawText(tostring(i), slotX + 3, self.margins + 1, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font)
            local item = self.attachedItems[i]
            if i == mouseOverSlotIndex then
                local r, g, b = 1, 1, 1
                if draggedItem then
                    item = draggedItem
                elseif ISMouseDrag.dragging then
                    r, g, b = 1, 0, 0
                end
                self:drawRect(slotX, self.margins, self.slotWidth, self.slotHeight, 0.2, r, g, b, 1)
                local slotName = getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name
                local textWid = getTextManager():MeasureStringX(UIFont.Small, slotName)
                self:drawText(slotName, slotX + (self.slotWidth - textWid) / 2, 0 - FONT_HGT_SMALL, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font)
            elseif item == draggedItem then
                item = nil
            end
            if item then
                local tex = item:getTexture()
                -- Fallback for VehicleScanner if game hasn't loaded the mod icon yet (e.g. in Equipment panel)
                if item:getType() == "VehicleScanner" and (not tex or not tex.getWidth or tex:getWidth() == 0) then
                    tex = getTexture("Item_VehicleScanner")
                end
                if tex and tex.getWidth and tex:getWidth() > 0 then
                    if item:getType() == "VehicleScanner" then
                        local x = slotX + (self.slotWidth - VDS_HOTBAR_ICON_SIZE) / 2
                        local y = (self.height - VDS_HOTBAR_ICON_SIZE) / 2
                        self:drawTextureScaled(tex, x, y, VDS_HOTBAR_ICON_SIZE, VDS_HOTBAR_ICON_SIZE, 1, 1, 1, 1)
                    else
                        self:drawTexture(tex, slotX + (tex:getWidth() / 2), (self.height - tex:getHeight()) / 2, 1, 1, 1, 1)
                    end
                end

                if item:isEquipped() then
                    tex = self.equippedItemIcon
                    self:drawTexture(tex, slotX + self.slotWidth - tex:getWidth() - 5, self.height - self.margins - tex:getHeight() - 5, 1, 1, 1, 1)
                end
            elseif slot.texture then
                self:drawTexture(slot.texture, slotX + slot.texture:getWidth() / 2, (self.height - slot.texture:getHeight()) / 2, 0.25, 1.0, 1.0, 1.0)
            end
            slotX = slotX + self.slotWidth + self.slotPad
        end
    end

    ISHotbar.VDS_renderHooked = true
end

-- Install when this script loads (game core is loaded first) or on game start for safety
installHotbarHook()
Events.OnGameStart.Add(installHotbarHook)