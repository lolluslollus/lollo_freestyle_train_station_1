-- local _constants = require('lollo_freestyle_train_station.constants')
local _underpassDepth = 4 -- _constants.underpassDepthM LOLLO TODO restore after testing

return function(height)
    local _xExtraShift = 0.01 -- a lil shift to avoid flickering when overlaying "elevated stairs" and these

    local function _getWallsBelowPlatform(lod)
        local results = {}

        local zShift4Wall = -1.8 + 5
        for h = 5, height, 5 do
            zShift4Wall = zShift4Wall - 5
            local zedZoom4Wall = h == 5 and 0.5 or 1
            local wallTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, zedZoom4Wall, 0,  4.5 + _xExtraShift, 2.2, zShift4Wall, 1}

            results[#results + 1] = {
                materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                mesh = 'lollo_freestyle_train_station/lift/lollo9x5x5room_deco.msh',
                transf = wallTransf
            }
        end

        if lod == 0 then
            local zShift4Shaft = 0
            for h = 5, height, 5 do
                zShift4Shaft = zShift4Shaft - 5
                -- local zedZoom4Shaft = h == 5 and 0.5 or 1
                local zedZoom4Shaft = 1
                local shaftTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Shaft, 0, 0, -0.3, zShift4Shaft, 1}
                    results[#results + 1] = {
                        materials = {'lollo_freestyle_train_station/shaft.mtl'},
                        mesh = 'lollo_freestyle_train_station/lift/inner_shaft_round_lod0.msh',
                        transf = shaftTransf
                    }
            end
        end

        return results
    end
    local _wallsBelowThePlatformLod0 = _getWallsBelowPlatform(0)
    local _wallsBelowThePlatformLod1 = _getWallsBelowPlatform(1)

    local zedShift4groundRoof = -height + 2.9 -- - height * .6 + 2.60
    local groundRoofTransf = {0.3, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0.07, 0, 0, -2.75, zedShift4groundRoof, 1}

    local zedShift4groundPillar = -height + 3.2
    -- local zedZoom4groundPillar = -1 -- -1.075
    local pillarsTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, -1, 0,  4.5 + _xExtraShift, 2.2, zedShift4groundPillar, 1}
    local shaftTopTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -0.3, 0.8, 1}

    local idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    local stationMainTransf = {0.6, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}

    -- LOLLO NOTE I can make many of these, one for each height.
    -- For example, platform_lifts_5.mdl, platform_lifts_10.mdl, and so on.
    -- Only the transformations above will change, if I am clever,
    -- and the height of the bounding box.

    --print('LOLLO height = ', height)
    return {
        boundingInfo = {
            -- bbMax = {5.8, 1.0, 1.0},
            bbMax = {5.8, 2.0, 1.0},
            bbMin = {-5.8, -2.6, -height}
        },
        -- LOLLO NOTE the collider here seems to have no effect.
        -- We already get it in platform_lifts.module, so never mind
        collider = {
            -- params = {
            --     halfExtents = {5.8, 2.4, 32.0}
            -- },
            -- transf = idTransf,
            -- type = 'BOX'
            params = {},
            transf = idTransf,
            type = 'MESH'
        },
        lods = {
            {
                node = {
                    children = {
                        {
                            children = {
                                -- ground level
                                {
                                    -- entrance roof
                                    materials = {
                                        'station/rail/era_c/era_c_trainstation_borders_1.mtl',
                                        'station/rail/era_c/era_c_trainstation_roof_wood.mtl',
                                        'station/rail/era_c/era_c_trainstation_roof_white.mtl',
                                        'station/rail/era_c/era_c_trainstation_modeling_tmp.mtl'
                                    },
                                    mesh = 'station/rail/era_c/station_3_roof_perron_side/station_3_roof_perron_side_lod0.msh',
                                    name = 'station_3_roof_perron_side',
                                    transf = groundRoofTransf
                                },
                                {
                                    -- ticket machine right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 7.47, 1.6, -height, 1}
                                },
                                {
                                    -- ticket machine left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -7.47, 1.6, -height, 1}
                                },
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        },
                        {
                            children = _wallsBelowThePlatformLod0,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        {
                            -- pillars
                            materials = {
                                'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        {
                            -- shaft top
                            materials = {
                                'lollo_freestyle_train_station/shaft.mtl',
                                -- 'lollo_freestyle_train_station/station_concrete_2.mtl',
                                'lollo_freestyle_train_station/wall_grey.mtl',
                                'lollo_freestyle_train_station/hole.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/shaft-top-round-lod0.msh',
                            transf = shaftTopTransf
                        },
                    },
                    name = 'RootNode',
                    transf = idTransf
                },
                static = false,
                visibleFrom = 0,
                visibleTo = 200
            },
            {
                node = {
                    children = {
                        {
                            children = _wallsBelowThePlatformLod1,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        {
                            -- pillars
                            materials = {
                                'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            name = 'oil_refinery_wall_large',
                            transf = pillarsTransf
                        },
                        {
                            -- shaft top
                            materials = {
                                'lollo_freestyle_train_station/shaft.mtl',
                                -- 'lollo_freestyle_train_station/station_concrete_2.mtl',
                                'lollo_freestyle_train_station/wall_grey.mtl',
                                'lollo_freestyle_train_station/hole.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/shaft-top-round-lod1.msh',
                            transf = shaftTopTransf
                        },
                    },
                    name = 'RootNode',
                    transf = idTransf
                },
                static = false,
                visibleFrom = 200,
                visibleTo = 1000
            },
            {
                node = {
                    children = {
                        {
                            children = _wallsBelowThePlatformLod1,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        {
                            -- pillars
                            materials = {
                                'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            name = 'oil_refinery_wall_large',
                            transf = pillarsTransf
                        },
                    },
                    name = 'RootNode',
                    transf = idTransf
                },
                static = false,
                visibleFrom = 1000,
                visibleTo = 3500
            }
        },
        metadata = {
            -- labelList = {
            --     labels = {
            --         {
            --             alignment = 'CENTER',
            --             alphaMode = 'BLEND',
            --             childId = 'RootNode',
            --             fitting = 'SCALE',
            --             nLines = 1,
            --             renderMode = "EMISSIVE",
            --             size = {5.2, .6},
            --             transf = {1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, -2.6, -2.833, .23, 1},
            --             type = 'STATION_NAME',
            --             verticalAlignment = 'CENTER'
            --         }
            --     }
            -- },
            transportNetworkProvider = {
                laneLists = {
                    -- {
                    --     -- horizontally into the across underpass
                    --     nodes = {
                    --         {
                    --             {0, -0.3, underpassZed},
                    --             {0, 0.3, 0},
                    --             2.4000000953674
                    --         },
                    --         {
                    --             {0, 0, underpassZed},
                    --             {0, 0.3, 0},
                    --             2.4000000953674
                    --         }
                    --     },
                    --     speedLimit = 20,
                    --     transportModes = {'PERSON'}
                    -- },
                    height > 0 and
                        {
                            -- straight down and then out
                            linkable = true,
                            nodes = {
                                {
                                    {0, 0, 0.1 + 0.8 - _underpassDepth}, -- LOLLO TODO thematisiere this 0.8 (typical of lifts) and 0.1 (typical of side areas)
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, 0, -height},
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, 0, -height},
                                    {0, -1, 0},
                                    2.4
                                },
                                {
                                    {0, -2.7, -height},
                                    -- {0, -2.8, -height},
                                    {0, -1, 0},
                                    2.4
                                }
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        } or nil,
                        {
                            -- out to the back
                            linkable = true,
                            nodes = {
                                {
                                    {0, 0, -height},
                                    {0, 1, 0},
                                    2.4
                                },
                                {
                                    {0, 2.2, -height},
                                    {0, 1, 0},
                                    2.4
                                },
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        },
                        {
                            -- sideways, to connect extra elements
                            linkable = true,
                            nodes = {
                                {
                                    {-4.5, -0.3, -height},
                                    {1, 0.1, 0},
                                    2.4
                                },
                                {
                                    {0, 0, -height},
                                    {1, 0.1, 0},
                                    2.4
                                },
                                {
                                    {0, 0, -height},
                                    {1, -0.1, 0},
                                    2.4
                                },
                                {
                                    {4.5, -0.3, -height},
                                    {1, -0.1, 0},
                                    2.4
                                },
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        },
                },
                runways = {},
                terminals = {}
            }
        },
        version = 1
    }
end
