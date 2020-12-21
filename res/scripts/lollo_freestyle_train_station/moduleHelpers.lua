local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local slotUtils = require('lollo_freestyle_train_station.slotHelpers')
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

helpers.getTerrainAlignmentList = function(face)
    local _raiseBy = 0.28 -- a lil bit less than 0.3 to avoid bits of construction being covered by earth
    local raisedFace = {}
    for i = 1, #face do
        raisedFace[i] = face[i]
        raisedFace[i][3] = raisedFace[i][3] + _raiseBy
    end
    -- print('LOLLO raisedFaces =')
    -- debugPrint(raisedFace)
    return {
        faces = {raisedFace},
        optional = true,
        slopeHigh = 99,
        slopeLow = 0.1,
        type = 'EQUAL',
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

helpers.getWaitingAreaTransf = function(wap, inverseMainTransf)
    -- print('wap =') debugPrint(wap)
    local platformPosTanX2 = transfUtils.getPosTanX2Transformed(wap.posTanX2, inverseMainTransf)
    -- print('platformPosTanX2 =') debugPrint(platformPosTanX2)
    -- solve this system:
    -- first point: 0, 0, 0 => platformPosTanX2[1][1]
    -- transf[13] = platformPosTanX2[1][1][1]
    -- transf[14] = platformPosTanX2[1][1][2]
    -- transf[15] = platformPosTanX2[1][1][3]
    -- second point: 1, 0, 0 => platformPosTanX2[2][1]
    -- transf[1] + transf[13] = platformPosTanX2[2][1][1]
    -- transf[2] + transf[14] = platformPosTanX2[2][1][2]
    -- transf[3] + transf[15] = platformPosTanX2[2][1][3]
    local waitingAreaTransf = {
        platformPosTanX2[2][1][1] - platformPosTanX2[1][1][1],
        platformPosTanX2[2][1][2] - platformPosTanX2[1][1][2],
        platformPosTanX2[2][1][3] - platformPosTanX2[1][1][3],
        0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        platformPosTanX2[1][1][1],
        platformPosTanX2[1][1][2],
        platformPosTanX2[1][1][3],
        1
    }
    print('waitingAreaTransf =') debugPrint(waitingAreaTransf)
    return waitingAreaTransf
end

helpers.getTerminalDecoTransf = function(edge)
    -- print('getTerminalDecoTransf starting, edge =') debugPrint(edge)
    local pos1 = edge[1][1]
    local pos2 = edge[2][1]
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

return helpers
