package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

print('scratch7 starting')

local logger = require('lollo_freestyle_train_station.logger')
-- local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

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

local posTanX2_curve4 = {
    {
        {0, 0, 0}, {-10, 0, 1}
    },
    {
        {-10, -10, 1}, {0, -10, 1}
    },
}

local posTanX2_curve5 = {
    {
        {0, 0, 0}, {-10, 0, -1}
    },
    {
        {-10, -10, -1}, {0, -10, -1}
    },
}

local moduleHelpers = {
    getTerminalDecoTransf = function(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        return transfUtilsUG.rotZTransl(
            math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
            {
                x = pos1[1],
                y = pos1[2],
                z = pos1[3],
            }
        )
    end,
    getTerminalDecoTransfNEW = function(posTanX2)
        -- print('getTerminalDecoTransf starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        local sinZ = (pos2[2] - pos1[2])
        local cosZ = (pos2[1] - pos1[1])
        local length = math.sqrt(sinZ * sinZ + cosZ * cosZ)
        sinZ, cosZ = sinZ / length, cosZ / length

        return {
            cosZ, sinZ, 0, 0,
            -sinZ, cosZ, 0, 0,
            0, 0, 1, 0,
            pos1[1], pos1[2], pos1[3], 1
        }
    end,
    getPlatformObjectTransf_AlwaysVerticalOLD = function(posTanX2)
        -- print('getPlatformObjectTransf_AlwaysVertical starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        return transfUtilsUG.rotZTransl(
            math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
            {
                x = (pos1[1] + pos2[1]) * 0.5,
                y = (pos1[2] + pos2[2]) * 0.5,
                z = (pos1[3] + pos2[3]) * 0.5,
            }
        )
    end,
    getPlatformObjectTransf_AlwaysVertical = function(posTanX2)
        -- print('getPlatformObjectTransf_AlwaysVertical starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        local sinZ = (pos2[2] - pos1[2]) -- / lengthAcross
        local cosZ = (pos2[1] - pos1[1]) -- / lengthAcross
        local length = math.sqrt(sinZ * sinZ + cosZ * cosZ)
        sinZ, cosZ = sinZ / length, cosZ / length

        return {
            cosZ, sinZ, 0, 0,
            -sinZ, cosZ, 0, 0,
            0, 0, 1, 0,
            (pos1[1] + pos2[1]) * 0.5, (pos1[2] + pos2[2]) * 0.5, (pos1[3] + pos2[3]) * 0.5, 1
        }
    end,
    getPlatformObjectTransf_WithYRotationOLD = function(posTanX2) --, angleYFactor)
        -- print('_getUnderpassTransfWithYRotation starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        local angleZ = math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1])
        local transfZ = transfUtilsUG.rotZTransl(
            angleZ,
            {
                x = (pos1[1] + pos2[1]) * 0.5,
                y = (pos1[2] + pos2[2]) * 0.5,
                z = (pos1[3] + pos2[3]) * 0.5,
            }
        )

        local angleY = math.atan2(
            (pos2[3] - pos1[3]),
            transfUtils.getVectorLength(
                {
                    pos2[1] - pos1[1],
                    pos2[2] - pos1[2],
                    0
                }
            ) -- * (angleYFactor or 1)
        )

        local transfY = transfUtilsUG.rotY(-angleY)

        return transfUtilsUG.mul(transfZ, transfY)
        -- return transfUtilsUG.mul(transfY, transfZ) -- NO!
    end,
    getPlatformObjectTransf_WithYRotation = function(posTanX2) --, angleYFactor)
        -- print('_getUnderpassTransfWithYRotation starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        local sinZ = (pos2[2] - pos1[2])
        local cosZ = (pos2[1] - pos1[1])
        local _lengthZ = math.sqrt(sinZ * sinZ + cosZ * cosZ)
        sinZ, cosZ = sinZ / _lengthZ, cosZ / _lengthZ

        -- local transfZ = {
        --     cosZ,   sinZ,   0,  0,
        --     -sinZ,  cosZ,   0,  0,
        --     0,      0,      1,      0,
        --     (pos1[1] + pos2[1]) * 0.5, (pos1[2] + pos2[2]) * 0.5, (pos1[3] + pos2[3]) * 0.5, 1
        -- }

        local sinY = (pos2[3] - pos1[3])
        local cosY = _lengthZ
        local _lengthY = math.sqrt(sinY * sinY + cosY * cosY)
        sinY, cosY = sinY / _lengthY, cosY / _lengthY

        -- local transfY = {
        --     cosY,   0,  sinY,   0,
        --     0,      1,  0,      0,
        --     -sinY,  0,  cosY,   0,
        --     0,      0,  0,      1
        -- }

        return {
            cosZ * cosY,    sinZ * cosY,    sinY,       0,
            -sinZ,          cosZ,           0,          0,
            -cosZ * sinY,   -sinZ * sinY,   cosY,       0,
            (pos1[1] + pos2[1]) * 0.5,  (pos1[2] + pos2[2]) * 0.5,  (pos1[3] + pos2[3]) * 0.5,  1
        }
    end,
}

local tr1, tr2, tr3, tr4, tr5, tr6, tr7, tr8
local tr1B, tr2B, tr3B, tr4B, tr5B, tr6B, tr7B, tr8B
local tr1C, tr2C, tr3C, tr4C, tr5C, tr6C, tr7C, tr8C
-- logger.profile(
--     'OLD takes',
--     function()
--         for i = 1, 100000, 1 do
--         tr1 = moduleHelpers.getTerminalDecoTransf(posTanX2_straight)
--         tr2 = moduleHelpers.getTerminalDecoTransf(posTanX2_straight_diagonal)
--         tr3 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve1)
--         tr4 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve1_shifted)
--         tr5 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve2)
--         tr6 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve3)
--         tr7 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve4)
--         tr8 = moduleHelpers.getTerminalDecoTransf(posTanX2_curve5)
--         end
--     end
-- )
-- logger.profile(
--     'NEW takes',
--     function()
--         for i = 1, 100000, 1 do
--         tr1B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_straight)
--         tr2B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_straight_diagonal)
--         tr3B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve1)
--         tr4B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve1_shifted)
--         tr5B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve2)
--         tr6B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve3)
--         tr7B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve4)
--         tr8B = moduleHelpers.getTerminalDecoTransfNEW(posTanX2_curve5)
--         end
--     end
-- )
-- logger.profile(
--     'OLD takes',
--     function()
--         for i = 1, 100000, 1 do
--         tr1 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_straight)
--         tr2 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_straight_diagonal)
--         tr3 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve1)
--         tr4 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve1_shifted)
--         tr5 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve2)
--         tr6 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve3)
--         tr7 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve4)
--         tr8 = moduleHelpers.getPlatformObjectTransf_AlwaysVerticalOLD(posTanX2_curve5)
--         end
--     end
-- )
-- logger.profile(
--     'NEW takes',
--     function()
--         for i = 1, 100000, 1 do
--         tr1B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_straight)
--         tr2B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_straight_diagonal)
--         tr3B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve1)
--         tr4B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve1_shifted)
--         tr5B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve2)
--         tr6B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve3)
--         tr7B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve4)
--         tr8B = moduleHelpers.getPlatformObjectTransf_AlwaysVertical(posTanX2_curve5)
--         end
--     end
-- )
-- logger.profile(
--     'OLD',
--     function()
--         for i = 1, 100000, 1 do
--         tr1 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_straight)
--         tr2 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_straight_diagonal)
--         tr3 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve1)
--         tr4 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve1_shifted)
--         tr5 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve2)
--         tr6 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve3)
--         tr7 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve4)
--         tr8 = moduleHelpers.getPlatformObjectTransf_WithYRotationOLD(posTanX2_curve5)
--         end
--     end
-- )
-- logger.profile(
--     'NEW',
--     function()
--         for i = 1, 100000, 1 do
--         tr1B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_straight)
--         tr2B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_straight_diagonal)
--         tr3B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve1)
--         tr4B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve1_shifted)
--         tr5B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve2)
--         tr6B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve3)
--         tr7B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve4)
--         tr8B = moduleHelpers.getPlatformObjectTransf_WithYRotation(posTanX2_curve5)
--         end
--     end
-- )

