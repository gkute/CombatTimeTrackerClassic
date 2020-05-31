-- Declare AceAddon
CTT = LibStub("AceAddon-3.0"):NewAddon("CTT", "AceConsole-3.0", "AceEvent-3.0")


--|-------------------------|
--| Variable Declarations   |
--|-------------------------|

local time = 0
local fontTableOptions = {}
local bossEncounter = false
local loadOptionsAfterCombat = false
local hours = "00"
local minutes = "00"
local seconds = "00"
local totalSeconds = "00"
local miliseconds = "00"
local fontDropDownMorpheus = 0
local cttElapsedSeconds = 0
local db
local globalMenu
local defaultSavedVars = {
	global = {
		minimap = {
			hide = false,
		},
	},
}

local instanceTypes = {
    "Dungeons Only", 
    "Raids Only",
    "Dungons and Raids Only", 
    "Everywhere"
}

local instanceZones = {
}

local raidInstanceZones = {
    
}

-- Get encounter ID's 
--/run local i=1 while EJ_GetInstanceByIndex(i,true)do local a1,a2=EJ_GetInstanceByIndex(i,true)print(a1,a2)EJ_SelectInstance(a1)i=i+1 local j=1 while EJ_GetEncounterInfoByIndex(j,a1)do local b1,_,b2=EJ_GetEncounterInfoByIndex(j,a1)print(b2,b1)j=j+1 end end

local BoDBosses = {
-- 9 bosses
    2265,
    2263,
    2266,
    2271,
    2268,
    2272,
    2276,
    2280,
    2281
}

local CoSBosses = {
-- 2 bosses
    2269,
    2273
}

local TEPBosses = {
-- 8 bosses
    2298,
    2289,
    2305,
    2304,
    2303,
    2311,
    2293,
    2299
}

local NTWCBosses = {

}

local difficultyList = {
    "LFR",
    "Normal",
    "Heroic",
    "Mythic"
}


--|----------------------------|
--| Ace Library Declarations   |
--|----------------------------|

local L = LibStub("AceLocale-3.0"):GetLocale("cttTranslations")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local db
local icon = LibStub("LibDBIcon-1.0")
local cttLBD = LibStub("LibDataBroker-1.1"):NewDataObject("CombatTimeTracker", {
	type = "data source",
	text = "Combat Time Tracker",
	icon = "Interface\\Icons\\inv_belt_armor_waistoftime_d_01",
    OnClick = function(button, buttonPressed)
        if buttonPressed == "RightButton" then
            if db.minimap.lock then
                icon:Unlock("CombatTimeTracker")
            else
                icon:Lock("CombatTimeTracker")
            end
        elseif buttonPressed == "MiddleButton" then
            icon:Hide("CombatTimeTracker")
            db.minimap.hide = true
            cttMenuOptions.minimapIconCheckButton = true
            CTT.menu.minimapIconCheckButton:SetValue(true)
        else
            CTT_ToggleMenu()
        end
    end,
    OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		tooltip:AddLine("|cffff930fCombat Time Tracker|r")
        tooltip:AddLine("Click to open Options Menu")
        tooltip:AddLine("Middle-Click to hide minimap Button")
        tooltip:AddLine("Right-click to lock Minimap Button")
    end,
})


--|----------------------|
--| AceAddon Functions   |
--|----------------------|

function CTT:OnEnable()
    self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("ENCOUNTER_START", "Encounter_Start")
    self:RegisterEvent("ENCOUNTER_END", "Encounter_End")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

-- Register slash commands for addon.
function CTT:OnInitialize()
    self:RegisterChatCommand('ctt', 'SlashCommands')
    LSM.RegisterCallback(self, "LibSharedMedia_Registered", "UpdateUsedMedia")
    db = LibStub("AceDB-3.0"):New("cttDB", defaultSavedVars).global
    icon:Register("CombatTimeTracker", cttLBD, db.minimap)
    if not db.minimap.hide then
        icon:Show("CombatTimeTracker")
    end
end

-- Handle the initialization of values from nil to 0 first time addon is loaded.
function CTT:ADDON_LOADED()
    if longestMin == nil then
        longestMin = 0
    end

    if longestSec == nil then
        longestSec = 0
    end
    if cttMenuOptions == nil then
        cttMenuOptions = {}
        cttMenuOptions.dropdownValue = 1
        cttMenuOptions.dropdownValue2 = 1
        cttMenuOptions.dropdownValue3 = 1
        cttMenuOptions.lockFrameCheckButton = true
        cttMenuOptions.fontVal = 16
        cttMenuOptions.fontName = "Fonts\\MORPHEUS_CYR.TTF"
        cttMenuOptions.timeTrackerSize = {100,40}
        cttMenuOptions.textFrameSizeSlider = 0
        cttMenuOptions.backDropAlphaSlider = 1
        cttMenuOptions.timeValues = {"00","00","00","00","00"}
        -- cttMenuOptions.difficultyDropDown = 1
    end
    if cttMenuOptions.uiReset == nil then 
        cttMenuOptions.uiReset = true
    end
    if table.getn(cttMenuOptions.timeValues) ~= 5 then
        cttMenuOptions.timeValues = {"00","00","00","00","00"}
    end
    if cttTextFormatOptions == nil or table.getn(cttTextFormatOptions) > 1 then
        cttTextFormatOptions = {"(SS)", "(MM:SS)", "(HH:MM:SS)"}
    end
    if fightLogs == nil then
        fightLogs = {}
        for i=1,36 do
            fightLogs[i] = "00:00"
        end
    end
    CTT_CheckForReload()
    if GetAddOnMetadata("CombatTimeTracker", "Version") >= "2.5" and cttMenuOptions.uiReset then
        CTT_PopUpMessage()
    end

--     local i = 1
--     while EJ_GetInstanceByIndex(i, true) do
--     local instanceId, name = EJ_GetInstanceByIndex(i, true)
--     print(instanceId, name)
--     EJ_SelectInstance(instanceId)
--     i = i+1
    
--     local j = 1
--     while EJ_GetEncounterInfoByIndex(j, instanceId) do
--         local _,_,_,_,_,_,id,_ = EJ_GetEncounterInfoByIndex(j, instanceId)
--         print(id)
--         j = j+1
--     end
-- end

    cttStopwatchGui.elapsed = .05
    cttStopwatchGui:SetScript("OnUpdate", function(self, elapsed)
        cttElapsedSeconds = cttElapsedSeconds + elapsed
        self.elapsed = self.elapsed - elapsed
        if self.elapsed > 0 then return end
        self.elapsed = 0.05
        -- rest of the code here
        if UnitAffectingCombat("player") or bossEncounter then
            --CTT:Print(cttElapsedSeconds)
            local times = GetTime() - time
            local time = cttElapsedSeconds
            totalSeconds = floor(time)
            hours = floor(time/3600)
            minutes = floor((time-floor(time/3600)*3600)/60)
            seconds = floor(time-floor(time/3600)*3600-floor((time-floor(time/3600)*3600)/60)*60)
            miliseconds = floor((time-floor(time/3600)*3600-floor((time-floor(time/3600)*3600)/60)*60-floor(time-floor(time/3600)*3600-floor((time-floor(time/3600)*3600)/60)*60))*100)

            if seconds < 10 then
                --local temp = tostring(seconds)
                seconds = "0" .. seconds
            end
            if minutes < 10 then
                --local temp = tostring(minutes)
                minutes = "0" .. minutes
            end
            if hours < 10 then
                --local temp = tostring(hours)
                hours = "0" .. hours
            end
            if totalSeconds < 10 then
                --local temp = tostring(totalSeconds)
                totalSeconds = "0" .. totalSeconds
            end
            if miliseconds < 10 then
                miliseconds = "0" .. miliseconds
            end

            --cttMenuOptions.timeValues = {hours, minutes, seconds, tonumber(string.format("%02.f", math.floor(times)))}
            CTT_UpdateText(hours, minutes, seconds, miliseconds, cttMenuOptions.dropdownValue, 1)
        end
    end)
