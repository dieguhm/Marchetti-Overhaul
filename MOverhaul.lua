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
    poiMenuEnabled = true,
    poiMenuLocked = false,
    poiMenuX = nil,
    poiMenuY = nil,
    poiMenuCollapsed = false,
    poiCache = {},
}

local overloadLabel = nil
local CacheMapPOIs

local ASSISTED_QUEST_PIN_TYPES = {}
local NORMAL_QUEST_PIN_TYPES = {}

local function InitializeQuestPinTypes()
    ASSISTED_QUEST_PIN_TYPES = {}
    NORMAL_QUEST_PIN_TYPES = {}
    
    local questKeys = {
        -- Original Quest Pin Types
        "MAP_PIN_TYPE_QUEST_CONDITION",
        "MAP_PIN_TYPE_QUEST_ENDING",
        "MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_QUEST_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_ENDING",
        
        "MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION",
        "MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING",
        "MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_REPEATABLE_QUEST_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_ENDING",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_REPEATABLE_QUEST_ZONE_STORY_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_ZONE_STORY_ENDING",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_ZONE_STORY_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_QUEST_ZONE_STORY_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_ZONE_STORY_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_ZONE_STORY_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_ZONE_STORY_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_QUEST_ZONE_STORY_OPTIONAL_ENDING",

        -- Favor Quest Pin Types (Added for U50 Favor System)
        "MAP_PIN_TYPE_FAVOR_QUEST_CONDITION",
        "MAP_PIN_TYPE_FAVOR_QUEST_ENDING",
        "MAP_PIN_TYPE_FAVOR_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_FAVOR_QUEST_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_QUEST_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_QUEST_ENDING",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_QUEST_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_FAVOR_CONDITION",
        "MAP_PIN_TYPE_FAVOR_ENDING",
        "MAP_PIN_TYPE_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_FAVOR_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_ENDING",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_FAVOR_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_QUEST_FAVOR_CONDITION",
        "MAP_PIN_TYPE_QUEST_FAVOR_ENDING",
        "MAP_PIN_TYPE_QUEST_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_QUEST_FAVOR_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_FAVOR_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_FAVOR_ENDING",
        "MAP_PIN_TYPE_ASSISTED_QUEST_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_QUEST_FAVOR_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_REPEATABLE_FAVOR_QUEST_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_QUEST_ENDING",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_QUEST_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_QUEST_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_QUEST_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_QUEST_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_QUEST_OPTIONAL_ENDING",

        "MAP_PIN_TYPE_REPEATABLE_FAVOR_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_ENDING",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_REPEATABLE_FAVOR_OPTIONAL_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_ENDING",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_OPTIONAL_CONDITION",
        "MAP_PIN_TYPE_ASSISTED_REPEATABLE_FAVOR_OPTIONAL_ENDING",
    }
    
    for _, key in ipairs(questKeys) do
        local value = _G[key]
        if type(value) == "number" then
            if string.find(key, "ASSISTED") then
                ASSISTED_QUEST_PIN_TYPES[value] = true
            else
                NORMAL_QUEST_PIN_TYPES[value] = true
            end
        end
    end
end

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
local MOverhaul_QuestArrow = nil
local questArrowFragment = nil
local waypointArrowFragment = nil

local function UpdateQuestArrowFragmentVisibility()
    if not MOverhaul_QuestArrow then return end
    if not questArrowFragment then
        questArrowFragment = ZO_HUDFadeSceneFragment:New(MOverhaul_QuestArrow)
    end
    if MOverhaul.db and MOverhaul.db.quest3DArrowEnabled then
        if not HUD_SCENE:HasFragment(questArrowFragment) then
            HUD_SCENE:AddFragment(questArrowFragment)
            HUD_UI_SCENE:AddFragment(questArrowFragment)
        end
    else
        if HUD_SCENE:HasFragment(questArrowFragment) then
            HUD_SCENE:RemoveFragment(questArrowFragment)
            HUD_UI_SCENE:RemoveFragment(questArrowFragment)
        end
        MOverhaul_QuestArrow:SetHidden(true)
    end
end

local function UpdateWaypointArrowFragmentVisibility()
    if not MOverhaul_WaypointArrow then return end
    if not waypointArrowFragment then
        waypointArrowFragment = ZO_HUDFadeSceneFragment:New(MOverhaul_WaypointArrow)
    end
    if MOverhaul.db and MOverhaul.db.questWaypointArrowEnabled then
        if not HUD_SCENE:HasFragment(waypointArrowFragment) then
            HUD_SCENE:AddFragment(waypointArrowFragment)
            HUD_UI_SCENE:AddFragment(waypointArrowFragment)
        end
    else
        if HUD_SCENE:HasFragment(waypointArrowFragment) then
            HUD_SCENE:RemoveFragment(waypointArrowFragment)
            HUD_UI_SCENE:RemoveFragment(waypointArrowFragment)
        end
        MOverhaul_WaypointArrow:SetHidden(true)
    end
end

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
        db.questWaypointArrowX = self:GetLeft()
        db.questWaypointArrowY = self:GetTop()
    end)

    MOverhaul_WaypointArrow:SetHandler("OnUpdate", OnWaypointArrowUpdate)
    MOverhaul_WaypointArrow:SetHidden(not db.questWaypointArrowEnabled)

    -- Try to force refresh quest pins on initial load
    local pinManager = ZO_WorldMap_GetPinManager()
    if pinManager and pinManager.RefreshQuestPins then
        pcall(function() pinManager:RefreshQuestPins() end)
    end
