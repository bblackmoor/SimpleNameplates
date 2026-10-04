-- Simple Nameplates: one rendering policy for all styled plate text.
local _, ns = ...

function ns.FontFlags(outlined)
    if ns.GetAppearanceSetting("useSlugRendering") == true then
        return outlined and "SLUG,OUTLINE" or "SLUG"
    end
    return outlined and "THICKOUTLINE" or ""
end
