package.path = package.path .. ';res/scripts/?.lua'

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

logger.print('LOLLO')
local dummy = 123
