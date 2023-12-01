local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local _constants = require('lollo_freestyle_train_station.constants')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')


local _eventId = '__lolloAutoSplitPlatform__'
local _eventProperties = {
    splitPlatformRequested = { eventName = 'splitPlatformRequested'},
}
local trackTypes = {
    eraA = {
        autoSplitTrackId = nil,
        autoSplitTrackName = 'lollo_freestyle_train_station/era_a_passenger_platform_5m_auto_split.lua',
        narrowTrackId = nil,
        narrowTrackName = 'lollo_freestyle_train_station/era_a_passenger_platform_2_5m.lua',
    },
    eraB = {
        autoSplitTrackId = nil,
        autoSplitTrackName = 'lollo_freestyle_train_station/era_b_passenger_platform_5m_auto_split.lua',
        narrowTrackId = nil,
        narrowTrackName = 'lollo_freestyle_train_station/era_b_passenger_platform_2_5m.lua',
    },
    eraC = {
        autoSplitTrackId = nil,
        autoSplitTrackName = 'lollo_freestyle_train_station/era_c_passenger_platform_5m_auto_split.lua',
        narrowTrackId = nil,
        narrowTrackName = 'lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua',
    },
}

local _utils = {
    guiInit = function()
        trackTypes.eraA.autoSplitTrackId = api.res.trackTypeRep.find(trackTypes.eraA.autoSplitTrackName)
        trackTypes.eraB.autoSplitTrackId = api.res.trackTypeRep.find(trackTypes.eraB.autoSplitTrackName)
        trackTypes.eraC.autoSplitTrackId = api.res.trackTypeRep.find(trackTypes.eraC.autoSplitTrackName)

        trackTypes.eraA.narrowTrackId = api.res.trackTypeRep.find(trackTypes.eraA.narrowTrackName)
        trackTypes.eraB.narrowTrackId = api.res.trackTypeRep.find(trackTypes.eraB.narrowTrackName)
        trackTypes.eraC.narrowTrackId = api.res.trackTypeRep.find(trackTypes.eraC.narrowTrackName)
    end,
}

