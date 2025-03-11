local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local comparisonUtils = require('lollo_freestyle_train_station.comparisonUtils')
local guiHelpers = require('lollo_fence.guiHelpers')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local modelHelper = require('lollo_fence.modelHelper')
local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

-- LOLLO NOTE to avoid collisions when combining several parallel tracks,
-- cleanupStreetGraph is false everywhere.

local _eventId = _constants.eventData.autoFence.eventId
local _eventNames = _constants.eventData.autoFence.eventNames
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
    getNearestEdgeToCon = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return nil end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if not(con) or not(con.transf) then return nil end

        local conTransfLua = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
        local nearestEdgeId = edgeUtils.track.getNearestEdgeIdStrict(
            conTransfLua,
            conTransfLua[15] + _constants.splitterZShift - _constants.splitterZToleranceM,
            conTransfLua[15] + _constants.splitterZShift + _constants.splitterZToleranceM,
            logger
        )

        return nearestEdgeId
    end
}
local _actions = {
    buildFence = function(trackRecords, yShift, conTransf, isWaypoint2ArrowAgainstTrackDirection)
        logger.print('_buildFence starting, args =')
        if not(trackRecords) or #trackRecords == 0 then return end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = _constants.autoFenceConFileName

        local _mainTransf = arrayUtils.cloneDeepOmittingFields(conTransf)
        local _inverseMainTransf = transfUtils.getInverseTransf(_mainTransf)

        local inverseTransfs = arrayUtils.map(
            trackRecords,
            function(record)
                -- logger.print('record =') logger.debugPrint(record)
                return {
                    groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                    hasLevelCrossing = record.hasLevelCrossing,
                    posTanX2_main = transfUtils.getPosTanX2Transformed(record.posTanX2_main, _inverseMainTransf),
                    -- posTanX2_wallBehind = transfUtils.getPosTanX2Transformed(record.posTanX2_wallBehind, _inverseMainTransf),
                    xRatio_main = record.xRatio_main,
                    yRatio_main = record.yRatio_main,
                    xRatio_wallBehind = record.xRatio_wallBehind,
                    yRatio_wallBehind = record.yRatio_wallBehind,
                }
            end
        )
--[[
        -- early releases, now obsolete
        local newTransfs = arrayUtils.map(
            inverseTransfs,
            function(record)
                local skew = record.posTanX2_main[2][1][3] - record.posTanX2_main[1][1][3]
                return transfUtils.getTransf_XSkewedOnZ(
                    transfUtils.getTransf_XScaled(
                        moduleHelpers.getPlatformObjectTransf_AlwaysVertical(record.posTanX2_main),
                        record.xRatio_main
                    ),
                    skew
                )
            end
        )
]]
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
        local newTransfs_ground = arrayUtils.map(
            inverseTransfs,
            function(record)
                local skew = record.posTanX2_main[2][1][3] - record.posTanX2_main[1][1][3]
                return {
                    groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                    hasLevelCrossing = record.hasLevelCrossing,
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
        local newTransfs_wallBehind = arrayUtils.map(
            inverseTransfs,
            function(record)
                local skew = record.posTanX2_main[2][1][3] - record.posTanX2_main[1][1][3]
                return {
                    groundBridgeTunnel_012 = record.groundBridgeTunnel_012,
                    hasLevelCrossing = record.hasLevelCrossing,
                    transf = transfUtils.getTransf_XSkewedOnZ(
                        transfUtils.getTransf_XScaled(
                            moduleHelpers.getPlatformObjectTransf_AlwaysVertical(record.posTanX2_main),
                            math.max(record.xRatio_wallBehind, record.xRatio_main)
                        ),
                        skew
                    ),
                }
            end
        )

        -- logger.print('first 3 transfs =')
        -- logger.debugPrint(newTransfs[1])
        -- logger.debugPrint(newTransfs[2])
        -- logger.debugPrint(newTransfs[3])
        logger.print('first 3 newTransfs_ground =')
        logger.debugPrint(newTransfs_ground[1])
        logger.debugPrint(newTransfs_ground[2])
        logger.debugPrint(newTransfs_ground[3])
        logger.print('first 3 transfs_wallBehind =')
        logger.debugPrint(newTransfs_wallBehind[1])
        logger.debugPrint(newTransfs_wallBehind[2])
        logger.debugPrint(newTransfs_wallBehind[3])

        local newParams = {
            inverseMainTransf = _inverseMainTransf,
            mainTransf = _mainTransf,
            seed = math.abs(math.ceil(conTransf[13] * 1000)),
            -- transfs = newTransfs, -- early releases, now obsolete
            transfs_ground = newTransfs_ground,
            transfs_wallBehind = newTransfs_wallBehind,
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
--[[
    bulldozeCon = function(conId)
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
                logger.print('_bulldozeCon success = ', success)
                -- logger.print('_bulldozeCon result = ') logger.debugPrint(result)
            end
        )
    end,
]]
    bulldozeConstruction = function(conId)
        if not(edgeUtils.isValidAndExistingId(conId)) then return end

        -- local oldCon = api.engine.getComponent(constructionId, api.type.ComponentType.CONSTRUCTION)
        -- logger.print('oldCon =') logger.debugPrint(oldCon)
        -- if not(oldCon) or not(oldCon.params) then return end

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
                logger.print('LOLLO _bulldozeConstruction success = ', success)
                -- logger.print('LOLLO _bulldozeConstruction result = ') logger.debugPrint(result)
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
        if oldCon == nil or oldCon.fileName ~= _constants.autoFenceConFileName then
            logger.print('_updateConstruction cannot get the con, or it is not one of mine')
            return
        end

        local newCon = api.type.SimpleProposal.ConstructionEntity.new()
        newCon.fileName = oldCon.fileName

        local newParams = arrayUtils.cloneDeepOmittingFields(oldCon.params, nil, true)
        newParams[paramKey] = newParamValueIndexBase0
        newParams.seed = newParams.seed + 1
        newCon.params = newParams
        -- logger.print('oldCon.params =') logger.debugPrint(oldCon.params)
        -- logger.print('newCon.params =') logger.debugPrint(newCon.params)
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
        if con == nil or con.fileName ~= _constants.autoFenceConFileName then
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
    handleBulldozeClicked = function(conId) -- unused
        logger.print('_handleBulldozeClicked starting for conId =', conId or 'NIL')
        if not(edgeUtils.isValidAndExistingId(conId)) then
            logger.warn('_handleBulldozeClicked got no con or no valid con')
            return
        end

        local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        if con == nil or con.fileName ~= _constants.autoFenceConFileName then
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
        --     isPrecise = true,
        --     isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        --     newWaypointId = newWaypointId,
        --     twinWaypointId = twinWaypointId
        -- }
        logger.print('_handleValidFenceWaypointBuilt starting, lastWaypointData =')
        logger.debugPrint(lastWaypointData)
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

        local edge2Node0 = api.engine.getComponent(baseEdge2.node0, api.type.ComponentType.BASE_NODE)
        local edge2Node1 = api.engine.getComponent(baseEdge2.node1, api.type.ComponentType.BASE_NODE)
        if not(edge2Node0) or not(edge2Node0.position) or not(edge2Node1) or not(edge2Node1.position) then
            logger.err('_handleValidFenceWaypointBuilt cannot find node data')
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
        --     logger.err('_handleValidFenceWaypointBuilt cannot find edge object sides')
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
        -- local lastWaypointData = {
        --     autoFenceMarkerEdgeIds_indexedByConId
        --     isPrecise = true
        --     isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
        --     newWaypointId = newWaypointId,
        --     twinWaypointId = twinWaypointId
        -- }
        logger.print('_handleValidFenceMarkerBuilt starting, lastWaypointData =')
        logger.debugPrint(lastWaypointData)
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
            logger.err('_handleValidFenceWaypointBuilt cannot find the fence waypoint positions')
            return
        end

        local edge1Id = lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId[conIds[1]]
        local edge2Id = lastWaypointData.autoFenceMarkerEdgeIds_indexedByConId[conIds[2]]
        if not(edgeUtils.isValidAndExistingId(edge1Id)) or not(edgeUtils.isValidAndExistingId(edge2Id)) then
            logger.err('_handleValidFenceWaypointBuilt cannot find the fence waypoint edges')
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
            logger.err('_handleValidFenceWaypointBuilt cannot find edge data')
            return
        end

        local edge2Node0 = api.engine.getComponent(baseEdge2.node0, api.type.ComponentType.BASE_NODE)
        local edge2Node1 = api.engine.getComponent(baseEdge2.node1, api.type.ComponentType.BASE_NODE)
        if not(edge2Node0) or not(edge2Node0.position) or not(edge2Node1) or not(edge2Node1.position) then
            logger.err('_handleValidFenceWaypointBuilt cannot find node data')
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
    validateFenceWaypointBuilt = function(targetWaypointModelId, newWaypointId, waypointEdgeId, isWaypointArrowAgainstTrackDirection, trackTypeIndex)
        logger.print('LOLLO waypoint with target modelId', targetWaypointModelId, 'built, validation started!')
        if not(edgeUtils.isValidAndExistingId(newWaypointId)) then logger.err('newWaypointId not valid') return false end
        if not(edgeUtils.isValidAndExistingId(waypointEdgeId)) then logger.err('waypointEdgeId not valid') return false end
        if not(edgeUtils.isValidId(trackTypeIndex)) then logger.err('trackTypeIndex not valid') return false end

        logger.print('waypointEdgeId =') logger.debugPrint(waypointEdgeId)
        local lastBuiltBaseEdge = api.engine.getComponent(waypointEdgeId, api.type.ComponentType.BASE_EDGE)
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
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    waypointId = newWaypointId
                }
            ))
            return false
        end

        local twinWaypointId = (newWaypointId == similarObjectIdsInAnyEdges[1])
            and similarObjectIdsInAnyEdges[2]
            or similarObjectIdsInAnyEdges[1]
        if not(edgeUtils.isValidAndExistingId(twinWaypointId)) then logger.err('twinWaypointId not valid') return false end

        local twinWaypointPosition = edgeUtils.getObjectPosition(twinWaypointId)
        -- no twin or no useful twin
        if not(twinWaypointPosition) then
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    waypointId = twinWaypointId
                }
            ))
            return false
        end

        local waypointDistance = transfUtils.getPositionsDistance(newWaypointPosition, twinWaypointPosition)
        -- forbid building waypoints too close
        if type(waypointDistance) ~= 'number' or waypointDistance < _constants.minFenceWaypointDistance then
            guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooClose, newWaypointId)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    waypointId = newWaypointId
                }
            ))
            return false
        -- forbid building waypoints too far apart, which would make the fence too long
        elseif waypointDistance > _constants.maxFenceWaypointDistance then
            guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooFar, newWaypointId, similarObjectIdsInAnyEdges)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                {
                    waypointId = newWaypointId
                }
            ))
            return false
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
        local nodesBetweenWps = edgeUtils.track.getNodeIdsBetweenEdgeIds_optionalEnds(contiguousEdgeIds, false)
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
    end,
    validateFenceMarkerBuilt = function(newConId)
        -- first of all, we check if we have plopped a marker of ours
        -- we must not interfere with other mods
        local fileName = _utils.getConFileName(newConId)
        if fileName ~= _constants.autoFenceMarkerConFileName and fileName ~= _constants.autoFenceMarkerPreciseConFileName then return false end

        local newEdgeId = _utils.getNearestEdgeToCon(newConId)
        logger.print('validateFenceMarkerBuilt starting, fence marker edgeId = ' .. tostring(newEdgeId) .. ', conId = ' .. tostring(newConId))
        if not(edgeUtils.isValidAndExistingId(newEdgeId)) then
            guiHelpers.showWarningWithGoto(_guiTexts.invalidEdge, newConId)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = newConId
                }
            ))
            return false
        end

        local newConPosition = _utils.getConPosition(newConId)
        logger.print('fence marker position =') logger.debugPrint(newConPosition)
        if not(type(newConPosition) == 'table') then
            guiHelpers.showWarningWithGoto(_guiTexts.invalidPosition, newConId)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
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
                pos = transfUtils.getVec123Transformed({0, 0, 0}, _constants.idTransf),
                radius = 99999
            },
            {
                fileName = fileName,
                includeData = false,
                type = 'CONSTRUCTION'
            }
        )
        logger.print('similarConIds =') logger.debugPrint(similarConIds)
        local autoFenceMarkerEdgeIds_indexedByConId = {}
        for _, oldConId in pairs(similarConIds) do
            logger.print('looping over oldConId = ' .. tostring(oldConId))
            if oldConId ~= newConId and edgeUtils.isValidAndExistingId(oldConId) then
                logger.print('loop TWO')
                local oldEdgeId = _utils.getNearestEdgeToCon(oldConId)
                logger.print('loop got oldEdgeId = ' .. tostring(oldEdgeId))
                if edgeUtils.isValidAndExistingId(oldEdgeId) then
                    autoFenceMarkerEdgeIds_indexedByConId[oldConId] = oldEdgeId
                end
            end
        end
        logger.print('autoFenceMarkerEdgeIds_indexedByConId after =') logger.debugPrint(autoFenceMarkerEdgeIds_indexedByConId)

        -- forbid building more then two markers of the same type
        local markerCount = arrayUtils.getCount(autoFenceMarkerEdgeIds_indexedByConId, true)
        logger.print('markerCount = ' .. tostring(markerCount))
        if markerCount > 1 then
            local conIds = {}
            for conId, _ in pairs(autoFenceMarkerEdgeIds_indexedByConId) do
                conIds[#conIds+1] = conId
            end
            guiHelpers.showWarningWithGoto(_guiTexts.waypointAlreadyBuilt, newConId, conIds)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = newConId
                }
            ))
            return false
        end

        if markerCount ~= 1 then
            autoFenceMarkerEdgeIds_indexedByConId[newConId] = newEdgeId
            -- not ready yet
            -- guiHelpers.showWarningWithGoto(_guiTexts.buildMoreWaypoints), newWaypointId)
            return false
        end

        -- now we check the twin
        local twinConId = nil
        for oldConId, oldEdgeId in pairs(autoFenceMarkerEdgeIds_indexedByConId) do
            if oldConId ~= newConId then twinConId = oldConId end
        end
        local twinConPosition = _utils.getConPosition(twinConId)
        local twinEdgeId = autoFenceMarkerEdgeIds_indexedByConId[twinConId]
        if logger.isExtendedLog() then
            logger.print('newConId, twinConId = ' .. tostring(newConId) .. ', ' .. tostring(twinConId))
            logger.print('newEdgeId, twinEdgeId = ' .. tostring(newEdgeId) .. ', ' .. tostring(twinEdgeId))
            logger.print('fence marker position =') logger.debugPrint(newConPosition)
            logger.print('twin marker position =') logger.debugPrint(twinConPosition)
        end
        -- no twin or no useful twin
        if not(twinConPosition) or not(edgeUtils.isValidAndExistingId(twinConId)) or not(edgeUtils.isValidAndExistingId(twinEdgeId)) then
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = twinConId
                }
            ))
            return false
        end

        local markerDistance = transfUtils.getPositionsDistance(newConPosition, twinConPosition)
        -- forbid building markers too close
        if type(markerDistance) ~= 'number' or markerDistance < _constants.minFenceWaypointDistance then
            guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooClose, newConId)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = newConId
                }
            ))
            return false
        -- forbid building markers too far apart, which would make the fence too long
        elseif markerDistance > _constants.maxFenceWaypointDistance then
            local conIds = {}
            for conId, _ in pairs(autoFenceMarkerEdgeIds_indexedByConId) do
                conIds[#conIds+1] = conId
            end
            guiHelpers.showWarningWithGoto(_guiTexts.waypointsTooFar, newConId, conIds)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = newConId
                }
            ))
            return false
        end

        local contiguousTrackEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
            newEdgeId,
            twinEdgeId,
            _constants.maxFenceWaypointDistance,
            true,
            logger.isExtendedLog()
        )
        logger.print('contiguous track edge ids =') logger.debugPrint(contiguousTrackEdgeIds)
        -- make sure the waypoints are on connected tracks
        if #contiguousTrackEdgeIds < 1 then
            local conIds = {}
            for conId, _ in pairs(autoFenceMarkerEdgeIds_indexedByConId) do
                conIds[#conIds+1] = conId
            end
            guiHelpers.showWarningWithGoto(_guiTexts.markersNotConnected, newConId, conIds)
            api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                string.sub(debug.getinfo(1, 'S').source, 1),
                _eventId,
                _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED,
                {
                    conId = newConId
                }
            ))
            return false
        end
    --[[
        local contiguousEdgeIds = {}
        for _, value in pairs(contiguousTrackEdgeProps) do
            arrayUtils.addUnique(contiguousEdgeIds, value.entity)
        end
        logger.print('contiguousEdgeIds =') logger.debugPrint(contiguousEdgeIds)
    ]]

        -- LOLLO NOTE do not check that the tracks between the waypoints are all of the same type
        -- (ie, platforms have the same width) so we have more flexibility with tunnel entrances
        -- on the other hand, different platform widths make trouble with cargo, which has multiple waiting areas:
        -- let's check if they are different only if one is > 5, which only happens with cargo.
