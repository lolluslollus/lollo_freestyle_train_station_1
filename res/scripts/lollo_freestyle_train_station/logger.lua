local _isExtendedLogActive = false
local _isWarningLogActive = true
local _isErrorLogActive = true
local _isTimersActive = false

return {
    isExtendedLog = function()
        return _isExtendedLogActive
    end,
    print = function(...)
        if not(_isExtendedLogActive) then return end
        print('lollo_freestyle_train_station INFO: ', ...)
    end,
    warn = function(label, ...)
        if not(_isWarningLogActive) then return end
        print('lollo_freestyle_train_station WARNING: ' .. label, ...)
    end,
    err = function(label, ...)
        if not(_isErrorLogActive) then return end
        print('lollo_freestyle_train_station ERROR: ' .. label, ...)
    end,
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
    xpHandler = function(error)
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
