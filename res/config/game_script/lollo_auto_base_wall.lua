local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local comparisonUtils = require('lollo_freestyle_train_station.comparisonUtils')
local constants = require('lollo_freestyle_train_station.constants')
local guiHelpers = require('lollo_base_wall.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local modelHelper = require('lollo_base_wall.modelHelper')
local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

local _eventId = constants.eventData.autoBaseWall.eventId
local _eventNames = constants.eventData.autoBaseWall.eventNames
local _guiFenceWaypointModelId = nil
local _guiFenceWaypointPreciseModelId = nil
local _guiTexts = {
    differentPlatformWidths = '',
    invalidEdge = '',
    invalidPosition = '',
    markersNotConnected = '',
    waypointAlreadyBuilt = '',
    waypointsCrossCrossing = '',
    waypointsCrossSignal = '',
    waypointsCrossStation = '',
    waypointsTooClose = '',
    waypointsTooFar = '',
    waypointsNotConnected = '',
}
-- these can be called by any thread
local _utils = {
    getConFileName = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return nil end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) then return nil end

        return con.fileName
    end,
    getConPosition = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return nil end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return nil end

        local conTransfLua = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        return {conTransfLua[13], conTransfLua[14], conTransfLua[15]}
    end,
    getConTransf = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return nil end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return nil end

        local conTransfLua = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        return conTransfLua
    end,
    getHeight = function(posTanX2)
        local baseHeight1 = 0
        local baseHeight2 = 0
        xpcall(
            function()
                baseHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    posTanX2[1][1][1],
                    posTanX2[1][1][2]
                ))
                baseHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    posTanX2[2][1][1],
                    posTanX2[2][1][2]
                ))
            end,
            logger.errorOut
        )
        return math.max((posTanX2[1][1][3] or 0) - (baseHeight1 or 0), (posTanX2[2][1][3] or 0) - (baseHeight2 or 0))
    end,
    getNearestEdgeToCon = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return nil end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return nil end

        local conTransfLua = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        local nearestEdgeId = edgeUtils.track.getNearestEdgeIdStrict(
            conTransfLua,
            conTransfLua[15] - constants.splitterZToleranceM,
            conTransfLua[15] + constants.splitterZToleranceM,
            logger.isExtendedLog()
        )

        return nearestEdgeId
    end
}
-- these are for the worker thread
local _actions = {
    buildFence = function(trackRecords, trackRecords_yFlipped, yShift, conTransf, isWaypoint2ArrowAgainstTrackDirection)
        logger.infoOut('_buildFence starting')
        if not(trackRecords) or #trackRecords == 0 then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = constants.autoBaseWallConFileName

        local _mainTransf = arrayUtils.cloneDeepOmittingFields(conTransf)
        local _inverseMainTransf = transfUtils.getInverseTransf(_mainTransf)

        local getInverseTransfs = function(records)
            return arrayUtils.map(
                records,
                function(record)
                    return {
                        absolutePosTanX2 = record.posTanX2_main,
                        groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                        hasLevelCrossing = record.hasLevelCrossing,
                        posTanX2_main = transfUtils.getPosTanX2Transformed(record.posTanX2_main, _inverseMainTransf),
                        xRatio_main = record.xRatio_main,
                        yRatio_main = record.yRatio_main,
                    }
                end
            )
        end
        local inverseTransfs = getInverseTransfs(trackRecords)
        local inverseTransfs_yFlipped = getInverseTransfs(trackRecords_yFlipped)
--[[
        -- This should be more accurate, but it looks the same
        -- so we make one array instead of two
        local newTransfs_ground = arrayUtils.map(
            inverseTransfs,
            function(record)
                return {
                    groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                    transf = transfUtils.getTransf_XScaled(
                        moduleHelpers.getPlatformObjectTransf_WithYRotation(record.posTanX2_main),
                        record.xRatio_main
                    ),
                }
            end
        )
]]

        local getNewTransfs_ground = function(transfs)
            return arrayUtils.map(
                transfs,
                function(record)
                    local skew = record.posTanX2_main[2][1][3] - record.posTanX2_main[1][1][3]
                    return {
                        absolutePosTanX2 = record.absolutePosTanX2,
                        groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                        hasLevelCrossing = record.hasLevelCrossing,
                        height = _utils.getHeight(record.absolutePosTanX2),
                        transf = transfUtils.getTransf_XSkewedOnZ(
                            transfUtils.getTransf_XScaled(
                                moduleHelpers.getPlatformObjectTransf_AlwaysVertical(record.posTanX2_main),
                                record.xRatio_main
                            ),
                            skew
                        ),
                    }
                end
            )
        end
        local newTransfs_ground = getNewTransfs_ground(inverseTransfs)
        local newTransfs_ground_yFlipped = getNewTransfs_ground(inverseTransfs_yFlipped)

        logger.infoOut('first 3 newTransfs_ground =', newTransfs_ground[1], newTransfs_ground[2], newTransfs_ground[3])
        logger.infoOut('first 3 newTransfs_ground_yFlipped =', newTransfs_ground_yFlipped[1], newTransfs_ground_yFlipped[2], newTransfs_ground_yFlipped[3])

        local newParams = {
            inverseMainTransf = _inverseMainTransf,
            mainTransf = _mainTransf,
            seed = math.abs(math.ceil(conTransf[13] * 1000)),
            -- transfs = newTransfs, -- early releases, now obsolete
            transfs_ground = newTransfs_ground,
            transfs_ground_yFlipped = newTransfs_ground_yFlipped,
        }
        local paramsMetadata = modelHelper.getChangeableParamsMetadata()
        -- logger.infoOut('paramsMetadata =', paramsMetadata})
        -- logger.infoOut('modelHelper.getDefaultIndexes() =', modelHelper.getDefaultIndexes()})
        for _, pm in pairs(paramsMetadata) do
            -- logger.infoOut('pm.key =', pm.key})
            newParams[pm.key] = modelHelper.getDefaultIndexes()[pm.key]
        end
        newCon.params = newParams
        newCon.transf = transfUtils.getSolTransfFromLuaTransf(conTransf)
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
                    logger.infoOut('_buildFence succeeded, conId = ', fenceConstructionId)
                else
                    logger.warningOut('_buildFence failed, result =', result)
                end
                collectgarbage()
            end
        )
    end,
    bulldozeConstruction = function(conId)
        logger.infoOut('bulldozeConstruction starting, conId = ', conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return end

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
                logger.infoOut('LOLLO _bulldozeConstruction success = ', success)
            end
        )
    end,
    replaceEdgeWithSameRemovingObject = function(objectIdToRemove)
        logger.infoOut('_replaceEdgeWithSameRemovingObject starting')
        if not(edgeUtils.isValidAndExistingId(objectIdToRemove)) then return end

        logger.infoOut('_replaceEdgeWithSameRemovingObject found, the edge object id is valid')
        local oldEdgeId = api.engine.system.streetSystem.getEdgeForEdgeObject(objectIdToRemove)
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return end

        logger.infoOut('_replaceEdgeWithSameRemovingObject found, the old edge id is valid')
        -- replaces a track segment with an identical one, without destroying the buildings
        local proposal = stationHelpers.getProposal2ReplaceEdgeWithSameRemovingObject(oldEdgeId, objectIdToRemove)
        if not(proposal) then return end

        logger.infoOut('_replaceEdgeWithSameRemovingObject likes the proposal')

        local context = api.type.Context:new()
        -- context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true),
            function(result, success)
                logger.infoOut('LOLLO _replaceEdgeWithSameRemovingObject success = ', success)
            end
        )
    end,
    updateConstruction = function(oldConId, paramKey, newParamValueIndexBase0)
        logger.infoOut('_updateConstruction starting, conId =', oldConId, 'paramKey =', paramKey, 'newParamValueIndexBase0 =', newParamValueIndexBase0)

        if not(edgeUtils.isValidAndExistingId(oldConId)) then
            logger.warningOut('_updateConstruction received an invalid conId')
            return
        end
        local oldCon = api.engine.getComponent(oldConId, api.type.ComponentType.CONSTRUCTION)
        if oldCon == nil or oldCon.fileName ~= constants.autoBaseWallConFileName then
            logger.infoOut('_updateConstruction cannot get the con, or it is not one of mine')
            return
        end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName

        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        -- recalc height coz the terrain might have changed since the last update
        for _, transf_ground in pairs(newParams.transfs_ground) do
            transf_ground.height = _utils.getHeight(transf_ground.absolutePosTanX2)
        end
        for _, transf_ground in pairs(newParams.transfs_ground_yFlipped) do
            transf_ground.height = _utils.getHeight(transf_ground.absolutePosTanX2)
        end
        -- update last changed parameter
        newParams[paramKey] = newParamValueIndexBase0
        -- boilerplate
        newParams.seed = newParams.seed + 1
        newCon.params = newParams
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
                logger.infoOut('_updateConstruction callback, success =', success)
                if not(success) then
                    logger.warningOut('_updateConstruction callback failed', '_updateConstruction proposal =', proposal, '_updateConstruction result =', result)
                    -- LOLLO TODO give feedback
                else
                    local newConId = result.resultEntities[1]
                    logger.infoOut('_updateConstruction succeeded, stationConId = ', newConId)
                end
            end
        )
    end,
}
-- these are for the GUI thread
local _guiActions = {
    bulldozeConstructions = function(conIds)
        if type(conIds) ~= 'table' then return end

        for _, conId in pairs(conIds) do
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.BULLDOZE_CON_REQUESTED,
                {
                    conId = conId
                }
            ))
        end
    end,
    bulldozeWaypoints = function(objectIds)
        if type(objectIds) ~= 'table' then return end

        for _, objectId in pairs(objectIds) do
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                constants.eventData.lolloFreestyleTrainStation.eventId,
                constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    waypointId = objectId
                }
            ))
        end
    end,
    getCon = function(constructionId)
        if not(edgeUtils.isValidAndExistingId(constructionId)) then return nil end

        return api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
    end,
    handleParamValueChanged = function(conId, paramsMetadata, paramKey, newParamValueIndexBase0)
        logger.infoOut('handleParamValueChanged starting for conId =', conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warningOut('_handleParamValueChanged got no con or no valid con')
            return
        end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if con == nil or con.fileName ~= constants.autoBaseWallConFileName then
            logger.infoOut('_handleParamValueChanged cannot get the con or it is not one of mine')
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
    handleBulldozeClicked = function(conId) -- unused
        logger.infoOut('_handleBulldozeClicked starting for conId =', conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warningOut('_handleBulldozeClicked got no con or no valid con')
            return
        end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if con == nil or con.fileName ~= constants.autoBaseWallConFileName then
            logger.infoOut('_handleBulldozeClicked cannot get the con or it is not one of mine')
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
        --     isPrecise = true,
        --     isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        --     newWaypointId = newWaypointId,
        --     twinWaypointId = twinWaypointId
        -- }
        logger.infoOut('_handleValidFenceWaypointBuilt starting, lastWaypointData =', lastWaypointData)
        local fenceWaypointIds = stationHelpers.getAllEdgeObjectsWithModelId(lastWaypointData.isPrecise and _guiFenceWaypointPreciseModelId or _guiFenceWaypointModelId)
        if #fenceWaypointIds ~= 2 then return end

        -- sort the ids first placed first, the sequence matters here
        if fenceWaypointIds[1] == lastWaypointData.newWaypointId then
            fenceWaypointIds[1], fenceWaypointIds[2] = fenceWaypointIds[2], fenceWaypointIds[1]
        end
        -- set a place to build the fence con
        local fenceWaypoint1Pos = edgeUtils.getObjectPosition(fenceWaypointIds[1])
        local fenceWaypoint2Pos = edgeUtils.getObjectPosition(fenceWaypointIds[2])
        if fenceWaypoint1Pos == nil or fenceWaypoint2Pos == nil then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find the fence waypoint positions')
            return
        end

        local edge1Id = api.engine.system.streetSystem.getEdgeForEdgeObject(fenceWaypointIds[1])
        local edge2Id = api.engine.system.streetSystem.getEdgeForEdgeObject(fenceWaypointIds[2])
        if not(edgeUtils.isValidAndExistingId(edge1Id)) or not(edgeUtils.isValidAndExistingId(edge2Id)) then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find the fence waypoint edges')
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
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find edge data')
            return
        end

        local edge2Node0 = api.engine.getComponent(baseEdge2.node0, api.type.ComponentType.BASE_NODE)
        local edge2Node1 = api.engine.getComponent(baseEdge2.node1, api.type.ComponentType.BASE_NODE)
        if not(edge2Node0) or not(edge2Node0.position) or not(edge2Node1) or not(edge2Node1.position) then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find node data')
            return
        end
        -- convert userdata.XYZ to table.123
        local edge2Node0Pos = transfUtils.xYZ2OneTwoThree(edge2Node0.position)
        local edge2Node1Pos = transfUtils.xYZ2OneTwoThree(edge2Node1.position)

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
        --     logger.errorOut('_handleValidFenceWaypointBuilt cannot find edge object sides')
        --     return
        -- end

        local eventArgs = {
            edge1Id = edge1Id,
            edge2Id = edge2Id,
            edge2Node0Pos = edge2Node0Pos,
            edge2Node1Pos = edge2Node1Pos,
            -- fenceMarkerCon1Id = nil,
            -- fenceMarkerCon2Id = nil,
            fenceWaypoint1Id = fenceWaypointIds[1],
            fenceWaypoint2Id = fenceWaypointIds[2],
            fenceWaypointMidTransf = fenceWaypointMidTransf,
            isPrecise = lastWaypointData.isPrecise,
            isWaypoint2ArrowAgainstTrackDirection = lastWaypointData.isWaypointArrowAgainstTrackDirection,
        }

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.FENCE_WAYPOINTS_BUILT,
            eventArgs
        ))
    end,
    handleValidFenceMarkerBuilt = function(lastWaypointData)
        logger.infoOut('_handleValidFenceMarkerBuilt starting, lastWaypointData =', lastWaypointData)
        local markerCount = arrayUtils.getCount(lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId, true)
        if markerCount ~= 2 then return end

        local conIds = {}
        for conId, _ in pairs(lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId) do
            conIds[#conIds+1] = conId
        end
        -- sort the ids first placed first, the sequence matters here because the second marker commands the orientation
        if conIds[1] == lastWaypointData.newWaypointId then
            conIds[1], conIds[2] = conIds[2], conIds[1]
        end
        -- set a place to build the fence con
        local marker1Pos = _utils.getConPosition(conIds[1])
        local marker2Pos = _utils.getConPosition(conIds[2])
        if marker1Pos == nil or marker2Pos == nil then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find the fence waypoint positions')
            return
        end

        local edge1Id = lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId[conIds[1]]
        local edge2Id = lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId[conIds[2]]
        if not(edgeUtils.isValidAndExistingId(edge1Id)) or not(edgeUtils.isValidAndExistingId(edge2Id)) then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find the fence waypoint edges')
            return
        end

        local fenceWaypointMidTransf = transfUtils.position2Transf({
            (marker1Pos[1] + marker2Pos[1]) * 0.5,
            (marker1Pos[2] + marker2Pos[2]) * 0.5,
            (marker1Pos[3] + marker2Pos[3]) * 0.5,
        })

        local baseEdge1 = api.engine.getComponent(edge1Id, api.type.ComponentType.BASE_EDGE)
        local baseEdge2 = api.engine.getComponent(edge2Id, api.type.ComponentType.BASE_EDGE)
        if not(baseEdge1) or not(baseEdge2) or not(baseEdge1.objects) or not(baseEdge2.objects) then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find edge data')
            return
        end

        local edge2Node0 = api.engine.getComponent(baseEdge2.node0, api.type.ComponentType.BASE_NODE)
        local edge2Node1 = api.engine.getComponent(baseEdge2.node1, api.type.ComponentType.BASE_NODE)
        if not(edge2Node0) or not(edge2Node0.position) or not(edge2Node1) or not(edge2Node1.position) then
            logger.errorOut('_handleValidFenceWaypointBuilt cannot find node data')
            return
        end
        -- convert userdata.XYZ to table.123
        local edge2Node0Pos = transfUtils.xYZ2OneTwoThree(edge2Node0.position)
        local edge2Node1Pos = transfUtils.xYZ2OneTwoThree(edge2Node1.position)

        local eventArgs = {
            edge1Id = edge1Id,
            edge2Id = edge2Id,
            edge2Node0Pos = edge2Node0Pos,
            edge2Node1Pos = edge2Node1Pos,
            fenceMarkerCon1Id = conIds[1],
            fenceMarkerCon2Id = conIds[2],
            -- fenceWaypoint1Id = conIds[1],
            -- fenceWaypoint2Id = conIds[2],
            fenceWaypointMidTransf = fenceWaypointMidTransf,
            isPrecise = lastWaypointData.isPrecise,
            isWaypoint2ArrowAgainstTrackDirection = lastWaypointData.isWaypointArrowAgainstTrackDirection,
        }

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.FENCE_WAYPOINTS_BUILT,
            eventArgs
        ))
    end,
}
_guiActions.validateFenceWaypointBuilt = function(targetWaypointModelId, newWaypointId, waypointEdgeId, isWaypointArrowAgainstTrackDirection, trackTypeIndex)
    logger.infoOut('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
    if not(edgeUtils.isValidAndExistingId(newWaypointId)) then logger.errorOut('newWaypointId not valid') return false end
    if not(edgeUtils.isValidAndExistingId(waypointEdgeId)) then logger.errorOut('waypointEdgeId not valid') return false end
    if not(edgeUtils.isValidId(trackTypeIndex)) then logger.errorOut('trackTypeIndex not valid') return false end

    logger.infoOut('waypointEdgeId =', waypointEdgeId)
    local lastBuiltBaseEdge = api.engine.getComponent(waypointEdgeId, api.type.ComponentType.BASE_EDGE)
    if not(lastBuiltBaseEdge) then return false end

    local similarObjectIdsInAnyEdges = stationHelpers.getAllEdgeObjectsWithModelId(targetWaypointModelId)
    logger.infoOut('similarObjectsIdsInAnyEdges =', similarObjectIdsInAnyEdges)
    -- forbid building more then two waypoints of the same type
    local bulldozeAllWaypointsFunc = function()
        logger.infoOut('bulldozeAllWaypointsFunc starting')
        _guiActions.bulldozeWaypoints(similarObjectIdsInAnyEdges)
    end
    if #similarObjectIdsInAnyEdges > 2 then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointAlreadyBuilt, newWaypointId, similarObjectIdsInAnyEdges, bulldozeAllWaypointsFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = newWaypointId
            }
        ))
        return false
    end

    if #similarObjectIdsInAnyEdges < 2 then
        -- not ready yet
        return false
    end

    local newWaypointPosition = edgeUtils.getObjectPosition(newWaypointId)
    if not(newWaypointPosition) then
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = newWaypointId
            }
        ))
        return false
    end

    local twinWaypointId = (newWaypointId == similarObjectIdsInAnyEdges[1])
        and similarObjectIdsInAnyEdges[2]
        or similarObjectIdsInAnyEdges[1]
    if not(edgeUtils.isValidAndExistingId(twinWaypointId)) then logger.errorOut('twinWaypointId not valid') return false end

    local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)
    -- no twin or no useful twin
    if not(twinWaypointPosition) then
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = twinWaypointId
            }
        ))
        return false
    end

    local waypointDistance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition)
    -- forbid building waypoints too close
    if type(waypointDistance) ~= 'number' or waypointDistance < constants.minFenceWaypointDistance then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooClose, newWaypointId, similarObjectIdsInAnyEdges, bulldozeAllWaypointsFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = newWaypointId
            }
        ))
        return false
    -- forbid building waypoints too far apart, which would make the fence too long
    elseif waypointDistance > constants.maxFenceWaypointDistance then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooFar, newWaypointId, similarObjectIdsInAnyEdges, bulldozeAllWaypointsFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = newWaypointId
            }
        ))
        return false
    end

    local contiguousTrackEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
        api.engine.system.streetSystem.getEdgeForEdgeObject(newWaypointId),
        api.engine.system.streetSystem.getEdgeForEdgeObject(twinWaypointId),
        constants.maxFenceWaypointDistance,
        true,
        logger.isExtendedLog()
    )
    logger.infoOut('contiguous track edge ids =', contiguousTrackEdgeIds)
    -- make sure the waypoints are on connected tracks
    if #contiguousTrackEdgeIds < 1 then
        guiHelpers.showWarningWithGoto(_guiTexts.markersNotConnected, newWaypointId, similarObjectIdsInAnyEdges, bulldozeAllWaypointsFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            constants.eventData.lolloFreestyleTrainStation.eventId,
            constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
            {
                waypointId = newWaypointId,
            }
        ))
        return false
    end

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
                guiHelpers.showWarningWithGoto(_guiTexts.differentPlatformWidths, newWaypointId, similarObjectIdsInAnyEdges, bulldozeAllWaypointsFunc)
                api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                    string.sub(debug.getinfo(1, 'S').source, 1),
                    constants.eventData.lolloFreestyleTrainStation.eventId,
                    constants.eventData.lolloFreestyleTrainStation.eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                    {
                        waypointId = newWaypointId,
                    }
                ))
                return false
            end
        end
    end

    -- validation fine, return data
    return {
        isPrecise = (targetWaypointModelId == _guiFenceWaypointPreciseModelId),
        isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        newWaypointId = newWaypointId,
        twinWaypointId = twinWaypointId
    }
