-- local bridgeutil = require 'bridgeutil'
local bridgeutil = require('lollo_freestyle_train_station.bridgeUtil')

function data()
    local pillarDir = 'bridge/lollo_freestyle_train_station/cement_pillars/'
    local railingDir = 'bridge/lollo_freestyle_train_station/cement_no_sides/'

    local railing = {
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_side_no_side.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        railingDir .. 'railing_rep_rep.mdl',
        -- dir .. 'railing_rep_side2_no_side.mdl',
        -- dir .. 'railing_rep_side2_no_side.mdl',
        -- dir .. 'railing_rep_side2_no_side.mdl',
    }

    local config = {
        pillarBase = { pillarDir .. 'pillar_btm_side.mdl', pillarDir .. 'pillar_btm_rep.mdl', pillarDir .. 'pillar_btm_side2.mdl' },
        pillarRepeat = { pillarDir .. 'pillar_rep_side.mdl', pillarDir .. 'pillar_rep_rep.mdl', pillarDir .. 'pillar_rep_side2.mdl' },
        pillarTop = { pillarDir .. 'pillar_top_side.mdl', pillarDir .. 'pillar_top_rep.mdl', pillarDir .. 'pillar_top_side2.mdl' },
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
