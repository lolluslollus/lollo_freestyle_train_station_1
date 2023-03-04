-- local bridgeutil = require 'bridgeutil'
local pedestrianBridgeUtil = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

function data()
	local pillarDir = 'bridge/lollo_freestyle_train_station/iron_pillars_high/'
	local railingDir = 'bridge/lollo_freestyle_train_station/cement_glass/'

	-- bridgeutil uses the lane width to see how wide a bridge is. However, it does not respect 2.5 m platform-tracks,
	-- it says 0 m instead of 2.5. As a consequence, this fancy bridge only goes with 5 m platforms.
	local railing = {
		railingDir .. 'railing_rep_side_glass_shield_roof.mdl',
		railingDir .. 'railing_rep_side_glass_shield.mdl',
		railingDir .. 'railing_rep_side_no_side.mdl',
		railingDir .. 'railing_rep_rep_roof.mdl',
		railingDir .. 'railing_rep_rep.mdl',
	}

	local config = {
		pillarBase = { pillarDir .. "pillar_2_btm_side.mdl", pillarDir .. "pillar_2_btm_rep.mdl", pillarDir .. "pillar_2_btm_side_2.mdl" },
        pillarRepeat = { pillarDir .. "pillar_2_rep_side.mdl", pillarDir .. "pillar_2_rep_rep.mdl", pillarDir .. "pillar_2_rep_side_2.mdl" },
        pillarTop = { pillarDir .. "pillar_2_top_side.mdl", pillarDir .. "pillar_2_top_rep.mdl", pillarDir .. "pillar_2_top_side_2.mdl" },
		railingBegin = railing,
		railingRepeat = railing,
		railingEnd = railing,
	}

	return pedestrianBridgeUtil.getData4CementGlassBridge(
		_('CementBridgeGlassWallNoPillars'),
		config,
		65535, 65535, 65535
	)
--[[
	return {
		name = _('CementBridgeGlassWallNoPillars'),
		yearFrom = 0,
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
		-- updateFn = bridgeutil.makeDefaultUpdateFn(config),
	}
]]
end
