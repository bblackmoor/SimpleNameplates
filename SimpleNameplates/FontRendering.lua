-- Simple Nameplates: thin outlines on all styled plate text.
local _, ns = ...

function ns.FontFlags()
    return ns.GetAppearanceSetting("useSlugRendering") == true and "SLUG,OUTLINE" or "OUTLINE"
end
