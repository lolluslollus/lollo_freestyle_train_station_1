function data()
    local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
    local pedestrianBridgeUtils = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

    return pedestrianBridgeUtils.getData4Basic(moduleHelpers.eras.era_a.prefix, true)
end
