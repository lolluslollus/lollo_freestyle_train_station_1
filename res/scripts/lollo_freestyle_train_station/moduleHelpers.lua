local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local modulesutil = require "modulesutil"
local slotUtils = require('lollo_freestyle_train_station.slotHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require 'transf'
local vec3 = require "vec3"


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
    local angle = -math.atan((pos2[3] - pos1[3]) / transfUtils.getVectorLength(
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

helpers.getYShift4SlopedArea = function(params, t, i, slopedAreaWidth)
    local isTrackOnPlatformLeft = params.terminals[t].isTrackOnPlatformLeft
    local platformWidth = params.terminals[t].centrePlatforms[i].width

    local baseYShift = (slopedAreaWidth + platformWidth) * 0.5 -0.35
    -- local baseYShift = slopedAreaWidth * 0.5 + platformWidth - 1.6

    local yShiftOutside = isTrackOnPlatformLeft and -baseYShift or baseYShift
    local yShiftOutside4StreetAccess = slopedAreaWidth * 2 - 1.8

    return yShiftOutside, yShiftOutside4StreetAccess
end



local _addTrackEdges = function(params, result, inverseMainTransf, tag2nodes, t)
    result.terminateConstructionHookInfo.vehicleNodes[t] = (#result.edgeLists + params.terminals[t].midTrackIndex) * 2 - 2

    for i = 1, #params.terminals[t].trackEdgeLists do
        local tel = params.terminals[t].trackEdgeLists[i]
        local newEdgeList = {
            alignTerrain = tel.type == 0 or tel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(tel.posTanX2, inverseMainTransf),
            edgeType = tel.edgeType,
            edgeTypeName = tel.edgeTypeName,
            -- freeNodes = {},
            params = {
                type = tel.trackTypeName,
                catenary = tel.catenary
            },
            snapNodes = {},
            tag2nodes = tag2nodes,
            type = 'TRACK'
        }

        if i == 1 then
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
        end
        if i == #params.terminals[t].trackEdgeLists then
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
        end

        -- LOLLO NOTE the edges won't snap to the neighbours
        -- unless you rebuild those neighbours, by hand or by script,
        -- and make them snap to the station own nodes.
        result.edgeLists[#result.edgeLists+1] = newEdgeList
    end
end

local _addPlatformEdges = function(params, result, inverseMainTransf, tag2nodes, t)
    for i = 1, #params.terminals[t].platformEdgeLists do
        local pel = params.terminals[t].platformEdgeLists[i]

        local invisibleTrackTypeName = stringUtils.stringContains(pel.trackTypeName, 'cargo')
            and pel.trackTypeName:gsub('cargo', 'invisible')
            or pel.trackTypeName:gsub('passenger', 'invisible')

        local newEdgeList = {
            alignTerrain = pel.type == 0 or pel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(pel.posTanX2, inverseMainTransf),
            edgeType = pel.edgeType,
            edgeTypeName = pel.edgeTypeName,
            -- freeNodes = {},
            params = {
                -- type = pel.trackTypeName,
                type = invisibleTrackTypeName,
                catenary = false --pel.catenary
            },
            snapNodes = {},
            tag2nodes = tag2nodes,
            type = 'TRACK'
        }

        if i == 1 then
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
        end
        if i == #params.terminals[t].platformEdgeLists then
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
        end

        result.edgeLists[#result.edgeLists+1] = newEdgeList
    end
end

local _getNNodesInTerminalsSoFar = function(params, t)
    local result = 0
    for tt = 1, t - 1 do
        if params.terminals[tt] ~= nil then
            -- if params.terminals[tt].platformEdgeLists ~= nil then
            --     result = result + #params.terminals[tt].platformEdgeLists * 2
            -- end
            if params.terminals[tt].trackEdgeLists ~= nil then
                result = result + #params.terminals[tt].trackEdgeLists * 2
            end
        end
    end
    return result
end

helpers.addEdges = function(params, result, inverseMainTransf, tag, t)
    local nNodesInTerminalSoFar = _getNNodesInTerminalsSoFar(params, t)

    local tag2nodes = {
        [tag] = { } -- base 0
    }

    for i = 1, #params.terminals[t].platformEdgeLists + #params.terminals[t].trackEdgeLists do
    -- for i = 1, #params.terminals[t].trackEdgeLists do
        for ii = 1, 2 do
            tag2nodes[tag][#tag2nodes[tag]+1] = nNodesInTerminalSoFar
            nNodesInTerminalSoFar = nNodesInTerminalSoFar + 1
        end
    end

    _addPlatformEdges(params, result, inverseMainTransf, tag2nodes, t)
    _addTrackEdges(params, result, inverseMainTransf, tag2nodes, t)
end

helpers.tryGetLiftHeight = function(params, nTerminal, nTrackEdge)
    local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
		-- local terrainHeight = cpl.terrainHeight1
    local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

    local buildingHeight = 0
    if bridgeHeight < 5 then
        buildingHeight = 5
    elseif bridgeHeight < 10 then
        buildingHeight = 10
    elseif bridgeHeight < 15 then
        buildingHeight = 15
    elseif bridgeHeight < 20 then
        buildingHeight = 20
    elseif bridgeHeight < 25 then
        buildingHeight = 25
    elseif bridgeHeight < 30 then
        buildingHeight = 30
    elseif bridgeHeight < 35 then
        buildingHeight = 35
    elseif bridgeHeight < 40 then
        buildingHeight = 40
    else
        return false
    end

    return buildingHeight
end

helpers.tryGetSideLiftModelId = function(params, nTerminal, nTrackEdge)
    local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
		-- local terrainHeight = cpl.terrainHeight1
    local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

    local buildingModelId = 'lollo_freestyle_train_station/lift/'
    if bridgeHeight < 5 then
        buildingModelId = buildingModelId .. 'elevated_stairs_5.mdl'
    elseif bridgeHeight < 10 then
        buildingModelId = buildingModelId .. 'elevated_stairs_10.mdl'
    elseif bridgeHeight < 15 then
        buildingModelId = buildingModelId .. 'elevated_stairs_15.mdl'
    elseif bridgeHeight < 20 then
        buildingModelId = buildingModelId .. 'elevated_stairs_20.mdl'
    elseif bridgeHeight < 25 then
        buildingModelId = buildingModelId .. 'elevated_stairs_25.mdl'
    elseif bridgeHeight < 30 then
        buildingModelId = buildingModelId .. 'elevated_stairs_30.mdl'
    elseif bridgeHeight < 35 then
        buildingModelId = buildingModelId .. 'elevated_stairs_35.mdl'
    elseif bridgeHeight < 40 then
        buildingModelId = buildingModelId .. 'elevated_stairs_40.mdl'
    else
        return false
    end

    return buildingModelId
end

helpers.doTerrain4SideLifts = function(buildingHeight, slotTransf, result)
    local groundFace = { -- the ground faces ignore z, the alignment lists don't
        {-1, -6.2, -buildingHeight -0.8, 1},
        {-1, 6.2, -buildingHeight -0.8, 1},
        {6.0, 6.2, -buildingHeight -0.8, 1},
        {6.0, -6.2, -buildingHeight -0.8, 1},
    }
    modulesutil.TransformFaces(slotTransf, groundFace)
    table.insert(
        result.groundFaces,
        {
            face = groundFace,
            modes = {
                {
                    type = 'FILL',
                    key = 'shared/asphalt_01.gtex.lua' --'shared/asphalt_01.gtex.lua'
                },
                --[[                         {
                    type = 'STROKE_INNER',
                    key = 'shared/asphalt_01.gtex.lua',
                },
                ]]
                {
                    type = 'STROKE_OUTER',
                    key = 'shared/asphalt_01.gtex.lua' --'street_border.lua'
                }
            }
        }
    )

    local terrainAlignmentList = {
        faces = { groundFace },
        optional = true,
        slopeHigh = 99,
        slopeLow = 0.9, --0.1,
        type = 'EQUAL',
    }
    result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = terrainAlignmentList
end

helpers.tryGetPlatformLiftModelId = function(params, nTerminal, nTrackEdge)
    local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
		-- local terrainHeight = cpl.terrainHeight1
    local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

    local buildingModelId = 'lollo_freestyle_train_station/lift/'
    if bridgeHeight < 5 then
        buildingModelId = buildingModelId .. 'platform_lifts_5.mdl'
    elseif bridgeHeight < 10 then
        buildingModelId = buildingModelId .. 'platform_lifts_10.mdl'
    elseif bridgeHeight < 15 then
        buildingModelId = buildingModelId .. 'platform_lifts_15.mdl'
    elseif bridgeHeight < 20 then
        buildingModelId = buildingModelId .. 'platform_lifts_20.mdl'
    elseif bridgeHeight < 25 then
        buildingModelId = buildingModelId .. 'platform_lifts_25.mdl'
    elseif bridgeHeight < 30 then
        buildingModelId = buildingModelId .. 'platform_lifts_30.mdl'
    elseif bridgeHeight < 35 then
        buildingModelId = buildingModelId .. 'platform_lifts_35.mdl'
    elseif bridgeHeight < 40 then
        buildingModelId = buildingModelId .. 'platform_lifts_40.mdl'
    else
        return false
    end

    return buildingModelId
end

return helpers
