local matrixUtils = require('lollo_freestyle_train_station.matrix')

local utils = {}

local _getMatrix = function(transf)
    return {
        {
            transf[1],
            transf[5],
            transf[9],
            transf[13]
        },
        {
            transf[2],
            transf[6],
            transf[10],
            transf[14]
        },
        {
            transf[3],
            transf[7],
            transf[11],
            transf[15]
        },
        {
            transf[4],
            transf[8],
            transf[12],
            transf[16]
        }
    }
end

local _getTransf = function(mtx)
    return {
        mtx[1][1],
        mtx[2][1],
        mtx[3][1],
        mtx[4][1],
        mtx[1][2],
        mtx[2][2],
        mtx[3][2],
        mtx[4][2],
        mtx[1][3],
        mtx[2][3],
        mtx[3][3],
        mtx[4][3],
        mtx[1][4],
        mtx[2][4],
        mtx[3][4],
        mtx[4][4]
    }
end

utils.flipXYZ = function(m)
    return {
        -m[1],
        -m[2],
        -m[3],
        m[4],
        -m[5],
        -m[6],
        -m[7],
        m[8],
        -m[9],
        -m[10],
        -m[11],
        m[12],
        -m[13],
        -m[14],
        -m[15],
        m[16]
    }
end

utils.mul = function(m1, m2)
    -- returns the product of two 1x16 vectors
    local m = function(line, col)
        local l = (line - 1) * 4
        return m1[l + 1] * m2[col + 0] + m1[l + 2] * m2[col + 4] + m1[l + 3] * m2[col + 8] + m1[l + 4] * m2[col + 12]
    end
    return {
        m(1, 1),
        m(1, 2),
        m(1, 3),
        m(1, 4),
        m(2, 1),
        m(2, 2),
        m(2, 3),
        m(2, 4),
        m(3, 1),
        m(3, 2),
        m(3, 3),
        m(3, 4),
        m(4, 1),
        m(4, 2),
        m(4, 3),
        m(4, 4)
    }
end

utils.getInverseTransf = function(transf)
    local matrix = _getMatrix(transf)
    local invertedMatrix = matrixUtils.invert(matrix)
    return _getTransf(invertedMatrix)
end

-- -- what I imagined first
-- results.getVecTransformed = function(vec, transf)
--     return {
--         x = vec.x * transf[1] + vec.y * transf[2] + vec.z * transf[3] + transf[13],
--         y = vec.x * transf[5] + vec.y * transf[6] + vec.z * transf[7] + transf[14],
--         z = vec.x * transf[9] + vec.y * transf[10] + vec.z * transf[11] + transf[15],
--     }
-- end

-- what coor does, and it makes more sense
utils.getVecTransformed = function(vecXYZ, transf)
    return {
        x = vecXYZ.x * transf[1] + vecXYZ.y * transf[5] + vecXYZ.z * transf[9] + transf[13],
        y = vecXYZ.x * transf[2] + vecXYZ.y * transf[6] + vecXYZ.z * transf[10] + transf[14],
        z = vecXYZ.x * transf[3] + vecXYZ.y * transf[7] + vecXYZ.z * transf[11] + transf[15]
    }
end

utils.getVec123Transformed = function(vec123, transf)
    return {
        vec123[1] * transf[1] + vec123[2] * transf[5] + vec123[3] * transf[9] + transf[13],
        vec123[1] * transf[2] + vec123[2] * transf[6] + vec123[3] * transf[10] + transf[14],
        vec123[1] * transf[3] + vec123[2] * transf[7] + vec123[3] * transf[11] + transf[15]
    }
end

