local helpers = {}
local _cargoPlatformZ = -0.03

helpers.getCargoAreaInner4x4BoundingInfo = function()
    return {
        bbMax = { 1.9, 1.9, 5 },
        bbMin = { -1.9, -1.9, 0 },
    }
end

helpers.getCargoAreaInner4x4Collider = function()
    return {
        params = {
            halfExtents = { 1.9, 1.9, 2.7, },
        },
        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2.3, 1, },
        type = 'BOX',
    }
end

helpers.getCargoAreaInner4x4Lods = function()
    local _materials = { 'street/new_medium_sidewalk.mtl', 'street/new_medium_sidewalk.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/tarmac_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner4x4EarthLods = function()
    return {
        {
            node = {
                children = {
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner4x4GravelLods = function()
    return {
        {
            node = {
                children = {
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner4x4Metadata = function()
    local _cargoNodeZ = 0.3
    return {
        transportNetworkProvider = {
            laneLists = {
                {
                    linkable = true, -- false, --true,
                    nodes = {
                        {
                            { 2, 0, _cargoNodeZ }, -- edge 0
                            { -4, 0, 0 },
                            3,
                        },
                        {
                            { -2, 0, _cargoNodeZ },
                            { -4, 0, 0 },
                            3,
                        },
                        -- lanes across 1
                        {
                            { 1.8, 2, _cargoNodeZ }, -- edge 1
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 2, 0, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 2, 0, _cargoNodeZ }, -- edge 2
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 1.8, -2, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        -- lanes across 2
                        {
                            { -1.8, -2, _cargoNodeZ }, -- edge 3
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -2, 0, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -2, 0, _cargoNodeZ }, -- edge 10
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -1.8, 2, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                    },
                    transportModes = { 'CARGO', },
                    speedLimit = 30,
                },
            },
            runways = { },
            terminals = {
                {
                    -- order = 0,
                    personEdges = { 0 },
                    personNodes = { 0, 1 },
                    -- vehicleNode = -1, -- 0,
                },
            },
        },
    }
end

helpers.getCargoLinks4x4Metadata = function()
    local result = helpers.getCargoAreaInner4x4Metadata()
    result.transportNetworkProvider.terminals = {
        {
            -- order = 0,
            -- personEdges = { 0 },
            personEdges = { },
            -- personNodes = { 0, 1 },
            personNodes = { },
            -- vehicleNode = -1, -- 0,
        },
    }
    return result
end

helpers.getCargoAreaInner5x5BoundingInfo = function()
    return {
        bbMax = { 2.4, 2.4, 2 },
        bbMin = { -2.4, -2.4, 0 },
    }
end

helpers.getCargoAreaInner5x5Collider = function()
    return {
        params = {
            halfExtents = { 2.4, 2.4, 1.0, },
        },
        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        type = 'BOX',
    }
end

helpers.getVoidBoundingInfo = function()
    return {} -- this seems the same as the following
    -- return {
    --     bbMax = { 0, 0, 0 },
    --     bbMin = { 0, 0, 0 },
    -- }
end

helpers.getVoidCollider = function()
    -- return {
    --     params = {
    --         halfExtents = { 0, 0, 0, },
    --     },
    --     transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
    --     type = 'BOX',
    -- }
    return {
        type = 'NONE'
    }
end

helpers.getCargoAreaInner5x5Lods = function()
    local _materials = { 'street/new_medium_sidewalk.mtl', 'street/new_medium_sidewalk.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -2.5, -2.5, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 2.5, -2.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner5x5EarthLods = function()
    local _materials = { 'lollo_lorry_station/earth.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/lollo5x5.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2.5, -2.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoLinksEnhanced4x4Lods = function()
    return {
        {
            node = {
                children = {
                    {
                        materials = { 'lollo_lorry_station/links_enhanced.mtl' },
                        mesh = 'lollo_lorry_station/lollo4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x01.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, -0.00, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 100,
        },
    }
end

helpers.getCargoLinks4x4Lods = function()
    return {
        {
            node = {
                children = {
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x01.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, -0.00, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 100,
        },
    }
end

helpers.getCargoLinks5x5Lods = function()
    local _materials = { 'lollo_lorry_station/links.mtl' }
    return {
        {
            -- node = {
            --     children = {
			-- 		{
			-- 			materials = { "asset/tram_pole.mtl", },
			-- 			mesh = "asset/lod_0_cable_junction.msh",
			-- 			transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
			-- 		},
			-- 	},
            --     name = 'RootNode',
            --     transf = { 10, 0, 0, 0,  0, 10, 0, 0,  0, 0, 10, 0, 0, 0, 0, 1, },
            -- },
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/lollo5x5.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2.5, -2.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 50,
        },
    }
end

helpers.getCargoAreaInner5x5GravelLods = function()
    local _materials = { 'lollo_lorry_station/gravel.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/lollo5x5.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2.5, -2.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner5x5Metadata = function()
    local _cargoNodeZ = 0.3
    return {
        transportNetworkProvider = {
            laneLists = {
                {
                    linkable = true, -- false, --true,
                    nodes = {
                        {
                            { 2.50000, -1.25, _cargoNodeZ }, -- edge 0
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 2.00000, -1.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 2.00000, -1.25, _cargoNodeZ }, -- edge 1
                            { -4, 0, 0 },
                            3,
                        },
                        {
                            { -2.00000, -1.25, _cargoNodeZ },
                            { -4, 0, 0 },
                            3,
                        },
                        {
                            { -2.00000, -1.25, _cargoNodeZ }, -- edge 2
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { -2.50000, -1.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },

                        {
                            { -2.50000, 1.25, _cargoNodeZ }, -- edge 3
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -2.00000, 1.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -2.00000, 1.25, _cargoNodeZ }, -- edge 4
                            { 4, 0, 0 },
                            3,
                        },
                        {
                            { 2.00000, 1.25, _cargoNodeZ },
                            { 4, 0, 0 },
                            3,
                        },
                        {
                            { 2.00000, 1.25, _cargoNodeZ }, -- edge 5
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { 2.50000, 1.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        -- lanes across 1
                        {
                            { 2, 2.5, _cargoNodeZ }, -- edge 6
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, 1.25, _cargoNodeZ },
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, 1.25, _cargoNodeZ }, -- edge 7
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, -1.25, _cargoNodeZ },
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, -1.25, _cargoNodeZ }, -- edge 8
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, -2.5, _cargoNodeZ },
                            { 0, -1.25, 0 },
                            3,
                        },
                        -- lanes across 2
                        {
                            { -2, -2.5, _cargoNodeZ }, -- edge 9
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, -1.25, _cargoNodeZ },
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, -1.25, _cargoNodeZ }, -- edge 10
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, 1.25, _cargoNodeZ },
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, 1.25, _cargoNodeZ }, -- edge 11
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, 2.5, _cargoNodeZ },
                            { 0, 1.25, 0 },
                            3,
                        },
                    },
                    transportModes = { 'CARGO', },
                    speedLimit = 30,
                },
            },
            runways = { },
            terminals = {
                {
                    -- order = 0,
                    personEdges = { 1, 4 },
                    personNodes = { 2, 3, 8, 9 },
                    -- vehicleNode = -1, -- 0,
                },
            },
        },
    }
end

helpers.getCargoAreaInner12x12BoundingInfo = function()
    return {
        bbMax = { 5.9, 5.9, 5 },
        bbMin = { -5.9, -5.9, 0 },
    }
end

helpers.getCargoAreaInner12x12Collider = function()
    return {
        params = {
            halfExtents = { 5.9, 5.9, 2.7, },
        },
        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2.3, 1, },
        type = 'BOX',
    }
end

helpers.getCargoAreaInner12x12Lods = function()
    local _materials = { 'street/new_medium_sidewalk.mtl', 'street/new_medium_sidewalk.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/tarmac_12x12.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner12x12EarthLods = function()
    return {
        {
            node = {
                children = {
                --     {
                --         materials = _materials,
                --         mesh = 'lollo_lorry_station/lollo12x12.msh',
                --         transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -6, _cargoPlatformZ, 1, },
                --     },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner12x12GravelLods = function()
    return {
        {
            node = {
                children = {
                --     {
                --         materials = _materials,
                --         mesh = 'lollo_lorry_station/lollo12x12.msh',
                --         transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -6, _cargoPlatformZ, 1, },
                --     },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'lollo_lorry_station/power_pole.mtl' },
                        mesh = 'lollo_lorry_station/cargo_roof_grid_4x4.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2, 2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, -6, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, -2, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = { 'street/new_medium_sidewalk.mtl' },
                        mesh = 'lollo_lorry_station/tyre-tracks-4x4x03.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 2, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner12x12Metadata = function()
    local _cargoNodeZ = 0.3
    return {
        transportNetworkProvider = {
            laneLists = {
                {
                    linkable = true,
                    nodes = {
                        {
                            { 6, -4, _cargoNodeZ }, -- edge 0
                            { -12, 0, 0 },
                            3,
                        },
                        {
                            { -6, -4, _cargoNodeZ },
                            { -12, 0, 0 },
                            3,
                        },
                        {
                            { 6, 0, _cargoNodeZ }, -- edge 1
                            { -12, 0, 0 },
                            3,
                        },
                        {
                            { -6, 0, _cargoNodeZ },
                            { -12, 0, 0 },
                            3,
                        },
                        {
                            { 6, 4, _cargoNodeZ }, -- edge 2
                            { -12, 0, 0 },
                            3,
                        },
                        {
                            { -6, 4, _cargoNodeZ },
                            { -12, 0, 0 },
                            3,
                        },
                        -- lanes across 1
                        {
                            { 5.8, 6, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, 4, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, 4, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 5.8, 2, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 5.8, 2, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, 0, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, 0, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 5.8, -2, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 5.8, -2, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, -4, _cargoNodeZ },
                            { 0.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, -4, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        {
                            { 5.8, -6, _cargoNodeZ },
                            { -0.2, -2, 0 },
                            3,
                        },
                        -- lanes across 2
                        {
                            { -5.8, -6, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, -4, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, -4, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -5.8, -2, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -5.8, -2, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, 0, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, 0, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -5.8, 2, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -5.8, 2, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, 4, _cargoNodeZ },
                            { -0.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, 4, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        {
                            { -5.8, 6, _cargoNodeZ },
                            { 0.2, 2, 0 },
                            3,
                        },
                        -- diagonal lanes to match small cargo area
                        {
                            { -1.8, -6, _cargoNodeZ }, -- edge 33
                            { -4.2, 2, 0 },
                            3,
                        },
                        {
                            { -6, -4, _cargoNodeZ },
                            { -4.2, 2, 0 },
                            3,
                        },
                        {
                            { 6, -4, _cargoNodeZ }, -- edge 34
                            { -4.2, -2, 0 },
                            3,
                        },
                        {
                            { 1.8, -6, _cargoNodeZ },
                            { -4.2, -2, 0 },
                            3,
                        },
                        {
                            { -6, 4, _cargoNodeZ }, -- edge 35
                            { 4.2, 2, 0 },
                            3,
                        },
                        {
                            { -1.8, 6, _cargoNodeZ },
                            { 4.2, 2, 0 },
                            3,
                        },
                        {
                            { 1.8, 6, _cargoNodeZ }, -- edge 36
                            { 4.2, -2, 0 },
                            3,
                        },
                        {
                            { 6, 4, _cargoNodeZ },
                            { 4.2, -2, 0 },
                            3,
                        },
                    },
                    transportModes = { 'CARGO', },
                    speedLimit = 30,
                },

                -- laneutil.createLanes(
                --     generatedData['lanes_terminal'], -- curves
                --     { 'CARGO' }, -- transport means
                --     20, -- max speed
                --     4, -- lane width
                --     true -- linkable
                -- ),
            },
            runways = { },
            terminals = {
                {
                    -- order = 0,
                    personEdges = { 0, 1, 2 },
                    personNodes = { 0, 1, 2, 3, 4, 5 },
                    -- vehicleNode = -1, -- 0,
                },
            },
        },
    }
end

helpers.getCargoAreaInner15x15BoundingInfo = function()
    return {
        bbMax = { 7.4, 7.4, 2 },
        bbMin = { -7.4, -7.4, 0 },
    }
end

helpers.getCargoAreaInner15x15Collider = function()
    return {
        params = {
            halfExtents = { 7.4, 7.4, 1.0, },
        },
        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        type = 'BOX',
    }
end

helpers.getCargoAreaInner15x15Lods = function()
    local _materials = { 'street/new_medium_sidewalk.mtl', 'street/new_medium_sidewalk.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        -- materials = { 'street/new_medium_sidewalk_border_inner.mtl', 'street/new_medium_sidewalk.mtl', },
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -7.5, -7.5, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, -2.5, -7.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, 2.5, -7.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 7.5, -7.5, _cargoPlatformZ, 1, },
                    },

                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -7.5, -2.5, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, -2.5, -2.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, 2.5, -2.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 7.5, -2.5, _cargoPlatformZ, 1, },
                    },

                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -7.5, 2.5, _cargoPlatformZ, 1, },
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, -2.5, 2.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/straight_lod0.msh',
                        transf = {1, 0, 0, 0, 0, -2.05, 0, 0, 0, 0, 1, 0, 2.5, 2.5, _cargoPlatformZ, 1}
                    },
                    {
                        materials = _materials,
                        mesh = 'station/road/streetstation/pedestrian_era_c/end_l_lod0.msh',
                        transf = { 0, 2.05, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 7.5, 2.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner15x15EarthLods = function()
    local _materials = { 'lollo_lorry_station/earth.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/lollo15x15.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -7.5, -7.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner15x15GravelLods = function()
    local _materials = { 'lollo_lorry_station/gravel.mtl' }
    return {
        {
            node = {
                children = {
                    {
                        materials = _materials,
                        mesh = 'lollo_lorry_station/lollo15x15.msh',
                        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -7.5, -7.5, _cargoPlatformZ, 1, },
                    },
                },
                name = 'RootNode',
                transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
            },
            static = false,
            visibleFrom = 0,
            visibleTo = 1000,
        },
    }
end

helpers.getCargoAreaInner15x15Metadata = function()
    local _cargoNodeZ = 0.3
    return {
        transportNetworkProvider = {
            laneLists = {
                {
                    linkable = true,
                    nodes = {
                        {
                            { 7.5, -6.25, _cargoNodeZ }, -- edge 0
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -6.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -6.25, _cargoNodeZ }, -- edge 1
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -6.25, _cargoNodeZ },
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -6.25, _cargoNodeZ }, -- edge 2
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.5, -6.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },

                        {
                            { -7.5, -3.75, _cargoNodeZ }, -- edge 3
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -3.75, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -3.75, _cargoNodeZ }, -- edge 4
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -3.75, _cargoNodeZ },
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -3.75, _cargoNodeZ }, -- edge 5
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.5, -3.75, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },

                        {
                            { 7.5, -1.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -1.25, _cargoNodeZ }, -- edge 6
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, -1.25, _cargoNodeZ },
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -1.25, _cargoNodeZ }, -- edge 7
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, -1.25, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.5, -1.25, _cargoNodeZ }, -- edge 8
                            { -0.5, 0, 0 },
                            3,
                        },

                        {
                            { -7.5, 1.25, _cargoNodeZ }, -- edge 9
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 1.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 1.25, _cargoNodeZ }, -- edge 10
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 1.25, _cargoNodeZ },
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 1.25, _cargoNodeZ }, -- edge 11
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.5, 1.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },


                        {
                            { 7.5, 3.75, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 3.75, _cargoNodeZ }, -- edge 12
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 3.75, _cargoNodeZ },
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 3.75, _cargoNodeZ }, -- edge 13
                            { -14, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 3.75, _cargoNodeZ },
                            { -0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.5, 3.75, _cargoNodeZ }, -- edge 14
                            { -0.5, 0, 0 },
                            3,
                        },

                        {
                            { -7.5, 6.25, _cargoNodeZ }, -- edge 15
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 6.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { -7.00000, 6.25, _cargoNodeZ }, -- edge 16
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 6.25, _cargoNodeZ },
                            { 14, 0, 0 },
                            3,
                        },
                        {
                            { 7.00000, 6.25, _cargoNodeZ }, -- edge 17
                            { 0.5, 0, 0 },
                            3,
                        },
                        {
                            { 7.5, 6.25, _cargoNodeZ },
                            { 0.5, 0, 0 },
                            3,
                        },
                        -- lanes across 1
                        {
                            { 7, 7.5, _cargoNodeZ }, -- edge 18
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 7, 6.25, _cargoNodeZ },
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 7, 6.25, _cargoNodeZ }, -- edge 19
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, 3.75, _cargoNodeZ },
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, 3.75, _cargoNodeZ }, -- edge 20
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, 1.25, _cargoNodeZ },
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, 1.25, _cargoNodeZ }, -- edge 22
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, -1.25, _cargoNodeZ },
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, -1.25, _cargoNodeZ }, -- edge 23
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, -3.75, _cargoNodeZ },
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, -3.75, _cargoNodeZ }, -- edge 24
                            { 0, -2.5, 0 },
                            3,
                        },
                        {
                            { 7, -6.25, _cargoNodeZ },
                            { 0, -2.5, 0 },
                            3,
                        },

                        {
                            { 7, -6.25, _cargoNodeZ }, -- edge 25
                            { 0, -1.25, 0 },
                            3,
                        },
                        {
                            { 7, -7.5, _cargoNodeZ },
                            { 0, -1.25, 0 },
                            3,
                        },
                        -- lanes across 2
                        {
                            { -7, -7.5, _cargoNodeZ }, -- edge 26
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -7, -6.25, _cargoNodeZ },
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -7, -6.25, _cargoNodeZ }, -- edge 27
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, -3.75, _cargoNodeZ },
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, -3.75, _cargoNodeZ }, -- edge 28
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, -1.25, _cargoNodeZ },
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, -1.25, _cargoNodeZ }, -- edge 29
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 1.25, _cargoNodeZ },
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 1.25, _cargoNodeZ }, -- edge 30
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 3.75, _cargoNodeZ },
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 3.75, _cargoNodeZ }, -- edge 31
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 6.25, _cargoNodeZ },
                            { 0, 2.5, 0 },
                            3,
                        },
                        {
                            { -7, 6.25, _cargoNodeZ }, -- edge 32
                            { 0, 1.25, 0 },
                            3,
                        },
                        {
                            { -7, 7.5, _cargoNodeZ },
                            { 0, 1.25, 0 },
                            3,
                        },
                        -- diagonal lanes to match small cargo area
                        {
                            { -2, -7.5, _cargoNodeZ }, -- edge 33
                            { -5, 1.25, 0 },
                            3,
                        },
                        {
                            { -7, -6.25, _cargoNodeZ },
                            { -5, 1.25, 0 },
                            3,
                        },
                        {
                            { 7, -6.25, _cargoNodeZ }, -- edge 34
                            { -5, -1.25, 0 },
                            3,
                        },
                        {
                            { 2, -7.5, _cargoNodeZ },
                            { -5, -1.25, 0 },
                            3,
                        },
                        {
                            { -7, 6.25, _cargoNodeZ }, -- edge 35
                            { 5, 1.25, 0 },
                            3,
                        },
                        {
                            { -2, 7.5, _cargoNodeZ },
                            { 5, 1.25, 0 },
                            3,
                        },
                        {
                            { 2, 7.5, _cargoNodeZ }, -- edge 36
                            { 5, -1.25, 0 },
                            3,
                        },
                        {
                            { 7, 6.25, _cargoNodeZ },
                            { 5, -1.25, 0 },
                            3,
                        },
                    },
                    transportModes = { 'CARGO', },
                    speedLimit = 30,
                },

                -- laneutil.createLanes(
                --     generatedData['lanes_terminal'], -- curves
                --     { 'CARGO' }, -- transport means
                --     20, -- max speed
                --     4, -- lane width
                --     true -- linkable
                -- ),
            },
            runways = { },
            terminals = {
                {
                    -- order = 0,
                    personEdges = { 1, 4, 7, 10, 13, 16 },
                    personNodes = { 2, 3, 8, 9, 14, 15, 20, 21, 26, 27, 32, 33 },
                    -- vehicleNode = -1, -- 0,
                },
            },
        },
    }
