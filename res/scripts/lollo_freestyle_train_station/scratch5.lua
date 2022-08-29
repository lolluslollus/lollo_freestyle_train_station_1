package.path = package.path .. ';res/scripts/?.lua'


local utils = {}
-- "%." .. math.floor(significantFigures) .. "g"
-- we make the array for performance reasons
local _isVeryCloseFormatStrings = {
    "%.1g",
    "%.2g",
    "%.3g",
    "%.4g",
    "%.5g",
    "%.6g",
    "%.7g",
    "%.8g",
    "%.9g",
    "%.10g",
}
-- 1 + 10^(-significantFigures +1) -- 1.01 with 3 significant figures, 1.001 with 4, etc
-- we make the array for performance reasons
local _isVeryCloseTesters = {
    1.1,
    1.01,
    1.001,
    1.0001,
    1.00001,
    1.000001,
    1.0000001,
    1.00000001,
    1.000000001,
    1.0000000001,
}
-- local _roundingFactors = {
--     10,
--     100,
--     1000,
--     10000,
--     100000,
--     1000000,
--     10000000,
--     100000000,
--     1000000000,
--     10000000000,
-- }

--[[
local _log2 = math.log(2)

local frexpCopied = function(x)
    if x == 0 then return 0.0, 0.0 end
    local e = math.floor(math.log(math.abs(x)) / _log2)
    if e > 0 then
        -- Why not x / 2^e? Because for large-but-still-legal values of e this
        -- ends up rounding to inf and the wheels come off.
        x = x * 2^-e
    else
        x = x / 2^e
    end
    -- Normalize to the range [0.5,1)
    if math.abs(x) >= 1.0 then
        x, e = x/2, e+1
    end
    return x, e
end
]]

local _getResult1 = function(num1, num2, significantFigures)
    local _formatString = _isVeryCloseFormatStrings[significantFigures]
    local result = (_formatString):format(num1) == (_formatString):format(num2)
    return result
end
local _getResult2 = function(num1, num2, significantFigures)
    local result
    local exp1 = math.floor(math.log(math.abs(num1), 10))
    local exp2 = math.floor(math.log(math.abs(num2), 10))
    if exp1 ~= exp2 then
        result = false
    else
        local mant1 = math.floor(num1 * 10^(significantFigures -exp1 -1))
        local mant2 = math.floor(num2 * 10^(significantFigures -exp2 -1))
        result = mant1 == mant2
    end
    return result
end

local _isSameSgnNumVeryClose = function (num1, num2, significantFigures)
    -- local roundingFactor = _roundingFactors[significantFigures]
    -- wrong (less accurate):
    -- local roundedNum1 = math.ceil(num1 * roundingFactor)
    -- local roundedNum2 = math.ceil(num2 * roundingFactor)
    -- better:
    -- local roundedNum1 = math.floor(num1 * roundingFactor + 0.5)
    -- local roundedNum2 = math.floor(num2 * roundingFactor + 0.5)
    -- return math.floor(roundedNum1 / roundingFactor) == math.floor(roundedNum2 / roundingFactor)
    -- but what I really want are the first significant figures, never mind how big the number is
    local result1 = _getResult1(num1, num2, significantFigures)
    or _getResult1(num1 * _isVeryCloseTesters[significantFigures], num2 * _isVeryCloseTesters[significantFigures], significantFigures)

    -- LOLLO NOTE I use subtler testers here
    local result2 = _getResult2(num1, num2, significantFigures)
    or _getResult2(num1 * _isVeryCloseTesters[significantFigures], num2 * _isVeryCloseTesters[significantFigures], significantFigures)

    return result1, result2
end
utils.isNumVeryClose = function(num1, num2, significantFigures)
    if type(num1) ~= 'number' or type(num2) ~= 'number' then return false end

    if not(significantFigures) then significantFigures = 5
    elseif type(significantFigures) ~= 'number' then return false
    elseif significantFigures < 1 then return false
    elseif significantFigures > 10 then significantFigures = 10
    end

    if (num1 > 0) == (num2 > 0) then
        return _isSameSgnNumVeryClose(num1, num2, significantFigures)
    else
        local addFactor = 0
        if math.abs(num1) < math.abs(num2) then
            addFactor = num1 > 0 and -num1 or num1
        else
            addFactor = num2 > 0 and -num2 or num2
        end
        addFactor = addFactor + addFactor -- safely away from 0

        return _isSameSgnNumVeryClose(num1 + addFactor, num2 + addFactor, significantFigures)
    end
end

local vec1 = { 60289776611328, 602.89776611328, 0.60289776611328, 99.9, 99.99, 100.0, 100.0, -0.00012345}
local vec2 = { 60296420214167, 602.96420214167, 0.60296420214167, 100.0, 100.0, 100.1, 100.01, 0.00012345}
local a, b = utils.isNumVeryClose(vec1[1], vec2[1], 3)
local aa, bb = utils.isNumVeryClose(vec1[2], vec2[2], 3)
local aaa, bbb = utils.isNumVeryClose(vec1[3], vec2[3], 3)
local aaaa, bbbb = utils.isNumVeryClose(vec1[4], vec2[4], 3) -- different
local aaaaa, bbbbb = utils.isNumVeryClose(vec1[5], vec2[5], 3) -- same with adjusted testers
local aaaaaa, bbbbbb = utils.isNumVeryClose(vec1[6], vec2[6], 3) -- same with adjusted testers
local aaaaaaa, bbbbbbb = utils.isNumVeryClose(vec1[7], vec2[7], 3) -- same with adjusted testers

local stopHere = 123