utils.getPosTanX2Transformed = function(posTanX2, transf)
    local pos1 = {posTanX2[1][1][1], posTanX2[1][1][2], posTanX2[1][1][3]}
    local pos2 = {posTanX2[2][1][1], posTanX2[2][1][2], posTanX2[2][1][3]}
    local tan1 = {posTanX2[1][2][1], posTanX2[1][2][2], posTanX2[1][2][3]}
    local tan2 = {posTanX2[2][2][1], posTanX2[2][2][2], posTanX2[2][2][3]}

    local rotateTransf = {
        transf[1], transf[2], transf[3], transf[4],
        transf[5], transf[6], transf[7], transf[8],
        transf[9], transf[10], transf[11], transf[12],
        0, 0, 0, 1
    }

    local result = {
        {
            utils.getVec123Transformed(pos1, transf),
            utils.getVec123Transformed(tan1, rotateTransf)
        },
        {
            utils.getVec123Transformed(pos2, transf),
            utils.getVec123Transformed(tan2, rotateTransf)
        }
    }
    return result
end

utils.position2Transf = function(position)
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        position[1] or position.x, position[2] or position.y, position[3] or position.z, 1
    }
end

utils.transf2Position = function(transf, xyzFormat)
    if xyzFormat then
        return {
            x = transf[13],
            y = transf[14],
            z = transf[15]
        }
    else
        return {
            transf[13],
            transf[14],
            transf[15]
        }
    end
end

utils.oneTwoThree2XYZ = function(arr)
    if type(arr) ~= 'table' and type(arr) ~= 'userdata' then return nil end

    return {
        x = arr[1] or arr.x,
        y = arr[2] or arr.y,
        z = arr[3] or arr.z,
    }
end

utils.getPositionRaisedBy = function(position, raiseBy)
    -- faster than calling mul()
    if position == nil or type(raiseBy) ~= 'number' then return position end

    if position.x ~= nil and position.y ~= nil and position.z ~= nil then
        return {
            x = position.x, y = position.y, z = position.z + raiseBy
        }
    else
        return {
            position[1], position[2], position[3] + raiseBy
        }
    end
end

utils.getVectorLength = function(xyz)
    if type(xyz) ~= 'table' and type(xyz) ~= 'userdata' then return nil end
    local x = xyz.x or xyz[1] or 0.0
    local y = xyz.y or xyz[2] or 0.0
    local z = xyz.z or xyz[3] or 0.0
    return math.sqrt(x * x + y * y + z * z)
end

utils.getVectorNormalised = function(xyz, targetLength)
    if type(xyz) ~= 'table' and type(xyz) ~= 'userdata' then return nil end
    if type(targetLength) == 'number' and targetLength == 0 then return { 0, 0, 0 } end

    local _oldLength = utils.getVectorLength(xyz)
    if _oldLength == 0 then return { 0, 0, 0 } end

    local _lengthFactor = (type(targetLength) == 'number' and targetLength or 1.0) / _oldLength
    if xyz.x ~= nil and xyz.y ~= nil and xyz.z ~= nil then
        return {
            x = xyz.x * _lengthFactor,
            y = xyz.y * _lengthFactor,
            z = xyz.z * _lengthFactor
        }
    else
        return {
            xyz[1] * _lengthFactor,
            xyz[2] * _lengthFactor,
            xyz[3] * _lengthFactor
        }
    end
end

utils.getPositionsDistance = function(pos0, pos1)
    local distance = utils.getVectorLength({
        (pos0.x or pos0[1]) - (pos1.x or pos1[1]),
        (pos0.y or pos0[2]) - (pos1.y or pos1[2]),
        (pos0.z or pos0[3]) - (pos1.z or pos1[3]),
    })
    return distance
end

utils.getPositionsMiddle = function(pos0, pos1)
    local midPos = {
        ((pos0.x or pos0[1]) + (pos1.x or pos1[1])) * 0.5,
        ((pos0.y or pos0[2]) + (pos1.y or pos1[2])) * 0.5,
        ((pos0.z or pos0[3]) + (pos1.z or pos1[3])) * 0.5,
    }

    if pos0.x ~= nil and pos0.y ~= nil and pos0.z ~= nil then
        return {
            x = midPos[1],
            y = midPos[2],
            z = midPos[3]
        }
    else
        return midPos
    end
