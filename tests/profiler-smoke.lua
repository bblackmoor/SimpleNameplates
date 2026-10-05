-- Deterministic timings, transparent calls, and session lifecycle.
local output, now, clockReads, memoryReads, updates = {}, 0, 0, 0, 0
local originalPrint = print
function print(message) output[#output + 1] = message end
function GetTimePreciseSec() clockReads = clockReads + 1; return now end
function UpdateAddOnMemoryUsage() updates = updates + 1 end
function GetAddOnMemoryUsage(name)
    assert(name == "SimpleNameplates")
    memoryReads = memoryReads + 1
    return memoryReads == 1 and 100 or 90
end
local ns = {AccessibleNumber = function(value) if type(value) == "number" then return value end end}
assert(loadfile("SimpleNameplates/Profiler.lua"))("SimpleNameplates", ns)
local p = ns.Profiler
local function Contains(text)
    for _, line in ipairs(output) do if line:find(text, 1, true) then return true end end
    error("Missing report: " .. text)
end
local function Pack(...) return {n = select('#', ...), ...} end
local marker = {}
local child = p.Wrap("Child", function(...) now = now + 0.002; return ... end)
local parent = p.Wrap("Parent", function(...) local result = Pack(child(...)); now = now + 0.003; return table.unpack(result, 1, result.n) end)
local result = Pack(parent(nil, marker, false, nil))
assert(result.n == 4 and result[2] == marker and result[3] == false)
assert(clockReads == 0 and memoryReads == 0 and updates == 0, "disabled path performs no measurement")
p.Command("report"); Contains("No profiling session")
p.Command("start")
local startReads = memoryReads
p.Command("start"); assert(memoryReads == startReads, "duplicate start does not reset")
result = Pack(parent(nil, marker, false, nil))
assert(result.n == 4 and result[2] == marker and result[3] == false)
p.Command("report")
Contains("Parent: 1 calls; 5.000 ms total; 5.000 ms average; 5.000 ms longest")
Contains("Child: 1 calls; 2.000 ms total")
assert(memoryReads == 1, "running reports do not scan memory")
local failure = {}
local broken = p.Wrap("Failure", function() now = now + 0.001; error(failure) end)
local ok, err = pcall(broken); assert(not ok and err == failure, "original error object preserved")
p.Command("stop"); p.Command("report")
Contains("Failure: 1 calls; 1.000 ms total")
Contains("100.0 -> 90.0 KiB (-10.0 KiB)")
local reads = clockReads
parent(); p.Command("stop"); p.Command("report")
assert(clockReads == reads and memoryReads == 2, "stopped calls/reports perform no measurements")
output = {}; p.Command("start"); p.Command("report"); Contains("No measured calls yet")
-- Finishing a call after stop/restart cannot pollute the next session.
local transition = p.Wrap("Transition", function() p.Command("stop"); p.Command("start") end)
transition(); output = {}; p.Command("report"); Contains("No measured calls yet")
p.Command("stop")
GetTimePreciseSec = nil; output = {}; p.Command("start"); Contains("requires a readable precise timer")
GetTimePreciseSec = function() return 0/0 end
output = {}; p.Command("start"); Contains("requires a readable precise timer")
GetTimePreciseSec = function() return now end
UpdateAddOnMemoryUsage = function() error("unavailable") end
output = {}; p.Command("start"); parent(); p.Command("stop"); p.Command("report")
Contains("Addon memory readings unavailable")
Contains("Parent: 1 calls")
p.Command("invalid"); Contains("/snp perf start | stop | report")
print = originalPrint
print("Profiler smoke: passed")