end

-- Handle the stopwatch when entering combat.
function CTT:PLAYER_REGEN_DISABLED()
    if not bossEncounter then
        time = GetTime()
        cttElapsedSeconds = 0
        CTT_InstanceTypeDisplay(cttMenuOptions.instanceType)
        --self:Print(L["Entering Combat!"])
    else
        return
    end
end

-- Handle the stopwatch when leaving combat.
function CTT:PLAYER_REGEN_ENABLED()
    if not bossEncounter then
        if loadOptionsAfterCombat then
            CTT_ToggleMenu()
            loadOptionsAfterCombat = false
        end
        --self:Print(L["Leaving Combat!"])
        cttMenuOptions.timeValues = {hours, minutes, seconds, totalSeconds, miliseconds}
        local min = 0
        local sec = 0
        local temp = GetTime() - time
        local tempSec = temp % 60
        if tempSec > 0 then
            sec = tonumber(math.floor(tempSec))
        end
        min = tonumber(string.format("%02.f", math.floor(temp/60)))

        if sec < 10 then
            local temp = tostring(sec)
            sec = "0" .. temp
        end
        if min < 10 then
            local temp = tostring(min)
            min = "0" .. temp
        end
        if tonumber(min) > longestMin then
            longestMin = tonumber(min)
            longestSec = tonumber(sec)
            CTT_DisplayResults(true)
        elseif tonumber(min) == longestMin then
            if tonumber(sec) > longestSec then
                longestMin = tonumber(min)
                longestSec = tonumber(sec)
                CTT_DisplayResults(true)
            else
                CTT_DisplayResults(false)
            end
        else
            CTT_DisplayResults(false)
        end
    else
        return 
    end
end

-- Hook function into ENCOUNTER_START to handle getting the data stored.
function CTT:Encounter_Start(...)
    bossEncounter = true
    local arg1, arg2, arg3, arg4, arg5 = ...
    --CTT:Print(L["Encounter Started!"])
    -- local members = {}
    -- local numMembers = GetNumGroupMembers()
    -- if numMembers > 1 then
    --     for i=1,GetNumGroupMembers(),1 do
    --         members[i] = select(1, GetRaidRosterInfo(i))
    --     end
    -- else
    --     members = {UnitName("player")}
    -- end

    --table.insert(fightLogs, {arg2, arg3, arg4, arg5, members, false})
    time = GetTime()
    cttElapsedSeconds = 0
    CTT_InstanceTypeDisplay(cttMenuOptions.instanceType)
end

-- Hook function into ENOUNTER_END to handle storing the data after a fight ends.
function CTT:Encounter_End(...)
    bossEncounter = false
    if loadOptionsAfterCombat then 
        loadOptionsAfterCombat = false
        CTT_ToggleMenu()
    end
    --CTT:Print(L["Encounter Ended!"])
    local arg1, arg2, arg3, arg4, arg5, arg6 = ...
    local diffIDKey = 0
    if arg6 == 1 then
        for k,v in pairs(BoDBosses) do
            if v == arg2 then
                if arg4 == 14 then 
                    diffIDKey = 9
                elseif arg4 == 15 then
                    diffIDKey = 18 
                elseif arg4 == 16 then 
                    diffIDKey = 27
                end

                local mins,secs = strsplit(":",fightLogs[k + diffIDKey])
                if (mins =="00" and secs == "00") then
                    local text = tostring(minutes..":"..seconds)
                    fightLogs[diffIDKey + k] = text
                else
                    if tonumber(seconds) < tonumber(secs) then
                        if (tonumber(minutes) <= tonumber(mins)) then
                            local text = tostring(minutes..":"..seconds)
                            fightLogs[diffIDKey + k] = text
                        end
                    else
                        if tonumber(minutes) < tonumber(mins) then
                            local text = tostring(minutes..":"..seconds)
                            fightLogs[diffIDKey + k] = text
                        end
                    end
                    break
                end
            end
        end
        CTT_DisplayResultsBosses(arg3, true)
    else
        --local index = table.getn(fightLogs)
        --fightLogs[index][7] = {hours, minutes, seconds, totalSeconds, miliseconds}
        --cttMenuOptions.timeValues = {hours, minutes, seconds, totalSeconds, miliseconds}
        CTT_DisplayResultsBosses(arg3, false)
    end
end


-- event function to handle persistence on the settings of the tracker when the player enters the world
function CTT:PLAYER_ENTERING_WORLD()
    --CTT:Print(GetAddOnMetadata("CombatTimeTracker", "Version"))
    CTT_InstanceTypeDisplay()
    if cttMenuOptions.timeTrackerSize then
        CTT_SetTrackerSizeOnLogin()
    end
    if cttMenuOptions.textColorPicker then
        cttStopwatchGuiTimeText:SetTextColor(cttMenuOptions.textColorPicker[1], cttMenuOptions.textColorPicker[2], cttMenuOptions.textColorPicker[3], cttMenuOptions.textColorPicker[4])
    else
        cttStopwatchGuiTimeText:SetTextColor(255,255,255)
    end
    if cttMenuOptions.lockFrameCheckButton then
        cttStopwatchGui:EnableMouse(false)
    else
        cttStopwatchGui:EnableMouse(true)
    end
    if cttMenuOptions.timeValues then
        hours = cttMenuOptions.timeValues[1]
        minutes = cttMenuOptions.timeValues[2]
        seconds = cttMenuOptions.timeValues[3]
        totalSeconds = cttMenuOptions.timeValues[4]
        miliseconds = cttMenuOptions.timeValues[5]
        CTT_UpdateText(cttMenuOptions.timeValues[1], cttMenuOptions.timeValues[2], cttMenuOptions.timeValues[3], cttMenuOptions.timeValues[5], cttMenuOptions.dropdownValue,1)
    else
        CTT_UpdateText("00","00","00","00",1,1)
    end
end

function CTT:ZONE_CHANGED()
    --[===[@debug@
    --self:Print("Zone_Changed: " .. GetRealZoneText())
    --self:Print("Zone_Changed: " .. GetSubZoneText())
    --@end-debug@]===]
end

function CTT:ZONE_CHANGED_INDOORS()
    --[===[@debug@
    --self:Print("Zone_Changed_Indoors: " .. GetRealZoneText())
    --self:Print("Zone_Changed_Indoors: " .. GetSubZoneText())
    --@end-debug@]===]
end

function CTT:ZONE_CHANGED_NEW_AREA()
    --[===[@debug@
    --self:Print("Zone_Changed_New_Area: " .. GetRealZoneText())
    --@end-debug@]===]
    CTT_InstanceTypeDisplay(cttMenuOptions.instanceType) 
end


