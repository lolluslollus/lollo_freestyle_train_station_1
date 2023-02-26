local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local guiHelpers = require('lollo_fence.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local modelHelper = require('lollo_fence.modelHelper')
local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

local _eventId = _constants.eventData.eventId
local _eventNames = _constants.eventData.eventNames
local _guiFenceWaypointModelId = nil
local _guiTexts = {
    differentPlatformWidths = '',
    waypointAlreadyBuilt = '',
    waypointsCrossCrossing = '',
    waypointsCrossSignal = '',
    waypointsCrossStation = '',
    waypointsTooFar = '',
    waypointsNotConnected = '',
}

local _actions = {
    buildFence = function(trackEdgeList, yShift, conTransf, isWaypoint2ArrowAgainstTrackDirection)
        logger.print('_buildFence starting, args =')
        if not(trackEdgeList) or #trackEdgeList == 0 then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.fenceConFileName

        local _mainTransf = arrayUtils.cloneDeepOmittingFields(conTransf)
        local _inverseMainTransf = transfUtils.getInverseTransf(_mainTransf)

        local transfs = arrayUtils.map(
            arrayUtils.map(
                trackEdgeList,
                function(record)
                    -- logger.print('record =') logger.debugPrint(record)
                    return {
                        posTanX2 = transfUtils.getPosTanX2Transformed(record.posTanX2, _inverseMainTransf),
                        xRatio = record.xRatio,
                        yRatio = record.yRatio,
                    }
                end
            ),
            function(record)
                -- logger.print('record2 =') logger.debugPrint(record)
                local skew = record.posTanX2[2][1][3] - record.posTanX2[1][1][3]
                -- if not(isWaypoint2ArrowAgainstTrackDirection) then skew = -skew end -- NO!
                return transfUtils.getTransf_XSkewedOnZ(
                    transfUtils.getTransf_XScaled(
                        moduleHelpers.getPlatformObjectTransf_AlwaysVertical(record.posTanX2),
                        record.xRatio
                    ),
                    skew
                )
            end
        )

        local newParams = {
            inverseMainTransf = _inverseMainTransf,
            mainTransf = _mainTransf,
            seed = math.abs(math.ceil(conTransf[13] * 1000)),
            transfs = transfs,
        }
        local paramsMetadata = modelHelper.getChangeableParamsMetadata()
        -- logger.print('paramsMetadata =') logger.debugPrint(paramsMetadata)
        -- logger.print('modelHelper.getDefaultIndexes() =') logger.debugPrint(modelHelper.getDefaultIndexes())
        for _, pm in pairs(paramsMetadata) do
            -- logger.print('pm.key =', pm.key or 'NIL')
            newParams[pm.key] = modelHelper.getDefaultIndexes()[pm.key]
        end
        newCon.params = newParams
        -- logger.print('newParams =') logger.debugPrint(arrayUtils.cloneDeepOmittingFields(newParams, {'transfs'}, true))

        newCon.transf = api.type.Mat4f.new(
            api.type.Vec4f.new(conTransf[1], conTransf[2], conTransf[3], conTransf[4]),
            api.type.Vec4f.new(conTransf[5], conTransf[6], conTransf[7], conTransf[8]),
            api.type.Vec4f.new(conTransf[9], conTransf[10], conTransf[11], conTransf[12]),
            api.type.Vec4f.new(conTransf[13], conTransf[14], conTransf[15], conTransf[16])
        )

        newCon.playerEntity = api.engine.util.getPlayer()

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd[1] = newCon

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true
        -- context.cleanupStreetGraph = true
        -- context.gatherBuildings = false -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer()

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                if success then
                    local fenceConstructionId = result.resultEntities[1]
                    logger.print('_buildFence succeeded, conId = ', fenceConstructionId)
                else
                    logger.warn('_buildFence failed, result =') logger.warningDebugPrint(result)
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

    updateConstruction = function(oldConId, paramKey, newParamValueIndexBase0)
        logger.print('_updateConstruction starting, conId =', oldConId or 'NIL', 'paramKey =', paramKey or 'NIL', 'newParamValueIndexBase0 =', newParamValueIndexBase0 or 'NIL')

        if not(edgeUtils.isValidAndExistingId(oldConId)) then
            logger.warn('_updateConstruction received an invalid conId')
            return
        end
        local oldCon = api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil or oldCon.fileName ~= _constants.fenceConFileName then
            logger.print('_updateConstruction cannot get the con, or it is not one of mine')
            return
        end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName

        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        newParams[paramKey] = newParamValueIndexBase0
        newParams.seed = newParams.seed + 1
        newCon.params = newParams
        logger.print('oldCon.params =') logger.debugPrint(oldCon.params)
        logger.print('newCon.params =') logger.debugPrint(newCon.params)
        newCon.playerEntity = api.engine.util.getPlayer()
        newCon.transf = oldCon.transf

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

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                logger.print('_updateConstruction callback, success =', success)
                -- logger.debugPrint(result)
                if not(success) then
                    logger.warn('_updateConstruction callback failed')
                    logger.warn('_updateConstruction proposal =') logger.warningDebugPrint(proposal)
                    logger.warn('_updateConstruction result =') logger.warningDebugPrint(result)
                    -- LOLLO TODO give feedback
                else
                    local newConId = result.resultEntities[1]
                    logger.print('_updateConstruction succeeded, stationConId = ', newConId)
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
    handleParamValueChanged = function(conId, paramsMetadata, paramKey, newParamValueIndexBase0)
        logger.print('handleParamValueChanged starting for conId =', conId or 'NIL')
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warn('_handleParamValueChanged got no con or no valid con')
            return
        end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if con == nil or con.fileName ~= _constants.fenceConFileName then
            logger.print('_handleParamValueChanged cannot get the con or it is not one of mine')
            return
        end

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.CON_PARAMS_UPDATED,
            {
                conId = conId,
                paramKey = paramKey,
                newParamValueIndexBase0 = newParamValueIndexBase0,
            }
        ))
    end,
    handleBulldozeClicked = function(conId)
        logger.print('_handleBulldozeClicked starting for conId =', conId or 'NIL')
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warn('_handleBulldozeClicked got no con or no valid con')
            return
        end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if con == nil or con.fileName ~= _constants.fenceConFileName then
            logger.print('_handleBulldozeClicked cannot get the con or it is not one of mine')
            return
        end

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = conId,
            }
        ))
    end,
    handleValidFenceWaypointBuilt = function(lastWaypointData)
        -- local lastWaypointData = {
        --     isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        --     newWaypointId = newWaypointId,
        --     twinWaypointId = twinWaypointId
        -- }
        logger.print('_handleValidFenceWaypointBuilt starting, lastWaypointData =')
        logger.debugPrint(lastWaypointData)
        local fenceWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(_guiFenceWaypointModelId)
        if #fenceWaypointIds ~= 2 then return end

        -- sort the ids, the sequence matters here
        if fenceWaypointIds[1] == lastWaypointData.newWaypointId then
            fenceWaypointIds[1], fenceWaypointIds[2] = fenceWaypointIds[2], fenceWaypointIds[1]
        end
        -- set a place to build the fence con
        local fenceWaypoint1Pos = edgeUtils.getObjectPosition(fenceWaypointIds[1])
        local fenceWaypoint2Pos = edgeUtils.getObjectPosition(fenceWaypointIds[2])
        if fenceWaypoint1Pos == nil or fenceWaypoint2Pos == nil then
            logger.err('_handleValidFenceWaypointBuilt cannot find the fence waypoint positions')
            return
        end

        local edge1Id = api.engine.system.streetSystem.getEdgeForEdgeObject(fenceWaypointIds[1])
        local edge2Id = api.engine.system.streetSystem.getEdgeForEdgeObject(fenceWaypointIds[2])
        if not(edgeUtils.isValidAndExistingId(edge1Id)) or not(edgeUtils.isValidAndExistingId(edge2Id)) then
            logger.err('_handleValidFenceWaypointBuilt cannot find the fence waypoint edges')
            return
        end

        local fenceWaypointMidTransf = transfUtils.position2Transf({
            (fenceWaypoint1Pos[1] + fenceWaypoint2Pos[1]) * 0.5,
            (fenceWaypoint1Pos[2] + fenceWaypoint2Pos[2]) * 0.5,
            (fenceWaypoint1Pos[3] + fenceWaypoint2Pos[3]) * 0.5,
        })

        local baseEdge1 = api.engine.getComponent(edge1Id, api.type.ComponentType.BASE_EDGE)
        local baseEdge2 = api.engine.getComponent(edge2Id, api.type.ComponentType.BASE_EDGE)
        if not(baseEdge1) or not(baseEdge2) or not(baseEdge1.objects) or not(baseEdge2.objects) then
            logger.err('_handleValidFenceWaypointBuilt cannot find edge data')
            return
        end

        -- convert userdata to table
        local edge2Node0Pos = api.engine.getComponent(baseEdge2.node0, api.type.ComponentType.BASE_NODE).position
        local edge2Node1Pos = api.engine.getComponent(baseEdge2.node1, api.type.ComponentType.BASE_NODE).position

        -- useless
        -- local edgeObject1Side, edgeObject2Side
        -- for _, obj in pairs(baseEdge1.objects) do
        --     if obj[1] == fenceWaypointIds[1] then
        --         edgeObject1Side = obj[2]
        --         break
        --     end
        -- end
        -- for _, obj in pairs(baseEdge2.objects) do
        --     if obj[1] == fenceWaypointIds[2] then
        --         edgeObject2Side = obj[2]
        --         break
        --     end
        -- end
        -- if not(edgeObject1Side) or not(edgeObject2Side) then
        --     logger.err('_handleValidFenceWaypointBuilt cannot find edge object sides')
        --     return
        -- end

        local eventArgs = {
            edge1Id = edge1Id,
            edge2Id = edge2Id,
            edge2Node0Pos = {edge2Node0Pos.x, edge2Node0Pos.y, edge2Node0Pos.z},
            edge2Node1Pos = {edge2Node1Pos.x, edge2Node1Pos.y, edge2Node1Pos.z},
            fenceWaypoint1Id = fenceWaypointIds[1],
            fenceWaypoint2Id = fenceWaypointIds[2],
            fenceWaypointMidTransf = fenceWaypointMidTransf,
            isWaypoint2ArrowAgainstTrackDirection = lastWaypointData.isWaypointArrowAgainstTrackDirection,
        }

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.FENCE_WAYPOINTS_BUILT,
            eventArgs
        ))
    end,
    validateFenceWaypointBuilt = function(targetWaypointModelId, newWaypointId, waypointEdgeId, isWaypointArrowAgainstTrackDirection, trackTypeIndex)
        logger.print('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
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

        if #similarObjectIdsInAnyEdges < 2 then
            -- not ready yet
            -- guiHelpers.showWarningWithGoto(_guiTexts.buildMoreWaypoints), newWaypointId)
            return false
        end

        local newWaypointPosition = edgeUtils.getObjectPosition(newWaypointId)
        local twinWaypointId = newWaypointId == similarObjectIdsInAnyEdges[1]
            and similarObjectIdsInAnyEdges[2]
            or similarObjectIdsInAnyEdges[1]
        local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)

        -- forbid building waypoints too far apart, which would make the fence too long
        if newWaypointPosition ~= nil and twinWaypointPosition ~= nil then
            local distance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition)
            if distance > _constants.maxFenceWaypointDistance then
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
        end

        local contiguousTrackEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
            api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
            api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId),
            _constants.maxFenceWaypointDistance,
            true,
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
--[[
        -- make sure the waypoints are not overlapping existing station tracks or platforms, for any sort of station
        for _, edgeId in pairs(contiguousTrackEdgeIds) do
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
]]
--[[
        local contiguousEdgeIds = {}
        for _, value in pairs(contiguousTrackEdgeProps) do
            arrayUtils.addUnique(contiguousEdgeIds, value.entity)
        end
        logger.print('contiguousEdgeIds =') logger.debugPrint(contiguousEdgeIds)
]]
--[[
        -- make sure there are no crossings between the waypoints
        local nodesBetweenWps = edgeUtils.getNodeIdsBetweenNeighbourEdgeIds(contiguousEdgeIds, false)
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
]]
--[[
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
]]

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
            for _, td in pairs(trackDistances) do
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
            isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
            newWaypointId = newWaypointId,
            twinWaypointId = twinWaypointId
        }
    end,
}

