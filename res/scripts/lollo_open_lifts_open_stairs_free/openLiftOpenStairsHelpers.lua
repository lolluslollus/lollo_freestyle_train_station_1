local _arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local _constants = require('lollo_freestyle_train_station.constants')

local _liftHeights = {}
for i = 8, 40, 2 do
    _liftHeights[#_liftHeights+1] = i
end
local _pedestrianBridgeHeights = {}
for i = 1, 30, 1 do
    _pedestrianBridgeHeights[#_pedestrianBridgeHeights+1] = i
end

local _paramHelpers = {
    getSliderValues = function(max, step)
        local results = {}
        for i = -max, max, step do
            results[#results+1] = tostring(i)
        end
        return results
    end,
    lift_v1 = {
        heights = _liftHeights,
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
        bridgeModes = {0, 1, 2, 3},
        maxBridgeChunkYAngleDeg = 15,
        bridgeChunkYAngleStep = 1,
        baseModes = {-1, 0, 1, 2, 3,},
    },
    lift_v2 = {
        bridgeChunkLengths = {-1, --[[ 0, 1, ]] 2, 3},
        heights = _liftHeights,
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
        baseModes = {-1, 0, 1, --[[2, 3,]]},
    },
    pedestrianBridgePillar = {
        heights = _pedestrianBridgeHeights,
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
    },
    stairs = {
        heights = {2, 4, 6, 8, 10},
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
        bridgeChunkLengths = {-2, -1, 4, 8, 16, 32, 64, 0, 1, 2, 3},
        maxBridgeChunkZAngleDeg = 90,
        bridgeChunkZAngleStep = 5,
        maxBridgeChunkYAngleDeg = 15,
        bridgeChunkYAngleStep = 1,
        stairsBases = {-1, 99, 0, 1, 2, 3, 98},
        terrainAlignmentTypes = {'EQUAL', 'LESS', 'GREATER'},
    },
    twinStairs = {
        bridgeChunkLengths = {-1, --[[ 0, 1, ]] 2, 3},
    },
}

local public = {
    paramReaders = {
        lift_v1 = {
            getHeight = function(params)
                return _paramHelpers.lift_v1.heights[params.lift_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.lift_v1.eraPrefixes[params.era_prefix + 1] or _paramHelpers.lift_v1.eraPrefixes[1]
            end,
            getBridgeMode = function(params)
                return _paramHelpers.lift_v1.bridgeModes[params.lift_bridge_mode + 1] or 2
            end,
            getSinYAngle = function(params)
                local yAngleDeg = (math.floor(params.bridge_chunk_y_angle * _paramHelpers.lift_v1.bridgeChunkYAngleStep) - _paramHelpers.lift_v1.maxBridgeChunkYAngleDeg) or 0
                return math.sin(yAngleDeg * math.pi / 180)
            end,
            getBaseMode = function(params)
                return _paramHelpers.lift_v1.baseModes[params.lift_base_mode + 1] or -1
            end,
        },
        lift_v2 = {
            getHeight = function(params)
                return _paramHelpers.lift_v2.heights[params.lift_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.lift_v2.eraPrefixes[params.era_prefix + 1] or _paramHelpers.lift_v2.eraPrefixes[1]
            end,
            getBridgeChunkLengthNorth = function(params)
                return _paramHelpers.lift_v2.bridgeChunkLengths[params.bridge_chunk_north + 1] or -1
            end,
            getBridgeChunkLengthEast = function(params)
                return _paramHelpers.lift_v2.bridgeChunkLengths[params.bridge_chunk_east + 1] or -1
            end,
            getBridgeChunkLengthSouth = function(params)
                return _paramHelpers.lift_v2.bridgeChunkLengths[params.bridge_chunk_south + 1] or -1
            end,
            getBridgeChunkLengthWest = function(params)
                return _paramHelpers.lift_v2.bridgeChunkLengths[params.bridge_chunk_west + 1] or -1
            end,
            getBaseTowardEast = function(params)
                return _paramHelpers.lift_v2.baseModes[params.lift_base_mode_east + 1] or -1
            end,
            getBaseTowardWest = function(params)
                return _paramHelpers.lift_v2.baseModes[params.lift_base_mode_west + 1] or -1
            end,
        },
        pedestrianBridgePillar = {
            getHeight = function(params)
                return _paramHelpers.pedestrianBridgePillar.heights[params.pedestrian_bridge_pillar_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.pedestrianBridgePillar.eraPrefixes[params.era_prefix + 1] or _paramHelpers.pedestrianBridgePillar.eraPrefixes[1]
            end,
        },
        stairs = {
            getHeight = function(params)
                return _paramHelpers.stairs.heights[params.stairs_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.stairs.eraPrefixes[params.era_prefix + 1] or _paramHelpers.stairs.eraPrefixes[1]
            end,
            getBridgeChunkLength = function(params)
                return _paramHelpers.stairs.bridgeChunkLengths[params.bridge_chunk_length + 1] or -1
            end,
            getBridgeChunkZAngle = function(params)
                return (math.floor(params.bridge_chunk_z_angle * _paramHelpers.stairs.bridgeChunkZAngleStep) - _paramHelpers.stairs.maxBridgeChunkZAngleDeg) or 0
            end,
            getBridgeChunkYAngle = function(params)
                return -(math.floor(params.bridge_chunk_y_angle * _paramHelpers.stairs.bridgeChunkYAngleStep) - _paramHelpers.stairs.maxBridgeChunkYAngleDeg) or 0
            end,
            getSinYAngle = function(params)
                local yAngleDeg = (math.floor(params.bridge_chunk_y_angle * _paramHelpers.stairs.bridgeChunkYAngleStep) - _paramHelpers.stairs.maxBridgeChunkYAngleDeg) or 0
                return math.sin(yAngleDeg * math.pi / 180)
            end,
            getTerrainAlignmentType = function(params)
                return _paramHelpers.stairs.terrainAlignmentTypes[params.terrain_alignment_type + 1] or _paramHelpers.stairs.terrainAlignmentTypes[1]
            end,
            getStairsBase = function(params)
                return _paramHelpers.stairs.stairsBases[params.stairs_base + 1] or -1
            end,
        },
        twinStairs_v1 = {
            getHeight = function(params)
                return _paramHelpers.stairs.heights[params.stairs_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.stairs.eraPrefixes[params.era_prefix + 1] or _paramHelpers.stairs.eraPrefixes[1]
            end,
            getBridgeChunkLengthNorth = function(params)
                return _paramHelpers.twinStairs.bridgeChunkLengths[params.bridge_chunk_length_north + 1] or -1
            end,
            getBridgeChunkLengthSouth = function(params)
                return _paramHelpers.twinStairs.bridgeChunkLengths[params.bridge_chunk_length_south + 1] or -1
            end,
            getTerrainAlignmentType = function(params)
                return _paramHelpers.stairs.terrainAlignmentTypes[params.terrain_alignment_type + 1] or _paramHelpers.stairs.terrainAlignmentTypes[1]
            end,
            getStairsBase = function(params)
                return _paramHelpers.stairs.stairsBases[params.stairs_base + 1] or -1
            end,
        },
        twinStairs_v2 = {
            getHeight = function(params)
                return _paramHelpers.stairs.heights[params.stairs_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.stairs.eraPrefixes[params.era_prefix + 1] or _paramHelpers.stairs.eraPrefixes[1]
            end,
            getBridgeChunkLengthNorth = function(params)
                return _paramHelpers.twinStairs.bridgeChunkLengths[params.bridge_chunk_length_north + 1] or -1
            end,
            getBridgeChunkLengthSouth = function(params)
                return _paramHelpers.twinStairs.bridgeChunkLengths[params.bridge_chunk_length_south + 1] or -1
            end,
            getTerrainAlignmentType = function(params)
                return _paramHelpers.stairs.terrainAlignmentTypes[params.terrain_alignment_type + 1] or _paramHelpers.stairs.terrainAlignmentTypes[1]
            end,
            getStairsBaseEast = function(params)
                return _paramHelpers.stairs.stairsBases[params.stairs_base_east + 1] or -1
            end,
            getStairsBaseWest = function(params)
                return _paramHelpers.stairs.stairsBases[params.stairs_base_west + 1] or -1
            end,
        },
    },
    paramValues = {
        lift_v1 = {
            bridge_chunk_y_angle = _paramHelpers.getSliderValues(_paramHelpers.lift_v1.maxBridgeChunkYAngleDeg, _paramHelpers.lift_v1.bridgeChunkYAngleStep),
            bridge_chunk_y_angle_DefaultIndex = math.floor(_paramHelpers.lift_v1.maxBridgeChunkYAngleDeg / _paramHelpers.lift_v1.bridgeChunkYAngleStep),
            era_prefix = {'A', 'B', 'C'},
            lift_base_mode = {_('SimpleConnection'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            lift_bridge_mode = {_('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            lift_height = _arrayUtils.map(_paramHelpers.lift_v1.heights, function(int) return tostring(int) .. 'm' end)
        },
        lift_v2 = {
            bridge_chunk_north = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_east = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_south = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_west = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            era_prefix = {'A', 'B', 'C'},
            lift_base_mode_east = {_('SimpleConnection'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), --[[_('EdgeWithBridge'), _('SnappyEdgeWithBridge')]]},
            lift_base_mode_west = {_('SimpleConnection'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), --[[_('EdgeWithBridge'), _('SnappyEdgeWithBridge')]]},
            lift_height = _arrayUtils.map(_paramHelpers.lift_v2.heights, function(int) return tostring(int) .. 'm' end)
        },
        pedestrianBridgePillar = {
            era_prefix = {'A', 'B', 'C'},
            pedestrian_bridge_pillar_height = _arrayUtils.map(_paramHelpers.pedestrianBridgePillar.heights, function(int) return tostring(int) .. 'm' end)
        },
        stairs = {
            bridge_chunk_length = {_('NoRailing0'), '0', '4 m', '8 m', '16 m', '32 m', '64 m', _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_z_angle = _paramHelpers.getSliderValues(_paramHelpers.stairs.maxBridgeChunkZAngleDeg, _paramHelpers.stairs.bridgeChunkZAngleStep),
            bridge_chunk_z_angle_DefaultIndex = math.floor(_paramHelpers.stairs.maxBridgeChunkZAngleDeg / _paramHelpers.stairs.bridgeChunkZAngleStep),
            bridge_chunk_y_angle = _paramHelpers.getSliderValues(_paramHelpers.stairs.maxBridgeChunkYAngleDeg, _paramHelpers.stairs.bridgeChunkYAngleStep),
            bridge_chunk_y_angle_DefaultIndex = math.floor(_paramHelpers.stairs.maxBridgeChunkYAngleDeg / _paramHelpers.stairs.bridgeChunkYAngleStep),
            era_prefix = {'A', 'B', 'C'},
            flat_sloped_terrain = {_('TerrainAlignmentTypeFlat'), _('TerrainAlignmentTypeSloped')},
            stairs_base = {_('NO'), _('Model'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge'), _('ModelRaised'),},
            stairs_height = _arrayUtils.map(_paramHelpers.stairs.heights, function(int) return tostring(int) .. 'm' end),
            terrain_alignment_type = {'EQUAL', 'LESS', 'GREATER'},
        },
        twinStairs_v1 = {
            bridge_chunk_length_north = {'0', --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_length_south = {'0', --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            era_prefix = {'A', 'B', 'C'},
            flat_sloped_terrain = {_('TerrainAlignmentTypeFlat'), _('TerrainAlignmentTypeSloped')},
            stairs_base = {_('NO'), _('Model'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge'), _('ModelRaised'),},
            stairs_height = _arrayUtils.map(_paramHelpers.stairs.heights, function(int) return tostring(int) .. 'm' end),
            terrain_alignment_type = {'EQUAL', 'LESS', 'GREATER'},
        },
        twinStairs_v2 = {
            bridge_chunk_length_north = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_length_south = {_('None'), --[[ _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), ]] _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            era_prefix = {'A', 'B', 'C'},
            flat_sloped_terrain = {_('TerrainAlignmentTypeFlat'), _('TerrainAlignmentTypeSloped')},
            stairs_base_east = {_('None'), _('Model'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge'), _('ModelRaised'),},
            stairs_base_west = {_('None'), _('Model'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge'), _('ModelRaised'),},
            stairs_height = _arrayUtils.map(_paramHelpers.stairs.heights, function(int) return tostring(int) .. 'm' end),
            terrain_alignment_type = {'EQUAL', 'LESS', 'GREATER'},
        },
    },
}

public.getOpenLiftParamsMetadata = function()
    --[[
        LOLLO NOTE
        In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
        which are available in the present game.
        In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
        including those from inactive mods.
        This is why we read the data from the table that we set in postRunFn, and not from the api.
    ]]
    local _paramValues = public.paramValues.lift_v2
    local metadata_sorted = {
        {
            key = 'lift_height',
            name = _('BridgeHeight'),
            values = _paramValues.lift_height,
        },
        {
            key = 'era_prefix',
            name = _('Era'),
            values = _paramValues.era_prefix,
        },
        {
            key = 'bridge_chunk_north', -- do not rename this param or chenge its values
            name = _('TopPlatformNorthLength'),
            tooltip = _('TopPlatformLengthTooltip_Lift'),
            values = _paramValues.bridge_chunk_north,
        },
        {
            key = 'bridge_chunk_east', -- do not rename this param or chenge its values
            name = _('TopPlatformEastLength'),
            tooltip = _('TopPlatformLengthTooltip_Lift'),
            values = _paramValues.bridge_chunk_east,
        },
        {
            key = 'bridge_chunk_south', -- do not rename this param or chenge its values
            name = _('TopPlatformSouthLength'),
            tooltip = _('TopPlatformLengthTooltip_Lift'),
            values = _paramValues.bridge_chunk_south,
        },
        {
            key = 'bridge_chunk_west', -- do not rename this param or chenge its values
            name = _('TopPlatformWestLength'),
            tooltip = _('TopPlatformLengthTooltip_Lift'),
            values = _paramValues.bridge_chunk_west,
        },
        {
            key = 'lift_base_mode_east', -- do not rename this param or chenga its values
            name = _('BaseTowardEast'),
            tooltip = _('BaseTooltip_Lift'),
            values = _paramValues.lift_base_mode_east,
        },        {
            key = 'lift_base_mode_west', -- do not rename this param or chenga its values
            name = _('BaseTowardWest'),
            tooltip = _('BaseTooltip_Lift'),
            values = _paramValues.lift_base_mode_west,
        },
    }
    -- add defaultIndex wherever not present
    for _, record in pairs(metadata_sorted) do
        record.defaultIndex = record.defaultIndex or 0
    end
    local metadata_indexed = {}
    for _, record in pairs(metadata_sorted) do
        metadata_indexed[record.key] = record
    end
    -- logger.print('metadata_sorted =') logger.debugPrint(metadata_sorted)
    -- logger.print('metadata_indexed =') logger.debugPrint(metadata_indexed)
    return metadata_sorted, metadata_indexed
end

public.getOpenStairsParamsMetadata = function()
    --[[
        LOLLO NOTE
        In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
        which are available in the present game.
        In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
        including those from inactive mods.
        This is why we read the data from the table that we set in postRunFn, and not from the api.
    ]]
    local _paramValues = public.paramValues.stairs
    local metadata_sorted = {
        {
            key = 'stairs_height',
            name = _('OpenStairsFreeHeight'),
            values = _paramValues.stairs_height,
            defaultIndex = 1,
        },
        {
            key = 'era_prefix',
            name = _('Era'),
            values = _paramValues.era_prefix,
        },
        {
            key = 'bridge_chunk_length', -- do not rename this param or chenga its values
            name = _('TopPlatformLength'),
            tooltip = _('TopPlatformLengthTooltip_Stairs'),
            values = _paramValues.bridge_chunk_length,
        },
        {
            key = 'bridge_chunk_z_angle',
            name = _('BridgeZAngle'),
            values = _paramValues.bridge_chunk_z_angle,
            uiType = 'SLIDER',
            defaultIndex = _paramValues.bridge_chunk_z_angle_DefaultIndex,
        },
        {
            key = 'bridge_chunk_y_angle',
            name = _('BridgeYAngle'),
            values = _paramValues.bridge_chunk_y_angle,
            uiType = 'SLIDER',
            defaultIndex = _paramValues.bridge_chunk_y_angle_DefaultIndex,
        },
        {
            key = 'stairs_base', -- do not rename this param or chenga its values
            name = _('StairsBase'),
            tooltip = _('BaseTooltip_Stairs'),
            values = _paramValues.stairs_base,
        },
        {
            key = 'terrain_alignment_type',
            name = _('TerrainAlignmentType'),
            values = _paramValues.terrain_alignment_type,
        },
        {
            key = 'flat_sloped_terrain',
            name = _('FlatSlopedTerrain'),
            values = _paramValues.flat_sloped_terrain,
        },
    }
    -- add defaultIndex wherever not present
    for _, record in pairs(metadata_sorted) do
        record.defaultIndex = record.defaultIndex or 0
    end
    local metadata_indexed = {}
    for _, record in pairs(metadata_sorted) do
        metadata_indexed[record.key] = record
    end
    -- logger.print('metadata_sorted =') logger.debugPrint(metadata_sorted)
    -- logger.print('metadata_indexed =') logger.debugPrint(metadata_indexed)
    return metadata_sorted, metadata_indexed
end

public.getOpenTwinStairsParamsMetadata = function()
    --[[
        LOLLO NOTE
        In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
        which are available in the present game.
        In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
        including those from inactive mods.
        This is why we read the data from the table that we set in postRunFn, and not from the api.
    ]]
    local _paramValues = public.paramValues.twinStairs_v2
    local metadata_sorted = {
        {
            key = 'stairs_height',
            name = _('OpenStairsFreeHeight'),
            values = _paramValues.stairs_height,
            defaultIndex = 1,
        },
        {
            key = 'era_prefix',
            name = _('Era'),
            values = _paramValues.era_prefix,
        },
        {
            key = 'bridge_chunk_length_north', -- do not rename this param or chenga its values
            name = _('TopPlatformNorthLength'),
            tooltip = _('TopPlatformLengthTooltip_TwinStairs'),
            values = _paramValues.bridge_chunk_length_north,
        },
        {
            key = 'bridge_chunk_length_south', -- do not rename this param or chenga its values
            name = _('TopPlatformSouthLength'),
            tooltip = _('TopPlatformLengthTooltip_TwinStairs'),
            values = _paramValues.bridge_chunk_length_south,
        },
        {
            key = 'stairs_base_east', -- do not rename this param or chenga its values
            name = _('StairsBaseEast'),
            tooltip = _('BaseTooltip_TwinStairs'),
            values = _paramValues.stairs_base_east,
        },
        {
            key = 'stairs_base_west', -- do not rename this param or chenga its values
            name = _('StairsBaseWest'),
            tooltip = _('BaseTooltip_TwinStairs'),
            values = _paramValues.stairs_base_west,
        },
        {
            key = 'terrain_alignment_type',
            name = _('TerrainAlignmentType'),
            values = _paramValues.terrain_alignment_type,
        },
        {
            key = 'flat_sloped_terrain',
            name = _('FlatSlopedTerrain'),
            values = _paramValues.flat_sloped_terrain,
        },
    }
    -- add defaultIndex wherever not present
    for _, record in pairs(metadata_sorted) do
        record.defaultIndex = record.defaultIndex or 0
    end
    local metadata_indexed = {}
    for _, record in pairs(metadata_sorted) do
        metadata_indexed[record.key] = record
    end
    -- logger.print('metadata_sorted =') logger.debugPrint(metadata_sorted)
    -- logger.print('metadata_indexed =') logger.debugPrint(metadata_indexed)
    return metadata_sorted, metadata_indexed
end

return public
