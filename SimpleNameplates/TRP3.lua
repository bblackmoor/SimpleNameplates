-- Simple Nameplates: optional Total RP 3 integration.
--
-- This file is the single boundary between Simple Nameplates and TRP3. Future
-- display options should normalize public TRP3 profile data here rather than
-- exposing TRP3's data structures throughout the nameplate code.

local _, ns = ...

local TRP3 = {}

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

-- Future profile-name, title, status, icon, or other display choices belong
-- here. Until one is selected, Simple Nameplates deliberately changes no text.
function TRP3.GetDisplayInfo(unitToken)
    local profile, characterID = TRP3.GetKnownProfile(unitToken)
    if not profile then return nil end

    return {
        characterID = characterID,
        profile = profile,
    }
end

function TRP3.Refresh()
    if ns.RefreshAll then ns.RefreshAll() end
end

ns.TRP3 = TRP3