end

utils.getParallelSideways = function(posTanX2, sideShift)
    local result = {
        {
            {},
            posTanX2[1][2]
        },
        {
            {},
            posTanX2[2][2]
        },
    }

    local oldPos1 = posTanX2[1][1]
    local oldPos2 = posTanX2[2][1]

    local ro = math.atan2(oldPos2[2] - oldPos1[2], oldPos2[1] - oldPos1[1])

    result[1][1] = { oldPos1[1] + math.sin(ro) * sideShift, oldPos1[2] - math.cos(ro) * sideShift, oldPos1[3] }
    result[2][1] = { oldPos2[1] + math.sin(ro) * sideShift, oldPos2[2] - math.cos(ro) * sideShift, oldPos2[3] }

    return result
end

utils.get1MLaneTransf = function(pos1, pos2)
    -- gets a transf to fit a 1 m long model (typically a lane) between two points
    -- using transfUtils.getVecTransformed(), solve this system:
    -- first point: 0, 0, 0 => pos1
    -- transf[13] = pos1[1]
    -- transf[14] = pos1[2]
    -- transf[15] = pos1[3]
    -- second point: 1, 0, 0 => pos2
    -- transf[1] + transf[13] = pos2[1]
    -- transf[2] + transf[14] = pos2[2]
    -- transf[3] + transf[15] = pos2[3]
    -- third point: 0, 1, 0 => pos1 + { 0, 1, 0 }
    -- transf[5] + transf[13] = pos1[1]
    -- transf[6] + transf[14] = pos1[2] + 1
    -- transf[7] + transf[15] = pos1[3]
    -- fourth point: 0, 0, 1 => pos1 + { 0, 0, 1 }
    -- transf[9] + transf[13] = pos1[1]
    -- transf[10] + transf[14] = pos1[2]
    -- transf[11] + transf[15] = pos1[3] + 1
    -- fifth point: 1, 1, 0 => pos2 + { 0, 1, 0 }
    -- transf[1] + transf[5] + transf[13] = pos2[1]
    -- transf[2] + transf[6] + transf[14] = pos2[2] + 1
    -- transf[3] + transf[7] + transf[15] = pos2[3]
    local result = {
        pos2[1] - pos1[1],
        pos2[2] - pos1[2],
        pos2[3] - pos1[3],
        0,
        0, 1, 0,
        0,
        0, 0, 1,
        0,
        pos1[1],
        pos1[2],
        pos1[3],
        1
    }
    -- print('unitaryLaneTransf =') debugPrint(result)
    return result
end

utils.getPosTanX2Normalised = function(posTanX2)
    local pos1 = {posTanX2[1][1][1], posTanX2[1][1][2], posTanX2[1][1][3]}
    local tan1 = utils.getVectorNormalised(posTanX2[1][2], 2)
    local tan2 = utils.getVectorNormalised(posTanX2[2][2], 2)
    local pos2 = {
        posTanX2[1][1][1] + tan1[1],
        posTanX2[1][1][2] + tan1[2],
        posTanX2[1][1][3] + tan1[3],
    }

    local result = {
        {
            pos1,
            tan1
        },
        {
            pos2,
            tan2
        }
    }
    return result
end

utils.getExtrapolatedPosTanX2Continuation = function(posTanX2, length)
    if length == 0 then
        return posTanX2
    -- elseif length > 0 then
    else
        local oldPos2 = {posTanX2[2][1][1], posTanX2[2][1][2], posTanX2[2][1][3]}
        local newTan = utils.getVectorNormalised(posTanX2[2][2], length)

        local result = {
            {
                oldPos2,
                newTan
            },
            {
                {
                    oldPos2[1] + newTan[1],
                    oldPos2[2] + newTan[2],
                    oldPos2[3] + newTan[3],
                },
                newTan
            }
        }
        return result
    end
