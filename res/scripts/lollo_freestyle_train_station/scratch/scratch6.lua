package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local constants = require('lollo_freestyle_train_station.constants')
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
      {0, 0, 0}, {15.707963267949, 0, 0}
  },
  {
      {10, 10, 0}, {0, 15.707963267949, 0}
  },
}

local posTanX2_curve1_shifted = {
  {
      {-9, 0, 0}, {15.707963267949, 0, 0}
  },
  {
      {1, 10, 0}, {0, 15.707963267949, 0}
  },
}

local posTanX2_curve2 = {
  {
      {0, 0, 0}, {-15.707963267949, 0, 0}
  },
  {
      {-10, 10, 0}, {0, 15.707963267949, 0}
  },
}

local posTanX2_curve3 = {
  {
      {0, 0, 0}, {-15.707963267949, 0, 0}
  },
  {
      {-10, -10, 0}, {0, -15.707963267949, 0}
  },
}

local posTanX2_one_fourth_pi_radius_10 = {
    {
        {0, 0, 0,}, {7.8539816339745, 0, 0}
    },
    {
        {7.0710678118655, 2.9289321881345, 0}, {5.553603672698, 5.553603672698, 0}
    }
}

local aP1, bP1, cP1 = transfUtils.getParallelSideways(posTanX2_straight, 2)
local aP2, bP2, cP2 = transfUtils.getParallelSideways(posTanX2_straight, -2)
local aP3, bP3, cP3 = transfUtils.getParallelSideways(posTanX2_straight_diagonal, 2)
local aP4, bP4, cP4 = transfUtils.getParallelSideways(posTanX2_straight_diagonal, -2)
local aP5, bP5, cP5 = transfUtils.getParallelSideways(posTanX2_curve1, 2)
local aP6, bP6, cP6 = transfUtils.getParallelSideways(posTanX2_curve1, -2)
local aP7, bP7, cP7 = transfUtils.getParallelSideways(posTanX2_curve1_shifted, 2)
local aP8, bP8, cP8 = transfUtils.getParallelSideways(posTanX2_curve1_shifted, -2)
local aP9, bP9, cP9 = transfUtils.getParallelSideways(posTanX2_curve2, 2)
local aP10, bP10, cP10 = transfUtils.getParallelSideways(posTanX2_curve2, -2)
local aP11, bP11, cP11 = transfUtils.getParallelSideways(posTanX2_curve3, 2)
local aP12, bP12, cP12 = transfUtils.getParallelSideways(posTanX2_curve3, -2)
local aP13, bP13, cP13 = transfUtils.getParallelSideways(posTanX2_one_fourth_pi_radius_10, -2)
local aP14, bP14, cP14 = transfUtils.getParallelSideways(posTanX2_one_fourth_pi_radius_10, 2)
local aP15, bP15, cP15 = transfUtils.getParallelSideways(
    transfUtils.getPosTanX2Transformed(
        posTanX2_one_fourth_pi_radius_10,
        transfUtils.getTransf_ZRotated(
            constants.idTransf,
            0.65
        )
    ),
    -2
)
local aP16, bP16, cP16 = transfUtils.getParallelSideways(
    transfUtils.getPosTanX2Transformed(
        posTanX2_one_fourth_pi_radius_10,
        transfUtils.getTransf_ZRotated(
            constants.idTransf,
            0.65
        )
    ),
    2
)

local dummy2 = 123

local func2 = function()
    return 1, 2
end

local res1, res2 = logger.profile('my label', func2)

local dummy3 = 123
