MOverhaul = {}
MOverhaul.name = "MOverhaul"
MOverhaul.isConfirmed = false

local defaults = {
    gearLockoutEnabled = true,
    overloadIndicatorEnabled = true,
    questMapLineEnabled = true,
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

local MOverhaul_MapQuestLine = nil
local lastMapUpdate = 0
local MAP_UPDATE_INTERVAL = 0.05 -- Update 20 times per second

local function UpdateMapQuestLine()
    if not MOverhaul.db or not MOverhaul.db.questMapLineEnabled then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        return
    end

    local time = GetFrameTimeSeconds()
    if time - lastMapUpdate < MAP_UPDATE_INTERVAL then return end
    lastMapUpdate = time

    if not ZO_WorldMap or ZO_WorldMap:IsHidden() then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
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

    if not activePins then return end

    local targetPin = nil
    for pinKey, pin in pairs(activePins) do
        if type(pin) == "table" or type(pin) == "userdata" then
            if pin.GetPinType and pin.GetNormalizedPosition then
                local pinType = pin:GetPinType()
                -- Prioritize assisted quest pins
                if pinType == MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION or pinType == MAP_PIN_TYPE_ASSISTED_QUEST_ENDING then
                    targetPin = pin
                    break
                elseif pinType == MAP_PIN_TYPE_QUEST_CONDITION or pinType == MAP_PIN_TYPE_QUEST_ENDING then
                    if not targetPin then
                        targetPin = pin
                    end
                end
            end
        end
    end

    if not targetPin then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        return
    end

    local pinX, pinY = targetPin:GetNormalizedPosition()
    if not pinX or pinX == 0 then
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

    MOverhaul_MapQuestLine:ClearAnchors()
    MOverhaul_MapQuestLine:SetAnchor(TOPLEFT, ZO_WorldMapContainer, TOPLEFT, 0, 0)
    MOverhaul_MapQuestLine:SetStartPoint(startX, startY)
    MOverhaul_MapQuestLine:SetEndPoint(endX, endY)
    MOverhaul_MapQuestLine:SetHidden(false)
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
    if not CT_LINE then
        d("[MOverhaul] CT_LINE is nil!")
        return
    end

    local testLine = WINDOW_MANAGER:CreateControl("MOverhaul_TestLine", GuiRoot, CT_LINE)
    if not testLine then
        d("[MOverhaul] Failed to create CT_LINE control!")
        return
    end

    d("[MOverhaul] CT_LINE control created successfully")

    local mt = getmetatable(testLine)
    if mt and mt.__index then
        local methods = {}
        for k, v in pairs(mt.__index) do
            if type(v) == "function" then
                table.insert(methods, tostring(k))
            end
        end
        d("[MOverhaul] Line Methods: " .. table.concat(methods, ", "))
    else
        d("[MOverhaul] Line metatable.__index is nil!")
    end
end

EVENT_MANAGER:RegisterForEvent(MOverhaul.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
