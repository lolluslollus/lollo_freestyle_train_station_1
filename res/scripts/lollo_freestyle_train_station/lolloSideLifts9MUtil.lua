return function(height, era)
    local _constants = require('lollo_freestyle_train_station.constants')
    local _moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
    era = era or _moduleHelpers.eras.era_c.prefix

    local ventOneTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, -2, 4.5, 1}
    local ventTwoTransf = {-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, -2, 4.5, 1}
    local topTransf = {1, 0, 0, 0,  0, -1, 0, 0,  0, 0, 1, 0,  0, 0, 0.707 - 0.8, 1}

    local _allMaterials = {
        era_a = {
            stationSign = "station/rail/era_a/era_a_trainstation_assets.mtl",
            tiles = 'lollo_freestyle_train_station/era_a_station_tiles_1_z.mtl',
            iron = 'lollo_freestyle_train_station/metal/metal_w_rivets.mtl',
            doors = 'lollo_freestyle_train_station/era_a_doors.mtl',
            roof = 'lollo_freestyle_train_station/metal/metal_ceiling_vintage_002.mtl',
            roofDeco = 'lollo_freestyle_train_station/metal/metal_deco_002_repeat.mtl',
        },
        era_b = {
            shaft = 'lollo_freestyle_train_station/shaft.mtl',
            stationSign = "lollo_freestyle_train_station/asset/era_b_station_signs.mtl",
            tiles = 'lollo_freestyle_train_station/era_b_station_tiles_1_z.mtl',
            wallGrey = 'lollo_freestyle_train_station/wall_marble_2.mtl',
            wallGreyDeco = 'lollo_freestyle_train_station/wall_marble_2.mtl',
            wallWhite = 'lollo_freestyle_train_station/wall_marble_1.mtl',
            wallWhiteDeco = 'lollo_freestyle_train_station/wall_marble_1.mtl',
        },
        era_c = {
            shaft = 'lollo_freestyle_train_station/shaft.mtl',
            stationSign = 'station/rail/era_c/era_c_trainstation_assets.mtl',
            tiles = 'lollo_freestyle_train_station/era_c_station_tiles_1_z.mtl',
            wallGrey = 'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl',
            wallGreyDeco = 'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl',
            wallWhite = 'lollo_freestyle_train_station/lollo_trainstation_wall_white_no_stripes.mtl',
            wallWhiteDeco = 'lollo_freestyle_train_station/lollo_trainstation_wall_white.mtl',
        }
    }
    local _materials = nil
    if era == _moduleHelpers.eras.era_a.prefix then
        _materials = _allMaterials.era_a
    elseif era == _moduleHelpers.eras.era_b.prefix then
        _materials = _allMaterials.era_b
    else
        _materials = _allMaterials.era_c
    end

    local _allMeshes = {
        era_a = {
            stationSign = 'lollo_freestyle_train_station/asset/era_a_single_station_name_lod0.msh',
        },
        era_b = {
            stationSign = 'lollo_freestyle_train_station/asset/era_b_single_station_name_lod0.msh',
        },
        era_c = {
            stationSign = 'lollo_freestyle_train_station/asset/era_c_single_station_name_lod0.msh',
        },
    }
    local _meshes = nil
    if era == _moduleHelpers.eras.era_a.prefix then
        _meshes = _allMeshes.era_a
    elseif era == _moduleHelpers.eras.era_b.prefix then
        _meshes = _allMeshes.era_b
    else
        _meshes = _allMeshes.era_c
    end

    local _labelColour = nil
    if era == _moduleHelpers.eras.era_a.prefix then
        _labelColour = { 0, 0, 0, }
    elseif era == _moduleHelpers.eras.era_b.prefix then
        _labelColour = { 255, 255, 255, }
    else
        _labelColour = { 255, 255, 255, }
    end

    local function _getWallsBelowPlatform(lod)
        local results = {}

        local zShift4Wall = -1.8 + 5
        for h = 5, height, 5 do
            zShift4Wall = zShift4Wall - 5
            local wallTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, zShift4Wall, 1}
            if era == _moduleHelpers.eras.era_a.prefix then
                results[#results + 1] = {
                    materials = {
                        _materials.iron,
                    },
                    mesh = h == 5 and 'lollo_freestyle_train_station/lift/era_a_lift9x5x5top_level_deco.msh' or 'lollo_freestyle_train_station/lift/era_a_lift9x5x5level_deco.msh',
                    transf = wallTransf
                }
            else
                results[#results + 1] = {
                    --materials = {'industry/oil_refinery/era_a/wall_2.mtl'},
                    materials = {
                        _materials.wallGrey,
                        _materials.wallGreyDeco,
                        _materials.wallWhite,
                    },
                    mesh = h == 5 and 'lollo_freestyle_train_station/lift/lift9x5x5top_level_deco.msh' or 'lollo_freestyle_train_station/lift/lift9x5x5level_deco.msh',
                    transf = wallTransf
                }
            end
        end

        if lod == 0 then
            local zShift4Shaft = 0
            for h = 5, height, 5 do
                zShift4Shaft = zShift4Shaft - 5
                -- local zedZoom4Shaft = h == 5 and 0.5 or 1
                local zedZoom4Shaft = 1
                local shaftTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Shaft, 0, 0, -1.7, zShift4Shaft, 1}
                if era == _moduleHelpers.eras.era_a.prefix then
                    results[#results + 1] = {
                        materials = {
                            _materials.iron,
                            _materials.doors,
                        },
                        mesh = 'lollo_freestyle_train_station/lift/era_a_inner_shaft_lod0.msh',
                        transf = shaftTransf
                    }
                else
                    results[#results + 1] = {
                        materials = {_materials.shaft},
                        mesh = 'lollo_freestyle_train_station/lift/inner_shaft_round_lod0.msh',
                        transf = shaftTransf
                    }
                end
            end
        end

        return results
    end
    local _wallsBelowThePlatformLod0 = _getWallsBelowPlatform(0)
    local _wallsBelowThePlatformLod1 = _getWallsBelowPlatform(1)

    local pillarsTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, -1, 0,  0, 0, 3.2 - height, 1}
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
                            children = era == _moduleHelpers.eras.era_b.prefix and {
                                {
                                    -- ticket machine upstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5.25, -1.5, 0, 1}
                                },
                                {
                                    -- ticket machine upstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5.25, -2.7, 0, 1}
                                },
                                {
                                    -- ticket machine downstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5.97, 0.2, -height, 1}
                                },
                                {
                                    -- ticket machine downstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    name = 'tickets_era_c_1',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5.97, 0.2, -height, 1}
                                },
                                height > 5 and {
                                    -- roof vent 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventOneTransf
                                } or nil,
                                height > 5 and {
                                    -- roof vent 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventTwoTransf
                                } or nil,
                            } or era == _moduleHelpers.eras.era_c.prefix and {
                                {
                                    -- ticket machine upstairs right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5.25, -1.5, 0, 1}
                                },
                                {
                                    -- ticket machine upstairs left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5.25, -2.7, 0, 1}
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
                                height > 5 and {
                                    -- roof vent 1
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventOneTransf
                                } or nil,
                                height > 5 and {
                                    -- roof vent 2
                                    materials = {'asset/roof/asset_roof_decor1.mtl'},
                                    mesh = 'asset/roof/lod_0_ventilation_end_curved.msh',
                                    transf = ventTwoTransf
                                } or nil,
                            } or nil,
                            transf = stationMainTransf
                        },
                        {
                            children = _wallsBelowThePlatformLod0,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        -- pillars
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        -- top
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = {
                                _materials.iron,
                                _materials.tiles,
                                _materials.doors,
                                _materials.roof,
                                _materials.roofDeco,
                            },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_side_lift_top_9x5x5_lod0.msh',
                            transf = topTransf
                        } or {
                            materials = {
                                _materials.wallGrey,
                                _materials.wallGreyDeco,
                                _materials.wallWhite,
                                _materials.tiles,
                                _materials.shaft,
                            },
                            --materials = { "asset/roof/asset_roof_decor1.mtl", },
                            mesh = 'lollo_freestyle_train_station/lift/side_lift_top_9x5x5_lod0.msh',
                            transf = topTransf
                        },
                        {
                            children = {
                                {
                                    materials = { _materials.stationSign },
                                    mesh = _meshes.stationSign,
                                    transf = idTransf
                                }
                            },
                            transf = {1.4, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -4.25, -0.40, 1}
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
                        era ~= _moduleHelpers.eras.era_a.prefix and {
                            children = {
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
                            },
                            name = 'station_1_main_grp',
                            transf = stationMainTransf
                        } or nil,
                        {
                            children = _wallsBelowThePlatformLod1,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        -- pillars
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        -- top
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = {
                                _materials.iron,
                                _materials.tiles,
                                _materials.doors,
                                _materials.roof,
                                _materials.roofDeco,
                            },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_side_lift_top_9x5x5_lod0.msh',
                            transf = topTransf
                        } or {
                            materials = {
                                _materials.wallGrey,
                                _materials.wallGreyDeco,
                                _materials.wallWhite,
                                _materials.tiles,
                                _materials.shaft,
                            },
                            --materials = { "asset/roof/asset_roof_decor1.mtl", },
                            mesh = 'lollo_freestyle_train_station/lift/side_lift_top_9x5x5_lod1.msh',
                            transf = topTransf
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
                        -- pillars
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/lollo9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        -- top
                        era == _moduleHelpers.eras.era_a.prefix and {
                            materials = {
                                _materials.iron,
                                _materials.tiles,
                                _materials.doors,
                                _materials.roof,
                                _materials.roofDeco,
                            },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_side_lift_top_9x5x5_lod0.msh',
                            transf = topTransf
                        } or {
                            materials = {
                                _materials.wallGrey,
                                _materials.wallGreyDeco,
                                _materials.wallWhite,
                                _materials.tiles,
                                _materials.shaft,
                            },
                            --materials = { "asset/roof/asset_roof_decor1.mtl", },
                            mesh = 'lollo_freestyle_train_station/lift/side_lift_top_9x5x5_lod1.msh',
                            transf = topTransf
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
                        color = _labelColour,
                        fitting = 'SCALE',
                        -- renderMode = "EMISSIVE",
                        nLines = 2,
                        size = {4.0, 0.6},
                        transf = {1, 0, 0, 0,  0, 0, 1, 0,  0, -1, 0, 0,  -2.0, -4.29, 0.12 -0.8, 1},
                        type = 'STATION_NAME',
                        verticalAlignment = 'CENTER'
                    }
                }
            },
            transportNetworkProvider = {
                laneLists = {
                    {
                        -- across the hall and into the lift
                        linkable = false,
                        nodes = {
                            {
                                {0, 0, 0},
                                {0, -2, 0},
                                2.4
                            },
                            {
                                {0, -2.0, 0},
                                {0, -2, 0},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    },
                    height > 0 and
                    {
                        -- across the hall and into the lift, under the platform
                        linkable = false,
                        nodes = {
                            {
                                {0, 0, _constants.underpassZ},
                                {0, -2, 0},
                                2.4
                            },
                            {
                                {0, -2.0, _constants.underpassZ},
                                {0, -2, 0},
                                2.4
                            }
                        },
                        speedLimit = 20,
                        transportModes = {'PERSON'}
                    } or nil,
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
                                {0, -2.0, math.max(_constants.underpassZ, -height)},
                                {0, 0, -1},
                                2.4
                            },
                            {
                                {0, -2.0, math.max(_constants.underpassZ, -height)},
                                {0, 0, -1},
                                2.4
                            },
                            {
                                {0, -2.0, math.min(_constants.underpassZ, -height)},
                                {0, 0, -1},
                                2.4
                            },
                            {
                                {0, -2.0, math.min(_constants.underpassZ, -height)},
                                {0, 0, -1},
                                2.4
                            },
                            {
                                {0, -2.0, -height + _constants.underpassZ},
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
