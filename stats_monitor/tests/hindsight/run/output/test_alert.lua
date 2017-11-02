alerts = {}
function process_message()
    local raw = read_message("raw")
    local msg = decode_message(raw)
    alerts[msg.Fields[2].value[1]] = msg.Payload
    return 0
end
ticks = 0
function timer_event(ns)
    if ticks == 3 then
        assert(alerts["percent"] == "10% of recent messages failed")
        assert(alerts["number"] == "10 recent messages failed")
        print("success")
    end
    ticks = ticks + 1
end
