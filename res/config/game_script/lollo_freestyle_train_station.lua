local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

-- LOLLO NOTE you can only update the state from the worker thread
local state = {}

local _eventId = _constants.eventData.eventId
local _eventNames = _constants.eventData.eventNames
local _guiPlatformWaypointModelId = nil
local _guiTrackWaypointModelId = nil

local _actions = {
    -- LOLLO api.engine.util.proposal.makeProposalData(simpleProposal, context) returns the proposal data,
    -- which has the same format as the result of api.cmd.make.buildProposal
    addSubway = function(stationConstructionId, subwayConstructionId, successEventName)
        logger.print('addSubway starting, stationConstructionId =', stationConstructionId, 'subwayConstructionId =', subwayConstructionId)
        if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then print('WARNING: invalid stationConstructionId') debugPrint(stationConstructionId) return end
        if not(edgeUtils.isValidAndExistingId(subwayConstructionId)) then print('WARNING: invalid subwayConstructionId') debugPrint(subwayConstructionId) return end

        local oldCon = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil then return end

        local subwayTransf = api.engine.getComponent(subwayConstructionId, api.type.ComponentType.CONSTRUCTION).transf
        -- print('subwayTransf =') logger.debugPrint(subwayTransf)
        if subwayTransf == nil then print('lollo freestyle train station ERROR: no subway transf') return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true),
            modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
            seed = oldCon.params.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldCon.params.subways, nil, true),
            terminals = arrayUtils.cloneDeepOmittingFields(oldCon.params.terminals, nil, true)
        }
        local _getNextAvailableSlotId = function()
            local counter = 0
            while counter < 1000 do
                counter = counter + 1

                local testResult = slotHelpers.mangleId(0, counter, _constants.idBases.subwaySlotId)
                if newParams.modules[testResult] == nil then return testResult end
            end

            print('WARNING: cannot find an available slot for a subway')
            return false
        end
        local newSubway_Key = _getNextAvailableSlotId()
        if not(newSubway_Key) then return end

        local newSubway_Value = {
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
                fileName = '',
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
        proposal.constructionsToRemove = { stationConstructionId, subwayConstructionId }
        -- proposal.old2new = {
        --     [stationConstructionId] = 0,
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
                logger.print('addSubway callback, success =', success)
                -- logger.debugPrint(result)
                if success and successEventName ~= nil then
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        {
                            stationConstructionId = result.resultEntities[1]
                        }
                    ))
                end
            end
        )
    end,

    bulldozeMarker = function(conId)
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
        local conTransf = args.platformWaypointTransf

        logger.print('buildStation starting, args =')
        local oldCon = edgeUtils.isValidAndExistingId(args.join2StationId)
        and api.engine.getComponent(args.join2StationId, api.type.ComponentType.CONSTRUCTION)
        or nil

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local _mainTransf = oldCon == nil
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
        local params_newTerminal = {
            isCargo = args.isCargo,
            -- myTransf = arrayUtils.cloneDeepOmittingFields(conTransf),
            platformEdgeLists = args.platformEdgeList,
            trackEdgeLists = args.trackEdgeList,
            -- centrePlatforms = args.centrePlatforms,
            centrePlatformsRelative = arrayUtils.map(
                args.centrePlatforms,
                _getRelativePosTanX2s
            ),
            -- centrePlatformsFine = args.centrePlatformsFine,
            centrePlatformsFineRelative = arrayUtils.map(
                args.centrePlatformsFine,
                _getRelativePosTanX2s
            ),
            trackEdgeListMidIndex = args.trackEdgeListMidIndex,
            -- leftPlatforms = args.leftPlatforms,
            leftPlatformsRelative = arrayUtils.map(
                args.leftPlatforms,
                _getRelativePosTanX2s
            ),
            -- rightPlatforms = args.rightPlatforms,
            rightPlatformsRelative = arrayUtils.map(
                args.rightPlatforms,
                _getRelativePosTanX2s
            ),
            -- crossConnectors = args.crossConnectors,
            crossConnectorsRelative = arrayUtils.map(
                args.crossConnectors,
                _getRelativePosTanX2s
            ),
            -- cargoWaitingAreas = args.cargoWaitingAreas,
            cargoWaitingAreasRelative = {},
            isTrackOnPlatformLeft = args.isTrackOnPlatformLeft,
            slopedAreasFineRelative = {},
        }

        for _, cwas in pairs(args.cargoWaitingAreas) do
            params_newTerminal.cargoWaitingAreasRelative[#params_newTerminal.cargoWaitingAreasRelative+1] = arrayUtils.map(
                cwas,
                _getRelativePosTanX2s
            )
        end
        for width, slopedAreasFine4Width in pairs(args.slopedAreasFine) do
            params_newTerminal.slopedAreasFineRelative[width] = arrayUtils.map(
                slopedAreasFine4Width,
                _getRelativePosTanX2s
            )
        end
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
            local newParams = {
                -- it is not too correct to pass two parameters, one of which can be inferred from the other. However, performance matters more.
                inverseMainTransf = _inverseMainTransf,
                mainTransf = _mainTransf,
                modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
                seed = oldCon.params.seed + 1,
                subways = arrayUtils.cloneDeepOmittingFields(oldCon.params.subways, nil, true),
                terminals = arrayUtils.cloneDeepOmittingFields(oldCon.params.terminals, nil, true)
            }
            newParams.modules[params_newModuleKeys[1]] = params_newModuleValues[1]
            newParams.modules[params_newModuleKeys[2]] = params_newModuleValues[2]
            newParams.modules[params_newModuleKeys[3]] = params_newModuleValues[3]
            newParams.terminals[#newParams.terminals+1] = params_newTerminal
            newCon.params = newParams
            newCon.transf = oldCon.transf
        end
        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        if edgeUtils.isValidAndExistingId(args.join2StationId) then
            proposal.constructionsToRemove = { args.join2StationId }
            -- proposal.old2new = {
            --     [args.join2StationId] = 0,
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
                logger.print('build station callback, success =', success)
                -- logger.debugPrint(result)
                if success and successEventName ~= nil then
                    -- logger.print('station proposal data = ', result.resultProposalData) -- userdata
                    -- logger.print('station entities = ', result.resultEntities) -- userdata
                    logger.print('stationConstructionId = ', result.resultEntities[1])
                    logger.print('buildStation callback is about to send command')
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        successEventName,
                        {
                            stationConstructionId = result.resultEntities[1]
                        }
                    ))
                end
            end
        )
    end,

    removeTerminal = function(constructionId, nTerminalToRemove, nRemainingTerminals, successEventName)
        logger.print('removeTerminal starting, constructionId =', constructionId)

        local oldCon = edgeUtils.isValidAndExistingId(constructionId)
        and api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        or nil
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        if oldCon == nil then return end

        logger.print('nTerminalToRemove =') logger.debugPrint(nTerminalToRemove)
        if type(nTerminalToRemove) ~= 'number' then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.inverseMainTransf, nil, true),
            mainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true),
            modules = arrayUtils.cloneDeepOmittingFields(oldCon.params.modules, nil, true),
            seed = oldCon.params.seed + 1,
            subways = arrayUtils.cloneDeepOmittingFields(oldCon.params.subways, nil, true),
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

        -- write this away before removing it
        local removedTerminalEdgeLists = {
            platformEdgeLists = newParams.terminals[nTerminalToRemove].platformEdgeLists,
            trackEdgeLists = newParams.terminals[nTerminalToRemove].trackEdgeLists,
        }
        table.remove(newParams.terminals, nTerminalToRemove)
        -- get rid of subways if bulldozing the last terminal
        if #newParams.terminals < 1 then newParams.subways = {} end

        newCon.params = newParams
        newCon.transf = oldCon.transf
        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon

        proposal.constructionsToRemove = { constructionId }
        -- proposal.old2new = {
        --     [constructionId] = 0,
        -- }

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        context.gatherBuildings = false -- default is false
        context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('removeTerminal callback, success =', success)
                -- logger.debugPrint(result)
                if success and successEventName ~= nil then
                    local eventArgs = {
                        nRemainingTerminals = nRemainingTerminals,
                        removedTerminalEdgeLists = removedTerminalEdgeLists,
                        stationConstructionId = result.resultEntities[1]
                    }
                    logger.print('eventArgs.stationConstructionId =', eventArgs.stationConstructionId)
                    logger.print('removeTerminal callback is about to send command')
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

    rebuildOneTerminalTracks = function(trackEdgeLists, platformEdgeLists, neighbourNodeIds, stationConstructionId, successEventName)
        local _significantFigures4LocateNode = 5 -- you may lower this down to 100 if tracks are not properly rebuilt.
        -- cleanupStreetGraph in previous events (removeTerminal and bulldozeStation) might also play a role, it might.
        logger.print('rebuildOneTerminalTracks starting')
        -- logger.print('trackEdgeLists =') logger.debugPrint(trackEdgeLists)
        -- logger.print('platformEdgeLists =') logger.debugPrint(platformEdgeLists)
        -- logger.print('neighbourNodeIds =') logger.debugPrint(neighbourNodeIds)
        if trackEdgeLists == nil or type(trackEdgeLists) ~= 'table' then return end
        if platformEdgeLists == nil or type(platformEdgeLists) ~= 'table' then return end

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
                and edgeUtils.isNumVeryClose(position[1], _baseNode1.position.x, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[2], _baseNode1.position.y, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[3], _baseNode1.position.z, _significantFigures4LocateNode)
                then
                    -- logger.print('_baseNode1 matches')
                    return neighbourNodeIds_plOrTr.node1
                elseif _baseNode2 ~= nil
                and edgeUtils.isNumVeryClose(position[1], _baseNode2.position.x, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[2], _baseNode2.position.y, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[3], _baseNode2.position.z, _significantFigures4LocateNode)
                then
                    -- logger.print('_baseNode2 matches')
                    return neighbourNodeIds_plOrTr.node2
                else
                    for _, newNode in pairs(newNodes) do
                        if edgeUtils.isNumVeryClose(position[1], newNode.position[1], _significantFigures4LocateNode)
                        and edgeUtils.isNumVeryClose(position[2], newNode.position[2], _significantFigures4LocateNode)
                        and edgeUtils.isNumVeryClose(position[3], newNode.position[3], _significantFigures4LocateNode)
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
                newSegment.trackEdge.catenary = trackEdgeList.catenary

                proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
            end

            local result = false
            for _, edgeList in pairs(edgeLists) do
                _addSegment(edgeList)
                result = true
            end
            return result
        end

        local isPlatformsChanged = doTrackOrPlatform(platformEdgeLists, neighbourNodeIds.platforms)
        local isTracksChanged = doTrackOrPlatform(trackEdgeLists, neighbourNodeIds.tracks)
        if not(isPlatformsChanged) and not(isTracksChanged) then return end

        -- logger.print('rebuildOneTerminalTracks proposal =') logger.debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                logger.print('LOLLO rebuildOneTerminalTracks success = ', success)
                -- logger.print('LOLLO result = ') logger.debugPrint(result)
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

    bulldozeStation = function(constructionId)
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
                logger.print('LOLLO bulldozeStation success = ', success)
                -- logger.print('LOLLO bulldozeStation result = ') logger.debugPrint(result)
            end
        )
    end,

    removeTracks = function(platformEdgeIds, trackEdgeIds, successEventName, successEventArgs)
        logger.print('removeTracks starting')
        -- logger.print('successEventName =') logger.debugPrint(successEventName)
        -- logger.print('successEventArgs =') logger.debugPrint(successEventArgs)
        logger.print('platformEdgeIds =') logger.debugPrint(platformEdgeIds)
        logger.print('trackEdgeIds =') logger.debugPrint(trackEdgeIds)
        local allEdgeIds = {}
        arrayUtils.concatValues(allEdgeIds, trackEdgeIds)
        arrayUtils.concatValues(allEdgeIds, platformEdgeIds)
        logger.print('allEdgeIds =') logger.debugPrint(allEdgeIds)

        local proposal = api.type.SimpleProposal.new()
        for _, edgeId in pairs(allEdgeIds) do
            if edgeUtils.isValidAndExistingId(edgeId) then
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if baseEdge then
                    proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
                    if baseEdge.objects then
                        for o = 1, #baseEdge.objects do
                            proposal.streetProposal.edgeObjectsToRemove[#proposal.streetProposal.edgeObjectsToRemove+1] = baseEdge.objects[o][1]
                        end
                    end
                end
            end
        end
        -- logger.print('proposal.streetProposal.edgeObjectsToRemove =')
        -- logger.debugPrint(proposal.streetProposal.edgeObjectsToRemove)

        local sharedNodeIds = {}
        arrayUtils.concatValues(sharedNodeIds, edgeUtils.getNodeIdsBetweenEdgeIds(trackEdgeIds, true))
        arrayUtils.concatValues(sharedNodeIds, edgeUtils.getNodeIdsBetweenEdgeIds(platformEdgeIds, true))
        for i = 1, #sharedNodeIds do
            proposal.streetProposal.nodesToRemove[i] = sharedNodeIds[i]
        end
        -- logger.print('proposal.streetProposal.nodesToRemove =') logger.debugPrint(proposal.streetProposal.nodesToRemove)
        -- logger.print('proposal =') logger.debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('command callback firing for removeTracks, success =', success)
                -- logger.debugPrint(result)
                if success and successEventName ~= nil then
                    logger.print('removeTracks callback is about to send command')
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
        logger.print('replaceEdgeWithSameRemovingObject starting')
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end
        logger.print('replaceEdgeWithSameRemovingObject found, the old edge id is valid')
        -- replaces a track segment with an identical one, without destroying the buildings
        local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(oldEdgeId, objectIdToRemove)
        if not(proposal) then return end
        logger.print('replaceEdgeWithSameRemovingObject likes the proposal')
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
                -- logger.print('LOLLO replaceEdgeWithSameRemovingObject result = ') logger.debugPrint(result)
                logger.print('LOLLO replaceEdgeWithSameRemovingObject success = ') logger.debugPrint(success)
            end
        )
    end,

    splitEdgeRemovingObject = function(wholeEdgeId, nodeBetween, objectIdToRemove, successEventName, successEventArgs, newArgName, mustSplit)
        -- logger.print('splitEdgeRemovingObject starting')
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

        if not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)) and not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node1.position)) then
            print('WARNING: splitEdge cannot find the nodes')
        end
        local isNodeBetweenOrientatedLikeMyEdge = edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)
        logger.print('isNodeBetweenOrientatedLikeMyEdge =', isNodeBetweenOrientatedLikeMyEdge)
        local distance0 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance0 or nodeBetween.refDistance1
        local distance1 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance1 or nodeBetween.refDistance0
        logger.print('distance0 =') logger.debugPrint(distance0)
        logger.print('distance1 =') logger.debugPrint(distance1)
        local tanSign = isNodeBetweenOrientatedLikeMyEdge and 1 or -1

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, true may shift the new nodes after the split, which makes them impossible for us to recognise.
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        -- the split may occur at the end of an edge - in theory, but I could not make it happen in practise.
        if distance0 == 0 or distance1 == 0 or (not(mustSplit) and (distance0 < _constants.minSplitDistance or distance1 < _constants.minSplitDistance)) then
            -- we use this to avoid unnecessary splits, unless they must happen
            logger.print('WARNING: nodeBetween is at the end of an edge; nodeBetween =') logger.debugPrint(nodeBetween)
            local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(wholeEdgeId, objectIdToRemove)
            if not(proposal) then return end

            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    logger.print('command callback firing for split, success =', success) --, 'result =') logger.debugPrint(result)
                    if success and successEventName ~= nil then
                        -- logger.print('successEventName =') logger.debugPrint(successEventName)
                        local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                        if not(stringUtils.isNullOrEmptyString(newArgName)) then
                            local splitNodeId = -1
                            if distance0 == 0 then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node0 or oldBaseEdge.node1 logger.print('8one')
                            elseif distance1 == 0 then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node1 or oldBaseEdge.node0 logger.print('8two')
                            elseif distance0 < _constants.minSplitDistance then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node0 or oldBaseEdge.node1 logger.print('8three')
                            elseif distance1 < _constants.minSplitDistance then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node1 or oldBaseEdge.node0 logger.print('8four')
                            else
                                print('lollo freestyle train station ERROR: impossible condition, distance0 =') debugPrint(distance0)
                                print('distance1 =') debugPrint(distance1)
                                print('isNodeBetweenOrientatedLikeMyEdge =') debugPrint(isNodeBetweenOrientatedLikeMyEdge)
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
            nodeBetween.tangent.x * distance0 * tanSign,
            nodeBetween.tangent.y * distance0 * tanSign,
            nodeBetween.tangent.z * distance0 * tanSign
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
            nodeBetween.tangent.x * distance1 * tanSign,
            nodeBetween.tangent.y * distance1 * tanSign,
            nodeBetween.tangent.z * distance1 * tanSign
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

        if type(oldBaseEdge.objects) == 'table' and #oldBaseEdge.objects > 1 then
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
                if success and successEventName ~= nil then
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
                        print('lollo freestyle train station ERROR: #result.proposal.proposal.addedNodes =', #result.proposal.proposal.addedNodes)
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
                end
            end
        )
    end,

    rebuildUndergroundDepotWithoutHole = function(oldConId)
        logger.print('rebuildUndergroundDepotWithoutHole starting, oldConId =', oldConId or 'NIL')
        local oldCon = edgeUtils.isValidAndExistingId(oldConId)
        and api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
        or nil
        if not(oldCon) then return end

        logger.print('oldCon =') logger.debugPrint(oldCon)

        local newParams = {
            catenary = oldCon.params.catenary,
            isShowUnderground = 0, -- this is what this is all about: once built, stop showing underground
            -- paramX = oldCon.params.paramX,
            -- paramY = oldCon.params.paramY,
            seed = oldCon.params.seed + 1,
            trackType = oldCon.params.trackType,
            -- year = oldCon.params.year,
        }
        -- LOLLO NOTE this is no ordinary construction, but a rail depot.
        -- Some magic is involved.
        -- Rebuilding it with the api will lead to crashes as soon as the user clicks it.
        -- Instead, we try the old interface, which fails with the usual "pr.second failed"
    --[[
        game.interface.upgradeConstruction(
            oldConId,
            oldCon.fileName,
            newParams
        )
    ]]
    --[[
        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName
        newCon.params = newParams
        newCon.transf = oldCon.transf
        newCon.playerEntity = api.engine.util.getPlayer()

        logger.print('newCon =') logger.debugPrint(newCon)

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon
        proposal.constructionsToRemove = { oldConId }
        proposal.old2new = {
            oldConId, 0
            -- oldConId, 1
        }

        logger.print('proposal =') logger.debugPrint(proposal)

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('rebuild underground depot without hole callback, success =', success)
                -- logger.debugPrint(result)
            end
        )
    ]]
    end,
}

