local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local transfUtilUG = require('transf')

local function _myErrorHandler(err)
    print('lollo freestyle train station ERROR: ', err)
end

local _eventId = '__lolloFreestyleTrainStation__'
local _eventNames = {
    WAYPOINT_BUILT_ON_PLATFORM = 'waypointBuiltOnPlatform',
    WAYPOINT_BUILT_OUTSIDE_PLATFORM = 'waypointBuiltOutsidePlatform',
}

local function _calcContiguousEdges(firstEdgeId, firstNodeId, map, trackType, isInsertFirst, results)
    local refEdgeId = firstEdgeId
    local edgeIds = map[firstNodeId] -- userdata
    local refNodeId = firstNodeId
    local isExit = false
    while not(isExit) do
        if not(edgeIds) or #edgeIds ~= 2 then
            isExit = true
        else
            for _, edgeId in pairs(edgeIds) do -- cannot use edgeIds[index] here
                print('edgeId =')
                debugPrint(edgeId)
                if edgeId ~= refEdgeId then
                    local baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
                    print('baseEdgeTrack =')
                    debugPrint(baseEdgeTrack)
                    if not(baseEdgeTrack) or baseEdgeTrack.trackType ~= trackType then
                        isExit = true
                        break
                    else
                        if isInsertFirst then
                            table.insert(results, 1, edgeId)
                        else
                            table.insert(results, edgeId)
                        end
                        local edgeData = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
                        if edgeData.node0 ~= refNodeId then
                            refNodeId = edgeData.node0
                        else
                            refNodeId = edgeData.node1
                        end
                        refEdgeId = edgeId
                        break
                    end
                end
            end
            edgeIds = map[refNodeId]
        end
    end
end

local function _getContiguousEdges(edgeId, trackType)
    print('_getContiguousEdges starting, edgeId =')
    debugPrint(edgeId)
    print('track type =')
    debugPrint(trackType)

    if not(edgeId) or not(trackType) then return {} end

    local _baseEdgeTrack = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE_TRACK)
    if not(_baseEdgeTrack) or _baseEdgeTrack.trackType ~= trackType then return {} end

    local _baseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
    local _edgeId = edgeId
    local _map = api.engine.system.streetSystem.getNode2SegmentMap()
    local results = { edgeId }

    _calcContiguousEdges(_edgeId, _baseEdge.node0, _map, trackType, true, results)
    _calcContiguousEdges(_edgeId, _baseEdge.node1, _map, trackType, false, results)

    return results
end

