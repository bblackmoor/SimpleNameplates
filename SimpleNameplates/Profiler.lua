-- Opt-in, session-only timings. No clocks or allocations on the disabled path.
local addonName, ns = ...
local active, last
local unpackValues = unpack or table.unpack
local function Pack(...) return {n = select("#", ...), ...} end
local function Finite(value)
    value = ns.AccessibleNumber(value)
    if value and value == value and value ~= math.huge and value ~= -math.huge then return value end
end
local function Clock()
    if type(GetTimePreciseSec) ~= "function" then return end
    return Finite(GetTimePreciseSec())
end
local function Memory()
    if type(UpdateAddOnMemoryUsage) ~= "function" or type(GetAddOnMemoryUsage) ~= "function" then return end
    local ok = pcall(UpdateAddOnMemoryUsage)
    if not ok then return end
    local read, value = pcall(GetAddOnMemoryUsage, addonName)
    if read then return Finite(value) end
end
local function Say(message) print("|cff0cd29fSimple Nameplates:|r " .. message) end
local function Wrap(label, callback)
    return function(...)
        local session = active
        if not session then return callback(...) end
        local started = Clock()
        local result = Pack(pcall(callback, ...))
        local finished = Clock()
        -- Calls spanning stop/restart must not alter a frozen or new session.
        if active == session and started and finished then
            local duration = math.max(0, (finished - started) * 1000)
            local row = session.stats[label]
            if not row then
                row = {calls = 0, total = 0, maximum = 0}
                session.stats[label] = row
            end
            row.calls = row.calls + 1
            row.total = row.total + duration
            row.maximum = math.max(row.maximum, duration)
        end
        if not result[1] then error(result[2], 0) end
        return unpackValues(result, 2, result.n)
    end
end
local function Start()
    if active then Say("Profiling is already running."); return end
    local memory = Memory()
    local started = Clock()
    if not started then Say("Profiling requires a readable precise timer."); return end
    active = {started = started, memoryStart = memory, stats = {}}
    last = active
    Say("Profiling started. Use /snp perf stop, then /snp perf report.")
end
local function Stop()
    if not active then Say("Profiling is not running."); return end
    local session = active
    active = nil
    session.finished = Clock() or session.started
    session.memoryEnd = Memory()
    Say("Profiling stopped. Use /snp perf report.")
end
local function Report()
    if not last then Say("No profiling session. Use /snp perf start."); return end
    local finished = last.finished or Clock() or last.started
    Say(("Profiling %s; %.1f seconds elapsed."):format(active and "running" or "stopped",
        math.max(0, finished - last.started)))
    Say("Inclusive timings overlap; do not sum them. Measurement adds overhead.")
    local labels = {}
    for label in pairs(last.stats) do labels[#labels + 1] = label end
    table.sort(labels, function(a, b)
        local left, right = last.stats[a].total, last.stats[b].total
        if left == right then return a < b end
        return left > right
    end)
    if #labels == 0 then Say("No measured calls yet.") end
    for _, label in ipairs(labels) do
        local row = last.stats[label]
        Say(("%s: %d calls; %.3f ms total; %.3f ms average; %.3f ms longest.")
            :format(label, row.calls, row.total, row.total / row.calls, row.maximum))
    end
    if last.memoryStart and last.memoryEnd then
        Say(("Addon memory: %.1f -> %.1f KiB (%+.1f KiB).")
            :format(last.memoryStart, last.memoryEnd, last.memoryEnd - last.memoryStart))
        Say("Memory includes profiler/shared-library attribution and garbage collection; not per-function allocations.")
    elseif active and last.memoryStart then
        Say(("Addon memory at start: %.1f KiB; stop to capture the end reading."):format(last.memoryStart))
    else Say("Addon memory readings unavailable.") end
end
local function Command(argument)
    if argument == "start" then Start()
    elseif argument == "stop" then Stop()
    elseif argument == "report" or argument == "" then Report()
    else Say("/snp perf start | stop | report") end
end
ns.Profiler = {Wrap = Wrap, Command = Command}
