local M = {}
-- M["cgilua.cgi"] = [[#!/bin/sh

-- LUAROCKS_SYSCONFDIR='/etc/luarocks' exec '/usr/bin/lua5.3' -e 'package.path="/home/app/.luarocks/share/lua/5.3/?.lua;/home/app/.luarocks/share/lua/5.3/?/init.lua;"..package.path;package.cpath="/home/app/.luarocks/lib/lua/5.3/?.so;"..package.cpath;local k,l,_=pcall(require,"luarocks.loader") _=k and l.add_context("cgilua","6.0.2-0")' '/home/app/.luarocks/lib/luarocks/rocks-5.3/cgilua/6.0.2-0/bin/cgilua.cgi' "$@"  
-- local cgilua = require"cgilua"
-- ]]

M["cgilua.conf"] = [[
<VirtualHost *:80>
    ServerAlias *
    DocumentRoot /home/app/src/controller 
    ErrorLog /home/app/logs/error.log 
    CustomLog /home/app/logs/access.log combined

    <Directory /home/app/src/controller >
        DirectoryIndex main.lua
        Options FollowSymLinks ExecCGI
        AddHandler cgi-script .lua
        AllowOverride None
        Allow from all
        Require all granted
    </Directory>
</VirtualHost>
]]

M["config.lua"] = [[local lib_dir = {
  "/home/app/src/modules"
}

cgilua.addopenfunction (function ()
	cgilua.script_vdir = cgilua.splitonlast(cgilua.urlpath):gsub("%/+", "/")
	local package = package
	-- local app = lib_dir[cgilua.script_vdir]
	-- if app then
	for i, path in ipairs(lib_dir) do
		package.path = path.."/?.lua;"..path.."/?/init.lua;"..package.path
	end
	-- end
end)

-- inserts value into table. checks if value is a simple value or a table
local function insert_value(tab, value)
	if type(value) == "table" then -- both POST and QUERY have table values in k index
		for _, vv in ipairs(value) do
			table.insert(tab, vv)
		end
	else -- QUERY has simple value in k index
		table.insert(tab, value)
	end
end

-- copies the orig_table to the dest_table
local function copy_table (dest_tab, orig_tab)
    for k,v in pairs(orig_tab) do
	    if type(v) == "table" then
			dest_tab[k] = {}
			for i, vv in pairs(v) do
				dest_tab[k][i] = vv
			end
		else
			dest_tab[k] = v
		end
	end
end

local function old_behavior()
    cgi = {}

    -- copies POST table to cgi table
    copy_table(cgi, cgilua.POST)

    -- check if any key in QUERY's table exists in POST(now cgi) table
    for k, v in pairs(cgilua.QUERY) do
	    local cgik = cgi[k]
	    if cgik then-- key already exists. note that cgik is the value on key k in "POST" table
		    if type(cgik) == "table" and not cgik.file then
			    insert_value(cgik, v)
		    else
			    cgi[k] = { cgik }
			    insert_value(cgi[k], v)
		    end
	    else
		    cgi[k] = v
	    end
    end
    return cgi
end

cgilua.addopenfunction (function ()
	cgi = old_behavior()
	package.loaded["cgi"] = cgi
end)
]]


M["db_connection.lua"] = [[local dado = require"dado"

return dado.connect("nil", "nil", "nil", "duckdb", "db")
]]

M["dev.lua"] = [[return {http = "$$HTTP_PORT$$",
project_name = "$$PROJECT_NAME$$",
}
]]

M["docker-compose.yml"] = [[version: '3.9'

services:
    application:
      image: "cgilua_slim:latest"
      tty: true
      container_name: "$$PROJECT_NAME$$"
      hostname: "$$PROJECT_NAME$$"
      volumes:
        - "$$CWD$$/src:/home/app/src"
        - "$$CWD$$/logs:/home/app/logs"
        - "$$CWD$$/backup:/home/app/backup"
        - "$$CWD$$/luarocks:/home/app/.luarocks"
      ports: 
        - "$$HTTP_PORT$$:80"
]]
M["Dockerfile"] =[[from rousbound/cgilua:latest 

copy  $$PROJECT_NAME$$-0.1-0.rockspec /tmp
run cd /tmp && luarocks make $$PROJECT_NAME$$-0.1-0.rockspec --tree=/home/app/.luarocks PGSQL_INCDIR=/usr/include/postgresql/
]]

M["main.lua"] = [[
#!/usr/bin/env cgilua.cgi

cgilua.put("Hello Lua!")
]]

M["rockspec.lua"] = [[
package = "$$PROJECT_NAME$$"
version = "0.1-0"
source = {
  url = "", 
}
description = {
  summary = "$$PROJECT_NAME$$ rockspec",
}
dependencies = {
  "cgilua >= 6.0",
  "wsapi >= 1.7",
  "dado >=  2.2",
  "htk >= 3.3",
  -- "luasql-postgres >= 2.6.0",
}
build = {
  type = "builtin",
  modules = {},
}
]]

return M
