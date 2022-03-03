local _constants = require('lollo_freestyle_train_station.constants')

local helpers = {}
    local _minExtent = 0.1
    local _tolerance = 0.1

    helpers.getSubwayBoundingInfo = function(length, width)
        return {
            bbMax = {
                4.5, 1.0, 3
            },
            bbMin = {
                0, -1.0, -4
            },
        }
    end
    helpers.getSubwayCollider = function(width, length)
        return {
            params = {
                halfExtents = {
                    2.25 - _tolerance,
                    1.0 - _tolerance,
                    3.5 - _tolerance,
                },
            },
            transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  2.25, 0, -0.5, 1, },
            type = 'BOX',
        }
    end

    helpers.getPlatformStretchFactor = function(length, width)
        if width < 10 and length <= 4 then return 1.075 end

        local lengthAdjusted = math.max(length, 4) -- 4 is the shape step of our platform tracks, incidentally
        local widthAdjusted = math.max(width, 5) -- narrow platforms are trickier than it appears they should
        return 1 + widthAdjusted / lengthAdjusted * 0.06
    end

    helpers.getSlopedPlatformStretchFactor = function(length, width)
        return 1
        -- if width < 10 and length <= 4 then return 1.075 end

        -- local lengthAdjusted = math.max(length, 4) -- 4 is the shape step of our platform tracks, incidentally
        -- local widthAdjusted = math.max(width, 5) -- narrow platforms are trickier than it appears they should
        -- return 1 + widthAdjusted / lengthAdjusted * 0.06
    end

    helpers.getPlatformTrackEraACargoMaterials = function()
        return {
            'lollo_freestyle_train_station/era_a_station_tiles_1.mtl',
            'lollo_freestyle_train_station/square_cobbles.mtl',
            'lollo_freestyle_train_station/era_a_station_tiles_1_z.mtl',
            'lollo_freestyle_train_station/square_cobbles_z.mtl',
        }
    end

    helpers.getPlatformTrackEraBCargoMaterials = function()
        return {
            'lollo_freestyle_train_station/station_concrete_3.mtl',
            'lollo_freestyle_train_station/square_cobbles_large.mtl',
            'lollo_freestyle_train_station/station_concrete_3_z.mtl',
            'lollo_freestyle_train_station/square_cobbles_large_z.mtl',
        }
    end

    helpers.getPlatformTrackEraCCargoMaterials = function()
        return {
            'lollo_freestyle_train_station/station_concrete_3.mtl',
            'lollo_freestyle_train_station/station_concrete_1.mtl',
            'lollo_freestyle_train_station/station_concrete_3_z.mtl',
            'lollo_freestyle_train_station/station_concrete_1_z.mtl',
        }
    end

    helpers.getPlatformTrackEraAPassengerMaterials = function()
        return {
            'lollo_freestyle_train_station/era_a_station_tiles_1.mtl',
            'lollo_freestyle_train_station/square_cobbles.mtl',
            'lollo_freestyle_train_station/era_a_station_tiles_1_z.mtl',
            'lollo_freestyle_train_station/square_cobbles_z.mtl',
        }
    end

    helpers.getPlatformTrackEraBPassengerMaterials = function()
        return {
            'lollo_freestyle_train_station/era_b_station_tiles_1.mtl',
            'lollo_freestyle_train_station/square_cobbles_large.mtl',
            'lollo_freestyle_train_station/era_b_station_tiles_1_z.mtl',
            'lollo_freestyle_train_station/square_cobbles_large_z.mtl',
        }
    end

    helpers.getPlatformTrackEraCPassengerMaterials = function()
        return {
            'lollo_freestyle_train_station/era_c_station_tiles_1.mtl',
            'lollo_freestyle_train_station/station_concrete_1.mtl',
            'lollo_freestyle_train_station/era_c_station_tiles_1_z.mtl',
            'lollo_freestyle_train_station/station_concrete_1_z.mtl',
        }
    end

    helpers.getTrackBoundingInfo = function(length, width, height)
        local adjustedLength = 1
        local adjustedWidth = 1
        local x = math.max(adjustedLength * 0.5 - _tolerance, _minExtent)
        local y = math.max(adjustedWidth * 0.5 - _tolerance, _minExtent)
        local z = math.max(height * 0.5 - _tolerance, _minExtent)
        return {
            bbMax = {
                x, y, height * 0.5 + z
            },
            bbMin = {
                -x, -y, height * 0.5 - z
            },
        }
    end
    helpers.getTrackCollider = function(length, width, height)
        local adjustedLength = 1
        local adjustedWidth = 1
        return {
            params = {
                halfExtents = {
                    math.max(adjustedLength * 0.5 - _tolerance, _minExtent),
                    math.max(adjustedWidth * 0.5 - _tolerance, _minExtent),
                    math.max(height * 0.5 - _tolerance, _minExtent),
                },
            },
            transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, height * 0.5, 1, },
            type = 'BOX',
        }
    end

    -- LOLLO NOTE if a construction contains models without bounding info and collider,
    -- it will still detect collisions with them. With these, we avoid that problem.
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

    helpers.subway = {
        getClaphamMediumTransportNetworkProvider = function()
            return {
                laneLists = {
                    { -- across the model
                        linkable = true,
                        nodes = {
                            {
                                { -1.5, 0, 0 },
                                { 0.5, 0, 0 },
                                3,
                            },
                            {
                                { -1, 0, 0 },
                                { 0.5, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- into the model
                        linkable = false,
                        nodes = {
                            {
                                { -1, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                            {
                                { 0, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- down into the earth
                        linkable = false,
                        nodes = {
                            {
                                { 0, 0, 0 },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                            {
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, _constants.subwayPos2LinkZ },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                },
                runways = { },
                terminals = { },
            }
        end,
        getHollowayTransportNetworkProvider = function()
            return {
                laneLists = {
                    { -- across the model
                        linkable = true,
                        nodes = {
                            {
                                { -2.5, 0, 0 },
                                { 0.5, 0, 0 },
                                3,
                            },
                            {
                                { -2, 0, 0 },
                                { 0.5, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- across the model
                        linkable = false,
                        nodes = {
                            {
                                { -2, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                            {
                                { -1, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- into the model
                        linkable = false,
                        nodes = {
                            {
                                { -1, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                            {
                                { 0, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- down into the earth
                        linkable = false,
                        nodes = {
                            {
                                { 0, 0, 0 },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                            {
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, _constants.subwayPos2LinkZ },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                },
                runways = { },
                terminals = { },
            }
        end,
        getSubwayTransportNetworkProvider = function()
            return {
                laneLists = {
                    { -- into the model
                        linkable = true,
                        nodes = {
                            {
                                { -1, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                            {
                                { 0, 0, 0 },
                                { 1, 0, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                    { -- down into the earth
                        linkable = false,
                        nodes = {
                            {
                                { 0, 0, 0 },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                            {
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, _constants.subwayPos2LinkZ },
                                { _constants.subwayPos2LinkX, _constants.subwayPos2LinkY, 0 },
                                3,
                            },
                        },
                        transportModes = { 'PERSON', },
                        speedLimit = 20,
                    },
                },
                runways = { },
                terminals = { },
            }
        end,
    }

return helpers