--[[
        local trackDistances = {}
        for _, edgeId in pairs(contiguousTrackEdgeIds) do
            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
            local baseEdgeProperties = api.res.trackTypeRep.get(baseEdgeTrack.trackType)
            arrayUtils.addUnique(trackDistances, baseEdgeProperties.trackDistance)
        end
         if #trackDistances > 1 then
            for _, td in pairs(trackDistances) do
                if td > 5 then
                    guiHelpers.showWarningWithGoto(_guiTexts.differentPlatformWidths, conId)
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        _eventId,
                        _eventNames.WAYPOINT_BULLDOZE_REQUESTED,
                        {
                            waypointId = conId,
                        }
                    ))
                    return false
                end
            end
        end
]]

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
            print('marker con transf =') debugPrint(newConTransf)
            print('vector 000 transformed =') debugPrint(vec000Transformed)
            print('vector 100 transformed =') debugPrint(vec100Transformed)
            print('node0 position =') debugPrint(node0.position)
            print('node1 position =') debugPrint(node1.position)
            print('isWaypointArrowAgainstTrackDirection = ' .. tostring(isWaypointArrowAgainstTrackDirection))
        end

        autoFenceMarkerEdgeIds_indexedByConId[newConId] = newEdgeId
        return {
            autoFenceMarkerEdgeIds_indexedByConId = autoFenceMarkerEdgeIds_indexedByConId,
            isPrecise = (fileName == _constants.autoFenceMarkerPreciseConFileName),
            isWaypointArrowAgainstTrackDirection = isWaypointArrowAgainstTrackDirection,
            newWaypointId = newConId,
            twinWaypointId = twinConId
        }
    end,
}

