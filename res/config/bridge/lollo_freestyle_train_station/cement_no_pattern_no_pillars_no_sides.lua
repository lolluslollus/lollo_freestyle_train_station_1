local bridgeutil = require 'bridgeutil'
-- local bridgeutil = require('lollo_freestyle_train_station.bridgeUtil')

function data()
    local pillarDir = 'bridge/lollo_freestyle_train_station/cement_pillars/'
    local railingDir = 'bridge/lollo_freestyle_train_station/cement_no_sides/'
    local stockDir = 'bridge/cement/'

    -- LOLLO NOTE bridgeutil receives a list of models of bridge parts, each with its bounding box,
    -- then places them together depending on this information.
    -- Either we rewrite the whole thing, or we use the automatisms. So we go for number two.
    -- the *_rep models have a mesh 0.5 m wide instead of 4, and same with the bounding box.
    -- This applies to railing and pillars.
    -- This allows them to fit below 2.5 m platform-tracks.
    -- Sadly, any sorts of sides won't work with 2.5 m platforms coz bridgeutil assumes tracks are 5 m wide.
    local railing = {
        stockDir .. 'railing_rep_side_no_side.mdl',
        stockDir .. 'railing_rep_side_no_side.mdl',
        stockDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        stockDir .. 'railing_rep_side2_no_side.mdl', -- these are useful to avoid funny dark textures on one side
        stockDir .. 'railing_rep_side2_no_side.mdl',
        stockDir .. 'railing_rep_side2_no_side.mdl',
    }

    local config = {
        pillarBase = { stockDir .. 'pillar_btm_side.mdl', pillarDir .. 'pillar_btm_rep.mdl', stockDir .. 'pillar_btm_side2.mdl' },
        pillarRepeat = { stockDir .. 'pillar_rep_side.mdl', pillarDir .. 'pillar_rep_rep.mdl', stockDir .. 'pillar_rep_side2.mdl' },
        pillarTop = { stockDir .. 'pillar_top_side.mdl', pillarDir .. 'pillar_top_rep.mdl', stockDir .. 'pillar_top_side2.mdl' },
        railingBegin = railing,
        railingRepeat = railing,
        railingEnd = railing,
    }

    return {
        name = _('CementBridgeNoPillarsNoSides'),
        yearFrom = 1960,
        yearTo = 0,
        carriers = { 'RAIL', 'ROAD' },
        speedLimit = 320.0 / 3.6,
        pillarLen = 3,
        pillarMinDist = 65535,
        pillarMaxDist = 65535,
        pillarTargetDist = 65535,
        pillarWidth = 2,
        cost = 400.0,
        materialsToReplace = {
            streetPaving = {
                name = 'street/country_new_medium_paving.mtl',
            },
            streetLane = {
                name = 'street/new_medium_lane.mtl',
            },
            crossingLane = {
                name = 'street/new_medium_lane.mtl',
            },
            sidewalkPaving = {
                name = 'street/new_medium_sidewalk.mtl',
            },
            sidewalkBorderInner = {
                name = 'street/new_medium_sidewalk_border_inner.mtl',
                size = { 3, 0.6 },
            },
        },
        updateFn = bridgeutil.makeDefaultUpdateFn(config),
    }
end
