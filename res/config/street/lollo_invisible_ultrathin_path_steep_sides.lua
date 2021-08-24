function data()
    return {
        numLanes = 2,
        -- transportModesStreet = {'PERSON'}, -- dumps
        -- transportModesStreet = {'TRUCK'}, -- it dumps with an empty array or with {'PERSON'}; savegames dump with {'TRUCK'}
        sidewalkWidth = 0.2,
        sidewalkHeight = .0,
        streetWidth = 0.1,
        yearFrom = 0,
        yearTo = 0,
        aiLock = true,
        visibility = true,
        country = true,
        speed = 20.0,
        type = 'lollo_invisible_ultrathin_path',
        name = _("Invisible ultrathin path with steep enbankment"),
        desc = _("Invisible ultrathin path with a speed limit of %2%, give it a bus lane to pedestrianise it."),
        categories = { 'paths' },
        order = 3,
        busAndTramRight = true,
        slopeBuildSteps = 4,
        embankmentSlopeLow  = 0.0,
        embankmentSlopeHigh  = 9.9,
        materials = {
            -- streetPaving = {
            --     name = 'street/country_new_medium_paving.mtl',
            --     size = {1.0, 1.0}
            -- },
        },
        assets = {},
        cost = 1.0
    }
end