local _guiActions = {
    getCon = function(constructionId)
        if not(edgeUtils.isValidAndExistingId(constructionId)) then return nil end

        return api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
    end,
    tryHideHole = function(conId, con)
        if con == nil or type(con.fileName) ~= 'string' or con.fileName ~= _constants.undergroundDepotConFileName or con.transf == nil then return false end

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.HIDE_HOLE_REQUESTED,
            { conId = conId }
        ))

        return true
    end,
    tryJoinSubway = function(conId, con)
        if con == nil or type(con.fileName) ~= 'string' or con.fileName ~= _constants.subwayConFileName or con.transf == nil then return false end

        local subwayTransf_c = con.transf
        if subwayTransf_c == nil then return false end

        local subwayTransf_lua = transfUtilsUG.new(subwayTransf_c:cols(0), subwayTransf_c:cols(1), subwayTransf_c:cols(2), subwayTransf_c:cols(3))
        if subwayTransf_lua == nil then return false end

        logger.print('conTransf =') logger.debugPrint(subwayTransf_lua)
        local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationsList(subwayTransf_lua, _constants.searchRadius4NearbyStation2Join, true)
        -- logger.print('nearbyFreestyleStations =') logger.debugPrint(nearbyFreestyleStations)
        logger.print('#nearbyFreestyleStations =', #nearbyFreestyleStations)
        if #nearbyFreestyleStations == 0 then return false end

        guiHelpers.showNearbyStationPicker(
            false, -- subways are only for passengers
            nearbyFreestyleStations,
            _eventId,
            _eventNames.SUBWAY_JOIN_REQUESTED,
            nil,
            {
                subwayId = conId
                -- join2StationId will be added by the popup
            }
        )

        return true
    end,
}

