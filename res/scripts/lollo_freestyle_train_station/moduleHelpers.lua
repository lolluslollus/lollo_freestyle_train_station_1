local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local modulesutil = require "modulesutil"
local slotUtils = require('lollo_freestyle_train_station.slotHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require 'transf'
local vec3 = require "vec3"
local vec4 = require "vec4"


local helpers = {
    eras = trackUtils.eras
}

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
    if type(slopeHigh) ~= 'number' then slopeHigh = _constants.slopeHigh end
    if type(slopeLow) ~= 'number' then slopeLow = _constants.slopeLow end
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
        {
            x = (pos1[1] + pos2[1]) * 0.5,
            y = (pos1[2] + pos2[2]) * 0.5,
            z = (pos1[3] + pos2[3]) * 0.5,
        }
    )

    -- print('newTransf =') debugPrint(newTransf)
    return newTransf
end

helpers.getPlatformObjectTransf_WithYRotation = function(posTanX2) --, angleYFactor)
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
    -- local angleY = -math.atan((pos2[3] - pos1[3]) / transfUtils.getVectorLength(
    --     {
    --         pos2[1] - pos1[1],
    --         pos2[2] - pos1[2],
    --         0
    --     }
    -- ))

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
end

helpers.slopedAreas = {
    _hunchLengthRatioToClaimBend = 0.01, -- must be positive
    _hunchToClaimBend = 0.2, -- must be positive
    innerDegrees = {
        inner = 1,
        neutral = 0,
        outer = -1
    },
    getYShift = function(params, t, i, slopedAreaWidth)
        local isTrackOnPlatformLeft = params.terminals[t].isTrackOnPlatformLeft
        if not(params.terminals[t].centrePlatformsRelative[i]) then return false end

        local platformWidth = params.terminals[t].centrePlatformsRelative[i].width
        local baseYShift = (slopedAreaWidth + platformWidth) * 0.5 -0.85
        local yShiftOutside = isTrackOnPlatformLeft and -baseYShift or baseYShift

        local yShiftOutside4StreetAccess = slopedAreaWidth * 2 - 1.2 -- - 1.8

        return yShiftOutside, yShiftOutside4StreetAccess
    end,
}

local _getSlopedAreaInnerDegree = function(params, nTerminal, nTrackEdge)
    local centrePlatforms = params.terminals[nTerminal].centrePlatformsRelative

    local x1 = 0
    local y1 = 0
    local xM = 0
    local yM = 0
    local x2 = 0
    local y2 = 0
    if centrePlatforms[nTrackEdge - 1] ~= nil and centrePlatforms[nTrackEdge] ~= nil and centrePlatforms[nTrackEdge + 1] ~= nil then
        x1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][1]
        y1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][2]
        x2 = centrePlatforms[nTrackEdge + 1].posTanX2[1][1][1]
        y2 = centrePlatforms[nTrackEdge + 1].posTanX2[1][1][2]
        xM = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
        yM = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
    elseif centrePlatforms[nTrackEdge - 1] ~= nil and centrePlatforms[nTrackEdge] ~= nil then
        x1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][1]
        y1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][2]
        x2 = centrePlatforms[nTrackEdge].posTanX2[2][1][1]
        y2 = centrePlatforms[nTrackEdge].posTanX2[2][1][2]
        xM = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
        yM = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
    elseif centrePlatforms[nTrackEdge] ~= nil and centrePlatforms[nTrackEdge + 1] ~= nil then
        x1 = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
        y1 = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
        x2 = centrePlatforms[nTrackEdge + 1].posTanX2[2][1][1]
        y2 = centrePlatforms[nTrackEdge + 1].posTanX2[2][1][2]
        xM = centrePlatforms[nTrackEdge].posTanX2[2][1][1]
        yM = centrePlatforms[nTrackEdge].posTanX2[2][1][2]
    else
        print('WARNING: cannot get inner degree')
        return helpers.slopedAreas.innerDegrees.neutral
    end

    local segmentHunch = transfUtils.getDistanceBetweenPointAndStraight(
        {x1, y1, 0},
        {x2, y2, 0},
        {xM, yM, 0}
    )
    -- print('segmentHunch =', segmentHunch)

    -- local segmentLength = transfUtils.getPositionsDistance(
    --     centrePlatforms[nTrackEdge - 1].posTanX2[1][1],
    --     centrePlatforms[nTrackEdge + 1].posTanX2[1][1]
    -- )
    -- print('segmentLength =', segmentLength)
    -- if segmentHunch / segmentLength < helpers.slopedAreas._hunchLengthRatioToClaimBend then return helpers.slopedAreas.innerDegrees.neutral end
    if segmentHunch < helpers.slopedAreas._hunchToClaimBend then return helpers.slopedAreas.innerDegrees.neutral end

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

    local innerSign = transfUtils.sgn((y1 - yM) * (x1 - x2) + (y1 - y2) * (xM - x1))

    if not(params.terminals[nTerminal].isTrackOnPlatformLeft) then innerSign = -innerSign end
    -- print('terminal', nTerminal, 'innerSign =', innerSign)
    return innerSign
