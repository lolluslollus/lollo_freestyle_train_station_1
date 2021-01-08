return function(height)
    local _xExtraShift = 0.01 -- a lil shift to avoid flickering when overlaying "elevated stairs" and these
    local topTransf = {1, 0, 0, 0,  0, -1, 0, 0,  0, 0, 1, 0,  4.5, -4.25, 0.707, 1}

    local function _getWallsBelowPlatform(lod)
        local results = {}

        local zShift4Wall = -1.8 + 5
        for h = 5, height, 5 do
            zShift4Wall = zShift4Wall - 5
            local zedZoom4Wall = h == 5 and 0.5 or 1
            local wallTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, zedZoom4Wall, 0,  4.5, 0.75, zShift4Wall, 1}
            results[#results + 1] = {
                --materials = {'industry/oil_refinery/era_a/wall_2.mtl'},
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
                local shaftTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Shaft, 0, 0, -1.7, zShift4Shaft, 1}
                    results[#results + 1] = {
                        materials = {'lollo_freestyle_train_station/shaft.mtl'},
                        -- mesh = 'lollo_freestyle_train_station/lift/inner_shaft_lod0.msh',
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
    local groundRoofTransf = {0.3, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0.07, 0, 0, -4.1, zedShift4groundRoof, 1}

    local zedShift4groundPillar = -height + 3.2
    -- local zedZoom4groundPillar = -1.075
    -- local frontLeftPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, -9.0, -5, zedShift4groundPillar, 1}
    -- local frontRightPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, 9.0, -5, zedShift4groundPillar, 1}
    -- local rearLeftPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, -9.0, 0.5, zedShift4groundPillar, 1}
    -- local rearRightPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, 9.0, 0.5, zedShift4groundPillar, 1}
    local pillarsTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, -1, 0,  4.5 + _xExtraShift, 0.75, zedShift4groundPillar, 1}

    local roofTransf = {1.46, 0, 0, 0,  0, 0, 3.0, 0,  0, 1.55, 0, 0,  0.0, -4.24, 4.5, 1}
    -- local solarOneTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1.1, 5.25, 1}
    -- local solarTwoTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -3.4, 5.25, 1}
    local ventOneTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, -2, 5.3, 1}
    local ventTwoTransf = {-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, -2, 5.3, 1}
    local floorPavingWithHoleTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1.71, 0.0, 1}
    local floorPavingTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.01, 0, 1}
    local floorBracketTransf = {1.48, 0, 0, 0, 0, 0, 1.9, 0, 0, 0.2, 0, 0, 0, -0.2, 0.32, 1}
    local idTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1}
    local stationMainTransf = {0.6, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}

    -- LOLLO NOTE I can make many of these, one for each height.
    -- For example, side_lifts_9_5_5.mdl, side_lifts_9_5_10.mdl, and so on.
    -- Only the transformations above will change, if I am clever,
    -- and the height of the bounding box.

    --print('LOLLO height = ', height)
    return {
        boundingInfo = {
            -- bbMax = {4.4, 1.0, 5.0}, -- this would be the building without vents or tunnel awereness
            -- bbMin = {-4.4, -4.0, -height} -- this would be the building without vents or tunnel awereness
            bbMax = {4.4, 1.0, 6.5}, -- a bit taller to protect the vents from bridges
            bbMin = {-4.4, -4.0, -height -1.5} -- a bit lower to protect the floor from tunnels
        },
        collider = {
            params = {
                -- halfExtents = {4.4, 2.5, 2.5 + height * 0.5} -- this would be the building without vents or tunnel awereness
                halfExtents = {4.4, 2.5, 5.5 + height * 0.5} -- a bit taller to protect the floor from tunnels and the vents from bridges
            },
            -- transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -1.5, 2.5 - height * 0.5, 1 }, -- this would be the building without vents
            transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -1.5, 1.0 - height * 0.5, 1 }, -- a bit lower to protect the floor from tunnels and the vents from bridges
            type = 'BOX'
        },
        lods = {
            {
                node = {
                    children = {
                        {
                            children = {
                                -- above the platform
                                {
                                    -- ticket machine upstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 6.3, -1.5, 0.8, 1}
                                },
                                {
                                    -- ticket machine upstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.25, -2.7, 0.8, 1}
                                },
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
                                    -- ticket machine downstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5.97, 0.2, -height, 1}
                                },
                                {
                                    -- ticket machine downstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5.97, 0.2, -height, 1}
                                },
                                -- roof
                                {
                                    -- flat roof
                                    --materials = { "industry/oil_refinery/era_a/wall_2.mtl", },
                                    --materials = { "station/rail/era_c/era_c_trainstation_roof_white.mtl", },
                                    --materials = { "station/rail/era_c/era_c_trainstation_glass_milk.mtl", },
                                    --materials = { "asset/roof/asset_roof_decor1.mtl", },
                                    --materials = { "asset/roof/asset_roof_decor1.mtl", },
                                    --materials = { "industry/chemical_plant/wall_1.mtl", },
                                    --materials = { "industry/goods_factory/goods_factory_roof1.mtl", },
                                    --materials = { "industry/machines_factory/wall_1.mtl", },
                                    --materials = {'industry/machines_factory/roof_2.mtl'},
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = roofTransf
                                },
                                --[[ {
                                    --solar panel 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_solar_panel1.msh',
                                    transf = solarOneTransf
                                }, ]]
--[[                                 {
                                    --solar panel 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_solar_panel1.msh',
                                    transf = solarTwoTransf
                                }, ]]
                                {
                                    -- roof vent 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventOneTransf
                                },
                                {
                                    -- roof vent 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventTwoTransf
                                },
                                -- floor bracket
                                {
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'station_1_main_floor',
                                    transf = floorBracketTransf
                                }
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        },
                        -- floor paving upstairs
                        {
                            -- materials = {'station/rail/era_c/era_c_trainstation_floor_1.mtl'},
                            -- mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod0.msh',
                            -- mesh = 'floor_with_hole.msh',
                            materials = {
                                'station/rail/era_c/era_c_trainstation_floor_1.mtl',
                                'lollo_freestyle_train_station/shaft.mtl'
                            },
                            mesh = 'lollo_freestyle_train_station/lift/floor_with_hole_and_shaft_9x4x3.msh',
                            name = 'floor_paving_upstairs',
                            transf = floorPavingWithHoleTransf
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
                            -- top
                            --materials = { "industry/oil_refinery/era_a/wall_2.mtl", },
                            materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white_no_stripes.mtl'},
                            --materials = { "station/rail/era_c/era_c_trainstation_glass_milk.mtl", },
                            --materials = { "station/rail/era_c/era_c_trainstation_special.mtl", },
                            --materials = { "asset/commercial/era_c/com_glass.mtl", },
                            --materials = { "building/era_c/com_1_1x1_03/com_era_c_window_glass_mat.mtl", }, -- crashes
                            --materials = { "asset/roof/asset_roof_decor1.mtl", },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x5top.msh',
                            transf = topTransf
                        },
                        {
                            children = {
                                {
                                    materials = {'station/rail/era_c/era_c_trainstation_assets.mtl'},
                                    mesh = 'lollo_freestyle_train_station/asset/era_c_single_station_name_lod0.msh',
                                    name = 'era_c_station_name',
                                    transf = idTransf
                                }
                            },
                            name = 'era_c_station_name_grp',
                            --transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
                            transf = {1.4, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -4.1, -.1, 1}
                        }
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
                            children = {
                                -- {
                                --     -- entrance roof
                                --     materials = {
                                --         'station/rail/era_c/era_c_trainstation_borders_1.mtl',
                                --         'station/rail/era_c/era_c_trainstation_roof_wood.mtl',
                                --         'station/rail/era_c/era_c_trainstation_roof_white.mtl',
                                --         'station/rail/era_c/era_c_trainstation_modeling_tmp.mtl'
                                --     },
                                --     mesh = 'station/rail/era_c/station_3_roof_perron_side/station_3_roof_perron_side_lod0.msh',
                                --     name = 'station_3_roof_perron_side',
                                --     transf = groundRoofTransf
                                -- },
                                -- roof
                                {
                                    -- flat roof
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = roofTransf
                                },
                                --[[ {
                                    --solar panel 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_solar_panel1.msh',
                                    transf = solarOneTransf
                                }, ]]
--[[                                 {
                                    --solar panel 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_solar_panel1.msh',
                                    transf = solarTwoTransf
                                }, ]]
                                {
                                    -- roof vent 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventOneTransf
                                },
                                {
                                    -- roof vent 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventTwoTransf
                                },
                                -- floor paving upstairs
                                {
                                    -- materials = {'station/rail/era_c/era_c_trainstation_floor_1.mtl'},
                                    -- mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod0.msh',
                                    -- mesh = 'floor_with_hole.msh',
                                    materials = {
                                        'station/rail/era_c/era_c_trainstation_floor_1.mtl',
                                        'lollo_freestyle_train_station/shaft.mtl'
                                    },
                                    mesh = 'lollo_freestyle_train_station/lift/floor_with_hole_and_shaft_9x4x3.msh',
                                    name = 'floor_paving_upstairs',
                                    transf = floorPavingWithHoleTransf
                                },
                                -- floor bracket
                                {
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    transf = floorBracketTransf
                                }
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        },
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
                            transf = pillarsTransf
                        },
                        {
                            children = {
                                {
                                    -- top
                                    --materials = { "industry/oil_refinery/era_a/wall_2.mtl", },
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white_no_stripes.mtl'},
                                    --materials = { "station/rail/era_c/era_c_trainstation_glass_milk.mtl", },
                                    --materials = { "station/rail/era_c/era_c_trainstation_special.mtl", },
                                    --materials = { "asset/commercial/era_c/com_glass.mtl", },
                                    --materials = { "building/era_c/com_1_1x1_03/com_era_c_window_glass_mat.mtl", }, -- crashes
                                    --materials = { "asset/roof/asset_roof_decor1.mtl", },
                                    mesh = 'lollo_freestyle_train_station/lift/lollo9x5x5top.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = topTransf
                                }
                            },
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
                            children = {
                                -- roof
                                {
                                    -- flat roof
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = roofTransf
                                },
                                -- floor paving upstairs
                                {
                                    materials = {'station/rail/era_c/era_c_trainstation_floor_1.mtl'},
                                    mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod2.msh',
                                    name = 'station_1_main_perron',
                                    transf = floorPavingTransf
                                },
                                -- floor bracket
                                -- {
                                --     materials = {'lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                                --     mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                --     name = 'station_1_main_floor',
                                --     transf = floorTransf
                                -- }
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        },
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
                            transf = pillarsTransf
                        },
                        {
                            children = {
                                {
                                    -- top
                                    --materials = { "industry/oil_refinery/era_a/wall_2.mtl", },
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_white_no_stripes.mtl'},
                                    --materials = { "station/rail/era_c/era_c_trainstation_glass_milk.mtl", },
                                    --materials = { "station/rail/era_c/era_c_trainstation_special.mtl", },
                                    --materials = { "asset/commercial/era_c/com_glass.mtl", },
                                    --materials = { "building/era_c/com_1_1x1_03/com_era_c_window_glass_mat.mtl", }, -- crashes
                                    --materials = { "asset/roof/asset_roof_decor1.mtl", },
                                    mesh = 'lollo_freestyle_train_station/lift/lollo9x5x5top.msh',
                                    transf = topTransf
                                }
                            },
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
            labelList = {
                labels = {
                    {
                        alignment = 'CENTER',
                        alphaMode = 'BLEND',
                        childId = 'RootNode',
                        fitting = 'SCALE',
                        -- renderMode = "EMISSIVE",
                        -- nLines = 1,
                        size = {5.2, 0.6},
                        -- size = {4.0, 0.6},
                        transf = {0.7, 0, 0, 0,  0, 0, 0.7, 0,  0, -1, 0, 0,  -1.80, -4.333, 0.27, 1},
                        type = 'STATION_NAME',
                        verticalAlignment = 'CENTER'
                    }
                }
            },
            transportNetworkProvider = {
                laneLists = {
                    {
                        -- down the stairs and into the lift
                        linkable = false,
                        nodes = {
                            {
                                {0, 0, 0.8},
                                {0, -1.8, 0},
                                2.4000000953674
                            },
                            {
                                {0, -1.8, 0.8},
                                {0, -1.8, 0},
                                2.4000000953674
                            },
                            {
                                {0, -1.8, 0.8},
                                {0, -0.2, 0},
                                2.4000000953674
                            },
                            {
                                {0, -2.0, 0},
                                {0, -0.2, 0},
                                2.4000000953674
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    height > 0 and
                    {
                        -- straight down
                        linkable = false,
                        nodes = {
                            {
                                {0, -2.0, 0},
                                {0, 0, -1}, -- 0, 0, 0 crashes, 0, 0, -1 and 0, 0, 1 hide the people, 0, 1, 0 and 1, 0, 0 have them walk while being lifted
                                2.4
                            },
                            {
                                {0, -2.0, -height},
                                {0, 0, -1},
                                2.4
                            },
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    } or nil,
                    height > 0 and
                    {
                        -- out to the front
                        linkable = true,
                        nodes = {
                            {
                                {0, -2.0, -height},
                                {0, -2, 0},
                                2.4
                            },
                            {
                                {0, -4.0, -height},
                                {0, -2, 0},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    } or
                    { -- height = 0: it never happens
                        -- out to the front
                        linkable = true,
                        nodes = {
                            {
                                {0, -2.0, 0},
                                {0, 0, -1}, -- 0, 0, 0 crashes, 0, 0, -1 and 0, 0, 1 hide the people, 0, 1, 0 and 1, 0, 0 have them walk while being lifted
                                2.4
                            },
                            {
                                {0, -2.0, -3}, -- was {0, -2.5, underpassZed}
                                {0, 0, -1},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    {
                        -- out to the back
                        linkable = true,
                        nodes = {
                            {
                                {0, 0, -height},
                                {0, -1, 0},
                                2.4
                            },
                            {
                                {0, -2.0, -height},
                                {0, -1, 0},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    {
                        -- sideways, to connect extra elements
                        linkable = true,
                        nodes = {
                            {
                                {-4.5, -2.0, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {0, -2.0, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {0, -2.0, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {4.5, -2.0, -height},
                                {1, 0, 0},
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