end

utils.getShiftedEdgePositionsOLD = function(edgeLists, sideShift)
    local results = {
        {
            -- catenary = edgeLists[1].catenary,
            posTanX2 = utils.getParallelSideways(edgeLists[1].posTanX2, sideShift),
            -- trackType = edgeLists[1].trackType,
            -- trackTypeName = edgeLists[1].trackTypeName,
            -- type = edgeLists[1].type,
            -- typeIndex = edgeLists[1].typeIndex
        }
    }
    local previousPosTanX2 = results[1].posTanX2
    for i = 2, #edgeLists do
        local currentPosTanX2 = utils.getParallelSideways(edgeLists[i].posTanX2, sideShift)
        currentPosTanX2[1][1] = previousPosTanX2[2][1]
        results[#results+1] = {
            -- catenary = edgeLists[i].catenary,
            posTanX2 = currentPosTanX2,
            -- trackType = edgeLists[i].trackType,
            -- trackTypeName = edgeLists[i].trackTypeName,
            -- type = edgeLists[i].type,
            -- typeIndex = edgeLists[i].typeIndex
        }
        previousPosTanX2 = currentPosTanX2
    end

    return results
end

utils.getShiftedEdgePositions = function(posTanX2Owners, sideShift, index1, indexN)
    -- LOLLO TODO check this function, it's new
    local i1 = index1
    local iN = indexN
    if type(i1) ~= 'number' or i1 < 1 then i1 = 1 end
    if type(iN) ~= 'number' or iN > #posTanX2Owners then iN = #posTanX2Owners end

    local results = {}
    for i = i1, iN do
        results[#results+1] = {
            -- catenary = edgeLists[i].catenary,
            posTanX2 = utils.getParallelSideways(posTanX2Owners[i].posTanX2, sideShift),
            -- trackType = edgeLists[i].trackType,
            -- trackTypeName = edgeLists[i].trackTypeName,
            -- type = edgeLists[i].type,
            -- typeIndex = edgeLists[i].typeIndex
        }
    end

    for i = 1, #results - 1 do
        local pos1 = results[i].posTanX2[2][1]
        local pos2 = results[i + 1].posTanX2[1][1]
        if pos1[1] ~= pos2[1] or pos1[2] ~= pos2[2] or pos1[3] ~= pos2[3] then
            -- an average is cheaper than working out the intersection
            local oldLength1 = utils.getPositionsDistance(results[i].posTanX2[1][1], results[i].posTanX2[2][1])
            local oldLength2 = utils.getPositionsDistance(results[i + 1].posTanX2[1][1], results[i + 1].posTanX2[2][1])

            local newPos = utils.getPositionsMiddle(pos1, pos2)
            local newLength1 = utils.getPositionsDistance(results[i].posTanX2[1][1], newPos)
            local newLength2 = utils.getPositionsDistance(newPos, results[i + 1].posTanX2[2][1])
            local tanCorrectionFactor1 = newLength1 / oldLength1
            local tanCorrectionFactor2 = newLength2 / oldLength2

            results[i].posTanX2[2][1] = newPos
            results[i].posTanX2[2][2] = {
                results[i].posTanX2[2][2][1] * tanCorrectionFactor1,
                results[i].posTanX2[2][2][2] * tanCorrectionFactor1,
                results[i].posTanX2[2][2][3] * tanCorrectionFactor1,
            }

            results[i + 1].posTanX2[1][1] = newPos
            results[i + 1].posTanX2[1][2] = {
                results[i + 1].posTanX2[1][2][1] * tanCorrectionFactor2,
                results[i + 1].posTanX2[1][2][2] * tanCorrectionFactor2,
                results[i + 1].posTanX2[1][2][3] * tanCorrectionFactor2,
            }
        end
    end

    return results
end

