-- Simple Nameplates: optional Total RP 3 integration.
--
-- This file is the single boundary between Simple Nameplates and TRP3. Future
-- display options should normalize public TRP3 profile data here rather than
-- exposing TRP3's data structures throughout the nameplate code.

local _, ns = ...

local TRP3 = {}
local ROLEPLAY_STATUS_OUT_OF_CHARACTER = 2

local function CleanText(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return nil end
    return value
end

function TRP3.IsAvailable()
    return type(TRP3_API) == "table"
        and type(TRP3_API.utils) == "table"
        and type(TRP3_API.utils.str) == "table"
        and type(TRP3_API.utils.str.getUnitID) == "function"
        and type(TRP3_API.register) == "table"
        and type(TRP3_API.register.getUnitIDCurrentProfileSafe) == "function"
end

function TRP3.IsEnabled()
    return ns.GetTRP3Enabled() == true
end

function TRP3.ShouldDisplayProfileInfo()
    return TRP3.IsEnabled() and TRP3.IsAvailable()
end

function TRP3.GetKnownProfile(unitToken)
    if not TRP3.ShouldDisplayProfileInfo() then return nil end

    local characterID = TRP3_API.utils.str.getUnitID(unitToken)
    if not characterID then return nil end

    local profile = TRP3_API.register.getUnitIDCurrentProfileSafe(characterID)
    if type(profile) ~= "table" or next(profile) == nil then return nil end
    return profile, characterID
end

function TRP3.GetDisplayInfo(unitToken)
    local profile, characterID = TRP3.GetKnownProfile(unitToken)
    if not profile then return nil end

    local characteristics = type(profile.characteristics) == "table" and profile.characteristics or {}
    local character = type(profile.character) == "table" and profile.character or {}
    local firstName = CleanText(characteristics.FN)
    local lastName = CleanText(characteristics.LN)
    local roleplayingName

    if firstName and lastName then
        roleplayingName = firstName .. " " .. lastName
    elseif firstName then
        roleplayingName = firstName
    elseif lastName then
        local unitName = ns.AccessibleValue(UnitName(unitToken))
        roleplayingName = unitName and (unitName .. " " .. lastName) or lastName
    end

    return {
        characterID = characterID,
        roleplayingName = roleplayingName,
        shortTitle = CleanText(characteristics.TI),
        fullTitle = CleanText(characteristics.FT),
        isOutOfCharacter = character.RP == ROLEPLAY_STATUS_OUT_OF_CHARACTER,
    }
end

function TRP3.Refresh()
    if ns.RefreshAll then ns.RefreshAll() end
end

ns.TRP3 = TRP3
