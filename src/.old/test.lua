local socket = require("socket")

function find_open_port()
    local min_port = 49152
    local max_port = 65535
    local port

    while true do
        port = math.random(min_port, max_port)
        local server = socket.tcp()
        local result, err = server:bind("*", port)

        if result then
            server:close()
            return port
        end
    end
end

math.randomseed(os.time())
local open_port = find_open_port()
print("Open port found: " .. open_port)
