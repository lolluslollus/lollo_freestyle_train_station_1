local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local openStairsHelpers = require('lollo_freestyle_train_station.openLiftOpenStairsHelpers')
local streetUtils = require('lollo_freestyle_train_station.streetUtils')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')


local _compTypeBridge = 1
local _eventId = 'lolloOpenLiftOpenStairsFree'
local _eventProperties = {
    buildBridgeRequested = { eventName = 'buildBridgeRequested'},
    openLiftBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openLiftFree.con', eventName = 'openLiftBuilt' },
    openStairsBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openStairsFree.con', eventName = 'openStairsBuilt' },
}
local function _isBuildingConstructionWithFileName(args, fileName)
    local toAdd =
        type(args) == 'table' and type(args.proposal) == 'userdata' and type(args.proposal.toAdd) == 'userdata' and
        args.proposal.toAdd

    if toAdd and #toAdd > 0 then
        for i = 1, #toAdd do
            if toAdd[i].fileName == fileName then
                return true
            end
        end
    end

    return false
end

local function _isBuildingOpenLift(args)
    return _isBuildingConstructionWithFileName(args, _eventProperties.openLiftBuilt.conName)
end

local function _isBuildingOpenStairs(args)
    return _isBuildingConstructionWithFileName(args, _eventProperties.openStairsBuilt.conName)
end

