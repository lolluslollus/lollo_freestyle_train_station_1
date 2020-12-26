local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelper')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

local _getParallelSideways = function(posTanX2, sideShift)
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
    local length = edgeUtils.getVectorLength({ oldPos2[1] - oldPos1[1], oldPos2[2] - oldPos1[2], oldPos2[3] - oldPos1[3] })

    local ro = math.atan2(oldPos2[2] - oldPos1[2], oldPos2[1] - oldPos1[1])

    result[1][1] = { oldPos1[1] + math.sin(ro) * sideShift, oldPos1[2] - math.cos(ro) * sideShift, oldPos1[3] }
    result[2][1] = { oldPos2[1] + math.sin(ro) * sideShift, oldPos2[2] - math.cos(ro) * sideShift, oldPos2[3] }

    return result
end

local helpers = {
    getNearbyFreestyleStationsList = function(transf, searchRadius)
        if type(transf) ~= 'table' then return {} end

        local squareCentrePosition = transfUtils.getVec123Transformed({0, 0, 0}, transf)
        local cons = game.interface.getEntities(
            {pos = squareCentrePosition, radius = searchRadius},
            {type = "CONSTRUCTION", includeData = true, fileName = _constants.stationConFileNameLong}
        )
        -- #cons returns 0 coz it's not a list
        local results = {}
        for _, con in pairs(cons) do
            local staGroups = {}
            for _, staId in pairs(con.stations) do
                local staGroupId = api.engine.system.stationGroupSystem.getStationGroup(staId)
                local staGroupName = api.engine.getComponent(staGroupId, api.type.ComponentType.NAME)
                staGroups[staGroupId] = staGroupName and staGroupName.name or ''
                con.uiName = staGroupName and staGroupName.name or ''
                print('staGroupName =') debugPrint(staGroupName)
            end
            -- LOLLO TODO 1 con can have N stations, but they all belong to the same group. Right?
            -- If so, staGroups will always have 1 item only
            con.stationGroups = staGroups
            results[#results+1] = con
        end

        -- print('# nearby freestyle stations = ', #results)
        -- print('nearby freestyle stations = ') debugPrint(results)
        return results
    end,

    getStationEndNodeIds = function(con, nTerminal, stationConstructionId)
        -- print('getStationEndNodesUnsorted starting, nTerminal =', nTerminal)
        -- print('getStationEndNodesUnsorted, con =') debugPrint(con)
        -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
        if not(con) or con.fileName ~= _constants.stationConFileNameLong then
            return {}
        end

        local pos1 = con.params.terminals[nTerminal].trackEdgeLists[1].posTanX2[1][1]
        local edgeFunds1 = edgeUtils.getNearestObjectIds(transfUtils.position2Transf(pos1), 0.001, api.type.ComponentType.BASE_EDGE)
        print('edgeFunds1 =') debugPrint(edgeFunds1)
        local nodeFunds1 = edgeUtils.getNearestObjectIds(transfUtils.position2Transf(pos1), 0.001, api.type.ComponentType.BASE_NODE)
        print('nodeFunds1 =') debugPrint(nodeFunds1)
        local node1Id = nil
        for _, edgeId in pairs(edgeFunds1) do
            if arrayUtils.arrayHasValue(con.frozenEdges, edgeId) then
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                for _, nodeId in pairs(nodeFunds1) do
                    if baseEdge.node0 == nodeId or baseEdge.node1 == nodeId then
                        node1Id = nodeId
                        break
                    end
                end
                break
            end
        end
        local posN = con.params.terminals[nTerminal].trackEdgeLists[#con.params.terminals[nTerminal].trackEdgeLists].posTanX2[2][1]
        local edgeFundsN = edgeUtils.getNearestObjectIds(transfUtils.position2Transf(posN), 0.001, api.type.ComponentType.BASE_EDGE)
        print('edgeFundsN =') debugPrint(edgeFundsN)
        local nodeFundsN = edgeUtils.getNearestObjectIds(transfUtils.position2Transf(posN), 0.001, api.type.ComponentType.BASE_NODE)
        print('nodeFundsN =') debugPrint(nodeFundsN)
        local node2Id = nil
        for _, edgeId in pairs(edgeFundsN) do
            if arrayUtils.arrayHasValue(con.frozenEdges, edgeId) then
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                for _, nodeId in pairs(nodeFundsN) do
                    if baseEdge.node0 == nodeId or baseEdge.node1 == nodeId then
                        node2Id = nodeId
                        break
                    end
                end
                break
            end
        end

        if node1Id == nil then
            print('WARNING: could not find node1Id in station construction')
            print('stationConstructionId =') debugPrint(stationConstructionId)
        end
        if node2Id == nil then
            print('WARNING: could not find node2Id in station construction')
            print('stationConstructionId =') debugPrint(stationConstructionId)
        end

        return {
            node1Id = node1Id,
            node2Id = node2Id,
        }
    end,

    getEdgeIdsProperties = function(edgeIds)
        if type(edgeIds) ~= 'table' then return {} end

        local _getEdgeType = function(baseEdgeType)
            return baseEdgeType == 1 and 'BRIDGE' or (baseEdgeType == 2 and 'TUNNEL' or nil)
        end
        local _getEdgeTypeName = function(baseEdgeType, baseEdgeTypeIndex)
            if baseEdgeType == 1 then -- bridge
                return api.res.bridgeTypeRep.getName(baseEdgeTypeIndex)
            elseif baseEdgeType == 2 then -- tunnel
                return api.res.tunnelTypeRep.getName(baseEdgeTypeIndex)
            else
                return nil
            end
        end

        local results = {}
        for i = 1, #edgeIds do
            local baseEdge = api.engine.getComponent(edgeIds[i], api.type.ComponentType.BASE_EDGE)
            local baseEdgeTrack = api.engine.getComponent(edgeIds[i], api.type.ComponentType.BASE_EDGE_TRACK)
            local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
            local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)

            local pos0 = baseNode0.position
            local pos1 = baseNode1.position
            local tan0 = baseEdge.tangent0
            local tan1 = baseEdge.tangent1
            local _swap = function()
                local swapPos = pos0
                pos0 = pos1
                pos1 = swapPos
                local swapTan = tan0
                tan0 = tan1
                tan1 = swapTan
                tan0.x = -tan0.x
                tan0.y = -tan0.y
                tan0.z = -tan0.z
                tan1.x = -tan1.x
                tan1.y = -tan1.y
                tan1.z = -tan1.z
            end
            -- edgeIds are in the right sequence, but baseNode0 and baseNode1 depend on the sequence edges were laid in
            if i == 1 then
                if i < #edgeIds then
                    local nextBaseEdge = api.engine.getComponent(edgeIds[i + 1], api.type.ComponentType.BASE_EDGE)
                    if baseEdge.node0 == nextBaseEdge.node0 or baseEdge.node0 == nextBaseEdge.node1 then _swap() end
                end
            else
                local prevBaseEdge = api.engine.getComponent(edgeIds[i - 1], api.type.ComponentType.BASE_EDGE)
                if baseEdge.node1 == prevBaseEdge.node0 or baseEdge.node1 == prevBaseEdge.node1 then _swap() end
            end

            local result = {
                catenary = baseEdgeTrack.catenary,
                -- edgeId = edgeIds[i],
                posTanX2 = {
                    {
                        {
                            pos0.x,
                            pos0.y,
                            pos0.z,
                        },
                        {
                            tan0.x,
                            tan0.y,
                            tan0.z,
                        }
                    },
                    {
                        {
                            pos1.x,
                            pos1.y,
                            pos1.z,
                        },
                        {
                            tan1.x,
                            tan1.y,
                            tan1.z,
                        }
                    }
                },
                trackType = baseEdgeTrack.trackType,
                trackTypeName = api.res.trackTypeRep.getName(baseEdgeTrack.trackType),
                type = baseEdge.type, -- 0 on ground, 1 bridge, 2 tunnel
                edgeType = _getEdgeType(baseEdge.type), -- same as above but in a format constructions understand
                typeIndex = baseEdge.typeIndex, -- -1 on ground, 0 tunnel / cement bridge, 1 steel bridge, 2 stone bridge, 3 suspension bridge
                edgeTypeName = _getEdgeTypeName(baseEdge.type, baseEdge.typeIndex), -- same as above but in a format constructions understand
            }
            results[#results+1] = result
        end

        return results
    end,

    getAllEdgeObjectsWithModelIdOLD = function(refModelId, searchRadius)
        -- too slow
        if not(searchRadius) then searchRadius = 99999 end
        local results = {}
        local nearbyEdgeIds = edgeUtils.getNearestObjectIds(_constants.idTransf, searchRadius, api.type.ComponentType.BASE_EDGE)
        -- print('nearbyEdgeIds =')
        -- debugPrint(nearbyEdgeIds)
        for _, edgeId in pairs(nearbyEdgeIds) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge ~= nil and baseEdge.objects ~= nil then
                local edgeObjectIds = edgeUtils.getEdgeObjectsIdsWithModelId(baseEdge.objects, refModelId)
                for _, edgeObjectId in pairs(edgeObjectIds) do
                    arrayUtils.addUnique(results, edgeObjectId)
                end
            end
        end

        -- print('getAllEdgeObjectsWithModelId is about to return') debugPrint(results)
        return results
    end,

    getAllEdgeObjectsWithModelId = function(refModelId)
        if not(edgeUtils.isValidAndExistingId(refModelId)) then return {} end

        local _map = api.engine.system.streetSystem.getEdgeObject2EdgeMap()
        local edgeObjectIds = {}
        for edgeObjectId, edgeId in pairs(_map) do
            edgeObjectIds[#edgeObjectIds+1] = edgeObjectId
        end

        return edgeUtils.getEdgeObjectsIdsWithModelId2(edgeObjectIds, refModelId)
    end,

    getOuterNodes = function(contiguousEdgeIds, trackType)
        -- only for testing
        local _hasOnlyOneEdgeOfType1 = function(nodeId, map)
            if not(edgeUtils.isValidAndExistingId(nodeId)) or not(trackType) then return false end

            local edgeIds = map[nodeId] -- userdata
            if not(edgeIds) or #edgeIds < 2 then return true end

            local counter = 0
            for _, edgeId in pairs(edgeIds) do -- cannot use edgeIds[index] here
                local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                if baseEdgeTrack ~= nil and baseEdgeTrack.trackType == trackType then
                    counter = counter + 1
                end
            end

            return counter < 2
        end

        print('one')
        if type(contiguousEdgeIds) ~= 'table' or #contiguousEdgeIds < 1 then return {} end
        print('two')
        if #contiguousEdgeIds == 1 then
            local _baseEdge = api.engine.getComponent(contiguousEdgeIds[1], api.type.ComponentType.BASE_EDGE)
            print('three')
            return { _baseEdge.node0, _baseEdge.node1 }
        end

        local results = {}
        local _map = api.engine.system.streetSystem.getNode2SegmentMap()
        local _baseEdgeFirst = api.engine.getComponent(contiguousEdgeIds[1], api.type.ComponentType.BASE_EDGE)
        local _baseEdgeLast = api.engine.getComponent(contiguousEdgeIds[#contiguousEdgeIds], api.type.ComponentType.BASE_EDGE)
        if _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node0, _map) then
            results[#results+1] = _baseEdgeFirst.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node1, _map) then
            results[#results+1] = _baseEdgeFirst.node1
        end
        if _hasOnlyOneEdgeOfType1(_baseEdgeLast.node0, _map) then
            results[#results+1] = _baseEdgeLast.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeLast.node1, _map) then
            results[#results+1] = _baseEdgeLast.node1
        end

        return results
    end,

    getCentreLanePositions = function(platformEdgeLists, maxEdgeLength)
        -- print('getCentreLanePositions starting')
        if type(platformEdgeLists) ~= 'table' then return {} end

        local results = {}
        for _, pel in pairs(platformEdgeLists) do
            local edgeLength = (edgeUtils.getVectorLength(pel.posTanX2[1][2]) + edgeUtils.getVectorLength(pel.posTanX2[2][2])) * 0.5
            -- print('edgeLength =') debugPrint(edgeLength)
            local nModelsInEdge = math.ceil(edgeLength / maxEdgeLength)
            -- print('nModelsInEdge =') debugPrint(nModelsInEdge)

            local edgeResults = {}
            local lengthCovered = 0
            local previousNodeBetween = nil
            for i = 1, nModelsInEdge do
                -- print('i == ', i)
                local nodeBetween = edgeUtils.getNodeBetween(
                    transfUtils.oneTwoThree2XYZ(pel.posTanX2[1][1]),
                    transfUtils.oneTwoThree2XYZ(pel.posTanX2[2][1]),
                    transfUtils.oneTwoThree2XYZ(pel.posTanX2[1][2]),
                    transfUtils.oneTwoThree2XYZ(pel.posTanX2[2][2]),
                    i / nModelsInEdge
                )
                -- print('nodeBetween =') debugPrint(nodeBetween)
                if nodeBetween == nil then
                    print('ERROR: nodeBetween not found')
                    print('pel =') debugPrint(pel)
                    return {}
                else
                    local lengthFactor = nodeBetween.length0 - lengthCovered
                    if i == 1 then
                        edgeResults[#edgeResults+1] = {
                            posTanX2 = {
                                {
                                    {
                                        pel.posTanX2[1][1][1],
                                        pel.posTanX2[1][1][2],
                                        pel.posTanX2[1][1][3],
                                    },
                                    {
                                        pel.posTanX2[1][2][1] * lengthFactor / edgeLength,
                                        pel.posTanX2[1][2][2] * lengthFactor / edgeLength,
                                        pel.posTanX2[1][2][3] * lengthFactor / edgeLength,
                                    }
                                },
                                {
                                    {
                                        nodeBetween.position.x,
                                        nodeBetween.position.y,
                                        nodeBetween.position.z,
                                    },
                                    {
                                        nodeBetween.tangent.x * lengthFactor,
                                        nodeBetween.tangent.y * lengthFactor,
                                        nodeBetween.tangent.z * lengthFactor,
                                    }
                                },
                            }
                        }
                    elseif i == nModelsInEdge then
                        edgeResults[#edgeResults+1] = {
                            posTanX2 = {
                                {
                                    {
                                        previousNodeBetween.position.x,
                                        previousNodeBetween.position.y,
                                        previousNodeBetween.position.z,
                                    },
                                    {
                                        previousNodeBetween.tangent.x * lengthFactor,
                                        previousNodeBetween.tangent.y * lengthFactor,
                                        previousNodeBetween.tangent.z * lengthFactor,
                                    }
                                },
                                {
                                    {
                                        pel.posTanX2[2][1][1],
                                        pel.posTanX2[2][1][2],
                                        pel.posTanX2[2][1][3],
                                    },
                                    {
                                        pel.posTanX2[2][2][1] * lengthFactor / edgeLength,
                                        pel.posTanX2[2][2][2] * lengthFactor / edgeLength,
                                        pel.posTanX2[2][2][3] * lengthFactor / edgeLength,
                                    }
                                },
                            }
                        }
                    else
                        edgeResults[#edgeResults+1] = {
                            posTanX2 = {
                                {
                                    {
                                        previousNodeBetween.position.x,
                                        previousNodeBetween.position.y,
                                        previousNodeBetween.position.z,
                                    },
                                    {
                                        previousNodeBetween.tangent.x * lengthFactor,
                                        previousNodeBetween.tangent.y * lengthFactor,
                                        previousNodeBetween.tangent.z * lengthFactor,
                                    }
                                },
                                {
                                    {
                                        nodeBetween.position.x,
                                        nodeBetween.position.y,
                                        nodeBetween.position.z,
                                    },
                                    {
                                        nodeBetween.tangent.x * lengthFactor,
                                        nodeBetween.tangent.y * lengthFactor,
                                        nodeBetween.tangent.z * lengthFactor,
                                    }
                                },
                            }
                        }
                    end
                end
                lengthCovered = nodeBetween.length0
                previousNodeBetween = nodeBetween
            end

            for _, value in pairs(edgeResults) do
                results[#results+1] = value
            end
        end

        -- print('getCentreLanePositions results =') debugPrint(results)
        return results
    end,

    getShiftedLanePositions = function(centreLanePositions, isCargo, sideShift)
        if isCargo then return {} end

        local results = {
            {
                posTanX2 = _getParallelSideways(centreLanePositions[1].posTanX2, sideShift)
            }
        }
        local previousPosTanX2 = results[1].posTanX2
        for i = 2, #centreLanePositions do
            local currentPosTanX2 = _getParallelSideways(centreLanePositions[i].posTanX2, sideShift)
            currentPosTanX2[1][1] = previousPosTanX2[2][1]
            results[#results+1] = {
                posTanX2 = currentPosTanX2
            }
            previousPosTanX2 = currentPosTanX2
        end

        return results
    end,

    getCrossConnectors = function(leftLanePositions, centreLanePositions, rightLanePositions, isCargo)
        if isCargo then return {} end

        local results = {}
        for i = 2, #leftLanePositions do
            local leftPosTanX2 = leftLanePositions[i].posTanX2
            local centrePosTanX2 = centreLanePositions[i].posTanX2
            local rightPosTanX2 = rightLanePositions[i].posTanX2

            local newTanLeft = {
                centrePosTanX2[1][1][1] - leftPosTanX2[1][1][1],
                centrePosTanX2[1][1][2] - leftPosTanX2[1][1][2],
                centrePosTanX2[1][1][3] - leftPosTanX2[1][1][3],
            }
            local newRecordLeft = {
                {
                    leftPosTanX2[1][1],
                    newTanLeft
                },
                {
                    centrePosTanX2[1][1],
                    newTanLeft
                }
            }
            results[#results+1] = { posTanX2 = newRecordLeft }

            local newTanRight = {
                rightPosTanX2[1][1][1] - centrePosTanX2[1][1][1],
                rightPosTanX2[1][1][2] - centrePosTanX2[1][1][2],
                rightPosTanX2[1][1][3] - centrePosTanX2[1][1][3],
            }
            local newRecordRight = {
                {
                    centrePosTanX2[1][1],
                    newTanRight
                },
                {
                    rightPosTanX2[1][1],
                    newTanRight
                },
            }
            results[#results+1] = { posTanX2 = newRecordRight }
        end

        return results
    end,

    getWhichEdgeGetsEdgeObjectAfterSplit = function(edgeObjPosition, node0pos, node1pos, nodeBetween)
        local result = {
            -- assignToFirstEstimate = nil,
            assignToSecondEstimate = nil,
        }
        -- print('LOLLO attempting to place edge object with position =')
        -- debugPrint(edgeObjPosition)
        -- print('wholeEdge.node0pos =') debugPrint(node0pos)
        -- print('nodeBetween.position =') debugPrint(nodeBetween.position)
        -- print('nodeBetween.tangent =') debugPrint(nodeBetween.tangent)
        -- print('wholeEdge.node1pos =') debugPrint(node1pos)
        -- first estimator
        -- local nodeBetween_Node0_Distance = edgeUtils.getVectorLength({
        --     nodeBetween.position.x - node0pos[1],
        --     nodeBetween.position.y - node0pos[2]
        -- })
        -- local nodeBetween_Node1_Distance = edgeUtils.getVectorLength({
        --     nodeBetween.position.x - node1pos[1],
        --     nodeBetween.position.y - node1pos[2]
        -- })
        -- local edgeObj_Node0_Distance = edgeUtils.getVectorLength({
        --     edgeObjPosition[1] - node0pos[1],
        --     edgeObjPosition[2] - node0pos[2]
        -- })
        -- local edgeObj_Node1_Distance = edgeUtils.getVectorLength({
        --     edgeObjPosition[1] - node1pos[1],
        --     edgeObjPosition[2] - node1pos[2]
        -- })
        -- if edgeObj_Node0_Distance < nodeBetween_Node0_Distance then
        --     result.assignToFirstEstimate = 0
        -- elseif edgeObj_Node1_Distance < nodeBetween_Node1_Distance then
        --     result.assignToFirstEstimate = 1
        -- end

        -- second estimator
        local edgeObjPosition_assignTo = nil
        local node0_assignTo = nil
        local node1_assignTo = nil
        -- at nodeBetween, I can draw the normal to the road:
        -- y = a + bx
        -- the angle is alpha = atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + PI / 2
        -- so b = math.tan(alpha)
        -- a = y - bx
        -- so a = nodeBetween.position.y - b * nodeBetween.position.x
        -- points under this line will go one way, the others the other way
        local alpha = math.atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + math.pi * 0.5
        local b = math.tan(alpha)
        if math.abs(b) < 1e+06 then
            local a = nodeBetween.position.y - b * nodeBetween.position.x
            if a + b * edgeObjPosition[1] > edgeObjPosition[2] then -- edgeObj is below the line
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if a + b * node0pos[1] > node0pos[2] then -- wholeEdge.node0pos is below the line
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if a + b * node1pos[1] > node1pos[2] then -- wholeEdge.node1pos is below the line
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        -- if b grows too much, I lose precision, so I approximate it with the y axis
        else
            -- print('alpha =', alpha, 'b =', b)
            if edgeObjPosition[1] > nodeBetween.position.x then
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if node0pos[1] > nodeBetween.position.x then
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if node1pos[1] > nodeBetween.position.x then
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        end

        if edgeObjPosition_assignTo == node0_assignTo then
            result.assignToSecondEstimate = 0
        elseif edgeObjPosition_assignTo == node1_assignTo then
            result.assignToSecondEstimate = 1
        end

        -- print('LOLLO assignment =') debugPrint(result)
        return result
    end,

    isBuildingConstructionWithFileName = function(param, fileName)
        local toAdd =
            type(param) == 'table' and type(param.proposal) == 'userdata' and type(param.proposal.toAdd) == 'userdata' and
            param.proposal.toAdd

        if toAdd and #toAdd > 0 then
            for i = 1, #toAdd do
                if toAdd[i].fileName == fileName then
                    return true
                end
            end
        end

        return false
    end,

    getProposal2ReplaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        -- replaces a track segment with an identical one, without destroying the buildings
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return false end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return false end

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = _constants.railEdgeType
        -- newEdge.comp = oldEdge -- no good enough if I want to remove objects, the api moans
        newEdge.comp.node0 = oldEdge.node0
        newEdge.comp.node1 = oldEdge.node1
        newEdge.comp.tangent0 = oldEdge.tangent0
        newEdge.comp.tangent1 = oldEdge.tangent1
        newEdge.comp.type = oldEdge.type -- respect bridge or tunnel
        newEdge.comp.typeIndex = oldEdge.typeIndex -- respect type of bridge or tunnel
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge.trackEdge = oldEdgeTrack
        if trackUtils.isPlatform(oldEdgeTrack.trackType) then
            newEdge.trackEdge.catenary = false
        end

        -- print('edgeUtils.isValidId(objectIdToRemove) =', edgeUtils.isValidId(objectIdToRemove))
        -- print('edgeUtils.isValidAndExistingId(objectIdToRemove) =', edgeUtils.isValidAndExistingId(objectIdToRemove))
        if edgeUtils.isValidId(objectIdToRemove) then
            local edgeObjects = {}
            for _, edgeObj in pairs(oldEdge.objects) do
                if edgeObj[1] ~= objectIdToRemove then
                    table.insert(edgeObjects, { edgeObj[1], edgeObj[2] })
                end
            end
            if #edgeObjects > 0 then
                newEdge.comp.objects = edgeObjects -- LOLLO NOTE cannot insert directly into edge0.comp.objects
                -- print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects =') debugPrint(newEdge.comp.objects)
            else
                -- print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects = not changed')
            end
        else
            print('replaceEdgeWithSameRemovingObject: objectIdToRemove is no good, it is') debugPrint(objectIdToRemove)
            newEdge.comp.objects = oldEdge.objects
        end

        -- print('newEdge.comp.objects:')
        -- for key, value in pairs(newEdge.comp.objects) do
        --     print('key =', key) debugPrint(value)
        -- end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end

        return proposal
    end,
}

helpers.getStationEndEntitiesTyped = function(stationConstructionId)
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then
        print('ERROR: getStationEndEntitiesTyped invalid stationConstructionId') debugPrint(stationConstructionId)
        return nil
    end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- print('con =') debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileNameLong then
        print('ERROR: getStationEndEntitiesTyped con.fileName =') debugPrint(con.fileName)
        return nil
    end

    local result = {}
    for t = 1, #con.params.terminals do
        local endNodeIds4T = helpers.getStationEndNodeIds(con, t, stationConstructionId)

        -- I cannot clone these, for some reason: it dumps
        local node1Position = edgeUtils.isValidAndExistingId(endNodeIds4T.node1Id)
            and api.engine.getComponent(endNodeIds4T.node1Id, api.type.ComponentType.BASE_NODE).position
            or nil
        local node2Position = edgeUtils.isValidAndExistingId(endNodeIds4T.node2Id)
            and api.engine.getComponent(endNodeIds4T.node2Id, api.type.ComponentType.BASE_NODE).position
            or nil
        result[t] = {
            -- these are empty or nil if the station has been snapped to its neighbours
            disjointNeighbourEdgeIds = {
                edge1Ids = {},
                edge2Ids = {}
            },
            -- same
            disjointNeighbourNodeIds = {
                node1Id = nil,
                node2Id = nil,
            },
            stationEndNodeIds = {
                node1Id = endNodeIds4T.node1Id,
                node2Id = endNodeIds4T.node2Id,
            },
            stationEndNodePositions = {
                node1 = node1Position ~= nil and { x = node1Position.x, y = node1Position.y, z = node1Position.z } or nil,
                node2 = node2Position ~= nil and { x = node2Position.x, y = node2Position.y, z = node2Position.z } or nil,
            }
        }

        local nearbyNodeIds = edgeUtils.isValidAndExistingId(endNodeIds4T.node1Id)
            and edgeUtils.getNearestObjectIds(
                transfUtils.position2Transf(api.engine.getComponent(endNodeIds4T.node1Id, api.type.ComponentType.BASE_NODE).position),
                0.001,
                api.type.ComponentType.BASE_NODE
            )
            or {}
        for _, nearbyNodeId in pairs(nearbyNodeIds) do
            if edgeUtils.isValidAndExistingId(nearbyNodeId) and nearbyNodeId ~= endNodeIds4T.node1Id then
                result[t].disjointNeighbourNodeIds.node1Id = nearbyNodeId
                break
            end
        end
        nearbyNodeIds = edgeUtils.isValidAndExistingId(endNodeIds4T.node2Id)
            and edgeUtils.getNearestObjectIds(
                transfUtils.position2Transf(api.engine.getComponent(endNodeIds4T.node2Id, api.type.ComponentType.BASE_NODE).position),
                0.001,
                api.type.ComponentType.BASE_NODE
            )
            or {}
        for _, nearbyNodeId in pairs(nearbyNodeIds) do
            if edgeUtils.isValidAndExistingId(nearbyNodeId) and nearbyNodeId ~= endNodeIds4T.node2Id then
                result[t].disjointNeighbourNodeIds.node2Id = nearbyNodeId
                break
            end
        end

        result[t].disjointNeighbourEdgeIds.edge1Ids = edgeUtils.getConnectedEdgeIds({result[t].disjointNeighbourNodeIds.node1Id})
        result[t].disjointNeighbourEdgeIds.edge2Ids = edgeUtils.getConnectedEdgeIds({result[t].disjointNeighbourNodeIds.node2Id})
    end

    -- print('getStationEndEntitiesTyped result =') debugPrint(result)
    return result
end

helpers.getBulldozedStationNeighbourNodeIds = function(endEntities4T)
    print('getBulldozedStationNeighbourNodeIds starting')
    if endEntities4T == nil or endEntities4T.stationEndNodePositions == nil then return nil end

    local result = {
        node1 = endEntities4T.stationEndNodePositions.node1 ~= nil
            and edgeUtils.getNearestObjectIds(
                transfUtils.position2Transf(endEntities4T.stationEndNodePositions.node1), 0.001, api.type.ComponentType.BASE_NODE
            )[1]
            or nil,
        node2 = endEntities4T.stationEndNodePositions.node2 ~= nil
            and edgeUtils.getNearestObjectIds(
                transfUtils.position2Transf(endEntities4T.stationEndNodePositions.node2), 0.001, api.type.ComponentType.BASE_NODE
            )[1]
            or nil
    }

    -- print('getBulldozedStationNeighbourNodeIds about to return') debugPrint(result)
    return result
end

helpers.getTrackEdgeIdsBetweenEdgeIds = function(_edge1Id, _edge2Id)
    print('getTrackEdgeIdsBetweenEdgeIds starting, _edge1Id =', _edge1Id, '_edge2Id =', _edge2Id)
    -- the output is sorted by sequence, from edge1 to edge2
    print('one')
    if not(edgeUtils.isValidAndExistingId(_edge1Id)) then return {} end
    if not(edgeUtils.isValidAndExistingId(_edge2Id)) then return {} end
    print('two')
    if _edge1Id == _edge2Id then return { _edge1Id } end
    print('three')
    local _baseEdge1 = api.engine.getComponent(
        _edge1Id,
        api.type.ComponentType.BASE_EDGE
    )
    local _baseEdge2 = api.engine.getComponent(
        _edge2Id,
        api.type.ComponentType.BASE_EDGE
    )
    if _baseEdge1 == nil or _baseEdge2 == nil then return {} end
    print('four')
    local _baseEdgeTrack2 = api.engine.getComponent(_edge2Id, api.type.ComponentType.BASE_EDGE_TRACK)
    if not(_baseEdgeTrack2) then return {} end
    print('five')
    -- local _trackType2 = _baseEdgeTrack2.trackType
    local _isTrack2Platform = trackUtils.isPlatform(_baseEdgeTrack2.trackType)

    local _isTrackEdgeContiguousTo2 = function(baseEdge)
        return baseEdge.node0 == _baseEdge2.node0 or baseEdge.node0 == _baseEdge2.node1
            or baseEdge.node1 == _baseEdge2.node0 or baseEdge.node1 == _baseEdge2.node1
    end

    local _isTrackEdgesSameTypeAs2 = function(edgeId)
        local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- return baseEdgeTrack ~= nil and baseEdgeTrack.trackType == _trackType2
        return trackUtils.isPlatform(baseEdgeTrack.trackType) == _isTrack2Platform
    end

    if _isTrackEdgeContiguousTo2(_baseEdge1) then
        if _isTrackEdgesSameTypeAs2(_edge1Id) then
            print('six')
            if _baseEdge1.node1 == _baseEdge2.node0 then
                print('six point one')
                return { _edge1Id, _edge2Id }
            else
                print('six point two')
                return { _edge2Id, _edge1Id }
            end
        end
        print('seven')
        return {}
    end

    local _map = api.engine.system.streetSystem.getNode2SegmentMap()

    local _getEdgesBetween1and2 = function(node0Or1FieldName)
        local baseEdge1 = _baseEdge1
        local edge1Id = _edge1Id
        local edgeIds = { _edge1Id }

        local _fetchEdgeConnectedToNode = function(nodeId)
            local adjacentEdgeIds = _map[nodeId] -- userdata
            if adjacentEdgeIds == nil then
                print('nine')
                return 0
            end
            -- we don't deal with intersections for now
            -- LOLLO NOTE even if we did, the game will have trouble when we bulldoze the tracks,
            -- if some of them cross an intersection
            if #adjacentEdgeIds > 2 then
                print('nine and a half')
                return 0
            end
            for _, edgeId in pairs(adjacentEdgeIds) do -- cannot use adjacentEdgeIds[index] here, it's fucking userdata
                print('ten')
                if not(arrayUtils.arrayHasValue(edgeIds, edgeId)) and _isTrackEdgesSameTypeAs2(edgeId) then
                    print('eleven')
                    edge1Id = edgeId
                    edgeIds[#edgeIds+1] = edge1Id
                    baseEdge1 = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                    if _isTrackEdgeContiguousTo2(baseEdge1) then
                        print('twelve')
                        edgeIds[#edgeIds+1] = _edge2Id
                        return 2
                    end
                    return 1
                end
            end
            return 0
        end

        local nodeId = baseEdge1[node0Or1FieldName]
        print('nodeId =', nodeId)
        local counter = 0
        while counter < 100 do
            counter = counter + 1
            print('eight, counter =', counter, 'nodeId =', nodeId)
            local fetchResult = _fetchEdgeConnectedToNode(nodeId)
            if fetchResult == 0 then
                print('thirteen')
                return false
            elseif fetchResult == 1 then
                -- make new nodeId
                if nodeId == baseEdge1.node0 then nodeId = baseEdge1.node1 else nodeId = baseEdge1.node0 end
                print('fourteen, new nodeId =', nodeId)
            else
                -- success
                print('fifteen')
                return edgeIds
            end
        end

        return false
    end

    local node0Results = _getEdgesBetween1and2('node0')
    print('node0results =') debugPrint(node0Results)
    if node0Results ~= false then
        return arrayUtils.getReversed(node0Results)
    end

    -- nothing good found, try in the opposite direction
    local node1Results = _getEdgesBetween1and2('node1')
    print('node1results =') debugPrint(node1Results)
    if node1Results then return node1Results end

    return {}
end

helpers.getTrackEdgeIdsBetweenNodeIds = function(_node1Id, _node2Id)
    print('getTrackEdgeIdsBetweenNodeIds starting')
    print('node1Id =', _node1Id)
    print('node2Id =', _node2Id)
    print('ONE')
    if not(edgeUtils.isValidAndExistingId(_node1Id)) then return {} end
    if not(edgeUtils.isValidAndExistingId(_node2Id)) then return {} end
    print('TWO')
    if _node1Id == _node2Id then return {} end
    print('THREE')

    local _map = api.engine.system.streetSystem.getNode2SegmentMap()
    local adjacentEdge1Ids = {}
    local adjacentEdge2Ids = {}
    local _fetchAdjacentEdges = function()
        local adjacentEdge1IdsUserdata = _map[_node1Id] -- userdata
        local adjacentEdge2IdsUserdata = _map[_node2Id] -- userdata
        if adjacentEdge1IdsUserdata == nil then
            print('FOUR')
            return false
        else
            for _, edgeId in pairs(adjacentEdge1IdsUserdata) do -- cannot use adjacentEdgeIds[index] here
                -- arrayUtils.addUnique(adjacentEdge1Ids, edgeId)
                adjacentEdge1Ids[#adjacentEdge1Ids+1] = edgeId
            end
            print('FIVE')
        end
        if adjacentEdge2IdsUserdata == nil then
            print('SIX')
            return false
        else
            for _, edgeId in pairs(adjacentEdge2IdsUserdata) do -- cannot use adjacentEdgeIds[index] here
                -- arrayUtils.addUnique(adjacentEdge2Ids, edgeId)
                adjacentEdge2Ids[#adjacentEdge2Ids+1] = edgeId
            end
            print('SEVEN')
        end

        return true
    end

    if not(_fetchAdjacentEdges()) then print('SEVEN HALF') return {} end
    if #adjacentEdge1Ids < 1 or #adjacentEdge2Ids < 1 then print('EIGHT') return {} end

    if #adjacentEdge1Ids == 1 and #adjacentEdge2Ids == 1 then
        if adjacentEdge1Ids[1] == adjacentEdge2Ids[1] then
            print('NINE')
            return { adjacentEdge1Ids[1] }
        else
            print('TEN')
        --     return {}
        end
    end

    local trackEdgeIdsBetweenEdgeIds = helpers.getTrackEdgeIdsBetweenEdgeIds(adjacentEdge1Ids[1], adjacentEdge2Ids[1])
    print('trackEdgeIdsBetweenEdgeIds =') debugPrint(trackEdgeIdsBetweenEdgeIds)
    -- print('adjacentEdge1Ids =') debugPrint(adjacentEdge1Ids)
    -- print('adjacentEdge2Ids =') debugPrint(adjacentEdge2Ids)
    -- remove edges adjacent to but outside node1 and node2

    -- for _, edgeId in pairs(trackEdgeIdsBetweenEdgeIds) do
    --     local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    --     print('base edge = ', edgeId) debugPrint(baseEdge)
    -- end

    local isExit = false
    while not(isExit) do
        if #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge1Ids, trackEdgeIdsBetweenEdgeIds[1])
        and arrayUtils.arrayHasValue(adjacentEdge1Ids, trackEdgeIdsBetweenEdgeIds[2]) then
            print('ELEVEN')
            table.remove(trackEdgeIdsBetweenEdgeIds, 1)
        elseif #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge2Ids, trackEdgeIdsBetweenEdgeIds[1])
        and arrayUtils.arrayHasValue(adjacentEdge2Ids, trackEdgeIdsBetweenEdgeIds[2]) then
            print('ELEVEN HALF')
            table.remove(trackEdgeIdsBetweenEdgeIds, 1)
        else
            print('TWELVE')
            isExit = true
        end
    end
    isExit = false
    while not(isExit) do
        if #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge1Ids, trackEdgeIdsBetweenEdgeIds[#trackEdgeIdsBetweenEdgeIds])
        and arrayUtils.arrayHasValue(adjacentEdge1Ids, trackEdgeIdsBetweenEdgeIds[#trackEdgeIdsBetweenEdgeIds-1]) then
            print('THIRTEEN')
            table.remove(trackEdgeIdsBetweenEdgeIds, #trackEdgeIdsBetweenEdgeIds)
        elseif #trackEdgeIdsBetweenEdgeIds > 1
        and arrayUtils.arrayHasValue(adjacentEdge2Ids, trackEdgeIdsBetweenEdgeIds[#trackEdgeIdsBetweenEdgeIds])
        and arrayUtils.arrayHasValue(adjacentEdge2Ids, trackEdgeIdsBetweenEdgeIds[#trackEdgeIdsBetweenEdgeIds-1]) then
            print('THIRTEEN HALF')
            table.remove(trackEdgeIdsBetweenEdgeIds, #trackEdgeIdsBetweenEdgeIds)
        else
            print('FOURTEEN')
            isExit = true
        end
    end

    -- for _, edgeId in pairs(trackEdgeIdsBetweenEdgeIds) do
    --     local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    --     print('base edge = ', edgeId) debugPrint(baseEdge)
    -- end
    return trackEdgeIdsBetweenEdgeIds
end

helpers.getTrackEdgeIdsBetweenEdgeIdsBROKEN = function(edge1Id, edge2Id)
    print('edge1Id =')
    debugPrint(edge1Id)
    print('edge2Id =')
    debugPrint(edge2Id)
    local edge1IdTyped = api.type.EdgeId.new()
    edge1IdTyped.entity = edge1Id
    local edge2IdTyped = api.type.EdgeId.new()
    edge2IdTyped.entity = edge2Id
    print('edge1IdTyped =')
    debugPrint(edge1IdTyped)
    print('edge2IdTyped =')
    debugPrint(edge2IdTyped)
    local edgeIdDir1 = api.type.EdgeIdDirAndLength.new(edge1IdTyped, true, 10)
    -- local edgeIdDir2 = api.type.EdgeIdDirAndLength.new(edge2IdTyped, true, 10)
    print('edgeIdDir1 =')
    debugPrint(edgeIdDir1)
    local baseEdge1 = api.engine.getComponent(
        edge1Id,
        api.type.ComponentType.BASE_EDGE
    )
    local baseEdge2 = api.engine.getComponent(
        edge2Id,
        api.type.ComponentType.BASE_EDGE
    )
    print('baseEdge1 =')
    debugPrint(baseEdge1)
    print('baseEdge2 =')
    debugPrint(baseEdge2)
    local node1Typed = api.type.NodeId.new()
    node1Typed.entity = baseEdge2.node0
    local node2Typed = api.type.NodeId.new()
    node2Typed.entity = baseEdge2.node1

    print('edgeIdDir1 =')
    debugPrint(edgeIdDir1)
    print('node1Typed =')
    debugPrint(node1Typed)
    print('node2Typed =')
    debugPrint(node2Typed)
    -- UG TODO this dumps without useful messages: ask UG
    local path = api.engine.util.pathfinding.findPath(
        { edgeIdDir1 },
        { node1Typed },
        {
            api.type.enum.TransportMode.TRAIN,
            api.type.enum.TransportMode.ELECTRIC_TRAIN
        },
        500.0
    )
    -- online example (outdated and generally useless):
    -- Find a path from two edges of the street entity 170679 to the nodes of the street entity 171540:
    print('path =')
    debugPrint(path)

    -- local e1 = api.type.EdgeId.new(170679, 0)
    -- local e2 = api.type.EdgeId.new(170679, 1)
    -- local n1 = api.type.NodeId.new(171540, 0)
    -- local n2 = api.type.NodeId.new(171540, 1)
    -- local n3 = api.type.NodeId.new(171540, 2)
    -- local n4 = api.type.NodeId.new(171540, 3)
    local e1 = api.type.EdgeId.new(edge1Id, 0)
    local e2 = api.type.EdgeId.new(edge1Id, 1)
    local n1 = api.type.NodeId.new(edge2Id, 0)
    local n2 = api.type.NodeId.new(edge2Id, 1)
    -- local n3 = api.type.NodeId.new(edge2Id, 2)
    -- local n4 = api.type.NodeId.new(edge2Id, 3)

    -- g = api.engine.getComponent(171540, api.type.ComponentType.TRANSPORT_NETWORK)

    local z = api.engine.util.pathfinding.findPath(
        {
            api.type.EdgeIdDirAndLength.new(e1, true, .0),
            api.type.EdgeIdDirAndLength.new(e2, true, .0),
        },
        {
            n1, n2 --, n3, n4
        },
        {},
        1000
    )
    print('z =')
    debugPrint(z)
    return {}
end

return helpers