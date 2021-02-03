local _constants = require('lollo_freestyle_train_station.constants')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local helpers = {
    eras = {
        era_a = { prepend = 'era_a_', startYear = 1850 },
        era_b = { prepend = 'era_b_', startYear = 1920 },
        era_c = { prepend = 'era_c_', startYear = 1980 },
    },
    getInvisibleTwinFileName = function(trackFileName)
        local result = stringUtils.stringContains(trackFileName, '_cargo_')
            and trackFileName:gsub('_cargo_', '_invisible_')
            or trackFileName:gsub('_passenger_', '_invisible_')

        result = result:gsub('era_a_', '')
        result = result:gsub('era_b_', '')
        result = result:gsub('era_c_', '')
        return result
    end,

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

helpers.getEra = function (trackTypeIndex)
    if type(trackTypeIndex) ~= 'number' or trackTypeIndex < 0 then return helpers.eras.era_c.prepend end

    local fileName = api.res.trackTypeRep.getFileName(trackTypeIndex)
    if stringUtils.stringContains(fileName, helpers.eras.era_a.prepend) then return helpers.eras.era_a.prepend
    elseif stringUtils.stringContains(fileName, helpers.eras.era_b.prepend) then return helpers.eras.era_b.prepend
    elseif stringUtils.stringContains(fileName, helpers.eras.era_c.prepend) then return helpers.eras.era_c.prepend
    end

    return helpers.eras.era_c.prepend
end

helpers.getTrackAvailability = function(trackFileName)
    if stringUtils.stringContains(trackFileName, 'era_c') then
        return { yearFrom = helpers.eras.era_c.startYear, yearTo = 0 }
    elseif stringUtils.stringContains(trackFileName, 'era_b') then
        return { yearFrom = helpers.eras.era_b.startYear, yearTo = helpers.eras.era_c.startYear }
    elseif stringUtils.stringContains(trackFileName, 'era_a') then
        return { yearFrom = helpers.eras.era_a.startYear, yearTo = helpers.eras.era_b.startYear }
    else
        return { yearFrom = 0, yearTo = 0 }
    end
end

return helpers