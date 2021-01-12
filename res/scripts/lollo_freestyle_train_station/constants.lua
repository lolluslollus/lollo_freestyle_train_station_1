local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local _maxPercentageDeviation4Midpoint = 1.1

local constants = {
    cargoPlatformTracksCategory = 'cargo-platform-tracks',
    invisiblePlatformTracksCategory = 'invisible-platform-tracks',
    passengerPlatformTracksCategory = 'passenger-platform-tracks',

    stairsHeight = 1.2,
    platformHeight = 1.2,
    platformSideBitsZ = -0.10, -- a bit lower than the platform, to look good in bends
    underpassZ = -4,
    underpassLengthM = 1, -- don't change this, it must stay 1
    stairs2SubwayZ = 4,
    subwayPos2LinkX = 4,
    subwayPos2LinkY = 0,
    subwayPos2LinkZ = -4,

    maxPercentageDeviation4Midpoint = _maxPercentageDeviation4Midpoint,
    minPercentageDeviation4Midpoint = 1 / _maxPercentageDeviation4Midpoint,

    maxCargoWaitingAreaEdgeLength = 9, -- do not tamper with this
    maxPassengerWaitingAreaEdgeLength = 9, -- do not tamper with this
    railEdgeType = 1, -- 0 = ROAD, 1 = RAIL
    maxNTerminals = 12,
    minSplitDistance = 2,
    maxWaypointDistance = 800,
    searchRadius4NearbyStation2Join = 500,

    platformMarkerConName = 'station/rail/lollo_freestyle_train_station/platform_marker.con',
    stationConFileName = 'station/rail/lollo_freestyle_train_station/station.con',
    subwayConFileName = 'station/rail/lollo_freestyle_train_station/subway.con',

    flatStairsModuleType = 'freestyleTrainStationFlatStairs',
    flatCargoArea5x5ModuleType = 'freestyleTrainStationFlatCargoArea5x5',
    flatCargoArea10x5ModuleType = 'freestyleTrainStationFlatCargoArea10x5',
    flatCargoArea10x10ModuleType = 'freestyleTrainStationFlatCargoArea10x10',
    flatPassengerArea5x5ModuleType = 'freestyleTrainStationFlatPassengerArea5x5',
    flatPassengerArea10x5ModuleType = 'freestyleTrainStationFlatPassengerArea10x5',
    flatPassengerArea10x10ModuleType = 'freestyleTrainStationFlatPassengerArea10x10',
    flatPassengerStation0MModuleType = 'freestyleTrainStationFlatPassengerStation0M',
    flatPassengerStation5MModuleType = 'freestyleTrainStationFlatPassengerStation5M',
    passengerSideLiftModuleType = 'freestyleTrainStationPassengerSideLift',
    passengerPlatformLiftModuleType = 'freestyleTrainStationPassengerPlatformLift',
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
    stairs2SubwayModuleType = 'freestyleTrainStationStairs2Subway',
    subwayModuleType = 'freestyleTrainStationSubway',
    trackSpeedModuleType = 'freestyleTrainStationTrackSpeed',
    trackElectrificationModuleType = 'freestyleTrainStationTrackElectrification',

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
    terminalModelFileName = 'lollo_freestyle_train_station/asset/arrivi_partenze_colonna_new.mdl',
    underpassGroundModelFileName = 'lollo_freestyle_train_station/underpass/underpassFloor.mdl',
    underpassBuilding10MModelFileName = 'lollo_freestyle_train_station/underpass/underpass-building-10m.mdl',
    underpassBuilding8MModelFileName = 'lollo_freestyle_train_station/underpass/underpass-building-8m.mdl',
    trackWaypointModelId = 'lollo_freestyle_train_station/railroad/track_waypoint.mdl',
    platformWaypointModelId = 'lollo_freestyle_train_station/railroad/platform_waypoint.mdl',
    cargoWaitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area.mdl',
    cargoWaitingAreaCentredModelId = 'lollo_freestyle_train_station/cargo_waiting_area_centred.mdl',
    passengerWaitingAreaModelId = 'lollo_freestyle_train_station/passenger_waiting_area.mdl',
    passengerLaneLiftModelId = 'lollo_freestyle_train_station/passenger_lane_lift.mdl',
    passengerLaneUnderpassModelId = 'lollo_freestyle_train_station/passenger_lane_underpass.mdl',
    passengerLaneModelId = 'lollo_freestyle_train_station/passenger_lane.mdl',
    passengerLaneLinkableModelId = 'lollo_freestyle_train_station/passenger_lane_linkable.mdl',
    passengerLaneStairs2SubwayModelId = 'lollo_freestyle_train_station/passenger_lane_stairs2Subway.mdl',
    stairs2SubwayModelId = 'lollo_freestyle_train_station/subway/stairs2Subway.mdl',
    subwayModelId = 'lollo_freestyle_train_station/subway/subway.mdl',
    subwayUnconnectedModelId = 'lollo_freestyle_train_station/subway/subway_unconnected.mdl',
    unconnectedSubwayModelId = 'lollo_freestyle_train_station/icon/red_tall_no_collision.mdl',
    emptyModelFileName = 'lollo_freestyle_train_station/empty.mdl',

    cargoTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/cargoTerminal.module',
    passengerTerminalModuleFileName = 'station/rail/lollo_freestyle_train_station/passengerTerminal.module',
    subwayModuleFileName = 'station/rail/lollo_freestyle_train_station/subway.module',
    trackSpeedSlowModuleFileName = 'station/rail/lollo_freestyle_train_station/trackSpeedSlow.module',
    trackSpeedFastModuleFileName = 'station/rail/lollo_freestyle_train_station/trackSpeedFast.module',
    trackSpeedUndefinedModuleFileName = 'station/rail/lollo_freestyle_train_station/trackSpeedUndefined.module',
    trackElectrificationNoModuleFileName = 'station/rail/lollo_freestyle_train_station/trackElectrificationNo.module',
    trackElectrificationYesModuleFileName = 'station/rail/lollo_freestyle_train_station/trackElectrificationYes.module',
    trackElectrificationUndefinedModuleFileName = 'station/rail/lollo_freestyle_train_station/trackElectrificationUndefined.module',

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
        flatStation0MSlotId = 21000000,
        flatStation5MSlotId = 22000000,
        sideLiftSlotId = 23000000,
        platformLiftSlotId = 24000000,
        stationSquareOuterSlotId = 25000000,
        stationSquareInnerSlotId = 26000000,
        slopedArea1x5SlotId = 31000000,
        slopedArea1x10SlotId = 32000000,
        slopedArea1x20SlotId = 33000000,
        underpassSlotId = 40000000,
        stairs2SubwaySlotId = 50000000,
        subwaySlotId = 51000000,
        trackElectrificationSlotId = 60000000,
        trackSpeedSlotId = 61000000,
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