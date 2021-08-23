local bridgeutil = require 'bridgeutil'

function data()
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

    -- LOLLO TODO make an invisible path, totally invisible. This way, sharp bends will look better.
    -- LOLLO TODO add railings to meshes
    -- LOLLO TODO make icon
    local railing = {
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_side2_no_side.mdl', -- these are useful to avoid funny dark textures on one side
        railingDir .. 'railing_rep_side2_no_side.mdl',
        railingDir .. 'railing_rep_side2_no_side.mdl',
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
        print('newUpdateFn starting with params =')
        print('params.pillarHeights = ') debugPrint(params.pillarHeights)
        print('params.pillarLength = ') debugPrint(params.pillarLength)
        print('params.pillarWidth = ') debugPrint(params.pillarWidth)
        print('params.railingIntervals = ') debugPrint(params.railingIntervals)
        print('params.railingWidth = ') debugPrint(params.railingWidth)
        -- UG TODO
        -- LOLLO NOTE
        -- when making a sharp bend, railingWidth is 10 instead of 0.5 and the lanes are screwed:
        -- this draws pointless artifacts on the sides
        params.pillarHeights = {}
        params.pillarLength = 0
        params.pillarWidth = 0
        for key, value in pairs(params.railingIntervals) do
            value.hasPillar = { -1, -1, }
            value.lanes = {
              {
                offset = 0,
                type = 0,
              },
            }
        end
        params.railingWidth = 0.5

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
        pillarLen = 3,
        pillarMinDist = 65535,
        pillarMaxDist = 65535,
        pillarTargetDist = 65535,
        -- pillarWidth = 2,
        cost = 400.0,
        materialsToReplace = {
            -- streetPaving = {
            --     name = 'street/country_new_medium_paving.mtl',
            -- },
            -- streetLane = { -- this is useful
            --     name = 'street/new_medium_lane.mtl',
            --     size = { 2, 1.0 },
            -- },
            -- crossingLane = {
            --     name = 'street/new_medium_lane.mtl',
            -- },
            -- sidewalkPaving = {
            --     name = 'street/new_medium_sidewalk.mtl',
            -- },
            -- sidewalkBorderInner = {
            --     name = 'street/new_medium_sidewalk_border_inner.mtl',
            --     size = { 3, 0.6 },
            -- },
        },
        noParallelStripSubdivision = false,
        -- updateFn = updateFn,
        updateFn = newUpdateFn,
    }
end
