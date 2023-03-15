function data()
    local constants = require('lollo_freestyle_train_station.constants')
    local pedestrianBridgeUtil = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

    return pedestrianBridgeUtil.getData4PedestrianBridge(constants.eras.era_c, true)
end
