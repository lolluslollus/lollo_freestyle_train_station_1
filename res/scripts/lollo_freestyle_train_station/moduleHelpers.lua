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

helpers.getPlatformObjectTransf_WithYRotation = function(posTanX2, angleYFactor)
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
        ) * (angleYFactor or 1)
    )

    local transfY = transfUtilsUG.rotY(-angleY)

    return transfUtilsUG.mul(transfZ, transfY)
    -- return transfUtilsUG.mul(transfY, transfZ) -- NO!
end

helpers.slopedAreas = {
    -- LOLLO TODO recheck all the sloped stuff, it's new. There will always be some microsteps,
    -- a skewing transf could be the best bet here.
    _hunchLengthRatioToClaimBend = 0.01, -- must be positive
    _hunchToClaimBend = 0.2, -- must be positive
    doTerrainOLD = function(result, slotTransf, params, nTerminal, nTrackEdge, innerDegree, areaWidth)
        if result.centrePlatformsRelative[nTerminal][nTrackEdge].type == 0 then -- only align terrain if on ground
            local face = {}
            if areaWidth <= 5 then
                if innerDegree > 0 then
                    face = {
                        {-3.0, -9, 0, 1},
                        {-3.0, 9, 0, 1},
                        {3.0, 13, 0, 1},
                        {3.0, -13, 0, 1},
                    }
                elseif innerDegree < 0 then
                    face = {
                        {-3.0, -15, 0, 1},
                        {-3.0, 15, 0, 1},
                        {3.0, 13, 0, 1},
                        {3.0, -13, 0, 1},
                    }
                else
                    face = {
                        {-3.0, -13, 0, 1},
                        {-3.0, 13, 0, 1},
                        {3.0, 13, 0, 1},
                        {3.0, -13, 0, 1},
                    }
                end
            elseif areaWidth <= 10 then
                if innerDegree > 0 then
                    face = {
                        {-5.5, -9, 0, 1},
                        {-5.5, 9, 0, 1},
                        {5.5, 13, 0, 1},
                        {5.5, -13, 0, 1},
                    }
                elseif innerDegree < 0 then
                    face = {
                        {-5.5, -15, 0, 1},
                        {-5.5, 15, 0, 1},
                        {5.5, 13, 0, 1},
                        {5.5, -13, 0, 1},
                    }
                else
                    face = {
                        {-5.5, -13, 0, 1},
                        {-5.5, 13, 0, 1},
                        {5.5, 13, 0, 1},
                        {5.5, -13, 0, 1},
                    }
                end
            elseif areaWidth <= 20 then
                if innerDegree > 0 then
                    face = {
                        {-10.5, -9, 0, 1},
                        {-10.5, 9, 0, 1},
                        {10.5, 13, 0, 1},
                        {10.5, -13, 0, 1},
                    }
                elseif innerDegree < 0 then
                    face = {
                        {-10.5, -15, 0, 1},
                        {-10.5, 15, 0, 1},
                        {10.5, 13, 0, 1},
                        {10.5, -13, 0, 1},
                    }
                else
                    face = {
                        {-10.5, -13, 0, 1},
                        {-10.5, 13, 0, 1},
                        {10.5, 13, 0, 1},
                        {10.5, -13, 0, 1},
                    }
                end
            end
			modulesutil.TransformFaces(slotTransf, face)
			result.groundFaces[#result.groundFaces + 1] = helpers.getGroundFace(face, 'shared/asphalt_01.gtex.lua')
			result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = helpers.getTerrainAlignmentList(face, 0, 'EQUAL', 1, 0.5)
        end
    end,
    innerDegrees = {
        inner = 1,
        neutral = 0,
        outer = -1
    },
    getInnerDegree = function(params, nTerminal, nTrackEdge)
        local centrePlatforms = params.terminals[nTerminal].centrePlatforms
        if not(centrePlatforms[nTrackEdge - 1])
        or not(centrePlatforms[nTrackEdge])
        or not(centrePlatforms[nTrackEdge + 1])
        then return helpers.slopedAreas.innerDegrees.neutral end

        local segmentHunch = transfUtils.getDistanceBetweenPointAndStraight(
            centrePlatforms[nTrackEdge - 1].posTanX2[1][1],
            centrePlatforms[nTrackEdge + 1].posTanX2[1][1],
            centrePlatforms[nTrackEdge].posTanX2[1][1]
        )
        print('segmentHunch =', segmentHunch)
        -- local segmentLength = transfUtils.getPositionsDistance(
        --     centrePlatforms[nTrackEdge - 1].posTanX2[1][1],
        --     centrePlatforms[nTrackEdge + 1].posTanX2[1][1]
        -- )
        -- print('segmentLength =', segmentLength)
        -- if segmentHunch / segmentLength < helpers.slopedAreas._hunchLengthRatioToClaimBend then return helpers.slopedAreas.innerDegrees.neutral end
        if segmentHunch < helpers.slopedAreas._hunchToClaimBend then return helpers.slopedAreas.innerDegrees.neutral end

        local x1 = params.terminals[nTerminal].centrePlatforms[nTrackEdge - 1].posTanX2[1][1][1]
        local y1 = params.terminals[nTerminal].centrePlatforms[nTrackEdge - 1].posTanX2[1][1][2]
        local xM = params.terminals[nTerminal].centrePlatforms[nTrackEdge].posTanX2[1][1][1]
        local yM = params.terminals[nTerminal].centrePlatforms[nTrackEdge].posTanX2[1][1][2]
        local x2 = params.terminals[nTerminal].centrePlatforms[nTrackEdge + 1].posTanX2[1][1][1]
        local y2 = params.terminals[nTerminal].centrePlatforms[nTrackEdge + 1].posTanX2[1][1][2]
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
        print('terminal', nTerminal, 'innerSign =', innerSign)
        return innerSign
    end,
    getYShift = function(params, t, i, slopedAreaWidth)
        local isTrackOnPlatformLeft = params.terminals[t].isTrackOnPlatformLeft
        if not(params.terminals[t].centrePlatforms[i]) then return false end

        local platformWidth = params.terminals[t].centrePlatforms[i].width

        local baseYShift = (slopedAreaWidth + platformWidth) * 0.5 -0.85

        local yShiftOutside = isTrackOnPlatformLeft and -baseYShift or baseYShift
        local yShiftOutside4StreetAccess = slopedAreaWidth * 2 - 1.8

        return yShiftOutside, yShiftOutside4StreetAccess
    end,
}

local _getSlopedAreaTweakFactors = function(innerDegree, areaWidth)
    local waitingAreaScaleFactor = 1
    if areaWidth <= 5 then waitingAreaScaleFactor = 4
    elseif areaWidth <= 10 then waitingAreaScaleFactor = 8
    elseif areaWidth <= 20 then waitingAreaScaleFactor = 16
    end

    -- LOLLO NOTE sloped areas are parallelepipeds that extend the parallelepipeds that make up the platform sideways.
    -- I don't know of any transformation to twist or deform a model, so either I make an arsenal of meshes (no!) or I adjust things.
    -- 1) If I am outside a bend, I must stretch the sloped areas so there are no holes between them.
    -- Inside a bend, I haven't got this problem but I cannot shrink them, either, lest I get holes.
    -- 2) As I approach the centre of a bend, the slope should increase, and it should decrease as I move outwards.
    -- To visualise this, imagine building a helter skelter with horizontal planks, or a tight staircase: the centre will be super steep.
    -- Since there is no transf for this, I tweak the angle around the Y axis.
    -- These tricks work to a certain extent, but since I cannot skew or twist my models,
    -- I could work out a new series of segments to follow instead of extending the platform sideways.
    -- Tried that, it is slow and it does not bring real benefits.
    -- Using multiple thin parallel extensions is slow and brings nothing at all.
    -- At the end of the day, the easiest is: leave the narrower slopes since they don't cause much grief, and bridges need them,
    -- and use the terrain for the wider ones. LOLLO TODO try this.
    local angleYFactor = 1
    local xScaleFactor = 1
    local waitingAreaPeriod = 5
    -- outside a bend
    if innerDegree < 0 then
        waitingAreaPeriod = 4
        if areaWidth <= 5 then
            xScaleFactor = 1.15
            angleYFactor = 1.0625
        elseif areaWidth <= 10 then
            xScaleFactor = 1.25
            angleYFactor = 1.10
        elseif areaWidth <= 20 then
            xScaleFactor = 1.35
            angleYFactor = 1.20
        end
    -- inside a bend
    elseif innerDegree > 0 then
        waitingAreaPeriod = 6
        xScaleFactor = 0.95
        if areaWidth <= 5 then
            angleYFactor = 0.9
        elseif areaWidth <= 10 then
            angleYFactor = 0.825
        elseif areaWidth <= 20 then
            angleYFactor = 0.75
        end
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
    print('xScaleFactor =', xScaleFactor)
    print('angleYFactor =', angleYFactor)

    return angleYFactor, waitingAreaPeriod, waitingAreaScaleFactor, xScaleFactor
