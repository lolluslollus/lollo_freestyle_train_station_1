local _constants = require('lollo_freestyle_train_station/constants')
local helpers = {}

helpers.demangleId = function(slotId)
    local function _getBaseId()
        local baseId = 0
        for _, v in pairs(_constants.idBasesSortedDesc) do
            if slotId >= v.id then
                baseId = v.id
                break
            end
        end

        return baseId > 0 and baseId or false
    end

    local baseId = _getBaseId()
    if not baseId then return false, false, false end

    local nTrack = math.floor((slotId - baseId) / _constants.nTrackMultiplier)
    local nTrackEdge = math.floor(slotId - baseId - nTrack * _constants.nTrackMultiplier)

    return nTrack, nTrackEdge, baseId
end

helpers.mangleId = function(nTrack, nTrackEdge, baseId)
    return baseId + nTrack * _constants.nTrackMultiplier + nTrackEdge
end

return helpers