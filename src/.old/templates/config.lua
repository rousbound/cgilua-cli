local cgilua = require"cgilua"

local lib_dir = {
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



--[[
*** Simulates old cgi table for CGILua
*** merging POST and QUERY data in a single table.
*** date: ccpa sep 2010
*** developers: Tomas, Carla, Pablo
--]]

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


