local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local comparisonUtils = require('lollo_freestyle_train_station.comparisonUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

-- LOLLO NOTE you can only update the state from the worker thread
local m_state = {}
-- LOLLO NOTE block parallel actions on the global variable. Maybe overkill.
local m_conConfigMenu = { -- also this is for the worker thread only
    isBusy = false, -- a sort of semaphore
    isOpen = false, -- another sort of semaphore
    args = nil, -- the data
}

local m_guiConConfigMenu = {
    openForConId = nil
}

local _eventId = _constants.eventData.eventId
local _eventNames = _constants.eventData.eventNames
local _guiPlatformWaypointModelId = nil
local _guiSplitterWaypointModelId = nil
local _guiTrackWaypointModelId = nil
local _guiTexts = {
    awaitFinalisationBeforeSaving = '',
    buildInProgress = '',
    buildSubwayInProgress = '',
    buildMoreWaypoints = '',
    buildSnappyTracksFailed = '',
    closeConConfigBeforeSaving = '',
    differentPlatformWidths = '',
    modName = '',
    needAdjust4Snap = '',
    rebuildNeighboursInProgress = '',
    restoreInProgress = '',
    trackWaypointBuiltOnPlatform = '',
    unsnappedRoads = '',
    waypointAlreadyBuilt = '',
    waypointsCrossCrossing = '',
    waypointsCrossSignal = '',
    waypointsCrossStation = '',
    waypointsTooCloseToStation = '',
    waypointsTooFar = '',
    waypointsTooNear = '',
    waypointsNotConnected = '',
    waypointsWrong = '',
}

local _utils = {
    ---build a post with a message for the user to see where things are not right
    ---@param pos {x: number, y: number, z: number} | boolean | nil
    buildWarningHint = function(pos, message4Sign, message4Warning)
        if not(pos) then
            if message4Warning ~= nil and m_state.warningText ~= message4Warning then m_state.warningText = message4Warning end
            return
        end

        local _removeWarningHints = function()
            local nearbyConIds = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(pos),
                0.001,
                api.type.ComponentType.CONSTRUCTION
            )
            if #nearbyConIds == 0 then return end

            local proposal = api.type.SimpleProposal.new()
            local conIdsToRemove = nearbyConIds
            api.cmd.sendCommand(api.cmd.make.buildProposal(proposal, nil, true))
        end
        _removeWarningHints()

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.unsnappedSomethingMessageConFileName
        newCon.params = {
            message = message4Sign,
            seed = math.abs(math.ceil(pos.x * 1000)),
        }
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = api.type.Mat4f.new(
            api.type.Vec4f.new(1, 0, 0, 0),
            api.type.Vec4f.new(0, 1, 0, 0),
            api.type.Vec4f.new(0, 0, 1, 0),
            api.type.Vec4f.new(pos.x, pos.y, pos.z, 1)
        )
        local warningProposal = api.type.SimpleProposal.new()
        warningProposal.constructionsToAdd[1] = newCon

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(warningProposal, context, true),
            function(result, success)
                if message4Warning ~= nil and m_state.warningText ~= message4Warning then m_state.warningText = message4Warning end
            end
        )
    end,

    getAverageZ = function(edgeId)
        if not(edgeUtils.isValidAndExistingId(edgeId)) then return nil end

        local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
        if baseEdge == nil then return nil end

        local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
        local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
        if baseNode0 == nil
        or baseNode1 == nil
        or baseNode0.position == nil
        or baseNode1.position == nil
        or type(baseNode0.position.z) ~= 'number'
        or type(baseNode1.position.z) ~= 'number'
        then
            return nil
        end

        return (baseNode0.position.z + baseNode1.position.z) / 2
    end,
    ---this alters oldModules in place
    ---@param oldModules table
    ---@return boolean
    ---@return table
    replaceFakeEdgesWithSnappy = function (oldModules)
        local _edgeModuleFileNames = _constants.edgeModuleFileNames
        local isSomethingChanged = false
        local newModules = {}
        for slotId, modu in pairs(oldModules) do
            if modu.name == _edgeModuleFileNames.fake.axialArea then
                modu.name = _edgeModuleFileNames.snappy.axialArea
                isSomethingChanged = true
            elseif modu.name == _edgeModuleFileNames.fake.flatArea then
                modu.name = _edgeModuleFileNames.snappy.flatArea
                isSomethingChanged = true
            elseif modu.name == _edgeModuleFileNames.fake.openStairs then
                modu.name = _edgeModuleFileNames.snappy.openStairs
                isSomethingChanged = true
            end
            newModules[slotId] = modu
        end
        logger.print('_replaceFakeEdgesWithSnappy is about to return isSomethingChanged = ' .. tostring(isSomethingChanged))
        return isSomethingChanged, newModules
    end,
    ---gets adjacent tracks, (station) end nodes and lone nodes without station; expects a list with > 1 entries
    ---@param trackEdgeList edgeIdsProperties
    ---@return {edgeIds: table<integer>, edges: table<integer, {edgeProps: edgeIdProperties, node0Props: nodeIdProperties, node1Props: nodeIdProperties}>}
    -- ---@return {edgeIds: table<integer>, edges: table<integer, {edgeProps: edgeIdProperties, node0Props: nodeIdProperties, node1Props: nodeIdProperties}>, innerSharedNodeIds: table<integer>, outerLoneNodeIds: table<integer>}
    getNeighbours = function(trackEdgeList)
        ---@return table<integer>, integer | nil, boolean
        local _getNeighbours = function(thisEdgeId, nextEdgeId)
            local _baseEdge = api.engine.getComponent(thisEdgeId, api.type.ComponentType.BASE_EDGE)
            if _baseEdge == nil then
                logger.print('_baseEdge == nil, thisEdgeId =', thisEdgeId)
                return {}, nil, false
            end

            local innerNodeId = _baseEdge.node0
            local connectedEdgeIds = edgeUtils.track.getConnectedEdgeIds({innerNodeId})
            logger.print('thisEdgeId =', thisEdgeId, 'nextEdgeId', nextEdgeId, 'connectedEdgeIds =') logger.debugPrint(connectedEdgeIds)
            if arrayUtils.arrayHasValue(connectedEdgeIds, nextEdgeId) then
                innerNodeId = _baseEdge.node1
                connectedEdgeIds = edgeUtils.track.getConnectedEdgeIds({innerNodeId})
                if arrayUtils.arrayHasValue(connectedEdgeIds, nextEdgeId) then
                    logger.err('getAdjacentTracks failed to retrieve adjacent edges, edgeId =', thisEdgeId)
                    return {}, nil, false
                end
            end
            local neighbourEdgeIds = {}
            for _, edgeId in pairs(connectedEdgeIds) do
                if edgeId ~= thisEdgeId then
                    neighbourEdgeIds[edgeId] = true
                end
            end
            return neighbourEdgeIds, innerNodeId, #connectedEdgeIds > 1
        end

        logger.print('_getNeighbours got trackEdgeList =') logger.debugPrint(trackEdgeList)
        local numEdges = #trackEdgeList
        if type(trackEdgeList) ~= 'table' or #trackEdgeList < 2 or trackEdgeList[1].edgeId == trackEdgeList[numEdges].edgeId then
            logger.err('trackEdgeList too short or nil')
            return {
                edgeIds = {},
                edges = {},
    --[[
                innerSharedNodeIds = {},
                outerLoneNodeIds = {},
    ]]
            }
        end

        local neighbourEdge1Ids_indexed, innerNode1Id, is1Shared = _getNeighbours(trackEdgeList[1].edgeId, trackEdgeList[2].edgeId)
        local neighbourEdgeNIds_indexed, innerNodeNId, isNShared = _getNeighbours(trackEdgeList[numEdges].edgeId, trackEdgeList[numEdges-1].edgeId)
        arrayUtils.concatKeysValues(neighbourEdge1Ids_indexed, neighbourEdgeNIds_indexed)
        logger.print('_getNeighbours calculated neighbourEdge1Ids_indexed =') logger.debugPrint(neighbourEdge1Ids_indexed)

        local edgeIds = {}
        local edges = {}
        local outerLoneNodeIds_indexed = {}
        for edgeId, _ in pairs(neighbourEdge1Ids_indexed) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            for _, nodeId in pairs({baseEdge.node0, baseEdge.node1}) do
                if #(edgeUtils.track.getConnectedEdgeIds({nodeId})) < 2 then
                    outerLoneNodeIds_indexed[nodeId] = true
                end
            end
            edges[edgeId] = {
                edgeProps = stationHelpers.getEdgeIdsProperties({edgeId}, true, true, false)[1],
                node0Props = stationHelpers.getNodeIdsProperties({baseEdge.node0})[1],
                node1Props = stationHelpers.getNodeIdsProperties({baseEdge.node1})[1]
            }
            edgeIds[#edgeIds+1] = edgeId
        end
    --[[
        local innerSharedNodeIds = {}
        if innerNode1Id ~= nil and is1Shared then innerSharedNodeIds[#innerSharedNodeIds+1] = innerNode1Id end
        if innerNodeNId ~= nil and innerNodeNId ~= innerNode1Id and isNShared then innerSharedNodeIds[#innerSharedNodeIds+1] = innerNodeNId end
    
        local outerLoneNodeIds = {}
        for id, _ in pairs(outerLoneNodeIds_indexed) do outerLoneNodeIds[#outerLoneNodeIds+1] = id end
    ]]
        return {
            edgeIds = edgeIds,
            edges = edges,
    --[[
            innerSharedNodeIds = innerSharedNodeIds,
            outerLoneNodeIds = outerLoneNodeIds
    ]]
        }
    end,
    getProposal_2_rebuildAllTerminalTracks = function(oldConParams, nTerminalsToRemove)
        logger.print('_getProposal_2_rebuildAllTerminalTracks starting')
        local oldModules = arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true)
        local oldTerminals = oldConParams.terminals

        -- write this away before removing it
        local _getRemovedTerminalsEdgeProps = function()
            local results_indexed = {}
            for _, t in pairs(nTerminalsToRemove) do
                local electricModuleValue = arrayUtils.cloneDeepOmittingFields(oldModules[slotHelpers.mangleId(t, 0, _constants.idBases.trackElectrificationSlotId)], nil, true)
                local isForceTrackElectrification = electricModuleValue ~= nil
                    and (electricModuleValue.name == _constants.trackElectrificationYesModuleFileName
                        or electricModuleValue.name == _constants.trackElectrificationNoModuleFileName)
                local forcedElectrificationValue = isForceTrackElectrification and electricModuleValue.name == _constants.trackElectrificationYesModuleFileName
                results_indexed[t] = {
                    isForceTrackElectrification = isForceTrackElectrification,
                    forcedElectrificationValue = forcedElectrificationValue,
                    platformEdgeLists = arrayUtils.cloneDeepOmittingFields(oldTerminals[t].platformEdgeLists, nil, true),
                    trackEdgeLists = arrayUtils.cloneDeepOmittingFields(oldTerminals[t].trackEdgeLists, nil, true),
                    t = t
                }
            end

            local results = {}
            for t, props in pairs(results_indexed) do
                results[#results+1] = props
            end

            return results
        end
        local removedTerminalsEdgeProps = _getRemovedTerminalsEdgeProps()

        logger.print('nTerminalsToRemove =') logger.debugPrint(nTerminalsToRemove)
        logger.print('removedTerminalsEdgeProps =') logger.debugPrint(removedTerminalsEdgeProps)

        if #nTerminalsToRemove == 0 then return nil end

        local _newNodePositionsXYZ_indexed = {}
        local _getNearbyNodeId = function(position123)--, isIgnoreExistingNodes)
            local _tolerance = 0.001
            for nodeId, nodePositionXYZ in pairs(_newNodePositionsXYZ_indexed) do
                logger.print('nodeId =', tostring(nodeId))
                logger.print('nodeId =') logger.debugPrint(nodePositionXYZ)
                if math.abs(nodePositionXYZ.x - position123[1]) < _tolerance
                and math.abs(nodePositionXYZ.y - position123[2]) < _tolerance
                and math.abs(nodePositionXYZ.z - position123[3]) < _tolerance then
                    -- logger.print('reusing a new node')
                    return nodeId
                end
            end
            -- local _significantFigures4LocateNode = 5 -- you may lower this if tracks are not properly rebuilt.
            -- for nodeId, nodePositionXYZ in pairs(_newNodePositionsXYZ_indexed) do
            --     if comparisonUtils.isNumsVeryClose(position123[1], nodePositionXYZ.x, _significantFigures4LocateNode)
            --     and comparisonUtils.isNumsVeryClose(position123[2], nodePositionXYZ.y, _significantFigures4LocateNode)
            --     and comparisonUtils.isNumsVeryClose(position123[3], nodePositionXYZ.z, _significantFigures4LocateNode)
            --     then
            --         -- logger.print('reusing a new node')
            --         return nodeId
            --     end
            -- end
            -- if isIgnoreExistingNodes then return nil end

            local _nearbyNodeIds = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position123),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position123[3] - _tolerance,
                position123[3] + _tolerance
            )
            return _nearbyNodeIds[1]
        end

        local proposal = api.type.SimpleProposal.new()
        local isAnythingChanged = false
        local nNewEntities = 0
        local _rebuildOneTerminalTracks = function(removedTerminalEdgeProps)
            -- cleanupStreetGraph in previous events (rebuildStationWithOneLessTerminal and bulldozeConstruction) might also play a role, it might.
            logger.print('_getProposal_2_rebuildAllTerminalTracks._rebuildOneTerminalTracks starting')

            local _doTrackOrPlatform = function(edgeLists) --, neighbourNodeIds_plOrTr)
                -- there may be no neighbour nodes, if the station was built in a certain fashion
                local _baseNode1 = nil
                local _baseNode2 = nil

                local _addNode = function(position123)
                    local newNode = api.type.NodeAndEntity.new()
                    nNewEntities = nNewEntities - 1
                    newNode.entity = nNewEntities
                    newNode.comp.position.x = position123[1]
                    newNode.comp.position.y = position123[2]
                    newNode.comp.position.z = position123[3]
                    proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode
                    _newNodePositionsXYZ_indexed[nNewEntities] = {
                        x = position123[1],
                        y = position123[2],
                        z = position123[3],
                    }

                    return nNewEntities
                end
                local _addSegment = function(trackEdgeList)
                    local newSegment = api.type.SegmentAndEntity.new()
                    nNewEntities = nNewEntities - 1
                    newSegment.entity = nNewEntities
                    local _posTanX2 = trackEdgeList.posTanX2
                    newSegment.comp.node0 = _getNearbyNodeId(_posTanX2[1][1]) or _addNode(_posTanX2[1][1])
                    newSegment.comp.node1 = _getNearbyNodeId(_posTanX2[2][1]) or _addNode(_posTanX2[2][1])
                    newSegment.comp.tangent0.x = _posTanX2[1][2][1]
                    newSegment.comp.tangent0.y = _posTanX2[1][2][2]
                    newSegment.comp.tangent0.z = _posTanX2[1][2][3]
                    newSegment.comp.tangent1.x = _posTanX2[2][2][1]
                    newSegment.comp.tangent1.y = _posTanX2[2][2][2]
                    newSegment.comp.tangent1.z = _posTanX2[2][2][3]
                    newSegment.comp.type = trackEdgeList.type
                    newSegment.comp.typeIndex = trackEdgeList.typeIndex
                    -- newSegment.playerOwned = {player = api.engine.util.getPlayer()}
                    newSegment.type = _constants.railEdgeType
                    newSegment.trackEdge.trackType = trackEdgeList.trackType
                    if removedTerminalEdgeProps.isForceTrackElectrification then
                        newSegment.trackEdge.catenary = removedTerminalEdgeProps.forcedElectrificationValue
                    else
                        newSegment.trackEdge.catenary = trackEdgeList.catenary
                    end

                    proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
                end

                local result = false
                for _, edgeList in pairs(edgeLists) do
                    _addSegment(edgeList)
                    result = true
                end
                return result
            end

            -- logger.print('type(removedTerminalEdgeProps.platformEdgeLists) = ' .. tostring(type(removedTerminalEdgeProps.platformEdgeLists)))
            -- logger.print('type(removedTerminalEdgeProps.trackEdgeLists) = ' .. tostring(type(removedTerminalEdgeProps.trackEdgeLists)))
            local isPlatformsChanged = type(removedTerminalEdgeProps.platformEdgeLists) == 'table'
                and _doTrackOrPlatform(removedTerminalEdgeProps.platformEdgeLists)
            local isTracksChanged = type(removedTerminalEdgeProps.platformEdgeLists) == 'table'
                and _doTrackOrPlatform(removedTerminalEdgeProps.trackEdgeLists)
            isAnythingChanged = isAnythingChanged or isPlatformsChanged or isTracksChanged
            logger.print('isAnythingChanged = ' .. tostring(isAnythingChanged))
            -- logger.print('_rebuildOneTerminalTracks proposal =') logger.debugPrint(proposal)
        end

        for _, removedTerminalEdgeProps in pairs(removedTerminalsEdgeProps) do
            _rebuildOneTerminalTracks(removedTerminalEdgeProps)
        end

        logger.print('_getProposal_2_rebuildAllTerminalTracks is about to return proposal =') logger.debugPrint(proposal)
        return proposal
    end,
    getNTerminalsToRemove = function(conParams)
        local result_indexed = {}
        local nTerminals = 0
        local modules = conParams.modules
        for t, _ in pairs(conParams.terminals) do
            nTerminals = nTerminals + 1
            local slotId = slotHelpers.mangleId(t, 0, _constants.idBases.terminalSlotId)
            if not(modules[slotId]) then
                result_indexed[t] = true
            end
        end

        local results = {}
        for t, _ in pairs(result_indexed) do
            results[#results+1] = t
        end
        return results
        -- return result_indexed --, nTerminals - arrayUtils.getCount(nTerminalsToRemove_indexed)  -- cannot pass indexed tables as args
    end,
    sendAllowProgress = function()
        api.cmd.sendCommand(
            api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.ALLOW_PROGRESS
            )
        )
    end,
    sendHideProgress = function()
        m_conConfigMenu.isBusy = false
        api.cmd.sendCommand(
            api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.HIDE_PROGRESS
            )
        )
    end,
    sendHideWarnings = function()
        api.cmd.sendCommand(
            api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.HIDE_WARNINGS
            )
        )
    end,
    tryRenameStationGroup = function(conId)
        -- For some reason, adding a cargo station to a passengers station (or viceversa)
        -- sets the name of the older station to an empty string.
        -- This function goes around it.
        if not edgeUtils.isValidAndExistingId(conId) then return end

        xpcall(
            function()
                local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                if not con or not(con.stations) then return end

                local stationsIdsInCon = con.stations
                local stationGroupIdsInCon = {}

                for _, stationId in pairs(stationsIdsInCon) do
                    if edgeUtils.isValidAndExistingId(stationId) then
                        local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(stationId)
                        if edgeUtils.isValidAndExistingId(stationGroupId) then
                            if not(stationGroupIdsInCon[stationGroupId]) then stationGroupIdsInCon[stationGroupId] = {} end
                            local stationGroupName_struct = api.engine.getComponent(stationGroupId, api.type.ComponentType.NAME)
                            if stationGroupName_struct and not stringUtils.isNullOrEmptyString(stationGroupName_struct.name) then
                                stationGroupIdsInCon[stationGroupId].name = stationGroupName_struct.name
                            end
                        end
                    end
                end

                logger.print('stationGroupIdsInCon =') logger.debugPrint(stationGroupIdsInCon)

                local fallbackName_struct = {}
                for stationGroupId, staGroupInfo in pairs(stationGroupIdsInCon) do
                    if staGroupInfo and not stringUtils.isNullOrEmptyString(staGroupInfo.name) then
                        fallbackName_struct = {stationGroupId = stationGroupId, name = staGroupInfo.name}
                    end
                end

                logger.print('fallbackName_struct =') logger.debugPrint(fallbackName_struct)

                for stationGroupId, staGroupInfo in pairs(stationGroupIdsInCon) do
                    if staGroupInfo and stringUtils.isNullOrEmptyString(staGroupInfo.name) and not stringUtils.isNullOrEmptyString(fallbackName_struct.name) then
                        logger.print('renaming...')
                        api.cmd.sendCommand(
                            api.cmd.make.setName(
                                stationGroupId,
                                fallbackName_struct.name
                            ),
                            function(result, success)
                                logger.print('_tryRename sent out a command that returned success =', not(not(success)))
                            end
                        )
                    end
                end
            end,
            logger.xpErrorHandler
        )
    end,
--[[
    tryReplaceSegment = function(edgeId, endEntities4T_plOrTr, proposal, nNewEntities)
        logger.print('_tryReplaceSegment starting with edgeId =', edgeId or 'NIL')
    
        local _addNodeToRemove = function(nodeId)
            if edgeUtils.isValidAndExistingId(nodeId) and not(arrayUtils.arrayHasValue(proposal.streetProposal.nodesToRemove, nodeId)) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = nodeId
            end
        end
    
        if not(edgeUtils.isValidAndExistingId(edgeId)) then
            logger.warn('invalid edgeId in _tryReplaceSegment')
            return false, nNewEntities
        end
    
        -- logger.print('valid edgeId in _tryReplaceSegment, going ahead')
    
        local newSegment = api.type.SegmentAndEntity.new()
        local nNewEntities_ = nNewEntities - 1
        newSegment.entity = nNewEntities_
    
        local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
        if baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodes.node1Id then
            newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
            _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodes.node1Id)
            -- logger.print('twenty-one')
        elseif baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodes.node2Id then
            newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
            _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodes.node2Id)
            -- logger.print('twenty-two')
        else
            newSegment.comp.node0 = baseEdge.node0
            -- logger.print('twenty-three')
        end
    
        if baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodes.node1Id then
            newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
            _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodes.node1Id)
            -- logger.print('twenty-four')
        elseif baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodes.node2Id then
            newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
            _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodes.node2Id)
            -- logger.print('twenty-five')
        else
            newSegment.comp.node1 = baseEdge.node1
            -- logger.print('twenty-six')
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
        local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        local baseEdgeStreet = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
    
        if baseEdgeTrack ~= nil then
            newSegment.trackEdge.trackType = baseEdgeTrack.trackType
            newSegment.trackEdge.catenary = baseEdgeTrack.catenary
            newSegment.type = _constants.railEdgeType
        elseif baseEdgeStreet ~= nil then
            logger.warn('edgeId', edgeId, 'is street')
            newSegment.streetEdge.streetType = baseEdgeStreet.streetType
            newSegment.streetEdge.hasBus = baseEdgeStreet.hasBus
            newSegment.streetEdge.tramTrackType = baseEdgeStreet.tramTrackType
            -- newSegment.streetEdge.precedenceNode0 = baseEdgeStreet.precedenceNode0
            -- newSegment.streetEdge.precedenceNode1 = baseEdgeStreet.precedenceNode1
            newSegment.type = _constants.streetEdgeType
        end
    
        proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
        if not(arrayUtils.arrayHasValue(proposal.streetProposal.edgesToRemove, edgeId)) then
            proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
        end
    
        return true, nNewEntities_
    end,
]]
    ---Try to upgrade a construction such as stairs or a lift. This might crash and there is no way to catch it UG TODO, so call it last.
    ---@return boolean, table<number> | nil
    tryUpgradeStationOrStairsOrLiftConstruction = function(oldConId)
        logger.print('_tryUpgradeStationOrStairsOrLiftConstruction starting, oldConId =', oldConId)
        if not(edgeUtils.isValidAndExistingId(oldConId)) then return false end

        local oldCon = api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
        logger.print('oldCon.fileName =') logger.debugPrint(oldCon and oldCon.fileName or 'NIL')
        if not(oldCon)
        or not(arrayUtils.arrayHasValue(
            {
                _constants.stationConFileName,
                -- 'station/rail/lollo_freestyle_train_station/openLiftFree.con',
                'station/rail/lollo_freestyle_train_station/openLiftFree_v2.con',
                'station/rail/lollo_freestyle_train_station/openStairsFree.con',
                -- 'station/rail/lollo_freestyle_train_station/openTwinStairsFree.con',
                'station/rail/lollo_freestyle_train_station/openTwinStairsFree_v2.con',
            },
            oldCon.fileName
        ))
        or not(oldCon.params)
        then return false end

        local paramsBak_NoSeed = arrayUtils.cloneDeepOmittingFields(oldCon.params, {'seed'}, true)
        local conTransf_lua = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))
        return xpcall(
            function()
                -- UG TODO there is no such thing in the new api,
                -- nor an upgrade event, both would be useful
                collectgarbage() -- LOLLO TODO this is a stab in the dark to try and avoid crashes in the following
                logger.print('_tryUpgradeStationOrStairsOrLiftConstruction - collect garbage done')
                logger.print('oldConId =') logger.debugPrint(oldConId)
                logger.print('oldCon.fileName =') logger.debugPrint(oldCon.fileName)
                local upgradedConId = game.interface.upgradeConstruction(
                    oldConId,
                    oldCon.fileName,
                    paramsBak_NoSeed
                )
                logger.print('_tryUpgradeStationOrStairsOrLiftConstruction succeeded, upgradedConId =') logger.debugPrint(upgradedConId)
                return conTransf_lua
            end,
            function(error)
                logger.warn('_tryUpgradeStationOrStairsOrLiftConstruction failed')
                m_state.warningText = _('NeedAdjust4Snap')
                logger.warn(error)
                return conTransf_lua
            end
        )
    end,
}
--[[
_utils.getStationParams_WithOneLessTerminal = function(args)
    logger.print('_getStationParams_WithOneLessTerminal starting, args =') logger.debugPrint(args)
    if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then return nil end

    local oldCon = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- logger.print('oldCon =') logger.debugPrint(oldCon)
    if oldCon == nil then return nil end

    local oldConParams = oldCon.params
    local oldModules = arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true)
    local newModules = {}
    for slotId, modu in pairs(oldModules) do
        local nTerminal, nTrackEdge, baseId = slotHelpers.demangleId(slotId)
        if nTerminal < args.nTerminalToRemove then
            newModules[slotId] = modu
        elseif nTerminal == args.nTerminalToRemove then
        else
            local newSlotId = slotHelpers.mangleId(nTerminal - 1, nTrackEdge, baseId)
            newModules[newSlotId] = modu
        end
    end
    -- local isSomethingChangedWithFakes, newModules_2 = _utils.replaceFakeEdgesWithSnappy(newModules)

    local newParams = {
        inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.inverseMainTransf, nil, true),
        mainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.mainTransf, nil, true),
        modules = newModules,
        seed = oldConParams.seed + 1,
        subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
        -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
        terminals = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals, nil, true),
    }
    -- write this away before removing it
    local electricModuleValue = oldModules[slotHelpers.mangleId(args.nTerminalToRemove, 0, _constants.idBases.trackElectrificationSlotId)]
    local isForceTrackElectrification = electricModuleValue ~= nil
    and (electricModuleValue.name == _constants.trackElectrificationYesModuleFileName or electricModuleValue.name == _constants.trackElectrificationNoModuleFileName)
    local forcedElectrificationValue = isForceTrackElectrification and electricModuleValue.name == _constants.trackElectrificationYesModuleFileName
    local removedTerminalEdgeProps = {
        isForceTrackElectrification = isForceTrackElectrification,
        forcedElectrificationValue = forcedElectrificationValue,
        platformEdgeLists = newParams.terminals[args.nTerminalToRemove].platformEdgeLists,
        trackEdgeLists = newParams.terminals[args.nTerminalToRemove].trackEdgeLists,
    }

    table.remove(newParams.terminals, args.nTerminalToRemove)
    -- get rid of subways if bulldozing the last terminal
    if #newParams.terminals < 1 then newParams.subways = {} end

    -- logger.print('newParams =') logger.debugPrint(newParams)

    return newParams, removedTerminalEdgeProps
