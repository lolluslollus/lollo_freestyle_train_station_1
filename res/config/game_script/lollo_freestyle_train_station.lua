local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

-- LOLLO NOTE you can only update the state from the worker thread
local state = {}

local _eventId = _constants.eventData.eventId
local _eventNames = _constants.eventData.eventNames

local _actions = {
    -- LOLLO api.engine.util.proposal.makeProposalData(simpleProposal, context) returns the proposal data,
    -- which has the same format as the result of api.cmd.make.buildProposal
    addSubway = function(stationConstructionId, subwayConstructionId, successEventName)
        print('addSubway starting, stationConstructionId =', stationConstructionId, 'subwayConstructionId =', subwayConstructionId)
        if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then print('WARNING: invalid stationConstructionId') debugPrint(stationConstructionId) return end
        if not(edgeUtils.isValidAndExistingId(subwayConstructionId)) then print('WARNING: invalid subwayConstructionId') debugPrint(subwayConstructionId) return end

        local oldCon = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil then return end

        local subwayTransf = api.engine.getComponent(subwayConstructionId, api.type.ComponentType.CONSTRUCTION).transf
        -- print('subwayTransf =') debugPrint(subwayTransf)
        if subwayTransf == nil then print('ERROR: no subway transf') return end

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
                print('addSubway callback, success =', success)
                -- debugPrint(result)
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
        -- print('oldCon =') debugPrint(oldCon)
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
                print('LOLLO bulldozeMarker success = ', success)
                -- print('LOLLO bulldozeMarker result = ') debugPrint(result)
            end
        )
    end,

    buildSnappyTracks = function(endEntities)
        -- LOLLO NOTE after building the station, never mind how well you placed it,
        -- its end nodes won't snap to the adjacent roads.
        -- AltGr + L will show a red dot, and here is the catch: there are indeed
        -- two separate nodes in the same place, at each station end.
        -- Here, I remove the neighbour track (edge and node) and replace it
        -- with an identical track, which snaps to the station end node instead.
        -- The same happens after joining a subway to a station, which also rebuilds the station construction.
        print('buildSnappyTracks starting')
        print('endEntities =') debugPrint(endEntities)
        if endEntities == nil then return end

        local isAnyPlatformFailed = false
        local isAnyTrackFailed = false

        for _, endEntities4T in pairs(endEntities) do
            -- we make a build proposal for each terminal, so if one fails we still get the others
            local proposal = api.type.SimpleProposal.new()
            local isProposalPopulated = false
            local nNewEntities = 0

            local _replaceSegment = function(edgeId, endEntities4T_plOrTr)
                local newSegment = api.type.SegmentAndEntity.new()
                nNewEntities = nNewEntities - 1
                newSegment.entity = nNewEntities
    
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id then
                    newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
                elseif baseEdge.node0 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id then
                    newSegment.comp.node0 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
                else
                    newSegment.comp.node0 = baseEdge.node0
                end
    
                if baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node1Id then
                    newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node1Id
                elseif baseEdge.node1 == endEntities4T_plOrTr.disjointNeighbourNodeIds.node2Id then
                    newSegment.comp.node1 = endEntities4T_plOrTr.stationEndNodeIds.node2Id
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
                local baseEdgeStreet = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
    
                if baseEdgeTrack ~= nil then
                    newSegment.trackEdge.trackType = baseEdgeTrack.trackType
                    newSegment.trackEdge.catenary = baseEdgeTrack.catenary
                elseif baseEdgeStreet ~= nil then
                    print('edgeId', edgeId, 'is street')
                    newSegment.streetEdge.streetType = baseEdgeStreet.streetType
                    newSegment.streetEdge.hasBus = baseEdgeStreet.hasBus
                    newSegment.streetEdge.tramTrackType = baseEdgeStreet.tramTrackType
                    -- newSegment.streetEdge.precedenceNode0 = baseEdgeStreet.precedenceNode0
                    -- newSegment.streetEdge.precedenceNode1 = baseEdgeStreet.precedenceNode1
                end
    
                proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd+1] = newSegment
                proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove+1] = edgeId
                isProposalPopulated = true
            end

            for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdgeIds.edge1Ids) do
                _replaceSegment(edgeId, endEntities4T.platforms)
            end
            for _, edgeId in pairs(endEntities4T.platforms.disjointNeighbourEdgeIds.edge2Ids) do
                _replaceSegment(edgeId, endEntities4T.platforms)
            end

            if edgeUtils.isValidAndExistingId(endEntities4T.platforms.disjointNeighbourNodeIds.node1Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.platforms.disjointNeighbourNodeIds.node1Id
                isProposalPopulated = true
            end
            if edgeUtils.isValidAndExistingId(endEntities4T.platforms.disjointNeighbourNodeIds.node2Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.platforms.disjointNeighbourNodeIds.node2Id
                isProposalPopulated = true
            end

            if isProposalPopulated then
                local context = api.type.Context:new()
                -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
                -- context.cleanupStreetGraph = true -- default is false
                -- context.gatherBuildings = false -- default is false
                -- context.gatherFields = true -- default is true
                -- context.player = api.engine.util.getPlayer()

                local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
                if expectedResult.errorState.critical then
                    print('expectedResult =') debugPrint(expectedResult)
                    isAnyPlatformFailed = true
                else
                    api.cmd.sendCommand(
                        api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                        function(result, success)
                            print('buildSnappyTracks callback, success =', success)
                        end
                    )
                end
            end

            proposal = api.type.SimpleProposal.new()
            isProposalPopulated = false
            nNewEntities = 0

            for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdgeIds.edge1Ids) do
                _replaceSegment(edgeId, endEntities4T.tracks)
            end
            for _, edgeId in pairs(endEntities4T.tracks.disjointNeighbourEdgeIds.edge2Ids) do
                _replaceSegment(edgeId, endEntities4T.tracks)
            end

            if edgeUtils.isValidAndExistingId(endEntities4T.tracks.disjointNeighbourNodeIds.node1Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.tracks.disjointNeighbourNodeIds.node1Id
                isProposalPopulated = true
            end
            if edgeUtils.isValidAndExistingId(endEntities4T.tracks.disjointNeighbourNodeIds.node2Id) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove+1] = endEntities4T.tracks.disjointNeighbourNodeIds.node2Id
                isProposalPopulated = true
            end

            if isProposalPopulated then
                local context = api.type.Context:new()
                -- context.checkTerrainAlignment = true -- true gives smoother z, default is false
                -- context.cleanupStreetGraph = true -- default is false
                -- context.gatherBuildings = false -- default is false
                -- context.gatherFields = true -- default is true
                -- context.player = api.engine.util.getPlayer()

                local expectedResult = api.engine.util.proposal.makeProposalData(proposal, context)
                if expectedResult.errorState.critical then
                    print('expectedResult =') debugPrint(expectedResult)
                    isAnyTrackFailed = true
                else
                    api.cmd.sendCommand(
                        api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                        function(result, success)
                            print('buildSnappyTracks callback, success =', success)
                        end
                    )
                end
            end
        end

        if isAnyTrackFailed then
            -- cannot call the popup from the worker thread
            state.isShowBuildSnappyTracksFailed = true
        end
    end,

    buildStation = function(successEventName, args)
        local conTransf = args.platformWaypointTransf

        print('buildStation starting, args =')
        local oldCon = edgeUtils.isValidAndExistingId(args.join2StationId)
        and api.engine.getComponent(args.join2StationId, api.type.ComponentType.CONSTRUCTION)
        or nil

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local _mainTransf = oldCon == nil
            and arrayUtils.cloneDeepOmittingFields(conTransf)
            or arrayUtils.cloneDeepOmittingFields(oldCon.params.mainTransf, nil, true)
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
            -- slopedAreasFine = args.slopedAreasFine,
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
        -- print('params_newTerminal =') debugPrint(params_newTerminal)

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
                print('build station callback, success =', success)
                -- debugPrint(result)
                if success and successEventName ~= nil then
                    print('stationConstructionId = ', result.resultEntities[1])
                    print('buildStation callback is about to send command')
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
        print('removeTerminal starting, constructionId =', constructionId)

        local oldCon = edgeUtils.isValidAndExistingId(constructionId)
        and api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        or nil
        -- print('oldCon =') debugPrint(oldCon)
        if oldCon == nil then return end

        print('nTerminalToRemove =') debugPrint(nTerminalToRemove)
        if type(nTerminalToRemove) ~= 'number' then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.stationConFileName

        local newParams = {
            inverseMainTransf = arrayUtils.cloneDeepOmittingFields(oldCon.params.inverseMainTransf, nil, true),
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

        local removedTerminalEdgeLists = {
            platformEdgeLists = newParams.terminals[nTerminalToRemove].platformEdgeLists,
            trackEdgeLists = newParams.terminals[nTerminalToRemove].trackEdgeLists,
        }
        table.remove(newParams.terminals, nTerminalToRemove)

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
                print('removeTerminal callback, success =', success)
                -- debugPrint(result)
                if success and successEventName ~= nil then
                    local eventArgs = {
                        nRemainingTerminals = nRemainingTerminals,
                        removedTerminalEdgeLists = removedTerminalEdgeLists,
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

    rebuildOneTerminalTracks = function(trackEdgeLists, platformEdgeLists, neighbourNodeIds, stationConstructionId, successEventName)
        local _significantFigures4LocateNode = 5 -- you may lower this down to 100 if tracks are not properly rebuilt.
        -- cleanupStreetGraph in previous events (removeTerminal and bulldozeStation) might also play a role, it might.
        print('rebuildOneTerminalTracks starting')
        -- print('trackEdgeLists =') debugPrint(trackEdgeLists)
        -- print('platformEdgeLists =') debugPrint(platformEdgeLists)
        -- print('neighbourNodeIds =') debugPrint(neighbourNodeIds)
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
            -- print('_baseNode1 =') debugPrint(_baseNode1)
            local _baseNode2 = (neighbourNodeIds_plOrTr ~= nil and edgeUtils.isValidAndExistingId(neighbourNodeIds_plOrTr.node2))
            and api.engine.getComponent(neighbourNodeIds_plOrTr.node2, api.type.ComponentType.BASE_NODE)
            or nil
            -- print('_baseNode2 =') debugPrint(_baseNode2)

            local _addNode = function(position)
                -- print('adding node, position =') debugPrint(position)
                if _baseNode1 ~= nil
                and edgeUtils.isNumVeryClose(position[1], _baseNode1.position.x, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[2], _baseNode1.position.y, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[3], _baseNode1.position.z, _significantFigures4LocateNode)
                then
                    -- print('_baseNode1 matches')
                    return neighbourNodeIds_plOrTr.node1
                elseif _baseNode2 ~= nil
                and edgeUtils.isNumVeryClose(position[1], _baseNode2.position.x, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[2], _baseNode2.position.y, _significantFigures4LocateNode)
                and edgeUtils.isNumVeryClose(position[3], _baseNode2.position.z, _significantFigures4LocateNode)
                then
                    -- print('_baseNode2 matches')
                    return neighbourNodeIds_plOrTr.node2
                else
                    for _, newNode in pairs(newNodes) do
                        if edgeUtils.isNumVeryClose(position[1], newNode.position[1], _significantFigures4LocateNode)
                        and edgeUtils.isNumVeryClose(position[2], newNode.position[2], _significantFigures4LocateNode)
                        and edgeUtils.isNumVeryClose(position[3], newNode.position[3], _significantFigures4LocateNode)
                        then
                            -- print('reusing a new node')
                            return newNode.id
                        end
                    end

                    -- print('making a new node')
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

        -- print('rebuildOneTerminalTracks proposal =') debugPrint(proposal)

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        -- context.player = api.engine.util.getPlayer() -- default is -1
        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                print('LOLLO rebuildOneTerminalTracks success = ', success)
                -- print('LOLLO result = ') debugPrint(result)
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
        -- print('oldCon =') debugPrint(oldCon)
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
                print('LOLLO bulldozeStation success = ', success)
                -- print('LOLLO bulldozeStation result = ') debugPrint(result)
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
                        for o = 1, #baseEdge.objects do
                            proposal.streetProposal.edgeObjectsToRemove[#proposal.streetProposal.edgeObjectsToRemove+1] = baseEdge.objects[o][1]
                        end
                    end
                end
            end
        end
        -- print('proposal.streetProposal.edgeObjectsToRemove =')
        -- debugPrint(proposal.streetProposal.edgeObjectsToRemove)

        local sharedNodeIds = {}
        arrayUtils.concatValues(sharedNodeIds, edgeUtils.getNodeIdsBetweenEdgeIds(trackEdgeIds, true))
        arrayUtils.concatValues(sharedNodeIds, edgeUtils.getNodeIdsBetweenEdgeIds(platformEdgeIds, true))
        for i = 1, #sharedNodeIds do
            proposal.streetProposal.nodesToRemove[i] = sharedNodeIds[i]
        end
        -- print('proposal.streetProposal.nodesToRemove =') debugPrint(proposal.streetProposal.nodesToRemove)
        -- print('proposal =') debugPrint(proposal)

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
        -- context.cleanupStreetGraph = true -- default is false
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

    splitEdgeRemovingObject = function(wholeEdgeId, nodeBetween, objectIdToRemove, successEventName, successEventArgs, newArgName, mustSplit)
        -- print('splitEdgeRemovingObject starting')
        if not(edgeUtils.isValidAndExistingId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

        -- print('nodeBetween =') debugPrint(nodeBetween)
        local oldBaseEdge = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldBaseEdgeTrack = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldBaseEdge == nil or oldBaseEdgeTrack == nil then return end
        -- print('oldBaseEdge =') debugPrint(oldBaseEdge)

        local node0 = api.engine.getComponent(oldBaseEdge.node0, api.type.ComponentType.BASE_NODE)
        local node1 = api.engine.getComponent(oldBaseEdge.node1, api.type.ComponentType.BASE_NODE)
        if node0 == nil or node1 == nil then return end
        -- print('node0 =') debugPrint(node0)
        -- print('node1 =') debugPrint(node1)

        -- local isNodeBetweenOrientatedLikeMyEdge = edgeUtils.isXYZVeryClose(nodeBetween.refPosition0, node0.position)
        if not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)) and not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node1.position)) then
            print('WARNING: splitEdge cannot find the nodes')
        end
        local isNodeBetweenOrientatedLikeMyEdge = edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)
        print('isNodeBetweenOrientatedLikeMyEdge =', isNodeBetweenOrientatedLikeMyEdge)
        local distance0 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance0 or nodeBetween.refDistance1
        local distance1 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance1 or nodeBetween.refDistance0
        print('distance0 =') debugPrint(distance0)
        print('distance1 =') debugPrint(distance1)
        local tanSign = isNodeBetweenOrientatedLikeMyEdge and 1 or -1

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false, true may shift the new nodes after the split, which makes them impossible for us to recognise.
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        -- mustSplit = true -- LOLLO TODO remove after testing
        -- the split may occur at the end of an edge - in theory, but I could not make it happen in practise.
        if distance0 == 0 or distance1 == 0 or (not(mustSplit) and (distance0 < _constants.minSplitDistance or distance1 < _constants.minSplitDistance)) then
            -- we use this to avoid unnecessary splits, unless they must happen
            print('WARNING: nodeBetween is at the end of an edge; nodeBetween =') debugPrint(nodeBetween)
            local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(wholeEdgeId, objectIdToRemove)
            if not(proposal) then return end

            api.cmd.sendCommand(
                api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
                function(result, success)
                    print('command callback firing for split, success =', success) --, 'result =') debugPrint(result)
                    if success and successEventName ~= nil then
                        -- print('successEventName =') debugPrint(successEventName)
                        local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                        if not(stringUtils.isNullOrEmptyString(newArgName)) then
                            local splitNodeId = -1
                            if distance0 == 0 then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node0 or oldBaseEdge.node1 print('8one')
                            elseif distance1 == 0 then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node1 or oldBaseEdge.node0 print('8two')
                            elseif distance0 < _constants.minSplitDistance then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node0 or oldBaseEdge.node1 print('8three')
                            elseif distance1 < _constants.minSplitDistance then splitNodeId = isNodeBetweenOrientatedLikeMyEdge and oldBaseEdge.node1 or oldBaseEdge.node0 print('8four')
                            else
                                print('ERROR: impossible condition, distance0 =') debugPrint(distance0)
                                print('distance1 =') debugPrint(distance1)
                                print('isNodeBetweenOrientatedLikeMyEdge =') debugPrint(isNodeBetweenOrientatedLikeMyEdge)
                            end
                            print('splitEdgeRemovingObject is about to raise its event with splitNodeId =', splitNodeId or 'NIL')
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
        -- print('oldTan0Length =') debugPrint(oldTan0Length)
        -- print('oldTan1Length =') debugPrint(oldTan1Length)

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
            print('splitting: edge objects found')
            local edge0Objects = {}
            local edge1Objects = {}
            for _, edgeObj in pairs(oldBaseEdge.objects) do
                print('edgeObj =') debugPrint(edgeObj)
                if edgeObj[1] ~= objectIdToRemove then
                    local edgeObjPosition = edgeUtils.getObjectPosition(edgeObj[1])
                    print('edgeObjPosition =') debugPrint(edgeObjPosition)
                    if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                    local assignment = stationHelpers.getWhichEdgeGetsEdgeObjectAfterSplit(
                        edgeObjPosition,
                        {node0.position.x, node0.position.y, node0.position.z},
                        {node1.position.x, node1.position.y, node1.position.z},
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
                print('command callback firing for split, success =', success)
                if not(success) then
                    print('proposal =') debugPrint(proposal)
                    print('split callback result =') debugPrint(result)
                end
                if success and successEventName ~= nil then
                    print('successEventName =') debugPrint(successEventName)
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
                    print('addedNodePosition =') debugPrint(addedNodePosition)

                    local addedNodeIds = edgeUtils.getNearbyObjectIds(
                        transfUtils.position2Transf(addedNodePosition),
                        0.001,
                        api.type.ComponentType.BASE_NODE
                    )
                    print('addedNodeIds =') debugPrint(addedNodeIds)
                    local eventArgs = arrayUtils.cloneDeepOmittingFields(successEventArgs)
                    if not(stringUtils.isNullOrEmptyString(newArgName)) then
                        eventArgs[newArgName] = addedNodeIds[1]
                    end
                    -- print('sending out eventArgs =') debugPrint(eventArgs)
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

-- local function _isBuildingPlatformMarker(args)
--     return stationHelpers.isBuildingConstructionWithFileName(args, _constants.platformMarkerConName)
-- end

function data()
    return {
        -- ini = function()
        -- end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            xpcall(
                function()

            print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
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
                    print('ERROR: #trackEdgeIdsBetweenNodeIds == 0')
                    return
                end
                if #trackEdgeIdsBetweenNodeIds == 1 then
                    print('only one track edge, going to split it')
                    local edgeId = trackEdgeIdsBetweenNodeIds[1]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    print('args.splitTrackNode1Id =') debugPrint(args.splitTrackNode1Id)
                    print('args.splitTrackNode2Id =') debugPrint(args.splitTrackNode2Id)
                    print('edgeId =') debugPrint(edgeId)
                    local nodeBetween = edgeUtils.getNodeBetweenByPercentageShift(edgeId, 0.5)
                    print('nodeBetween =') debugPrint(nodeBetween)
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

                print('at least two track edges found')
                local platformEdgeIdsBetweenNodeIds = stationHelpers.getTrackEdgeIdsBetweenNodeIds(
                    args.splitPlatformNode1Id,
                    args.splitPlatformNode2Id
                )
                if #platformEdgeIdsBetweenNodeIds == 0 then
                    print('ERROR: #platformEdgeIdsBetweenNodeIds == 0')
                    return
                end
                -- LOLLO NOTE I need this, or a station with only one platform edge will dump with
                -- Assertion `std::find(frozenNodes.begin(), frozenNodes.end(), result.entity) != frozenNodes.end()' failed
                if #platformEdgeIdsBetweenNodeIds == 1 then
                    print('only one platform edge, going to split it')
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
                print('at least two platform edges found')

                local eventArgs = arrayUtils.cloneDeepOmittingFields(args, { 'splitPlatformNode1Id', 'splitPlatformNode2Id', 'splitTrackNode1Id', 'splitTrackNode2Id', })
                print('track bulldoze requested, platformEdgeIdsBetweenNodeIds =') debugPrint(platformEdgeIdsBetweenNodeIds)
                eventArgs.platformEdgeList = stationHelpers.getEdgeIdsProperties(platformEdgeIdsBetweenNodeIds)
                -- print('track bulldoze requested, platformEdgeList =') debugPrint(eventArgs.platformEdgeList)
                print('track bulldoze requested, trackEdgeIdsBetweenNodeIds =') debugPrint(trackEdgeIdsBetweenNodeIds)
                eventArgs.trackEdgeList = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenNodeIds)
                -- print('track bulldoze requested, trackEdgeList =') debugPrint(eventArgs.trackEdgeList)
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
                    print('no track edge is close enough to the middle (halfway between the ends), going to add a split. iAcrossMidLength =', iAcrossMidLength)
                    if iAcrossMidLength < 1 then
                        print('WARNING: trouble finding trackEdgeListMidIndex')
                        print('totalLength =') debugPrint(totalLength)
                        print('trackLengths =') debugPrint(trackLengths)
                        print('halfTotalLength =') debugPrint(halfTotalLength)
                        print('lengthSoFar =') debugPrint(lengthSoFar)
                    end
                    local edgeId = trackEdgeIdsBetweenNodeIds[iAcrossMidLength]
                    if not(edgeUtils.isValidAndExistingId(edgeId)) then return end

                    print('edgeId =') debugPrint(edgeId)
                    local position0 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[1][1])
                    local position1 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[2][1])
                    local tangent0 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[1][2])
                    local tangent1 = transfUtils.oneTwoThree2XYZ(eventArgs.trackEdgeList[iAcrossMidLength].posTanX2[2][2])
                    print('position0 =') debugPrint(position0)
                    print('position1 =') debugPrint(position1)
                    print('tangent0 =') debugPrint(tangent0)
                    print('tangent1 =') debugPrint(tangent1)
                    print('(halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength] =') debugPrint((halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength])

                    local nodeBetween = edgeUtils.getNodeBetween(
                        position0, position1, tangent0, tangent1,
                        (halfTotalLength - lengthSoFar) / trackLengths[iAcrossMidLength]
                    )
                    print('nodeBetween =') debugPrint(nodeBetween)
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
                print('eventArgs.trackEdgeListMidIndex =') debugPrint(eventArgs.trackEdgeListMidIndex)
                print('eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex] =') debugPrint(eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex])

                eventArgs.centrePlatforms = stationHelpers.getCentralEdgePositions(
                    eventArgs.platformEdgeList,
                    args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                    true
                )
                print('aaa')
                -- No, we need the leading indexes
                -- eventArgs.centrePlatformsFine = stationHelpers.getCentralEdgePositions(
                --     eventArgs.platformEdgeList,
                --     1,
                --     true
                -- )
                eventArgs.centrePlatformsFine = stationHelpers.getCentralEdgePositions(
                    eventArgs.centrePlatforms,
                    1
                )
                -- print('centrePlatformsFine =') debugPrint(centrePlatformsFine)

                local centrePlatformIndex_Nearest2_TrackEdgeListMid = stationHelpers.getCentrePlatformIndex_Nearest2_TrackEdgeListMid(eventArgs)
                print('centrePlatformIndex_Nearest2_TrackEdgeListMid =') debugPrint(centrePlatformIndex_Nearest2_TrackEdgeListMid)

                local platformWidth = eventArgs.centrePlatforms[centrePlatformIndex_Nearest2_TrackEdgeListMid].width
                eventArgs.leftPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, - platformWidth * 0.45)
                eventArgs.rightPlatforms = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatforms, platformWidth * 0.45)
                print('alalalalal')
                local centreTracks = stationHelpers.getCentralEdgePositions(
                    eventArgs.trackEdgeList,
                    args.isCargo and _constants.maxCargoWaitingAreaEdgeLength or _constants.maxPassengerWaitingAreaEdgeLength,
                    false
                )
                print('eee')
                eventArgs.isTrackOnPlatformLeft = stationHelpers.getIsTrackOnPlatformLeft(
                    eventArgs.leftPlatforms,
                    eventArgs.rightPlatforms,
                    centrePlatformIndex_Nearest2_TrackEdgeListMid,
                    eventArgs.trackEdgeList[eventArgs.trackEdgeListMidIndex]
                )
                print('eventArgs.isTrackOnPlatformLeft =', eventArgs.isTrackOnPlatformLeft)

                print('calculating slopedAreasFine, platformWidth =', platformWidth)
                eventArgs.slopedAreasFine = {}
                if eventArgs.isTrackOnPlatformLeft then
                    -- I add 2 coz it is a little less than half the width of the 5m sloped area,
                    eventArgs.slopedAreasFine[5] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 2)
                    eventArgs.slopedAreasFine[10] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 4.5)
                    eventArgs.slopedAreasFine[20] = stationHelpers.getShiftedEdgePositions(eventArgs.centrePlatformsFine, platformWidth * 0.5 + 9.5)
                else
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
                print('eventArgs.nTerminal =', eventArgs.nTerminal)

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
                    print('ERROR: args.stationConstructionId not valid')
                    return
                end
                if type(args.removedTerminalEdgeLists) ~= 'table' or type(args.removedTerminalEdgeLists.trackEdgeLists) ~= 'table' then
                    _actions.bulldozeStation(args.stationConstructionId)
                    print('ERROR: args.removedTerminalEdgeLists.trackEdgeLists not available')
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
                    print('ERROR: args.stationConstructionId not valid')
                    return
                end
                _actions.buildSnappyTracks(
                    stationHelpers.getStationEndEntities(args.stationConstructionId)
                )
            elseif name == _eventNames.BULLDOZE_STATION_REQUESTED then
                _actions.bulldozeStation(args.stationConstructionId)
            elseif name == _eventNames.SUBWAY_JOIN_REQUESTED then
                if not(edgeUtils.isValidAndExistingId(args.join2StationId))
                or not(edgeUtils.isValidAndExistingId(args.subwayId)) then
                    print('ERROR: args.join2StationId or args.subwayId is invalid')
                    return
                end
                _actions.addSubway(args.join2StationId, args.subwayId, _eventNames.BUILD_SNAPPY_TRACKS_REQUESTED)
            end
        end,
        _myErrorHandler
    )
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            -- print('guiHandleEvent caught id =', id, 'name =', name)
            local _joinSubway = function(subwayConstructionId)
                if not(edgeUtils.isValidAndExistingId(subwayConstructionId)) then return end

                local con = api.engine.getComponent(subwayConstructionId, api.type.ComponentType.CONSTRUCTION)
                -- if con ~= nil then print('con.fileName =') debugPrint(con.fileName) end
                if con == nil or type(con.fileName) ~= 'string' or con.fileName ~= _constants.subwayConFileName or con.transf == nil then return end

                local subwayTransfApi = con.transf
                if subwayTransfApi == nil then return end

                local conTransf = transfUtilsUG.new(subwayTransfApi:cols(0), subwayTransfApi:cols(1), subwayTransfApi:cols(2), subwayTransfApi:cols(3))
                if conTransf == nil then return end

                print('conTransf =') debugPrint(conTransf)
                local nearbyFreestyleStations = stationHelpers.getNearbyFreestyleStationsList(conTransf, _constants.searchRadius4NearbyStation2Join, true)
                -- print('nearbyFreestyleStations =') debugPrint(nearbyFreestyleStations)
                print('#nearbyFreestyleStations =', #nearbyFreestyleStations)
                if #nearbyFreestyleStations == 0 then return end

                guiHelpers.showNearbyStationPicker(
                    false, -- subways are only for passengers
                    nearbyFreestyleStations,
                    _eventId,
                    _eventNames.SUBWAY_JOIN_REQUESTED,
                    nil,
                    {
                        subwayId = subwayConstructionId
                        -- join2StationId will be added by the popup
                    }
                )
            end
            xpcall(
                function()
                    if name == 'builder.apply' then
                        guiHelpers.hideAllWarnings()
                        -- print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                        if id == 'bulldozer' then
                            for _, constructionId in pairs(args.proposal.toRemove) do
                                print('about to bulldoze construction', constructionId)
                                if edgeUtils.isValidAndExistingId(constructionId) then
                                    local con = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
                                    if con ~= nil and type(con.fileName) == 'string' and con.fileName == _constants.stationConFileName then
                                        -- print('args = ') debugPrint(args)
                                        -- bulldozed a station module AND there are more left
                                        -- print('bulldozing a component of a freestyle station, con.params.modules =') debugPrint(con.params.modules)
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
                                                print('nTerminalToRemove =', nTerminalToRemove)
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
                                                    print('ERROR: cannot find id of deleted terminal')
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

                            -- print('args =') debugPrint(args)
                            local subwayId = args.result[1]
                            -- print('construction built, construction id =') debugPrint(subwayId)

                            _joinSubway(subwayId)
                        elseif id == 'streetTerminalBuilder' then
                            -- waypoint, traffic light, my own waypoints built
                            if args and args.proposal and args.proposal.proposal
                            and args.proposal.proposal.edgeObjectsToAdd
                            and args.proposal.proposal.edgeObjectsToAdd[1]
                            and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                            then
                                local _platformWaypointModelId = api.res.modelRep.find(_constants.platformWaypointModelId)
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

                                    -- make sure the waypoints are on connected tracks
                                    local contiguousTrackEdgeProps = stationHelpers.getTrackEdgePropsBetweenEdgeIds(
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
                                        api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId)
                                    )
                                    print('contiguous track edges =') debugPrint(contiguousTrackEdgeProps)
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
                                    local trackWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_trackWaypointModelId)
                                    if #trackWaypointIds ~= 2 then return end

                                    local platformWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_platformWaypointModelId)
                                    if #platformWaypointIds ~= 2 then return end

                                    local edgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(platformWaypointIds[1])
                                    local edgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                                    local isCargo = trackUtils.isCargoPlatform(edgeTrack.trackType)
                                    print('TWENTY, isCargo =', isCargo)

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
                                if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _platformWaypointModelId then
                                    local waypointData = _validateWaypointBuilt(_platformWaypointModelId, true)
                                    print('platformWaypointData =') debugPrint(waypointData)
                                    if not(waypointData) then return end

                                    _handleValidWaypointBuilt()

                                    -- if any platform nodes are joints between more than 2 platform-tracks,
                                    -- we bar building two platform waypoints outside a junction.
                                    -- Or maybe, we could bar intersecting platform-tracks altogether:
                                    -- they look mighty ugly. Maybe someone knows how to fix their looks? ask UG TODO

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
                                        print('WARNING upgrading, addedSegment =') -- debugPrint(addedSegment)
                                        -- print('args.data.entity2tn =') debugPrint(args.data.entity2tn)
                                        -- LOLLO TODO when upgrading, the game adds a segment and two nodes, which won't work with the following.
                                        -- Probably unimportant, but check it coz edgeUtils.getLastBuiltEdgeId errors out (gracefully)
                                        -- when adding electrification or high speed.
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
                    elseif name == 'select' then
                        -- LOLLO TODO MAYBE same with stations. Maybe one day.
                        -- print('LOLLO caught gui select, id = ', id, ' name = ', name, ' args = ')
                        -- debugPrint(args)

                        _joinSubway(args)
                    end
                end,
                _myErrorHandler
            )
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