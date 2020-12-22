local _constants = require('lollo_freestyle_train_station/constants')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
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

    local nTerminal = math.floor((slotId - baseId) / _constants.nTerminalMultiplier)
    local nTrackEdge = math.floor(slotId - baseId - nTerminal * _constants.nTerminalMultiplier)

    return nTerminal, nTrackEdge, baseId
end

helpers.mangleId = function(nTerminal, nTrackEdge, baseId)
    return baseId + nTerminal * _constants.nTerminalMultiplier + nTrackEdge
end

helpers.getTerminalFromModelTag = function(modelTag)
    if stringUtils.isNullOrEmptyString(modelTag) then return nil end

    if stringUtils.stringStartsWith(modelTag, _constants.cargoWaitingAreaTagRoot) then
        return tonumber(string.gsub(modelTag, _constants.cargoWaitingAreaTagRoot, ''), 10) -- tonumber(a, base) returns nil if a is no valid number
    elseif stringUtils.stringStartsWith(modelTag, _constants.passengersWaitingAreaTagRoot) then
        return tonumber(string.gsub(modelTag, _constants.passengersWaitingAreaTagRoot, ''), 10)
    elseif stringUtils.stringStartsWith(modelTag, _constants.passengersWaitingAreaUnderpassTagRoot) then
        return tonumber(string.gsub(modelTag, _constants.passengersWaitingAreaUnderpassTagRoot, ''), 10)
    end

    return nil
end

helpers.mangleModelTag = function(nTerminal, isCargo, isUnderpass)
    if isCargo then
        return _constants.cargoWaitingAreaTagRoot .. tostring(nTerminal)
    elseif isUnderpass then
        return _constants.passengersWaitingAreaUnderpassTagRoot .. tostring(nTerminal)
    else
        return _constants.passengersWaitingAreaTagRoot .. tostring(nTerminal)
    end
end

return helpers