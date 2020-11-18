local lollo = {}
local stringUtils = require('lollo_lorry_station/stringUtils')

local function myErrorHandler(err)
    print('ERROR: ', err)
end

function lollo.debugGetInfo()
    local results = {}
    for i = 1, 99 do
        local info = debug.getInfo(i)
        if info then
            table.insert(results, #results + 1, info)
        else
            return results
        end
    end
    return results
end
function lollo.showState(state)
    print('LOLLO state = ')
    debugPrint(state)
end
function lollo.tryGlobalVariables()
    -- -USEALLAVAILABLECORES
    -- gnome-terminal -- %command%
    -- xfce4-terminal -- %command%
    -- print('about to try global variables')
    -- print('---')
    -- debugPrint(game)

    -- if true then return end
print('LOLLO game.interface.buildConstruction = ')
debugPrint(game.interface.buildConstruction)
print('LOLLO game.interface.bulldoze = ')
debugPrint(game.interface.bulldoze)
print('LOLLO game.interface.findPath = ')
debugPrint(game.interface.findPath)
print('LOLLO game.interface.setZone = ')
debugPrint(game.interface.setZone)
print('LOLLO game.interface.startEvent = ')
debugPrint(game.interface.startEvent)
print('LOLLO game.interface.upgradeConstruction = ')
debugPrint(game.interface.upgradeConstruction)

    xpcall(
        function()
            print('-- global variables = ')
            for key, value in pairs(_G) do
                print(key, value)
                -- if key ~= "package" and key ~= "_G" then
                --     debugPrint(value)
                -- else
                --     print("data too long, skipped")
                -- end
            end

            --  print('---')
            -- print('LOLLO getmetatable("") = ')
            -- debugPrint(getmetatable(''))
            -- print('---')
            -- print('LOLLO getmetatable(_G) = ')
            -- debugPrint(getmetatable(_G))

            -- local filefilterutil = require('filefilterutil')
            -- print('filefilterutil.package.mod')
            -- debugPrint(filefilterutil.package.mod)
            -- debugPrint(filefilterutil.package.mod('vehicle/train/etr500_gen2_locomotive_f_eurostar_italy.mdl', {}))

            print('---')

            --print('package.loaded = ')
            -- debugPrint(package.loaded)
            -- print('debug.getregistry = ')
            -- debugPrint(debug.getregistry())
            -- print('---')
            --print('package.preload = ')
            -- debugPrint(package.preload)
            --print('LOLLO path = ', package.path) -- workshop mods do not appear here, only local mods

            -- local getMods = print('LOLLO getMods = ', package.loadlib('loadall.dll', 'getMods')) -- LOLLO TODO look into this, it may help with remote debugging
            -- debugPrint(getMods)
            -- local getActiveMods = print('LOLLO getMods = ', package.loadlib('loadall.dll', 'getActiveMods')) -- LOLLO TODO look into this, it may help with remote debugging
            -- debugPrint(getActiveMods)
            
            print('---')

--[[             print('game.interface.getLog() = ')
            debugPrint(game.interface.getLog) -- this needs 3 params
            --debugPrint(game.interface.getLog()) -- this needs 3 params
            print('game.interface.getName() = ')
            debugPrint(game.interface.getName) -- this needs 1 param
            --debugPrint(game.interface.getName()) -- this needs 1 param
            print('game.interface.getPlayer() = ')
            debugPrint(game.interface.getPlayer())
            print('game.interface.getPlayerJournal() = ')
            debugPrint(game.interface.getPlayerJournal) -- this needs 2 to 3 params
            --debugPrint(game.interface.getPlayerJournal()) -- this needs 2 to 3 params
 ]]        end,
        myErrorHandler
    )
end

function lollo.tryDebugger()
    -- -USEALLAVAILABLECORES
    -- gnome-terminal -- %command%
    -- xfce4-terminal -- %command%

    print('---')
    --debugPrint(package)
    print('---')
    debugPrint(package.loaded['lollo_cement'])
    debugPrint(package.loaded['lollo_cement.lua'])
    print('---')
    print('traceback = ', debug.traceback(nil, 4))
    print('---')
    print('traceback = ', debug.traceback())
end

function lollo.trySocket()
    print('new new new text') -- LOLLO change this string to see if the reload really works

    xpcall(
        function()
            -- if not (stringUtils.stringContains(package.cpath, 'luasocket')) then
            --     --package.cpath = package.cpath .. ";C:/Users/lollus/Documents/GitHub/ZeroBraneStudio/bin/?.dll;C:/temp/luasocket64/clibs52/?.dll"
            --     --package.cpath = package.cpath .. ";C:/temp/luasocket64/clibs52/?.dll"
            --     package.cpath = package.cpath .. ";./lib/?.dll"
            -- else
            --     print("cpath not updated")
            -- end
            if not (stringUtils.stringContains(package.path, 'mobdebug')) then
                --package.path = package.path .. ';C:/Users/lollus/Documents/GitHub/ZeroBraneStudio/lualibs/?/?.lua;C:/Users/lollus/Documents/GitHub/ZeroBraneStudio/lualibs/?.lua'
                package.path = package.path .. ';C:/Users/lollus/Documents/GitHub/ZeroBraneStudio/lualibs/?/?.lua'
            else
                print('path not updated')
            end
            print('source 0 = ', debug.getinfo(0, 'S').source)
            print('source 1 = ', debug.getinfo(1, 'S').source)
            print('source 2 = ', debug.getinfo(2, 'S').source)
            print('source 3 = ', debug.getinfo(3, 'S').source)
            print('package.cpath = ', package.cpath)
            print('package.path = ', package.path)

            print('about to start mobdebug')
            local mdbg = require('mobdebug')
            print('mobdebug required')
            debugPrint(mdbg)
            mdbg.listen('*', 8172) -- same as listen("*", 8172)
            print('mobdebug listening')
            --require('mobdebug').start()
        end,
        myErrorHandler
    )
    xpcall(
        function()
            print('about to start mobdebug')
            local mdbg = require('mobdebug')
            print('mobdebug required')
            debugPrint(mdbg)
            mdbg.start()
            print('mobdebug listening')
            --require('mobdebug').start()
        end,
        myErrorHandler
    )
end

return lollo

--[[
Start menu - visual studio 2*** folder - x64 - x86 cross-tool command line
in the command line:
navigate to the dir luawinmulti
cd C:\Users\lollus\Documents\GitHub\luawinmulti
make --52 install C:\lua52
navigate to C:\lua52\luarocks
luarocks.bat install luasocket

it all fails tho. Easier is:
copy the dirs socket and mime into C:\Program Files (x86)\Steam\steamapps\common\Transport Fever 2
copy lua52.dll into C:\Program Files (x86)\Steam\steamapps\common\Transport Fever 2
Make sure they are all compiled for 64 bit! 

The trouble is, I might need a lua52.dll compiled against msvcrt140
I have found the lua-5.2.4_Win64_dll14_lib and lua-5.2.4_Win64_dll15_lib on lua binaries, but now it dumps:
The thread tried to read from or write to a virtual address for which it does not have the appropriate access

Maybe I call the socket from the game.interface thread? Nope, the luadump still shows the same message, even tho it might behave a bit differently
Even starting the game as an admin won't help.
]]

--[[
    It is instead easy to use the rustical debugger:
    on Linux:
    1) create a file named steam_appid.txt in the Transport Fever 2 folder, with
        1066780
        as content.
    2) Now you can run.sh to start TPF in your favorite terminal. For example,
        ./run.sh &

    If you have problems with libpng12 not found, create a new sh file with content:
    #!/bin/sh
    LD_LIBRARY_PATH=.:~/.steam/ubuntu12_32/steam-runtime/lib/x86_64-linux-gnu/:$LD_LIBRARY_PATH ./TransportFever2

    In any lua you now can use:
        require "debugger"()
    this will be a lua debugger breakpoint.
    The whole game stops and you can use the debugger on your console.

    Note: you shouldn’t use quit but continue, otherwise game will crash ;)

    Technical the same should be doable on Windows. (via cmd.exe)

    Here is a copy of the stock run.sh:

    #!/bin/sh
    LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH ./TransportFever2

    # The LD_LIBRARY_PATH environment variable contains a colon separated list of paths 
    # that the linker uses to resolve library dependencies of ELF executables at run-time. 
    # These paths will be given priority over the standard library paths /lib and /usr/lib. 
    # The standard paths will still be searched, but only after the list of paths in LD_LIBRARY_PATH has been exhausted.

    # The best way to use LD_LIBRARY_PATH is to set it on the command line or script 
    # immediately before executing the program. 
    # This way you can keep the new LD_LIBRARY_PATH isolated from the rest of your system.

    #   $ export LD_LIBRARY_PATH="/list/of/library/paths:/another/path"
    #   $ ./program

    # In general it is not a good practice to have LD_LIBRARY_PATH permanently set in your environment. 
    # This could lead to unintended side effects as programs can link to unintended libraries 
    # producing strange results or unexpectedly crashing. 
    # There is also the possibility introducing potential security threats.

    # You can check if the linker can locate all the required libraries by running the ldd command.
    #   $ ldd ~/myprogram

]]
