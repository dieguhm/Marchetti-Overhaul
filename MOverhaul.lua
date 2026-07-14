MOverhaul = {}
MOverhaul.name = "MOverhaul"
MOverhaul.isConfirmed = false

local defaults = {
    gearLockoutEnabled = true,
    overloadIndicatorEnabled = true,
    questMapLineEnabled = true,
    quest3DArrowEnabled = true,
    questWaypointArrowEnabled = true,
    questWaypointArrowLocked = false,
    questWaypointArrowX = nil,
    questWaypointArrowY = nil,
}

local overloadLabel = nil

local function GetUltimateButtonControl()
    -- 1. Try ACTION_BAR.actionButtons
    if ACTION_BAR and ACTION_BAR.actionButtons then
        local btn = ACTION_BAR.actionButtons[ACTION_BAR_ULTIMATE_SLOT_INDEX or 8]
        if btn then
            if btn.control then
                return btn.control
            elseif btn.GetControl then
                return btn:GetControl()
            end
        end
    end

    -- 2. Try ZO_ActionBar_GetButton
    if ZO_ActionBar_GetButton then
        local btn = ZO_ActionBar_GetButton(ACTION_BAR_ULTIMATE_SLOT_INDEX or 8)
        if btn then
            if type(btn) == "userdata" and btn.GetType then
                return btn
            elseif btn.control and type(btn.control) == "userdata" then
                return btn.control
            elseif btn.GetControl then
                local ctrl = btn:GetControl()
                if ctrl then return ctrl end
            elseif btn.buttonControl then
                return btn.buttonControl
            end
        end
    end

    -- 3. Try global ActionButton8
    if ActionButton8 then
        return ActionButton8
    end

    -- 4. Try global ZO_ActionBar1Button8
    if ZO_ActionBar1Button8 then
        return ZO_ActionBar1Button8
    end

    -- 5. Try finding children in ZO_ActionBar1
    if ZO_ActionBar1 then
        local btn = ZO_ActionBar1:GetNamedChild("Button8")
        if btn then return btn end
        btn = ZO_ActionBar1:GetNamedChild("ActionButton8")
        if btn then return btn end
    end

    return nil
end

local isOverloadActive = false

local function IsOverloadActive()
    if not GetCurrentHotbarCategory then return isOverloadActive end
    return isOverloadActive or GetCurrentHotbarCategory() == (HOTBAR_CATEGORY_OVERLOAD or 3)
end

local function IsOverloadEquipped()
    if IsOverloadActive() then
        return true
    end

    local slotIndex = ACTION_BAR_ULTIMATE_SLOT_INDEX or 8
    
    -- 1. Try checking by Ability ID
    local abilityId = 0
    if GetSlotBoundId then
        abilityId = GetSlotBoundId(slotIndex)
    elseif GetSlotAbilityId then
        abilityId = GetSlotAbilityId(slotIndex)
    end
    
    if abilityId == 29623 or abilityId == 29631 or abilityId == 29627 then
        return true
    end
    
    -- 2. Fallback to name check
    if not GetSlotName then return false end
    local name = GetSlotName(slotIndex)
    if not name or name == "" then return false end
    
    name = name:lower()
    return string.find(name, "overload") ~= nil or string.find(name, "sobrecarga") ~= nil
end

function MOverhaul.UpdateOverloadState()
    if not MOverhaul.db or not MOverhaul.db.overloadIndicatorEnabled then
        if overloadLabel then
            overloadLabel:SetHidden(true)
        end
        return
    end

    local buttonControl = GetUltimateButtonControl()
    if not buttonControl then
        return
    end

    if not IsOverloadEquipped() then
        if overloadLabel then
            overloadLabel:SetHidden(true)
        end
        return
    end

    if not overloadLabel then
        local parentControl = ZO_ActionBar1 or GuiRoot
        overloadLabel = WINDOW_MANAGER:CreateControl("MOverhaul_OverloadLabel", parentControl, CT_LABEL)
        overloadLabel:SetFont("$(BOLD_FONT)|22|soft-shadow-thick")
        overloadLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        overloadLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        overloadLabel:SetDimensions(80, 25)
        overloadLabel:SetDrawTier(DT_HIGH)
        overloadLabel:SetDrawLayer(DL_OVERLAY)
    end

    overloadLabel:ClearAnchors()
    overloadLabel:SetAnchor(BOTTOM, buttonControl, TOP, 0, -2)
    overloadLabel:SetHidden(false)

    if IsOverloadActive() then
        overloadLabel:SetText("ON")
        overloadLabel:SetColor(0, 1, 0, 1) -- Green
    else
        overloadLabel:SetText("OFF")
        overloadLabel:SetColor(1, 0, 0, 1) -- Red
    end
