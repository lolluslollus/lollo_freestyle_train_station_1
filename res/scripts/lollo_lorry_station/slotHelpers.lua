local _constants = require('lollo_lorry_station/constants')
local helpers = {}

helpers.getFlatTable = function(nestedTable)
    local results = {}
    if type(nestedTable) == 'table' then
        for kx, vx in pairs(nestedTable) do
            if type(vx) == 'table' then
                for ky, vy in pairs(vx) do
                    results[#results+1] = {x = kx, y = ky, value = vy}
                end
            end
        end
    end
    return results
end
helpers.getValueFromNestedTable = function(nestedTable, x, y)
    if not(nestedTable[tostring(x)]) then return nil end
    return nestedTable[tostring(x)][tostring(y)]
end
helpers.setValueInNestedTable = function(nestedTable, newValue, x, y)
    if not nestedTable[tostring(x)] then nestedTable[tostring(x)] = {} end
    nestedTable[tostring(x)][tostring(y)] = newValue
end
local function getPoint(inValues, x, y)
    -- print('LOLLO getPoint, x = ', x, ' y = ', y)
    if x > _constants.xMax or x < _constants.xMin
    or y > _constants.yMax or y < _constants.yMin
    then return false end
    return helpers.getValueFromNestedTable(inValues, x, y) or false
end
local function addPointThenNeighbours(inValues, outValues, visitedXYs, x, y)
    if x > _constants.xMax or x < _constants.xMin
    or y > _constants.yMax or y < _constants.yMin
    then return end

    if (helpers.getValueFromNestedTable(visitedXYs, x, y) or false) then return end

    helpers.setValueInNestedTable(visitedXYs, true, x, y)

    local valueAtXY = getPoint(inValues, x, y)
    if not valueAtXY then return end

    outValues[#outValues+1] = valueAtXY

    addPointThenNeighbours(inValues, outValues, visitedXYs, x, y + 1)
    addPointThenNeighbours(inValues, outValues, visitedXYs, x + 1, y)
    addPointThenNeighbours(inValues, outValues, visitedXYs, x, y - 1)
    addPointThenNeighbours(inValues, outValues, visitedXYs, x - 1, y)
end
helpers.getAdjacentValues = function(inValuesNested, x, y)
    local results = {}
    local visitedXYs = {}
    helpers.setValueInNestedTable(visitedXYs, true, x, y)

    addPointThenNeighbours(inValuesNested, results, visitedXYs, x, y + 1)
    addPointThenNeighbours(inValuesNested, results, visitedXYs, x + 1, y)
    addPointThenNeighbours(inValuesNested, results, visitedXYs, x, y - 1)
    addPointThenNeighbours(inValuesNested, results, visitedXYs, x - 1, y)

    return results
end

helpers.getCargoAreaModelIndexesBase0 = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        -- if helpers.getIsCargoAreaInner15x15(model.tag) or helpers.getIsCargoAreaInner12x12(model.tag) then
        if helpers.getIsCargoAreaInner12x12(model.tag) then
            local x = tostring((model.transf[13]  - _constants.anyInnerXShift) / _constants.xTransfFactor)
            local y = tostring((model.transf[14]  - _constants.anyInnerYShift) / _constants.yTransfFactor)
            helpers.setValueInNestedTable(results, base0ModelIndex, x, y)
        -- elseif helpers.getIsCargoAreaInner5x5(model.tag) or helpers.getIsCargoAreaInner4x4(model.tag) then
        elseif helpers.getIsCargoAreaInner4x4(model.tag) then
            local x = tostring((model.transf[13]  - _constants.anyInnerXShift) / _constants.xTransfFactor)
            local y = tostring((model.transf[14]  - _constants.anyInnerYShift) / _constants.yTransfFactor)
            helpers.setValueInNestedTable(results, base0ModelIndex, x, y)
        -- elseif helpers.getIsCargoAreaStreetside15x5(model.tag) or helpers.getIsCargoAreaStreetside12x4(model.tag) then
        elseif helpers.getIsCargoAreaStreetside12x4(model.tag) then
            local x = tostring((model.transf[13]  - _constants.anyStreetsideXShift) / _constants.xTransfFactor)
            local y = tostring((model.transf[14]  - _constants.anyStreetsideYShift) / _constants.yTransfFactor)
            helpers.setValueInNestedTable(results, base0ModelIndex, x, y)
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end

helpers.getCargoAreaModelIndexesBase0Simple = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        if -- helpers.getIsCargoAreaInner15x15(model.tag)
        helpers.getIsCargoAreaInner12x12(model.tag)
        -- or helpers.getIsCargoAreaInner5x5(model.tag)
        or helpers.getIsCargoAreaInner4x4(model.tag)
        -- or helpers.getIsCargoAreaStreetside15x5(model.tag)
        or helpers.getIsCargoAreaStreetside12x4(model.tag)
        then
            results[#results+1] = base0ModelIndex
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end

helpers.getCargoLinksModelIndexesBase0Simple = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        if helpers.getIsCargoLink4x4(model.tag) then
            results[#results+1] = base0ModelIndex
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end

helpers.getLorryBayModelIndexesBase0 = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        if helpers.getIsLorryBay(model.tag) then
            -- results[#results+1] = {
            --         x = (model.transf[13]  - _constants.anyStreetsideXShift) / _constants.xTransfFactor,
            --         y = (model.transf[14]  - _constants.anyStreetsideYShift) / _constants.yTransfFactor,
            --         z = model.transf[15],
            --         base0ModelIndex = base0ModelIndex
            --     }
            results[#results+1] = base0ModelIndex
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end

helpers.getStreetsideModelIndexesBase0 = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        if helpers.getIsStreetside(model.tag) then
            results[#results+1] = base0ModelIndex
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end


helpers.getVehicleEdgeModelIndexesBase0 = function(models)
    local results = {}
    local base0ModelIndex = 0
    for _, model in pairs(models) do
        if helpers.getIsVehicleEdge(model.tag) then
            -- results[#results+1] = {
            --         x = (model.transf[13]  - _constants.anyStreetsideXShift) / _constants.xTransfFactor,
            --         y = (model.transf[14]  - _constants.anyStreetsideYShift) / _constants.yTransfFactor,
            --         z = model.transf[15],
            --         base0ModelIndex = base0ModelIndex
            --     }
            results[#results+1] = base0ModelIndex
        end
        base0ModelIndex = base0ModelIndex + 1
    end
    return results
end

helpers.getIsCargoAreaInner12x12 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaInner12x12ModelTag) then
        return true
    else
        return false
    end
end

helpers.getIsCargoAreaInner15x15 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaInner15x15ModelTag) then
        -- return tag:sub(('cargoArea_slotId_'):len() + 1) or false
        return true
    else
        return false
    end
end

helpers.getIsCargoAreaInner4x4 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaInner4x4ModelTag) then
        return true
    else
        return false
    end
end

helpers.getIsCargoAreaInner5x5 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaInner5x5ModelTag) then
        -- return tag:sub(('smallCargoArea_slotId_'):len() + 1) or false
        return true
    else
        return false
    end
end

helpers.getIsCargoAreaStreetside12x4 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaStreetside12x4ModelTag) then
        return true
    else
        return false
    end
end

helpers.getIsCargoAreaStreetside15x5 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoAreaStreetside15x5ModelTag) then
        -- return tag:sub(('streetsideCargoArea_slotId_'):len() + 1) or false
        return true
    else
        return false
    end
end

helpers.getIsCargoLink4x4 = function(tag)
    if type(tag) == 'string' and tag:find(_constants.cargoLinks4x4ModelTag) then
        return true
    else
        return false
    end
end

helpers.getIsLorryBay = function(tag)
    -- if type(tag) == 'string' and (tag:find(_constants.lorryBayStreetside15x5ModelTag) or tag:find(_constants.lorryBayStreetside12x4ModelTag)) then
    if type(tag) == 'string' and tag:find(_constants.lorryBayStreetside12x4ModelTag) then
        return true
    else
        return false
    end
end

helpers.getIsStreetside = function(tag)
    if type(tag) == 'string' and (
        tag:find(_constants.cargoAreaStreetside12x4ModelTag)
        or tag:find(_constants.lorryBayStreetside12x4ModelTag)
        or tag:find(_constants.lorryBayStreetsideEntrance12x4ModelTag)
    ) then
        return true
    else
        return false
    end
end

helpers.getIsVehicleEdge = function(tag)
    if type(tag) == 'string' and (tag:find(_constants.lorryBayVehicleEdgeRightModelTag) or tag:find(_constants.lorryBayVehicleEdgeLeftModelTag)) then
        return true
    else
        return false
    end
end

helpers.demangleId = function(slotId)
    local function _getIdBase(slotId)
        local baseId = 0
        for _, v in pairs(_constants.idBasesSortedDesc) do
            if slotId >= v.id then
                baseId = v.id
                break
            end
        end

        return baseId > 0 and baseId or false
    end

    local baseId = _getIdBase(slotId)
    if not baseId then return false, false, false end

    local y = math.floor((slotId - baseId) / _constants.idRoundingFactor)
    local x = math.floor((slotId - baseId - y * _constants.idRoundingFactor))

    return x + _constants.xMin, y + _constants.yMin, baseId
end

helpers.mangleId = function(x, y, baseId)
    return baseId + _constants.idRoundingFactor * (y  - _constants.yMin) + (x  - _constants.xMin)
end

return helpers