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
  2,
  1.1,
  1.01,
  1.001,
  1.0001,
  1.00001,
  1.000001,
  1.0000001,
  1.00000001,
  1.000000001,
}
utils.isNumVeryClose = function(num1, num2, significantFigures)
  if type(num1) ~= 'number' or type(num2) ~= 'number' then return false end

  if not(significantFigures) then significantFigures = 5
  elseif type(significantFigures) ~= 'number' then return false
  elseif significantFigures < 1 or significantFigures > 10 then return false
  end

  local _formatString = _isVeryCloseFormatStrings[significantFigures]

  -- wrong (less accurate):
  -- local roundedNum1 = math.ceil(num1 * roundingFactor)
  -- local roundedNum2 = math.ceil(num2 * roundingFactor)
  -- better:
  -- local roundedNum1 = math.floor(num1 * roundingFactor + 0.5)
  -- local roundedNum2 = math.floor(num2 * roundingFactor + 0.5)
  -- return roundedNum1 == roundedNum2
  -- but what I really want are the first significant figures, never mind how big the number is
  if (num1 > 0) == (num2 > 0) then
      return (_formatString):format(num1) == (_formatString):format(num2)
          or (_formatString):format(num1 * _isVeryCloseTesters[significantFigures]) == (_formatString):format(num2 * _isVeryCloseTesters[significantFigures])
      else
          return (_formatString):format(num1 - num2) == 0 -- ???????
    end
  end

local vec1 = { 92.263687133789, 602.89776611328, 99.9, -0.0001}
local vec2 = { 91.385019392729, 602.96420214167, 100.0, 0.0001}
local test1 = utils.isNumVeryClose(vec1[1], vec2[1], 3)
local test2 = utils.isNumVeryClose(vec1[2], vec2[2], 3)
local test3 = utils.isNumVeryClose(vec1[3], vec2[3], 3)
local test4 = utils.isNumVeryClose(vec1[4], vec2[4], 3)
local dummy2 = 123