function data()
    return {
        guiInit = function()
            -- read variables
            _guiFenceWaypointModelId = api.res.modelRep.find(_constants.fenceWaypointModelId)
            -- read texts
            _guiTexts.differentPlatformWidths = _('DifferentPlatformWidths')
            _guiTexts.waypointAlreadyBuilt = _('WaypointAlreadyBuilt')
            _guiTexts.waypointsCrossCrossing = _('WaypointsCrossCrossing')
            _guiTexts.waypointsCrossSignal = _('WaypointsCrossSignal')
            _guiTexts.waypointsCrossStation = _('WaypointsCrossStation')
            _guiTexts.waypointsTooFar = _('WaypointsTooFar')
            _guiTexts.waypointsNotConnected = _('WaypointsNotConnected')
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            xpcall(
                function()
                    logger.print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
                    if name == _eventNames.FENCE_WAYPOINTS_BUILT then
                        -- fence waypoints built, eventArgs = {
                        --     edge1Id = edge1Id,
                        --     edge2Id = edge2Id,
                        --     edge2Node0Pos = edge2Node0Pos,
                        --     edge2Node1Pos = edge2Node1Pos,
                        --     fenceWaypoint1Id = fenceWaypointIds[1],
                        --     fenceWaypoint2Id = fenceWaypointIds[2],
                        --     fenceWaypointMidTransf = fenceWaypointMidTransf,
                        --     isWaypoint2ArrowAgainstTrackDirection = true
                        -- }
                        logger.print('args =') logger.debugPrint(args)
                        local trackEdgeIdsBetweenEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
                            args.edge1Id, args.edge2Id, _constants.maxFenceWaypointDistance, true, logger.isExtendedLog()
                        )
                        if #trackEdgeIdsBetweenEdgeIds > 0 then
                            local trackEdgeList_Ordered = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenEdgeIds)
                            if transfUtils.isXYZSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[2][1],
                                args.edge2Node1Pos
                            )
                            then
                                logger.print('isWaypoint2ArrowAgainstTrackDirection does not need reversing')
                            elseif transfUtils.isXYZSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[1][1],
                                args.edge2Node1Pos
                            ) then
                                logger.print('reversing isWaypoint2ArrowAgainstTrackDirection')
                                args.isWaypoint2ArrowAgainstTrackDirection = not(args.isWaypoint2ArrowAgainstTrackDirection)
                            else
                                logger.warn('cannot find the right direction to build my fence')
                            end

                            if args.isWaypoint2ArrowAgainstTrackDirection then
                                logger.print('reversing trackEdgeList')
                                trackEdgeList_Ordered = stationHelpers.reversePosTanX2ListInPlace(trackEdgeList_Ordered)
                                -- yShift = -yShift -- NO!
                            end
                            logger.print('trackEdgeList =') logger.debugPrint(trackEdgeList_Ordered)
                            local trackEdgeListFine = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(
                                trackEdgeList_Ordered,
                                1,
                                false,
                                false
                            )
                            -- logger.print('trackEdgeListFine =') logger.debugPrint(trackEdgeListFine)
                            if #trackEdgeListFine > 0 then
                                local yShift = trackEdgeList_Ordered[1].width * 0.5
                                local trackEdgeListShifted = arrayUtils.map(
                                    trackEdgeListFine,
                                    function(tel)
                                        -- the func returns three arguments, I only return the first, so no direct return
                                        local gps, xRatio, yRatio = transfUtils.getParallelSideways(tel.posTanX2, yShift)
                                        return {
                                            posTanX2 = gps,
                                            xRatio = xRatio,
                                            yRatio = yRatio,
                                        }
                                    end
                                )
                                logger.print('trackEdgeListShifted, first 3 records =')
                                logger.debugPrint(trackEdgeListShifted[1])
                                logger.debugPrint(trackEdgeListShifted[2])
                                logger.debugPrint(trackEdgeListShifted[3])
                                if #trackEdgeListShifted > 0 then
                                    _actions.buildFence(
                                        trackEdgeListShifted,
                                        yShift,
                                        args.fenceWaypointMidTransf,
                                        args.isWaypoint2ArrowAgainstTrackDirection
                                    )
                                end
                            end
                        end
                        _actions.replaceEdgeWithSameRemovingObject(args.fenceWaypoint1Id)
                        _actions.replaceEdgeWithSameRemovingObject(args.fenceWaypoint2Id)
                    elseif name == _eventNames.CON_PARAMS_UPDATED then
                        _actions.updateConstruction(args.conId, args.paramKey, args.newParamValueIndexBase0)
                    end
                end,
                logger.xpErrorHandler
            )
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            -- logger.print('guiHandleEvent caught id =', id, 'name =', name)
            if (name == 'builder.apply' and id == 'streetTerminalBuilder') then -- for performance
                xpcall(
                    function()
                        -- logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =')
                        -- waypoint, traffic light, my own waypoints built
                        if args and args.proposal and args.proposal.proposal
                        and args.proposal.proposal.edgeObjectsToAdd
                        and args.proposal.proposal.edgeObjectsToAdd[1]
                        and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                        then
                            -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                            if args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == _guiFenceWaypointModelId then
                                logger.print('args.proposal.proposal.edgeObjectsToAdd[1] =') logger.debugPrint(args.proposal.proposal.edgeObjectsToAdd[1])
                                local waypointData = _guiActions.validateFenceWaypointBuilt(
                                    _guiFenceWaypointModelId,
                                    args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                    args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                    args.proposal.proposal.edgeObjectsToAdd[1].left or false,
                                    args.proposal.proposal.addedSegments[1].trackEdge.trackType
                                )
                                logger.print('fenceWaypointData =') logger.debugPrint(waypointData)
                                if not(waypointData) then return end

                                _guiActions.handleValidFenceWaypointBuilt(waypointData)
                            end
                        end
                    end,
                    logger.xpErrorHandler
                )
            elseif (name == 'select' and id == 'mainView') then
                -- select happens after idAdded, which looks like:
                -- id =	temp.view.entity_28693	name =	idAdded
                -- id =	temp.view.entity_26372	name =	idAdded
                xpcall(
                    function()
                        logger.print('guiHandleEvent caught id =', id, 'name =', name, 'args =') logger.debugPrint(args)
                        local conId = args
                        if not(edgeUtils.isValidAndExistingId(conId)) then return end

                        local con = _guiActions.getCon(conId)
                        if not(con) or con.fileName ~= _constants.fenceConFileName then return end

                        logger.print('selected one of my fences, it has conId =', conId, 'and con.fileName =', con.fileName)
                        guiHelpers.addConConfigToWindow(
                            conId,
                            _guiActions.handleParamValueChanged,
                            modelHelper.getChangeableParamsMetadata(),
                            con.params,
                            _guiActions.handleBulldozeClicked
                        )
                        -- not required but it might prevent a crash with the conMover: no it does not
                        -- local paramsMetadata = modelHelper.getChangeableParamsMetadata()
                        -- local changeableParams = {}
                        -- for _, paramMetadata in pairs(paramsMetadata) do
                        --     changeableParams[#changeableParams+1] = arrayUtils.cloneDeepOmittingFields(
                        --         con.params[paramMetadata.key]
                        --     )
                        -- end
                        -- guiHelpers.addConConfigToWindow(
                        --     conId,
                        --     _guiActions.handleParamValueChanged,
                        --     paramsMetadata,
                        --     changeableParams,
                        --     _guiActions.handleBulldozeClicked
                        -- )
                    end,
                    logger.xpErrorHandler
                )
            end
        end,
        -- guiUpdate = function()
        -- end,
        -- load = function(loadedState)
        -- end,
        -- save = function()
        -- end,
        -- update = function()
        -- end,
    }
end