end
]]
local _actions = {
    -- LOLLO NOTE api.engine.util.proposal.makeProposalData(simpleProposal, context) returns the proposal data,
    -- which has the same format as the result of api.cmd.make.buildProposal
    addSubway = function(successEventName, args)
        logger.print('_addSubway starting, args =') logger.debugPrint(args)
        if not(edgeUtils.isValidAndExistingId(args.join2StationConId)) then 
            logger.warn('_addSubway got invalid join2StationConId') logger.warningDebugPrint(args.join2StationConId)
            _utils.sendHideProgress()
            return
        end
        if not(edgeUtils.isValidAndExistingId(args.subwayConstructionId)) then
            logger.warn('_addSubway got invalid subwayConstructionId') logger.warningDebugPrint(args.subwayConstructionId)
            _utils.sendHideProgress()
            return
        end

        local oldCon = api.engine.getComponent(args.join2StationConId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil then
            logger.err('_addSubway found no station con')
            _utils.sendHideProgress()
            return
        end

        local subwayCon = api.engine.getComponent(args.subwayConstructionId, api.type.ComponentType.CONSTRUCTION)
        if not(subwayCon) or not(subwayCon.transf) then
            logger.err('_addSubway found no subway con')
            _utils.sendHideProgress()
            return
        end

        local subwayTransf = subwayCon.transf

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local oldConParams = oldCon.params
        local isSomethingChangedWithFakes, newModules = _utils.replaceFakeEdgesWithSnappy(arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true))
        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.mainTransf, nil, true),
            modules = newModules,
            seed = oldConParams.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
            -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
            terminals = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals, nil, true),
        }
        local _getNextAvailableSlotId = function()
            local counter = 0
            while counter < 1000 do
                counter = counter + 1

                local testResult = slotHelpers.mangleId(0, counter, _constants.idBases.subwaySlotId)
                if newParams.modules[testResult] == nil then return testResult end
            end

            logger.warn('cannot find an available slot for a subway')
            return false
        end
        local newSubway_Key = _getNextAvailableSlotId()
        if not(newSubway_Key) then _utils.sendHideProgress() return end

        local newSubway_Value = {
            subwayConFileName = subwayCon.fileName,
            transf = transfUtilsUG.new(subwayTransf:cols(0), subwayTransf:cols(1), subwayTransf:cols(2), subwayTransf:cols(3))
        }
        newSubway_Value.transf2Link = transfUtilsUG.mul(
            newSubway_Value.transf,
            { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, _constants.subwayPos2LinkZ, 1 }
        )

        newParams.modules[newSubway_Key] = {
            metadata = { -- it gets overwritten
                -- myTransf = transfUtilsUG.new(subwayTransf:cols(0), subwayTransf:cols(1), subwayTransf:cols(2), subwayTransf:cols(3))
            },
            name = _constants.subwayModuleFileName,
            updateScript = {
                fileName = '', -- 'construction/station/rail/lollo_freestyle_train_station/subwayUpdateFn.updateFn',
                params = { -- it gets overwritten
                    -- myTransf = transfUtilsUG.new(subwayTransf:cols(0), subwayTransf:cols(1), subwayTransf:cols(2), subwayTransf:cols(3))
                },
            },
            variant = 0,
        }
        newParams.subways[newSubway_Key] = newSubway_Value
        newCon.params = newParams

        newCon.transf = oldCon.transf

        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { args.join2StationConId, args.subwayConstructionId }
        -- proposal.old2new = {
        --     [join2StationConId] = 0,
        -- }

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true
        -- context.cleanupStreetGraph = true
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_addSubway callback, success =', success)
                if success then
                    if successEventName ~= nil then
                        args.stationConstructionId = result.resultEntities[1]
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            args
                        ))
                    end
                else
                    logger.print('proposal =') logger.debugPrint(proposal)
                    logger.print('result =') logger.debugPrint(result)
                end
            end
        )
    end,

    bulldozeCon = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return end

        -- local oldCon = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        -- if not(oldCon) then return end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { conId }
        -- proposal.constructionsToRemove[1] = constructionId -- fails to add
        -- proposal.constructionsToRemove:add(constructionId) -- fails to add

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('LOLLO bulldozeMarker success = ', success)
                -- logger.print('LOLLO bulldozeMarker result = ') logger.debugPrint(result)
            end
        )
    end,

    buildStation = function(successEventName, args)
        local conTransf = args.platformWaypointMidTransf

        logger.print('_buildStation starting, args =')

        local oldCon = edgeUtils.isValidAndExistingId(args.join2StationConId)
        and api.engine.getComponent(args.join2StationConId, api.type.ComponentType.CONSTRUCTION)
        or nil

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local _mainTransf = (oldCon == nil)
            and arrayUtils.cloneDeepOmittingFields(conTransf)
            or arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true)
        logger.print('_mainTransf =') logger.debugPrint(_mainTransf)
        local _inverseMainTransf = transfUtils.getInverseTransf(_mainTransf)

        local params_newModuleKeys = {
            slotHelpers.mangleId(args.nTerminal, 0, _constants.idBases.terminalSlotId),
            slotHelpers.mangleId(args.nTerminal, 0, _constants.idBases.trackElectrificationSlotId),
            slotHelpers.mangleId(args.nTerminal, 0, _constants.idBases.trackSpeedSlotId),
        }
        local params_newModuleValues = {
            {
                metadata = { },
                name = args.isCargo and _constants.cargoTerminalModuleFileName or _constants.passengerTerminalModuleFileName,
                updateScript = {
                    fileName = '',
                    params = { },
                },
                variant = 0,
            },
            {
                metadata = { },
                name = _constants.trackElectrificationUndefinedModuleFileName,
                updateScript = {
                    fileName = '',
                    params = { },
                },
                variant = 0,
            },
            {
                metadata = { },
                name = _constants.trackSpeedUndefinedModuleFileName,
                updateScript = {
                    fileName = '',
                    params = { },
                },
                variant = 0,
            },
        }
        local _getRelativePosTanX2s = function(record)
            record.posTanX2 = transfUtils.getPosTanX2Transformed(record.posTanX2, _inverseMainTransf)
            return record
        end
        -- local memorySizeBefore = collectgarbage('count')
        local params_newTerminal = {
            isCargo = args.isCargo,
            platformEdgeLists = args.platformEdgeList,
            trackEdgeLists = args.trackEdgeList,
            centrePlatformsRelative = arrayUtils.map(
                args.centrePlatforms,
                _getRelativePosTanX2s
            ),
            centrePlatformsFineRelative = arrayUtils.map(
                args.centrePlatformsFine,
                _getRelativePosTanX2s
            ),
            centreTracksRelative = arrayUtils.map(
                args.centreTracks,
                _getRelativePosTanX2s
            ),
            centreTracksFineRelative = arrayUtils.map(
                args.centreTracksFine,
                _getRelativePosTanX2s
            ),
            trackEdgeListMidIndex = args.trackEdgeListMidIndex,
            trackEdgeListVehicleNode0Index = args.trackEdgeListVehicleNode0Index,
            trackEdgeListVehicleNode1Index = args.trackEdgeListVehicleNode1Index,
            leftPlatformsRelative = arrayUtils.map(
                args.leftPlatforms,
                _getRelativePosTanX2s
            ),
            rightPlatformsRelative = arrayUtils.map(
                args.rightPlatforms,
                _getRelativePosTanX2s
            ),
            -- leftTracksRelative = arrayUtils.map(
            --     args.leftTracks,
            --     _getRelativePosTanX2s
            -- ),
            -- rightTracksRelative = arrayUtils.map(
            --     args.rightTracks,
            --     _getRelativePosTanX2s
            -- ),
            crossConnectorsRelative = arrayUtils.map(
                args.crossConnectors,
                _getRelativePosTanX2s
            ),
            cargoWaitingAreasRelative = {},
            isTrackOnPlatformLeft = args.isTrackOnPlatformLeft,
            -- slopedAreasFineRelative = {},
        }
        for _, cwas in pairs(args.cargoWaitingAreas) do
            params_newTerminal.cargoWaitingAreasRelative[#params_newTerminal.cargoWaitingAreasRelative+1] = arrayUtils.map(
                cwas,
                _getRelativePosTanX2s
            )
        end
        -- for width, slopedAreasFine4Width in pairs(args.slopedAreasFine) do
        --     params_newTerminal.slopedAreasFineRelative[width] = arrayUtils.map(
        --         slopedAreasFine4Width,
        --         _getRelativePosTanX2s
        --     )
        -- end
        -- logger.print('params_newTerminal =') logger.debugPrint(params_newTerminal)

        if oldCon == nil then
            newCon.params = {
                -- it is not too correct to pass two parameters, one of which can be inferred from the other. However, performance matters more.
                inverseMainTransf = _inverseMainTransf,
                mainTransf = _mainTransf,
                modules = {
                    [params_newModuleKeys[1]] = params_newModuleValues[1],
                    [params_newModuleKeys[2]] = params_newModuleValues[2],
                    [params_newModuleKeys[3]] = params_newModuleValues[3],
                },
                -- seed = 123,
                seed = math.abs(math.ceil(conTransf[13] * 1000)),
                subways = { },
                terminals = { params_newTerminal },
            }
            newCon.transf = api.type.Mat4f.new(
                api.type.Vec4f.new(conTransf[1], conTransf[2], conTransf[3], conTransf[4]),
                api.type.Vec4f.new(conTransf[5], conTransf[6], conTransf[7], conTransf[8]),
                api.type.Vec4f.new(conTransf[9], conTransf[10], conTransf[11], conTransf[12]),
                api.type.Vec4f.new(conTransf[13], conTransf[14], conTransf[15], conTransf[16])
            )
            newCon.name = _('NewStationName') -- LOLLO TODO see if the name can be assigned automatically, as it should
        else
            local oldConParams = oldCon.params
            local isSomethingChangedWithFakes, newModules = _utils.replaceFakeEdgesWithSnappy(arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true))
            local newParams = {
                -- it is not too correct to pass two parameters, one of which can be inferred from the other. However, performance matters more.
                inverseMainTransf = _inverseMainTransf,
                mainTransf = _mainTransf,
                modules = newModules,
                seed = oldConParams.seed + 1,
                subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
                -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
                terminals = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals, nil, true),
            }
            newParams.modules[params_newModuleKeys[1]] = params_newModuleValues[1]
            newParams.modules[params_newModuleKeys[2]] = params_newModuleValues[2]
            newParams.modules[params_newModuleKeys[3]] = params_newModuleValues[3]
            newParams.terminals[#newParams.terminals+1] = params_newTerminal
            newCon.params = newParams
            newCon.transf = oldCon.transf
        end
        newCon.playerEntity = api.engine.util.getPlayer()
        -- local memorySizeAfter = collectgarbage('count')
        -- local roughTableSize = memorySizeAfter - memorySizeBefore
        -- logger.print('rough table size (kB) =', roughTableSize, 'memory size now (kB) =', memorySizeAfter)

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        if edgeUtils.isValidAndExistingId(args.join2StationConId) then
            proposal.constructionsToRemove = { args.join2StationConId }
            -- proposal.old2new = {
            --     [args.join2StationConId] = 0,
            -- }
        end

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true
        -- context.cleanupStreetGraph = true
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_buildStation callback, success =', success)
                -- logger.debugPrint(result)
                if success then
                    local stationConstructionId = result.resultEntities[1]
                    logger.print('_buildStation succeeded, stationConstructionId = ', stationConstructionId)
                    _utils.tryRenameStationGroup(stationConstructionId)
                    if successEventName ~= nil then
                        -- logger.print('station proposal data = ', result.resultProposalData) -- userdata
                        -- logger.print('station entities = ', result.resultEntities) -- userdata
                        logger.print('_buildStation callback is about to send command')
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            {
                                trackEndEntities = args.trackEndEntities,
                                streetEndEntities = args.streetEndEntities,
                                newTerminalNeighbours = args.newTerminalNeighbours,
                                nTerminal = args.nTerminal,
                                stationConstructionId = stationConstructionId
                            }
                        ))
                    end
                else
                    logger.warn('_buildStation failed, result =') logger.warningDebugPrint(result)
                    _utils.sendHideProgress()
                end
            end
        )
    end,

    rebuildNeighboursOLD = function(args)
        -- LOLLO TODO join two lifts with a bridge and halve it: one of the halves won't be rebuilt.
        -- The problem is caused by two different proposals attempting to build nodes in the same location
        -- This function sends out edge proposals one by one, in parallel, so one cannot use the node of the other.
        -- Either I send them out in a sequence (the currentPosition function rebuildNeighbours() does that) or I wait for UG TODO to fix this.
        logger.print('_rebuildNeighbours starting, args =') logger.debugPrint(args)
        local errorPositions = {}

        local _newNodePositionsXYZ_indexed = {}
        local _getNearbyNodeId = function(positionXYZ)
            local _tolerance = 0.001
            for nodeId, nodePositionXYZ in pairs(_newNodePositionsXYZ_indexed) do
                if math.abs(nodePositionXYZ.x - positionXYZ.x) < _tolerance
                and math.abs(nodePositionXYZ.y - positionXYZ.y) < _tolerance
                and math.abs(nodePositionXYZ.z - positionXYZ.z) < _tolerance then
                    return nodeId
                end
            end
            local _nearbyNodeIds = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(positionXYZ),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                positionXYZ.z - _tolerance,
                positionXYZ.z + _tolerance
            )
            return _nearbyNodeIds[1]
        end
        local _setEdgeObjects = function(edgeData, newSegment, proposal)
            if edgeData.edgeProps.edgeObjects == nil then return end

            local segmentCompObjects = {}
            for o, edgeObject in pairs(edgeData.edgeProps.edgeObjects) do
                logger.print('edgeObject =') logger.debugPrint(edgeObject)
                logger.print('#proposal.streetProposal.edgeObjectsToAdd =') logger.debugPrint(#proposal.streetProposal.edgeObjectsToAdd)
                local eo = api.type.SimpleStreetProposal.EdgeObject.new()
                eo.left = edgeObject.isLeft
                eo.model = edgeObject.modelFileName
                -- eo.model = edgeObject.modelId NO!
                eo.name = edgeObject.name
                eo.oneWay = edgeObject.isOneWay
                eo.param = edgeObject.param
                if edgeObject.playerEntity then eo.playerEntity = edgeObject.playerEntity end
                -- LOLLO NOTE the api makes trouble with edge objects unless the edge has entity -1
                -- 0 crash
                -- 1 Assertion `eo.edgeEntity.GetId() < 0 && eo.edgeEntity.GetId() >= -(int)result.proposal.addedSegments.size()' failed.
                -- 2 crash
                -- 3 crash
                -- 4 crash
                -- 5 ecs::Engine::GetComponentDataIndex(const class ecs::Entity &,int) const: Assertion `it != components.end()' failed
                -- 6 crash
                -- 7 crash
                -- 8 ecs::Engine::GetComponentDataIndex(const class ecs::Entity &,int) const: Assertion `it != components.end()' failed.

                -- eo.edgeEntity = newSegment.entity -- 1
                -- eo.edgeEntity = nNewSegments -- 0 2 3 4 5 6 7 8
                eo.edgeEntity = -1 -- fix to avoid trouble

                proposal.streetProposal.edgeObjectsToAdd[#proposal.streetProposal.edgeObjectsToAdd+1] = eo

                segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects -1, edgeObject.flag}
                -- segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects -1, edgeObject.flag} -- 5
                -- segmentCompObjects[#segmentCompObjects+1] = {#segmentCompObjects -1, edgeObject.flag} -- 6
                -- segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects, edgeObject.flag} -- 7
                -- segmentCompObjects[#segmentCompObjects+1] = {#segmentCompObjects, edgeObject.flag} -- 8
                -- segmentCompObjects[#segmentCompObjects+1] = {-#proposal.streetProposal.edgeObjectsToAdd, edgeObject.flag} -- 0 1
                -- segmentCompObjects[#segmentCompObjects+1] = {#proposal.streetProposal.edgeObjectsToAdd, edgeObject.flag} -- 2
                -- segmentCompObjects[#segmentCompObjects+1] = {-#proposal.streetProposal.edgeObjectsToAdd +1, edgeObject.flag} -- 3
                -- segmentCompObjects[#segmentCompObjects+1] = {#proposal.streetProposal.edgeObjectsToAdd +1, edgeObject.flag} -- 4
            end
            logger.print('segmentCompObjects =') logger.debugPrint(segmentCompObjects)
            newSegment.comp.objects = segmentCompObjects
        end
        local _setSegmentProps = function(edgeData, newSegment)
            local props = edgeData.edgeProps
            newSegment.comp.tangent0.x = props.posTanX2[1][2][1]
            newSegment.comp.tangent0.y = props.posTanX2[1][2][2]
            newSegment.comp.tangent0.z = props.posTanX2[1][2][3]
            newSegment.comp.tangent1.x = props.posTanX2[2][2][1]
            newSegment.comp.tangent1.y = props.posTanX2[2][2][2]
            newSegment.comp.tangent1.z = props.posTanX2[2][2][3]
            newSegment.comp.type = props.type
            newSegment.comp.typeIndex = props.typeIndex
            if props.player ~= nil then newSegment.playerOwned = { player = props.player } end
            if props.isTrack then
                newSegment.type = _constants.railEdgeType
                newSegment.trackEdge.trackType = props.trackType
                newSegment.trackEdge.catenary = props.catenary
            else
                newSegment.type = _constants.streetEdgeType
                newSegment.streetEdge.streetType = props.streetType
                newSegment.streetEdge.tramTrackType = props.tramTrackType
                newSegment.streetEdge.hasBus = props.hasBus
            end
        end

        -- edges and nodes
        local allEdges_indexedByEdgeId = {}
        if args.newTerminalNeighbours ~= nil then
            arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, args.newTerminalNeighbours.platforms.edges)
            arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, args.newTerminalNeighbours.tracks.edges)
        end
        if args.trackEndEntities ~= nil then
            for t, terminalEndEntities in pairs(args.trackEndEntities) do
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, terminalEndEntities.platforms.jointNeighbourEdges.props)
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, terminalEndEntities.tracks.jointNeighbourEdges.props)
            end
        end
        if args.streetEndEntities ~= nil then
            for e, endEntity in pairs(args.streetEndEntities) do
                -- you can't do the same edge twice coz the table is indexed by edgeId
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, endEntity.jointNeighbourEdges.props)
            end
        end
        logger.print('allEdges_indexedByEdgeId =') logger.debugPrint(allEdges_indexedByEdgeId)

        local nNewEntities_total = -1
        local proposalWithObjectlessEdges = api.type.SimpleProposal.new()
        local proposalsWithEdgesWithObjects = {}
        local _getInitialLoopProps = function(edgeData)
            local isSegmentWithEdgeObjects = edgeData.edgeProps.edgeObjects ~= nil
            local proposal = nil
            local nNewEntities_local = 0
            if isSegmentWithEdgeObjects then
                proposal = api.type.SimpleProposal.new()
                proposalsWithEdgesWithObjects[#proposalsWithEdgesWithObjects+1] = proposal
                nNewEntities_local = -1
            else
                proposal = proposalWithObjectlessEdges
                nNewEntities_local = nNewEntities_total
            end

            return isSegmentWithEdgeObjects, proposal, nNewEntities_local
        end
        for e, edgeData in pairs(allEdges_indexedByEdgeId) do
            local isSegmentWithEdgeObjects, proposal, nNewEntities_local = _getInitialLoopProps(edgeData)
            -- first add the segment, so its "entity" will always be -1, so the edge objects won't suffer at the hands of the dumb api
            local newSegment = api.type.SegmentAndEntity.new()
            newSegment.entity = nNewEntities_local
            _setSegmentProps(edgeData, newSegment)
            _setEdgeObjects(edgeData, newSegment, proposal)
            nNewEntities_local = nNewEntities_local - 1

            local node0Id, node1Id = nil, nil
            local _addNode = function(positionXYZ)
                local newNode = api.type.NodeAndEntity.new()
                newNode.entity = nNewEntities_local
                newNode.comp.position.x = positionXYZ.x
                newNode.comp.position.y = positionXYZ.y
                newNode.comp.position.z = positionXYZ.z
                proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode
                _newNodePositionsXYZ_indexed[nNewEntities_local] = {
                    x = positionXYZ.x,
                    y = positionXYZ.y,
                    z = positionXYZ.z,
                }

                nNewEntities_local = nNewEntities_local - 1
                return newNode.entity
            end
            node0Id = _getNearbyNodeId(edgeData.node0Props.position) or _addNode(edgeData.node0Props.position)
            node1Id = _getNearbyNodeId(edgeData.node1Props.position) or _addNode(edgeData.node1Props.position)

            -- now the nodes are done, complete the segment
            newSegment.comp.node0 = node0Id
            newSegment.comp.node1 = node1Id
            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment

            if not(isSegmentWithEdgeObjects) then nNewEntities_total = nNewEntities_local end
        end

        -- neighbouring constructions
        if args.streetEndEntities ~= nil then
            local neighbourConIds = {}
            for _, endEntity in pairs(args.streetEndEntities) do
                for conId, conProps in pairs(endEntity.jointNeighbourNode.conProps) do
                    if not(arrayUtils.arrayHasValue(neighbourConIds, conId)) then -- make sure you don't do the same con twice
                        neighbourConIds[#neighbourConIds+1] = conId

                        local newParams = arrayUtils.cloneDeepOmittingFields(conProps.params)
                        newParams.seed = conProps.params.seed + 1
                        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
                        newCon.fileName = conProps.fileName
                        newCon.params = newParams
                        newCon.playerEntity = api.engine.util.getPlayer()
                        -- newCon.transf = oldCon.transf
                        newCon.transf = api.type.Mat4f.new(
                            api.type.Vec4f.new(conProps.transf[1], conProps.transf[2], conProps.transf[3], conProps.transf[4]),
                            api.type.Vec4f.new(conProps.transf[5], conProps.transf[6], conProps.transf[7], conProps.transf[8]),
                            api.type.Vec4f.new(conProps.transf[9], conProps.transf[10], conProps.transf[11], conProps.transf[12]),
                            api.type.Vec4f.new(conProps.transf[13], conProps.transf[14], conProps.transf[15], conProps.transf[16])
                        )

                        proposalWithObjectlessEdges.constructionsToAdd[#proposalWithObjectlessEdges.constructionsToAdd+1] = newCon
                    end
                end
            end
        end

        for _, pos in pairs(errorPositions) do
            if pos ~= nil and type(pos.x) == 'number' and type(pos.y) == 'number' and type(pos.z) == 'number' then
                local newCon = api.type.SimpleProposal.ConstructionEntity.new()
                newCon.fileName = _constants.unsnappedSomethingMessageConFileName
                newCon.params = {
                    seed = math.abs(math.ceil(pos.x * 1000)),
                }
                newCon.playerEntity = api.engine.util.getPlayer()
                newCon.transf = api.type.Mat4f.new(
                    api.type.Vec4f.new(1, 0, 0, 0),
                    api.type.Vec4f.new(0, 1, 0, 0),
                    api.type.Vec4f.new(0, 0, 1, 0),
                    api.type.Vec4f.new(pos.x, pos.y, pos.z, 1)
                )

                proposalWithObjectlessEdges.constructionsToAdd[#proposalWithObjectlessEdges.constructionsToAdd+1] = newCon
            end
        end
        logger.print('_rebuildNeighbours made proposalWithObjectlessEdges =') logger.debugPrint(proposalWithObjectlessEdges)
        logger.print('_rebuildNeighbours made proposalsWithEdgesWithObjects =') logger.debugPrint(proposalsWithEdgesWithObjects)
        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposalWithObjectlessEdges, context, true),
            function(result, success)
                logger.print('_rebuildNeighbours success_0 = ', success)
                -- logger.print('LOLLO result = ') logger.debugPrint(result)
                if success then
                    -- Write away the adjoining constructions
                    local newConIds = {}
                    if result.resultEntities ~= nil then
                        for _, conId in pairs(result.resultEntities) do
                            newConIds[#newConIds+1] = conId
                        end
                        logger.print('newConIds =') logger.debugPrint(newConIds)
                    end
                    -- Add edges with objects, one by one coz the api does not work well with edge objects
                    for _, proposal in pairs(proposalsWithEdgesWithObjects) do
                        api.cmd.sendCommand(
                            api.cmd.make.buildProposal(proposal, context, true),
                            function(result_1, success_1)
                                logger.print('_rebuildNeighbours success_1 = ', success_1)
                                if not(success_1) then logger.warn('cannot rebuild all the edge objects ONE') end
                                if result_1.resultProposalData.errorState.critical then logger.warn('cannot rebuild all the edge objects ONE_TWO') end
                            end
                        )
                    end
                    -- Upgrade the adjoining constructions so that, if they have snappy edges, they will resnap.
                    local _upgradeNeighbourCons = function()
                        local isAnyUpgradeFailed = false
                        for _, newConId in pairs(newConIds) do
                            isAnyUpgradeFailed = isAnyUpgradeFailed or not(_utils.tryUpgradeStationOrStairsOrLiftConstruction(newConId))
                        end
                        logger.print('isAnyUpgradeFailed =', isAnyUpgradeFailed)
                        if not(isAnyUpgradeFailed) then return end

                        m_state.warningText = _('UnsnappedRoads')
                    end
                    _upgradeNeighbourCons()
                end
                _utils.sendHideProgress()
            end
        )
    end,

    rebuildNeighbourEdges = function(args)
        logger.print('_rebuildNeighbourEdges starting, args =') logger.debugPrint(args)

        local _setEdgeObjects = function(edgeData, newSegment, proposal)
            if edgeData.edgeProps.edgeObjects == nil then return end

            local segmentCompObjects = {}
            for o, edgeObject in pairs(edgeData.edgeProps.edgeObjects) do
                logger.print('edgeObject =') logger.debugPrint(edgeObject)
                logger.print('#proposal.streetProposal.edgeObjectsToAdd =') logger.debugPrint(#proposal.streetProposal.edgeObjectsToAdd)
                local eo = api.type.SimpleStreetProposal.EdgeObject.new()
                eo.left = edgeObject.isLeft
                eo.model = edgeObject.modelFileName
                -- eo.model = edgeObject.modelId NO!
                eo.name = edgeObject.name
                eo.oneWay = edgeObject.isOneWay
                eo.param = edgeObject.param
                if edgeObject.playerEntity then eo.playerEntity = edgeObject.playerEntity end
                -- LOLLO NOTE the api makes trouble with edge objects unless the edge has entity -1
                -- 0 crash
                -- 1 Assertion `eo.edgeEntity.GetId() < 0 && eo.edgeEntity.GetId() >= -(int)result.proposal.addedSegments.size()' failed.
                -- 2 crash
                -- 3 crash
                -- 4 crash
                -- 5 ecs::Engine::GetComponentDataIndex(const class ecs::Entity &,int) const: Assertion `it != components.end()' failed
                -- 6 crash
                -- 7 crash
                -- 8 ecs::Engine::GetComponentDataIndex(const class ecs::Entity &,int) const: Assertion `it != components.end()' failed.

                -- eo.edgeEntity = newSegment.entity -- 1
                -- eo.edgeEntity = nNewSegments -- 0 2 3 4 5 6 7 8
                eo.edgeEntity = -1 -- fix to avoid trouble

                proposal.streetProposal.edgeObjectsToAdd[#proposal.streetProposal.edgeObjectsToAdd+1] = eo

                segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects -1, edgeObject.flag}
                -- segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects -1, edgeObject.flag} -- 5
                -- segmentCompObjects[#segmentCompObjects+1] = {#segmentCompObjects -1, edgeObject.flag} -- 6
                -- segmentCompObjects[#segmentCompObjects+1] = {-#segmentCompObjects, edgeObject.flag} -- 7
                -- segmentCompObjects[#segmentCompObjects+1] = {#segmentCompObjects, edgeObject.flag} -- 8
                -- segmentCompObjects[#segmentCompObjects+1] = {-#proposal.streetProposal.edgeObjectsToAdd, edgeObject.flag} -- 0 1
                -- segmentCompObjects[#segmentCompObjects+1] = {#proposal.streetProposal.edgeObjectsToAdd, edgeObject.flag} -- 2
                -- segmentCompObjects[#segmentCompObjects+1] = {-#proposal.streetProposal.edgeObjectsToAdd +1, edgeObject.flag} -- 3
                -- segmentCompObjects[#segmentCompObjects+1] = {#proposal.streetProposal.edgeObjectsToAdd +1, edgeObject.flag} -- 4
            end
            logger.print('segmentCompObjects =') logger.debugPrint(segmentCompObjects)
            newSegment.comp.objects = segmentCompObjects
        end
        local _setSegmentProps = function(edgeData, newSegment)
            local props = edgeData.edgeProps
            newSegment.comp.tangent0.x = props.posTanX2[1][2][1]
            newSegment.comp.tangent0.y = props.posTanX2[1][2][2]
            newSegment.comp.tangent0.z = props.posTanX2[1][2][3]
            newSegment.comp.tangent1.x = props.posTanX2[2][2][1]
            newSegment.comp.tangent1.y = props.posTanX2[2][2][2]
            newSegment.comp.tangent1.z = props.posTanX2[2][2][3]
            newSegment.comp.type = props.type
            newSegment.comp.typeIndex = props.typeIndex
            if props.player ~= nil then newSegment.playerOwned = { player = props.player } end
            if props.isTrack then
                newSegment.type = _constants.railEdgeType
                newSegment.trackEdge.trackType = props.trackType
                newSegment.trackEdge.catenary = props.catenary
            else
                newSegment.type = _constants.streetEdgeType
                newSegment.streetEdge.streetType = props.streetType
                newSegment.streetEdge.tramTrackType = props.tramTrackType
                newSegment.streetEdge.hasBus = props.hasBus
            end
        end

        -- edges and nodes
        local allEdges_indexedByEdgeId = {}
        if args.newTerminalNeighbours ~= nil then
            arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, args.newTerminalNeighbours.platforms.edges)
            arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, args.newTerminalNeighbours.tracks.edges)
        end
        if args.trackEndEntities ~= nil then
            for t, terminalEndEntities in pairs(args.trackEndEntities) do
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, terminalEndEntities.platforms.jointNeighbourEdges.props)
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, terminalEndEntities.tracks.jointNeighbourEdges.props)
            end
        end
        -- if args.removedTerminalsEdgeProps ~= nil then
        --     for t, props in pairs(args.removedTerminalsEdgeProps) do
        --         local platformEdgeLists = props.platformEdgeLists
        --         local trackEdgeLists = props.trackEdgeLists
        --     end
        -- end
        if args.streetEndEntities ~= nil then
            for e, endEntity in pairs(args.streetEndEntities) do
                -- you can't do the same edge twice coz the table is indexed by edgeId
                arrayUtils.concatKeysValues(allEdges_indexedByEdgeId, endEntity.jointNeighbourEdges.props)
            end
        end
        logger.print('allEdges_indexedByEdgeId =') logger.debugPrint(allEdges_indexedByEdgeId)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        local _rebuildConstructions = function()
            -- rebuild the neighbour cons in a separate event, so the neighbours will stay rebuilt if the upgrade fails
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.REBUILD_NEIGHBOUR_CONS,
                -- arrayUtils.cloneDeepOmittingFields(args)
                args
            ))
        end

        local _getEdgeProposal = function(edgeData)
            local proposal = api.type.SimpleProposal.new()
            -- first add the segment, so its "entity" will always be -1, so the edge objects won't suffer at the hands of the dumb api
            local newSegment = api.type.SegmentAndEntity.new()
            newSegment.entity = -1
            _setSegmentProps(edgeData, newSegment)
            _setEdgeObjects(edgeData, newSegment, proposal)

            local _newNodePositionsXYZ_indexed = {}
            local _getNearbyNodeId = function(positionXYZ)
                logger.print('_rebuildNeighbourEdges._getNearbyNodeId starting, positionXYZ =') logger.debugPrint(positionXYZ)
                local _tolerance = 0.001
                for nodeId, nodePositionXYZ in pairs(_newNodePositionsXYZ_indexed) do
                    logger.print('nodePositionXYZ =') logger.debugPrint(nodePositionXYZ)
                    if math.abs(nodePositionXYZ.x - positionXYZ.x) < _tolerance
                    and math.abs(nodePositionXYZ.y - positionXYZ.y) < _tolerance
                    and math.abs(nodePositionXYZ.z - positionXYZ.z) < _tolerance then
                        logger.print('_rebuildNeighbourEdges._getNearbyNodeId found an existing node id')
                        return nodeId
                    end
                end
                local _nearbyNodeIds = edgeUtils.getNearbyObjectIds(
                    transfUtils.position2Transf(positionXYZ),
                    _tolerance,
                    api.type.ComponentType.BASE_NODE,
                    positionXYZ.z - _tolerance,
                    positionXYZ.z + _tolerance
                )
                return _nearbyNodeIds[1]
            end

            local nNewEntities = -2
            local node0Id, node1Id = nil, nil
            local _addNode = function(positionXYZ)
                local newNode = api.type.NodeAndEntity.new()
                newNode.entity = nNewEntities
                newNode.comp.position.x = positionXYZ.x
                newNode.comp.position.y = positionXYZ.y
                newNode.comp.position.z = positionXYZ.z
                proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode
                _newNodePositionsXYZ_indexed[nNewEntities] = {
                    x = positionXYZ.x,
                    y = positionXYZ.y,
                    z = positionXYZ.z,
                }

                nNewEntities = nNewEntities - 1
                return newNode.entity
            end
            node0Id = _getNearbyNodeId(edgeData.node0Props.position) or _addNode(edgeData.node0Props.position)
            node1Id = _getNearbyNodeId(edgeData.node1Props.position) or _addNode(edgeData.node1Props.position)

            -- now the nodes are done, complete the segment
            newSegment.comp.node0 = node0Id
            newSegment.comp.node1 = node1Id
            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment

            return proposal
        end

        local allEdges = {}
        for _, value in pairs(allEdges_indexedByEdgeId) do allEdges[#allEdges+1] = value end
        local allEdgesIndex = 1
        local _rebuildEdge = function(nextFunc)
            local edge = allEdges[allEdgesIndex]
            if not(edge) then
                _rebuildConstructions()
                return
            end

            local edgeId = edge.edgeProps.edgeId
            local proposal = _getEdgeProposal(edge)
            logger.print('_rebuildEdge doing edgeId = ' .. tostring(edgeId or 'NIL'))
            -- logger.print('_rebuildEdge proposal =') logger.debugPrint(proposal)

            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true),
                function(result, success)
                    allEdgesIndex = allEdgesIndex + 1
                    if not(success) then
                        logger.warn('_rebuildEdge: edgeId ' .. tostring(edgeId or 'NIL') .. ' was not rebuilt')
                        logger.warn('_rebuildEdge proposal =') logger.warningDebugPrint(proposal)
                        _utils.buildWarningHint(edge.node0Props.position, _('UnsnappedSomethingHere'), _('UnsnappedSomething'))
                        _utils.sendHideProgress()
                    end
                    logger.print('_rebuildEdge about to call nextFunc()')
                    nextFunc(nextFunc)
                end
            )
        end
        _rebuildEdge(_rebuildEdge)
    end,

    rebuildNeighbourCons = function(args)
        logger.print('_rebuildNeighbourCons started')
        local constructionsProposal = api.type.SimpleProposal.new()
        local isAnyConToBeRebuilt = false
        if args.streetEndEntities ~= nil then
            local neighbourConIds = {}
            for _, endEntity in pairs(args.streetEndEntities) do
                for conId, conProps in pairs(endEntity.jointNeighbourNode.conProps) do
                    if not(arrayUtils.arrayHasValue(neighbourConIds, conId)) then -- make sure you don't do the same con twice
                        neighbourConIds[#neighbourConIds+1] = conId

                        local newParams = arrayUtils.cloneDeepOmittingFields(conProps.params)
                        newParams.seed = conProps.params.seed + 1
                        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
                        newCon.fileName = conProps.fileName
                        newCon.params = newParams
                        newCon.playerEntity = api.engine.util.getPlayer()
                        -- newCon.transf = oldCon.transf
                        newCon.transf = api.type.Mat4f.new(
                            api.type.Vec4f.new(conProps.transf[1], conProps.transf[2], conProps.transf[3], conProps.transf[4]),
                            api.type.Vec4f.new(conProps.transf[5], conProps.transf[6], conProps.transf[7], conProps.transf[8]),
                            api.type.Vec4f.new(conProps.transf[9], conProps.transf[10], conProps.transf[11], conProps.transf[12]),
                            api.type.Vec4f.new(conProps.transf[13], conProps.transf[14], conProps.transf[15], conProps.transf[16])
                        )

                        constructionsProposal.constructionsToAdd[#constructionsProposal.constructionsToAdd+1] = newCon
                        isAnyConToBeRebuilt = true
                    end
                end
            end
        end

        if not(isAnyConToBeRebuilt) then
            _utils.sendHideProgress()
            return
        end

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(constructionsProposal, context, true),
            function(result, success)
                logger.print('_rebuildNeighbourCons success = ', success)
                local stationCon = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
                local stationConPositionXYZ = (stationCon ~= nil and stationCon.fileName == _constants.stationConFileName)
                    and transfUtils.transf2Position(
                        transfUtilsUG.new(stationCon.transf:cols(0), stationCon.transf:cols(1), stationCon.transf:cols(2), stationCon.transf:cols(3)),
                        true
                    )
                if success then
                    -- Write away the adjoining constructions
                    if result.resultEntities == nil then -- this should never happen
                        _utils.sendHideProgress()
                        logger.warn('_rebuildNeighbourCons rebuilt some cons but failed to read their ids, result.resultEntities == nil')
                        _utils.buildWarningHint(stationConPositionXYZ, _('UnsnappedNeighbouringConstruction'), _('UnsnappedNeighbouringConstruction'))
                        return
                    end

                    local newConIds = {}
                    for _, conId in pairs(result.resultEntities) do
                        newConIds[#newConIds+1] = conId
                    end
                    logger.print('newConIds =') logger.debugPrint(newConIds)
                    if #newConIds == 0 then -- this should never happen
                        _utils.sendHideProgress()
                        logger.warn('_rebuildNeighbourCons rebuilt some cons but failed to read their ids, result.resultEntities == empty')
                        _utils.buildWarningHint(stationConPositionXYZ, _('UnsnappedNeighbouringConstruction'), _('UnsnappedNeighbouringConstruction'))
                        return
                    end

                    _utils.sendHideProgress()
                    -- upgrade the neighbour cons in a separate event, so the neighbours will stay rebuilt if the upgrade fails
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        _eventNames.UPGRADE_NEIGHBOUR_CONS,
                        {
                            conIds = newConIds
                        }
                    ))
                else
                    _utils.sendHideProgress()
                    logger.warn('_rebuildNeighbourCons failed to rebuild some constructions, result.resultProposalData =') logger.warningDebugPrint(result.resultProposalData)
                    _utils.buildWarningHint(stationConPositionXYZ, _('UnsnappedNeighbouringConstruction'), _('UnsnappedNeighbouringConstruction'))
                end
            end
        )
    end,
    --- Upgrade the adjoining constructions so that, if they have snappy edges, they will resnap. It calls an old routine that may crash uncatchable, so call it last.
    upgradeNeighbourCons = function(args)
        logger.print('_upgradeNeighbourCons started')
        if not(args) or type(args.conIds) ~= 'table' then return end

        local isAnyUpgradeFailed = false
        for _, newConId in pairs(args.conIds) do
            local isThisUpgradeOK, conTransf = _utils.tryUpgradeStationOrStairsOrLiftConstruction(newConId)
            if not(isThisUpgradeOK) then
                logger.warn('_upgradeNeighbourCons failed upgrading construction') logger.warningDebugPrint(newConId)
                if conTransf ~= nil then
                    _utils.buildWarningHint(transfUtils.transf2Position(conTransf, true))
                end
            end
            isAnyUpgradeFailed = isAnyUpgradeFailed or not(isThisUpgradeOK)
        end
        if not(isAnyUpgradeFailed) then return end

        logger.warn('_upgradeNeighbourCons: some construction upgrades failed')
        m_state.warningText = _('UnsnappedRoads')
    end,