end

local _getSlopedAreaTweakFactors = function(innerDegree, areaWidth)
    local waitingAreaScaleFactor = areaWidth * 0.8

    -- LOLLO NOTE sloped areas are parallelepipeds that extend the parallelepipeds that make up the platform sideways.
    -- I don't know of any transformation to twist or deform a model, so either I make an arsenal of meshes (no!) or I adjust things.
    -- 1) If I am outside a bend, I must stretch the sloped areas so there are no holes between them.
    -- Inside a bend, I haven't got this problem but I cannot shrink them, either, lest I get holes.
    -- 2) As I approach the centre of a bend, the slope should increase, and it should decrease as I move outwards.
    -- To visualise this, imagine building a helter skelter with horizontal planks, or a tight staircase: the centre will be super steep.
    -- Since there is no transf for this, I tweak the angle around the Y axis.

    -- These tricks work to a certain extent, but since I cannot skew or twist my models,
    -- I work out a new cleaner series of segments to follow, instead of extending the platform sideways.
    -- It is cleaner (the Y angle is optimised by construction) but slow, so we run the calculations in advance in the big script.
    -- And we still need to tweak it a little.

    -- Using multiple thin parallel extensions is slow and brings nothing at all.

    -- The easiest is: leave the narrower slopes since they don't cause much grief, and bridges need them,
    -- and use the terrain for the wider ones. Even the smaller sloped areas need quite a bit of stretch, but they are less sensiitive to the angle problem.
    -- However, the terrain will never look as good as a dedicated model.
    -- local angleYFactor = 1
    local xScaleFactor = 1
    -- local waitingAreaPeriod = 5
    -- outside a bend
    if innerDegree < 0 then
        -- waitingAreaPeriod = 4
        if areaWidth <= 5 then
            xScaleFactor = 1.20
            -- angleYFactor = 1.0625
        elseif areaWidth <= 10 then
            xScaleFactor = 1.30
            -- angleYFactor = 1.10
        elseif areaWidth <= 20 then
            xScaleFactor = 1.40
            -- angleYFactor = 1.20
        end
    -- inside a bend
    elseif innerDegree > 0 then
        -- waitingAreaPeriod = 6
        xScaleFactor = 0.95
        -- if areaWidth <= 5 then
        --     angleYFactor = 0.9
        -- elseif areaWidth <= 10 then
        --     angleYFactor = 0.825
        -- elseif areaWidth <= 20 then
        --     angleYFactor = 0.75
        -- end
    -- more or less straight
    else
        if areaWidth <= 5 then
            xScaleFactor = 1.05
        elseif areaWidth <= 10 then
            xScaleFactor = 1.15
        elseif areaWidth <= 20 then
            xScaleFactor = 1.25
        end
    end
    -- print('xScaleFactor =', xScaleFactor)
    -- print('angleYFactor =', angleYFactor)

    return waitingAreaScaleFactor, xScaleFactor