end

helpers.getAnythingStreetside12x4BoundingInfo = function ()
    return {
        bbMax = { 5.9, 1.9, 5, },
        bbMin = { -5.9, -1.9, 0, },
    }
end

helpers.getAnythingStreetside12x4Collider = function ()
    return {
        params = {
            -- halfExtents = { 5.9, 1.9, 2.7, },
            halfExtents = { 0.9, 1.9, 2.7, },
        },
        transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2.3, 1, },
        type = "BOX",
    }
end

helpers.getLaneLists12x4NormalCapacity = function()
    local _cargoNodeZ = 0.3
    return {
        -- on the pavement
        {
            linkable = true, -- LOLLO NOTE this is useful to connect the station to the industry
            nodes = {
                {{ 6, 0, _cargoNodeZ, },{ -12, 0, 0, }, 3}, -- edge 0
                {{ -6, 0, _cargoNodeZ, },{ -12, 0, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- along the y axis
        {
            linkable = false,
            nodes = {
                {{ 5.8, 2, _cargoNodeZ, }, { 0.2, -2, 0, }, 3},
                {{ 6, 0, _cargoNodeZ, }, { 0.2, -2, 0, }, 3},
                {{ 6, 0, _cargoNodeZ, }, { -0.2, -2, 0, }, 3},
                {{ 5.8, -2, _cargoNodeZ, }, { -0.2, -2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -5.8, -2, _cargoNodeZ, }, { -0.2, 2, 0, }, 3},
                {{ -6, 0, _cargoNodeZ, }, { -0.2, 2, 0, }, 3},
                {{ -6, 0, _cargoNodeZ, }, { 0.2, 2, 0, }, 3},
                {{ -5.8, 2, _cargoNodeZ, }, { 0.2, 2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- diagonals to join up with the 4x4 units
        {
            linkable = false,
            nodes = {
                {{ 1.8, 2, _cargoNodeZ, }, { 4.2, -2, 0, }, 3},
                {{ 6, 0, _cargoNodeZ, }, { 4.2, -2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -6, 0, _cargoNodeZ, }, { 4.2, 2, 0, }, 3},
                {{ -1.8, 2, _cargoNodeZ, }, { 4.2, 2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ 6, 0, _cargoNodeZ, }, { -4.2, -2, 0, }, 3},
                {{ 1.8, -2, _cargoNodeZ, }, { -4.2, -2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -1.8, -2, _cargoNodeZ, }, { -4.2, 2, 0, }, 3},
                {{ -6, 0, _cargoNodeZ, }, { -4.2, 2, 0, }, 3}, -- edge 6
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
    }
end

helpers.getLaneLists15x5HighCapacity = function()
    local _cargoNodeZ = 0.3
    return {
        -- on the pavement
        {
            linkable = true, -- LOLLO NOTE this is useful to connect the station to the industry
            nodes = {
                {{ 7.5, -1.25, _cargoNodeZ, },{ -0.5, 0, 0, }, 3}, -- edge 0
                {{ 7, -1.25, _cargoNodeZ, },{ -0.5, 0, 0, }, 3},

                {{ 7, -1.25, _cargoNodeZ, },{ -14, 0, 0, }, 3}, -- edge 1
                {{ -7, -1.25, _cargoNodeZ, },{ -14, 0, 0, }, 3},

                {{ -7, -1.25, _cargoNodeZ, },{ -0.5, 0, 0, }, 3}, -- edge 2
                {{ -7.5, -1.25, _cargoNodeZ, },{ -0.5, 0, 0, }, 3},


                {{ -7.5, 1.25, _cargoNodeZ, },{ 0.5, 0, 0, }, 3}, -- edge 3
                {{ -7, 1.25, _cargoNodeZ, },{ 0.5, 0, 0, }, 3},

                {{ -7, 1.25, _cargoNodeZ, },{ 14, 0, 0, }, 3}, -- edge 4
                {{ 7, 1.25, _cargoNodeZ, },{ 14, 0, 0, }, 3},

                {{ 7, 1.25, _cargoNodeZ, },{ 0.5, 0, 0, }, 3}, -- edge 5
                {{ 7.5, 1.25, _cargoNodeZ, },{ 0.5, 0, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- along y axis
        {
            linkable = false,
            nodes = {
                {{ 7, 2, _cargoNodeZ, }, { 0, -0.75, 0, }, 3},
                {{ 7, 1.25, _cargoNodeZ, }, { 0, -0.75, 0, }, 3},
                {{ 7, 1.25, _cargoNodeZ, }, { 0, -2.5, 0, }, 3},
                {{ 7, -1.25, _cargoNodeZ, }, { 0, -2.5, 0, }, 3},
                {{ 7, -1.25, _cargoNodeZ, }, { 0, -1.75, 0, }, 3},
                {{ 7, -3, _cargoNodeZ, }, { 0, -1.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -7, - 3, _cargoNodeZ, }, { 0, 1.75, 0, }, 3},
                {{ -7, - 1.25, _cargoNodeZ, }, { 0, 1.75, 0, }, 3},
                {{ -7, - 1.25, _cargoNodeZ, }, { 0, 2.5, 0, }, 3},
                {{ -7, 1.25, _cargoNodeZ, }, { 0, 2.5, 0, }, 3},
                {{ -7, 1.25, _cargoNodeZ, }, { 0, 0.75, 0, }, 3},
                {{ -7, 2, _cargoNodeZ, }, { 0, 0.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- diagonals to fit 5x5 items
        {
            linkable = false,
            nodes = {
                {{ 2, 2, _cargoNodeZ, }, { 5, -0.75, 0, }, 3},
                {{ 7, 1.25, _cargoNodeZ, }, { 5, -0.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -7, 1.25, _cargoNodeZ, }, { 5, 0.75, 0, }, 3},
                {{ -2, 2, _cargoNodeZ, }, { 5, 0.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ 7, -1.25, _cargoNodeZ, }, { -5, -1.75, 0, }, 3},
                {{ 2, - 3, _cargoNodeZ, }, { -5, -1.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -2, - 3, _cargoNodeZ, }, { -5, 1.75, 0, }, 3},
                {{ -7, -1.25, _cargoNodeZ, }, { -5, 1.75, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
    }
end

helpers.getLaneLists15x5NormalCapacity = function()
    local _cargoNodeZ = 0.3
    return {
        -- on the pavement
        {
            linkable = true, -- LOLLO NOTE this is useful to connect the station to the industry
            nodes = {
                {{ 7.5, 0, _cargoNodeZ, },{ -0.5, 0, 0, }, 3}, -- edge 0
                {{ 7, 0, _cargoNodeZ, },{ -0.5, 0, 0, }, 3},

                {{ 7, 0, _cargoNodeZ, },{ -14, 0, 0, }, 3}, -- edge 1
                {{ -7, 0, _cargoNodeZ, },{ -14, 0, 0, }, 3},

                {{ -7, 0, _cargoNodeZ, },{ -0.5, 0, 0, }, 3}, -- edge 2
                {{ -7.5, 0, _cargoNodeZ, },{ -0.5, 0, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- behind the pavement, away from the road
        {
            linkable = false,
            nodes = {
                {{ 7, 2, _cargoNodeZ, }, { 0, -2, 0, }, 3}, -- edge 3
                {{ 7, 0, _cargoNodeZ, }, { 0, -2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -7, 0, _cargoNodeZ, }, { 0, 2, 0, }, 3}, -- edge 4
                {{ -7, 2, _cargoNodeZ, }, { 0, 2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ 2, 2, _cargoNodeZ, }, { 5, -2, 0, }, 3}, -- edge 5
                {{ 7, 0, _cargoNodeZ, }, { 5, -2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -7, 0, _cargoNodeZ, }, { 5, 2, 0, }, 3}, -- edge 6
                {{ -2, 2, _cargoNodeZ, }, { 5, 2, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        -- behind the pavement, toward the road
        {
            linkable = false,
            nodes = {
                {{ 7, 0, _cargoNodeZ, }, { 0, -3, 0, }, 3}, -- edge 3
                {{ 7, -3, _cargoNodeZ, }, { 0, -3, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -7, -3, _cargoNodeZ, }, { 0, 3, 0, }, 3}, -- edge 4
                {{ -7, 0, _cargoNodeZ, }, { 0, 3, 0, }, 3},
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ 7, 0, _cargoNodeZ, }, { -5, -3, 0, }, 3},
                {{ 2, -3, _cargoNodeZ, }, { -5, -3, 0, }, 3}, -- edge 5
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
        {
            linkable = false,
            nodes = {
                {{ -2, -3, _cargoNodeZ, }, { -5, 3, 0, }, 3},
                {{ -7, 0, _cargoNodeZ, }, { -5, 3, 0, }, 3}, -- edge 6
            },
            speedLimit = 30,
            transportModes = { 'CARGO' },
        },
    }
end

return helpers
