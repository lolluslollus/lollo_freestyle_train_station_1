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

    getStationEndNodeIdsUntyped = function(con, nTerminal, stationConstructionId)
        -- print('getStationEndNodesUnsorted starting, nTerminal =', nTerminal)
        -- print('getStationEndNodesUnsorted, con =') debugPrint(con)
        -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
        if not(con) or con.fileName ~= _constants.stationConFileNameLong then
            return {}
        end

        local endNodeIds = {}
        for _, frozenEdgeId in pairs(con.frozenEdges) do
            if edgeUtils.isValidAndExistingId(frozenEdgeId) then
                local baseEdge = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE)
                local baseEdgeTrack = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                if baseEdge ~= nil and baseEdgeTrack ~= nil and not(trackUtils.isPlatform(baseEdgeTrack.trackType)) then
                    local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                    local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                    for _, edgeInTerminal in pairs(con.params.terminals[nTerminal].trackEdgeLists) do
                        if edgeInTerminal ~= nil and (
                        (
                            edgeInTerminal.posTanX2[1][1][1] == baseNode0.position.x
                            and edgeInTerminal.posTanX2[1][1][2] == baseNode0.position.y
                            and edgeInTerminal.posTanX2[1][1][3] == baseNode0.position.z
                            and edgeInTerminal.posTanX2[2][1][1] == baseNode1.position.x
                            and edgeInTerminal.posTanX2[2][1][2] == baseNode1.position.y
                            and edgeInTerminal.posTanX2[2][1][3] == baseNode1.position.z
                        ) or (
                            edgeInTerminal.posTanX2[1][1][1] == baseNode1.position.x
                            and edgeInTerminal.posTanX2[1][1][2] == baseNode1.position.y
                            and edgeInTerminal.posTanX2[1][1][3] == baseNode1.position.z
                            and edgeInTerminal.posTanX2[2][1][1] == baseNode0.position.x
                            and edgeInTerminal.posTanX2[2][1][2] == baseNode0.position.y
                            and edgeInTerminal.posTanX2[2][1][3] == baseNode0.position.z
                        )) then
                            if not(arrayUtils.arrayHasValue(con.frozenNodes, baseEdge.node0)) then
                                endNodeIds[#endNodeIds+1] = baseEdge.node0
                            end
                            if not(arrayUtils.arrayHasValue(con.frozenNodes, baseEdge.node1)) then
                                endNodeIds[#endNodeIds+1] = baseEdge.node1
                            end
                            break
                        end
                    end
                end
            else
                print('WARNING: invalid frozen edge id')
            end
        end

        if #endNodeIds ~= 2 then
            print('WARNING: found', #endNodeIds, 'free nodes in station construction')
            print('stationConstructionId =') debugPrint(stationConstructionId)
            print('I found endNodeIds =') debugPrint(endNodeIds)
        end

        return endNodeIds
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
            local result = {
                catenary = baseEdgeTrack.catenary,
                -- edgeId = edgeIds[i],
                posTanX2 = {
                    {
                        {
                            baseNode0.position.x,
                            baseNode0.position.y,
                            baseNode0.position.z,
                        },
                        {
                            baseEdge.tangent0.x,
                            baseEdge.tangent0.y,
                            baseEdge.tangent0.z,
                        }
                    },
                    {
                        {
                            baseNode1.position.x,
                            baseNode1.position.y,
                            baseNode1.position.z,
                        },
                        {
                            baseEdge.tangent1.x,
                            baseEdge.tangent1.y,
                            baseEdge.tangent1.z,
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

    getAllEdgeObjectsWithModelId = function(refModelId)
        local results = {}
        local nearbyEdgeIds = edgeUtils.getNearestObjectIds(_constants.idTransf, 99999, api.type.ComponentType.BASE_EDGE)
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

        print('getAllEdgeObjectsWithModelId is about to return')
        debugPrint(results)
        return results
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

    getCentreLanePositions = function(platformEdgeIds, isCargo)
        -- print('getCentreLanePositions starting')
        if type(platformEdgeIds) ~= 'table' then return {} end

        local maxEdgeLength = isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength
        local results = {}
        for _, platformEdgeId in pairs(platformEdgeIds) do
            if edgeUtils.isValidAndExistingId(platformEdgeId) then
                local edgeLength = edgeUtils.getEdgeLength(platformEdgeId)
                -- print('edgeLength =') debugPrint(edgeLength)
                local nModelsInEdge = math.ceil(edgeLength / maxEdgeLength)
                -- print('nModelsInEdge =') debugPrint(nModelsInEdge)
                local basePlatformEdge =  api.engine.getComponent(platformEdgeId, api.type.ComponentType.BASE_EDGE)
                local basePlatformNode0 = api.engine.getComponent(basePlatformEdge.node0, api.type.ComponentType.BASE_NODE)
                local basePlatformNode1 = api.engine.getComponent(basePlatformEdge.node1, api.type.ComponentType.BASE_NODE)
                -- print('basePlatformEdge =') debugPrint(basePlatformEdge)
                -- print('basePlatformNode0 =') debugPrint(basePlatformNode0)
                -- print('basePlatformNode1 =') debugPrint(basePlatformNode1)

                local edgeResults = {}
                local lengthCovered = 0
                local previousNodeBetween = nil
                for i = 1, nModelsInEdge do
                    -- print('i == ', i)
                    local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(platformEdgeId, i / nModelsInEdge)
                    -- print('nodeBetween =') debugPrint(nodeBetween)
                    if nodeBetween == nil then
                        print('ERROR: nodeBetween not found')
                        return {}
                    else
                        local lengthFactor = nodeBetween.length0 - lengthCovered
                        if i == 1 then
                            edgeResults[#edgeResults+1] = {
                                posTanX2 = {
                                    {
                                        {
                                            basePlatformNode0.position.x,
                                            basePlatformNode0.position.y,
                                            basePlatformNode0.position.z,
                                        },
                                        {
                                            basePlatformEdge.tangent0.x * lengthFactor / edgeLength,
                                            basePlatformEdge.tangent0.y * lengthFactor / edgeLength,
                                            basePlatformEdge.tangent0.z * lengthFactor / edgeLength,
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
                                            basePlatformNode1.position.x,
                                            basePlatformNode1.position.y,
                                            basePlatformNode1.position.z,
                                        },
                                        {
                                            basePlatformEdge.tangent1.x * lengthFactor / edgeLength,
                                            basePlatformEdge.tangent1.y * lengthFactor / edgeLength,
                                            basePlatformEdge.tangent1.z * lengthFactor / edgeLength,
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

        -- print('LOLLO assignment =')
        -- debugPrint(result)
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
                print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects =')
                debugPrint(newEdge.comp.objects)
            else
                print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects = not changed')
            end
        else
            print('replaceEdgeWithSameRemovingObject: objectIdToRemove is no good, it is') debugPrint(objectIdToRemove)
            newEdge.comp.objects = oldEdge.objects
        end

        print('newEdge.comp.objects:')
        for key, value in pairs(newEdge.comp.objects) do
            print('key =', key) debugPrint(value)
        end

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
        local endNodeIds4T = helpers.getStationEndNodeIdsUntyped(con, t, stationConstructionId)
        if #endNodeIds4T ~= 2 then
            print('ERROR: getStationEndEntitiesTyped cannnot find the end nodes of station', stationConstructionId)
            print('endNodeIds4T =') debugPrint(endNodeIds4T)
            print('stationConstructionId =', stationConstructionId)
            -- return nil
        end

        -- I cannot clone these, for some reason: it dumps
        local node1Position = edgeUtils.isValidAndExistingId(endNodeIds4T[1])
            and api.engine.getComponent(endNodeIds4T[1], api.type.ComponentType.BASE_NODE).position
            or nil
        local node2Position = edgeUtils.isValidAndExistingId(endNodeIds4T[2])
            and api.engine.getComponent(endNodeIds4T[2], api.type.ComponentType.BASE_NODE).position
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
                node1Id = endNodeIds4T[1],
                node2Id = endNodeIds4T[2],
            },
            stationEndNodePositions = {
                node1 = node1Position ~= nil and { x = node1Position.x, y = node1Position.y, z = node1Position.z } or nil,
                node2 = node2Position ~= nil and { x = node2Position.x, y = node2Position.y, z = node2Position.z } or nil,
            }
        }

        for i = 1, 2 do
            local nearbyNodeIds = edgeUtils.isValidAndExistingId(endNodeIds4T[i])
                and edgeUtils.getNearestObjectIds(
                    transfUtils.position2Transf(api.engine.getComponent(endNodeIds4T[i], api.type.ComponentType.BASE_NODE).position),
                    0.001,
                    api.type.ComponentType.BASE_NODE
                )
                or {}
            for _, nearbyNodeId in pairs(nearbyNodeIds) do
                if edgeUtils.isValidAndExistingId(nearbyNodeId) and nearbyNodeId ~= endNodeIds4T[i] then
                    if i == 1 then result[t].disjointNeighbourNodeIds.node1Id = nearbyNodeId
                    else result[t].disjointNeighbourNodeIds.node2Id = nearbyNodeId
                    end
                    break
                end
            end
        end

        result[t].disjointNeighbourEdgeIds.edge1Ids = edgeUtils.getConnectedEdgeIds({result[t].disjointNeighbourNodeIds.node1Id})
        result[t].disjointNeighbourEdgeIds.edge2Ids = edgeUtils.getConnectedEdgeIds({result[t].disjointNeighbourNodeIds.node2Id})
    end

    print('getStationEndEntitiesTyped result =') debugPrint(result)
    return result
end

helpers.getBulldozedStationNeighbourNodeIds = function(endEntities4T)
    print('getBulldozedStationNeighbourNodeIds starting')
    if endEntities4T == nil or endEntities4T.stationEndNodePositions == nil then return nil end

    -- print('candidates for node 1 =')
    -- debugPrint(edgeUtils.getNearestObjectIds(
    --     transfUtils.position2Transf(endEntities4T.stationEndNodePositions.node1), 0.001, api.type.ComponentType.BASE_NODE
    -- ))
    -- print('candidates for node 2 =')
    -- debugPrint(edgeUtils.getNearestObjectIds(
    --     transfUtils.position2Transf(endEntities4T.stationEndNodePositions.node2), 0.001, api.type.ComponentType.BASE_NODE
    -- ))

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

    print('getBulldozedStationNeighbourNodeIds about to return') debugPrint(result)
    return result
end

return helpers