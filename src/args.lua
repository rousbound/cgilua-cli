------------------------------------------------------------------------------
-- Improve the treatment of CLI options for scripts.
------------------------------------------------------------------------------

local assert, pairs, print, type = assert, pairs, print, type

local M = {
	_COPYRIGHT = "Copyright (C) 2024 PUC-Rio",
	_DESCRIPTION = "CLI Argument Parser",
	_VERSION = "Args 1.0",
}

------------------------------------------------------------------------------
-- List valid options.
-- @tparam table options

function M.listoptions (options)
	if options._description then
		print(options._description, '\n')
	end
    print ("Usage: "..options._nome)
    for op, exp in pairs (options) do
        if exp == "list" then
            exp = "Show this list"
        elseif type(exp) == "table" then
            exp = exp[1]
        end
		if op:sub(1,1) ~= '_' then
			if op:len() > 1 then
				print ("", "--"..op, exp)
			else
				print ("", "-"..op, exp)
			end
		end
    end
end

------------------------------------------------------------------------------
-- Processes the list of arguments according to the defined options.
-- The options table should be indexed with the names of the valid options, 
-- and the corresponding values should indicate what to do.
-- If the value is the string "list," then the result of this option implies 
-- the execution of the function listoptions, which shows all valid options;
-- if the value is a string (the text to be displayed by listoptions), 
-- then the option is a simple flag;
-- if the value is a table (the string at position [1] will be displayed by 
-- listoptions), then this option should be followed by a value.
-- @param opcoes Table with the valid options.
-- @return Table with the processed options.
function M.get(options, ...)
    local res = {}
    local args = { ... }
    local i = 1
    while args[i] do
        local a = args[i]
        if a:sub(1,1) == '-' then
            local op = a:match ("^%-+(.*)")
            local t = type (options[op])
            if t == "boolean" then
                res[op] = true
            elseif t == "string" then
                if options[op] == "list" then
                    M.listoptions (options)
                    return false
                else
                    res[op] = true
                end
            elseif t == "table" then
                res[op] = assert (args[i+1], "Missing parameter for option -" .. op)
                i = i + 1
            else
                M.listoptions (options)
                return false
            end
        else
            res[#res+1] = a
        end
        i = i + 1
    end
    return res
end
------------------------------------------------------------------------------
return M
