function data()
    local constants = require('lollo_freestyle_train_station.constants')
    local pedestrianBridgeUtils = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

    return pedestrianBridgeUtils.getData4StoneLolloBridge(_('BrownStoneBridge'), 'bridge/lollo_freestyle_train_station/stone_brown/', true)
end
