local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeHelper')
local transfUtilUG = require('transf')

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

local _eventId = '__lolloFreestyleTrainStation__'
local _eventNames = {
    PLATFORM_WAYPOINT_BUILT_ON_PLATFORM = 'platformWaypointBuiltOnPlatform',
    PLATFORM_WAYPOINT_BUILT_OUTSIDE_PLATFORM = 'platformWaypointBuiltOutsidePlatform',
    TRACK_WAYPOINT_1_BUILT_ON_PLATFORM = 'trackWaypoint1BuiltOnPlatform',
    TRACK_WAYPOINT_1_BUILT_OUTSIDE_PLATFORM = 'trackWaypoint1BuiltOutsidePlatform',
    TRACK_WAYPOINT_2_BUILT_ON_PLATFORM = 'trackWaypoint2BuiltOnPlatform',
    TRACK_WAYPOINT_2_BUILT_OUTSIDE_PLATFORM = 'trackWaypoint2BuiltOutsidePlatform',
}

local _newEdgeType = 1 -- 0 = ROAD, 1 = RAIL
local _utils = {
    getContiguousEdges = function(edgeId, trackType)
        local _calcContiguousEdges = function(firstEdgeId, firstNodeId, map, trackType, isInsertFirst, results)
            local refEdgeId = firstEdgeId
            local edgeIds = map[firstNodeId] -- userdata
            local refNodeId = firstNodeId
            local isExit = false
            while not(isExit) do
                if not(edgeIds) or #edgeIds ~= 2 then
                    isExit = true
                else
                    for _, edgeId in pairs(edgeIds) do -- cannot use edgeIds[index] here
                        print('edgeId =')
                        debugPrint(edgeId)
                        if edgeId ~= refEdgeId then
                            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                            print('baseEdgeTrack =')
                            debugPrint(baseEdgeTrack)
                            if not(baseEdgeTrack) or baseEdgeTrack.trackType ~= trackType then
                                isExit = true
                                break
                            else
                                if isInsertFirst then
                                    table.insert(results, 1, edgeId)
                                else
                                    table.insert(results, edgeId)
                                end
                                local edgeData = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                                if edgeData.node0 ~= refNodeId then
                                    refNodeId = edgeData.node0
                                else
                                    refNodeId = edgeData.node1
                                end
                                refEdgeId = edgeId
                                break
                            end
                        end
                    end
                    edgeIds = map[refNodeId]
                end
            end
        end

        print('_getContiguousEdges starting, edgeId =')
        debugPrint(edgeId)
        print('track type =')
        debugPrint(trackType)

        if not(edgeId) or not(trackType) then return {} end

        local _baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        if not(_baseEdgeTrack) or _baseEdgeTrack.trackType ~= trackType then return {} end

        local _baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
        local _edgeId = edgeId
        local _map = api.engine.system.streetSystem.getNode2SegmentMap()
        local results = { edgeId }

        _calcContiguousEdges(_edgeId, _baseEdge.node0, _map, trackType, true, results)
        _calcContiguousEdges(_edgeId, _baseEdge.node1, _map, trackType, false, results)

        return results
    end,

    getObjectPosition = function(objectId)
        -- print('getObjectPosition starting')
        if type(objectId) ~= 'number' or objectId < 0 then return nil end

        local modelInstanceList = api.engine.getComponent(objectId, api.type.ComponentType.MODEL_INSTANCE_LIST)
        if not(modelInstanceList) then return nil end

        local fatInstances = modelInstanceList.fatInstances
        if not(fatInstances) or not(fatInstances[1]) or not(fatInstances[1].transf) or not(fatInstances[1].transf.cols) then return nil end

        local objectTransf = transfUtilUG.new(
            fatInstances[1].transf:cols(0),
            fatInstances[1].transf:cols(1),
            fatInstances[1].transf:cols(2),
            fatInstances[1].transf:cols(3)
        )
        -- print('fatInstances[1]', fatInstances[1] and true)
        -- print('fatInstances[2]', fatInstances[2] and true) -- always nil
        -- print('fatInstances[3]', fatInstances[3] and true) -- always nil
        -- print('objectTransf =')
        -- debugPrint(objectTransf)
        return {
            [1] = objectTransf[13],
            [2] = objectTransf[14],
            [3] = objectTransf[15]
        }
    end,

    getOuterNodes = function(contiguousEdgeIds, trackType)
        local _hasOnlyOneEdgeOfType1 = function(nodeId, map, trackType)
            if type(nodeId) ~= 'number' or nodeId < 1 or not(trackType) then return false end

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
        if _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node0, _map, trackType) then
            results[#results+1] = _baseEdgeFirst.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node1, _map, trackType) then
            results[#results+1] = _baseEdgeFirst.node1
        end
        if _hasOnlyOneEdgeOfType1(_baseEdgeLast.node0, _map, trackType) then
            results[#results+1] = _baseEdgeLast.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeLast.node1, _map, trackType) then
            results[#results+1] = _baseEdgeLast.node1
        end

        return results
    end,

    getLastBuiltEdge = function(entity2tn)
        local nodeIds = {}
        for k, _ in pairs(entity2tn) do
            local entity = game.interface.getEntity(k)
            if entity.type == 'BASE_NODE' then nodeIds[#nodeIds+1] = entity.id end
        end
        if #nodeIds ~= 2 then return nil end

        for k, _ in pairs(entity2tn) do
            local entity = game.interface.getEntity(k)
            if entity.type == 'BASE_EDGE'
            and ((entity.node0 == nodeIds[1] and entity.node1 == nodeIds[2])
            or (entity.node0 == nodeIds[2] and entity.node1 == nodeIds[1])) then
                local extraEdgeData = api.engine.getComponent(entity.id, api.type.ComponentType.BASE_EDGE)
                return {
                    id = entity.id,
                    objects = extraEdgeData.objects
                }
            end
        end

        return nil
    end,

    getTransfFromApiResult = function(transfStr)
        transfStr = transfStr:gsub('%(%(', '(')
        transfStr = transfStr:gsub('%)%)', ')')
        local results = {}
        for match0 in transfStr:gmatch('%([^(%))]+%)') do
            local noBrackets = match0:gsub('%(', '')
            noBrackets = noBrackets:gsub('%)', '')
            for match1 in noBrackets:gmatch('[%-%.%d]+') do
                results[#results + 1] = tonumber(match1 or '0')
            end
        end
        return results
    end,

    getWaypointId = function(edgeObjects, refModelId)
        local result = nil
        for i = 1, #edgeObjects do
            -- debugPrint(game.interface.getEntity(edgeObjects[i][1]))
            local modelInstanceList = api.engine.getComponent(edgeObjects[i][1], api.type.ComponentType.MODEL_INSTANCE_LIST)
            -- print('LOLLO model instance list =')
            -- debugPrint(modelInstanceList)
            if modelInstanceList
            and modelInstanceList.fatInstances
            and modelInstanceList.fatInstances[1]
            and modelInstanceList.fatInstances[1].modelId == refModelId then
                result = edgeObjects[i][1]
                break
            end
        end
        return result
    end,

    getWhichEdgeGetsEdgeObjectAfterSplit = function(edgeObjPosition, node0pos, node1pos, nodeBetween)
        local result = {
            -- assignToFirstEstimate = nil,
            assignToSecondEstimate = nil,
        }
        -- print('LOLLO attempting to place edge object with position =')
        -- debugPrint(edgeObjPosition)
        -- print('wholeEdge.node0pos =')
        -- debugPrint(node0pos)
        -- print('nodeBetween.position =')
        -- debugPrint(nodeBetween.position)
        -- print('nodeBetween.tangent =')
        -- debugPrint(nodeBetween.tangent)
        -- print('wholeEdge.node1pos =')
        -- debugPrint(node1pos)
        -- first estimator
        -- local nodeBetween_Node0_Distance = edgeUtils.getVectorLength({
        --     nodeBetween.position[1] - node0pos[1],
        --     nodeBetween.position[2] - node0pos[2]
        -- })
        -- local nodeBetween_Node1_Distance = edgeUtils.getVectorLength({
        --     nodeBetween.position[1] - node1pos[1],
        --     nodeBetween.position[2] - node1pos[2]
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
        -- the angle is alpha = atan2(nodeBetween.tangent[2], nodeBetween.tangent[1]) + PI / 2
        -- so b = math.tan(alpha)
        -- a = y - bx
        -- so a = nodeBetween.position[2] - b * nodeBetween.position[1]
        -- points under this line will go one way, the others the other way
        local alpha = math.atan2(nodeBetween.tangent[2], nodeBetween.tangent[1]) + math.pi * 0.5
        local b = math.tan(alpha)
        if math.abs(b) < 1e+06 then
            local a = nodeBetween.position[2] - b * nodeBetween.position[1]
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
            if edgeObjPosition[1] > nodeBetween.position[1] then
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if node0pos[1] > nodeBetween.position[1] then
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if node1pos[1] > nodeBetween.position[1] then
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
}

local _actions = {
    bulldozeConstruction = function(constructionId)
        -- print('constructionId =', constructionId)
        if type(constructionId) ~= 'number' or constructionId < 0 then return end

        local oldConstruction = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        -- print('oldConstruction =')
        -- debugPrint(oldConstruction)
        if not(oldConstruction) or not(oldConstruction.params) then return end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { constructionId }
        -- proposal.constructionsToRemove[1] = constructionId -- fails to add
        -- proposal.constructionsToRemove:add(constructionId) -- fails to add

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, false), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(res, success)
                -- print('LOLLO _bulldozeConstruction res = ')
                -- debugPrint(res)
                --for _, v in pairs(res.entities) do print(v) end
                -- print('LOLLO _bulldozeConstruction success = ')
                -- debugPrint(success)
            end
        )
    end,

    replageEdgeWithSame = function(oldEdgeId, objectIdToRemove)
        -- only for testing
        -- replaces a track segment with an identical one, without destroying the buildings
        if type(oldEdgeId) ~= 'number' or oldEdgeId < 0 then return end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return end

        local playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = _newEdgeType
        newEdge.comp = oldEdge
        -- newEdge.playerOwned = {player = api.engine.util.getPlayer()}
        newEdge.playerOwned = playerOwned
        newEdge.trackEdge = oldEdgeTrack

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        --[[ local sampleNewEdge =
        {
        entity = -1,
        comp = {
            node0 = 13010,
            node1 = 18753,
            tangent0 = {
            x = -32.318000793457,
            y = 81.757850646973,
            z = 3.0953373908997,
            },
            tangent1 = {
            x = -34.457527160645,
            y = 80.931526184082,
            z = -1.0708819627762,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
        },
        type = 0,
        params = {
            streetType = 23,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
        },
        playerOwned = nil,
        streetEdge = {
            streetType = 23,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
        },
        trackEdge = {
            trackType = -1,
            catenary = false,
        },
        } ]]

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, false),
            function(res, success)
                print('LOLLO res = ')
                debugPrint(res)
                --for _, v in pairs(res.entities) do print(v) end
                -- print('LOLLO success = ')
                debugPrint(success)
            end
        )
    end,

    replaceEdgeWithTrackType = function(oldEdgeId, newTrackTypeId)
        -- replaces the track without destroying the buildings
        if type(oldEdgeId) ~= 'number' or oldEdgeId < 0
        or type(newTrackTypeId) ~= 'number' or newTrackTypeId < 0 then return end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return end

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = _newEdgeType
        newEdge.comp = oldEdge
        -- newEdge.playerOwned = {player = api.engine.util.getPlayer()}
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge.trackEdge = oldEdgeTrack
        newEdge.trackEdge.trackType = newTrackTypeId
        -- add / remove tram tracks upgrade if the new street type explicitly wants so
        -- if streetUtils.transportModes.isTramRightBarred(newStreetTypeId) then
        --     newEdge.trackEdge.tramTrackType = 0
        -- elseif streetUtils.getIsStreetAllTramTracks((api.res.streetTypeRep.get(newStreetTypeId) or {}).laneConfigs) then
        --     newEdge.trackEdge.tramTrackType = 2
        -- end

        -- leave if nothing changed
        if newEdge.trackEdge.trackType == oldEdgeTrack.trackType
        and newEdge.trackEdge.tramTrackType == oldEdgeTrack.tramTrackType then return end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, false),
            function(res, success)
                -- print('LOLLO res = ')
                -- debugPrint(res)
                --for _, v in pairs(res.entities) do print(v) end
                -- print('LOLLO _replaceEdgeWithStreetType success = ')
                -- debugPrint(success)
            end
        )
    end,

    splitEdge = function(wholeEdgeId, position0, tangent0, position1, tangent1, nodeBetween, objectIdToRemove)
        if type(wholeEdgeId) ~= 'number' or wholeEdgeId < 0 or type(nodeBetween) ~= 'table' then return end

        local node0TangentLength = edgeUtils.getVectorLength({
            tangent0.x,
            tangent0.y,
            tangent0.z
        })
        local node1TangentLength = edgeUtils.getVectorLength({
            tangent1.x,
            tangent1.y,
            tangent1.z
        })
        local edge0Length = edgeUtils.getVectorLength({
            nodeBetween.position[1] - position0.x,
            nodeBetween.position[2] - position0.y,
            nodeBetween.position[3] - position0.z
        })
        local edge1Length = edgeUtils.getVectorLength({
            nodeBetween.position[1] - position1.x,
            nodeBetween.position[2] - position1.y,
            nodeBetween.position[3] - position1.z
        })

        local oldEdge = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return end

        local playerOwned = api.type.PlayerOwned.new()
        playerOwned.player = api.engine.util.getPlayer()

        local newNodeBetween = api.type.NodeAndEntity.new()
        newNodeBetween.entity = -3
        newNodeBetween.comp.position = api.type.Vec3f.new(nodeBetween.position[1], nodeBetween.position[2], nodeBetween.position[3])

        local newEdge0 = api.type.SegmentAndEntity.new()
        newEdge0.entity = -1
        newEdge0.type = _newEdgeType
        newEdge0.comp.node0 = oldEdge.node0
        newEdge0.comp.node1 = -3
        newEdge0.comp.tangent0 = api.type.Vec3f.new(
            tangent0.x * edge0Length / node0TangentLength,
            tangent0.y * edge0Length / node0TangentLength,
            tangent0.z * edge0Length / node0TangentLength
        )
        newEdge0.comp.tangent1 = api.type.Vec3f.new(
            nodeBetween.tangent[1] * edge0Length,
            nodeBetween.tangent[2] * edge0Length,
            nodeBetween.tangent[3] * edge0Length
        )
        newEdge0.comp.type = oldEdge.type -- respect bridge or tunnel
        newEdge0.comp.typeIndex = oldEdge.typeIndex -- respect bridge or tunnel
        newEdge0.playerOwned = playerOwned
        newEdge0.trackEdge = oldEdgeTrack -- TODO here it fails coz it expects userdata but receives sol.ecs::component::BaseEdgeTrack

        local newEdge1 = api.type.SegmentAndEntity.new()
        newEdge1.entity = -2
        newEdge1.type = _newEdgeType
        newEdge1.comp.node0 = -3
        newEdge1.comp.node1 = oldEdge.node1
        newEdge1.comp.tangent0 = api.type.Vec3f.new(
            nodeBetween.tangent[1] * edge1Length,
            nodeBetween.tangent[2] * edge1Length,
            nodeBetween.tangent[3] * edge1Length
        )
        newEdge1.comp.tangent1 = api.type.Vec3f.new(
            tangent1.x * edge1Length / node1TangentLength,
            tangent1.y * edge1Length / node1TangentLength,
            tangent1.z * edge1Length / node1TangentLength
        )
        newEdge1.comp.type = oldEdge.type
        newEdge1.comp.typeIndex = oldEdge.typeIndex
        newEdge1.playerOwned = playerOwned
        newEdge1.trackEdge = oldEdgeTrack

        if type(oldEdge.objects) == 'table' and #oldEdge.objects > 1 then
            local edge0Objects = {}
            local edge1Objects = {}
            for _, edgeObj in pairs(oldEdge.objects) do
                if edgeObj[1] ~= objectIdToRemove then
                    -- print('edgeObjEntityId =', edgeObj[1])
                    -- local edgeObjPositionOld = _utils.getObjectPositionOld(edgeObj[1])
                    local edgeObjPosition = _utils.getObjectPosition(edgeObj[1])
                    -- print('edge object position: old and new way')
                    -- debugPrint(edgeObjPositionOld)
                    -- debugPrint(edgeObjPosition)
                    if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                    local assignment = _utils.getWhichEdgeGetsEdgeObjectAfterSplit(
                        edgeObjPosition,
                        {position0.x, position0.y, position0.z},
                        {position1.x, position1.y, position1.z},
                        nodeBetween
                    )
                    -- if assignment.assignToFirstEstimate == 0 then
                    if assignment.assignToSecondEstimate == 0 then
                        table.insert(edge0Objects, { edgeObj[1], edgeObj[2] })
                        -- local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(edgeObj[1])
                        -- LOLLO TODO do we really need this check? Now we know that the crash happens with removed mod stations!
                        -- if arrayUtils.arrayHasValue(edge1StationGroups, stationGroupId) then return end -- don't split station groups
                        -- if type(stationGroupId) == 'number' and stationGroupId > 0 then table.insert(edge0StationGroups, stationGroupId) end
                    -- elseif assignment.assignToFirstEstimate == 1 then
                    elseif assignment.assignToSecondEstimate == 1 then
                        table.insert(edge1Objects, { edgeObj[1], edgeObj[2] })
                        -- local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(edgeObj[1])
                        -- LOLLO TODO do we really need this check? Now we know that the crash happens with removed mod stations!
                        -- if arrayUtils.arrayHasValue(edge0StationGroups, stationGroupId) then return end -- don't split station groups
                        -- if type(stationGroupId) == 'number' and stationGroupId > 0 then table.insert(edge1StationGroups, stationGroupId) end
                    else
                        -- print('don\'t change anything and leave')
                        -- print('LOLLO error, assignment.assignToFirstEstimate =', assignment.assignToFirstEstimate)
                        -- print('LOLLO error, assignment.assignToSecondEstimate =', assignment.assignToSecondEstimate)
                        return -- change nothing and leave
                    end
                end
            end
            newEdge0.comp.objects = edge0Objects -- LOLLO NOTE cannot insert directly into edge0.comp.objects
            newEdge1.comp.objects = edge1Objects
        end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToAdd[1] = newEdge0
        proposal.streetProposal.edgesToAdd[2] = newEdge1
        proposal.streetProposal.edgesToRemove[1] = wholeEdgeId
        proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        proposal.streetProposal.nodesToAdd[1] = newNodeBetween
        -- print('split proposal =')
        -- debugPrint(proposal)

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, false), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(res, success)
                -- print('LOLLO freestyle train station callback returned res = ')
                -- debugPrint(res)
                --for _, v in pairs(res.entities) do print(v) end
                -- print('LOLLO freestyle train station callback returned success = ')
                print(success)
            end
        )
    end,
}

