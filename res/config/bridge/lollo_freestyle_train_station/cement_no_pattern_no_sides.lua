local bridgeutil = require 'bridgeutil'

function data()
    local pillarDir = 'bridge/lollo_freestyle_train_station/cement_pillars/'
    local railingDir = 'bridge/lollo_freestyle_train_station/cement_no_sides/'
    local stockDir = 'bridge/cement/'

    local railing = {
        stockDir .. 'railing_rep_side_no_side.mdl',
        stockDir .. 'railing_rep_side_no_side.mdl',
        stockDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        stockDir .. 'railing_rep_side2_no_side.mdl',
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
        name = _('CementBridgeNormalPillarsNoSides'),
        yearFrom = 1960,
        yearTo = 0,
        carriers = { 'RAIL', 'ROAD' },
        speedLimit = 320.0 / 3.6,
        pillarLen = 3,
        pillarMinDist = 6.0,
        pillarMaxDist = 132.0,
        pillarTargetDist = 48.0,
        -- pillarWidth = 2,
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
