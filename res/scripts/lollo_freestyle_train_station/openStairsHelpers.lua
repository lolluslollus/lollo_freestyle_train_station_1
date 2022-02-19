local constants = require('lollo_freestyle_train_station.constants')

local public = {
    eraA = {
        streetTypeId_withBridge = nil,
        streetTypeName_withBridge = 'lollo_1m_path_cobbles_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_cobbles.lua',
        bridgeTypeId_withRailing = nil,
        bridgeTypeId_noRailing = nil,
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_a.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_a.lua',
    },
    eraB = {
        streetTypeId_withBridge = nil,
        streetTypeName_withBridge = 'lollo_1m_path_cobbles_large_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_cobbles_large.lua',
        bridgeTypeId_withRailing = nil,
        bridgeTypeId_noRailing = nil,
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_b.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_b.lua',
    },
    eraC = {
        streetTypeId_withBridge = nil,
        streetTypeName_withBridge = 'lollo_1m_path_concrete_bridge.lua',
        streetTypeName_noBridge = 'lollo_1m_path_concrete.lua',
        bridgeTypeId_withRailing = nil,
        bridgeTypeId_noRailing = nil,
        bridgeTypeName_withRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_era_c.lua',
        bridgeTypeName_noRailing = 'lollo_freestyle_train_station/pedestrian_basic_no_pillars_no_sides_era_c.lua',
    },
}

public.getBridgeTypeId = function(streetTypeId_withBridge, isRailing)
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

public.getData4Era = function(eraPrefix)
    if eraPrefix == constants.eras.era_a.prefix then return public.eraA
    elseif eraPrefix == constants.eras.era_b.prefix then return public.eraB
    elseif eraPrefix == constants.eras.era_c.prefix then return public.eraC
    else return nil
    end
end

return public