local function _isBuildingFreestyleTrainStation(param)
    return _utils.isBuildingConstructionWithFileName(param, 'station/rail/lollo_freestyle_train_station.con')
end

function data()
    return {
        ini = function()
        end,
        handleEvent = function(src, id, name, param)
            if (id ~= _eventId) then return end
            -- if type(param) ~= 'table' or type(param.constructionEntityId) ~= 'number' or param.constructionEntityId < 0 then return end

            print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'param =')
            debugPrint(param)
            -- handleEvent firing, src =	lollo_freestyle_train_station.lua	id =	__lolloFreestyleTrainStation__	name =	waypointBuilt	param =

            if name == _eventNames.TRACK_WAYPOINT_1_BUILT_OUTSIDE_PLATFORM or name == _eventNames.TRACK_WAYPOINT_2_BUILT_OUTSIDE_PLATFORM then
                if param.edgeId and param.transf then
                    -- _actions.replageEdgeWithSame(param.edgeId)
                    -- if true then return end

                    local oldEdge = api.engine.getComponent(param.edgeId, api.type.ComponentType.BASE_EDGE)
                    if oldEdge then
                        local node0 = api.engine.getComponent(oldEdge.node0, api.type.ComponentType.BASE_NODE)
                        local node1 = api.engine.getComponent(oldEdge.node1, api.type.ComponentType.BASE_NODE)
                        if node0 and node1 then
                            local nodeBetween = edgeUtils.getNodeBetween(
                                node0.position,
                                oldEdge.tangent0,
                                node1.position,
                                oldEdge.tangent1,
                                -- LOLLO NOTE position and transf are always very similar
                                {
                                    x = param.transf[13],
                                    y = param.transf[14],
                                    z = param.transf[15],
                                }
                            )

                            _actions.splitEdge(
                                param.edgeId,
                                node0.position,
                                oldEdge.tangent0,
                                node1.position,
                                oldEdge.tangent1,
                                nodeBetween,
                                param.waypointId
                            )
                        end
                    end
                end
            end
            -- print('param.constructionEntityId =', param.constructionEntityId or 'NIL')
            -- if name == 'lorryStationBuilt' then
            --     _replaceStationWithSnapNodes(param.constructionEntityId)
            -- elseif name == 'lorryStationSelected' then
            --     _replaceStationWithStreetType_(param.constructionEntityId)
            -- end
            -- LOLLO TODO remove waypoint
        end,
        guiHandleEvent = function(id, name, param)
            -- LOLLO NOTE param can have different types, even boolean, depending on the event id and name
            if name == 'builder.apply' then
                xpcall(
                    function()
                        print('guiHandleEvent caught id =', id, 'name =', name, 'param =')
                        -- debugPrint(param)

                        if param and param.proposal and param.proposal.proposal
                        and param.proposal.proposal.edgeObjectsToAdd
                        and param.proposal.proposal.edgeObjectsToAdd[1]
                        and param.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                        then
                            local platformWaypointModelId = api.res.modelRep.find('railroad/lollo_freestyle_train_station/lollo_platform_waypoint.mdl')
                            local trackWaypoint1ModelId = api.res.modelRep.find('railroad/lollo_freestyle_train_station/lollo_track_waypoint_1.mdl')
                            local trackWaypoint2ModelId = api.res.modelRep.find('railroad/lollo_freestyle_train_station/lollo_track_waypoint_2.mdl')
                            local platformTrackType = api.res.trackTypeRep.find('platform.lua')

                            -- if not param.result or not param.result[1] then
                            --     return
                            -- end

                            if param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == platformWaypointModelId then
                                print('LOLLO platform waypoint built!')
                                local lastBuiltEdge = _utils.getLastBuiltEdge(param.data.entity2tn)
                                if not(lastBuiltEdge) then return end

                                local waypointId = _utils.getWaypointId(lastBuiltEdge.objects, platformWaypointModelId)
                                -- for i = 1, #lastBuiltEdge.objects do
                                --     -- debugPrint(game.interface.getEntity(lastBuiltEdge.objects[i][1]))
                                --     local modelInstanceList = api.engine.getComponent(lastBuiltEdge.objects[i][1], api.type.ComponentType.MODEL_INSTANCE_LIST)
                                --     -- print('LOLLO model instance list =')
                                --     -- debugPrint(modelInstanceList)
                                --     if modelInstanceList
                                --     and modelInstanceList.fatInstances
                                --     and modelInstanceList.fatInstances[1]
                                --     and modelInstanceList.fatInstances[1].modelId == platformWaypointModelId then
                                --         waypointId = lastBuiltEdge.objects[i][1]
                                --     end
                                -- end
                                if not(waypointId) then return end

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if param.proposal.proposal.addedSegments[1].trackEdge.trackType == platformTrackType then
                                    -- waypoint built on platform
                                    -- LOLLO TODO:
                                    -- find all consecutive edges of the same type
                                    -- sort them from first to last
                                    local continuousEdges = _utils.getContiguousEdges(
                                        lastBuiltEdge.id,
                                        platformTrackType
                                    )
                                    print('contiguous edges =')
                                    debugPrint(continuousEdges)
                                    print('# contiguous edges =')
                                    debugPrint(#continuousEdges)
                                    print('type of contiguous edges =')
                                    debugPrint(type(continuousEdges))
                                    print('contiguous edges[1] =')
                                    debugPrint(continuousEdges[1])
                                    print('contiguous edges[last] =')
                                    debugPrint(continuousEdges[#continuousEdges])

                                    local outerNodes = _utils.getOuterNodes(continuousEdges, platformTrackType)
                                    print('outerNodes =')
                                    debugPrint(outerNodes)

                                    -- left side: find the 2 tracks (real tracks, not platform tracks) nearest to the platform start and end
                                    -- repeat on the right side
                                    -- for now, identify them with the red and green pins instead!
                                    -- if at least one normal track was found:
                                        -- raise an event
                                        -- the worker thread will:
                                        -- split the tracks near the ends of the platform (left and / or right)
                                        -- destroy all the tracks between the splits
                                        -- add a construction with:
                                            -- rail edges replacing the destroyed tracks
                                            -- many small models with straight person paths and terminals { personNode, personEdge, vehicleEdge }
                                            -- terminals with vehicleNodeOverride
                                        -- destroy the waypoint
                                        -- WHAT IF there is already a waypoint on the same table of platforms?
                                        -- WHAT IF the same track has already been split by another platform, or by the same?
                                        -- WHAT IF the user adds or removes an adjacent piece of platform?
                                            -- catch it and check if the station needs expanding
                                        -- WHAT IF the user removes a piece of platform inbetween?
                                            -- Homer Simpson: remove the station or make it on one end only
                                        -- WHAT IF the user destroys the construction?
                                            -- replace the edges with normal pieces of track
                                        -- WHAT IF more than 1 of my special waypoints is built? Delete the last one!
                                    -- else
                                        -- raise an event
                                        -- the worker thread will:
                                        -- destroy the waypoint
                                    -- endif
                                    game.interface.sendScriptEvent(_eventId, _eventNames.PLATFORM_WAYPOINT_BUILT_ON_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        -- transf = _getTransfFromApiResult(tostring(param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf))
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                    -- LOLLO TODO the worker thread must destroy the waypoint
                                else
                                    -- waypoint built outside platform
                                    game.interface.sendScriptEvent(_eventId, _eventNames.PLATFORM_WAYPOINT_BUILT_OUTSIDE_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        -- transf = _getTransfFromApiResult(tostring(param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf))
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                end
                            elseif param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint1ModelId then
                                print('LOLLO track waypoint 1 built!')
                                local lastBuiltEdge = _utils.getLastBuiltEdge(param.data.entity2tn)
                                if not(lastBuiltEdge) then return end

                                local waypointId = _utils.getWaypointId(lastBuiltEdge.objects, trackWaypoint1ModelId)
                                if not(waypointId) then return end

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if param.proposal.proposal.addedSegments[1].trackEdge.trackType ~= platformTrackType then
                                    game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_1_BUILT_OUTSIDE_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                else
                                    game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_1_BUILT_ON_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                end
                            elseif param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint2ModelId then
                                print('LOLLO track waypoint 2 built!')
                                local lastBuiltEdge = _utils.getLastBuiltEdge(param.data.entity2tn)
                                if not(lastBuiltEdge) then return end

                                local waypointId = _utils.getWaypointId(lastBuiltEdge.objects, trackWaypoint2ModelId)
                                if not(waypointId) then return end

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if param.proposal.proposal.addedSegments[1].trackEdge.trackType ~= platformTrackType then
                                    game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_2_BUILT_OUTSIDE_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                else
                                    game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_2_BUILT_ON_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                end
                            end
                        end
                    end,
                    _myErrorHandler
                )
            end
        end,
        update = function()
        end,
        guiUpdate = function()
        end,
        -- save = function()
        --     return allState
        -- end,
        -- load = function(allState)
        -- end
    }
end