end

local MOverhaul_WaypointArrow = nil

local function OnWaypointArrowUpdate(self, elapsed)
    if not MOverhaul.db or not MOverhaul.db.questWaypointArrowEnabled then
        self:SetHidden(true)
        return
    end

    local tx, ty = MOverhaul.targetX, MOverhaul.targetY
    if not tx or not ty then
        self:SetHidden(true)
        return
    end

    local px, py = GetMapPlayerPosition("player")
    if not px or px == 0 then
        self:SetHidden(true)
        return
    end

    self:SetHidden(false)

    -- 1. Calculate distance in meters
    local distanceText = ""
    local LibGPS = LibGPS3 or LibGPS2 or LibGPS
    if LibGPS then
        local distance = LibGPS:GetLocalDistanceInMeters(px, py, tx, ty)
        if distance then
            if distance > 1000 then
                distanceText = string.format("%.1f km", distance / 1000)
            else
                distanceText = string.format("%d m", math.floor(distance))
            end
        end
    else
        local distPct = math.sqrt((tx - px)^2 + (ty - py)^2)
        distanceText = string.format("%.0f%%", distPct * 100)
    end

    -- 2. Calculate angle and rotation
    local dx = tx - px
    local dy = ty - py

    local targetAngle = 0
    if dx ~= 0 or dy ~= 0 then
        targetAngle = math.atan2(dx, -dy)
    end

    local cameraHeading = GetPlayerCameraHeading()
    local relativeAngle = targetAngle - cameraHeading

    -- Update texture rotation
    local arrowTexture = self:GetNamedChild("Texture")
    if arrowTexture then
        arrowTexture:SetTextureRotation(relativeAngle)
    end

    -- Update distance label
    local label = self:GetNamedChild("Label")
    if label then
        label:SetText(distanceText)
    end
end

local function CreateWaypointArrowControl()
    if MOverhaul_WaypointArrow then return end

    -- Create top level window
    MOverhaul_WaypointArrow = WINDOW_MANAGER:CreateTopLevelWindow("MOverhaul_WaypointArrow")
    MOverhaul_WaypointArrow:SetDimensions(80, 80)

    -- Load saved position or use default (center-top)
    local db = MOverhaul.db
    if db.questWaypointArrowX and db.questWaypointArrowY then
        MOverhaul_WaypointArrow:ClearAllPoints()
        MOverhaul_WaypointArrow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, db.questWaypointArrowX, db.questWaypointArrowY)
    else
        MOverhaul_WaypointArrow:ClearAllPoints()
        MOverhaul_WaypointArrow:SetAnchor(CENTER, GuiRoot, CENTER, 0, -200)
    end

    MOverhaul_WaypointArrow:SetMovable(not db.questWaypointArrowLocked)
    MOverhaul_WaypointArrow:SetMouseEnabled(not db.questWaypointArrowLocked)
    MOverhaul_WaypointArrow:SetClampedToScreen(true)

    -- Glow backing
    local glow = WINDOW_MANAGER:CreateControl("MOverhaul_WaypointArrowGlow", MOverhaul_WaypointArrow, CT_TEXTURE)
    glow:SetAnchor(CENTER, MOverhaul_WaypointArrow, CENTER, 0, 0)
    glow:SetDimensions(80, 80)
    glow:SetTexture("MOverhaul/art/glow.dds")
    glow:SetColor(0, 0.7, 1, 0.4)

    -- Arrow texture
    local arrow = WINDOW_MANAGER:CreateControl("MOverhaul_WaypointArrowTexture", MOverhaul_WaypointArrow, CT_TEXTURE)
    arrow:SetAnchor(CENTER, MOverhaul_WaypointArrow, CENTER, 0, 0)
    arrow:SetDimensions(50, 50)
    arrow:SetTexture("MOverhaul/art/arrow.dds")
    arrow:SetColor(0, 0.8, 1, 1)

    -- Distance text label
    local label = WINDOW_MANAGER:CreateControl("MOverhaul_WaypointArrowLabel", MOverhaul_WaypointArrow, CT_LABEL)
    label:SetAnchor(TOP, MOverhaul_WaypointArrow, BOTTOM, 0, 5)
    label:SetFont("$(BOLD_FONT)|16|soft-shadow-thin")
    label:SetColor(1, 1, 1, 1)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetText("")

    -- Drag behavior
    MOverhaul_WaypointArrow:SetHandler("OnMoveStop", function(self)
        local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = self:GetAnchor()
        if isValidAnchor then
            db.questWaypointArrowX = offsetX
            db.questWaypointArrowY = offsetY
        end
    end)

    MOverhaul_WaypointArrow:SetHandler("OnUpdate", OnWaypointArrowUpdate)
    MOverhaul_WaypointArrow:SetHidden(not db.questWaypointArrowEnabled)
