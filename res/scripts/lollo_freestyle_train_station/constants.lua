local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local constants = {
    cargoPlatformTracksCategory = 'cargo-platform-tracks',
    passengerPlatformTracksCategory = 'passenger-platform-tracks',

    passengerPlatformModelZ = 0.0,
    cargoLaneZ = 0.8,
    passengerLaneZ = 1.2,

    tracksideBitsZ = -1.05,
    underpassDepthM = 4,
    underpassLengthM = 1, -- don't change this, it must stay 1

    maxCargoWaitingAreaEdgeLength = 9,
    maxPassengerWaitingAreaEdgeLength = 9,
    terminalAssetStep = 3,
    railEdgeType = 1, -- 0 = ROAD, 1 = RAIL
    nTerminalMultiplier = 1000,
    nTracksMax = 10, -- LOLLO TODO enforce this
    maxWaypointDistance = 1000,
    minSplitDistance = 1,

    platformMarkerConName = 'station/rail/lollo_freestyle_train_station/platform_marker.con',
    stationConFileNameLong = 'station/rail/lollo_freestyle_train_station/station.con',
    stationConFileNameShort = 'lollo_freestyle_train_station/station.con',

    flatStairsModuleType = 'freestyleTrainStationFlatStairs',
    flatPassengerArea5x5ModuleType = 'freestyleTrainStationFlatPassengerArea5x5',
    flatPassengerArea10x5ModuleType = 'freestyleTrainStationFlatPassengerArea10x5',
    flatPassengerArea10x10ModuleType = 'freestyleTrainStationFlatPassengerArea10x10',
    slopedPassengerArea1x5ModuleType = 'freestyleTrainStationSlopedPassengerArea1x5',
    slopedPassengerArea1x10ModuleType = 'freestyleTrainStationSlopedPassengerArea1x10',
    slopedPassengerArea1x20ModuleType = 'freestyleTrainStationSlopedPassengerArea1x20',
    cargoTerminalModuleType = 'freestyleTrainStationCargoTerminal',
    passengerTerminalModuleType = 'freestyleTrainStationPassengerTerminal',
    underpassModuleType = 'freestyleTrainStationUnderpass',

    flatStairsModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/stairs.mdl',
    flatPassengerArea5x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area5x5.mdl',
    flatPassengerArea10x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area10x5.mdl',
    flatPassengerArea10x10ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area10x10.mdl',
    slopedPassengerArea1x5ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x5.mdl',
    slopedPassengerArea1x10ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x10.mdl',
    slopedPassengerArea1x20ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x20.mdl',
    -- terminalModelFileName = 'lollo_freestyle_train_station/icon/red_short.mdl',
    terminalModelFileName = 'lollo_freestyle_train_station/asset/arrivi_partenze_colonna_new.mdl',
    terminalModelTag = 'freestyleTrainStationTerminal',
    underpassModelTag = 'freestyleTrainStationUnderpass',
    underpassGroundModelFileName = 'lollo_freestyle_train_station/underpassFloor.mdl',
    underpassWallsModelFileName = 'lollo_freestyle_train_station/underpassBuilding.mdl',
    cargoTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/cargoTerminal.module',
    passengerTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/passengerTerminal.module',
    trackWaypointModelId = 'lollo_freestyle_train_station/railroad/track_waypoint.mdl',
    platformWaypointModelId = 'lollo_freestyle_train_station/railroad/platform_waypoint.mdl',
    cargoWaitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area.mdl',
    passengerWaitingAreaModelId = 'lollo_freestyle_train_station/passenger_waiting_area.mdl',
    passengerLaneUnderpassModelId = 'lollo_freestyle_train_station/passenger_lane_underpass.mdl',
    passengerLaneOnPlatformModelId = 'lollo_freestyle_train_station/passenger_lane_on_platform.mdl',
    passengerLaneModelId = 'lollo_freestyle_train_station/passenger_lane.mdl',
    cargoWaitingAreaTagRoot = 'cargoWaitingArea_',
    passengersWaitingAreaTagRoot = 'passengersWaitingArea_',
    passengersWaitingAreaUnderpassTagRoot = 'passengersWaitingAreaUnderpass_',

    areaSpacing = {2, 2, 2, 2},
    trackSpacing = {2, 2, 2, 2}, -- the smaller, the less the risk of collision. Too small, problems removing the module. x is length, y is width.
    -- trackSpacing = {5, 5, 2, 2}, -- the smaller, the less the risk of collision. Too small, problems removing the module. x is length, y is width.
    underpassSpacing = {2.5, 2.5, 1.5, 1.5}, -- the smaller, the less the risk of collision. Too small, problems removing the module. x is length, y is width.
	idBases = {
        terminalSlotId = 100000,
        -- areaSlotId = 200000,
        flatStairsSlotId = 200000,
        flatPassengerArea5x5SlotId = 300000,
        flatPassengerArea10x5SlotId = 400000,
        flatPassengerArea10x10SlotId = 500000,
        slopedPassengerArea5x5SlotId = 700000,
        slopedPassengerArea10x5SlotId = 800000,
        slopedPassengerArea10x10SlotId = 900000,
        underpassSlotId = 1000000,
    },
    idTransf = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
}

local _idBasesSortedDesc = {}
for k, v in pairs(constants.idBases) do
    table.insert(_idBasesSortedDesc, {id = v, name = k})
end
arrayUtils.sort(_idBasesSortedDesc, 'id', false)
constants.idBasesSortedDesc = _idBasesSortedDesc

return constants