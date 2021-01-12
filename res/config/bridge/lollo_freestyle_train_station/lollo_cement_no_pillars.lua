local bridgeutil = require 'bridgeutil'

function data()
--    local dirCustom = 'bridge/'
    local dir = 'bridge/cement/'

    local railing = {
        -- dirCustom .. 'railing_rep_side.mdl',
        -- dirCustom .. 'railing_rep_side.mdl',
        dir .. 'railing_rep_side_no_side.mdl',
        dir .. 'railing_rep_side_no_side.mdl',
        dir .. 'railing_rep_side_no_side.mdl',
        dir .. 'railing_rep_rep.mdl',
        dir .. 'railing_rep_rep.mdl',
        -- dirCustom .. 'railing_rep_side2.mdl',
        -- dirCustom .. 'railing_rep_side2.mdl',
        dir .. 'railing_rep_side2_no_side.mdl',
        dir .. 'railing_rep_side2_no_side.mdl',
        dir .. 'railing_rep_side2_no_side.mdl',
    }

    local config = {
        pillarBase = {dir .. 'pillar_btm_side.mdl', dir .. 'pillar_btm_rep.mdl', dir .. 'pillar_btm_side2.mdl'},
        pillarRepeat = {dir .. 'pillar_rep_side.mdl', dir .. 'pillar_rep_rep.mdl', dir .. 'pillar_rep_side2.mdl'},
        pillarTop = {dir .. 'pillar_top_side.mdl', dir .. 'pillar_top_rep.mdl', dir .. 'pillar_top_side2.mdl'},
        railingBegin = railing,
        railingRepeat = railing,
        railingEnd = railing
    }

    return {
        name = _('CementBridgeNoPillars'),
        yearFrom = 0, -- so we don't show it in the bridge menus
        yearTo = 0,
        carriers = {'RAIL', 'ROAD'},
        speedLimit = 320.0 / 3.6,
        pillarLen = 1, -- LOLLO was 3,
        pillarMinDist = 65535, -- LOLLO was 6.0,
        pillarMaxDist = 65535, -- LOLLO was 132.0,
        pillarTargetDist = 65535, -- LOLLO was 48.0,
        cost = 400.0,
        materialsToReplace = {
            streetPaving = {
                name = 'street/country_new_medium_paving.mtl'
            },
            streetLane = {
                name = 'street/new_medium_lane.mtl'
            },
            crossingLane = {
                name = 'street/new_medium_lane.mtl'
            },
            sidewalkPaving = {
                name = 'street/new_medium_sidewalk.mtl'
            },
            sidewalkBorderInner = {
                name = 'street/new_medium_sidewalk_border_inner.mtl',
                size = {3, 0.6}
            }
        },
        updateFn = bridgeutil.makeDefaultUpdateFn(config)
    }
end
