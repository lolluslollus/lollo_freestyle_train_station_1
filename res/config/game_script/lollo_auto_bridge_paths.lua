local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local autoBridgePathsHelper = require('lollo_freestyle_train_station.autoBridgePathsHelper')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local streetUtils = require('lollo_freestyle_train_station.streetUtils')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')


local _compTypeBridge = 1
local _eventId = '__lolloAutoBridgePaths__'
local _eventProperties = {
    buildBridgeRequested = { eventName = 'buildBridgeRequested'},
}

local _actions = {
    replaceEdgeWithSameOnBridge = function(oldEdgeId, bridgeTypeId)
        logger.print('replaceEdgeWithSameOnBridge starting, oldEdgeId =', oldEdgeId, 'bridgeTypeId =', bridgeTypeId or 'NIL')
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        if oldEdge == nil or oldEdge.type == _compTypeBridge then return end

        local oldEdgeStreet = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_STREET)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeStreet
        if oldEdgeStreet == nil then return end

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = 0 -- 0 is api.type.enum.Carrier.ROAD, 1 is api.type.enum.Carrier.RAIL
        newEdge.comp = oldEdge
        newEdge.comp.type = _compTypeBridge
        newEdge.comp.typeIndex = bridgeTypeId -- bridge type
        newEdge.comp.objects = {}
        -- newEdge.playerOwned = {player = api.engine.util.getPlayer()}
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge.streetEdge = oldEdgeStreet

        -- LOLLO NOTE here, we do the same as the street fine tuning would do,
        -- if it could catch the build event, which is not guaranteed.
        -- We need this coz we cannot raise a gui event, obviously, so the street fine tuning cannot do its thing.
        -- add / remove tram tracks upgrade if the new street type explicitly wants so
        if streetUtils.isTramRightBarred(newEdge.streetEdge.streetType) then
            newEdge.streetEdge.tramTrackType = 0
        elseif streetUtils.isStreetAllTramTracks((api.res.streetTypeRep.get(newEdge.streetEdge.streetType) or {}).laneConfigs) then
            newEdge.streetEdge.tramTrackType = 2
        end
        -- add bus lane and bar tram if the new street type wants so (paths)
        if streetUtils.isPath(newEdge.streetEdge.streetType) then
            newEdge.streetEdge.hasBus = true
            newEdge.streetEdge.tramTrackType = 0
        end

        -- -- leave if nothing changed
        -- if newEdge.streetEdge.streetType == oldEdgeStreet.streetType
        -- and newEdge.streetEdge.tramTrackType == oldEdgeStreet.tramTrackType
        -- and newEdge.streetEdge.hasBus == oldEdgeStreet.hasBus
        -- and newEdge.comp.type == oldEdge.comp.type
        -- and newEdge.comp.typeIndex == oldEdge.comp.typeIndex
        -- then return end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        -- remove edge objects, they are not allowed on bridges
        local i = 1
        for _, edgeObj in pairs(oldEdge.objects) do
            proposal.streetProposal.edgeObjectsToRemove[i] = edgeObj[1]
            i = i + 1
        end
        logger.print('lollo_open_stairs_free proposal =') logger.debugPrint(proposal)

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true),
            function(res, success)
                logger.print('lollo_open_stairs_free replaceEdgeWithSameOnBridge success = ') logger.debugPrint(success)
                if not(success) then
                    logger.print('Warning: lollo_open_stairs_free.replaceEdgeWithStreetType failed, proposal = ') logger.debugPrint(proposal)
                end
            end
        )
    end,
}

function data()
    return {
        guiInit = function()
            autoBridgePathsHelper.guiInit()
        end,
        -- guiUpdate = function()
        -- end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            if (name == 'builder.apply') then
                if id == 'streetBuilder' or id == 'streetTrackModifier' then
                    xpcall(
                        function()
                            logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') logger.debugPrint(args)

                            if (not(args.data.errorState) or not(args.data.errorState.critical))
                            and (args.proposal) and (args.proposal.proposal) and (args.proposal.proposal.addedSegments)
                            then
                                local forceBridgeEventParams = {}
                                for _, addedSegment in pairs(args.proposal.proposal.addedSegments) do
                                    if addedSegment
                                    and addedSegment.streetEdge
                                    and addedSegment.comp
                                    and addedSegment.comp.type ~= _compTypeBridge
                                    and edgeUtils.isValidAndExistingId(addedSegment.entity)
                                    then
                                        -- print('addedSegment =') debugPrint(addedSegment)
                                        local conId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(addedSegment.entity)
                                        if not(edgeUtils.isValidId(conId)) then -- do not touch frozen segments
                                            local bridgeTypeId = autoBridgePathsHelper.getBridgeTypeId(addedSegment.streetEdge.streetType, true)
                                            if bridgeTypeId then
                                                forceBridgeEventParams[#forceBridgeEventParams+1] = {
                                                    edgeId = addedSegment.entity,
                                                    bridgeTypeId = bridgeTypeId
                                                }
                                            end
                                        end
                                    end
                                end
                                for i = 1, #forceBridgeEventParams do
                                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                        string.sub(debug.getinfo(1, 'S').source, 1),
                                        _eventId,
                                        _eventProperties.buildBridgeRequested.eventName,
                                        forceBridgeEventParams[i]
                                    ))
                                end
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
                    logger.print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =') logger.debugPrint(args)

                    if edgeUtils.isValidAndExistingId(args.edgeId) then
                        if name == _eventProperties.buildBridgeRequested.eventName then
                            _actions.replaceEdgeWithSameOnBridge(
                                args.edgeId,
                                args.bridgeTypeId
                            )
                        end
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
