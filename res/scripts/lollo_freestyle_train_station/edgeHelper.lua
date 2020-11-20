local matrixUtils = require('lollo_freestyle_train_station.matrix')
local quadrangleUtils = require('lollo_freestyle_train_station.quadrangleUtils')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

if math.atan2 == nil then
    math.atan2 = function(dy, dx)
        local result = 0
        if dx == 0 then
            result = math.pi * 0.5
        else
            result = math.atan(dy / dx)
        end

        if dx > 0 then
            return result
        elseif dx < 0 and dy >= 0 then
            return result + math.pi
        elseif dx < 0 and dy < 0 then
            return result - math.pi
        elseif dy > 0 then
            return result
        elseif dy < 0 then
            return - result
        else return false
        end
    end
end

local helper = {}

helper.getVectorLength = function(xyz)
    if type(xyz) ~= 'table' then return nil end
    local x = xyz.x or xyz[1] or 0.0
    local y = xyz.y or xyz[2] or 0.0
    local z = xyz.z or xyz[3] or 0.0
    return math.sqrt(x * x + y * y + z * z)
end

helper.getNearbyEntities = function(transf)
    if type(transf) ~= 'table' then return {} end

    -- debugger()
    local edgeSearchRadius = 0.0
    local squareCentrePosition = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local results = game.interface.getEntities(
        {pos = squareCentrePosition, radius = edgeSearchRadius},
        {includeData = true}
        -- {includeData = true}
    )

    return results
end

local function swap(num1, num2)
    local swapTemp = num1
    num1 = num2
    num2 = swapTemp
end

