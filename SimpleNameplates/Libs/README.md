# Bundled libraries

LibCustomGlow-1.0, minor revision 25, from https://github.com/Stanzilla/LibCustomGlow/blob/master/LibCustomGlow-1.0.lua.
Upstream source blob: `c7a328ade1d9a4a026d704d812a0250ebd373212`.
MIT license retained in `LibCustomGlow-1.0/LICENSE`, including upstream attribution in the source.

LibStub 2 (upstream revision 103), from https://github.com/lua-wow/LibStub/blob/master/LibStub.lua.
Upstream source blob: `7e9b5cd15277d750ef2f106bca3999c306044f03`.
Public-domain notice retained in the source.

LibSharedMedia-3.0, minor 12000001 (12.0.0 v1, upstream revision 164), from
https://github.com/SquizzCheeze/Squizzumables/blob/master/Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua.
Source blob: `722962c74661f8b96df757ed25aa54b8ea2f0ff2`.
Canonical project: https://www.wowace.com/projects/libsharedmedia-3-0.
LGPL v2.1 license retained in `LibSharedMedia-3.0/LICENSE` and source attribution retained.
The library contains a media registry and references to Blizzard assets, not external font files.

CallbackHandler-1.0, minor 8 (upstream revision 25), from
https://github.com/WoWUIDev/Ace3/blob/master/CallbackHandler-1.0/CallbackHandler-1.0.lua.
Source blob: `05fb9d2276dd45bd784ecc64672ca4fec0e96612`.
Ace3 distribution license retained in `CallbackHandler-1.0/LICENSE`.

Library whitespace is normalized. Library behavior is unchanged.
Libraries use LibStub version arbitration to coexist with other addons' copies.

DetailsFramework-1.0, minor 762, from
https://github.com/Tercioo/Details-Framework/tree/653af57120e1287be784d468324590a9c150ae98.
The complete upstream `load.xml` chain is embedded in `DetailsFramework/`:
52 Lua scripts and 9 XML manifests, plus the LGPL-2.1-or-later `LICENSE`.
Source provenance and upstream blob hashes are recorded in `DetailsFramework/UPSTREAM.json`.
Only whitespace is normalized (see UPSTREAM.json); no library behavior is patched.
The upstream standalone TOC, examples and documentation are not loaded or bundled.
Existing LibStub, CallbackHandler and LibSharedMedia load first. No Ace framework,
profile scaffold or optional DF helper dependencies are used by our adapter.
`SettingsWidgets.lua` supplies Blizzard textures instead of Details image paths
for its controls; Details and Plater are not required. Colors uses the adapter
as of 1.0.152. Other pages retain their legacy controls, and the existing layout
helpers in `SettingsControls.lua` remain shared during the conversion.