end

helpers.slopedAreas.addModels = function(result, tag, params, nTerminal, nTrackEdge, areaWidth, modelId, waitingAreaModelId)
    local innerDegree = helpers.slopedAreas.getInnerDegree(params, nTerminal, nTrackEdge)
    print('innerDegree =', innerDegree, '(inner == 1, outer == -1)')

    local angleYFactor, waitingAreaPeriod, waitingAreaScaleFactor, xScaleFactor = _getSlopedAreaTweakFactors(innerDegree, areaWidth)

    local ii1 = nTrackEdge - 1
    local iiN = nTrackEdge + 1
    local waitingAreaCounter = 0
    local cpfs = result.centrePlatformsFineRelative[nTerminal]
    for ii = 1, #cpfs do
        if cpfs[ii].leadingIndex > iiN then break end
        if cpfs[ii].leadingIndex >= ii1 then
            local cpf = cpfs[ii]
            local myTransf = helpers.getPlatformObjectTransf_WithYRotation(cpf.posTanX2, angleYFactor)
            local yShiftOutside = helpers.slopedAreas.getYShift(params, nTerminal, cpf.leadingIndex, areaWidth)
            result.models[#result.models+1] = {
                id = modelId,
                transf = transfUtilsUG.mul(
                    myTransf,
                    { xScaleFactor, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, yShiftOutside, _constants.platformSideBitsZ, 1 }
                ),
                tag = tag
            }

            if waitingAreaModelId ~= nil
            and cpfs[ii - 2]
            and cpfs[ii - 2].leadingIndex >= ii1
            and cpfs[ii + 2]
            and cpfs[ii + 2].leadingIndex <= iiN then
                if math.fmod(waitingAreaCounter, waitingAreaPeriod) == 0 then
                    result.models[#result.models+1] = {
                        id = waitingAreaModelId,
                        transf = transfUtilsUG.mul(
                            myTransf,
                            { 0, waitingAreaScaleFactor, 0, 0,  -waitingAreaScaleFactor, 0, 0, 0,  0, 0, 1, 0,  0, yShiftOutside, result.laneZs[nTerminal], 1 }
                        ),
                        tag = slotUtils.mangleModelTag(nTerminal, true),
                    }
                end
                waitingAreaCounter = waitingAreaCounter + 1
            end
        end
    end

    return innerDegree
