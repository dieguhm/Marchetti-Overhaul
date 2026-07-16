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
    questArrowLocked = false,
    questArrowX = nil,
    questArrowY = nil,
    questCoordsCache = {},
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

    local label = self:GetNamedChild("Label")
    local arrowTexture = self:GetNamedChild("Texture")

    local tx, ty = GetMapPlayerWaypoint()
    local px, py = GetMapPlayerPosition("player")

    if not tx or tx == 0 or not ty or ty == 0 or not px or px == 0 then
        if label then
            label:SetText("")
        end
        if arrowTexture then
            arrowTexture:SetHidden(true)
        end
        return
    end

    if arrowTexture then
        arrowTexture:SetHidden(false)
    end

    -- 1. Calculate distance, angle, and rotation using global coordinates
    local distanceText = ""
    local targetAngle = 0
    local converted = false
    local LibGPS = LibGPS3 or LibGPS2 or LibGPS
    if LibGPS then
        LibGPS:PushCurrentMap()
        local gpx, gpy = LibGPS:LocalToGlobal(px, py)
        local gtx, gty = LibGPS:LocalToGlobal(tx, ty)
        if gpx and gpy and gtx and gty then
            -- Use global distance in meters to avoid issues when the map is hidden
            local distance = LibGPS:GetGlobalDistanceInMeters(gpx, gpy, gtx, gty)
            if distance and distance ~= math.huge and distance == distance then
                -- Scale down LibGPS distance to align with the game's native world scale
                distance = distance / 2.0
                if distance > 1000 then
                    distanceText = string.format("%.1f km", distance / 1000)
                else
                    distanceText = string.format("%d m", math.floor(distance))
                end
            else
                -- Fallback to local map scale estimation if global distance fails
                local distPct = math.sqrt((tx - px)^2 + (ty - py)^2)
                distanceText = string.format("%.0f%%", distPct * 100)
            end
            targetAngle = math.atan2(gtx - gpx, gpy - gty)
        end
        LibGPS:PopCurrentMap()
    end

    if distanceText == "" then
        local distPct = math.sqrt((tx - px)^2 + (ty - py)^2)
        distanceText = string.format("%.0f%%", distPct * 100)
    end

    if label then
        label:SetText(distanceText)
        label:SetColor(1, 1, 1, 1)
    end

    -- 2. Calculate local map angle (100% accurate)
    local targetAngle = math.atan2(tx - px, py - ty)

    local cameraHeading = GetPlayerCameraHeading()
    local cameraHeadingCw = (math.pi / 2) - cameraHeading
    -- Default to 0 since transform_arrow.dds points North by default.
    local offset = MOverhaul.db and MOverhaul.db.arrowOffset or 0
    local relativeAngle = cameraHeadingCw - targetAngle - offset

    -- Update texture rotation
    if arrowTexture then
        arrowTexture:SetTextureRotation(relativeAngle)
        arrowTexture:SetColor(0, 0.8, 1, 1) -- Bright cyan
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
        MOverhaul_WaypointArrow:ClearAnchors()
        MOverhaul_WaypointArrow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, db.questWaypointArrowX, db.questWaypointArrowY)
    else
        MOverhaul_WaypointArrow:ClearAnchors()
        MOverhaul_WaypointArrow:SetAnchor(CENTER, GuiRoot, CENTER, 0, -200)
    end

    MOverhaul_WaypointArrow:SetMovable(not db.questWaypointArrowLocked)
    MOverhaul_WaypointArrow:SetMouseEnabled(not db.questWaypointArrowLocked)
    MOverhaul_WaypointArrow:SetClampedToScreen(true)

    -- Arrow texture (transform_arrow.dds)
    local arrow = WINDOW_MANAGER:CreateControl("MOverhaul_WaypointArrowTexture", MOverhaul_WaypointArrow, CT_TEXTURE)
    arrow:SetAnchor(CENTER, MOverhaul_WaypointArrow, CENTER, 0, 0)
    arrow:SetDimensions(50, 50)
    arrow:SetTexture("esoui/art/miscellaneous/transform_arrow.dds")
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

    -- Try to force refresh quest pins on initial load
    local pinManager = ZO_WorldMap_GetPinManager()
    if pinManager and pinManager.RefreshQuestPins then
        pcall(function() pinManager:RefreshQuestPins() end)
    end
