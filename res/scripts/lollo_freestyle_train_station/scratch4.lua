package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local _constants = require('lollo_freestyle_train_station.constants')

local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local dummy = 123

local function getCentralEdgePositions(edgeLists, stepLength, addTerrainHeight)
    logger.print('getCentralEdgePositions starting, stepLength =', stepLength, 'edgeLists =') --logger.debugPrint(edgeLists)
    if type(edgeLists) ~= 'table' then return {} end

    local leadingIndex = 0
    local lengthUncovered = 0
    local previousNodeBetween = nil
    local previousEdgeLength = 0
    local previousPel = nil

    local results = {}
    for _, pel in pairs(edgeLists) do
        local _edgeLength = (transfUtils.getVectorLength(pel.posTanX2[1][2]) + transfUtils.getVectorLength(pel.posTanX2[2][2])) * 0.5
        local _nSplitsInEdge = math.floor((_edgeLength + lengthUncovered) / stepLength)
        local _firstStepPercent = (stepLength - lengthUncovered) / _edgeLength
        local _nextStepPercent = stepLength / _edgeLength
        if _nSplitsInEdge > 0 then leadingIndex = leadingIndex + 1 end
        logger.print('edgeLength, _nSplitsInEdge, firstStepPercent, nextStepPercent, leadingIndex =', _edgeLength, _nSplitsInEdge, _firstStepPercent, _nextStepPercent, leadingIndex)
        if _firstStepPercent < 0 then
            logger.err('firstStep cannot be < 0; edgeLength, _nSplitsInEdge, lengthUncovered =', _edgeLength, _nSplitsInEdge, lengthUncovered)
            return {}
        end

        local edgeResults = {}
        local lastCoveredLengthInEdge = -lengthUncovered
        for i = 1, _nSplitsInEdge do
            -- logger.print('i == ', i)
            -- logger.print('i / _nSplitsInEdge =', i / _nSplitsInEdge)
            local nodeBetween = edgeUtils.getNodeBetween(
                transfUtils.oneTwoThree2XYZ(pel.posTanX2[1][1]),
                transfUtils.oneTwoThree2XYZ(pel.posTanX2[2][1]),
                transfUtils.oneTwoThree2XYZ(pel.posTanX2[1][2]),
                transfUtils.oneTwoThree2XYZ(pel.posTanX2[2][2]),
                _firstStepPercent + (i-1) * _nextStepPercent
            )
            -- logger.print('nodeBetween =') logger.debugPrint(nodeBetween)
            if nodeBetween == nil then
                -- logger.err('nodeBetween not found; pel =')
                -- logger.errorDebugPrint(pel)
                return {}
            end
            local newEdgeLength = nodeBetween.refDistance0 - lastCoveredLengthInEdge
            logger.print('newEdgeLength =', newEdgeLength)
            logger.print('lastCoveredLengthInEdge =', lastCoveredLengthInEdge)
            if previousNodeBetween == nil then
                edgeResults[#edgeResults+1] = {
                    posTanX2 = {
                        {
                            {
                                pel.posTanX2[1][1][1],
                                pel.posTanX2[1][1][2],
                                pel.posTanX2[1][1][3],
                            },
                            {
                                pel.posTanX2[1][2][1] * newEdgeLength / _edgeLength,
                                pel.posTanX2[1][2][2] * newEdgeLength / _edgeLength,
                                pel.posTanX2[1][2][3] * newEdgeLength / _edgeLength,
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
            edgeResults[#edgeResults].catenary = pel.catenary
            edgeResults[#edgeResults].leadingIndex = pel.leadingIndex or leadingIndex
            if addTerrainHeight then
                edgeResults[#edgeResults].terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    edgeResults[#edgeResults].posTanX2[1][1][1],
                    edgeResults[#edgeResults].posTanX2[1][1][2]
                ))
                -- edgeResults[#edgeResults].terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                --     edgeResults[#edgeResults].posTanX2[2][1][1],
                --     edgeResults[#edgeResults].posTanX2[2][1][2]
                -- ))
            end
            edgeResults[#edgeResults].trackType = pel.trackType
            edgeResults[#edgeResults].trackTypeName = pel.trackTypeName
            edgeResults[#edgeResults].type = pel.type
            edgeResults[#edgeResults].typeIndex = pel.typeIndex
            edgeResults[#edgeResults].width = pel.width or 0
            edgeResults[#edgeResults].era = pel.era or _constants.eras.era_c.prefix

            lastCoveredLengthInEdge = nodeBetween.refDistance0
            previousNodeBetween = nodeBetween
        end

        for _, value in pairs(edgeResults) do
            results[#results+1] = value
        end

        if _nSplitsInEdge < 1 then
            lengthUncovered = lengthUncovered + _edgeLength
        else
            lengthUncovered = (1 - _firstStepPercent - (_nSplitsInEdge-1) * _nextStepPercent) * _edgeLength
        end
        logger.print('lengthUncovered =', lengthUncovered)

        previousEdgeLength = _edgeLength
        previousPel = pel
    end

    if lengthUncovered > 0 and previousPel ~= nil and previousEdgeLength ~= 0 then -- LOLLO TODO see to the roundings!
        results[#results+1] = {
            catenary = previousPel.catenary,
            leadingIndex = previousPel.leadingIndex or leadingIndex,
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
                        previousPel.posTanX2[2][1][1],
                        previousPel.posTanX2[2][1][2],
                        previousPel.posTanX2[2][1][3],
                    },
                    {
                        previousPel.posTanX2[2][2][1] * lengthUncovered / previousEdgeLength,
                        previousPel.posTanX2[2][2][2] * lengthUncovered / previousEdgeLength,
                        previousPel.posTanX2[2][2][3] * lengthUncovered / previousEdgeLength,
                    }
                },
            },
            trackType = previousPel.trackType,
            trackTypeName = previousPel.trackTypeName,
            type = previousPel.type,
            typeIndex = previousPel.typeIndex,
            width = previousPel.width or 0,
            era = previousPel.era or _constants.eras.era_c.prefix,
        }
    end
    -- logger.print('getCentralEdgePositions results =') logger.debugPrint(results)
    return results
end

local edgeLists1 = {
    {
        leadingIndex = 1,
        posTanX2 = {
            {
                {0, 0, 0}, {10, 0, 0}
            },
            {
                {10, 0, 0}, {10, 0, 0}
            },
        },
    },
    {
        leadingIndex = 2,
        posTanX2 = {
            {
                {10, 0, 0}, {10, 0, 0}
            },
            {
                {20, 0, 0}, {10, 0, 0}
            },
        },
    },
}
-- local splits1 = getCentralEdgePositions(edgeLists1, 7)


local edgeLists2 = {
    {
        catenary = false,
        era = "era_a_",
        leadingIndex = 1,
        posTanX2 = {
            {
                { 72.69287109375, 595.46820068359, 14.149421691895, },
                { 8.4114667253264, 3.1932004397108, -0.22516182892976, },
            },
            {
                { 81.104337819076, 598.66140132421, 13.924259935211, },
                { 8.4114666775778, 3.1932006719572, -0.2251617210165, },
            },
        },
        terrainHeight1 = 14.383262634277,
        trackType = 6,
        trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
        type = 0,
        typeIndex = -1,
        width = 5,
    },
    {
        catenary = false,
        era = "era_a_",
        leadingIndex = 2,
        posTanX2 = {
            {
                { 81.104337819076, 598.66140132421, 13.924259935211, },
                { 8.4114666775778, 3.1932006719572, -0.2251617210165, },
            },
            {
                { 89.515804545154, 601.85460200782, 13.699098189412, },
                { 8.4114666994519, 3.1932006116084, -0.22516175971086, },
            },
        },
        terrainHeight1 = 13.985610961914,
        trackType = 6,
        trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
        type = 0,
        typeIndex = -1,
        width = 5,
    },
    {
        posTanX2 = {
            {
                { 89.515804545154, 601.85460200782, 13.699098189412, },
                { 2.7478825798883, 1.043164129188, -0.073556503196616, },
            },
            {
                { 92.263687133789, 602.89776611328, 13.625541687012, },
                { 2.7478825886346, 1.0431640731434, -0.073556500710351, },
            },
        },
    },
  }

local splits2 = getCentralEdgePositions(edgeLists2, 2)

local dummy2 = 123
