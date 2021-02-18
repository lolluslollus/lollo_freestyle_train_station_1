local bridgeutil = require 'bridgeutil'

function data()
    local pillarDir = 'bridge/lollo_freestyle_train_station/iron_pillars/'
    local railingDir = 'bridge/lollo_freestyle_train_station/iron_no_sides/'
    -- local stockIronDir = 'bridge/iron/'
    local stockSuspensionDir = 'bridge/suspension/'

    local railing = {
        railingDir .. "railing_rep_2_no_side.mdl",
        railingDir .. "railing_rep_2_no_side.mdl",
        railingDir .. "railing_rep_2_no_side.mdl",
        railingDir .. "railing_rep_2_rep.mdl",
        railingDir .. "railing_rep_2_rep.mdl",
        -- railingDir .. "railing_rep_rep.mdl",
        -- railingDir .. "railing_rep_rep.mdl",
        railingDir .. "railing_rep_2_no_side_2.mdl",
        railingDir .. "railing_rep_2_no_side_2.mdl",
        railingDir .. "railing_rep_2_no_side_2.mdl",
    }

    local config = {
        pillarBase = { pillarDir .. "pillar_2_btm_side.mdl", pillarDir .. "pillar_2_btm_rep.mdl", pillarDir .. "pillar_2_btm_side_2.mdl" },
        pillarRepeat = { pillarDir .. "pillar_2_rep_side.mdl", pillarDir .. "pillar_2_rep_rep.mdl", pillarDir .. "pillar_2_rep_side_2.mdl" },
        pillarTop = { pillarDir .. "pillar_2_top_side.mdl", pillarDir .. "pillar_2_top_rep.mdl", pillarDir .. "pillar_2_top_side_2.mdl" },
        railingBegin = railing,
        railingRepeat = railing,
        railingEnd = railing,
    }

    return {
        name = _('IronBridgeNormalPillarsNoSides'),
        yearFrom = 1850,
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
