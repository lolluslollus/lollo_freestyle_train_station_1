function data()
    local constants = require('lollo_freestyle_train_station.constants')
    local pedestrianBridgeUtils = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

    return pedestrianBridgeUtils.getData4StoneLolloBridge(_('BrownStoneBridge_NoSides'), 'bridge/lollo_freestyle_train_station/stone_brown/', false)
end
