return function(height, eraPrefix)
    local _constants = require('lollo_freestyle_train_station.constants')
    local _moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')
    local _eraPrefix = eraPrefix or _moduleHelpers.eras.era_c.prefix

    local _allMaterials = {
        era_a = {
            doors = 'lollo_freestyle_train_station/era_a_doors.mtl',
            hole = 'lollo_freestyle_train_station/hole.mtl',
            iron = 'lollo_freestyle_train_station/metal/metal_w_rivets.mtl',
            iron_pillar = 'lollo_freestyle_train_station/metal/metal_w_large_rivets.mtl',
            roof = 'lollo_freestyle_train_station/metal/metal_ceiling_vintage_002.mtl',
            stationSign = "station/rail/era_a/era_a_trainstation_assets.mtl",
            tiles = 'lollo_freestyle_train_station/era_a_station_tiles_1_z.mtl',
        },
        era_b = {
            hole = 'lollo_freestyle_train_station/hole.mtl',
            -- shaft = 'lollo_freestyle_train_station/shaft.mtl',
            shaft = 'lollo_freestyle_train_station/era_b_lift_doors.mtl',
            stationSign = "lollo_freestyle_train_station/asset/era_b_station_signs.mtl",
            tiles = 'lollo_freestyle_train_station/era_b_station_tiles_1_z.mtl',
            wallGrey = 'lollo_freestyle_train_station/wall_marble_2.mtl',
            wallGreyDeco = 'lollo_freestyle_train_station/wall_marble_2.mtl',
            wallWhite = 'lollo_freestyle_train_station/wall_marble_1.mtl',
            wallWhiteDeco = 'lollo_freestyle_train_station/wall_marble_1.mtl',
        },
        era_c = {
            hole = 'lollo_freestyle_train_station/hole.mtl',
            shaft = 'lollo_freestyle_train_station/shaft.mtl',
            stationSign = 'station/rail/era_c/era_c_trainstation_assets.mtl',
            tiles = 'lollo_freestyle_train_station/era_c_station_tiles_1_z.mtl',
            wallGrey = 'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_stripes.mtl',
            -- wallGreyDeco = 'lollo_freestyle_train_station/lollo_trainstation_wall_grey_no_horiz_stripes.mtl',
            wallGreyDeco = 'lollo_freestyle_train_station/facade_modern_ribbed.mtl',
            wallWhite = 'lollo_freestyle_train_station/lollo_trainstation_wall_white_no_stripes.mtl',
            wallWhiteDeco = 'lollo_freestyle_train_station/lollo_trainstation_wall_white.mtl',
        }
    }
    local _materials = nil
    if _eraPrefix == _moduleHelpers.eras.era_a.prefix then
        _materials = _allMaterials.era_a
    elseif _eraPrefix == _moduleHelpers.eras.era_b.prefix then
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
    if _eraPrefix == _moduleHelpers.eras.era_a.prefix then
        _meshes = _allMeshes.era_a
    elseif _eraPrefix == _moduleHelpers.eras.era_b.prefix then
        _meshes = _allMeshes.era_b
    else
        _meshes = _allMeshes.era_c
    end

    local _labelColour = nil
    if _eraPrefix == _moduleHelpers.eras.era_a.prefix then
        _labelColour = { 0, 0, 0, }
    elseif _eraPrefix == _moduleHelpers.eras.era_b.prefix then
        _labelColour = { 255, 255, 255, }
    else
        _labelColour = { 255, 255, 255, }
    end

    local function _getWallsBelowPlatform(lod)
        local results = {}

        local zShift4Wall = -1.8 + 5
        for h = 5, height, 5 do
            zShift4Wall = zShift4Wall - 5
            local wallTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 1.45, zShift4Wall, 1}

            if _eraPrefix == _moduleHelpers.eras.era_a.prefix then
                results[#results + 1] = {
                    materials = h == 5 and {
                        _materials.iron_pillar,
                    } or {
                        _materials.iron,
                        _materials.iron_pillar,
                    },
                    mesh = h == 5 and 'lollo_freestyle_train_station/lift/era_a_platform_lift_9x5x5_top.msh' or 'lollo_freestyle_train_station/lift/era_a_lift_9x5x5_level.msh',
                    transf = wallTransf
                }
            elseif _eraPrefix == _moduleHelpers.eras.era_b.prefix then
                local mesh = 'lollo_freestyle_train_station/lift/era_b_lift9x5x5level_deco.msh'
                if h == 5 then mesh = 'lollo_freestyle_train_station/lift/era_b_platform_lift_9x5x5_top.msh'
                elseif h == height then mesh = 'lollo_freestyle_train_station/lift/era_b_lift9x5x5level.msh'
                end
                results[#results + 1] = {
                    materials = {
                        _materials.wallGrey,
                        _materials.wallGreyDeco,
                        _materials.wallWhite,
                    },
                    mesh = mesh,
                    transf = wallTransf
                }
            else
                local mesh = 'lollo_freestyle_train_station/lift/era_c_lift9x5x5level.msh'
                if h == 5 then mesh = 'lollo_freestyle_train_station/lift/era_c_platform_lift_9x5x5_top.msh'
                end
                results[#results + 1] = {
                    materials = {
                        _materials.wallGrey,
                        _materials.wallGreyDeco,
                        _materials.wallWhite,
                    },
                    mesh = mesh,
                    transf = wallTransf
                }
            end
        end

        if lod == 0 then
            local zShift4Shaft = 0
            for h = 5, height, 5 do
                zShift4Shaft = zShift4Shaft - 5
                local zedZoom4Shaft = h == 5 and 0.93 or 1
                local shaftTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, zedZoom4Shaft, 0, 0, -0.3, zShift4Shaft, 1}
                if _eraPrefix == _moduleHelpers.eras.era_a.prefix then
                    results[#results + 1] = {
                        materials = {
                            _materials.iron,
                            _materials.doors,
                        },
                        mesh = 'lollo_freestyle_train_station/lift/era_a_inner_shaft_thin_lod0.msh',
                        transf = shaftTransf
                    }
                else
                    results[#results + 1] = {
                        materials = { _materials.shaft },
                        mesh = 'lollo_freestyle_train_station/lift/inner_shaft_thin_round_lod0.msh',
                        transf = shaftTransf
                    }
                end
            end
        end

        return results
    end
    local _wallsBelowThePlatformLod0 = _getWallsBelowPlatform(0)
    local _wallsBelowThePlatformLod1 = _getWallsBelowPlatform(1)

    local zedShift4groundRoof = -height + 2.9 -- - height * .6 + 2.60
    local zedShift4groundPillar = -height + 3.2
    local pillarsTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 1.45, zedShift4groundPillar, 1}
    local shaftTopTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -0.3, 0.15, 1}

    local idTransf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    local stationMainTransf = {0.6, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}

    --print('LOLLO height = ', height)
    return {
        boundingInfo = {
            -- bbMax = {4.4, 2.0, 4.0}, -- this would be the building without vents or tunnel awereness
            -- bbMin = {-4.4, -2.6, -height} -- this would be the building without vents or tunnel awereness
            bbMax = {4.4, 2.0, 5.5}, -- a bit taller to protect the vents from bridges
            bbMin = {-4.4, -2.6, -height -1.5} -- a bit lower to protect the floor from tunnels
        },
        collider = {
            params = {
                -- halfExtents = {4.4, 2.3, 2.0 + height * 0.5} -- this would be the building without vents or tunnel awereness
                halfExtents = {4.4, 2.3, 5.0 + height * 0.5} -- a bit taller to protect the floor from tunnels and the vents from bridges
            },
            -- transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -0.3, 2.0 - height * 0.5, 1 }, -- this would be the building without vents
            transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, -0.3, 0.5 - height * 0.5, 1 }, -- a bit lower to protect the floor from tunnels and the vents from bridges
            type = 'BOX'
        },
        lods = {
            {
                node = {
                    children = {
                        {
                            children = _eraPrefix == _moduleHelpers.eras.era_b.prefix and {
                                {
                                    -- ticket machine right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 6.90, 1.6, -height, 1}
                                },
                                {
                                    -- ticket machine left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_a_2/tickets_era_a_2_lod0.msh',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.90, 1.6, -height, 1}
                                },
                            } or _eraPrefix == _moduleHelpers.eras.era_c.prefix and {
                                {
                                    -- ticket machine right
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    transf = {0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 6.90, 1.6, -height, 1}
                                },
                                {
                                    -- ticket machine left
                                    materials = {'station/road/streetstation/streetstation_1.mtl'},
                                    mesh = 'station/road/streetstation/asset/tickets_era_c_1/tickets_era_c_1_lod0.msh',
                                    transf = {0, -1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.90, 1.6, -height, 1}
                                },
                            } or nil,
                            transf = stationMainTransf
                        },
                        {
                            children = _wallsBelowThePlatformLod0,
                            name = 'walls_below_the_platform',
                            transf = idTransf
                        },
                        -- pillars
                        _eraPrefix == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron_pillar },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/era_b_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        -- shaft top
                        _eraPrefix == _moduleHelpers.eras.era_a.prefix and {
                            materials = {
                                _materials.hole,
                                _materials.tiles,
                                _materials.iron,
                                _materials.doors,
                                _materials.roof,
                            },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_shaft_top_lod0.msh',
                            transf = shaftTopTransf
                        } or {
                            materials = {
                                _materials.shaft,
                                _materials.wallWhite,
                                _materials.hole,
                                'lollo_freestyle_train_station/station_concrete_1.mtl',
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
                        -- pillars
                        _eraPrefix == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron_pillar },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/era_b_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        },
                        -- shaft top
                        _eraPrefix == _moduleHelpers.eras.era_a.prefix and {
                            materials = {
                                _materials.hole,
                                _materials.tiles,
                                _materials.iron,
                                _materials.doors,
                                _materials.roof,
                            },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_shaft_top_lod0.msh',
                            transf = shaftTopTransf
                        } or {
                            materials = {
                                _materials.shaft,
                                _materials.wallWhite,
                                _materials.hole,
                                'lollo_freestyle_train_station/station_concrete_1.mtl',
                            },
                            mesh = 'lollo_freestyle_train_station/lift/shaft-top-round-lod0.msh',
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
                        -- pillars
                        _eraPrefix == _moduleHelpers.eras.era_a.prefix and {
                            materials = { _materials.iron_pillar },
                            mesh = 'lollo_freestyle_train_station/lift/era_a_9x5x3_225pillars.msh',
                            transf = pillarsTransf
                        } or {
                            materials = { _materials.wallGrey },
                            mesh = 'lollo_freestyle_train_station/lift/era_b_9x5x3_225pillars.msh',
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
            transportNetworkProvider = {
                laneLists = {
                    height > 0 and
                        {
                            -- straight down
                            linkable = false,
                            nodes = {
                                {
                                    {0, 0, _constants.underpassZ},
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
                                    {0, 0, -1},
                                    2.4
                                },
                                {
                                    {0, 0, -height + _constants.underpassZ},
                                    {0, 0, -1},
                                    2.4
                                },
                            },
                            speedLimit = 20,
                            transportModes = {'PERSON'}
                        } or nil,
                    {
                        -- out to the front
                        linkable = true,
                        nodes = {
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
                    },
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
