local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelper')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- local state = nil -- LOLLO NOTE you can only update the state from the worker thread

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

local constructionDataBak = nil
local _eventId = '__lolloFreestyleTrainStation__'
local _eventNames = {
    BUILD_SNAPPY_TRACKS_REQUESTED = 'buildSnappyTracksRequested',
    BUILD_STATION_REQUESTED = 'buildStationRequested',
    BULLDOZE_STATION_REQUESTED = 'bulldozeStationRequested',
    PLATFORM_WAYPOINT_1_SPLIT_REQUESTED = 'platformWaypoint1SplitRequested',
    PLATFORM_WAYPOINT_2_SPLIT_REQUESTED = 'platformWaypoint2SplitRequested',
    REBUILD_ALL_TRACKS_REQUESTED = 'rebuildAllTracksRequested',
    REBUILD_1_TRACK_REQUESTED = 'rebuild1TrackRequested',
    REMOVE_TERMINAL_REQUESTED = 'removeTerminalRequested',
    TRACK_BULLDOZE_REQUESTED = 'trackBulldozeRequested',
    TRACK_WAYPOINT_1_SPLIT_REQUESTED = 'trackWaypoint1SplitRequested',
    TRACK_WAYPOINT_2_SPLIT_REQUESTED = 'trackWaypoint2SplitRequested',
    WAYPOINT_BULLDOZE_REQUESTED = 'waypointBulldozeRequested',
}

