package.path = package.path .. ';res/scripts/?.lua'

local tab1 = {1, 2, 3, 4, 5}
local index = 0
for _, value in pairs(tab1) do
    index = index + 1
    if index == 2 or index == 4 then tab1[index] = nil end
end
local dummy = 123

local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
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

local mainTransf = { -0.96921515464783, -0.24621538817883, 0, 0, 0.24621538817883, -0.96921515464783, 0, 0, 0, 0, 1, 0, -2769.6831054688, -1132.5921630859, 18.883646011353, 1, }

local myTransf = { -0.96921503543854, -0.24621585011482, 0, 0, 0.24621585011482, -0.96921503543854, 0, 0, 0, 0, 1, 0, -2790.322265625, -1132.6765136719, 18.892417907715, 1, }

local inverseMainTransf = transfUtils.getInverseTransf(mainTransf)
local inverseMyTransf = transfUtils.getInverseTransf(myTransf)

-- local newTransf = transfUtils.mul(mainTransf, inverseMyTransf)


local edgeIds = {111, 222, 333, 444}
local edgeIdsReversed = arrayUtils.sort(edgeIds, nil, false)

local seed = math.randomseed(123)
local rnd = math.random(123, 999)

local root = 'aaa_'
local a2 = 'aaa_2'
local a3 = 'aaa_3'
local tail = string.gsub(a2, root, '')

local kkk = not(nil)
local indexedList = {
    [1010] = 'aaa',
    [1011] = 'bbb',
}
indexedList[1010] = nil

local list1 = { 1919, 1920, 1921 }
local list2 = { 1922, 1923, 1924 }
local listAll = list1
arrayUtils.concatValues(listAll, list2)

local one = nil
local two = 2
local oneOrTwo = one or two

local what = arrayUtils.getLast({})
local what = arrayUtils.getFirst({})

local aka = ''
local akn = tonumber(aka)
local akk = tonumber(nil)

for i = 1, -1 do
    print('LOLLO')
end

for i = 1, 7, 6 do
    print('i ==', i)
end

local a = ("%.5g"):format(234.235534)
local aa = ("%.5g"):format(234235534)
local b = ("%.3g"):format(234.235534)
local bb = ("%.3g"):format(234235534)
--local ccc = ("%.3g"):format(nil) -- error
--local ddd = ("%.3g"):format('sqq') -- error

local isNumVeryClose = function(num1, num2, significantFigures)
    if type(num1) ~= 'number' or type(num2) ~= 'number' then return false end

    if not(significantFigures) then significantFigures = 5
    elseif type(significantFigures) ~= 'number' then return false
    elseif significantFigures < 1 or significantFigures > 10 then return false
    end

    local _formatString = "%." .. math.floor(significantFigures) .. "g"

    -- wrong (less accurate):
    -- local roundedNum1 = math.ceil(num1 * roundingFactor)
    -- local roundedNum2 = math.ceil(num2 * roundingFactor)
    -- better:
    -- local roundedNum1 = math.floor(num1 * roundingFactor + 0.5)
    -- local roundedNum2 = math.floor(num2 * roundingFactor + 0.5)
    -- return roundedNum1 == roundedNum2
    -- but what I really want are the first significant figures, never mind how big the number is
    return (_formatString):format(num1) == (_formatString):format(num2)
        or (_formatString):format(num1 * 1.1) == (_formatString):format(num2 * 1.1)
end

local test0 = isNumVeryClose(0.999999, 1.0000001, 3) -- true
local test1 = isNumVeryClose(0.99999, 1.00001, 3) -- true
local test2 = isNumVeryClose(0.9999, 1.0001, 3) -- true
local test3 = isNumVeryClose(0.999, 1.000, 3) -- true
local test4 = isNumVeryClose(0.999, 1.001, 3) -- true
local test5 = isNumVeryClose(0.99, 1.0000, 3) -- false

local b0 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 1}, {1, 0}) -- 0.707
local b1 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 1}, {0, 1}) -- 0.707
local b2 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 1}, {0, 0}) -- 0
local b3 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 1}, {1, 1}) -- 0
local b4 = transfUtils.getDistanceBetweenPointAndStraight({-4, 0}, {-4, 1}, {1, 0}) -- 5
local b5 = transfUtils.getDistanceBetweenPointAndStraight({-4, 0}, {-4, 1}, {0, 1}) -- 4
local b6 = transfUtils.getDistanceBetweenPointAndStraight({-4, -4}, {-2, -4}, {0, 0}) -- 4
local b7 = transfUtils.getDistanceBetweenPointAndStraight({-4, -4}, {-2, -4}, {-1, 0}) -- 4

local c0 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {1, 0}) -- 1
local c01 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {0.5, 0}) -- 0.5
local c02 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {-0.5, 0}) -- 0.5
local c03 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {0.5, 1}) -- 0.5
local c04 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {-0.5, 0.5}) -- 0.5
local c1 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {0, 1}) -- 0
local c2 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {0, 0}) -- 0
local c3 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {1, 1}) -- 1
local c4 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {-1, 1}) -- 1
local c5 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0, 1}, {-1, 0}) -- 1

local c6 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0.1, 1}, {-1, 1}) -- 1.094
local c7 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {-0.1, 1}, {-1, 1}) -- 0.89
local c8 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {0.1, 1}, {1, 1}) -- 0.89
local c9 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {-0.1, 1}, {1, 1}) -- 1.094

local d0 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {1, 0}) -- 0
local d1 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {0, 1}) -- 1
local d2 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {0.5, 1}) -- 1
local d3 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {0.5, -1}) -- 1
local d4 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {0, 0}) -- 0
local d5 = transfUtils.getDistanceBetweenPointAndStraight({0, 0}, {1, 0}, {1, 1}) -- 1

-- 808.78717041016	-997.80047607422	792.95832642313	-990.78839434966	800.90161479805	-994.2243518885
local e0 = transfUtils.getDistanceBetweenPointAndStraight({808, -997}, {792, -990}, {800, -994}) -- 0.458
local e1 = transfUtils.getDistanceBetweenPointAndStraight({808 - 808, -997}, {792 - 808, -990}, {800 - 808, -994}) -- 0.458
local e2 = transfUtils.getDistanceBetweenPointAndStraight({808 - 808, -997 - 997}, {792 - 808, -990 - 997}, {800 - 808, -994 - 997}) -- 0.458
local dummy = 123

--  id = 24148,
--  node0 = 25258,
--  node1 = 25261,

-- id = 24100,
--   node0 = 24592,
--   node1 = 25290,