end

local _doTerrain4SlopedArea = function(result, params, nTerminal, nTrackEdge, areaWidth, groundFacesFillKey, isGroundLevel)
    -- print('_doTerrain4SlopedArea got groundFacesFillKey =', groundFacesFillKey)
    local terrainCoordinates = {}

    local i1 = nTrackEdge - 1
    local iN = nTrackEdge + 1
    local safs = params.terminals[nTerminal].slopedAreasFineRelative[areaWidth]
    for ii = 1, #safs do
        if safs[ii].leadingIndex > iN then break end
        if safs[ii].leadingIndex >= i1 then
            local saf = safs[ii]
            local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
            local pos1Inner = cpf.posTanX2[1][1]
            local pos2Inner = cpf.posTanX2[2][1]
            local pos2Outer = saf.posTanX2[2][1]
            local pos1Outer = saf.posTanX2[1][1]
            terrainCoordinates[#terrainCoordinates+1] = {
                pos1Inner,
                pos2Inner,
                transfUtils.getExtrapolatedPosX2Continuation(pos2Inner, pos2Outer, areaWidth * 0.5),
                transfUtils.getExtrapolatedPosX2Continuation(pos1Inner, pos1Outer, areaWidth * 0.5),
            }
        end
    end
    -- print('terrainCoordinates =') debugPrint(terrainCoordinates)

    local faces = {}
    for tc = 1, #terrainCoordinates do
        local face = { }
        for i = 1, 4 do
            face[i] = {
                terrainCoordinates[tc][i][1],
                terrainCoordinates[tc][i][2],
                isGroundLevel
                    and terrainCoordinates[tc][i][3] + result.laneZs[nTerminal] + _constants.platformSideBitsZ
                    or terrainCoordinates[tc][i][3] + result.laneZs[nTerminal] * 0.5 + _constants.platformSideBitsZ,
                1
            }
        end
        faces[#faces+1] = face
        if groundFacesFillKey ~= nil then
            result.groundFaces[#result.groundFaces + 1] = {
                face = face, -- Z is ignored here
                loop = true,
                modes = {
                    {
                        type = 'FILL',
                        key = groundFacesFillKey,
                    },
                    {
                    	type = 'STROKE_OUTER',
                    	key = groundFacesFillKey
                    }
                }
            }
        end
    end
    if #faces > 1 then
        result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = {
            faces = faces, -- Z is accounted here
            optional = true,
            slopeHigh = _constants.slopeHigh,
            slopeLow = _constants.slopeLow,
            type = 'EQUAL', -- GREATER, LESS
        }
    end
end

helpers.slopedAreas.addAll = function(result, tag, params, nTerminal, nTrackEdge, areaWidth, modelId, waitingAreaModelId, groundFacesFillKey)
    local innerDegree = _getSlopedAreaInnerDegree(params, nTerminal, nTrackEdge)
--     print('innerDegree =', innerDegree, '(inner == 1, outer == -1)')
    local waitingAreaScaleFactor, xScaleFactor = _getSlopedAreaTweakFactors(innerDegree, areaWidth)
    -- local waitingAreaShift = params.terminals[nTerminal].isTrackOnPlatformLeft and -areaWidth * 0.4 or areaWidth * 0.4
    local waitingAreaIndex = 0

    local ii1 = nTrackEdge - 1
    local iiN = nTrackEdge + 1

    local safs = params.terminals[nTerminal].slopedAreasFineRelative[areaWidth]
    -- print('safs =') debugPrint(safs)
    for ii = 1, #safs do
        if safs[ii].leadingIndex > iiN then break end
        if safs[ii].leadingIndex >= ii1 then
            local saf = safs[ii]
            local myTransf = helpers.getPlatformObjectTransf_WithYRotation(saf.posTanX2) --, angleYFactor)
            result.models[#result.models+1] = {
                id = modelId,
                transf = transfUtilsUG.mul(
                    myTransf,
                    { xScaleFactor, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, _constants.platformSideBitsZ, 1 }
                ),
                tag = tag
            }

            if waitingAreaModelId ~= nil
            and safs[ii - 2]
            and safs[ii - 2].leadingIndex >= ii1
            and safs[ii + 2]
            and safs[ii + 2].leadingIndex <= iiN then
                if math.fmod(waitingAreaIndex, 5) == 0 then
                    result.models[#result.models+1] = {
                        id = waitingAreaModelId,
                        transf = transfUtilsUG.mul(
                            myTransf,
                            { 0, waitingAreaScaleFactor, 0, 0,  -waitingAreaScaleFactor, 0, 0, 0,  0, 0, 1, 0,  0, 0, result.laneZs[nTerminal], 1 }
                        ),
                        tag = slotUtils.mangleModelTag(nTerminal, true),
                    }
                end
                waitingAreaIndex = waitingAreaIndex + 1
            end
        end
    end

    _doTerrain4SlopedArea(result, params, nTerminal, nTrackEdge, areaWidth, groundFacesFillKey)