--[[
    rebuildStationWithOneLessTerminal = function(successEventName, args)
        logger.print('_rebuildStationWithOneLessTerminal starting, args =') logger.debugPrint(args)

        local oldCon = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        if oldCon == nil then
            logger.warn('_rebuildStationWithOneLessTerminal got a null con')
            _utils.sendHideProgress()
            return
        end

        local oldConParams = oldCon.params
        -- local oldModules = arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true)
        local oldModules = oldConParams.modules
        local oldTerminals = oldConParams.terminals
        local oldTransf = oldCon.transf
        local conTransf_lua = transfUtilsUG.new(oldTransf:cols(0), oldTransf:cols(1), oldTransf:cols(2), oldTransf:cols(3))

        local newModules = {}
        for slotId, modu in pairs(oldModules) do
            local nTerminal, nTrackEdge, baseId = slotHelpers.demangleId(slotId)
            if nTerminal < args.nTerminalToRemove then
                newModules[slotId] = arrayUtils.cloneDeepOmittingFields(modu, nil, true)
            elseif nTerminal == args.nTerminalToRemove then
            else
                local newSlotId = slotHelpers.mangleId(nTerminal - 1, nTrackEdge, baseId)
                newModules[newSlotId] = arrayUtils.cloneDeepOmittingFields(modu, nil, true)
            end
        end
        logger.print('_rebuildStationWithOneLessTerminal.newModules =') logger.debugPrint(newModules)
        -- this changes the table by ref!
        -- local isSomethingChangedWithFakes, newModules_NoFakes = _utils.replaceFakeEdgesWithSnappy(newModules) -- LOLLO TODO this makes trouble
        -- logger.print('_rebuildStationWithOneLessTerminal.newModules_NoFakes =') logger.debugPrint(newModules_NoFakes)

        -- write this away before removing it
        local electricModuleValue = oldModules[slotHelpers.mangleId(args.nTerminalToRemove, 0, _constants.idBases.trackElectrificationSlotId)]
        local isForceTrackElectrification = electricModuleValue ~= nil
        and (electricModuleValue.name == _constants.trackElectrificationYesModuleFileName or electricModuleValue.name == _constants.trackElectrificationNoModuleFileName)
        local forcedElectrificationValue = isForceTrackElectrification and electricModuleValue.name == _constants.trackElectrificationYesModuleFileName
        local removedTerminalEdgeProps = {
            isForceTrackElectrification = isForceTrackElectrification,
            forcedElectrificationValue = forcedElectrificationValue,
            platformEdgeLists = arrayUtils.cloneDeepOmittingFields(oldTerminals[args.nTerminalToRemove].platformEdgeLists, nil, true),
            trackEdgeLists = arrayUtils.cloneDeepOmittingFields(oldTerminals[args.nTerminalToRemove].trackEdgeLists, nil, true),
        }

        local _getNewTerminals = function()
            local results = {}
            for t = 1, #oldTerminals, 1 do
                if t ~= args.nTerminalToRemove then
                    -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
                    results[#results+1] = arrayUtils.cloneDeepOmittingFields(oldTerminals[t], nil, true)
                    -- results[#results+1] = oldTerminals[t]
                end
            end
            return results
        end
        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.mainTransf, nil, true),
            -- modules = newModules_NoFakes,
            modules = newModules, -- LOLLO TODO this is better but it will crash later at _removeNeighbours, after closing the con config menu.
            -- I need to reset m_conConfigMenu after this.
            seed = oldConParams.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
            -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
            -- terminals = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals, nil, true),
            terminals = _getNewTerminals()
        }
        logger.print('#newParams.terminals = ' .. tostring(#newParams.terminals))

        -- table.remove(newParams.terminals, args.nTerminalToRemove)
        -- get rid of subways if bulldozing the last terminal
        if #newParams.terminals < 1 then newParams.subways = {} end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
logger.print('TWO')
        newCon.params = newParams
logger.print('THREE')
        newCon.transf = oldTransf
logger.print('FOUR')
        newCon.playerEntity = api.engine.util.getPlayer()
logger.print('FIVE')

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { args.stationConstructionId }
        -- proposal.old2new = {
        --     [constructionId] = 0,
        -- }
logger.print('SIX')
        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_rebuildStationWithOneLessTerminal callback, success =', success)
                -- logger.debugPrint(result)
                if success then
                    if successEventName ~= nil then
                        -- args.nTerminalToRemove = nil
                        args.removedTerminalEdgeProps = removedTerminalEdgeProps
                        args.stationConstructionId = result.resultEntities[1]
                        logger.print('_rebuildStationWithOneLessTerminal eventArgs.stationConstructionId =', args.stationConstructionId)
                        logger.print('_rebuildStationWithOneLessTerminal callback is about to send command ' .. successEventName .. ' with args =') logger.debugPrint(args)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            args
                        ))
                    else
                        _utils.sendHideProgress()
                    end
                else
                    logger.warn('_rebuildStationWithOneLessTerminal proposal failed, resultProposalData =') logger.warningDebugPrint(result.resultProposalData )
                    logger.warn('_rebuildStationWithOneLessTerminal proposal =') logger.warningDebugPrint(proposal)
                    _utils.buildWarningHint(transfUtils.transf2Position(conTransf_lua, true), _('ErrorRemovingTerminalHere'), _('ErrorRemovingTerminal'))
                    _utils.sendHideProgress()
                end
            end
        )
    end,
    rebuildStationWithOneLessTerminal_2_steps = function(successEventName, args)
        logger.print('_rebuildStationWithOneLessTerminal starting, args =')

        local oldCon = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        if oldCon == nil then
            logger.warn('_rebuildStationWithOneLessTerminal got a null con')
            _utils.sendHideProgress()
            return
        end

        local conTransf_lua = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName
        newCon.params = args.conParams
        newCon.transf = oldCon.transf
        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { args.stationConstructionId }
        -- proposal.old2new = {
        --     [constructionId] = 0,
        -- }

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_rebuildStationWithOneLessTerminal callback, success =', success)
                -- logger.debugPrint(result)
                if success then
                    if successEventName ~= nil then
                        -- args.nTerminalToRemove = nil
                        args.conParams = nil
                        args.stationConstructionId = result.resultEntities[1]
                        logger.print('_rebuildStationWithOneLessTerminal eventArgs.stationConstructionId =', args.stationConstructionId)
                        logger.print('_rebuildStationWithOneLessTerminal callback is about to send command ' .. successEventName .. ' with args =') logger.debugPrint(args)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            -- arrayUtils.cloneDeepOmittingFields(args)
                            args
                        ))
                    else
                        _utils.sendHideProgress()
                    end
                else
                    logger.warn('_rebuildStationWithOneLessTerminal proposal failed, resultProposalData =') logger.warningDebugPrint(result.resultProposalData )
                    logger.warn('_rebuildStationWithOneLessTerminal proposal =') logger.warningDebugPrint(proposal)
                    _utils.buildWarningHint(transfUtils.transf2Position(conTransf_lua, true), _('ErrorRemovingTerminalHere'), _('ErrorRemovingTerminal'))
                    _utils.sendHideProgress()
                end
            end
        )
    end,

    rebuildOneTerminalTracks = function(successEventName, args)
        local _significantFigures4LocateNode = 5 -- you may lower this if tracks are not properly rebuilt.
        -- cleanupStreetGraph in previous events (rebuildStationWithOneLessTerminal and bulldozeConstruction) might also play a role, it might.
        logger.print('_rebuildOneTerminalTracks starting')
        -- logger.print('trackEdgeLists =') logger.debugPrint(args.removedTerminalEdgeProps.trackEdgeLists)
        -- logger.print('platformEdgeLists =') logger.debugPrint(args.removedTerminalEdgeProps.platformEdgeLists)
        logger.print('args.neighbourNodeIdsOfBulldozedTerminal =') logger.debugPrint(args.neighbourNodeIdsOfBulldozedTerminal)
        logger.print('args.stationConstructionId =') logger.debugPrint(args.stationConstructionId)
        logger.print('successEventName =') logger.debugPrint(successEventName)

        local proposal = api.type.SimpleProposal.new()

        local nNewEntities = 0
        local newNodes = {}

        local doTrackOrPlatform = function(edgeLists, neighbourNodeIds_plOrTr)
            -- there may be no neighbour nodes, if the station was built in a certain fashion
            local _baseNode1 = (neighbourNodeIds_plOrTr ~= nil and edgeUtils.isValidAndExistingId(neighbourNodeIds_plOrTr.node1))
            and api.engine.getComponent(neighbourNodeIds_plOrTr.node1, api.type.ComponentType.BASE_NODE)
            or nil
            -- logger.print('_baseNode1 =') logger.debugPrint(_baseNode1)
            local _baseNode2 = (neighbourNodeIds_plOrTr ~= nil and edgeUtils.isValidAndExistingId(neighbourNodeIds_plOrTr.node2))
            and api.engine.getComponent(neighbourNodeIds_plOrTr.node2, api.type.ComponentType.BASE_NODE)
            or nil
            -- logger.print('_baseNode2 =') logger.debugPrint(_baseNode2)

            local _addNode = function(position)
                -- logger.print('adding node, position =') logger.debugPrint(position)
                if _baseNode1 ~= nil
                and comparisonUtils.isNumsVeryClose(position[1], _baseNode1.position.x, _significantFigures4LocateNode)
                and comparisonUtils.isNumsVeryClose(position[2], _baseNode1.position.y, _significantFigures4LocateNode)
                and comparisonUtils.isNumsVeryClose(position[3], _baseNode1.position.z, _significantFigures4LocateNode)
                then
                    -- logger.print('_baseNode1 matches')
                    return neighbourNodeIds_plOrTr.node1
                elseif _baseNode2 ~= nil
                and comparisonUtils.isNumsVeryClose(position[1], _baseNode2.position.x, _significantFigures4LocateNode)
                and comparisonUtils.isNumsVeryClose(position[2], _baseNode2.position.y, _significantFigures4LocateNode)
                and comparisonUtils.isNumsVeryClose(position[3], _baseNode2.position.z, _significantFigures4LocateNode)
                then
                    -- logger.print('_baseNode2 matches')
                    return neighbourNodeIds_plOrTr.node2
                else
                    for _, newNode in pairs(newNodes) do
                        if comparisonUtils.isNumsVeryClose(position[1], newNode.position[1], _significantFigures4LocateNode)
                        and comparisonUtils.isNumsVeryClose(position[2], newNode.position[2], _significantFigures4LocateNode)
                        and comparisonUtils.isNumsVeryClose(position[3], newNode.position[3], _significantFigures4LocateNode)
                        then
                            -- logger.print('reusing a new node')
                            return newNode.id
                        end
                    end

                    -- logger.print('making a new node')
                    local newNode = api.type.NodeAndEntity.new()
                    nNewEntities = nNewEntities - 1
                    newNode.entity = nNewEntities
                    newNode.comp.position.x = position[1]
                    newNode.comp.position.y = position[2]
                    newNode.comp.position.z = position[3]
                    proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode

                    newNodes[#newNodes+1] = {
                        id = nNewEntities,
                        position = { position[1], position[2], position[3], }
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
                newSegment.type = _constants.railEdgeType
                newSegment.trackEdge.trackType = trackEdgeList.trackType
                if args.removedTerminalEdgeProps.isForceTrackElectrification then
                    newSegment.trackEdge.catenary = args.removedTerminalEdgeProps.forcedElectrificationValue
                else
                    newSegment.trackEdge.catenary = trackEdgeList.catenary
                end

                proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
            end

            local result = false
            for _, edgeList in pairs(edgeLists) do
                _addSegment(edgeList)
                result = true
            end
            return result
        end

        local isPlatformsChanged = type(args.removedTerminalEdgeProps.platformEdgeLists) == 'table'
            and doTrackOrPlatform(args.removedTerminalEdgeProps.platformEdgeLists, args.neighbourNodeIdsOfBulldozedTerminal.platforms)
        local isTracksChanged = type(args.removedTerminalEdgeProps.platformEdgeLists) == 'table'
            and doTrackOrPlatform(args.removedTerminalEdgeProps.trackEdgeLists, args.neighbourNodeIdsOfBulldozedTerminal.tracks)
        if not(isPlatformsChanged) and not(isTracksChanged) then
            logger.print('_rebuildOneTerminalTracks found neither tracks nor platforms have changed')
            if successEventName ~= nil then
                logger.print('_rebuildOneTerminalTracks about to send command ' .. successEventName)
                args.removedTerminalEdgeProps = nil
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    successEventName,
                    -- arrayUtils.cloneDeepOmittingFields(args)
                    args
                ))
            else
                _utils.sendHideProgress()
            end
            return
        end

        -- logger.print('_rebuildOneTerminalTracks proposal =') logger.debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                logger.print('_rebuildOneTerminalTracks success = ', success)
                -- logger.print('LOLLO result = ') logger.debugPrint(result)
                if success then
                    if successEventName ~= nil then
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            -- arrayUtils.cloneDeepOmittingFields(args)
                            args
                        ))
                    else
                        _utils.sendHideProgress()
                    end
                else
                    logger.warn('_rebuildOneTerminalTracks proposal failed, result.resultProposalData =') logger.warningDebugPrint(result.resultProposalData)
                    m_state.warningText = _('UnsnappedSomething')
                    _utils.sendHideProgress()
                end
            end
        )
    end,

    rebuildStationWithSnappyStreetEdgesOLD = function(successEventName, args)
        logger.print('_rebuildStationWithSnappyStreetEdgesOLD starting, args =') logger.debugPrint(args)
        if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
            logger.err('_rebuildStationWithSnappyStreetEdgesOLD got an invalid args.stationConstructionId')
            _utils.sendHideProgress()
            return
        end

        local oldCon = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil or oldCon.fileName ~= _constants.stationConFileName then
            logger.err('_rebuildStationWithSnappyStreetEdgesOLD found no station or a non-freestyle station')
            _utils.sendHideProgress()
            return
        end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()

        local oldConParams = oldCon.params
        local oldModules = arrayUtils.cloneDeepOmittingFields(oldConParams.modules, nil, true)
        local conTransf_lua = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))
        local isSomethingChanged, newModules = _utils.replaceFakeEdgesWithSnappy(oldModules)

        if not(isSomethingChanged) then
            logger.print('_rebuildStationWithSnappyStreetEdgesOLD has nothing to change, leaving')
            if successEventName ~= nil then
                logger.print('_rebuildStationWithSnappyStreetEdgesOLD callback is about to send command ' .. successEventName)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    successEventName,
                    -- arrayUtils.cloneDeepOmittingFields(args)
                    args
                ))
            end
            return
        end

        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.mainTransf, nil, true),
            modules = newModules, -- this is what it's all about
            seed = oldConParams.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
            -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
            terminals = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals, nil, true),
        }
        logger.print('_rebuildStationWithSnappyStreetEdgesOLD newParams.modules =') logger.debugPrint(newParams.modules)

        newCon.fileName = _constants.stationConFileName
        newCon.params = newParams
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { args.stationConstructionId }
        -- proposal.old2new = { -- this does not save destroying and rebuilding the neighbours
        --     [constructionId] = 0,
        -- }

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_rebuildStationWithSnappyStreetEdgesOLD callback, success =', success)
                if success then
                    if successEventName ~= nil then
                        logger.print('_rebuildStationWithSnappyStreetEdgesOLD callback is about to send command ' .. successEventName)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            -- arrayUtils.cloneDeepOmittingFields(args)
                            args
                        ))
                    end
                else
                    -- logger.warn('_rebuildStationWithSnappyStreetEdgesOLD proposal =') logger.warningDebugPrint(proposal)
                    logger.warn('_rebuildStationWithSnappyStreetEdgesOLD result.resultProposalData =') logger.warningDebugPrint(result.resultProposalData)
                    _utils.sendHideProgress()
                    _utils.buildWarningHint(transfUtils.transf2Position(conTransf_lua, true), _('UnsnappedCheckEdgeExits'), _('UnsnappedCheckEdgeExits'))
                end
            end
        )
    end,
]]
    rebuildStationWithLatestProperties = function(oldCon, successEventName, args)
        logger.print('_rebuildStationWithLatestProperties starting, args =') logger.debugPrint(args)

        local oldConParams = oldCon.params
        local oldModules = oldConParams.modules
        logger.print('oldModules =') logger.debugPrint(oldModules)
        local conTransf_lua = transfUtilsUG.new(oldCon.transf:cols(0), oldCon.transf:cols(1), oldCon.transf:cols(2), oldCon.transf:cols(3))

        local nTerminalsToRemove = args.nTerminalsToRemove
        local proposal = _utils.getProposal_2_rebuildAllTerminalTracks(oldConParams, nTerminalsToRemove) or api.type.SimpleProposal.new()
        logger.print('_rebuildStationWithLatestProperties got proposal =') logger.debugPrint(proposal)

        local _maxT = #oldConParams.terminals

        local _getModulesWithoutRemovedTerminals = function()
            local nTerminalsToRemove_indexed = {}
            for _, value in pairs(nTerminalsToRemove) do
                nTerminalsToRemove_indexed[value] = true
            end
            local _getNLowerTerminalsToRemove_indexedBy_nTerminal = function()
                local results = {}
                local nRemovedTerminalCounter = 0
                for t = 1, _maxT, 1 do
                    results[t] = nRemovedTerminalCounter
                    if nTerminalsToRemove_indexed[t] then nRemovedTerminalCounter = nRemovedTerminalCounter + 1 end
                end
                return results
            end
            local nLowerTerminalsToRemove_indexedBy_nTerminal = _getNLowerTerminalsToRemove_indexedBy_nTerminal()
            logger.print('nLowerTerminalsToRemove_indexedBy_nTerminal =') logger.debugPrint(nLowerTerminalsToRemove_indexedBy_nTerminal)

            local moduleProps_indexedBySlotId = {}
            for slotId, modu in pairs(oldModules) do
                local nTerminal, nTrackEdge, baseId = slotHelpers.demangleId(slotId)

                if nTerminal == 0 then -- some modules have terminal == 0, like subways
                    moduleProps_indexedBySlotId[slotId] = {
                        baseId = baseId,
                        module = arrayUtils.cloneDeepOmittingFields(modu, nil, true),
                        nNewTerminal = 0,
                        nOldTerminal = 0,
                        nTrackEdge = nTrackEdge,
                    }
                elseif not(nTerminalsToRemove_indexed[nTerminal]) then
                    moduleProps_indexedBySlotId[slotId] = {
                        baseId = baseId,
                        module = arrayUtils.cloneDeepOmittingFields(modu, nil, true),
                        nNewTerminal = nTerminal - nLowerTerminalsToRemove_indexedBy_nTerminal[nTerminal],
                        nOldTerminal = nTerminal,
                        nTrackEdge = nTrackEdge,
                    }
                end
            end

            local results = {}
            logger.print('modulesAndTerminals_indexedBySlotId =') logger.debugPrint(moduleProps_indexedBySlotId)
            for slotId, props in pairs(moduleProps_indexedBySlotId) do
                if props.nNewTerminal then
                    if props.nNewTerminal == props.nOldTerminal then
                        results[slotId] = props.module
                    else
                        local newSlotId = slotHelpers.mangleId(props.nNewTerminal, props.nTrackEdge, props.baseId)
                        results[newSlotId] = props.module
                    end
                end
            end

            return results
        end

        local newModules = _getModulesWithoutRemovedTerminals()
        -- do this with the con config menu open if you ask for trouble. Probably, preProcessFn() interferes.
        -- Here, we act after the menu has closed.
        local isSomethingChanged, newModules_NoRemovedTerminals_NoFakes = _utils.replaceFakeEdgesWithSnappy(newModules)

        if not(isSomethingChanged) and #nTerminalsToRemove == 0 then
            logger.print('_rebuildStationWithLatestProperties has nothing to change, leaving')
            if successEventName ~= nil then
                logger.print('_rebuildStationWithLatestProperties callback is about to send command ' .. successEventName)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    successEventName,
                    -- arrayUtils.cloneDeepOmittingFields(args)
                    args
                ))
            end
            return
        end

        local _getTerminalParams = function()
            local newTerminals = {}
            for t = 1, _maxT, 1 do
                if not(arrayUtils.arrayHasValue(nTerminalsToRemove, t)) then
                    -- this is very expensive but we need it otherwise we get userdata - lua data mismatches
                    newTerminals[#newTerminals+1] = arrayUtils.cloneDeepOmittingFields(oldConParams.terminals[t], nil, true)
                    -- newTerminals[#newTerminals+1] = oldConParams.terminals[t]
                end
            end
            return newTerminals
        end
        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldConParams.mainTransf, nil, true),
            modules = newModules,
            seed = oldConParams.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldConParams.subways, nil, true),
            terminals = _getTerminalParams(),
        }
        -- get rid of subways if bulldozing the last terminal
        if #newParams.terminals < 1 then newParams.subways = {} end
        logger.print('_rebuildStationWithLatestProperties newParams.modules =') logger.debugPrint(newParams.modules)

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName
        newCon.params = newParams
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf
logger.print('ONE')
        if #nTerminalsToRemove < _maxT then
            proposal.constructionsToAdd[1] = newCon
        end