end

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
        db.questArrowX = self:GetLeft()
        db.questArrowY = self:GetTop()
    end)

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

local QUEST_TYPE_MAIN_STORY = QUEST_TYPE_MAIN_STORY or 1
local QUEST_TYPE_GUILD = QUEST_TYPE_GUILD or 2
local QUEST_TYPE_CRAFTING = QUEST_TYPE_CRAFTING or 3
local QUEST_TYPE_DUNGEON = QUEST_TYPE_DUNGEON or 4
local QUEST_TYPE_ZONE_STORY = QUEST_TYPE_ZONE_STORY or 5
local QUEST_TYPE_HOLIDAY_EVENT = QUEST_TYPE_HOLIDAY_EVENT or 9
local QUEST_TYPE_PROLOGUE = QUEST_TYPE_PROLOGUE or 11

local INSTANCE_DISPLAY_TYPE_DUNGEON = INSTANCE_DISPLAY_TYPE_DUNGEON or 2
local INSTANCE_DISPLAY_TYPE_GROUP_AREA = INSTANCE_DISPLAY_TYPE_GROUP_AREA or 3
local INSTANCE_DISPLAY_TYPE_RAID = INSTANCE_DISPLAY_TYPE_RAID or 4

local function GetQuestIconPath(questIndex)
    if not questIndex or questIndex <= 0 then return nil end

    local questType = GetJournalQuestType and GetJournalQuestType(questIndex)
    local instanceDisplayType = GetJournalQuestInstanceDisplayType and GetJournalQuestInstanceDisplayType(questIndex)
    
    local _, _, _, _, _, _, _, _, _, _, _, isDaily, isRepeatable = GetJournalQuestInfo(questIndex)
    local isRepeat = isDaily or isRepeatable
    
    if instanceDisplayType == INSTANCE_DISPLAY_TYPE_DUNGEON or instanceDisplayType == INSTANCE_DISPLAY_TYPE_GROUP_AREA then
        return "esoui/art/journal/journal_quest_dungeon.dds"
    elseif instanceDisplayType == INSTANCE_DISPLAY_TYPE_RAID then
        return "esoui/art/journal/journal_quest_raid.dds"
    end
    
    if questType == QUEST_TYPE_MAIN_STORY then
        return "esoui/art/journal/journal_quest_mainstory.dds"
    elseif questType == QUEST_TYPE_GUILD then
        return "esoui/art/journal/journal_quest_guild.dds"
    elseif questType == QUEST_TYPE_CRAFTING then
        return "esoui/art/journal/journal_quest_crafting.dds"
    elseif questType == QUEST_TYPE_DUNGEON then
        return "esoui/art/journal/journal_quest_dungeon.dds"
    elseif questType == QUEST_TYPE_ZONE_STORY then
        return "esoui/art/journal/journal_quest_zone_story.dds"
    elseif questType == QUEST_TYPE_HOLIDAY_EVENT then
        return "esoui/art/journal/journal_quest_holiday.dds"
    elseif questType == QUEST_TYPE_PROLOGUE then
        return "esoui/art/journal/journal_quest_prologue.dds"
    end
    
    if isRepeat then
        return "esoui/art/journal/journal_quest_repeat.dds"
    end
    
    return "esoui/art/journal/journal_quest_sidequest.dds"
end

