local _arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local _constants = require('lollo_freestyle_train_station.constants')

local _liftHeights = {}
for i = 8, 40, 2 do
    _liftHeights[#_liftHeights+1] = i
end

local _paramHelpers = {
    getSliderValues = function(max, step)
        local results = {}
        for i = -max, max, step do
            results[#results+1] = tostring(i)
        end
        return results
    end,
    lift = {
        heights = _liftHeights,
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
        bridgeModes = {0, 1, 2, 3},
        maxBridgeChunkYAngleDeg = 15,
        bridgeChunkYAngleStep = 1,
        baseModes = {-1, 0, 1, 2, 3,},
    },
    stairs = {
        heights = {2, 4, 6, 8, 10},
        eraPrefixes = {_constants.eras.era_a.prefix, _constants.eras.era_b.prefix, _constants.eras.era_c.prefix},
        bridgeChunkLengths = {-2, -1, 4, 8, 16, 32, 64, 0, 1, 2, 3},
        maxBridgeChunkZAngleDeg = 90,
        bridgeChunkZAngleStep = 5,
        maxBridgeChunkYAngleDeg = 15,
        bridgeChunkYAngleStep = 1,
        stairsBases = {-1, 99, 0, 1, 2, 3,},
        terrainAlignmentTypes = {'EQUAL', 'LESS', 'GREATER'},
    },
}

local public = {
    paramReaders = {
        lift = {
            getHeight = function(params)
                return _paramHelpers.lift.heights[params.lift_height + 1] or 8
            end,
            getEraPrefix = function(params)
                return _paramHelpers.lift.eraPrefixes[params.era_prefix + 1] or _paramHelpers.lift.eraPrefixes[1]
            end,
            getBridgeMode = function(params)
                return _paramHelpers.lift.bridgeModes[params.lift_bridge_mode + 1] or 2
            end,
            getSinYAngle = function(params)
                local yAngleDeg = (math.floor(params.bridge_chunk_y_angle * _paramHelpers.lift.bridgeChunkYAngleStep) - _paramHelpers.lift.maxBridgeChunkYAngleDeg) or 0
                return math.sin(yAngleDeg * math.pi / 180)
            end,
            getBaseMode = function(params)
                return _paramHelpers.lift.baseModes[params.lift_base_mode + 1] or -1
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
    },
    paramValues = {
        lift = {
            bridge_chunk_y_angle = _paramHelpers.getSliderValues(_paramHelpers.lift.maxBridgeChunkYAngleDeg, _paramHelpers.lift.bridgeChunkYAngleStep),
            bridge_chunk_y_angle_DefaultIndex = math.floor(_paramHelpers.lift.maxBridgeChunkYAngleDeg / _paramHelpers.lift.bridgeChunkYAngleStep),
            era_prefix = {'A', 'B', 'C'},
            lift_base_mode = {_('SimpleConnection'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            lift_bridge_mode = {_('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            lift_height = _arrayUtils.map(_paramHelpers.lift.heights, function(int) return tostring(int) .. 'm' end)
        },
        stairs = {
            bridge_chunk_length = {_('NoRailing0'), '0', '4 m', '8 m', '16 m', '32 m', '64 m', _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge')},
            bridge_chunk_z_angle = _paramHelpers.getSliderValues(_paramHelpers.stairs.maxBridgeChunkZAngleDeg, _paramHelpers.stairs.bridgeChunkZAngleStep),
            bridge_chunk_z_angle_DefaultIndex = math.floor(_paramHelpers.stairs.maxBridgeChunkZAngleDeg / _paramHelpers.stairs.bridgeChunkZAngleStep),
            bridge_chunk_y_angle = _paramHelpers.getSliderValues(_paramHelpers.stairs.maxBridgeChunkYAngleDeg, _paramHelpers.stairs.bridgeChunkYAngleStep),
            bridge_chunk_y_angle_DefaultIndex = math.floor(_paramHelpers.stairs.maxBridgeChunkYAngleDeg / _paramHelpers.stairs.bridgeChunkYAngleStep),
            era_prefix = {'A', 'B', 'C'},
            flat_sloped_terrain = {_('TerrainAlignmentTypeFlat'), _('TerrainAlignmentTypeSloped')},
            stairs_base = {_('NO'), _('Model'), _('EdgeWithNoBridge'), _('SnappyEdgeWithNoBridge'), _('EdgeWithBridge'), _('SnappyEdgeWithBridge'),},
            stairs_height = _arrayUtils.map(_paramHelpers.stairs.heights, function(int) return tostring(int) .. 'm' end),
            terrain_alignment_type = {'EQUAL', 'LESS', 'GREATER'},
        },
    },
    autoSnapHelper = {
        lift = {
            getBaseNewValue4Snappy = function(params)
                if not(params) then return false end

                if params.lift_base_mode == 1 then return {name = 'lift_base_mode', value = 2}
                elseif params.lift_base_mode == 3 then return {name = 'lift_base_mode', value = 4}
                end

                return false
            end,
            getBridgeNewValue4Snappy = function(params)
                if not(params) then return false end

                if params.lift_bridge_mode == 0 then return {name = 'lift_bridge_mode', value = 1}
                elseif params.lift_bridge_mode == 2 then return {name = 'lift_bridge_mode', value = 3}
                end

                return false
            end,
        },
        stairs = {
            getBaseNewValue4Snappy = function(params)
                if not(params) then return false end

                if params.stairs_base == 2 then return {name = 'stairs_base', value = 3}
                elseif params.stairs_base == 4 then return {name = 'stairs_base', value = 5}
                end

                return false
            end,
            getBridgeNewValue4Snappy = function(params)
                if not(params) then return false end

                if params.bridge_chunk_length == 7 then return {name = 'bridge_chunk_length', value = 8}
                elseif params.bridge_chunk_length == 9 then return {name = 'bridge_chunk_length', value = 10}
                end

                return false
            end,
        },
    },
}

return public
