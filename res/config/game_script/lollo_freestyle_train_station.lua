local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelper')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilUG = require('transf')

-- local state = nil -- LOLLO NOTE you can only update the state from the worker thread

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

local constructionDataBak = nil
local _eventId = '__lolloFreestyleTrainStation__'
local _eventNames = {
    BUILD_SNAPPY_TRACKS_4_1_TERMINAL_REQUESTED = 'buildSnappyTracks41TerminalRequested',
    BUILD_STATION_REQUESTED = 'buildStationRequested',
    REBUILD_ALL_TRACKS_REQUESTED = 'rebuildAllTracksRequested',
    REBUILD_1_TERMINAL_TRACKS_REQUESTED = 'rebuild1TerminalTracksRequested',
    REMOVE_TERMINAL_REQUESTED = 'removeTerminalRequested',
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

local _idTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1}
local _metresToAddOrCut = 3
local _newEdgeType = 1 -- 0 = ROAD, 1 = RAIL
-- local _searchRadius = 500

local _utils = {
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

    getStationEndNodesUnsorted = function(con, nTerminal)
        -- print('getStationEndNodesUnsorted starting, nTerminal =', nTerminal)
        print('getStationEndNodesUnsorted, con =') debugPrint(con)
        -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
        if not(con) or con.fileName ~= _constants.stationConFileNameLong then
            return {}
        end

        local endNodeIds = {}
        for _, frozenEdgeId in pairs(con.frozenEdges) do
            if edgeUtils.isValidAndExistingId(frozenEdgeId) then
                local baseEdge = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE)
                if baseEdge ~= nil then
                    local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                    local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                    for _, edgeInTerminal in pairs(con.params.terminals[nTerminal].trackEdgeLists) do
                        if edgeInTerminal ~= nil and ((
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
                            local baseEdgeTrack = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                            if baseEdgeTrack ~= nil and not(trackUtils.isPlatform(baseEdgeTrack.trackType)) then
                                if not(arrayUtils.arrayHasValue(con.frozenNodes, baseEdge.node0)) then
                                    endNodeIds[#endNodeIds+1] = baseEdge.node0
                                end
                                if not(arrayUtils.arrayHasValue(con.frozenNodes, baseEdge.node1)) then
                                    endNodeIds[#endNodeIds+1] = baseEdge.node1
                                end
                            end
                            break
                        end
                    end
                end
            end
        end

        if #endNodeIds ~= 2 then
            print('found', #endNodeIds, 'free nodes in station construction')
            return {}
        end

        return {
            endNodeIds[1],
            endNodeIds[2]
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

    getEdgeIdsPropertiesCropped = function(edgeIdsProperties)
        -- this works, but the tracks still refuse to snap
        print('edgeIdsProperties BEFORE CROPPING =')
        debugPrint(edgeIdsProperties)

        local function _removeShortEnds()
            local cutMetres1 = 0
            local isExit = false
            local i = 0
            while not(isExit) do
                i = i + 1
                local edgeProperties = edgeIdsProperties[i]
                local length = edgeUtils.getVectorLength({
                    edgeProperties.posTanX2[1][1][1] - edgeProperties.posTanX2[2][1][1],
                    edgeProperties.posTanX2[1][1][2] - edgeProperties.posTanX2[2][1][2],
                    edgeProperties.posTanX2[1][1][3] - edgeProperties.posTanX2[2][1][3]
                })
                if length < (_metresToAddOrCut - cutMetres1) then
                    table.remove(edgeIdsProperties, i)
                    cutMetres1 = cutMetres1 + length
                    i = i - 1
                else
                    isExit = true
                end
            end

            local cutMetres2 = 0
            isExit = false
            i = #edgeIdsProperties + 1
            while not(isExit) do
                i = i - 1
                local edgeProperties = edgeIdsProperties[i]
                local length = edgeUtils.getVectorLength({
                    edgeProperties.posTanX2[1][1][1] - edgeProperties.posTanX2[2][1][1],
                    edgeProperties.posTanX2[1][1][2] - edgeProperties.posTanX2[2][1][2],
                    edgeProperties.posTanX2[1][1][3] - edgeProperties.posTanX2[2][1][3]
                })
                if length < (_metresToAddOrCut - cutMetres2) then
                    table.remove(edgeIdsProperties, i)
                    cutMetres2 = cutMetres2 + length
                    i = i + 1
                else
                    isExit = true
                end
            end

            return cutMetres1, cutMetres2
        end

        local cutMetres1, cutMetres2 = _removeShortEnds()
        if cutMetres1 < _metresToAddOrCut then
            -- getPointbetween would be more elegant, this is just a test
            local posTanX2 = edgeIdsProperties[1].posTanX2
            local point1 = posTanX2[1][1]
            local point2 = posTanX2[2][1]
            local tan1 = posTanX2[1][2]
            local length = edgeUtils.getVectorLength({
                point1[1] - point2[1],
                point1[2] - point2[2],
                point1[3] - point2[3]
            })
            local newPoint1 = {
                point1[1] + tan1[1] * (_metresToAddOrCut - cutMetres1) / length,
                point1[2] + tan1[2] * (_metresToAddOrCut - cutMetres1) / length,
                point1[3] + tan1[3] * (_metresToAddOrCut - cutMetres1) / length
            }
            edgeIdsProperties[1].posTanX2[1][1] = newPoint1
        end
        if cutMetres2 < _metresToAddOrCut then
            -- getPointbetween would be more elegant, this is just a test
            local posTanX2 = edgeIdsProperties[#edgeIdsProperties].posTanX2
            local point1 = posTanX2[1][1]
            local point2 = posTanX2[2][1]
            local tan2 = posTanX2[2][2]
            local length = edgeUtils.getVectorLength({
                point1[1] - point2[1],
                point1[2] - point2[2],
                point1[3] - point2[3]
            })
            local newPoint2 = {
                point2[1] - tan2[1] * (_metresToAddOrCut - cutMetres2) / length,
                point2[2] - tan2[2] * (_metresToAddOrCut - cutMetres2) / length,
                point2[3] - tan2[3] * (_metresToAddOrCut - cutMetres2) / length
            }
            edgeIdsProperties[#edgeIdsProperties].posTanX2[2][1] = newPoint2
        end

        print('edgeIdsProperties AFTER CROPPING =')
        debugPrint(edgeIdsProperties)
        return edgeIdsProperties
    end,

    getEdgeIdsPropertiesExtended = function(edgeIdsProperties)
        -- this works, but the tracks still refuse to snap
        print('edgeIdsProperties BEFORE EXTENDING =')
        debugPrint(edgeIdsProperties)

        local addedMetres1, addedMetres2 = 0, 0
        if addedMetres1 < _metresToAddOrCut then
            -- getPointbetween would be more elegant, this is just a test
            local posTanX2 = edgeIdsProperties[1].posTanX2
            local point1 = posTanX2[1][1]
            local point2 = posTanX2[2][1]
            local tan1 = posTanX2[1][2]
            local length = edgeUtils.getVectorLength({
                point1[1] - point2[1],
                point1[2] - point2[2],
                point1[3] - point2[3]
            })
            local newPoint1 = {
                point1[1] - tan1[1] * (_metresToAddOrCut - addedMetres1) / length,
                point1[2] - tan1[2] * (_metresToAddOrCut - addedMetres1) / length,
                point1[3] - tan1[3] * (_metresToAddOrCut - addedMetres1) / length
            }
            edgeIdsProperties[1].posTanX2[1][1] = newPoint1
        end
        if addedMetres2 < _metresToAddOrCut then
            -- getPointbetween would be more elegant, this is just a test
            local posTanX2 = edgeIdsProperties[#edgeIdsProperties].posTanX2
            local point1 = posTanX2[1][1]
            local point2 = posTanX2[2][1]
            local tan2 = posTanX2[2][2]
            local length = edgeUtils.getVectorLength({
                point1[1] - point2[1],
                point1[2] - point2[2],
                point1[3] - point2[3]
            })
            local newPoint2 = {
                point2[1] + tan2[1] * (_metresToAddOrCut - addedMetres2) / length,
                point2[2] + tan2[2] * (_metresToAddOrCut - addedMetres2) / length,
                point2[3] + tan2[3] * (_metresToAddOrCut - addedMetres2) / length
            }
            edgeIdsProperties[#edgeIdsProperties].posTanX2[2][1] = newPoint2
        end

        print('edgeIdsProperties AFTER EXTENDING =')
        debugPrint(edgeIdsProperties)
        return edgeIdsProperties
    end,

    getEdgesModels = function(edgeIds)
        -- LOLLO TODO try and get the models used to display the edges.
        -- I already have a fallback in place, but it'd be interesting anyway.
        local _getEdgeModels = function(edgeId)
            -- this returns a table of strips
            local strips = api.engine.system.baseParallelStripSystem.getStrips(edgeId)
            -- LOT_LIST tells me things about the terrain
            local edgeLotLists = api.engine.getComponent(edgeId, api.type.ComponentType.LOT_LIST)
            local stripsLotLists = api.engine.getComponent(strips[1], api.type.ComponentType.LOT_LIST)
            -- ideally, I would use:
            local models = api.engine.getComponent(edgeId, api.type.ComponentType.MODEL_INSTANCE_LIST)
            -- however, it returns nil, LOLLO TODO ask UG
        end
    end,

    getAllEdgeObjectsWithModelId = function(refModelId)
        local results = {}
        local nearbyEdgeIds = edgeUtils.getNearestObjectIds(_idTransf, 99999, api.type.ComponentType.BASE_EDGE)
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
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return false end

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
        newEdge.comp.typeIndex = oldEdge.typeIndex -- respect type of bridge or tunnel
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)

        if oldEdgeTrack == nil then return false end

        newEdge.trackEdge = oldEdgeTrack
        if trackUtils.isPlatform(oldEdgeTrack.trackType) then
            newEdge.trackEdge.catenary = false
        end

        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
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

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end

        return proposal
    end,
}

_utils.getAllStationEndNodesUnsorted = function(stationConstructionId)
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then return {} end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- print('con =') debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileNameLong then
        return {}
    end

    local results = {}
    for i = 1, #con.params.terminals do
        results[#results+1] = _utils.getStationEndNodesUnsorted(con, i)
    end

    return results
end

_utils.getStationEndNodesTyped = function(neighbourNode1Id, neighbourNode2Id, stationConstructionId, nTerminal)
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then
        print('getStationEndNodesTyped invalid stationConstructionId') debugPrint(stationConstructionId)
        return nil
    end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- print('con =') debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileNameLong then
        print('getStationEndNodesTyped con.fileName =') debugPrint(con.fileName)
        return nil
    end

    local endNodeIds = _utils.getStationEndNodesUnsorted(con, nTerminal)
    print('getStationEndNodesTyped endNodeIds =') debugPrint(endNodeIds)
    if #endNodeIds ~= 2 then return nil end

    local result = {
        neighbourNodeIds = {
            node1Id = neighbourNode1Id,
            node2Id = neighbourNode2Id,
        },
        stationEndNodeIds = {
            node1Id = nil,
            node2Id = nil,
        }
    }

    local neighbourNodeId1 = api.engine.getComponent(neighbourNode1Id, api.type.ComponentType.BASE_NODE)
    local stationEndNodeId1 = api.engine.getComponent(endNodeIds[1], api.type.ComponentType.BASE_NODE)
    local neighbourNodeId2 = api.engine.getComponent(neighbourNode2Id, api.type.ComponentType.BASE_NODE)
    local stationEndNodeId2 = api.engine.getComponent(endNodeIds[2], api.type.ComponentType.BASE_NODE)
    if edgeUtils.isXYZVeryClose(stationEndNodeId1.position, neighbourNodeId1.position) then
        result.stationEndNodeIds.node1Id = endNodeIds[1]
    elseif edgeUtils.isXYZVeryClose(stationEndNodeId2.position, neighbourNodeId1.position) then
        result.stationEndNodeIds.node1Id = endNodeIds[2]
    else
        return nil
    end
    if edgeUtils.isXYZVeryClose(stationEndNodeId1.position, neighbourNodeId2.position) then
        result.stationEndNodeIds.node2Id = endNodeIds[1]
    elseif edgeUtils.isXYZVeryClose(stationEndNodeId2.position, neighbourNodeId2.position) then
        result.stationEndNodeIds.node2Id = endNodeIds[2]
    else
        return nil
    end

    print('getStationEndNodesTyped result =') debugPrint(result)
    return result
end

local _actions = {
    buildSnappyTracks = function(neighbourEdgeIds, nodeIds)
        -- LOLLO NOTE after building the station, never mind how well you placed it,
        -- its end nodes won't snap to the adjacent roads.
        -- AltGr + L will show a red dot, and here is the catch: there are indeed
        -- two separate nodes in the same place, at each station end.
        -- Here, I remove the neighbour track (edge and node) and replace it
        -- with an identical track, which snaps to the station end node instead.
        print('buildSnappyTracks starting')
        print('neighbourEdgeIds =') debugPrint(neighbourEdgeIds)
        -- TODO fix error when building new stations, nodeIds may arrive nil:
        print('nodeIds =') debugPrint(nodeIds)
        if nodeIds == nil then return end

        local proposal = api.type.SimpleProposal.new()

        local nNewEntities = 0
        local _replaceSegment = function(edgeId)
            local newSegment = api.type.SegmentAndEntity.new()
            nNewEntities = nNewEntities - 1
            newSegment.entity = nNewEntities

            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge.node0 == nodeIds.neighbourNodeIds.node1Id then
                newSegment.comp.node0 = nodeIds.stationEndNodeIds.node1Id
            elseif baseEdge.node0 == nodeIds.neighbourNodeIds.node2Id then
                newSegment.comp.node0 = nodeIds.stationEndNodeIds.node2Id
            else
                newSegment.comp.node0 = baseEdge.node0
            end

            if baseEdge.node1 == nodeIds.neighbourNodeIds.node1Id then
                newSegment.comp.node1 = nodeIds.stationEndNodeIds.node1Id
            elseif baseEdge.node1 == nodeIds.neighbourNodeIds.node2Id then
                newSegment.comp.node1 = nodeIds.stationEndNodeIds.node2Id
            else
                newSegment.comp.node1 = baseEdge.node1
            end

            newSegment.comp.tangent0.x = baseEdge.tangent0.x
            newSegment.comp.tangent0.y = baseEdge.tangent0.y
            newSegment.comp.tangent0.z = baseEdge.tangent0.z
            newSegment.comp.tangent1.x = baseEdge.tangent1.x
            newSegment.comp.tangent1.y = baseEdge.tangent1.y
            newSegment.comp.tangent1.z = baseEdge.tangent1.z
            newSegment.comp.type = baseEdge.type
            newSegment.comp.typeIndex = baseEdge.typeIndex
            newSegment.comp.objects = baseEdge.objects
            -- newSegment.playerOwned = {player = api.engine.util.getPlayer()}
            newSegment.type = _newEdgeType
            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
            newSegment.trackEdge.trackType = baseEdgeTrack.trackType
            newSegment.trackEdge.catenary = baseEdgeTrack.catenary

            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
            proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
        end

        for i = 1, #neighbourEdgeIds do
            _replaceSegment(neighbourEdgeIds[i])
        end

        proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = nodeIds.neighbourNodeIds.node1Id
        proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = nodeIds.neighbourNodeIds.node2Id
        -- local newConstruction = api.type.SimpleProposal.ConstructionEntity.new()
        -- newConstruction.fileName = 'station/rail/lollo_freestyle_train_station/snappy_track.con'
        -- newConstruction.params = {
        --     seed = 924e4, -- we need this to avoid dumps
        --     trackEdgeLists = connectedEdges
        -- }
        -- newConstruction.transf = api.type.Mat4f.new(
        --     api.type.Vec4f.new(1, 0, 0, 0),
        --     api.type.Vec4f.new(0, 1, 0, 0),
        --     api.type.Vec4f.new(0, 0, 1, 0),
        --     api.type.Vec4f.new(0, 0, 0, 1)
        -- )
        -- newConstruction.name = 'snappy track construction name'

        -- local proposal = api.type.SimpleProposal.new()
        -- proposal.constructionsToAdd[1] = newConstruction

        -- local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('buildSnappyTracks callback, success =', success)
                -- debugPrint(result)
            end
        )
    end,

    buildStation = function(successEventName, args)
        local conTransf = args.platformWaypointTransf

        print('buildStation starting, args =')
        local oldCon = edgeUtils.isValidAndExistingId(args.join2StationId)
        and api.engine.getComponent(args.join2StationId, api.type.ComponentType.CONSTRUCTION)
        or nil
        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileNameLong

        local params_newModuleKey = slotHelpers.mangleId(args.nTerminal, 0, _constants.idBases.terminalSlotId)
        local params_newModuleValue = {
            metadata = {
                cargo = true,
            },
            name = _constants.terminalModuleFileName,
            updateScript = {
                fileName = '',
                params = { },
            },
            variant = 0,
        }
        local params_neighbourNodeIds = {
            node1Id = args.neighbourNodeIds.node1Id,
            node2Id = args.neighbourNodeIds.node2Id,
        }
        local params_newTerminal = {
            myTransf = arrayUtils.cloneDeepOmittingFields(conTransf),
            platformEdgeLists = args.platformEdgeList,
            trackEdgeLists = args.trackEdgeList
        }
        if oldCon == nil then
            newCon.params = {
                modules = { [params_newModuleKey] = params_newModuleValue },
                neighbourNodeIds = params_neighbourNodeIds,
                -- seed = 123,
                seed = math.abs(math.ceil(conTransf[13] * 1000)),
                terminals = { params_newTerminal },
            }
            newCon.transf = api.type.Mat4f.new(
                api.type.Vec4f.new(conTransf[1], conTransf[2], conTransf[3], conTransf[4]),
                api.type.Vec4f.new(conTransf[5], conTransf[6], conTransf[7], conTransf[8]),
                api.type.Vec4f.new(conTransf[9], conTransf[10], conTransf[11], conTransf[12]),
                api.type.Vec4f.new(conTransf[13], conTransf[14], conTransf[15], conTransf[16])
            )
            newCon.name = 'construction name'
        else
            local newParams = {
                modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
                neighbourNodeIds = params_neighbourNodeIds,
                -- seed = oldCon.params.seed,
                seed = oldCon.params.seed + 1,
                terminals = arrayUtils.cloneDeepOmittingFields(oldCon.params.terminals, nil, true)
            }
            newParams.modules[params_newModuleKey] = params_newModuleValue
            newParams.terminals[#newParams.terminals+1] = params_newTerminal
            newCon.params = newParams
            newCon.transf = oldCon.transf
        end
        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        if edgeUtils.isValidAndExistingId(args.join2StationId) then
            proposal.constructionsToRemove = { args.join2StationId }
            proposal.old2new = {
                [args.join2StationId] = 0,
            }
        end

        -- remove edge object
        -- local platformEdgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(platformWaypointId)
        -- local proposal2 = _utils.getProposal2ReplaceEdgeWithSameRemovingObject(platformEdgeId, platformWaypointId)
        -- if not(proposal2) then return end

        -- proposal.streetProposal = proposal2.streetProposal

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- true gives smoother z, default is false
        context.cleanupStreetGraph = true -- default is false
        context.gatherBuildings = false -- default is false
        context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('build station callback, success =', success)
                -- debugPrint(result)
                if success and successEventName then
                    local eventArgs = arrayUtils.cloneDeepOmittingFields(args)
                    eventArgs.stationConstructionId = result.resultEntities[1]
                    print('eventArgs.stationConstructionId =', eventArgs.stationConstructionId)
                    print('buildStation callback is about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        eventArgs
                    ))
                end
            end
        )
    end,

    rebuildTracks = function(trackEdgeList, platformEdgeList, neighbourNodeIds)
        print('rebuildTracks starting')
        -- print('trackEdgeList =') debugPrint(trackEdgeList)
        -- print('neighbourNodeIds =') debugPrint(neighbourNodeIds)

        if type(neighbourNodeIds) ~= 'table' or #neighbourNodeIds ~= 2 then return end

        local proposal = api.type.SimpleProposal.new()

        local _baseNode1 = api.engine.getComponent(neighbourNodeIds[1], api.type.ComponentType.BASE_NODE)
        local _baseNode2 = api.engine.getComponent(neighbourNodeIds[2], api.type.ComponentType.BASE_NODE)
        local nNewEntities = 0
        local newNodes = {}

        local _addNode = function(position)
            if edgeUtils.isNumVeryClose(position[1], _baseNode1.position.x)
            and edgeUtils.isNumVeryClose(position[2], _baseNode1.position.y)
            and edgeUtils.isNumVeryClose(position[3], _baseNode1.position.z)
            then
                return neighbourNodeIds[1]
            elseif edgeUtils.isNumVeryClose(position[1], _baseNode2.position.x)
            and edgeUtils.isNumVeryClose(position[2], _baseNode2.position.y)
            and edgeUtils.isNumVeryClose(position[3], _baseNode2.position.z)
            then
                return neighbourNodeIds[2]
            else
                for _, newNode in pairs(newNodes) do
                    if edgeUtils.isNumVeryClose(position[1], newNode.position[1])
                    and edgeUtils.isNumVeryClose(position[2], newNode.position[2])
                    and edgeUtils.isNumVeryClose(position[3], newNode.position[3])
                    then
                        return newNode.id
                    end
                end

                local newNode = api.type.NodeAndEntity.new()
                nNewEntities = nNewEntities - 1
                newNode.entity = nNewEntities
                newNode.comp.position.x = position[1]
                newNode.comp.position.y = position[2]
                newNode.comp.position.z = position[3]
                proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode

                newNodes[#newNodes+1] = {
                    id = nNewEntities,
                    position = {
                        position[1],
                        position[2],
                        position[3],
                    }
                }
                return nNewEntities
            end
        end
        local _addSegment = function(trackEdgeList)
            local newSegment = api.type.SegmentAndEntity.new()
            nNewEntities = nNewEntities - 1
            newSegment.entity = nNewEntities
            newSegment.comp.node0 = _addNode(trackEdgeList.posTanX2[1][1])
            newSegment.comp.node1 = _addNode(trackEdgeList.posTanX2[2][1])
            newSegment.comp.tangent0.x = trackEdgeList.posTanX2[1][2][1]
            newSegment.comp.tangent0.y = trackEdgeList.posTanX2[1][2][2]
            newSegment.comp.tangent0.z = trackEdgeList.posTanX2[1][2][3]
            newSegment.comp.tangent1.x = trackEdgeList.posTanX2[2][2][1]
            newSegment.comp.tangent1.y = trackEdgeList.posTanX2[2][2][2]
            newSegment.comp.tangent1.z = trackEdgeList.posTanX2[2][2][3]
            newSegment.comp.type = trackEdgeList.type
            newSegment.comp.typeIndex = trackEdgeList.typeIndex
            -- newSegment.playerOwned = {player = api.engine.util.getPlayer()}
            newSegment.type = _newEdgeType
            -- me may need:
            -- newSegment.trackEdge = api.type.BaseEdgeTrack.new()
            newSegment.trackEdge.trackType = trackEdgeList.trackType
            newSegment.trackEdge.catenary = trackEdgeList.catenary

            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
        end

        for _, trackEdgeList in pairs(trackEdgeList) do
            _addSegment(trackEdgeList)
        end

        print('proposal =') debugPrint(proposal)
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true),
            function(result, success)
                -- print('LOLLO result = ')
                -- debugPrint(result)
                print('LOLLO rebuildTracks success = ', success)
            end
        )
    end,

    bulldozeConstruction = function(constructionId)
        -- print('constructionId =', constructionId)
        if not(edgeUtils.isValidAndExistingId(constructionId)) then return end

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
        context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO _bulldozeConstruction result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                print('LOLLO _bulldozeConstruction success = ')
                debugPrint(success)
            end
        )
    end,

    removeTracks = function(successEventName, successEventArgs)
        print('removeTracks starting')
        -- print('successEventName =') debugPrint(successEventName)
        -- print('successEventArgs =') debugPrint(successEventArgs)
        local allEdgeIds = {}
        arrayUtils.concatValues(allEdgeIds, successEventArgs.trackEdgeIds)
        arrayUtils.concatValues(allEdgeIds, successEventArgs.platformEdgeIds)
        -- print('allEdgeIds =') debugPrint(allEdgeIds)

        local proposal = api.type.SimpleProposal.new()
        for _, edgeId in pairs(allEdgeIds) do
            if edgeUtils.isValidAndExistingId(edgeId) then
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if baseEdge then
                    proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
                    if baseEdge.objects then
                        for j = 1, #baseEdge.objects do
                            proposal.streetProposal.edgeObjectsToRemove[#proposal.streetProposal.edgeObjectsToRemove+1] = baseEdge.objects[j][1]
                        end
                    end
                end
            end
        end
        -- print('proposal.streetProposal.edgeObjectsToRemove =')
        -- debugPrint(proposal.streetProposal.edgeObjectsToRemove)

        local sharedNodeIds = {}
        arrayUtils.concatValues(
            sharedNodeIds,
            edgeUtils.getNodeIdsBetweenEdgeIds(successEventArgs.trackEdgeIds)
        )
        arrayUtils.concatValues(
            sharedNodeIds,
            edgeUtils.getNodeIdsBetweenEdgeIds(successEventArgs.platformEdgeIds, true)
        )
        for i = 1, #sharedNodeIds do
            proposal.streetProposal.nodesToRemove[i] = sharedNodeIds[i]
        end
        -- print('proposal.streetProposal.nodesToRemove =')
        -- debugPrint(proposal.streetProposal.nodesToRemove)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('command callback firing for removeTracks')
                print(success)
                -- debugPrint(result)
                if success and successEventName then
                    print('removeTracks callback is about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        arrayUtils.cloneDeepOmittingFields(successEventArgs or {})
                    ))
                end
            end
        )
    end,

    replaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end
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
        context.cleanupStreetGraph = true -- default is false, it seems to do nothing
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                -- print('LOLLO result = ')
                -- debugPrint(result)
                print('LOLLO replaceEdgeWithSameRemovingObject success = ') debugPrint(success)
            end
        )
    end,

    splitEdgeRemovingObject = function(wholeEdgeId, position0, tangent0, position1, tangent1, nodeBetween, objectIdToRemove, successEventName, successEventArgs)
        if not(edgeUtils.isValidAndExistingId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

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
        context.cleanupStreetGraph = true -- default is false, it seems to do nothing
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
                    -- LOLLO TODO this should come from UG!
                    -- LOLLO TODO try reading the node ids from the added edges instead.
                    -- no good, there may be a new edge using an old node!
                    print('result =') debugPrint(result)
                    print('result.proposal.proposal.addedNodes =') debugPrint(result.proposal.proposal.addedNodes)
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

                    local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                    if not(eventArgs.neighbourNodeIds) then eventArgs.neighbourNodeIds = {} end
                    if successEventName == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                        eventArgs.neighbourNodeIds.node1Id = addedNodeIds[1]
                    elseif successEventName == _eventNames.TRACK_BULLDOZE_REQUESTED then
                        eventArgs.neighbourNodeIds.node2Id = addedNodeIds[1]
                    end
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        eventArgs
                    ))
                end
            end
        )
    end,
}

