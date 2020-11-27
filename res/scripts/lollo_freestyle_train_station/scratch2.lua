package.path = package.path .. ';res/scripts/?.lua'

local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local aaa = { 1, 0, 0, 0,
0, 1, 0, 0,
0, 0, 1, 0,
10, 0, 0, 1}
local inverted = transfUtils.getInverseTransf(aaa)
-- the inverted matrix is 
local aaaInverted = { 1, 0, 0, 0,
0, 1, 0, 0,
0, 0, 1, 0,
-10, 0, 0, 1}

local dummy = 123
