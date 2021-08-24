local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local bridgeutil = require 'bridgeutil'

function data()
    local _pillarLength = 3

    local pillarDir = 'bridge/lollo_freestyle_train_station/cement_pillars/'
    local railingDir = 'bridge/lollo_freestyle_train_station/pedestrian_cement/'
    local stockDir = 'bridge/cement/'

    -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
    -- and a list of lanes and offsets,
    -- then places them together depending on this information.
    -- The bounding boxes probably explain why bridges have a less flexible file structure.
    -- The trouble is, platform-tracks != 5 m don't work well on stock bridges.
    -- Either we rewrite the whole thing, or we use the automatisms => number two.
    -- The *_rep models have a mesh 0.5 m wide instead of 4, and same with the bounding box.
    -- This applies to railing and pillars.
    -- This allows them to fit 2.5 m platform-tracks.
    -- Sadly, any sorts of sides won't work with 2.5 m platforms
    -- coz bridgeutil assumes tracks are 5 m wide (UG TODO the lane data is manky).
    -- Skins and bones help bridges look better, they look segmented without them.
    -- Blender 2.79 has them and they work with the old converter; they are called vertex groups.
    -- I could use 5 models instead of 8, but it does not look good on top.
    -- You can make these models with blender 2.79, using the weight painting (gradient tool helps) on every vertex group.
    -- Don't forget to clean each vertex group, like with meshes.

    -- LOLLO TODO make an invisible path, totally invisible. This way, the mod won't depend on others.
    local railing = {
        railingDir .. 'railing_rep_side_full_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        -- these are useful to avoid funny dark textures on one side, but we use the two-sided material instead
        -- railingDir .. 'railing_rep_side2_full_side.mdl',
        -- railingDir .. 'railing_rep_side2_no_side.mdl',
        -- railingDir .. 'railing_rep_side2_no_side.mdl',
    }

    local config = {
        pillarBase = { stockDir .. 'pillar_btm_side.mdl', pillarDir .. 'pillar_btm_rep.mdl', stockDir .. 'pillar_btm_side2.mdl' },
        pillarRepeat = { stockDir .. 'pillar_rep_side.mdl', pillarDir .. 'pillar_rep_rep.mdl', stockDir .. 'pillar_rep_side2.mdl' },
        pillarTop = { stockDir .. 'pillar_top_side.mdl', pillarDir .. 'pillar_top_rep.mdl', stockDir .. 'pillar_top_side2.mdl' },
        railingBegin = railing,
        railingRepeat = railing,
        railingEnd = railing,
    }

    local updateFn = bridgeutil.makeDefaultUpdateFn(config)
    local newUpdateFn = function(params)
        print('newUpdateFn starting with params =') debugPrint(arrayUtils.cloneOmittingFields(params, {'state'}))
        -- UG TODO
        -- LOLLO NOTE
        -- when making a sharp bend, railingWidth is 10 instead of 0.5 and the lanes are screwed:
        -- this draws pointless artifacts on the sides. When it happens, pillarLength is different from the set value.

        -- params.pillarHeights = {}

        if params.pillarLength ~= _pillarLength then
            params.pillarLength = _pillarLength
            params.pillarWidth = 0.5

            for _, railingInterval in pairs(params.railingIntervals) do
                -- railingInterval.hasPillar = { -1, -1, }
                for _, lane in pairs(railingInterval.lanes) do
                    lane.offset = 0
                    -- lane.type = 0
                end
            end
            params.railingWidth = 0.5
        end

        local results = updateFn(params)
        -- print('newUpdateFn returning =') debugPrint(results)
        return results
    end
    return {
        name = _('PedestrianCementBridgeNoPillarsNoSides'),
        yearFrom = 1960,
        yearTo = 0,
        carriers = { 'ROAD' },
        speedLimit = 20.0 / 3.6,
        pillarLen = _pillarLength,
        pillarMinDist = 120, -- 65535,
        pillarMaxDist = 120, -- 65535,
        pillarTargetDist = 120, -- 65535,
        -- pillarWidth = 2,
        cost = 400.0,
        -- replace street materials, so sharp bends will look better.
        materialsToReplace = {
            streetPaving = {
                -- name = 'street/country_new_medium_paving.mtl',
                name = 'lollo_freestyle_train_station/totally_transparent.mtl'
            },
            streetLane = { -- this is useful
                -- name = 'street/new_medium_lane.mtl',
                -- size = { 2, 1.0 },
                name = 'lollo_freestyle_train_station/totally_transparent.mtl'
            },
            crossingLane = {
                -- name = 'street/new_medium_lane.mtl',
                name = 'lollo_freestyle_train_station/totally_transparent.mtl'
            },
            sidewalkPaving = {
                -- name = 'street/new_medium_sidewalk.mtl',
            },
            sidewalkBorderInner = {
                -- name = 'street/new_medium_sidewalk_border_inner.mtl',
                -- size = { 3, 0.6 },
                name = 'lollo_freestyle_train_station/totally_transparent.mtl'
            },
        },
        noParallelStripSubdivision = true,
        -- updateFn = updateFn,
        updateFn = newUpdateFn,
    }
end
