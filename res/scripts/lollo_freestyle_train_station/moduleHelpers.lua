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
    -- print('waitingAreaTransf =') debugPrint(waitingAreaTransf)
    return waitingAreaTransf
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

helpers.getUnderpassTransf = function(posTanX2)
    -- print('getUnderpassTransf starting, posTanX2 =') debugPrint(posTanX2)
    local pos1 = posTanX2[1][1]
    local pos2 = posTanX2[2][1]
    -- local newTransf = transfUtilsUG.rotZYXTransl(
    --     {
    --         x = 0,
    --         y = -math.atan2(pos2[3] - pos1[3], pos2[1] - pos1[1]),
    --         z = math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
    --     },
    --     {
    --         x = pos1[1],
    --         y = pos1[2],
    --         z = pos1[3],
    --     }
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

    -- print('newTransf =') debugPrint(newTransf)
    if true then return newTransf end

    print('newTransf =') debugPrint(newTransf)

    -- print('angle on Y axis (deg) with atan =') debugPrint(math.atan((pos2[3] - pos1[3]) / (pos2[1] - pos1[1])) * 180 / math.pi)
    -- print('angle on Y axis (deg) with atan2 =') debugPrint(math.atan2(pos2[3] - pos1[3], pos2[1] - pos1[1]) * 180 / math.pi)
    -- print('rotY =') debugPrint(transfUtilsUG.rotY(math.atan2(pos2[3] - pos1[3], pos2[1] - pos1[1])))

    -- if true then return newTransf2 end

    -- LOLLO TODO this is wrong. The log shows:
--[[
     getUnderpassTransf starting, posTanX2 =
    {
        {
            { 112.94583432614, 52.74210043538, -1.839821820744, },
            { -4.2869175992319, -2.3746321067699, 0.092825916435686, },
        },
        {
            { 108.64070527488, 50.402910568881, -1.7481150535168, },
            { -4.3231888201262, -2.3036847898209, 0.090554455586243, },
        },
    }
    newTransf 1 =
    { -0.99977319498448, -0, 0.021296915047328, 0, 0.010167700978762, -0.87867196030975, 0.47731771811051, 0, 0.018713002093186, 0.47742600072202, 0.87847267310215, 0, 110.79326980051, 51.57250550213, -1.7939684371304, 1, }
    newTransf 2 =
    { -0.87867196030975, -0.47742600072202, 0, 0, 0.47742600072202, -0.87867196030975, 0, 0, 0, 0, 1, 0, 112.94583432614, 52.74210043538, 0.16017817925604, 1, }
    angle on Y axis (deg) =
    178.77968439184
]]
    -- local angle = -math.atan2(pos2[3] - pos1[3], pos2[1] - pos1[1])
    -- while angle > math.pi * 0.5 do angle = angle - math.pi end
    -- while angle < -math.pi * 0.5 do angle = angle + math.pi end
    local angle = math.atan((pos2[3] - pos1[3]) / (pos2[1] - pos1[1]))
    print('angle around Y axis, deg =', angle * 180 / math.pi)
    local newTransf3 = transfUtilsUG.mul(
        newTransf,
        transfUtilsUG.rotY(angle)
    )
    print('newTransf 3 =') debugPrint(newTransf3)
    return newTransf3
end

return helpers