local function _isBuildingStation(param)
    return _utils.isBuildingConstructionWithFileName(param, _constants.stationConFileNameLong)
end

function data()
    return {
        ini = function()
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
            debugPrint(args)

            if name == _eventNames.WAYPOINT_BULLDOZE_REQUESTED then
                print('bulldoze requested caught, waypointId =') debugPrint(args.waypointId)
                print('edgeId =') debugPrint(args.edgeId)
                -- game.interface.bulldoze(args.waypointId) -- dumps
                _actions.replaceEdgeWithSameRemovingObject(args.edgeId, args.waypointId)
            elseif name == _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED then
                if not(edgeUtils.isValidId(args.platformWaypointId))
                or not(edgeUtils.isValidAndExistingId(args.trackWaypoint1Id))
                or not(edgeUtils.isValidId(args.trackWaypoint2Id))
                or type(args.trackWaypoint1Position) ~= 'table' or #args.trackWaypoint1Position ~= 3
                or type(args.trackWaypoint2Position) ~= 'table' or #args.trackWaypoint2Position ~= 3
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint1Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local trackWaypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint1Id)
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
                    args.trackWaypoint1Id,
                    _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED,
                    arrayUtils.cloneDeepOmittingFields(args)
                )
            elseif name == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                if not(edgeUtils.isValidId(args.platformWaypointId))
                or not(edgeUtils.isValidId(args.neighbourNodeIds.node1Id))
                or not(edgeUtils.isValidAndExistingId(args.trackWaypoint2Id))
                or type(args.trackWaypoint1Position) ~= 'table' or #args.trackWaypoint1Position ~= 3
                or type(args.trackWaypoint2Position) ~= 'table' or #args.trackWaypoint2Position ~= 3
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint2Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end

                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local trackWaypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint2Id)
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
                    args.trackWaypoint2Id,
                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                    arrayUtils.cloneDeepOmittingFields(args)
                )
            elseif name == _eventNames.TRACK_BULLDOZE_REQUESTED then
                if not(edgeUtils.isValidId(args.platformWaypointId))
                or not(edgeUtils.isValidAndExistingId(args.neighbourNodeIds.node1Id))
                or not(edgeUtils.isValidAndExistingId(args.neighbourNodeIds.node2Id))
                or type(args.trackWaypoint1Position) ~= 'table' or #args.trackWaypoint1Position ~= 3
                or type(args.trackWaypoint2Position) ~= 'table' or #args.trackWaypoint2Position ~= 3
                then return end

                local trackEdgeIdsBetweenNodeIds = edgeUtils.track.getTrackEdgeIdsBetweenNodeIds(
                    args.neighbourNodeIds.node1Id,
                    args.neighbourNodeIds.node2Id
                )
                -- print('trackEdgeIdsBetweenNodeIds =')
                -- debugPrint(trackEdgeIdsBetweenNodeIds)

                local trackEdgeList = _utils.getEdgeIdsProperties(trackEdgeIdsBetweenNodeIds)
                -- print('track bulldoze requested, trackEdgeList =') debugPrint(trackEdgeList)

                local platformEdgeList = _utils.getEdgeIdsProperties(args.platformEdgeIds)
                -- print('platformEdgeList =') debugPrint(platformEdgeList)

                -- local platformModels = _utils.getEdgesModels(args.platformEdgeIds)

                local eventArgs = arrayUtils.cloneDeepOmittingFields(args)
                eventArgs.platformEdgeList = platformEdgeList
                eventArgs.trackEdgeIds = trackEdgeIdsBetweenNodeIds
                eventArgs.trackEdgeList = trackEdgeList

                _actions.removeTracks(
                    _eventNames.BUILD_STATION_REQUESTED,
                    eventArgs
                )
                -- LOLLO TODO split the platform in short chunks
            elseif name == _eventNames.BUILD_STATION_REQUESTED then
                local eventArgs = arrayUtils.cloneDeepOmittingFields(args)
                eventArgs.nTerminal = 1
                if edgeUtils.isValidAndExistingId(eventArgs.join2StationId) then
                    local con = api.engine.getComponent(eventArgs.join2StationId, api.type.ComponentType.CONSTRUCTION)
                    if con ~= nil then eventArgs.nTerminal = #con.params.terminals + 1 end
                end
                print('eventArgs.nTerminal =', eventArgs.nTerminal)
                _actions.buildStation(
                    _eventNames.BUILD_SNAPPY_TRACKS_4_1_TERMINAL_REQUESTED,
                    eventArgs
                )
            elseif name == _eventNames.BUILD_SNAPPY_TRACKS_4_1_TERMINAL_REQUESTED then
                _actions.buildSnappyTracks(
                    edgeUtils.getConnectedEdgeIds(
                        {
                            args.neighbourNodeIds.node1Id,
                            args.neighbourNodeIds.node2Id
                        }
                    ),
                    _utils.getStationEndNodesTyped(
                        args.neighbourNodeIds.node1Id,
                        args.neighbourNodeIds.node2Id,
                        args.stationConstructionId,
                        args.nTerminal
                    )
                )
            elseif name == _eventNames.REMOVE_TERMINAL_REQUESTED then
                -- TODO rebuild the station without the given terminal
                -- and then rebuild its tracks
            elseif name == _eventNames.REBUILD_ALL_TRACKS_REQUESTED then
                for i = 1, #args.constructionData.params.terminals do
                    _actions.rebuildTracks(
                        args.constructionData.params.terminals[i].trackEdgeLists,
                        args.constructionData.params.terminals[i].platformEdgeLists,
                        args.constructionData.endNodesUnsorted[i]
                    )
                end
            end
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            -- print('guiHandleEvent caught id =', id, 'name =', name)
            xpcall(
                function()
                    -- about to bulldoze a freestyle station: write away its params so you can rebuild its tracks later
                    if name == 'builder.proposalCreate' and id == 'bulldozer' then
                        if not(args.proposal.toRemove) then return end

                        for _, constructionId in pairs(args.proposal.toRemove) do
                            local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                            if con ~= nil and type(con.fileName) == 'string' and con.fileName == _constants.stationConFileNameLong then
                                constructionDataBak = {
                                    constructionId = constructionId,
                                    endNodesUnsorted = _utils.getAllStationEndNodesUnsorted(constructionId),
                                    -- params = arrayUtils.cloneDeepOmittingFields(con.params, {'seed'}, true)
                                    params = arrayUtils.cloneDeepOmittingFields(con.params, nil, true)
                                }
                                break
                            end
                        end
                    elseif name == 'builder.apply' then
                        -- print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                        if id == 'bulldozer' then
                            -- now it's too late to read the station params:
                            -- if you are bulldozing the station you backed up before,
                            -- read its tracks from the backup and rebuild them.
                            -- Otherwise, do nothing.

                            if constructionDataBak == nil then print('conParamsBak is nil') return end

                            for _, constructionId in pairs(args.proposal.toRemove) do
                                print('about to bulldoze construction', constructionId)
                                if constructionDataBak.constructionId == constructionId then
                                    print('bulldozing a freestyle station, conParamsBak exists and has type', type(constructionDataBak))
                                    -- print('args = ') debugPrint(args)
                                    -- print('constructionDataBak =') debugPrint(constructionDataBak)
                                    local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                                    -- print('constructionParams new =') debugPrint(con)

                                    if con ~= nil and con.params ~= nil and con.params.modules ~= nil
                                    and constructionDataBak ~= nil and constructionDataBak.params ~= nil and constructionDataBak.params.modules ~= nil then
                                        if args.result ~= nil and args.result[1] == constructionId
                                        and #constructionDataBak.params.terminals > 1 then
                                            -- bulldozing a station module AND there are more terminals left
                                            local removedSlotIds = {}
                                            for oldSlotId, _ in pairs(constructionDataBak.params.modules) do
                                                local isFound = false
                                                for newSlotId, _ in pairs(con.params.modules) do
                                                    if newSlotId == oldSlotId then
                                                        isFound = true
                                                        break
                                                    end
                                                end
                                                if not(isFound) then removedSlotIds[#removedSlotIds+1] = oldSlotId end
                                            end
                                            print('removedSlotIds =') debugPrint(removedSlotIds)
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.REMOVE_TERMINAL_REQUESTED,
                                                {
                                                    constructionData = constructionDataBak,
                                                    removedSlotIds = removedSlotIds
                                                }
                                            ))
                                            -- game.interface.sendScriptEvent(_eventId, _eventNames.REMOVE_TERMINAL_REQUESTED, {
                                            --     constructionData = constructionDataBak,
                                            --     removedSlotIds = removedSlotIds
                                            -- })
                                        else
                                            -- bulldozing the whole station
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.REBUILD_ALL_TRACKS_REQUESTED,
                                                {
                                                    constructionData = constructionDataBak,
                                                }
                                            ))
                                            -- game.interface.sendScriptEvent(_eventId, _eventNames.REBUILD_ALL_TRACKS_REQUESTED, {
                                            --     constructionData = constructionDataBak,
                                            -- })
                                        end
                                    end
                                    return
                                else
                                    print('bulldozing something else than', constructionDataBak.constructionId)
                                end
                            end
                        elseif id == 'streetTerminalBuilder' then
                            -- waypoint, traffic light, my own waypoints built
                            if args and args.proposal and args.proposal.proposal
                            and args.proposal.proposal.edgeObjectsToAdd
                            and args.proposal.proposal.edgeObjectsToAdd[1]
                            and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                            then
                                local platformWaypointModelId = api.res.modelRep.find('lollo_freestyle_train_station/railroad/lollo_platform_waypoint.mdl')
                                local trackWaypoint1ModelId = api.res.modelRep.find('lollo_freestyle_train_station/railroad/lollo_track_waypoint_1.mdl')
                                local trackWaypoint2ModelId = api.res.modelRep.find('lollo_freestyle_train_station/railroad/lollo_track_waypoint_2.mdl')

                                local handleTrackWaypointBuilt = function(trackWaypointModelId)
                                    print('LOLLO track waypoint', trackWaypoint1ModelId, 'built!')
                                    local lastBuiltEdgeId = edgeUtils.getLastBuiltEdgeId(args.data.entity2tn, args.proposal.proposal.addedSegments[1])
                                    if not(edgeUtils.isValidAndExistingId(lastBuiltEdgeId)) then return false end

                                    local lastBuiltEdge = api.engine.getComponent(
                                        lastBuiltEdgeId,
                                        api.type.ComponentType.BASE_EDGE
                                    )
                                    if not(lastBuiltEdge) then return false end

                                    local newWaypointId = arrayUtils.getLast(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltEdge.objects, trackWaypointModelId))
                                    if not(newWaypointId) then return false end

                                    if trackUtils.isPlatform(args.proposal.proposal.addedSegments[1].trackEdge.trackType) then
                                        guiHelpers.showWarningWindowWithGoto(_('TrackWaypointBuiltOnPlatform'))
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return false
                                    else
                                        local similarObjectsIds = _utils.getAllEdgeObjectsWithModelId(trackWaypointModelId)
                                        if #similarObjectsIds > 1 then
                                            guiHelpers.showWarningWindowWithGoto(_('WaypointAlreadyBuilt'), newWaypointId, similarObjectsIds)
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                                {
                                                    edgeId = lastBuiltEdgeId,
                                                    waypointId = newWaypointId ~= similarObjectsIds[1] and newWaypointId or similarObjectsIds[2],
                                                }
                                            ))
                                            -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                            --     edgeId = lastBuiltEdgeId,
                                            --     waypointId = newWaypointId ~= similarObjectsIds[1] and newWaypointId or similarObjectsIds[2],
                                            -- })
                                            return false
                                        end
                                    end

                                    return true
                                end
                                print('waypointbuilt, args.result =') debugPrint(args.result)
                                -- if not args.result or not args.result[1] then
                                --     return
                                -- end

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == platformWaypointModelId then
                                    print('LOLLO platform waypoint built!')
                                    -- LOLLO TODO ask UG: can't we have the waypointId in args.result?
                                    local lastBuiltEdgeId = edgeUtils.getLastBuiltEdgeId(args.data.entity2tn, args.proposal.proposal.addedSegments[1])
                                    if not(edgeUtils.isValidAndExistingId(lastBuiltEdgeId)) then return end

                                    local lastBuiltEdge = api.engine.getComponent(
                                        lastBuiltEdgeId,
                                        api.type.ComponentType.BASE_EDGE
                                    )
                                    if not(lastBuiltEdge) then return end

                                    local newWaypointId = arrayUtils.getLast(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltEdge.objects, platformWaypointModelId))
                                    if not(newWaypointId) then return end

                                    local allPlatformWaypointIds = _utils.getAllEdgeObjectsWithModelId(platformWaypointModelId)
                                    local allTrackWaypoint1Ids = _utils.getAllEdgeObjectsWithModelId(trackWaypoint1ModelId)
                                    local allTrackWaypoint2Ids = _utils.getAllEdgeObjectsWithModelId(trackWaypoint2ModelId)

                                    if not(trackUtils.isPlatform(args.proposal.proposal.addedSegments[1].trackEdge.trackType)) then
                                        guiHelpers.showWarningWindowWithGoto(_('PlatformWaypointBuiltOnTrack'))
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return
                                    elseif #allPlatformWaypointIds > 1 then
                                        guiHelpers.showWarningWindowWithGoto(_('WaypointAlreadyBuilt'), newWaypointId, allPlatformWaypointIds)
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return
                                    elseif #allTrackWaypoint1Ids < 1 or #allTrackWaypoint2Ids < 1 then
                                        guiHelpers.showWarningWindowWithGoto(_('TrackWaypointsMissing'))
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return
                                    end
                                    -- waypoint built on platform and two track waypoints built nearby
                                    -- find all consecutive track edges of the same type
                                    -- sort them from first to last
                                    print('nearbyTrackWaypoint1Ids =')
                                    debugPrint(allTrackWaypoint1Ids)
                                    print('nearbyTrackWaypoint2Ids =')
                                    debugPrint(allTrackWaypoint2Ids)

                                    local contiguousTrackEdges = edgeUtils.track.getEdgeIdsBetweenEdgeIds(
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(allTrackWaypoint1Ids[1]),
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(allTrackWaypoint2Ids[1])
                                    )
                                    print('contiguous track edges =')
                                    debugPrint(contiguousTrackEdges)
                                    if #contiguousTrackEdges < 1 then
                                        guiHelpers.showWarningWindowWithGoto(_('TrackWaypointsNotConnected'), allTrackWaypoint1Ids[1], allTrackWaypoint2Ids)
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return
                                    end
                                    -- find all consecutive platform edges of the same type
                                    -- sort them from first to last
                                    local contiguousPlatformEdges = edgeUtils.track.getContiguousEdges(
                                        lastBuiltEdgeId,
                                        trackUtils.getAllPlatformTrackTypes()
                                    )
                                    print('contiguous platform edges =')
                                    debugPrint(contiguousPlatformEdges)
                                    if #contiguousPlatformEdges < 1 then
                                        -- no platform edges
                                        print('ERROR: contiguousPlatformEdges not found, this should never happen')
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BULLDOZE_REQUESTED, {
                                        --     edgeId = lastBuiltEdgeId,
                                        --     waypointId = newWaypointId,
                                        -- })
                                        return
                                    end

                                    local platformWaypointTransf = transfUtilUG.new(
                                        args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                        args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                        args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                        args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                    )

                                    local eventArgs = {
                                        platformEdgeIds = contiguousPlatformEdges,
                                        platformWaypointId = newWaypointId,
                                        platformWaypointTransf = platformWaypointTransf,
                                        trackWaypoint1Id = allTrackWaypoint1Ids[1],
                                        trackWaypoint1Position = edgeUtils.getObjectPosition(allTrackWaypoint1Ids[1]),
                                        trackWaypoint2Id = allTrackWaypoint2Ids[1],
                                        trackWaypoint2Position = edgeUtils.getObjectPosition(allTrackWaypoint2Ids[1]),
                                    }
                                    -- TODO get nearby freestyle stations;
                                    -- if any, send out a new param "join2StationId" to say, join this new station with it
                                    local nearbyFreestyleStations = _utils.getNearbyFreestyleStationsList(platformWaypointTransf, 500)
                                    if #nearbyFreestyleStations > 0 then
                                        guiHelpers.showNearbyStationPicker(
                                            nearbyFreestyleStations,
                                            _eventId,
                                            _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                                            eventArgs
                                        )
                                    else
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                                            eventArgs
                                        ))
                                        -- game.interface.sendScriptEvent(_eventId, _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED, eventArgs)
                                    end
                                elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint1ModelId then
                                    handleTrackWaypointBuilt(trackWaypoint1ModelId)
                                elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == trackWaypoint2ModelId then
                                    handleTrackWaypointBuilt(trackWaypoint2ModelId)
                                end
                            end
                        elseif id == 'trackBuilder' or id == 'streetTrackModifier' then
                            -- I get here in 3 cases:
                            -- 1) a new track is built (id = trackBuilder)
                            -- 2) an existing track is changed to a different type (id = streetTrackModifier)
                            -- 3) an existing track is changed with the upgrade tool (id = streetTrackModifier)

                            -- the user has built or updated a piece of platform-track:
                            -- if there is a track waypoint, remove it, ie rebuild the platform-track without
                            -- otherwise, if the catenary is true, rebuild the platform-track without
                            -- note that this can affect multiple edges at once.
                            if not(args) or not(args.proposal) or not(args.proposal.proposal)
                            or not(args.proposal.proposal.addedSegments) or not(args.proposal.proposal.addedSegments[1])
                            or not(args.data) or not(args.data.entity2tn) then return end

                            local _trackWaypoint1ModelId = api.res.modelRep.find('lollo_freestyle_train_station/railroad/lollo_track_waypoint_1.mdl')
                            local _trackWaypoint2ModelId = api.res.modelRep.find('lollo_freestyle_train_station/railroad/lollo_track_waypoint_2.mdl')

                            local removeTrackWaypointsEventArgs = {}
                            for _, addedSegment in pairs(args.proposal.proposal.addedSegments) do
                                if addedSegment and addedSegment.trackEdge
                                and trackUtils.isPlatform(addedSegment.trackEdge.trackType)
                                and addedSegment.comp.objects then
                                    local edgeObjectsToRemoveIds = edgeUtils.getEdgeObjectsIdsWithModelId(addedSegment.comp.objects, _trackWaypoint1ModelId)
                                    arrayUtils.concatKeysValues(edgeObjectsToRemoveIds, edgeUtils.getEdgeObjectsIdsWithModelId(addedSegment.comp.objects, _trackWaypoint2ModelId))
                                    if #edgeObjectsToRemoveIds > 0 then
                                        for _, waypointId in pairs(edgeObjectsToRemoveIds) do
                                            removeTrackWaypointsEventArgs[#removeTrackWaypointsEventArgs+1] = {
                                                edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(waypointId),
                                                waypointId = waypointId,
                                            }
                                        end
                                    else
                                        removeTrackWaypointsEventArgs[#removeTrackWaypointsEventArgs+1] = {
                                            edgeId = edgeUtils.getLastBuiltEdgeId(args.data.entity2tn, addedSegment),
                                            waypointId = nil,
                                        }
                                    end
                                else
                                    print('addedSegment =') debugPrint(addedSegment)
                                end
                            end
                            for i = 1, #removeTrackWaypointsEventArgs do
                                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                    string.sub(debug.getinfo(1, 'S').source, 1),
                                    _eventId,
                                    _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                    {
                                        edgeId = removeTrackWaypointsEventArgs[i].edgeId,
                                        waypointId = removeTrackWaypointsEventArgs[i].waypointId,
                                    }
                                ))
                                -- game.interface.sendScriptEvent(
                                --     _eventId,
                                --     _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                --     {
                                --         edgeId = removeTrackWaypointsEventArgs[i].edgeId,
                                --         waypointId = removeTrackWaypointsEventArgs[i].waypointId,
                                --     }
                                -- )
                            end
                        end
                    end
                end,
                _myErrorHandler
            )
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