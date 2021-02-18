-- local bridgeutil = require 'bridgeutil'
local bridgeutil = require('lollo_freestyle_train_station.bridgeUtil')

function data()
    local pillarDir = 'bridge/lollo_freestyle_train_station/cement_pillars/'
	local railingDir = 'bridge/lollo_freestyle_train_station/cement_glass/'
	local stockDir = 'bridge/cement/'

	local railing = {
		railingDir .. 'railing_rep_side_glass_shield_roof.mdl',
		railingDir .. 'railing_rep_side_glass_shield.mdl',
		railingDir .. 'railing_rep_side_no_side.mdl',
		railingDir .. 'railing_rep_rep_roof.mdl',
		railingDir .. 'railing_rep_rep.mdl',
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
		name = _('CementBridgeGlassWallNoPillars'),
		yearFrom = 1960,
		yearTo = 0,
		carriers = { 'RAIL', 'ROAD' },
		speedLimit = 320.0 / 3.6,
		pillarLen = 3,
		pillarMinDist = 65535,
		pillarMaxDist = 65535,
		pillarTargetDist = 65535,
		noParallelStripSubdivision = true,
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
