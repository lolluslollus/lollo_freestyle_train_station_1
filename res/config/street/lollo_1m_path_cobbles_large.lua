function data()
    return {
        numLanes = 2,
        -- transportModesStreet = {'PERSON'}, -- dumps
        -- transportModesStreet = {'TRUCK'}, -- it dumps with an empty array or with {'PERSON'}; savegames dump with {'TRUCK'}
        sidewalkWidth = 0.4,
        sidewalkHeight = 0.0,
        streetWidth = 0.2,
        yearFrom = game.config.busLaneYearFrom,
        yearTo = 0,
        aiLock = true,
        visibility = true,
        country = false,
        speed = 20.0,
        type = 'lollo_1m_path_cobbles_large',
        name = _("1 Metre Large-Cobbled Path"),
        desc = _("1 metre large-cobbled path with a speed limit of %2%, give it a bus lane or install the street fine tuning to pedestrianise it. It matches the freestyle station era B."),
        categories = { 'paths' },
        order = 2,
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
                name = "lollo_freestyle_train_station/square_cobbles_large_z.mtl",
                size = { 2.0, 2.0 }
            },
            streetPaving = {
                name = "lollo_freestyle_train_station/square_cobbles_large_z.mtl",
                size = { 2.0, 2.0 }
            },
        },
        assets = {},
        cost = 1.0
    }
end
