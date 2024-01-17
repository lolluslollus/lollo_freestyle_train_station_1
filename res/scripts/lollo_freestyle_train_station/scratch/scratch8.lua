package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

print('scratch8 starting')

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

local transf1 = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 1
}

local transf11 = transfUtilsUG.mul(transf1, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  4, 2, 1.2, 1 })
local transf12 = transfUtils.getTransf_Shifted(transf1, {4, 2, 1.2})

local vec1 = {2, 5, 11}
local rot90 = transfUtils.getVec123ZRotatedP90Deg(vec1)
local rot180_1 = transfUtils.getVec123ZRotatedP90Deg(rot90)
local rot180_2 = transfUtils.getVec123ZRotated180Deg(vec1)

local pos = {0, 2, 0}
local segPos1 = {-1, 0, 0}
local segPos2 = {2, 0, 0}
local intersection_ERR = transfUtils.getPointToSegmentNormalIntersection_3D(pos, segPos1, segPos1)
local intersection_1 = transfUtils.getPointToSegmentNormalIntersection_3D(pos, segPos1, segPos2)

local intersection_2 = transfUtils.getPointToSegmentNormalIntersection_3D(
    {0, 2, 0},
    {-1, 0, 3},
    {2, 0, 0}
)

local intersection_3 = transfUtils.getPointToSegmentNormalIntersection_3D(
    {0, 2, 0},
    {-1, 0, 3},
    {2, 0, 3}
)

local intersection_4 = transfUtils.getPointToSegmentNormalIntersection_3D(
    {0, 2, 3},
    {-1, 0, 3},
    {2, 0, 3}
)

local dummy = 124