end

local MOverhaul_MapQuestLine = nil
local lastMapUpdate = 0
local MAP_UPDATE_INTERVAL = 0.05 -- Update 20 times per second

local quest3DArrow = nil

local function UpdateQuest3DArrow(pinX, pinY)
    if not Lib3DArrow then return end
    if not MOverhaul.db or not MOverhaul.db.quest3DArrowEnabled then
        if quest3DArrow then
            quest3DArrow:SetTarget(0, 0)
        end
        return
    end

    if not quest3DArrow then
        quest3DArrow = Lib3DArrow:CreateArrow({
            arrowMagnitude = 6,
            depthBuffer = true
        })
        if quest3DArrow then
            quest3DArrow:ChangeColours("00FFFF", "00FFFF") -- Cyan color
        end
    end

    if quest3DArrow then
        if pinX and pinY and pinX > 0 and pinY > 0 then
            quest3DArrow:SetTarget(pinX, pinY)
        else
            quest3DArrow:SetTarget(0, 0)
        end
    end
end

local function UpdateMapQuestLine()
    local time = GetFrameTimeSeconds()
    if time - lastMapUpdate < MAP_UPDATE_INTERVAL then return end
    lastMapUpdate = time

    if not ZO_WorldMap or ZO_WorldMap:IsHidden() then
        return
    end

    local playerX, playerY = GetMapPlayerPosition("player")
    if not playerX or playerX == 0 then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        return
    end

    local pinManager = ZO_WorldMap_GetPinManager()
    if not pinManager then return end

    local activePins = nil
    if pinManager.GetActiveObjects then
        activePins = pinManager:GetActiveObjects()
    elseif pinManager.m_Active then
        activePins = pinManager.m_Active
    end

    local targetPin = nil
    if activePins then
        for pinKey, pin in pairs(activePins) do
            if type(pin) == "table" or type(pin) == "userdata" then
                if pin.GetPinType and pin.GetNormalizedPosition then
                    local pinType = pin:GetPinType()
                    -- Prioritize assisted quest pins (Block 1: 10 to 17)
                    if pinType >= 10 and pinType <= 17 then
                        targetPin = pin
                        break
                    -- Fall back to tracked secondary quest pins (Block 2: 19 to 26)
                    elseif pinType >= 19 and pinType <= 26 then
                        if not targetPin or targetPin:GetPinType() > 26 then
                            targetPin = pin
                        end
                    -- Fall back to general journal quest pins (Block 3: 28 to 35)
                    elseif pinType >= 28 and pinType <= 35 then
                        if not targetPin then
                            targetPin = pin
                        end
                    end
                end
            end
        end
    end

    local pinX, pinY = 0, 0
    if targetPin then
        pinX, pinY = targetPin:GetNormalizedPosition()
        MOverhaul.targetX = pinX
        MOverhaul.targetY = pinY
        MOverhaul.targetPinType = targetPin:GetPinType()
    else
        MOverhaul.targetX = nil
        MOverhaul.targetY = nil
        MOverhaul.targetPinType = nil
    end

    -- Update 3D Arrow
    UpdateQuest3DArrow(pinX, pinY)

    -- Draw the 2D Line on the Map
    if not MOverhaul.db or not MOverhaul.db.questMapLineEnabled or pinX == 0 or pinY == 0 then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        return
    end

    if not MOverhaul_MapQuestLine then
        MOverhaul_MapQuestLine = WINDOW_MANAGER:CreateControl("MOverhaul_MapQuestLine", ZO_WorldMapContainer, CT_LINE)
        MOverhaul_MapQuestLine:SetThickness(5)
        MOverhaul_MapQuestLine:SetColor(0.2, 0.8, 1, 0.7) -- Light blue line
        MOverhaul_MapQuestLine:SetDrawLevel(2)
    end

    local w, h = ZO_WorldMapContainer:GetDimensions()
    local startX = playerX * w
    local startY = playerY * h
    local endX = pinX * w
    local endY = pinY * h

    if MOverhaul_MapQuestLine.SetThickness then
        MOverhaul_MapQuestLine:ClearAnchors()
        MOverhaul_MapQuestLine:SetAnchor(TOPLEFT, ZO_WorldMapContainer, TOPLEFT, startX, startY)
        MOverhaul_MapQuestLine:SetAnchor(BOTTOMRIGHT, ZO_WorldMapContainer, TOPLEFT, endX, endY)
        MOverhaul_MapQuestLine:SetHidden(false)
    else
        MOverhaul_MapQuestLine:SetHidden(true)
    end
