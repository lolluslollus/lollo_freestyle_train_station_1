local helpers = {}
    local _minExtent = 0.1
    local _tolerance = 0.1

    helpers.getTrackBoundingInfo = function(length, width, height)
        local x = math.max(length * 0.5 - _tolerance, _minExtent)
        local y = math.max(width * 0.5 - _tolerance, _minExtent)
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
        return {
            params = {
                halfExtents = {
                    math.max(length * 0.5 - _tolerance, _minExtent),
                    math.max(width * 0.5 - _tolerance, _minExtent),
                    math.max(height * 0.5 - _tolerance, _minExtent),
                },
            },
            transf = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, height * 0.5, 1, },
            type = "BOX",
        }
    end

return helpers
