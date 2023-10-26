local hilbish = require 'hilbish'


local oldRunner = hilbish.runner.getCurrent and hilbish.runner.getCurrent() or 'hybrid'
local oldSetCurrent = hilbish.runner.setCurrent
function hilbish.runner.setCurrent(mode)
	if mode ~= 'easySH' then oldRunner = mode end
	oldSetCurrent(mode)
end
local oldPrint = print
local printWithTables = function(...)
	local arg = table.pack(...)
	for i,v in pairs(arg) do
		if(type(v) == "table") then
			local ret = "{"
			for i,v in pairs(v) do
				ret = ('%s\n [%s] = %s,'):format(ret,type(i) == "string" and ("%q"):format(i) or tostring(i),type(v) == "string" and ("%q"):format(v) or tostring(v))
			end
			arg[i] = (ret == "{") and '{}' or ret ..'\n}'

		end
	end
	oldPrint(table.unpack(arg))
end

-- Quick run types, the index is the start of the command and the function is what'll be run
local runTypes = {
	['$bash'] = function(input,...) 
		return hilbish.runner.sh(('bash -c %q'):format(input),...)
	end,
	['$zsh'] = function(input,...) 
		return hilbish.runner.sh(('zsh -c %q'):format(input),...)
	end,
	['$sh'] = function(input,...) 
		return hilbish.runner.sh(('sh -c %q'):format(input),...)
	end,
	['$'] = hilbish.runner.sh,
	['$lua'] = hilbish.runner.lua,
	['^'] = hilbish.runner.lua,
	['^run'] = function(input,...)
		local f = io.open(input,'r') 
		local succ,ret = pcall(function()
			if(f == nil) then error('no such file') end
			local content,err = f:read('*a')
			if not content and err then error(err) end
			local e =hilbish.runner.lua(content)
			return e
		end)
		if succ and ret then return ret end
		return {exitCode = -1,
			err = ('Error reading from file %s: %s'):format(input,ret)}
	end,
	['^p'] = function(input,...)
		print = printWithTables
		local ret = hilbish.runner.lua(('print(%s)'):format(input),...)
		print = oldPrint
		return ret
	end,
	['$p'] = function(input,...)
		print = printWithTables
		local ret = hilbish.runner.lua(('print(%s)'):format(input),...)
		print = oldPrint
		return ret
	end,

}

local sh = {
	runTypes=runTypes,
	customPrint=printWithTables,
	runnerExtensions={},
	runners={},
}
sh.run = function(input)
	-- If there are runnerExtensions, run them on the input first
	if(#sh.runnerExtensions > 0) then
		for i,v in pairs(sh.runnerExtensions) do
			local _input = v(input);
			if _input then input = _input end
		end
	end
	-- Check for quick command
	local runType = input:match('^([$^][^%s]-)%s')
	if not runType then
		-- Run custom runners if they're present, if a runner returns something, then return that
		for i,v in pairs(sh.runners) do
			local ret = v(input);
			if ret then return ret end
		end
		-- Run the normal runner
		return hilbish.runner.exec(input, oldRunner)
	end

	-- If this is supposed to be a quick command but the command doesn't exist, throw an error
	local rtFunc = sh.runTypes[runType]
	if not rtFunc then
		return {
			exitCode = 1,
			err = ('invalid runtype %s specified'):format(runType)
		}
	end
	-- Run the function for the command and return whatever it returns
	local ret = rtFunc(input:sub(#runType + 2));
	if(type(ret) ~= "table") then
		return {
			exitCode = 1,
			err = ('%s returned invalid response of type %s: %s'):format(input,type(ret),tostring(ret))
		}
	end
	-- Update the input to be the original input to prevent the beginning from being stripped
	if(ret.input) then ret.input = input end
	return ret

end
-- Add the runner and set it as default
hilbish.runner.add('easySH', sh)
hilbish.runner.setCurrent("easySH")


return sh