local function UpdateQuest2DArrow(pinX, pinY, questIndex)
    if not MOverhaul_QuestArrow then
        CreateQuestArrowControl()
    end

    -- If the HUD scene fragment is not active (e.g. player is in menus/map), hide and return
    if questArrowFragment and not questArrowFragment:IsShowing() then
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

    -- If we don't have a valid quest index, hide everything and return
    if not questIndex or questIndex <= 0 then
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

    if MOverhaul_QuestArrow then
        MOverhaul_QuestArrow:SetHidden(false)
    end

    local label = MOverhaul_QuestArrow:GetNamedChild("Label")
    local arrowTexture = MOverhaul_QuestArrow:GetNamedChild("Texture")

    local distanceText = ""
    local targetAngle = 0
    local hasTargetCoords = false

    local LibGPS = LibGPS3 or LibGPS2 or LibGPS
    if LibGPS then
        LibGPS:PushCurrentMap()
        local gpx, gpy = LibGPS:LocalToGlobal(px, py)
        local gtx, gty = nil, nil

        local uniqueKey = string.format("%d_%s", questIndex, questName)
        if MOverhaul.db and MOverhaul.db.questCoordsCache and MOverhaul.db.questCoordsCache[uniqueKey] then
            gtx = MOverhaul.db.questCoordsCache[uniqueKey].gtx
            gty = MOverhaul.db.questCoordsCache[uniqueKey].gty
        else
            -- Try to find target pin by switching map to quest zone temporarily
            local oldIsHidden = ZO_WorldMap.IsHidden
            local oldIsWorldMapShowing = _G["ZO_WorldMap_IsWorldMapShowing"]
            local oldIsChangingAllowed = ZO_WorldMap_IsMapChangingAllowed

            ZO_WorldMap.IsHidden = function() return false end
            _G["ZO_WorldMap_IsWorldMapShowing"] = function() return true end
            ZO_WorldMap_IsMapChangingAllowed = function() return true end

            local success, err = pcall(function()
                local mapHidden = ZO_WorldMap:IsHidden()
                if mapHidden then
                    ZO_WorldMap:SetHidden(false)
                end

                local wasZoneMapSet = SetMapToQuestObjective(questIndex)
                if wasZoneMapSet then
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
                    local minDistance = math.huge
                    if activePins then
                        for pinKey, pin in pairs(activePins) do
                            if type(pin) == "table" or type(pin) == "userdata" then
                                if pin.GetPinType and pin.GetNormalizedPosition then
                                    local pinType = pin:GetPinType()
                                    if ASSISTED_QUEST_PIN_TYPES[pinType] or NORMAL_QUEST_PIN_TYPES[pinType] then
                                        if not IsWayshrinePin(pin, activePins) then
                                            local pinX, pinY = pin:GetNormalizedPosition()
                                            if pinX and pinY then
                                                local dist = (pinX - px)^2 + (pinY - py)^2
                                                local isAssisted = ASSISTED_QUEST_PIN_TYPES[pinType] ~= nil
                                                local targetIsAssisted = targetPinQuest and (ASSISTED_QUEST_PIN_TYPES[targetPinQuest:GetPinType()] ~= nil)
                                                
                                                if not targetPinQuest then
                                                    targetPinQuest = pin
                                                    minDistance = dist
                                                elseif isAssisted and not targetIsAssisted then
                                                    targetPinQuest = pin
                                                    minDistance = dist
                                                elseif isAssisted == targetIsAssisted then
                                                    if dist < minDistance then
                                                        targetPinQuest = pin
                                                        minDistance = dist
                                                    end
                                                end
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

                    if pinManager and pinManager.RebuildPins then
                        pcall(function() pinManager:RebuildPins() end)
                    end
                end
            end)

            -- ALWAYS restore native map functions, regardless of wasZoneMapSet result or pcall errors
            ZO_WorldMap_IsMapChangingAllowed = oldIsChangingAllowed
            ZO_WorldMap.IsHidden = oldIsHidden
            _G["ZO_WorldMap_IsWorldMapShowing"] = oldIsWorldMapShowing

            -- Force reset map to player location in case anything failed during the map-swap
            pcall(function() SetMapToPlayerLocation() end)
        end

        -- Fallback to local pin coordinates if still not cached
        local hasCoords = pinX and pinX > 0 and pinY and pinY > 0
        if not gtx and hasCoords then
            gtx, gty = LibGPS:LocalToGlobal(pinX, pinY)
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
                
                -- Calculate target angle in global Tamriel coords
                targetAngle = math.atan2(gtx - gpx, gty - gpy)
                hasTargetCoords = true
            end
        end
        LibGPS:PopCurrentMap()
    end

    -- Fallback to local map coordinates if global calculations weren't possible
    local hasLocalCoords = pinX and pinX > 0 and pinY and pinY > 0
    if not hasTargetCoords and hasLocalCoords then
        if distanceText == "" then
            local distPct = math.sqrt((pinX - px)^2 + (pinY - py)^2)
            distanceText = string.format("%.0f%%", distPct * 100)
        end
        targetAngle = math.atan2(pinX - px, py - pinY)
        hasTargetCoords = true
    end

    -- Control arrow visibility dynamically based on target coordinate availability
    if arrowTexture then
        arrowTexture:SetHidden(not hasTargetCoords)
    end

    local finalText = distanceText
    if questName ~= "" then
        local icon = GetQuestIconPath(questIndex)
        if icon and icon ~= "" then
            if finalText ~= "" then
                finalText = finalText .. "\n|t18:18:" .. icon .. "|t |cFFFF00" .. questName .. "|r"
            else
                finalText = "|t18:18:" .. icon .. "|t |cFFFF00" .. questName .. "|r"
            end
        else
            if finalText ~= "" then
                finalText = finalText .. "\n|cFFFF00" .. questName .. "|r"
            else
                finalText = "|cFFFF00" .. questName .. "|r"
            end
        end
    end
    if zoneName ~= "" then
        if finalText ~= "" then
            finalText = finalText .. "\n|cAAAAAA" .. zoneName .. "|r"
        else
            finalText = "|cAAAAAA" .. zoneName .. "|r"
        end
    end

    if label then
        label:SetText(finalText)
        label:SetColor(1, 1, 1, 1)
    end

    if hasTargetCoords then
        local cameraHeading = GetPlayerCameraHeading()
        local cameraHeadingCw = (math.pi / 2) - cameraHeading
        local offset = MOverhaul.db and MOverhaul.db.arrowOffset or 0
        local relativeAngle = cameraHeadingCw - targetAngle - offset

        if arrowTexture then
            arrowTexture:SetTextureRotation(relativeAngle)
        end
    end
end

local lastPOICacheTime = 0

