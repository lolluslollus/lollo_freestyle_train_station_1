local _isExtendedLogActive = false
local _isWarningLogActive = true
local _isErrorLogActive = true
local _isTimersActive = true

---@param param any
---@return boolean
local _checkIsString = function(param)
    if type(param) == 'string' then return true end

    print('outString must be a string at ')
    -- local info1 = debug.getinfo(1)
    -- if info1 then debugPrint(info1) end
    local info2 = debug.getinfo(2)
    if info2 then debugPrint(info2) end
    local info3 = debug.getinfo(3)
    if info3 then debugPrint(info3) end
    return false
end
---@param outString string
---@param value any
---@return string
local _printOneThing = function(outString, value)
    local typ = type(value)
    if typ == 'function' or typ == 'table' then
        if outString ~= '' then print(outString) end
        debugPrint(value)
        return ''
    else
        return outString .. ' ' .. tostring(value)
    end
end
---@param outString string
---@param tab table<any>
local _printThings = function(outString, tab)
    if not(_checkIsString(outString)) then return end
    if type(tab) ~= 'table' then
        -- local newOutString = _printOneThing(outString, tab)
        -- if newOutString ~= '' then print(newOutString) end
        print(outString .. ' Cannot output non-tab values')
        return
    end

    local nTab = #tab
    if nTab == 0 then --indexed table
        -- if outString ~= '' then print(outString) end
        -- debugPrint(tab)
        print(outString .. ' Cannot output an indexed or empty table. If you want to output a single value or an indexed table, enclose it in curly brackets.')
        return
    end

    local newOutString = outString
    for i = 1, nTab, 1 do
        newOutString = _printOneThing(newOutString, tab[i])
    end
    if newOutString ~= '' then print(newOutString) end
end
local _printThingsVararg = function(outString, ...)
    -- arg is null (obsolete) and ... is numerical; both have no metatable
    if not(_checkIsString(outString)) then return end

    local tab = {...}
    local nTab = select('#', ...) -- LOLLO NOTE not #tab because it will skip the last consecutive nils. select is for varargs, it is NOT a table item counter.
    local newOutString = outString
    for i = 1, nTab, 1 do
        newOutString = _printOneThing(newOutString, tab[i])
    end
    if nTab > 0 then
        if newOutString ~= '' then print(newOutString) end
    else
        print(newOutString .. ' no args were processed')
    end
end

-- func = function(...) print('arg', type(arg)) print('...', type(...), ...) for k, v in pairs({...}) do print('k= ', k, ', v= ', v) end end
-- func = function(...) debugPrint(getmetatable(...)) print('arg has type ', type(arg)) print('... has type ', type(...), 'and num records ', #{...}) debugPrint(getmetatable({...})) for k, v in pairs({...}) do print('k= ', k, ', v= ', v) end end
-- func = function(...) print('... has type ', type(...), ' and num records ', #{...}) local tab = {...} for i=1, #tab, 1 do print('i= ', i, ', v= ', tab[i]) end end
return {
    isExtendedLog = function()
        return _isExtendedLogActive
    end,
    ---@param tab table<any>
    thingsOut = function(tab)
        _printThings('', tab)
    end,
    ---@param ... unknown
    thingOut = function(...)
        _printThingsVararg('', ...)
    end,
    print = function(...)
        if not(_isExtendedLogActive) then return end
        print('lollo_freestyle_train_station INFO: ', ...)
    end,
    ---@param tab table<any>
    infozOut = function(tab)
        if not(_isExtendedLogActive) then return end
        _printThings('lollo_freestyle_train_station INFO: ', tab)
    end,
    ---@param ... unknown
    infoOut = function(...)
        if not(_isExtendedLogActive) then return end
        _printThingsVararg('lollo_freestyle_train_station INFO: ', ...)
    end,
    warn = function(label, ...)
        if not(_isWarningLogActive) then return end
        print('lollo_freestyle_train_station WARNING: ' .. label, ...)
    end,
    ---@param ... unknown
    warningOut = function(...)
        if not(_isWarningLogActive) then return end
        _printThingsVararg('lollo_freestyle_train_station WARNING: ', ...)
    end,
    ---@param tab table<any>
    warningsOut = function(tab)
        if not(_isWarningLogActive) then return end
        _printThings('lollo_freestyle_train_station WARNING: ', tab)
    end,
    err = function(label, ...)
        if not(_isErrorLogActive) then return end
        print('lollo_freestyle_train_station ERROR: ' .. label, ...)
    end,
    ---@param ... unknown
    errorOut = function(...)
        if not(_isErrorLogActive) then return end
        _printThingsVararg('lollo_freestyle_train_station ERROR: ', ...)
    end,
    ---@param tab table<any>
    errorsOut = function(tab)
        if not(_isErrorLogActive) then return end
        _printThings('lollo_freestyle_train_station ERROR: ', tab)
    end,
    ---obsolete
    ---@param whatever any
    debugPrint = function(whatever)
        if not(_isExtendedLogActive) then return end
        if not(debugPrint) then print('lollo_freestyle_train_station no debugPrint available') return end
        debugPrint(whatever)
    end,
    ---obsolete
    ---@param whatever any
    warningDebugPrint = function(whatever)
        if not(_isWarningLogActive) then return end
        if not(debugPrint) then print('lollo_freestyle_train_station no debugPrint available') return end
        debugPrint(whatever)
    end,
    ---obsolete
    ---@param whatever any
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
        _printThings('lollo_freestyle_train_station INFO: ', {error})
    end,
    xpWarningHandler = function(error)
        if not(_isWarningLogActive) then return end
        _printThings('lollo_freestyle_train_station WARNING: ', {error})
    end,
    xpErrorHandler = function(error)
        if not(_isErrorLogActive) then return end
        _printThings('lollo_freestyle_train_station ERROR: ', {error})
    end,
}