end

helpers.slopedAreas.addWaitingAreas = function(result, params, nTerminal, nTrackEdge, areaWidth, waitingAreaModelId)
    local innerDegree = helpers.slopedAreas.getInnerDegree(params, nTerminal, nTrackEdge)
    print('innerDegree =', innerDegree, '(inner == 1, outer == -1)')
    if waitingAreaModelId == nil then return innerDegree end

    local angleYFactor, waitingAreaPeriod, waitingAreaScaleFactor, xScaleFactor = _getSlopedAreaTweakFactors(innerDegree, areaWidth)

    local ii1 = nTrackEdge - 1
    local iiN = nTrackEdge + 1
    local waitingAreaIndex = 0
    local cpfs = result.centrePlatformsFineRelative[nTerminal]

    for ii = 1, #cpfs do
        if cpfs[ii].leadingIndex > iiN then break end
        if cpfs[ii].leadingIndex >= ii1 then
            if cpfs[ii - 2]
            and cpfs[ii - 2].leadingIndex >= ii1
            and cpfs[ii + 2]
            and cpfs[ii + 2].leadingIndex <= iiN then
                if math.fmod(waitingAreaIndex, waitingAreaPeriod) == 0 then
                    local cpf = cpfs[ii]
                    local myTransf = helpers.getPlatformObjectTransf_WithYRotation(cpf.posTanX2, angleYFactor)
                    local yShiftOutside = helpers.slopedAreas.getYShift(params, nTerminal, cpf.leadingIndex, areaWidth)

                    result.models[#result.models+1] = {
                        id = waitingAreaModelId,
                        transf = transfUtilsUG.mul(
                            myTransf,
                            { 0, waitingAreaScaleFactor, 0, 0,  -waitingAreaScaleFactor, 0, 0, 0,  0, 0, 1, 0,  0, yShiftOutside, result.laneZs[nTerminal], 1 }
                        ),
                        tag = slotUtils.mangleModelTag(nTerminal, true),
                    }
                end
                waitingAreaIndex = waitingAreaIndex + 1
            end
        end
    end

    return innerDegree