function data()
    return {
        guiInit = function()
            -- read variables
            _guiFenceWaypointModelId = api.res.modelRep.find(_constants.fenceWaypointModelId)
            _guiFenceWaypointPreciseModelId = api.res.modelRep.find(_constants.fenceWaypointPreciseModelId)
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
                    logger.print('lollo_auto_fence.handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =')
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
                        logger.print('args =') logger.debugPrint(args)
                        local trackEdgeIdsBetweenEdgeIds = edgeUtils.track.getTrackEdgeIdsBetweenEdgeIds(
                            args.edge1Id, args.edge2Id, _constants.maxFenceWaypointDistance, true, logger.isExtendedLog()
                        )
                        if #trackEdgeIdsBetweenEdgeIds > 0 then
                            local trackEdgeList_Ordered = stationHelpers.getEdgeIdsProperties(trackEdgeIdsBetweenEdgeIds, true, false, true, true)

                            if comparisonUtils.is123sSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[2][1],
                                args.edge2Node1Pos
                            )
                            then
                                logger.print('isWaypoint2ArrowAgainstTrackDirection does not need reversing')
                            elseif comparisonUtils.is123sSame(
                                trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[1][1],
                                args.edge2Node1Pos
                            ) then
                                logger.print('reversing isWaypoint2ArrowAgainstTrackDirection')
                                args.isWaypoint2ArrowAgainstTrackDirection = not(args.isWaypoint2ArrowAgainstTrackDirection)
                            else
                                logger.warn('cannot find the right direction to build my fence')
                                print('last track\'s start position =') debugPrint(trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[1][1])
                                print('last track\'s end position =') debugPrint(trackEdgeList_Ordered[#trackEdgeList_Ordered].posTanX2[2][1])
                                print('second waypoint edge\'s node0 pos =') debugPrint(args.edge2Node0Pos)
                                print('second waypoint edge\'s node1 pos =') debugPrint(args.edge2Node1Pos)
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
                                false,
                                true
                            )
                            -- precise markers: cull the bits on the marker edges but outside the markers
                            if #trackEdgeListFine > 0 then
                                if args.isPrecise then
                                    logger.print('isPrecise, about to cull the bits beyond the markers')
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
                                                logger.print('endPos1 =') logger.debugPrint(endPos1)
                                                logger.print('endPos2 =') logger.debugPrint(endPos2)
                                                logger.print('trackEdgeListFine[1].posTanX2[1][1] = ') logger.debugPrint(trackEdgeListFine[1].posTanX2[1][1])
                                                logger.print('trackEdgeListFine[maxII].posTanX2[2][1] = ') logger.debugPrint(trackEdgeListFine[maxII].posTanX2[2][1])
                                                logger.print('maxII = ' .. tostring(maxII))
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
                                            logger.print('maxII = ' .. tostring(maxII))
                                            logger.print('nearestII = ' .. tostring(nearestII))
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
                                            logger.print('maxII = ' .. tostring(maxII))
                                            logger.print('nearestII = ' .. tostring(nearestII))
                                            for ii = nearestII + 1, maxII, 1 do
                                                table.remove(trackEdgeListFine, nearestII + 1)
                                            end
                                        end
                                    end
                                end

                                local yShift_main = trackEdgeList_Ordered[1].width * 0.5
                                local yShift_WallBehind = trackEdgeList_Ordered[1].width * 0.5 + 1 -- walls behind are 1m or 2m thick and they have y backed up by 0.5
                                local transfs = arrayUtils.map(
                                    trackEdgeListFine,
                                    function(tel)
                                        -- the func returns three arguments, I only return the first, so no direct return
                                        local gps_main, xRatio_main, yRatio_main = transfUtils.getParallelSideways(tel.posTanX2, yShift_main)
                                        local gps_wallBehind, xRatio_wallBehind, yRatio_wallBehind = nil, 1, 1
                                        if tel.type == 0 then -- only on ground
                                            gps_wallBehind, xRatio_wallBehind, yRatio_wallBehind = transfUtils.getParallelSideways(tel.posTanX2, yShift_WallBehind)
                                        end
                                        return {
                                            groundBridgeTunnel_012 = tel.type,
                                            hasLevelCrossing = tel.hasLevelCrossing,
                                            posTanX2_main = gps_main,
                                            xRatio_main = xRatio_main,
                                            yRatio_main = yRatio_main,
                                            -- posTanX2_wallBehind = gps_wallBehind,
                                            xRatio_wallBehind = xRatio_wallBehind,
                                            yRatio_wallBehind = yRatio_wallBehind,
                                        }
                                    end
                                )
                                logger.print('transfs, first 3 records =')
                                logger.debugPrint(transfs[1])
                                logger.debugPrint(transfs[2])
                                logger.debugPrint(transfs[3])
                                if #transfs > 0 then
                                    _actions.buildFence(
                                        transfs,
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
                    -- elseif name == _eventNames.BULLDOZE_CON_REQUESTED then -- unused
                    --     _actions.bulldozeCon(args.conId)
                    elseif name == _eventNames.AUTO_FENCE_MARKER_BULLDOZE_REQUESTED then
                        _actions.bulldozeConstruction(args.conId)
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
                            local newModelId = args.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId
                            if newModelId == _guiFenceWaypointModelId or newModelId == _guiFenceWaypointPreciseModelId then
                                logger.print('args.proposal.proposal.edgeObjectsToAdd[1] =') logger.debugPrint(args.proposal.proposal.edgeObjectsToAdd[1])
                                local waypointData = _guiActions.validateFenceWaypointBuilt(
                                    newModelId,
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
            elseif (name == 'builder.apply' and id == 'constructionBuilder') then
                if not args or not args.result or not args.result[1] then return end

                local conId = args.result[1]

                logger.print('some construction was built')
                local waypointData = _guiActions.validateFenceMarkerBuilt(conId)
                logger.print('fenceWaypointData =') logger.debugPrint(waypointData)
                if not(waypointData) then return end

                _guiActions.handleValidFenceMarkerBuilt(waypointData)
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
                        if not(con) or con.fileName ~= _constants.autoFenceConFileName then return end

                        logger.print('selected one of my fences, it has conId =', conId, 'and con.fileName =', con.fileName)
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
