local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local openStairsHelpers = require('lollo_freestyle_train_station.openLiftOpenStairsHelpers')
local streetUtils = require('lollo_freestyle_train_station.streetUtils')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')


local _eventId = '__lolloOpenLiftOpenStairsFree__'
local _eventProperties = {
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
    replaceConWithSnappyCopy = function(oldConId)
        -- We don't use this anymore, check out the NOTE below.

        -- Rebuild the station with the same but snappy, to prevent pointless internal conflicts
        -- that will prevent using the construction mover
        logger.print('replaceConWithSnappyCopy starting, oldConId =', oldConId)
        if not(edgeUtils.isValidAndExistingId(oldConId)) then return end

        local oldConstruction = api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
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
        if not(newBaseParamValue) and not(newBridgeParamValue) then return end -- leave if nothing is going to change

        local newConstruction = api.type.SimpleProposal.ConstructionEntity.new()
        newConstruction.fileName = oldConstruction.fileName

        local newParams = arrayUtils.cloneDeepOmittingFields(oldConstruction.params, nil, true)
        newParams.seed = oldConstruction.params.seed + 1
        -- this is what this is all about
        if newBaseParamValue then newParams[newBaseParamValue.name] = newBaseParamValue.value end
        if newBridgeParamValue then newParams[newBridgeParamValue.name] = newBridgeParamValue.value end
        logger.print('newParams =') logger.debugPrint(newParams)
        local paramsBak = arrayUtils.cloneDeepOmittingFields(newParams, {'seed'})
        newConstruction.params = newParams

        newConstruction.transf = oldConstruction.transf
        newConstruction.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newConstruction
        -- LOLLO NOTE different tables are handled differently.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { oldConId }
        -- proposal.constructionsToRemove[1] = oldConId -- fails to add
        -- proposal.constructionsToRemove:add(oldConId) -- fails to add
        -- proposal.old2new = { -- expected number, received table
        --     { oldConId, 1 }
        -- }
        -- proposal.old2new = {
        --     oldConId, 1
        -- }
        -- proposal.old2new = {
        --     oldConId,
        -- }

        -- local context = api.type.Context:new() -- useless: sometimes, snappy connections will break when rebuilding the con
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        local cmd = api.cmd.make.buildProposal(proposal, nil, false) -- the 2nd param is context, the 3rd is "ignore errors"
        api.cmd.sendCommand(cmd, function(result, success)
            -- logger.print('LOLLO _replaceConWithSnappyCopy result = ') logger.debugPrint(result)
            logger.print('LOLLO _replaceConWithSnappyCopy success = ') logger.debugPrint(success)
            if success then
                xpcall(
                    function()
                        if result
                        and result.resultProposalData
                        and result.resultProposalData.errorState
                        and not(result.resultProposalData.errorState.critical)
                        and result.resultEntities
                        and result.resultEntities[1] ~= nil
                        and result.resultEntities[1] > 0
                        then
                            -- UG TODO there is no such thing in the new api,
                            -- nor an upgrade event, both would be useful
                            logger.print('oldConId =') logger.debugPrint(oldConId)
                            logger.print('result.resultEntities[1] =') logger.debugPrint(result.resultEntities[1])
                            logger.print('oldConstruction.fileName =') logger.debugPrint(oldConstruction.fileName)
                            -- collectgarbage() -- LOLLO TODO this might work, check it
                            local upgradedConId = game.interface.upgradeConstruction(
                                result.resultEntities[1],
                                oldConstruction.fileName,
                                paramsBak
                            )
                            logger.print('upgradeConstruction succeeded') logger.debugPrint(upgradedConId)
                        else
                            logger.warn('cannot upgrade construction')
                        end
                    end,
                    function(error)
                        logger.warn(error)
                    end
                )
            end
        end)
    end,
}

function data()
    return {
--[[
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
        -- guiUpdate = function()
        -- end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            if (name == 'builder.apply') then
                if id == 'constructionBuilder' then
                    -- LOLLO NOTE as of build 35050 (or the one before),
                    -- transforming unsnapping edge nodes into snapping ones might break the connection
                    -- and game.interface.upgradeConstruction often fails to restore it.
                    -- This breaks wysiwyg, so we don't do it anymore.
                    logger.print('guiHandleEvent caught id = constructionBuilder and name = builder.apply')
                    xpcall(
                        function()
                            if not args.result or not args.result[1] then return end
                            if args.data.errorState and args.data.errorState.critical then logger.warn('cannot rebuild snappy copy') return end

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

        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end
            if type(args) ~= 'table' then return end

            xpcall(
                function()
                    logger.print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =') logger.debugPrint(args)

                    if edgeUtils.isValidAndExistingId(args.conId) then
                        if name == _eventProperties.openLiftBuilt.eventName or name == _eventProperties.openStairsBuilt.eventName then
                            logger.print('about to call replaceConWithSnappyCopy')
                            _actions.replaceConWithSnappyCopy(args.conId)
                        end
                    end
                end,
                logger.xpErrorHandler
            )
        end,
]]
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