utils.isNumVeryClose = function(num1, num2, significantFigures)
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
    -- LOLLO TODO test this THOROUGHLY
    return (_formatString):format(num1) == (_formatString):format(num2)
        or (_formatString):format(num1 * 1.1) == (_formatString):format(num2 * 1.1)
end

utils.sgn = function(num)
    if tonumber(num) == nil then return nil end
    if num > 0 then return 1
    elseif num < 0 then return -1
    else return 0
    end
end

utils.getDistanceBetweenPointAndStraight = function(segmentPosition1, segmentPosition2, testPointPosition)
    -- a + bx = y
    -- => a + b * x1 = y1
    -- => a + b * x2 = y2
    -- => b * (x1 - x2) = y1 - y2
    -- => b = (y1 - y2) / (x1 - x2)
    -- OR division by zero
    -- => a = y1 - b * x1
    -- => a = y1 - (y1 - y2) / (x1 - x2) * x1
    -- a + b * xM > yM <= this is what we want to know
    -- => y1 - (y1 - y2) / (x1 - x2) * x1 + (y1 - y2) / (x1 - x2) * xM > yM
    -- => y1 * (x1 - x2) - (y1 - y2) * x1 + (y1 - y2) * xM > yM * (x1 - x2)
    -- => (y1 - yM) * (x1 - x2) + (y1 - y2) * (xM - x1) > 0

    local x1 = segmentPosition1[1] or segmentPosition1.x
    local y1 = segmentPosition1[2] or segmentPosition1.y
    local x2 = segmentPosition2[1] or segmentPosition2.x
    local y2 = segmentPosition2[2] or segmentPosition2.y
    local xM = testPointPosition[1] or testPointPosition.x
    local yM = testPointPosition[2] or testPointPosition.y
    print('getDistanceBetweenPointAndStraight received coords =', x1, y1, x2, y2, xM, yM)
    local b = (y1 - y2) / (x1 - x2)
    local a = y1 - (y1 - y2) / (x1 - x2) * x1
    -- local yMDist = math.abs(yM - b * xM - a) / math.sqrt(1 + b * b)
    -- local yMDist = math.abs(yM - (y1 - y2) / (x1 - x2) * xM  - y1 + (y1 - y2) / (x1 - x2) * x1) / math.sqrt(1 + (y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2))
    -- local yMDist = math.abs(yM - y1 + (y1 - y2) / (x1 - x2) * (x1 - xM)) / math.sqrt(1 + (y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2))

    -- Ax + By + C = 0
    -- dist = math.abs(A * xM + B * yM + C) / math.sqrt(A * A + B * B)
    -- => -A/B x -C/B = y
    -- => b = -A/B, a = -C/B
    -- => dist = math.abs(A/B * xM + yM + C/B) / math.sqrt(A/B * A/B + 1)
    -- => dist = math.abs(-b * xM + yM -a) / math.sqrt(b * b + 1)
    -- => dist = math.abs(-(y1 - y2) / (x1 - x2) * xM + yM -(y1 - (y1 - y2) / (x1 - x2) * x1)) / math.sqrt((y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2) + 1)
    -- => dist = math.abs(-(y1 - y2) / (x1 - x2) * xM + yM -y1 + (y1 - y2) / (x1 - x2) * x1) / math.sqrt((y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2) + 1)
    -- => dist = math.abs((y1 - y2) / (x1 - x2) * (x1 -xM ) + yM -y1) / math.sqrt((y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2) + 1)
    local yMDist = 0
    if x1 == x2 then
        if y1 == y2 then return utils.getPositionsDistance(segmentPosition1, testPointPosition) end
        return math.abs(x1 - xM)
    else
        -- return math.abs(yM + (y1 - y2) / (x1 - x2) * (x1 - xM)) / math.sqrt(1 + (y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2))
        return math.abs(yM - y1 + (y1 - y2) / (x1 - x2) * (x1 - xM)) / math.sqrt(1 + (y1 - y2) / (x1 - x2) * (y1 - y2) / (x1 - x2))
    end

end

return utils
