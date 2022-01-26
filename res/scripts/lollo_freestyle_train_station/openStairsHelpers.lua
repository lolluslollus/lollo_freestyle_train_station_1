local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')

local helpers = {
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

helpers.getBridgeTypeId = function(streetTypeId_withBridge, isRailing)
    if isRailing then
        if helpers.eraA.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraA.bridgeTypeId_withRailing
        elseif helpers.eraB.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraB.bridgeTypeId_withRailing
        elseif helpers.eraC.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraC.bridgeTypeId_withRailing
        else return nil
        end
    else
        if helpers.eraA.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraA.bridgeTypeId_noRailing
        elseif helpers.eraB.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraB.bridgeTypeId_noRailing
        elseif helpers.eraC.streetTypeId_withBridge == streetTypeId_withBridge then return helpers.eraC.bridgeTypeId_noRailing
        else return nil
        end
    end
end

helpers.getData4Era = function(eraPrefix)
    if eraPrefix == moduleHelpers.eras.era_a.prefix then return helpers.eraA
    elseif eraPrefix == moduleHelpers.eras.era_b.prefix then return helpers.eraB
    elseif eraPrefix == moduleHelpers.eras.era_c.prefix then return helpers.eraC
    else return nil
    end
end

return helpers
