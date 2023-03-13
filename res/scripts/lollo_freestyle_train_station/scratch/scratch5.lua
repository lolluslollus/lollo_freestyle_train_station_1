package.path = package.path .. ';res/scripts/?.lua'

local comparisonUtils = require('lollo_freestyle_train_station.comparisonUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

local vec1 = { 60289776611328, 602.89776611328, 0.00060289776611328, 99.9, 99.99, 100.0, 100.0, -0.00012345}
local vec2 = { 60296420214167, 602.96420214167, 0.00060296420214167, 100.0, 100.0, 100.1, 100.01, 0.00012345}
-- print('mSec =', os.clock() * 1000)
    local a, b = comparisonUtils.isNumsVeryClose(vec1[1], vec2[1], 3)
    local aa, bb = comparisonUtils.isNumsVeryClose(vec1[2], vec2[2], 3)
    local aaa, bbb = comparisonUtils.isNumsVeryClose(vec1[3], vec2[3], 3)
    local aaaa, bbbb = comparisonUtils.isNumsVeryClose(vec1[4], vec2[4], 3) -- the first is more tolerant
    local aaaaa, bbbbb = comparisonUtils.isNumsVeryClose(vec1[5], vec2[5], 3) -- same
    local aaaaaa, bbbbbb = comparisonUtils.isNumsVeryClose(vec1[6], vec2[6], 3) -- same
    local aaaaaaa, bbbbbbb = comparisonUtils.isNumsVeryClose(vec1[7], vec2[7], 3) -- same
    local aaaaaaaa, bbbbbbbb = comparisonUtils.isNumsVeryClose(vec1[8], vec2[8], 3)
-- print('mSec =', os.clock() * 1000) -- 1661804180 - 1661804188 with the string format
local results = {}
for i = 1, 8 do
    results[i] = comparisonUtils.isNumsCloserThan(vec1[i], vec2[i], 0.001)
end

local vec1M = { -60289776611328, -602.89776611328, -0.00060289776611328, -99.9, -99.99, -100.0, -100.0, 0.00012345}
local vec2M = { -60296420214167, -602.96420214167, -0.00060296420214167, -100.0, -100.0, -100.1, -100.01, -0.00012345}
-- print('mSec =', os.clock() * 1000)
    local aM, bM = comparisonUtils.isNumsVeryClose(vec1M[1], vec2M[1], 3)
    local aaM, bbM = comparisonUtils.isNumsVeryClose(vec1M[2], vec2M[2], 3)
    local aaaM, bbbM = comparisonUtils.isNumsVeryClose(vec1M[3], vec2M[3], 3)
    local aaaaM, bbbbM = comparisonUtils.isNumsVeryClose(vec1M[4], vec2M[4], 3) -- the first is more tolerant
    local aaaaaM, bbbbbM = comparisonUtils.isNumsVeryClose(vec1M[5], vec2M[5], 3) -- same
    local aaaaaaM, bbbbbbM = comparisonUtils.isNumsVeryClose(vec1M[6], vec2M[6], 3) -- same
    local aaaaaaaM, bbbbbbbM = comparisonUtils.isNumsVeryClose(vec1M[7], vec2M[7], 3) -- same
    local aaaaaaaaM, bbbbbbbbM = comparisonUtils.isNumsVeryClose(vec1M[8], vec2M[8], 3)

local resultsM = {}
for i = 1, 8 do
    resultsM[i] = comparisonUtils.isNumsCloserThan(vec1M[i], vec2M[i], 0.001)
end

local stopHere = 123