local sideShift = 2
-- logger.profile(
--     'OLD tr',
--     function()
--         for i = 1, 100000, 1 do
--         tr1 = transfUtils.getParallelSidewaysOLD(posTanX2_straight, sideShift)
--         tr2 = transfUtils.getParallelSidewaysOLD(posTanX2_straight_diagonal, sideShift)
--         tr3 = transfUtils.getParallelSidewaysOLD(posTanX2_curve1, sideShift)
--         tr4 = transfUtils.getParallelSidewaysOLD(posTanX2_curve1_shifted, sideShift)
--         tr5 = transfUtils.getParallelSidewaysOLD(posTanX2_curve2, sideShift)
--         tr6 = transfUtils.getParallelSidewaysOLD(posTanX2_curve3, sideShift)
--         tr7 = transfUtils.getParallelSidewaysOLD(posTanX2_curve4, sideShift)
--         tr8 = transfUtils.getParallelSidewaysOLD(posTanX2_curve5, sideShift)
--         end
--     end
-- )
logger.profile(
    'NEW tr',
    function()
        for i = 1, 100000, 1 do
        tr1C = transfUtils.getParallelSidewaysCoarse(posTanX2_straight, sideShift)
        tr2C = transfUtils.getParallelSidewaysCoarse(posTanX2_straight_diagonal, sideShift)
        tr3C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve1, sideShift)
        tr4C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve1_shifted, sideShift)
        tr5C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve2, sideShift)
        tr6C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve3, sideShift)
        tr7C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve4, sideShift)
        tr8C = transfUtils.getParallelSidewaysCoarse(posTanX2_curve5, sideShift)
        end
    end
)
-- logger.profile(
--     'OLD tr with rot Z',
--     function()
--         for i = 1, 100000, 1 do
--         tr1 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_straight, sideShift)
--         tr2 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_straight_diagonal, sideShift)
--         tr3 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve1, sideShift)
--         tr4 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve1_shifted, sideShift)
--         tr5 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve2, sideShift)
--         tr6 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve3, sideShift)
--         tr7 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve4, sideShift)
--         tr8 = transfUtils.getParallelSidewaysWithRotZOLD(posTanX2_curve5, sideShift)
--         end
--     end
-- )
logger.profile(
    'NEW tr with rot Z',
    function()
        for i = 1, 100000, 1 do
        tr1B = transfUtils.getParallelSideways(posTanX2_straight, sideShift)
        tr2B = transfUtils.getParallelSideways(posTanX2_straight_diagonal, sideShift)
        tr3B = transfUtils.getParallelSideways(posTanX2_curve1, sideShift)
        tr4B = transfUtils.getParallelSideways(posTanX2_curve1_shifted, sideShift)
        tr5B = transfUtils.getParallelSideways(posTanX2_curve2, sideShift)
        tr6B = transfUtils.getParallelSideways(posTanX2_curve3, sideShift)
        tr7B = transfUtils.getParallelSideways(posTanX2_curve4, sideShift)
        tr8B = transfUtils.getParallelSideways(posTanX2_curve5, sideShift)
        end
    end
)
local dummy2 = 123