-- function to get the position of morpheus font
function CTT:UpdateUsedMedia(event, mediatype, key)
    fontTableOptions = LSM:List("font")
    for k,v in pairs(fontTableOptions) do
        if v == "Morpheus" then
            fontDropDownMorpheus = k
            break
        end
    end
end

-- Slash Command function
function CTT:SlashCommands(input)
    input = string.lower(input)
    local command,value,_ = strsplit(" ", input)
    if command == "" then 
        CTT_ToggleMenu()
    elseif command == "help" then
        CTT:Print("======== Combat Time Tracker ========")
        CTT:Print(L["/ctt - to open the options menu!"])
        CTT:Print(L["/ctt show - to show the tracker if hidden!"])
        CTT:Print(L["/ctt hide - to hide the tracker if shown!"])
        CTT:Print("/ctt reset - reset the time on the tracker(done automatically)!")
        CTT:Print("/ctt longest - print longest fight!")
        CTT:Print(L["/ctt lock -  to lock or unlock the window!"])
        CTT:Print("/ctt resetfull - restore addon to default settings.")
        CTT:Print("=================================")
    elseif command == "reset" then
        cttMenuOptions.timeValues = {"00","00","00","00"}
        CTT_UpdateText(cttMenuOptions.timeValues[1], cttMenuOptions.timeValues[2], cttMenuOptions.timeValues[3], cttMenuOptions.timeValues[5],cttMenuOptions.dropdownValue,1)
        CTT:Print(L["Stopwatch has been reset!"])
    elseif command == "show" then
        cttStopwatchGui:Show()
        CTT:Print(L["Stopwatch is now being shown!"])
    elseif command == "hide" then
        cttStopwatchGui:Hide()
        CTT:Print(L["Stopwatch is now being hidden!"])
    elseif command == "resetfull" then
        longestMin = 0
        longestSec = 0
        fightLogs = {}
        for i=1,36 do
            fightLogs[i] = "00:00"
        end
        --CTT_SetupSavedVariables()
        CTT:Print(L["Combat Time Tracker has been reset to default settings!"])
    elseif command == "longest" then
        CTT:Print("Your longest fight took (MM:SS): "..longestMin..":"..longestSec..".")
    elseif command == "lock" then
        if cttMenuOptions.lockFrameCheckButton then
            cttMenuOptions.lockFrameCheckButton = false
            cttStopwatchGui:EnableMouse(true)
            CTT:Print(L["Tracker has been unlocked!"])
        else
            cttMenuOptions.lockFrameCheckButton = true
            cttStopwatchGui:EnableMouse(false)
            CTT:Print(L["Tracker has been locked!"])
        end
    --[===[@debug@
    elseif command == "debug" then
        CallSimulateBossKill()
    --@end-debug@]===]
    end
    
end


--|--------------------------|
--| Non AceAddon functions --|
--|--------------------------|

-- function to check if a ui reset is needed.
function CTT_CheckForReload()
    if table.getn(fightLogs) < 36 then cttMenuOptions.uiReset = true else cttMenuOptions.uiReset = false end
end

-- function to setup the savedvariables
function CTT_SetupSavedVariables()
    --print(menu.textStyleDropDown)
    -- cttMenuOptions.dropdownValue = 1
    -- ctt.menu.tab.textStyleDropDown:SetText(cttTextFormatOptions[cttMenuOptions.dropdownValue])
    -- CTT.menu.textStyleDropDown:SetValue(1)
    -- cttMenuOptions.timeValues = {"00","00","00","00","00"}
    -- cttMenuOptions.lockFrameCheckButton = true
    -- CTT.menu.lockFrameCheckButton:SetValue(true)
    -- cttMenuOptions.fontVal = 16
    -- cttMenuOptions.fontName = "Fonts\\MORPHEUS_CYR.TTF"
    -- CTT.menu.fontPickerDropDown:SetText("Morpheus")
    -- cttMenuOptions.timeTrackerSize = {100,40}
    -- cttMenuOptions.textColorPicker = {1,1,1,1}
    -- CTT.menu.textColorPicker:SetColor(255,255,255)
    -- cttMenuOptions.textFrameSizeSlider = 0
    -- CTT.menu.textFrameSizeSlider:SetValue(0)
    -- cttMenuOptions.backDropAlphaSlider = 1
    -- CTT.menu.backDropAlphaSlider:SetValue(1)
    -- cttMenuOptions.fontPickerDropDown = false
    -- CTT_SetTrackerSizeOnLogin()
    -- cttStopwatchGuiTimeText:SetTextColor(255,255,255)
    -- CTT_UpdateText(cttMenuOptions.timeValues[1], cttMenuOptions.timeValues[2], cttMenuOptions.timeValues[3], cttMenuOptions.timeValues[5], cttMenuOptions.dropdownValue,1)
end

-- function to handle showing the tracker based on instance type settings
function CTT_InstanceTypeDisplay(key)
    local zone = GetRealZoneText()
    local subZone = GetSubZoneText()

    if key == 1 then
        --Handle dungeons
        for k,v in pairs(instanceZones) do
            if zone == v then
                if not cttStopwatchGui:IsShown() then
                    cttStopwatchGui:Show()
                end
                break
            else
                cttStopwatchGui:Hide()
            end
        end
    elseif key == 2 then
        -- handle raid stuff
        for k,v in pairs(raidInstanceZones) do
            if zone == v then
                if not cttStopwatchGui:IsShown() then
                    cttStopwatchGui:Show()
                end
                break
            else
                cttStopwatchGui:Hide()
            end
        end
    elseif key == 3 then
        -- handle both dungeon and raid stuff

        --Handle dungeons
        for k,v in pairs(instanceZones) do
            if zone == v then
                if not cttStopwatchGui:IsShown() then
                    cttStopwatchGui:Show()
                end
                return
            else
                cttStopwatchGui:Hide()
            end
        end
        -- handle raid stuff
        for k,v in pairs(raidInstanceZones) do
            if zone == v then
                if not cttStopwatchGui:IsShown() then
                    cttStopwatchGui:Show()
                end
                return
            else
                cttStopwatchGui:Hide()
            end
        end
    else
        -- always show
        if not cttStopwatchGui:IsShown() then
            cttStopwatchGui:Show()
        end
        return
    end
end

