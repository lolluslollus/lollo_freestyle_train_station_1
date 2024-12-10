-- local bridgeutil = require 'bridgeutil'
local pedestrianBridgeUtil = require('lollo_freestyle_train_station.pedestrianBridgeUtil')

function data()
	local pillarDir = 'bridge/lollo_freestyle_train_station/copper_pillars_high/'
	local railingDir = 'bridge/lollo_freestyle_train_station/cement_glass/'

	-- bridgeutil uses the lane width to see how wide a bridge is. However, it does not respect 2.5 m platform-tracks,
	-- it says 0 m instead of 2.5. As a consequence, this fancy bridge only goes with 5 m platforms.
	local railing = {
		railingDir .. 'railing_copper_rep_side_no_side.mdl',
		railingDir .. 'railing_copper_rep_side_no_side.mdl',
		railingDir .. 'railing_copper_rep_side_no_side.mdl',
		railingDir .. 'railing_copper_rep_rep.mdl',
		railingDir .. 'railing_copper_rep_rep.mdl',
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
		_('FranzBridgeCopperNoRoofSpacedPillarsNoSides'),
		config,
		48, 192, 96
	)
end