local _actions = {
    replaceEdgeWithParallelNarrowTracks = function(oldEdgeId, newTrackTypeId)
        logger.print('replaceEdgeWithParallelNarrowTracks starting, oldEdgeId =', oldEdgeId, 'newTrackTypeId =', newTrackTypeId)
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end
        if not(edgeUtils.isValidId(newTrackTypeId)) then return end

        local oldBaseEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        if oldBaseEdge == nil then return end

        local oldTrackEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldTrackEdge
        if oldTrackEdge == nil then return end

        local oldNode0 = api.engine.getComponent(oldBaseEdge.node0, api.type.ComponentType.BASE_NODE)
        local oldNode1 = api.engine.getComponent(oldBaseEdge.node1, api.type.ComponentType.BASE_NODE)
        if oldNode0 == nil or oldNode1 == nil then return end

        local oldPosTanX2 = {
            {
                {
                    oldNode0.position.x,
                    oldNode0.position.y,
                    oldNode0.position.z,
                },
                {
                    oldBaseEdge.tangent0.x,
                    oldBaseEdge.tangent0.y,
                    oldBaseEdge.tangent0.z,
                },
            },
            {
                {
                    oldNode1.position.x,
                    oldNode1.position.y,
                    oldNode1.position.z,
                },
                {
                    oldBaseEdge.tangent1.x,
                    oldBaseEdge.tangent1.y,
                    oldBaseEdge.tangent1.z,
                },
            },
        }
        local newPosTanX2_1, xRatio_1, yRatio_1 = transfUtils.getParallelSideways(oldPosTanX2, 1.25)
        local newPosTanX2_2, xRatio_2, yRatio_2 = transfUtils.getParallelSideways(oldPosTanX2, -1.25)

        local proposal = api.type.SimpleProposal.new()
        local nNewEntities = -1
        ---@param position123 table<integer>
        ---@return integer
        local _addNode = function(position123)
            local _tolerance = 0.001
            local nodeIds = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position123),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position123[3] - _tolerance,
                position123[3] + _tolerance
            )
            if nodeIds[1] ~= nil then return nodeIds[1] end

            local newNode = api.type.NodeAndEntity.new()
            newNode.entity = nNewEntities
            newNode.comp.position.x = position123[1]
            newNode.comp.position.y = position123[2]
            newNode.comp.position.z = position123[3]

            proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd+1] = newNode
            nNewEntities = nNewEntities - 1
            return nNewEntities + 1
        end
        local node1_1Id = _addNode(newPosTanX2_1[1][1])
        local node1_2Id = _addNode(newPosTanX2_1[2][1])
        local node2_1Id = _addNode(newPosTanX2_2[1][1])
        local node2_2Id = _addNode(newPosTanX2_2[2][1])

        local newEdge_1 = api.type.SegmentAndEntity.new()
        newEdge_1.entity = nNewEntities
        newEdge_1.comp = oldBaseEdge
        newEdge_1.comp.node0 = node1_1Id
        newEdge_1.comp.node1 = node1_2Id
        newEdge_1.comp.tangent0.x = newPosTanX2_1[1][2][1]
        newEdge_1.comp.tangent0.y = newPosTanX2_1[1][2][2]
        newEdge_1.comp.tangent0.z = newPosTanX2_1[1][2][3]
        newEdge_1.comp.tangent1.x = newPosTanX2_1[2][2][1]
        newEdge_1.comp.tangent1.y = newPosTanX2_1[2][2][2]
        newEdge_1.comp.tangent1.z = newPosTanX2_1[2][2][3]
        newEdge_1.comp.objects = {}
        newEdge_1.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge_1.trackEdge.catenary = oldTrackEdge.catenary
        newEdge_1.trackEdge.trackType = newTrackTypeId
        newEdge_1.type = _constants.railEdgeType
        proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newEdge_1
        nNewEntities = nNewEntities -1

        local newEdge_2 = api.type.SegmentAndEntity.new()
        newEdge_2.entity = nNewEntities
        newEdge_2.comp = oldBaseEdge
        newEdge_2.comp.node0 = node2_1Id
        newEdge_2.comp.node1 = node2_2Id
        newEdge_2.comp.tangent0.x = newPosTanX2_2[1][2][1]
        newEdge_2.comp.tangent0.y = newPosTanX2_2[1][2][2]
        newEdge_2.comp.tangent0.z = newPosTanX2_2[1][2][3]
        newEdge_2.comp.tangent1.x = newPosTanX2_2[2][2][1]
        newEdge_2.comp.tangent1.y = newPosTanX2_2[2][2][2]
        newEdge_2.comp.tangent1.z = newPosTanX2_2[2][2][3]
        newEdge_2.comp.objects = {}
        newEdge_2.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge_2.trackEdge.catenary = oldTrackEdge.catenary
        newEdge_2.trackEdge.trackType = newTrackTypeId
        newEdge_2.type = _constants.railEdgeType
        proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newEdge_2

        -- remove nodes
        if #(edgeUtils.getConnectedEdgeIds({oldBaseEdge.node0})) < 2 then
            proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = oldBaseEdge.node0
        end
        if #(edgeUtils.getConnectedEdgeIds({oldBaseEdge.node1})) < 2 then
            proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = oldBaseEdge.node1
        end
        -- remove edge
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        -- remove edge objects
        local i = 1
        for _, edgeObj in pairs(oldBaseEdge.objects) do
            proposal.streetProposal.edgeObjectsToRemove[i] = edgeObj[1]
            i = i + 1
        end

        logger.print('lollo_auto_split_platform proposal =') logger.debugPrint(proposal)

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true),
            function(res, success)
                logger.print('lollo_auto_split_platform replaceEdgeWithParallelNarrowTracks success = ') logger.debugPrint(success)
                if not(success) then
                    logger.warn('replaceEdgeWithParallelNarrowTracks failed, proposal = ') logger.warningDebugPrint(proposal)
                end
            end
        )
    end,
}