local function UpdateMapQuestLine()
    local time = GetFrameTimeSeconds()
    if time - lastMapUpdate < MAP_UPDATE_INTERVAL then return end
    lastMapUpdate = time

    -- Update POI Cache when map is visible
    if ZO_WorldMap and not ZO_WorldMap:IsHidden() then
        if time - lastPOICacheTime >= 1.0 then
            lastPOICacheTime = time
            if CacheMapPOIs then
                local success, err = pcall(CacheMapPOIs)
                if not success then
                    d("[MOverhaul Cache Error] " .. tostring(err))
                end
            end
        end
    end

    local assistedQuestIndex = QUEST_JOURNAL_MANAGER and QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex() or nil
    
    -- Detect if focused quest changed to force rebuilding map pins immediately
    if assistedQuestIndex ~= MOverhaul.lastTrackedQuestIndex then
        MOverhaul.lastTrackedQuestIndex = assistedQuestIndex
        SetMapToPlayerLocation()
        local pinManager = ZO_WorldMap_GetPinManager()
        if pinManager and pinManager.RebuildPins then
            pcall(function() pinManager:RebuildPins() end)
        end
    end

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
        if assistedQuestIndex and assistedQuestIndex > 0 then
            -- 1. If we have an active focused quest, ONLY scan for pins belonging to this quest
            -- First pass: look for actively assisted pin (green) that is not a wayshrine
            local minDistance = math.huge
            for pinKey, pin in pairs(activePins) do
                if type(pin) == "table" or type(pin) == "userdata" then
                    if pin.GetPinType and pin.GetNormalizedPosition then
                        local pinQuestIndex = pin.GetQuestIndex and pin:GetQuestIndex() or pin.m_QuestIndex
                        if pinQuestIndex == assistedQuestIndex then
                            local pinType = pin:GetPinType()
                            if ASSISTED_QUEST_PIN_TYPES[pinType] then
                                if pin.IsAssisted and pin:IsAssisted() then
                                    if not IsWayshrinePin(pin, activePins) then
                                        local pinX, pinY = pin:GetNormalizedPosition()
                                        if pinX and pinY then
                                            local dist = (pinX - playerX)^2 + (pinY - playerY)^2
                                            if dist < minDistance then
                                                minDistance = dist
                                                targetPin = pin
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Second pass: look for any assisted pin belonging to the focused quest
            if not targetPin then
                minDistance = math.huge
                for pinKey, pin in pairs(activePins) do
                    if type(pin) == "table" or type(pin) == "userdata" then
                        if pin.GetPinType and pin.GetNormalizedPosition then
                            local pinQuestIndex = pin.GetQuestIndex and pin:GetQuestIndex() or pin.m_QuestIndex
                            if pinQuestIndex == assistedQuestIndex then
                                local pinType = pin:GetPinType()
                                if ASSISTED_QUEST_PIN_TYPES[pinType] then
                                    if pin.IsAssisted and pin:IsAssisted() then
                                        local pinX, pinY = pin:GetNormalizedPosition()
                                        if pinX and pinY then
                                            local dist = (pinX - playerX)^2 + (pinY - playerY)^2
                                            if dist < minDistance then
                                                minDistance = dist
                                                targetPin = pin
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Third pass: look for any quest pin (including non-assisted and wayshrines) of the focused quest
            if not targetPin then
                minDistance = math.huge
                for pinKey, pin in pairs(activePins) do
                    if type(pin) == "table" or type(pin) == "userdata" then
                        if pin.GetPinType and pin.GetNormalizedPosition then
                            local pinQuestIndex = pin.GetQuestIndex and pin:GetQuestIndex() or pin.m_QuestIndex
                            if pinQuestIndex == assistedQuestIndex then
                                local pinType = pin:GetPinType()
                                if ASSISTED_QUEST_PIN_TYPES[pinType] or NORMAL_QUEST_PIN_TYPES[pinType] then
                                    local pinX, pinY = pin:GetNormalizedPosition()
                                    if pinX and pinY then
                                        local dist = (pinX - playerX)^2 + (pinY - playerY)^2
                                        local isAssisted = ASSISTED_QUEST_PIN_TYPES[pinType] ~= nil
                                        local targetIsAssisted = targetPin and (ASSISTED_QUEST_PIN_TYPES[targetPin:GetPinType()] ~= nil)
                                        
                                        if not targetPin then
                                            targetPin = pin
                                            minDistance = dist
                                        elseif isAssisted and not targetIsAssisted then
                                            targetPin = pin
                                            minDistance = dist
                                        elseif isAssisted == targetIsAssisted then
                                            if dist < minDistance then
                                                targetPin = pin
                                                minDistance = dist
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

        else
            -- 2. If no active focused quest is selected, fall back to scanning any quest pin
            -- First pass: look for any actively assisted pin that is not a wayshrine
            for pinKey, pin in pairs(activePins) do
                if type(pin) == "table" or type(pin) == "userdata" then
                    if pin.GetPinType and pin.GetNormalizedPosition then
                        local pinType = pin:GetPinType()
                        if ASSISTED_QUEST_PIN_TYPES[pinType] then
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

            -- Second pass: look for any assisted pin
            if not targetPin then
                for pinKey, pin in pairs(activePins) do
                    if type(pin) == "table" or type(pin) == "userdata" then
                        if pin.GetPinType and pin.GetNormalizedPosition then
                            local pinType = pin:GetPinType()
                            if ASSISTED_QUEST_PIN_TYPES[pinType] then
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
                            if ASSISTED_QUEST_PIN_TYPES[pinType] or NORMAL_QUEST_PIN_TYPES[pinType] then
                                if not IsWayshrinePin(pin, activePins) then
                                    if ASSISTED_QUEST_PIN_TYPES[pinType] then
                                        targetPin = pin
                                        break
                                    else
                                        if not targetPin or ASSISTED_QUEST_PIN_TYPES[targetPin:GetPinType()] == nil then
                                            targetPin = pin
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Final pass: fallback to any quest pin (including wayshrines)
            if not targetPin then
                for pinKey, pin in pairs(activePins) do
                    if type(pin) == "table" or type(pin) == "userdata" then
                        if pin.GetPinType and pin.GetNormalizedPosition then
                            local pinType = pin:GetPinType()
                            if ASSISTED_QUEST_PIN_TYPES[pinType] or NORMAL_QUEST_PIN_TYPES[pinType] then
                                if ASSISTED_QUEST_PIN_TYPES[pinType] then
                                    targetPin = pin
                                    break
                                else
                                    if not targetPin or ASSISTED_QUEST_PIN_TYPES[targetPin:GetPinType()] == nil then
                                        targetPin = pin
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local pinX, pinY = 0, 0
    local questIndex = assistedQuestIndex
    if targetPin then
        pinX, pinY = targetPin:GetNormalizedPosition()
        MOverhaul.targetX = pinX
        MOverhaul.targetY = pinY
        MOverhaul.targetPinType = targetPin:GetPinType()
        if targetPin.GetQuestIndex then
            local pIndex = targetPin:GetQuestIndex()
            if pIndex and pIndex > 0 then
                questIndex = pIndex
            end
        elseif targetPin.m_QuestIndex then
            local pIndex = targetPin.m_QuestIndex
            if pIndex and pIndex > 0 then
                questIndex = pIndex
            end
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

