function data()
    return {
        numLanes = 2,
        -- transportModesStreet = {'PERSON'}, -- dumps
        -- transportModesStreet = {'TRUCK'}, -- it dumps with an empty array or with {'PERSON'}; savegames dump with {'TRUCK'}
        sidewalkWidth = 0.4,
        sidewalkHeight = 0.0,
        streetWidth = 0.2,
        yearFrom = 0,
        yearTo = 0,
        aiLock = true,
        visibility = true,
        country = false,
        speed = 20.0,
        type = 'lollo_1m_path_concrete',
        name = _("1 Metre Concrete Path"),
        desc = _("1 metre concrete path with a speed limit of %2%; give it a bus lane or install the street fine tuning to pedestrianise it. It matches the freestyle station and the \"stairs\" asset, era C."),
        categories = { 'paths' },
        order = 3,
        busAndTramRight = true,
        -- slopeBuildSteps = 1,
        embankmentSlopeLow  = 0.75,
        embankmentSlopeHigh  = 2.5,
        borderGroundTex = "street_border.lua",
        materials = {
            -- sidewalkBorderOuter = {
            --     name = "street/old_medium_sidewalk_border_outer.mtl",
            --     -- size = { 16.0, 0.41602 }
            --     size = { 16.0, 0.2 }
            -- },
            sidewalkPaving = {
                name = "lollo_freestyle_train_station/station_concrete_1_z.mtl",
                size = { 4.0, 4.0 }
            },
            streetPaving = {
                name = "lollo_freestyle_train_station/station_concrete_1_z.mtl",
                size = { 4.0, 4.0 }
            },
        },
        catenary = {
            pole = { name = "lollo_freestyle_train_station/empty.mdl" },
            poleCrossbar = { name = "lollo_freestyle_train_station/empty.mdl" },
            poleDoubleCrossbar = { name = "lollo_freestyle_train_station/empty.mdl" },
            isolatorStraight = "lollo_freestyle_train_station/empty.mdl";
            isolatorCurve =  "lollo_freestyle_train_station/empty.mdl";
            junction = "lollo_freestyle_train_station/empty.mdl";
        },
        assets = {},
        cost = 1.0
    }
end
