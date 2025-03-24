local _isExtendedLogActive = false
local _isWarningLogActive = true
local _isErrorLogActive = true
local _isTimersActive = true

local _printThings = function(outString, tab)
    for i = 1, #tab, 1 do
        local value = tab[i]
        local valueString = tostring(value)
        if valueString:sub(0, 10) == 'function: ' or valueString:sub(0, 7) == 'table: ' then
            print(outString)
            outString = ''
            debugPrint(value)
        else
            outString = outString .. ' ' .. valueString
        end
    end
    print(outString)
end
local _printThingsSkippingNils = function(outString, ...)
    for _, value in pairs({...}) do
        local valueString = tostring(value)
        if valueString:sub(0, 10) == 'function: ' or valueString:sub(0, 7) == 'table: ' then
            print(outString)
            outString = ''
            debugPrint(value)
        else
            outString = outString .. ' ' .. valueString
        end
    end
    print(outString)
end

return {
    isExtendedLog = function()
        return _isExtendedLogActive
    end,
    thingsOut = function(tab)
        return _printThings('', tab)
    end,
    print = function(...)
        if not(_isExtendedLogActive) then return end
        print('lollo_freestyle_train_station INFO: ', ...)
    end,
    ---@param tab table<any>
    infoOut = function(tab)
        if not(_isExtendedLogActive) then return end
        return _printThings('lollo_freestyle_train_station INFO: ', tab)
    end,
    -- printInfoSkippingNils = function(...)
    --     if not(_isExtendedLogActive) then return end
    --     return _printThingsSkippingNils('lollo_freestyle_train_station INFO: ', ...)
    -- end,
    warn = function(label, ...)
        if not(_isWarningLogActive) then return end
        print('lollo_freestyle_train_station WARNING: ' .. label, ...)
    end,
    ---@param tab table<any>
    warningsOut = function(tab)
        if not(_isWarningLogActive) then return end
        return _printThings('lollo_freestyle_train_station WARNING: ', tab)
    end,
    -- printWarningsSkippingNils = function(...)
    --     if not(_isWarningLogActive) then return end
    --     return _printThingsSkippingNils('lollo_freestyle_train_station WARNING: ', ...)
    -- end,
    err = function(label, ...)
        if not(_isErrorLogActive) then return end
        print('lollo_freestyle_train_station ERROR: ' .. label, ...)
    end,
    ---@param tab table<any>
    errorsOut = function(tab)
        if not(_isErrorLogActive) then return end
        return _printThings('lollo_freestyle_train_station ERROR: ', tab)
    end,
    -- printErrorsSkippingNils = function(...)
    --     if not(_isErrorLogActive) then return end
    --     return _printThingsSkippingNils('lollo_freestyle_train_station ERROR: ', ...)
    -- end,
    debugPrint = function(whatever)
        if not(_isExtendedLogActive) then return end
        if not(debugPrint) then print('lollo_freestyle_train_station no debugPrint available') return end
        debugPrint(whatever)
    end,
    warningDebugPrint = function(whatever)
        if not(_isWarningLogActive) then return end
        if not(debugPrint) then print('lollo_freestyle_train_station no debugPrint available') return end
        debugPrint(whatever)
    end,
    errorDebugPrint = function(whatever)
        if not(_isErrorLogActive) then return end
        if not(debugPrint) then print('lollo_freestyle_train_station no debugPrint available') return end
        debugPrint(whatever)
    end,
    profile = function(label, func)
        if _isTimersActive then
            local results
            local _startSec = os.clock()
            print('######## ' .. tostring(label or '') .. ' starting at ' .. math.ceil(_startSec * 1000) .. ' mSec')
            results = {func()} -- func() may return several results, it's LUA
            local _elapsedSec = os.clock() - _startSec
            print('######## ' .. tostring(label or '') .. ' took ' .. math.ceil(_elapsedSec * 1000) .. ' mSec')
            return table.unpack(results) -- unpack the results as they are supposed to be
        else
            return func()
        end
    end,
    xpInfoHandler = function(error)
        if not(_isExtendedLogActive) then return end
        print('lollo_freestyle_train_station INFO:') debugPrint(error)
    end,
    xpWarningHandler = function(error)
        if not(_isWarningLogActive) then return end
        print('lollo_freestyle_train_station WARNING:') debugPrint(error)
    end,
    xpErrorHandler = function(error)
        if not(_isErrorLogActive) then return end
        print('lollo_freestyle_train_station ERROR:') debugPrint(error)
    end,
}