local MOverhaul_POIFinderMenu = nil

local POI_MENU_ITEMS = {
    { category = "bank",        name = "Bank",              icon = "esoui/art/icons/servicemappins/servicepin_bank.dds" },
    { category = "stable",      name = "Stable",            icon = "esoui/art/icons/servicemappins/servicepin_stable.dds" },
    { category = "mages",       name = "Mages Guild",       icon = "esoui/art/icons/servicemappins/servicepin_magesguild.dds" },
    { category = "fighters",    name = "Fighters Guild",    icon = "esoui/art/icons/servicemappins/servicepin_fightersguild.dds" },
    { category = "guildtrader", name = "Guild Traders",     icon = "esoui/art/icons/servicemappins/servicepin_guildkiosk.dds" },
    { category = "wayshrine",   name = "Wayshrine",         icon = "esoui/art/icons/poi/poi_wayshrine_complete.dds" },
}

local function GetPinTexture(pin)
    if not pin then return "" end
    
    -- 1. Try to get texture directly from the control or its children
    if pin.GetControl then
        local control = pin:GetControl()
        if control then
            -- Try Background child (standard for native map pins)
            local bg = control.GetNamedChild and control:GetNamedChild("Background")
            if bg and bg.GetTextureFileName then
                local texture = bg:GetTextureFileName()
                if texture and texture ~= "" then
                    return texture:lower()
                end
            end
            
            -- Try Icon child
            local icon = control.GetNamedChild and control:GetNamedChild("Icon")
            if icon and icon.GetTextureFileName then
                local texture = icon:GetTextureFileName()
                if texture and texture ~= "" then
                    return texture:lower()
                end
            end
            
            -- Try control directly
            if control.GetTextureFileName then
                local texture = control:GetTextureFileName()
                if texture and texture ~= "" then
                    return texture:lower()
                end
            end
        end
    end

    -- 2. Fallback to PIN_LAYOUTS via ZO_MapPin or pinManager
    local pinType = pin.GetPinType and pin:GetPinType()
    if pinType then
        local layouts = (ZO_MapPin and ZO_MapPin.PIN_LAYOUTS) or (ZO_WorldMap_GetPinManager and ZO_WorldMap_GetPinManager().m_pinLayouts)
        local layout = layouts and layouts[pinType]
        if layout then
            local texture = layout.texture
            if type(texture) == "function" then
                local success, result = pcall(texture, pin)
                if success and type(result) == "string" then
                    return result:lower()
                end
            elseif type(texture) == "string" then
                return texture:lower()
            end
        end
    end

    return ""
end

local function GetPinName(pin)
    if not pin then return "" end
    
    -- 1. Hook ZO_Tooltip_AddLine and ZO_Tooltip_AddHeaderLine to capture text dynamically
    local capturedLines = {}
    local oldAddLine = _G["ZO_Tooltip_AddLine"]
    local oldAddHeader = _G["ZO_Tooltip_AddHeaderLine"]
    
    -- Use ComparativeTooltip1 (which is offscreen/hidden) to prevent screen flickering
    local mapTooltip = _G["ComparativeTooltip1"] or _G["ItemTooltip"] or _G["InformationTooltip"]
    
    if oldAddLine then
        _G["ZO_Tooltip_AddLine"] = function(tooltipControl, text, ...)
            if text and text ~= "" then
                table.insert(capturedLines, tostring(text))
            end
            if tooltipControl == mapTooltip then
                return
            end
            return oldAddLine(tooltipControl, text, ...)
        end
    end
    
    if oldAddHeader then
        _G["ZO_Tooltip_AddHeaderLine"] = function(tooltipControl, text, ...)
            if text and text ~= "" then
                table.insert(capturedLines, tostring(text))
            end
            if tooltipControl == mapTooltip then
                return
            end
            return oldAddHeader(tooltipControl, text, ...)
        end
    end
    
    -- Invoke SetTooltip on the offscreen tooltip control
    if mapTooltip and pin.SetTooltip then
        pcall(pin.SetTooltip, pin, mapTooltip)
    end
    
    -- Restore the hooks immediately!
    if oldAddLine then _G["ZO_Tooltip_AddLine"] = oldAddLine end
    if oldAddHeader then _G["ZO_Tooltip_AddHeaderLine"] = oldAddHeader end
    
    -- If we captured text, join and return
    if #capturedLines > 0 then
        return table.concat(capturedLines, " "):lower()
    end
    
    -- 2. Fallback to standard tag checks if tooltip was empty
    local pinType2, pinTag
    if pin.GetPinTypeAndTag then
        pinType2, pinTag = pin:GetPinTypeAndTag()
    end
    
    if type(pinTag) == "string" then
        return pinTag:lower()
    elseif type(pinTag) == "table" or type(pinTag) == "userdata" then
        if pinTag.GetName then
            local success, name = pcall(pinTag.GetName, pinTag)
            if success and type(name) == "string" and name ~= "" then
                return name:lower()
            end
        end
        if pinTag.GetTooltipText then
            local success, text = pcall(pinTag.GetTooltipText, pinTag)
            if success and type(text) == "string" and text ~= "" then
                return text:lower()
            end
        end
        if pinTag.name then return tostring(pinTag.name):lower() end
        if pinTag.title then return tostring(pinTag.title):lower() end
    end
    
    return ""
