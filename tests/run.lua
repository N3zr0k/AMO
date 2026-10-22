-- luacheck: ignore 111 113 122 143 432
-- Kleiner Testlauf ohne Fremdbibliothek. Jeder Test steht in tests/test_*.lua und ruft
-- test("Name", function() ... end) auf.
local dir = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = dir .. "/?.lua;" .. package.path

local stub = require("wowstub")
local format = string.format
local passed, failed = 0, 0
local failures = {}

function test(name, func)
    stub.reset()
    local ok, err = xpcall(func, debug.traceback)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        failures[#failures + 1] = name .. "\n" .. tostring(err)
    end
end

function eq(actual, expected, message)
    if actual ~= expected then
        error(format("%s: erwartet %s, bekommen %s", message or "Wert", tostring(expected), tostring(actual)), 2)
    end
end

function near(actual, expected, message)
    if math.abs(actual - expected) > 1e-9 then
        error(format("%s: erwartet %s, bekommen %s", message or "Wert", expected, actual), 2)
    end
end

local files = {}
local list = io.popen('ls "' .. dir .. '"/test_*.lua')
for file in list:lines() do files[#files + 1] = file end
list:close()
table.sort(files)

for _, file in ipairs(files) do dofile(file) end

for _, text in ipairs(failures) do print("FEHLER: " .. text .. "\n") end
print(format("%d bestanden, %d fehlgeschlagen", passed, failed))
os.exit(failed == 0 and 0 or 1)
