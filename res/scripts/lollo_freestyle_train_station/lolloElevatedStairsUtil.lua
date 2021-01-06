return function(height)
    -- local underpassZed = require('lollo_freestyle_train_station.constants').underpassZed
    local underpassZed = - 3 -- LOLLO TODO use the constants once you are done with testing
    local topTransf = {1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 6, -5.25, 0.707, 1}

    local function _getWallsBelowPlatform(lod)
        local results = {}

        local zShift4Wall = -1.8 + 5
        for h = 5, height, 5 do
            zShift4Wall = zShift4Wall - 5
            local zedZoom4Wall = h == 5 and 0.5 or 1
            local wallTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Wall, 0, 6, 0.75, zShift4Wall, 1}
            results[#results + 1] = {
                --materials = {'industry/oil_refinery/era_a/wall_2.mtl'},
                materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                -- mesh = 'lollo12x6x5room.msh',
                mesh = 'lollo_freestyle_train_station/lift/lollo12x6x5room_deco.msh',
                name = 'walls',
                transf = wallTransf
            }
        end

        if lod == 0 then
            local zShift4Shaft = 0
            for h = 5, height, 5 do
                zShift4Shaft = zShift4Shaft - 5
                -- local zedZoom4Shaft = h == 5 and 0.5 or 1
                local zedZoom4Shaft = 1
                local shaftTransf = {0.6, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Shaft, 0, 0, -2.5, zShift4Shaft, 1}
                    results[#results + 1] = {
                        materials = {'lollo_freestyle_train_station/shaft.mtl'},
                        mesh = 'lollo_freestyle_train_station/lift/inner_shaft_lod0.msh',
                        name = 'shaft',
                        transf = shaftTransf
                    }
            end
        end

        return results
    end
    local _wallsBelowThePlatformLod0 = _getWallsBelowPlatform(0)
    local _wallsBelowThePlatformLod1 = _getWallsBelowPlatform(1)

    local zedShift4groundRoof = -height + 2.9 -- - height * .6 + 2.60
    local groundRoofTransf = {0.4, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0.07, 0, 0, -5.1, zedShift4groundRoof, 1}

    local zedShift4groundPillar = -height + 3.2
    local zedZoom4groundPillar = -1.075
    local frontLeftPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, -9.0, -5, zedShift4groundPillar, 1}
    local frontRightPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, 9.0, -5, zedShift4groundPillar, 1}
    local rearLeftPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, -9.0, 0.5, zedShift4groundPillar, 1}
    local rearRightPillarTransf = {0.2, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4groundPillar, 0, 9.0, 0.5, zedShift4groundPillar, 1}

    local roofTransf = {1.95, 0, 0, 0, 0, 0, 3.0, 0, 0, 1.55, 0, 0, 0.0, -5.24, 4.5, 1}
    -- local solarOneTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1.1, 5.25, 1}
    -- local solarTwoTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -3.4, 5.25, 1}
    local ventOneTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 6, -2, 5.3, 1}
    local ventTwoTransf = {-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -6, -2, 5.3, 1}
    local floorPavingWithHoleTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -2.51, 0.0, 1}
    local floorPavingTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -0.01, 0, 1}
    local floorTransf = {1.96, 0, 0, 0, 0, 0, 1.9, 0, 0, 0.2, 0, 0, 0, -0.6, 0.32, 1}
    local idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    local stationMainTransf = {.6, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}

    -- LOLLO NOTE I can make many of these, one for each height.
    -- For example, elevated_stairs_5.mdl, elevated_stairs_10.mdl, and so on.
    -- I must leave the existing elevated_stairs.mdl for compatibility with previous versions.
    -- Only the transformations above will change, if I am clever,
    -- and the height of the bounding box.

    --print('LOLLO height = ', height)
    return {
        boundingInfo = {
            bbMax = {5.8, 1.0, 5.0},
            bbMin = {-5.8, -5.0, -height}
        },
        -- LOLLO NOTE the collider here seems to have no effect.
        -- We already get it in elevated_stairs.module, so never mind
        collider = {
            params = {
                halfExtents = {5.8, 3.0, 32.0}
            },
            transf = idTransf,
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
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 7.8, -1.5, 0.8, 1}
                                },
                                {
                                    -- ticket machine upstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -7.75, -2.7, 0.8, 1}
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
                                -- {
                                --     -- floor paving
                                --     --materials = {'station/rail/era_c/era_c_trainstation_floor_1.mtl'}, -- same as era_c_station_floor_1.mtl
                                --     --materials = {'station/rail/era_c/era_c_station_floor_1.mtl'},
                                --     materials = {'station/road/streetstation/streetstation_perron_base_new.mtl'},
                                --     mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod0.msh',
                                --     name = 'station_1_main_perron',
                                --     transf = groundFloorPavingTransf
                                -- },
                                {
                                    -- front left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontLeftPillarTransf
                                },
                                {
                                    --front right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontRightPillarTransf
                                },
                                {
                                    --rear left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearLeftPillarTransf
                                },
                                {
                                    -- rear right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearRightPillarTransf
                                },
                                {
                                    -- ticket machine downstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 7.47, 0.2, -height, 1}
                                },
                                {
                                    -- ticket machine downstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -7.47, 0.2, -height, 1}
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
                                -- floor paving upstairs
                                {
                                    -- materials = {'station/rail/era_c/era_c_trainstation_floor_1.mtl'},
                                    -- mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod0.msh',
                                    -- mesh = 'floor_with_hole.msh',
                                    materials = {
                                        'station/rail/era_c/era_c_trainstation_floor_1.mtl',
                                        'lollo_freestyle_train_station/shaft.mtl'
                                    },
                                    mesh = 'lollo_freestyle_train_station/lift/floor_with_hole_and_shaft.msh',
                                    name = 'floor_paving_upstairs',
                                    transf = floorPavingWithHoleTransf
                                },
                                -- floor bracket
                                {
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'station_1_main_floor',
                                    transf = floorTransf
                                }
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        },
                        --[[                         {
                            animations = {
                                forever = {
                                    forward = true,
                                    params = {
                                        keyframes = {
                                            {
                                                rot = {0, 0, 0},
                                                time = 0,
                                                transl = {0, 0, 0}
                                            },
                                            {
                                                rot = {0, 0, 0},
                                                time = 4000,
                                                transl = {0, 0, -22}
                                            },
                                            {
                                                rot = {0, 0, 0},
                                                time = 6000,
                                                transl = {0, 0, -22}
                                            },
                                            {
                                                rot = {0, 0, 0},
                                                time = 10000,
                                                transl = {0, 0, 0}
                                            },
                                            {
                                                rot = {0, 0, 0},
                                                time = 12000,
                                                transl = {0, 0, 0}
                                            }
                                        },
                                        origin = {0, 0, 0}
                                    },
                                    type = 'KEYFRAME'
                                }
                            },
                            materials = {'industry/construction_material/trim_2.mtl'},
                            mesh = 'industry/construction_material/lod_0_building_2_elevator.msh',
                            --transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2.5, 0, 30, 1, },
                            transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 1}
                        }, ]]
                        --[[ 						{
							animations = {
								forever = {
									forward = false,
									params = {
										keyframes = {
											{
												rot = { 0, 0, 0, },
												time = 0,
												transl = { 0, 0, 1, },
											},
											{
												rot = { 0, 0, 0, },
												time = 4000,
												transl = { 0, 0, -25, },
											},
											{
												rot = { 0, 0, 0, },
												time = 6000,
												transl = { 0, 0, -25, },
											},
											{
												rot = { 0, 0, 0, },
												time = 10000,
												transl = { 0, 0, 1, },
											},
											{
												rot = { 0, 0, 0, },
												time = 12000,
												transl = { 0, 0, 1, },
											},
										},
										origin = { 0, 0, 0, },
									},
									type = "KEYFRAME",
								},
							},
							materials = { "industry/construction_material/trim_2.mtl", },
							mesh = "industry/construction_material/lod_0_building_2_elevator.msh",
							--transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -8.5, 0, 30, 1, },
                            transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -2.5, 0, -1, 1, },
                        }, ]]
                        {
                            children = _wallsBelowThePlatformLod0,
                            name = 'walls_below_the_platform',
                            transf = idTransf
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
                                    mesh = 'lollo_freestyle_train_station/lift/lollo12x6x5top.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = topTransf
                                }
                            },
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
                            transf = {2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -5.1, -.1, 1}
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
                                -- above the platform
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
                                -- {
                                --     -- floor paving
                                --     materials = {'station/road/streetstation/streetstation_perron_base_new.mtl'},
                                --     mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod1.msh',
                                --     name = 'station_1_main_perron',
                                --     transf = groundFloorPavingTransf
                                -- },
                                {
                                    -- front left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontLeftPillarTransf
                                },
                                {
                                    --front right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontRightPillarTransf
                                },
                                {
                                    --rear left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearLeftPillarTransf
                                },
                                {
                                    -- rear right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearRightPillarTransf
                                },
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
                                    mesh = 'lollo_freestyle_train_station/lift/floor_with_hole_and_shaft.msh',
                                    name = 'floor_paving_upstairs',
                                    transf = floorPavingWithHoleTransf
                                },
                                -- floor bracket
                                {
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'station_1_main_floor',
                                    transf = floorTransf
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
                                    mesh = 'lollo_freestyle_train_station/lift/lollo12x6x5top.msh',
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
                visibleTo = 400
            },
            {
                node = {
                    children = {
                        {
                            children = {
                                -- ground level
                                -- {
                                --     -- floor paving
                                --     materials = {'station/road/streetstation/streetstation_perron_base_new.mtl'},
                                --     mesh = 'station/rail/era_c/station_1_main/station_1_main_perron_lod2.msh',
                                --     name = 'station_1_main_perron',
                                --     transf = groundFloorPavingTransf
                                -- },
                                {
                                    -- front left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontLeftPillarTransf
                                },
                                {
                                    --front right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = frontRightPillarTransf
                                },
                                {
                                    --rear left pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearLeftPillarTransf
                                },
                                {
                                    -- rear right pillar
                                    materials = {'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl'},
                                    mesh = 'industry/oil_refinery/era_a/oil_refinery_wall_large/oil_refinery_wall_large_lod0.msh',
                                    name = 'oil_refinery_wall_large',
                                    transf = rearRightPillarTransf
                                },
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
                                    mesh = 'lollo_freestyle_train_station/lift/lollo12x6x5top.msh',
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
                visibleFrom = 400,
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
                        nLines = 1,
                        size = {5.2, .6},
                        transf = {1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, -2.6, -5.333, .23, 1},
                        type = 'STATION_NAME',
                        verticalAlignment = 'CENTER'
                    }
                }
            },
            transportNetworkProvider = {
                laneLists = {
                    {
                        -- down the stairs
                        linkable = true,
                        nodes = {
                            {
                                {0, 0, 0.80000001192093},
                                {0, -1, 0},
                                2.4000000953674
                            },
                            {
                                {0, -2, 0.80000001192093},
                                {0, -1, 0},
                                2.4000000953674
                            },
                            {
                                {0, -2, 0.80000001192093},
                                {0, -1, 0},
                                2.4000000953674
                            },
                            {
                                {0, -2.5, 0},
                                {0, -1, 0},
                                2.4000000953674
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    -- {
                    --     -- horizontally into the across underpass
                    --     nodes = {
                    --         {
                    --             {0, -0, underpassZed},
                    --             {0, -2.5, 0},
                    --             2.4000000953674
                    --         },
                    --         {
                    --             {0, -2.5, underpassZed},
                    --             {0, -2.5, 0},
                    --             2.4000000953674
                    --         }
                    --     },
                    --     speedLimit = 20,
                    --     transportModes = {'PERSON'}
                    -- },
                    {
                        -- out to the back
                        nodes = {
                            {
                                {0, 0, -height},
                                {0, -1, 0},
                                2.4
                            },
                            {
                                {0, -2.5, -height},
                                {0, -1, 0},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    {
                        -- sideways, to connect extra elements
                        nodes = {
                            {
                                {-6, -2.5, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {0, -2.5, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {0, -2.5, -height},
                                {1, 0, 0},
                                2.4
                            },
                            {
                                {6, -2.5, -height},
                                {1, 0, 0},
                                2.4
                            },
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    height > 0 and
                        {
                            -- straight down and then out
                            -- LOLLO NOTE alter the sequence if underpassZed changes!
                            linkable = true,
                            nodes = {
                                {
                                    {0, -2.5, 0},
                                    {0, 0, -1}, -- 0, 0, 0 crashes, 0, 0, -1 and 0, 0, 1 hide the people, 0, 1, 0 and 1, 0, 0 have them walk while being lifted
                                    2.4
                                },
                                {
                                    {0, -2.5, underpassZed},
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, -2.5, underpassZed},
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, -2.5, -height},
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, -2.5, -height},
                                    {0, -1, 0},
                                    2.4
                                },
                                {
                                    {0, -5, -height},
                                    {0, -1, 0},
                                    2.4
                                }
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        } or
                        {
                            -- straight down and then out
                            -- LOLLO NOTE alter the sequence if underpassZed changes!
                            linkable = true,
                            nodes = {
                                {
                                    {0, -2.5, 0},
                                    {0, 0, -1}, -- 0, 0, 0 crashes, 0, 0, -1 and 0, 0, 1 hide the people, 0, 1, 0 and 1, 0, 0 have them walk while being lifted
                                    2.4
                                },
                                {
                                    {0, -2.5, underpassZed},
                                    {0, 0, -1},
                                    2.4
                                }
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        }
                },
                runways = {},
                terminals = {}
            }
        },
        version = 1
    }
end