end

local function MatchPinCategory(category, texture, name, pinType)
    texture = texture or ""
    name = name or ""
    
    if category == "bank" then
        if _G.MAP_PIN_TYPE_BANK and pinType == _G.MAP_PIN_TYPE_BANK then return true end
        return string.find(texture, "bank") or string.find(name, "bank") or string.find(name, "banco")
    elseif category == "stable" then
        if _G.MAP_PIN_TYPE_STABLE and pinType == _G.MAP_PIN_TYPE_STABLE then return true end
        return string.find(texture, "stable") or string.find(texture, "horse") or string.find(name, "stable") or string.find(name, "estabulo") or string.find(name, "estábulo")
    elseif category == "mages" then
        return string.find(texture, "magesguild") or string.find(texture, "mage") or string.find(name, "mages guild") or string.find(name, "guilda dos magos") or string.find(name, "guilda de magos") or string.find(name, "magos")
    elseif category == "fighters" then
        return string.find(texture, "fightersguild") or string.find(texture, "fighter") or string.find(name, "fighters guild") or string.find(name, "guilda dos guerreiros") or string.find(name, "guilda de guerreiros") or string.find(name, "guerreiros") or string.find(name, "combatentes")
    elseif category == "guildtrader" then
        return string.find(texture, "trader") or string.find(texture, "kiosk") or string.find(name, "guild trader") or string.find(name, "guild kiosk") or string.find(name, "quiosque de guilda") or string.find(name, "comerciante de guilda") or string.find(name, "mercador de guilda") or string.find(name, "quiosque") or string.find(name, "trader") or string.find(name, "kiosk")
    elseif category == "wayshrine" then
        if (_G.MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE and pinType == _G.MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE) or
           (_G.MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT and pinType == _G.MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT) then
            return true
        end
        return string.find(texture, "wayshrine") or string.find(texture, "fasttravel") or string.find(name, "wayshrine") or string.find(name, "santuario") or string.find(name, "santuário")
    end
    
    return false
end

CacheMapPOIs = function()
    local pinManager = ZO_WorldMap_GetPinManager()
    if not pinManager then return end

    local activePins = nil
    if pinManager.GetActiveObjects then
        activePins = pinManager:GetActiveObjects()
    elseif pinManager.m_Active then
        activePins = pinManager.m_Active
    end

    if not activePins then return end

    local mapKey = GetMapTileTexture()
    if not mapKey or mapKey == "" then return end
    mapKey = mapKey:lower()

    local db = MOverhaul.db
    if not db then return end
    db.poiCache = db.poiCache or {}
    db.poiCache[mapKey] = {}

    local currentCache = db.poiCache[mapKey]
    local cachedCount = 0
    local totalScanned = 0

    for pinKey, pin in pairs(activePins) do
        if type(pin) == "table" or type(pin) == "userdata" then
            if pin.GetPinType and pin.GetNormalizedPosition then
                local x, y = pin:GetNormalizedPosition()
                if x and x > 0 and y and y > 0 then
                    totalScanned = totalScanned + 1
                    local texture = GetPinTexture(pin)
                    local name = GetPinName(pin)
                    local pinType = pin:GetPinType()
                    local categories = { "bank", "stable", "mages", "fighters", "guildtrader", "wayshrine" }
                    for _, category in ipairs(categories) do
                        if MatchPinCategory(category, texture, name, pinType) then
                            currentCache[category] = currentCache[category] or {}
                            
                            local exists = false
                            for _, cached in ipairs(currentCache[category]) do
                                if math.abs(cached.x - x) < 0.0001 and math.abs(cached.y - y) < 0.0001 then
                                    exists = true
                                    break
                                end
                            end
                            
                            if not exists then
                                table.insert(currentCache[category], { x = x, y = y, name = name })
                                cachedCount = cachedCount + 1
                            end
                        end
                    end
                end
            end
        end
    end
end

function MOverhaul.SetWaypointToNearest(category)
    local mapKey = GetMapTileTexture()
    if not mapKey or mapKey == "" then
        d("[MOverhaul] Nao foi possivel obter o mapa atual.")
        return
    end
    mapKey = mapKey:lower()

    local db = MOverhaul.db
    if not db then return end

    -- Toggle off if same category is clicked again
    if MOverhaul.lastActiveWaypointCategory == category then
        pcall(RemovePlayerWaypoint)
        MOverhaul.lastActiveWaypointCategory = nil
        d("[MOverhaul] Marcador removido.")
        PlaySound(SOUNDS.MAP_PING_REMOVE or SOUNDS.DEFAULT_CLICK)
        return
    end

    db.poiCache = db.poiCache or {}
    local currentCache = db.poiCache[mapKey]

    local foundLocations = {}
    if currentCache and currentCache[category] then
        foundLocations = currentCache[category]
    end

    if #foundLocations == 0 then
        if ZO_WorldMap and not ZO_WorldMap:IsHidden() then
            CacheMapPOIs()
            if currentCache and currentCache[category] then
                foundLocations = currentCache[category]
            end
        end
    end

    if #foundLocations == 0 then
        d("[MOverhaul] Nenhum POI do tipo '" .. category .. "' catalogado para este mapa.")
        d("[MOverhaul] Abra o mapa (M) uma vez nesta cidade para carregar os POIs.")
        return
    end

    local px, py = GetMapPlayerPosition("player")
    if not px or px == 0 then
        d("[MOverhaul] Nao foi possivel obter a posicao do jogador.")
        return
    end

    local nearestPOI = nil
    local minDistance = math.huge

    for _, data in ipairs(foundLocations) do
        local dist = (data.x - px)^2 + (data.y - py)^2
        if dist < minDistance then
            minDistance = dist
            nearestPOI = data
        end
    end

    if nearestPOI then
        local wpPinType = MAP_PIN_TYPE_PLAYER_WAYPOINT or 1
        local mapTypeLoc = MAP_TYPE_LOCATION_CENTERED or 1
        
        pcall(RemovePlayerWaypoint)
        PingMap(wpPinType, mapTypeLoc, nearestPOI.x, nearestPOI.y)
        
        MOverhaul.lastActiveWaypointCategory = category
        
        local pinName = nearestPOI.name or ""
        if pinName == "" then
            pinName = category:upper()
        else
            pinName = pinName:gsub("^%l", string.upper)
        end
        
        d("[MOverhaul] Marcador definido para: " .. pinName)
        PlaySound(SOUNDS.MAP_PING)
    end
