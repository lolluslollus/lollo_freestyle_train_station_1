local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local guiHelpers = require('lollo_open_lifts_open_stairs_free.guiHelpers')
local logger = require('lollo_freestyle_train_station.logger')
local moduleHelpers = require('lollo_open_lifts_open_stairs_free.moduleHelpers')
local openStairsHelpers = require('lollo_freestyle_train_station.openLiftOpenStairsHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtilsUG = require('transf')


local _eventId = '__lolloOpenLiftOpenStairsFree__'
local _eventProperties = {
    conBuilt = {eventName = 'conBuilt'},
    conParamsUpdated = {eventName = 'conParamsUpdated'},
    openLiftBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openLiftFree.con', eventName = 'openLiftBuilt' },
    openStairsBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openStairsFree.con', eventName = 'openStairsBuilt' },
    openTwinStairsBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openTwinStairsFree.con', eventName = 'openTwinStairsBuilt' },
}

-- only accessible in the UI thread
local _guiData = {
    conOpenLiftParamsMetadataSorted = {},
    conOpenStairsParamsMetadataSorted = {},
    conOpenTwinStairsParamsMetadataSorted = {},
    isExperimentalParamsMenu = false,
}

-- LOLLO NOTE this whole script is to change construction parameters from my own menu,
-- so a parameter change that causes a minor error will be carried out anyway.
-- It works, but two snapping stairs will break their link if one has a parameter altered
-- (even an insignificant one such as the era style),
-- and they won't snap again.
-- LOLLO TODO see if this improves with new game builds

--[[ local function _isBuildingConstructionWithFileName(args, fileName)
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
end ]]

local _utils = {
    getIsProposalOK = function(proposal, context)
        logger.print('getIsProposalOK starting')
        if not(proposal) then logger.err('getIsProposalOK got no proposal') return false end
        -- if not(context) then logger.err('getIsProposalOK got no context') return false end

        local isErrorsOtherThanCollision = false
        local isWarnings = false
        xpcall(
            function()
                -- this tries to build the construction, it calls con.updateFn()
                -- UG TODO this should never crash, but it crashes in the construction thread, and it is uncatchable here.
                local proposalData = api.engine.util.proposal.makeProposalData(proposal, context)
                -- logger.print('getIsProposalOK proposalData =') logger.debugPrint(proposalData)

                if proposalData.errorState ~= nil then
                    if proposalData.errorState.critical == true then
                        logger.print('proposalData.errorState.critical is true')
                        logger.print('proposalData.errorState =') logger.debugPrint(proposalData.errorState)
                        isErrorsOtherThanCollision = true
                    else
                        for _, message in pairs(proposalData.errorState.messages or {}) do
                            logger.print('looping over messages, message found =', message)
                            if message ~= 'Collision' then
                                isErrorsOtherThanCollision = true
                                logger.print('found message', message or 'NIL')
                                break
                            end
                        end
                        for _, warning in pairs(proposalData.errorState.warnings or {}) do
                            logger.print('looping over warnings, warning found =', warning)
                            if warning ~= 'Main connection will be interrupted' then
                                isWarnings = true
                                logger.print('found warning', warning or 'NIL')
                                break
                            end
                        end
                    end
                end
            end,
            function(error)
                isErrorsOtherThanCollision = true
                logger.warn('getIsProposalOK caught an exception')
                logger.xpWarningHandler(error)
            end
        )
        logger.print('getIsProposalOK isErrorsOtherThanCollision =', isErrorsOtherThanCollision)
        logger.print('getIsProposalOK isWarnings =', isWarnings)
        return not(isErrorsOtherThanCollision) -- and not(isWarnings)
    end,
}

local _actions = {
    replaceConWithSnappyCopyUNUSED = function(oldConId)
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
                            -- UG TODO there is no such thing in the new api, nor an upgrade event, both would be useful
                            logger.print('oldConId =') logger.debugPrint(oldConId)
                            logger.print('result.resultEntities[1] =') logger.debugPrint(result.resultEntities[1])
                            logger.print('result.resultProposalData.errorState =') logger.debugPrint(result.resultProposalData.errorState)
                            logger.print('oldConstruction.fileName =') logger.debugPrint(oldConstruction.fileName)
                            collectgarbage() -- LOLLO TODO this is a stab in the dark to try and avoid crashes in the following
                            logger.print('collectgarbage done')
                            logger.print('result.resultEntities[1] =') logger.debugPrint(result.resultEntities[1])
                            logger.print('oldConstruction.fileName =') logger.debugPrint(oldConstruction.fileName)
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
    updateConstruction = function(oldConId, paramKey, newParamValueIndexBase0)
        logger.print('updateConstruction starting, conId =', oldConId or 'NIL')

        if not(edgeUtils.isValidAndExistingId(oldConId)) then
            logger.warn('updateConstruction received an invalid conId')
            return
        end
        local oldCon = api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil then
            logger.warn('updateConstruction cannot get the con')
            return
        end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName
        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        newParams[paramKey] = newParamValueIndexBase0

        newParams.seed = newParams.seed + 1
        -- clone your own variable, it's safer than cloning newCon.params, which is userdata
        local conParamsBak = arrayUtils.cloneDeepOmittingFields(newParams)
        newCon.params = newParams
        logger.print('oldCon.params =') logger.debugPrint(oldCon.params)
        logger.print('newCon.params =') logger.debugPrint(newCon.params)
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf
        local conTransf_lua = transfUtilsUG.new(newCon.transf:cols(0), newCon.transf:cols(1), newCon.transf:cols(2), newCon.transf:cols(3))

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { oldConId }
        -- proposal.old2new = { oldConId, 1 } -- this is wrong and makes trouble like
        -- C:\GitLab-Runner\builds\1BJoMpBZ\0\ug\urban_games\train_fever\src\Game\UrbanSim\StockListUpdateHelper.cpp:166: __cdecl StockListUpdateHelper::~StockListUpdateHelper(void) noexcept(false): Assertion `0 <= pr.second && pr.second < (int)m_data->addedEntities->size()' failed.

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()
        -- Sometimes, the game fails in the following; UG does not handle the failure graacefully and the game crashes with "an error just occurred" and no useful info.
        if not(_utils.getIsProposalOK(proposal, context)) then
            logger.warn('updateConstruction made a dangerous proposal')
            -- LOLLO TODO give feedback
            return
        end

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('updateConstruction callback, success =', success)
                -- logger.debugPrint(result)
                if not(success) then
                    logger.warn('updateConstruction callback failed')
                    logger.warn('updateConstruction proposal =') logger.warningDebugPrint(proposal)
                    logger.warn('updateConstruction result =') logger.warningDebugPrint(result)
                    -- LOLLO TODO give feedback
                else
                    local newConId = result.resultEntities[1]
                    logger.print('updateConstruction succeeded, stationConId = ', newConId)
                    xpcall(
                        function ()
                            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                string.sub(debug.getinfo(1, 'S').source, 1),
                                _eventId,
                                _eventProperties.conBuilt.eventName,
                                {
                                    conId = newConId,
                                    conParams = conParamsBak,
                                    conTransf = conTransf_lua,
                                }
                            ))
                        end,
                        function(error)
                            logger.xpErrorHandler(error)
                        end
                    )
                end
            end
        )
    end,
}

local _handlers = {
    guiHandleParamValueChanged = function(conId, paramsMetadata, paramKey, newParamValueIndexBase0)
        logger.print('guiHandleParamValueChanged firing')
        logger.print('conId =') logger.debugPrint(conId)
        logger.print('paramsMetadata =') logger.debugPrint(paramsMetadata)
        logger.print('paramKey =') logger.debugPrint(paramKey)
        logger.print('newParamValueIndexBase0 =') logger.debugPrint(newParamValueIndexBase0)
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warn('guiHandleParamValueChanged got no con or no valid con')
        end

        xpcall(
            function ()
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    _eventId,
                    _eventProperties.conParamsUpdated.eventName,
                    {
                        conId = conId,
                        paramKey = paramKey,
                        newParamValueIndexBase0 = newParamValueIndexBase0,
                    }
                ))
            end,
            logger.xpErrorHandler
        )
    end,
}

function data()
    return {
        guiHandleEvent = function(id, name, args)
            if not(_guiData.isExperimentalParamsMenu) then return end
            -- logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') -- logger.debugPrint(args)
            -- LOLLO NOTE param can have different types, even boolean, depending on the event id and name
            if (name == 'select' and id == 'mainView') then
                -- select happens after idAdded, which looks like:
                -- id =	temp.view.entity_28693	name =	idAdded
                -- id =	temp.view.entity_26372	name =	idAdded
                xpcall(
                    function()
                        logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') logger.debugPrint(args)
                        local conId = args
                        if not(edgeUtils.isValidAndExistingId(conId)) then return end

                        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                        if con == nil or not(arrayUtils.arrayHasValue({_eventProperties.openLiftBuilt.conName, _eventProperties.openStairsBuilt.conName, _eventProperties.openTwinStairsBuilt.conName}, con.fileName)) then return end

                        logger.print('selected open stairs or lift, it has conId =', conId, 'and con.fileName =', con.fileName)
                        if con.fileName == _eventProperties.openLiftBuilt.conName then
                            if not(_guiData.conOpenLiftParamsMetadataSorted) then
                                logger.print('_guiData.conOpenLiftParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addConConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenLiftParamsMetadataSorted, con.params)
                        elseif con.fileName == _eventProperties.openStairsBuilt.conName then
                            if not(_guiData.conOpenStairsParamsMetadataSorted) then
                                logger.print('_guiData.conOpenStairsParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addConConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenStairsParamsMetadataSorted, con.params)
                        elseif con.fileName == _eventProperties.openTwinStairsBuilt.conName then
                            if not(_guiData.conOpenTwinStairsParamsMetadataSorted) then
                                logger.print('_guiData.conOpenTwinStairsParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addConConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenTwinStairsParamsMetadataSorted, con.params)
                        end
                    end,
                    logger.xpErrorHandler
                )
            end
        end,
        guiInit = function()
            -- logger.print('guiInit starting')
            _guiData.conOpenLiftParamsMetadataSorted = moduleHelpers.getOpenLiftParamsMetadata()
            _guiData.conOpenStairsParamsMetadataSorted = moduleHelpers.getOpenStairsParamsMetadata()
            _guiData.conOpenTwinStairsParamsMetadataSorted = moduleHelpers.getOpenTwinStairsParamsMetadata()
            -- logger.print('guiInit ending')
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end
            logger.print('handleEvent starting, src =', src, ', id =', id, ', name =', name, ', args =') logger.debugPrint(args)
            if type(args) ~= 'table' then return end

            xpcall(
                function()
                    if name == _eventProperties.conParamsUpdated.eventName then
                        _actions.updateConstruction(args.conId, args.paramKey, args.newParamValueIndexBase0)
                    elseif name == _eventProperties.conBuilt.eventName then
                        -- do nothing for now
                    end
                end,
                function(error)
                    logger.xpErrorHandler(error)
                end
            )
        end,
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
