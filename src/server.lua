local socket = require("socket")
local lfs = require"lfs"
local urlcode = require"cgilua.urlcode"


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


local function execute_script(script_path, query_string, post_data, method, content_length, content_type)
    script_path = script_path == "/" and "main.lua" or script_path
    print("executing script:" ..script_path )
    -- if script_path:match("%.%.") and script_path:match("[/\\]") and not script_path:match("%.lua$") then
    --     return print"Path trasversal error"
    -- end
    -- if query_string then
    --     command = command .. " arg=1"-- .. query_string
    -- end
    local cwd = lfs.currentdir()
    -- local handle = io.popen("export QUERY_STRING='" .. query_string ..  "' && export POST_STRING='"..(post_data or "") .."' && export DOCUMENT_ROOT=" .. cwd .. " && " .. command .. " " .. (post_data or ""))
    -- local method = post_data and "POST" or "GET"
    local vars = {
        CONTENT_LENGTH = content_length,
        CONTENT_TYPE = content_type,
        REQUEST_METHOD = method,
        QUERY_STRING = query_string,
        DOCUMENT_ROOT = cwd
    }
    local ivars ={}
    for k,v in pairs(vars) do
        table.insert(ivars, "export " .. k .. "='" .. v .. "'")
    end
    local exports = table.concat(ivars, " && ")
    -- local cmd = exports .. " && " ..post_data .. " ./"..script_path
    local cmd = exports .. " && "
    if method == "POST" then
        cmd = cmd .. " " .. "echo -n '" .. post_data .. "' | "
    end
    cmd = cmd .. " ./" .. script_path
    print("CGI command:" .. cmd)
    local handle, err = io.popen(cmd)
    assert(handle, err)

    local result = handle:read("*a")
    print("Result:"  .. (result or ""))
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
    path = urlcode.unescape(path)

    local headers = {}
    while true do
        local line, err = client:receive()
        if not line or line == "" then break end
        local key, value = line:match("^(.-):%s*(.*)")
        if key and value then
            headers[key:lower()] = value
        end
    end

    local post_data = nil
    local content_length, content_type
    if method == "POST" then
        content_length = tonumber(headers["content-length"])
        if content_length then
            post_data = client:receive(content_length)
        end
        content_type = headers["content-type"]
    end

    print("Method:", method)
    print("Path:", path)
    print("Query String:", query_string)
    if post_data then
        print("POST Data:", post_data or "No POST data")
        print("Content Length:", content_length or "")
    end

    print(path, query_string)
    if path and file_exists(path) then
        if path:match("%.lua") then
            local response = execute_script(path, query_string, post_data, method, content_length, content_type)
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
                elseif path:match("%.svg$") or path:match("%.svg$") then
                    content_type = "image/svg+xml"
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
