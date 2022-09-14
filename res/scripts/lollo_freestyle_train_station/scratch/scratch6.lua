package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

local dummy = 123

local posTanX2_straight = {
    {
        {0, 0, 0}, {10, 0, 0}
    },
    {
        {10, 0, 0}, {10, 0, 0}
    },
}

local posTanX2_straight_diagonal = {
    {
        {0, 0, 0}, {10, 10, 0}
    },
    {
        {10, 10, 0}, {10, 10, 0}
    },
}

local posTanX2_curve1 = {
  {
      {0, 0, 0}, {10, 0, 0}
  },
  {
      {10, 10, 0}, {0, 10, 0}
  },
}

local posTanX2_curve1_shifted = {
  {
      {-9, 0, 0}, {10, 0, 0}
  },
  {
      {1, 10, 0}, {0, 10, 0}
  },
}

local posTanX2_curve2 = {
  {
      {0, 0, 0}, {-10, 0, 0}
  },
  {
      {-10, 10, 0}, {0, 10, 0}
  },
}

local posTanX2_curve3 = {
  {
      {0, 0, 0}, {-10, 0, 0}
  },
  {
      {-10, -10, 0}, {0, -10, 0}
  },
}

local aP1, bP1, cP1 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_straight, 2)
local aP2, bP2, cP2 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_straight, -2)
local aP3, bP3, cP3 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_straight_diagonal, 2)
local aP4, bP4, cP4 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_straight_diagonal, -2)
local aP5, bP5, cP5 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve1, 2)
local aP6, bP6, cP6 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve1, -2)
local aP7, bP7, cP7 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve1_shifted, 2)
local aP8, bP8, cP8 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve1_shifted, -2)
local aP9, bP9, cP9 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve2, 2)
local aP10, bP10, cP10 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve2, -2)
local aP11, bP11, cP11 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve3, 2)
local aP12, bP12, cP12 = transfUtils.getParallelSidewaysWithRotZ(posTanX2_curve3, -2)

local dummy2 = 123

local func2 = function()
    return 1, 2
end

local res1, res2 = logger.profile('my label', func2)

local dummy3 = 123