helper.getNearestEdgeId = function(transf)
    if type(transf) ~= 'table' then return nil end

    local _position = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local _searchRadius = 0.5
    local _box0 = api.type.Box3.new(
        api.type.Vec3f.new(_position[1] - _searchRadius, _position[2] - _searchRadius, -9999),
        api.type.Vec3f.new(_position[1] + _searchRadius, _position[2] + _searchRadius, 9999)
    )
    local baseEdgeIds = {}
    local callback0 = function(entity, boundingVolume)
        -- print('callback0 found entity', entity)
        -- print('boundingVolume =')
        -- debugPrint(boundingVolume)
        if not(entity) then return end

        if not(api.engine.getComponent(entity, api.type.ComponentType.BASE_EDGE)) then return end
        -- print('the entity is a BASE_EDGE')

        baseEdgeIds[#baseEdgeIds+1] = entity
    end
    api.engine.system.octreeSystem.findIntersectingEntities(_box0, callback0)

    if #baseEdgeIds == 0 then
        return nil
    elseif #baseEdgeIds == 1 then
        return baseEdgeIds[1]
    else
        -- print('multiple base edges found')
        -- choose one edge and return its id
        for i = 1, #baseEdgeIds do
            local baseEdge = api.engine.getComponent(baseEdgeIds[i], api.type.ComponentType.BASE_EDGE)
            local baseEdgeStreet = api.engine.getComponent(baseEdgeIds[i], api.type.ComponentType.BASE_EDGE_STREET)
            if baseEdge ~= nil and baseEdgeStreet ~= nil then -- false when there is a modded road that underwent a breaking change
                local node0 = api.engine.getComponent(baseEdge.node0, api.type.ComponentType.BASE_NODE)
                local node1 = api.engine.getComponent(baseEdge.node1, api.type.ComponentType.BASE_NODE)
                local streetTypeProperties = api.res.streetTypeRep.get(baseEdgeStreet.streetType)
                local halfStreetWidth = (streetTypeProperties.streetWidth or 0) * 0.5 + (streetTypeProperties.sidewalkWidth or 0)
                local alpha = math.atan2(node1.position.y - node0.position.y, node1.position.x - node0.position.x)
                local xPlus = - math.sin(alpha) * halfStreetWidth
                local yPlus = math.cos(alpha) * halfStreetWidth
                local vertices = {
                    [1] = {
                        x = node0.position.x - xPlus,
                        y = node0.position.y - yPlus
                    },
                    [2] = {
                        x = node0.position.x + xPlus,
                        y = node0.position.y + yPlus
                    },
                    [3] = {
                        x = node1.position.x + xPlus,
                        y = node1.position.y + yPlus
                    },
                    [4] = {
                        x = node1.position.x - xPlus,
                        y = node1.position.y - yPlus
                    },
                }
                -- check if the _position falls within the quadrangle approximating the edge
                -- LOLLO NOTE I could get a more accurate polygon (not necessarily a quadrangle!) getIsPointWithin
                -- api.engine.getComponent(entity, api.type.ComponentType.LOT_LIST)
                -- but it returns nothing with bridges and tunnels
                if quadrangleUtils.getIsPointWithin(quadrangleUtils.getVerticesSortedClockwise(vertices), _position) then
                    return baseEdgeIds[i]
                end
            end
        end
        -- print('falling back')
        return baseEdgeIds[1] -- fallback
    end
end

helper.getNearestEdgeIds = function(transf, searchRadius)
    if type(transf) ~= 'table' then return nil end

    local _position = transfUtils.getVec123Transformed({0, 0, 0}, transf)
    local _searchRadius = searchRadius or 0.5
    local _box0 = api.type.Box3.new(
        api.type.Vec3f.new(_position[1] - _searchRadius, _position[2] - _searchRadius, -9999),
        api.type.Vec3f.new(_position[1] + _searchRadius, _position[2] + _searchRadius, 9999)
    )
    local baseEdgeIds = {}
    local callback0 = function(entity, boundingVolume)
        -- print('callback0 found entity', entity)
        -- print('boundingVolume =')
        -- debugPrint(boundingVolume)
        if not(entity) then return end

        if not(api.engine.getComponent(entity, api.type.ComponentType.BASE_EDGE)) then return end
        -- print('the entity is a BASE_EDGE')

        baseEdgeIds[#baseEdgeIds+1] = entity
    end
    api.engine.system.octreeSystem.findIntersectingEntities(_box0, callback0)

    return baseEdgeIds
end

local function sign(num1)
    if type(num1) ~= 'number' then return nil end

    if num1 == 0 then return 0 end
    if num1 > 0 then return 1 end
    return -1
end

helper.getNodeBetween = function(position0, tangent0, position1, tangent1, betweenPosition)
    if not(position0) or not(position1) or not(tangent0) or not(tangent1) then return nil end

    local node01Distance = helper.getVectorLength({
        position1.x - position0.x,
        position1.y - position0.y,
        position1.z - position0.z
    })
    if node01Distance == 0 then return nil end

    local node01DistanceXY = helper.getVectorLength({
        position1.x - position0.x,
        position1.y - position0.y,
        0.0
    })
    local x20Shift = type(betweenPosition) ~= 'table'
        and
            0.5
        or
            (helper.getVectorLength({
                betweenPosition.x - position0.x,
                betweenPosition.y - position0.y,
                -- betweenPosition.z - position0.z
                -- 0.0
            }) / node01Distance)
    -- print('x20Shift =', x20Shift or 'NIL')
    -- shift everything around betweenPosition to avoid large numbers being summed and subtracted
    local x0 = position0.x - betweenPosition.x
    local x1 = position1.x - betweenPosition.x
    local y0 = position0.y - betweenPosition.y
    local y1 = position1.y - betweenPosition.y
    local ypsilon0 = math.atan2(tangent0.y, tangent0.x)
    local ypsilon1 = math.atan2(tangent1.y, tangent1.x)
    local z0 = position0.z - betweenPosition.z
    local z1 = position1.z - betweenPosition.z
    -- rotate the edges around the Z axis so that y0 = y1
    local zRotation = -math.atan2(y1 - y0, x1 - x0)
    local x0I = x0
    local x1I = x0 + node01DistanceXY
    local y0I = y0
    local ypsilon0I = ypsilon0 + zRotation
    local ypsilon1I = ypsilon1 + zRotation
    local z0I = z0
    local z1I = z1

    local invertedXMatrix = matrixUtils.invert(
        {
            {1, x0I, x0I * x0I, x0I * x0I * x0I},
            {1, x1I, x1I * x1I, x1I * x1I * x1I},
            {0, 1, 2 * x0I, 3 * x0I * x0I},
            {0, 1, 2 * x1I, 3 * x1I * x1I}
        }
    )

    if not(invertedXMatrix) then return nil end -- if x0 == x1 the system cannot be solved, this is why I rotated it. If it still fails, reject.

    local _maxTangent = 3 -- node01DistanceXY * 0.3 -- 5 -- this is tricky. In edge cases, I will be approximating a U or a J with a polynom.
    -- That means, the bottom tip of the U or the bottom tip of the J will be infinitely far away from its top.
    -- This factor keeps the curve in shape, but it must have the right sign. Beyond that, I can reject or bodge.
    -- Also, tangents have a discontinuity at +/- PI/2: bodging could get tricky
    -- AN idea could be: replace the equation with the large tangent with one based on the position the user clicked.
    local tan0I = math.tan(ypsilon0I)
    if math.abs(tan0I) > _maxTangent then return nil end
    local tan1I = math.tan(ypsilon1I)
    if math.abs(tan1I) > _maxTangent then return nil end

    -- Now I solve the system for y:
    -- a + b x0' + c x0'^2 + d x0'^3 = y0'
    -- a + b x1' + c x1'^2 + d x1'^3 = y0' .. y0' == y1' by construction
    -- b + 2 c x0' + 3 d x0'^2 = sin0' / cos0'
    -- b + 2 c x1' + 3 d x1'^2 = sin1' / cos1'
    local abcdY = matrixUtils.mul(
        invertedXMatrix,
        {
            {y0I},
            {y0I},
            {tan0I},
            {tan1I}
        }
    )
    local aY = abcdY[1][1]
    local bY = abcdY[2][1]
    local cY = abcdY[3][1]
    local dY = abcdY[4][1]

    -- Now I solve the system for z:
    -- a + b x0' + c x0'^2 + d x0'^3 = z0'
    -- a + b x1' + c x1'^2 + d x1'^3 = z1'
    -- b + 2 c x0' + 3 d x0'^2 = sin0' / cos0'
    -- b + 2 c x1' + 3 d x1'^2 = sin1' / cos1'
    local abcdZ = matrixUtils.mul(
        invertedXMatrix,
        {
            {z0I},
            {z1I},
            {tangent0.z / helper.getVectorLength({tangent0.x, tangent0.y, 0.0})},
            {tangent1.z / helper.getVectorLength({tangent1.x, tangent1.y, 0.0})},
        }
    )
    local aZ = abcdZ[1][1]
    local bZ = abcdZ[2][1]
    local cZ = abcdZ[3][1]
    local dZ = abcdZ[4][1]

    -- Now I take x2' between x0' and x1',
    local x2I = x0I + (x1I - x0I) * x20Shift
    local y2I = aY + bY * x2I + cY * x2I * x2I + dY * x2I * x2I * x2I
    local z2I = aZ + bZ * x2I + cZ * x2I * x2I + dZ * x2I * x2I * x2I
    -- calculate its y derivative:
    local DYOnDX2I = bY + 2 * cY * x2I + 3 * dY * x2I * x2I
    local ypsilon2I = math.atan(DYOnDX2I)
    -- calculate its z derivative:
    local DZOnDX2I = bZ + 2 * cZ * x2I + 3 * dZ * x2I * x2I
    local zeta2I = math.atan(DZOnDX2I)

    -- Now I undo the rotation and the traslation I did at the beginning
    local ro2 = helper.getVectorLength({x2I - x0I, y2I - y0I, 0.0})
    local alpha2I = math.atan2(y2I - y0I, x2I - x0I)

    local nodeBetween = {
        position = {
            x0I + ro2 * math.cos(alpha2I - zRotation) + betweenPosition.x,
            y0I + ro2 * math.sin(alpha2I - zRotation) + betweenPosition.y,
            z2I + betweenPosition.z
        },
        tangent = {
            math.cos(ypsilon2I - zRotation),
            math.sin(ypsilon2I - zRotation),
            math.sin(zeta2I)
        }
    }

    -- normalise tangent
    local tangentLength = helper.getVectorLength(nodeBetween.tangent)
    if tangentLength ~= 0 and tangentLength ~= 1 then
        nodeBetween.tangent[1] = nodeBetween.tangent[1] / tangentLength
        nodeBetween.tangent[2] = nodeBetween.tangent[2] / tangentLength
        nodeBetween.tangent[3] = nodeBetween.tangent[3] / tangentLength
    end

    return nodeBetween
end

return helper