local _tryReplaceSegment = function(edgeId, endEntities4T_plOrTr, proposal, nNewEntities)
    logger.print('_tryReplaceSegment starting with edgeId =', edgeId or 'NIL')

    local _addNodeToRemove = function(nodeId)
        if edgeUtils.isValidAndExistingId(nodeId) and not(arrayUtils.arrayHasValue(proposal.streetProposal.nodesToRemove, nodeId)) then
            proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = nodeId
        end
    end

    if not(edgeUtils.isValidAndExistingId(edgeId)) then
        print('Warning: invalid edgeId in _tryReplaceSegment')
        return false, nNewEntities
    end

    -- logger.print('valid edgeId in _tryReplaceSegment, going ahead')

    local newSegment = api.type.SegmentAndEntity.new()
    local nNewEntities_ = nNewEntities - 1
    newSegment.entity = nNewEntities_

    local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    if baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id then
        newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
        _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id)
        -- logger.print('twenty-one')
    elseif baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id then
        newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
        _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id)
        -- logger.print('twenty-two')
    else
        newSegment.comp.node0 = baseEdge.node0
        -- logger.print('twenty-three')
    end

    if baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id then
        newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
        _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id)
        -- logger.print('twenty-four')
    elseif baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id then
        newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
        _addNodeToRemove(endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id)
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
    newSegment.type = _constants.railEdgeType
    local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
    local baseEdgeStreet = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)

    if baseEdgeTrack ~= nil then
        newSegment.trackEdge.trackType = baseEdgeTrack.trackType
        newSegment.trackEdge.catenary = baseEdgeTrack.catenary
    elseif baseEdgeStreet ~= nil then
        logger.print('Warning: edgeId', edgeId, 'is street')
        newSegment.streetEdge.streetType = baseEdgeStreet.streetType
        newSegment.streetEdge.hasBus = baseEdgeStreet.hasBus
        newSegment.streetEdge.tramTrackType = baseEdgeStreet.tramTrackType
        -- newSegment.streetEdge.precedenceNode0 = baseEdgeStreet.precedenceNode0
        -- newSegment.streetEdge.precedenceNode1 = baseEdgeStreet.precedenceNode1
    end

    proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
    if not(arrayUtils.arrayHasValue(proposal.streetProposal.edgesToRemove, edgeId)) then
        proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
    end

    return true, nNewEntities_
