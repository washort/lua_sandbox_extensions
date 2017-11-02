-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--[[
Monitors Parquet output plugin for errors, alerting when they pass a given threshold.

```lua
filename = 'parquet_output_error_monitor.lua'
message_matcher = 'Fields[Type] == "hindsight.plugins"'
ticker_interval = 60
preserve_data = false

alert = {
  disabled = false,
  prefix = true,
  throttle = 1440, -- once a day
  modules = {
    email = {recipients = {"trink@mozilla.com"}},
  },

  thresholds = {
    "output.s3_parquet" = {
      percent = 1 -- alert if more than 1% of outputs cause an error
      number = 100 -- alert if there are more than 100 errors reported at once
    }
  }
}
```
--]]
local alert      = require "heka.alert"
local thresholds = read_config("alert").thresholds

for k, t in pairs(thresholds) do
    if t.number then
        assert(type(t.number) == "number" and t.number > 0,
               string.format("alert: \"%s\".number must contain a number of message failures", k))
    end
    if t.percent then
        assert(type(t.percent) == "number" and t.percent > 0 and t.percent <= 100,
               string.format("alert: \"%s\".percent must contain a percentage of message failures (1-100)", k))
    end
end

local columns = {
    ["Inject Message Count"] = 0,
    ["Inject Message Bytes"] = 1,
    ["Process Message Count"] = 2,
    ["Process Message Failures"] = 3,
    ["Current Memory"] = 4,
    ["Max Memory"] = 5,
    ["Max Output"] = 6,
    ["Max Instructions"] = 7,
    ["Message Matcher Avg (ns)"] = 8,
    ["Message Matcher SD (ns)"] = 9,
    ["Process Message Avg (ns)"] = 10,
    ["Process Message SD (ns)"] = 11,
    ["Timer Event Avg (ns)"] = 12,
    ["Timer Event SD (ns)"] = 13
}


function process_message()
    for k, t in pairs(thresholds) do
        local ff = "Fields[" .. k .. "]"
        local count = tonumber(read_message(ff, nil, columns["Process Message Count"]))
        local fails = tonumber(read_message(ff, nil, columns["Process Message Failures"]))
        local fail_percent = fails / count * 100
        if t["number"] and fails > t["number"] then
            alert.send(k, "number", string.format("%d recent messages failed", fails))
        end
        if t["percent"] and fail_percent > t["percent"] then
            alert.send(k, "percent", string.format("%g%% of recent messages failed", fail_percent))
        end
    end
    return 0
end

function timer_event()
end