end

local MOverhaul_QuestArrow = nil

local function CreateQuestArrowControl()
    if MOverhaul_QuestArrow then return end

    local db = MOverhaul.db

    -- Create top level window
    MOverhaul_QuestArrow = WINDOW_MANAGER:CreateTopLevelWindow("MOverhaul_QuestArrow")
    MOverhaul_QuestArrow:SetDimensions(80, 80)

    -- Load saved position or use default (center-top shifted to the right)
    if db.questArrowX and db.questArrowY then
        MOverhaul_QuestArrow:ClearAnchors()
        MOverhaul_QuestArrow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, db.questArrowX, db.questArrowY)
    else
        MOverhaul_QuestArrow:ClearAnchors()
        MOverhaul_QuestArrow:SetAnchor(CENTER, GuiRoot, CENTER, 100, -200)
    end

    MOverhaul_QuestArrow:SetMovable(not db.questArrowLocked)
    MOverhaul_QuestArrow:SetMouseEnabled(not db.questArrowLocked)
    MOverhaul_QuestArrow:SetClampedToScreen(true)

    -- Arrow texture (transform_arrow.dds)
    local arrow = WINDOW_MANAGER:CreateControl("MOverhaul_QuestArrowTexture", MOverhaul_QuestArrow, CT_TEXTURE)
    arrow:SetAnchor(CENTER, MOverhaul_QuestArrow, CENTER, 0, 0)
    arrow:SetDimensions(50, 50)
    arrow:SetTexture("esoui/art/miscellaneous/transform_arrow.dds")
    arrow:SetColor(1, 1, 0, 1) -- Yellow

    -- Distance text label
    local label = WINDOW_MANAGER:CreateControl("MOverhaul_QuestArrowLabel", MOverhaul_QuestArrow, CT_LABEL)
    label:SetAnchor(TOP, MOverhaul_QuestArrow, BOTTOM, 0, 5)
    label:SetFont("$(BOLD_FONT)|16|soft-shadow-thin")
    label:SetColor(1, 1, 1, 1)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetText("")

    -- Drag behavior
    MOverhaul_QuestArrow:SetHandler("OnMoveStop", function(self)
        local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = self:GetAnchor()
        if isValidAnchor then
            db.questArrowX = offsetX
            db.questArrowY = offsetY
        end
    end)

    MOverhaul_QuestArrow:SetHidden(not db.quest3DArrowEnabled)
end

local MOverhaul_MapQuestLine = nil
local lastMapUpdate = 0
local MAP_UPDATE_INTERVAL = 0.05 -- Update 20 times per second
local lastPlayerMapRefresh = 0

local function IsWayshrinePin(pin, activePins)
    if not pin or not activePins then return false end
    if not pin.GetNormalizedPosition then return false end
    local pinX, pinY = pin:GetNormalizedPosition()
    if not pinX or pinX == 0 or not pinY or pinY == 0 then return false end

    local wpType1 = MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE or 2
    local wpType2 = MAP_PIN_TYPE_WAYSHRINE or 3
    local wpType3 = MAP_PIN_TYPE_WAYSHRINE_CAPPED or 4
    local wpType4 = MAP_PIN_TYPE_FAST_TRAVEL_KEEP or 5

    for pinKey, otherPin in pairs(activePins) do
        if otherPin ~= pin and (type(otherPin) == "table" or type(otherPin) == "userdata") then
            if otherPin.GetPinType and otherPin.GetNormalizedPosition then
                local pinType = otherPin:GetPinType()
                if pinType == wpType1 or pinType == wpType2 or pinType == wpType3 or pinType == wpType4 then
                    local wx, wy = otherPin:GetNormalizedPosition()
                    if wx and wy then
                        local dist = math.sqrt((pinX - wx)^2 + (pinY - wy)^2)
                        if dist < 0.005 then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
