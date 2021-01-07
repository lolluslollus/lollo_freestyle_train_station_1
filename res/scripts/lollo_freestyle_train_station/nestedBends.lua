local three_nested_bends = {
    { -- outer
        hasBus = false,
        hasTram = false,
        id = 25545,
        node0 = 25418,
        node0pos = { -203.24967956543, -3802.8234863281, 107.46990203857, },
        node0tangent = { -17.580934524536, 0.63046824932098, -1.3194175958633, }, -- length = 17.64164424768
        node1 = 25564,
        node1pos = { -220.59648132324, -3804.9809570313, 106.09600830078, },
        node1tangent = { -16.890789031982, -4.9181070327759, -1.147238612175, }, -- length = 17.64164424768
        streetType = "",
        track = true,
        type = "BASE_EDGE",
    },
    { -- middle
        hasBus = false,
        hasTram = false,
        id = 25395,
        node0 = 25968,
        node0pos = { -203.42886352539, -3807.8203125, 107.46990203857, },
        node0tangent = { -15.982632637024, 0.57315176725388, -1.1994678974152, }, -- length = 16.037823175085
        node1 = 25907,
        node1pos = { -219.19866943359, -3809.7814941406, 106.09600830078, },
        node1tangent = { -15.355231285095, -4.4709968566895, -1.0429420471191, }, -- length = 16.037823175085
        streetType = "",
        track = true,
        type = "BASE_EDGE",
    },
    { -- inner
        hasBus = false,
        hasTram = false,
        id = 25434,
        node0 = 25665,
        node0pos = { -203.60804748535, -3812.8171386719, 107.46990203857, },
        node0tangent = { -14.384330749512, 0.51583522558212, -1.0795183181763, }, -- length = 14.434002109276
        node1 = 25272,
        node1pos = { -217.80085754395, -3814.58203125, 106.09600830078, },
        node1tangent = { -13.819671630859, -4.023886680603, -0.93864542245865, }, -- length = 14.434002109276
        streetType = "",
        track = true,
        type = "BASE_EDGE",
    },
}

-- at node0, I can imagine two vectors of length 5 (the min distance between the tracks) that have:
-- same pos0
-- one has the tangents rotated by 90°, normalised and remultiplied by 5
-- the other has the tangents rotated by -90°, normalised and remultiplied by 5
-- those vectors will be perpendicular to posTanX2[1] and point at their inner or outer siblings
-- How to calculate the rotation?

local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

local _targetParallelDistance = 5

-- setting z to 0 improves accuracy, after all, it's what I am looking for.
-- local vec0Orig = transfUtils.getVectorNormalised({three_nested_bends[1].node0tangent[1], three_nested_bends[1].node0tangent[2], 0}, _targetParallelDistance)
-- local vec0RotatedRight = transfUtils.getVec123Transformed(vec0Orig, transfUtilsUG.rotZ(math.pi * 0.5))
-- local vec0RotatedLeft = transfUtils.getVec123Transformed(vec0Orig, transfUtilsUG.rotZ(-math.pi * 0.5))

-- local vec1Orig = transfUtils.getVectorNormalised({three_nested_bends[1].node1tangent[1], three_nested_bends[1].node1tangent[2], 0}, _targetParallelDistance)
-- local vec1RotatedRight = transfUtils.getVec123Transformed(vec1Orig, transfUtilsUG.rotZ(math.pi * 0.5))
-- local vec1RotatedLeft = transfUtils.getVec123Transformed(vec1Orig, transfUtilsUG.rotZ(-math.pi * 0.5))

-- debugPrint(vec0RotatedRight)
-- debugPrint(vec0RotatedLeft)
-- debugPrint(vec1RotatedRight)
-- debugPrint(vec1RotatedLeft)
local oldPos0 = three_nested_bends[1].node0Pos
local oldPos1 = three_nested_bends[1].node1Pos
local oldTan0 = three_nested_bends[1].node0tangent
local oldTan1 = three_nested_bends[1].node1tangent
print('transfUtils.oneTwoThree2XYZ(oldPos0) =') debugPrint(transfUtils.oneTwoThree2XYZ(oldPos0))
local tan0Rotated = transfUtils.getVectorNormalised({oldTan0[1], oldTan0[2], 0}, _targetParallelDistance)
local newPos0Right = transfUtils.getVec123Transformed(tan0Rotated, transfUtilsUG.rotZTransl(math.pi * 0.5, transfUtils.oneTwoThree2XYZ(oldPos0)))
local newPos0Left = transfUtils.getVec123Transformed(tan0Rotated, transfUtilsUG.rotZTransl(-math.pi * 0.5, transfUtils.oneTwoThree2XYZ(oldPos0)))

local tan1Rotated = transfUtils.getVectorNormalised({oldTan1[1], oldTan1[2], 0}, _targetParallelDistance)
local newPos1Right = transfUtils.getVec123Transformed(tan1Rotated, transfUtilsUG.rotZTransl(math.pi * 0.5, transfUtils.oneTwoThree2XYZ(oldPos1)))
local newPos1Left = transfUtils.getVec123Transformed(tan1Rotated, transfUtilsUG.rotZTransl(-math.pi * 0.5, transfUtils.oneTwoThree2XYZ(oldPos1)))

-- this is an approximation
local oldLength = transfUtils.getVectorLength({
    oldPos0[1] - oldPos1[1],
    oldPos0[2] - oldPos1[2],
    oldPos0[3] - oldPos1[3],
})
local newLengthRight = transfUtils.getVectorLength({
    newPos0Right[1] - newPos1Right[1],
    newPos0Right[2] - newPos1Right[2],
    newPos0Right[3] - newPos1Right[3],
})
local newLengthLeft = transfUtils.getVectorLength({
    newPos0Left[1] - newPos1Left[1],
    newPos0Left[2] - newPos1Left[2],
    newPos0Left[3] - newPos1Left[3],
})

local newTan0Right = {
    oldTan0[1] * newLengthRight / oldLength,
    oldTan0[2] * newLengthRight / oldLength,
    oldTan0[3] * newLengthRight / oldLength,
}
local newTan0Left = {
    oldTan0[1] * newLengthLeft / oldLength,
    oldTan0[2] * newLengthLeft / oldLength,
    oldTan0[3] * newLengthLeft / oldLength,
}

local newTan1Right = {
    oldTan1[1] * newLengthRight / oldLength,
    oldTan1[2] * newLengthRight / oldLength,
    oldTan1[3] * newLengthRight / oldLength,
}
local newTan1Left = {
    oldTan1[1] * newLengthLeft / oldLength,
    oldTan1[2] * newLengthLeft / oldLength,
    oldTan1[3] * newLengthLeft / oldLength,
}

-- local newTan0Right = transfUtils.getVectorNormalised({oldTan0[1], oldTan0[2], 0}, _targetLength)

debugPrint(newPos0Right)
debugPrint(newTan0Right)
debugPrint(newPos0Left)
debugPrint(newTan0Left)
debugPrint(newPos1Right)
debugPrint(newTan1Right)
debugPrint(newPos1Left)
debugPrint(newTan1Left)

-- LOLLO NOTE this seems to work, try it with cargoExtraModules
return newPos0Right, newTan0Right, newPos0Left, newTan0Left, newPos1Right, newTan1Right, newPos1Left, newTan1Left