-- display a popup message
function CTT_PopUpMessage()
    StaticPopupDialogs["NEW_VERSION"] = {
        text = "Combat Time Tracker has been updated, the tracker needs to be reset to work properly!",
        button1 = "Reset Now",
        button2 = "Reset Later",
        OnAccept = function()
            fightLogs = {}
            for i=1,36 do
                fightLogs[i] = "00:00"
            end
            cttMenuOptions.uiReset = false
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show ("NEW_VERSION")
end

-- function to display results on ecounter end or regen enabled
function CTT_DisplayResults(newRecord)
    if cttMenuOptions.dropdownValue == 1 then
        if newRecord then 
            CTT:Print(L["New Record! Fight ended in "] .. cttMenuOptions.timeValues[4] .. "." .. cttMenuOptions.timeValues[5] .. " " .. L["seconds"] .. "!")
        else
            CTT:Print(L["Fight ended in "] .. cttMenuOptions.timeValues[4] .. "." .. cttMenuOptions.timeValues[5] .. " ".. L["seconds"] .. ".")
        end
    elseif cttMenuOptions.dropdownValue == 2 then
        if newRecord then
            CTT:Print(L["New Record! Fight ended in "] .. "(MM:SS.MS): " .. cttMenuOptions.timeValues[2] .. ":" .. cttMenuOptions.timeValues[3] .. "." .. cttMenuOptions.timeValues[5] .. "!")
        else
            CTT:Print(L["Fight ended in "] .. "(MM:SS.MS): " .. cttMenuOptions.timeValues[2] .. ":" .. cttMenuOptions.timeValues[3] .. "." .. cttMenuOptions.timeValues[5] .. ".")
        end
    else
        if newRecord then
            CTT:Print(L["New Record! Fight ended in "] .. "(HH:MM:SS.MS): " .. cttMenuOptions.timeValues[1] .. ":" .. cttMenuOptions.timeValues[2] .. ":" .. cttMenuOptions.timeValues[3] .. "." .. cttMenuOptions.timeValues[5] .. "!")
        else
            CTT:Print(L["Fight ended in "] .. "(HH:MM:SS.MS): " .. cttMenuOptions.timeValues[1] .. ":" .. cttMenuOptions.timeValues[2] .. ":" .. cttMenuOptions.timeValues[3] .. "." .. cttMenuOptions.timeValues[5] .. ".")
        end
    end
end

-- function to fix display results on a boss encounter ending
function CTT_DisplayResultsBosses(bossEncounter, wasAKill)
    if cttMenuOptions.dropdownValue == 1 then
        if wasAKill then
            CTT:Print(L["You have successfully killed "] .. bossEncounter .. " " .. L["after"] .. " " .. totalSeconds .. "." .. miliseconds .. " " .. L["seconds"] .. "!")
        else
            CTT:Print(L["You have wiped on "] .. bossEncounter .. L["after"] .. " " .. totalSeconds .. "." .. miliseconds ..".")
        end
    elseif cttMenuOptions.dropdownValue == 2 then
        if wasAKill then
            CTT:Print(L["You have successfully killed "] .. bossEncounter .. " " .. L["after"] .. " " .. minutes .. ":" .. seconds .. "." .. miliseconds .. "!")
        else
            CTT:Print(L["You have wiped on "] .. bossEncounter .. " " .. L["after"] .. " " .. minutes .. ":" .. seconds .. "." .. miliseconds .. ".")
        end
    else
        if wasAKill then
            CTT:Print(L["You have successfully killed "] .. bossEncounter .. " " .. L["after"] .. " " .. hours .. ":" .. minutes .. ":" .. seconds .. "." .. miliseconds .. ".")
        else
            CTT:Print(L["You have wiped on "] .. bossEncounter .. " " .. L["after"] .. " " .. hours .. ":" .. minutes .. ":" .. seconds .. "." .. miliseconds .. ".")
        end
    end
end

-- function to update the text on the tracker frame
function CTT_UpdateText(hours, minutes, seconds, miliseconds, textFormat, fontUpdate)
    if fontUpdate == 2 then
        cttStopwatchGuiTimeText:SetText("")
    end
    if textFormat == 1 then
        if cttMenuOptions.timeValues then
            cttStopwatchGuiTimeText:SetText(totalSeconds)-- .. "." .. miliseconds)
        else
            cttStopwatchGuiTimeText:SetText(seconds)-- .. "." .. miliseconds)
        end
    elseif textFormat == 2 then
        cttStopwatchGuiTimeText:SetText(minutes .. ":" .. seconds)-- .. "." .. miliseconds)
    else
        cttStopwatchGuiTimeText:SetText(hours .. ":" .. minutes .. ":" .. seconds)-- .. "." .. miliseconds)
    end
end

function CTT_UpdateMenuTexts(container,difficultyNumber)
    if difficultyNumber == 1 then
        difficultyNumber = 0
    elseif difficultyNumber == 2 then
        difficultyNumber = 9
    elseif difficultyNumber == 3 then
        difficultyNumber = 18
    else
        difficultyNumber = 27
    end

    container.CoLTime:SetText(fightLogs[1+difficultyNumber])
    container.GrongTime:SetText(fightLogs[2+difficultyNumber])
    container.MonksTime:SetText(fightLogs[3+difficultyNumber])
    container.OpulenceTime:SetText(fightLogs[4+difficultyNumber])
    container.CouncilTime:SetText(fightLogs[5+difficultyNumber])
    container.KingTime:SetText(fightLogs[6+difficultyNumber])
    container.MekkaTime:SetText(fightLogs[7+difficultyNumber])
    container.StormwallTime:SetText(fightLogs[8+difficultyNumber])
    container.IceBitchTime:SetText(fightLogs[9+difficultyNumber])
end

function CTT_CoSUpdateMenuTexts(container, difficultyNumber)
    if difficultyNumber == 1 then
        difficultyNumber = 0
    elseif difficultyNumber == 2 then
        difficultyNumber = 2
    elseif difficultyNumber == 3 then
        difficultyNumber = 4
    else
        difficultyNumber = 6
    end

    container.CabalTime:SetText(cosFightLogs[1+difficultyNumber])
    container.UunatTime:SetText(cosFightLogs[2+difficultyNumber])
end

function CTT_tepUpdateMenuTexts(container, difficultyNumber)
    if difficultyNumber == 1 then
        difficultyNumber = 0
    elseif difficultyNumber == 2 then
        difficultyNumber = 8
    elseif difficultyNumber == 3 then
        difficultyNumber = 16
    else
        difficultyNumber = 24
    end

    container.ACSTime:SetText(tepFightLogs[1+difficultyNumber])
    container.BBTime:SetText(tepFightLogs[2+difficultyNumber])
    container.RoATime:SetText(tepFightLogs[3+difficultyNumber])
    container.LATime:SetText(tepFightLogs[4+difficultyNumber])
    container.OTime:SetText(tepFightLogs[5+difficultyNumber])
    container.TQCTime:SetText(tepFightLogs[6+difficultyNumber])
    container.ZHoNTime:SetText(tepFightLogs[7+difficultyNumber])
    container.QATime:SetText(tepFightLogs[8+difficultyNumber])
end


--|-----------------------|
--| AceGUI Options Menu --|
--|-----------------------|

-- function to toggle the options menu
function CTT_ToggleMenu()
    if UnitAffectingCombat("player") or bossEncounter then
        loadOptionsAfterCombat = true
        CTT:Print("Options menu cannot be loaded while in combat, try again after combat has ended!")
    else
        if not CTT.menu then CTT:CreateOptionsMenu() end
        if CTT.menu:IsShown() then
            CTT.menu:Hide()
            CTT:Print(L["Options menu hidden, for other commands use /ctt help!"])
        else
            CTT.menu:Show()
            CTT:Print(L["Options menu loaded, for other commands use /ctt help!"])
        end
    end
end

function CTT_LockFrameCheckBoxState(widget, event, value)
    cttMenuOptions.lockFrameCheckButton = value
    if cttMenuOptions.lockFrameCheckButton then
        cttStopwatchGui:EnableMouse(false)
        CTT:Print(L["Tracker has been locked!"])
    else
        cttStopwatchGui:EnableMouse(true)
        CTT:Print(L["Tracker has been unlocked!"])
    end
end

function CTT_ColorPickerConfirmed(widget, event, r, g, b, a)
    cttMenuOptions.textColorPicker = {r,g,b,a}
    cttStopwatchGuiTimeText:SetTextColor(r,g,b,a)
end