local function SetMapToQuestObjective(questIndex)
    if not questIndex or questIndex <= 0 then return false end
    local numSteps = GetJournalQuestNumSteps(questIndex) or 1
    for stepIndex = 1, numSteps do
        local resultIndex = SetMapToQuestStepEnding(questIndex, stepIndex)
        if resultIndex == SET_MAP_RESULT_MAP_CHANGED or resultIndex == SET_MAP_RESULT_CURRENT_MAP_UNCHANGED then
            return true
        end
        local numConditions = GetJournalQuestNumConditions(questIndex, stepIndex) or 1
        for conditionIndex = 1, numConditions do
            local result = SetMapToQuestCondition(questIndex, stepIndex, conditionIndex)
            if result == SET_MAP_RESULT_MAP_CHANGED or result == SET_MAP_RESULT_CURRENT_MAP_UNCHANGED then
                return true
            end
        end
    end
    local result = SetMapToQuestZone(questIndex)
    return result == SET_MAP_RESULT_MAP_CHANGED or result == SET_MAP_RESULT_CURRENT_MAP_UNCHANGED
end
local function UpdateQuest2DArrow(pinX, pinY, questIndex)
    if not MOverhaul.db or not MOverhaul.db.quest3DArrowEnabled then
        if MOverhaul_QuestArrow then
            MOverhaul_QuestArrow:SetHidden(true)
        end
        return
    end

    if not MOverhaul_QuestArrow then
        CreateQuestArrowControl()
    end

    if not pinX or pinX == 0 or not pinY or pinY == 0 then
        if MOverhaul_QuestArrow then
            MOverhaul_QuestArrow:SetHidden(true)
        end
        return
    end

    local px, py = GetMapPlayerPosition("player")
    if not px or px == 0 then
        if MOverhaul_QuestArrow then
            MOverhaul_QuestArrow:SetHidden(true)
        end
        return
    end

    local questName = ""
    local zoneName = ""
    if questIndex and questIndex > 0 then
        questName = GetJournalQuestName(questIndex) or ""
        zoneName = GetJournalQuestLocationInfo(questIndex) or ""
    end

    if MOverhaul_QuestArrow then
        MOverhaul_QuestArrow:SetHidden(false)

        local label = MOverhaul_QuestArrow:GetNamedChild("Label")
        local arrowTexture = MOverhaul_QuestArrow:GetNamedChild("Texture")

        -- 1. Calculate distance using global coordinates
        local distanceText = ""
        local LibGPS = LibGPS3 or LibGPS2 or LibGPS
        if LibGPS then
            LibGPS:PushCurrentMap()
            local gpx, gpy = LibGPS:LocalToGlobal(px, py)
            
            local currentMapName = GetMapName()
            local isDifferentZone = zoneName ~= "" and currentMapName ~= "" and zoneName ~= currentMapName
            local gtx, gty = nil, nil

            -- Generate a unique key for the current quest state to cache coordinates
            local uniqueKey = nil
            if questIndex and questIndex > 0 then
                local numSteps = GetJournalQuestNumSteps(questIndex) or 0
                local progressKey = ""
                for stepIndex = 1, numSteps do
                    local numConditions = GetJournalQuestNumConditions(questIndex, stepIndex) or 0
                    for conditionIndex = 1, numConditions do
                        local conditionText, currentVal, maxVal, isFail, isComplete = GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)
                        if not isComplete then
                            progressKey = progressKey .. "_" .. stepIndex .. "_" .. conditionIndex .. "_" .. tostring(currentVal)
                        end
                    end
                end
                uniqueKey = questName .. progressKey
            end

            -- Ensure questCoordsCache exists
            if MOverhaul.db then
                MOverhaul.db.questCoordsCache = MOverhaul.db.questCoordsCache or {}
            end

            if not isDifferentZone then
                -- Same zone (or map showing quest zone), get global coordinates from current pin
                if pinX and pinX > 0 and pinY and pinY > 0 then
                    gtx, gty = LibGPS:LocalToGlobal(pinX, pinY)
                    -- Cache these coordinates as they are correct
                    if uniqueKey and MOverhaul.db then
                        MOverhaul.db.questCoordsCache[uniqueKey] = { gtx = gtx, gty = gty }
                    end
                end
            else
                -- Different zone, retrieve from cache if available
                local cached = uniqueKey and MOverhaul.db and MOverhaul.db.questCoordsCache[uniqueKey]
                if cached then
                    gtx, gty = cached.gtx, cached.gty
                else
                    -- Cache miss! Let's do a one-time background map-swap to retrieve and cache the coordinates
                    local now = GetFrameTimeSeconds()
                    -- Throttle background swaps to avoid spamming if it fails repeatedly (e.g. 5 seconds)
                    if not MOverhaul.lastBgSwapTime or (now - MOverhaul.lastBgSwapTime >= 5.0) then
                        MOverhaul.lastBgSwapTime = now
                        
                        -- Fakes to allow background map-swapping and pin rebuilding
                        local mapHidden = false
                        if ZO_WorldMap then
                            mapHidden = ZO_WorldMap:IsHidden()
                        end

                        local oldIsChangingAllowed = ZO_WorldMap_IsMapChangingAllowed
                        ZO_WorldMap_IsMapChangingAllowed = function() return true end

                        local oldIsHidden = ZO_WorldMap.IsHidden
                        ZO_WorldMap.IsHidden = function() return false end

                        local oldIsWorldMapShowing = ZO_WorldMap_IsWorldMapShowing
                        _G["ZO_WorldMap_IsWorldMapShowing"] = function() return true end

                        if ZO_WorldMap and mapHidden then
                            ZO_WorldMap:SetHidden(false)
                        end

                        SetMapToQuestObjective(questIndex)

                        local pinManager = ZO_WorldMap_GetPinManager()
                        if pinManager and pinManager.RebuildPins then
                            pcall(function() pinManager:RebuildPins() end)
                        end

                        local activePins = nil
                        if pinManager then
                            if pinManager.GetActiveObjects then
                                activePins = pinManager:GetActiveObjects()
                            elseif pinManager.m_Active then
                                activePins = pinManager.m_Active
                            end
                        end

                        local targetPinQuest = nil
                        if activePins then
                            for pinKey, pin in pairs(activePins) do
                                if type(pin) == "table" or type(pin) == "userdata" then
                                    if pin.GetPinType and pin.GetNormalizedPosition then
                                        local pinType = pin:GetPinType()
                                        if pinType >= 10 and pinType <= 17 then
                                            if not IsWayshrinePin(pin, activePins) then
                                                targetPinQuest = pin
                                                break
                                            end
                                        elseif pinType >= 19 and pinType <= 26 then
                                            if not IsWayshrinePin(pin, activePins) then
                                                if not targetPinQuest or targetPinQuest:GetPinType() > 26 then
                                                    targetPinQuest = pin
                                                end
                                            end
                                        elseif pinType >= 28 and pinType <= 35 then
                                            if not IsWayshrinePin(pin, activePins) then
                                                if not targetPinQuest then
                                                    targetPinQuest = pin
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if targetPinQuest then
                            local qPinX, qPinY = targetPinQuest:GetNormalizedPosition()
                            if qPinX and qPinX > 0 and qPinY and qPinY > 0 then
                                gtx, gty = LibGPS:LocalToGlobal(qPinX, qPinY)
                                if uniqueKey and MOverhaul.db then
                                    MOverhaul.db.questCoordsCache[uniqueKey] = { gtx = gtx, gty = gty }
                                end
                            end
                        end

                        -- Restore map to player location
                        SetMapToPlayerLocation()

                        if ZO_WorldMap and mapHidden then
                            ZO_WorldMap:SetHidden(true)
                        end

                        ZO_WorldMap_IsMapChangingAllowed = oldIsChangingAllowed
                        ZO_WorldMap.IsHidden = oldIsHidden
                        _G["ZO_WorldMap_IsWorldMapShowing"] = oldIsWorldMapShowing

                        if pinManager and pinManager.RebuildPins then
                            pcall(function() pinManager:RebuildPins() end)
                        end
                    end
                end

                -- Fallback to local pin coordinates (door/exit) if still not cached
                if not gtx and pinX and pinX > 0 and pinY and pinY > 0 then
                    gtx, gty = LibGPS:LocalToGlobal(pinX, pinY)
                end
            end

            if gpx and gpy and gtx and gty then
                local distance = LibGPS:GetGlobalDistanceInMeters(gpx, gpy, gtx, gty)
                if distance and distance ~= math.huge and distance == distance then
                    distance = distance / 2.0
                    if distance > 1000 then
                        distanceText = string.format("%.1f km", distance / 1000)
                    else
                        distanceText = string.format("%d m", math.floor(distance))
                    end
                else
                    local distPct = math.sqrt((pinX - px)^2 + (pinY - py)^2)
                    distanceText = string.format("%.0f%%", distPct * 100)
                end
            end
            LibGPS:PopCurrentMap()
        end

        if distanceText == "" then
            local distPct = math.sqrt((pinX - px)^2 + (pinY - py)^2)
            distanceText = string.format("%.0f%%", distPct * 100)
        end

        -- Calculate local map angle (100% accurate for player's current map)
        local targetAngle = math.atan2(pinX - px, py - pinY)

        local finalText = distanceText
        if questName ~= "" then
            finalText = finalText .. "\n|cFFFF00" .. questName .. "|r"
        end
        if zoneName ~= "" then
            finalText = finalText .. "\n|cAAAAAA" .. zoneName .. "|r"
        end

        if label then
            label:SetText(finalText)
            label:SetColor(1, 1, 1, 1)
        end

        local cameraHeading = GetPlayerCameraHeading()
        local cameraHeadingCw = (math.pi / 2) - cameraHeading
        -- Default to 0 since transform_arrow.dds points North by default.
        local offset = MOverhaul.db and MOverhaul.db.arrowOffset or 0
        local relativeAngle = cameraHeadingCw - targetAngle - offset

        if arrowTexture then
            arrowTexture:SetTextureRotation(relativeAngle)
        end
    end
end

local function UpdateMapQuestLine()
    local time = GetFrameTimeSeconds()
    if time - lastMapUpdate < MAP_UPDATE_INTERVAL then return end
    lastMapUpdate = time

    if not ZO_WorldMap or ZO_WorldMap:IsHidden() then
        if time - lastPlayerMapRefresh >= 1.0 then
            lastPlayerMapRefresh = time
            SetMapToPlayerLocation()
            local pinManager = ZO_WorldMap_GetPinManager()
            if pinManager and pinManager.RebuildPins then
                pcall(function() pinManager:RebuildPins() end)
            end
        end
    end

    local playerX, playerY = GetMapPlayerPosition("player")
    if not playerX or playerX == 0 then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        MOverhaul.targetX = nil
        MOverhaul.targetY = nil
        MOverhaul.targetPinType = nil
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
        -- First pass: look for the actively assisted pin (green glowing tracker pin) that is NOT a wayshrine transit suggestion
        for pinKey, pin in pairs(activePins) do
            if type(pin) == "table" or type(pin) == "userdata" then
                if pin.GetPinType and pin.GetNormalizedPosition then
                    local pinType = pin:GetPinType()
                    if pinType >= 10 and pinType <= 17 then
                        if pin.IsAssisted and pin:IsAssisted() then
                            if not IsWayshrinePin(pin, activePins) then
                                targetPin = pin
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Second pass: if no non-wayshrine assisted pin found, look for any assisted pin
        if not targetPin then
            for pinKey, pin in pairs(activePins) do
                if type(pin) == "table" or type(pin) == "userdata" then
                    if pin.GetPinType and pin.GetNormalizedPosition then
                        local pinType = pin:GetPinType()
                        if pinType >= 10 and pinType <= 17 then
                            if pin.IsAssisted and pin:IsAssisted() then
                                targetPin = pin
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Third pass: fall back to non-wayshrine generic quest pins
        if not targetPin then
            for pinKey, pin in pairs(activePins) do
                if type(pin) == "table" or type(pin) == "userdata" then
                    if pin.GetPinType and pin.GetNormalizedPosition then
                        local pinType = pin:GetPinType()
                        if pinType >= 10 and pinType <= 17 then
                            if not IsWayshrinePin(pin, activePins) then
                                targetPin = pin
                                break
                            end
                        elseif pinType >= 19 and pinType <= 26 then
                            if not IsWayshrinePin(pin, activePins) then
                                if not targetPin or targetPin:GetPinType() > 26 then
                                    targetPin = pin
                                end
                            end
                        elseif pinType >= 28 and pinType <= 35 then
                            if not IsWayshrinePin(pin, activePins) then
                                if not targetPin then
                                    targetPin = pin
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Final pass: fallback to original behavior (any quest pin) if nothing else is found
        if not targetPin then
            for pinKey, pin in pairs(activePins) do
                if type(pin) == "table" or type(pin) == "userdata" then
                    if pin.GetPinType and pin.GetNormalizedPosition then
                        local pinType = pin:GetPinType()
                        if pinType >= 10 and pinType <= 17 then
                            targetPin = pin
                            break
                        elseif pinType >= 19 and pinType <= 26 then
                            if not targetPin or targetPin:GetPinType() > 26 then
                                targetPin = pin
                            end
                        elseif pinType >= 28 and pinType <= 35 then
                            if not targetPin then
                                targetPin = pin
                            end
                        end
                    end
                end
            end
        end
    end

    local pinX, pinY = 0, 0
    local questIndex = nil
    if targetPin then
        pinX, pinY = targetPin:GetNormalizedPosition()
        MOverhaul.targetX = pinX
        MOverhaul.targetY = pinY
        MOverhaul.targetPinType = targetPin:GetPinType()
        if targetPin.GetQuestIndex then
            questIndex = targetPin:GetQuestIndex()
        elseif targetPin.m_QuestIndex then
            questIndex = targetPin.m_QuestIndex
        end
    else
        MOverhaul.targetX = nil
        MOverhaul.targetY = nil
        MOverhaul.targetPinType = nil
    end

    -- Update 2D Quest Arrow
    UpdateQuest2DArrow(pinX, pinY, questIndex)

    -- Draw the 2D Line on the Map
    if not ZO_WorldMap or ZO_WorldMap:IsHidden() or not MOverhaul.db or not MOverhaul.db.questMapLineEnabled or pinX == 0 or pinY == 0 then
        if MOverhaul_MapQuestLine then
            MOverhaul_MapQuestLine:SetHidden(true)
        end
        return
    end

    if not MOverhaul_MapQuestLine then
        MOverhaul_MapQuestLine = WINDOW_MANAGER:CreateControl("MOverhaul_MapQuestLine", ZO_WorldMapContainer, CT_LINE)
        MOverhaul_MapQuestLine:SetThickness(5)
        MOverhaul_MapQuestLine:SetColor(1, 1, 0, 0.7) -- Yellow line to match yellow quest arrow
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
        CreateQuestArrowControl()
        
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
                    name = "Quest 2D Arrow (Modulo)",
                    tooltip = "Habilita ou desabilita a seta 2D amarela no HUD apontando para a quest ativa.",
                    getFunc = function() return MOverhaul.db.quest3DArrowEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.quest3DArrowEnabled = value 
                        if MOverhaul_QuestArrow then
                            MOverhaul_QuestArrow:SetHidden(not value)
                        end
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Bloquear Seta de Quest",
                    tooltip = "Bloqueia a movimentacao da seta de quest 2D no HUD para evitar arrastes acidentais.",
                    getFunc = function() return MOverhaul.db.questArrowLocked end,
                    setFunc = function(value) 
                        MOverhaul.db.questArrowLocked = value 
                        if MOverhaul_QuestArrow then
                            MOverhaul_QuestArrow:SetMovable(not value)
                            MOverhaul_QuestArrow:SetMouseEnabled(not value)
                        end
                    end,
                    default = false,
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

        local mapUpdateControl = WINDOW_MANAGER:CreateControl("MOverhaul_MapQuestUpdate", GuiRoot, CT_CONTROL)
        mapUpdateControl:SetHandler("OnUpdate", function(self)
            UpdateMapQuestLine()
        end)

        -- Register Quest Journal keybind strip button
        MOverhaul.gpsQuestKeybind = {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            {
                name = function()
                    if MOverhaul.db and MOverhaul.db.quest3DArrowEnabled then
                        return "GPS Quest: Ativo"
                    else
                        return "GPS Quest: Inativo"
                    end
                end,
                keybind = "UI_SHORTCUT_QUATERNARY",
                callback = function()
                    MOverhaul.db.quest3DArrowEnabled = not MOverhaul.db.quest3DArrowEnabled
                    KEYBIND_STRIP:UpdateKeybindButtonGroup(MOverhaul.gpsQuestKeybind)
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                    if MOverhaul.db.quest3DArrowEnabled then
                        d("[MOverhaul] Seta 2D da Quest ATIVADA.")
                        if MOverhaul_QuestArrow then
                            MOverhaul_QuestArrow:SetHidden(false)
                        end
                    else
                        d("[MOverhaul] Seta 2D da Quest DESATIVADA.")
                        if MOverhaul_QuestArrow then
                            MOverhaul_QuestArrow:SetHidden(true)
                        end
                    end
                end,
                visible = function()
                    return true
                end,
            }
        }

        if QUEST_JOURNAL_SCENE then
            QUEST_JOURNAL_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                if newState == SCENE_SHOWING then
                    KEYBIND_STRIP:AddKeybindButtonGroup(MOverhaul.gpsQuestKeybind)
                elseif newState == SCENE_HIDING then
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(MOverhaul.gpsQuestKeybind)
                end
            end)
        end

    end
