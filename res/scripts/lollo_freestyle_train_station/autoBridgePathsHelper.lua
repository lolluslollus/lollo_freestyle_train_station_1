local constants = require('lollo_freestyle_train_station.constants')
local logger = require('lollo_freestyle_train_station.logger')

local public = {
    eraA = {
        streetTypeId_withBridge = nil, -- populated at runtime
        streetTypeName_withBridge = 'lollo_1m_path_cobbles_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_cobbles.lua',
        bridgeTypeId_withRailing = nil, -- populated at runtime
        bridgeTypeId_noRailing = nil, -- populated at runtime
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_a.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_a.lua',
    },
    eraB = {
        streetTypeId_withBridge = nil, -- populated at runtime
        streetTypeName_withBridge = 'lollo_1m_path_cobbles_large_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_cobbles_large.lua',
        bridgeTypeId_withRailing = nil, -- populated at runtime
        bridgeTypeId_noRailing = nil, -- populated at runtime
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_b.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_b.lua',
    },
    eraC = {
        streetTypeId_withBridge = nil, -- populated at runtime
        streetTypeName_withBridge = 'lollo_1m_path_concrete_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_concrete.lua',
        bridgeTypeId_withRailing = nil, -- populated at runtime
        bridgeTypeId_noRailing = nil, -- populated at runtime
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_c.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_c.lua',
    },
}

local _getBridgeTypeId = function(streetTypeId_withBridge, isRailing)
    if isRailing then
        if public.eraA.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraA.bridgeTypeId_withRailing
        elseif public.eraB.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraB.bridgeTypeId_withRailing
        elseif public.eraC.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraC.bridgeTypeId_withRailing
        else return nil
        end
    else
        if public.eraA.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraA.bridgeTypeId_noRailing
        elseif public.eraB.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraB.bridgeTypeId_noRailing
        elseif public.eraC.streetTypeId_withBridge == streetTypeId_withBridge then return public.eraC.bridgeTypeId_noRailing
        else return nil
        end
    end
end

public.getBridgeTypeId = function(streetTypeId_withBridge, isRailing)
    local result = _getBridgeTypeId(streetTypeId_withBridge, isRailing)
    if result == -1 then result = nil end
    return result
end

public.getData4Era = function(eraPrefix)
    if eraPrefix == constants.eras.era_a.prefix then return public.eraA
    elseif eraPrefix == constants.eras.era_b.prefix then return public.eraB
    elseif eraPrefix == constants.eras.era_c.prefix then return public.eraC
    else return nil
    end
end

public.guiInit = function()
    public.eraA.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(public.eraA.bridgeTypeName_withRailing)
    public.eraB.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(public.eraB.bridgeTypeName_withRailing)
    public.eraC.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(public.eraC.bridgeTypeName_withRailing)

    public.eraA.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(public.eraA.bridgeTypeName_noRailing)
    public.eraB.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(public.eraB.bridgeTypeName_noRailing)
    public.eraC.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(public.eraC.bridgeTypeName_noRailing)

    public.eraA.streetTypeId_withBridge = api.res.streetTypeRep.find(public.eraA.streetTypeName_withBridge)
    public.eraB.streetTypeId_withBridge = api.res.streetTypeRep.find(public.eraB.streetTypeName_withBridge)
    public.eraC.streetTypeId_withBridge = api.res.streetTypeRep.find(public.eraC.streetTypeName_withBridge)
    -- logger.print('guiInit has initialised the bridge types, they are:') logger.debugPrint(public)
end

return public
