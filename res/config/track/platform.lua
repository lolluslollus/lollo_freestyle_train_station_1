function data()
	local t = { }

	t.name = _("Lollo platform tracks")
	t.desc = _("Standard tracks with limited speed capabilities.")

	t.yearFrom = 0
	t.yearTo = 0

	t.shapeWidth = 4.0
	t.shapeStep = 4.0
	t.shapeSleeperStep = 8.0 / 12.0

	t.ballastHeight = .3
	t.ballastCutOff = .1

	t.sleeperBase = t.ballastHeight
	t.sleeperLength = .26
	t.sleeperWidth = 2.6
	t.sleeperHeight = .08
	t.sleeperCutOff = .02

	t.railTrackWidth = 1.435
	t.railBase = t.sleeperBase + t.sleeperHeight
	t.railHeight = .15
	t.railWidth = .07
	t.railCutOff = .02
    
    t.embankmentSlopeLow = 0.75
    t.embankmentSlopeHigh = 2.5

	t.catenaryBase = 5.917 + t.railBase + t.railHeight
	t.catenaryHeight = 1.35
	t.catenaryPoleDistance = 32.0
	t.catenaryMaxPoleDistanceFactor = 2.0
	t.catenaryMinPoleDistanceFactor = 0.8

	t.trackDistance = 5.0

	t.speedLimit = 120.0 / 3.6
	t.speedCoeffs = { .85, 30.0, .6 }		-- curve speed limit = a * (radius + b) ^ c
	
	t.minCurveRadius = 44.0
	t.minCurveRadiusBuild = 60.0
	
	t.maxSlopeBuild = 0.075
	t.maxSlope = t.maxSlopeBuild * 1.6
	t.maxSlopeShape = t.maxSlope * 1.25
	
	t.slopeBuildSteps = 2

	t.ballastMaterial = "track/ballast.mtl"
	t.sleeperMaterial = "track/sleeper.mtl"
	t.railMaterial = "track/rail.mtl"
	t.catenaryMaterial = "track/catenary.mtl"
	t.tunnelWallMaterial = "track/tunnel_rail_ug.mtl"
	t.tunnelHullMaterial = "track/tunnel_hull.mtl"

	-- LOLLO TODO fix the following
	t.catenaryPoleModel = "railroad/power_pole_us_2.mdl"
	t.catenaryMultiPoleModel = "railroad/power_pole_us_1_pole.mdl"
	t.catenaryMultiGirderModel = "railroad/power_pole_us_1a_repeat.mdl"
	t.catenaryMultiInnerPoleModel = "railroad/power_pole_us_1b_pole2.mdl"

	-- LOLLO TODO fix the following
	t.bumperModel = "railroad/bumper.mdl"
	t.switchSignalModel = "railroad/switch_box.mdl"

	-- LOLLO TODO fix the following
	t.fillGroundTex = "ballast_fill.lua"

	-- LOLLO TODO fix the following
	t.borderGroundTex = "ballast.lua"
	
    -- t.railModel ="railroad/tracks/single_rail.mdl"
    t.railModel = 'lollo_freestyle_train_station/platform_2m.mdl'
	-- t.sleeperModel = "railroad/tracks/single_sleeper_base.mdl"
	t.trackStraightModel = {
		'lollo_freestyle_train_station/platform_2m_base.mdl', --"railroad/tracks/2m_base.mdl",
		'lollo_freestyle_train_station/platform_4m_base.mdl', --"railroad/tracks/4m_base.mdl",
		'lollo_freestyle_train_station/platform_8m_base.mdl', --"railroad/tracks/8m_base.mdl",
		'lollo_freestyle_train_station/platform_16m_base.mdl', --"railroad/tracks/16m_base.mdl",
	}

	t.cost = 75.0

	return t
end
