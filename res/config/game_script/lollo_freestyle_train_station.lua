local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeHelper')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilUG = require('transf')

-- local state = nil -- LOLLO NOTE you can only update the state from the worker thread

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

local _eventId = '__lolloFreestyleTrainStation__'
local _eventNames = {
    BUILD_STATION_REQUESTED = 'platformWaypointBuiltOnPlatform',
    TRACK_BULLDOZE_REQUESTED = 'trackBulldozeRequested',
    -- TRACK_WAYPOINT_1_BUILT_ON_TRACK = 'trackWaypoint1BuiltOnTrack',
    TRACK_WAYPOINT_1_SPLIT_FAILED = 'trackWaypoint1SplitFailed',
    TRACK_WAYPOINT_1_SPLIT_REQUESTED = 'trackWaypoint1SplitRequested',
    -- TRACK_WAYPOINT_1_SPLIT_SUCCEEDED = 'trackWaypoint1SplitSucceeded',
    TRACK_WAYPOINT_2_SPLIT_FAILED = 'trackWaypoint2SplitFailed',
    -- TRACK_WAYPOINT_2_BUILT_ON_TRACK = 'trackWaypoint2BuiltOnTrack',
    TRACK_WAYPOINT_2_SPLIT_REQUESTED = 'trackWaypoint2SplitRequested',
    -- TRACK_WAYPOINT_2_SPLIT_SUCCEEDED = 'trackWaypoint2SplitSucceeded',
    WAYPOINT_BULLDOZE_REQUESTED = 'waypointBulldozeRequested',
}