function CTT_DropdownState(widget, event, key, checked)
    cttMenuOptions.dropdownValue = key
    CTT_UpdateText(cttMenuOptions.timeValues[1], cttMenuOptions.timeValues[2], cttMenuOptions.timeValues[3], cttMenuOptions.timeValues[5], cttMenuOptions.dropdownValue,1)
end

-- function to handle the sliding of the slider, this fires anytime the slider moves
function CTT_ResizeFrameSliderUpdater(widget, event, value)
    cttMenuOptions.textFrameSizeSlider = value
    local multiplier = value
    local width = 100 + (multiplier * 100)
    local height = 40 + (multiplier * 40)
    local fontVal = 16 + (multiplier * 16)
    cttStopwatchGui:SetWidth(width)
    cttStopwatchGui:SetHeight(height)
    cttStopwatchGuiTimeText:SetSize(width, height)
    if cttMenuOptions.fontName then
        cttStopwatchGuiTimeText:SetFont(cttMenuOptions.fontName,fontVal)
        cttMenuOptions.fontVal = fontVal
    else
        cttStopwatchGuiTimeText:SetFont("Fonts\\MORPHEUS.ttf",fontVal)
        cttMenuOptions.fontVal = fontVal
    end
end

-- function to update the tracker size from user settings on login
function CTT_SetTrackerSizeOnLogin()
    if table.getn(cttMenuOptions.timeTrackerSize) == 2 and cttMenuOptions.fontVal and cttMenuOptions.fontName and cttMenuOptions.backDropAlphaSlider then
        cttStopwatchGui:SetWidth(cttMenuOptions.timeTrackerSize[1])
        cttStopwatchGui:SetHeight(cttMenuOptions.timeTrackerSize[2])
        cttStopwatchGuiTimeText:SetSize(cttMenuOptions.timeTrackerSize[1], cttMenuOptions.timeTrackerSize[2])
        cttStopwatchGuiTimeText:SetFont(cttMenuOptions.fontName,cttMenuOptions.fontVal)
        cttStopwatchGui:SetBackdropColor(0,0,0,cttMenuOptions.backDropAlphaSlider)
        cttStopwatchGui:SetBackdropBorderColor(255,255,255,cttMenuOptions.backDropAlphaSlider)
    else
        cttStopwatchGuiTimeText:SetFont("Fonts\\MORPHEUS.ttf", 16)
        cttMenuOptions.fontVal = fontVal
    end
end

-- SetCallBack function that handles when the person stops sliding the slider
function CTT_ResizeFrameSliderDone(widget, event, value)
    cttMenuOptions.textFrameSizeSlider = value
    cttMenuOptions.timeTrackerSize = {cttStopwatchGui:GetWidth(), cttStopwatchGui:GetHeight()}
end

-- Callback function for the font picker dropdown
function CTT_FontPickerDropDownState(widget, event, key, checked)
    cttMenuOptions.fontPickerDropDown = key
    cttMenuOptions.fontName = LSM:Fetch("font", fontTableOptions[key])
    if table.getn(cttMenuOptions.timeTrackerSize) == 2 and cttMenuOptions.fontVal and cttMenuOptions.fontName then
        cttStopwatchGui:SetWidth(cttMenuOptions.timeTrackerSize[1])
        cttStopwatchGui:SetHeight(cttMenuOptions.timeTrackerSize[2])
        cttStopwatchGuiTimeText:SetSize(cttMenuOptions.timeTrackerSize[1], cttMenuOptions.timeTrackerSize[2])
        cttStopwatchGuiTimeText:SetFont(cttMenuOptions.fontName,cttMenuOptions.fontVal)
        -- cttStopwatchGui:Hide()
        -- cttStopwatchGui:Show()
        CTT_UpdateText(cttMenuOptions.timeValues[1], cttMenuOptions.timeValues[2], cttMenuOptions.timeValues[3], cttMenuOptions.timeValues[5], cttMenuOptions.dropdownValue, 2)
    end
end

-- callback for the backdrop opacity slider while moving
function CTT_BackDropSliderOnValueChanged(widget, event, value)
    cttMenuOptions.backDropAlphaSlider = value
    cttStopwatchGui:SetBackdropColor(0,0,0,value)
    cttStopwatchGui:SetBackdropBorderColor(255,255,255,value)
end

-- callback for the backdrop opacity slider when dont moving
function CTT_BackDropSliderDone(widget, event, value)
    cttMenuOptions.backDropAlphaSlider = value
end

function CTT_MinimapIconCheckButton(widget, event, value)
    cttMenuOptions.minimapIconCheckButton = value
    if cttMenuOptions.minimapIconCheckButton then
        db.minimap.hide = true
        icon:Hide("CombatTimeTracker")
    else
        db.minimap.hide = false
        icon:Show("CombatTimeTracker")
    end
end

function CTT_InstanceTypeDropDown(widget, event, key, checked)
    local zone = GetRealZoneText()
    cttMenuOptions.instanceType = key
    if key ~= 4 then
        CTT_InstanceTypeDisplay(key)
    else
        if cttStopwatchGui:IsShown() then
            return
        else
            cttStopwatchGui:Show()
        end
    end
end

function CTT_DifficultyDropDown(widget, event, key, checked)
    cttMenuOptions.difficultyDropDown = key
    if key == 1 then
        -- TODO LFR times
        CTT_UpdateMenuTexts(menu.tab,key)
    elseif key == 2 then
        -- TODO normal times
        CTT_UpdateMenuTexts(menu.tab,key)
    elseif key == 3 then
        -- TODO heroic times
        CTT_UpdateMenuTexts(menu.tab,key)
    else
        -- TODO mythic times
        CTT_UpdateMenuTexts(menu.tab,key)
    end
end

--|-----------------------|
--| AceGUI Raid Bosses  --|
--|-----------------------|