function data()
    return {
        guiInit = function()
            _utils.guiInit()
            logger.print('trackTypes =') logger.debugPrint(trackTypes)
        end,
        -- guiUpdate = function()
        -- end,
        guiHandleEvent = function(id, name, args)
            -- args can have different types, even boolean, depending on the event id and name
            if (name == 'builder.apply') then
                if id == 'trackBuilder' or id == 'streetTrackModifier' then
                    xpcall(
                        function()
                            logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') logger.debugPrint(args)
                            if not(args) or not(args.proposal) or not(args.proposal.proposal)
                            or not(args.proposal.proposal.addedSegments)
                            or not(args.data)
                            or not(args.data.errorState)
                            or args.data.errorState.critical
                            then return end

                            local eventParams = {}
                            for _, addedSegment in pairs(args.proposal.proposal.addedSegments) do
                                logger.print('addedSegment =') logger.debugPrint(addedSegment)
                                if addedSegment
                                and addedSegment.trackEdge ~= nil
                                and addedSegment.trackEdge.trackType ~= nil
                                and (
                                    addedSegment.trackEdge.trackType == trackTypes.eraA.autoSplitTrackId
                                    or addedSegment.trackEdge.trackType == trackTypes.eraB.autoSplitTrackId
                                    or addedSegment.trackEdge.trackType == trackTypes.eraC.autoSplitTrackId
                                )
                                and edgeUtils.isValidAndExistingId(addedSegment.entity)
                                then
                                    logger.print('addedSegment =') logger.debugPrint(addedSegment)
                                    local conId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(addedSegment.entity)
                                    if not(edgeUtils.isValidId(conId)) then -- do not touch frozen segments
                                        -- local newTrackTypeId = nil
                                        for key, value in pairs(trackTypes) do
                                            logger.print('key =') logger.debugPrint(key)
                                            logger.print('value =') logger.debugPrint(value)
                                            if addedSegment.trackEdge.trackType == value.autoSplitTrackId then
                                                eventParams[#eventParams+1] = {
                                                    edgeId = addedSegment.entity,
                                                    newTrackTypeId = value.narrowTrackId,
                                                }
                                                break
                                            end
                                        end
                                        -- if addedSegment.trackEdge.trackType == trackTypes.eraA.autoSplitTrackId then
                                        --     newTrackTypeId = trackTypes.eraA.narrowTrackId
                                        -- elseif addedSegment.trackEdge.trackType == trackTypes.eraB.autoSplitTrackId then
                                        --     newTrackTypeId = trackTypes.eraB.narrowTrackId
                                        -- elseif addedSegment.trackEdge.trackType == trackTypes.eraC.autoSplitTrackId then
                                        --     newTrackTypeId = trackTypes.eraC.narrowTrackId
                                        -- end
                                        -- if newTrackTypeId ~= nil then
                                        --     eventParams[#eventParams+1] = {
                                        --         edgeId = addedSegment.entity,
                                        --         -- this must be done here coz it is initialised at guiInit()
                                        --         newTrackTypeId = newTrackTypeId,
                                        --     }
                                        -- end
                                    end
                                end
                            end
                            for i = 1, #eventParams do
                                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                    string.sub(debug.getinfo(1, 'S').source, 1),
                                    _eventId,
                                    _eventProperties.splitPlatformRequested.eventName,
                                    eventParams[i]
                                ))
                            end
                        end,
                        logger.xpErrorHandler
                    )
                end
            end
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end
            if type(args) ~= 'table' then return end

            xpcall(
                function()
                    logger.print('lollo_auto_split_platform.handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =') logger.debugPrint(args)

                    if name == _eventProperties.splitPlatformRequested.eventName then
                        _actions.replaceEdgeWithParallelNarrowTracks(args.edgeId, args.newTrackTypeId)
                    end
                end,
                logger.xpErrorHandler
            )
        end,
        -- update = function()
        -- end,
        -- save = function()
        --     -- only fires when the worker thread changes the state
        --     if not state then state = {} end
        --     if not state.isErrorReplacingConWithSnappyCopy then state.isErrorReplacingConWithSnappyCopy = false end
        --     return state
        -- end,
        -- load = function(loadedState)
        --     -- fires once in the worker thread, at game load, and many times in the UI thread
        --     if loadedState then
        --         state = {}
        --         state.isErrorReplacingConWithSnappyCopy = loadedState.isErrorReplacingConWithSnappyCopy or false
        --     else
        --         state = {
        --             isErrorReplacingConWithSnappyCopy = false,
        --         }
        --     end
        -- end,
    }
end
