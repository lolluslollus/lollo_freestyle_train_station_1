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

return helpers
