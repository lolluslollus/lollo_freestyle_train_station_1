local logger = require('lollo_freestyle_train_station.logger')
local openLiftOpenStairsHelpers = require('lollo_freestyle_train_station.openLiftOpenStairsHelpers')


local funcs = {
-- Returns a sorted table and an indexed table with the same values.
-- Inside constructions, you must pass all parameters coz the api is not available
    getOpenLiftParamsMetadata = function()
        --[[
            LOLLO NOTE
            In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
            which are available in the present game.
            In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
            including those from inactive mods.
            This is why we read the data from the table that we set in postRunFn, and not from the api.
        ]]
        local _paramValues = openLiftOpenStairsHelpers.paramValues.lift
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
                key = 'lift_bridge_mode', -- do not rename this param or change its values
                name = _('BridgeMode'),
                values = _paramValues.lift_bridge_mode,
                defaultIndex = 2,
            },
            {
                key = 'bridge_chunk_y_angle',
                name = _('BridgeYAngle'),
                values = _paramValues.bridge_chunk_y_angle,
                defaultIndex = _paramValues.bridge_chunk_y_angle_DefaultIndex,
            },
            {
                key = 'lift_base_mode', -- do not rename this param or chenga its values
                name = _('BaseMode'),
                values = _paramValues.lift_base_mode,
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
    end,

    getOpenStairsParamsMetadata = function()
        --[[
            LOLLO NOTE
            In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
            which are available in the present game.
            In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
            including those from inactive mods.
            This is why we read the data from the table that we set in postRunFn, and not from the api.
        ]]
        local _paramValues = openLiftOpenStairsHelpers.paramValues.stairs
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
                tooltip = _('TopPlatformLengthTooltip'),
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
                tooltip = _('StairsBaseTooltip'),
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
    end,

    getOpenTwinStairsParamsMetadata = function()
        --[[
            LOLLO NOTE
            In postRunFn, api.res.streetTypeRep.getAll() only returns street types,
            which are available in the present game.
            In other lua states, eg in game_script, it returns all street types, which have ever been present in the game,
            including those from inactive mods.
            This is why we read the data from the table that we set in postRunFn, and not from the api.
        ]]
        local _paramValues = openLiftOpenStairsHelpers.paramValues.twinStairs
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
                tooltip = _('TopPlatformNorthLengthTooltip'),
                values = _paramValues.bridge_chunk_length_north,
            },
            {
                key = 'bridge_chunk_length_south', -- do not rename this param or chenga its values
                name = _('TopPlatformSouthLength'),
                tooltip = _('TopPlatformNorthLengthTooltip'),
                values = _paramValues.bridge_chunk_length_south,
            },
            {
                key = 'stairs_base', -- do not rename this param or chenga its values
                name = _('StairsBase'),
                tooltip = _('StairsBaseTooltip'),
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
    end,
}

return funcs
