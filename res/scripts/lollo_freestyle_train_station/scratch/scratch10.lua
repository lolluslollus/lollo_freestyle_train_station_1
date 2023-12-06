package.path = package.path .. ';res/scripts/?.lua'
--package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

print('scratch8 starting')

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