end
_guiActions.validateFenceMarkerBuilt = function(newConId)
    -- first of all, we check if we have plopped a marker of ours
    -- we must not interfere with other mods
    local fileName = _utils.getConFileName(newConId)
    if fileName ~= constants.autoBaseWallMarkerConFileName and fileName ~= constants.autoBaseWallMarkerPreciseConFileName then return false end

    local newEdgeId = _utils.getNearestEdgeToCon(newConId)
    logger.infoOut('validateFenceMarkerBuilt starting, fence marker edgeId = ', newEdgeId, ', conId = ', newConId)
    if not(edgeUtils.isValidAndExistingId(newEdgeId)) then
        guiHelpers.showWarningWithGoto(_guiTexts.invalidEdge, newConId)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    end

    local newConPosition = _utils.getConPosition(newConId)
    logger.infoOut('fence marker position =', newConPosition)
    if not(type(newConPosition) == 'table') then
        guiHelpers.showWarningWithGoto(_guiTexts.invalidPosition, newConId)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    end

    -- read all similar marker constructions
    -- api.engine.forEachEntityWithComponent(function(entityId) print(entityId) end, api.type.ComponentType.CONSTRUCTION)
    -- local similarConIds = {}
    -- api.engine.forEachEntityWithComponent(
    --     function(entityId)
    --         print(entityId)
    --         if _utils.getConFileName(entityId) == fileName
    --         then
    --             similarConIds[#similarConIds+1] = entityId
    --         end
    --     end,
    --     api.type.ComponentType.CONSTRUCTION
    -- )
    -- this is the old api but it is much faster
    local similarConIds = game.interface.getEntities(
        {
            pos = {0, 0, 0},
            radius = 99999
        },
        {
            fileName = fileName,
            includeData = false,
            type = 'CONSTRUCTION'
        }
    )
    logger.infoOut('similarConIds =', similarConIds)
    local bulldozeAllMarkersFunc = function() _guiActions.bulldozeConstructions(similarConIds) end
    local otherAutoFenceMarkerEdgeIds_indexedByConId = {}
    for _, oldConId in pairs(similarConIds) do
        logger.infoOut('looping over oldConId = ', oldConId)
        if oldConId ~= newConId and edgeUtils.isValidAndExistingId(oldConId) then
            logger.infoOut('loop TWO')
            local oldEdgeId = _utils.getNearestEdgeToCon(oldConId)
            logger.infoOut('loop got oldEdgeId = ', oldEdgeId)
            if edgeUtils.isValidAndExistingId(oldEdgeId) then
                otherAutoFenceMarkerEdgeIds_indexedByConId[oldConId] = oldEdgeId
            end
        end
    end
    local otherConIds = {}
    for conId, _ in pairs(otherAutoFenceMarkerEdgeIds_indexedByConId) do
        otherConIds[#otherConIds+1] = conId
    end
    logger.infoOut('autoFenceMarkerEdgeIds_indexedByConId after =', otherAutoFenceMarkerEdgeIds_indexedByConId)

    -- forbid building more then two markers of the same type
    local markerCount = arrayUtils.getCount(otherAutoFenceMarkerEdgeIds_indexedByConId, true)
    logger.infoOut('markerCount = ', markerCount)
    if markerCount > 1 then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointAlreadyBuilt, newConId, otherConIds, bulldozeAllMarkersFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    end

    if markerCount ~= 1 then
        -- not ready yet
        return false
    end

    -- now we check the twin
    local twinConId = nil
    for oldConId, oldEdgeId in pairs(otherAutoFenceMarkerEdgeIds_indexedByConId) do
        if oldConId ~= newConId then twinConId = oldConId end
    end
    local twinConPosition = _utils.getConPosition(twinConId)
    local twinEdgeId = otherAutoFenceMarkerEdgeIds_indexedByConId[twinConId]
    if logger.isExtendedLog() then
        logger.infoOut('newConId, twinConId =', newConId, ',', twinConId)
        logger.infoOut('newEdgeId, twinEdgeId =', newEdgeId, ',', twinEdgeId)
        logger.infoOut('fence marker position =', newConPosition)
        logger.infoOut('twin marker position =', twinConPosition)
    end
    -- no twin or no useful twin
    if not(twinConPosition) or not(edgeUtils.isValidAndExistingId(twinConId)) or not(edgeUtils.isValidAndExistingId(twinEdgeId)) then
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = twinConId
            }
        ))
        return false
    end

    local markerDistance = transfUtils.getPositionsDistance(newConPosition, twinConPosition)
    -- forbid building markers too close
    if type(markerDistance) ~= 'number' or markerDistance < constants.minFenceWaypointDistance then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooClose, newConId, {}, bulldozeAllMarkersFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    -- forbid building markers too far apart, which would make the fence too long
    elseif markerDistance > constants.maxFenceWaypointDistance then
        guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooFar, newConId, otherConIds, bulldozeAllMarkersFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    end

    local contiguousTrackEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
        newEdgeId,
        twinEdgeId,
        constants.maxFenceWaypointDistance,
        true,
        logger.isExtendedLog()
    )
    logger.infoOut('contiguous track edge ids =', contiguousTrackEdgeIds)
    -- make sure the waypoints are on connected tracks
    if #contiguousTrackEdgeIds < 1 then
        guiHelpers.showWarningWithGoto(_guiTexts.markersNotConnected, newConId, otherConIds, bulldozeAllMarkersFunc)
        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            _eventNames.BULLDOZE_CON_REQUESTED,
            {
                conId = newConId
            }
        ))
        return false
    end

    -- validation fine, return data
    local newConTransf = _utils.getConTransf(newConId)
    local vec000Transformed = transfUtils.getVec123Transformed({0, 0, 0}, newConTransf)
    local vec100Transformed = transfUtils.getVec123Transformed({1, 0, 0}, newConTransf)
    local baseEdge = api.engine.getComponent(newEdgeId, api.type.ComponentType.BASE_EDGE)
    local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
    local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
    local distance000 = transfUtils.getPositionsDistance(node0.position, vec000Transformed)
    local distance100 = transfUtils.getPositionsDistance(node0.position, vec100Transformed)
    local isWaypointArrowAgainstTrackDirection = (distance100 < distance000)
    if logger.isExtendedLog() then
        logger.infoOut(
            'marker con transf =', newConTransf,
            'vector 000 transformed =', vec000Transformed,
            'vector 100 transformed =', vec100Transformed,
            'node0 position =', node0.position,
            'node1 position =', node1.position,
            'isWaypointArrowAgainstTrackDirection = ', isWaypointArrowAgainstTrackDirection
        )
    end

    otherAutoFenceMarkerEdgeIds_indexedByConId[newConId] = newEdgeId
    return {
        autoFenceMarkerEdgeIds_indexedByConId = otherAutoFenceMarkerEdgeIds_indexedByConId,
        isPrecise = (fileName == constants.autoBaseWallMarkerPreciseConFileName),
        isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        newWaypointId = newConId,
        twinWaypointId = twinConId
    }