--function that draws the widgets for the first tab
local function OptionsMenu(container)
    -- frame lock button
    local lockFrameCheckButton = AceGUI:Create("CheckBox")
    lockFrameCheckButton:SetLabel(L["Lock"])
    lockFrameCheckButton:SetWidth(80)
    lockFrameCheckButton:SetHeight(22)
    lockFrameCheckButton:SetType("checkbox")
    lockFrameCheckButton:ClearAllPoints()
    if cttMenuOptions.lockFrameCheckButton then lockFrameCheckButton:SetValue(cttMenuOptions.lockFrameCheckButton)end
    lockFrameCheckButton:SetPoint("TOPLEFT", container.tab, "TOPLEFT",6, 0)
    lockFrameCheckButton:SetCallback("OnValueChanged",CTT_LockFrameCheckBoxState)
    container:AddChild(lockFrameCheckButton)
    container.lockFrameCheckButton = lockFrameCheckButton

    local minimapIconCheckButton = AceGUI:Create("CheckBox")
    minimapIconCheckButton:SetLabel("Hide Minimap")
    minimapIconCheckButton:SetWidth(100)
    minimapIconCheckButton:SetHeight(22)
    minimapIconCheckButton:SetType("checkbox")
    minimapIconCheckButton:ClearAllPoints()
    if cttMenuOptions.minimapIconCheckButton then 
        minimapIconCheckButton:SetValue(cttMenuOptions.minimapIconCheckButton)
    else
        minimapIconCheckButton:SetValue(false)
    end
    minimapIconCheckButton:SetPoint("CENTER", container.tab, "CENTER",6,0)
    --minimapIconCheckButton:SetCallBack("OnValueChanged", CTT_MinimapIconCheckButton)
    minimapIconCheckButton:SetCallback("OnValueChanged",CTT_MinimapIconCheckButton)
    container:AddChild(minimapIconCheckButton)
    container.minimapIconCheckButton = minimapIconCheckButton

    -- color picker
    local textColorPicker = AceGUI:Create("ColorPicker")
    if cttMenuOptions.textColorPicker then 
        textColorPicker:SetColor(cttMenuOptions.textColorPicker[1], cttMenuOptions.textColorPicker[2], cttMenuOptions.textColorPicker[3], cttMenuOptions.textColorPicker[4]) 
    else
        textColorPicker:SetColor(255,255,255)
    end
    textColorPicker:SetLabel(L["Text Color"])
    textColorPicker:ClearAllPoints()
    textColorPicker:SetPoint("TOPLEFT", container.tab, "TOPLEFT", 6, 0)
    textColorPicker:SetCallback("OnValueConfirmed", CTT_ColorPickerConfirmed)
    container:AddChild(textColorPicker)
    container.textColorPicker = textColorPicker

    -- different text options
    local textStyleDropDown = AceGUI:Create("Dropdown")
    textStyleDropDown:SetLabel(L["Text Format"])
    textStyleDropDown:SetWidth(125)
    textStyleDropDown:SetMultiselect(false)
    textStyleDropDown:ClearAllPoints()
    textStyleDropDown:SetList(cttTextFormatOptions)
    textStyleDropDown:SetText(cttTextFormatOptions[cttMenuOptions.dropdownValue])
    textStyleDropDown:SetValue(cttMenuOptions.dropdownValue)
    textStyleDropDown:SetPoint("LEFT", container.tab, "LEFT", 6, 0)
    textStyleDropDown:SetCallback("OnValueChanged", CTT_DropdownState)
    container:AddChild(textStyleDropDown)
    container.textStyleDropDown = textStyleDropDown

    -- slider for changing the size of the tracker and text
    local textFrameSizeSlider = AceGUI:Create("Slider")
    textFrameSizeSlider:SetLabel(L["Tracker Size"])
    textFrameSizeSlider:SetWidth(150)
    textFrameSizeSlider:SetIsPercent(true)
    if cttMenuOptions.textFrameSizeSlider then textFrameSizeSlider:SetValue(cttMenuOptions.textFrameSizeSlider) end
    textFrameSizeSlider:SetSliderValues(0,1,.01)
    textFrameSizeSlider:ClearAllPoints()
    textFrameSizeSlider:SetPoint("LEFT", container.tab, "LEFT", 6, 0)
    textFrameSizeSlider:SetCallback("OnValueChanged", CTT_ResizeFrameSliderUpdater)
    textFrameSizeSlider:SetCallback("OnMouseUp", CTT_ResizeFrameSliderDone)
    container:AddChild(textFrameSizeSlider)
    container.textFrameSizeSlider = textFrameSizeSlider

    -- Slider for the opacity of the backdrop and/or border
    local backDropAlphaSlider = AceGUI:Create("Slider")
    backDropAlphaSlider:SetLabel(L["Backdrop Opacity"])
    backDropAlphaSlider:SetWidth(150)
    backDropAlphaSlider:SetIsPercent(true)
    if cttMenuOptions.backDropAlphaSlider then backDropAlphaSlider:SetValue(cttMenuOptions.backDropAlphaSlider) else backDropAlphaSlider:SetValue(1) end
    backDropAlphaSlider:SetSliderValues(0,1,.01)
    backDropAlphaSlider:ClearAllPoints()
    backDropAlphaSlider:SetPoint("LEFT", container.tab, "LEFT", 6, 0)
    backDropAlphaSlider:SetCallback("OnValueChanged", CTT_BackDropSliderOnValueChanged)
    backDropAlphaSlider:SetCallback("OnMouseUp", CTT_BackDropSliderDone)
    container:AddChild(backDropAlphaSlider)
    container.backDropAlphaSlider = backDropAlphaSlider

    -- Dropdown for different font options
    local fontPickerDropDown = AceGUI:Create("Dropdown")
    fontPickerDropDown:SetLabel(L["Choose Font"])
    fontPickerDropDown:SetWidth(250)
    fontPickerDropDown:SetMultiselect(false)
    fontPickerDropDown:ClearAllPoints()
    fontPickerDropDown:SetList(LSM:List("font"))
    if cttMenuOptions.fontName and cttMenuOptions.fontPickerDropDown then 
        fontPickerDropDown:SetText(fontTableOptions[cttMenuOptions.fontPickerDropDown])
        fontPickerDropDown:SetValue(cttMenuOptions.fontPickerDropDown)
    else
        fontPickerDropDown:SetText("Morpheus")
        fontPickerDropDown:SetValue(fontDropDownMorpheus)
    end
    fontPickerDropDown:SetPoint("LEFT", container.tab, "LEFT", 6, 0)
    fontPickerDropDown:SetCallback("OnValueChanged", CTT_FontPickerDropDownState)
    container:AddChild(fontPickerDropDown)
    container.fontPickerDropDown = fontPickerDropDown

    -- Dropdown for different options to show the tracker
    local instanceType = AceGUI:Create("Dropdown")
    instanceType:SetLabel("Show Tracker When?")
    instanceType:SetWidth(150)
    instanceType:SetMultiselect(false)
    instanceType:ClearAllPoints()
    instanceType:SetList(instanceTypes)
    --TODO add conditionals to display the menu text as needed once list is made
    if cttMenuOptions.instanceType then
        instanceType:SetText(instanceTypes[cttMenuOptions.instanceType])
        instanceType:SetValue(cttMenuOptions.instanceType)
    else
        instanceType:SetText(instanceType[4])
        instanceType:SetValue(4)
    end
    instanceType:SetPoint("LEFT", container.tab, "LEFT", 6, 0)
    instanceType:SetCallback("OnValueChanged", CTT_InstanceTypeDropDown)
    container:AddChild(instanceType)
    container.instanceType = instanceType

    -- local default = AceGUI:Create("Button")
    -- default:SetText("Reset Full")
    -- default:SetWidth(100)
    -- default:ClearAllPoints()
    -- default:SetPoint("BOTTOMLEFT", container.tab, "BOTTOMLEFT", 6, 0)
    -- default:SetCallback("OnClick", CTT_DefaultButtonOnClick)
    -- container:AddChild(default)
    -- container.default = default
end
    
