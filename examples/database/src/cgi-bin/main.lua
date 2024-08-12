#!/usr/bin/env cgilua.cgi

local conn = require"db_connection"

conn:assertexec[[
    create table if not exists test (x text);
]]

conn:insert("test", {x = "database!"})

local rs = conn:select("x", "test", nil, "limit 1")()
cgilua.put("Hello Lua! " .. rs)
