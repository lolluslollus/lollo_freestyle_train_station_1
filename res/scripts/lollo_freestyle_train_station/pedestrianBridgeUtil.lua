local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local bridgeutil = require 'bridgeutil'
local constants = require('lollo_freestyle_train_station.constants')
local mdlHelpers = require('lollo_freestyle_train_station.mdlHelpers')


local private = {
    getBetterUpdateFn = function(_pillarLength, _pillarWidth, _roadWidth, _oldUpdateFn)
        return function(params)
            -- print('newUpdateFn starting with params =') debugPrint(arrayUtils.cloneOmittingFields(params, {'state'}))
            -- UG TODO
            -- LOLLO NOTE
            -- when making a sharp bend, railingWidth is 10 instead of 0.5 and the lanes are screwed:
            -- this draws pointless artifacts on the sides. When it happens, pillarLength is different from the set value.
            -- the reason is, the C routine giving us the params assumes that the road is at least 5 m wide.
            -- this stupid C routine does not say how wide the road is, so we specialise the bridge on 1 metre wide roads.

            -- params.pillarHeights = {}

            if params.pillarLength ~= _pillarLength then
                params.pillarLength = _pillarLength
                params.pillarWidth = _pillarWidth

                for _, railingInterval in pairs(params.railingIntervals) do
                    -- print('railingInterval =') debugPrint(railingInterval)
                    -- railingInterval.hasPillar = { -1, -1, }
                    for _, lane in pairs(railingInterval.lanes) do
                        -- lane.offset = -0.5 -- goodish, it is minus the road width * 0.5
                        -- print('lane before =') debugPrint(lane)
                        lane.offset = -_roadWidth * 0.5
                        -- lane.type = 0
                        -- print('lane after =') debugPrint(lane)
                    end
                end
                -- params.railingWidth = 0.5
                -- params.railingWidth = 1 -- goodish, it is the road width
                params.railingWidth = _roadWidth
                -- print('newUpdateFn tweaked params =') debugPrint(arrayUtils.cloneOmittingFields(params, {'state'}))
            end

            local results = _oldUpdateFn(params)
            -- print('newUpdateFn returning =') debugPrint(results)
            return results
        end
    end,
    ---@param eraPrefix eraPrefix
    getMaterials = function(eraPrefix)
        local _lod0_skinMaterials_era_a_rep = {
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/square_cobbles_skinned.mtl',
        }
        local _lod0_skinMaterials_era_a_side = {
            'lollo_freestyle_train_station/square_cobbles_skinned.mtl',
            'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod0_skinMaterials_era_a_side_no_railing = {
            'lollo_freestyle_train_station/square_cobbles_skinned.mtl',
            'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod1_materials_era_a = {
            'lollo_freestyle_train_station/square_cobbles.mtl',
        }

        local _lod0_skinMaterials_era_b_rep = {
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/square_marble_tiles_skinned.mtl',
        }
        local _lod0_skinMaterials_era_b_side = {
            'lollo_freestyle_train_station/square_marble_tiles_skinned.mtl',
            'lollo_freestyle_train_station/square_marble_tiles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod0_skinMaterials_era_b_side_no_railing = {
            'lollo_freestyle_train_station/square_marble_tiles_skinned.mtl',
            'lollo_freestyle_train_station/square_marble_tiles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod1_materials_era_b = {
            'lollo_freestyle_train_station/square_marble_tiles.mtl',
        }

        local _lod0_skinMaterials_era_c_rep = {
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/station_concrete_1_skinned.mtl',
        }
        local _lod0_skinMaterials_era_c_side = {
            'lollo_freestyle_train_station/station_concrete_1_skinned.mtl',
            'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
        }
        local _lod0_skinMaterials_era_c_side_no_railing = {
            'lollo_freestyle_train_station/station_concrete_1_skinned.mtl',
            'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
        }
        local _lod1_materials_era_c = {
            'lollo_freestyle_train_station/station_concrete_1.mtl',
        }
        if eraPrefix == constants.eras.era_a.prefix then
            return _lod0_skinMaterials_era_a_rep, _lod0_skinMaterials_era_a_side, _lod0_skinMaterials_era_a_side_no_railing, _lod1_materials_era_a
        elseif eraPrefix == constants.eras.era_b.prefix then
            return _lod0_skinMaterials_era_b_rep, _lod0_skinMaterials_era_b_side, _lod0_skinMaterials_era_b_side_no_railing, _lod1_materials_era_b
        else
            return _lod0_skinMaterials_era_c_rep, _lod0_skinMaterials_era_c_side, _lod0_skinMaterials_era_c_side_no_railing, _lod1_materials_era_c
        end
    end,
    ---@param eraPrefix eraPrefix
    getMaterials_Tube = function(eraPrefix)
        local _lod0_skinMaterials_era_a_rep = {
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
        }
        local _lod0_skinMaterials_era_a_side = {
            'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod0_skinMaterials_era_a_side_no_railing = {
            'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod1_materials_era_a = {
            'lollo_freestyle_train_station/square_cobbles.mtl',
        }

        local _lod0_skinMaterials_era_b_rep = {
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/square_marble_tiles_low_prio_skinned.mtl',
        }
        local _lod0_skinMaterials_era_b_side = {
            'lollo_freestyle_train_station/square_marble_tiles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod0_skinMaterials_era_b_side_no_railing = {
            'lollo_freestyle_train_station/square_marble_tiles_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
        }
        local _lod1_materials_era_b = {
            'lollo_freestyle_train_station/square_marble_tiles.mtl',
        }

        local _lod0_skinMaterials_era_c_rep = {
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
            'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
        }
        local _lod0_skinMaterials_era_c_side = {
            'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
        }
        local _lod0_skinMaterials_era_c_side_no_railing = {
            'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
            'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
        }
        local _lod1_materials_era_c = {
            'lollo_freestyle_train_station/station_concrete_1.mtl',
        }

        if eraPrefix == constants.eras.era_a.prefix then
            return _lod0_skinMaterials_era_a_rep, _lod0_skinMaterials_era_a_side, _lod0_skinMaterials_era_a_side_no_railing, _lod1_materials_era_a
        elseif eraPrefix == constants.eras.era_b.prefix then
            return _lod0_skinMaterials_era_b_rep, _lod0_skinMaterials_era_b_side, _lod0_skinMaterials_era_b_side_no_railing, _lod1_materials_era_b
        else
            return _lod0_skinMaterials_era_c_rep, _lod0_skinMaterials_era_c_side, _lod0_skinMaterials_era_c_side_no_railing, _lod1_materials_era_c
        end
    end,
}

