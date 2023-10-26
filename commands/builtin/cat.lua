local commander = require 'commander'
commander.register('cat', function(args, sinks)
	if #args == 0 then
		sinks.out:writeln [[
usage: cat [file]...]]
		return 1
	end

	local exit = 0

	for _, fName in ipairs(args) do
		local f = io.open(fName)
		if f == nil then
			exit = 1
			sinks.out:writeln(('cat: %s: no such file or directory'):format(fName))
			goto continue
		end
		local file,err = f:read('*a')
		local out = file;
		if(not out) then
			out = ("cat: %s: %s"):format(fName,err:gsub('read .-:',''))
		end
		sinks.out:writeln(out)
		::continue::
	end
	io.flush()
	return exit
end)