end

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

    logger.print('buildSnappyPlatforms starting')
    if type(t) ~= 'number' or type(tMax) ~= 'number' then print('Warning: buildSnappyPlatforms received wrong t or tMax') debugPrint(t) debugPrint(tMax) return end
    if t > tMax then logger.print('tMax reached, leaving') return end

    local endEntities4T = stationHelpers.getStationEndEntities4T(stationConstructionId, t)
    logger.print('endEntities4T =') logger.debugPrint(endEntities4T)
    if endEntities4T == nil then return end

    local isAnyPlatformFailed = false

    local proposal = api.type.SimpleProposal.new()
    local nNewEntities = 0
    local isSuccess = true

    for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdgeIds.edge1Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _tryReplaceSegment(edgeId, endEntities4T.platforms, proposal, nNewEntities)
        -- logger.print('isSuccess =', isSuccess, 'nNewEntities =', nNewEntities)
    end
    for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdgeIds.edge2Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _tryReplaceSegment(edgeId, endEntities4T.platforms, proposal, nNewEntities)
        -- logger.print('isSuccess =', isSuccess, 'nNewEntities =', nNewEntities)
    end

    -- logger.print('proposal =') logger.debugPrint(proposal)
    -- UG TODO I need to check myself coz the api will crash, even if I call it in this step-by-step fashion.
    if isSuccess then
        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
        if expectedResult.errorState.critical then
            logger.print('expectedResult =') logger.debugPrint(expectedResult)
            isAnyPlatformFailed = true
            _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
        else
            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    logger.print('buildSnappyPlatforms callback, success =', success)
                    _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
                end
            )
        end
    else
        isAnyPlatformFailed = true
        _actions.buildSnappyPlatforms(stationConstructionId, t + 1, tMax)
    end
end

_actions.buildSnappyTracks = function(stationConstructionId, t, tMax)
    -- see the comments in buildSnappyPlatforms
    logger.print('buildSnappyTracks starting')
    if type(t) ~= 'number' or type(tMax) ~= 'number' then print('Warning: buildSnappyTracks received wrong t or tMax') debugPrint(t) debugPrint(tMax) return end
    if t > tMax then logger.print('tMax reached, leaving') return end

    local endEntities4T = stationHelpers.getStationEndEntities4T(stationConstructionId, t)
    logger.print('endEntities4T =') logger.debugPrint(endEntities4T)
    if endEntities4T == nil then return end

    local isAnyTrackFailed = false

    local proposal = api.type.SimpleProposal.new()
    local nNewEntities = 0
    local isSuccess = true

    for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdgeIds.edge1Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _tryReplaceSegment(edgeId, endEntities4T.tracks, proposal, nNewEntities)
    end
    for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdgeIds.edge2Ids) do
        if not(isSuccess) then break end
        isSuccess, nNewEntities = _tryReplaceSegment(edgeId, endEntities4T.tracks, proposal, nNewEntities)
    end

    if isSuccess then
        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer()

        local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
        if expectedResult.errorState.critical then
            logger.print('expectedResult =') logger.debugPrint(expectedResult)
            isAnyTrackFailed = true
            _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
        else
            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    logger.print('buildSnappyTracks callback, success =', success)
                    _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
                end
            )
        end
    else
        isAnyTrackFailed = true
        _actions.buildSnappyTracks(stationConstructionId, t + 1, tMax)
    end

    if isAnyTrackFailed then
        -- cannot call the popup from the worker thread
        state.isShowBuildSnappyTracksFailed = true
    end
end

-- local function _isBuildingPlatformMarker(args)
--     return stationHelpers.isBuildingConstructionWithFileName(args, _constants.platformMarkerConName)
-- end

