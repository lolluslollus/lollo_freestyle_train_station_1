function data()
    local constants = require('lollo_freestyle_train_station.constants')
    local pedestrianBridgeUtils = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

    return pedestrianBridgeUtils.getData4StoneLolloBridge(_('GreyStoneBridge_NoSides'), 'bridge/lollo_freestyle_train_station/stone_grey/', false)
end