local _actions = {
    replaceConWithSnappyCopy = function(oldConstructionId)
        -- rebuild the station with the same but snappy, to prevent pointless internal conflicts
        -- that will prevent using the construction mover
        logger.print('replaceConWithSnappyCopy starting, oldConstructionId =', oldConstructionId)
        if not(edgeUtils.isValidAndExistingId(oldConstructionId)) then return end

        local oldConstruction = api.engine.getComponent(oldConstructionId, api.type.ComponentType.CONSTRUCTION)
        logger.print('oldConstruction =') logger.debugPrint(oldConstruction)
        if not(oldConstruction)
        or not(oldConstruction.params)
        then return end

        local newBaseParamValue, newBridgeParamValue
        if oldConstruction.fileName == _eventProperties.openLiftBuilt.conName then
            newBaseParamValue  = openStairsHelpers.autoSnapHelper.lift.getBaseNewValue4Snappy(oldConstruction.params)
            newBridgeParamValue = openStairsHelpers.autoSnapHelper.lift.getBridgeNewValue4Snappy(oldConstruction.params)
        elseif oldConstruction.fileName == _eventProperties.openStairsBuilt.conName then
            newBaseParamValue  = openStairsHelpers.autoSnapHelper.stairs.getBaseNewValue4Snappy(oldConstruction.params)
            newBridgeParamValue = openStairsHelpers.autoSnapHelper.stairs.getBridgeNewValue4Snappy(oldConstruction.params)
        else
            return
        end
        if not(newBaseParamValue) and not(newBridgeParamValue) then return end

        local newConstruction = api.type.SimpleProposal.ConstructionEntity.new()
        newConstruction.fileName = oldConstruction.fileName

        local newParams = arrayUtils.cloneDeepOmittingFields(oldConstruction.params, nil, true)
        newParams.seed = oldConstruction.params.seed + 1
        -- this is what this is all about
        if newBaseParamValue then newParams[newBaseParamValue.name] = newBaseParamValue.value end
        if newBridgeParamValue then newParams[newBridgeParamValue.name] = newBridgeParamValue.value end

        logger.print('newParams =') logger.debugPrint(newParams)
        newConstruction.params = newParams

        newConstruction.transf = oldConstruction.transf
        newConstruction.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newConstruction
        -- LOLLO NOTE different tables are handled differently.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { oldConstructionId }
        -- proposal.constructionsToRemove[1] = oldConstructionId -- fails to add
        -- proposal.constructionsToRemove:add(oldConstructionId) -- fails to add
        -- proposal.old2new = { -- expected number, received table
        --     { oldConstructionId, 1 }
        -- }
        -- proposal.old2new = {
        --     oldConstructionId, 1
        -- }
        -- proposal.old2new = {
        --     oldConstructionId,
        -- }

        -- local context = api.type.Context:new()
        -- context.checkTerrainAlignment = false -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = false -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        local cmd = api.cmd.make.buildProposal(proposal, nil, true) -- the 3rd param is "ignore errors"
        api.cmd.sendCommand(cmd, function(res, success)
            -- logger.print('LOLLO _replaceConWithSnappyCopy res = ')
            -- logger.debugPrint(res)
            --for _, v in pairs(res.entities) do logger.print(v) end
            logger.print('LOLLO _replaceConWithSnappyCopy success = ') logger.debugPrint(success)
            -- if success then
                -- LOLLO NOTE the following was not required before beta 350**, it is useless after 35041
                -- xpcall(
                --     function()
                --         -- UG TODO there is no such thing in the new api,
                --         -- nor an upgrade event, which could be useful
                --         logger.print('oldConId =') logger.debugPrint(oldConId)
                --         logger.print('result.resultEntities[1] =') logger.debugPrint(result.resultEntities[1])
                --         logger.print('oldConstruction.fileName =') logger.debugPrint(oldConstruction.fileName)
                --         local upgradedConId = game.interface.upgradeConstruction(
                --             result.resultEntities[1],
                --             oldConstruction.fileName,
                --             paramsBak
                --         )
                --         logger.print('upgradeConstruction succeeded') logger.debugPrint(upgradedConId)
                --     end,
                --     function(error)
                --         logger.err(error)
                --     end
                -- )
            -- end
        end)
    end,
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
            openStairsHelpers.eraA.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraA.bridgeTypeName_withRailing)
            openStairsHelpers.eraB.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraB.bridgeTypeName_withRailing)
            openStairsHelpers.eraC.bridgeTypeId_withRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraC.bridgeTypeName_withRailing)

            openStairsHelpers.eraA.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraA.bridgeTypeName_noRailing)
            openStairsHelpers.eraB.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraB.bridgeTypeName_noRailing)
            openStairsHelpers.eraC.bridgeTypeId_noRailing = api.res.bridgeTypeRep.find(openStairsHelpers.eraC.bridgeTypeName_noRailing)

            openStairsHelpers.eraA.streetTypeId_withBridge = api.res.streetTypeRep.find(openStairsHelpers.eraA.streetTypeName_withBridge)
            openStairsHelpers.eraB.streetTypeId_withBridge = api.res.streetTypeRep.find(openStairsHelpers.eraB.streetTypeName_withBridge)
            openStairsHelpers.eraC.streetTypeId_withBridge = api.res.streetTypeRep.find(openStairsHelpers.eraC.streetTypeName_withBridge)
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
                    elseif edgeUtils.isValidAndExistingId(args.conId) then
                        if name == _eventProperties.openLiftBuilt.eventName or name == _eventProperties.openStairsBuilt.eventName then
                            logger.print('TWO')
                            _actions.replaceConWithSnappyCopy(args.conId)
                        end
                    end
                end,
                logger.xpErrorHandler
            )
        end,
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
                                    if addedSegment and addedSegment.streetEdge and addedSegment.comp and addedSegment.comp.type ~= _compTypeBridge then
                                        -- print('addedSegment =') debugPrint(addedSegment)
                                        local bridgeTypeId = openStairsHelpers.getBridgeTypeId(addedSegment.streetEdge.streetType, true)
                                        if bridgeTypeId then
                                            forceBridgeEventParams[#forceBridgeEventParams+1] = {
                                                edgeId = addedSegment.entity,
                                                bridgeTypeId = bridgeTypeId
                                            }
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
                elseif id == 'constructionBuilder' then
                    logger.print('guiHandleEvent caught id = constructionBuilder and name = builder.apply')
                    xpcall(
                        function()
                            if not args.result or not args.result[1] then return end

                            local _sendCommand = function(eventName)
                                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                    string.sub(debug.getinfo(1, 'S').source, 1),
                                    _eventId,
                                    eventName,
                                    {
                                        conId = args.result[1]
                                    }
                                ))
                            end

                            if _isBuildingOpenLift(args) then
                                _sendCommand(_eventProperties.openLiftBuilt.eventName)
                            elseif _isBuildingOpenStairs(args) then
                                _sendCommand(_eventProperties.openStairsBuilt.eventName)
                            end
                        end,
                        logger.xpErrorHandler
                    )
                end
            end
        end,
        -- update = function()
        -- end,
        -- guiUpdate = function()
        -- end,
        -- save = function()
        --     -- only fires when the worker thread changes the state
        -- end,
        -- load = function(loadedState)
        --     -- fires once in the worker thread, at game load, and many times in the UI thread
        -- end,
    }
end