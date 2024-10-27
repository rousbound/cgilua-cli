local socket = require("socket")
local lfs = require"lfs"
-- local table = require"luar.table"
local urlcode = require"cgilua.urlcode"

local M = {}

local function file_exists(path)
    local attr = lfs.attributes(path)
    return attr ~= nil and attr.mode == "file"
end

local function read_file(file_path)
    local file = io.open(file_path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end


local allowed_methods = {
    GET = 1, POST = 1, PATCH = 1,
    HEAD = 1, PUT = 1, DELETE = 1,
    CONNECT = 1, OPTIONS = 1, TRACE = 1,
}

-- Define a table with pattern matches for content types
local content_types = {
    -- Text/HTML-related formats
    { pattern = "%.html?$", content_type = "text/html" },
    { pattern = "%.css$", content_type = "text/css" },
    { pattern = "%.js$", content_type = "application/javascript" },
    { pattern = "%.xml$", content_type = "application/xml" },
    { pattern = "%.json$", content_type = "application/json" },
    { pattern = "%.txt$", content_type = "text/plain" },
    { pattern = "%.md$", content_type = "text/markdown" },

    -- Image formats
    { pattern = "%.png$", content_type = "image/png" },
    { pattern = "%.jpg$", content_type = "image/jpeg" },
    { pattern = "%.jpeg$", content_type = "image/jpeg" },
    { pattern = "%.gif$", content_type = "image/gif" },
    { pattern = "%.bmp$", content_type = "image/bmp" },
    { pattern = "%.ico$", content_type = "image/x-icon" },
    { pattern = "%.tiff?$", content_type = "image/tiff" },
    { pattern = "%.webp$", content_type = "image/webp" },
    { pattern = "%.svg$", content_type = "image/svg+xml" },

    -- Video formats
    { pattern = "%.mp4$", content_type = "video/mp4" },
    { pattern = "%.mkv$", content_type = "video/x-matroska" },
    { pattern = "%.webm$", content_type = "video/webm" },
    { pattern = "%.ogv$", content_type = "video/ogg" },
    { pattern = "%.avi$", content_type = "video/x-msvideo" },
    { pattern = "%.mov$", content_type = "video/quicktime" },
    { pattern = "%.wmv$", content_type = "video/x-ms-wmv" },
    { pattern = "%.flv$", content_type = "video/x-flv" },
    { pattern = "%.mpeg$", content_type = "video/mpeg" },

    -- Audio formats
    { pattern = "%.mp3$", content_type = "audio/mpeg" },
    { pattern = "%.wav$", content_type = "audio/wav" },
    { pattern = "%.ogg$", content_type = "audio/ogg" },
    { pattern = "%.flac$", content_type = "audio/flac" },
    { pattern = "%.aac$", content_type = "audio/aac" },
    { pattern = "%.m4a$", content_type = "audio/x-m4a" },
    { pattern = "%.weba$", content_type = "audio/webm" },

    -- Document formats
    { pattern = "%.pdf$", content_type = "application/pdf" },
    { pattern = "%.doc$", content_type = "application/msword" },
    { pattern = "%.docx$", content_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document" },
    { pattern = "%.xls$", content_type = "application/vnd.ms-excel" },
    { pattern = "%.xlsx$", content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" },
    { pattern = "%.ppt$", content_type = "application/vnd.ms-powerpoint" },
    { pattern = "%.pptx$", content_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation" },
    { pattern = "%.odt$", content_type = "application/vnd.oasis.opendocument.text" },
    { pattern = "%.ods$", content_type = "application/vnd.oasis.opendocument.spreadsheet" },

    -- Archive formats
    { pattern = "%.zip$", content_type = "application/zip" },
    { pattern = "%.tar$", content_type = "application/x-tar" },
    { pattern = "%.gz$", content_type = "application/gzip" },
    { pattern = "%.bz2$", content_type = "application/x-bzip2" },
    { pattern = "%.7z$", content_type = "application/x-7z-compressed" },
    { pattern = "%.rar$", content_type = "application/vnd.rar" },

    -- Application formats
    { pattern = "%.exe$", content_type = "application/vnd.microsoft.portable-executable" },
    { pattern = "%.msi$", content_type = "application/x-msi" },
    { pattern = "%.deb$", content_type = "application/vnd.debian.binary-package" },
    { pattern = "%.rpm$", content_type = "application/x-rpm" },
    { pattern = "%.apk$", content_type = "application/vnd.android.package-archive" },

    -- Font formats
    { pattern = "%.woff$", content_type = "font/woff" },
    { pattern = "%.woff2$", content_type = "font/woff2" },
    { pattern = "%.ttf$", content_type = "font/ttf" },
    { pattern = "%.otf$", content_type = "font/otf" },

    -- Miscellaneous formats
    { pattern = "%.csv$", content_type = "text/csv" },
    { pattern = "%.tsv$", content_type = "text/tab-separated-values" },
    { pattern = "%.ics$", content_type = "text/calendar" },
    { pattern = "%.rtf$", content_type = "application/rtf" },
    { pattern = "%.swf$", content_type = "application/x-shockwave-flash" },
    { pattern = "%.eot$", content_type = "application/vnd.ms-fontobject" },
    
    -- Default fallback
    { pattern = "%.txt$", content_type = "text/plain" } -- Fallback if nothing else matches
}

local function get_content_type(path)
    for _, entry in ipairs(content_types) do
        if path:match(entry.pattern) then
            return entry.content_type
        end
    end
    return "text/plain"
end

-- CGI environment variables implementation
local function execute_script(script_path, query_string, post_data, method, content_length, content_type, headers, client_ip, server_name, server_port)
    local cwd = lfs.currentdir()
    local path_info = script_path
    local script_name = script_path:match("/[^/]*%.lua$") or script_path -- Extract script name

    -- Required environment variables
    headers.GATEWAY_INTERFACE = "CGI/1.1"
    headers.PATH_INFO = path_info
    headers.PATH_TRANSLATED = cwd .. path_info
    headers.QUERY_STRING = query_string
    headers.REMOTE_ADDR = client_ip
    headers.REMOTE_HOST = headers["HTTP_HOST"] or server_name
    headers.REQUEST_METHOD = method
    headers.DOCUMENT_ROOT = cwd
    headers.SCRIPT_NAME = script_name
    headers.SERVER_NAME = server_name
    headers.SERVER_PORT = tostring(server_port)
    headers.SERVER_PROTOCOL = "HTTP/1.1"
    headers.SERVER_SOFTWARE = "LuaSocket/CGI-Server"

    -- Handle POST data
    headers.CONTENT_LENGTH = content_length or ""
    headers.CONTENT_TYPE = content_type or ""

    -- Print all headers for debugging

    -- Prepare environment variables for the command
    local env = {}
    for k, v in pairs(headers) do
        table.insert(env, string.format("export %s='%s'", k, v))
    end

    local exports = table.concat(env, " && ")
    local cmd = exports .. " && "

    if method == "POST" then
        cmd = cmd .. string.format("echo -n '%s' | ", post_data)
    end

    cmd = cmd .. "./" .. script_path
    local handle = assert(io.popen(cmd))
    local result = handle:read("*a")
    handle:close()
    return result
end

local function handle_request(client, server_name, server_port)
    local request = client:receive()
    if not request then return end

    -- Extract method, path, and query string
    local method, path, query_string = request:match("^(%w+)%s+([^?%s]+)%??([^%s]*)%s+HTTP/%d%.%d")

    -- Validate the method
    if not allowed_methods[method] then
        client:send("HTTP/1.1 405 Method Not Allowed\r\n\r\n")
        return
    end

    path = urlcode.unescape(path:sub(2))
    if path == "" then path = "index.lua" end

    -- Parse headers
    local headers = {}
    repeat
        local line = client:receive()
        if not line or line == "" then break end
        local key, value = line:match("^(.-):%s*(.*)")
        if key then
            headers["HTTP_" .. key:upper():gsub("-", "_")] = value
        end
    until not line

    -- Handle POST data if present
    local post_data
    local content_length, content_type = headers["HTTP_CONTENT_LENGTH"], headers["HTTP_CONTENT_TYPE"]
    if method == "POST" and content_length then
        post_data = client:receive(tonumber(content_length))
    end

    -- Check if the file exists
    if not file_exists(path) then
        client:send("HTTP/1.1 404 Not Found\r\n\r\n")
        return
    end

    -- Get client IP
    local client_ip = client:getpeername()

    -- Execute the script if it's a Lua file
    if path:match("%.lua$") then
        local response = execute_script(path, query_string, post_data, method, content_length, content_type, headers, client_ip, server_name, server_port)
        client:send("HTTP/1.1 200 OK\n" .. response)
    else
        -- Serve static content
        local content = read_file(path)
        if content then
            local content_type = get_content_type(path)
            client:send("HTTP/1.1 200 OK\r\nContent-Type: " .. content_type .. "\r\n\r\n" .. content)
        else
            client:send("HTTP/1.1 404 Not Found\r\n\r\n")
        end
    end
end

function M.start(port)
    local server = assert(socket.bind("*", port))
    local server_name, server_port = server:getsockname()
    print("Server running at http://" .. server_name .. ":" .. server_port)

    while true do
        local client = server:accept()
        client:settimeout(10)
        handle_request(client, server_name, server_port)
        client:close()
    end
end

return M
