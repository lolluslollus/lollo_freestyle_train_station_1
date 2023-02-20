package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')


-- it boils down to this returning a wrong position (x should be < 106 but it is 106.29; refDistance0 is 2.05, which is what I wish, but it is inconsistent with the position)
local pos0 = {
    x = 103.88204956055,
    y = 684.29473876953,
    z = 56.414089202881,
}
local pos1 = {
    x = 109.86787414551,
    y = 684.45861816406,
    z = 56.578479766846,
}
local tan0 = {
    x = 4.9876294136047,
    y = 0.13657999038696,
    z = 0.15421308577061,
}
local tan1 = {
    x = 4.9875664710999,
    y = 0.13659618794918,
    z = 0.11138851940632,
}
local straightLength = transfUtils.getPositionsDistance(pos0, pos1) -- this is 5.99
local howManyTimes = 100000

logger.profile(
    'NOT_OPTIMISED',
    function()
        for i = 1, howManyTimes, 1 do
            local result_NOT_OPTIMISED = edgeUtils.getNodeBetween_NOT_OPTIMISED( -- this finds a length of 4.99: it makes no sense. The tangents in the input are too short.
            -- the correct length can be obtained with
            -- api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK).edges[1].geometry.length
            -- which gives 5.9903
                pos0,
                pos1,
                tan0,
                tan1,
                0.41044438488067,
                5.9903
            )
        end
    end
)

logger.profile(
    'CURRENT',
    function()
        for i = 1, howManyTimes, 1 do
            local result_CURRENT = edgeUtils.getNodeBetween( -- this finds a length of 4.99: it makes no sense. The tangents in the input are too short.
            -- the correct length can be obtained with
            -- api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK).edges[1].geometry.length
            -- which gives 5.9903
                pos0,
                pos1,
                tan0,
                tan1,
                0.41044438488067,
                5.9903
            )
        end
    end
)

logger.profile(
    'OPTIMISED',
    function()
        for i = 1, howManyTimes, 1 do
            local result_OPTIMISED = edgeUtils.getNodeBetween_OPTIMISED( -- this finds a length of 4.99: it makes no sense. The tangents in the input are too short.
            -- the correct length can be obtained with
            -- api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK).edges[1].geometry.length
            -- which gives 5.9903
                pos0,
                pos1,
                tan0,
                tan1,
                0.41044438488067,
                5.9903
            )
        end
    end
)

local dummy2 = 123