local function _getLastBuiltEdge(entity2tn)
    local nodeIds = {}
    for k, _ in pairs(entity2tn) do
        local entity = game.interface.getEntity(k)
        if entity.type == 'BASE_NODE' then nodeIds[#nodeIds+1] = entity.id end
    end
    if #nodeIds ~= 2 then return nil end

    for k, _ in pairs(entity2tn) do
        local entity = game.interface.getEntity(k)
        if entity.type == 'BASE_EDGE'
        and ((entity.node0 == nodeIds[1] and entity.node1 == nodeIds[2])
        or (entity.node0 == nodeIds[2] and entity.node1 == nodeIds[1])) then
            local extraEdgeData = api.engine.getComponent(entity.id, api.type.ComponentType.BASE_EDGE)
            return {
                id = entity.id,
                objects = extraEdgeData.objects
            }
        end
    end

    return nil
end

local function _getTransfFromApiResult(transfStr)
    transfStr = transfStr:gsub('%(%(', '(')
    transfStr = transfStr:gsub('%)%)', ')')
    local results = {}
    for match0 in transfStr:gmatch('%([^(%))]+%)') do
        local noBrackets = match0:gsub('%(', '')
        noBrackets = noBrackets:gsub('%)', '')
        for match1 in noBrackets:gmatch('[%-%.%d]+') do
            results[#results + 1] = tonumber(match1 or '0')
        end
    end
    return results
end

local function _isBuildingConstructionWithFileName(param, fileName)
    local toAdd =
        type(param) == 'table' and type(param.proposal) == 'userdata' and type(param.proposal.toAdd) == 'userdata' and
        param.proposal.toAdd

    if toAdd and #toAdd > 0 then
        for i = 1, #toAdd do
            if toAdd[i].fileName == fileName then
                return true
            end
        end
    end

    return false
end

local function _isBuildingFreestyleTrainStation(param)
    return _isBuildingConstructionWithFileName(param, 'station/rail/lollo_freestyle_train_station.con')
end

function data()
    return {
        ini = function()
        end,
        handleEvent = function(src, id, name, param)
            if (id ~= _eventId) then return end
            -- if type(param) ~= 'table' or type(param.constructionEntityId) ~= 'number' or param.constructionEntityId < 0 then return end

            print('handleEvent firing, src =', src, 'id =', id, 'name =', name, 'param =')
            debugPrint(param)
            -- handleEvent firing, src =	lollo_freestyle_train_station.lua	id =	__lolloFreestyleTrainStation__	name =	waypointBuilt	param =

            -- print('param.constructionEntityId =', param.constructionEntityId or 'NIL')
            -- if name == 'lorryStationBuilt' then
            --     _replaceStationWithSnapNodes(param.constructionEntityId)
            -- elseif name == 'lorryStationSelected' then
            --     _replaceStationWithStreetType_(param.constructionEntityId)
            -- end
            -- LOLLO TODO remove waypoint
        end,
        guiHandleEvent = function(id, name, param)
            -- LOLLO NOTE param can have different types, even boolean, depending on the event id and name
            if name == 'builder.apply' then
                xpcall(
                    function()
                        print('guiHandleEvent caught id =', id, 'name =', name, 'param =')
                        debugPrint(param)

                        if param and param.proposal and param.proposal.proposal
                        and param.proposal.proposal.edgeObjectsToAdd
                        and param.proposal.proposal.edgeObjectsToAdd[1]
                        and param.proposal.proposal.edgeObjectsToAdd[1].modelInstance
                        then
                            local myWaypointModelId = api.res.modelRep.find('railroad/lollo_signal_waypoint.mdl')
                            local platformTrackType = api.res.trackTypeRep.find('platform.lua')

                            -- if not param.result or not param.result[1] then
                            --     return
                            -- end

                            if param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.modelId == myWaypointModelId then
                                print('LOLLO waypoint built!')
                                local lastBuiltEdge = _getLastBuiltEdge(param.data.entity2tn)
                                if not(lastBuiltEdge) then return end

                                -- local waypointId = api.engine.system.streetSystem.getEdgeForEdgeObject(lastBuiltEdge.id)
                                local waypointId = nil
                                for i = 1, #lastBuiltEdge.objects do
                                    -- debugPrint(game.interface.getEntity(lastBuiltEdge.objects[i][1]))
                                    local modelInstanceList = api.engine.getComponent(lastBuiltEdge.objects[i][1], api.type.ComponentType.MODEL_INSTANCE_LIST)
                                    -- print('LOLLO model instance list =')
                                    -- debugPrint(modelInstanceList)
                                    if modelInstanceList
                                    and modelInstanceList.fatInstances
                                    and modelInstanceList.fatInstances[1]
                                    and modelInstanceList.fatInstances[1].modelId == myWaypointModelId then
                                        waypointId = lastBuiltEdge.objects[i][1]
                                    end
                                end
                                if not(waypointId) then return end

                                -- LOLLO NOTE as I added an edge object, I have NOT split the edge
                                if param.proposal.proposal.addedSegments[1].trackEdge.trackType == platformTrackType then
                                    -- waypoint built on platform
                                    -- LOLLO TODO:
                                    -- find all consecutive edges of the same type
                                    -- sort them from first to last
                                    local test = _getContiguousEdges(
                                        lastBuiltEdge.id,
                                        platformTrackType
                                    )
                                    print('contiguous edges =')
                                    debugPrint(test)

                                    -- left side: find the 2 tracks (real tracks, not platform tracks) nearest to the platform start and end
                                    -- repeat on the right side
                                    -- if at least one normal track was found:
                                        -- raise an event
                                        -- the worker thread will:
                                        -- split the tracks near the ends of the platform (left and / or right)
                                        -- destroy all the tracks between the splits
                                        -- add a construction with:
                                            -- rail edges replacing the destroyed tracks
                                            -- many small models with straight person paths and terminals { personNode, personEdge, vehicleEdge }
                                            -- terminals with vehicleNodeOverride
                                        -- destroy the waypoint
                                        -- WHAT IF there is already a waypoint on the same table of platforms?
                                        -- WHAT IF the same track has already been split by another platform, or by the same?
                                        -- WHAT IF the user adds or removes an adjacent piece of platform?
                                            -- catch it and check if the station needs expanding
                                        -- WHAT IF the user removes a piece of platform inbetween?
                                            -- Homer Simpson: remove the station or make it on one end only
                                        -- WHAT IF the user destroys the construction?
                                            -- replace the edges with normal pieces of track
                                    -- else
                                        -- raise an event
                                        -- the worker thread will:
                                        -- destroy the waypoint
                                    -- endif
                                    game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BUILT_ON_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        -- transf = _getTransfFromApiResult(tostring(param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf))
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                    -- LOLLO TODO the worker thread must destroy the waypoint
                                else
                                    -- waypoint built outside platform
                                    game.interface.sendScriptEvent(_eventId, _eventNames.WAYPOINT_BUILT_OUTSIDE_PLATFORM, {
                                        edgeId = lastBuiltEdge.id,
                                        -- transf = _getTransfFromApiResult(tostring(param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf))
                                        transf = transfUtilUG.new(
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(0),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(1),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(2),
                                            param.proposal.proposal.edgeObjectsToAdd[1].modelInstance.transf:cols(3)
                                        ),
                                        waypointId = waypointId,
                                    })
                                end
                            end

                            -- if _isBuildingFreestyleTrainStation(param) then
                            --     game.interface.sendScriptEvent(
                            --         _eventId,
                            --         'lorryStationBuilt',
                            --         {
                            --             constructionEntityId = param.result[1]
                            --         }
                            --     )
                            -- end
                        end
                    end,
                    _myErrorHandler
                )
            
            --[[ elseif name == 'select' then
                print('guiHandleEvent firing, id =', id, 'name =', name, 'param =')
                debugPrint(param)

                if type(param) == 'number' then
                    local entity = game.interface.getEntity(param)

                    if (entity and entity.type == "STATION_GROUP") then
                        local allLorryStationConstructions = game.interface.getEntities(
                            {pos = entity.position, radius = 999},
                            {type = "CONSTRUCTION", includeData = true, fileName = "station/street/lollo_lorry_bay_with_edges.con"}
                        )
                        print('allLorryStationConstructions =')
                        debugPrint(allLorryStationConstructions)

                        -- the game distinguishes constructions, stations and station groups.
                        -- Constructions and stations in a station group are not selected, only the station group itself,
                        -- which does not contain a lot of data: this is why we need this loop.
                        -- The API here does not help, the old game.interface is better.
                        for _, staId in ipairs(entity.stations) do
                            for _, con in pairs(allLorryStationConstructions) do
                                if arrayUtils.arrayHasValue(con.stations, staId) then
                                    print('found con =')
                                    debugPrint(con)
                                    if con.id and con.params and con.params.streetType_ then
                                        local allStreetData = streetUtils.getGlobalStreetData(streetUtils.getStreetDataFilters().STOCK_AND_MODS)

                                        print('#allStreetData =', #allStreetData)
                                        if con.params.streetType_ > #allStreetData then
                                            game.interface.sendScriptEvent(
                                                _eventId,
                                                "lorryStationSelected",
                                                {
                                                    constructionEntityId = con.id,
                                                    constructionParams = con.params
                                                }
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end ]]
            end
        end,
        update = function()
        end,
        guiUpdate = function()
        end,
        -- save = function()
        --     return allState
        -- end,
        -- load = function(allState)
        -- end
    }
end