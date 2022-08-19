local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local transfUtilUG = require('transf')

-- LOLLO BUG when you split a road near a modded street station, whose mod was removed,
-- and then apply a modifier, such as add / remove bus lane or change the street type,
-- the game crashes.
-- This happens with single as well as double-sided stations.
-- You can tell those stations because the game shows a placeholder at their location.
-- This seems to be a UG problem.
-- To solve the issue, replace those stations with some others available in your game.

local _eventId = '__lolloTrackSplitterEvent__'
local _eventProperties = {
    lollo_track_splitter_w_api = { conName = 'station/rail/lollo_freestyle_train_station/lollo_track_splitter_w_api.con', eventName = 'trackSplitterWithApiBuilt' },
}

local function _isBuildingConstructionWithFileName(args, fileName)
    local toAdd =
        type(args) == 'table' and type(args.proposal) == 'userdata' and type(args.proposal.toAdd) == 'userdata' and
        args.proposal.toAdd

    if toAdd and #toAdd > 0 then
        for i = 1, #toAdd do
            if toAdd[i].fileName == fileName then
                return true
            end
        end
    end

    return false
end

local function _isBuildingTrackSplitterWithApi(args)
    return _isBuildingConstructionWithFileName(args, _eventProperties.lollo_track_splitter_w_api.conName)
end

local _utils = {
    getWhichEdgeGetsEdgeObjectAfterSplit = function(edgeObjPosition, node0pos, node1pos, nodeBetween)
        local result = {
            assignToSide = nil,
        }
        -- print('LOLLO attempting to place edge object with position =') debugPrint(edgeObjPosition)
        -- print('wholeEdge.node0pos =') debugPrint(node0pos)
        -- print('nodeBetween.position =') debugPrint(nodeBetween.position)
        -- print('nodeBetween.tangent =') debugPrint(nodeBetween.tangent)
        -- print('wholeEdge.node1pos =') debugPrint(node1pos)

        local edgeObjPosition_assignTo = nil
        local node0_assignTo = nil
        local node1_assignTo = nil
        -- at nodeBetween, I can draw the normal to the road:
        -- y = a + bx
        -- the angle is alpha = atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + PI / 2
        -- so b = math.tan(alpha)
        -- a = y - bx
        -- so a = nodeBetween.position.y - b * nodeBetween.position.x
        -- points under this line will go one way, the others the other way
        local alpha = math.atan2(nodeBetween.tangent.y, nodeBetween.tangent.x) + math.pi * 0.5
        local b = math.tan(alpha)
        if math.abs(b) < 1e+06 then
            local a = nodeBetween.position.y - b * nodeBetween.position.x
            if a + b * edgeObjPosition[1] > edgeObjPosition[2] then -- edgeObj is below the line
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if a + b * node0pos[1] > node0pos[2] then -- wholeEdge.node0pos is below the line
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if a + b * node1pos[1] > node1pos[2] then -- wholeEdge.node1pos is below the line
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        -- if b grows too much, I lose precision, so I approximate it with the y axis
        else
            -- print('alpha =', alpha, 'b =', b)
            if edgeObjPosition[1] > nodeBetween.position.x then
                edgeObjPosition_assignTo = 0
            else
                edgeObjPosition_assignTo = 1
            end
            if node0pos[1] > nodeBetween.position.x then
                node0_assignTo = 0
            else
                node0_assignTo = 1
            end
            if node1pos[1] > nodeBetween.position.x then
                node1_assignTo = 0
            else
                node1_assignTo = 1
            end
        end

        if edgeObjPosition_assignTo == node0_assignTo then
            result.assignToSide = 0
        elseif edgeObjPosition_assignTo == node1_assignTo then
            result.assignToSide = 1
        end

        -- print('LOLLO assignment =')
        -- debugPrint(result)
        return result
    end,
    sendCommand = function(eventName, args)
        if not args or not args.result or not args.result[1] then return end

        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            string.sub(debug.getinfo(1, 'S').source, 1),
            _eventId,
            eventName,
            {
                constructionEntityId = args.result[1]
            }
        ))
    end,
}

