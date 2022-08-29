package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local _constants = require('lollo_freestyle_train_station.constants')

local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local dummy = 123

local getCentralEdgePositions_OnlyOuterBounds = function(edgeLists, stepLength, isAddTerrainHeight)
    logger.print('getCentralEdgePositions_OnlyOuterBounds starting, stepLength =', stepLength, 'edgeLists =') logger.debugPrint(edgeLists)
    if type(edgeLists) ~= 'table' or type(stepLength) ~= 'number' or stepLength <= 0 then
        logger.err('getCentralEdgePositions_OnlyOuterBounds got wrong parameters, leaving')
        return {}
    end

    local firstRefEdge = nil
    local firstRefEdgeLength = 0
    local lengthUncovered = 0
    local previousNodeBetween = nil
    local previousRefEdge = nil
    local previousRefEdgeLength = 0

    local results = {}
    for _, _refEdge in pairs(edgeLists) do
        -- These should be identical but they are not quite so, so we average
        local _refEdgeLength = (transfUtils.getVectorLength(_refEdge.posTanX2[1][2]) + transfUtils.getVectorLength(_refEdge.posTanX2[2][2])) * 0.5
        if firstRefEdge == nil and _refEdgeLength > 0 then
            firstRefEdge = _refEdge
            firstRefEdgeLength = _refEdgeLength
        end

        if firstRefEdge ~= nil then
            -- local _nSplitsInEdge = math.floor((_oldEdgeLength + lengthUncovered) / stepLength)
            local _firstStep = stepLength - lengthUncovered
            local _firstStepPercent = _firstStep / _refEdgeLength
            local _nextStepPercent = stepLength / _refEdgeLength
            logger.print('_refEdgeLength, firstStepPercent, nextStepPercent =', _refEdgeLength, _firstStepPercent, _nextStepPercent)
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
                    logger.isExtendedLog()
                )
                logger.print('nodeBetween =') --logger.debugPrint(nodeBetween)
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

                if isAddTerrainHeight then
                    newEdgeResults[#newEdgeResults].terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                        newEdgeResults[#newEdgeResults].posTanX2[1][1][1],
                        newEdgeResults[#newEdgeResults].posTanX2[1][1][2]
                    ))
                    -- edgeResults[#edgeResults].terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                    --     edgeResults[#edgeResults].posTanX2[2][1][1],
                    --     edgeResults[#edgeResults].posTanX2[2][1][2]
                    -- ))
                end
                newEdgeResults[#newEdgeResults].catenary = _refEdge.catenary -- this is not totally accurate since we ignore the inner bounds
                newEdgeResults[#newEdgeResults].era = _refEdge.era or _constants.eras.era_c.prefix -- idem
                newEdgeResults[#newEdgeResults].trackType = _refEdge.trackType -- idem
                newEdgeResults[#newEdgeResults].trackTypeName = _refEdge.trackTypeName -- idem
                newEdgeResults[#newEdgeResults].type = _refEdge.type -- idem
                newEdgeResults[#newEdgeResults].typeIndex = _refEdge.typeIndex -- idem
                newEdgeResults[#newEdgeResults].width = _refEdge.width or 0 -- idem

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
    local _lastRefEdgePosition = previousRefEdge.posTanX2[2][1]
    if edgeUtils.isXYZVeryClose(_lastRefEdgePosition, results[#results].posTanX2[2][1], 3) then
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
            catenary = previousRefEdge.catenary, -- this is not totally accurate since we ignore the inner bounds
            era = previousRefEdge.era or _constants.eras.era_c.prefix, -- idem
            trackType = previousRefEdge.trackType, -- idem
            trackTypeName = previousRefEdge.trackTypeName, -- idem
            type = previousRefEdge.type, -- idem
            typeIndex = previousRefEdge.typeIndex, -- idem
            width = previousRefEdge.width or 0, -- idem
        }
        if isAddTerrainHeight then
            results[#results].terrainHeight1 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
                results[#results].posTanX2[1][1][1],
                results[#results].posTanX2[1][1][2]
            ))
            -- results[#results].terrainHeight2 = api.engine.terrain.getBaseHeightAt(api.type.Vec2f.new(
            --     results[#results].posTanX2[2][1][1],
            --     results[#results].posTanX2[2][1][2]
            -- ))
        end
    else
        logger.err('there is a piece missing')
    end
    logger.print('getCentralEdgePositions_OnlyOuterBounds results =') logger.debugPrint(results)
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

local splits2 = getCentralEdgePositions_OnlyOuterBounds(edgeLists2, 2)

local edgeLists3 = {
    {
      catenary = false,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -139.9704284668, 2353.1716308594, 110.11576080322, },
          { -0.35029852390289, -2.0228176116943, -0.013037061318755, },
        },
        {
          { -140.3207244873, 2351.1489257813, 110.10293579102, },
          { -0.350301861763, -2.0228197574615, -0.012617093510926, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -140.3207244873, 2351.1489257813, 110.10293579102, },
          { -3.228590965271, -18.64351272583, -0.11628666520119, },
        },
        {
          { -143.54928588867, 2332.5056152344, 110.00344085693, },
          { -3.2285737991333, -18.643692016602, -0.083605222404003, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -143.54928588867, 2332.5056152344, 110.00344085693, },
          { -1.8746665716171, -10.825435638428, -0.048545408993959, },
        },
        {
          { -145.42390441895, 2321.6799316406, 109.95977020264, },
          { -1.8746734857559, -10.825554847717, -0.038956969976425, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -145.42390441895, 2321.6799316406, 109.95977020264, },
          { -1.874635219574, -10.825332641602, -0.038956079632044, },
        },
        {
          { -147.2985534668, 2310.8542480469, 109.92517089844, },
          { -1.8746440410614, -10.82536315918, -0.030422085896134, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -147.2985534668, 2310.8542480469, 109.92517089844, },
          { -0.51127368211746, -2.95241355896, -0.0082970531657338, },
        },
        {
          { -147.8098449707, 2307.9020996094, 109.91717529297, },
          { -0.51127403974533, -2.9524164199829, -0.0077123241499066, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -147.8098449707, 2307.9020996094, 109.91717529297, },
          { -0.34084266424179, -1.9682388305664, -0.00514144776389, },
        },
        {
          { -148.15069580078, 2305.9338378906, 109.91216278076, },
          { -0.34085232019424, -1.9682669639587, -0.0048896786756814, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -148.15069580078, 2305.9338378906, 109.91216278076, },
          { -4.1522178649902, -23.977167129517, -0.059565424919128, },
        },
        {
          { -152.30285644531, 2281.9567871094, 109.86915588379, },
          { -4.1521496772766, -23.977235794067, -0.028357073664665, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -152.30285644531, 2281.9567871094, 109.86915588379, },
          { -3.2737874984741, -18.9049949646, -0.022358303889632, },
        },
        {
          { -155.57662963867, 2263.0517578125, 109.85378265381, },
          { -3.2737681865692, -18.905010223389, -0.009324349462986, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -155.57662963867, 2263.0517578125, 109.85378265381, },
          { -0.83014333248138, -4.7938241958618, -0.0023644149769098, },
        },
        {
          { -156.40676879883, 2258.2578125, 109.85173034668, },
          { -0.83013105392456, -4.7938265800476, -0.0017540538683534, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -156.40676879883, 2258.2578125, 109.85173034668, },
          { -0.38651180267334, -2.2320215702057, -0.00081669329665601, },
        },
        {
          { -156.79328918457, 2256.0258789063, 109.85097503662, },
          { -0.38652482628822, -2.2320194244385, -0.00069818960037082, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -156.79328918457, 2256.0258789063, 109.85097503662, },
          { -0.38929349184036, -2.2480072975159, -0.00070319068618119, },
        },
        {
          { -157.18257141113, 2253.7778320313, 109.85032653809, },
          { -0.38928410410881, -2.2480089664459, -0.00059283361770213, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.18257141113, 2253.7778320313, 109.85032653809, },
          { -0.094450138509274, -0.54542362689972, -0.00014383638335858, },
        },
        {
          { -157.27702331543, 2253.232421875, 109.85018920898, },
          { -0.094452515244484, -0.54542320966721, -0.00013722422590945, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.27702331543, 2253.232421875, 109.85018920898, },
          { -0.094370432198048, -0.54494917392731, -0.00013710495841224, },
        },
        {
          { -157.37138366699, 2252.6875, 109.85005187988, },
          { -0.094362020492554, -0.54495060443878, -0.00013150545419194, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.37138366699, 2252.6875, 109.85005187988, },
          { -0.18873094022274, -1.0899410247803, -0.00026302054175176, },
        },
        {
          { -157.5601348877, 2251.5974121094, 109.84980010986, },
          { -0.18874357640743, -1.0899388790131, -0.00023935954959597, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.5601348877, 2251.5974121094, 109.84980010986, },
          { -0.37784859538078, -2.1819648742676, -0.00047917745541781, },
        },
        {
          { -157.93798828125, 2249.4155273438, 109.84936523438, },
          { -0.37785297632217, -2.1819641590118, -0.00039299696800299, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.93798828125, 2249.4155273438, 109.84936523438, },
          { -0.77880698442459, -4.4973282814026, -0.00081002083607018, },
        },
        {
          { -158.716796875, 2244.9182128906, 109.84871673584, },
          { -0.77880668640137, -4.4973282814026, -0.00049793208017945, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = false,
      era = "era_c_",
      posTanX2 = {
        {
          { -158.716796875, 2244.9182128906, 109.84871673584, },
          { -1.1986937522888, -6.9220266342163, -0.00076638802420348, },
        },
        {
          { -159.89352416992, 2237.9924316406, 109.84844207764, },
          { -1.1550387144089, -6.9294452667236, -3.673996161524e-06, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 0,
      typeIndex = -1,
      width = 2.5,
    },
  }

local splits3 = getCentralEdgePositions_OnlyOuterBounds(edgeLists2, 9)

local vec1 = { 92.263687133789, 602.89776611328, 13.625541687012, }
local vec2 = { 91.385019392729, 602.56420214167, 13.649062242507, }

local res = edgeUtils.isXYZVeryClose(vec1, vec2, 3)

local dummy2 = 123