end

helpers.slopedAreas.getTerrainCoordinates = function(result, params, nTerminal, nTrackEdge, areaWidth)
    local innerDegree = helpers.slopedAreas.getInnerDegree(params, nTerminal, nTrackEdge)
    print('innerDegree =', innerDegree, '(inner == 1, outer == -1)')

    local angleYFactor, waitingAreaPeriod, waitingAreaScaleFactor, xScaleFactor = _getSlopedAreaTweakFactors(innerDegree, areaWidth)

    local cpls = result.centrePlatformsRelative[nTerminal]
    local i1 = math.max(nTrackEdge - 1, 1)
    local iN = math.min(nTrackEdge + 1, #cpls)

    local terrainCoordinates = {}
    for i = i1, iN do
        local cpl = cpls[i]
        local myTransf = helpers.getPlatformObjectTransf_WithYRotation(cpl.posTanX2, angleYFactor)
        local yShiftOutside = helpers.slopedAreas.getYShift(params, nTerminal, i, areaWidth)
        local traaa = transfUtilsUG.mul(
            myTransf,
            { xScaleFactor, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, yShiftOutside, _constants.platformSideBitsZ, 1 }
        )
        terrainCoordinates[#terrainCoordinates+1] = {
            transfUtils.getVec123Transformed({-4.75, -areaWidth * 0.5, result.laneZs[nTerminal]}, traaa),
            transfUtils.getVec123Transformed({-4.75, areaWidth * 0.5, result.laneZs[nTerminal]}, traaa),
            transfUtils.getVec123Transformed({4.75, areaWidth * 0.5, result.laneZs[nTerminal]}, traaa),
            transfUtils.getVec123Transformed({4.75, -areaWidth * 0.5, result.laneZs[nTerminal]}, traaa),
        }
    end

    return terrainCoordinates
end

helpers.slopedAreas.doTerrain = function(result, params, nTerminal, nTrackEdge, areaWidth)
    local terrainCoordinates = helpers.slopedAreas.getTerrainCoordinates(result, params, nTerminal, nTrackEdge, areaWidth)
    local faces = {}
    for _, pos1234 in pairs(terrainCoordinates) do
        local face = {}
        for i = 1, 4 do
            face[i] = { pos1234[i][1], pos1234[i][2], pos1234[i][3], 0 }
        end
        faces[#faces+1] = face
        result.groundFaces[#result.groundFaces + 1] = {
            face = face, -- LOLLO NOTE Z is ignored here
            loop = true,
            modes = {
                {
                    type = 'FILL',
                    key = 'shared/asphalt_02.gtex.lua'
                    -- key = 'shared/asphalt_03.gtex.lua'
                    -- key = 'shared/asphalt_04.gtex.lua'
                },
                -- {
                -- 	type = 'STROKE_OUTER',
                -- 	key = 'shared/asphalt_04.gtex.lua'
                -- }
            }
        }
    end
    result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = {
        faces = faces,
        optional = true,
        slopeHigh = 10.0,
        slopeLow = 0.25, --0.25,
        type = 'EQUAL', -- GREATER, LESS
    }
end

local _addTrackEdges = function(params, result, inverseMainTransf, tag2nodes, t)
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
        local newEdgeList = {
            alignTerrain = tel.type == 0 or tel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(tel.posTanX2, inverseMainTransf),
            edgeType = tel.edgeType,
            edgeTypeName = tel.edgeTypeName,
            -- freeNodes = {},
            params = {
                type = forceFast == 0 and tel.trackTypeName or (forceFast == 1 and 'standard.lua' or 'high_speed.lua'),
                catenary = forceCatenary == 0 and tel.catenary or (forceCatenary == 2 and true or false)
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

        local newEdgeList = {
            alignTerrain = pel.type == 0 or pel.type == 2, -- only align on ground and in tunnels
            edges = transfUtils.getPosTanX2Transformed(pel.posTanX2, inverseMainTransf),
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
    addEdges = function(params, result, inverseMainTransf, tag, t)
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

        _addPlatformEdges(params, result, inverseMainTransf, tag2nodes, t)
        _addTrackEdges(params, result, inverseMainTransf, tag2nodes, t)

        -- print('moduleHelpers.edges.addEdges ending for terminal', t, ', result.edgeLists =') debugPrint(result.edgeLists)
    end,
}


-- local _bridgeHeights = { 5, 10, 15, 20, 25, 30, 35, 40 } -- too little, stations get buried
local _bridgeHeights = { 7.5, 12.5, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5 }
-- local _bridgeHeights = { 6.5, 11.5, 16.5, 21.5, 26.5, 31.5, 36.5, 41.5 }
helpers.lifts = {
    tryGetLiftHeight = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
            -- local terrainHeight = cpl.terrainHeight1
        local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

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
        local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
            -- local terrainHeight = cpl.terrainHeight1
        local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

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

    doTerrain4SideLifts = function(buildingHeight, slotTransf, result)
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
    end,

    tryGetPlatformLiftModelId = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatforms[nTrackEdge]
            -- local terrainHeight = cpl.terrainHeight1
        local bridgeHeight = cpl.type == 1 and cpl.posTanX2[1][1][3] - cpl.terrainHeight1 or 0

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

helpers.doTerrain4Subways = function(result, slotTransf)
    local groundFace = { -- the ground faces ignore z, the alignment lists don't
        {0.0, -0.95, 0, 1},
        {0.0, 0.95, 0, 1},
        {4.5, 0.95, 0, 1},
        {4.5, -0.95, 0, 1},
    }
    local terrainFace = { -- the ground faces ignore z, the alignment lists don't
        {-0.2, -1.15, 0, 1},
        {-0.2, 1.15, 0, 1},
        {4.7, 1.15, 0, 1},
        {4.7, -1.15, 0, 1},
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
                    -- key = 'shared/asphalt_01.gtex.lua'
                    key = 'lollo_freestyle_train_station/hole.lua',
                    type = 'FILL',
                },
                -- {
                -- 	-- key = 'shared/asphalt_01.gtex.lua',
                -- 	key = 'lollo_freestyle_train_station/hole.lua',
                -- 	type = 'STROKE_INNER',
                -- },
                {
                    -- key = 'street_border.lua'
                    -- key = 'shared/asphalt_01.gtex.lua',
                    key = 'lollo_freestyle_train_station/asphalt_01_high_priority.lua',
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
            slopeHigh = 99,
            slopeLow = 0.9, --0.1,
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
        local crossConnectorPosTanX2 = transfUtils.getPosTanX2Transformed(
            params.terminals[nTerminal].crossConnectors[nTrackEdge].posTanX2,
            result.inverseMainTransf
        )
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

return helpers