function data()
    return {
        -- ini = function()
        -- end,
        guiInit = function()
            _guiPlatformWaypointModelId = api.res.modelRep.find(_constants.platformWaypointModelId)
            _guiTrackWaypointModelId = api.res.modelRep.find(_constants.trackWaypointModelId)
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            xpcall(
                function()

            logger.print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
            -- LOLLO NOTE ONLY SOMETIMES, it can crash when calling game.interface.getEntity(stationId).
            -- Things are better now, it seems that the error came after a fast loop of calling split and raising the event, then calling split again.
            -- That looks like a race, difficult to handle here.
            -- For example, it crashes when using the street get info on a piece of track
            -- the error happens when we do debugPrint(args), after removeTrack detected there was only on edge and decided to split it.
            -- the split succeeds, then control returns here and the eggs break.
            -- if you put debugPrint(args) inside split(), it will crash there.
            -- if you remove it, it won't crash.
            -- debugPrint(args)

            if name == _eventNames.HIDE_WARNINGS then
                state.isShowBuildSnappyTracksFailed = false
                guiHelpers.isShowingWarning = false
            elseif name == _eventNames.HIDE_HOLE_REQUESTED then
                -- _actions.rebuildUndergroundDepotWithoutHole(args.conId)
            elseif name == _eventNames.BULLDOZE_MARKER_REQUESTED then
                _actions.bulldozeMarker(args.platformMarkerConstructionEntityId)
            elseif name == _eventNames.WAYPOINT_BULLDOZE_REQUESTED then
                -- game.interface.bulldoze(args.waypointId) -- dumps
                _actions.replaceEdgeWithSameRemovingObject(args.edgeId, args.waypointId)
            elseif name == _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.trackWaypoint1Id))
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint1Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint1Id)
                -- UG TODO see if the api can get the exact percentage shift.
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition))

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
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.trackWaypoint2Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                local waypointPosition = edgeUtils.getObjectPosition(args.trackWaypoint2Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition))
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
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint1Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint1Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition))

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
                then return end

                local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(args.platformWaypoint2Id)
                if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                local waypointPosition = edgeUtils.getObjectPosition(args.platformWaypoint2Id)
                local nodeBetween = edgeUtils.getNodeBetweenByPosition(edgeId, transfUtils.oneTwoThree2XYZ(waypointPosition))

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
                    if args == nil then print('args is NIL')
                    else
                        print('WARNING: some data is missing or invalid. args.splitTrackNode1Id =') debugPrint(args.splitTrackNode1Id)
                        print('args.splitTrackNode2Id =') debugPrint(args.splitTrackNode2Id)
                    end
                    return
                end

                local trackEdgeIdsBetweenNodeIds = stationHelpers.getTrackEdgeIdsBetweenNodeIds(
                    args.splitTrackNode1Id,
                    args.splitTrackNode2Id
                )
                -- LOLLO NOTE I need this, or a station with only one track edge will dump with
                -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                if #trackEdgeIdsBetweenNodeIds == 0 then
                    print('lollo freestyle train station ERROR: #trackEdgeIdsBetweenNodeIds == 0')
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
                local platformEdgeIdsBetweenNodeIds = stationHelpers.getTrackEdgeIdsBetweenNodeIds(
                    args.splitPlatformNode1Id,
                    args.splitPlatformNode2Id
                )
                if #platformEdgeIdsBetweenNodeIds == 0 then
                    print('lollo freestyle train station ERROR: #platformEdgeIdsBetweenNodeIds == 0')
                    return
                end
                -- LOLLO NOTE I need this, or a station with only one platform edge will dump with
                -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                if #platformEdgeIdsBetweenNodeIds == 1 then
                    logger.print('only one platform edge, going to split it')
                    local edgeId = platformEdgeIdsBetweenNodeIds[1]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
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
                eventArgs.platformEdgeList = stationHelpers.getEdgeIdsProperties(platformEdgeIdsBetweenNodeIds)
                -- logger.print('track bulldoze requested, platformEdgeList =') logger.debugPrint(eventArgs.platformEdgeList)
                logger.print('track bulldoze requested, trackEdgeIdsBetweenNodeIds =') logger.debugPrint(trackEdgeIdsBetweenNodeIds)
                eventArgs.trackEdgeList = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenNodeIds)
                -- logger.print('track bulldoze requested, trackEdgeList =') logger.debugPrint(eventArgs.trackEdgeList)
                local totalLength = 0
                local trackLengths = {}
                for i = 1, #eventArgs.trackEdgeList do
                    local tel = eventArgs.trackEdgeList[i]
                    -- these should be identical, but they are not really so, so we average them
                    local length = (transfUtils.getVectorLength(tel.posTanX2[1][2]) + transfUtils.getVectorLength(tel.posTanX2[2][2])) * 0.5
                    trackLengths[i] = length
                    totalLength = totalLength + length
                end
                local lengthSoFar = 0
                local halfTotalLength = totalLength * 0.5
                local iAcrossMidLength = -1
                local iCloseEnoughToMidLength = -1
                for i = 1, #trackLengths do
                    local length = trackLengths[i]
                    if lengthSoFar <= halfTotalLength and lengthSoFar + length >= halfTotalLength then
                        iAcrossMidLength = i
                        if lengthSoFar / halfTotalLength > _constants.minPercentageDeviation4Midpoint and lengthSoFar / halfTotalLength < _constants.maxPercentageDeviation4Midpoint then
                            iCloseEnoughToMidLength = i
                        else
                            if (lengthSoFar + length) / halfTotalLength > _constants.minPercentageDeviation4Midpoint and (lengthSoFar + length) / halfTotalLength < _constants.maxPercentageDeviation4Midpoint then
                                iCloseEnoughToMidLength = i + 1
                            end
                        end
                        break
                    end
                    lengthSoFar = lengthSoFar + length
                end
                if iCloseEnoughToMidLength < 1 then
                    logger.print('no track edge is close enough to the middle (halfway between the ends), going to add a split. iAcrossMidLength =', iAcrossMidLength)
                    if iAcrossMidLength < 1 then
                        print('WARNING: trouble finding trackEdgeListMidIndex')
                        print('totalLength =') debugPrint(totalLength)
                        print('trackLengths =') debugPrint(trackLengths)
                        print('halfTotalLength =') debugPrint(halfTotalLength)
                        print('lengthSoFar =') debugPrint(lengthSoFar)
                    end
                    local edgeId = trackEdgeIdsBetweenNodeIds[iAcrossMidLength]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    logger.print('edgeId =') logger.debugPrint(edgeId)
                    local position0 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[1][1])
                    local position1 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[2][1])
                    local tangent0 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[1][2])
                    local tangent1 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[2][2])
                    logger.print('position0 =') logger.debugPrint(position0)
                    logger.print('position1 =') logger.debugPrint(position1)
                    logger.print('tangent0 =') logger.debugPrint(tangent0)
                    logger.print('tangent1 =') logger.debugPrint(tangent1)
                    logger.print('(halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength] =') logger.debugPrint((halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength])

                    local nodeBetween = edgeUtils.getNodeBetween(
                        position0, position1, tangent0, tangent1,
                        (halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength]
                    )
                    logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                    -- LOLLO NOTE it seems fixed, but keep checking it:
                    -- this can screw up the directions. It happens on tracks where slope varies, ie tan0.z ~= tan1.z
                    -- in these cases, split produces something like:
                    -- node0 = 26197,
                    -- node0pos = { 972.18054199219, 596.27990722656, 12.010199546814, },
                    -- node0tangent = { 35.427974700928, 26.778322219849, -2.9104161262512, },
                    -- node1 = 26348,
                    -- node1pos = { 1007.6336669922, 623.07720947266, 9.3951835632324, },
                    -- node1tangent = { -35.457813262939, -26.800853729248, 2.2689030170441, },
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

                -- this will be the vehicle node, where the trains stop with their belly
                eventArgs.trackEdgeListMidIndex = iCloseEnoughToMidLength
                -- logger.print('eventArgs.trackEdgeListMidIndex =') logger.debugPrint(eventArgs.trackEdgeListMidIndex)
                -- logger.print('eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex] =') logger.debugPrint(eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex])

                local _setLeftCentreRightPlatforms = function(platformEdgeList, trackEdgeList, trackEdgeListMidIndex)
                    eventArgs.centrePlatforms = stationHelpers.getCentralEdgePositions(
                        platformEdgeList,
                        args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                        true
                    )
                    -- logger.print('aaa')

                    local centrePlatformIndex_Nearest2_TrackEdgeListMid = stationHelpers.getCentrePlatformIndex_Nearest2_TrackEdgeListMid(eventArgs)
                    -- logger.print('centrePlatformIndex_Nearest2_TrackEdgeListMid =') logger.debugPrint(centrePlatformIndex_Nearest2_TrackEdgeListMid)

                    local platformWidth = eventArgs.centrePlatforms[centrePlatformIndex_Nearest2_TrackEdgeListMid].width
                    eventArgs.leftPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - platformWidth * 0.45)
                    eventArgs.rightPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, platformWidth * 0.45)
                    -- logger.print('alalalalal')
                    local centreTracks = stationHelpers.getCentralEdgePositions(
                        trackEdgeList,
                        args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                        false
                    )
                    -- logger.print('eee')
                    eventArgs.isTrackOnPlatformLeft = stationHelpers.getIsTrackOnPlatformLeft(
                        eventArgs.leftPlatforms,
                        eventArgs.rightPlatforms,
                        centrePlatformIndex_Nearest2_TrackEdgeListMid,
                        trackEdgeList[trackEdgeListMidIndex]
                    )
                    logger.print('eventArgs.isTrackOnPlatformLeft =', eventArgs.isTrackOnPlatformLeft)

                    return platformWidth
                end
                local platformWidth = _setLeftCentreRightPlatforms(eventArgs.platformEdgeList, eventArgs.trackEdgeList, eventArgs.trackEdgeListMidIndex)
                -- reverse track and platform edges if the platform is on the right of the track.
                -- this will make trains open their doors on the correct side.
                -- Remember that "left" and "right" are just conventions here, there is no actual left and right.
                if not(eventArgs.isTrackOnPlatformLeft) then
                    local midPos1 = eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex].posTanX2[1][1]
                    -- logger.print('LOLLO reversing platformEdgeList, platformEdgeList =') logger.debugPrint(eventArgs.platformEdgeList)
                    eventArgs.platformEdgeList = stationHelpers.getPosTanX2ListReversed(eventArgs.platformEdgeList)
                    -- logger.print('LOLLO reversed platformEdgeList, platformEdgeList =') logger.debugPrint(eventArgs.platformEdgeList)
                    -- logger.print('LOLLO reversing trackEdgeList, trackEdgeList =') logger.debugPrint(eventArgs.trackEdgeList)
                    eventArgs.trackEdgeList = stationHelpers.getPosTanX2ListReversed(eventArgs.trackEdgeList)
                    -- logger.print('LOLLO reversed trackEdgeList, trackEdgeList =') logger.debugPrint(eventArgs.trackEdgeList)
                    -- eventArgs.trackEdgeListMidIndex = #eventArgs.trackEdgeList - eventArgs.trackEdgeListMidIndex + 2 -- dangerous
                    -- eventArgs.trackEdgeListMidIndex = #eventArgs.trackEdgeList - eventArgs.trackEdgeListMidIndex + 1 -- wrong
                    -- eventArgs.trackEdgeListMidIndex = #eventArgs.trackEdgeList - eventArgs.trackEdgeListMidIndex -- wrong
                    -- logger.print('eventArgs.trackEdgeListMidIndex before =', eventArgs.trackEdgeListMidIndex)
                    -- dumber but safer
                    for i = 1, #eventArgs.trackEdgeList do
                        if (
                            eventArgs.trackEdgeList[i].posTanX2[1][1][1] == midPos1[1]
                            and eventArgs.trackEdgeList[i].posTanX2[1][1][2] == midPos1[2]
                            and eventArgs.trackEdgeList[i].posTanX2[1][1][3] == midPos1[3]
                        ) then
                            eventArgs.trackEdgeListMidIndex = i
                            -- logger.print('FOUND, new value =', i)
                            break
                        end
                    end
                    platformWidth = _setLeftCentreRightPlatforms(eventArgs.platformEdgeList, eventArgs.trackEdgeList, eventArgs.trackEdgeListMidIndex)
                end

                eventArgs.centrePlatformsFine = stationHelpers.getCentralEdgePositions(
                    eventArgs.centrePlatforms,
                    1
                )
                -- logger.print('centrePlatformsFine =') logger.debugPrint(centrePlatformsFine)

                logger.print('calculating slopedAreasFine, platformWidth =', platformWidth)
                eventArgs.slopedAreasFine = {}
                if eventArgs.isTrackOnPlatformLeft then
                    -- I add 2 coz it is a little less than half the width of the 5m sloped area,
                    eventArgs.slopedAreasFine[2.5] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 0.75)
                    eventArgs.slopedAreasFine[5] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 2)
                    eventArgs.slopedAreasFine[10] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 4.5)
                    eventArgs.slopedAreasFine[20] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 9.5)
                else
                    eventArgs.slopedAreasFine[2.5] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, - platformWidth * 0.5 - 0.75)
                    eventArgs.slopedAreasFine[5] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, - platformWidth * 0.5 - 2)
                    eventArgs.slopedAreasFine[10] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, - platformWidth * 0.5 - 4.5)
                    eventArgs.slopedAreasFine[20] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, - platformWidth * 0.5 - 9.5)
                end

                eventArgs.crossConnectors = stationHelpers.getCrossConnectors(eventArgs.leftPlatforms, eventArgs.centrePlatforms, eventArgs.rightPlatforms, eventArgs.isTrackOnPlatformLeft)
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
                logger.print('eventArgs.nTerminal =', eventArgs.nTerminal)

                _actions.buildStation(
                    _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED,
                    eventArgs
                )
            elseif name == _eventNames.REMOVE_TERMINAL_REQUESTED then
                _actions.removeTerminal(
                    args.stationConstructionId,
                    args.nTerminalToRemove,
                    args.nRemainingTerminals,
                    _eventNames.REBUILD_1_TRACK_REQUESTED
                )
            elseif name == _eventNames.REBUILD_1_TRACK_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                    print('lollo freestyle train station ERROR: args.stationConstructionId not valid')
                    return
                end
                if type(args.removedTerminalEdgeLists) ~= 'table' or type(args.removedTerminalEdgeLists.trackEdgeLists) ~= 'table' then
                    _actions.bulldozeStation(args.stationConstructionId)
                    print('lollo freestyle train station ERROR: args.removedTerminalEdgeLists.trackEdgeLists not available')
                    return
                end
                _actions.rebuildOneTerminalTracks(
                    args.removedTerminalEdgeLists.trackEdgeLists,
                    args.removedTerminalEdgeLists.platformEdgeLists,
                    stationHelpers.getNeighbourNodeIdsOfBulldozedTerminal(args.removedTerminalEdgeLists.platformEdgeLists, args.removedTerminalEdgeLists.trackEdgeLists),
                    args.stationConstructionId,
                    args.nRemainingTerminals > 0 and _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED or _eventNames.BULLDOZE_STATION_REQUESTED
                )
            elseif name == _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.stationConstructionId)) then
                    print('lollo freestyle train station ERROR: args.stationConstructionId not valid')
                    return
                end
                local con = api.engine.getComponent(args.stationConstructionId, api.type.ComponentType.CONSTRUCTION)
                if con == nil or type(con.fileName) ~= 'string' or con.fileName ~= _constants.stationConFileName or con.params == nil or #con.params.terminals < 1 then
                    print('lollo freestyle train station ERROR: construction', args.stationConstructionId, 'is not a freestyle station')
                    return
                end
                _actions.buildSnappyPlatforms(args.stationConstructionId, 1, #con.params.terminals)
                _actions.buildSnappyTracks(args.stationConstructionId, 1, #con.params.terminals)
            elseif name == _eventNames.BULLDOZE_STATION_REQUESTED then
                _actions.bulldozeStation(args.stationConstructionId)
            elseif name == _eventNames.SUBWAY_JOIN_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.join2StationId))
                or not(edgeUtils.isValidAndExistingId(args.subwayId)) then
                    print('lollo freestyle train station ERROR: args.join2StationId or args.subwayId is invalid')
                    return
                end
                _actions.addSubway(args.join2StationId, args.subwayId, _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED)
            end
        end,
        logger.xpErrorHandler
    )
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            -- logger.print('guiHandleEvent caught id =', id, 'name =', name)
            local isHideDistance = true
            if (name == 'builder.proposalCreate' or name == 'builder.apply' or name == 'select') then -- for performance

                xpcall(
                    function()
                        if name == 'builder.proposalCreate' then
                            if id == 'streetTerminalBuilder' then
                                -- waypoint, traffic light, my own waypoints built
                                if args and args.proposal and args.proposal.proposal
                                and args.proposal.proposal.edgeObjectsToAdd
                                and args.proposal.proposal.edgeObjectsToAdd[1]
                                and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                                then
                                    local _tryShowDistance = function(targetWaypointModelId, newWaypointTransf, mustBeOnPlatform)
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
                                            guiHelpers.showWaypointDistance(tostring((_('WaypointDistanceWindowTitle') .. " %.0f m"):format(distance)))
                                            return true
                                        end

                                        return false
                                    end

                                    if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiPlatformWaypointModelId then
                                        isHideDistance = not(_tryShowDistance(
                                            _guiPlatformWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf,
                                            true
                                        ))
                                    elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiTrackWaypointModelId then
                                        isHideDistance = not(_tryShowDistance(
                                            _guiTrackWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf,
                                            false
                                        ))
                                    end
                                end
                            end
                        elseif name == 'builder.apply' then
                            guiHelpers.hideAllWarnings()
                            -- logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                            if id == 'bulldozer' then
                                for _, constructionId in pairs(args.proposal.toRemove) do
                                    logger.print('about to bulldoze construction', constructionId)
                                    if edgeUtils.isValidAndExistingId(constructionId) then
                                        local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                                        if con ~= nil and type(con.fileName) == 'string' and con.fileName == _constants.stationConFileName then
                                            -- logger.print('args = ') logger.debugPrint(args)
                                            -- bulldozed a station module AND there are more left
                                            -- logger.print('bulldozing a component of a freestyle station, con.params.modules =') logger.debugPrint(con.params.modules)
                                            local remainingTerminalIds = {}
                                            for slotId, _ in pairs(con.params.modules) do
                                                local nTerminal, _, baseId = slotHelpers.demangleId(slotId)
                                                if baseId == _constants.idBases.terminalSlotId then
                                                    arrayUtils.addUnique(remainingTerminalIds, nTerminal)
                                                end
                                            end
                                            -- a terminal was bulldozed
                                            if #remainingTerminalIds < #con.params.terminals then
                                                -- if #remainingTerminalIds > 0 then
                                                    local nTerminalToRemove = -1
                                                    for t = 1, #con.params.terminals do
                                                        if not(arrayUtils.arrayHasValue(remainingTerminalIds, t)) then
                                                            nTerminalToRemove = t
                                                            break
                                                        end
                                                    end
                                                    logger.print('nTerminalToRemove =', nTerminalToRemove)
                                                    if nTerminalToRemove > 0 then
                                                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                            string.sub(debug.getinfo(1, 'S').source, 1),
                                                            _eventId,
                                                            _eventNames.REMOVE_TERMINAL_REQUESTED,
                                                            {
                                                                stationConstructionId = constructionId,
                                                                nRemainingTerminals = #remainingTerminalIds,
                                                                nTerminalToRemove = nTerminalToRemove
                                                            }
                                                        ))
                                                    else
                                                        print('lollo freestyle train station ERROR: cannot find id of deleted terminal')
                                                    end
                                                -- else
                                                --     -- last terminal removed: pull down the station
                                                --     api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                                                --         string.sub(debug.getinfo(1, 'S').source, 1),
                                                --         _eventId,
                                                --         _eventNames.BULLDOZE_STATION_REQUESTED,
                                                --         {
                                                --             constructionId = constructionId,
                                                --         }
                                                --     ))
                                                -- end
                                            end
                                        end
                                    end
                                end
                            elseif id == 'constructionBuilder' then
                                if not args.result or not args.result[1] then return end

                                -- logger.print('args =') logger.debugPrint(args)
                                local conId = args.result[1]
                                local con = _guiActions.getCon(conId)
                                -- logger.print('construction built, construction id =') logger.debugPrint(conId)
                                if not(con) then return end

                                _guiActions.tryJoinSubway(conId, con)
                                -- _guiActions.tryHideHole(conId, con)
                            elseif id == 'streetTerminalBuilder' then
                                -- waypoint, traffic light, my own waypoints built
                                if args and args.proposal and args.proposal.proposal
                                and args.proposal.proposal.edgeObjectsToAdd
                                and args.proposal.proposal.edgeObjectsToAdd[1]
                                and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                                then
                                    local _validateWaypointBuilt = function(targetWaypointModelId, newWaypointId, lastBuiltEdgeId, mustBeOnPlatform)
                                        logger.print('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
                                        -- UG TODO this is empty, ask UG to fix this: can't we have the waypointId in args.result?
                                        -- The problem persists with build 33345
                                        logger.print('waypoint built, args.result =') logger.debugPrint(args.result)

                                        -- logger.print('args.proposal.proposal.addedSegments =') logger.debugPrint(args.proposal.proposal.addedSegments)
                                        if not(edgeUtils.isValidAndExistingId(newWaypointId)) then print('lollo freestyle train station ERROR with newWaypointId') return false end
                                        if not(edgeUtils.isValidAndExistingId(lastBuiltEdgeId)) then print('lollo freestyle train station ERROR with lastBuiltEdgeId') return false end

                                        logger.print('lastBuiltEdgeId =') logger.debugPrint(lastBuiltEdgeId)
                                        local lastBuiltBaseEdge = api.engine.getComponent(
                                            lastBuiltEdgeId,
                                            api.type.ComponentType.BASE_EDGE
                                        )
                                        if not(lastBuiltBaseEdge) then return false end

                                        -- logger.print('edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, waypointModelId) =')
                                        -- logger.debugPrint(edgeUtils.getEdgeObjectsIdsWithModelId(lastBuiltBaseEdge.objects, targetWaypointModelId))

                                        -- forbid building track waypoint on a platform or platform waypoint on a track
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
                                        logger.print('similarObjectsIdsInAnyEdges =') logger.debugPrint(similarObjectIdsInAnyEdges)
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

                                        local newWaypointPosition = edgeUtils.getObjectPosition(newWaypointId)
                                        -- make sure the waypoint is not too close to station end nodes, or the game will complain later with it != components.end()
                                        local endEdgeIds = edgeUtils.getEdgeIdsConnectedToEdgeId(lastBuiltEdgeId)
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
                                                        local stationEndEntities = stationHelpers.getStationEndEntities(conId)
                                                        -- logger.print('stationEndEntities =') logger.debugPrint(stationEndEntities)
                                                        -- if any end nodes are too close to my waypoint
                                                        for __, stationEndEntities4T in pairs(stationEndEntities) do
                                                            if transfUtils.getPositionsDistance(stationEndEntities4T.platforms.stationEndNodePositions.node1, newWaypointPosition) < _minDistance
                                                            or transfUtils.getPositionsDistance(stationEndEntities4T.platforms.stationEndNodePositions.node2, newWaypointPosition) < _minDistance
                                                            or transfUtils.getPositionsDistance(stationEndEntities4T.tracks.stationEndNodePositions.node1, newWaypointPosition) < _minDistance
                                                            or transfUtils.getPositionsDistance(stationEndEntities4T.tracks.stationEndNodePositions.node2, newWaypointPosition) < _minDistance
                                                            then
                                                                guiHelpers.showWarningWindowWithGoto(_('WaypointsTooCloseToStation'), newWaypointId)
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
                                                        end
                                                    else -- if con.stations ~= nil and #con.stations > 0 then
                                                        -- no knowledge of end nodes: just forbid the waypoint
                                                        guiHelpers.showWarningWindowWithGoto(_('WaypointsTooCloseToStation'), newWaypointId)
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
                                                end
                                            end
                                        end

                                        if #similarObjectIdsInAnyEdges < 2 then
                                            -- not ready yet
                                            -- guiHelpers.showWarningWindowWithGoto(_('BuildMoreWaypoints'), newWaypointId)
                                            return false
                                        end

                                        local twinWaypointId =
                                            newWaypointId == similarObjectIdsInAnyEdges[1] and similarObjectIdsInAnyEdges[2] or similarObjectIdsInAnyEdges[1]
                                        local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)

                                        -- forbid building waypoints too far apart, which would make the station too large
                                        if newWaypointPosition ~= nil and twinWaypointPosition ~= nil then
                                            local distance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition)
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

                                        local contiguousTrackEdgeProps = stationHelpers.getTrackEdgePropsBetweenEdgeIds(
                                            api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
                                            api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId)
                                        )
                                        logger.print('contiguous track edges =') logger.debugPrint(contiguousTrackEdgeProps)
                                        -- make sure the waypoints are on connected tracks
                                        if #contiguousTrackEdgeProps < 1 then
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

                                        -- make sure the waypoints are not overlapping existing station tracks or platforms, for any sort of station
                                        for __, obj in pairs(contiguousTrackEdgeProps) do -- don't use _ here, we call it below to translate the message!
                                            local edgeId = obj.entity
                                            local conId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(edgeId)
                                            if edgeUtils.isValidAndExistingId(conId) then
                                                local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                                                if con ~= nil and con.stations ~= nil and #con.stations > 0 then
                                                    guiHelpers.showWarningWindowWithGoto(_('WaypointsCrossStation'), newWaypointId)
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
                                            end
                                        end

                                        local contiguousEdgeIds = {}
                                        for __, value in pairs(contiguousTrackEdgeProps) do
                                            arrayUtils.addUnique(contiguousEdgeIds, value.entity)
                                        end
                                        logger.print('contiguousEdgeIds =') logger.debugPrint(contiguousEdgeIds)
                                        -- make sure there are no crossings between the waypoints
                                        local nodesBetweenWps = edgeUtils.getNodeIdsBetweenNeighbourEdgeIds(contiguousEdgeIds, false)
                                        logger.print('nodesBetweenWps =') logger.debugPrint(nodesBetweenWps)
                                        local _map = api.engine.system.streetSystem.getNode2SegmentMap()
                                        for __, nodeId in pairs(nodesBetweenWps) do
                                            if _map[nodeId] and #_map[nodeId] > 2 then
                                                guiHelpers.showWarningWindowWithGoto(_('WaypointsCrossCrossing'), newWaypointId)
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
                                        end

                                        -- make sure there are no signals or waypoints between the waypoints
                                        for ___, edgeId in pairs(contiguousEdgeIds) do
                                            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                                            if baseEdge and baseEdge.objects and #baseEdge.objects > 0 then
                                                for __, edgeObj in pairs(baseEdge.objects) do
                                                    logger.print('edgeObj between waypoints =') logger.debugPrint(edgeObj)
                                                    if edgeObj[1] ~= newWaypointId and edgeObj[1] ~= twinWaypointId then
                                                        guiHelpers.showWarningWindowWithGoto(_('WaypointsCrossSignal'), newWaypointId)
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
                                                end
                                            end
                                        end

                                        -- LOLLO NOTE do not check that the tracks between the waypoints are all of the same type
                                        -- (ie, platforms have the same width) so we have more flexibility with tunnel entrances
                                        -- on the other hand, different platform widths make trouble with cargo, which has multiple waiting areas:
                                        -- let's check if they are different only if one is > 5, which only happens with cargo.
                                        local trackDistances = {}
                                        for _, obj in pairs(contiguousTrackEdgeProps) do
                                            local edgeId = obj.entity
                                            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                                            local baseEdgeProperties = api.res.trackTypeRep.get(baseEdgeTrack.trackType)
                                            arrayUtils.addUnique(trackDistances, baseEdgeProperties.trackDistance)
                                        end
                                        if #trackDistances > 1 then
                                            for __, td in pairs(trackDistances) do -- don't use _ here, we call it below to translate the message!
                                                if td > 5 then
                                                    guiHelpers.showWarningWindowWithGoto(_('DifferentPlatformWidths'), newWaypointId)
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
                                            end
                                        end

                                        -- validation fine, return data
                                        return {
                                            newWaypointId = newWaypointId,
                                            twinWaypointId = twinWaypointId
                                        }
                                    end

                                    local _handleValidWaypointBuilt = function()
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
                                            platformWaypointTransf = platformWaypointMidTransf,
                                            platformWaypoint1Id = platformWaypointIds[1],
                                            platformWaypoint2Id = platformWaypointIds[2],
                                            trackWaypoint1Id = distance11 < distance12 and trackWaypointIds[1] or trackWaypointIds[2],
                                            trackWaypoint2Id = distance11 < distance12 and trackWaypointIds[2] or trackWaypointIds[1],
                                        }

                                        local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationsList(platformWaypointMidTransf, _constants.searchRadius4NearbyStation2Join)
                                        if #nearbyFreestyleStations > 0 and #nearbyFreestyleStations < _constants.maxNTerminals then
                                            guiHelpers.showNearbyStationPicker(
                                                isCargo,
                                                nearbyFreestyleStations,
                                                _eventId,
                                                _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                                                _eventNames.TRACK_WAYPOINT_1_SPLIT_REQUESTED,
                                                eventArgs -- join2StationId will be added by the popup
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
                                    if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiPlatformWaypointModelId then
                                        local waypointData = _validateWaypointBuilt(_guiPlatformWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                            args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                            true
                                        )
                                        logger.print('platformWaypointData =') logger.debugPrint(waypointData)
                                        if not(waypointData) then return end

                                        _handleValidWaypointBuilt()

                                        -- if any platform nodes are joints between more than 2 platform-tracks,
                                        -- we bar building two platform waypoints outside a junction.
                                        -- Or maybe, we could bar intersecting platform-tracks altogether:
                                        -- they look mighty ugly. Maybe someone knows how to fix their looks? ask UG TODO

                                    elseif args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiTrackWaypointModelId then
                                        local waypointData = _validateWaypointBuilt(_guiTrackWaypointModelId,
                                            args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                            args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                            false
                                        )
                                        logger.print('trackWaypointData =') logger.debugPrint(waypointData)
                                        if not(waypointData) then return end

                                        _handleValidWaypointBuilt()
                                    end
                                end
                            --[[ elseif id == 'trackBuilder' or id == 'streetTrackModifier' then
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
                                            logger.print('WARNING upgrading, addedSegment =') -- logger.debugPrint(addedSegment)
                                            -- logger.print('args.data.entity2tn =') logger.debugPrint(args.data.entity2tn)
                                            -- LOLLO TODO when upgrading, the game adds a segment and two nodes, which won't work with the following.
                                            -- Probably unimportant, but check it coz edgeUtils.getLastBuiltEdgeId errors out (gracefully)
                                            -- when adding electrification or high speed.
                                            removeTrackWaypointsEventArgs[#removeTrackWaypointsEventArgs+1] = {
                                                edgeId = edgeUtils.getLastBuiltEdgeId(args.data.entity2tn, addedSegment),
                                                waypointId = nil,
                                            }
                                        end
                                    -- else
                                        -- logger.print('addedSegment =') logger.debugPrint(addedSegment)
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
                                end ]]
                            end
                        elseif name == 'select' then
                            -- LOLLO TODO MAYBE same with stations. Maybe one day.
                            -- logger.print('LOLLO caught gui select, id = ', id, ' name = ', name, ' args = ')
                            -- logger.debugPrint(args)

                            local conId = args
                            local con = _guiActions.getCon(conId)
                            if not(con) then return end

                            _guiActions.tryJoinSubway(conId, con)
                        end
                    end,
                    logger.xpErrorHandler
                )
            end
            if isHideDistance then guiHelpers.hideWaypointDistance() end
        end,
        -- update = function()
        -- end,
        guiUpdate = function()
            if state.isShowBuildSnappyTracksFailed and not(guiHelpers.isShowingWarning) then guiHelpers.showWarningWindowWithState(_('BuildSnappyTracksFailed')) end
        end,
        save = function()
            -- only fires when the worker thread changes the state
            if not state then state = {} end
            if not state.isShowBuildSnappyTracksFailed then state.isShowBuildSnappyTracksFailed = false end
            return state
        end,
        load = function(loadedState)
            -- fires once in the worker thread, at game load, and many times in the UI thread
            if loadedState then
                state = {}
                state.isShowBuildSnappyTracksFailed = loadedState.isShowBuildSnappyTracksFailed or false
            else
                state = {
                    isShowBuildSnappyTracksFailed = false,
                }
            end
        end,
    }
end