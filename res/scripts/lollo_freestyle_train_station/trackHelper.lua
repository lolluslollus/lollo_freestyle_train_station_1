local _constants = require('lollo_freestyle_train_station.constants')

local helper = {
    isPlatform = function(trackTypeIndex)
        if type(trackTypeIndex) ~= 'number' or trackTypeIndex < 0 then return false end

        local trackType = api.res.trackTypeRep.get(trackTypeIndex)
        if trackType == nil then return false end

        for _, cat in pairs(trackType.categories) do
            if cat == _constants.platformTracksCategory then return true end
        end

        return false
    end
}

helper.getAllPlatformTrackTypes = function()
    local results = {}

    local allTrackTypeIndexesAndFileNames = api.res.trackTypeRep.getAll()
    for trackTypeIndex, _ in pairs(allTrackTypeIndexesAndFileNames) do
        if helper.isPlatform(trackTypeIndex) then results[#results+1] = trackTypeIndex end
    end

    return results
end

return helper