local _actions = {
    bulldozeConstruction = function(conId)
        -- print('conId =', conId)
        if type(conId) ~= 'number' or conId < 0 then return end

        local oldConstruction = api.engine.getComponent(conId, api.type.ComponentType.CONSTRUCTION)
        -- print('oldConstruction =')
        -- debugPrint(oldConstruction)
        if not(oldConstruction) or not(oldConstruction.params) then return end

        local proposal = api.type.SimpleProposal.new()
        -- LOLLO NOTE there are asymmetries how different tables are handled.
        -- This one requires this system, UG says they will document it or amend it.
        proposal.constructionsToRemove = { conId }
        -- proposal.constructionsToRemove[1] = conId -- fails to add
        -- proposal.constructionsToRemove:add(conId) -- fails to add

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, nil, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(res, success)
                -- print('LOLLO _bulldozeConstruction res = ') debugPrint(res)
                -- print('LOLLO _bulldozeConstruction success = ') debugPrint(success)
            end
        )
    end,

    splitTrackEdge = function(wholeEdgeId, nodeBetween)
        if not(edgeUtils.isValidAndExistingId(wholeEdgeId)) or type(nodeBetween) ~= 'table' then return end

        local oldBaseEdge = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE)
        local oldBaseEdgeTrack = api.engine.getComponent(wholeEdgeId, api.type.ComponentType.BASE_EDGE_TRACK)
        -- save a crash when a modded road underwent a breaking change, so it has no oldEdgeTrack
        if oldBaseEdge == nil or oldBaseEdgeTrack == nil then return end

        local node0 = api.engine.getComponent(oldBaseEdge.node0, api.type.ComponentType.BASE_NODE)
        local node1 = api.engine.getComponent(oldBaseEdge.node1, api.type.ComponentType.BASE_NODE)
        if node0 == nil or node1 == nil then return end

        if not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)) and not(edgeUtils.isXYZSame(nodeBetween.refPosition0, node1.position)) then
            logger.warn('splitTrackEdge cannot find the nodes')
        end
        local isNodeBetweenOrientatedLikeMyEdge = edgeUtils.isXYZSame(nodeBetween.refPosition0, node0.position)
        local distance0 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance0 or nodeBetween.refDistance1
        local distance1 = isNodeBetweenOrientatedLikeMyEdge and nodeBetween.refDistance1 or nodeBetween.refDistance0
        local tanSign = isNodeBetweenOrientatedLikeMyEdge and 1 or -1

        local oldTan0Length = edgeUtils.getVectorLength(oldBaseEdge.tangent0)
        local oldTan1Length = edgeUtils.getVectorLength(oldBaseEdge.tangent1)

        local playerOwned = api.type.PlayerOwned.new()
        playerOwned.player = api.engine.util.getPlayer()

        local newNodeBetween = api.type.NodeAndEntity.new()
        newNodeBetween.entity = -3
        newNodeBetween.comp.position = api.type.Vec3f.new(nodeBetween.position.x, nodeBetween.position.y, nodeBetween.position.z)

        local newEdge0 = api.type.SegmentAndEntity.new()
        newEdge0.entity = -1
        newEdge0.type = 1 -- 0 is api.type.enum.Carrier.ROAD, 1 is api.type.enum.Carrier.RAIL
        newEdge0.comp.node0 = oldBaseEdge.node0
        newEdge0.comp.node1 = -3
        newEdge0.comp.tangent0 = api.type.Vec3f.new(
            oldBaseEdge.tangent0.x * distance0 / oldTan0Length,
            oldBaseEdge.tangent0.y * distance0 / oldTan0Length,
            oldBaseEdge.tangent0.z * distance0 / oldTan0Length
        )
        newEdge0.comp.tangent1 = api.type.Vec3f.new(
            nodeBetween.tangent.x * distance0 * tanSign,
            nodeBetween.tangent.y * distance0 * tanSign,
            nodeBetween.tangent.z * distance0 * tanSign
        )
        newEdge0.comp.type = oldBaseEdge.type -- respect bridge or tunnel
        newEdge0.comp.typeIndex = oldBaseEdge.typeIndex -- respect bridge or tunnel type
        newEdge0.playerOwned = playerOwned
        newEdge0.trackEdge = oldBaseEdgeTrack

        local newEdge1 = api.type.SegmentAndEntity.new()
        newEdge1.entity = -2
        newEdge1.type = 1 -- 0 is api.type.enum.Carrier.ROAD, 1 is api.type.enum.Carrier.RAIL
        newEdge1.comp.node0 = -3
        newEdge1.comp.node1 = oldBaseEdge.node1
        newEdge1.comp.tangent0 = api.type.Vec3f.new(
            nodeBetween.tangent.x * distance1 * tanSign,
            nodeBetween.tangent.y * distance1 * tanSign,
            nodeBetween.tangent.z * distance1 * tanSign
        )
        newEdge1.comp.tangent1 = api.type.Vec3f.new(
            oldBaseEdge.tangent1.x * distance1 / oldTan1Length,
            oldBaseEdge.tangent1.y * distance1 / oldTan1Length,
            oldBaseEdge.tangent1.z * distance1 / oldTan1Length
        )
        newEdge1.comp.type = oldBaseEdge.type
        newEdge1.comp.typeIndex = oldBaseEdge.typeIndex
        newEdge1.playerOwned = playerOwned
        newEdge1.trackEdge = oldBaseEdgeTrack

        if type(oldBaseEdge.objects) == 'table' then
            -- local edge0StationGroups = {}
            -- local edge1StationGroups = {}
            local edge0Objects = {}
            local edge1Objects = {}
            for _, edgeObj in pairs(oldBaseEdge.objects) do
                local edgeObjPosition = edgeUtils.getObjectPosition(edgeObj[1])
                -- print('edge object position =') debugPrint(edgeObjPosition)
                if type(edgeObjPosition) ~= 'table' then return end -- change nothing and leave
                local assignment = _utils.getWhichEdgeGetsEdgeObjectAfterSplit(
                    edgeObjPosition,
                    {node0.position.x, node0.position.y, node0.position.z},
                    {node1.position.x, node1.position.y, node1.position.z},
                    nodeBetween
                )
                if assignment.assignToSide == 0 then
                    -- LOLLO NOTE if we skip this check,
                    -- one can split a road between left and right terminals of a streetside staion
                    -- and add more terminals on the new segments.
                    -- local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(edgeObj[1])
                    -- if arrayUtils.arrayHasValue(edge1StationGroups, stationGroupId) then return end -- don't split station groups
                    -- if edgeUtils.isValidId(stationGroupId) then table.insert(edge0StationGroups, stationGroupId) end
                    table.insert(edge0Objects, { edgeObj[1], edgeObj[2] })
                elseif assignment.assignToSide == 1 then
                    -- local stationGroupId = api.engine.system.stationGroupSystem.getStationGroup(edgeObj[1])
                    -- if arrayUtils.arrayHasValue(edge0StationGroups, stationGroupId) then return end -- don't split station groups
                    -- if edgeUtils.isValidId(stationGroupId) then table.insert(edge1StationGroups, stationGroupId) end
                    table.insert(edge1Objects, { edgeObj[1], edgeObj[2] })
                else
                    -- print('don\'t change anything and leave')
                    -- print('LOLLO error, assignment.assignToSide =', assignment.assignToSide)
                    return -- change nothing and leave
                end
            end
            newEdge0.comp.objects = edge0Objects -- LOLLO NOTE cannot insert directly into edge0.comp.objects. Different tables are handled differently...
            newEdge1.comp.objects = edge1Objects
        end

        local proposal = api.type.SimpleProposal.new()
        proposal.streetProposal.edgesToAdd[1] = newEdge0
        proposal.streetProposal.edgesToAdd[2] = newEdge1
        proposal.streetProposal.edgesToRemove[1] = wholeEdgeId
        proposal.streetProposal.nodesToAdd[1] = newNodeBetween

        local context = api.type.Context:new()
        context.checkTerrainAlignment = true -- default is false, true gives smoother Z
        -- context.cleanupStreetGraph = true -- default is false
        -- context.gatherBuildings = true  -- default is false
        -- context.gatherFields = true -- default is true
        context.player = api.engine.util.getPlayer() -- default is -1

        api.cmd.sendCommand(
            api.cmd.make.buildProposal(proposal, context, true), -- the 3rd param is "ignore errors"; wrong proposals will be discarded anyway
            function(result, success)
                -- print('LOLLO track splitter callback returned result = ') debugPrint(result)
                -- print('LOLLO track splitter callback returned success = ', success)
                if not(success) then
                    logger.warn('splitTrackEdge failed, proposal = ') logger.warningDebugPrint(proposal)
                end
            end
        )
    end,
}