-- function that draws the widgets for the second tab
local function BattleForDazaralor(container)
    -- obj:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy);
    -- obj:SetPoint(point, relativeFrame, relativePoint);
    -- obj:SetPoint(point, ofsx, ofsy);
    -- obj:SetPoint(point);
    -- negative ofsx goes left, positive goes right
    -- negative ofsy goes down, positive goes up

    -- drop down menu (to load difficulty into the window)
    local difficultyDropDown = AceGUI:Create("Dropdown")
    difficultyDropDown:SetLabel(" Instance Difficulty")
    difficultyDropDown:SetFullWidth(true)
    difficultyDropDown:SetMultiselect(false)
    difficultyDropDown:ClearAllPoints()
    difficultyDropDown:SetList(difficultyList)
    if cttMenuOptions.difficultyDropDown then
        difficultyDropDown:SetText(difficultyList[cttMenuOptions.difficultyDropDown])
        difficultyDropDown:SetValue(cttMenuOptions.difficultyDropDown)
    else
        difficultyDropDown:SetText(difficultyDropDown[1])
        difficultyDropDown:SetValue(1)
    end
    difficultyDropDown:SetPoint("RIGHT", container.tab, "LEFT")
    difficultyDropDown:SetCallback("OnValueChanged", CTT_DifficultyDropDown)
    container:AddChild(difficultyDropDown)
    container.difficultyDropDown = difficultyDropDown

    local CoL = AceGUI:Create("Label")
    CoL:SetText("Champion of Light: ")
    CoL:SetColor(255,255,0)
    CoL:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    CoL:SetWidth(112)
    CoL:ClearAllPoints()
    CoL:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(CoL)
    container.CoL = CoL

    local CoLTime = AceGUI:Create("Label")
    CoLTime:SetText(fightLogs[1])
    CoLTime:SetColor(255,255,255)
    CoLTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    CoLTime:ClearAllPoints()
    CoLTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(CoLTime)
    container.CoLTime = CoLTime

    local separator1 = AceGUI:Create("Label")
    separator1:SetFullWidth(true)
    separator1:SetText(" ")
    separator1:ClearAllPoints()
    separator1:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator1)
    container.separator1 = separator1

    local Grong = AceGUI:Create("Label")
    Grong:SetText("Grong: ")
    Grong:SetColor(255,255,0)
    Grong:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Grong:SetWidth(112)
    Grong:ClearAllPoints()
    Grong:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Grong)
    container.Grong = Grong

    local GrongTime = AceGUI:Create("Label")
    GrongTime:SetText(fightLogs[2])
    GrongTime:SetColor(255,255,255)
    GrongTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    GrongTime:ClearAllPoints()
    GrongTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(GrongTime)
    container.GrongTime = GrongTime

    local separator2 = AceGUI:Create("Label")
    separator2:SetFullWidth(true)
    separator2:SetText(" ")
    separator2:ClearAllPoints()
    separator2:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator2)
    container.separator2 = separator2

    local Monks = AceGUI:Create("Label")
    Monks:SetText("Jadefire Masters: ")
    Monks:SetColor(255,255,0)
    Monks:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Monks:SetWidth(112)
    Monks:ClearAllPoints()
    Monks:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Monks)
    container.Monks = Monks

    local MonksTime = AceGUI:Create("Label")
    MonksTime:SetText(fightLogs[3])
    MonksTime:SetColor(255,255,255)
    MonksTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    MonksTime:ClearAllPoints()
    MonksTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(MonksTime)
    container.MonksTime = MonksTime

    local separator3 = AceGUI:Create("Label")
    separator3:SetFullWidth(true)
    separator3:SetText(" ")
    separator3:ClearAllPoints()
    separator3:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator3)
    container.separator3 = separator3

    local Opulence = AceGUI:Create("Label")
    Opulence:SetText("Opulence: ")
    Opulence:SetColor(255,255,0)
    Opulence:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Opulence:SetWidth(112)
    Opulence:ClearAllPoints()
    Opulence:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Opulence)
    container.Opulence = Opulence

    local OpulenceTime = AceGUI:Create("Label")
    OpulenceTime:SetText(fightLogs[4])
    OpulenceTime:SetColor(255,255,255)
    OpulenceTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    OpulenceTime:ClearAllPoints()
    OpulenceTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(OpulenceTime)
    container.OpulenceTime = OpulenceTime

    local separator4 = AceGUI:Create("Label")
    separator4:SetFullWidth(true)
    separator4:SetText(" ")
    separator4:ClearAllPoints()
    separator4:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator4)
    container.separator4 = separator4

    local Council = AceGUI:Create("Label")
    Council:SetText("Conclave of the Chosen: ")
    Council:SetColor(255,255,0)
    Council:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Council:SetWidth(112)
    Council:ClearAllPoints()
    Council:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Council)
    container.Grong = Council

    local CouncilTime = AceGUI:Create("Label")
    CouncilTime:SetText(fightLogs[5])
    CouncilTime:SetColor(255,255,255)
    CouncilTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    CouncilTime:ClearAllPoints()
    CouncilTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(CouncilTime)
    container.CouncilTime = CouncilTime

    local separator5 = AceGUI:Create("Label")
    separator5:SetFullWidth(true)
    separator5:SetText(" ")
    separator5:ClearAllPoints()
    separator5:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator5)
    container.separator5 = separator5

    local King = AceGUI:Create("Label")
    King:SetText("King Rastakhan: ")
    King:SetColor(255,255,0)
    King:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    King:SetWidth(112)
    King:ClearAllPoints()
    King:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(King)
    container.King = King

    local KingTime = AceGUI:Create("Label")
    KingTime:SetText(fightLogs[6])
    KingTime:SetColor(255,255,255)
    KingTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    KingTime:ClearAllPoints()
    KingTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(KingTime)
    container.KingTime = KingTime

    local separator6 = AceGUI:Create("Label")
    separator6:SetFullWidth(true)
    separator6:SetText(" ")
    separator6:ClearAllPoints()
    separator6:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator6)
    container.separator6 = separator6

    local Mekka = AceGUI:Create("Label")
    Mekka:SetText("High Tinker Mekkatorque: ")
    Mekka:SetColor(255,255,0)
    Mekka:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Mekka:SetWidth(112)
    Mekka:ClearAllPoints()
    Mekka:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Mekka)
    container.Mekka = Mekka

    local MekkaTime = AceGUI:Create("Label")
    MekkaTime:SetText(fightLogs[7])
    MekkaTime:SetColor(255,255,255)
    MekkaTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    MekkaTime:ClearAllPoints()
    MekkaTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(MekkaTime)
    container.MekkaTime = MekkaTime

    local separator7 = AceGUI:Create("Label")
    separator7:SetFullWidth(true)
    separator7:SetText(" ")
    separator7:ClearAllPoints()
    separator7:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator7)
    container.separator7 = separator7

    local Stormwall = AceGUI:Create("Label")
    Stormwall:SetText("Stormwall Blockade: ")
    Stormwall:SetColor(255,255,0)
    Stormwall:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    Stormwall:SetWidth(112)
    Stormwall:ClearAllPoints()
    Stormwall:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(Stormwall)
    container.Stormwall = Stormwall

    local StormwallTime = AceGUI:Create("Label")
    StormwallTime:SetText(fightLogs[8])
    StormwallTime:SetColor(255,255,255)
    StormwallTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    StormwallTime:ClearAllPoints()
    StormwallTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(StormwallTime)
    container.StormwallTime = StormwallTime

    local separator8 = AceGUI:Create("Label")
    separator8:SetFullWidth(true)
    separator8:SetText(" ")
    separator8:ClearAllPoints()
    separator8:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(separator8)
    container.separator8 = separator8

    local IceBitch = AceGUI:Create("Label")
    IceBitch:SetText("Lady Jaina Proudmoore: ")
    IceBitch:SetColor(255,255,0)
    IceBitch:SetFont("Fonts\\MORPHEUS_CYR.TTF", 12)
    IceBitch:SetWidth(112)
    IceBitch:ClearAllPoints()
    IceBitch:SetPoint("LEFT", container.tab, "LEFT", 6, 10)
    container:AddChild(IceBitch)
    container.IceBitch = IceBitch

    local IceBitchTime = AceGUI:Create("Label")
    IceBitchTime:SetText(fightLogs[9])
    IceBitchTime:SetColor(255,255,255)
    IceBitchTime:SetFont("Fonts\\MORPHEUS_CYR.TTF", 16)
    IceBitchTime:ClearAllPoints()
    IceBitchTime:SetPoint("LEFT", container.tab, "CENTER", 10, 0)
    container:AddChild(IceBitchTime)
    container.IceBitchTime = IceBitchTime

    CTT_UpdateMenuTexts(container,cttMenuOptions.difficultyDropDown)

