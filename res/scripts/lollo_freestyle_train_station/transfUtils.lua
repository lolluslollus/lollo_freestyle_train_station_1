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
    local point1 = {posTanX2[1][1][1], posTanX2[1][1][2], posTanX2[1][1][3]}
    local point2 = {posTanX2[2][1][1], posTanX2[2][1][2], posTanX2[2][1][3]}
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
            utils.getVec123Transformed(point1, transf),
            utils.getVec123Transformed(tan1, rotateTransf)
        },
        {
            utils.getVec123Transformed(point2, transf),
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

return utils