end

local _addTrackEdges = function(result, tag2nodes, params, t)
    result.terminateConstructionHookInfo.vehicleNodes[t] = (#result.edgeLists + params.terminals[t].trackEdgeListMidIndex) * 2 - 2

    -- print('_addTrackEdges starting for terminal =', t)
    local forceCatenary = 0
    local trackElectrificationModuleKey = slotUtils.mangleId(t, 0, _constants.idBases.trackElectrificationSlotId)
    if params.modules[trackElectrificationModuleKey] ~= nil then
        if params.modules[trackElectrificationModuleKey].name == _constants.trackElectrificationYesModuleFileName then
            forceCatenary = 2
        elseif params.modules[trackElectrificationModuleKey].name == _constants.trackElectrificationNoModuleFileName then
            forceCatenary = 1
        end
    end
    -- print('forceCatenary =', forceCatenary)
    local forceFast = 0
    local trackSpeedModuleKey = slotUtils.mangleId(t, 0, _constants.idBases.trackSpeedSlotId)
    if params.modules[trackSpeedModuleKey] ~= nil then
        if params.modules[trackSpeedModuleKey].name == _constants.trackSpeedFastModuleFileName then
            forceFast = 2
        elseif params.modules[trackSpeedModuleKey].name == _constants.trackSpeedSlowModuleFileName then
            forceFast = 1
        end
    end
    -- print('forceFast =', forceFast)

    for i = 1, #params.terminals[t].trackEdgeLists do
        local tel = params.terminals[t].trackEdgeLists[i]

        local overriddenCatenary = tel.catenary
        if forceCatenary == 1 then overriddenCatenary = false
        elseif forceCatenary == 2 then overriddenCatenary = true
        end

        local overriddenTrackType = tel.trackTypeName
        if forceFast == 1 then overriddenTrackType = 'standard.lua'
        elseif forceFast == 2 then overriddenTrackType = 'high_speed.lua'
        end

        local newEdgeList = {
            alignTerrain = tel.type == 0 or tel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(tel.posTanX2, params.inverseMainTransf),
            edgeType = tel.edgeType,
            edgeTypeName = tel.edgeTypeName,
            -- freeNodes = {},
            params = {
                catenary = overriddenCatenary,
                type = overriddenTrackType,
            },
            snapNodes = {},
            tag2nodes = tag2nodes,
            type = 'TRACK'
        }

        if i == 1 then
            -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 0
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
        end
        if i == #params.terminals[t].trackEdgeLists then
            -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 1
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
        end

        -- LOLLO NOTE the edges won't snap to the neighbours
        -- unless you rebuild those neighbours, by hand or by script,
        -- and make them snap to the station own nodes.
        result.edgeLists[#result.edgeLists+1] = newEdgeList
    end
end

local _addPlatformEdges = function(result, tag2nodes, params, t)
    for i = 1, #params.terminals[t].platformEdgeLists do
        local pel = params.terminals[t].platformEdgeLists[i]

        local newEdgeList = {
            alignTerrain = pel.type == 0 or pel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(pel.posTanX2, params.inverseMainTransf),
            edgeType = pel.edgeType,
            edgeTypeName = pel.edgeTypeName,
            -- freeNodes = {},
            params = {
                -- type = pel.trackTypeName,
                type = trackUtils.getInvisibleTwinFileName(pel.trackTypeName),
                catenary = false --pel.catenary
            },
            snapNodes = {},
            tag2nodes = tag2nodes,
            type = 'TRACK'
        }

        if i == 1 then
            -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 0
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
        end
        if i == #params.terminals[t].platformEdgeLists then
            -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 1
            newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
        end

        result.edgeLists[#result.edgeLists+1] = newEdgeList
    end
end

local _getNNodesInTerminalsSoFar = function(params, t)
    local result = 0
    for tt = 1, t - 1 do
        if params.terminals[tt] ~= nil then
            if params.terminals[tt].platformEdgeLists ~= nil then
                result = result + #params.terminals[tt].platformEdgeLists * 2
            end
            if params.terminals[tt].trackEdgeLists ~= nil then
                result = result + #params.terminals[tt].trackEdgeLists * 2
            end
        end
    end
    return result
end

helpers.edges = {
    addEdges = function(result, tag, params, t)
        -- print('moduleHelpers.edges.addEdges starting for terminal', t, ', result.edgeLists =') debugPrint(result.edgeLists)

        local nNodesInTerminalSoFar = _getNNodesInTerminalsSoFar(params, t)

        local tag2nodes = {
            [tag] = { } -- list of base 0 indexes
        }

        for i = 1, #params.terminals[t].platformEdgeLists + #params.terminals[t].trackEdgeLists do
        -- for i = 1, #params.terminals[t].trackEdgeLists do
            for ii = 1, 2 do
                tag2nodes[tag][#tag2nodes[tag]+1] = nNodesInTerminalSoFar
                nNodesInTerminalSoFar = nNodesInTerminalSoFar + 1
            end
        end

        _addPlatformEdges(result, tag2nodes, params, t)
        _addTrackEdges(result, tag2nodes, params, t)

        -- print('moduleHelpers.edges.addEdges ending for terminal', t, ', result.edgeLists =') debugPrint(result.edgeLists)
    end,
}


-- local _bridgeHeights = { 5, 10, 15, 20, 25, 30, 35, 40 } -- too little, stations get buried
local _bridgeHeights = { 7.5, 12.5, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5 }
-- local _bridgeHeights = { 6.5, 11.5, 16.5, 21.5, 26.5, 31.5, 36.5, 41.5 }
helpers.lifts = {
    tryGetLiftHeight = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
        local bridgeHeight = cpl.type == 1 and params.mainTransf[15] + cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

        local buildingHeight = 0
        if bridgeHeight < _bridgeHeights[1] then
            buildingHeight = 5
        elseif bridgeHeight < _bridgeHeights[2] then
            buildingHeight = 10
        elseif bridgeHeight < _bridgeHeights[3] then
            buildingHeight = 15
        elseif bridgeHeight < _bridgeHeights[4] then
            buildingHeight = 20
        elseif bridgeHeight < _bridgeHeights[5] then
            buildingHeight = 25
        elseif bridgeHeight < _bridgeHeights[6] then
            buildingHeight = 30
        elseif bridgeHeight < _bridgeHeights[7] then
            buildingHeight = 35
        elseif bridgeHeight < _bridgeHeights[8] then
            buildingHeight = 40
        else
            buildingHeight = 40
            -- return false
        end

        return buildingHeight
    end,

    tryGetSideLiftModelId = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
        local bridgeHeight = cpl.type == 1 and params.mainTransf[15] + cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

        local buildingModelId = 'lollo_freestyle_train_station/lift/'
        if bridgeHeight < _bridgeHeights[1] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_5.mdl'
        elseif bridgeHeight < _bridgeHeights[2] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_10.mdl'
        elseif bridgeHeight < _bridgeHeights[3] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_15.mdl'
        elseif bridgeHeight < _bridgeHeights[4] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_20.mdl'
        elseif bridgeHeight < _bridgeHeights[5] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_25.mdl'
        elseif bridgeHeight < _bridgeHeights[6] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_30.mdl'
        elseif bridgeHeight < _bridgeHeights[7] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_35.mdl'
        elseif bridgeHeight < _bridgeHeights[8] then
            buildingModelId = buildingModelId .. 'side_lifts_9_5_40.mdl'
        else
            buildingModelId = buildingModelId .. 'side_lifts_9_5_40.mdl'
            -- return false
        end

        return buildingModelId
    end,

    doTerrain4SideLifts = function(buildingHeight, slotTransf, result, groundFacesFillKey, groundFacesStrokeOuterKey)
        local groundFace = { -- the ground faces ignore z, the alignment lists don't
            {-1, -6.2, -buildingHeight, 1},
            {-1, 6.2, -buildingHeight, 1},
            {6.0, 6.2, -buildingHeight, 1},
            {6.0, -6.2, -buildingHeight, 1},
        }
        modulesutil.TransformFaces(slotTransf, groundFace)
        table.insert(
            result.groundFaces,
            {
                face = groundFace,
                modes = {
                    {
                        type = 'FILL',
                        key = groundFacesFillKey
                    },
                    {
                        type = 'STROKE_OUTER',
                        key = groundFacesStrokeOuterKey
                    }
                }
            }
        )

        local terrainAlignmentList = {
            faces = { groundFace },
            optional = true,
            slopeHigh = _constants.slopeHigh,
			slopeLow = _constants.slopeLow,
            type = 'EQUAL',
        }
        result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = terrainAlignmentList
    end,

    tryGetPlatformLiftModelId = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
        local bridgeHeight = cpl.type == 1 and params.mainTransf[15] + cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

        local buildingModelId = 'lollo_freestyle_train_station/lift/'
        if bridgeHeight < _bridgeHeights[1] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_5.mdl'
        elseif bridgeHeight < _bridgeHeights[2] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_10.mdl'
        elseif bridgeHeight < _bridgeHeights[3] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_15.mdl'
        elseif bridgeHeight < _bridgeHeights[4] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_20.mdl'
        elseif bridgeHeight < _bridgeHeights[5] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_25.mdl'
        elseif bridgeHeight < _bridgeHeights[6] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_30.mdl'
        elseif bridgeHeight < _bridgeHeights[7] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_35.mdl'
        elseif bridgeHeight < _bridgeHeights[8] then
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_40.mdl'
        else
            buildingModelId = buildingModelId .. 'platform_lifts_9_5_40.mdl'
            -- return false
        end

        return buildingModelId
    end,
}

helpers.doTerrain4Subways = function(result, slotTransf, groundFacesStrokeOuterKey)
    local groundFace = { -- the ground faces ignore z, the alignment lists don't
        {0.0, -0.95, 0, 1},
        {0.0, 0.95, 0, 1},
        {4.5, 0.95, 0, 1},
        {4.5, -0.95, 0, 1},
    }
    local terrainFace = { -- the ground faces ignore z, the alignment lists don't
        {-0.2, -1.15, _constants.platformSideBitsZ, 1},
        {-0.2, 1.15, _constants.platformSideBitsZ, 1},
        {4.7, 1.15, _constants.platformSideBitsZ, 1},
        {4.7, -1.15, _constants.platformSideBitsZ, 1},
    }
    if type(slotTransf) == 'table' then
        modulesutil.TransformFaces(slotTransf, groundFace)
        modulesutil.TransformFaces(slotTransf, terrainFace)
    end

    table.insert(
        result.groundFaces,
        {
            face = groundFace,
            loop = true,
            modes = {
                {
                    key = 'lollo_freestyle_train_station/hole.lua',
                    type = 'FILL',
                },
                {
                    key = groundFacesStrokeOuterKey,
                    type = 'STROKE_OUTER',
                }
            }
        }
    )
    table.insert(
        result.terrainAlignmentLists,
        {
            faces =  { terrainFace },
            optional = true,
            slopeHigh = _constants.slopeHigh,
			slopeLow = _constants.slopeLow,
            type = "EQUAL",
        }
    )
end


helpers.getVariant = function(params, slotId)
    local variant = 0
    if type(params) == 'table'
    and type(params.modules) == 'table'
    and type(params.modules[slotId]) == 'table'
    and type(params.modules[slotId].variant) == 'number' then
        variant = params.modules[slotId].variant
    end
    return variant
end

helpers.flatAreas = {
    getMNAdjustedTransf_Limited = function(params, slotId, slotTransf)
        local variant = helpers.getVariant(params, slotId)
        local deltaZ = variant * 0.1 + _constants.platformSideBitsZ
        if deltaZ < -1 then deltaZ = -1 elseif deltaZ > 1 then deltaZ = 1 end

        return transfUtilsUG.mul(slotTransf, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, deltaZ, 1 })
    end,

    addLaneToStreet = function(result, slotAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)
        local crossConnectorPosTanX2 = params.terminals[nTerminal].crossConnectorsRelative[nTrackEdge].posTanX2
        local lane2AreaTransf = transfUtils.get1MLaneTransf(
            transfUtils.getPositionRaisedBy(crossConnectorPosTanX2[2][1], result.laneZs[nTerminal]),
            transfUtils.transf2Position(slotAdjustedTransf)
        )
        result.models[#result.models+1] = {
            id = _constants.passengerLaneModelId,
            slotId = slotId,
            transf = lane2AreaTransf,
            tag = tag
        }
    end
}

helpers.addSlopedPassengerAreaDeco = function(result, slotTransf, tag, slotId, xShift, yShift)
    result.models[#result.models + 1] = {
        id = 'station/rail/asset/era_c_double_chair.mdl',
        -- id = 'station/rail/asset/era_c_single_chair.mdl',
        -- id = 'lollo_freestyle_train_station/asset/era_c_two_chairs.mdl',
        slotId = slotId,
        transf = transfUtilsUG.mul(slotTransf, { 0, -1, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0,  -1.0 + xShift, yShift - 1, _constants.stairsAndRampHeight + 0.0, 1 }),
        tag = tag
    }
    result.models[#result.models + 1] = {
        id = 'station/rail/asset/era_c_trashcan.mdl',
        slotId = slotId,
        transf = transfUtilsUG.mul(slotTransf, { 0, 1, 0, 0,  -1, 0, 0, 0,  0, 0, 1, 0,  1.0 + xShift, yShift - 1, 1.1, 1 }),
        tag = tag
    }
    result.models[#result.models + 1] = {
        id = 'lollo_freestyle_train_station/asset/tabellone_standing.mdl',
        slotId = slotId,
        transf = transfUtilsUG.mul(slotTransf, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  -0.7 + xShift, yShift + 3, _constants.stairsAndRampHeight + 0.0, 1 }),
        tag = tag
    }
end

helpers.addSlopedCargoAreaDecoEraC = function(result, slotTransf, tag, slotId, xShift, yShift)
    result.models[#result.models + 1] = {
        id = 'lollo_freestyle_train_station/asset/cargo_roof_grid_4x4.mdl',
        slotId = slotId,
        transf = transfUtilsUG.mul(slotTransf, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  xShift , yShift -4.3, _constants.stairsAndRampHeight + 0.0, 1 }),
        tag = tag
    }
    result.models[#result.models + 1] = {
        id = 'lollo_freestyle_train_station/asset/cargo_roof_grid_4x4.mdl',
        slotId = slotId,
        transf = transfUtilsUG.mul(slotTransf, { -1, 0, 0, 0,  0, -1, 0, 0,  0, 0, 1, 0,  xShift, yShift +4.6, _constants.stairsAndRampHeight + 0.0, 1 }),
        tag = tag
    }
end

helpers.doPlatformRoof = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge,
ceiling2_5ModelId, ceiling5ModelId, pillar2_5ModelId, pillar5ModelId)
    local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
    local transfXZoom = isTrackOnPlatformLeft and -1 or 1
    local transfYZoom = isTrackOnPlatformLeft and -1 or 1

    -- LOLLO NOTE setting this to 2 gets a negligible performance boost and uglier joints,
    -- particularly on slopes and bends
    local _ceilingStep = 1
    local _pillarPeriod = 4 -- it would be math.ceil(4 / _ceilingStep)

    local ii1 = nTrackEdge - 1
    local iiN = nTrackEdge + 1
    local ceilingCounter = -2
    local drawNumberSign = 1
    for ii = 1, #params.terminals[nTerminal].centrePlatformsFineRelative, _ceilingStep do
        local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
        local leadingIndex = cpf.leadingIndex
        if leadingIndex > iiN then break end
        if leadingIndex >= ii1 then
            local cpl = params.terminals[nTerminal].centrePlatformsRelative[leadingIndex]
            local era = cpl.era or helpers.eras.era_c.prefix
            local platformWidth = cpl.width

            if cpf.type ~= 2 then
                result.models[#result.models+1] = {
                    id = platformWidth < 5 and ceiling2_5ModelId or ceiling5ModelId,
                    transf = transfUtilsUG.mul(
                        helpers.getPlatformObjectTransf_WithYRotation(cpf.posTanX2),
                        { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, _constants.platformRoofZ, 1 }
                    ),
                    tag = tag
                }
            end

            ceilingCounter = ceilingCounter + 1
            if params.terminals[nTerminal].centrePlatformsFineRelative[ii + _ceilingStep]
            and params.terminals[nTerminal].centrePlatformsFineRelative[ii + _ceilingStep].leadingIndex <= iiN
            and math.fmod(ceilingCounter, _pillarPeriod) == 0 then
                local myTransf = transfUtilsUG.mul(
                    helpers.getPlatformObjectTransf_AlwaysVertical(cpf.posTanX2),
                    { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, _constants.platformRoofZ, 1 }
                )
                if cpf.type ~= 2 then
                    result.models[#result.models+1] = {
                        id = platformWidth < 5 and pillar2_5ModelId or pillar5ModelId,
                        transf = myTransf,
                        tag = tag,
                    }
                end
                drawNumberSign = -drawNumberSign

                if drawNumberSign == 1 then -- little bodge to prevent overlapping with station name signs
                    -- local yShift = isTrackOnPlatformLeft and platformWidth * 0.5 - 0.05 or -platformWidth * 0.5 + 0.05
                    if cpf.type ~= 2 then
                        local yShift = -platformWidth * 0.5 + 0.20
                        local perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_c_perron_number_single_hanging.mdl'
                        if era == helpers.eras.era_a.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_a_perron_number_single_hanging.mdl'
                        elseif era == helpers.eras.era_b.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_b_perron_number_single_hanging.mdl'
                        end
                        result.models[#result.models + 1] = {
                            id = perronNumberModelId,
                            slotId = slotId,
                            transf = transfUtilsUG.mul(
                                myTransf,
                                { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, yShift, 4.83, 1 }
                            ),
                            tag = tag
                        }
                        -- the model index must be in base 0 !
                        result.labelText[#result.models - 1] = { tostring(nTerminal), tostring(nTerminal)}
                    end
                end
            end
        end
    end
end

return helpers
