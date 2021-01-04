local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local slotUtils = require('lollo_freestyle_train_station.slotHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require 'transf'


local helpers = {}

helpers.getGroundFace = function(face, key)
    return {
        face = face, -- LOLLO NOTE Z is ignored here
        loop = true,
        modes = {
            {
                type = 'FILL',
                key = key
            }
        }
    }
end

helpers.getTerrainAlignmentList = function(face, raiseBy, alignmentType, slopeHigh, slopeLow)
    if type(raiseBy) ~= 'number' then raiseBy = 0 end
    if stringUtils.isNullOrEmptyString(alignmentType) then alignmentType = 'EQUAL' end -- GREATER, LESS
    if type(slopeHigh) ~= 'number' then slopeHigh = 99 end
    if type(slopeLow) ~= 'number' then slopeLow = 0.1 end
    -- With “EQUAL” the terrain is aligned exactly to the specified faces,
    -- with “LESS” only higher areas are taken down,
    -- with “GREATER” areas below the faces will be filled up.
    -- local raiseBy = 0 -- 0.28 -- a lil bit less than 0.3 to avoid bits of construction being covered by earth
    local raisedFace = {}
    for i = 1, #face do
        raisedFace[i] = face[i]
        raisedFace[i][3] = raisedFace[i][3] + raiseBy
    end
    -- print('LOLLO raisedFaces =')
    -- debugPrint(raisedFace)
    return {
        faces = {raisedFace},
        optional = true,
        slopeHigh = slopeHigh,
        slopeLow = slopeLow,
        type = alignmentType,
    }
end

-- LOLLO NOTE adding colliders with this seems correct,
-- but calling it from con.updateFn or from a module.updateFn or terminateConstructionHook
-- will result in no colliders at all being active,
-- except for the edge colliders
helpers.getCollider = function(sidewalkWidth, model)
	local result = nil
	if sidewalkWidth < 3.8 then
		if slotUtils.getIsStreetside(model.tag) then
			local transfRes = transfUtilsUG.mul(
				model.transf,
				{ 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, sidewalkWidth * 0.5, 0, 1 }
			)
			-- print('LOLLO transfRes =')
			-- debugPrint(transfRes)
			result = {
				params = {
					halfExtents = { 5.9, 1.9 - sidewalkWidth * 0.5, 1.0 },
				},
				transf = transfRes,
				type = 'BOX',
			}
		end

		-- print('LOLLO model =')
		-- debugPrint(model)
		-- print('LOLLO collider =')
		-- debugPrint(result)
	end

	return result
end

helpers.get1MLaneTransf = function(pos1, pos2)
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

helpers.getTerminalDecoTransf = function(posTanX2)
    -- print('getTerminalDecoTransf starting, posTanX2 =') debugPrint(posTanX2)
    local pos1 = posTanX2[1][1]
    local pos2 = posTanX2[2][1]
    local newTransf = transfUtilsUG.rotZTransl(
        math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
        {
            x = pos1[1],
            y = pos1[2],
            z = pos1[3],
        }
    )

    -- print('newTransf =') debugPrint(newTransf)
    return newTransf
end

helpers.getPlatformObjectTransf_AlwaysVertical = function(posTanX2)
    -- print('getPlatformObjectTransf_AlwaysVertical starting, posTanX2 =') debugPrint(posTanX2)
    local pos1 = posTanX2[1][1]
    local pos2 = posTanX2[2][1]

    local newTransf = transfUtilsUG.rotZTransl(
        math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
        -- {
        -- 	x = pos1[1],
        -- 	y = pos1[2],
        -- 	z = pos1[3] + 1,
        -- }
        {
            x = (pos1[1] + pos2[1]) * 0.5,
            y = (pos1[2] + pos2[2]) * 0.5,
            z = (pos1[3] + pos2[3]) * 0.5 + 1,
        }
    )

    -- print('newTransf =') debugPrint(newTransf)
    return newTransf
end

helpers.getPlatformObjectTransf_WithYRotation = function(posTanX2)
    -- print('_getUnderpassTransfWithYRotation starting, posTanX2 =') debugPrint(posTanX2)
    local pos1 = posTanX2[1][1]
    local pos2 = posTanX2[2][1]
    -- local newTransf = transfUtilsUG.rotZYXTransl( -- NO!
    -- 	{
    -- 		x = 0, ---math.atan2(pos2[3] - pos1[3], pos2[2] - pos1[2]),
    -- 		y = 0, -- -math.atan2(pos2[3] - pos1[3], pos2[1] - pos1[1]),
    -- 		z = math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
    -- 	},
    -- 	{
    -- 		x = (pos1[1] + pos2[1]) * 0.5,
    -- 		y = (pos1[2] + pos2[2]) * 0.5,
    -- 		z = (pos1[3] + pos2[3]) * 0.5 + 1,
    -- 	}
    -- )
    local newTransf = transfUtilsUG.rotZTransl(
        math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
        -- {
            -- 	x = pos1[1],
            -- 	y = pos1[2],
            -- 	z = pos1[3] + 1,
        -- }
        {
            x = (pos1[1] + pos2[1]) * 0.5,
            y = (pos1[2] + pos2[2]) * 0.5,
            z = (pos1[3] + pos2[3]) * 0.5 + 1,
        }
    )
    local angle = -math.atan((pos2[3] - pos1[3]) / edgeUtils.getVectorLength(
        {
            pos2[1] - pos1[1],
            pos2[2] - pos1[2],
            0
        }
    ))

    -- print('angle =') debugPrint(angle)
    local newTransf2 = transfUtilsUG.rotY(angle)

    local result = transfUtilsUG.mul(newTransf, newTransf2)
    return result
end

helpers.getPosTanX2Normalised = function(posTanX2)
    local pos1 = {posTanX2[1][1][1], posTanX2[1][1][2], posTanX2[1][1][3]}
    local tan1 = edgeUtils.getVectorNormalised(posTanX2[1][2], 2)
    local tan2 = edgeUtils.getVectorNormalised(posTanX2[2][2], 2)
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

helpers.getExtrapolatedPosTanX2Continuation = function(posTanX2, length)
    -- local oldPos1 = {posTanX2[1][1][1], posTanX2[1][1][2], posTanX2[1][1][3]}
    local oldPos2 = {posTanX2[2][1][1], posTanX2[2][1][2], posTanX2[2][1][3]}
    -- local tan1 = edgeUtils.getVectorNormalised(posTanX2[1][2], length)
    local newTan = edgeUtils.getVectorNormalised(posTanX2[2][2], length)

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

helpers.getYShift4SlopedArea = function(params, t, i, slopedAreaWidth)
    local isTrackOnPlatformLeft = params.terminals[t].isTrackOnPlatformLeft
    local platformWidth = params.terminals[t].centrePlatforms[i].width

    local baseYShift = (slopedAreaWidth + platformWidth) * 0.5 -0.35
    -- local baseYShift = slopedAreaWidth * 0.5 + platformWidth - 1.6

    local yShiftOutside = isTrackOnPlatformLeft and -baseYShift or baseYShift
    local yShiftOutside4StreetAccess = slopedAreaWidth * 2 - 1.8

    return yShiftOutside, yShiftOutside4StreetAccess
end

return helpers
