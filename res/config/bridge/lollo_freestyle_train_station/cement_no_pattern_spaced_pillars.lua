local bridgeutil = require 'bridgeutil'

function data()
	local dir = 'bridge/cement/'
    local customDir = 'bridge/lollo_freestyle_train_station/cement_glass/'

	local railing = {
		-- customDir .. 'railing_rep_side_glass_deco.mdl',
		-- customDir .. 'railing_rep_side_glass_deco.mdl',

		customDir .. 'railing_rep_side_glass_deco_old_fashioned.mdl',
		customDir .. 'railing_rep_side_glass_deco_old_fashioned.mdl',
		customDir .. 'railing_rep_side_no_side_old_fashioned.mdl',
		customDir .. 'railing_rep_rep_old_fashioned.mdl',
		customDir .. 'railing_rep_rep_old_fashioned.mdl',

		-- customDir .. 'railing_rep_side2_glass_deco.mdl',
		-- customDir .. 'railing_rep_side2_glass_deco.mdl',
		customDir .. 'railing_rep_side2_glass_deco_old_fashioned.mdl',
		customDir .. 'railing_rep_side2_glass_deco_old_fashioned.mdl',
		customDir .. 'railing_rep_side2_no_side_old_fashioned.mdl',
	}

	local config = {
		pillarBase = { dir .. 'pillar_btm_side.mdl', dir .. 'pillar_btm_rep.mdl', dir .. 'pillar_btm_side2.mdl' },
		pillarRepeat = { dir .. 'pillar_rep_side.mdl', dir .. 'pillar_rep_rep.mdl', dir .. 'pillar_rep_side2.mdl' },
		pillarTop = { dir .. 'pillar_top_side.mdl', dir .. 'pillar_top_rep.mdl', dir .. 'pillar_top_side2.mdl' },
		railingBegin = railing,
		railingRepeat = railing,
		railingEnd = railing,
	}

	return {
		name = _('CementBridgeGlassWallSpacedPillars'),
		yearFrom = 0,
		yearTo = 0,
		carriers = { 'RAIL', 'ROAD' },
		speedLimit = 320.0 / 3.6,
		pillarLen = 3,
		pillarMinDist = 48.0,
		pillarMaxDist = 192.0,
		pillarTargetDist = 96.0,
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
