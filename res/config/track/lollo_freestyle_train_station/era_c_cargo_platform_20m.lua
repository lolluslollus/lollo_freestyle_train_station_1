function data()
	local _constants = require('lollo_freestyle_train_station.constants')

	local t = { }

	t.name = _("CargoPlatform20MTracksName")
	t.desc = _("CargoPlatform20MTracksDesc")
	t.categories  = { _constants.cargoPlatformTracksCategory }
	t.icon = "ui/lollo_freestyle_train_station/era_c_cargo_platform_20m.tga"

	t.yearFrom = 0
	t.yearTo = 0

	-- sets the width of the terrain enbankment, all out (ie including ballastCutOff).
	-- It can override trackDistance!
	t.shapeWidth = 19.0 -- was 4.0
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

	t.catenaryBase = 0 -- 5.917 + t.railBase + t.railHeight -- [m] base height of the cable over ground level
	t.catenaryHeight = 0 -- 1.35 -- [m] height of the support cable at the poles
	t.catenaryPoleDistance = 999 -- 32.0 -- [m] target distance between poles
	t.catenaryMaxPoleDistanceFactor = 999 -- 2.0
	t.catenaryMinPoleDistanceFactor = 999 -- 0.8

	t.trackDistance = 20.0 -- was 5.0 -- [m] distance between track centers when dragging parallel tracks

	t.speedLimit = 5.0 / 3.6 -- [m/s] maximum speed on a straight track
	t.speedCoeffs = { .85, 30.0, .6 } -- curve speed limit = a * (radius + b) ^ c
	
	t.minCurveRadius = 44.0 -- [m] minimal radius when snapping (and parallel tracks)
	t.minCurveRadiusBuild = 60.0 -- [m] minimal radius when dragging
	
	t.maxSlopeBuild = 0.075
	t.maxSlope = t.maxSlopeBuild * 1.6
	t.maxSlopeShape = t.maxSlope * 1.25
	
	t.slopeBuildSteps = 3 -- was 2 -- [1-4] steps for slope arrow buttons

	-- t.ballastMaterial = -- "track/ballast.mtl" "lollo_freestyle_train_station/station_concrete_1.mtl"
	t.ballastMaterial = "lollo_freestyle_train_station/station_concrete_1.mtl"
	t.sleeperMaterial = "track/sleeper.mtl"
	t.railMaterial = "track/rail.mtl"
	t.catenaryMaterial = "track/catenary.mtl"
	t.tunnelWallMaterial = "track/tunnel_rail_ug.mtl"
	t.tunnelHullMaterial = "track/tunnel_hull.mtl"

	t.catenaryPoleModel = "lollo_freestyle_train_station/empty.mdl" -- "railroad/power_pole_us_2.mdl"
	t.catenaryMultiPoleModel = "lollo_freestyle_train_station/empty.mdl" -- "railroad/power_pole_us_1_pole.mdl"
	t.catenaryMultiGirderModel = "lollo_freestyle_train_station/empty.mdl" -- "railroad/power_pole_us_1a_repeat.mdl"
	t.catenaryMultiInnerPoleModel = "lollo_freestyle_train_station/empty.mdl" -- "railroad/power_pole_us_1b_pole2.mdl"

	-- t.bumperModel = "railroad/bumper.mdl"
	t.bumperModel = "lollo_freestyle_train_station/railroad/track/railing_3m.mdl"
	-- t.switchSignalModel = "railroad/switch_box.mdl"

	t.fillGroundTex = "industry_floor_paving.lua" -- "industry_concrete_01.lua" -- "none.lua" -- "ballast_fill.lua"
	t.borderGroundTex = "none.lua" -- "ballast.lua"
	
    -- t.railModel ="railroad/tracks/single_rail.mdl"
	-- t.railModel = 'lollo_freestyle_train_station/railroad/track/platform_2m.mdl'
	t.railModel = "lollo_freestyle_train_station/empty.mdl"
    -- t.sleeperModel = "railroad/tracks/single_sleeper_base.mdl"
	-- t.sleeperModel = "lollo_freestyle_train_station/empty.mdl"
	t.sleeperModel = "lollo_freestyle_train_station/railroad/track/era_c_cargo_sleeper_20m_wide.mdl"
	t.trackStraightModel = {
		'lollo_freestyle_train_station/railroad/track/era_c_cargo_platform_2m_base_20m_wide.mdl', --"railroad/tracks/2m_base.mdl",
		'lollo_freestyle_train_station/railroad/track/era_c_cargo_platform_4m_base_20m_wide.mdl', --"railroad/tracks/4m_base.mdl",
		'lollo_freestyle_train_station/railroad/track/era_c_cargo_platform_8m_base_20m_wide.mdl', --"railroad/tracks/8m_base.mdl",
		'lollo_freestyle_train_station/railroad/track/era_c_cargo_platform_16m_base_20m_wide.mdl', --"railroad/tracks/16m_base.mdl",
	}

	t.maintenanceCost = 0.0   -- [$/m/M] per meter and month
	t.cost = 75.0 -- [$/m] per meter

	return t
end