end

SLASH_COMMANDS["/mo_debugwaypoint"] = function()
    local px, py = GetMapPlayerPosition("player")
    local tx, ty = GetMapPlayerWaypoint()
    local heading = GetPlayerCameraHeading()
    
    d("[MOverhaul] Debug Waypoint:")
    d("Player Pos: " .. tostring(px) .. ", " .. tostring(py))
    d("Waypoint Pos: " .. tostring(tx) .. ", " .. tostring(ty))
    d("Camera Heading (rad): " .. tostring(heading))
    d("Camera Heading (deg): " .. tostring(math.deg(heading)))
    
    local dx = tx - px
    local dy = ty - py
    local targetAngle = math.atan2(dx, -dy)
    d("Target Angle (rad): " .. tostring(targetAngle))
    d("Target Angle (deg): " .. tostring(math.deg(targetAngle)))
    
    local relativeAngle = targetAngle - heading
    d("Relative Angle (rad): " .. tostring(relativeAngle))
    d("Relative Angle (deg): " .. tostring(math.deg(relativeAngle)))
    
    local LibGPS = LibGPS3 or LibGPS2 or LibGPS
    if LibGPS then
        local distance = LibGPS:GetLocalDistanceInMeters(px, py, tx, ty)
        d("LibGPS Distance (m): " .. tostring(distance))
    else
        d("LibGPS NOT LOADED")
    end
end

SLASH_COMMANDS["/mo_offset"] = function(extra)
    local num = tonumber(extra)
    if num then
        MOverhaul.db.arrowOffset = math.rad(num)
        d("[MOverhaul] Deslocamento da seta definido para " .. tostring(num) .. " graus.")
    else
        local current = MOverhaul.db.arrowOffset or (3 * math.pi / 2)
        d("[MOverhaul] Deslocamento atual: " .. tostring(math.floor(math.deg(current) + 0.5)) .. " graus. Use: /mo_offset <graus>")
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