end

function data()
    return {
        guiInit = function()
            -- read variables
            _guiFenceWaypointModelId = api.res.modelRep.find(constants.baseWallWaypointModelId)
            _guiFenceWaypointPreciseModelId = api.res.modelRep.find(constants.baseWallWaypointPreciseModelId)
            -- read texts
            _guiTexts.differentPlatformWidths = _('DifferentPlatformWidths')
            _guiTexts.invalidEdge = _('InvalidEdge')
            _guiTexts.invalidPosition = _('InvalidPosition')
            _guiTexts.markersNotConnected = _('MarkersNotConnected')
            _guiTexts.waypointAlreadyBuilt = _('WaypointAlreadyBuilt')
            _guiTexts.waypointsCrossCrossing = _('WaypointsCrossCrossing')
            _guiTexts.waypointsCrossSignal = _('WaypointsCrossSignal')
            _guiTexts.waypointsCrossStation = _('WaypointsCrossStation')
            _guiTexts.waypointsTooClose = _('WaypointsTooClose')
            _guiTexts.waypointsTooFar = _('WaypointsTooFar')
            _guiTexts.waypointsNotConnected = _('WaypointsNotConnected')
        end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end

            xpcall(
                function()
                    logger.infoOut('lollo_auto_fence.handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
                    if name == _eventNames.FENCE_WAYPOINTS_BUILT then
                        -- fence waypoints built, eventArgs = {
                        --     edge1Id = edge1Id, -- the edge where the first marker was placed
                        --     edge2Id = edge2Id, -- the edge where the second marker was placed
                        --     edge2Node0Pos = edge2Node0Pos,
                        --     edge2Node1Pos = edge2Node1Pos,
                        --     fenceMarkerCon1Id -- the first marker placed (if using marker constructions)
                        --     fenceMarkerCon2Id -- the second marker placed (if using marker constructions)
                        --     fenceWaypoint1Id = fenceWaypointIds[1], -- the first waypoint placed (if using waypoints)
                        --     fenceWaypoint2Id = fenceWaypointIds[2], -- the second waypoint placed (if using waypoints)
                        --     fenceWaypointMidTransf = fenceWaypointMidTransf,
                        --     isPrecise = true, (if using precise marker constructions or waypoints)
                        --     isWaypoint2ArrowAgainstTrackDirection = true
                        -- }
                        logger.infoOut('args =', args)
                        local trackEdgeIdsBetweenEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
                            args.edge1Id, args.edge2Id, constants.maxFenceWaypointDistance, true, logger.isExtendedLog()
                        )
                        if #trackEdgeIdsBetweenEdgeIds > 0 then
                            local trackEdgeList_Ordered = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenEdgeIds, true, false, true, true)

                            if comparisonUtils.is123sSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[2][1],
                                args.edge2Node1Pos
                            )
                            then
                                logger.infoOut('isWaypoint2ArrowAgainstTrackDirection does not need reversing')
                            elseif comparisonUtils.is123sSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[1][1],
                                args.edge2Node1Pos
                            ) then
                                logger.infoOut('reversing isWaypoint2ArrowAgainstTrackDirection')
                                args.isWaypoint2ArrowAgainstTrackDirection = not(args.isWaypoint2ArrowAgainstTrackDirection)
                            else
                                logger.warningOut(
                                    'cannot find the right direction to build my fence',
                                    'last track\'s start position =', trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[1][1],
                                    'last track\'s end position =', trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[2][1],
                                    'second waypoint edge\'s node0 pos =', args.edge2Node0Pos,
                                    'second waypoint edge\'s node1 pos =', args.edge2Node1Pos
                                )
                            end

                            if args.isWaypoint2ArrowAgainstTrackDirection then
                                logger.infoOut('reversing trackEdgeList')
                                trackEdgeList_Ordered = stationHelpers.reversePosTanX2ListInPlace(trackEdgeList_Ordered)
                                -- yShift = -yShift -- NO!
                            end
                            logger.infoOut('trackEdgeList =', trackEdgeList_Ordered)
                            local trackEdgeListFine = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(
                                trackEdgeList_Ordered,
                                1,
                                false,
                                false,
                                true
                            )

                            if #trackEdgeListFine > 0 then
                                -- precise markers: cull the bits on the marker edges but outside the markers
                                if args.isPrecise then
                                    logger.infoOut('isPrecise, about to cull the bits beyond the markers')
                                    local maxII = #trackEdgeListFine
                                    local endPos1, endPos2
                                    if args.fenceMarkerCon1Id and args.fenceMarkerCon2Id then
                                        endPos1 = _utils.getConPosition(args.fenceMarkerCon1Id)
                                        endPos2 = _utils.getConPosition(args.fenceMarkerCon2Id)
                                    elseif args.fenceWaypoint1Id and args.fenceWaypoint2Id then
                                        endPos1 = edgeUtils.getObjectPosition(args.fenceWaypoint1Id)
                                        endPos2 = edgeUtils.getObjectPosition(args.fenceWaypoint2Id)
                                    end
                                    if endPos1 and endPos2 then
                                        local distance11 = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[1].posTanX2[1][1], endPos1)
                                        local distance12 = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[maxII].posTanX2[2][1], endPos2)
                                        local distance21 = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[maxII].posTanX2[2][1], endPos1)
                                        local distance22 = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[1].posTanX2[1][1], endPos2)
                                        if type(distance11) == 'number' and type(distance12) == 'number' and type(distance21) == 'number' and type(distance22) == 'number' then
                                            -- I have no flags that avoid this estimator
                                            if (distance11 + distance12) > (distance21 + distance22) then
                                                endPos1, endPos2 = endPos2, endPos1
                                            end
                                            if (logger.isExtendedLog()) then
                                                logger.infoOut(
                                                    'endPos1 =', endPos1,
                                                    'endPos2 =', endPos2,
                                                    'trackEdgeListFine[1].posTanX2[1][1] = ', trackEdgeListFine[1].posTanX2[1][1],
                                                    'trackEdgeListFine[maxII].posTanX2[2][1] = ', trackEdgeListFine[maxII].posTanX2[2][1],
                                                    'maxII = ', maxII
                                                )
                                            end
                                            local minDistance = 9999
                                            local nearestII = 0
                                            for ii = 1, maxII, 1 do
                                                local currentDistance = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[ii].posTanX2[1][1], endPos1)
                                                if type(currentDistance) == 'number' and currentDistance < minDistance then
                                                    minDistance = currentDistance
                                                    nearestII = ii
                                                else
                                                    break
                                                end
                                            end
                                            logger.infoOut('maxII = ', maxII, 'nearestII = ', nearestII)
                                            for ii = 1, nearestII - 1, 1 do
                                                table.remove(trackEdgeListFine, 1)
                                            end

                                            maxII = #trackEdgeListFine
                                            minDistance = 9999
                                            nearestII = maxII
                                            for ii = maxII, 1, -1 do
                                                local currentDistance = transfUtils.getPositionsDistance_onlyXY(trackEdgeListFine[ii].posTanX2[2][1], endPos2)
                                                if type(currentDistance) == 'number' and currentDistance < minDistance then
                                                    minDistance = currentDistance
                                                    nearestII = ii
                                                else
                                                    break
                                                end
                                            end
                                            logger.infoOut('maxII = ', maxII, 'nearestII = ', nearestII)
                                            for ii = nearestII + 1, maxII, 1 do
                                                table.remove(trackEdgeListFine, nearestII + 1)
                                            end
                                        end
                                    end
                                end

                                local trackEdgeListFine_yFlipped = stationHelpers.getReversedPosTanX2List(trackEdgeListFine)

                                local yShift_main = trackEdgeList_Ordered[1].width * 0.5
                                local getTransfs = function(tel)
                                    return arrayUtils.map(
                                        tel,
                                        function(te)
                                            local ps_main, xRatio_main, yRatio_main = transfUtils.getParallelSideways(te.posTanX2, yShift_main)
                                            return {
                                                groundBridgeTunnel_012 = te.type,
                                                hasLevelCrossing = te.hasLevelCrossing,
                                                posTanX2_main = ps_main,
                                                xRatio_main = xRatio_main,
                                                yRatio_main = yRatio_main,
                                            }
                                        end
                                    )
                                end
                                local transfs = getTransfs(trackEdgeListFine)
                                local transfs_yFlipped = getTransfs(trackEdgeListFine_yFlipped)
                                logger.infoOut('transfs, first 3 records =', transfs[1], transfs[2], transfs[3])
                                logger.infoOut('transfs_yFlipped, first 3 records =', transfs_yFlipped[1], transfs_yFlipped[2], transfs_yFlipped[3])
                                if #transfs > 0 then
                                    _actions.buildFence(
                                        transfs,
                                        transfs_yFlipped,
                                        yShift_main,
                                        args.fenceWaypointMidTransf,
                                        args.isWaypoint2ArrowAgainstTrackDirection
                                    )
                                end
                            end
                        end
                        _actions.replaceEdgeWithSameRemovingObject(args.fenceWaypoint1Id)
                        _actions.replaceEdgeWithSameRemovingObject(args.fenceWaypoint2Id)
                        _actions.bulldozeConstruction(args.fenceMarkerCon1Id)
                        _actions.bulldozeConstruction(args.fenceMarkerCon2Id)
                    elseif name == _eventNames.CON_PARAMS_UPDATED then
                        _actions.updateConstruction(args.conId, args.paramKey, args.newParamValueIndexBase0)
                    elseif name == _eventNames.BULLDOZE_CON_REQUESTED then
                        _actions.bulldozeConstruction(args.conId)
                    end
                end,
                logger.errorOut
            )
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            if (name == 'builder.apply' and id == 'streetTerminalBuilder') then -- for performance
                xpcall(
                    function()
                        -- waypoint, traffic light, my own waypoints built
                        if args and args.proposal and args.proposal.proposal
                        and args.proposal.proposal.edgeObjectsToAdd
                        and args.proposal.proposal.edgeObjectsToAdd[1]
                        and args.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                        then
                            -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                            local newModelId = args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId
                            if newModelId == _guiFenceWaypointModelId or newModelId == _guiFenceWaypointPreciseModelId then
                                logger.infoOut('args.proposal.proposal.edgeObjectsToAdd[1] =', args.proposal.proposal.edgeObjectsToAdd[1])
                                local waypointData = _guiActions.validateFenceWaypointBuilt(
                                    newModelId,
                                    args.proposal.proposal.edgeObjectsToAdd[1].resultEntity,
                                    args.proposal.proposal.edgeObjectsToAdd[1].segmentEntity,
                                    args.proposal.proposal.edgeObjectsToAdd[1].left or false,
                                    args.proposal.proposal.addedSegments[1].trackEdge.trackType
                                )
                                logger.infoOut('baseWallWaypointData =', waypointData)
                                if not(waypointData) then return end

                                _guiActions.handleValidFenceWaypointBuilt(waypointData)
                            end
                        end
                    end,
                    logger.errorOut
                )
            elseif (name == 'builder.apply' and id == 'constructionBuilder') then
                if not args or not args.result or not args.result[1] then return end

                local conId = args.result[1]

                logger.infoOut('some construction was built')
                local waypointData = _guiActions.validateFenceMarkerBuilt(conId)
                logger.infoOut('fenceWaypointData =', waypointData)
                if not(waypointData) then return end

                _guiActions.handleValidFenceMarkerBuilt(waypointData)
            elseif (name == 'select' and id == 'mainView') then
                -- select happens after idAdded, which looks like:
                -- id =	temp.view.entity_28693	name =	idAdded
                -- id =	temp.view.entity_26372	name =	idAdded
                xpcall(
                    function()
                        logger.infoOut('guiHandleEvent caught id =', id, 'name =', name, 'args =', args)
                        local conId = args
                        if not(edgeUtils.isValidAndExistingId(conId)) then return end

                        local con = _guiActions.getCon(conId)
                        if not(con) or con.fileName ~= constants.autoBaseWallConFileName then return end

                        logger.infoOut('selected one of my fences, it has conId =', conId, 'and con.fileName =', con.fileName)
                        guiHelpers.addEntityConfigToWindow(
                            conId,
                            _guiActions.handleParamValueChanged,
                            modelHelper.getChangeableParamsMetadata(),
                            con.params,
                            _guiActions.handleBulldozeClicked -- unused
                        )
                        -- not required but it might prevent a crash with the conMover: no it does not
                        -- local paramsMetadata = modelHelper.getChangeableParamsMetadata()
                        -- local changeableParams = {}
                        -- for _, paramMetadata in pairs(paramsMetadata) do
                        --     changeableParams[#changeableParams+1] = arrayUtils.cloneDeepOmittingFields(
                        --         con.params[paramMetadata.key]
                        --     )
                        -- end
                        -- guiHelpers.addEntityConfigToWindow(
                        --     conId,
                        --     _guiActions.handleParamValueChanged,
                        --     paramsMetadata,
                        --     changeableParams,
                        --     _guiActions.handleBulldozeClicked
                        -- )
                    end,
                    logger.errorOut
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
