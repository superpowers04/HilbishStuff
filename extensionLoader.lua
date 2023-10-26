-- Simple extension loader for hilbish by Superpowers04
--  Simply requires lua files found in the specified directories 
--   with some simple error checking that'll prevent a single extension from crashing hilbish 
--  Note, any extensions named the same thing as vanilla hilbish stuff will replace the default when required. 
--   For example having commands/cd would replace the built-in cd require. 
--    However the default cd require is still run, since it's required before this script
--  By default this'll just scan 
--  - ~/.config/hilbish/extensions/
--  - ~/.local/share/hilbish/extensions/
--  - ~/.local/share/hilbish/commands/
--  - ~/.config/hilbish/commands/
--  or your operating system equivilent


-- TO USE: Simply place this in your hilbish config folder and require it in your init.lua

-- Config

local printMissingFolders = true -- If paths missing should be printed

local extensionsPath = { -- Add directories to this if you want more locations to load
	hilbish.userDir.config ..'/hilbish/extensions',
	hilbish.userDir.data .. '/hilbish/extensions',
	hilbish.userDir.config ..'/hilbish/commands',
	hilbish.userDir.data .. '/hilbish/commands',
}
local showGreeting = true -- If the extension loader message should be shown. Note if your greeting is nil, it won't be shown anyways

-- Script
local fs = require('fs')
local count = 0
local oldPackagePath = package.path
for _,extLoc in pairs(extensionsPath) do
	local folder = io.open(extLoc,'r')
	if(not folder or folder:read('*a')) then
		if(printMissingFolders) then
			print(('\27[101m[Extension Loader] Extension path %q is not a folder!\27[0m'):format(extLoc))
		end
		goto nextExtension
	end
	folder:close()

	package.path = (package.path .. ';' .. extLoc .. '/?/init.lua;'.. extLoc .. '/?.lua')
	for _,v in pairs(fs.readdir(extLoc)) do
		if(v:lower() == "extensionLoader.lua" or (not v:find('%.lua$') and v:find('%.'))) then goto nextExtFile end
		local succ,err = pcall(require,v:gsub('%.lua$',''))
		if succ then
			count = count + 1
			goto nextExtFile
		end
		print(('\27[101m[Extension Loader] Error while loading %q!: %s \27[0m'):format(v,err:gsub('.+extensionLoader%.lua',"")))
		::nextExtFile::
	end
	::nextExtension::
end
local greet = showGreeting and hilbish.opts.greeting
if not greet then return end
if(greet:find('%[Extension Loader%]')) then
	greet:gsub("Loaded (%d) extension",function(a)
		return ('Loaded %i extension')(tonumber(a) + count)
		end,1):gsub("No extensions loaded",('Loaded %i extension(s)')(tonumber(a) + count))
	return
end
if(count == 0) then
	hilbish.opts.greeting = greet .. ('\n\27[35m[Extension Loader] \27[32mNo extensions loaded!\27[0m'):format(count)
	return
end
hilbish.opts.greeting = greet .. ('\n\27[35m[Extension Loader] \27[32mLoaded %i extension(s)!\27[0m'):format(count)
