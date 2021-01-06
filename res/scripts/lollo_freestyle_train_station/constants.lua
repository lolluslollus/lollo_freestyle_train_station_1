local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local constants = {
    cargoPlatformTracksCategory = 'cargo-platform-tracks',
    invisiblePlatformTracksCategory = 'invisible-platform-tracks',
    passengerPlatformTracksCategory = 'passenger-platform-tracks',

    passengerPlatformModelZ = 0.0,
    cargoLaneZ = 1.2,
    passengerLaneZ = 1.2,

    platformZ = -1.0,
    tracksideBitsZ = -1.05,
    underpassDepthM = 4,
    underpassLengthM = 1, -- don't change this, it must stay 1
    underpassZed = -3,

    maxCargoWaitingAreaEdgeLength = 9, -- do not tamper with this
    maxPassengerWaitingAreaEdgeLength = 9, -- do not tamper with this
    railEdgeType = 1, -- 0 = ROAD, 1 = RAIL
    maxNTerminals = 12,
    maxWaypointDistance = 1000,
    minSplitDistance = 2,

    platformMarkerConName = 'station/rail/lollo_freestyle_train_station/platform_marker.con',
    stationConFileNameLong = 'station/rail/lollo_freestyle_train_station/station.con',
    stationConFileNameShort = 'lollo_freestyle_train_station/station.con',

    flatStairsModuleType = 'freestyleTrainStationFlatStairs',
    flatCargoArea5x5ModuleType = 'freestyleTrainStationFlatCargoArea5x5',
    flatCargoArea10x5ModuleType = 'freestyleTrainStationFlatCargoArea10x5',
    flatCargoArea10x10ModuleType = 'freestyleTrainStationFlatCargoArea10x10',
    flatPassengerArea5x5ModuleType = 'freestyleTrainStationFlatPassengerArea5x5',
    flatPassengerArea10x5ModuleType = 'freestyleTrainStationFlatPassengerArea10x5',
    flatPassengerArea10x10ModuleType = 'freestyleTrainStationFlatPassengerArea10x10',
    flatPassengerStationModuleType = 'freestyleTrainStationFlatPassengerStation',
    passengerLiftModuleType = 'freestyleTrainStationPassengerLift',
    passengerStationSquareModuleType = 'freestyleTrainStationPassengerStationSquare',
    -- slopedStairsModuleType = 'freestyleTrainStationSlopedStairs',
    slopedCargoArea1x5ModuleType = 'freestyleTrainStationSlopedCargoArea1x5',
    slopedCargoArea1x10ModuleType = 'freestyleTrainStationSlopedCargoArea1x10',
    slopedCargoArea1x20ModuleType = 'freestyleTrainStationSlopedCargoArea1x20',
    slopedPassengerArea1x5ModuleType = 'freestyleTrainStationSlopedPassengerArea1x5',
    slopedPassengerArea1x10ModuleType = 'freestyleTrainStationSlopedPassengerArea1x10',
    slopedPassengerArea1x20ModuleType = 'freestyleTrainStationSlopedPassengerArea1x20',
    cargoTerminalModuleType = 'freestyleTrainStationCargoTerminal',
    passengerTerminalModuleType = 'freestyleTrainStationPassengerTerminal',
    underpassModuleType = 'freestyleTrainStationUnderpass',

    flatStairsSmoothModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/stairs_smooth.mdl',
    flatStairsSteepModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/stairs_steep.mdl',
    flatCargoArea5x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/cargo/area5x5.mdl',
    flatCargoArea10x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/cargo/area10x5.mdl',
    flatCargoArea10x10ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/cargo/area10x10.mdl',
    flatPassengerArea5x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area5x5.mdl',
    flatPassengerArea10x5ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area10x5.mdl',
    flatPassengerArea10x10ModelFileName = 'lollo_freestyle_train_station/railroad/flatSides/passengers/area10x10.mdl',
    slopedCargoArea1x5ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/cargo/area1x5.mdl',
    slopedCargoArea1x10ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/cargo/area1x10.mdl',
    slopedCargoArea1x20ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/cargo/area1x20.mdl',
    slopedPassengerArea1x5ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x5.mdl',
    slopedPassengerArea1x10ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x10.mdl',
    slopedPassengerArea1x20ModelFileName = 'lollo_freestyle_train_station/railroad/slopedSides/passengers/area1x20.mdl',
    -- terminalModelFileName = 'lollo_freestyle_train_station/icon/red_short.mdl',
    terminalModelFileName = 'lollo_freestyle_train_station/asset/arrivi_partenze_colonna_new.mdl',
    underpassGroundModelFileName = 'lollo_freestyle_train_station/underpass/underpassFloor.mdl',
    underpassWallsModelFileName = 'lollo_freestyle_train_station/underpass/underpassBuilding.mdl',
    cargoTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/cargoTerminal.module',
    passengerTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/passengerTerminal.module',
    trackWaypointModelId = 'lollo_freestyle_train_station/railroad/track_waypoint.mdl',
    platformWaypointModelId = 'lollo_freestyle_train_station/railroad/platform_waypoint.mdl',
    cargoWaitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area.mdl',
    passengerWaitingAreaModelId = 'lollo_freestyle_train_station/passenger_waiting_area.mdl',
    passengerLaneUnderpassModelId = 'lollo_freestyle_train_station/passenger_lane_underpass.mdl',
    passengerLaneModelId = 'lollo_freestyle_train_station/passenger_lane.mdl',
    passengerLaneLinkableModelId = 'lollo_freestyle_train_station/passenger_lane_linkable.mdl',

    cargoWaitingAreaTagRoot = 'cargoWaitingArea_',
    passengersWaitingAreaTagRoot = 'passengersWaitingArea_',
    passengersWaitingAreaUnderpassTagRoot = 'passengersWaitingAreaUnderpass_',

    nTerminalMultiplier = 10000,
	idBases = {
        terminalSlotId = 1000000,
        flatStairsSlotId = 12000000,
        flatArea5x5SlotId = 13000000,
        flatArea10x5SlotId = 14000000,
        flatArea10x10SlotId = 15000000,
        flatStationSlotId = 21000000,
        liftSlotId = 23000000,
        stationSquareSlotId = 25000000,
        slopedArea1x5SlotId = 31000000,
        slopedArea1x10SlotId = 32000000,
        slopedArea1x20SlotId = 33000000,
        underpassSlotId = 40000000,
    },
    idTransf = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
}

constants.maxPercentageDeviation4Midpoint = 1.1
constants.minPercentageDeviation4Midpoint = 1 / constants.maxPercentageDeviation4Midpoint


local _idBasesSortedDesc = {}
for k, v in pairs(constants.idBases) do
    table.insert(_idBasesSortedDesc, {id = v, name = k})
end
arrayUtils.sort(_idBasesSortedDesc, 'id', false)
constants.idBasesSortedDesc = _idBasesSortedDesc

return constants