local _actions = {
    buildSnappyTracks = function(endEntities)
        -- LOLLO NOTE after building the station, never mind how well you placed it,
        -- its end nodes won't snap to the adjacent roads.
        -- AltGr + L will show a red dot, and here is the catch: there are indeed
        -- two separate nodes in the same place, at each station end.
        -- Here, I remove the neighbour track (edge and node) and replace it
        -- with an identical track, which snaps to the station end node instead.
        print('buildSnappyTracks starting')
        print('endEntities =') debugPrint(endEntities)
        if endEntities == nil then return end

        local proposal = api.type.SimpleProposal.new()
        local isProposalPopulated = false
        local nNewEntities = 0

        local _replaceSegment = function(edgeId, endEntities4T)
            local newSegment = api.type.SegmentAndEntity.new()
            nNewEntities = nNewEntities - 1
            newSegment.entity = nNewEntities

            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            if baseEdge.node0 == endEntities4T.disjointNeighbourNodeIds.node1Id then
                newSegment.comp.node0 = endEntities4T.stationEndNodeIds.node1Id
            elseif baseEdge.node0 == endEntities4T.disjointNeighbourNodeIds.node2Id then
                newSegment.comp.node0 = endEntities4T.stationEndNodeIds.node2Id
            else
                newSegment.comp.node0 = baseEdge.node0
            end

            if baseEdge.node1 == endEntities4T.disjointNeighbourNodeIds.node1Id then
                newSegment.comp.node1 = endEntities4T.stationEndNodeIds.node1Id
            elseif baseEdge.node1 == endEntities4T.disjointNeighbourNodeIds.node2Id then
                newSegment.comp.node1 = endEntities4T.stationEndNodeIds.node2Id
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
            newSegment.type = _constants.railEdgeType
            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
            newSegment.trackEdge.trackType = baseEdgeTrack.trackType
            newSegment.trackEdge.catenary = baseEdgeTrack.catenary

            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
            proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
            isProposalPopulated = true
        end

        for _, endEntities4T in pairs(endEntities) do
            -- for each terminal
            for i = 1, #endEntities4T.disjointNeighbourEdgeIds.edge1Ids do
                _replaceSegment(endEntities4T.disjointNeighbourEdgeIds.edge1Ids[i], endEntities4T)
            end
            for i = 1, #endEntities4T.disjointNeighbourEdgeIds.edge2Ids do
                _replaceSegment(endEntities4T.disjointNeighbourEdgeIds.edge2Ids[i], endEntities4T)
            end

            if edgeUtils.isValidAndExistingId(endEntities4T.disjointNeighbourNodeIds.node1Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.disjointNeighbourNodeIds.node1Id
                isProposalPopulated = true
            end
            if edgeUtils.isValidAndExistingId(endEntities4T.disjointNeighbourNodeIds.node2Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.disjointNeighbourNodeIds.node2Id
                isProposalPopulated = true
            end
        end

        if not(isProposalPopulated) then return end
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
                -- cargo = true,
            },
            name = args.isCargo and _constants.cargoTerminalModuleFileName or _constants.passengerTerminalModuleFileName,
            updateScript = {
                fileName = '',
                params = { },
            },
            variant = 0,
        }
        local params_newTerminal = {
            isCargo = args.isCargo,
            -- myTransf = arrayUtils.cloneDeepOmittingFields(conTransf),
            platformEdgeLists = args.platformEdgeList,
            trackEdgeLists = args.trackEdgeList,
            centreLanePositions = args.centreLanePositions,
            centreLanePositionsFine = args.centreLanePositionsFine,
            leftLanePositions = args.leftLanePositions,
            rightLanePositions = args.rightLanePositions,
            crossConnectorPositions = args.crossConnectorPositions
        }

        if oldCon == nil then
            newCon.params = {
                mainTransf = arrayUtils.cloneDeepOmittingFields(conTransf),
                modules = { [params_newModuleKey] = params_newModuleValue },
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
            -- newCon.name = 'construction name' -- LOLLO TODO assign a proper name
        else
            local newParams = {
                mainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true),
                modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
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

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- we need it here, or we will have trouble later building the snappy tracks
        -- context.cleanupStreetGraph = true -- we need it here, or we will have trouble later building the snappy tracks
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('build station callback, success =', success)
                -- debugPrint(result)
                if success and successEventName ~= nil then
                    -- local eventArgs = arrayUtils.cloneDeepOmittingFields(args)
                    local eventArgs = arrayUtils.cloneDeepOmittingFields(args, {'centreLanePositions', 'centreLanePositionsFine', 'crossConnectorPositions', 'leftLanePositions', 'rightLanePositions'})
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

    removeTerminal = function(constructionData, nTerminalToRemove, successEventName)
        print('removeTerminal starting, constructionData.constructionId =', constructionData.constructionId)

        local oldCon = edgeUtils.isValidAndExistingId(constructionData.constructionId)
        and api.engine.getComponent(constructionData.constructionId, api.type.ComponentType.CONSTRUCTION)
        or nil
        -- print('oldCon =') debugPrint(oldCon)
        if oldCon == nil then return end

        print('nTerminalToRemove =') debugPrint(nTerminalToRemove)
        if type(nTerminalToRemove) ~= 'number' then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileNameLong

        local newParams = {
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true),
            modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
            seed = oldCon.params.seed + 1,
            terminals = arrayUtils.cloneDeepOmittingFields(oldCon.params.terminals, nil, true)
        }

        local newModules = {}
        for slotId, modu in pairs(newParams.modules) do
            local nTerminal, nTrackEdge, baseId = slotHelpers.demangleId(slotId)
            if nTerminal < nTerminalToRemove then
                newModules[slotId] = modu
            elseif nTerminal == nTerminalToRemove then
            else
                local newSlotId = slotHelpers.mangleId(nTerminal - 1, nTrackEdge, baseId)
                newModules[newSlotId] = modu
            end
        end
        newParams.modules = newModules

        local removedTerminal = newParams.terminals[nTerminalToRemove]
        table.remove(newParams.terminals, nTerminalToRemove)

        newCon.params = newParams
        newCon.transf = oldCon.transf
        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon

        proposal.constructionsToRemove = { constructionData.constructionId }
        proposal.old2new = {
            [constructionData.constructionId] = 0,
        }

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- true gives smoother z, default is false
        context.cleanupStreetGraph = true -- default is false
        context.gatherBuildings = false -- default is false
        context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('removeTerminal callback, success =', success)
                -- debugPrint(result)
                if success and successEventName ~= nil then
                    local eventArgs = {
                        endEntities = type(constructionData.endEntities) == 'table'
                            and arrayUtils.cloneDeepOmittingFields(constructionData.endEntities[nTerminalToRemove])
                            or {}
                        ,
                        removedTerminal = removedTerminal,
                        stationConstructionId = result.resultEntities[1]
                    }
                    print('eventArgs.stationConstructionId =', eventArgs.stationConstructionId)
                    print('removeTerminal callback is about to send command')
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

    rebuildTracks = function(trackEdgeLists, platformEdgeLists, neighbourNodeIds, stationConstructionId, successEventName)
        -- print('rebuildTracks starting')
        -- print('trackEdgeLists =') debugPrint(trackEdgeLists)
        -- print('neighbourNodeIds =') debugPrint(neighbourNodeIds)
        if trackEdgeLists == nil or type(trackEdgeLists) ~= 'table' or #trackEdgeLists == 0 then return end

        local proposal = api.type.SimpleProposal.new()

        -- there may be no neighbour nodes, if the station was built in a certain fashion
        local _baseNode1 = (neighbourNodeIds ~= nil and edgeUtils.isValidAndExistingId(neighbourNodeIds.node1))
        and api.engine.getComponent(neighbourNodeIds.node1, api.type.ComponentType.BASE_NODE)
        or nil
        -- print('_baseNode1 =') debugPrint(_baseNode1)
        local _baseNode2 = (neighbourNodeIds ~= nil and edgeUtils.isValidAndExistingId(neighbourNodeIds.node2))
        and api.engine.getComponent(neighbourNodeIds.node2, api.type.ComponentType.BASE_NODE)
        or nil
        -- print('_baseNode2 =') debugPrint(_baseNode2)
        local nNewEntities = 0
        local newNodes = {}

        local _addNode = function(position)
            -- print('adding node, position =') debugPrint(position)
            if _baseNode1 ~= nil then
                -- print('_baseNode1.position =') debugPrint(_baseNode1.position)
            else
                -- print('_baseNode1 is NIL')
            end
            if _baseNode2 ~= nil then
                -- print('_baseNode2.position =') debugPrint(_baseNode2.position)
            else
                -- print('_baseNode2 is NIL')
            end
            if _baseNode1 ~= nil
            and edgeUtils.isNumVeryClose(position[1], _baseNode1.position.x)
            and edgeUtils.isNumVeryClose(position[2], _baseNode1.position.y)
            and edgeUtils.isNumVeryClose(position[3], _baseNode1.position.z)
            then
                -- print('fifteen')
                return neighbourNodeIds.node1
            elseif _baseNode2 ~= nil
            and edgeUtils.isNumVeryClose(position[1], _baseNode2.position.x)
            and edgeUtils.isNumVeryClose(position[2], _baseNode2.position.y)
            and edgeUtils.isNumVeryClose(position[3], _baseNode2.position.z)
            then
                -- print('sixteen')
                return neighbourNodeIds.node2
            else
                for _, newNode in pairs(newNodes) do
                    if edgeUtils.isNumVeryClose(position[1], newNode.position[1])
                    and edgeUtils.isNumVeryClose(position[2], newNode.position[2])
                    and edgeUtils.isNumVeryClose(position[3], newNode.position[3])
                    then
                        -- print('eighteen')
                        return newNode.id
                    end
                end

                -- print('twenty')
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
            newSegment.type = _constants.railEdgeType
            newSegment.trackEdge.trackType = trackEdgeList.trackType
            newSegment.trackEdge.catenary = trackEdgeList.catenary

            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
        end

        for _, trackEdgeList in pairs(trackEdgeLists) do
            _addSegment(trackEdgeList)
        end

        -- print('rebuildTracks proposal =') debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                -- print('LOLLO result = ')
                -- debugPrint(result)
                print('LOLLO rebuildTracks success = ', success)
                if success and successEventName ~= nil then
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        {
                            stationConstructionId = stationConstructionId
                        }
                    ))
                end
            end
        )
    end,

    bulldozeStation = function(constructionData, successEventName)
        if constructionData == nil then return end
        local constructionId = constructionData.constructionId

        if not(edgeUtils.isValidAndExistingId(constructionId)) then return end

        local oldCon = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        -- print('oldCon =') debugPrint(oldCon)
        if not(oldCon) or not(oldCon.params) then return end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { constructionId }
        -- proposal.constructionsToRemove[1] = constructionId -- fails to add
        -- proposal.constructionsToRemove:add(constructionId) -- fails to add

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('LOLLO bulldozeStation success = ', success)
                -- print('LOLLO bulldozeStation result = ') debugPrint(result)
                if success and successEventName ~= nil then
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        {
                            constructionData = arrayUtils.cloneDeepOmittingFields(constructionData)
                        }
                    ))
                end
            end
        )
    end,

    removeTracks = function(platformEdgeIds, trackEdgeIds, successEventName, successEventArgs)
        print('removeTracks starting')
        -- print('successEventName =') debugPrint(successEventName)
        -- print('successEventArgs =') debugPrint(successEventArgs)
        print('platformEdgeIds =') debugPrint(platformEdgeIds)
        print('trackEdgeIds =') debugPrint(trackEdgeIds)
        local allEdgeIds = {}
        arrayUtils.concatValues(allEdgeIds, trackEdgeIds)
        arrayUtils.concatValues(allEdgeIds, platformEdgeIds)
        print('allEdgeIds =') debugPrint(allEdgeIds)

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
            edgeUtils.getNodeIdsBetweenEdgeIds(trackEdgeIds)
        )
        arrayUtils.concatValues(
            sharedNodeIds,
            edgeUtils.getNodeIdsBetweenEdgeIds(platformEdgeIds)
        )
        for i = 1, #sharedNodeIds do
            proposal.streetProposal.nodesToRemove[i] = sharedNodeIds[i]
        end
        -- print('proposal.streetProposal.nodesToRemove =')
        -- debugPrint(proposal.streetProposal.nodesToRemove)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                print('command callback firing for removeTracks, success =', success)
                -- debugPrint(result)
                if success and successEventName ~= nil then
                    print('removeTracks callback is about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        arrayUtils.cloneDeepOmittingFields(successEventArgs)
                    ))
                end
            end
        )
    end,

    replaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        print('replaceEdgeWithSameRemovingObject starting')
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end
        print('replaceEdgeWithSameRemovingObject found, the old edge id is valid')
        -- replaces a track segment with an identical one, without destroying the buildings
        local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(oldEdgeId, objectIdToRemove)
        if not(proposal) then return end
        print('replaceEdgeWithSameRemovingObject likes the proposal')
        -- debugPrint(proposal)
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
        context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                -- print('LOLLO replaceEdgeWithSameRemovingObject result = ') debugPrint(result)
                print('LOLLO replaceEdgeWithSameRemovingObject success = ') debugPrint(success)
            end
        )
    end,

    splitEdgeRemovingObject = function(wholeEdgeId, position0, tangent0, position1, tangent1, nodeBetween, objectIdToRemove, successEventName, successEventArgs, newArgName)
        if not(edgeUtils.isValidAndExistingId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

        local oldBaseEdge = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldBaseEdgeTrack = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldBaseEdge == nil or oldBaseEdgeTrack == nil then return end

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, true may shift the new nodes after the split, which makes them impossible for us to recognise.
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        -- the split may occur at the end of an edge - in theory, but I could not make it happen in practise.
        if nodeBetween.length0 == 0 or nodeBetween.length1 == 0 then
            -- LOLLO TODO check this, it seems to never happen
            print('WARNING: nodeBetween is at the end of an edge; nodeBetween =') debugPrint(nodeBetween)
            local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(wholeEdgeId, objectIdToRemove)
            if not(proposal) then return end

            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    print('command callback firing for split, success =', success)
                    if success and successEventName ~= nil then
                        local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                        if not(stringUtils.isNullOrEmptyString(newArgName)) then
                            local splitNodeId = nodeBetween.length0 == 0 and oldBaseEdge.node0 or oldBaseEdge.node1
                            eventArgs[newArgName] = splitNodeId
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
            return
        end

        local node0TangentLength = edgeUtils.getVectorLength({ tangent0.x, tangent0.y, tangent0.z })
        local node1TangentLength = edgeUtils.getVectorLength({ tangent1.x, tangent1.y, tangent1.z })

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
            tangent0.x * nodeBetween.length0 / node0TangentLength,
            tangent0.y * nodeBetween.length0 / node0TangentLength,
            tangent0.z * nodeBetween.length0 / node0TangentLength
        )
        newEdge0.comp.tangent1 = api.type.Vec3f.new(
            nodeBetween.tangent.x * nodeBetween.length0,
            nodeBetween.tangent.y * nodeBetween.length0,
            nodeBetween.tangent.z * nodeBetween.length0
        )
        newEdge0.comp.type = oldBaseEdge.type -- respect bridge or tunnel
        newEdge0.comp.typeIndex = oldBaseEdge.typeIndex -- respect bridge or tunnel
        newEdge0.playerOwned = playerOwned
        newEdge0.trackEdge = oldBaseEdgeTrack

        local newEdge1 = api.type.SegmentAndEntity.new()
        newEdge1.entity = -2
        newEdge1.type = _constants.railEdgeType
        newEdge1.comp.node0 = -3
        newEdge1.comp.node1 = oldBaseEdge.node1
        newEdge1.comp.tangent0 = api.type.Vec3f.new(
            nodeBetween.tangent.x * nodeBetween.length1,
            nodeBetween.tangent.y * nodeBetween.length1,
            nodeBetween.tangent.z * nodeBetween.length1
        )
        newEdge1.comp.tangent1 = api.type.Vec3f.new(
            tangent1.x * nodeBetween.length1 / node1TangentLength,
            tangent1.y * nodeBetween.length1 / node1TangentLength,
            tangent1.z * nodeBetween.length1 / node1TangentLength
        )
        newEdge1.comp.type = oldBaseEdge.type
        newEdge1.comp.typeIndex = oldBaseEdge.typeIndex
        newEdge1.playerOwned = playerOwned
        newEdge1.trackEdge = oldBaseEdgeTrack

        if type(oldBaseEdge.objects) == 'table' and #oldBaseEdge.objects > 1 then
            print('splitting: edge objects found')
            local edge0Objects = {}
            local edge1Objects = {}
            for _, edgeObj in pairs(oldBaseEdge.objects) do
                print('edgeObj =')
                debugPrint(edgeObj)
                if edgeObj[1] ~= objectIdToRemove then
                    local edgeObjPosition = edgeUtils.getObjectPosition(edgeObj[1])
                    print('edgeObjPosition =')
                    debugPrint(edgeObjPosition)
                    if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                    local assignment = stationHelpers.getWhichEdgeGetsEdgeObjectAfterSplit(
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
        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end
        proposal.streetProposal.nodesToAdd[1] = newNodeBetween
        -- print('split proposal =') debugPrint(proposal)

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO freestyle train station: split callback returned result = ')
                -- debugPrint(result)
                --for _, v in pairs(result.entities) do print(v) end
                -- print('LOLLO freestyle train station callback returned success = ')
                print('command callback firing for split, success =', success)
                if success and successEventName ~= nil then
                    -- UG TODO this should come from UG!
                    -- try reading the node ids from the added edges instead.
                    -- no good, there may be a new edge using an old node!
                    -- But check how many nodes are actually added. If it is only 1, fine;
                    -- otherwise, we need a better way to check the new node
                    -- it looks fine, fortunately
                    -- print('split callback result =') debugPrint(result)
                    -- print('split callback result.proposal.proposal.addedNodes =') debugPrint(result.proposal.proposal.addedNodes)
                    if #result.proposal.proposal.addedNodes ~= 1 then
                        print('ERROR: #result.proposal.proposal.addedNodes =', #result.proposal.proposal.addedNodes)
                    end
                    local addedNodePosition = result.proposal.proposal.addedNodes[1].comp.position
                    -- print('addedNodePosition =') debugPrint(addedNodePosition)

                    local addedNodeIds = edgeUtils.getNearestObjectIds(
                        transfUtils.position2Transf(addedNodePosition),
                        0.001,
                        api.type.ComponentType.BASE_NODE
                    )
                    -- edgeUtils.getNearestObjectIds(transfUtils.position2Transf(addedNodePosition), 0, api.type.ComponentType.BASE_NODE)
                    -- edgeUtils.getNearestObjectIds(transfUtils.position2Transf(addedNodePosition), 2, api.type.ComponentType.BASE_NODE)
                    -- edgeUtils.getNearestObjectIds(transfUtils.position2Transf(addedNodePosition), 0.5, api.type.ComponentType.BASE_NODE)
                    -- print('addedNodeIds =') debugPrint(addedNodeIds)

                    -- if #addedNodeIds == 0 then
                    --     addedNodeIds = edgeUtils.getNearestObjectIds(
                    --         transfUtils.position2Transf(addedNodePosition),
                    --         1,
                    --         api.type.ComponentType.BASE_NODE
                    --     )
                    --     print('addedNodeIds =') debugPrint(addedNodeIds)
                    -- end

                    local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                    if not(stringUtils.isNullOrEmptyString(newArgName)) then
                        eventArgs[newArgName] = addedNodeIds[1]
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
    return stationHelpers.isBuildingConstructionWithFileName(param, _constants.stationConFileNameLong)
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
                -- game.interface.bulldoze(args.waypointId) -- dumps
                _actions.replaceEdgeWithSameRemovingObject(args.edgeId, args.waypointId)
            elseif name == _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.trackWaypoint1Id))
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint1Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint1Id)
                -- UG TODO see if the api can get the exact percentage shift
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                    edgeId,
                    -- LOLLO NOTE position and transf are always very similar
                    {
                        x = waypointPosition[1],
                        y = waypointPosition[2],
                        z = waypointPosition[3],
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
                    arrayUtils.cloneDeepOmittingFields(args),
                    'splitTrackNode1Id'
                )
            elseif name == _eventNames.TRACK_WAYPOINT_2_SPLIT_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.trackWaypoint2Id))
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint2Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint2Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                    edgeId,
                    {
                        x = waypointPosition[1],
                        y = waypointPosition[2],
                        z = waypointPosition[3],
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
                    _eventNames.PLATFORM_WAYPOINT_1_SPLIT_REQUESTED,
                    arrayUtils.cloneDeepOmittingFields(args),
                    'splitTrackNode2Id'
                )
            elseif name == _eventNames.PLATFORM_WAYPOINT_1_SPLIT_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.platformWaypoint1Id))
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint1Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint1Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                    edgeId,
                    {
                        x = waypointPosition[1],
                        y = waypointPosition[2],
                        z = waypointPosition[3],
                    }
                )

                _actions.splitEdgeRemovingObject(
                    edgeId,
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    nodeBetween,
                    args.platformWaypoint1Id,
                    _eventNames.PLATFORM_WAYPOINT_2_SPLIT_REQUESTED,
                    arrayUtils.cloneDeepOmittingFields(args),
                    'splitPlatformNode1Id'
                )
            elseif name == _eventNames.PLATFORM_WAYPOINT_2_SPLIT_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.platformWaypoint2Id))
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint2Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if not(baseEdge) then return end
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                if not(node0) or not(node1) then return end
                local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint2Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                    edgeId,
                    {
                        x = waypointPosition[1],
                        y = waypointPosition[2],
                        z = waypointPosition[3],
                    }
                )

                _actions.splitEdgeRemovingObject(
                    edgeId,
                    node0.position,
                    baseEdge.tangent0,
                    node1.position,
                    baseEdge.tangent1,
                    nodeBetween,
                    args.platformWaypoint2Id,
                    _eventNames.TRACK_BULLDOZE_REQUESTED,
                    arrayUtils.cloneDeepOmittingFields(args),
                    'splitPlatformNode2Id'
                )
            elseif name == _eventNames.TRACK_BULLDOZE_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.splitPlatformNode1Id))
                or not(edgeUtils.isValidAndExistingId(args.splitPlatformNode2Id))
                or not(edgeUtils.isValidAndExistingId(args.splitTrackNode1Id))
                or not(edgeUtils.isValidAndExistingId(args.splitTrackNode2Id))
                then
                    print('WARNING: some data is missing or invalid. args.splitTrackNode1Id =') debugPrint(args.splitTrackNode1Id)
                    print('args.splitTrackNode2Id =') debugPrint(args.splitTrackNode2Id)
                    return
                end

                local trackEdgeIdsBetweenNodeIds = stationHelpers.getTrackEdgeIdsBetweenNodeIds(
                    args.splitTrackNode1Id,
                    args.splitTrackNode2Id
                )
                -- LOLLO NOTE I need this, or a station with only one track edge will dump with
                -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                if #trackEdgeIdsBetweenNodeIds == 1 then
                    print('only one track edge, going to split it')
                    local edgeId = trackEdgeIdsBetweenNodeIds[1]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                    if not(baseEdge) then return end

                    local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                    local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                    if not(node0) or not(node1) then return end

                    local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
                    _actions.splitEdgeRemovingObject(
                        edgeId,
                        node0.position,
                        baseEdge.tangent0,
                        node1.position,
                        baseEdge.tangent1,
                        nodeBetween,
                        nil,
                        _eventNames.TRACK_BULLDOZE_REQUESTED,
                        arrayUtils.cloneDeepOmittingFields(args),
                        false
                    )
                    return
                end
                print('at least two track edges found')

                local platformEdgeIdsBetweenNodeIds = stationHelpers.getTrackEdgeIdsBetweenNodeIds(
                    args.splitPlatformNode1Id,
                    args.splitPlatformNode2Id
                )
                -- LOLLO NOTE I need this, or a station with only one platform edge will dump with
                -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                -- You may leave this out if you lay down platform models instead of edges
                if #platformEdgeIdsBetweenNodeIds == 1 then
                    print('only one platform edge, going to split it')
                    local edgeId = platformEdgeIdsBetweenNodeIds[1]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                    if not(baseEdge) then return end

                    local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                    local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                    if not(node0) or not(node1) then return end

                    local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
                    _actions.splitEdgeRemovingObject(
                        edgeId,
                        node0.position,
                        baseEdge.tangent0,
                        node1.position,
                        baseEdge.tangent1,
                        nodeBetween,
                        nil,
                        _eventNames.TRACK_BULLDOZE_REQUESTED,
                        arrayUtils.cloneDeepOmittingFields(args),
                        false
                    )
                    return
                end
                print('at least two platform edges found')


                local eventArgs = arrayUtils.cloneDeepOmittingFields(args, { 'splitTrackNode1Id', 'splitTrackNode2Id', 'trackWaypoint1Id', 'trackWaypoint2Id', })
                eventArgs.platformEdgeList = stationHelpers.getEdgeIdsProperties(platformEdgeIdsBetweenNodeIds)
                print('track bulldoze requested, platformEdgeList =') debugPrint(eventArgs.platformEdgeList)
                eventArgs.trackEdgeList = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenNodeIds)
                print('track bulldoze requested, trackEdgeList =') debugPrint(eventArgs.trackEdgeList)
                eventArgs.centreLanePositionsFine = stationHelpers.getCentreLanePositions(eventArgs.platformEdgeList, 1)
                eventArgs.centreLanePositions = stationHelpers.getCentreLanePositions(eventArgs.platformEdgeList, args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength)
                eventArgs.leftLanePositions = stationHelpers.getShiftedLanePositions(eventArgs.centreLanePositions, args.isCargo, - _constants.sideLaneShiftM)
                eventArgs.rightLanePositions = stationHelpers.getShiftedLanePositions(eventArgs.centreLanePositions, args.isCargo, _constants.sideLaneShiftM)
                eventArgs.crossConnectorPositions = stationHelpers.getCrossConnectors(eventArgs.leftLanePositions, eventArgs.centreLanePositions, eventArgs.rightLanePositions, args.isCargo)

                -- LOLLO TODO MAYBE add underground connections for cargo, with lanes of type PERSON, if required. Not fancy, just vertical and horizontal lanes,
				-- maybe even overground. For now, it looks unnecessary.

                _actions.removeTracks(
                    platformEdgeIdsBetweenNodeIds,
                    trackEdgeIdsBetweenNodeIds,
                    _eventNames.BUILD_STATION_REQUESTED,
                    eventArgs
                )
            elseif name == _eventNames.BUILD_STATION_REQUESTED then
                local eventArgs = arrayUtils.cloneDeepOmittingFields(args)
                eventArgs.nTerminal = 1
                if edgeUtils.isValidAndExistingId(eventArgs.join2StationId) then
                    local con = api.engine.getComponent(eventArgs.join2StationId, api.type.ComponentType.CONSTRUCTION)
                    if con ~= nil then eventArgs.nTerminal = #con.params.terminals + 1 end
                end
                print('eventArgs.nTerminal =', eventArgs.nTerminal)

                _actions.buildStation(
                    _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED,
                    eventArgs
                )
            elseif name == _eventNames.REMOVE_TERMINAL_REQUESTED then
                _actions.removeTerminal(args.constructionData, args.nTerminalToRemove, _eventNames.REBUILD_1_TRACK_REQUESTED)
            elseif name == _eventNames.REBUILD_1_TRACK_REQUESTED then
                if type(args.removedTerminal) ~= 'table' or type(args.removedTerminal.trackEdgeLists) ~= 'table' then
                    print('ERROR: args.removedTerminal.trackEdgeLists not available')
                    return
                end
                if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                    print('ERROR: args.stationConstructionId not valid')
                    return
                end
                _actions.rebuildTracks(
                    args.removedTerminal.trackEdgeLists,
                    nil,
                    stationHelpers.getBulldozedStationNeighbourNodeIds(args.endEntities),
                    args.stationConstructionId,
                    _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED
                )
            elseif name == _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                    print('ERROR: args.stationConstructionId not valid')
                    return
                end
                _actions.buildSnappyTracks(
                    stationHelpers.getStationEndEntitiesTyped(args.stationConstructionId)
                )
            elseif name == _eventNames.BULLDOZE_STATION_REQUESTED then
                _actions.bulldozeStation(args.constructionData, _eventNames.REBUILD_ALL_TRACKS_REQUESTED)
            elseif name == _eventNames.REBUILD_ALL_TRACKS_REQUESTED then
                for t = 1, #args.constructionData.params.terminals do
                    if type(args.constructionData.endEntities) == 'table' then
                        _actions.rebuildTracks(
                            args.constructionData.params.terminals[t].trackEdgeLists,
                            args.constructionData.params.terminals[t].platformEdgeLists,
                            stationHelpers.getBulldozedStationNeighbourNodeIds(args.constructionData.endEntities[t])
                        )
                    end
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
                        guiHelpers.hideAllWarnings()
                        if not(args.proposal.toRemove) then return end

                        for _, constructionId in pairs(args.proposal.toRemove) do
                            local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                            if con ~= nil and type(con.fileName) == 'string' and con.fileName == _constants.stationConFileNameLong then
                                constructionDataBak = {
                                    constructionId = constructionId,
                                    endEntities = stationHelpers.getStationEndEntitiesTyped(constructionId),
                                    params = arrayUtils.cloneDeepOmittingFields(con.params, nil, true)
                                }
                                break
                            end
                        end
                    elseif name == 'builder.apply' then
                        guiHelpers.hideAllWarnings()
                        -- print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                        if id == 'bulldozer' then
                            -- now it's too late to read the station params:
                            -- if you are bulldozing the station you backed up before,
                            -- read its tracks from the backup and rebuild them.
                            -- Otherwise, do nothing (it should never happen).
                            if constructionDataBak == nil then print('conParamsBak is nil') return end

                            for _, constructionId in pairs(args.proposal.toRemove) do
                                print('about to bulldoze construction', constructionId)
                                if constructionDataBak.constructionId == constructionId then
                                    print('bulldozing a freestyle station, conParamsBak exists and has type', type(constructionDataBak))
                                    print('#constructionDataBak.params.terminals =', #constructionDataBak.params.terminals)
                                    -- print('args = ') debugPrint(args)
                                    -- print('constructionDataBak =') debugPrint(constructionDataBak)
                                    if edgeUtils.isValidAndExistingId(constructionId) then
                                        -- bulldozed a station module AND there are more terminals left
                                        local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                                        local removedSlotIds = {}
                                        for oldSlotId, _ in pairs(constructionDataBak.params.modules) do
                                            local isStillThere = false
                                            for newSlotId, _ in pairs(con.params.modules) do
                                                if newSlotId == oldSlotId then
                                                    isStillThere = true
                                                    break
                                                end
                                            end
                                            if not(isStillThere) then removedSlotIds[#removedSlotIds+1] = oldSlotId end
                                        end
                                        print('removedSlotIds =') debugPrint(removedSlotIds)
                                        if #removedSlotIds < 1 then print('ERROR station was bulldozed but no slot ids to remove were found') return end

                                        -- the user may have removed any sort of module. Here, we only care for the terminal slot,
                                        -- because we need to remove its tracks and platforms.
                                        local nTerminalsToRemove = {}
                                        for _, slotId in pairs(removedSlotIds) do
                                            local nTerminal, _, baseId = slotHelpers.demangleId(slotId)
                                            if baseId == _constants.idBases.terminalSlotId then
                                                arrayUtils.addUnique(nTerminalsToRemove, nTerminal)
                                                -- break
                                            end
                                        end
                                        if #nTerminalsToRemove == 0 then print('user removed a module, but not the terminal: carry on') return end
                                        if #nTerminalsToRemove > 1 then print('ERROR user removed more than one terminal: this cannot be') return end

                                        if #constructionDataBak.params.terminals > 1 then
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.REMOVE_TERMINAL_REQUESTED,
                                                {
                                                    constructionData = constructionDataBak,
                                                    nTerminalToRemove = nTerminalsToRemove[1]
                                                }
                                            ))
                                        else
                                            -- last terminal removed: pull down the station
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.BULLDOZE_STATION_REQUESTED,
                                                {
                                                    constructionData = constructionDataBak,
                                                }
                                            ))
                                        end
                                    else
                                        -- the whole station was bulldozed
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.REBUILD_ALL_TRACKS_REQUESTED,
                                            {
                                                constructionData = constructionDataBak,
                                            }
                                        ))
                                    end
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
                                local _cargoPlatformWaypointModelId = api.res.modelRep.find(_constants.cargoPlatformWaypointModelId)
                                local _passengerPlatformWaypointModelId = api.res.modelRep.find(_constants.passengerPlatformWaypointModelId)
                                local _trackWaypointModelId = api.res.modelRep.find(_constants.trackWaypointModelId)

                                local _validateWaypointBuilt = function(targetWaypointModelId, mustBeOnPlatform)
                                    print('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
                                    -- UG TODO this is empty, ask UG to fix this: can't we have the waypointId in args.result?
                                    -- print('waypoint built, args.result =') debugPrint(args.result)

                                    -- print('args.proposal.proposal.addedSegments =') debugPrint(args.proposal.proposal.addedSegments)
                                    local lastBuiltEdgeId = edgeUtils.getLastBuiltEdgeId(args.data.entity2tn, args.proposal.proposal.addedSegments[1])
                                    if not(edgeUtils.isValidAndExistingId(lastBuiltEdgeId)) then print('ERROR with lastBuiltEdgeId') return false end

                                    local lastBuiltBaseEdge = api.engine.getComponent(
                                        lastBuiltEdgeId,
                                        api.type.ComponentType.BASE_EDGE
                                    )
                                    if not(lastBuiltBaseEdge) then return false end

                                    -- print('edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, waypointModelId) =')
                                    -- debugPrint(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, targetWaypointModelId))
                                    local newWaypointId = arrayUtils.getLast(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, targetWaypointModelId))
                                    print('newWaypointId not found, lastBuiltEdgeId =', lastBuiltEdgeId, '#args.proposal.proposal.addedSegments =', #args.proposal.proposal.addedSegments)
                                    if not(newWaypointId) then return false end

                                    -- forbid building this on a platform or a track
                                    if trackUtils.isPlatform(args.proposal.proposal.addedSegments[1].trackEdge.trackType) ~= mustBeOnPlatform then
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
                                        return false
                                    end

                                    local similarObjectIdsInAnyEdges = stationHelpers.getAllEdgeObjectsWithModelId(targetWaypointModelId)
                                    print('similarObjectsIdsInAnyEdges =') debugPrint(similarObjectIdsInAnyEdges)
                                    -- forbid building more then two waypoints of the same type
                                    if #similarObjectIdsInAnyEdges > 2 then
                                        guiHelpers.showWarningWindowWithGoto(_('WaypointAlreadyBuilt'), newWaypointId, similarObjectIdsInAnyEdges)
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId
                                            }
                                        ))
                                        return false
                                    end

                                    if #similarObjectIdsInAnyEdges < 2 then
                                        -- not ready yet
                                        -- guiHelpers.showWarningWindowWithGoto(_('BuildMoreWaypoints'), newWaypointId)
                                        return false
                                    end

                                    local twinWaypointId =
                                        newWaypointId == similarObjectIdsInAnyEdges[1] and similarObjectIdsInAnyEdges[2] or similarObjectIdsInAnyEdges[1]
                                    local newWaypointPosition = edgeUtils.getObjectPosition(newWaypointId)
                                    local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)

                                    -- forbid building waypoints too far apart, which would make the station too large
                                    if newWaypointPosition ~= nil and twinWaypointPosition ~= nil then
                                        local distance = edgeUtils.getVectorLength({
                                            newWaypointPosition[1] - twinWaypointPosition[1],
                                            newWaypointPosition[2] - twinWaypointPosition[2],
                                            newWaypointPosition[3] - twinWaypointPosition[3],
                                        })
                                        if distance > _constants.maxWaypointDistance then
                                            guiHelpers.showWarningWindowWithGoto(_('WaypointsTooFar'), newWaypointId, similarObjectIdsInAnyEdges)
                                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                string.sub(debug.getinfo(1, 'S').source, 1),
                                                _eventId,
                                                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                                {
                                                    edgeId = lastBuiltEdgeId,
                                                    waypointId = newWaypointId
                                                }
                                            ))
                                            return false
                                        end
                                    end

                                    -- make sure the waypoints are on connected tracks
                                    local contiguousTrackEdges = stationHelpers.getTrackEdgeIdsBetweenEdgeIds(
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId)
                                    )
                                    print('contiguous track edges =') debugPrint(contiguousTrackEdges)
                                    if #contiguousTrackEdges < 1 then
                                        guiHelpers.showWarningWindowWithGoto(_('WaypointsNotConnected'), newWaypointId, similarObjectIdsInAnyEdges)
                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                            _eventId,
                                            _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                                            {
                                                edgeId = lastBuiltEdgeId,
                                                waypointId = newWaypointId,
                                            }
                                        ))
                                        return false
                                    end

                                    -- validation fine, return data
                                    return {
                                        newWaypointId = newWaypointId,
                                        twinWaypointId = twinWaypointId
                                    }
                                end

                                local _handleValidWaypointBuilt = function()
                                    local trackWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_trackWaypointModelId)
                                    if #trackWaypointIds ~= 2 then return end

                                    local cargoPlatformWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_cargoPlatformWaypointModelId)
                                    local passengerPlatformWaypointIds = #cargoPlatformWaypointIds ~= 2
                                        and stationHelpers.getAllEdgeObjectsWithModelId(_passengerPlatformWaypointModelId)
                                        or {}
                                    if #cargoPlatformWaypointIds ~= 2 and #passengerPlatformWaypointIds ~= 2 then return end

                                    local isCargo = #cargoPlatformWaypointIds == 2
                                    print('TWENTY')
                                    local platformWaypointIds = isCargo and cargoPlatformWaypointIds or passengerPlatformWaypointIds

                                    -- set a place to build the station
                                    local platformWaypoint1Pos = edgeUtils.getObjectPosition(platformWaypointIds[1])
                                    local platformWaypoint2Pos = edgeUtils.getObjectPosition(platformWaypointIds[2])
                                    local platformWaypointMidTransf = transfUtils.position2Transf({
                                        (platformWaypoint1Pos[1] + platformWaypoint2Pos[1]) * 0.5,
                                        (platformWaypoint1Pos[2] + platformWaypoint2Pos[2]) * 0.5,
                                        (platformWaypoint1Pos[3] + platformWaypoint2Pos[3]) * 0.5,
                                    })

                                    local trackWaypoint1Pos = edgeUtils.getObjectPosition(trackWaypointIds[1])
                                    local trackWaypoint2Pos = edgeUtils.getObjectPosition(trackWaypointIds[2])
                                    local distance11 = edgeUtils.getVectorLength({
                                        platformWaypoint1Pos[1] - trackWaypoint1Pos[1],
                                        platformWaypoint1Pos[2] - trackWaypoint1Pos[2],
                                        platformWaypoint1Pos[3] - trackWaypoint1Pos[3],
                                    })
                                    local distance12 = edgeUtils.getVectorLength({
                                        platformWaypoint1Pos[1] - trackWaypoint2Pos[1],
                                        platformWaypoint1Pos[2] - trackWaypoint2Pos[2],
                                        platformWaypoint1Pos[3] - trackWaypoint2Pos[3],
                                    })

                                    local eventArgs = {
                                        isCargo = isCargo,
                                        platformWaypointTransf = platformWaypointMidTransf,
                                        platformWaypoint1Id = platformWaypointIds[1],
                                        platformWaypoint2Id = platformWaypointIds[2],
                                        trackWaypoint1Id = distance11 < distance12 and trackWaypointIds[1] or trackWaypointIds[2],
                                        trackWaypoint2Id = distance11 < distance12 and trackWaypointIds[2] or trackWaypointIds[1],
                                    }

                                    local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationsList(platformWaypointMidTransf, 500)
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
                                    end
                                end
                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _cargoPlatformWaypointModelId then
                                    local waypointData = _validateWaypointBuilt(_cargoPlatformWaypointModelId, true)
                                    print('cargoPlatformWaypointData =') debugPrint(waypointData)
                                    if not(waypointData) then return end

                                    _handleValidWaypointBuilt()
                                elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _passengerPlatformWaypointModelId then
                                    local waypointData = _validateWaypointBuilt(_passengerPlatformWaypointModelId, true)
                                    print('passengerPlatformWaypointData =') debugPrint(waypointData)
                                    if not(waypointData) then return end

                                    _handleValidWaypointBuilt()

                                    -- LOLLO TODO if any platform nodes are joints between more than 2 platform-tracks,
                                    -- bar building or only build up to the node.

                                    -- LOLLO TODO if two terminals are on two consecutive bits of platform, join them with a pedestrian lane, in the station.con
                                    -- or at least, allow doing that by hand

                                    -- LOLLO TODO centre, left and right lanes need the info if each posTanX2 ir flat, bridge or tunnel.

                                    -- local platformWaypointTransf = transfUtilsUG.new(
                                    --     args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                    --     args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                    --     args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                    --     args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                    -- )

                                elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _trackWaypointModelId then
                                    local waypointData = _validateWaypointBuilt(_trackWaypointModelId, false)
                                    print('trackWaypointData =') debugPrint(waypointData)
                                    if not(waypointData) then return end

                                    _handleValidWaypointBuilt()
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

                            local _trackWaypointModelId = api.res.modelRep.find(_constants.trackWaypointModelId)

                            local removeTrackWaypointsEventArgs = {}
                            for _, addedSegment in pairs(args.proposal.proposal.addedSegments) do
                                if addedSegment and addedSegment.trackEdge
                                and trackUtils.isPlatform(addedSegment.trackEdge.trackType)
                                and addedSegment.comp.objects then
                                    local edgeObjectsToRemoveIds = edgeUtils.getEdgeObjectsIdsWithModelId(addedSegment.comp.objects, _trackWaypointModelId)
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
                                -- else
                                    -- print('addedSegment =') debugPrint(addedSegment)
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
        --     if not state.trackWaypoint1Id then state.trackWaypoint1Id = nil end
        --     if not state.trackWaypoint2Id then state.trackWaypoint2Id = nil end
        --     return state
        -- end,
        -- load = function(loadedState)
        --     -- fires once in the worker thread, at game load, and many times in the UI thread
        --     if loadedState then
        --         state = {}
        --         state.trackWaypoint1Id = loadedState.trackWaypoint1Id or nil
        --         state.trackWaypoint2Id = loadedState.trackWaypoint2Id or nil
        --     else
        --         state = {
        --             trackWaypoint1Id = nil,
        --             trackWaypoint2Id = nil
        --         }
        --     end
        --     -- commonData.set(state)
        -- end,
    }
end