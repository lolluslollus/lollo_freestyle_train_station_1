local _constants = require('lollo_freestyle_train_station.constants')
local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local comparisonUtils = require('lollo_freestyle_train_station.comparisonUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require('transf')

local _utils = {
    getStreetEraPrefix = function(streetTypeIndex)
        if type(streetTypeIndex) ~= 'number' or streetTypeIndex < 0 then return _constants.eras.era_c.prefix end
        local fileName = api.res.streetTypeRep.getFileName(streetTypeIndex)
        if stringUtils.stringContains(fileName, _constants.eras.era_a.prefix) then return _constants.eras.era_a.prefix
        elseif stringUtils.stringContains(fileName, _constants.eras.era_b.prefix) then return _constants.eras.era_b.prefix
        elseif stringUtils.stringContains(fileName, _constants.eras.era_c.prefix) then return _constants.eras.era_c.prefix
        end
        return _constants.eras.era_c.prefix
    end,
}

---@alias edgeObject {flag: 0|1|2, param: number, modelFileName: string, playerEntity: string | nil, isLeft: boolean, isOneWay: boolean}
---@alias edgeIdProperties {edgeId: integer, catenary: boolean, player: integer | nil, posTanX2: table, trackType: integer, trackTypeName: string, type: 0|1|2, edgeType: string, typeIndex: 0|1|2, edgeTypeName: string, width: number, era: eraPrefix, edgeObjects: table<edgeObject>}
---@alias edgeIdsProperties table<edgeIdProperties>
---@alias nodeIdProperties {nodeId: integer, position: {x: number, y: number, z: number}}
---@alias nodeIdsProperties table<nodeIdProperties>
local helpers = {
    ---isReadEdgeObjects might disagree with isSortOutput
    ---@param edgeIds table<integer>
    ---@param isTrack boolean|nil
    ---@param isReadEdgeObjects boolean|nil
    ---@param isSortOutput boolean|nil
    ---@param isCheckLevelCrossings boolean|nil
    ---@return edgeIdsProperties
    getEdgeIdsProperties = function(edgeIds, isTrack, isReadEdgeObjects, isSortOutput, isCheckLevelCrossings)
        if type(edgeIds) ~= 'table' then return {} end

        local _getEdgeType = function(baseEdgeType)
            return baseEdgeType == 1 and 'BRIDGE' or (baseEdgeType == 2 and 'TUNNEL' or nil)
        end
        local _getEdgeTypeName = function(baseEdgeType, baseEdgeTypeIndex)
            if baseEdgeType == 1 then -- bridge
                return api.res.bridgeTypeRep.getName(baseEdgeTypeIndex)
            elseif baseEdgeType == 2 then -- tunnel
                return api.res.tunnelTypeRep.getName(baseEdgeTypeIndex)
            else
                return nil
            end
        end

        local results = {}
        for i = 1, #edgeIds do
            local edgeId = edgeIds[i]
            -- logger.print('edgeId =', edgeId)
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
            -- logger.print('baseEdge =') logger.debugPrint(baseEdge)
            local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
            local baseEdgeStreet = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
            -- logger.print('baseEdgeTrack =') logger.debugPrint(baseEdgeTrack)
            local baseNode0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
            local baseNode1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
            local baseEdgeProperties = isTrack and api.res.trackTypeRep.get(baseEdgeTrack.trackType) or api.res.streetTypeRep.get(baseEdgeStreet.streetType)

            local pos0 = baseNode0.position
            local pos1 = baseNode1.position
            local tan0 = baseEdge.tangent0
            local tan1 = baseEdge.tangent1

            if isSortOutput then
                local _swap = function()
                    -- LOLLO NOTE lua does not need the third variable for swapping since the assignments take place at the same time
                    pos0, pos1 = pos1, pos0
                    tan0, tan1 = tan1, tan0
                    tan0.x = -tan0.x
                    tan0.y = -tan0.y
                    tan0.z = -tan0.z
                    tan1.x = -tan1.x
                    tan1.y = -tan1.y
                    tan1.z = -tan1.z
                end
                -- edgeIds are in the right sequence, but baseNode0 and baseNode1 depend on the sequence edges were laid in
                if i == 1 then
                    if i < #edgeIds then
                        -- logger.print('nextBaseEdgeId =') logger.debugPrint(edgeIds[i + 1])
                        local nextBaseEdge = api.engine.getComponent(edgeIds[i + 1], api.type.ComponentType.BASE_EDGE)
                        if baseEdge.node0 == nextBaseEdge.node0 or baseEdge.node0 == nextBaseEdge.node1 then _swap() end
                    end
                else
                    local prevBaseEdge = api.engine.getComponent(edgeIds[i - 1], api.type.ComponentType.BASE_EDGE)
                    if baseEdge.node1 == prevBaseEdge.node0 or baseEdge.node1 == prevBaseEdge.node1 then _swap() end
                end
            end

            local playerOwned = api.engine.getComponent(edgeId, api.type.ComponentType.PLAYER_OWNED)
            local result = {
                edgeId = edgeId,
                catenary = baseEdgeTrack and baseEdgeTrack.catenary,
                hasBus = baseEdgeStreet and baseEdgeStreet.hasBus,
                isTrack = isTrack,
                player = playerOwned and playerOwned.player,
                posTanX2 = {
                    {
                        {
                            pos0.x,
                            pos0.y,
                            pos0.z,
                        },
                        {
                            tan0.x,
                            tan0.y,
                            tan0.z,
                        }
                    },
                    {
                        {
                            pos1.x,
                            pos1.y,
                            pos1.z,
                        },
                        {
                            tan1.x,
                            tan1.y,
                            tan1.z,
                        }
                    }
                },
                streetType = baseEdgeStreet and baseEdgeStreet.streetType,
                streetTypeName = baseEdgeStreet and api.res.streetTypeRep.getName(baseEdgeStreet.streetType),
                trackType = baseEdgeTrack and baseEdgeTrack.trackType,
                trackTypeName = baseEdgeTrack and api.res.trackTypeRep.getName(baseEdgeTrack.trackType),
                tramTrackType = baseEdgeStreet and baseEdgeStreet.tramTrackType,
                type = baseEdge.type, -- 0 on ground, 1 bridge, 2 tunnel
                edgeType = _getEdgeType(baseEdge.type), -- same as above but in a format constructions understand
                typeIndex = baseEdge.typeIndex, -- -1 on ground, 0 tunnel / cement bridge, 1 steel bridge, 2 stone bridge, 3 suspension bridge
                edgeTypeName = _getEdgeTypeName(baseEdge.type, baseEdge.typeIndex), -- same as above but in a format constructions understand
                width = baseEdgeProperties.trackDistance,
                era = isTrack and trackUtils.getEraPrefix(baseEdgeTrack.trackType) or _utils.getStreetEraPrefix(baseEdgeStreet.streetType)
            }
            if isReadEdgeObjects then
                result.edgeObjects = {}
                for _, object in pairs(baseEdge.objects) do
                    if object ~= nil and object[1] ~= nil then
                        local newEdgeObject = {}

                        local edgeObjectId = object[1]
                        newEdgeObject.flag = object[2] or 0
                        local modelInstanceList = api.engine.getComponent(edgeObjectId, api.type.ComponentType.MODEL_INSTANCE_LIST)
                        local ugTransf = modelInstanceList.fatInstances[1].transf
                        local myTransf = transfUtilsUG.new(ugTransf:cols(0), ugTransf:cols(1), ugTransf:cols(2), ugTransf:cols(3))
                        local distanceNode0Object = transfUtils.getPositionsDistance(
                            baseNode0.position,
                            transfUtils.transf2Position(myTransf, true)
                        )
                        local distanceNode1Object = transfUtils.getPositionsDistance(
                            baseNode1.position,
                            transfUtils.transf2Position(myTransf, true)
                        )
                        if (distanceNode0Object + distanceNode1Object) ~= 0 then
                            newEdgeObject.param = distanceNode0Object / (distanceNode0Object + distanceNode1Object)
                            if newEdgeObject.param < 0 then newEdgeObject.param = 0 elseif newEdgeObject.param > 1 then newEdgeObject.param = 1 end
                        else
                            newEdgeObject.param = 0.5
                            logger.warn('getEdgeIdsProperties found edge ' .. edgeId .. ' has length 0')
                        end

                        newEdgeObject.modelFileName = api.res.modelRep.getName(modelInstanceList.fatInstances[1].modelId)

                        local objectPlayerOwned = api.engine.getComponent(edgeObjectId, api.type.ComponentType.PLAYER_OWNED)
                        if objectPlayerOwned ~= nil then newEdgeObject.playerEntity = objectPlayerOwned.player end

                        local objectWithName = api.engine.getComponent(edgeObjectId, api.type.ComponentType.NAME)
                        if objectWithName ~= nil then newEdgeObject.name = objectWithName.name end

                        --[[
                            api.type.enum.EdgeObjectType.SIGNAL = 2
                            api.type.enum.EdgeObjectType.STOP_LEFT = 0
                            api.type.enum.EdgeObjectType.STOP_RIGHT = 1
                        ]]
                        local isEdgeObjectLeft = true
                        local isEdgeObjectOneWay = false
                        if newEdgeObject.flag == 1 then -- 0 and 1 are for street edges
                            isEdgeObjectLeft = false
                        elseif newEdgeObject.flag == 2 then -- rail edge
                            local signalList = api.engine.getComponent(edgeObjectId, api.type.ComponentType.SIGNAL_LIST)
                            if signalList ~= nil then
                                local signal = signalList.signals[1]
                                -- local edgeId = signal.edgePr.entity

                                local objectIndex = signal.edgePr.index
                                local signalAgainst = api.engine.system.signalSystem.getSignal(api.type.EdgeId.new(edgeId, objectIndex), false)
                                local signalAlong = api.engine.system.signalSystem.getSignal(api.type.EdgeId.new(edgeId, objectIndex), true)
                                if signalAgainst.entity == edgeObjectId then isEdgeObjectLeft = true
                                elseif signalAlong.entity == edgeObjectId then isEdgeObjectLeft = false
                                end

                                isEdgeObjectOneWay = (signal.type == 1)
                            else
                                logger.warn('getEdgeIdsProperties found no signal list for edge ' .. edgeId)
                            end
                        end
                        newEdgeObject.isLeft = isEdgeObjectLeft
                        newEdgeObject.isOneWay = isEdgeObjectOneWay

                        result.edgeObjects[#result.edgeObjects+1] = newEdgeObject
                    end
                end
            end
            if isCheckLevelCrossings then
                if api.engine.system.railRoadCrossingSystem.getRailroadCrossingForNode(baseEdge.node0) ~= -1
                or api.engine.system.railRoadCrossingSystem.getRailroadCrossingForNode(baseEdge.node1) ~= -1
                then
                    result.hasLevelCrossing = true
                end
            end
            results[#results+1] = result
        end

        return results
    end,

    ---@param nodeIds table<integer>
    ---@return nodeIdsProperties
    getNodeIdsProperties = function(nodeIds)
        if type(nodeIds) ~= 'table' then return {} end

        local results = {}
        for i = 1, #nodeIds do
            local nodeId = nodeIds[i]
            if edgeUtils.isValidAndExistingId(nodeId) then
                local baseNode = api.engine.getComponent(nodeId, api.type.ComponentType.BASE_NODE)
                if baseNode ~= nil then
                    results[#results+1] = {
                        nodeId = nodeId,
                        position = {
                            x = baseNode.position.x,
                            y = baseNode.position.y,
                            z = baseNode.position.z,
                        }
                    }
                end
            end
        end

        return results
    end,

    getAllEdgeObjectsWithModelId = function(refModelId)
        if not(edgeUtils.isValidId(refModelId)) then return {} end

        local _map = api.engine.system.streetSystem.getEdgeObject2EdgeMap()
        local edgeObjectIds = {}
        for edgeObjectId, edgeId in pairs(_map) do
            edgeObjectIds[#edgeObjectIds+1] = edgeObjectId
        end

        return edgeUtils.getEdgeObjectsIdsWithModelId2(edgeObjectIds, refModelId)
    end,

    getOuterNodes = function(contiguousEdgeIds, trackType)
        -- only for testing
        local _hasOnlyOneEdgeOfType1 = function(nodeId, map)
            if not(edgeUtils.isValidAndExistingId(nodeId)) or not(trackType) then return false end

            local edgeIds = map[nodeId] -- userdata
            if not(edgeIds) or #edgeIds < 2 then return true end

            local counter = 0
            for _, edgeId in pairs(edgeIds) do -- cannot use edgeIds[index] here
                local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                if baseEdgeTrack ~= nil and baseEdgeTrack.trackType == trackType then
                    counter = counter + 1
                end
            end

            return counter < 2
        end

        logger.print('one')
        if type(contiguousEdgeIds) ~= 'table' or #contiguousEdgeIds < 1 then return {} end
        logger.print('two')
        if #contiguousEdgeIds == 1 then
            local _baseEdge = api.engine.getComponent(contiguousEdgeIds[1], api.type.ComponentType.BASE_EDGE)
            logger.print('three')
            return { _baseEdge.node0, _baseEdge.node1 }
        end

        local results = {}
        local _map = api.engine.system.streetSystem.getNode2TrackEdgeMap()
        local _baseEdgeFirst = api.engine.getComponent(contiguousEdgeIds[1], api.type.ComponentType.BASE_EDGE)
        local _baseEdgeLast = api.engine.getComponent(contiguousEdgeIds[#contiguousEdgeIds], api.type.ComponentType.BASE_EDGE)
        if _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node0, _map) then
            results[#results+1] = _baseEdgeFirst.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeFirst.node1, _map) then
            results[#results+1] = _baseEdgeFirst.node1
        end
        if _hasOnlyOneEdgeOfType1(_baseEdgeLast.node0, _map) then
            results[#results+1] = _baseEdgeLast.node0
        elseif _hasOnlyOneEdgeOfType1(_baseEdgeLast.node1, _map) then
            results[#results+1] = _baseEdgeLast.node1
        end

        return results
    end,

    getCentralEdgePositions_AllBounds_UNUSED_BUT_KEEP_IT = function(edgeLists, maxEdgeLength, isAddTerrainHeight)
        -- logger.print('getCentralEdgePositions_AllBounds starting')
        if type(edgeLists) ~= 'table' then return {} end

        local leadingIndex = 0
        local results = {}
        for _, refEdge in pairs(edgeLists) do
            leadingIndex = leadingIndex + 1
            -- local edgeLength = (transfUtils.getVectorLength(refEdge.posTanX2[1][2]) + transfUtils.getVectorLength(refEdge.posTanX2[2][2])) * 0.5
            local edgeLength, isEdgeLengthUsable, isEdgeLengthAccurate = edgeUtils.getEdgeLength(refEdge.edgeId)
            if edgeLength == nil then
                logger.err('getCentralEdgePositions_OnlyOuterBounds could not find length of edge ' .. (refEdge.edgeId or 'NIL') .. ', leaving')
                return {}
            end
            -- logger.print('edgeLength =') logger.debugPrint(edgeLength)
            local nModelsInEdge = math.ceil(edgeLength / maxEdgeLength)
            -- logger.print('nModelsInEdge =') logger.debugPrint(nModelsInEdge)

            local edgeResults = {}
            local lengthCovered = 0
            local previousNodeBetween = nil
            for i = 1, nModelsInEdge do
                -- logger.print('i == ', i)
                -- logger.print('i / nModelsInEdge =', i / nModelsInEdge)
                local nodeBetween = edgeUtils.getNodeBetween(
                    transfUtils.oneTwoThree2XYZ(refEdge.posTanX2[1][1]),
                    transfUtils.oneTwoThree2XYZ(refEdge.posTanX2[2][1]),
                    transfUtils.oneTwoThree2XYZ(refEdge.posTanX2[1][2]),
                    transfUtils.oneTwoThree2XYZ(refEdge.posTanX2[2][2]),
                    i / nModelsInEdge,
                    edgeLength
                )
                -- logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                if nodeBetween == nil then
                    logger.err('nodeBetween not found; pel =')
                    logger.errorDebugPrint(refEdge)
                    return {}
                end
                local newEdgeLength = nodeBetween.refDistance0 - lengthCovered
                -- logger.print('newEdgeLength =', newEdgeLength)
                -- logger.print('lengthCovered =', lengthCovered)
                if i == 1 then
                    edgeResults[#edgeResults+1] = {
                        posTanX2 = {
                            {
                                {
                                    refEdge.posTanX2[1][1][1],
                                    refEdge.posTanX2[1][1][2],
                                    refEdge.posTanX2[1][1][3],
                                },
                                {
                                    refEdge.posTanX2[1][2][1] * newEdgeLength / edgeLength,
                                    refEdge.posTanX2[1][2][2] * newEdgeLength / edgeLength,
                                    refEdge.posTanX2[1][2][3] * newEdgeLength / edgeLength,
                                }
                            },
                            {
                                {
                                    nodeBetween.position.x,
                                    nodeBetween.position.y,
                                    nodeBetween.position.z,
                                },
                                {
                                    nodeBetween.tangent.x * newEdgeLength,
                                    nodeBetween.tangent.y * newEdgeLength,
                                    nodeBetween.tangent.z * newEdgeLength,
                                }
                            },
                        },
                    }
                elseif i == nModelsInEdge then
                    edgeResults[#edgeResults+1] = {
                        posTanX2 = {
                            {
                                {
                                    previousNodeBetween.position.x,
                                    previousNodeBetween.position.y,
                                    previousNodeBetween.position.z,
                                },
                                {
                                    previousNodeBetween.tangent.x * newEdgeLength,
                                    previousNodeBetween.tangent.y * newEdgeLength,
                                    previousNodeBetween.tangent.z * newEdgeLength,
                                }
                            },
                            {
                                {
                                    refEdge.posTanX2[2][1][1],
                                    refEdge.posTanX2[2][1][2],
                                    refEdge.posTanX2[2][1][3],
                                },
                                {
                                    refEdge.posTanX2[2][2][1] * newEdgeLength / edgeLength,
                                    refEdge.posTanX2[2][2][2] * newEdgeLength / edgeLength,
                                    refEdge.posTanX2[2][2][3] * newEdgeLength / edgeLength,
                                }
                            },
                        },
                    }
                else
                    edgeResults[#edgeResults+1] = {
                        posTanX2 = {
                            {
                                {
                                    previousNodeBetween.position.x,
                                    previousNodeBetween.position.y,
                                    previousNodeBetween.position.z,
                                },
                                {
                                    previousNodeBetween.tangent.x * newEdgeLength,
                                    previousNodeBetween.tangent.y * newEdgeLength,
                                    previousNodeBetween.tangent.z * newEdgeLength,
                                }
                            },
                            {
                                {
                                    nodeBetween.position.x,
                                    nodeBetween.position.y,
                                    nodeBetween.position.z,
                                },
                                {
                                    nodeBetween.tangent.x * newEdgeLength,
                                    nodeBetween.tangent.y * newEdgeLength,
                                    nodeBetween.tangent.z * newEdgeLength,
                                }
                            },
                        },
                    }
                end

                if isAddTerrainHeight then
                    edgeResults[#edgeResults].terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                        edgeResults[#edgeResults].posTanX2[1][1][1],
                        edgeResults[#edgeResults].posTanX2[1][1][2]
                    ))
                    -- edgeResults[#edgeResults].terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    --     edgeResults[#edgeResults].posTanX2[2][1][1],
                    --     edgeResults[#edgeResults].posTanX2[2][1][2]
                    -- ))
                end
                -- we skip all other variables that we don't need
                -- edgeResults[#edgeResults].catenary = pel.catenary
                -- edgeResults[#edgeResults].era = pel.era or _constants.eras.era_c.prefix
                -- edgeResults[#edgeResults].trackType = pel.trackType
                -- edgeResults[#edgeResults].trackTypeName = pel.trackTypeName
                -- edgeResults[#edgeResults].type = pel.type
                -- edgeResults[#edgeResults].typeIndex = pel.typeIndex
                -- edgeResults[#edgeResults].width = pel.width or 0
                edgeResults[#edgeResults].leadingIndex = leadingIndex

                lengthCovered = nodeBetween.refDistance0
                previousNodeBetween = nodeBetween
            end

            for _, value in pairs(edgeResults) do
                results[#results+1] = value
            end
        end

        -- logger.print('getCentralEdgePositions_AllBounds results =') logger.debugPrint(results)
        return results
    end,

    ---comment
    ---@param edgeLists edgeIdsProperties
    ---@param stepLength number
    ---@param isAddTerrainHeight boolean|nil
    ---@param isAddExtraProps boolean|nil
    ---@param isAddLevelCrossings boolean|nil
    ---@return table
    getCentralEdgePositions_OnlyOuterBounds = function(edgeLists, stepLength, isAddTerrainHeight, isAddExtraProps, isAddLevelCrossings)
        local _addExtraProps = function(source, target)
            target.width = source.width or 0 -- idem
            target.type = source.type -- 0 == ground, 1 == bridge, 2 == tunnel
            if isAddExtraProps then
                target.catenary = source.catenary -- this is not totally accurate since we ignore the inner bounds
                target.era = source.era or _constants.eras.era_c.prefix -- idem
                target.trackType = source.trackType -- idem
                target.trackTypeName = source.trackTypeName -- idem
                target.typeIndex = source.typeIndex -- idem
            end
            if isAddTerrainHeight then
                target.terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    target.posTanX2[1][1][1],
                    target.posTanX2[1][1][2]
                ))
                -- edgeResults[#edgeResults].terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                --     edgeResults[#edgeResults].posTanX2[2][1][1],
                --     edgeResults[#edgeResults].posTanX2[2][1][2]
                -- ))
            end
            if isAddLevelCrossings then
                target.hasLevelCrossing  = source.hasLevelCrossing
            end
        end

        logger.print('getCentralEdgePositions_OnlyOuterBounds starting, stepLength =', stepLength, 'first 3 and last 3 edgeLists =') -- logger.debugPrint(edgeLists)
        if type(edgeLists) ~= 'table' or type(stepLength) ~= 'number' or stepLength <= 0 then
            logger.err('getCentralEdgePositions_OnlyOuterBounds got wrong parameters, leaving')
            return {}
        end
        if logger.isExtendedLog() then
            debugPrint(edgeLists[1])
            debugPrint(edgeLists[2])
            debugPrint(edgeLists[3])
            print('...')
            debugPrint(edgeLists[#edgeLists-2])
            debugPrint(edgeLists[#edgeLists-1])
            debugPrint(edgeLists[#edgeLists])
            -- logger.print('########## edgeLists =')
            -- logger.debugPrint(edgeLists)
        end
        local firstRefEdge = nil
        local firstRefEdgeLength = 0.0
        local lengthUncovered = 0.0
        local previousNodeBetween = nil
        local previousRefEdge = nil
        local previousRefEdgeLength = 0.0

        local results = {}
        for _, _refEdge in pairs(edgeLists) do
            -- These should be identical but they are not quite so, so we average
            -- local _refEdgeLength = (transfUtils.getVectorLength(_refEdge.posTanX2[1][2]) + transfUtils.getVectorLength(_refEdge.posTanX2[2][2])) * 0.5
            local _refEdgeLength, isUsable, isAccurate = edgeUtils.getEdgeLength(_refEdge.edgeId, logger.isExtendedLog())
            if _refEdgeLength == nil then
                logger.err('getCentralEdgePositions_OnlyOuterBounds could not find length of edge ' .. (_refEdge.edgeId or 'NIL') .. ', leaving')
                return {}
            end
            if firstRefEdge == nil and _refEdgeLength > 0 then
                firstRefEdge = _refEdge
                firstRefEdgeLength = _refEdgeLength
            end

            if firstRefEdge ~= nil then
                -- local _nSplitsInEdge = math.floor((_oldEdgeLength + lengthUncovered) / stepLength)
                local _firstStep = stepLength - lengthUncovered
                local _firstStepPercent = _firstStep / _refEdgeLength
                local _nextStepPercent = stepLength / _refEdgeLength
                logger.print('_refEdgeLength, _firstStep, firstStepPercent, nextStepPercent =', _refEdgeLength, _firstStep, _firstStepPercent, _nextStepPercent)
                if _firstStepPercent < 0 then
                    logger.err('firstStep cannot be < 0; _refEdgeLength, lengthUncovered =', _refEdgeLength, lengthUncovered)
                    return {}
                end

                local currentStepPercent = _firstStepPercent
                local newEdgeResults = {}

                while currentStepPercent <= 1 do
                    local nodeBetween = edgeUtils.getNodeBetween(
                        transfUtils.oneTwoThree2XYZ(_refEdge.posTanX2[1][1]),
                        transfUtils.oneTwoThree2XYZ(_refEdge.posTanX2[2][1]),
                        transfUtils.oneTwoThree2XYZ(_refEdge.posTanX2[1][2]),
                        transfUtils.oneTwoThree2XYZ(_refEdge.posTanX2[2][2]),
                        currentStepPercent,
                        _refEdgeLength
                        -- logger.isExtendedLog()
                    )
                    -- logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
                    if nodeBetween == nil then
                        logger.err('nodeBetween not found; oldEdge =') -- logger.errorDebugPrint(oldEdge)
                        return {}
                    end
                    -- local newEdgeLength = nodeBetween.refDistance0 - lastCoveredLengthInEdge
                    -- logger.print('nodeBetween.refDistance0 - lastCoveredLengthInEdge =', nodeBetween.refDistance0 - lastCoveredLengthInEdge)
                    -- logger.print('lastCoveredLengthInEdge =', lastCoveredLengthInEdge)
                    if previousNodeBetween == nil then
                        newEdgeResults[#newEdgeResults+1] = {
                            posTanX2 = {
                                {
                                    {
                                        firstRefEdge.posTanX2[1][1][1],
                                        firstRefEdge.posTanX2[1][1][2],
                                        firstRefEdge.posTanX2[1][1][3],
                                    },
                                    {
                                        firstRefEdge.posTanX2[1][2][1] * (lengthUncovered + _firstStep) / firstRefEdgeLength,
                                        firstRefEdge.posTanX2[1][2][2] * (lengthUncovered + _firstStep) / firstRefEdgeLength,
                                        firstRefEdge.posTanX2[1][2][3] * (lengthUncovered + _firstStep) / firstRefEdgeLength,
                                    }
                                },
                                {
                                    {
                                        nodeBetween.position.x,
                                        nodeBetween.position.y,
                                        nodeBetween.position.z,
                                    },
                                    {
                                        nodeBetween.tangent.x * stepLength,
                                        nodeBetween.tangent.y * stepLength,
                                        nodeBetween.tangent.z * stepLength,
                                    }
                                },
                            },
                        }
                    else
                        newEdgeResults[#newEdgeResults+1] = {
                            posTanX2 = {
                                {
                                    {
                                        previousNodeBetween.position.x,
                                        previousNodeBetween.position.y,
                                        previousNodeBetween.position.z,
                                    },
                                    {
                                        previousNodeBetween.tangent.x * stepLength,
                                        previousNodeBetween.tangent.y * stepLength,
                                        previousNodeBetween.tangent.z * stepLength,
                                    }
                                },
                                {
                                    {
                                        nodeBetween.position.x,
                                        nodeBetween.position.y,
                                        nodeBetween.position.z,
                                    },
                                    {
                                        nodeBetween.tangent.x * stepLength,
                                        nodeBetween.tangent.y * stepLength,
                                        nodeBetween.tangent.z * stepLength,
                                    }
                                },
                            },
                        }
                    end

                    _addExtraProps(_refEdge, newEdgeResults[#newEdgeResults])

                    currentStepPercent = currentStepPercent + _nextStepPercent
                    lengthUncovered = lengthUncovered - stepLength
                    previousNodeBetween = nodeBetween
                end

                for _, value in pairs(newEdgeResults) do
                    results[#results+1] = value
                end
                lengthUncovered = lengthUncovered + _refEdgeLength

                logger.print('currentStepPercent =', currentStepPercent, 'lengthUncovered =', lengthUncovered)

                previousRefEdge = _refEdge
                previousRefEdgeLength = _refEdgeLength
            end
        end
        -- now we see to the remaining bit, which may have rounding errors: if we can, we force the last result to the original edge end...
        if #results == 0 then -- if the step is longer than the segments, there will be no results
            logger.print('the step is longer than the segments')
            if firstRefEdge ~= nil and previousRefEdge ~= nil and previousRefEdgeLength ~= 0 then
                results = {
                    {
                        posTanX2 = {
                            {
                                {
                                    firstRefEdge.posTanX2[1][1][1],
                                    firstRefEdge.posTanX2[1][1][2],
                                    firstRefEdge.posTanX2[1][1][3],
                                },
                                {
                                    firstRefEdge.posTanX2[1][2][1] * lengthUncovered / firstRefEdgeLength,
                                    firstRefEdge.posTanX2[1][2][2] * lengthUncovered / firstRefEdgeLength,
                                    firstRefEdge.posTanX2[1][2][3] * lengthUncovered / firstRefEdgeLength,
                                }
                            },
                            {
                                {
                                    previousRefEdge.posTanX2[2][1][1],
                                    previousRefEdge.posTanX2[2][1][2],
                                    previousRefEdge.posTanX2[2][1][3],
                                },
                                {
                                    previousRefEdge.posTanX2[2][2][1] * lengthUncovered / previousRefEdgeLength,
                                    previousRefEdge.posTanX2[2][2][2] * lengthUncovered / previousRefEdgeLength,
                                    previousRefEdge.posTanX2[2][2][3] * lengthUncovered / previousRefEdgeLength,
                                }
                            },
                        },
                    }
                }
                _addExtraProps(firstRefEdge, results[1])
            end
        else
            local _lastRefEdgePosition = arrayUtils.cloneDeepOmittingFields(previousRefEdge.posTanX2[2][1])
            -- if comparisonUtils.isVec3sVeryClose(_lastRefEdgePosition, results[#results].posTanX2[2][1], 5) then
            if comparisonUtils.isVec3sCloserThan(_lastRefEdgePosition, results[#results].posTanX2[2][1], stepLength * 0.01) then
                logger.print('these position vectors are very close:') logger.debugPrint(_lastRefEdgePosition) logger.debugPrint(results[#results].posTanX2[2][1])
                results[#results].posTanX2[2][1] = _lastRefEdgePosition
            -- ...otherwise, we make a new edge to reach to the original edge end
            elseif lengthUncovered > 0 and previousRefEdge ~= nil and previousRefEdgeLength ~= 0 then
                logger.print('these position vectors are not close enough:') logger.debugPrint(_lastRefEdgePosition) logger.debugPrint(results[#results].posTanX2[2][1])
                results[#results+1] = {
                    posTanX2 = {
                        {
                            {
                                previousNodeBetween.position.x,
                                previousNodeBetween.position.y,
                                previousNodeBetween.position.z,
                            },
                            {
                                previousNodeBetween.tangent.x * lengthUncovered,
                                previousNodeBetween.tangent.y * lengthUncovered,
                                previousNodeBetween.tangent.z * lengthUncovered,
                            }
                        },
                        {
                            {
                                previousRefEdge.posTanX2[2][1][1],
                                previousRefEdge.posTanX2[2][1][2],
                                previousRefEdge.posTanX2[2][1][3],
                            },
                            {
                                previousRefEdge.posTanX2[2][2][1] * lengthUncovered / previousRefEdgeLength,
                                previousRefEdge.posTanX2[2][2][2] * lengthUncovered / previousRefEdgeLength,
                                previousRefEdge.posTanX2[2][2][3] * lengthUncovered / previousRefEdgeLength,
                            }
                        },
                    },
                }
                _addExtraProps(previousRefEdge, results[#results])
            else
                logger.err('getCentralEdgePositions_OnlyOuterBounds: there is a piece missing')
            end
        end
        if logger.isExtendedLog() then
            print('getCentralEdgePositions_OnlyOuterBounds last 3 results =')
            debugPrint(results[#results-2])
            debugPrint(results[#results-1])
            debugPrint(results[#results])
        end
        return results
    end,

    calcCentralEdgePositions_GroupByMultiple = function(edgeLists, multiple, isAddTerrainHeight, isAddExtraProps)
        logger.print('getCentralEdgePositions_GroupByMultiple starting, multiple =', multiple, 'edgeLists =') --logger.debugPrint(edgeLists)
        if type(edgeLists) ~= 'table' or type(multiple) ~= 'number' or math.floor(multiple) < 2 then
            logger.err('getCentralEdgePositions_GroupByMultiple got wrong parameters, leaving')
            return {}
        end
        multiple = math.floor(multiple)

        local refEdgeCounter = 0
        local refEdgeCounterMax = #edgeLists
        local groupCounter = 0
        local itemCounter = 0
        local newEdge = nil
        local results = {}
        for _, refEdge in pairs(edgeLists) do
            refEdgeCounter = refEdgeCounter + 1
            itemCounter = itemCounter + 1
            if itemCounter == 1 then
                groupCounter = groupCounter + 1

                newEdge = {
                    posTanX2 = {}
                }
                newEdge.posTanX2[1] = {
                    {
                        refEdge.posTanX2[1][1][1],
                        refEdge.posTanX2[1][1][2],
                        refEdge.posTanX2[1][1][3],
                    },
                    {
                        refEdge.posTanX2[1][2][1] * multiple,
                        refEdge.posTanX2[1][2][2] * multiple,
                        refEdge.posTanX2[1][2][3] * multiple,
                    }
                }
                newEdge.width = refEdge.width or 0
                newEdge.type = refEdge.type or 0
                if isAddExtraProps then
                    newEdge.catenary = refEdge.catenary
                    newEdge.era = refEdge.era or _constants.eras.era_c.prefix
                    newEdge.trackType = refEdge.trackType
                    newEdge.trackTypeName = refEdge.trackTypeName
                    newEdge.typeIndex = refEdge.typeIndex
                end
                if isAddTerrainHeight then
                    newEdge.terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                        newEdge.posTanX2[1][1][1],
                        newEdge.posTanX2[1][1][2]
                    ))
                end
            end
            -- an item could be the first and the last at the same time
            if (itemCounter == multiple or refEdgeCounter == refEdgeCounterMax) then
                if itemCounter ~= multiple then
                    newEdge.posTanX2[1][2][1] = newEdge.posTanX2[1][2][1] * itemCounter / multiple
                    newEdge.posTanX2[1][2][2] = newEdge.posTanX2[1][2][2] * itemCounter / multiple
                    newEdge.posTanX2[1][2][3] = newEdge.posTanX2[1][2][3] * itemCounter / multiple
                end
                newEdge.posTanX2[2] = {
                    {
                        refEdge.posTanX2[2][1][1],
                        refEdge.posTanX2[2][1][2],
                        refEdge.posTanX2[2][1][3],
                    },
                    {
                        refEdge.posTanX2[2][2][1] * itemCounter,
                        refEdge.posTanX2[2][2][2] * itemCounter,
                        refEdge.posTanX2[2][2][3] * itemCounter,
                    }
                }
                -- if isAddTerrainHeight then
                --     newEdge.terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                --         newEdge.posTanX2[2][1][1],
                --         newEdge.posTanX2[2][1][2]
                --     ))
                -- end
                itemCounter = 0
                results[#results+1] = newEdge
            end
            -- important
            refEdge.leadingIndex = groupCounter
        end

        logger.print('getCentralEdgePositions_GroupByMultiple about to return =') logger.debugPrint(results)
        return results
    end,

    getShiftedEdgePositions = function(edgeLists, sideShift, index1, indexN)
        local i1 = index1
        local iN = indexN
        if type(i1) ~= 'number' or i1 < 1 then i1 = 1 end
        if type(iN) ~= 'number' or iN > #edgeLists then iN = #edgeLists end

        local results = {}
        for i = i1, iN do
            results[#results+1] = {
                -- catenary = edgeLists[i].catenary,
                leadingIndex = edgeLists[i].leadingIndex,
                -- posTanX2 = transfUtils.getParallelSidewaysCoarse(edgeLists[i].posTanX2, sideShift),
                posTanX2 = transfUtils.getParallelSideways(edgeLists[i].posTanX2, sideShift),
                -- trackType = edgeLists[i].trackType,
                -- trackTypeName = edgeLists[i].trackTypeName,
                -- type = edgeLists[i].type,
                -- typeIndex = edgeLists[i].typeIndex
            }
        end

        -- make shifted edges match
        for i = 1, #results - 1 do
            local pos1 = results[i].posTanX2[2][1]
            local pos2 = results[i + 1].posTanX2[1][1]
            if pos1[1] ~= pos2[1] or pos1[2] ~= pos2[2] or pos1[3] ~= pos2[3] then
                local midPos = transfUtils.getPositionsMiddle(pos1, pos2)
                results[i].posTanX2[2][1] = midPos
                results[i + 1].posTanX2[1][1] = midPos
            end
        end
        return results
    end,

    getCrossConnectors = function(leftPlatforms, centrePlatforms, rightPlatforms, isTrackOnPlatformLeft)
        local results = {}
        local addResult = function(i, oneOrTwo)
            local centrePosTanX2 = centrePlatforms[i].posTanX2

            if isTrackOnPlatformLeft then
                local leftPosTanX2 = leftPlatforms[i].posTanX2
                local newTanLeft = {
                    centrePosTanX2[oneOrTwo][1][1] - leftPosTanX2[oneOrTwo][1][1],
                    centrePosTanX2[oneOrTwo][1][2] - leftPosTanX2[oneOrTwo][1][2],
                    centrePosTanX2[oneOrTwo][1][3] - leftPosTanX2[oneOrTwo][1][3],
                }
                local newRecordLeft = {
                    {
                        leftPosTanX2[oneOrTwo][1],
                        newTanLeft
                    },
                    {
                        centrePosTanX2[oneOrTwo][1],
                        newTanLeft
                    }
                }
                results[#results+1] = { posTanX2 = newRecordLeft }
            else
                local rightPosTanX2 = rightPlatforms[i].posTanX2
                local newTanRight = {
                    centrePosTanX2[oneOrTwo][1][1] - rightPosTanX2[oneOrTwo][1][1],
                    centrePosTanX2[oneOrTwo][1][2] - rightPosTanX2[oneOrTwo][1][2],
                    centrePosTanX2[oneOrTwo][1][3] - rightPosTanX2[oneOrTwo][1][3],
                }
                local newRecordRight = {
                    {
                        rightPosTanX2[oneOrTwo][1],
                        newTanRight
                    },
                    {
                        centrePosTanX2[oneOrTwo][1],
                        newTanRight
                    },
                }
                results[#results+1] = { posTanX2 = newRecordRight }
            end
        end
        for i = 1, #centrePlatforms do
            addResult(i, 1)
        end
        addResult(#centrePlatforms, 2)

        return results
    end,

    getWhichEdgeGetsEdgeObjectAfterSplit = function(edgeObjPosition, node0pos, node1pos, nodeBetween)
        local result = {
            assignToSide = nil,
        }
        -- logger.print('LOLLO attempting to place edge object with position =')
        -- logger.debugPrint(edgeObjPosition)
        -- logger.print('wholeEdge.node0pos =') logger.debugPrint(node0pos)
        -- logger.print('nodeBetween.position =') logger.debugPrint(nodeBetween.position)
        -- logger.print('nodeBetween.tangent =') logger.debugPrint(nodeBetween.tangent)
        -- logger.print('wholeEdge.node1pos =') logger.debugPrint(node1pos)

        local edgeObjPosition_assignTo = nil
        local node0_assignTo = nil
        local node1_assignTo = nil
        -- at nodeBetween, I can draw the normal to the road:
        -- y = a + bx
        -- the angle is alpha = atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + PI / 2
        -- so b = math.tan(alpha)
        -- a = y - bx
        -- so a = nodeBetween.position.y - b * nodeBetween.position.x
        -- points under this line will go one way, the others the other way
        local alpha = math.atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + math.pi * 0.5
        local b = math.tan(alpha)
        if math.abs(b) < 1e+06 then
            local a = nodeBetween.position.y - b * nodeBetween.position.x
            if a + b * edgeObjPosition[1] > edgeObjPosition[2] then -- edgeObj is below the line
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if a + b * node0pos[1] > node0pos[2] then -- wholeEdge.node0pos is below the line
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if a + b * node1pos[1] > node1pos[2] then -- wholeEdge.node1pos is below the line
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        -- if b grows too much, I lose precision, so I approximate it with the y axis
        else
            -- logger.print('alpha =', alpha, 'b =', b)
            if edgeObjPosition[1] > nodeBetween.position.x then
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if node0pos[1] > nodeBetween.position.x then
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if node1pos[1] > nodeBetween.position.x then
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        end

        if edgeObjPosition_assignTo == node0_assignTo then
            result.assignToSide = 0
        elseif edgeObjPosition_assignTo == node1_assignTo then
            result.assignToSide = 1
        end

        -- logger.print('LOLLO assignment =') logger.debugPrint(result)
        return result
    end,

    isBuildingConstructionWithFileName = function(param, fileName)
        local toAdd =
            type(param) == 'table' and type(param.proposal) == 'userdata' and type(param.proposal.toAdd) == 'userdata' and
            param.proposal.toAdd

        if toAdd and #toAdd > 0 then
            for i = 1, #toAdd do
                if toAdd[i].fileName == fileName then
                    return true
                end
            end
        end

        return false
    end,

    getProposal2ReplaceEdgeWithSameRemovingObject = function(oldEdgeId, objectIdToRemove)
        -- replaces a track segment with an identical one, without destroying the buildings
        if not(edgeUtils.isValidAndExistingId(oldEdgeId)) then return false end

        local oldEdge = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldEdgeTrack = api.engine.getComponent(oldEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldEdge == nil or oldEdgeTrack == nil then return false end

        local newEdge = api.type.SegmentAndEntity.new()
        newEdge.entity = -1
        newEdge.type = _constants.railEdgeType
        -- newEdge.comp = oldEdge -- no good enough if I want to remove objects, the api moans
        newEdge.comp.node0 = oldEdge.node0
        newEdge.comp.node1 = oldEdge.node1
        newEdge.comp.tangent0 = oldEdge.tangent0
        newEdge.comp.tangent1 = oldEdge.tangent1
        newEdge.comp.type = oldEdge.type -- respect bridge or tunnel
        newEdge.comp.typeIndex = oldEdge.typeIndex -- respect type of bridge or tunnel
        newEdge.playerOwned = api.engine.getComponent(oldEdgeId, api.type.ComponentType.PLAYER_OWNED)
        newEdge.trackEdge = oldEdgeTrack
        if trackUtils.isPlatform(oldEdgeTrack.trackType) then
            newEdge.trackEdge.catenary = false
        end

        -- logger.print('edgeUtils.isValidId(objectIdToRemove) =', edgeUtils.isValidId(objectIdToRemove))
        -- logger.print('edgeUtils.isValidAndExistingId(objectIdToRemove) =', edgeUtils.isValidAndExistingId(objectIdToRemove))
        if edgeUtils.isValidId(objectIdToRemove) then
            local edgeObjects = {}
            for _, edgeObj in pairs(oldEdge.objects) do
                if edgeObj[1] ~= objectIdToRemove then
                    table.insert(edgeObjects, { edgeObj[1], edgeObj[2] })
                end
            end
            if #edgeObjects > 0 then
                newEdge.comp.objects = edgeObjects -- LOLLO NOTE cannot insert directly into edge0.comp.objects
                -- logger.print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects =') logger.debugPrint(newEdge.comp.objects)
            else
                -- logger.print('replaceEdgeWithSameRemovingObject: newEdge.comp.objects = not changed')
            end
        else
            logger.print('replaceEdgeWithSameRemovingObject: objectIdToRemove is no good, it is') logger.debugPrint(objectIdToRemove)
            newEdge.comp.objects = oldEdge.objects
        end

        -- logger.print('newEdge.comp.objects:')
        -- for key, value in pairs(newEdge.comp.objects) do
        --     logger.print('key =', key) logger.debugPrint(value)
        -- end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToRemove[1] = oldEdgeId
        proposal.streetProposal.edgesToAdd[1] = newEdge
        if edgeUtils.isValidAndExistingId(objectIdToRemove) then
            proposal.streetProposal.edgeObjectsToRemove[1] = objectIdToRemove
        end

        return proposal
    end,

    getNeighbourNodeIdsOfBulldozedTerminal = function(platformEdgeLists, trackEdgeLists)
        logger.print('getNeighbourNodeIdsOfBulldozedTerminal starting')

        local result = {
            platforms = {
                node1 = nil,
                node2 = nil
            },
            tracks = {
                node1 = nil,
                node2 = nil
            }
        }

        local _map = api.engine.system.streetSystem.getNode2TrackEdgeMap()
        local _getNearestNodeId = function(refPosition, nodeIds)
            local shortestDistance = 9999.9
            local nearestNodeId = nil
            for _, nodeId in pairs(nodeIds) do
                -- only take track nodes with at least one edge attached
                if edgeUtils.isValidAndExistingId(nodeId) and #_map[nodeId] > 0 then
                    local nodePosition = api.engine.getComponent(nodeId, api.type.ComponentType.BASE_NODE).position
                    local distance = transfUtils.getPositionsDistance(refPosition, nodePosition)
                    if distance and distance < shortestDistance then
                        shortestDistance = distance
                        nearestNodeId = nodeId
                    elseif distance == shortestDistance then
                        -- LOLLO TODO what if there are multiple nodes in the same position? It's academic, but how do I make sure it will take the best one?
                        -- after build 35716, this should never happen; it'd be nice to know the game tolerance for "same position".
                        logger.warn('getNeighbourNodeIdsOfBulldozedTerminal got two nodes at') logger.warningDebugPrint(refPosition)
                    end
                end
            end
            return nearestNodeId
        end
        local _tolerance = 0.001
        if type(platformEdgeLists) == 'table' and #platformEdgeLists > 0 then
            local position1 = platformEdgeLists[1].posTanX2[1][1]
            local platformNode1Ids = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position1),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position1[3] - _tolerance,
                position1[3] + _tolerance
            )
            result.platforms.node1 = _getNearestNodeId(position1, platformNode1Ids)

            local position2 = platformEdgeLists[#platformEdgeLists].posTanX2[2][1]
            local platformNode2Ids = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position2),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position2[3] - _tolerance,
                position2[3] + _tolerance
            )
            result.platforms.node2 = _getNearestNodeId(position2, platformNode2Ids)
        end
        if type(trackEdgeLists) == 'table' and #trackEdgeLists > 0 then
            local position1 = trackEdgeLists[1].posTanX2[1][1]
            local trackNode1Ids = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position1),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position1[3] - _tolerance,
                position1[3] + _tolerance
            )
            result.tracks.node1 = _getNearestNodeId(position1, trackNode1Ids)

            local position2 = trackEdgeLists[#trackEdgeLists].posTanX2[2][1]
            local trackNode2Ids = edgeUtils.getNearbyObjectIds(
                transfUtils.position2Transf(position2),
                _tolerance,
                api.type.ComponentType.BASE_NODE,
                position2[3] - _tolerance,
                position2[3] + _tolerance
            )
            result.tracks.node2 = _getNearestNodeId(position2, trackNode2Ids)
        end
        logger.print('getNeighbourNodeIdsOfBulldozedTerminal about to return') logger.debugPrint(result)
        return result
    end,

    getHowManyTerminalsInStationGroup = function(stationGroupId)
        if not(edgeUtils.isValidAndExistingId(stationGroupId)) then return -1 end

        local stationGroupData = api.engine.getComponent(stationGroupId, api.type.ComponentType.STATION_GROUP)
        if not(stationGroupData) or not(stationGroupData.stations) then return -1 end

        local result = 0
        for _, stationId in pairs(stationGroupData.stations) do
            result = result + #(api.engine.getComponent(stationId, api.type.ComponentType.STATION).terminals)
        end
        return result
    end,
}

helpers.getNearbyFreestyleStationConsList = function(transf, searchRadius, isOnlyPassengers, isCheckMaxTerminals)
    logger.print('getNearbyFreestyleStationConsList starting')
    if type(transf) ~= 'table' then return {} end
    if tonumber(searchRadius) == nil then searchRadius = _constants.searchRadius4NearbyStation2Join end

    -- LOLLO NOTE in the game and in this mod, there is one train station for each station group
    -- and viceversa. Station groups hold some information that stations don't, tho.
    -- Multiple station groups can share a construction.
    -- What I really want here is a list with one item each construction, but that could be an expensive loop,
    -- so I check the stations instead and index by the construction.
    local stationIds = edgeUtils.getNearbyObjectIds(transf, searchRadius, api.type.ComponentType.STATION)
    local _station2ConstructionMap = api.engine.system.streetConnectorSystem.getStation2ConstructionMap()
    local resultsIndexed = {}
    for _, stationId in pairs(stationIds) do
        if edgeUtils.isValidAndExistingId(stationId) then
            local conId = _station2ConstructionMap[stationId]
            if edgeUtils.isValidAndExistingId(conId) then
                local con = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
                if con ~= nil and con.fileName == _constants.stationConFileName then
                    -- logger.print('construction.name =') logger.debugPrint(con.name) nil
                    local isCargo = api.engine.getComponent(stationId, api.type.ComponentType.STATION).cargo or false
                    -- logger.print('isCargo =', isCargo)
                    -- logger.print('isOnlyPassengers =', isOnlyPassengers)
                    if not(isCargo) or not(isOnlyPassengers) then
                        local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(stationId)
                        local howManyTerminalsInStationGroup = helpers.getHowManyTerminalsInStationGroup(stationGroupId)
                        logger.print('howManyTerminalsInStationGroup =', howManyTerminalsInStationGroup)
                        if howManyTerminalsInStationGroup >= 0 and (howManyTerminalsInStationGroup < _constants.maxNTerminals or not(isCheckMaxTerminals)) then
                            local isTwinCargo = false
                            local isTwinPassenger = false
                            local cargoStationGroupName = nil
                            local passengerStationGroupName = nil

                            if resultsIndexed[conId] ~= nil then
                                -- logger.print('found a twin, it is') logger.debugPrint(resultsIndexed[conId])
                                if resultsIndexed[conId].isCargo then isTwinCargo = true end
                                if resultsIndexed[conId].isPassenger then isTwinPassenger = true end
                                cargoStationGroupName = resultsIndexed[conId].cargoStationGroupName
                                passengerStationGroupName = resultsIndexed[conId].passengerStationGroupName
                            end

                            local stationGroupName_struct = api.engine.getComponent(stationGroupId, api.type.ComponentType.NAME)
                            if stationGroupName_struct ~= nil and not stringUtils.isNullOrEmptyString(stationGroupName_struct.name) then
                                if isCargo then
                                    cargoStationGroupName = stationGroupName_struct.name
                                else
                                    passengerStationGroupName = stationGroupName_struct.name
                                end
                            end

                            local position = transfUtils.transf2Position(
                                transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
                            )
                            resultsIndexed[conId] = {
                                id = conId,
                                isCargo = isCargo or isTwinCargo,
                                isPassenger = not(isCargo) or isTwinPassenger,
                                cargoStationGroupName = cargoStationGroupName,
                                passengerStationGroupName = passengerStationGroupName,
                                position = position
                            }
                        end
                    end
                end
            end
        end
    end

    logger.print('resultsIndexed =') logger.debugPrint(resultsIndexed)
    local results = {}
    for _, value in pairs(resultsIndexed) do
        results[#results+1] = value
        if value.cargoStationGroupName and value.passengerStationGroupName then
            value.name = value.cargoStationGroupName .. ' - ' .. value.passengerStationGroupName
        else
            value.name = (value.cargoStationGroupName or value.passengerStationGroupName) or ''
        end
        value.cargoStationGroupName = nil
        value.passengerStationGroupName = nil
    end
    -- logger.print('# nearby freestyle stations = ', #results)
    -- logger.print('nearby freestyle stations = ') logger.debugPrint(results)
    return results
end

local _getDisjointNeighbourNodeId = function(stationNodeId, stationNodePositionXYZ, frozenNodeIds_indexed, isTrack)
    if not(edgeUtils.isValidAndExistingId(stationNodeId)) or stationNodePositionXYZ == nil then return nil end

    local _map = isTrack and api.engine.system.streetSystem.getNode2TrackEdgeMap() or api.engine.system.streetSystem.getNode2StreetEdgeMap()
    local _tolerance = 0.001
    local _nearbyNodeIds = edgeUtils.getNearbyObjectIds(
        transfUtils.position2Transf(stationNodePositionXYZ),
        _tolerance,
        api.type.ComponentType.BASE_NODE,
        stationNodePositionXYZ.z - _tolerance,
        stationNodePositionXYZ.z + _tolerance
    )
    -- logger.print('_getDisjointNeighbourNodeId found') logger.debugPrint(nearbyNodeIds)
    local shortestDistance = 9999.9
    local nearestNodeId = nil
    for _, nearbyNodeId in pairs(_nearbyNodeIds) do
        if edgeUtils.isValidAndExistingId(nearbyNodeId)
        and nearbyNodeId ~= stationNodeId
        and not(frozenNodeIds_indexed[nearbyNodeId])
        -- only take street or track nodes, depending on isTrack, and with at least one edge attached
        and #_map[nearbyNodeId] > 0
        then
            local node = api.engine.getComponent(nearbyNodeId, api.type.ComponentType.BASE_NODE)
            local distance = transfUtils.getPositionsDistance(stationNodePositionXYZ, node.position)
            -- LOLLO TODO what if there are multiple nodes in the same position? It's academic, but how do I make sure it will take the best one?
            -- after build 35716, this should never happen; it'd be nice to know the game tolerance for "same position".
            if distance and distance < shortestDistance then
                shortestDistance = distance
                nearestNodeId = nearbyNodeId
            end
        end
    end
    return nearestNodeId
end

local _getNeighbourEdgeIdsAndConIds = function(nodeId, frozenEdgeIds_indexed, isTrack)
    local freeEdgeIds_indexed = {}
    local isAnyEdgeFrozenInAConstruction = false
    local neighbourConIds_indexed = {}

    local connectedEdgeIds = isTrack and edgeUtils.track.getConnectedEdgeIds({nodeId}) or edgeUtils.street.getConnectedEdgeIds({nodeId})
    for _, edgeId in pairs(connectedEdgeIds) do
        -- for streets, I use the generic edge getter so I also get the edges in the adjoining constructions;
        -- I make sure they are streets later
        if not(frozenEdgeIds_indexed[edgeId]) then
            -- check that the edge is not frozen in another construction, such as nearby stairs with a snappy bridge
            local neighbourConId = api.engine.system.streetConnectorSystem.getConstructionEntityForEdge(edgeId)
            if edgeUtils.isValidId(neighbourConId) then
                isAnyEdgeFrozenInAConstruction = true
                neighbourConIds_indexed[neighbourConId] = true
            elseif isTrack or (api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET) ~= nil) then
                freeEdgeIds_indexed[edgeId] = true
            end
        end
    end

    local freeEdgeIds = {}
    for edgeId, _ in pairs(freeEdgeIds_indexed) do
        freeEdgeIds[#freeEdgeIds+1] = edgeId
    end
    local neighbourConIds = {}
    for conId, _ in pairs(neighbourConIds_indexed) do
        neighbourConIds[#neighbourConIds+1] = conId
    end

    return freeEdgeIds, isAnyEdgeFrozenInAConstruction, neighbourConIds
end
---@return table<{nodeId: integer, edgeId: integer, nodePosition: {x: number, y: number, z: number}}>
local _getStationStreetEndNodes = function(frozenEdgeIds_indexed, frozenNodeIds_indexed)
    logger.print('_getStationStreetEndNodes starting, frozenEdges =') logger.debugPrint(frozenEdgeIds_indexed)
    -- we may want to respect frozen edges and nodes of other constructions, too, so we import them
    -- instead of picking them from the current station.

    local freeNodes = {}
    local _addNode = function(nodeId, edgeId)
        freeNodes[#freeNodes+1] = {
            nodeId = nodeId,
            edgeId = edgeId,
            nodePosition = edgeUtils.getPositionTableFromUserdata(api.engine.getComponent(nodeId, api.type.ComponentType.BASE_NODE).position)
        }
    end
    for edgeId, _ in pairs(frozenEdgeIds_indexed) do
        if edgeUtils.isValidAndExistingId(edgeId) then
            local baseEdgeStreet = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_STREET)
            if baseEdgeStreet ~= nil then
                local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                if baseEdge ~= nil then
                    if frozenNodeIds_indexed[baseEdge.node0] then
                        if not(frozenNodeIds_indexed[baseEdge.node1]) then
                            _addNode(baseEdge.node1, edgeId)
                        end
                    elseif frozenNodeIds_indexed[baseEdge.node1] then
                        if not(frozenNodeIds_indexed[baseEdge.node0]) then
                            _addNode(baseEdge.node0, edgeId)
                        end
                    end
                end
            end
        end
    end

    return freeNodes
end

local _getStationStreetEndEntities = function(frozenEdgeIds_indexed, frozenNodeIds_indexed)
    -- local frozenEdgeIds = arrayUtils.cloneDeepOmittingFields(stationCon.frozenEdges, {}, true)
    -- local frozenNodeIds = arrayUtils.cloneDeepOmittingFields(stationCon.frozenNodes, {}, true)
    local results = _getStationStreetEndNodes(frozenEdgeIds_indexed, frozenNodeIds_indexed)

    for _, endEntity in pairs(results) do
        -- endEntity.disjointNeighbourNode = {
        --     conIds = {},
        --     isNodeAdjoiningAConstruction = false,
        --     nodeId = _getDisjointNeighbourNodeId(endEntity.nodeId, endEntity.nodePosition, frozenNodeIds_indexed, false)
        -- }
        -- endEntity.disjointNeighbourEdges = {
        --     edgeIds = {}
        -- }
        -- endEntity.disjointNeighbourEdges.edgeIds, endEntity.disjointNeighbourNode.isNodeAdjoiningAConstruction, endEntity.disjointNeighbourNode.conIds = _getNeighbourEdgeIdsAndConIds(endEntity.disjointNeighbourNode.nodeId, frozenEdgeIds_indexed, false)
        endEntity.jointNeighbourNode = {
            conIds = {},
            conProps = {},
            isNodeAdjoiningAConstruction = false,
            -- outerLoneNodeIds = {}
        }
        endEntity.jointNeighbourEdges = {
            edgeIds = {},
            props = {}
        }
        endEntity.jointNeighbourEdges.edgeIds, endEntity.jointNeighbourNode.isNodeAdjoiningAConstruction, endEntity.jointNeighbourNode.conIds = _getNeighbourEdgeIdsAndConIds(endEntity.nodeId, frozenEdgeIds_indexed, false)
    end
    logger.print('_getStationStreetEndEntities results 1 =') logger.debugPrint(results)
    for a, endEntity in pairs(results) do
        for b, edgeId in pairs(endEntity.jointNeighbourEdges.edgeIds) do
            local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    --[[
            for c, nodeId in pairs({baseEdge.node0, baseEdge.node1}) do
                if #(edgeUtils.street.getConnectedEdgeIds({nodeId})) < 2 then
                    arrayUtils.addUnique(endEntity.jointNeighbourNode.outerLoneNodeIds, nodeId)
                end
            end
    ]]
            endEntity.jointNeighbourEdges.props[edgeId] = {
                edgeProps = helpers.getEdgeIdsProperties({edgeId}, false, true)[1],
                node0Props = helpers.getNodeIdsProperties({baseEdge.node0})[1],
                node1Props = helpers.getNodeIdsProperties({baseEdge.node1})[1],
            }
        end
        -- this is to rebuild neighbouring constructions
        for d, conId in pairs(endEntity.jointNeighbourNode.conIds) do
            local neighbourCon = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
            endEntity.jointNeighbourNode.conProps[conId] = {
                conId = conId,
                fileName = neighbourCon.fileName,
                params = arrayUtils.cloneDeepOmittingFields(neighbourCon.params, nil, true),
                -- playerEntity = api.engine.util.getPlayer(),  
                transf = transfUtilsUG.new(
                    neighbourCon.transf:cols(0),
                    neighbourCon.transf:cols(1),
                    neighbourCon.transf:cols(2),
                    neighbourCon.transf:cols(3)
                )
            }
        end
    end

    logger.print('_getStationStreetEndEntities final results =') logger.debugPrint(results)
    return results
end

local _getTrackEndNodeIds4T = function(nTerminal, frozenEdgeIds_indexed, frozenNodeIds_indexed, platformEdgeLists, trackEdgeLists)
    -- logger.print('getStationEndNodesUnsorted starting, nTerminal =', nTerminal)
    -- we may want to respect frozen edges and nodes of other constructions, too, so we import them
    -- instead of picking them from the current station.
    local _tolerance = 0.001
    local _map = api.engine.system.streetSystem.getNode2TrackEdgeMap()
    local _getNodeId = function(nodePosition, twinNodePosition)
        -- logger.print('nodePosition =') logger.debugPrint(nodePosition)
        -- logger.print('twinNodePosition =') logger.debugPrint(twinNodePosition)
        local nearbyNodeIds = edgeUtils.getNearbyObjectIds(
            transfUtils.position2Transf(nodePosition),
            _tolerance,
            api.type.ComponentType.BASE_NODE,
            nodePosition[3] - _tolerance,
            nodePosition[3] + _tolerance
        )
        -- logger.print('nodeFunds =') logger.debugPrint(nearbyNodeIds)
        for _, freeNodeId in pairs(nearbyNodeIds) do
            if not(frozenNodeIds_indexed[freeNodeId]) then -- outer nodes are not frozen
                for __, frozenEdgeId in pairs(_map[freeNodeId] or {}) do
                    if frozenEdgeIds_indexed[frozenEdgeId] then -- outer edges are frozen
                        local baseEdgeTrack = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                        if baseEdgeTrack ~= nil then
                            local baseEdge = api.engine.getComponent(frozenEdgeId, api.type.ComponentType.BASE_EDGE)
                            if baseEdge ~= nil then
                                -- If I have two terminals after the other, as opposed to parallel,
                                -- nodeId could belong to the other terminal: to make sure, I check the other node attached to the same frozen edge.
                                if baseEdge.node0 == freeNodeId then
                                    local twinBaseNode = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                                    -- logger.print('baseEdge.node0 == nodeId, twinBaseNode =') logger.debugPrint(twinBaseNode)
                                    if twinBaseNode and twinBaseNode.position and comparisonUtils.isVec3sVeryClose(twinBaseNode.position, twinNodePosition, 4) then
                                        return freeNodeId
                                    end
                                elseif baseEdge.node1 == freeNodeId then
                                    local twinBaseNode = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                                    -- logger.print('baseEdge.node1 == nodeId, twinBaseNode =') logger.debugPrint(twinBaseNode)
                                    if twinBaseNode and twinBaseNode.position and comparisonUtils.isVec3sVeryClose(twinBaseNode.position, twinNodePosition, 4) then
                                        return freeNodeId
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local result = {
        platforms = {
            node1Id = _getNodeId(
                platformEdgeLists[1].posTanX2[1][1],
                platformEdgeLists[1].posTanX2[2][1]
            ),
            node2Id = _getNodeId(
                arrayUtils.getLast(platformEdgeLists).posTanX2[2][1],
                arrayUtils.getLast(platformEdgeLists).posTanX2[1][1]
            )
        },
        tracks = {
            node1Id = _getNodeId(
                trackEdgeLists[1].posTanX2[1][1],
                trackEdgeLists[1].posTanX2[2][1]
            ),
            node2Id = _getNodeId(
                arrayUtils.getLast(trackEdgeLists).posTanX2[2][1],
                arrayUtils.getLast(trackEdgeLists).posTanX2[1][1]
            )
        }
    }

    if result.platforms.node1Id == nil then
        logger.warn('could not find platform.node1Id in station construction; nTerminal =')
        logger.warningDebugPrint(nTerminal)
    end
    if result.platforms.node2Id == nil then
        logger.warn('could not find platform.node2Id in station construction; nTerminal =')
        logger.warningDebugPrint(nTerminal)
    end
    if result.tracks.node1Id == nil then
        logger.warn('could not find track.node1Id in station construction; nTerminal =')
        logger.warningDebugPrint(nTerminal)
    end
    if result.tracks.node2Id == nil then
        logger.warn('WARNING: could not find track.node2Id in station construction; nTerminal =')
        logger.warningDebugPrint(nTerminal)
    end

    return result
end

local _getStationTrackEndEntities4T = function(nTerminal, frozenEdgeIds_indexed, frozenNodeIds_indexed, platformEdgeLists, trackEdgeLists)
    -- frozen edges and nodes can be streets or tracks

    -- get all stations, not only mine? It does not seem necessary for now, and we also bar building close to a station, on top of it.
    -- This thing here works, just in case.
    -- local conTransf = transfUtilsUG.new(con.transf:cols(0), con.transf:cols(1), con.transf:cols(2), con.transf:cols(3))
    -- logger.print('frozenEdges first =') logger.debugPrint(frozenEdgeIds_indexed)
    -- logger.print('frozenNodes first =') logger.debugPrint(frozenNodeIds_indexed)
    -- local nearbyStations = helpers.getNearbyFreestyleStationConsList(conTransf, _constants.searchRadius4NearbyStation2Join, true)
    -- for _, nearbyStation in pairs(nearbyStations) do
    --     logger.print('nearbyStation =') logger.debugPrint(nearbyStation)
    --     if edgeUtils.isValidAndExistingId(nearbyStation.id) then
    --         local nearbyCon = api.engine.getComponent(nearbyStation.id, api.type.ComponentType.CONSTRUCTION)
    --         logger.print('nearbyCon found')
    --         logger.print('#nearbyCon.frozenEdges = ', #nearbyCon.frozenEdges, 'nearbyCon.frozenEdges =') logger.debugPrint(nearbyCon.frozenEdges)
    --         if nearbyCon and nearbyCon.frozenEdges then
    --             for _, frozenEdgeId in pairs(nearbyCon.frozenEdges) do
    --                 frozenEdgeIds_indexed[frozenEdgeId] = true
    --             end
    --         end
    --         if nearbyCon and nearbyCon.frozenNodes then
    --             for _, frozenNodeId in pairs(nearbyCon.frozenNodes) do
    --                 frozenNodeIds_indexed[frozenNodeId] = true
    --             end
    --         end
    --     end
    -- end
    -- logger.print('frozenEdges with neighbours =') logger.debugPrint(frozenEdgeIds_indexed)
    -- logger.print('frozenNodes with neighbours =') logger.debugPrint(frozenNodeIds_indexed)
    local endNodeIds4T = _getTrackEndNodeIds4T(nTerminal, frozenEdgeIds_indexed, frozenNodeIds_indexed, platformEdgeLists, trackEdgeLists)
    -- logger.print('endNodeIds4T =') logger.debugPrint(endNodeIds4T)
    -- I cannot clone these, for some reason: it dumps
    local platformNode1Position = edgeUtils.isValidAndExistingId(endNodeIds4T.platforms.node1Id)
        and edgeUtils.getPositionTableFromUserdata(api.engine.getComponent(endNodeIds4T.platforms.node1Id, api.type.ComponentType.BASE_NODE).position)
        or nil
    local platformNode2Position = edgeUtils.isValidAndExistingId(endNodeIds4T.platforms.node2Id)
        and edgeUtils.getPositionTableFromUserdata(api.engine.getComponent(endNodeIds4T.platforms.node2Id, api.type.ComponentType.BASE_NODE).position)
        or nil
    local trackNode1Position = edgeUtils.isValidAndExistingId(endNodeIds4T.tracks.node1Id)
        and edgeUtils.getPositionTableFromUserdata(api.engine.getComponent(endNodeIds4T.tracks.node1Id, api.type.ComponentType.BASE_NODE).position)
        or nil
    local trackNode2Position = edgeUtils.isValidAndExistingId(endNodeIds4T.tracks.node2Id)
        and edgeUtils.getPositionTableFromUserdata(api.engine.getComponent(endNodeIds4T.tracks.node2Id, api.type.ComponentType.BASE_NODE).position)
        or nil

    local result = {
        platforms = {
            -- -- these are empty or nil if the station has been snapped to its neighbours
            -- disjointNeighbourEdges = {
            --     edge1Ids = {},
            --     edge2Ids = {}
            -- },
            -- -- same
            -- disjointNeighbourNodes = {
            --     isNode1AdjoiningAConstruction = false,
            --     isNode2AdjoiningAConstruction = false,
            --     node1Id = nil,
            --     node2Id = nil,
            -- },
            -- these are populated or nil if the station has been snapped to its neighbours
            jointNeighbourEdges = {
                edge1Ids = {},
                edge2Ids = {},
                props = {}
            },
            -- same
            jointNeighbourNodes = {
                isNode1AdjoiningAConstruction = false,
                isNode2AdjoiningAConstruction = false,
                -- outerLoneNodeIds = {},
            },
            stationEndNodeIds = {
                node1Id = endNodeIds4T.platforms.node1Id,
                node2Id = endNodeIds4T.platforms.node2Id,
            },
            stationEndNodePositions = {
                node1 = platformNode1Position ~= nil and { x = platformNode1Position.x, y = platformNode1Position.y, z = platformNode1Position.z } or nil,
                node2 = platformNode2Position ~= nil and { x = platformNode2Position.x, y = platformNode2Position.y, z = platformNode2Position.z } or nil,
            }
        },
        tracks = {
            -- -- these are empty or nil if the station has been snapped to its neighbours, or if there are no neighbours.
            -- disjointNeighbourEdges = {
            --     edge1Ids = {},
            --     edge2Ids = {}
            -- },
            -- -- same
            -- disjointNeighbourNodes = {
            --     isNode1AdjoiningAConstruction = false,
            --     isNode2AdjoiningAConstruction = false,
            --     node1Id = nil,
            --     node2Id = nil,
            -- },
            -- these are populated or nil if the station has been snapped to its neighbours, or if there are no neighbours.
            jointNeighbourEdges = {
                edge1Ids = {},
                edge2Ids = {},
                props = {}
            },
            -- same
            jointNeighbourNodes = {
                isNode1AdjoiningAConstruction = false,
                isNode2AdjoiningAConstruction = false,
                -- outerLoneNodeIds = {},
            },
            stationEndNodeIds = {
                node1Id = endNodeIds4T.tracks.node1Id,
                node2Id = endNodeIds4T.tracks.node2Id,
            },
            stationEndNodePositions = {
                node1 = trackNode1Position ~= nil and { x = trackNode1Position.x, y = trackNode1Position.y, z = trackNode1Position.z } or nil,
                node2 = trackNode2Position ~= nil and { x = trackNode2Position.x, y = trackNode2Position.y, z = trackNode2Position.z } or nil,
            }
        },
    }

    -- result.platforms.disjointNeighbourNodes.node1Id = _getDisjointNeighbourNodeId(result.platforms.stationEndNodeIds.node1Id, result.platforms.stationEndNodePositions.node1, frozenNodeIds_indexed, true)
    -- result.platforms.disjointNeighbourNodes.node2Id = _getDisjointNeighbourNodeId(result.platforms.stationEndNodeIds.node2Id, result.platforms.stationEndNodePositions.node2, frozenNodeIds_indexed, true)
    -- result.tracks.disjointNeighbourNodes.node1Id = _getDisjointNeighbourNodeId(result.tracks.stationEndNodeIds.node1Id, result.tracks.stationEndNodePositions.node1, frozenNodeIds_indexed, true)
    -- result.tracks.disjointNeighbourNodes.node2Id = _getDisjointNeighbourNodeId(result.tracks.stationEndNodeIds.node2Id, result.tracks.stationEndNodePositions.node2, frozenNodeIds_indexed, true)

    -- result.platforms.disjointNeighbourEdges.edge1Ids, result.platforms.disjointNeighbourNodes.isNode1AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.platforms.disjointNeighbourNodes.node1Id, frozenEdgeIds_indexed, true)
    -- result.platforms.disjointNeighbourEdges.edge2Ids, result.platforms.disjointNeighbourNodes.isNode2AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.platforms.disjointNeighbourNodes.node2Id, frozenEdgeIds_indexed, true)
    -- result.tracks.disjointNeighbourEdges.edge1Ids, result.tracks.disjointNeighbourNodes.isNode1AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.tracks.disjointNeighbourNodes.node1Id, frozenEdgeIds_indexed, true)
    -- result.tracks.disjointNeighbourEdges.edge2Ids, result.tracks.disjointNeighbourNodes.isNode2AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.tracks.disjointNeighbourNodes.node2Id, frozenEdgeIds_indexed, true)

    result.platforms.jointNeighbourEdges.edge1Ids, result.platforms.jointNeighbourNodes.isNode1AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.platforms.stationEndNodeIds.node1Id, frozenEdgeIds_indexed, true)
    result.platforms.jointNeighbourEdges.edge2Ids, result.platforms.jointNeighbourNodes.isNode2AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.platforms.stationEndNodeIds.node2Id, frozenEdgeIds_indexed, true)
    result.tracks.jointNeighbourEdges.edge1Ids, result.tracks.jointNeighbourNodes.isNode1AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.tracks.stationEndNodeIds.node1Id, frozenEdgeIds_indexed, true)
    result.tracks.jointNeighbourEdges.edge2Ids, result.tracks.jointNeighbourNodes.isNode2AdjoiningAConstruction = _getNeighbourEdgeIdsAndConIds(result.tracks.stationEndNodeIds.node2Id, frozenEdgeIds_indexed, true)

    for _, edgeId in pairs(arrayUtils.getConcatValues(result.platforms.jointNeighbourEdges.edge1Ids, result.platforms.jointNeighbourEdges.edge2Ids)) do
        local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
--[[
        for _, nodeId in pairs({baseEdge.node0, baseEdge.node1}) do
            if nodeId ~= result.platforms.stationEndNodeIds.node1Id and nodeId ~= result.platforms.stationEndNodeIds.node2Id then
                if #(edgeUtils.track.getConnectedEdgeIds({nodeId})) < 2 then
                    arrayUtils.addUnique(result.platforms.jointNeighbourNodes.outerLoneNodeIds, nodeId)
                end
            end
        end
]]
        result.platforms.jointNeighbourEdges.props[edgeId] = {
            edgeProps = helpers.getEdgeIdsProperties({edgeId}, true, true)[1],
            node0Props = helpers.getNodeIdsProperties({baseEdge.node0})[1],
            node1Props = helpers.getNodeIdsProperties({baseEdge.node1})[1]
        }
    end
    for _, edgeId in pairs(arrayUtils.getConcatValues(result.tracks.jointNeighbourEdges.edge1Ids, result.tracks.jointNeighbourEdges.edge2Ids)) do
        local baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
--[[
        for _, nodeId in pairs({baseEdge.node0, baseEdge.node1}) do
            if nodeId ~= result.tracks.stationEndNodeIds.node1Id and nodeId ~= result.tracks.stationEndNodeIds.node2Id then
                if #(edgeUtils.track.getConnectedEdgeIds({nodeId})) < 2 then
                    arrayUtils.addUnique(result.tracks.jointNeighbourNodes.outerLoneNodeIds, nodeId)
                end
            end
        end
]]
        result.tracks.jointNeighbourEdges.props[edgeId] = {
            edgeProps = helpers.getEdgeIdsProperties({edgeId}, true, true)[1],
            node0Props = helpers.getNodeIdsProperties({baseEdge.node0})[1],
            node1Props = helpers.getNodeIdsProperties({baseEdge.node1})[1]
        }
    end

    -- logger.print('__getStationTrackEndEntities4T result for terminal ' .. tostring(nTerminal) .. ' =') logger.debugPrint(result)
    return result
end

helpers.getStationTrackEndEntities = function(stationConstructionId, isSkipLogging, nRemovedTerminal)
    logger.print('_getStationTrackEndEntities started, conId =', stationConstructionId or 'NIL')
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then
        if isSkipLogging then return nil end
        logger.err('getStationTrackEndEntities invalid stationConstructionId') logger.errorDebugPrint(stationConstructionId)
        return nil
    end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- logger.print('con =') logger.debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileName then
        if isSkipLogging then return nil end
        logger.err('getStationTrackEndEntities con.fileName =') logger.errorDebugPrint(con.fileName)
        return nil
    end

    local frozenEdgeIds_indexed = {}
    for _, edgeId in pairs(con.frozenEdges) do
        frozenEdgeIds_indexed[edgeId] = true
    end
    local frozenNodeIds_indexed = {}
    for _, nodeId in pairs(con.frozenNodes) do
        frozenNodeIds_indexed[nodeId] = true
    end
    local conParams = con.params -- LOLLO NOTE addressing con, which is huge, can take 100's of msec, so we break it up
    local result = {}
    for t = 1, #conParams.terminals do
        if t ~= nRemovedTerminal then
            local _terminalData = conParams.terminals[t]
            local _platformEdgeLists = _terminalData.platformEdgeLists
            local _trackEdgeLists = _terminalData.trackEdgeLists
            result[t] = _getStationTrackEndEntities4T(t, frozenEdgeIds_indexed, frozenNodeIds_indexed, _platformEdgeLists, _trackEdgeLists)
        end
    end

    -- logger.print('getStationEndEntities result =') logger.debugPrint(result)
    return result
end

helpers.getStationTrackEndEntities4T = function(stationConstructionId, nTerminal)
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then
        logger.err('getStationTrackEndEntities4T received an invalid stationConstructionId')
        logger.errorDebugPrint(stationConstructionId)
        return nil
    end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- logger.print('con =') logger.debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileName then
        logger.err('getStationTrackEndEntities4T con.fileName =')
        logger.errorDebugPrint(con.fileName)
        return nil
    end

    if type(nTerminal) ~= 'number' or nTerminal < 1 or nTerminal > #con.params.terminals then
        logger.warn('getStationTrackEndEntities4T received invalid nTerminal =')
        logger.warningDebugPrint(nTerminal)
        return nil
    end

    local frozenEdgeIds_indexed = {}
    for _, edgeId in pairs(con.frozenEdges) do
        frozenEdgeIds_indexed[edgeId] = true
    end
    local frozenNodeIds_indexed = {}
    for _, nodeId in pairs(con.frozenNodes) do
        frozenNodeIds_indexed[nodeId] = true
    end
    local _terminalData = con.params.terminals[nTerminal] -- LOLLO NOTE addressing con, which is huge, can take 100's of msec, so we break it up
    local _platformEdgeLists = _terminalData.platformEdgeLists
    local _trackEdgeLists = _terminalData.trackEdgeLists
    return _getStationTrackEndEntities4T(nTerminal, frozenEdgeIds_indexed, frozenNodeIds_indexed, _platformEdgeLists, _trackEdgeLists)
end

helpers.getStationStreetEndEntities = function(stationConstructionId, isSkipLogging)
    if not(edgeUtils.isValidAndExistingId(stationConstructionId)) then
        if isSkipLogging then return nil end
        logger.err('getStationStreetEndEntities received an invalid stationConstructionId')
        logger.errorDebugPrint(stationConstructionId)
        return nil
    end

    local con = api.engine.getComponent(stationConstructionId, api.type.ComponentType.CONSTRUCTION)
    -- con contains fileName, params, transf, timeBuilt, frozenNodes, frozenEdges, depots, stations
    -- logger.print('con =') logger.debugPrint(conData)
    if not(con) or con.fileName ~= _constants.stationConFileName then
        if isSkipLogging then return nil end
        logger.err('getStationStreetEndEntities con.fileName =')
        logger.errorDebugPrint(con.fileName)
        return nil
    end

    local frozenEdgeIds_indexed = {}
    for _, edgeId in pairs(con.frozenEdges) do
        frozenEdgeIds_indexed[edgeId] = true
    end
    local frozenNodeIds_indexed = {}
    for _, nodeId in pairs(con.frozenNodes) do
        frozenNodeIds_indexed[nodeId] = true
    end
    return _getStationStreetEndEntities(frozenEdgeIds_indexed, frozenNodeIds_indexed)
end

local _getPosTanX2ListIndex_Nearest2_Point = function(posTanX2List, position)
    local result = 1

    local distance_power2 = transfUtils.getPositionsDistance_power2(
        transfUtils.getPositionsMiddle(
            posTanX2List[1].posTanX2[1][1],
            posTanX2List[1].posTanX2[2][1]
        ),
        position
    )
    for i = 2, #posTanX2List do
        local testDistance_power2 = transfUtils.getPositionsDistance_power2(
            transfUtils.getPositionsMiddle(
                posTanX2List[i].posTanX2[1][1],
                posTanX2List[i].posTanX2[2][1]
            ),
            position
        )
        if testDistance_power2 < distance_power2 then
            distance_power2 = testDistance_power2
            result = i
        end
    end

    return result
end

helpers.getIsTrackAlongPlatformLeft = function(platformEdgeList, midTrackEdge)
    logger.print('getIsTrackAlongPlatformLeft starting')
    -- logger.print('platformEdgeList =') logger.debugPrint(platformEdgeList)
    -- platform and track may have different lengths, so I check the central track segment,
    -- which is where the train bellies will stop.

    -- not the centre but the first of the two (nodes in the edge) is going to be my vehicleNode
    local _midTrackPoint = arrayUtils.cloneDeepOmittingFields(midTrackEdge.posTanX2[1][1])
    local _centrePlatforms = helpers.getCentralEdgePositions_OnlyOuterBounds(
        platformEdgeList,
        20 -- was 40, 20 is more accurate
    )
    -- logger.print('test centrePlatforms =') logger.debugPrint(centrePlatforms)

    local _centrePlatformIndex_Nearest2_TrackMid = _getPosTanX2ListIndex_Nearest2_Point(_centrePlatforms, _midTrackPoint)
    logger.print('_centrePlatformIndex_Nearest2_TrackMid =') logger.debugPrint(_centrePlatformIndex_Nearest2_TrackMid)

    local _platformWidth = _centrePlatforms[_centrePlatformIndex_Nearest2_TrackMid].width
    local _leftPlatforms = helpers.getShiftedEdgePositions(_centrePlatforms, _platformWidth * 0.5)
    local _rightPlatforms = helpers.getShiftedEdgePositions(_centrePlatforms, -_platformWidth * 0.5)
    -- logger.print('eee')

    local _midLeftPlatformPoint = transfUtils.getPositionsMiddle(
        _leftPlatforms[_centrePlatformIndex_Nearest2_TrackMid].posTanX2[1][1],
        _leftPlatforms[_centrePlatformIndex_Nearest2_TrackMid].posTanX2[2][1]
    )
    local _midRightPlatformPoint = transfUtils.getPositionsMiddle(
        _rightPlatforms[_centrePlatformIndex_Nearest2_TrackMid].posTanX2[1][1],
        _rightPlatforms[_centrePlatformIndex_Nearest2_TrackMid].posTanX2[2][1]
    )

    local result = transfUtils.getPositionsDistance_power2(
        _midTrackPoint,
        _midLeftPlatformPoint
    ) < transfUtils.getPositionsDistance_power2(
        _midTrackPoint,
        _midRightPlatformPoint
    )
    logger.print('getIsTrackAlongPlatformLeft is returning', result)

    return result
end

helpers.getIsTrackNorthOfPlatform = function(platformEdgeList, midTrackEdge)
    logger.print('getIsTrackNorthOfPlatform starting')
    -- logger.print('platformEdgeList =') logger.debugPrint(platformEdgeList)
    -- platform and track may have different lengths, so I check the central track segment,
    -- which is where the train bellies will stop.

    -- not the centre but the first of the two (nodes in the edge) is going to be my vehicleNode
    local _midTrackPos123 = arrayUtils.cloneDeepOmittingFields(midTrackEdge.posTanX2[1][1])
    logger.print('_midTrackPos =') logger.debugPrint(_midTrackPos123)
    local _centrePlatforms = helpers.getCentralEdgePositions_OnlyOuterBounds(
        platformEdgeList,
        20 -- was 40, 20 is more accurate
    )

    -- logger.print('_centrePlatforms =') logger.debugPrint(_centrePlatforms)
    local _centrePlatformIndex_Nearest2_TrackMid = _getPosTanX2ListIndex_Nearest2_Point(_centrePlatforms, _midTrackPos123)
    logger.print('_centrePlatformIndex_Nearest2_TrackMid =', tostring(_centrePlatformIndex_Nearest2_TrackMid))

    local _midPlatformSegment = _centrePlatforms[_centrePlatformIndex_Nearest2_TrackMid]
    logger.print('_midPlatformSegment =') logger.debugPrint(_midPlatformSegment)
    -- Now, I draw a perpendicular line from midTrackPos to midPlatformSegment.
    -- If it works, I check its intersection with midPlatformSegment;
    -- Otherwise, I use the segment mid point as fallback
    local _intersection123 = transfUtils.getPointToSegmentNormalIntersection_2D(_midTrackPos123, _midPlatformSegment.posTanX2[1][1], _midPlatformSegment.posTanX2[2][1])
    or transfUtils.getPositionsMiddle(_midPlatformSegment.posTanX2[1][1], _midPlatformSegment.posTanX2[2][1])
    logger.print('_intersection123 =') logger.debugPrint(_intersection123)

    local result = (_midTrackPos123[2] == _intersection123[2])
        and (_midTrackPos123[1] < _intersection123[1])
        or (_midTrackPos123[2] > _intersection123[2])
    logger.print('getIsTrackNorthOfPlatform is returning', result)

    return result
end

helpers.reversePosTanX2ListInPlace = function(posTanX2List)
    if type(posTanX2List) ~= 'table' then return posTanX2List end

    local result = {}
    for i = #posTanX2List, 1, -1 do
        result[#result+1] = posTanX2List[i]
    end

    for i = 1, #posTanX2List do
        -- LOLLO NOTE lua does not need the third variable for swapping since the assignments take place at the same time
        result[i].posTanX2[1], result[i].posTanX2[2] = result[i].posTanX2[2], result[i].posTanX2[1]
        for ii = 1, 2 do
            for iii = 1, 3 do
                result[i].posTanX2[ii][2][iii] = -result[i].posTanX2[ii][2][iii]
            end
        end
    end

    return result
end

return helpers
