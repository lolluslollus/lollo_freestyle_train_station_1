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
        type = 'lollo_1m_path_cobbles_bridge',
        name = _("1 Metre Cobbled Bridge"),
        desc = _("1 metre cobbled bridge with a speed limit of %2%. It matches the freestyle station and the \"stairs\" asset, era A. Build one and it will turn into a bridge automatically."),
        categories = { 'paths-on-forced-bridge' }, -- either this or paths, not both or the game script might get confused.
        order = 1,
        busAndTramRight = true,
        -- slopeBuildSteps = 1,
        embankmentSlopeLow  = 0.75,
        embankmentSlopeHigh  = 2.5,
        -- borderGroundTex = "street_border.lua",
        materials = {
            -- sidewalkBorderOuter = {
            --     name = "street/old_medium_sidewalk_border_outer.mtl",
            --     -- size = { 16.0, 0.41602 }
            --     size = { 16.0, 0.2 }
            -- },
            sidewalkPaving = {
                name = "lollo_freestyle_train_station/square_cobbles_z.mtl",
                size = { 2.0, 2.0 }
            },
            streetPaving = {
                name = "lollo_freestyle_train_station/square_cobbles_z.mtl",
                size = { 2.0, 2.0 }
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