end

local function SelectGroup(container, event, group)
    container:ReleaseChildren()
    if group == "options" then
        OptionsMenu(container)
    end
end
function CTT:CreateOptionsMenu()
    -- main menu frame
    menu = AceGUI:Create("Frame")
    menu:SetTitle("Combat Time Tracker Options")
    menu:SetStatusText(GetAddOnMetadata("CombatTimeTrackerClassic", "Version"))
    menu:SetWidth(500)
    menu:SetHeight(500)
    menu:SetLayout("Fill")
    -- menu:SetCallBack("OnGroupSelected", CTT_SelectGroup)
    menu:Hide()
    CTT.menu = menu

    CTT_menu = menu.frame
    menu.frame:SetMaxResize(500, 500)
    menu.frame:SetMinResize(500, 500)
    menu.frame:SetFrameStrata("HIGH")
    menu.frame:SetFrameLevel(1)

    -- Create the TabGroup
    local tab =  AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    -- Setup which tabs to show
    tab:SetTabs({{text="Options", value="options"}})
    -- Register callback
    tab:SetCallback("OnGroupSelected", SelectGroup)
    -- Set initial Tab (this will fire the OnGroupSelected callback)
    tab:SelectTab("options")
    
    -- add to the frame container
    menu:AddChild(tab)
    menu.tab = tab
end


--|-----------------------|
--|  CTT Debug Functions  |
--|-----------------------|

--[===[@debug@
--@end-debug@]===]

--[===[@debug@

function SimulateBossKill(arg6,arg2,arg3,arg4,testSec,testMin,savedSec,savedMin)
    local diffIDKey = 0
    if arg6 == 1 then
        CTT:Print("Starting To Check BoD Bosses")
        for k,v in pairs(BoDBosses) do
            if v == arg2 then
                if arg4 == 14 then 
                    diffIDKey = 9
                elseif arg4 == 15 then
                    diffIDKey = 18 
                elseif arg4 == 16 then 
                    diffIDKey = 27
                end
                if (savedMin=="00" and savedSec=="00") then
                    --fightLogs[diffIDKey + k] = text
                    CTT:Print("First Kill Recorded")
                else
                    local mins,secs = strsplit(":",fightLogs[k + diffIDKey])

                    if tonumber(testSec) < tonumber(savedSec) then
                        if (tonumber(testMin) <= tonumber(savedMin)) then
                            CTT:Print("Seconds was lower.")
                            local text = tostring(testMin..":"..testSec)
                            CTT:Print("Fight was shorter because of seconds, recorded new fight of length: "..text)
                        end
                    elseif tonumber(testMin) < tonumber(savedMin) then
                        CTT:Print("Minutes was lower.")
                        local text = tostring(testMin..":"..testSec)
                        CTT:Print("Fight was shorter because of minutes, recorded new fight of length: "..text)
                    else
                        CTT:Print("The new kill was slower than the saved kill.")
                    end
                end
                break
            end
        end

        CTT:Print("Starting To Check COS Bosses")
        for k,v in pairs(CoSBosses) do
            if v == arg2 then
                if arg4 == 14 then 
                    diffIDKey = 2
                elseif arg4 == 15 then
                    diffIDKey = 4 
                elseif arg4 == 16 then 
                    diffIDKey = 6
                end
                if (savedMin=="00" and savedSec=="00") then
                    --fightLogs[diffIDKey + k] = text
                    CTT:Print("First Kill Recorded")
                else
                    local mins,secs = strsplit(":",fightLogs[k + diffIDKey])

                    if tonumber(testSec) < tonumber(savedSec) then
                        if (tonumber(testMin) <= tonumber(savedMin)) then
                            CTT:Print("Seconds was lower.")
                            local text = tostring(testMin..":"..testSec)
                            CTT:Print("Fight was shorter because of seconds, recorded new fight of length: "..text)
                        end
                    elseif tonumber(testMin) < tonumber(savedMin) then
                        CTT:Print("Minutes was lower.")
                        local text = tostring(testMin..":"..testSec)
                        CTT:Print("Fight was shorter because of minutes, recorded new fight of length: "..text)
                    else
                        CTT:Print("The new kill was slower than the saved kill.")
                    end
                end
                break
            end
        end
        CTT:Print("Starting To Check TEP Bosses")
        for k,v in pairs(TEPBosses) do
            if v == arg2 then
                if arg4 == 14 then 
                    diffIDKey = 8
                elseif arg4 == 15 then
                    diffIDKey = 16
                elseif arg4 == 16 then 
                    diffIDKey = 24
                end
                if (savedMin=="00" and savedSec=="00") then
                    --fightLogs[diffIDKey + k] = text
                    CTT:Print("First Kill Recorded")
                else
                    local mins,secs = strsplit(":",fightLogs[k + diffIDKey])

                    if tonumber(testSec) < tonumber(savedSec) then
                        if (tonumber(testMin) <= tonumber(savedMin)) then
                            CTT:Print("Seconds was lower.")
                            local text = tostring(testMin..":"..testSec)
                            CTT:Print("Fight was shorter because of seconds, recorded new fight of length: "..text)
                        end
                    elseif tonumber(testMin) < tonumber(savedMin) then
                        CTT:Print("Minutes was lower.")
                        local text = tostring(testMin..":"..testSec)
                        CTT:Print("Fight was shorter because of minutes, recorded new fight of length: "..text)
                    else
                        CTT:Print("The new kill was slower than the saved kill.")
                    end
                end
                break
            end
        end
        
        CTT_DisplayResultsBosses(arg3, true)
    else
        --local index = table.getn(fightLogs)
        --fightLogs[index][7] = {hours, minutes, seconds, totalSeconds, miliseconds}
        --cttMenuOptions.timeValues = {hours, minutes, seconds, totalSeconds, miliseconds}
        CTT_DisplayResultsBosses(arg3, false)
    end
end

function CallSimulateBossKill()
    -- 5:50 (new kill)  vs 4:50 (saved kill) - fail
    -- 4:45 (new kill)  vs 4:50 (saved kill) - succeed (seconds)
    -- 5:50 (new kill)  vs 6:50 (saved kill) - succeed (minute)
    -- 5:50 (new kill)  vs 5:50 (saved kill) - ??
    -- 5:50 (new kill)  vs 00:00 (saved kill)- succeed (first kill)

    CTT:Print("Test 1 starting: ")
    SimulateBossKill(1, 2263, "Grong", 14, 50, 5, 50, 4)
    CTT:Print("Test 2 starting: ")
    SimulateBossKill(1, 2263, "Grong", 14, 45, 4, 50, 4)
    CTT:Print("Test 3 starting: ")
    SimulateBossKill(1, 2263, "Grong", 14, 50, 5, 50, 6)
    CTT:Print("Test 4 starting: ")
    SimulateBossKill(1, 2263, "Grong", 14, 50, 5, 50, 5)
    CTT:Print("Test 5 starting: ")
    SimulateBossKill(1, 2361, "Queen Azshara", 14, 50, 5, "00", "00")

end

--@end-debug@]===]