end

local function GetQuality(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    if not itemLink or itemLink == "" then return 0 end
    
    local quality = GetItemLinkQuality(itemLink)
    local legendaryVal = ITEM_QUALITY_LEGENDARY or 5
    
    if quality == legendaryVal or quality == 5 then
        local hasSet, _, _, _, maxEquipped = GetItemLinkSetInfo(itemLink)
        if hasSet and maxEquipped == 1 then
            return 6
        end
    end
    
    return quality
end

local function OnPrimaryAction(slotControl)
    if not MOverhaul.db.gearLockoutEnabled then
        return false
    end

    if MOverhaul.isConfirmed then
        MOverhaul.isConfirmed = false
        return false
    end

    if not slotControl then return false end
    
    local bagId, slotIndex
    if slotControl.bagId and slotControl.slotIndex then
        bagId = slotControl.bagId
        slotIndex = slotControl.slotIndex
    elseif slotControl.dataEntry and slotControl.dataEntry.data then
        local data = slotControl.dataEntry.data
        if data.bagId and data.slotIndex then
            bagId = data.bagId
            slotIndex = data.slotIndex
        end
    end
    
    if not bagId or not slotIndex then
        if ZO_Inventory_GetBagAndIndex then
            bagId, slotIndex = ZO_Inventory_GetBagAndIndex(slotControl)
        end
    end
    
    if not bagId or not slotIndex then 
        return false 
    end

    local itemLink = GetItemLink(bagId, slotIndex)
    if not itemLink or itemLink == "" then
        return false
    end

    local newQuality = GetQuality(bagId, slotIndex)

    local _, _, _, _, _, equipType = GetItemInfo(bagId, slotIndex)
    
    if not equipType or equipType == EQUIP_TYPE_INVALID then
        return false
    end

    local targetSlots = {}
    local activeWeaponPair = GetActiveWeaponPairInfo()
    
    if equipType == EQUIP_TYPE_HEAD then
        table.insert(targetSlots, EQUIP_SLOT_HEAD)
    elseif equipType == EQUIP_TYPE_NECK then
        table.insert(targetSlots, EQUIP_SLOT_NECK)
    elseif equipType == EQUIP_TYPE_CHEST then
        table.insert(targetSlots, EQUIP_SLOT_CHEST)
    elseif equipType == EQUIP_TYPE_SHOULDERS then
        table.insert(targetSlots, EQUIP_SLOT_SHOULDERS)
    elseif equipType == EQUIP_TYPE_HAND then
        table.insert(targetSlots, EQUIP_SLOT_HAND)
    elseif equipType == EQUIP_TYPE_WAIST then
        table.insert(targetSlots, EQUIP_SLOT_WAIST)
    elseif equipType == EQUIP_TYPE_LEGS then
        table.insert(targetSlots, EQUIP_SLOT_LEGS)
    elseif equipType == EQUIP_TYPE_FEET then
        table.insert(targetSlots, EQUIP_SLOT_FEET)
    elseif equipType == EQUIP_TYPE_RING then
        table.insert(targetSlots, EQUIP_SLOT_RING1)
        table.insert(targetSlots, EQUIP_SLOT_RING2)
    elseif equipType == EQUIP_TYPE_MAIN_HAND or equipType == EQUIP_TYPE_TWO_HAND or equipType == EQUIP_TYPE_ONE_HAND then
        table.insert(targetSlots, EQUIP_SLOT_MAIN_HAND)
        table.insert(targetSlots, EQUIP_SLOT_BACKUP_MAIN)
        if equipType == EQUIP_TYPE_ONE_HAND then
            table.insert(targetSlots, EQUIP_SLOT_OFF_HAND)
            table.insert(targetSlots, EQUIP_SLOT_BACKUP_OFF)
        end
    elseif equipType == EQUIP_TYPE_OFF_HAND then
        table.insert(targetSlots, EQUIP_SLOT_OFF_HAND)
        table.insert(targetSlots, EQUIP_SLOT_BACKUP_OFF)
    elseif equipType == EQUIP_TYPE_POISON then
        table.insert(targetSlots, EQUIP_SLOT_POISON)
        table.insert(targetSlots, EQUIP_SLOT_BACKUP_POISON)
    end

    for _, slot in ipairs(targetSlots) do
        local currentItemLink = GetItemLink(BAG_WORN, slot)
        
        if currentItemLink and currentItemLink ~= "" then
            local currentQuality = GetQuality(BAG_WORN, slot)
            
            if newQuality < currentQuality then
                PlaySound(SOUNDS.ERROR)
                
                ZO_Dialogs_ShowDialog("M_OVERHAUL_CONFIRM", {
                    slotControl = slotControl,
                    bagId = bagId,
                    slotIndex = slotIndex,
                    targetSlots = targetSlots
                })
                
                return true
            end
        end
    end

    return false
end

local function OnAddOnLoaded(event, addonName)
    if addonName == MOverhaul.name then
        EVENT_MANAGER:UnregisterForEvent(MOverhaul.name, EVENT_ADD_ON_LOADED)
        
        MOverhaul.db = ZO_SavedVars:NewAccountWide("MOverhaul_SavedVariables", 1, nil, defaults)
        CreateWaypointArrowControl()
        
        ZO_Dialogs_RegisterCustomDialog("M_OVERHAUL_CONFIRM", {
            title = {
                text = "Confirmar Equipamento",
            },
            mainText = {
                text = "Voce realmente deseja equipar um item de qualidade INFERIOR a do item atualmente equipado?",
            },
            buttons = {
                {
                    text = "Sim",
                    callback = function(dialog)
                        local data = dialog.data
                        if data then
                            local destSlot = nil
                            if data.targetSlots and #data.targetSlots > 0 then
                                destSlot = data.targetSlots[1]
                            end
                            
                            MOverhaul.isConfirmed = true
                            if destSlot then
                                if EquipItem then
                                    EquipItem(data.bagId, data.slotIndex, destSlot)
                                elseif RequestEquipItem then
                                    RequestEquipItem(data.bagId, data.slotIndex, destSlot)
                                end
                            else
                                if EquipItem then
                                    EquipItem(data.bagId, data.slotIndex)
                                elseif RequestEquipItem then
                                    RequestEquipItem(data.bagId, data.slotIndex)
                                end
                            end
                        end
                    end,
                },
                {
                    text = "Nao",
                    callback = function(dialog)
                    end,
                },
            },
        })

        ZO_PreHook("ZO_InventorySlot_DoPrimaryAction", OnPrimaryAction)
        
        ZO_PreHook(ZO_InventorySlotActions, "DoPrimaryAction", function(self)
            local slotControl = self.m_slotControl or self.slotControl or self.m_inventorySlot or moc()
            return OnPrimaryAction(slotControl)
        end)
        
        local LAM = LibAddonMenu2
        if LAM then
            local panelData = {
                type = "panel",
                name = "M Overhaul",
                displayName = "M Overhaul",
                author = "Marchetti",
                version = "1.0.0",
                registerForRefresh = true,
                registerForDefaults = true,
            }
            
            local optionsTable = {
                {
                    type = "checkbox",
                    name = "Gear Lockout (Modulo)",
                    tooltip = "Habilita ou desabilita o modulo Gear Lockout (confirmacao de downgrade de itens).",
                    getFunc = function() return MOverhaul.db.gearLockoutEnabled end,
                    setFunc = function(value) MOverhaul.db.gearLockoutEnabled = value end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Overload Indicator (Modulo)",
                    tooltip = "Habilita ou desabilita o texto indicador ON/OFF sobre a Ultimate Overload.",
                    getFunc = function() return MOverhaul.db.overloadIndicatorEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.overloadIndicatorEnabled = value 
                        MOverhaul.UpdateOverloadState()
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Quest Map Line (Modulo)",
                    tooltip = "Habilita ou desabilita a linha reta ligando o jogador ao objetivo da quest ativa no mapa.",
                    getFunc = function() return MOverhaul.db.questMapLineEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.questMapLineEnabled = value 
                        if not value and MOverhaul_MapQuestLine then
                            MOverhaul_MapQuestLine:SetHidden(true)
                        end
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Quest 3D Arrow (Modulo)",
                    tooltip = "Habilita ou desabilita a seta 3D na tela apontando para a quest ativa (Requer Lib3D e Lib3DArrow).",
                    getFunc = function() return MOverhaul.db.quest3DArrowEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.quest3DArrowEnabled = value 
                        if not value and quest3DArrow then
                            quest3DArrow:SetTarget(0, 0)
                        end
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Quest Waypoint Arrow (Modulo)",
                    tooltip = "Habilita ou desabilita a seta de navegacao 2D no HUD (estilo Zygor).",
                    getFunc = function() return MOverhaul.db.questWaypointArrowEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.questWaypointArrowEnabled = value 
                        if MOverhaul_WaypointArrow then
                            MOverhaul_WaypointArrow:SetHidden(not value)
                        end
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Bloquear Seta de Waypoint",
                    tooltip = "Bloqueia a movimentacao da seta de navegacao 2D no HUD para evitar arrastes acidentais.",
                    getFunc = function() return MOverhaul.db.questWaypointArrowLocked end,
                    setFunc = function(value) 
                        MOverhaul.db.questWaypointArrowLocked = value 
                        if MOverhaul_WaypointArrow then
                            MOverhaul_WaypointArrow:SetMovable(not value)
                            MOverhaul_WaypointArrow:SetMouseEnabled(not value)
                        end
                    end,
                    default = false,
                },
            }
            
            LAM:RegisterAddonPanel("MOverhaul_SettingsPanel", panelData)
            LAM:RegisterOptionControls("MOverhaul_SettingsPanel", optionsTable)
        end

        -- Register custom events for Overload Indicator
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadCategory", EVENT_HOTBAR_ACTIVE_HOTBAR_CATEGORY_CHANGED, MOverhaul.UpdateOverloadState)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadSet", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_SET, MOverhaul.UpdateOverloadState)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadWeapon", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, MOverhaul.UpdateOverloadState)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadSlot", EVENT_ACTION_SLOT_UPDATED, function(eventCode, slotIndex)
            if slotIndex == (ACTION_BAR_ULTIMATE_SLOT_INDEX or 8) then
                MOverhaul.UpdateOverloadState()
            end
        end)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadPlayer", EVENT_PLAYER_ACTIVATED, MOverhaul.UpdateOverloadState)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_OverloadEffect", EVENT_EFFECT_CHANGED, function(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, abilityId)
            if unitTag == "player" then
                local lowerName = effectName and effectName:lower() or ""
                if abilityId == 29623 or abilityId == 29631 or abilityId == 29627 or string.find(lowerName, "overload") or string.find(lowerName, "sobrecarga") then
                    if changeType == EFFECT_RESULT_GAINED then
                        isOverloadActive = true
                    elseif changeType == EFFECT_RESULT_FADED then
                        isOverloadActive = false
                    end
                    MOverhaul.UpdateOverloadState()
                end
            end
        end)

        if ZO_WorldMap then
            local mapUpdateControl = WINDOW_MANAGER:CreateControl("MOverhaul_MapQuestUpdate", ZO_WorldMap, CT_CONTROL)
            mapUpdateControl:SetHandler("OnUpdate", function(self)
                UpdateMapQuestLine()
            end)
        end

    end
