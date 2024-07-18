package.path = package.path .. ';res/scripts/?.lua'

print('scratch3 starting')

local dumb = ({2, 3, 4} == 'LOLLO') -- false, no errors
dumb = (nil == nil) -- true
local abaBool = true
local abaNum = 78
local abaStr = 'ABC'
local abbBool = abaBool or false
local abbNum = abaNum or false
local abbStr = abaStr or false

local aba = {1, {2, 3}, {{4, 5}}}
local abb = {6, {7, 8}, {{9, 0}}}
aba, abb = abb, aba -- you can swap without 3rd variable coz lua assigns both variables at the same time

local arr = {}
arr[7] = {a = 10, b = 20}
arr[7][8] = {c = 10, d = 20}
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local logger = require('lollo_freestyle_train_station.logger')

local posNW = transfUtils.oneTwoThree2XYZ({ -1, 2, 0 })
local posNE = transfUtils.oneTwoThree2XYZ({ 1, 2, 0 })
local posSE = transfUtils.oneTwoThree2XYZ({ 1, -2, 0 })
local posSW = transfUtils.oneTwoThree2XYZ({ -1, -2, 0 })

local newPosNW = transfUtils.oneTwoThree2XYZ({ -1, 2, 0 })
local newPosNE = transfUtils.oneTwoThree2XYZ({ 1, 2, 0 })
local newPosSE = transfUtils.oneTwoThree2XYZ({ 1, -2, 0 })
local newPosSW = transfUtils.oneTwoThree2XYZ({ -1, -2, 0 })

local test1 = transfUtils.getSkewTransf(posNW, posNE, posSE, posSW, newPosNW, newPosNE, newPosSE, newPosSW)


local posNW = transfUtils.oneTwoThree2XYZ({ -1, 2, 0 })
local posNE = transfUtils.oneTwoThree2XYZ({ 1, 2, 0 })
local posSE = transfUtils.oneTwoThree2XYZ({ 1, -2, 0 })
local posSW = transfUtils.oneTwoThree2XYZ({ -1, -2, 0 })

local newPosNW = transfUtils.oneTwoThree2XYZ({ -2, 2, 0 })
local newPosNE = transfUtils.oneTwoThree2XYZ({ 2, 2, 0 })
local newPosSE = transfUtils.oneTwoThree2XYZ({ 1, -2, 0 })
local newPosSW = transfUtils.oneTwoThree2XYZ({ -1, -2, 0 })

local test2 = transfUtils.getSkewTransf(posNW, posNE, posSE, posSW, newPosNW, newPosNE, newPosSE, newPosSW)

logger.print('1', '2', 3)

local platformHeightModuleNames = {
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight0.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight25.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight40.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight60.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight80.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight100.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight110.module',
    'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight125.module',
}
-- local regex = "/station\/rail\/lollo_freestyle_train_station\/platformHeights\/platformHeight(\d*)\.module/iu"
for _, name in pairs(platformHeightModuleNames) do
    local adj1 = string.gsub(name, 'station/rail/lollo_freestyle_train_station/platformHeights/platformHeight', '')
    local adj = string.gsub(adj1, '.module', '')
    local heightCm = tonumber(adj, 10)
    print('heightCm =', heightCm)
end

logger.print('LOLLO')
local dummy = 123
