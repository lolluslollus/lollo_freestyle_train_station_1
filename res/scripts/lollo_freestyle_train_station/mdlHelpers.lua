local _constants = require('lollo_freestyle_train_station.constants')

local helpers = {}
    local _minExtent = 0.1
    local _tolerance = 0.1

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
            type = "BOX",
        }
    end

    -- LOLLO NOTE if a construction contains models without bounding info and collider,
    -- it will still detect collisions with them. With this, we avoid that problem.
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

    helpers.getSubwayMetadata = function()
        return {
            transportNetworkProvider = {
                laneLists = {
                    { -- into the model
                        linkable = true, -- false, --true,
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
                        linkable = false, -- false, --true,
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
            },
        }
    end

return helpers