end

SLASH_COMMANDS["/mo_debugmap"] = function()
    local playerX, playerY = GetMapPlayerPosition("player")
    d("[MOverhaul] Player Pos: " .. tostring(playerX) .. ", " .. tostring(playerY))

    local pinManager = ZO_WorldMap_GetPinManager()
    if not pinManager then
        d("[MOverhaul] Pin Manager is nil!")
        return
    end

    local activePins = nil
    if pinManager.GetActiveObjects then
        activePins = pinManager:GetActiveObjects()
    elseif pinManager.m_Active then
        activePins = pinManager.m_Active
    end

    if not activePins then
        d("[MOverhaul] Active Pins table is nil!")
        return
    end

    local count = 0
    for k, v in pairs(activePins) do
        count = count + 1
    end
    d("[MOverhaul] Active Pins Count: " .. count)

    local targetPin = nil
    if activePins then
        for pinKey, pin in pairs(activePins) do
            if type(pin) == "table" or type(pin) == "userdata" then
                if pin.GetPinType and pin.GetNormalizedPosition then
                    local pinType = pin:GetPinType()
                    if pinType >= 10 and pinType <= 17 then
                        targetPin = pin
                        d("[MOverhaul] Found assisted quest pin (Block 1): type=" .. tostring(pinType))
                        break
                    elseif pinType >= 19 and pinType <= 26 then
                        if not targetPin or targetPin:GetPinType() > 26 then
                            targetPin = pin
                            d("[MOverhaul] Found tracked secondary quest pin (Block 2): type=" .. tostring(pinType))
                        end
                    elseif pinType >= 28 and pinType <= 35 then
                        if not targetPin then
                            targetPin = pin
                            d("[MOverhaul] Found general quest pin (Block 3): type=" .. tostring(pinType))
                        end
                    end
                end
            end
        end
    end

    if not targetPin then
        d("[MOverhaul] No Quest Pin found!")
        return
    end

    local pinX, pinY = targetPin:GetNormalizedPosition()
    d("[MOverhaul] Target Pin Pos: " .. tostring(pinX) .. ", " .. tostring(pinY))

    local w, h = ZO_WorldMapContainer:GetDimensions()
    d("[MOverhaul] Container Size: " .. tostring(w) .. "x" .. tostring(h))

    local startX = playerX * w
    local startY = playerY * h
    local endX = pinX * w
    local endY = pinY * h
    d("[MOverhaul] Line Points: Start(" .. tostring(startX) .. ", " .. tostring(startY) .. ") -> End(" .. tostring(endX) .. ", " .. tostring(endY) .. ")")
    d("[MOverhaul] Lib3D loaded: " .. tostring(Lib3D ~= nil))
    d("[MOverhaul] Lib3DArrow loaded: " .. tostring(Lib3DArrow ~= nil))
end

EVENT_MANAGER:RegisterForEvent(MOverhaul.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