function data()
    return {
        -- guiInit = function()
		-- end,
        handleEvent = function(src, id, name, args)
            if (id ~= _eventId) then return end
            if type(args) ~= 'table' then return end

            xpcall(
                function()
                    -- print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'args =') debugPrint(args)

                    local conTransf = api.engine.getComponent(args.constructionEntityId, api.type.ComponentType.CONSTRUCTION).transf
                    conTransf = transfUtilUG.new(conTransf:cols(0), conTransf:cols(1), conTransf:cols(2), conTransf:cols(3))
                    -- print('type(constructionTransf) =', type(constructionTransf)) debugPrint(constructionTransf)
                    if name == _eventProperties.lollo_track_splitter_w_api.eventName then
                        local nearestEdgeId = edgeUtils.track.getNearestEdgeIdStrict(conTransf)
                        -- print('track splitter got nearestEdge =', nearestEdgeId or 'NIL')
                        if edgeUtils.isValidAndExistingId(nearestEdgeId) and not(edgeUtils.isEdgeFrozen(nearestEdgeId)) then
                            local nodeBetween = edgeUtils.getNodeBetweenByPosition(
                                nearestEdgeId,
                                -- LOLLO NOTE position and transf are always very similar
                                {
                                    x = conTransf[13],
                                    y = conTransf[14],
                                    z = conTransf[15],
                                }
                            )
                            -- print('nodeBetween =') debugPrint(nodeBetween)
                            _actions.splitTrackEdge(nearestEdgeId, nodeBetween)
                        end
                    end

                    _actions.bulldozeConstruction(args.constructionEntityId)
                end,
                logger.xpErrorHandler
            )
        end,
        guiHandleEvent = function(id, name, args)
            -- LOLLO NOTE args can have different types, even boolean, depending on the event id and name
            if id == 'constructionBuilder' and name == 'builder.apply' then
                -- if name == "builder.proposalCreate" then return end
                -- logger.print('guiHandleEvent caught id = constructionBuilder and name = builder.apply')
                xpcall(
                    function()
                        if not args.result or not args.result[1] then return end

                        if _isBuildingTrackSplitterWithApi(args) then
                            _utils.sendCommand(_eventProperties.lollo_track_splitter_w_api.eventName, args)
                        end
                    end,
                    logger.xpErrorHandler
                )
            end
        end,
        -- update = function()
        -- end,
        -- guiUpdate = function()
        -- end,
    }
end
