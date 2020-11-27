local arrayUtils = require('lollo_freestyle_train_station/arrayUtils')

local constants = {
    nTrackMultiplier = 1000,
	nTracksMax = 10,
	trackSpacing = {5, 5, 5, 5}, -- the smaller, the less the risk of collision. Too small, problems removing the module.
	idBases = {
        trackSlotId = 100000,
        passengerPlatformSlotId = 200000,
	},
}

local _idBasesSortedDesc = {}
for k, v in pairs(constants.idBases) do
    table.insert(_idBasesSortedDesc, {id = v, name = k})
end
arrayUtils.sort(_idBasesSortedDesc, 'id', false)
constants.idBasesSortedDesc = _idBasesSortedDesc

return constants