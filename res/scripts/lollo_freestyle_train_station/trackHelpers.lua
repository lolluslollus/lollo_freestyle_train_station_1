local _constants = require('lollo_freestyle_train_station.constants')

local helpers = {
    isPlatform = function(trackTypeIndex)
        if type(trackTypeIndex) ~= 'number' or trackTypeIndex < 0 then return false end

        local trackType = api.res.trackTypeRep.get(trackTypeIndex)
        if trackType == nil then return false end

        for _, cat in pairs(trackType.categories) do
            if cat == _constants.passengerPlatformTracksCategory or cat == _constants.cargoPlatformTracksCategory then return true end
        end

        return false
    end,
    isPlatform2 = function(trackType)
        if trackType == nil then return false end

        for _, cat in pairs(trackType.categories) do
            if cat == _constants.passengerPlatformTracksCategory or cat == _constants.cargoPlatformTracksCategory then return true end
        end

        return false
    end,
    isCargoPlatform = function(trackTypeIndex)
        if type(trackTypeIndex) ~= 'number' or trackTypeIndex < 0 then return false end

        local trackType = api.res.trackTypeRep.get(trackTypeIndex)
        if trackType == nil then return false end

        for _, cat in pairs(trackType.categories) do
            if cat == _constants.cargoPlatformTracksCategory then return true end
        end

        return false
    end
}

helpers.getAllPlatformTrackTypes = function()
    local results = {}

    local allTrackTypeIndexesAndFileNames = api.res.trackTypeRep.getAll()
    for trackTypeIndex, _ in pairs(allTrackTypeIndexesAndFileNames) do
        if helpers.isPlatform(trackTypeIndex) then results[#results+1] = trackTypeIndex end
    end

    return results
end

return helpers