logger.print('TWO')
        proposal.constructionsToRemove = { args.stationConstructionId }
logger.print('THREE')
        -- proposal.old2new = { -- this does not save destroying and rebuilding the neighbours
        --     [constructionId] = 0,
        -- }

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()
logger.print('FOUR')
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_rebuildStationWithLatestProperties callback, success =', success)
                if success then
                    if successEventName ~= nil then
                        logger.print('_rebuildStationWithLatestProperties callback is about to send command ' .. successEventName)
                        
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            -- arrayUtils.cloneDeepOmittingFields(args)
                            args
                        ))
                    end
                else
                    -- logger.warn('_rebuildStationWithLatestProperties proposal =') logger.warningDebugPrint(proposal)
                    logger.warn('_rebuildStationWithLatestProperties result.resultProposalData =') logger.warningDebugPrint(result.resultProposalData)
                    _utils.sendHideProgress()
                    _utils.buildWarningHint(transfUtils.transf2Position(conTransf_lua, true), _('UnsnappedCheckEdgeExits'), _('UnsnappedCheckEdgeExits'))
                end
            end
        )
    end,
    bulldozeConstruction = function(constructionId)
        if not(edgeUtils.isValidAndExistingId(constructionId)) then return end

        -- local oldCon = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        -- if not(oldCon) or not(oldCon.params) then return end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { constructionId }
        -- proposal.constructionsToRemove[1] = constructionId -- fails to add
        -- proposal.constructionsToRemove:add(constructionId) -- fails to add

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('LOLLO _bulldozeConstruction success = ', success)
                -- logger.print('LOLLO _bulldozeConstruction result = ') logger.debugPrint(result)
            end
        )
    end,

    removeNeighbours = function(successEventName, args)
        logger.print('_removeNeighbours starting, successEventName = ' .. (successEventName or 'NIL'))
        -- logger.print('args =') logger.debugPrint(args)
        logger.print('args.nTerminalsToRemove =') logger.debugPrint(args.nTerminalsToRemove)
        logger.print('args.trackEdgeList =') logger.debugPrint(args.trackEdgeList)
        logger.print('args.platformEdgeList =') logger.debugPrint(args.platformEdgeList)
        logger.print('args.newTerminalNeighbours =') logger.debugPrint(args.newTerminalNeighbours)
        logger.print('args.trackEndEntities =') logger.debugPrint(args.trackEndEntities)
        logger.print('args.streetEndEntities =') logger.debugPrint(args.streetEndEntities)

        local trackEdgeIds = {}
        local platformEdgeIds = {}
        local allEdgeIds = {}
        local nTerminalsToRemove_indexed = {}
        if args.nTerminalsToRemove ~= nil then
            for _, t in pairs(args.nTerminalsToRemove) do
                nTerminalsToRemove_indexed[t] = true
            end
        end
        if args.trackEdgeList ~= nil then
            for _, edgeProps in pairs(args.trackEdgeList) do
                allEdgeIds[#allEdgeIds+1] = edgeProps.edgeId
                trackEdgeIds[#trackEdgeIds+1] = edgeProps.edgeId
            end
        end
        if args.platformEdgeList ~= nil then
            for _, edgeProps in pairs(args.platformEdgeList) do
                allEdgeIds[#allEdgeIds+1] = edgeProps.edgeId
                platformEdgeIds[#platformEdgeIds+1] = edgeProps.edgeId
            end
        end
        if args.newTerminalNeighbours ~= nil then
            arrayUtils.concatValues(allEdgeIds, args.newTerminalNeighbours.platforms.edgeIds)
            arrayUtils.concatValues(allEdgeIds, args.newTerminalNeighbours.tracks.edgeIds)
        end
        if args.trackEndEntities ~= nil then
            for t, terminalEndEntities in pairs(args.trackEndEntities) do
                for edgeId, _ in pairs(terminalEndEntities.platforms.jointNeighbourEdges.props) do
                    allEdgeIds[#allEdgeIds+1] = edgeId
                end
                for edgeId, _ in pairs(terminalEndEntities.tracks.jointNeighbourEdges.props) do
                    allEdgeIds[#allEdgeIds+1] = edgeId
                end
            end
        end
        -- here, there could be the same edge twice if it connects two terminals
        if args.streetEndEntities ~= nil then
            for _a, endEntity in pairs(args.streetEndEntities) do
                for edgeId, _b in pairs(endEntity.jointNeighbourEdges.props) do
                    allEdgeIds[#allEdgeIds+1] = edgeId
                end
            end
        end
        logger.print('_removeNeighbours allEdgeIds =') logger.debugPrint(allEdgeIds)

        -- If the user added or removed modules, preProcessFn() has deleted the street edges, so their edgeIds and nodeIds will be moot.
        -- This is why we check if stuff exists.
        local allEdgeIds_indexed = {}
        local allExistingEdgeIds_indexed = {}
        for _, edgeId in pairs(allEdgeIds) do
            if edgeUtils.isValidAndExistingId(edgeId) then
                allExistingEdgeIds_indexed[edgeId] = true
            end
            allEdgeIds_indexed[edgeId] = true
        end

        local isAnythingChanged = false
        local sharedNodeIds_indexed = {}
        local proposal = api.type.SimpleProposal.new()
        for edgeId, _ in pairs(allExistingEdgeIds_indexed) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge ~= nil then
                proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
                isAnythingChanged = true
                if baseEdge.objects then
                    for o = 1, #baseEdge.objects do
                        proposal.streetProposal.edgeObjectsToRemove[#proposal.streetProposal.edgeObjectsToRemove+1] = baseEdge.objects[o][1]
                    end
                end

                for __, nodeId in pairs({baseEdge.node0, baseEdge.node1}) do
                    local connectedEdgeIds = edgeUtils.getConnectedEdgeIds({nodeId})
                    local isNodeToBeRemoved = true
                    for ___, connectedEdgeId in pairs(connectedEdgeIds) do
                        if not(allExistingEdgeIds_indexed[connectedEdgeId]) then
                            isNodeToBeRemoved = false
                            break
                        end
                    end
                    if isNodeToBeRemoved then sharedNodeIds_indexed[nodeId] = true end
                end
            end
        end
        logger.print('sharedNodeIds_indexed ONE =') logger.debugPrint(sharedNodeIds_indexed)

        if args.streetEndEntities ~= nil then
            local _tolerance = 0.001
            for _, endEntity in pairs(args.streetEndEntities) do
                -- this would be OK for most cases, but it fails when two platforms are attached via two segments
                -- arrayUtils.concatValues(sharedNodeIds, endEntity.jointNeighbourNode.outerLoneNodeIds)

                -- remove inner node if all its edges are marked for removal or were removed by preProcessFn()
                -- local innerNodeId = endEntity.nodeId NO!! these nodeIds are unreliable coz they may have changed after preProcessFn()
                local innerNodePosition = endEntity.nodePosition
                local innerNodeId = edgeUtils.getNearbyObjectIds(
                    transfUtils.position2Transf(innerNodePosition),
                    _tolerance,
                    api.type.ComponentType.BASE_NODE,
                    innerNodePosition.z - _tolerance,
                    innerNodePosition.z + _tolerance
                )[1]
                if edgeUtils.isValidAndExistingId(innerNodeId) then
                    local isRemoveInnerNode = true
                    for __, edgeId in pairs(edgeUtils.getConnectedEdgeIds({innerNodeId})) do
                        if not(allEdgeIds_indexed[edgeId]) then -- node is connected to an edge that I am not removing here
                            isRemoveInnerNode = false
                            break
                        end
                    end
                    if isRemoveInnerNode then sharedNodeIds_indexed[innerNodeId] = true end
                end
                -- remove outer nodes if all their edges are marked for removal or were removed by preProcessFn()
                for __, props in pairs(endEntity.jointNeighbourEdges.props) do
                    local outerNodePosition = (props.node0Props.nodeId == endEntity.nodeId) and props.node1Props.position or props.node0Props.position
                    local outerNodeId = edgeUtils.getNearbyObjectIds(
                        transfUtils.position2Transf(outerNodePosition),
                        _tolerance,
                        api.type.ComponentType.BASE_NODE,
                        outerNodePosition.z - _tolerance,
                        outerNodePosition.z + _tolerance
                    )[1]
                    if edgeUtils.isValidAndExistingId(outerNodeId) then
                        local isRemoveOuterNode = true
                        for ___, edgeId in pairs(edgeUtils.getConnectedEdgeIds({outerNodeId})) do
                            if not(allEdgeIds_indexed[edgeId]) then -- node is connected to an edge that I am not removing here
                                isRemoveOuterNode = false
                                break
                            end
                        end
                        if isRemoveOuterNode then sharedNodeIds_indexed[outerNodeId] = true end
                    end
                end
            end
        end
        logger.print('sharedNodeIds_indexed FOUR =') logger.debugPrint(sharedNodeIds_indexed)
        local i = 0
        for nodeId, _ in pairs(sharedNodeIds_indexed) do
            i = i + 1
            proposal.streetProposal.nodesToRemove[i] = nodeId
            isAnythingChanged = true
        end

        -- if the neighbour is a construction, bulldoze it and rebuild it later
        local neighbourConIds = {}
        if args.streetEndEntities ~= nil then
            for a, endEntity in pairs(args.streetEndEntities) do
                for b, conId in pairs(endEntity.jointNeighbourNode.conIds) do
                    arrayUtils.addUnique(neighbourConIds, conId)
                end
            end
        end
        if #neighbourConIds > 0 then
            proposal.constructionsToRemove = neighbourConIds
            isAnythingChanged = true
        end

        logger.print('_removeNeighbours proposal =') logger.debugPrint(proposal)
        if not(isAnythingChanged) then
            logger.print('_removeNeighbours skipping an empty proposal')
            if successEventName ~= nil then
                logger.print('_removeNeighbours callback is about to send command ' .. successEventName)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    successEventName,
                    args
                    -- arrayUtils.cloneDeepOmittingFields(args)
                ))
            end
            return
        end

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('command callback firing for _removeNeighbours, success =', success)
                -- logger.debugPrint(result)
                if success then
                    if successEventName ~= nil then
                        logger.print('_removeNeighbours callback is about to send command ' .. successEventName)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            arrayUtils.cloneDeepOmittingFields(args)
                        ))
                    else
                        _utils.sendHideProgress()
                    end
                else
                    logger.err('_removeNeighbours proposal failed, result.resultProposalData =') logger.errorDebugPrint(result.resultProposalData)
                    m_state.warningText = _('UnsnappedSomething')
                    _utils.sendHideProgress()
                end
            end
        )
    end,

    replaceEdgeWithSameRemovingObject = function(objectIdToRemove)
        logger.print('_replaceEdgeWithSameRemovingObject starting')
        if not(edgeUtils.isValidAndExistingId(objectIdToRemove)) then return end

        logger.print('_replaceEdgeWithSameRemovingObject found, the edge object id is valid')
        local oldEdgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(objectIdToRemove)
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end

        logger.print('_replaceEdgeWithSameRemovingObject found, the old edge id is valid')
        -- replaces a track segment with an identical one, without destroying the buildings
        local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(oldEdgeId, objectIdToRemove)
        if not(proposal) then return end

        logger.print('_replaceEdgeWithSameRemovingObject likes the proposal')
        -- logger.debugPrint(proposal)
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
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                logger.print('LOLLO _replaceEdgeWithSameRemovingObject success = ') logger.debugPrint(success)
            end
        )
    end,

    splitEdgeRemovingObject = function(wholeEdgeId, nodeBetween, objectIdToRemove, successEventName, successEventArgs, newArgName, mustSplit)
        -- logger.print('splitEdgeRemovingObject starting, wholeEdgeId =', wholeEdgeId or 'NIL')
        if not(edgeUtils.isValidAndExistingId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

        -- logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
        local oldBaseEdge = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldBaseEdgeTrack = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldBaseEdge == nil or oldBaseEdgeTrack == nil then return end
        -- logger.print('oldBaseEdge =') logger.debugPrint(oldBaseEdge)

        local node0 = api.engine.getComponent(oldBaseEdge.node0, api.type.ComponentType.BASE_NODE)
        local node1 = api.engine.getComponent(oldBaseEdge.node1, api.type.ComponentType.BASE_NODE)
        if node0 == nil or node1 == nil then return end
        -- logger.print('node0 =') logger.debugPrint(node0)
        -- logger.print('node1 =') logger.debugPrint(node1)

        if not(comparisonUtils.isXYZsSame(nodeBetween.refPosition0, node0.position)) and not(comparisonUtils.isXYZsSame(nodeBetween.refPosition0, node1.position)) then
            logger.err('splitEdge cannot find the nodes')
            return
        end

        if comparisonUtils.isXYZsSame(nodeBetween.refPosition0, node0.position) then
            logger.print('nodeBetween is orientated like my edge')
        else
            logger.print('nodeBetween is not orientated like my edge')
            nodeBetween.refDistance0, nodeBetween.refDistance1 = nodeBetween.refDistance1, nodeBetween.refDistance0
            nodeBetween.refPosition0, nodeBetween.refPosition1 = nodeBetween.refPosition1, nodeBetween.refPosition0
            nodeBetween.refTangent0, nodeBetween.refTangent1 = nodeBetween.refTangent1, nodeBetween.refTangent0
            nodeBetween.tangent = transfUtils.getVectorMultiplied(nodeBetween.tangent, -1)
        end
        local distance0 = nodeBetween.refDistance0
        local distance1 = nodeBetween.refDistance1
        logger.print('distance0 =') logger.debugPrint(distance0)
        logger.print('distance1 =') logger.debugPrint(distance1)
        local isNode0EndOfLine = #(edgeUtils.track.getConnectedEdgeIds({oldBaseEdge.node0})) == 1
        local isNode1EndOfLine = #(edgeUtils.track.getConnectedEdgeIds({oldBaseEdge.node1})) == 1
        logger.print('isNode0EndOfLine =') logger.debugPrint(isNode0EndOfLine)
        logger.print('isNode1EndOfLine =') logger.debugPrint(isNode1EndOfLine)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, true may shift the new nodes after the split, which makes them impossible for us to recognise.
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        -- the split may occur at the end of an edge - in theory, but I could not make it happen in practise.
        local reasonForNotSplitting = 0
        if distance0 == 0 then reasonForNotSplitting = 1
        elseif distance1 == 0 then reasonForNotSplitting = 2
        elseif not(mustSplit) then
            if isNode0EndOfLine and distance0 < _constants.minSplitDistanceAtEndOfLine then
                reasonForNotSplitting = 3
            elseif isNode1EndOfLine and distance1 < _constants.minSplitDistanceAtEndOfLine then
                reasonForNotSplitting = 4
            elseif distance0 < _constants.minSplitDistance then
                reasonForNotSplitting = 5
            elseif distance1 < _constants.minSplitDistance then
                reasonForNotSplitting = 6
            end
        end
        logger.print('reasonForNotSplitting =', reasonForNotSplitting)

        if reasonForNotSplitting > 0 then
            -- we use this to avoid unnecessary splits, unless they must happen
            logger.print('nodeBetween is at the end of an edge; nodeBetween =') logger.debugPrint(nodeBetween)
            local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(wholeEdgeId, objectIdToRemove)
            if not(proposal) then return end

            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    logger.print('command callback firing for split, success =', success) --, 'result =') logger.debugPrint(result)
                    if success then
                        if successEventName ~= nil then
                            -- logger.print('successEventName =') logger.debugPrint(successEventName)
                            local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                            if not(stringUtils.isNullOrEmptyString(newArgName)) then
                                local splitNodeId = -1
                                if reasonForNotSplitting == 1 then splitNodeId = oldBaseEdge.node0 logger.print('8one')
                                elseif reasonForNotSplitting == 2 then splitNodeId = oldBaseEdge.node1 logger.print('8two')
                                elseif reasonForNotSplitting == 3 then splitNodeId = oldBaseEdge.node0 logger.print('8three')
                                elseif reasonForNotSplitting == 4 then splitNodeId = oldBaseEdge.node1 logger.print('8four')
                                elseif reasonForNotSplitting == 5 then splitNodeId = oldBaseEdge.node0 logger.print('8five')
                                elseif reasonForNotSplitting == 6 then splitNodeId = oldBaseEdge.node1 logger.print('8six')
                                else
                                    logger.err('impossible condition, distance0 =') logger.errorDebugPrint(distance0)
                                    logger.err('distance1 =') logger.errorDebugPrint(distance1)
                                end
                                logger.print('splitEdgeRemovingObject is about to raise its event with splitNodeId =', splitNodeId or 'NIL')
                                eventArgs[newArgName] = splitNodeId
                            end
                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                string.sub(debug.getinfo(1, 'S').source, 1),
                                _eventId,
                                successEventName,
                                eventArgs
                            ))
                        else
                            _utils.sendHideProgress()
                        end
                    else
                        logger.err('splitEdgeRemovingObject failed, this should never happen')
                        m_state.warningText = 'splitEdgeRemovingObject failed, this should never happen'
                        _utils.sendHideProgress()
                    end
                end
            )
            return
        end

        local oldTan0Length = transfUtils.getVectorLength(oldBaseEdge.tangent0)
        local oldTan1Length = transfUtils.getVectorLength(oldBaseEdge.tangent1)
        -- logger.print('oldTan0Length =') logger.debugPrint(oldTan0Length)
        -- logger.print('oldTan1Length =') logger.debugPrint(oldTan1Length)

        -- local playerOwned = api.type.PlayerOwned.new()
        -- playerOwned.player = api.engine.util.getPlayer()
        local playerOwned = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.PLAYER_OWNED)

        local newNodeBetween = api.type.NodeAndEntity.new()
        newNodeBetween.entity = -3
        newNodeBetween.comp.position = api.type.Vec3f.new(nodeBetween.position.x, nodeBetween.position.y, nodeBetween.position.z)

        local newEdge0 = api.type.SegmentAndEntity.new()
        newEdge0.entity = -1
        newEdge0.type = _constants.railEdgeType
        newEdge0.comp.node0 = oldBaseEdge.node0
        newEdge0.comp.node1 = -3
        newEdge0.comp.tangent0 = api.type.Vec3f.new(
            oldBaseEdge.tangent0.x * distance0 / oldTan0Length,
            oldBaseEdge.tangent0.y * distance0 / oldTan0Length,
            oldBaseEdge.tangent0.z * distance0 / oldTan0Length
        )
        newEdge0.comp.tangent1 = api.type.Vec3f.new(
            nodeBetween.tangent.x * distance0,
            nodeBetween.tangent.y * distance0,
            nodeBetween.tangent.z * distance0
        )
        newEdge0.comp.type = oldBaseEdge.type -- respect bridge or tunnel
        newEdge0.comp.typeIndex = oldBaseEdge.typeIndex -- respect bridge or tunnel type
        newEdge0.playerOwned = playerOwned
        newEdge0.trackEdge = oldBaseEdgeTrack

        local newEdge1 = api.type.SegmentAndEntity.new()
        newEdge1.entity = -2
        newEdge1.type = _constants.railEdgeType
        newEdge1.comp.node0 = -3
        newEdge1.comp.node1 = oldBaseEdge.node1
        newEdge1.comp.tangent0 = api.type.Vec3f.new(
            nodeBetween.tangent.x * distance1,
            nodeBetween.tangent.y * distance1,
            nodeBetween.tangent.z * distance1
        )
        newEdge1.comp.tangent1 = api.type.Vec3f.new(
            oldBaseEdge.tangent1.x * distance1 / oldTan1Length,
            oldBaseEdge.tangent1.y * distance1 / oldTan1Length,
            oldBaseEdge.tangent1.z * distance1 / oldTan1Length
        )
        newEdge1.comp.type = oldBaseEdge.type
        newEdge1.comp.typeIndex = oldBaseEdge.typeIndex
        newEdge1.playerOwned = playerOwned
        newEdge1.trackEdge = oldBaseEdgeTrack

        if type(oldBaseEdge.objects) == 'table' then
            logger.print('splitting: edge objects found')
            local edge0Objects = {}
            local edge1Objects = {}
            for _, edgeObj in pairs(oldBaseEdge.objects) do
                logger.print('edgeObj =') logger.debugPrint(edgeObj)
                if edgeObj[1] ~= objectIdToRemove then
                    local edgeObjPosition = edgeUtils.getObjectPosition(edgeObj[1])
                    logger.print('edgeObjPosition =') logger.debugPrint(edgeObjPosition)
                    if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                    local assignment = stationHelpers.getWhichEdgeGetsEdgeObjectAfterSplit(
                        edgeObjPosition,
                        {node0.position.x, node0.position.y, node0.position.z},
                        {node1.position.x, node1.position.y, node1.position.z},
                        nodeBetween
                    )
                    if assignment.assignToSide == 0 then
                        table.insert(edge0Objects, { edgeObj[1], edgeObj[2] })
                    elseif assignment.assignToSide == 1 then
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
        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end
        proposal.streetProposal.nodesToAdd[1] = newNodeBetween
        -- logger.print('split proposal =') logger.debugPrint(proposal)

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('command callback firing for split, success =', success)
                if not(success) then
                    logger.print('proposal =') logger.debugPrint(proposal)
                    logger.print('split callback result =') logger.debugPrint(result)
                end
                if success then
                    if successEventName ~= nil then
                        logger.print('successEventName =') logger.debugPrint(successEventName)
                        -- UG TODO this should come from UG!
                        -- try reading the node ids from the added edges instead.
                        -- no good, there may be a new edge using an old node!
                        -- But check how many nodes are actually added. If it is only 1, fine;
                        -- otherwise, we need a better way to check the new node
                        -- it looks fine, fortunately
                        -- logger.print('split callback result =') logger.debugPrint(result)
                        -- logger.print('split callback result.proposal.proposal.addedNodes =') logger.debugPrint(result.proposal.proposal.addedNodes)
                        if #result.proposal.proposal.addedNodes ~= 1 then
                            logger.err('#result.proposal.proposal.addedNodes =', #result.proposal.proposal.addedNodes)
                        end
                        local addedNodePosition = result.proposal.proposal.addedNodes[1].comp.position
                        logger.print('addedNodePosition =') logger.debugPrint(addedNodePosition)

                        local addedNodeIds = edgeUtils.getNearbyObjectIds(
                            transfUtils.position2Transf(addedNodePosition),
                            0.001,
                            api.type.ComponentType.BASE_NODE
                        )
                        logger.print('addedNodeIds =') logger.debugPrint(addedNodeIds)
                        local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                        if not(stringUtils.isNullOrEmptyString(newArgName)) then
                            eventArgs[newArgName] = addedNodeIds[1]
                        end
                        -- logger.print('sending out eventArgs =') logger.debugPrint(eventArgs)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            successEventName,
                            eventArgs
                        ))
                    else
                        _utils.sendHideProgress()
                    end
                else
                    logger.err('Error splitting tracks, this should never happen')
                    m_state.warningText = 'Error splitting tracks, this should never happen'
                    _utils.sendHideProgress()
                end
            end
        )
    end,

    rebuildUndergroundDepotWithoutHole = function(oldConId)
        -- LOLLO NOTE programmatically adding a depot works, but as soon as you click the depot, the game will crash
        logger.print('_rebuildUndergroundDepotWithoutHole starting, oldConId =', oldConId or 'NIL')
        local oldCon = edgeUtils.isValidAndExistingId(oldConId)
            and api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
            or nil
        if not(oldCon) then return end

        logger.print('oldCon =') logger.debugPrint(oldCon)

        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        if newParams.isShowUnderground == 0 then return end

        newParams.isShowUnderground = 0 -- this is what this is all about: once built, stop showing underground
        newParams.seed = newParams.seed + 1

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName
        newCon.params = newParams
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf

        logger.print('newCon =') logger.debugPrint(newCon)

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { oldConId }
        -- proposal.old2new = { -- makes trouble
        --     -- oldConId, 0
        --     oldConId, 1
        -- }

        logger.print('proposal =') logger.debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_rebuildUndergroundDepotWithoutHole callback, success =', success)
                -- logger.debugPrint(result)
                if not(success) then
                    logger.warn('_rebuildUndergroundDepotWithoutHole failed')
                    logger.warn('proposal =') logger.warningDebugPrint(proposal)
                    logger.warn('result =') logger.warningDebugPrint(result)
                else
                    local newConId = result.resultEntities[1]
                    logger.print('_rebuildUndergroundDepotWithoutHole succeeded, conId = ', newConId)
                end
            end
        )
    end,
}

