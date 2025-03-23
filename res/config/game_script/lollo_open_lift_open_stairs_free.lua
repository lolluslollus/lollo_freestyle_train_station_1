local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local guiHelpers = require('lollo_open_lifts_open_stairs_free.guiHelpers')
local logger = require('lollo_freestyle_train_station.logger')
local openStairsHelpers = require('lollo_open_lifts_open_stairs_free.openLiftOpenStairsHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtilsUG = require('transf')


local _eventId = '__lolloOpenLiftOpenStairsFree__'
local _eventProperties = {
    conBuilt = {eventName = 'conBuilt'},
    conParamsUpdated = {eventName = 'conParamsUpdated'},
    -- openLiftBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openLiftFree.con', eventName = 'openLiftBuilt' },
    openLiftSelected = { conName = 'station/rail/lollo_freestyle_train_station/openLiftFree_v2.con', eventName = 'openLiftSelected' },
    openStairsSelected = { conName = 'station/rail/lollo_freestyle_train_station/openStairsFree.con', eventName = 'openStairsSelected' },
    openStairsSelected_v2 = { conName = 'station/rail/lollo_freestyle_train_station/openStairsFree_v2.con', eventName = 'openStairsSelected_v2' },
    -- openTwinStairsBuilt = { conName = 'station/rail/lollo_freestyle_train_station/openTwinStairsFree.con', eventName = 'openTwinStairsBuilt' },
    openTwinStairsSelected = { conName = 'station/rail/lollo_freestyle_train_station/openTwinStairsFree_v2.con', eventName = 'openTwinStairsSelected' },
}

-- only accessible in the UI thread
local _guiData = {
    conOpenLiftParamsMetadataSorted = {},
    conOpenStairsParamsMetadataSorted = {},
    conOpenStairsParamsMetadataSorted_v2 = {},
    conOpenTwinStairsParamsMetadataSorted = {},
    isExperimentalParamsMenu = true,
}

-- LOLLO NOTE this whole script is to change construction parameters from my own menu,
-- so a parameter change that causes a minor error will be carried out anyway.
-- It works, but two snapping stairs will break their link if one has a parameter altered
-- (even an insignificant one such as the era style),
-- and they won't snap again.
-- LOLLO TODO see if this improves with new game builds

local _utils = {
    getIsProposalOK = function(proposal, context)
        logger.print('_getIsProposalOK starting')
        if not(proposal) then logger.err('_getIsProposalOK got no proposal') return false end
        -- if not(context) then logger.err('_getIsProposalOK got no context') return false end

        local isErrorsOtherThanCollision = false
        local isWarnings = false
        xpcall(
            function()
                -- this tries to build the construction, it calls con.updateFn()
                -- UG TODO this should never crash, but it crashes in the construction thread, and it is uncatchable here.
                local proposalData = api.engine.util.proposal.makeProposalData(proposal, context)
                -- logger.print('_getIsProposalOK proposalData =') logger.debugPrint(proposalData)

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
                logger.warn('_getIsProposalOK caught an exception')
                logger.xpWarningHandler(error)
            end
        )
        logger.print('_getIsProposalOK isErrorsOtherThanCollision =', isErrorsOtherThanCollision)
        logger.print('_getIsProposalOK isWarnings =', isWarnings)
        return not(isErrorsOtherThanCollision) -- and not(isWarnings)
    end,
}

local _actions = {
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
        logger.print('updateConstruction found oldCon.fileName =') logger.debugPrint(oldCon.fileName)
        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        newParams[paramKey] = newParamValueIndexBase0 -- this is what this func is all about
        newParams.seed = newParams.seed + 1 -- otherwise the game complains
        local paramsBak_NoSeed = arrayUtils.cloneDeepOmittingFields(newParams, {'seed'})
        newCon.params = newParams
        logger.print('oldCon.params =') logger.debugPrint(oldCon.params)
        logger.print('newCon.params =') logger.debugPrint(newCon.params)
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf
        -- local conTransf_lua = transfUtilsUG.new(newCon.transf:cols(0), newCon.transf:cols(1), newCon.transf:cols(2), newCon.transf:cols(3))

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
                    return xpcall(
                        function()
                            local newConId = result.resultEntities[1]
                            logger.print('updateConstruction succeeded, stationConId = ', newConId)
                            -- UG TODO there is no such thing in the new api, nor an upgrade event, both would be useful
                            -- print('api.util.getLuaUsedMemory() before = ' .. tostring(api.util.getLuaUsedMemory()))
                            collectgarbage() -- LOLLO TODO this is a stab in the dark to try and avoid crashes in the following
                            -- print('api.util.getLuaUsedMemory() after = ' .. tostring(api.util.getLuaUsedMemory()))
                            logger.print('lollo_open_lifts_open_stairs_free - collect garbage done')
                            logger.print('oldCon.fileName =') logger.debugPrint(oldCon.fileName)
                            local upgradedConId = game.interface.upgradeConstruction(
                                newConId,
                                oldCon.fileName,
                                paramsBak_NoSeed
                            )
                            -- print('api.util.getLuaUsedMemory() before = ' .. tostring(api.util.getLuaUsedMemory()))
                            -- collectgarbage()
                            -- print('api.util.getLuaUsedMemory() after = ' .. tostring(api.util.getLuaUsedMemory()))
                            logger.print('updateConstruction upgraded con =') logger.debugPrint(upgradedConId)
                        end,
                        function(error)
                            logger.warn('updateConstruction failed to upgrade con')
                            logger.warn(error)
                            -- print('api.util.getLuaUsedMemory() before = ' .. tostring(api.util.getLuaUsedMemory()))
                            -- collectgarbage()
                            -- print('api.util.getLuaUsedMemory() after = ' .. tostring(api.util.getLuaUsedMemory()))
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
                        if con == nil or not(arrayUtils.arrayHasValue(
                            {
                                _eventProperties.openLiftSelected.conName,
                                _eventProperties.openStairsSelected.conName,
                                _eventProperties.openStairsSelected_v2.conName,
                                _eventProperties.openTwinStairsSelected.conName
                            },
                            con.fileName
                        )) then return end

                        logger.print('selected open stairs or lift, it has conId =', conId, 'and con.fileName =', con.fileName)
                        if con.fileName == _eventProperties.openLiftSelected.conName then
                            if not(_guiData.conOpenLiftParamsMetadataSorted) then
                                logger.warn('_guiData.conOpenLiftParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addEntityConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenLiftParamsMetadataSorted, con.params)
                        elseif con.fileName == _eventProperties.openStairsSelected.conName then
                            if not(_guiData.conOpenStairsParamsMetadataSorted) then
                                logger.warn('_guiData.conOpenStairsParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addEntityConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenStairsParamsMetadataSorted, con.params)
                        elseif con.fileName == _eventProperties.openStairsSelected_v2.conName then
                            if not(_guiData.conOpenStairsParamsMetadataSorted_v2) then
                                logger.warn('_guiData.conOpenStairsParamsMetadataSorted_v2 is not available')
                                return
                            end

                            guiHelpers.addEntityConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenStairsParamsMetadataSorted_v2, con.params)
                        elseif con.fileName == _eventProperties.openTwinStairsSelected.conName then
                            if not(_guiData.conOpenTwinStairsParamsMetadataSorted) then
                                logger.warn('_guiData.conOpenTwinStairsParamsMetadataSorted is not available')
                                return
                            end

                            guiHelpers.addEntityConfigToWindow(conId, _handlers.guiHandleParamValueChanged, _guiData.conOpenTwinStairsParamsMetadataSorted, con.params)
                        end
                    end,
                    logger.xpErrorHandler
                )
            end
        end,
        guiInit = function()
            -- logger.print('guiInit starting')
            _guiData.conOpenLiftParamsMetadataSorted = openStairsHelpers.getOpenLiftParamsMetadata()
            _guiData.conOpenStairsParamsMetadataSorted = openStairsHelpers.getOpenStairsParamsMetadata()
            _guiData.conOpenStairsParamsMetadataSorted_v2 = openStairsHelpers.getOpenStairsParamsMetadata_v2()
            _guiData.conOpenTwinStairsParamsMetadataSorted = openStairsHelpers.getOpenTwinStairsParamsMetadata()
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
    }
end