local _newEdgeType = 1 -- 0 = ROAD, 1 = RAIL
local _searchRadius = 500
local _utils = {
    getEdgeIdsProperties = function(edgeIds)
        if type(edgeIds) ~= 'table' then return {} end

        local results = {}
        for i = 1, #edgeIds do
            local baseEdge = api.engine.getComponent(edgeIds[i], api.type.ComponentType.BASE_EDGE)
            local baseEdgeTrack = api.engine.getComponent(edgeIds[i], api.type.ComponentType.BASE_EDGE_TRACK)
            local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
            local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
            local result = {
                catenary = baseEdgeTrack.catenary,
                edgeList = {
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
                type = baseEdge.type,
                typeIndex = baseEdge.typeIndex,
            }
            results[#results+1] = result
        end

        return results
    end,

    getNearbyEdgeObjectIds = function(transf, refModelId)
        local results = {}
        local nearbyEdgeIds = edgeUtils.getNearestObjectIds(transf, _searchRadius, api.type.ComponentType.BASE_EDGE)
        -- print('nearbyEdgeIds =')
        -- debugPrint(nearbyEdgeIds)
        for _, edgeId in pairs(nearbyEdgeIds) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge ~= nil and baseEdge.objects then
                local edgeObjectIds = edgeUtils.getEdgeObjectsWithModelId(baseEdge.objects, refModelId)
                for _, edgeObjectId in pairs(edgeObjectIds) do
                    arrayUtils.addUnique(results, edgeObjectId)
                end
            end
        end

        print('getNearbyEdgeObjectsWithModelId is about to return')
        debugPrint(results)
        return results
    end,

    getOuterNodes = function(contiguousEdgeIds, trackType)
        -- only for testing
        local _hasOnlyOneEdgeOfType1 = function(nodeId, map)
            if not(edgeUtils.isValidId(nodeId)) or not(trackType) then return false end

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

    getProposal2ReplaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        -- replaces a track segment with an identical one, without destroying the buildings
        if not(edgeUtils.isValidId(oldEdgeId)) then return false end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return false end

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = _newEdgeType
        -- newEdge.comp = oldEdge -- no good enough if I want to remove objects, the api moans
        newEdge.comp.node0 = oldEdge.node0
        newEdge.comp.node1 = oldEdge.node1
        newEdge.comp.tangent0 = oldEdge.tangent0
        newEdge.comp.tangent1 = oldEdge.tangent1
        newEdge.comp.type = oldEdge.type -- respect bridge or tunnel
        newEdge.comp.typeIndex = oldEdge.typeIndex -- respect bridge or tunnel
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge.trackEdge = oldEdgeTrack

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
            newEdge.comp.objects = oldEdge.comp.objects
            print('replaceEdgeWithSameRemovingObject: objectIdToRemove is no good')
        end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        if edgeUtils.isValidId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end

        return proposal
    end,
}

local _actions = {
    buildStation = function(platformWaypointId, transf, trackEdgeLists, platformEdges)
        -- a modular station and params.modules look doable, too.
        -- then, you can do:
        -- for slotId, m in pairs(params.modules) do
        --     local moduParams = m.params
        --     local moduTransf = m.transf
        -- end
        -- Even easier: pass the required data in the parameters, it works!

        print('buildStation starting, transf =')
        debugPrint(transf)
        print('trackEdgeLists =')
        debugPrint(trackEdgeLists)
        print('platformEdges =')
        debugPrint(platformEdges)

        local newConstruction = api.type.SimpleProposal.ConstructionEntity.new()
        -- newConstruction.fileName = 'station/rail/lollo_freestyle_train_station/modular_station.con'
        newConstruction.fileName = 'station/rail/lollo_freestyle_train_station/station.con'
        newConstruction.params = {
            myTransf = arrayUtils.cloneDeepOmittingFields(transf),
            platformEdges = platformEdges,
            seed = 123e4, -- we need this to avoid dumps TODO see if we need a dynamic value when building multiple stations
            trackEdgeLists = trackEdgeLists
        }
        newConstruction.transf = api.type.Mat4f.new(
            api.type.Vec4f.new(transf[1], transf[2], transf[3], transf[4]),
            api.type.Vec4f.new(transf[5], transf[6], transf[7], transf[8]),
            api.type.Vec4f.new(transf[9], transf[10], transf[11], transf[12]),
            api.type.Vec4f.new(transf[13], transf[14], transf[15], transf[16])
        )
        newConstruction.name = 'construction name'
        newConstruction.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newConstruction

        -- remove edge object
        local platformEdgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(platformWaypointId)
        local proposal2 = _utils.getProposal2ReplaceEdgeWithSameRemovingObject(platformEdgeId, platformWaypointId)
        if not(proposal2) then return end

        proposal.streetProposal = proposal2.streetProposal

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- true gives smoother z, default is false
        context.cleanupStreetGraph = true -- default is false
        context.gatherBuildings = true -- default is false
        context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('build station callback, success =', success)
                -- debugPrint(result)
            end
        )
    end,

    bulldozeConstruction = function(constructionId)
        -- print('constructionId =', constructionId)
        if not(edgeUtils.isValidId(constructionId)) then return end

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

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, false), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO _bulldozeConstruction result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                print('LOLLO _bulldozeConstruction success = ')
                debugPrint(success)
            end
        )
    end,

    removeTracks = function(edgeIds, successEventName, successEventParams)
        print('removeTracks atarting, edgeIds =')
        debugPrint(edgeIds)
        print('successEventName =')
        debugPrint(successEventName)
        print('successEventParams =')
        debugPrint(successEventParams)

        local proposal = api.type.SimpleProposal.new()
        for i = 1, #edgeIds do
            local baseEdge = api.engine.getComponent(edgeIds[i], api.type.ComponentType.BASE_EDGE)
            if baseEdge then
                proposal.streetProposal.edgesToRemove[i] = edgeIds[i]
                -- LOLLO TODO check this
                if baseEdge.objects then
                    for j = 1, #baseEdge.objects do
                        proposal.streetProposal.edgeObjectsToRemove[#proposal.streetProposal.edgeObjectsToRemove+1] = baseEdge.objects[j][1]
                    end
                end
            end
        end
        local sharedNodeIds = edgeUtils.getNodeIdsBetweenEdgeIds(edgeIds)
        for i = 1, #sharedNodeIds do
            proposal.streetProposal.nodesToRemove[i] = sharedNodeIds[i]
        end
        print('proposal.streetProposal.edgesToRemove =')
        debugPrint(proposal.streetProposal.edgesToRemove)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, false), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO freestyle train station: removeTracks callback returned result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                -- print('LOLLO freestyle train station: removeTracks callback returned success = ')
                print('command callback firing for removeTracks')
                print(success)
                if success and successEventName then
                    print('about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        arrayUtils.cloneOmittingFields(successEventParams or {})
                    ))
                end
            end
        )
    end,

    replaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        -- replaces a track segment with an identical one, without destroying the buildings
        local proposal = _utils.getProposal2ReplaceEdgeWithSameRemovingObject(oldEdgeId, objectIdToRemove)
        if not(proposal) then return end

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

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, false),
            function(result, success)
                -- print('LOLLO result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                -- print('LOLLO success = ')
                debugPrint(success)
            end
        )
    end,

    replaceEdgeWithTrackType = function(oldEdgeId, newTrackTypeId)
        -- replaces the track without destroying the buildings
        if not(edgeUtils.isValidId(oldEdgeId))
        or not(edgeUtils.isValidId(newTrackTypeId)) then return end

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

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, false),
            function(result, success)
                -- print('LOLLO result = ')
                -- debugPrint(result)
                print('LOLLO _replaceEdgeWithStreetType success = ')
                debugPrint(success)
            end
        )
    end,

    splitEdgeRemovingObject = function(wholeEdgeId, position0, tangent0, position1, tangent1, nodeBetween, objectIdToRemove, successEventName, successEventParams)
        if not(edgeUtils.isValidId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

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

        -- local playerOwned = api.type.PlayerOwned.new()
        -- playerOwned.player = api.engine.util.getPlayer()
        local playerOwned = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.PLAYER_OWNED)

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
        newEdge0.trackEdge = oldEdgeTrack

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
                print('edgeObj =')
                debugPrint(edgeObj)
                if edgeObj[1] ~= objectIdToRemove then
                    local edgeObjPosition = edgeUtils.getObjectPosition(edgeObj[1])
                    print('edgeObjPosition =')
                    debugPrint(edgeObjPosition)
                    if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                    local assignment = _utils.getWhichEdgeGetsEdgeObjectAfterSplit(
                        edgeObjPosition,
                        {position0.x, position0.y, position0.z},
                        {position1.x, position1.y, position1.z},
                        nodeBetween
                    )
                    if assignment.assignToSecondEstimate == 0 then
                        table.insert(edge0Objects, { edgeObj[1], edgeObj[2] })
                    elseif assignment.assignToSecondEstimate == 1 then
                        table.insert(edge1Objects, { edgeObj[1], edgeObj[2] })
                    else
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
        if objectIdToRemove then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end
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
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO freestyle train station: split callback returned result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                -- print('LOLLO freestyle train station callback returned success = ')
                print('command callback firing for split')
                print(success)
                if success and successEventName then
                    local addedNodePosition = result.proposal.proposal.addedNodes[1].comp.position
                    print('addedNodePosition =')
                    debugPrint(addedNodePosition)

                    local addedNodeIds = edgeUtils.getNearestObjectIds(
                        transfUtils.position2Transf(addedNodePosition),
                        0,
                        api.type.ComponentType.BASE_NODE
                    )
                    print('addedNodeIds =')
                    debugPrint(addedNodeIds)

                    local eventParams = arrayUtils.cloneOmittingFields(successEventParams or {})
                    if successEventName == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                        eventParams.node1Id = addedNodeIds[1]
                    elseif successEventName == _eventNames.TRACK_BULLDOZE_REQUESTED then
                        eventParams.node2Id = addedNodeIds[1]
                    end
                    print('about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        eventParams
                    ))
                end
            end
        )
    end,
}

