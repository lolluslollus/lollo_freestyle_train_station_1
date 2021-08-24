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
        type = 'lollo_1m_path_concrete',
        name = _("1 Metre Concrete Path"),
        desc = _("1 metre concrete path with a speed limit of %2%, give it a bus lane to pedestrianise it."),
        categories = { 'paths' },
        order = 1,
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
                -- name = "street/old_medium_sidewalk.mtl",
                -- name = "lollo_freestyle_train_station/bridge/cement_no_pattern.mtl",
                -- name = "lollo_freestyle_train_station/bridge/lighter_cement_no_pattern.mtl",
                -- name = "lollo_freestyle_train_station/bridge/cement_shrunk.mtl",
                name = "lollo_freestyle_train_station/station_concrete_1_low_prio.mtl",
                size = { 4.0, 4.0 }
            },
            streetPaving = {
                -- name = "street/old_medium_sidewalk.mtl",
                -- name = "lollo_freestyle_train_station/bridge/cement_no_pattern.mtl",
                -- name = "lollo_freestyle_train_station/bridge/lighter_cement_no_pattern.mtl",
                -- name = "lollo_freestyle_train_station/bridge/cement_shrunk.mtl",
                name = "lollo_freestyle_train_station/station_concrete_1_low_prio.mtl",
                size = { 4.0, 4.0 }
            },
        },
        assets = {},
        cost = 1.0
    }
end