local _guiActions = {
    getCon = function(constructionId)
        if not(edgeUtils.isValidAndExistingId(constructionId)) then return nil end

        return api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
    end,
    handleSplitterWaypointBuilt = function()
        local splitterWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_guiSplitterWaypointModelId)
        if #splitterWaypointIds == 0 then return end

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.SPLITTER_WAYPOINT_PLACED,
            {
                splitterWaypointId = splitterWaypointIds[1],
            }
        ))
    end,
    handleValidWaypointBuilt = function()
        local trackWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_guiTrackWaypointModelId)
        if #trackWaypointIds ~= 2 then return end

        local platformWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_guiPlatformWaypointModelId)
        if #platformWaypointIds ~= 2 then return end

        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(platformWaypointIds[1])
        local edgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        local isCargo = trackUtils.isCargoPlatform(edgeTrack.trackType)
        logger.print('TWENTY, isCargo =', isCargo)

        -- set a place to build the station
        local platformWaypoint1Pos = edgeUtils.getObjectPosition(platformWaypointIds[1])
        local platformWaypoint2Pos = edgeUtils.getObjectPosition(platformWaypointIds[2])
        if platformWaypoint1Pos == nil or platformWaypoint2Pos == nil then
            logger.err('handleValidWaypointBuilt cannot find the platform waypoint positions')
            return
        end

        local platformWaypointMidTransf = transfUtils.position2Transf({
            (platformWaypoint1Pos[1] + platformWaypoint2Pos[1]) * 0.5,
            (platformWaypoint1Pos[2] + platformWaypoint2Pos[2]) * 0.5,
            (platformWaypoint1Pos[3] + platformWaypoint2Pos[3]) * 0.5,
        })

        local trackWaypoint1Pos = edgeUtils.getObjectPosition(trackWaypointIds[1])
        local trackWaypoint2Pos = edgeUtils.getObjectPosition(trackWaypointIds[2])
        local distance11 = transfUtils.getPositionsDistance(platformWaypoint1Pos, trackWaypoint1Pos)
        local distance12 = transfUtils.getPositionsDistance(platformWaypoint1Pos, trackWaypoint2Pos)

        local eventArgs = {
            isCargo = isCargo,
            platformWaypointMidTransf = platformWaypointMidTransf,
            platformWaypoint1Id = platformWaypointIds[1],
            platformWaypoint2Id = platformWaypointIds[2],
            trackWaypoint1Id = distance11 < distance12 and trackWaypointIds[1] or trackWaypointIds[2],
            trackWaypoint2Id = distance11 < distance12 and trackWaypointIds[2] or trackWaypointIds[1],
        }

        local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationConsList(platformWaypointMidTransf, _constants.searchRadius4NearbyStation2Join, false, true)
        logger.print('handleValidWaypointBuilt found #nearbyFreestyleStations = ' .. #nearbyFreestyleStations)
        if #nearbyFreestyleStations > 0 then
            guiHelpers.showNearbyStationPicker(
                isCargo,
                nearbyFreestyleStations,
                _eventId,
                _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                eventArgs, -- join2StationConId will be added by the popup
                function() guiHelpers.showProgress(_guiTexts.buildInProgress, _guiTexts.modName, _utils.sendAllowProgress) end
            )
        else
            guiHelpers.showProgress(_guiTexts.buildInProgress, _guiTexts.modName, _utils.sendAllowProgress)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                eventArgs
            ))
        end
    end,
    tryJoinSubway = function(conId, con)
        if con == nil
        or type(con.fileName) ~= 'string'
        or not(_constants.subwayConFileNames[con.fileName])
        or con.transf == nil
        then
            return false
        end

        logger.print('_tryJoinSubway starting, conId =', conId or 'NIL')
        local subwayTransf_c = con.transf
        if subwayTransf_c == nil then return false end

        local subwayTransf_lua = transfUtilsUG.new(subwayTransf_c:cols(0), subwayTransf_c:cols(1), subwayTransf_c:cols(2), subwayTransf_c:cols(3))
        if subwayTransf_lua == nil then return false end

        logger.print('conTransf =') logger.debugPrint(subwayTransf_lua)
        local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationConsList(subwayTransf_lua, _constants.searchRadius4NearbyStation2Join, true, false)

        logger.print('#nearbyFreestyleStations =', #nearbyFreestyleStations)
        if #nearbyFreestyleStations == 0 then return false end

        guiHelpers.showNearbyStationPicker(
            false, -- subways are only for passengers
            nearbyFreestyleStations,
            _eventId,
            _eventNames.SUBWAY_JOIN_REQUESTED,
            nil,
            {
                subwayConstructionId = conId
                -- join2StationConId will be added by the popup
            },
            function() guiHelpers.showProgress(_guiTexts.buildSubwayInProgress, _guiTexts.modName, _utils.sendAllowProgress) end
        )

        return true
    end,
    tryShowDistance = function(targetWaypointModelId, newWaypointTransf, mustBeOnPlatform)
        if not(targetWaypointModelId) or not(newWaypointTransf) then return false end

        local similarObjectIdsInAnyEdges = stationHelpers.getAllEdgeObjectsWithModelId(targetWaypointModelId)
        if #similarObjectIdsInAnyEdges ~= 1 then
            -- not ready yet
            return false
        end

        local twinWaypointPosition = edgeUtils.getObjectPosition(similarObjectIdsInAnyEdges[1])
        local newWaypointPosition = transfUtils.transf2Position(
            transfUtilsUG.new(newWaypointTransf:cols(0), newWaypointTransf:cols(1), newWaypointTransf:cols(2), newWaypointTransf:cols(3))
        )
        if newWaypointPosition ~= nil and twinWaypointPosition ~= nil then
            local distance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition) or 0
            guiHelpers.showWaypointDistance(distance)
            return true
        end

        return false
    end,
    validateWaypointBuilt = function(targetWaypointModelId, newWaypointId, waypointEdgeId, trackTypeIndex, mustBeOnPlatform)
        logger.print('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
        -- UG TODO this is empty, ask UG to fix this: can't we have the waypointId in args.result?
        -- The problem persists with build 33345
        -- logger.print('waypoint built, args.result =') logger.debugPrint(args.result)

        -- logger.print('args.proposal.proposal.addedSegments =') logger.debugPrint(args.proposal.proposal.addedSegments)
        if not(edgeUtils.isValidAndExistingId(newWaypointId)) then logger.err('newWaypointId not valid') return false end
        if not(edgeUtils.isValidAndExistingId(waypointEdgeId)) then logger.err('waypointEdgeId not valid') return false end
        if not(edgeUtils.isValidId(trackTypeIndex)) then logger.err('trackTypeIndex not valid') return false end

        logger.print('waypointEdgeId =') logger.debugPrint(waypointEdgeId)
        local lastBuiltBaseEdge = api.engine.getComponent(
            waypointEdgeId,
            api.type.ComponentType.BASE_EDGE
        )
        if not(lastBuiltBaseEdge) then return false end

        -- logger.print('edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, waypointModelId) =')
        -- logger.debugPrint(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, targetWaypointModelId))

        -- forbid building track waypoint on a platform or platform waypoint on a track
        -- if trackUtils.isPlatform(args.proposal.proposal.addedSegments[1].trackEdge.trackType) ~= mustBeOnPlatform then
        if trackUtils.isPlatform(trackTypeIndex) ~= mustBeOnPlatform then
            guiHelpers.showWarningWithGoto(_guiTexts.trackWaypointBuiltOnPlatform)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    edgeId = waypointEdgeId,
                    waypointId = newWaypointId,
                }
            ))
            return false
        end

        local similarObjectIdsInAnyEdges = stationHelpers.getAllEdgeObjectsWithModelId(targetWaypointModelId)
        logger.print('similarObjectsIdsInAnyEdges =') logger.debugPrint(similarObjectIdsInAnyEdges)
        -- forbid building more then two waypoints of the same type
        if #similarObjectIdsInAnyEdges > 2 then
            guiHelpers.showWarningWithGoto(_guiTexts.waypointAlreadyBuilt, newWaypointId, similarObjectIdsInAnyEdges)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    edgeId = waypointEdgeId,
                    waypointId = newWaypointId
                }
            ))
            return false
        end

        local newWaypointPosition = edgeUtils.getObjectPosition(newWaypointId)
        -- make sure the waypoint is not too close to station end nodes, or the game will complain later with it != components.end()
        local endEdgeIds = edgeUtils.getEdgeIdsConnectedToEdgeId(waypointEdgeId)
        local _minDistance = _constants.minSplitDistance * 2
        -- logger.print('endEdgeIds =') logger.debugPrint(endEdgeIds)
        for ___, edgeId in pairs(endEdgeIds) do
            local conId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(edgeId)
            -- logger.print('conId =', conId or 'NIL')
            -- if the edge belongs to a construction
            if edgeUtils.isValidAndExistingId(conId) then
                local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                -- and the construction is a station, freestyle or otherwise
                if con ~= nil then
                    if (type(con.fileName) == 'string' and con.fileName == _constants.stationConFileName) then
                        local stationEndEntities = stationHelpers.getStationTrackEndEntities(conId)
                        -- logger.print('stationEndEntities =') logger.debugPrint(stationEndEntities)
                        -- if any end nodes are too close to my waypoint
                        if stationEndEntities == nil then
                            guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooCloseToStation, newWaypointId)
                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                string.sub(debug.getinfo(1, 'S').source, 1),
                                _eventId,
                                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                {
                                    edgeId = waypointEdgeId,
                                    waypointId = newWaypointId,
                                }
                            ))
                            return false
                        else
                            for __, stationEndEntities4T in pairs(stationEndEntities) do
                                if transfUtils.getPositionsDistance(stationEndEntities4T.platforms.stationEndNodePositions.node1, newWaypointPosition) < _minDistance
                                or transfUtils.getPositionsDistance(stationEndEntities4T.platforms.stationEndNodePositions.node2, newWaypointPosition) < _minDistance
                                or transfUtils.getPositionsDistance(stationEndEntities4T.tracks.stationEndNodePositions.node1, newWaypointPosition) < _minDistance
                                or transfUtils.getPositionsDistance(stationEndEntities4T.tracks.stationEndNodePositions.node2, newWaypointPosition) < _minDistance
                                then
                                    guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooCloseToStation, newWaypointId)
                                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                        string.sub(debug.getinfo(1, 'S').source, 1),
                                        _eventId,
                                        _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                        {
                                            edgeId = waypointEdgeId,
                                            waypointId = newWaypointId,
                                        }
                                    ))
                                    return false
                                end
                            end
                        end
                    else -- if con.stations ~= nil and #con.stations > 0 then
                        -- no knowledge of end nodes: just forbid the waypoint
                        guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooCloseToStation, newWaypointId)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                            {
                                edgeId = waypointEdgeId,
                                waypointId = newWaypointId,
                            }
                        ))
                        return false
                    end
                end
            end
        end

        if #similarObjectIdsInAnyEdges < 2 then
            -- not ready yet
            -- guiHelpers.showWarningWithGoto(_guiTexts.buildMoreWaypoints), newWaypointId)
            return false
        end

        local twinWaypointId =
            newWaypointId == similarObjectIdsInAnyEdges[1] and similarObjectIdsInAnyEdges[2] or similarObjectIdsInAnyEdges[1]
        local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)

        if newWaypointPosition ~= nil and twinWaypointPosition ~= nil then
            local distance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition)
            -- forbid building waypoints too far apart, which would make the station too large
            if distance > _constants.maxWaypointDistance then
                guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooFar, newWaypointId, similarObjectIdsInAnyEdges)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                    {
                        edgeId = waypointEdgeId,
                        waypointId = newWaypointId
                    }
                ))
                return false
            end
            -- forbid building waypoints too close, which would make the station too short and error prone
            if distance < _constants.minWaypointDistance then
                guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooNear, newWaypointId, similarObjectIdsInAnyEdges)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                    {
                        edgeId = waypointEdgeId,
                        waypointId = newWaypointId
                    }
                ))
                return false
            end
        end

        local contiguousTrackEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
            api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
            api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId),
            _constants.maxWaypointDistance,
            false,
            logger.isExtendedLog()
        )
        logger.print('contiguous track edge ids =') logger.debugPrint(contiguousTrackEdgeIds)
        -- make sure the waypoints are on connected tracks
        if #contiguousTrackEdgeIds < 1 then
            guiHelpers.showWarningWithGoto(_guiTexts.waypointsNotConnected, newWaypointId, similarObjectIdsInAnyEdges)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    edgeId = waypointEdgeId,
                    waypointId = newWaypointId,
                }
            ))
            return false
        end

        -- make sure the waypoints are not overlapping existing station tracks or platforms, for any sort of station
        for __, edgeId in pairs(contiguousTrackEdgeIds) do -- don't use _ here, we call it below to translate the message!
            local conId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(edgeId)
            if edgeUtils.isValidAndExistingId(conId) then
                local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                if con ~= nil and con.stations ~= nil and #con.stations > 0 then
                    guiHelpers.showWarningWithGoto(_guiTexts.waypointsCrossStation, newWaypointId)
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                        {
                            edgeId = waypointEdgeId,
                            waypointId = newWaypointId,
                        }
                    ))
                    return false
                end
            end
        end

        local contiguousEdgeIds = {}
        for __, edgeId in pairs(contiguousTrackEdgeIds) do
            arrayUtils.addUnique(contiguousEdgeIds, edgeId)
        end
        logger.print('contiguousEdgeIds =') logger.debugPrint(contiguousEdgeIds)
        -- make sure there are no crossings between the waypoints
        local nodesBetweenWps = edgeUtils.track.getNodeIdsBetweenEdgeIds_optionalEnds(contiguousEdgeIds, false)
        logger.print('nodesBetweenWps =') logger.debugPrint(nodesBetweenWps)
        local _map = api.engine.system.streetSystem.getNode2SegmentMap()
        for __, nodeId in pairs(nodesBetweenWps) do
            if _map[nodeId] and #_map[nodeId] > 2 then
                guiHelpers.showWarningWithGoto(_guiTexts.waypointsCrossCrossing, newWaypointId)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                    {
                        edgeId = waypointEdgeId,
                        waypointId = newWaypointId,
                    }
                ))
                return false
            end
        end

        -- make sure there are no signals or waypoints between the waypoints
        for ___, edgeId in pairs(contiguousEdgeIds) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge and baseEdge.objects and #baseEdge.objects > 0 then
                for __, edgeObj in pairs(baseEdge.objects) do
                    logger.print('edgeObj between waypoints =') logger.debugPrint(edgeObj)
                    if edgeObj[1] ~= newWaypointId and edgeObj[1] ~= twinWaypointId then
                        guiHelpers.showWarningWithGoto(_guiTexts.waypointsCrossSignal, newWaypointId)
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            _eventId,
                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                            {
                                edgeId = waypointEdgeId,
                                waypointId = newWaypointId,
                            }
                        ))
                        return false
                    end
                end
            end
        end

        -- LOLLO NOTE do not check that the tracks between the waypoints are all of the same type
        -- (ie, platforms have the same width) so we have more flexibility with tunnel entrances
        -- on the other hand, different platform widths make trouble with cargo, which has multiple waiting areas:
        -- let's check if they are different only if one is > 5, which only happens with cargo.
        local trackDistances = {}
        for _, edgeId in pairs(contiguousTrackEdgeIds) do
            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
            local baseEdgeProperties = api.res.trackTypeRep.get(baseEdgeTrack.trackType)
            arrayUtils.addUnique(trackDistances, baseEdgeProperties.trackDistance)
        end
        if #trackDistances > 1 then
            for __, td in pairs(trackDistances) do -- don't use _ here, we call it below to translate the message!
                if td > 5 then
                    guiHelpers.showWarningWithGoto(_guiTexts.differentPlatformWidths, newWaypointId)
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                        {
                            edgeId = waypointEdgeId,
                            waypointId = newWaypointId,
                        }
                    ))
                    return false
                end
            end
        end

        -- validation fine, return data
        return {
            newWaypointId = newWaypointId,
            twinWaypointId = twinWaypointId
        }
    end,
}
--[[
_actions.buildSnappyPlatforms = function(stationConstructionId, t, tMax)
    -- we make a build proposal for each terminal, so if one fails we still get the others
    -- LOLLO NOTE after building the station, never mind how well you placed it,
    -- its end nodes won't snap to the adjacent tracks.
    -- AltGr + L will show a red dot, and here is the catch: there are indeed
    -- two separate nodes in the same place, at each station end.
    -- Here, I remove the neighbour track (edge and node) and replace it
    -- with an identical track, which snaps to the station end node instead.
    -- The same happens after joining a subway to a station, which also rebuilds the station construction.

    -- The station deals with appended terminals (one after the other, along the same track) as long as there is a bit in between.
    -- However, this bit in between is replaced once to snap to terminal 1 and replaced again to snap to terminal 2.
    -- The second time it has a new id, so I can only snap it if I reread the station end entities, in a tidy queue.

    logger.print('buildSnappyPlatforms starting for terminal =', t or 'NIL')
    if type(t) ~= 'number' or type(tMax) ~= 'number' then logger.warn('buildSnappyPlatforms received wrong t or tMax') logger.warningDebugPrint(t) logger.warningDebugPrint(tMax) return end
    if t > tMax then logger.print('tMax reached, leaving') return end

    local endEntities4T = stationHelpers.getStationTrackEndEntities4T(stationConstructionId, t)
    logger.print('endEntities4T ' .. (t or 'NIL') .. ' =') logger.debugPrint(endEntities4T)
    if endEntities4T == nil then return end

    local isAnyPlatformFailed = false

    local proposal = api.type.SimpleProposal.new()
    local nNewEntities = 0
    local isSuccess = true

    -- local isAnyNodeAdjoiningAConstruction = endEntities4T.platforms.disjointNeighbourNodes.isNode1AdjoiningAConstruction or endEntities4T.platforms.disjointNeighbourNodes.isNode2AdjoiningAConstruction
    for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdges.edge1Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _utils.tryReplaceSegment(edgeId, endEntities4T.platforms, proposal, nNewEntities)
        -- logger.print('isSuccess =', isSuccess, 'nNewEntities =', nNewEntities)
    end
    for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdges.edge2Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _utils.tryReplaceSegment(edgeId, endEntities4T.platforms, proposal, nNewEntities)
        -- logger.print('isSuccess =', isSuccess, 'nNewEntities =', nNewEntities)
    end

    -- logger.print('proposal =') logger.debugPrint(proposal)
    if isSuccess then
        if #proposal.streetProposal.edgesToAdd > 0 then
            local context = api.type.Context:new()
            -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
            -- context.cleanupStreetGraph = true -- default is false
            -- context.gatherBuildings = false -- default is false
            -- context.gatherFields = true -- default is true
            -- context.player = api.engine.util.getPlayer()
            -- UG TODO I need to check myself coz the api will crash, even if I call it in this step-by-step fashion.
            local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
            if expectedResult.errorState.critical then
                logger.print('expectedResult =') logger.debugPrint(expectedResult)
                isAnyPlatformFailed = true
                _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
            else
                api.cmd.sendCommand(
                    api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                    function(result, success)
                        logger.print('buildSnappyPlatforms callback for terminal', t or 'NIL', ', success =', success)
                        if not(success) then isAnyPlatformFailed = true end
                        -- move on to the next terminal
                        _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
                    end
                )
            end
        else
            -- move on to the next terminal
            _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
        end
    else
        isAnyPlatformFailed = true
        logger.warn('could not build snappy platforms for terminal', t or 'NIL')
        -- move on to the next terminal
        _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
    end
end
]]
--[[
_actions.buildSnappyStreetEdges = function(stationConId)
    -- rebuild the street edges connected to the station.
    -- If some are frozen in a construction, force-upgrade the station instead.
    logger.print('_buildSnappyStreetEdges starting')

    local allEndEntities = stationHelpers.getStationStreetEndEntities(stationConId)
    if allEndEntities == nil then
        logger.err('_buildSnappyStreetEdges cannot find the station end entities')
        return
    end

    local proposal = api.type.SimpleProposal.new()
    local _addNodeToRemove = function(nodeId)
        if edgeUtils.isValidAndExistingId(nodeId) and not(arrayUtils.arrayHasValue(proposal.streetProposal.nodesToRemove, nodeId)) then
            proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = nodeId
        end
    end

    -- Assertion `!ContainsEntity(m_proposal->removedNodes, entity)' failed
    -- used to happen when building a bridge between two platforms at LeftRightThin,
    -- these platforms being separated by a piece of grass with a bridge above connecting them.
    -- Two different platforms shared a neighbouring edge.
    -- In this case, we'll have:
    -- _getStationStreetEndEntities results =
    --     {
    --         {
    --             disjointNeighbourEdges.edgeIds = { 29462, },
    --             disjointNeighbourNode.nodeId = 28429,
    --             edgeId = 20883,
    --             disjointNeighbourNode.isNodeAdjoiningAConstruction = false,
    --             disjointNeighbourNode.conIds = { },
    --             nodeId = 29504,
    --             nodePosition = {
    --             x = 71.972915649414,
    --             y = 1241.5035400391,
    --             z = 45.285850524902,
    --             },
    --         },
    --         {
    --             disjointNeighbourEdges.edgeIds = { 29462, },
    --             disjointNeighbourNode.nodeId = 28919,
    --             edgeId = 23547,
    --             disjointNeighbourNode.isNodeAdjoiningAConstruction = false,
    --             disjointNeighbourNode.conIds = { },
    --             nodeId = 29619,
    --             nodePosition = {
    --             x = 46.655982971191,
    --             y = 1233.583984375,
    --             z = 45.712036132813,
    --             },
    --         },
    --     }

    local neighbourConIds_indexed = {}
    local newSegmentEntity = 0

    local endEntities_GroupedBy_disjointNeighbourEdgeId = {}
    for _, endEntity in pairs(allEndEntities) do
        for _, edgeId in pairs(endEntity.disjointNeighbourEdges.edgeIds) do
            if edgeUtils.isValidAndExistingId(edgeId) then
                if not(endEntities_GroupedBy_disjointNeighbourEdgeId[edgeId]) then endEntities_GroupedBy_disjointNeighbourEdgeId[edgeId] = {} end

                table.insert(
                    endEntities_GroupedBy_disjointNeighbourEdgeId[edgeId],
                    endEntity
                )
            else
                state.warningText = _('UnsnappedRoads')
                logger.warn('invalid disjointNeighbourEdgeId in _buildSnappyStreetEdges, edgeId = ' .. (edgeId or 'NIL'))
                return
            end
        end
    end

    for _, endEntity in pairs(allEndEntities) do
        for _, conId in pairs(endEntity.disjointNeighbourNode.conIds) do
            if edgeUtils.isValidAndExistingId(conId) then
                neighbourConIds_indexed[conId] = true
            else
                logger.warn('invalid disjointNeighbourNodeId.conId in _buildSnappyStreetEdges, conId = ' .. (conId or 'NIL'))
            end
        end
    end

    for disjointNeighbourEdgeId, endEntities in pairs(endEntities_GroupedBy_disjointNeighbourEdgeId) do
        logger.print('endEntities =') logger.debugPrint(endEntities)
        logger.print('valid disjointNeighbourEdgeId in _buildSnappyStreetEdges, going ahead')
        -- for _, endEntity in pairs(endEntities) do
            -- for _, neighbourConId in pairs(endEntity.disjointNeighbourNode.conIds) do
            --     neighbourConIds_indexed[neighbourConId] = true
            -- end
        -- end
        local newSegment = api.type.SegmentAndEntity.new()
        newSegment.entity = newSegmentEntity - 1

        local baseEdge = api.engine.getComponent(disjointNeighbourEdgeId, api.type.ComponentType.BASE_EDGE)
        local isNode0ReplacingDisjoint = false
        for _, endEntity in pairs(endEntities) do
            if baseEdge.node0 == endEntity.disjointNeighbourNode.nodeId then
                newSegment.comp.node0 = endEntity.nodeId
                _addNodeToRemove(endEntity.disjointNeighbourNode.nodeId)
                logger.print('twenty-one')
                isNode0ReplacingDisjoint = true
                break
            end
        end
        if not(isNode0ReplacingDisjoint) then
            newSegment.comp.node0 = baseEdge.node0
            logger.print('twenty-three')
        end

        local isNode1ReplacingDisjoint = false
        for _, endEntity in pairs(endEntities) do
            if baseEdge.node1 == endEntity.disjointNeighbourNode.nodeId then
                newSegment.comp.node1 = endEntity.nodeId
                _addNodeToRemove(endEntity.disjointNeighbourNode.nodeId)
                logger.print('twenty-four')
                isNode1ReplacingDisjoint = true
                break
            end
        end
        if not(isNode1ReplacingDisjoint) then
            newSegment.comp.node1 = baseEdge.node1
            logger.print('twenty-six')
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
        newSegment.type = _constants.streetEdgeType
        local baseEdgeStreet = api.engine.getComponent(disjointNeighbourEdgeId, api.type.ComponentType.BASE_EDGE_STREET)
        if baseEdgeStreet ~= nil then
            logger.print('edgeId', disjointNeighbourEdgeId, 'is street')
            newSegment.streetEdge.streetType = baseEdgeStreet.streetType
            newSegment.streetEdge.hasBus = baseEdgeStreet.hasBus
            newSegment.streetEdge.tramTrackType = baseEdgeStreet.tramTrackType
            -- newSegment.streetEdge.precedenceNode0 = baseEdgeStreet.precedenceNode0
            -- newSegment.streetEdge.precedenceNode1 = baseEdgeStreet.precedenceNode1
        end

        proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
        if not(arrayUtils.arrayHasValue(proposal.streetProposal.edgesToRemove, disjointNeighbourEdgeId)) then
            proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = disjointNeighbourEdgeId
        end

        newSegmentEntity = newSegmentEntity - 1
    end

    logger.print('_buildSnappyStreetEdges proposal =') logger.debugPrint(proposal)
    logger.print('_buildSnappyStreetEdges neighbourConIds_indexed =') logger.debugPrint(neighbourConIds_indexed)

    local _upgradeNeighbourCons = function()
        -- cannot rebuild some of the edges coz they are be locked in a construction:
        -- rebuild the station instead, or better: rebuild those adjoining constructions.
        -- If they have snappy edges, they will resnap.
        local isAnyUpgradeFailed = false
        for neighbourConId, _ in pairs(neighbourConIds_indexed) do
            isAnyUpgradeFailed = isAnyUpgradeFailed or not(_utils.tryUpgradeStationOrStairsOrLiftConstruction(neighbourConId))
        end
        logger.print('isAnyUpgradeFailed =', isAnyUpgradeFailed)
        if not(isAnyUpgradeFailed) then return end

        state.warningText = _('UnsnappedRoads')
    end

    if #proposal.streetProposal.edgesToAdd == 0 then
        logger.print('_buildSnappyStreetEdges added no street edges')
        _upgradeNeighbourCons()
        return
    end

    local context = api.type.Context:new()
    -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
    -- context.cleanupStreetGraph = true -- default is false
    -- context.gatherBuildings = false -- default is false
    -- context.gatherFields = true -- default is true
    -- context.player = api.engine.util.getPlayer()
    -- UG TODO I need to check myself coz the api will crash, even if I call it in this step-by-step fashion.
    local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
    if expectedResult.errorState.critical then
        logger.print('_buildSnappyStreetEdges expectedResult =') logger.debugPrint(expectedResult)
        state.warningText = _('UnsnappedRoads')
        return
    end

    api.cmd.sendCommand(
        api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
        function(result, success)
            logger.print('_buildSnappyStreetEdges callback, success =', success)
            
                -- LOLLO NOTE Snapping trouble with street edges:
                -- 1) if an edge is non-snappy and it is attached to a road, fine: 
                -- the station will resnap as soon as the user closes the construction menu.
                -- 2) if an edge is non-snappy and it is attached to a non-snappy con, fine:
                -- there will be a road in between, so we are in case 1.
                -- Obviously, the non-snappy con cannot be moved about or it will unsnap.
                -- 3) if an edge is non-snappy and it is attached to a snappy con, bad:
                -- the mod will not restore the snappiness;
                -- we try to fix this with tryUpgradeStationOrStairsOrLiftConstruction(),
                -- only for our own constructions.
                -- 4) if an edge is snappy and it is attached to a road, fine: like case 1.
                -- 5) if an edge is snappy and it is attached to a non-snappy con, fine: like case 2.
                -- 6) if an edge is snappy and it is attached to a snappy con, fine:
                -- the station will resnap at once.
            
            _upgradeNeighbourCons()
        end
    )
end
]]
--[[
_actions.buildSnappyTracks = function(stationConstructionId, t, tMax)
    -- see the comments in buildSnappyPlatforms
    logger.print('buildSnappyTracks starting for terminal =', t or 'NIL')
    if type(t) ~= 'number' or type(tMax) ~= 'number' then
        logger.warn('buildSnappyTracks received wrong t or tMax')
        logger.warningDebugPrint(t)
        logger.warningDebugPrint(tMax)
        return
    end
    if t > tMax then logger.print('tMax reached, leaving') return end

    local endEntities4T = stationHelpers.getStationTrackEndEntities4T(stationConstructionId, t)
    logger.print('endEntities4T =') logger.debugPrint(endEntities4T)
    if endEntities4T == nil then return end

    local isAnyTrackFailed = false

    local proposal = api.type.SimpleProposal.new()
    local nNewEntities = 0
    local isSuccess = true

    -- local isAnyNodeAdjoiningAConstruction = endEntities4T.tracks.disjointNeighbourNodes.isNode1AdjoiningAConstruction or endEntities4T.tracks.disjointNeighbourNodes.isNode2AdjoiningAConstruction
    for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdges.edge1Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _utils.tryReplaceSegment(edgeId, endEntities4T.tracks, proposal, nNewEntities)
    end
    for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdges.edge2Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _utils.tryReplaceSegment(edgeId, endEntities4T.tracks, proposal, nNewEntities)
    end

    if isSuccess then
        if #proposal.streetProposal.edgesToAdd > 0 then
            local context = api.type.Context:new()
            -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
            -- context.cleanupStreetGraph = true -- default is false
            -- context.gatherBuildings = false -- default is false
            -- context.gatherFields = true -- default is true
            -- context.player = api.engine.util.getPlayer()

            local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
            if expectedResult.errorState.critical then
                logger.print('critical error when building snappy tracks, expectedResult =') logger.debugPrint(expectedResult)
                isAnyTrackFailed = true
                _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
            else
                api.cmd.sendCommand(
                    api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                    function(result, success)
                        logger.print('buildSnappyTracks callback for terminal', t or 'NIL', ', success =', success)
                        if not(success) then isAnyTrackFailed = true end
                        -- move on to the next terminal
                        _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
                    end
                )
            end
        else
            -- move on to the next terminal
            _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
        end
    else
        isAnyTrackFailed = true
        logger.warn('could not build snappy tracks for terminal', t or 'NIL')
        -- move on to the next terminal
        _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
    end

    if isAnyTrackFailed then
        -- cannot call the popup from the worker thread
        state.warningText = _('BuildSnappyTracksFailed')
    end

    _utils.sendHideProgress()
end
]]
function data()
    return {
        -- ini = function()
        -- end,
        guiInit = function()
            -- read variables
            _guiPlatformWaypointModelId = api.res.modelRep.find(_constants.platformWaypointModelId)
            _guiSplitterWaypointModelId = api.res.modelRep.find(_constants.splitterWaypointModelId)
            _guiTrackWaypointModelId = api.res.modelRep.find(_constants.trackWaypointModelId)
            -- read texts
            _guiTexts.awaitFinalisationBeforeSaving = _('AwaitFinalisationBeforeSaving')
            _guiTexts.differentPlatformWidths = _('DifferentPlatformWidths')
            _guiTexts.buildInProgress = _('BuildInProgress')
            _guiTexts.buildMoreWaypoints = _('BuildMoreWaypoints')
            _guiTexts.buildSnappyTracksFailed = _('BuildSnappyTracksFailed')
            _guiTexts.buildSubwayInProgress = _('BuildSubwayInProgress')
            _guiTexts.closeConConfigBeforeSaving = _('CloseConConfigBeforeSaving')
            _guiTexts.modName = _('NAME')
            _guiTexts.needAdjust4Snap = _('NeedAdjust4Snap')
            _guiTexts.rebuildNeighboursInProgress = _('RebuildNeighboursInProgress')
            _guiTexts.restoreInProgress = _('RestoreInProgress')
            _guiTexts.trackWaypointBuiltOnPlatform = _('TrackWaypointBuiltOnPlatform')
            _guiTexts.unsnappedRoads = _('UnsnappedRoads')
            _guiTexts.waypointAlreadyBuilt = _('WaypointAlreadyBuilt')
            _guiTexts.waypointsCrossCrossing = _('WaypointsCrossCrossing')
            _guiTexts.waypointsCrossSignal = _('WaypointsCrossSignal')
            _guiTexts.waypointsCrossStation = _('WaypointsCrossStation')
            _guiTexts.waypointsTooCloseToStation = _('WaypointsTooCloseToStation')
            _guiTexts.waypointsTooFar = _('WaypointsTooFar')
            _guiTexts.waypointsTooNear = _('WaypointsTooNear')
            _guiTexts.waypointsNotConnected = _('WaypointsNotConnected')
            _guiTexts.waypointsWrong = _('WaypointsWrong')
            -- make param window resizable coz our parameters are massive
			for _, id in pairs({
				-- 'menu.construction.road.settingsWindow',
				'menu.construction.rail.settingsWindow',
				-- 'menu.construction.water.settingsWindow',
				-- 'menu.construction.air.settingsWindow',
				'menu.construction.terrain.settingsWindow',
				-- 'menu.construction.town.settingsWindow',
				-- 'menu.construction.industry.settingsWindow',
				'menu.modules.settingsWindow',
			}) do
				local iLayoutItem = api.gui.util.getById(id)
				if iLayoutItem ~= nil then
					iLayoutItem:setResizable(true)
                    iLayoutItem:setMaximumSize(api.gui.util.Size.new(800,1200))
					iLayoutItem:setIcon('ui/hammer19.tga')
				end
			end
            m_guiConConfigMenu = {
                openForConId = nil
            }
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            xpcall(
                function()
                    logger.print('### lollo_freestyle_station.handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
                    -- logger.print('args =') logger.debugPrint(args)
                    logger.print('state =') logger.debugPrint(m_state)
                    logger.print('isBusy = ' .. tostring(m_conConfigMenu.isBusy or false))
                    -- LOLLO NOTE ONLY SOMETIMES, it can crash when calling game.interface.getEntity(stationId).
                    -- Things are better now, it seems that the error came after a fast loop of calling split and raising the event, then calling split again.
                    -- That looks like a race, difficult to handle here.
                    -- For example, it crashes when using the street get info on a piece of track
                    -- the error happens when we do debugPrint(args), after removeTrack detected there was only on edge and decided to split it.
                    -- the split succeeds, then control returns here and the eggs break.
                    -- if you put debugPrint(args) inside split(), it will crash there.
                    -- if you remove it, it won't crash.

                    if name == _eventNames.HIDE_WARNINGS then
                        m_state.warningText = nil
                    elseif name == _eventNames.HIDE_PROGRESS then
                        m_state.isHideProgress = true
                    elseif name == _eventNames.ALLOW_PROGRESS then
                        m_state.isHideProgress = false
                    elseif name == _eventNames.HIDE_HOLE_REQUESTED then
                        -- LOLLO NOTE programmatically adding a depot works, but as soon as you click the depot, the game will crash
                        -- _actions.rebuildUndergroundDepotWithoutHole(args.conId)
                    elseif name == _eventNames.BULLDOZE_MARKER_REQUESTED then
                        _actions.bulldozeCon(args.platformMarkerConstructionEntityId)
                    elseif name == _eventNames.WAYPOINT_BULLDOZE_REQUESTED then
                        _actions.replaceEdgeWithSameRemovingObject(args.waypointId)
                    elseif name == _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED then
                        if not(edgeUtils.isValidAndExistingId(args.trackWaypoint1Id))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint1Id)
                        if not(edgeUtils.isValidAndExistingId(edgeId))
                        or not(api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint1Id)
                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition), false, logger.isExtendedLog())
                        if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                        _actions.splitEdgeRemovingObject(
                            edgeId,
                            nodeBetween,
                            args.trackWaypoint1Id,
                            _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED,
                            arrayUtils.cloneDeepOmittingFields(args, {'trackWaypoint1Id'}),
                            'splitTrackNode1Id'
                        )
                    elseif name == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                        if not(edgeUtils.isValidAndExistingId(args.trackWaypoint2Id))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint2Id)
                        if not(edgeUtils.isValidAndExistingId(edgeId))
                        or not(api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint2Id)
                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition), false, logger.isExtendedLog())
                        if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                        _actions.splitEdgeRemovingObject(
                            edgeId,
                            nodeBetween,
                            args.trackWaypoint2Id,
                            _eventNames.PLATFORM_WAYPOINT_1_SPLIT_REQUESTED,
                            arrayUtils.cloneDeepOmittingFields(args, {'trackWaypoint2Id'}),
                            'splitTrackNode2Id'
                        )
                    elseif name == _eventNames.PLATFORM_WAYPOINT_1_SPLIT_REQUESTED then
                        if not(edgeUtils.isValidAndExistingId(args.platformWaypoint1Id))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint1Id)
                        if not(edgeUtils.isValidAndExistingId(edgeId))
                        or not(api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint1Id)
                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition), false, false)
                        if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                        _actions.splitEdgeRemovingObject(
                            edgeId,
                            nodeBetween,
                            args.platformWaypoint1Id,
                            _eventNames.PLATFORM_WAYPOINT_2_SPLIT_REQUESTED,
                            arrayUtils.cloneDeepOmittingFields(args, {'platformWaypoint1Id'}),
                            'splitPlatformNode1Id'
                        )
                    elseif name == _eventNames.PLATFORM_WAYPOINT_2_SPLIT_REQUESTED then
                        if not(edgeUtils.isValidAndExistingId(args.platformWaypoint2Id))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint2Id)
                        if not(edgeUtils.isValidAndExistingId(edgeId))
                        or not(api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK))
                        then m_state.warningText = _('WaypointsWrong') _utils.sendHideProgress() return end

                        local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint2Id)
                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition), false, false)
                        if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                        _actions.splitEdgeRemovingObject(
                            edgeId,
                            nodeBetween,
                            args.platformWaypoint2Id,
                            _eventNames.TRACK_BULLDOZE_REQUESTED,
                            arrayUtils.cloneDeepOmittingFields(args, {'platformWaypoint2Id'}),
                            'splitPlatformNode2Id'
                        )
                    elseif name == _eventNames.TRACK_BULLDOZE_REQUESTED then
                        if args == nil
                        or not(edgeUtils.isValidAndExistingId(args.splitPlatformNode1Id))
                        or not(edgeUtils.isValidAndExistingId(args.splitPlatformNode2Id))
                        or not(edgeUtils.isValidAndExistingId(args.splitTrackNode1Id))
                        or not(edgeUtils.isValidAndExistingId(args.splitTrackNode2Id))
                        then
                            if args == nil then logger.warn('TRACK_BULLDOZE_REQUESTED got args == NIL')
                            else
                                logger.warn('TRACK_BULLDOZE_REQUESTED got some missing or invalid data; args.splitTrackNode1Id =') logger.warningDebugPrint(args.splitTrackNode1Id)
                                logger.warn('args.splitTrackNode2Id =') logger.warningDebugPrint(args.splitTrackNode2Id)
                            end
                            return
                        end

                        local trackEdgeIdsBetweenNodeIds = edgeUtils.track.getTrackEdgeIdsBetweenNodeIds(
                            args.splitTrackNode1Id,
                            args.splitTrackNode2Id,
                            _constants.maxWaypointDistance,
                            logger.isExtendedLog()
                        )
                        -- LOLLO NOTE I need this, or a station with only one track edge will dump with
                        -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                        if #trackEdgeIdsBetweenNodeIds == 0 then
                            logger.err('#trackEdgeIdsBetweenNodeIds == 0')
                            return
                        end
                        if #trackEdgeIdsBetweenNodeIds == 1 then
                            logger.print('only one track edge, going to split it')
                            local edgeId = trackEdgeIdsBetweenNodeIds[1]
                            if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                            logger.print('args.splitTrackNode1Id =') logger.debugPrint(args.splitTrackNode1Id)
                            logger.print('args.splitTrackNode2Id =') logger.debugPrint(args.splitTrackNode2Id)
                            logger.print('edgeId =') logger.debugPrint(edgeId)
                            local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
                            logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                            if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                            _actions.splitEdgeRemovingObject(
                                edgeId,
                                nodeBetween,
                                nil,
                                _eventNames.TRACK_BULLDOZE_REQUESTED,
                                arrayUtils.cloneDeepOmittingFields(args),
                                nil,
                                true
                            )
                            return
                        end
                        logger.print('at least two track edges found')

                        local platformEdgeIdsBetweenNodeIds = edgeUtils.track.getTrackEdgeIdsBetweenNodeIds(
                            args.splitPlatformNode1Id,
                            args.splitPlatformNode2Id,
                            _constants.maxWaypointDistance,
                            logger.isExtendedLog()
                        )
                        -- LOLLO NOTE I need this, or a station with only one platform edge will dump with
                        -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                        if #platformEdgeIdsBetweenNodeIds == 0 then
                            logger.err('#platformEdgeIdsBetweenNodeIds == 0')
                            return
                        end
                        if #platformEdgeIdsBetweenNodeIds == 1 then
                            logger.print('only one platform edge, going to split it')
                            local edgeId = platformEdgeIdsBetweenNodeIds[1]
                            if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                            logger.print('args.splitPlatformNode1Id =') logger.debugPrint(args.splitPlatformNode1Id)
                            logger.print('args.splitPlatformNode2Id =') logger.debugPrint(args.splitPlatformNode2Id)
                            logger.print('edgeId =') logger.debugPrint(edgeId)
                            local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
                            if nodeBetween == nil then m_state.warningText = _('WrongTrack') _utils.sendHideProgress() return end

                            _actions.splitEdgeRemovingObject(
                                edgeId,
                                nodeBetween,
                                nil,
                                _eventNames.TRACK_BULLDOZE_REQUESTED,
                                arrayUtils.cloneDeepOmittingFields(args),
                                nil,
                                true
                            )
                            return
                        end
                        logger.print('at least two platform edges found')

                        local eventArgs = arrayUtils.cloneDeepOmittingFields(args, { 'splitPlatformNode1Id', 'splitPlatformNode2Id', 'splitTrackNode1Id', 'splitTrackNode2Id', })
                        logger.print('track bulldoze requested, platformEdgeIdsBetweenNodeIds =') logger.debugPrint(platformEdgeIdsBetweenNodeIds)
                        eventArgs.platformEdgeList = stationHelpers.getEdgeIdsProperties(platformEdgeIdsBetweenNodeIds, true, false, true)
                        -- logger.print('track bulldoze requested, platformEdgeList =') logger.debugPrint(eventArgs.platformEdgeList)
                        logger.print('track bulldoze requested, trackEdgeIdsBetweenNodeIds =') logger.debugPrint(trackEdgeIdsBetweenNodeIds)
                        eventArgs.trackEdgeList = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenNodeIds, true, false, true)
                        -- logger.print('track bulldoze requested, trackEdgeList =') logger.debugPrint(eventArgs.trackEdgeList)

                        ---@param trackEdgeList table
                        ---@param getLengthAtSplit_FromTotalLength function<number>
                        ---@return integer
                        ---@return integer|nil
                        ---@return table|nil
                        local _getTrackIndex_orSplitPoint_atPosition = function(trackEdgeList, getLengthAtSplit_FromTotalLength)
                            logger.print('_getTrackMidIndex_orSplitPoint starting')
                            local totalLength = 0
                            local trackLengths = {}
                            local nTel = #trackEdgeList
                            for i = 1, nTel do
                                local tel = trackEdgeList[i]
                                -- these should be identical, but they are not really so, so we average them
                                -- local length = (transfUtils.getVectorLength(tel.posTanX2[1][2]) + transfUtils.getVectorLength(tel.posTanX2[2][2])) * 0.5
                                -- better this way:
                                local length = edgeUtils.getEdgeLength(tel.edgeId, logger.isExtendedLog())
                                if not(length) then
                                    logger.warn('cannot get edge length, trackEdgeList index = ' .. i)
                                    return -1, nil, nil
                                end
                                trackLengths[i] = length
                                totalLength = totalLength + length
                            end
                            local lengthSoFar = 0
                            -- local lengthAtSplit = totalLength * 0.5 -- older behaviour to get the midpoint only
                            local lengthAtSplit = getLengthAtSplit_FromTotalLength(totalLength)
                            logger.print('totalLength =', tostring(totalLength))
                            logger.print('lengthAtSplit =', tostring(lengthAtSplit))
                            local iAcrossSplit = -1
                            local iCloseEnoughToSplit = -1
                            for i = 1, #trackLengths do
                                local currentLength = trackLengths[i]
                                if lengthSoFar <= lengthAtSplit and lengthSoFar + currentLength >= lengthAtSplit then
                                    iAcrossSplit = i
                                    if math.abs(lengthAtSplit - lengthSoFar) < _constants.maxAbsoluteDeviation4Midpoint then
                                        iCloseEnoughToSplit = i
                                        logger.print('### tel[i] =') logger.debugPrint(trackEdgeList[i])
                                    elseif math.abs(lengthAtSplit - lengthSoFar - currentLength) < _constants.maxAbsoluteDeviation4Midpoint then
                                        --[[
                                            take this example: 2 segments, each 10 m, length AtSplit = 19
                                            the second segment will be ok and output iCloseEnoughToSplit = 3, which is out of bounds
                                            Even if we get around this somehow, the game will dislike a node at the end of a track;
                                            so we discard it, which will force a split
                                        ]]
                                        if i < nTel then
                                            iCloseEnoughToSplit = i + 1
                                            logger.print('### tel[i+1] =') logger.debugPrint(trackEdgeList[i+1])
                                        end
                                    end
                                    -- maybe I got a node already, which is close enough to the centre; 
                                    -- maybe not, but there won't be more luck going forward: leave anyway.
                                    break
                                end
                                lengthSoFar = lengthSoFar + currentLength
                            end

                            if iCloseEnoughToSplit > 0 then
                                logger.print('about to return iCloseEnoughToSplit =', tostring(iCloseEnoughToSplit))
                                return iCloseEnoughToSplit, nil, nil
                            else
                                logger.print('no track edge is close enough to the given point, going to add a split. iAcrossSplit =', iAcrossSplit)
                                if iAcrossSplit < 1 then
                                    logger.err('trouble finding a track split point')
                                    print('totalLength =') debugPrint(totalLength)
                                    print('trackLengths =') debugPrint(trackLengths)
                                    print('lengthAtSplit =') debugPrint(lengthAtSplit)
                                    print('lengthSoFar =') debugPrint(lengthSoFar)
                                    return -1, nil, nil
                                end

                                local splitEdgeId = trackEdgeIdsBetweenNodeIds[iAcrossSplit]
                                if not(edgeUtils.isValidAndExistingId(splitEdgeId)) then
                                    logger.err('invalid splitEdgeId =') logger.debugPrint(splitEdgeId)
                                    return -1, nil, nil
                                end

                                logger.print('splitEdgeId =') logger.debugPrint(splitEdgeId)
                                local position0 = transfUtils.oneTwoThree2XYZ(trackEdgeList[iAcrossSplit].posTanX2[1][1])
                                local position1 = transfUtils.oneTwoThree2XYZ(trackEdgeList[iAcrossSplit].posTanX2[2][1])
                                local tangent0 = transfUtils.oneTwoThree2XYZ(trackEdgeList[iAcrossSplit].posTanX2[1][2])
                                local tangent1 = transfUtils.oneTwoThree2XYZ(trackEdgeList[iAcrossSplit].posTanX2[2][2])
                                logger.print('position0 =') logger.debugPrint(position0)
                                logger.print('position1 =') logger.debugPrint(position1)
                                logger.print('tangent0 =') logger.debugPrint(tangent0)
                                logger.print('tangent1 =') logger.debugPrint(tangent1)
                                logger.print('(lengthAtSplit - lengthSoFar) / trackLengths[iAcrossSplit] =') logger.debugPrint((lengthAtSplit - lengthSoFar) / trackLengths[iAcrossSplit])

                                local edgeLength = edgeUtils.getEdgeLength(trackEdgeList[iAcrossSplit].edgeId, logger.isExtendedLog())
                                logger.print('split edge length =') logger.debugPrint(edgeLength)
                                if not(edgeLength) then
                                    logger.err('cannot get split edge length')
                                    return -1, nil, nil
                                end

                                local nodeBetween = edgeUtils.getNodeBetween(
                                    position0,
                                    position1,
                                    tangent0,
                                    tangent1,
                                    (lengthAtSplit - lengthSoFar) / trackLengths[iAcrossSplit],
                                    edgeLength,
                                    logger.isExtendedLog()
                                )
                                logger.print('nodeBetween around track split =') logger.debugPrint(nodeBetween)
                                if nodeBetween == nil then
                                    logger.warn('cannot get nodeBetween around track split')
                                    return -1, nil, nil
                                end
                                -- LOLLO NOTE it seems fixed, but keep checking it:
                                -- this can screw up the directions. It happens on tracks where slope varies, ie tan0.z ~= tan1.z
                                -- in these cases, split produces something like:
                                -- node0 = 26197,
                                -- node0pos = { 972.18054199219, 596.27990722656, 12.010199546814, },
                                -- node0tangent = { 35.427974700928, 26.778322219849, -2.9104161262512, },
                                -- node1 = 26348,
                                -- node1pos = { 1007.6336669922, 623.07720947266, 9.3951835632324, },
                                -- node1tangent = { -35.457813262939, -26.800853729248, 2.2689030170441, },
                                return -1, splitEdgeId, nodeBetween
                            end
                        end
                        local trackEdgeListMidIndex, midEdgeId, midNodeBetween = _getTrackIndex_orSplitPoint_atPosition(
                            eventArgs.trackEdgeList,
                            function(totalLength) return totalLength * 0.5 end
                        )
                        if trackEdgeListMidIndex < 1 then
                            if midEdgeId ~= nil and midNodeBetween ~= nil then
                                logger.print('about to split the centre of the track')
                                _actions.splitEdgeRemovingObject(
                                    midEdgeId,
                                    midNodeBetween,
                                    nil,
                                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                                    arrayUtils.cloneDeepOmittingFields(args),
                                    nil,
                                    true
                                )
                            else
                                logger.err('cannot find the centre of the track and cannot split it; midEdgeId =', tostring(midEdgeId), 'midNodeBetween =') logger.errorDebugPrint(midNodeBetween)
                                m_state.warningText = _('WrongTrack')
                                _utils.sendHideProgress()
                            end
                            return
                        end
                        -- this might become the vehicle node, ie where the trains stop with their belly
                        eventArgs.trackEdgeListMidIndex = trackEdgeListMidIndex
                        -- logger.print('eventArgs.trackEdgeListMidIndex =') logger.debugPrint(eventArgs.trackEdgeListMidIndex)
                        -- logger.print('eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex] =') logger.debugPrint(eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex])

                        local trackEdgeListVehicleNode0Index, vehicleNode0EdgeId, vehicleNode0NodeBetween = _getTrackIndex_orSplitPoint_atPosition(
                            eventArgs.trackEdgeList,
                            function(totalLength) return (args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength) end
                        )
                        if trackEdgeListVehicleNode0Index < 1 then
                            if vehicleNode0EdgeId ~= nil and vehicleNode0NodeBetween ~= nil then
                                logger.print('about to split the beginning of the track')
                                _actions.splitEdgeRemovingObject(
                                    vehicleNode0EdgeId,
                                    vehicleNode0NodeBetween,
                                    nil,
                                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                                    arrayUtils.cloneDeepOmittingFields(args),
                                    nil,
                                    true
                                )
                            else
                                logger.err('cannot find the beginning of the track and cannot split it; vehicleNode0EdgeId =', tostring(vehicleNode0EdgeId), 'vehicleNode0NodeBetween =') logger.errorDebugPrint(vehicleNode0NodeBetween)
                                m_state.warningText = _('WrongTrack')
                                _utils.sendHideProgress()
                            end
                            return
                        end
                        -- this might become the vehicle node, ie where the trains stop with their belly
                        eventArgs.trackEdgeListVehicleNode0Index = trackEdgeListVehicleNode0Index

                        local trackEdgeListVehicleNode1Index, vehicleNode1EdgeId, vehicleNode1NodeBetween = _getTrackIndex_orSplitPoint_atPosition(
                            eventArgs.trackEdgeList,
                            function(totalLength) return (args.isCargo and (totalLength - _constants.maxCargoWaitingAreaEdgeLength) or (totalLength - _constants.maxPassengerWaitingAreaEdgeLength)) end
                        )
                        if trackEdgeListVehicleNode1Index < 1 then
                            if vehicleNode1EdgeId ~= nil and vehicleNode1NodeBetween ~= nil then
                                logger.print('about to split the end of the track')
                                _actions.splitEdgeRemovingObject(
                                    vehicleNode1EdgeId,
                                    vehicleNode1NodeBetween,
                                    nil,
                                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                                    arrayUtils.cloneDeepOmittingFields(args),
                                    nil,
                                    true
                                )
                            else
                                logger.err('cannot find the end of the track and cannot split it; vehicleNode1EdgeId =', tostring(vehicleNode1EdgeId), 'vehicleNode1NodeBetween =') logger.errorDebugPrint(vehicleNode1NodeBetween)
                                m_state.warningText = _('WrongTrack')
                                _utils.sendHideProgress()
                            end
                            return
                        end
                        -- this might become the vehicle node, ie where the trains stop with their belly
                        eventArgs.trackEdgeListVehicleNode1Index = trackEdgeListVehicleNode1Index

                        -- reverse track and platform edges if the platform is on the right of the track.
                        -- this will make trains open their doors on the correct side.
                        -- Remember that "left" and "right" are just conventions here, there is no actual left and right.
                        local _reverseScrambledTracksAndPlatforms = function()
                            local isTrackOnPlatformLeft = stationHelpers.getIsTrackAlongPlatformLeft(
                                eventArgs.platformEdgeList,
                                eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex]
                            )
                            if isTrackOnPlatformLeft then
                                return true
                            else
                                logger.print('_reverseScrambledTracksAndPlatforms started, eventArgs.trackEdgeListMidIndex before =', eventArgs.trackEdgeListMidIndex)
                                -- back up vehicle node indexes before reversing platforms and tracks
                                if logger.isExtendedLog() then
                                    print('#eventArgs.trackEdgeList =', tostring(#eventArgs.trackEdgeList))
                                    print('eventArgs.trackEdgeListMidIndex =', tostring(eventArgs.trackEdgeListMidIndex))
                                    print('eventArgs.trackEdgeListVehicleNode0Index =', tostring(eventArgs.trackEdgeListVehicleNode0Index))
                                    print('eventArgs.trackEdgeListVehicleNode1Index =', tostring(eventArgs.trackEdgeListVehicleNode1Index))
                                end
                                local _midPos1 = arrayUtils.cloneDeepOmittingFields(eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex].posTanX2[1][1])
                                local _vehicleNode0Pos1 = arrayUtils.cloneDeepOmittingFields(eventArgs.trackEdgeList[eventArgs.trackEdgeListVehicleNode0Index].posTanX2[1][1])
                                local _vehicleNode1Pos1 = arrayUtils.cloneDeepOmittingFields(eventArgs.trackEdgeList[eventArgs.trackEdgeListVehicleNode1Index].posTanX2[1][1])

                                -- logger.print('reversing platformEdgeList, platformEdgeList =') --logger.debugPrint(eventArgs.platformEdgeList)
                                eventArgs.platformEdgeList = stationHelpers.reversePosTanX2ListInPlace(eventArgs.platformEdgeList)
                                -- logger.print('reversed platformEdgeList, platformEdgeList =') logger.debugPrint(eventArgs.platformEdgeList)
                                -- logger.print('reversing trackEdgeList, trackEdgeList =') --logger.debugPrint(eventArgs.trackEdgeList)
                                eventArgs.trackEdgeList = stationHelpers.reversePosTanX2ListInPlace(eventArgs.trackEdgeList)
                                -- logger.print('reversed trackEdgeList, trackEdgeList =') logger.debugPrint(eventArgs.trackEdgeList)

                                -- this seems logical, but it's wrong
                                -- eventArgs.trackEdgeListMidIndex = #eventArgs.trackEdgeList - eventArgs.trackEdgeListMidIndex + 1
                                -- logger.print('eventArgs.trackEdgeListMidIndex is now ', eventArgs.trackEdgeListMidIndex)

                                -- this is dumb but safe
                                -- not the centre but the first of the two (nodes in the edge) is going to be my vehicleNode
                                local isMidNodeFound = false
                                for i = 1, #eventArgs.trackEdgeList do
                                    if comparisonUtils.is123sSame(eventArgs.trackEdgeList[i].posTanX2[1][1], _midPos1) then
                                        eventArgs.trackEdgeListMidIndex = i
                                        isMidNodeFound = true
                                        logger.print('trackEdgeListMidIndex found, new value =', i)
                                        break
                                    end
                                end
                                if not(isMidNodeFound) then logger.warn('_reverseScrambledTracksAndPlatforms could not find the mid node') end
                                logger.print('eventArgs.trackEdgeListMidIndex is adjusted to ', eventArgs.trackEdgeListMidIndex)

                                local isVehicleNode0Found = false
                                for i = 1, #eventArgs.trackEdgeList do
                                    if comparisonUtils.is123sSame(eventArgs.trackEdgeList[i].posTanX2[1][1], _vehicleNode0Pos1) then
                                        eventArgs.trackEdgeListVehicleNode0Index = i
                                        isVehicleNode0Found = true
                                        logger.print('trackEdgeListVehicleNode0Index found, new value =', i)
                                        break
                                    end
                                end
                                if not(isVehicleNode0Found) then logger.warn('_reverseScrambledTracksAndPlatforms could not find vehicle node 0') end
                                logger.print('eventArgs.trackEdgeListVehicleNode0Index is adjusted to ', eventArgs.trackEdgeListVehicleNode0Index)

                                local isVehicleNode1Found = false
                                for i = 1, #eventArgs.trackEdgeList do
                                    if comparisonUtils.is123sSame(eventArgs.trackEdgeList[i].posTanX2[1][1], _vehicleNode1Pos1) then
                                        eventArgs.trackEdgeListVehicleNode1Index = i
                                        isVehicleNode1Found = true
                                        logger.print('trackEdgeListVehicleNode1Index found, new value =', i)
                                        break
                                    end
                                end
                                if not(isVehicleNode1Found) then logger.warn('_reverseScrambledTracksAndPlatforms could not find vehicle node 1') end
                                logger.print('eventArgs.trackEdgeListVehicleNode1Index is adjusted to ', eventArgs.trackEdgeListVehicleNode1Index)

                                -- now we try again
                                local result = stationHelpers.getIsTrackAlongPlatformLeft(
                                    eventArgs.platformEdgeList,
                                    eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex]
                                )
                                if not(result) then logger.warn('_reverseScrambledTracksAndPlatforms could not reverse') end

                                return result
                            end
                        end
                        local isTrackOnPlatformLeft = _reverseScrambledTracksAndPlatforms()

                        local isTrackNWOfPlatform = stationHelpers.getIsTrackNorthOfPlatform(eventArgs.platformEdgeList, eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex])
                        logger.print('isTrackOnPlatformLeft, isTrackNWOfPlatform', isTrackOnPlatformLeft, isTrackNWOfPlatform)

                        local _trySetPlatformProps = function(platformEdgeList_notOrientated)
                            -- instead of basing these numbers on the edges, we base them on absolute distances as of minor version 81.
                            -- The result is much neater, irrespective of how the user placed the edges.
                            -- There is an accuracy price to pay detecting if we are on a bridge or a tunnel, as large as _constants.fineSegmentLength
                            -- There is also less data in centrePlatformsFine.
                            -- print('platformEdgeList_notOrientated =') debugPrint(platformEdgeList_notOrientated)
                            logger.print('_setPlatformProps starting')
                            -- this name is for compatibility with older versions. Otherwise, I would choose a different name,
                            -- since we have two "isTrackOnPlatformLeft" with different meanings.
                            -- This comes with version 1.81, which adds the orientation
                            if isTrackNWOfPlatform then
                                eventArgs.isTrackOnPlatformLeft = isTrackOnPlatformLeft
                            else
                                eventArgs.isTrackOnPlatformLeft = not(isTrackOnPlatformLeft)
                            end

                            local platformEdgeList_orientated = isTrackNWOfPlatform
                                and arrayUtils.cloneDeepOmittingFields(platformEdgeList_notOrientated)
                                or stationHelpers.reversePosTanX2ListInPlace(arrayUtils.cloneDeepOmittingFields(platformEdgeList_notOrientated))

                            eventArgs.centrePlatformsFine = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(
                                platformEdgeList_orientated,
                                _constants.fineSegmentLength,
                                false,
                                true
                            )
                            logger.print('_setPlatformProps set eventArgs.centrePlatformsFine =') logger.debugPrint(eventArgs.centrePlatformsFine)
                            if #eventArgs.centrePlatformsFine < 1 then return false end

                            eventArgs.centrePlatforms = stationHelpers.calcCentralEdgePositions_GroupByMultiple(
                                eventArgs.centrePlatformsFine,
                                args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                                true,
                                true
                            )
                            logger.print('_setPlatformProps set eventArgs.centrePlatforms =') logger.debugPrint(eventArgs.centrePlatforms)
                            if #eventArgs.centrePlatforms < 1 then return false end

                            local midCentrePlatformItem = eventArgs.centrePlatforms[math.ceil(#eventArgs.centrePlatforms / 2)]
                            logger.print('_setPlatformProps found midCentrePlatformItem =') logger.debugPrint(midCentrePlatformItem)
                            local platformWidth = midCentrePlatformItem.width
                            eventArgs.leftPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, platformWidth * 0.45)
                            eventArgs.rightPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, -platformWidth * 0.45)

                            logger.print('_setPlatformProps found platformWidth =', platformWidth)

                            -- add cross connectors
                            eventArgs.crossConnectors = stationHelpers.getCrossConnectors(
                                eventArgs.leftPlatforms,
                                eventArgs.centrePlatforms,
                                eventArgs.rightPlatforms,
                                eventArgs.isTrackOnPlatformLeft
                            )

                            -- add cargo waiting areas
                            if args.isCargo then
                                -- LOLLO TODO MAYBE there may be platforms of different widths: set the waiting areas individually.
                                -- For now, I forbid using platforms of different widths in a station, if any of them is > 5.
                                -- This way, we don't disturb the passenger station, which hasn't got this problem coz it always has the same lanes.
                                -- We don't want to disturb it coz 2.5 m platforms have problems with bridges and tunnels, in the game.
                                if platformWidth <= 5 then
                                    eventArgs.cargoWaitingAreas = {
                                        eventArgs.centrePlatforms
                                    }
                                    -- eventArgs.crossConnectors = stationHelpers.getCrossConnectors(eventArgs.leftPlatforms, eventArgs.centrePlatforms, eventArgs.rightPlatforms, eventArgs.isTrackOnPlatformLeft)
                                elseif platformWidth <= 10 then
                                    eventArgs.cargoWaitingAreas = {
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - 2.5),
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, 2.5)
                                    }
                                    -- eventArgs.crossConnectors = stationHelpers.getCrossConnectors(eventArgs.cargoWaitingAreas[1], eventArgs.centrePlatforms, eventArgs.cargoWaitingAreas[2], eventArgs.isTrackOnPlatformLeft)
                                elseif platformWidth <= 15 then
                                    eventArgs.cargoWaitingAreas = {
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - 5),
                                        eventArgs.centrePlatforms,
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, 5)
                                    }
                                    -- eventArgs.crossConnectors = stationHelpers.getCrossConnectors(eventArgs.cargoWaitingAreas[1], eventArgs.centrePlatforms, eventArgs.cargoWaitingAreas[3], eventArgs.isTrackOnPlatformLeft)
                                else
                                    eventArgs.cargoWaitingAreas = {
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - 7.5),
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - 2.5),
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, 2.5),
                                        stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, 7.5)
                                    }
                                    -- eventArgs.crossConnectors = stationHelpers.getCrossConnectors(eventArgs.cargoWaitingAreas[1], eventArgs.centrePlatforms, eventArgs.cargoWaitingAreas[4], eventArgs.isTrackOnPlatformLeft)
                                end
                            else
                                eventArgs.cargoWaitingAreas = {}
                            end

                            return true
                        end
                        if not(_trySetPlatformProps(eventArgs.platformEdgeList)) then
                            logger.err('cannot set platform props')
                            return
                        end

                        local _trySetTrackProps = function(trackEdgeList_notOrientated)
                            -- This is as new as Feb 2023
                            logger.print('_setTrackProps starting')

                            local trackEdgeList_orientated = isTrackNWOfPlatform
                            and arrayUtils.cloneDeepOmittingFields(trackEdgeList_notOrientated)
                            or stationHelpers.reversePosTanX2ListInPlace(arrayUtils.cloneDeepOmittingFields(trackEdgeList_notOrientated))

                            eventArgs.centreTracksFine = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(
                                trackEdgeList_orientated,
                                _constants.fineSegmentLength,
                                false,
                                false
                            )
                            logger.print('_setTrackProps set eventArgs.centreTracksFine =') logger.debugPrint(eventArgs.centreTracksFine)
                            if #eventArgs.centreTracksFine < 1 then return false end

                            eventArgs.centreTracks = stationHelpers.calcCentralEdgePositions_GroupByMultiple(
                                eventArgs.centreTracksFine,
                                args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                                false,
                                false
                            )
                            logger.print('_setTrackProps set eventArgs.centreTracks =') logger.debugPrint(eventArgs.centreTracks)
                            if #eventArgs.centreTracks < 1 then return false end

                            -- local midCentreTrackItem = eventArgs.centreTracks[math.ceil(#eventArgs.centreTracks / 2)]
                            -- logger.print('_setTrackProps found midCentreTrackItem =') logger.debugPrint(midCentreTrackItem)
                            -- local trackWidth = midCentreTrackItem.width  -- LOLLO NOTE this is constant in the game but it might change one day, so we still read it.
                            -- eventArgs.leftTracks = stationHelpers.getShiftedEdgePositions(eventArgs.centreTracks, trackWidth * 0.45)
                            -- eventArgs.rightTracks = stationHelpers.getShiftedEdgePositions(eventArgs.centreTracks, -trackWidth * 0.45)

                            return true
                        end
                        if not(_trySetTrackProps(eventArgs.trackEdgeList)) then
                            logger.err('cannot set track props')
                            return
                        end

                        eventArgs.nTerminal = 1
                        if edgeUtils.isValidAndExistingId(eventArgs.join2StationConId) then
                            local con = api.engine.getComponent(eventArgs.join2StationConId, api.type.ComponentType.CONSTRUCTION)
                            if con ~= nil then
                                logger.print('joining an existing station, conId = eventArgs.join2StationConId')
                                eventArgs.nTerminal = #con.params.terminals + 1
                                eventArgs.trackEndEntities = stationHelpers.getStationTrackEndEntities(eventArgs.join2StationConId)
                                eventArgs.streetEndEntities = stationHelpers.getStationStreetEndEntities(eventArgs.join2StationConId)
                            end
                        end
                        logger.print('eventArgs.nTerminal =', eventArgs.nTerminal)

                        eventArgs.newTerminalNeighbours = {
                            tracks = _utils.getNeighbours(eventArgs.trackEdgeList),
                            platforms = _utils.getNeighbours(eventArgs.platformEdgeList)
                        }

                        _actions.removeNeighbours(_eventNames.BUILD_STATION_REQUESTED, eventArgs)
                    elseif name == _eventNames.BUILD_STATION_REQUESTED then
                        _actions.buildStation(_eventNames.REBUILD_NEIGHBOURS_ALL, args)
                    elseif name == _eventNames.REBUILD_NEIGHBOURS_ALL then
                        _actions.rebuildNeighbourEdges(args)
                        if type(args.nRemainingTerminals) == 'number' and args.nRemainingTerminals < 1 then
                            -- two process running at the same time, it's all right coz they are independent
                            logger.print('_rebuildNeighbourEdges running, no more terminals left, about to bulldoze the station')
                            _utils.sendHideProgress()
                            _actions.bulldozeConstruction(args.stationConstructionId)
                        end
                    elseif name == _eventNames.REBUILD_NEIGHBOUR_CONS then
                        _actions.rebuildNeighbourCons(args)
                    elseif name == _eventNames.UPGRADE_NEIGHBOUR_CONS then
                        _actions.upgradeNeighbourCons(args)
                    elseif name == _eventNames.BULLDOZE_STATION_REQUESTED then
                        _utils.sendHideProgress()
                        _actions.bulldozeConstruction(args.stationConstructionId)
                    elseif name == _eventNames.SUBWAY_JOIN_REQUESTED then
                        if m_conConfigMenu.isBusy then return end

                        m_conConfigMenu.isBusy = true
                        if not(edgeUtils.isValidAndExistingId(args.join2StationConId)) then
                            logger.err('SUBWAY_JOIN_REQUESTED got args.join2StationConId is invalid')
                            _utils.sendHideProgress()
                            return
                        end
                        if not(edgeUtils.isValidAndExistingId(args.subwayConstructionId)) then
                            logger.err('SUBWAY_JOIN_REQUESTED got args.subwayConstructionId is invalid')
                            _utils.sendHideProgress()
                            return
                        end

                        logger.print('subway joining an existing station, conId = eventArgs.join2StationConId')
                        args.trackEndEntities = stationHelpers.getStationTrackEndEntities(args.join2StationConId)
                        args.streetEndEntities = stationHelpers.getStationStreetEndEntities(args.join2StationConId)
                        _actions.removeNeighbours(_eventNames.SUBWAY_BUILD, args)
                    elseif name == _eventNames.SUBWAY_BUILD then
                        _actions.addSubway(_eventNames.REBUILD_NEIGHBOURS_ALL, args)
                    elseif name == _eventNames.TRACK_SPLIT_REQUESTED then
                        if args ~= nil and args.conId ~= nil then
                            if edgeUtils.isValidAndExistingId(args.conId) then
                                local conTransf = api.engine.getComponent(args.conId, api.type.ComponentType.CONSTRUCTION).transf
                                conTransf = transfUtilsUG.new(conTransf:cols(0), conTransf:cols(1), conTransf:cols(2), conTransf:cols(3))
                                logger.print('type(conTransf) =', type(conTransf)) logger.debugPrint(conTransf)
                                local nearestEdgeId = edgeUtils.track.getNearestEdgeIdStrict(
                                    conTransf,
                                    conTransf[15] + _constants.splitterZShift - _constants.splitterZToleranceM,
                                    conTransf[15] + _constants.splitterZShift + _constants.splitterZToleranceM
                                )
                                logger.print('track splitter got nearestEdge =', nearestEdgeId or 'NIL')
                                if edgeUtils.isValidAndExistingId(nearestEdgeId) and not(edgeUtils.isEdgeFrozen(nearestEdgeId)) then
                                    local averageZ = _utils.getAverageZ(nearestEdgeId)
                                    logger.print('averageZ =', averageZ or 'NIL')
                                    if type(averageZ) == 'number' then
                                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                                            nearestEdgeId,
                                            {
                                                x = conTransf[13],
                                                y = conTransf[14],
                                                z = averageZ,
                                            },
                                            true,
                                            logger.isExtendedLog()
                                        )
                                        logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                                        if nodeBetween == nil then return end

                                        _actions.splitEdgeRemovingObject(
                                            nearestEdgeId,
                                            nodeBetween,
                                            nil,
                                            nil,
                                            nil,
                                            nil,
                                            true
                                        )
                                    end
                                    -- this is a little more accurate, but it's also harder to use with tunnels and bridges.
                                    -- a user error can throw it out of whack more than the averageZ does.
                                    -- local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                                    --     nearestEdgeId,
                                    --     {
                                    --         x = conTransf[13],
                                    --         y = conTransf[14],
                                    --         z = conTransf[15] + _constants.splitterZShift,
                                    --     },
                                    --     true,
                                    --     logger.isExtendedLog()
                                    -- )
                                    -- logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                                    -- if nodeBetween == nil then return end
                                    --
                                    -- _actions.splitEdgeRemovingObject(
                                    --     nearestEdgeId,
                                    --     nodeBetween,
                                    --     nil,
                                    --     nil,
                                    --     nil,
                                    --     nil,
                                    --     true
                                    -- )
                                end
                            end
                            _actions.bulldozeConstruction(args.conId)
                        end
                    -- elseif name == _eventNames.BUILD_SNAPPY_STREET_EDGES_REQUESTED then
                    --     if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                    --         logger.err('args.stationConstructionId not valid')
                    --         return
                    --     end
                    --     local con = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
                    --     if con == nil or type(con.fileName) ~= 'string' or con.fileName ~= _constants.stationConFileName or con.params == nil or #con.params.terminals < 1 then
                    --         logger.err('construction', args.stationConstructionId, 'is not a freestyle station, I cannot build its snappy street edges')
                    --         return
                    --     end
                    --     _actions.buildSnappyStreetEdges(args.stationConstructionId)
                    elseif name == _eventNames.CON_CONFIG_MENU_OPENED then
                        if m_conConfigMenu.isBusy then return end -- do not overwrite conConfigMenu.args

                        -- make a note of the neighbours before the edge modules are replaced with fakes
                        -- Save these into the state? It would be slow but help if there is a crash during config
                        -- Not really, it should be enough to restart the game, open the config, then close it for the fake modules to go away
                        m_conConfigMenu.isOpen = false
                        m_conConfigMenu.args = arrayUtils.cloneDeepOmittingFields(args)
                        m_conConfigMenu.isOpen = true
                        logger.print('conConfigMenu.args.stationConstructionId =') logger.debugPrint(m_conConfigMenu.args.stationConstructionId)
                        logger.print('conConfigMenu.args.streetEndEntities =') logger.debugPrint(m_conConfigMenu.args.streetEndEntities)
                        logger.print('conConfigMenu.args.trackEndEntities =') logger.debugPrint(m_conConfigMenu.args.trackEndEntities)
                    elseif name == _eventNames.CON_CONFIG_MENU_CLOSED then
                        if m_conConfigMenu.isBusy then return end

                        if not(m_conConfigMenu.isOpen) then _utils.sendHideProgress() return end
                        m_conConfigMenu.isBusy = true

                        if args.stationConstructionId ~= m_conConfigMenu.args.stationConstructionId then _utils.sendHideProgress() return end
                        if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then _utils.sendHideProgress() return end
                        local con = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
                        if con == nil then _utils.sendHideProgress() return end

                        -- if no fake edges are present and no terminals were removed,
                        -- there is no need to destroy the neighbours, rebuild the station and rebuild the neighbours.
                        local conParams = con.params
                        local isFakeEdgesPresent, _ = _utils.replaceFakeEdgesWithSnappy(arrayUtils.cloneDeepOmittingFields(conParams.modules, nil, true))
                        local nTerminalsToRemove = _utils.getNTerminalsToRemove(conParams)
                        if not(isFakeEdgesPresent) and #nTerminalsToRemove == 0 then _utils.sendHideProgress() return end

                        args.streetEndEntities = m_conConfigMenu.args.streetEndEntities
                        args.trackEndEntities = m_conConfigMenu.args.trackEndEntities
                        args.nTerminalsToRemove = nTerminalsToRemove

                        _actions.removeNeighbours(_eventNames.REBUILD_STATION_WITH_LATEST_PROPERTIES, args)
                    elseif name == _eventNames.REBUILD_STATION_WITH_LATEST_PROPERTIES then
                        logger.print('REBUILD_STATION_WITH_LATEST_PROPERTIES fired, args =') logger.debugPrint(args)
                        if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                            logger.err('REBUILD_STATION_WITH_LATEST_PROPERTIES got an invalid args.stationConstructionId')
                            _utils.sendHideProgress()
                            return
                        end

                        local con = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
                        if con == nil or con.fileName ~= _constants.stationConFileName then
                            logger.err('REBUILD_STATION_WITH_LATEST_PROPERTIES found no station or a non-freestyle station')
                            _utils.sendHideProgress()
                            return
                        end

                        _actions.rebuildStationWithLatestProperties(
                            con,
                            _eventNames.REBUILD_NEIGHBOURS_ALL,
                            args
                        )
                    elseif name == _eventNames.SPLITTER_WAYPOINT_PLACED then
                        if not(edgeUtils.isValidAndExistingId(args.splitterWaypointId)) then return end

                        local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.splitterWaypointId)
                        if not(edgeUtils.isValidAndExistingId(edgeId)) or edgeUtils.isEdgeFrozen(edgeId) then return end

                        local waypointPosition = edgeUtils.getObjectPosition(args.splitterWaypointId)
                        local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition), false, logger.isExtendedLog())

                        _actions.splitEdgeRemovingObject(
                            edgeId,
                            nodeBetween,
                            args.splitterWaypointId,
                            nil, nil, nil, true
                        )
                    end
                end,
                function(error)
                    _utils.sendHideProgress()
                    logger.xpErrorHandler(error)
                    m_state.warningText = error
                end
            )
        end,
        guiHandleEvent = function(id, name, args)
            --[[
                sample output after removing a module:
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.addModuleComp	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	temp.addModuleComp.params.entity_22997	name =	destroy
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.moduleBulldozer	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.lineManager	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.vehicleManager	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.road	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.rail	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.water	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.air	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.terrain	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.town	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.industry	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction	name =	visibilityChange
                after adding an element:
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.addModuleComp	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	temp.addModuleComp.params.entity_22997	name =	destroy
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.moduleBulldozer	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.lineManager	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.vehicleManager	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.road	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.rail	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.water	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.air	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.terrain	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.town	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction.industry	name =	visibilityChange
                lollo_freestyle_train_station INFO: 	guiHandleEvent caught id =	menu.construction	name =	visibilityChange
                the results are the same, they only fire after closing the menu
                22997 is the conId of my station construction
            ]]
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            -- logger.print('guiHandleEvent caught id =', id, 'name =', name)
            local isHideDistance = true
            -- if (name == 'builder.proposalCreate' or name == 'builder.apply' or name == 'select' or name == 'destroy' or name == 'idAdded' or name == 'button.click') then -- for performance
                xpcall(
                    function()
                        if name == 'builder.proposalCreate' then
                            -- logger.print('name == builder.proposalCreate, id = ' .. (id or 'NIL') .. ', args.data = ') logger.debugPrint(args and args.data)
                            if id == 'streetTerminalBuilder' then
                                -- waypoint, traffic light, my own waypoints built
                                if args and args.proposal and args.proposal.proposal
                                and args.proposal.proposal.edgeObjectsToAdd
                                and args.proposal.proposal.edgeObjectsToAdd[1]
                                and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                                then
                                    if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiPlatformWaypointModelId then
                                        isHideDistance = not(_guiActions.tryShowDistance(
                                            _guiPlatformWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf,
                                            true
                                        ))
                                    elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiTrackWaypointModelId then
                                        isHideDistance = not(_guiActions.tryShowDistance(
                                            _guiTrackWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf,
                                            false
                                        ))
                                    end
                                end
                            end
                        elseif name == 'builder.apply' then
                            guiHelpers.hideWarningWithGoTo()
                            guiHelpers.hideWarning(
                                _utils.sendHideWarnings
                            )
                            -- logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                            if id == 'bulldozer' then -- we don't catch the bulldozer anymore coz it interferes with something, probably preProcessFn.
                                -- instead, I change things when the con config menu is closed.
                            elseif id == 'constructionBuilder' then
                                if not args or not args.result or not args.result[1] then return end

                                -- logger.print('args =') logger.debugPrint(args)
                                local conId = args.result[1]
                                local con = _guiActions.getCon(conId)
                                -- logger.print('construction built, construction id =') logger.debugPrint(conId)
                                if not(con) then return end

                                if con.fileName == 'station/rail/lollo_freestyle_train_station/track_splitter.con'
                                and con.transf ~= nil
                                then
                                    api.cmd.sendCommand(
                                        api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.TRACK_SPLIT_REQUESTED,
                                            { conId = conId }
                                        )
                                    )
                                -- elseif con.fileName == _constants.undergroundDepotConFileName
                                -- and con.transf ~= nil
                                -- then
                                --     api.cmd.sendCommand(
                                --         api.cmd.make.sendScriptEvent(
                                --             string.sub(debug.getinfo(1, 'S').source, 1),
                                --             _eventId,
                                --             _eventNames.HIDE_HOLE_REQUESTED,
                                --             { conId = conId }
                                --         )
                                --     )
                                else
                                    _guiActions.tryJoinSubway(conId, con)
                                end
                            elseif id == 'streetTerminalBuilder' then
                                -- waypoint, traffic light, my own waypoints built
                                if args and args.proposal and args.proposal.proposal
                                and args.proposal.proposal.edgeObjectsToAdd
                                and args.proposal.proposal.edgeObjectsToAdd[1]
                                and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                                then
                                    -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                    if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiPlatformWaypointModelId then
                                        local waypointData = _guiActions.validateWaypointBuilt(
                                            _guiPlatformWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                            args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                            args.proposal.proposal.addedSegments[1].trackEdge.trackType,
                                            true
                                        )
                                        logger.print('platformWaypointData =') logger.debugPrint(waypointData)
                                        if not(waypointData) then return end

                                        _guiActions.handleValidWaypointBuilt()

                                        -- if any platform nodes are joints between more than 2 platform-tracks,
                                        -- we bar building two platform waypoints outside a junction.
                                        -- Or maybe, we could bar intersecting platform-tracks altogether:
                                        -- they look mighty ugly. Maybe someone knows how to fix their looks? ask UG TODO

                                    elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiTrackWaypointModelId then
                                        local waypointData = _guiActions.validateWaypointBuilt(
                                            _guiTrackWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                            args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                            args.proposal.proposal.addedSegments[1].trackEdge.trackType,
                                            false
                                        )
                                        logger.print('trackWaypointData =') logger.debugPrint(waypointData)
                                        if not(waypointData) then return end

                                        _guiActions.handleValidWaypointBuilt()

                                    elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiSplitterWaypointModelId then
                                        _guiActions.handleSplitterWaypointBuilt()
                                    end
                                end
                            end
                        elseif name == 'select' then
                            -- LOLLO TODO MAYBE same with stations. Maybe one day.
                            logger.print('LOLLO caught gui select, id = ', id, ' name = ', name, ' args = ')
                            logger.debugPrint(args)

                            local con = _guiActions.getCon(args) -- if a construction is selected, args is conId
                            if con ~= nil then
                                _guiActions.tryJoinSubway(args, con)
                                return
                            else
                                local modelId = edgeUtils.getEdgeObjectModelId(args)-- if a waypoint is selected, args is waypointId
                                if modelId == _guiPlatformWaypointModelId or modelId == _guiTrackWaypointModelId then
                                    local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args)
                                    if edgeUtils.isValidAndExistingId(edgeId) then
                                        local trackEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                                        if trackEdge ~= nil and edgeUtils.isValidId(trackEdge.trackType) then
                                            local waypointData = _guiActions.validateWaypointBuilt(
                                                modelId,
                                                args,
                                                edgeId,
                                                trackEdge.trackType,
                                                modelId == _guiPlatformWaypointModelId
                                            )
                                            logger.print('trackWaypointData =') logger.debugPrint(waypointData)
                                            if waypointData then
                                                _guiActions.handleValidWaypointBuilt()
                                                return
                                            end
                                        end
                                    end
                                    guiHelpers.showWarningWithGoto(_guiTexts.waypointsWrong, args)
                                    return
                                end
                            end
                        elseif name == 'idAdded' and type(id) == 'string' and stringUtils.stringStartsWith(id, 'temp.addModuleComp.params.entity_') then
                            -- temp.addModuleComp.params.entity_31084	name =	idAdded when opening the con config menu, 31084 is the station conId
                            -- temp.addModuleComp.params.entity_31084	name =	destroy when closing the con config menu, 31084 is the station conId
                            -- id = bulldozer	name =	builder.apply fires when the user destroys a module
                            -- no way to tell when the user adds a module

                            -- To prevent collisions, whenever the user opens OR closes the con config menu,
                            -- I could make street edges with adjoining neighbours snappy and the other non-snappy
                            -- If unattached edges are snappy, they will try to snap to their neighbours and throw pointless errors;
                            -- UG TODO these errors are pointless because snapping is automatic, so it should be tolerant
                            -- If attached edges are non-snappy, the game will throw collision errors whenever the user attempts to change the con config
                            -- UG TODO this is wrong, too.
                            -- Both solutions have pros and cons, so preProcessFn() radically remove street edges and replaces them with fakes.
                            -- When the user opens the con config menu, before anything is removed, I write away the neighbours
                            -- When the user shuts the con config menu, I replace the fake edge modules with real edge modules,
                            -- snappy so to avoid the collision warning.
                            -- This way, I get no collisions and no snapping attempts when the con config menu is open.

                            local conId = tonumber(id:sub(34), 10)
                            if not(edgeUtils.isValidAndExistingId(conId)) then return end

                            -- LOLLO TODO if the user has changed a platform height, neighbouring streets and cons will have the wrong height
                            -- and so they won't match anymore: fix it
                            -- This is not easy because there is no way to associate frozen edges to terminals,
                            -- 
                            local streetEndEntities = stationHelpers.getStationStreetEndEntities(conId, true)
                            local trackEndEntities = stationHelpers.getStationTrackEndEntities(conId, true)
                            if not(streetEndEntities) or not(trackEndEntities) then return end

                            m_guiConConfigMenu.openForConId = conId
                            logger.print('the con config menu was opened, about to send command CON_CONFIG_MENU_OPENED, conId = ' .. conId)
                            api.cmd.sendCommand(api.cmd.make.setGameSpeed(0)) -- pause the game when config menu opens
                            api.cmd.sendCommand(
                                api.cmd.make.sendScriptEvent(
                                    string.sub(debug.getinfo(1, 'S').source, 1),
                                    _eventId,
                                    _eventNames.CON_CONFIG_MENU_OPENED,
                                    {
                                        stationConstructionId = conId,
                                        -- lock the UI thread and write these away before preProcessFn() kicks in
                                        streetEndEntities = streetEndEntities,
                                        trackEndEntities = trackEndEntities,
                                    }
                                )
                            )
                        elseif name == 'destroy' and type(id) == 'string' and stringUtils.stringStartsWith(id, 'temp.addModuleComp.params.entity_') then
                            -- see the notes under idAdded
                            m_guiConConfigMenu.openForConId = nil

                            local conId = tonumber(id:sub(34), 10)
                            if not(edgeUtils.isValidAndExistingId(conId)) then return end

                            local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                            if con == nil or con.fileName ~= _constants.stationConFileName then return end

                            -- prevent a crash if loading a game when the con config menu is open.
                            local _ingameMenu = api.gui.util.getById('ingameMenu')
                            if _ingameMenu ~= nil and _ingameMenu:isVisible() then return end

                            logger.print('the con config menu was closed, about to send command CON_CONFIG_MENU_CLOSED, conId = ' .. conId)
                            guiHelpers.showProgress(_guiTexts.rebuildNeighboursInProgress, _guiTexts.modName, _utils.sendAllowProgress)
                            api.cmd.sendCommand(
                                api.cmd.make.sendScriptEvent(
                                    string.sub(debug.getinfo(1, 'S').source, 1),
                                    _eventId,
                                    _eventNames.CON_CONFIG_MENU_CLOSED,
                                    { stationConstructionId = conId }
                                )
                            )
                        -- elseif name == 'visibilityChange' then
                        --     -- id =	ingameMenu.saveGameButton	name =	button.click
                        --     logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') logger.debugPrint(args)
                        elseif name == 'button.click' and id == 'ingameMenu.saveGameButton' then
                            -- bar saving the game if a station is not finalised
                            local userMessage = nil
                            if m_guiConConfigMenu.openForConId ~= nil then
                                logger.warn('about to save a game but the construction config menu is open, so a freestyle station is not finalised => closing the ingame menu')
                                userMessage = _guiTexts.closeConConfigBeforeSaving
                            elseif m_state.warningText ~= nil then
                                logger.warn('about to save a game but a warning is open, so a freestyle station is not finalised => closing the ingame menu')
                                userMessage = _guiTexts.awaitFinalisationBeforeSaving
                            elseif m_conConfigMenu.isBusy then
                                logger.warn('about to save a game but the mod is busy, so a freestyle station is not finalised => closing the ingame menu')
                                userMessage = _guiTexts.awaitFinalisationBeforeSaving
                            end
                            if userMessage ~= nil then
                                if guiHelpers.isAllowSaving then
                                    logger.warn('force-saving a game with a possibly unready station')
                                else
                                    local _ingameMenu = api.gui.util.getById('ingameMenu')
                                    if _ingameMenu ~= nil and _ingameMenu:isVisible() then
                                        _ingameMenu:setVisible(false, true)
                                        guiHelpers.showSaveWarning(userMessage)
                                    end
                                end
                            end
                        end
                    end,
                    logger.xpErrorHandler
                )
            -- end
            if isHideDistance then guiHelpers.hideWaypointDistance() end
        end,
        guiUpdate = function()
            -- LOLLO NOTE these warnings are issued in the worker thread after the operation chain has completed,
            -- so they are displayed when needed;
            -- the progress info is also sent to the state after the operation chain has completed,
            -- but it's too late for it.
            -- To get all notices at the right moment, we use different systems:
            -- Warnings are shown when the state wants so, and closed by hand or when building something.
            -- Progress info is shown when the GUI is at the right point, and closed when the operation chain has completed.
            -- Both restore the pre-notice state when closed, so future notices will show up.
            if m_state.warningText == nil then
                guiHelpers.hideWarning(
                    -- _utils.sendHideWarnings -- do not set the state here, it might interfere and it's redundant anyway
                )
            elseif not(guiHelpers.isShowingWarning) then -- the if () avoids rendering many times
                guiHelpers.showWarning(
                    m_state.warningText,
                    _utils.sendHideWarnings
                )
            end

            if m_state.isHideProgress then
                guiHelpers.hideProgress(
                    _utils.sendAllowProgress
                )
            end
        end,
        load = function(loadedState)
            -- fires once in the worker thread, at game load, and many times in the UI thread
            -- print('load got loadedState =') debugPrint(loadedState)
            if not(api.gui) or not(loadedState) then
                -- not(api.gui) is the one call from the worker thread, when starting
                -- (there are actually two calls on start, not one, never mind)
                -- with not(api.gui), loadedState is the last saved state from the save file (eg lollo-test-01.sav.lua)
                -- use it to reset the state if it gets stuck, which should never happen
                m_state = {
                    isHideProgress = false,
                    warningText = nil,
                }
                logger.print('script.load firing from the worker thread, state =') logger.debugPrint(m_state)
            else
                m_state = {
                    isHideProgress = loadedState.isHideProgress or false,
                    warningText = loadedState.warningText or nil,
                }
            end
        end,
        save = function()
            -- only fires when the worker thread changes the state
            if m_state == nil then m_state = {} end
            if not(m_state.isHideProgress) then m_state.isHideProgress = false end
            if m_state.warningText == '' then m_state.warningText = nil end
            return m_state
        end,
        -- update = function()
        -- end,
    }
end