local function _isBuildingModularStation(param)
    return _utils.isBuildingConstructionWithFileName(param, 'station/rail/lollo_freestyle_train_station/modular_station.con')
end
local function _isBuildingStation(param)
    return _utils.isBuildingConstructionWithFileName(param, 'station/rail/lollo_freestyle_train_station/station.con')
end

-- LOLLO TODO build both track waypoints, then two ordinary waypoints between them, then the platform waypoint on the platform:
-- not all the tracks get demolished, which is wrong.
function data()
    return {
        ini = function()
        end,
        handleEvent = function(src, id, name, params)
            if (id ~= _eventId) then return end
            -- if type(param) ~= 'table' or type(param.constructionEntityId) ~= 'number' or param.constructionEntityId < 0 then return end

            print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'param =')
            debugPrint(params)
            -- handleEvent firing, src =	lollo_freestyle_train_station.lua	id =	__lolloFreestyleTrainStation__	name =	waypointBuilt	param =

            if name == _eventNames.WAYPOINT_BULLDOZE_REQUESTED
            then
                print('bulldoze requested caught, waypointId =')
                debugPrint(params.waypointId)
                print('edgeId =')
                debugPrint(params.edgeId)
                -- game.interface.bulldoze(param.waypointId) -- dumps
                if params.edgeId and params.waypointId then
                    _actions.replaceEdgeWithSameRemovingObject(params.edgeId, params.waypointId)
                end
            elseif name == _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED then
                -- local sampleParam = {
                --     platformWaypointId,
                --     trackWaypoint1Id,
                --     trackWaypoint1Position,
                --     trackWaypoint2Id,
                --     trackWaypoint2Position
                -- }

                -- LOLLO TODO find out tracks between track flags
                -- LOLLO TODO write away the track params
                -- LOLLO TODO write away the platform params
                -- LOLLO TODO bulldoze those tracks
                -- build station basing on those params
                if not(edgeUtils.isValidId(params.platformWaypointId))
                or not(edgeUtils.isValidId(params.trackWaypoint1Id))
                or not(edgeUtils.isValidId(params.trackWaypoint2Id))
                or type(params.trackWaypoint1Position) ~= 'table' or #params.trackWaypoint1Position ~= 3
                or type(params.trackWaypoint2Position) ~= 'table' or #params.trackWaypoint2Position ~= 3
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(params.trackWaypoint1Id)
                if not(edgeUtils.isValidId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local trackWaypointPosition = edgeUtils.getObjectPosition(params.trackWaypoint1Id)
                local nodeBetween = edgeUtils.getNodeBetween(
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    -- LOLLO NOTE position and transf are always very similar
                    {
                        x = trackWaypointPosition[1],
                        y = trackWaypointPosition[2],
                        z = trackWaypointPosition[3],
                    }
                )

                _actions.splitEdgeRemovingObject(
                    edgeId,
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    nodeBetween,
                    params.trackWaypoint1Id,
                    _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED,
                    params
                )
            elseif name == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                if not(edgeUtils.isValidId(params.platformWaypointId))
                or not(edgeUtils.isValidId(params.node1Id))
                or not(edgeUtils.isValidId(params.trackWaypoint2Id))
                or type(params.trackWaypoint1Position) ~= 'table' or #params.trackWaypoint1Position ~= 3
                or type(params.trackWaypoint2Position) ~= 'table' or #params.trackWaypoint2Position ~= 3
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(params.trackWaypoint2Id)
                print('edgeId =')
                debugPrint(edgeId)

                if not(edgeUtils.isValidId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                print('baseEdge =')
                debugPrint(baseEdge)

                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local trackWaypointPosition = edgeUtils.getObjectPosition(params.trackWaypoint2Id)
                -- print('trackWaypointPosition =')
                -- debugPrint(trackWaypointPosition)
                local nodeBetween = edgeUtils.getNodeBetween(
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    -- LOLLO NOTE position and transf are always very similar
                    {
                        x = trackWaypointPosition[1],
                        y = trackWaypointPosition[2],
                        z = trackWaypointPosition[3],
                    }
                )
                _actions.splitEdgeRemovingObject(
                    edgeId,
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    nodeBetween,
                    params.trackWaypoint2Id,
                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                    params
                )
            elseif name == _eventNames.TRACK_BULLDOZE_REQUESTED then
                if not(edgeUtils.isValidId(params.platformWaypointId))
                or not(edgeUtils.isValidId(params.node1Id))
                or not(edgeUtils.isValidId(params.node2Id))
                or type(params.trackWaypoint1Position) ~= 'table' or #params.trackWaypoint1Position ~= 3
                or type(params.trackWaypoint2Position) ~= 'table' or #params.trackWaypoint2Position ~= 3
                then return end

                local edgeIdsBetweenNodeIds = edgeUtils.track.getTrackEdgeIdsBetweenNodeIds(params.node1Id, params.node2Id)
                print('edgeIdsBetweenNodeIds =')
                debugPrint(edgeIdsBetweenNodeIds)

                local edgeLists = _utils.getEdgeIdsProperties(edgeIdsBetweenNodeIds)
                print('edgeLists =')
                debugPrint(edgeLists)

                local eventParams = arrayUtils.cloneOmittingFields(params)
                eventParams.edgeLists = edgeLists
                _actions.removeTracks(
                    edgeIdsBetweenNodeIds,
                    _eventNames.BUILD_STATION_REQUESTED,
                    eventParams
                )
            elseif name == _eventNames.BUILD_STATION_REQUESTED then
                print('BUILD_STATION_REQUESTED caught, params =')
                debugPrint(params)
                -- LOLLO TODO build the construction
                _actions.buildStation(params.platformWaypointId, params.platformWaypointTransf, params.edgeLists, params.platformEdges)
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
                        if id == 'bulldozer' then
                            -- debugPrint(param)
                        elseif id == 'streetTerminalBuilder' then
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

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == platformWaypointModelId then
                                    print('LOLLO platform waypoint built!')
                                    local lastBuiltEdge = edgeUtils.getLastBuiltEdge(param.data.entity2tn)
                                    if not(lastBuiltEdge) then return end

                                    local newWaypointId = edgeUtils.getEdgeObjectsWithModelId(lastBuiltEdge.objects, platformWaypointModelId)[1]
                                    print('newWaypointId =')
                                    debugPrint(newWaypointId)
                                    if not(newWaypointId) then return end

                                    local platformWaypointTransf = transfUtilUG.new(
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                    )
                                    local nearbyPlatformWaypointIds = _utils.getNearbyEdgeObjectIds(platformWaypointTransf, platformWaypointModelId)
                                    local nearbyTrackWaypoint1Ids = _utils.getNearbyEdgeObjectIds(platformWaypointTransf, trackWaypoint1ModelId)
                                    local nearbyTrackWaypoint2Ids = _utils.getNearbyEdgeObjectIds(platformWaypointTransf, trackWaypoint2ModelId)

                                    if param.proposal.proposal.addedSegments[1].trackEdge.trackType ~= platformTrackType
                                    or #nearbyPlatformWaypointIds > 1
                                    or #nearbyTrackWaypoint1Ids < 1
                                    or #nearbyTrackWaypoint2Ids < 1
                                    then
                                        -- waypoint built outside platform or another waypoint exists nearby,
                                        -- on no track waypoints built yet
                                        game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                            edgeId = lastBuiltEdge.id,
                                            transf = platformWaypointTransf,
                                            waypointId = newWaypointId,
                                        })
                                        return
                                    end
                                    -- waypoint built on platform and two track waypoints built nearby
                                    -- find all consecutive track edges of the same type
                                    -- sort them from first to last
                                    print('nearbyTrackWaypoint1Ids =')
                                    debugPrint(nearbyTrackWaypoint1Ids)
                                    print('nearbyTrackWaypoint2Ids =')
                                    debugPrint(nearbyTrackWaypoint2Ids)

                                    local continuousTrackEdges = edgeUtils.track.getEdgeIdsBetweenEdgeIds(
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(nearbyTrackWaypoint1Ids[1]),
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(nearbyTrackWaypoint2Ids[1])
                                    )
                                    print('contiguous track edges =')
                                    debugPrint(continuousTrackEdges)
                                    print('# contiguous track edges =')
                                    debugPrint(#continuousTrackEdges)
                                    print('type of contiguous track edges =')
                                    debugPrint(type(continuousTrackEdges))
                                    print('contiguous track edges[1] =')
                                    debugPrint(continuousTrackEdges[1])
                                    print('contiguous track edges[last] =')
                                    debugPrint(continuousTrackEdges[#continuousTrackEdges])
                                    if #continuousTrackEdges < 1 then
                                        -- track waypoints built on unconnected tracks
                                        game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                            edgeId = lastBuiltEdge.id,
                                            transf = platformWaypointTransf,
                                            waypointId = newWaypointId,
                                        })
                                        return
                                    end
                                    -- find all consecutive platform edges of the same type
                                    -- sort them from first to last
                                    local contiguousPlatformEdges = edgeUtils.track.getContiguousEdges(
                                        lastBuiltEdge.id,
                                        platformTrackType
                                    )
                                    print('contiguous platform edges =')
                                    debugPrint(contiguousPlatformEdges)
                                    print('# contiguous platform edges =')
                                    debugPrint(#contiguousPlatformEdges)
                                    print('type of contiguous platform edges =')
                                    debugPrint(type(contiguousPlatformEdges))
                                    print('contiguous platform edges[1] =')
                                    debugPrint(contiguousPlatformEdges[1])
                                    print('contiguous platform edges[last] =')
                                    debugPrint(contiguousPlatformEdges[#contiguousPlatformEdges])
                                    if #contiguousPlatformEdges < 1 then
                                        -- no platform edges
                                        game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                            edgeId = lastBuiltEdge.id,
                                            transf = platformWaypointTransf,
                                            waypointId = newWaypointId,
                                        })
                                        return
                                    end

                                    local outerNodes = _utils.getOuterNodes(contiguousPlatformEdges, platformTrackType)
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
                                    game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED, {
                                        -- edgeId = lastBuiltEdge.id,
                                        platformEdges = contiguousPlatformEdges,
                                        platformWaypointId = newWaypointId,
                                        platformWaypointTransf = platformWaypointTransf,
                                        trackWaypoint1Id = nearbyTrackWaypoint1Ids[1],
                                        trackWaypoint1Position = edgeUtils.getObjectPosition(nearbyTrackWaypoint1Ids[1]),
                                        trackWaypoint2Id = nearbyTrackWaypoint2Ids[1],
                                        trackWaypoint2Position = edgeUtils.getObjectPosition(nearbyTrackWaypoint2Ids[1]),
                                    })
                                elseif param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint1ModelId then
                                    print('LOLLO track waypoint 1 built!')
                                    local lastBuiltEdge = edgeUtils.getLastBuiltEdge(param.data.entity2tn)
                                    if not(lastBuiltEdge) then return end

                                    local waypointId = edgeUtils.getEdgeObjectsWithModelId(lastBuiltEdge.objects, trackWaypoint1ModelId)[1]
                                    if not(waypointId) then return end

                                    local transf = transfUtilUG.new(
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                    )

                                    if param.proposal.proposal.addedSegments[1].trackEdge.trackType == platformTrackType
                                    or #_utils.getNearbyEdgeObjectIds(transf, trackWaypoint1ModelId) > 1
                                    -- LOLLO TODO bulldoze if track waypoint 2 is around and not connected
                                    then
                                        -- built on platform
                                        -- or another one exists nearby
                                        game.interface.sendScriptEvent(_eventId, _eventNames.BULLDOZE_REQUESTED, {
                                            edgeId = lastBuiltEdge.id,
                                            transf = transf,
                                            waypointId = waypointId,
                                        })
                                    end
                                elseif param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint2ModelId then
                                    print('LOLLO track waypoint 2 built!')
                                    local lastBuiltEdge = edgeUtils.getLastBuiltEdge(param.data.entity2tn)
                                    if not(lastBuiltEdge) then return end

                                    local waypointId = edgeUtils.getEdgeObjectsWithModelId(lastBuiltEdge.objects, trackWaypoint2ModelId)[1]
                                    if not(waypointId) then return end

                                    local transf = transfUtilUG.new(
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                        param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                    )

                                    if param.proposal.proposal.addedSegments[1].trackEdge.trackType == platformTrackType
                                    or #_utils.getNearbyEdgeObjectIds(transf, trackWaypoint2ModelId) > 1
                                    -- LOLLO TODO bulldoze if track waypoint 1 is around and not connected
                                    then
                                        -- built on platform
                                        -- or another one exists nearby
                                        game.interface.sendScriptEvent(_eventId, _eventNames.BULLDOZE_REQUESTED, {
                                            edgeId = lastBuiltEdge.id,
                                            transf = transf,
                                            waypointId = waypointId,
                                        })
                                    end
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
        --     -- only fires when the worker thread changes the state
        --     if not state then state = {} end
        --     if not state.platformWaypointId then state.platformWaypointId = nil end
        --     if not state.trackWaypoint1Id then state.trackWaypoint1Id = nil end
        --     if not state.trackWaypoint2Id then state.trackWaypoint2Id = nil end
        --     return state
        -- end,
        -- load = function(loadedState)
        --     -- fires once in the worker thread, at game load, and many times in the UI thread
        --     if loadedState then
        --         state = {}
        --         state.platformWaypointId = loadedState.platformWaypointId or nil
        --         state.trackWaypoint1Id = loadedState.trackWaypoint1Id or nil
        --         state.trackWaypoint2Id = loadedState.trackWaypoint2Id or nil
        --     else
        --         state = {
        --             platformWaypointId = nil,
        --             trackWaypoint1Id = nil,
        --             trackWaypoint2Id = nil
        --         }
        --     end
        --     -- commonData.set(state)
        -- end,
    }
end