local _constants = require('lollo_freestyle_train_station.constants')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local helpers = {
    addCategory = function(trackType, category)
        if trackType == nil or type(trackType.categories) ~= 'userdata' or stringUtils.isNullOrEmptyString(category) then return false end

        trackType.categories[#trackType.categories + 1] = category
        return true
    end,
    getEraPrefix = function (trackTypeIndex)
        if type(trackTypeIndex) ~= 'number' or trackTypeIndex < 0 then return _constants.eras.era_c.prefix end

        local fileName = api.res.trackTypeRep.getFileName(trackTypeIndex)
        if stringUtils.stringContains(fileName, _constants.eras.era_a.prefix) then return _constants.eras.era_a.prefix
        elseif stringUtils.stringContains(fileName, _constants.eras.era_b.prefix) then return _constants.eras.era_b.prefix
        elseif stringUtils.stringContains(fileName, _constants.eras.era_c.prefix) then return _constants.eras.era_c.prefix
        end

        return _constants.eras.era_c.prefix
    end,
    getInvisibleTwinFileName = function(trackFileName)
        -- logger.print('build 35716, trackFileName = ' .. (trackFileName or 'NIL'))
        -- return trackFileName
        local result = stringUtils.stringContains(trackFileName, '_cargo_')
            and trackFileName:gsub('_cargo_', '_invisible_')
            or trackFileName:gsub('_passenger_', '_invisible_')

        result = result:gsub('era_a_', '')
        result = result:gsub('era_b_', '')
        result = result:gsub('era_c_', '')

        -- logger.print('build 35716, invisibleTwinFileName = ' .. (result or 'NIL'))
        return result
    end,
    getTrackAvailability = function(trackFileName)
        if stringUtils.stringContains(trackFileName, 'era_c') then
            return { yearFrom = _constants.eras.era_c.startYear, yearTo = 0 }
        elseif stringUtils.stringContains(trackFileName, 'era_b') then
            return { yearFrom = _constants.eras.era_b.startYear, yearTo = _constants.eras.era_c.startYear }
        elseif stringUtils.stringContains(trackFileName, 'era_a') then
            return { yearFrom = _constants.eras.era_a.startYear, yearTo = _constants.eras.era_b.startYear }
        else
            return { yearFrom = 0, yearTo = 0 }
        end
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
    end,
    isUncategorised = function(trackType)
        if trackType == nil then return false end

        local isCategorised = false
        for _, cat in pairs(trackType.categories) do
            isCategorised = true
        end

        return not(isCategorised)
    end,
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