local public = {
    ---@obsolete
    ---@param isSides any
    ---@return table
    getData4CementOBSOLETE = function(isSides)
        local railingDir = 'bridge/lollo_freestyle_train_station/pedestrian_cement/'

        -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
        -- and a list of lanes and offsets,
        -- then places them together depending on this information.
        -- The bounding boxes explain why bridges have a less flexible file structure.

        -- One problem is, platform-tracks < 5 m don't work well on stock bridges.
        -- Either we rewrite the whole thing, or we adjust something and use the automatisms
        -- => number two.
        -- My dedicated *_rep_* models have a mesh and bounding box 0.5 m wide instead of 4.
        -- This applies to railing and pillars.
        -- bridgeutil uses more instances if required, stacked sideways;
        -- otherwise, only one, and it is narrow enough for anything.
        -- This allows for bridges under 2.5 m platform-tracks and narrow paths;
        -- Sadly, any sorts of sides won't work with 2.5 m platforms
        -- coz bridgeutil assumes tracks are 5 m wide (UG TODO the lane data is manky).

        -- Skins and bones help bridges look better, they look segmented without them.
        -- Blender 2.79 has them and they work with the old converter; they are done with vertex groups.
        -- Use the weight painting, then the gradient tool on every vertex group.
        -- Don't forget to clean each vertex group after editing, like with meshes.

        -- This particular bridge is for 1 metre roads, which are very bendy.
        -- See the notes below.

        local railing = isSides
            and {
                railingDir .. 'railing_rep_side_full_side.mdl',
                railingDir .. 'railing_rep_side_full_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                -- these are useful to avoid funny dark textures on one side, but we use the two-sided material instead
                -- railingDir .. 'railing_rep_side2_full_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
            }
            or {
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                -- these are useful to avoid funny dark textures on one side, but we use the two-sided material instead
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
            }

        local config = {
            pillarBase = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            pillarRepeat = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            pillarTop = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            railingBegin = railing,
            railingRepeat = railing,
            railingEnd = railing,
        }

        local _pillarLength = 999
        local _pillarWidth = 0.5
        local _roadWidth = 1
        local _oldUpdateFn = bridgeutil.makeDefaultUpdateFn(config)
        local newUpdateFn = private.getBetterUpdateFn(_pillarLength, _pillarWidth, _roadWidth, _oldUpdateFn)

        return {
            name = isSides and _('PedestrianCementBridgeNoPillars') or _('PedestrianCementBridgeNoPillarsNoSides'),
            yearFrom = -1, -- obsolete, keep it for compatibility
            yearTo = -1,
            carriers = { 'RAIL', 'ROAD' },
            speedLimit = 320.0 / 3.6,
            pillarLen = _pillarLength,
            pillarMinDist = 65535,
            pillarMaxDist = 65535,
            pillarTargetDist = 65535,
            -- pillarWidth = 2,
            cost = 400.0,
            -- LOLLO NOTE
            -- Sharp bends draw the street tangent to the bridge, outside,
            -- because the game expects 6m long street segments, while this bridge has 2m long segments.
            -- We can make street materials transparent, so sharp bends will look better.
            -- However, this will give junctions a hole in the middle.
            -- All in all, we choose junctions with no holes
            -- and put up with segments in stupidly narrow bends.
            materialsToReplace = {
                -- streetPaving = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- streetLane = { -- this is the most conspicuous
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- crossingLane = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- sidewalkPaving = { -- this fills small gaps at junctions but also draws tangent stripes outside sharp bends
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     -- name = 'lollo_freestyle_train_station/icon/green.mtl'
                --     -- name = 'lollo_freestyle_train_station/station_concrete_1_low_prio.mtl'
                --     name = 'street/country_new_medium_paving.mtl',
                --     size = { 2, 2 },
                -- },
                -- sidewalkCurb = { -- useless
                --     -- size = { 3, 0.6 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/yellow.mtl'
                -- },
                -- sidewalkBorderInner = {
                --     size = { 2, 0.8 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/blue.mtl'
                -- },
                -- sidewalkLane = {
                --     size = { 2, 0.8 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/red.mtl'
                -- },
            },
            noParallelStripSubdivision = true,
            -- updateFn = updateFn,
            updateFn = newUpdateFn,
        }
    end,
    ---pedestrian bridge, with or without railing
    ---@param era {prefix: eraPrefix, startYear: integer}
    ---@param isSides boolean
    ---@return table
    getData4PedestrianBridge = function(era, isSides)
        local railingDir = 'bridge/lollo_freestyle_train_station/pedestrian_basic/' .. era.prefix

        -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
        -- and a list of lanes and offsets,
        -- then places them together depending on this information.
        -- The bounding boxes explain why bridges have a less flexible file structure.

        -- One problem is, platform-tracks < 5 m don't work well on stock bridges.
        -- Either we rewrite the whole thing, or we adjust something and use the automatisms
        -- => number two.
        -- My dedicated *_rep_* models have a mesh and bounding box 0.5 m wide instead of 4.
        -- This applies to railing and pillars.
        -- bridgeutil uses more instances if required, stacked sideways;
        -- otherwise, only one, and it is narrow enough for anything.
        -- This allows for bridges under 2.5 m platform-tracks and narrow paths;
        -- Sadly, any sorts of sides won't work with 2.5 m platforms
        -- coz bridgeutil assumes tracks are 5 m wide (UG TODO the lane data is manky).

        -- Skins and bones help bridges look better, they look segmented without them.
        -- Blender 2.79 has them and they work with the old converter; they are done with vertex groups.
        -- Use the weight painting, then the gradient tool on every vertex group.
        -- Don't forget to clean each vertex group after editing, like with meshes.

        -- This particular bridge is for 1 metre roads, which are very bendy.
        -- See the notes below.

        local railing = isSides
            and {
                railingDir .. 'railing_rep_side_full_side.mdl',
                railingDir .. 'railing_rep_side_full_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                -- these are useful to avoid funny dark textures on one side, but we use the two-sided material instead
                -- railingDir .. 'railing_rep_side2_full_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
            }
            or {
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_side_no_side.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                railingDir .. 'railing_rep_rep.mdl',
                -- these are useful to avoid funny dark textures on one side, but we use the two-sided material instead
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
                -- railingDir .. 'railing_rep_side2_no_side.mdl',
            }

        local config = {
            pillarBase = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            pillarRepeat = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            pillarTop = { 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl', 'lollo_freestyle_train_station/empty.mdl' },
            railingBegin = railing,
            railingRepeat = railing,
            railingEnd = railing,
        }

        local _pillarLength = 999
        local _pillarWidth = 0.5
        local _roadWidth = 1
        local _oldUpdateFn = bridgeutil.makeDefaultUpdateFn(config)
        local newUpdateFn = private.getBetterUpdateFn(_pillarLength, _pillarWidth, _roadWidth, _oldUpdateFn)

        return {
            name = isSides and _(era.prefix .. 'PedestrianBasicBridgeNoPillars') or _(era.prefix .. 'PedestrianBasicBridgeNoPillarsNoSides'),
            yearFrom = era.startYear,
            yearTo = 0,
            carriers = { 'RAIL', 'ROAD' },
            speedLimit = 320.0 / 3.6,
            pillarLen = _pillarLength,
            pillarMinDist = 65535,
            pillarMaxDist = 65535,
            pillarTargetDist = 65535,
            -- pillarWidth = 2,
            cost = 400.0,
            -- LOLLO NOTE
            -- Sharp bends draw the street tangent to the bridge, outside,
            -- because the game expects 6m long street segments, while this bridge has 2m long segments.
            -- We can make street materials transparent, so sharp bends will look better.
            -- However, this will give junctions a hole in the middle.
            -- All in all, we choose junctions with no holes
            -- and put up with segments in stupidly narrow bends.
            materialsToReplace = {
                streetPaving = {
                    -- name = 'lollo_freestyle_train_station/icon/lilac.mtl',
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    size = { 1, 1 },
                },
                streetLane = { -- this is the most conspicuous
                    -- name = 'lollo_freestyle_train_station/icon/yellow.mtl',
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    size = { 1, 1 },
                },
                -- crossingLane = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                sidewalkPaving = { -- this fills small gaps at junctions but also draws tangent stripes outside sharp bends
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    -- name = 'lollo_freestyle_train_station/icon/green.mtl',
                    -- name = 'lollo_freestyle_train_station/station_concrete_1_low_prio.mtl'
                    -- name = 'street/country_new_medium_paving.mtl',
                    -- size = { 2, 2 },
                    size = { 1, 1 },
                },
                -- sidewalkCurb = { -- useless
                --     -- size = { 3, 0.6 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/yellow.mtl'
                -- },
                sidewalkBorderInner = {
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    -- name = 'lollo_freestyle_train_station/icon/blue.mtl'
                    -- size = { 2, 0.8 },
                    size = { 1, 1 },
                },
                sidewalkLane = {
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    -- name = 'lollo_freestyle_train_station/icon/red.mtl'
                    -- size = { 2, 0.8 },
                    size = { 1, 1 },
                },
            },
            noParallelStripSubdivision = true,
            -- updateFn = updateFn,
            updateFn = newUpdateFn,
        }
    end,
    ---enhanced stone bridge
    ---@param name string
    ---@param dir string
    ---@param isSides boolean
    ---@return table
    getData4StoneLolloBridge = function(name, dir, isSides)
        -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
        -- and a list of lanes and offsets,
        -- then places them together depending on this information.
        -- The bounding boxes explain why bridges have a less flexible file structure.

        -- One problem is, platform-tracks < 5 m don't work well on stock bridges.
        -- Either we rewrite the whole thing, or we adjust something and use the automatisms
        -- => number two.
        -- My dedicated *_rep_* models have a mesh and bounding box 0.5 m wide instead of 4.
        -- This applies to railing and pillars.
        -- bridgeutil uses more instances if required, stacked sideways;
        -- otherwise, only one, and it is narrow enough for anything.
        -- This allows for bridges under 2.5 m platform-tracks and narrow paths;
        -- Sadly, any sorts of sides won't work with 2.5 m platforms
        -- coz bridgeutil assumes tracks are 5 m wide (UG TODO the lane data is manky).

        -- Skins and bones help bridges look better, they look segmented without them.
        -- Blender 2.79 has them and they work with the old converter; they are done with vertex groups.
        -- Use the weight painting, then the gradient tool on every vertex group.
        -- Don't forget to clean each vertex group after editing, like with meshes.

        -- This particular bridge is for 1 metre roads, which are very bendy.
        -- See the notes below.

        local configWithSides = {
            pillarBase = { dir .. "pillar_btm_side.mdl", dir .. "pillar_btm_rep.mdl", dir .. "pillar_btm_side2.mdl" },
            pillarRepeat = { dir .. "pillar_rep_side.mdl", dir .. "pillar_rep_rep.mdl", dir .. "pillar_rep_side2.mdl" },
            pillarTop = { dir .. "pillar_top_side.mdl", dir .. "pillar_top_rep.mdl", dir .. "pillar_top_side2.mdl" },
        
            railingBegin = {
                dir .. "railing_start_side.mdl", dir .. "railing_start_side.mdl", dir .. "railing_start_side_no_side.mdl", 
                dir .. "railing_start_rep.mdl", dir .. "railing_start_rep.mdl",
                dir .. "railing_end_side2.mdl", dir .. "railing_end_side2.mdl", dir .. "railing_end_side2_no_side.mdl"
            },
            railingRepeat = {
                dir .. "railing_rep_side.mdl",  dir .. "railing_rep_side.mdl",  dir .. "railing_rep_side_no_side.mdl",
                dir .. "railing_rep_rep.mdl", dir .. "railing_rep_rep.mdl",
                dir .. "railing_rep_side2.mdl",  dir .. "railing_rep_side2.mdl",  dir .. "railing_rep_side2_no_side.mdl",
            },
            railingEnd = {
                dir .. "railing_end_side.mdl",  dir .. "railing_end_side.mdl",  dir .. "railing_end_side_no_side.mdl",
                dir .. "railing_end_rep.mdl", dir .. "railing_end_rep.mdl",
                dir .. "railing_start_side2.mdl",  dir .. "railing_start_side2.mdl",  dir .. "railing_start_side2_no_side.mdl",
            },
        }
        local configWithNoSides = {
            pillarBase = { dir .. "pillar_btm_side.mdl", dir .. "pillar_btm_rep.mdl", dir .. "pillar_btm_side2.mdl" },
            pillarRepeat = { dir .. "pillar_rep_side.mdl", dir .. "pillar_rep_rep.mdl", dir .. "pillar_rep_side2.mdl" },
            pillarTop = { dir .. "pillar_top_side.mdl", dir .. "pillar_top_rep.mdl", dir .. "pillar_top_side2.mdl" },

            railingBegin = {
                dir .. "railing_start_side_no_side.mdl", dir .. "railing_start_side_no_side.mdl", dir .. "railing_start_side_no_side.mdl", 
                dir .. "railing_start_rep.mdl", dir .. "railing_start_rep.mdl",
                dir .. "railing_end_side2_no_side.mdl", dir .. "railing_end_side2_no_side.mdl", dir .. "railing_end_side2_no_side.mdl"
            },
            railingRepeat = {
                dir .. "railing_rep_side_no_side.mdl",  dir .. "railing_rep_side_no_side.mdl",  dir .. "railing_rep_side_no_side.mdl",
                dir .. "railing_rep_rep.mdl", dir .. "railing_rep_rep.mdl",
                dir .. "railing_rep_side2_no_side.mdl",  dir .. "railing_rep_side2_no_side.mdl",  dir .. "railing_rep_side2_no_side.mdl",
            },
            railingEnd = {
                dir .. "railing_end_side_no_side.mdl",  dir .. "railing_end_side_no_side.mdl",  dir .. "railing_end_side_no_side.mdl",
                dir .. "railing_end_rep.mdl", dir .. "railing_end_rep.mdl",
                dir .. "railing_start_side2_no_side.mdl",  dir .. "railing_start_side2_no_side.mdl",  dir .. "railing_start_side2_no_side.mdl",
            },
        }
        local config = isSides and configWithSides or configWithNoSides

        local _pillarLength = 3
        local _pillarWidth = 2
        local _roadWidth = 1
        local _oldUpdateFn = bridgeutil.makeDefaultUpdateFn(config)
        local newUpdateFn = private.getBetterUpdateFn(_pillarLength, _pillarWidth, _roadWidth, _oldUpdateFn)

        return {
            name = name,
            yearFrom = 0,
            yearTo = 0,
            carriers = { 'RAIL', 'ROAD' },
            speedLimit = 320.0 / 3.6,
            pillarLen = _pillarLength,
            pillarMinDist = 12,
            pillarMaxDist = 48,
            pillarTargetDist = 12,
            -- pillarWidth = _pillarWidth,
            cost = 200.0,
            costFactors = { 10.0, 2.5, 1.0 },
            -- LOLLO NOTE
            -- Sharp bends draw the street tangent to the bridge, outside,
            -- because the game expects 6m long street segments, while this bridge has 2m long segments.
            -- We can make street materials transparent, so sharp bends will look better.
            -- However, this will give junctions a hole in the middle.
            -- All in all, we choose junctions with no holes
            -- and put up with segments in stupidly narrow bends.
            materialsToReplace = {
                -- streetPaving = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- streetLane = { -- this is the most conspicuous
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- crossingLane = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                sidewalkPaving = { -- this fills small gaps at junctions but also draws tangent stripes outside sharp bends
                    -- name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    -- size = { 1.0, 1.0 },
                    -- name = 'lollo_freestyle_train_station/icon/green.mtl'
                    -- name = 'lollo_freestyle_train_station/square_marble_tiles_z.mtl',
                    -- size = {4.0, 4.0},
                    name = "street/old_medium_sidewalk.mtl",
                    size = {5.0,5.0},
                },
                -- sidewalkCurb = { -- useless
                --     -- size = { 3, 0.6 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/yellow.mtl'
                -- },
                sidewalkBorderInner = {
                    -- size = { 2, 0.8 },
                    name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                    size = {5.0,5.0},
                    -- name = 'lollo_freestyle_train_station/icon/blue.mtl'
                    -- name = 'lollo_freestyle_train_station/square_marble_tiles_z.mtl',
                    -- size = {4.0, 4.0}
                },
                -- sidewalkLane = {
                --     size = { 2, 0.8 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/red.mtl'
                -- },
            },
            noParallelStripSubdivision = true,
            updateFn = newUpdateFn
        }
    end,
    ---cement + glass bridge
    ---@param name string
    ---@param config table
    ---@param pillarMinDist number
    ---@param pillarMaxDist number
    ---@param pillarTargetDist number
    ---@return table
    getData4CementGlassBridge = function(name, config, pillarMinDist, pillarMaxDist, pillarTargetDist)
        -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
        -- and a list of lanes and offsets,
        -- then places them together depending on this information.
        -- The bounding boxes explain why bridges have a less flexible file structure.

        -- One problem is, platform-tracks < 5 m don't work well on stock bridges.
        -- Either we rewrite the whole thing, or we adjust something and use the automatisms
        -- => number two.
        -- My dedicated *_rep_* models have a mesh and bounding box 0.5 m wide instead of 4.
        -- This applies to railing and pillars.
        -- bridgeutil uses more instances if required, stacked sideways;
        -- otherwise, only one, and it is narrow enough for anything.
        -- This allows for bridges under 2.5 m platform-tracks and narrow paths;
        -- Sadly, any sorts of sides won't work with 2.5 m platforms
        -- coz bridgeutil assumes tracks are 5 m wide (UG TODO the lane data is manky).

        -- Skins and bones help bridges look better, they look segmented without them.
        -- Blender 2.79 has them and they work with the old converter; they are done with vertex groups.
        -- Use the weight painting, then the gradient tool on every vertex group.
        -- Don't forget to clean each vertex group after editing, like with meshes.

        -- This particular bridge is for 1 metre roads, which are very bendy.
        -- See the notes below.

        local _pillarLength = 3
        local _pillarWidth = 2
        local _roadWidth = 1
        local _oldUpdateFn = bridgeutil.makeDefaultUpdateFn(config)
        local newUpdateFn = private.getBetterUpdateFn(_pillarLength, _pillarWidth, _roadWidth, _oldUpdateFn)

        return {
            name = name,
            yearFrom = 0,
            yearTo = 0,
            carriers = { 'RAIL', 'ROAD' },
            speedLimit = 320.0 / 3.6,
            pillarLen = _pillarLength,
            pillarMinDist = pillarMinDist,
            pillarMaxDist = pillarMaxDist,
            pillarTargetDist = pillarTargetDist,
            -- pillarWidth = _pillarWidth,
            cost = 200.0,
            costFactors = { 10.0, 2.5, 1.0 },
            -- LOLLO NOTE
            -- Sharp bends draw the street tangent to the bridge, outside,
            -- because the game expects 6m long street segments, while this bridge has 2m long segments.
            -- We can make street materials transparent, so sharp bends will look better.
            -- However, this will give junctions a hole in the middle.
            -- All in all, we choose junctions with no holes
            -- and put up with segments in stupidly narrow bends.
            materialsToReplace = {
                -- streetPaving = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- streetLane = { -- this is the most conspicuous
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- crossingLane = {
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                -- },
                -- sidewalkPaving = { -- this fills small gaps at junctions but also draws tangent stripes outside sharp bends
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                --     -- size = { 1.0, 1.0 },
                --     -- name = 'lollo_freestyle_train_station/icon/green.mtl'
                --     -- name = 'lollo_freestyle_train_station/square_marble_tiles_z.mtl',
                --     -- size = {4.0, 4.0},
                --     name = "street/old_medium_sidewalk.mtl",
                --     size = {5.0,5.0},
                -- },
                -- sidewalkCurb = { -- useless
                --     -- size = { 3, 0.6 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/yellow.mtl'
                -- },
                -- sidewalkBorderInner = {
                --     -- size = { 2, 0.8 },
                --     name = 'lollo_freestyle_train_station/totally_transparent.mtl',
                --     size = {5.0,5.0},
                --     -- name = 'lollo_freestyle_train_station/icon/blue.mtl'
                --     -- name = 'lollo_freestyle_train_station/square_marble_tiles_z.mtl',
                --     -- size = {4.0, 4.0}
                -- },
                -- sidewalkLane = {
                --     size = { 2, 0.8 },
                --     -- name = 'lollo_freestyle_train_station/totally_transparent.mtl'
                --     name = 'lollo_freestyle_train_station/icon/red.mtl'
                -- },
            },
            noParallelStripSubdivision = true,
            updateFn = newUpdateFn
        }
    end,
    ---model for pedestrian bridge within station
    ---@param nSegments integer
    ---@param isCompressed boolean
    ---@param eraPrefix eraPrefix
    ---@param isWithEdge boolean
    ---@return table
    getModel4StationBridge = function(nSegments, isCompressed, eraPrefix, isWithEdge)
        if (not(nSegments) or nSegments < 1) then nSegments = 1 end

        local _2nSegments = 2 * nSegments
        local _iMaxLod0 = _2nSegments - 2
        local _iMaxLod1 = nSegments - 1
        local _xFactorLod0 = isCompressed and (1 / _2nSegments) or 1
        local _xFactorLod1 = isCompressed and (1 / nSegments) or 2
        local _xFactorTN = isCompressed and 1 or _2nSegments

        local _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials = private.getMaterials(eraPrefix)

        local lod0Children  = {}
        for i = 0, _iMaxLod0, 2 do
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_start',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
                            -- },
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_end',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0, 0, 1, },
                            -- },
                            {
                                name = 'cement_bridge_bone_2m_start',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.25, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.25, 0, 1, },
                            },
                        },
                        name = 'container_2m',
                        skin = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod0.msh',
                        skinMaterials = _lod0_skinMaterials_rep,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
            }
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_start_side1',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                            -- },
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_end_side1',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                            -- },
                            {
                                name = 'cement_bridge_bone_2m_start_side1',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end_side1',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1, 0, 1, },
                            },
                        },
                        name = 'container_2m_side1',
                        skin = (i == 0 or i == _iMaxLod0)
                            and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
                            or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_full_side_lod0.msh',
                        skinMaterials = (i == 0 or i == _iMaxLod0)
                            and _lod0_skinMaterials_side_no_railing
                            or _lod0_skinMaterials_side,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
            }
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_start_side2',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                            -- },
                            -- {
                            -- 	name = 'cement_bridge_bone_2m_end_side2',
                            -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                            -- },
                            {
                                name = 'cement_bridge_bone_2m_start_side2',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end_side2',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1, 0, 1, },
                            },
                        },
                        name = 'container_2m_side2',
                        skin = (i == 0 or i == _iMaxLod0)
                            and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
                            or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_full_side_lod0.msh',
                        skinMaterials = (i == 0 or i == _iMaxLod0)
                            and _lod0_skinMaterials_side_no_railing
                            or _lod0_skinMaterials_side,
                    },
                },
                -- this transf looks wrong but it looks better than the right one
                transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
                -- while it should be like this, but it looks worse
                -- transf = { -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i+2, 0.5, 0, 1, },
            }
        end

        local lod1Children  = {}
        for i = 0, _iMaxLod1, 2 do
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
            }
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
            }
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
            }
        end

        local laneListsWithEdge = {
            {
                linkable = false,
                nodes = {
                    -- the lane starts where the model starts
                    {
                        { 0, 0, 0 },
                        { _xFactorTN - 0.3, 0, 0 }, -- _xFactorTN >= 4, by construction
                        1.5,
                    },
                    {
                        { _xFactorTN - 0.3, 0, 0 },
                        { _xFactorTN - 0.3, 0, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            },
            {
                linkable = true,
                nodes = {
                    -- two lanes to match the edge pavement
                    {
                        { _xFactorTN - 0.3, 0, 0 },
                        { 0.3, 0.3, 0 },
                        1.5,
                    },
                    {
                        { _xFactorTN, 0.3, 0 },
                        { 0.3, 0.3, 0 },
                        1.5,
                    },
                    {
                        { _xFactorTN - 0.3, 0, 0 },
                        { 0.3, -0.3, 0 },
                        1.5,
                    },
                    {
                        { _xFactorTN, -0.3, 0 },
                        { 0.3, -0.3, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            }
        }
        local laneListsNotCompressed = {
            {
                linkable = false,
                nodes = {
                    -- the lane starts where the model starts
                    {
                        { 0, 0, 0 },
                        { _xFactorTN - 1.2, 0, 0 }, -- _xFactorTN >= 2, by construction
                        1.5,
                    },
                    {
                        { _xFactorTN - 1.2, 0, 0 },
                        { _xFactorTN - 1.2, 0, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            },
            {
                linkable = true,
                nodes = {
                    {
                        { _xFactorTN - 1.2, 0, 0 },
                        { 0.2, 0, 0 },
                        1.5,
                    },
                    -- the lane ends 1 m before the model ends, for seamless looking links
                    {
                        { _xFactorTN - 1, 0, 0 },
                        { 0.2, 0, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            }
        }
        local laneListsCompressed = {{
            linkable = false,
            nodes = {
                -- the lane starts where the model starts
                {
                    { 0, 0, 0 },
                    { _xFactorTN, 0, 0 },
                    1.5,
                },
                -- the lane ends where the model ends
                {
                    { _xFactorTN, 0, 0 },
                    { _xFactorTN, 0, 0 },
                    1.5,
                },
            },
            transportModes = { 'PERSON', },
            speedLimit = 20,
        }}
        return {
            boundingInfo = mdlHelpers.getVoidBoundingInfo(),
            collider = mdlHelpers.getVoidCollider(),
            lods = {
                {
                    node = {
                        children =  lod0Children,
                        name = 'lod0Children',
                        transf = { _xFactorLod0, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 0,
                    visibleTo = 250,
                },
                {
                    node = {
                        children =  lod1Children,
                        name = 'lod1Children',
                        transf = { _xFactorLod1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 250,
                    visibleTo = 1000,
                },
            },
            metadata = {
                transportNetworkProvider = {
                    -- compressed bridges are inside stations;
                    -- bridge exits and free open stairs bridges are uncompressed
                    -- their x == 0 end is atop the stairs (free stairs or station stairs), their x > 0 end joins up with the outer world
                    laneLists = isWithEdge and laneListsWithEdge or (isCompressed and laneListsCompressed or laneListsNotCompressed),
                    runways = { },
                    terminals = { },
                },
            },
            version = 1,
        }
    end,
    ---model for tube bridge within station
    ---@param nSegments integer
    ---@param isCompressed boolean
    ---@param eraPrefix eraPrefix
    ---@return table
    getModel4StationTube = function(nSegments, isCompressed, eraPrefix)
        if (not(nSegments) or nSegments < 1) then nSegments = 1 end

        local _2nSegments = 2 * nSegments
        local _iMaxLod0 = _2nSegments - 2
        local _iMaxLod1 = nSegments - 1
        local _xFactorLod0 = isCompressed and (1 / _2nSegments) or 1
        local _xFactorLod1 = isCompressed and (1 / nSegments) or 2
        local _xFactorTN = isCompressed and 1 or _2nSegments

        local _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials = private.getMaterials(eraPrefix)
        local _lod0_skinMaterials_rep_tube, _lod0_skinMaterials_side_tube, _lod0_skinMaterials_side_no_railing_tube, _lod1_materials_tube = private.getMaterials_Tube(eraPrefix)

        local lod0Children  = {}
        for i = 0, _iMaxLod0, 2 do
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            --     {
                            --         name = 'cement_bridge_bone_2m_start',
                            --         transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                            --     },
                            --     {
                            --         name = 'cement_bridge_bone_2m_end',
                            --         transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                            --     },
                            {
                                name = 'cement_bridge_bone_2m_start',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.25, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.25, 0, 1, },
                            },
                        },
                        name = 'container_2m',
                        skin = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod0.msh',
                        skinMaterials = _lod0_skinMaterials_rep,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
            }
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            -- {
                            --     name = 'cement_bridge_bone_2m_start_side1',
                            --     transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                            -- },
                            -- {
                            --     name = 'cement_bridge_bone_2m_end_side1',
                            --     transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                            -- },
                            {
                                name = 'cement_bridge_bone_2m_start_side1',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end_side1',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1, 0, 1, },
                            },
                        },
                        name = 'container_2m_side1',
                        skin = (i == 0 or i == _iMaxLod0)
                            and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
                            or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_tube_side_lod0.msh',
                        skinMaterials = (i == 0 or i == _iMaxLod0)
                            and _lod0_skinMaterials_side_no_railing
                            or _lod0_skinMaterials_side_tube,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
            }
            lod0Children[#lod0Children + 1] = {
                children = {
                    {
                        children = {
                            -- {
                            --     name = 'cement_bridge_bone_2m_start_side2',
                            --     transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                            -- },
                            -- {
                            --     name = 'cement_bridge_bone_2m_end_side2',
                            --     transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                            -- },
                            {
                                name = 'cement_bridge_bone_2m_start_side2',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, },
                            },
                            {
                                name = 'cement_bridge_bone_2m_end_side2',
                                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1, 0, 1, },
                            },
                        },
                        name = 'container_2m_side2',
                        skin = (i == 0 or i == _iMaxLod0)
                            and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
                            or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_tube_side_lod0.msh',
                        skinMaterials = (i == 0 or i == _iMaxLod0)
                            and _lod0_skinMaterials_side_no_railing
                            or _lod0_skinMaterials_side_tube,
                    },
                },
                transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
            }
        end

        local lod1Children  = {}
        for i = 0, _iMaxLod1, 2 do
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
            }
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
            }
            lod1Children[#lod1Children + 1] = {
                children = {
                    {
                        mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
                        materials = _lod1_materials,
                    },
                },
                transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
            }
        end

        local laneListsNotCompressed = {
            {
                linkable = false,
                nodes = {
                    -- the lane starts where the model starts
                    {
                        { 0, 0, 0 },
                        { _xFactorTN - 1.2, 0, 0 }, -- _xFactorTN >= 2, by construction
                        1.5,
                    },
                    {
                        { _xFactorTN - 1.2, 0, 0 },
                        { _xFactorTN - 1.2, 0, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            },
            {
                linkable = true,
                nodes = {
                    {
                        { _xFactorTN - 1.2, 0, 0 },
                        { 0.2, 0, 0 },
                        1.5,
                    },
                    -- the lane ends 1 m before the model ends, for seamless looking links
                    {
                        { _xFactorTN - 1, 0, 0 },
                        { 0.2, 0, 0 },
                        1.5,
                    },
                },
                transportModes = { 'PERSON', },
                speedLimit = 20,
            }
        }
        local laneListsCompressed = {{
            linkable = false,
            nodes = {
                -- the lane starts where the model starts
                {
                    { 0, 0, 0 },
                    { _xFactorTN, 0, 0 },
                    1.5,
                },
                -- the lane ends where the model ends
                {
                    { _xFactorTN, 0, 0 },
                    { _xFactorTN, 0, 0 },
                    1.5,
                },
            },
            transportModes = { 'PERSON', },
            speedLimit = 20,
        }}
        return {
            boundingInfo = mdlHelpers.getVoidBoundingInfo(),
            collider = mdlHelpers.getVoidCollider(),
            lods = {
                {
                    node = {
                        children =  lod0Children,
                        name = 'lod0Children',
                        transf = { _xFactorLod0, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 0,
                    visibleTo = 250,
                },
                {
                    node = {
                        children =  lod1Children,
                        name = 'lod1Children',
                        transf = { _xFactorLod1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 250,
                    visibleTo = 1000,
                },
            },
            metadata = {
                transportNetworkProvider = {
                    -- compressed bridges are inside stations;
                    -- bridge exits and free open stairs bridges are uncompressed
                    -- their x == 0 end is atop the stairs (free stairs or station stairs), their x > 0 end joins up with the outer world
                    laneLists = isCompressed and laneListsCompressed or laneListsNotCompressed,
                    runways = { },
                    terminals = { },
                },
            },
            version = 1,
        }
    end,
    ---pedestrian bridge model rep_side
    ---@param eraPrefix eraPrefix
    ---@param isSide boolean
    ---@return table
    getPedestrianBridge_model_rep_side = function(eraPrefix, isSide)
        local _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials = private.getMaterials(eraPrefix)

        return {
            boundingInfo = {
                bbMax = { 2, 0, 0, },
                bbMin = { 0, -0.6, -0.5, },
            },
            collider = {
                params = {
                    halfExtents = { 1, 0.3, 0.25, },
                },
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, -0.3, -0.25, 1, },
                type = 'BOX',
            },
            -- collider = mdlHelpers.getVoidCollider(),
            lods = {
                {
                    node = {
                        children = {
                            {
                                children = {
                                    -- {
                                    -- 	name = 'cement_bridge_bone_2m_start_side1',
                                    -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                                    -- },
                                    -- {
                                    -- 	name = 'cement_bridge_bone_2m_end_side1',
                                    -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                                    -- },
                                    {
                                        name = 'cement_bridge_bone_2m_start_side1',
                                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, },
                                    },
                                    {
                                        name = 'cement_bridge_bone_2m_end_side1',
                                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 1, 0, 1, },
                                    },
                                },
                                name = 'container_2m_side1',
                                skin = isSide
                                    and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_full_side_lod0.msh'
                                    or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh',
                                skinMaterials = isSide
                                    and _lod0_skinMaterials_side
                                    or _lod0_skinMaterials_side_no_railing,
                            },
                        },
                        -- transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.5, 0, 1, },
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.25, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 0,
                    visibleTo = 250,
                },
                {
                    node = {
                        children = {
                            {
                                mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
                                materials = _lod1_materials,
                            },
                        },
                        -- transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.5, 0, 1, },
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.25, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 250,
                    visibleTo = 1000,
                },
            },
            metadata = { },
            version = 1,
        }
    end,
    ---pedestrian bridge model rep_rep
    ---@param eraPrefix eraPrefix
    getPedestrianBridge_model_rep_rep = function(eraPrefix)
        local _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials = private.getMaterials(eraPrefix)

        return {
            boundingInfo = {
                bbMax = { 2, 0.5, 0, },
                bbMin = { 0, 0, -0.5, },
            },
            collider = {
                params = {
                    halfExtents = { 1, 0.25, 0.25, },
                },
                transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  1, 0.25, -0.25, 1, },
                type = 'BOX',
            },
            -- collider = mdlHelpers.getVoidCollider(),
            lods = {
                {
                    node = {
                        children = {
                            {
                                children = {
                                    -- {
                                    -- 	name = 'cement_bridge_bone_2m_start',
                                    -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
                                    -- },
                                    -- {
                                    -- 	name = 'cement_bridge_bone_2m_end',
                                    -- 	transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
                                    -- },
                                    {
                                        name = 'cement_bridge_bone_2m_start',
                                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.25, 0, 1, },
                                    },
                                    {
                                        name = 'cement_bridge_bone_2m_end',
                                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.25, 0, 1, },
                                    },
                                },
                                name = 'container_2m',
                                skin = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod0.msh',
                                skinMaterials = _lod0_skinMaterials_rep,
                            },
                        },
                        -- transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.25, 0, 1, },
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 0,
                    visibleTo = 250,
                },
                {
                    node = {
                        children = {
                            {
                                mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod1.msh',
                                materials = _lod1_materials,
                            },
                        },
                        -- transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.25, 0, 1, },
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
                    },
                    static = false,
                    visibleFrom = 250,
                    visibleTo = 1000,
                },
            },
            metadata = { },
            version = 1,
        }
    end,
}

return public
