package.path = package.path .. ';res/scripts/?.lua'
--package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

print('scratch10 starting')

local logger = require('lollo_freestyle_train_station.logger')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')

local getTab1 = function()
    return {
        [123] = true,
        [124] = true,
        [125] = true
    }
end
local getTab2 = function()
    return {
        [223] = true,
        [124] = true, -- note
        [225] = true
    }
end

debugPrint = function(whatever)
    print('debugPrint =', whatever)
end
-- logger.printInfoSkippingNils('lollo =', function(a) return a end, {1, 2, 3}, {a = 1, b = 2, c = 3}, nil, true, false, 123.456)
-- logger.printWarningsSkippingNils('lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456)
-- logger.infozOut({'lollo =', function(a) return a end, {1, 2, 3}, {a = 1, b = 2, c = 3}, nil, true, false, 123.456})
-- logger.warningsOut({'lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456})
-- logger.errorsOut({'lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456})
-- print('------')
-- logger.errorsOut('lollo =')
-- logger.errorsOut({a = 1, b = 2, c = 3})
-- logger.errorsOut({{a = 1, b = 2, c = 3}})
-- logger.errorsOut(true)
-- logger.errorsOut(false)
-- logger.errorsOut(nil)
-- logger.errorsOut(123.456)
-- print('--------')
-- logger.errorsOut('lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456)

print('######')

logger.warningOut('lollo =', function(a) return a end, {1, 2, 3}, {a = 1, b = 2, c = 3}, nil, true, false, 123.456)
logger.warningOut('lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456)
logger.thingOut(nil,{a = 1, b = 2, c = 3}, nil, true, false, 123.456)
print('------')
logger.warningOut('lollo =')
logger.warningOut({a = 1, b = 2, c = 3})
logger.warningOut({{a = 1, b = 2, c = 3}})
logger.warningOut(true)
logger.warningOut(false)
logger.warningOut(nil)
logger.warningOut(nil, nil)
logger.warningOut(nil, nil, false)
logger.warningOut(false, nil, nil)
logger.warningOut(123.456)
print('--------')
logger.warningOut('lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456)

xpcall(
    function ()
        assert(true == false, 'belandi')
    end,
    logger.errorOut
)

local aaa = function()
    return xpcall(
        function()
            assert(true == false)
            return true
        end,
        function(error)
            return false
        end
    )
end
local aaaIsTrue = aaa()
-- they both take the same
-- logger.profile('### tab', function() for i = 1, 10000 do logger.warningsOut({'lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456}) end end)
-- logger.profile('### vararg', function() for i = 1, 10000 do logger.warningOut('lollo =', {a = 1, b = 2, c = 3}, nil, true, false, 123.456) end end)

local conc = arrayUtils.concatKeysValues(getTab1(), getTab2())
local tab1 = getTab1()
arrayUtils.concatKeysValues(tab1, getTab2())

local tabAll1 = arrayUtils.getConcatKeysValues(getTab1(), getTab2())
local tabAll2 = arrayUtils.getConcatKeysValues({1, 2, 3}, {3, 4, 5})
local tabAll3 = arrayUtils.getConcatValues(getTab1(), getTab2())
local tabAll4 = arrayUtils.getConcatValues({1, 2, 3}, {3, 4, 5})

local aaa = function()
    return xpcall(
        function ()
            local div0 = 123 / 'aa'
            return 'OK'
        end,
        function(err)
            return 'Err'
        end
    )
end
local aaa0, aaa1, aaa2 = aaa()

local dummy = 124