end

local function CreateMenuButton(parent, index, item)
    local btn = WINDOW_MANAGER:CreateControl("MOverhaul_POIButton_" .. item.category, parent, CT_CONTROL)
    btn:SetDimensions(32, 32)
    btn:SetMouseEnabled(true)
    btn:SetDrawLevel(2)
    
    local bg = WINDOW_MANAGER:CreateControl(nil, btn, CT_BACKDROP)
    bg:SetAnchorFill()
    bg:SetCenterColor(1, 1, 1, 0.05)
    bg:SetEdgeColor(0, 0, 0, 0)
    bg:SetEdgeTexture("", 8, 1, 1)
    bg:SetDrawLevel(1)
    
    local icon = WINDOW_MANAGER:CreateControl(nil, btn, CT_TEXTURE)
    icon:SetAnchor(CENTER, btn, CENTER, 0, 0)
    icon:SetDimensions(26, 26)
    icon:SetTexture(item.icon)
    icon:SetColor(1, 1, 1, 1)
    icon:SetDrawLevel(2)
    
    btn:SetHandler("OnMouseEnter", function(self)
        bg:SetCenterColor(1, 1, 1, 0.2)
        ZO_Tooltips_ShowTextTooltip(self, TOP, item.name)
    end)
    
    btn:SetHandler("OnMouseExit", function(self)
        bg:SetCenterColor(1, 1, 1, 0.05)
        ZO_Tooltips_HideTextTooltip()
    end)
    
    btn:SetHandler("OnMouseDown", function(self, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            PlaySound(SOUNDS.DEFAULT_CLICK)
            MOverhaul.SetWaypointToNearest(item.category)
        end
    end)
    
    return btn
end

local function CreatePOIFinderMenu()
    if MOverhaul_POIFinderMenu then return end

    local db = MOverhaul.db

    MOverhaul_POIFinderMenu = WINDOW_MANAGER:CreateTopLevelWindow("MOverhaul_POIFinderMenu")
    MOverhaul_POIFinderMenu:SetDimensions(226, 40)

    if db.poiMenuX and db.poiMenuY then
        MOverhaul_POIFinderMenu:ClearAnchors()
        MOverhaul_POIFinderMenu:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, db.poiMenuX, db.poiMenuY)
    else
        MOverhaul_POIFinderMenu:ClearAnchors()
        MOverhaul_POIFinderMenu:SetAnchor(RIGHT, GuiRoot, RIGHT, -50, 0)
    end

    MOverhaul_POIFinderMenu:SetMovable(not db.poiMenuLocked)
    MOverhaul_POIFinderMenu:SetMouseEnabled(true)
    MOverhaul_POIFinderMenu:SetClampedToScreen(true)

    local bg = WINDOW_MANAGER:CreateControl("MOverhaul_POIFinderMenuBG", MOverhaul_POIFinderMenu, CT_BACKDROP)
    bg:SetAnchorFill()
    bg:SetCenterColor(0, 0, 0, 0.4)
    bg:SetEdgeColor(0.2, 0.2, 0.2, 0.4)
    bg:SetEdgeTexture("", 8, 1, 1)
    bg:SetDrawLevel(1)

    -- Create dedicated Drag Handle on the left
    local dragHandle = WINDOW_MANAGER:CreateControl("MOverhaul_POIFinderMenuDrag", MOverhaul_POIFinderMenu, CT_CONTROL)
    dragHandle:SetDimensions(12, 32)
    dragHandle:SetAnchor(LEFT, MOverhaul_POIFinderMenu, LEFT, 4, 0)
    dragHandle:SetMouseEnabled(true)
    dragHandle:SetDrawLevel(2)

    local dragBg = WINDOW_MANAGER:CreateControl(nil, dragHandle, CT_BACKDROP)
    dragBg:SetAnchorFill()
    dragBg:SetCenterColor(1, 1, 1, 0.05)
    dragBg:SetEdgeColor(0, 0, 0, 0)
    dragBg:SetDrawLevel(1)

    local dragText = WINDOW_MANAGER:CreateControl(nil, dragHandle, CT_LABEL)
    dragText:SetAnchor(CENTER, dragHandle, CENTER, 0, 0)
    dragText:SetFont("$(BOLD_FONT)|14|soft-shadow-thin")
    dragText:SetColor(0.6, 0.6, 0.6, 1)
    dragText:SetText("⋮")

    dragHandle:SetHandler("OnMouseEnter", function(self)
        dragBg:SetCenterColor(1, 1, 1, 0.2)
        dragText:SetColor(1, 1, 0, 1)
        ZO_Tooltips_ShowTextTooltip(self, TOP, "Arrastar POI Finder")
    end)

    dragHandle:SetHandler("OnMouseExit", function(self)
        dragBg:SetCenterColor(1, 1, 1, 0.05)
        dragText:SetColor(0.6, 0.6, 0.6, 1)
        ZO_Tooltips_HideTextTooltip()
    end)

    local isDragging = false
    dragHandle:SetHandler("OnMouseDown", function(self, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and not db.poiMenuLocked then
            MOverhaul_POIFinderMenu:StartMoving()
            isDragging = true
        end
    end)

    dragHandle:SetHandler("OnMouseUp", function(self, button)
        if isDragging then
            MOverhaul_POIFinderMenu:StopMovingOrResizing()
            db.poiMenuX = MOverhaul_POIFinderMenu:GetLeft()
            db.poiMenuY = MOverhaul_POIFinderMenu:GetTop()
            isDragging = false
        end
    end)

    -- Anchor buttons horizontally after the drag handle
    local startX = 20
    for i, item in ipairs(POI_MENU_ITEMS) do
        local btn = CreateMenuButton(MOverhaul_POIFinderMenu, i, item)
        btn:ClearAnchors()
        btn:SetAnchor(LEFT, MOverhaul_POIFinderMenu, LEFT, startX, 0)
        startX = startX + 32 + 2
    end

    local menuFragment = ZO_HUDFadeSceneFragment:New(MOverhaul_POIFinderMenu)
    if db.poiMenuEnabled then
        HUD_SCENE:AddFragment(menuFragment)
        HUD_UI_SCENE:AddFragment(menuFragment)
    end
    MOverhaul_POIFinderMenu.fragment = menuFragment
end

local function OnAddOnLoaded(event, addonName)
    if addonName == MOverhaul.name then
        EVENT_MANAGER:UnregisterForEvent(MOverhaul.name, EVENT_ADD_ON_LOADED)
        
        InitializeQuestPinTypes()
        
        MOverhaul.db = ZO_SavedVars:NewAccountWide("MOverhaul_SavedVariables", 1, nil, defaults)
        MOverhaul.db.questCoordsCache = {}

        -- Limpar cache dinamicamente em mudanças de progresso ou conclusão de etapas de quests
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_QuestAdvanced", EVENT_QUEST_ADVANCED, function(eventCode, questIndex, questName)
            if MOverhaul.db and MOverhaul.db.questCoordsCache then
                local uniqueKey = string.format("%d_%s", questIndex, questName)
                MOverhaul.db.questCoordsCache[uniqueKey] = nil
            end
        end)
        EVENT_MANAGER:RegisterForEvent(MOverhaul.name .. "_QuestConditionChanged", EVENT_QUEST_CONDITION_COUNTER_CHANGED, function(eventCode, questIndex, questName)
            if MOverhaul.db and MOverhaul.db.questCoordsCache then
                local uniqueKey = string.format("%d_%s", questIndex, questName)
                MOverhaul.db.questCoordsCache[uniqueKey] = nil
            end
        end)
        

        CreateWaypointArrowControl()
        CreateQuestArrowControl()
        
        if MOverhaul.db.poiMenuEnabled then
            CreatePOIFinderMenu()
        end
        
        UpdateWaypointArrowFragmentVisibility()
        UpdateQuestArrowFragmentVisibility()
        
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
                        UpdateQuestArrowFragmentVisibility()
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
                        UpdateWaypointArrowFragmentVisibility()
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
                {
                    type = "checkbox",
                    name = "Menu POI Finder (Modulo)",
                    tooltip = "Habilita ou desabilita o menu do buscador de POIs na tela.",
                    getFunc = function() return MOverhaul.db.poiMenuEnabled end,
                    setFunc = function(value) 
                        MOverhaul.db.poiMenuEnabled = value 
                        if value then
                            if not MOverhaul_POIFinderMenu then
                                CreatePOIFinderMenu()
                            end
                            if MOverhaul_POIFinderMenu and MOverhaul_POIFinderMenu.fragment then
                                HUD_SCENE:AddFragment(MOverhaul_POIFinderMenu.fragment)
                                HUD_UI_SCENE:AddFragment(MOverhaul_POIFinderMenu.fragment)
                            end
                        else
                            if MOverhaul_POIFinderMenu and MOverhaul_POIFinderMenu.fragment then
                                HUD_SCENE:RemoveFragment(MOverhaul_POIFinderMenu.fragment)
                                HUD_UI_SCENE:RemoveFragment(MOverhaul_POIFinderMenu.fragment)
                            end
                        end
                    end,
                    default = true,
                },
                {
                    type = "checkbox",
                    name = "Bloquear Menu POI",
                    tooltip = "Bloqueia a movimentacao do menu do buscador de POIs na tela para evitar arrastes acidentais.",
                    getFunc = function() return MOverhaul.db.poiMenuLocked end,
                    setFunc = function(value) 
                        MOverhaul.db.poiMenuLocked = value 
                        if MOverhaul_POIFinderMenu then
                            MOverhaul_POIFinderMenu:SetMovable(not value)
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
                    UpdateQuestArrowFragmentVisibility()
                    if MOverhaul.db.quest3DArrowEnabled then
                        d("[MOverhaul] Seta 2D da Quest ATIVADA.")
                    else
                        d("[MOverhaul] Seta 2D da Quest DESATIVADA.")
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
