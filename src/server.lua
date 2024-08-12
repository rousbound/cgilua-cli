local socket = require("socket")
local lfs = require"lfs"


local M = {}

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        -- file:close()
        return true
    else
        return false
    end
end

local function read_file(file_path)
    local file = io.open(file_path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function execute_script(script_path, query_string)
    print("executing script:" ..script_path )
    if script_path:match("%.%.") and script_path:match("[/\\]") and not script_path:match("%.lua$") then
        return print"Path trasversal error"
    end
    local command = "./" .. script_path
    if query_string then
        command = command .. " " .. query_string
    end
    local cwd = lfs.currentdir()
    local handle = io.popen("export DOCUMENT_ROOT=" .. cwd .. " && " .. command)
    local result = handle:read("*a")
    handle:close()
    return result
end

local function handle_request(client)
    local request, err = client:receive()
    if not request then
        print("Error receiving request: " .. err)
        return
    end
    local method, path, query_string = request:match("^(%w+)%s+([^?%s]+)%??([^%s]*)%s+HTTP/%d%.%d")
    if method ~= "GET" and method ~= "POST" then
        client:send("HTTP/1.1 405 Method Not Allowed\r\n\r\n")
        return
    end
    path = path:sub(2)
    if path == "" then
        path = "index.lua"
    end

    if path and file_exists(path) then
        if path:match("%.lua$") then
            local response = execute_script(path, query_string)
            if response then
                client:send("HTTP/1.1 200 OK\n"  .. response)
            else
                client:send("HTTP/1.1 403 Forbidden\r\n\r\n")
            end
        else
            local content = read_file(path)
            if content then
                local content_type = "text/plain"
                if path:match("%.html$") then
                    content_type = "text/html"
                elseif path:match("%.css$") then
                    content_type = "text/css"
                elseif path:match("%.js$") then
                    content_type = "application/javascript"
                elseif path:match("%.png$") then
                    content_type = "image/png"
                elseif path:match("%.jpg$") or path:match("%.jpeg$") then
                    content_type = "image/jpeg"
                elseif path:match("%.pdf$") or path:match("%.pdf$") then
                    content_type = "application/pdf"
                end
                client:send("HTTP/1.1 200 OK\r\nContent-Type: " .. content_type .. "\r\n\r\n" .. content)
            else
                client:send("HTTP/1.1 404 Not Found\r\n\r\n")
            end
        end
    else
        print("Path not found:" .. tostring(path))
        client:send("HTTP/1.1 404 Not Found\r\n\r\n")
    end
end

function M.start(port)
    print("HTTP server running on port " .. port)
    local server = assert(socket.bind("*", port))
    local ip, port = server:getsockname()
    while true do
        local client = server:accept()
        client:settimeout(10)
        handle_request(client)
        client:close()
    end
end

return M
