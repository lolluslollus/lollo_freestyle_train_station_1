local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local constants = {
    cargoPlatformTracksCategory = 'cargo-platform-tracks',
    passengerPlatformTracksCategory = 'passenger-platform-tracks',

    passengerPlatformModelZ = 0.3,
    laneZ = 0.8,
    tracksideBitsZ = -1.05,
    underpassDepthM = 4,
    underpassLengthM = 1, -- don't change this, it must stay 1

    maxCargoWaitingAreaEdgeLength = 9,
    maxPassengerWaitingAreaEdgeLength = 10,
    terminalAssetStep = 3,
    railEdgeType = 1, -- 0 = ROAD, 1 = RAIL
    nTerminalMultiplier = 1000,
    nTracksMax = 10,
    maxWaypointDistance = 1000,

    platformMarkerConName = 'station/rail/lollo_freestyle_train_station/platform_marker.con',
    stationConFileNameLong = 'station/rail/lollo_freestyle_train_station/station.con',
    stationConFileNameShort = 'lollo_freestyle_train_station/station.con',
    cargoTerminalModuleType = 'freestyleTrainStationCargoTerminal',
    passengerTerminalModuleType = 'freestyleTrainStationPassengerTerminal',
    underpassModuleType = 'freestyleTrainStationUnderpass',
    -- terminalModelFileName = 'lollo_freestyle_train_station/icon/red_short.mdl',
    terminalModelFileName = 'lollo_freestyle_train_station/asset/arrivi_partenze_colonna_new.mdl',
    terminalModelTag = 'freestyleTrainStationTerminal',
    underpassModelTag = 'freestyleTrainStationUnderpass',
    underpassModelFileName2 = 'lollo_freestyle_train_station/era_c_underpass_alone.mdl',
    -- underpassModelFileName = 'lollo_freestyle_train_station/icon/green.mdl',
    underpassModelFileName = 'lollo_freestyle_train_station/underpassWalls.mdl',
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

    trackSpacing = {2, 2, 2, 2}, -- the smaller, the less the risk of collision. Too small, problems removing the module. x is length, y is width.
    underpassSpacing = {2.5, 2.5, 1.5, 1.5}, -- the smaller, the less the risk of collision. Too small, problems removing the module. x is length, y is width.
	idBases = {
        terminalSlotId = 100000,
        underpassSlotId = 400000,
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