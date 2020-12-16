local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local constants = {
    nTerminalMultiplier = 1000,
    nTracksMax = 10,
    stationConFileNameLong = 'station/rail/lollo_freestyle_train_station/station.con',
    stationConFileNameShort = 'lollo_freestyle_train_station/station.con',
    terminalModuleType = 'freestyleTrainStationTerminal',
    terminalModelFileName = 'lollo_freestyle_train_station/icon/red_short.mdl',
    terminalModelTag = 'freestyleTrainStationTerminal',
    terminalModuleFileName = 'station/rail/lollo_freestyle_train_station/terminal.module',
    waitingAreaTagRoot = 'waitingArea_',
	trackSpacing = {5, 5, 5, 5}, -- the smaller, the less the risk of collision. Too small, problems removing the module.
	idBases = {
        terminalSlotId = 100000,
        trackSlotId = 200000,
        passengerPlatformSlotId = 300000,
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