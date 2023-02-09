local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local autoBridgePathsHelper = require('lollo_freestyle_train_station.autoBridgePathsHelper')
local constants = require('lollo_freestyle_train_station.constants')
local logger = require('lollo_freestyle_train_station.logger')
local modulesutil = require 'modulesutil'
local openLiftOpenStairsHelpers = require('lollo_freestyle_train_station.openLiftOpenStairsHelpers')
local slotHelpers = require('lollo_freestyle_train_station.slotHelpers')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')
local trackUtils = require('lollo_freestyle_train_station.trackHelpers')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local transfUtilsUG = require 'transf'


local privateConstants = {
    cargoShelves = {
        -- setting this to 2 gets a negligible performance boost and uglier joints,
        -- particularly on slopes and bends
        bracketStep = 1,
        pillarPeriod = 5,
    },
    deco = {
        -- LOLLO NOTE setting this to 2 gets a negligible performance boost and uglier joints,
        -- particularly on slopes and bends
        ceilingStep = 1,
        numberSignPeriod = constants.maxPassengerWaitingAreaEdgeLength * 4,
        pillarPeriod = 4, -- this should be a submultiple of numberSignPeriod
    },
    lifts = {
        -- bridgeHeights = { 5, 10, 15, 20, 25, 30, 35, 40 } -- too little, stations get buried
        bridgeHeights = { 2.5, 7.5, 12.5, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5 }
        -- bridgeHeights = { 6.5, 11.5, 16.5, 21.5, 26.5, 31.5, 36.5, 41.5 }
    },
    slopedAreasOLD = {
        -- hunchLengthRatioToClaimBend = 0.01, -- must be positive
        hunchToClaimBend = 0.2, -- must be positive
        innerDegrees = {
            inner = 1,
            neutral = 0,
            outer = -1
        },
    }
}

local privateFuncs = {
    getFromVariant_0_or_1 = function(variant)
        return math.abs(math.fmod(variant, 2))
    end,
    getFromVariant_0_to_1 = function(variant, nSteps)
        local _nSteps = math.ceil(nSteps)
        return math.abs(math.fmod(variant, _nSteps) / (nSteps - 1))
    end,
    getFromVariant_AxialAreaTilt = function(variant)
        local tilt = -variant * 0.025
        local _maxRadAbs = 0.36
        if tilt > _maxRadAbs then tilt = _maxRadAbs elseif tilt < -_maxRadAbs then tilt = -_maxRadAbs end
        -- logger.print('getFromVariant_AxialAreaTilt returning', tilt, -_maxRadAbs, _maxRadAbs)
        return tilt, -_maxRadAbs, _maxRadAbs
    end,
    getFromVariant_BridgeTilt = function(variant)
        local tilt = variant * 0.0125
        local _maxRadAbs = 0.36
        if tilt > _maxRadAbs then tilt = _maxRadAbs elseif tilt < -_maxRadAbs then tilt = -_maxRadAbs end
        -- logger.print('getFromVariant_BridgeTilt returning', tilt, -_maxRadAbs, _maxRadAbs)
        return tilt, -_maxRadAbs, _maxRadAbs
    end,
    getFromVariant_FlatAreaHeight = function(variant, isFlush)
        local zShift = variant * 0.1 + (isFlush and 0 or constants.platformSideBitsZ)
        local _maxValueAbs = 1.2
        if zShift > _maxValueAbs then zShift = _maxValueAbs elseif zShift < -_maxValueAbs then zShift = -_maxValueAbs end
        -- logger.print('getFromVariant_FlatAreaHeight returning', zShift, -_maxValueAbs, _maxValueAbs)
        return zShift, -_maxValueAbs, _maxValueAbs
    end,
    getFromVariant_LiftHeight = function(variant)
        local deltaZ = 0
        if variant <= -2 then
            deltaZ = -10
        elseif variant <= -1 then
            deltaZ = -5
        elseif variant >= 2 then
            deltaZ = 10
        elseif variant >= 1 then
            deltaZ = 5
        end
        -- logger.print('getFromVariant_LiftHeight returning', deltaZ, -10, 10)
        return deltaZ, -10, 10
    end,
    getEraPrefix = function(params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge] or params.terminals[nTerminal].centrePlatformsRelative[1]
        local result = cpl.era or constants.eras.era_c.prefix
        if params.modules then
            if params.modules[slotHelpers.mangleId(nTerminal, 0, constants.idBases.platformEraASlotId)] then
                result = constants.eras.era_a.prefix
            elseif params.modules[slotHelpers.mangleId(nTerminal, 0, constants.idBases.platformEraBSlotId)] then
                result = constants.eras.era_b.prefix
            elseif params.modules[slotHelpers.mangleId(nTerminal, 0, constants.idBases.platformEraCSlotId)] then
                result = constants.eras.era_c.prefix
            end
        end

        return result
    end,
    getIsEndFillerEvery3 = function(nTrackEdge)
        -- this is for platform roofs and outside extensions, which have a slot every 3 track edge counts.
        -- to fill the last, if it is 4, 7, etc, we add an extra slot: this slot has a special behaviour,
        -- ie it does not draw on the adjacent track edges
        return math.fmod(nTrackEdge, 3) == 1
    end,
    getPlatformObjectTransf_AlwaysVertical = function(posTanX2)
        -- print('getPlatformObjectTransf_AlwaysVertical starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]

        local newTransf = transfUtilsUG.rotZTransl(
            math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
            {
                x = (pos1[1] + pos2[1]) * 0.5,
                y = (pos1[2] + pos2[2]) * 0.5,
                z = (pos1[3] + pos2[3]) * 0.5,
            }
        )

        -- print('newTransf =') debugPrint(newTransf)
        return newTransf
    end,
    getPlatformObjectTransf_WithYRotation = function(posTanX2) --, angleYFactor)
        -- print('_getUnderpassTransfWithYRotation starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]
    
        local angleZ = math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1])
        local transfZ = transfUtilsUG.rotZTransl(
            angleZ,
            {
                x = (pos1[1] + pos2[1]) * 0.5,
                y = (pos1[2] + pos2[2]) * 0.5,
                z = (pos1[3] + pos2[3]) * 0.5,
            }
        )
        -- local angleY = -math.atan((pos2[3] - pos1[3]) / transfUtils.getVectorLength(
        --     {
        --         pos2[1] - pos1[1],
        --         pos2[2] - pos1[2],
        --         0
        --     }
        -- ))
    
        local angleY = math.atan2(
            (pos2[3] - pos1[3]),
            transfUtils.getVectorLength(
                {
                    pos2[1] - pos1[1],
                    pos2[2] - pos1[2],
                    0
                }
            ) -- * (angleYFactor or 1)
        )
    
        local transfY = transfUtilsUG.rotY(-angleY)
    
        return transfUtilsUG.mul(transfZ, transfY)
        -- return transfUtilsUG.mul(transfY, transfZ) -- NO!
    end,
    -- returns an integer starting at 0, it can be positive or negative
    getVariant = function(params, slotId)
        local variant = 0
        if type(params) == 'table'
        and type(params.modules) == 'table'
        and type(params.modules[slotId]) == 'table'
        and type(params.modules[slotId].variant) == 'number' then
            variant = params.modules[slotId].variant or 0
        end
        return variant
    end,
}
privateFuncs.axialAreas = {
    getMNAdjustedTransf = function(params, slotId, slotTransf)
        local variant = privateFuncs.getVariant(params, slotId)
        local tilt = privateFuncs.getFromVariant_AxialAreaTilt(variant)
        return transfUtilsUG.mul(slotTransf, transfUtilsUG.rotY(tilt))
    end,
}
privateFuncs.deco = {
    addWallsAcross = function(cpf, isSideA, slopedAreaWidth, result, tag, wallModelId, zShift, deltaY)
        -- LOLLO TODO skip the wall around axial exits
        if isSideA then
            local posTanX2_1 = transfUtils.getParallelSidewaysWithRotZ(
                cpf.posTanX2,
                cpf.width / 2 + slopedAreaWidth - deltaY
            )
            local posTanX2_2 = transfUtils.getParallelSidewaysWithRotZ(
                cpf.posTanX2,
                cpf.width / 2 + slopedAreaWidth
            )
            local lengthAcross = deltaY
            local pos1 = posTanX2_1[1][1]
            local pos2 = posTanX2_2[1][1]

            result.models[#result.models+1] = {
                id = 'lollo_freestyle_train_station/icon/blue.mdl',
                transf = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    pos1[1], pos1[2], pos1[3], 1
                },
                tag = tag
            }
            result.models[#result.models+1] = {
                id = 'lollo_freestyle_train_station/icon/orange.mdl',
                transf = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    pos2[1], pos2[2], pos2[3], 1
                },
                tag = tag
            }

            -- print('pos1, pos2 =') debugPrint(pos1) debugPrint(pos2)
            local sinZ = (pos2[2] - pos1[2]) / lengthAcross
            local cosZ = (pos2[1] - pos1[1]) / lengthAcross
            -- print('length, cosZ, sinZ =', lengthAcross, cosZ, sinZ)

            for p = 1, lengthAcross, 1 do
                result.models[#result.models+1] = {
                    id = wallModelId,
                    transf = transfUtilsUG.mul(
                        {
                            cosZ, sinZ, 0, 0,
                            -sinZ, cosZ, 0, 0,
                            0, 0, 1, 0,
                            pos1[1] + (p-0.5) * cosZ, pos1[2] + (p-0.5) * sinZ, pos1[3] + constants.platformRoofZ + zShift, 1
                        },
                        {
                            1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, 1, 0,
                            0, -2.5, 0, 1
                        }
                    ),
                    tag = tag
                }
            end
        -- elseif (ii > 1 and params.terminals[nTerminal].centrePlatformsFineRelative[ii-1].type == 2) then
        -- getting out of a tunnel: draw full or skip altogether
        else
            -- same as above, checking the following element
            local posTanX2_1 = transfUtils.getParallelSidewaysWithRotZ(
                cpf.posTanX2,
                cpf.width / 2 + slopedAreaWidth - deltaY
            )
            local posTanX2_2 = transfUtils.getParallelSidewaysWithRotZ(
                cpf.posTanX2,
                cpf.width / 2 + slopedAreaWidth
            )
            local lengthAcross = cpf.width + slopedAreaWidth
            local pos1 = posTanX2_1[2][1]
            local pos2 = posTanX2_2[2][1]

            result.models[#result.models+1] = {
                id = 'lollo_freestyle_train_station/icon/green.mdl',
                transf = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    pos1[1], pos1[2], pos1[3], 1
                },
                tag = tag
            }
            result.models[#result.models+1] = {
                id = 'lollo_freestyle_train_station/icon/yellow.mdl',
                transf = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    pos2[1], pos2[2], pos2[3], 1
                },
                tag = tag
            }

            -- print('pos1, pos2 =') debugPrint(pos1) debugPrint(pos2)
            local sinZ = (pos2[2] - pos1[2]) / lengthAcross
            local cosZ = (pos2[1] - pos1[1]) / lengthAcross
            -- print('length, cosZ, sinZ =', lengthAcross, cosZ, sinZ)

            for p = 1, lengthAcross, 1 do
                result.models[#result.models+1] = {
                    id = wallModelId,
                    transf = transfUtilsUG.mul(
                        {
                            cosZ, sinZ, 0, 0,
                            -sinZ, cosZ, 0, 0,
                            0, 0, 1, 0,
                            pos1[1] + (p-0.5) * cosZ, pos1[2] + (p-0.5) * sinZ, pos1[3] + constants.platformRoofZ + zShift, 1
                        },
                        {
                            -1, 0, 0, 0,
                            0, -1, 0, 0,
                            0, 0, 1, 0,
                            0, 2.5, 0, 1
                        }
                    ),
                    tag = tag
                }
            end
        -- elseif (ii < _iiMax and params.terminals[nTerminal].centrePlatformsFineRelative[ii+1].type == 2) then
        -- getting out of a tunnel: draw full or skip altogether
        end
    end,
    getMNAdjustedValue_0Or1_Cycling = function(params, slotId)
        local variant = privateFuncs.getVariant(params, slotId)
        return privateFuncs.getFromVariant_0_or_1(variant)
    end,
    getStationSignFineIndexes = function(params, nTerminal)
        local results = {}
        for ii = 3, #params.terminals[nTerminal].centrePlatformsFineRelative - 2, constants.maxPassengerWaitingAreaEdgeLength * 6 do
            results[ii] = true
        end
        return results
    end,
}
privateFuncs.edges = {
    _addTrackEdges = function(result, tag2nodes, params, t)
        result.terminateConstructionHookInfo.vehicleNodes[t] = (#result.edgeLists + params.terminals[t].trackEdgeListMidIndex) * 2 - 2
    
        logger.print('_addTrackEdges starting for terminal =', t)
        local forceCatenary = 0
        local trackElectrificationModuleKey = slotHelpers.mangleId(t, 0, constants.idBases.trackElectrificationSlotId)
        if params.modules[trackElectrificationModuleKey] ~= nil then
            if params.modules[trackElectrificationModuleKey].name == constants.trackElectrificationYesModuleFileName then
                forceCatenary = 2
            elseif params.modules[trackElectrificationModuleKey].name == constants.trackElectrificationNoModuleFileName then
                forceCatenary = 1
            end
        end
        logger.print('forceCatenary =', forceCatenary)
        local forceFast = 0
        local trackSpeedModuleKey = slotHelpers.mangleId(t, 0, constants.idBases.trackSpeedSlotId)
        if params.modules[trackSpeedModuleKey] ~= nil then
            if params.modules[trackSpeedModuleKey].name == constants.trackSpeedFastModuleFileName then
                forceFast = 2
            elseif params.modules[trackSpeedModuleKey].name == constants.trackSpeedSlowModuleFileName then
                forceFast = 1
            end
        end
        logger.print('forceFast =', forceFast)
    
        for i = 1, #params.terminals[t].trackEdgeLists do
            local tel = params.terminals[t].trackEdgeLists[i]
    
            local overriddenCatenary = tel.catenary
            if forceCatenary == 1 then overriddenCatenary = false
            elseif forceCatenary == 2 then overriddenCatenary = true
            end
    
            local overriddenTrackType = tel.trackTypeName
            if forceFast == 1 then overriddenTrackType = 'standard.lua'
            elseif forceFast == 2 then overriddenTrackType = 'high_speed.lua'
            end
    
            local newEdgeList = {
                alignTerrain = tel.type == 0 or tel.type == 2, -- only align on ground and in tunnels
                edges = transfUtils.getPosTanX2Transformed(tel.posTanX2, params.inverseMainTransf),
                edgeType = tel.edgeType,
                edgeTypeName = tel.edgeTypeName,
                -- freeNodes = {},
                params = {
                    catenary = overriddenCatenary,
                    type = overriddenTrackType,
                },
                snapNodes = {},
                tag2nodes = tag2nodes,
                type = 'TRACK'
            }
    
            if i == 1 then
                -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 0
                newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
            end
            if i == #params.terminals[t].trackEdgeLists then
                -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 1
                newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
            end
    
            -- LOLLO NOTE the edges won't snap to the neighbours
            -- unless you rebuild those neighbours, by hand or by script,
            -- and make them snap to the station own nodes.
            result.edgeLists[#result.edgeLists+1] = newEdgeList
        end
    end,
    _addPlatformEdges = function(result, tag2nodes, params, t)
        for i = 1, #params.terminals[t].platformEdgeLists do
            local pel = params.terminals[t].platformEdgeLists[i]

            local newEdgeList = {
                -- UG TODO LOLLO TODO never mind if I align the terrain or I change the track materials,
                -- the game will always draw ballast in the underpasses - bridges are less affected.
                -- The cause is, when you snap a platform-track along a track, the terrain gets levelled
                -- and painted. It wins over terrainAlignments and over groundTextures with very high prios.
                -- The only thing that works is a material with 
                -- polygon_offset = {
                --     factor = -999,
                --     forceDepthWrite = true,
                --     units = -999,
                -- },
                -- but then it shines through everything else.
                -- You can see it with a platform that snaps to a track and then stretches away from it:
                -- In the free piece, you will see the underpasses properly; however, as soon as you lay any track 
                -- alongside, the terrain will come up. If the track does not snap, the underpass will look fine instead.
                -- The easy way around it is not to draw the platform edge;
                -- this will make trouble when snapping parallel platform, which far outweighs the optical benefit
                -- of underpasses.
                -- It will also make for missing bits of bridges.

                -- You can also lay an invisible track (after making it available)
                -- and snap some other track along it: the ballastMaterial of the latter will win and extend under the invisible track,
                -- never mind how many ypu have.
                -- The game will create a foundation (lots of little parallelepipeds),
                -- paint it with the winning ballast material
                -- and extend it to all snapped tracks.
                -- Unless we find the undocumented fallback - it looks like one. There is config/ground/texture/fallback.lua,
                -- but id does nothing.

                -- The winner does not seem affected by height.
                -- Neither by the material priority.
                -- It seems to have a degree of randomness, but the sucky part is: there is a winner and it takes all.
                -- So, even if I set a transparent ballastMaterial and I managa to make it will,
                -- also the normal tracks will receive a transparent ballast - not that I could manage so far.
                alignTerrain = pel.type == 0 or pel.type == 2, -- only align on ground and in tunnels
                edges = transfUtils.getPosTanX2Transformed(pel.posTanX2, params.inverseMainTransf),
                edgeType = pel.edgeType,
                edgeTypeName = pel.edgeTypeName,
                -- freeNodes = {},
                params = {
                    -- type = pel.trackTypeName,
                    type = trackUtils.getInvisibleTwinFileName(pel.trackTypeName),
                    catenary = false --pel.catenary
                },
                snapNodes = {},
                tag2nodes = tag2nodes,
                type = 'TRACK'
            }

            if i == 1 then
                -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 0
                newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 0
            end
            if i == #params.terminals[t].platformEdgeLists then
                -- newEdgeList.freeNodes[#newEdgeList.freeNodes+1] = 1
                newEdgeList.snapNodes[#newEdgeList.snapNodes+1] = 1
            end

            result.edgeLists[#result.edgeLists+1] = newEdgeList
        end
    end,
    _getNNodesInTerminalsSoFar = function(params, t)
        local result = 0
        for tt = 1, t - 1 do
            if params.terminals[tt] ~= nil then
                if params.terminals[tt].platformEdgeLists ~= nil then
                    result = result + #params.terminals[tt].platformEdgeLists * 2
                end
                if params.terminals[tt].trackEdgeLists ~= nil then
                    result = result + #params.terminals[tt].trackEdgeLists * 2
                end
            end
        end
        return result
    end,
}
privateFuncs.flatAreas = {
    addCargoLaneToStreet = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]

        local position123 = nil
        if cpl.width <= 5 then
            position123 = params.terminals[nTerminal].cargoWaitingAreasRelative[1][nTrackEdge].posTanX2[1][1]
        elseif cpl.width <= 10 then
            position123 = params.terminals[nTerminal].cargoWaitingAreasRelative[2][nTrackEdge].posTanX2[1][1]
        elseif cpl.width <= 15 then
            position123 = params.terminals[nTerminal].cargoWaitingAreasRelative[3][nTrackEdge].posTanX2[1][1]
        else
            position123 = params.terminals[nTerminal].cargoWaitingAreasRelative[4][nTrackEdge].posTanX2[1][1]
        end
        local _lane2AreaTransf = transfUtils.get1MLaneTransf(
            transfUtils.getPositionRaisedBy(position123, result.laneZs[nTerminal]),
            transfUtils.transf2Position(slotTransf)
        )

        result.models[#result.models+1] = {
            id = constants.passengerLaneModelId,
            slotId = slotId,
            transf = _lane2AreaTransf,
            tag = tag
        }

    end,
    addExitPole = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)
        local isCargoTerminal = params.terminals[nTerminal].isCargo
        local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, nTrackEdge)
        local perronModelId = 'lollo_freestyle_train_station/asset/era_c_perron_number.mdl'
        if (isCargoTerminal) then
            perronModelId = 'lollo_freestyle_train_station/asset/cargo_perron_number.mdl'
        elseif eraPrefix == constants.eras.era_b.prefix then
            perronModelId = 'lollo_freestyle_train_station/asset/era_b_perron_number_plain.mdl'
        elseif eraPrefix == constants.eras.era_a.prefix then
            perronModelId = 'lollo_freestyle_train_station/asset/era_a_perron_number.mdl'
        end
        result.models[#result.models + 1] = {
            id = perronModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(slotTransf, {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  -0.5, 0.5, 0, 1}),
            tag = tag
        }
        -- the model index must be in base 0 !
        result.labelText[#result.models - 1] = { tostring(nTerminal), "↑" }
    end,
    addPassengerLaneToStreet = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)
        local crossConnectorPosTanX2 = params.terminals[nTerminal].crossConnectorsRelative[nTrackEdge].posTanX2
        local lane2AreaTransf = transfUtils.get1MLaneTransf(
            transfUtils.getPositionRaisedBy(crossConnectorPosTanX2[2][1], result.laneZs[nTerminal]),
            transfUtils.transf2Position(slotTransf)
        )
        result.models[#result.models+1] = {
            id = constants.passengerLaneModelId,
            slotId = slotId,
            transf = lane2AreaTransf,
            tag = tag
        }
    end,
    getMNAdjustedTransf = function(params, slotId, slotTransf, isFlush)
        local variant = privateFuncs.getVariant(params, slotId)
        local deltaZ = privateFuncs.getFromVariant_FlatAreaHeight(variant, isFlush)
        return transfUtils.getTransfZShiftedBy(slotTransf, deltaZ)
    end,
}
privateFuncs.openStairs = {
    getExitModelTransf = function(slotTransf, slotId, params)
        local variant = privateFuncs.getVariant(params, slotId)
        local tilt = privateFuncs.getFromVariant_BridgeTilt(variant)
        return transfUtilsUG.mul(slotTransf, transfUtilsUG.rotY(tilt))
    end,
    getPedestrianBridgeModelId = function(length, eraPrefix, isWithEdge)
        -- eraPrefix is a string like 'era_a_'
        local lengthStr = '4'
        if length < 3 then lengthStr = '2'
        elseif length < 6 then lengthStr = '4'
        elseif length < 12 then lengthStr = '8'
        elseif length < 24 then lengthStr = '16'
        elseif length < 48 then lengthStr = '32'
        else lengthStr = '64'
        end

        local newEraPrefix = eraPrefix
        if newEraPrefix ~= constants.eras.era_a.prefix and newEraPrefix ~= constants.eras.era_b.prefix and newEraPrefix ~= constants.eras.era_c.prefix then
            newEraPrefix = constants.eras.era_c.prefix
        end

        if isWithEdge then
            return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_with_edge_' .. lengthStr .. 'm.mdl'
        else
            return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_' .. lengthStr .. 'm.mdl'
        end
    end,
}
privateFuncs.slopedAreas = {
    addSlopedCargoAreaDeco = function(result, tag, slotId, params, nTerminal, nTrackEdge, eraPrefix, areaWidth, nWaitingAreas, verticalTransfAtPlatformCentre)
        if areaWidth < 5 then return end

        local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)
        if isEndFiller then return end

        local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
        local platformWidth = cpl.width

        local xShift1 = nWaitingAreas <= 4 and -4.5 or -4.5
        local xShift2 = nWaitingAreas <= 4 and 0.7 or 3.7
        local yShift = (-platformWidth -areaWidth) / 2
        if not(isTrackOnPlatformLeft) then yShift = -yShift end

        local roofModelId = nil
        if eraPrefix == constants.eras.era_a.prefix then
            roofModelId = 'lollo_freestyle_train_station/asset/cargo_roof_grid_dark_4x4.mdl'
        else
            roofModelId = 'lollo_freestyle_train_station/asset/cargo_roof_grid_4x4.mdl'
        end

        result.models[#result.models + 1] = {
            id = roofModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(verticalTransfAtPlatformCentre, { 0, 1, 0, 0,  -1, 0, 0, 0,  0, 0, 1, 0,  xShift1, yShift, result.laneZs[nTerminal] + constants.platformSideBitsZ, 1 }),
            tag = tag
        }
        result.models[#result.models + 1] = {
            id = roofModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(verticalTransfAtPlatformCentre, { 0, -1, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0,  xShift2, yShift, result.laneZs[nTerminal] + constants.platformSideBitsZ, 1 }),
            tag = tag
        }
    end,
    addSlopedPassengerAreaDeco = function(result, tag, slotId, params, nTerminal, nTrackEdge, eraPrefix, areaWidth, nWaitingAreas, verticalTransfAtPlatformCentre)
        if areaWidth < 5 then return end

        local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)
        if isEndFiller then return end

        local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
        local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
        local platformWidth = cpl.width

        local xShift = nWaitingAreas <= 4 and -2.0 or 0.0
        local yShift1 = -platformWidth / 2 - 2.8
        local yShift2 = -platformWidth / 2 - 1.0
        local yShift3 = -platformWidth / 2 - 2.1
        if not(isTrackOnPlatformLeft) then yShift1 = -yShift1 yShift2 = -yShift2 yShift3 = -yShift3 end

        local chairsModelId = nil
        local binModelId = nil
        local arrivalsModelId = nil
        if eraPrefix == constants.eras.era_a.prefix then
            chairsModelId = 'lollo_freestyle_train_station/asset/era_a_four_chairs.mdl'
            binModelId = 'station/rail/asset/era_a_trashcan.mdl'
            arrivalsModelId = 'lollo_freestyle_train_station/asset/era_a_arrivals_departures_column.mdl'
        elseif eraPrefix == constants.eras.era_b.prefix then
            chairsModelId = 'lollo_freestyle_train_station/asset/era_b_four_chairs.mdl'
            binModelId = 'station/rail/asset/era_b_trashcan.mdl'
            arrivalsModelId = 'lollo_freestyle_train_station/asset/era_b_arrivals_departures_column.mdl'
        else
            chairsModelId = 'lollo_freestyle_train_station/asset/era_c_four_chairs.mdl'
            binModelId = 'station/rail/asset/era_c_trashcan.mdl'
            arrivalsModelId = 'lollo_freestyle_train_station/asset/tabellone_standing.mdl'
        end

        result.models[#result.models + 1] = {
            id = chairsModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(verticalTransfAtPlatformCentre, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  xShift + 1.6, yShift1, result.laneZs[nTerminal] + constants.platformSideBitsZ, 1 }),
            tag = tag
        }
        result.models[#result.models + 1] = {
            id = binModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(verticalTransfAtPlatformCentre, { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  xShift + 1.6, yShift2, result.laneZs[nTerminal] + constants.platformSideBitsZ, 1 }),
            tag = tag
        }
        result.models[#result.models + 1] = {
            id = arrivalsModelId,
            slotId = slotId,
            transf = transfUtilsUG.mul(verticalTransfAtPlatformCentre, { 0, 1, 0, 0,  -1, 0, 0, 0,  0, 0, 1, 0,  xShift + 6.2, yShift3, result.laneZs[nTerminal] + constants.platformSideBitsZ, 1 }),
            tag = tag
        }
    end,
    _getSlopedAreaInnerDegreeOLD = function(params, nTerminal, nTrackEdge)
        local centrePlatforms = params.terminals[nTerminal].centrePlatformsRelative
    
        local x1 = 0
        local y1 = 0
        local xM = 0
        local yM = 0
        local x2 = 0
        local y2 = 0
        if centrePlatforms[nTrackEdge - 1] ~= nil and centrePlatforms[nTrackEdge] ~= nil and centrePlatforms[nTrackEdge + 1] ~= nil then
            x1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][1]
            y1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][2]
            x2 = centrePlatforms[nTrackEdge + 1].posTanX2[1][1][1]
            y2 = centrePlatforms[nTrackEdge + 1].posTanX2[1][1][2]
            xM = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
            yM = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
        elseif centrePlatforms[nTrackEdge - 1] ~= nil and centrePlatforms[nTrackEdge] ~= nil then
            x1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][1]
            y1 = centrePlatforms[nTrackEdge - 1].posTanX2[1][1][2]
            x2 = centrePlatforms[nTrackEdge].posTanX2[2][1][1]
            y2 = centrePlatforms[nTrackEdge].posTanX2[2][1][2]
            xM = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
            yM = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
        elseif centrePlatforms[nTrackEdge] ~= nil and centrePlatforms[nTrackEdge + 1] ~= nil then
            x1 = centrePlatforms[nTrackEdge].posTanX2[1][1][1]
            y1 = centrePlatforms[nTrackEdge].posTanX2[1][1][2]
            x2 = centrePlatforms[nTrackEdge + 1].posTanX2[2][1][1]
            y2 = centrePlatforms[nTrackEdge + 1].posTanX2[2][1][2]
            xM = centrePlatforms[nTrackEdge].posTanX2[2][1][1]
            yM = centrePlatforms[nTrackEdge].posTanX2[2][1][2]
        else
            logger.warn('cannot get inner degree')
            return privateConstants.slopedAreasOLD.innerDegrees.neutral
        end
    
        local segmentHunch = transfUtils.getDistanceBetweenPointAndStraight(
            {x1, y1, 0},
            {x2, y2, 0},
            {xM, yM, 0}
        )
        -- print('segmentHunch =', segmentHunch)
    
        -- local segmentLength = transfUtils.getPositionsDistance(
        --     centrePlatforms[nTrackEdge - 1].posTanX2[1][1],
        --     centrePlatforms[nTrackEdge + 1].posTanX2[1][1]
        -- )
        -- print('segmentLength =', segmentLength)
        -- if segmentHunch / segmentLength < privateConstants.slopedAreas.hunchLengthRatioToClaimBend then return privateConstants.slopedAreas.innerDegrees.neutral end
        if segmentHunch < privateConstants.slopedAreasOLD.hunchToClaimBend then return privateConstants.slopedAreasOLD.innerDegrees.neutral end
    
        -- a + bx = y
        -- => a + b * x1 = y1
        -- => a + b * x2 = y2
        -- => b * (x1 - x2) = y1 - y2
        -- => b = (y1 - y2) / (x1 - x2)
        -- OR division by zero
        -- => a = y1 - b * x1
        -- => a = y1 - (y1 - y2) / (x1 - x2) * x1
        -- a + b * xM > yM <= this is what we want to know
        -- => y1 - (y1 - y2) / (x1 - x2) * x1 + (y1 - y2) / (x1 - x2) * xM > yM
        -- => y1 * (x1 - x2) - (y1 - y2) * x1 + (y1 - y2) * xM > yM * (x1 - x2)
        -- => (y1 - yM) * (x1 - x2) + (y1 - y2) * (xM - x1) > 0
    
        local innerSign = transfUtils.sgn((y1 - yM) * (x1 - x2) + (y1 - y2) * (xM - x1))
    
        if not(params.terminals[nTerminal].isTrackOnPlatformLeft) then innerSign = -innerSign end
        -- print('terminal', nTerminal, 'innerSign =', innerSign)
        return innerSign
    end,
    _getSlopedAreaTweakFactorsOLD = function(innerDegree, areaWidth)
        local waitingAreaScaleFactor = areaWidth * 0.8
    
        -- LOLLO NOTE sloped areas are parallelepipeds that extend the parallelepipeds that make up the platform sideways.
        -- I don't know of any transformation to twist or deform a model, so either I make an arsenal of meshes (no!) or I adjust things.
        -- 1) If I am outside a bend, I must stretch the sloped areas so there are no holes between them.
        -- Inside a bend, I haven't got this problem but I cannot shrink them, either, lest I get holes.
        -- 2) As I approach the centre of a bend, the slope should increase, and it should decrease as I move outwards.
        -- To visualise this, imagine building a helter skelter with horizontal planks, or a tight staircase: the centre will be super steep.
        -- Since there is no transf for this, I tweak the angle around the Y axis.
    
        -- These tricks work to a certain extent, but since I cannot skew or twist my models,
        -- I work out a new cleaner series of segments to follow, instead of extending the platform sideways.
        -- It is cleaner (the Y angle is optimised by construction) but slow, so we run the calculations in advance in the big script.
        -- And we still need to tweak it a little.
    
        -- Using multiple thin parallel extensions is slow and brings nothing at all.
    
        -- The easiest is: leave the narrower slopes since they don't cause much grief, and bridges need them,
        -- and use the terrain for the wider ones. Even the smaller sloped areas need quite a bit of stretch, but they are less sensiitive to the angle problem.
        -- However, the terrain will never look as good as a dedicated model.
        -- local angleYFactor = 1
        local xScaleFactor = 1
        -- local waitingAreaPeriod = 5
        -- outside a bend
        if innerDegree < 0 then
            -- waitingAreaPeriod = 4
            if areaWidth <= 5 then
                xScaleFactor = 1.20
                -- angleYFactor = 1.0625
            elseif areaWidth <= 10 then
                xScaleFactor = 1.30
                -- angleYFactor = 1.10
            elseif areaWidth <= 20 then
                xScaleFactor = 1.40
                -- angleYFactor = 1.20
            end
        -- inside a bend
        elseif innerDegree > 0 then
            -- waitingAreaPeriod = 6
            xScaleFactor = 0.95
            -- if areaWidth <= 5 then
            --     angleYFactor = 0.9
            -- elseif areaWidth <= 10 then
            --     angleYFactor = 0.825
            -- elseif areaWidth <= 20 then
            --     angleYFactor = 0.75
            -- end
        -- more or less straight
        else
            if areaWidth <= 5 then
                xScaleFactor = 1.05
            elseif areaWidth <= 10 then
                xScaleFactor = 1.15
            elseif areaWidth <= 20 then
                xScaleFactor = 1.25
            end
        end
        -- print('xScaleFactor =', xScaleFactor)
        -- print('angleYFactor =', angleYFactor)
    
        return waitingAreaScaleFactor, xScaleFactor
    end,
    isSlopedAreaAllowed = function(cpf, areaWidth)
        return cpf.type == 0 or (cpf.type == 1 and areaWidth <= 2.5)
    end,
    _doTerrain4SlopedArea = function(result, params, nTerminal, nTrackEdge, isEndFiller, areaWidth, groundFacesFillKey)
        -- print('_doTerrain4SlopedArea got groundFacesFillKey =', groundFacesFillKey)
        local terrainCoordinates = {}

        local i1 = isEndFiller and nTrackEdge or (nTrackEdge - 1)
        local iN = nTrackEdge + 1
        local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft

        local cpfs = params.terminals[nTerminal].centrePlatformsFineRelative
        for ii = 1, #cpfs do
            local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
            local leadingIndex = cpf.leadingIndex
            if leadingIndex > iN then break end
            if cpf.type == 0 then -- only on ground
                if leadingIndex >= i1 then
                    local platformWidth = cpf.width
                    local outerAreaEdgePosTanX2 = transfUtils.getParallelSidewaysWithRotZ(
                        cpf.posTanX2,
                        (isTrackOnPlatformLeft and (-areaWidth -platformWidth * 0.5) or (areaWidth + platformWidth * 0.5))
                    )
                    local pos1Inner = cpf.posTanX2[1][1]
                    local pos2Inner = cpf.posTanX2[2][1]
                    local pos2Outer = outerAreaEdgePosTanX2[2][1]
                    local pos1Outer = outerAreaEdgePosTanX2[1][1]
                    terrainCoordinates[#terrainCoordinates+1] = {
                        pos1Inner,
                        pos2Inner,
                        pos2Outer,
                        pos1Outer,
                    }
                end
            end
        end
        -- print('terrainCoordinates =') debugPrint(terrainCoordinates)

        local faces = {}
        for tc = 1, #terrainCoordinates do
            local face = { }
            for i = 1, 4 do
                face[i] = {
                    terrainCoordinates[tc][i][1],
                    terrainCoordinates[tc][i][2],
                    terrainCoordinates[tc][i][3] + result.laneZs[nTerminal] * 0.5 + constants.platformSideBitsZ,
                    1
                }
            end
            faces[#faces+1] = face
            if groundFacesFillKey ~= nil then
                result.groundFaces[#result.groundFaces + 1] = {
                    face = face, -- Z is ignored here
                    loop = true,
                    modes = {
                        {
                            type = 'FILL',
                            key = groundFacesFillKey,
                        },
                        {
                            type = 'STROKE_OUTER',
                            key = groundFacesFillKey
                        }
                    }
                }
            end
        end
        if #faces > 1 then
            result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = {
                faces = faces, -- Z is accounted here
                optional = true,
                slopeHigh = constants.slopeHigh,
                slopeLow = constants.slopeLow,
                type = 'EQUAL', -- GREATER, LESS
            }
        end
    end,
}
privateFuncs.subways = {
    doTerrain4ClosedSubways = function(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        local _groundFacesFillKey = constants[constants.eras.era_c.prefix .. 'groundFacesFillKey']
        -- local groundFace = { -- the ground faces ignore z, the alignment lists don't
        --     {0.0, -0.95, 0, 1},
        --     {0.0, 0.95, 0, 1},
        --     {4.5, 0.95, 0, 1},
        --     {4.5, -0.95, 0, 1},
        -- }
        -- local terrainFace = { -- the ground faces ignore z, the alignment lists don't
        --     {-2.2, -4.15, constants.platformSideBitsZ, 1},
        --     {-2.2, 4.15, constants.platformSideBitsZ, 1},
        --     {4.7, 4.15, constants.platformSideBitsZ, 1},
        --     {4.7, -4.15, constants.platformSideBitsZ, 1},
        -- }
        if type(slotTransf) == 'table' then
            -- modulesutil.TransformFaces(slotTransf, groundFace)
            modulesutil.TransformFaces(slotTransf, terrainFace)
        end

        table.insert(
            result.groundFaces,
            {
                -- face = groundFace,
                face = terrainFace,
                loop = true,
                modes = {
                    {
                        key = _groundFacesFillKey,
                        type = 'FILL',
                    },
                    -- {
                    --     key = groundFacesStrokeOuterKey,
                    --     type = 'STROKE_OUTER',
                    -- }
                }
            }
        )
        table.insert(
            result.terrainAlignmentLists,
            {
                faces =  { terrainFace },
                optional = true,
                slopeHigh = constants.slopeHigh,
                slopeLow = constants.slopeLow,
                type = 'EQUAL',
            }
        )
    end,
}

return {
    eras = constants.eras,
    getEraPrefix = function(params, nTerminal, nTrackEdge)
        return privateFuncs.getEraPrefix(params, nTerminal, nTrackEdge)
    end,
    getGroundFace = function(face, key)
        return {
            face = face, -- LOLLO NOTE Z is ignored here
            loop = true,
            modes = {
                {
                    type = 'FILL',
                    key = key
                }
            }
        }
    end,
    getIsEndFillerEvery3 = function(nTrackEdge)
        return privateFuncs.getIsEndFillerEvery3(nTrackEdge)
    end,
    getTerrainAlignmentList = function(face, raiseBy, alignmentType, slopeHigh, slopeLow)
        if type(raiseBy) ~= 'number' then raiseBy = 0 end
        if stringUtils.isNullOrEmptyString(alignmentType) then alignmentType = 'EQUAL' end -- GREATER, LESS
        if type(slopeHigh) ~= 'number' then slopeHigh = constants.slopeHigh end
        if type(slopeLow) ~= 'number' then slopeLow = constants.slopeLow end
        -- With “EQUAL” the terrain is aligned exactly to the specified faces,
        -- with “LESS” only higher areas are taken down,
        -- with “GREATER” areas below the faces will be filled up.
        -- local raiseBy = 0 -- 0.28 -- a lil bit less than 0.3 to avoid bits of construction being covered by earth
        local raisedFace = {}
        for i = 1, #face do
            raisedFace[i] = face[i]
            raisedFace[i][3] = raisedFace[i][3] + raiseBy
        end
        -- print('LOLLO raisedFaces =')
        -- debugPrint(raisedFace)
        return {
            faces = {raisedFace},
            optional = true,
            slopeHigh = slopeHigh,
            slopeLow = slopeLow,
            type = alignmentType,
        }
    end,
    getTerminalDecoTransf = function(posTanX2)
        -- print('getTerminalDecoTransf starting, posTanX2 =') debugPrint(posTanX2)
        local pos1 = posTanX2[1][1]
        local pos2 = posTanX2[2][1]
        local newTransf = transfUtilsUG.rotZTransl(
            math.atan2(pos2[2] - pos1[2], pos2[1] - pos1[1]),
            {
                x = pos1[1],
                y = pos1[2],
                z = pos1[3],
            }
        )
    
        -- print('newTransf =') debugPrint(newTransf)
        return newTransf
    end,
    getPlatformObjectTransf_AlwaysVertical = function(posTanX2)
        return privateFuncs.getPlatformObjectTransf_AlwaysVertical(posTanX2)
    end,
    getPlatformObjectTransf_WithYRotation = function(posTanX2) --, angleYFactor)
        return privateFuncs.getPlatformObjectTransf_WithYRotation(posTanX2)
    end,
    cargoShelves = {
        doCargoShelf = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge,
            bracket5ModelId, bracket10ModelId, bracket20ModelId,
            legs5ModelId, legs10ModelId, legs20ModelId)
            local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
            local transfXZoom = isTrackOnPlatformLeft and -1 or 1
            local transfYZoom = isTrackOnPlatformLeft and -1 or 1
            local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)

            local _i1 = isEndFiller and nTrackEdge or (nTrackEdge - 1)
            local _iMax = isEndFiller and nTrackEdge or (nTrackEdge + 1)
            for ii = 1, #params.terminals[nTerminal].centrePlatformsFineRelative, privateConstants.cargoShelves.bracketStep do
                local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
                local leadingIndex = cpf.leadingIndex
                if leadingIndex > _iMax then break end
                if leadingIndex >= _i1 then
                    if cpf.type == 0 then -- ground
                        local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, leadingIndex)
                        local platformWidth = cpf.width
                        local bracketModelId = bracket5ModelId
                        if platformWidth > 10 then bracketModelId = bracket20ModelId
                        elseif platformWidth > 5 then bracketModelId = bracket10ModelId
                        end
                        result.models[#result.models+1] = {
                            id = bracketModelId,
                            transf = transfUtilsUG.mul(
                                privateFuncs.getPlatformObjectTransf_WithYRotation(cpf.posTanX2),
                                { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformRoofZ, 1 }
                            ),
                            tag = tag
                        }
                        -- we shift it by 2 so it does not cover light and speakers
                        if math.fmod(ii + 2, privateConstants.cargoShelves.pillarPeriod) == 0 then
                            local legsModelId = legs5ModelId
                            local waitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area_on_shelf_5m.mdl'
                            if platformWidth > 10 then
                                legsModelId = legs20ModelId
                                waitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area_on_shelf_20m.mdl'
                            elseif platformWidth > 5 then
                                legsModelId = legs10ModelId
                                waitingAreaModelId = 'lollo_freestyle_train_station/cargo_waiting_area_on_shelf_10m.mdl'
                            end

                            local myTransf = transfUtilsUG.mul(
                                privateFuncs.getPlatformObjectTransf_AlwaysVertical(cpf.posTanX2),
                                { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformRoofZ, 1 }
                            )
                            result.models[#result.models+1] = {
                                id = legsModelId,
                                transf = myTransf,
                                tag = tag,
                            }
                            result.models[#result.models+1] = {
                                id = waitingAreaModelId,
                                transf = myTransf,
                                tag = slotHelpers.mangleModelTag(nTerminal, true),
                            }
                        end
                    end
                end
            end
        end,
    },
    deco = {
        getFromVariant_0_or_1 = function(variant)
            return privateFuncs.getFromVariant_0_or_1(variant)
        end,
        getPreviewIcon = function(params)
			local variant = (params ~= nil and type(params.variant) == 'number') and params.variant or 0
			local zeroOrOne = privateFuncs.getFromVariant_0_or_1(variant)
            local arrowModelId = 'lollo_freestyle_train_station/icon/slant_wall.mdl'
            local arrowModelTransf = {0.5, 0, 0, 0,  0, 0.5, 0, 0,  0, 0, 0.5, 0,  10, -2, 10, 1}
            if zeroOrOne > 0 then
                arrowModelId = 'lollo_freestyle_train_station/icon/perpendicular_wall.mdl'
            end
            return {
                id = arrowModelId,
                transf = arrowModelTransf,
            }
        end,
        getStationSignFineIndexes = function(params, nTerminal)
            return privateFuncs.deco.getStationSignFineIndexes(params, nTerminal)
        end,
        doPlatformRoof = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge,
            ceiling2_5ModelId, ceiling5ModelId, pillar2_5ModelId, pillar5ModelId, alternativeCeiling2_5ModelId, alternativeCeiling5ModelId, isTunnelOk)
            local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
            local transfXZoom = isTrackOnPlatformLeft and -1 or 1
            local transfYZoom = isTrackOnPlatformLeft and -1 or 1
            local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)

            local _barredNumberSignIIs = privateFuncs.deco.getStationSignFineIndexes(params, nTerminal)

            local _i1 = isEndFiller and nTrackEdge or (nTrackEdge - 1)
            local _iMax = isEndFiller and nTrackEdge or (nTrackEdge + 1)
            local isFreeFromOpenStairsLeft = {}
            local isFreeFromOpenStairsRight = {}
            for i = _i1, _iMax, 1 do
                isFreeFromOpenStairsLeft[i] = not(params.modules[result.mangleId(nTerminal, i+1, constants.idBases.openStairsUpLeftSlotId)])
                isFreeFromOpenStairsRight[i] = (i < 2 or not(params.modules[result.mangleId(nTerminal, i-1, constants.idBases.openStairsUpRightSlotId)]))
            end
            for ii = 1, #params.terminals[nTerminal].centrePlatformsFineRelative, privateConstants.deco.ceilingStep do
                local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
                local leadingIndex = cpf.leadingIndex
                if leadingIndex > _iMax then break end
                if leadingIndex >= _i1 then
                    if isTunnelOk or cpf.type ~= 2 then -- ground or bridge
                        local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, leadingIndex)
                        local platformWidth = cpf.width
                        local isFreeFromOpenStairsAndTunnels = isFreeFromOpenStairsLeft[leadingIndex] and isFreeFromOpenStairsRight[leadingIndex] and cpf.type ~= 2
                        local modelId = isFreeFromOpenStairsAndTunnels
                        and (platformWidth < 5 and ceiling2_5ModelId or ceiling5ModelId)
                        or (platformWidth < 5 and alternativeCeiling2_5ModelId or alternativeCeiling5ModelId)
                        if modelId ~= nil then
                            result.models[#result.models+1] = {
                                id = modelId,
                                transf = transfUtilsUG.mul(
                                    privateFuncs.getPlatformObjectTransf_WithYRotation(cpf.posTanX2),
                                    { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformRoofZ, 1 }
                                ),
                                tag = tag
                            }

                            if cpf.type ~= 2 and isFreeFromOpenStairsAndTunnels and math.fmod(ii, privateConstants.deco.pillarPeriod) == 0 then
                                local myTransf = transfUtilsUG.mul(
                                    privateFuncs.getPlatformObjectTransf_AlwaysVertical(cpf.posTanX2),
                                    { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformRoofZ, 1 }
                                )
                                result.models[#result.models+1] = {
                                    id = platformWidth < 5 and pillar2_5ModelId or pillar5ModelId,
                                    transf = myTransf,
                                    tag = tag,
                                }
                                -- prevent overlapping with station name signs
                                if not(_barredNumberSignIIs[ii])
                                and not(_barredNumberSignIIs[ii+1])
                                and (ii == 1 or not(_barredNumberSignIIs[ii-1]))
                                then
                                    if math.fmod(ii, privateConstants.deco.numberSignPeriod) == 0 then
                                        -- local yShift = isTrackOnPlatformLeft and platformWidth * 0.5 - 0.05 or -platformWidth * 0.5 + 0.05
                                        local yShift = -platformWidth * 0.5 + 0.20
                                        local perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_c_perron_number_hanging.mdl'
                                        if eraPrefix == constants.eras.era_a.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_a_perron_number_hanging.mdl'
                                        elseif eraPrefix == constants.eras.era_b.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_b_perron_number_hanging_plain.mdl'
                                        end
                                        result.models[#result.models + 1] = {
                                            id = perronNumberModelId,
                                            slotId = slotId,
                                            transf = transfUtilsUG.mul(
                                                myTransf,
                                                { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, yShift, 4.83, 1 }
                                            ),
                                            tag = tag
                                        }
                                        -- the model index must be in base 0 !
                                        result.labelText[#result.models - 1] = { tostring(nTerminal), tostring(nTerminal)}
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end,
        doPlatformWall = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge,
            wall_5m_ModelId,
            wall_low_5m_ModelId,
            pillar2_5ModelId, pillar5ModelId,
            isTunnelOk
        )
            local isSkipPillars = params.terminals[nTerminal].isCargo or pillar2_5ModelId == nil or pillar5ModelId == nil
            local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
            local transfXZoom = isTrackOnPlatformLeft and -1 or 1
            local transfYZoom = isTrackOnPlatformLeft and -1 or 1
            local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)

            local _wallTransfFunc = privateFuncs.deco.getMNAdjustedValue_0Or1_Cycling(params, slotId) == 0
                and privateFuncs.getPlatformObjectTransf_WithYRotation
                or privateFuncs.getPlatformObjectTransf_AlwaysVertical

            local _barredNumberSignIIs = privateFuncs.deco.getStationSignFineIndexes(params, nTerminal)

            local _i1 = isEndFiller and nTrackEdge or (nTrackEdge - 1)
            local _iMax = isEndFiller and nTrackEdge or (nTrackEdge + 1)

            local isFreeFromOpenStairsLeft = {}
            local isFreeFromOpenStairsRight = {}
            for i = _i1, _iMax, 1 do
                isFreeFromOpenStairsLeft[i] = not(params.modules[result.mangleId(nTerminal, i+1, constants.idBases.openStairsUpLeftSlotId)])
                isFreeFromOpenStairsRight[i] = (i < 2 or not(params.modules[result.mangleId(nTerminal, i-1, constants.idBases.openStairsUpRightSlotId)]))
            end

            local isFreeFromRoof = not(params.modules[result.mangleId(nTerminal, nTrackEdge, constants.idBases.platformRoofSlotId)])

            -- flat areas and deco are shifted by this amount, and it makes sense this way, so we must account for it
            local _deco2FlatAreaShiftInt = math.floor(constants.maxPassengerWaitingAreaEdgeLength / 2)
            local isFreeFromFlatAreas = {}
            for i = _i1, _iMax + 1, 1 do -- look ahead one more bit because of the shift
                isFreeFromFlatAreas[i] = not(result.getOccupiedInfo4FlatAreas(nTerminal, i))
            end
            -- print('*** isFreeFromFlatAreas =') debugPrint(isFreeFromFlatAreas)
            local _getWidthAbove_5m_BarePlatformWidth = function(cpf)
                local slopedAreaWidth = result.getOccupiedInfo4SlopedAreas(nTerminal, cpf.leadingIndex).width
                if not(privateFuncs.slopedAreas.isSlopedAreaAllowed(cpf, slopedAreaWidth)) then slopedAreaWidth = 0 end
                return (cpf.width - 5) * 0.5 + slopedAreaWidth, slopedAreaWidth -- slotTransf is centred at half platform width + full sloped area width
            end
            local _iiMax = #params.terminals[nTerminal].centrePlatformsFineRelative
            for ii = 1, _iiMax, privateConstants.deco.ceilingStep do
                local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
                local leadingIndex = cpf.leadingIndex
                if leadingIndex > _iMax then break end
                if leadingIndex >= _i1 then
                    if isTunnelOk or cpf.type ~= 2 then -- ground or bridge, tunnel only if allowed
                        local cpfAheadByDeco2FlatAreaShift = params.terminals[nTerminal].centrePlatformsFineRelative[ii + _deco2FlatAreaShiftInt]
                        -- no stations in this fine segment
                        if not(cpfAheadByDeco2FlatAreaShift) or isFreeFromFlatAreas[cpfAheadByDeco2FlatAreaShift.leadingIndex] then
                            local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, leadingIndex)
                            local widthAboveMinimum, slopedAreaWidth = _getWidthAbove_5m_BarePlatformWidth(cpf)
                            local basePosTanX2, xScaleFactor, zShift = cpf.posTanX2, 1, 0
                            if widthAboveMinimum ~= 0 then
                                local xRatio, yRatio = 1, 1
                                basePosTanX2, xRatio, yRatio = transfUtils.getParallelSidewaysWithRotZ(
                                    cpf.posTanX2,
                                    (isTrackOnPlatformLeft and -widthAboveMinimum or widthAboveMinimum)
                                )
                                xScaleFactor = math.max(xRatio * yRatio, 1.01) -- this is a bit crude but it's cheap
                                -- xScaleFactor = xRatio * yRatio * 1.01
                                -- xScaleFactor = math.max(xRatio, yRatio) * 1.02
                                -- print('xRatio, yRatio =', xRatio, yRatio)
                                -- xScaleFactor = xRatio * 1.05
                            end
                            if slopedAreaWidth > 0 then
                                zShift = constants.platformSideBitsZ
                            end
                            local wallModelId = cpf.type == 2 and wall_5m_ModelId or wall_low_5m_ModelId
                            result.models[#result.models+1] = {
                                id = wallModelId,
                                transf = transfUtilsUG.mul(
                                    _wallTransfFunc(basePosTanX2),
                                    {
                                        transfXZoom * xScaleFactor, 0, 0, 0,
                                        0, transfYZoom, 0, 0,
                                        0, 0, 1, 0,
                                        0, 0, constants.platformRoofZ + zShift, 1
                                    }
                                ),
                                tag = tag
                            }

                            -- add pillars
                            if cpf.type ~= 2
                            and not(isSkipPillars)
                            and isFreeFromOpenStairsLeft[leadingIndex] and isFreeFromOpenStairsRight[leadingIndex]
                            and math.fmod(ii, privateConstants.deco.numberSignPeriod) == 0
                            -- no platform numbers if there is a roof
                            and isFreeFromRoof
                            -- prevent overlapping with station name signs
                            and not(_barredNumberSignIIs[ii])
                            and not(_barredNumberSignIIs[ii+1])
                            and (ii == 1 or not(_barredNumberSignIIs[ii-1]))
                            then
                                local yShift4Pillar = isTrackOnPlatformLeft and 0.1 or -0.1
                                local myTransf = transfUtilsUG.mul(
                                    privateFuncs.getPlatformObjectTransf_AlwaysVertical(basePosTanX2),
                                    { transfXZoom, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, yShift4Pillar, constants.platformRoofZ + zShift, 1 }
                                )
                                result.models[#result.models+1] = {
                                    id = cpf.width < 5 and pillar2_5ModelId or pillar5ModelId,
                                    transf = myTransf,
                                    tag = tag,
                                }

                                local yShift4PerronNumber = -cpf.width * 0.5 + 0.20
                                local perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_c_perron_number_hanging.mdl'
                                if eraPrefix == constants.eras.era_a.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_a_perron_number_hanging.mdl'
                                elseif eraPrefix == constants.eras.era_b.prefix then perronNumberModelId = 'lollo_freestyle_train_station/roofs/era_b_perron_number_hanging_plain.mdl'
                                end
                                result.models[#result.models + 1] = {
                                    id = perronNumberModelId,
                                    slotId = slotId,
                                    transf = transfUtilsUG.mul(
                                        myTransf,
                                        { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, yShift4PerronNumber, 4.83 + zShift, 1 }
                                    ),
                                    tag = tag
                                }
                                -- the model index must be in base 0 !
                                result.labelText[#result.models - 1] = { tostring(nTerminal), tostring(nTerminal)}
                            end

                            -- add walls across
                            if cpf.type ~= 2 then
                                local cpfM1 = ii ~= 1 and params.terminals[nTerminal].centrePlatformsFineRelative[ii-1] or nil
                                local cpfP1 = ii ~= _iiMax and params.terminals[nTerminal].centrePlatformsFineRelative[ii+1] or nil
                                if ii == 1 then
                                    privateFuncs.deco.addWallsAcross(cpf, true, slopedAreaWidth, result, tag, wallModelId, zShift, slopedAreaWidth + cpf.width)
                                elseif leadingIndex ~= cpfM1.leadingIndex then
                                    local deltaY = cpf.width + slopedAreaWidth - cpfM1.width - result.getOccupiedInfo4SlopedAreas(nTerminal, cpfM1.leadingIndex).width
                                    if deltaY > 0 then
                                        privateFuncs.deco.addWallsAcross(cpf, true, slopedAreaWidth, result, tag, wallModelId, zShift, deltaY)
                                    end
                                elseif ii == _iiMax then
                                    privateFuncs.deco.addWallsAcross(cpf, false, slopedAreaWidth, result, tag, wallModelId, zShift, slopedAreaWidth + cpf.width)
                                elseif leadingIndex ~= cpfP1.leadingIndex then
                                    local deltaY = cpf.width + slopedAreaWidth - cpfP1.width - result.getOccupiedInfo4SlopedAreas(nTerminal, cpfP1.leadingIndex).width
                                    if deltaY > 0 then
                                        privateFuncs.deco.addWallsAcross(cpf, false, slopedAreaWidth, result, tag, wallModelId, zShift, deltaY)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end,
        doTrackWall = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge,
            wall_5m_ModelId,
            wall_low_5m_ModelId,
            isTunnelOk
        )
            -- check this coz it was added later
            if type(params.terminals[nTerminal].centreTracksFineRelative) ~= 'table' then return end

            -- do not confuse the tracks array with the platforms array: they are similar but different
            local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
            local transfXZoom = isTrackOnPlatformLeft and 1 or -1 -- -1 or 1
            local transfYZoom = isTrackOnPlatformLeft and 1 or -1 -- -1 or 1
            local isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)

            local _wallTransfFunc = privateFuncs.deco.getMNAdjustedValue_0Or1_Cycling(params, slotId) == 0
                and privateFuncs.getPlatformObjectTransf_WithYRotation
                or privateFuncs.getPlatformObjectTransf_AlwaysVertical

            local _i1 = isEndFiller and nTrackEdge or (nTrackEdge - 1)
            local _iMax = isEndFiller and nTrackEdge or (nTrackEdge + 1)

            -- query the first platform segment coz track segments, unlike platform segments,
            -- have no knowledge of the era: they only have leadingIndex, posTanX2, type and width.
            local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, 1)
            local wallBaseModelId = 'lollo_freestyle_train_station/trackWalls/era_c_wall_base_5m.mdl'
            if eraPrefix == constants.eras.era_a.prefix then
                wallBaseModelId = 'lollo_freestyle_train_station/trackWalls/era_a_wall_base_5m.mdl'
            elseif eraPrefix == constants.eras.era_b.prefix then
                wallBaseModelId = 'lollo_freestyle_train_station/trackWalls/era_b_wall_base_5m.mdl'
            end

            for ii = 1, #params.terminals[nTerminal].centreTracksFineRelative, privateConstants.deco.ceilingStep do
                local ctf = params.terminals[nTerminal].centreTracksFineRelative[ii]
                local leadingIndex = ctf.leadingIndex
                if leadingIndex > _iMax then break end
                if leadingIndex >= _i1 then
                    if isTunnelOk or ctf.type ~= 2 then -- ground or bridge, tunnel only if allowed
                        local basePosTanX2, xScaleFactor, zShift = ctf.posTanX2, 1, 0
                        local wallModelId = ctf.type == 2 and wall_5m_ModelId or wall_low_5m_ModelId
                        local myTransf = transfUtilsUG.mul(
                            _wallTransfFunc(basePosTanX2),
                            { transfXZoom * xScaleFactor, 0, 0, 0,  0, transfYZoom, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformRoofZ + zShift, 1 }
                        )
                        result.models[#result.models+1] = {
                            id = wallModelId,
                            transf = myTransf,
                            tag = tag
                        }
                        result.models[#result.models+1] = {
                            id = wallBaseModelId,
                            transf = myTransf,
                            tag = tag
                        }
                    end
                end
            end
        end,
    },
    edges = {
        addEdges = function(result, tag, params, t)
            -- logger.print('moduleHelpers.edges.addEdges starting for terminal', t, ', result.edgeLists =') debugPrint(result.edgeLists)
    
            local nNodesInTerminalSoFar = privateFuncs.edges._getNNodesInTerminalsSoFar(params, t)
    
            local tag2nodes = {
                [tag] = { } -- list of base 0 indexes
            }
    
            for i = 1, #params.terminals[t].platformEdgeLists + #params.terminals[t].trackEdgeLists do
            -- for i = 1, #params.terminals[t].trackEdgeLists do
                for ii = 1, 2 do
                    tag2nodes[tag][#tag2nodes[tag]+1] = nNodesInTerminalSoFar
                    nNodesInTerminalSoFar = nNodesInTerminalSoFar + 1
                end
            end
    
            privateFuncs.edges._addPlatformEdges(result, tag2nodes, params, t)
            privateFuncs.edges._addTrackEdges(result, tag2nodes, params, t)
    
            -- print('moduleHelpers.edges.addEdges ending for terminal', t, ', result.edgeLists =') debugPrint(result.edgeLists)
        end,
    },
    extraStationCapacity = {
        getStationPoolCapacities = function(modules, result)
            local extraCargoCapacity = 0
            local extraPassengersCapacity = 0

            for num, slot in pairs(result.slots) do
                local module = modules[slot.id]
                if module and module.metadata and module.metadata.moreCapacity then
                    if type(module.metadata.moreCapacity.cargo) == 'number' then
                        extraCargoCapacity = extraCargoCapacity + module.metadata.moreCapacity.cargo
                    end
                    if type(module.metadata.moreCapacity.passenger) == 'number' then
                        extraPassengersCapacity = extraPassengersCapacity + module.metadata.moreCapacity.passenger
                    end
                end
            end
            return extraCargoCapacity, extraPassengersCapacity
        end,
    },
    axialAreas = {
        exitWithEdgeModule_updateFn = function(result, slotTransf, tag, slotId, addModelFn, params, updateScriptParams, isSnap)
            local nTerminal, nTrackEdge, baseId = result.demangleId(slotId)
			if not nTerminal or not baseId then return end

            local adjustedTransf = privateFuncs.axialAreas.getMNAdjustedTransf(params, slotId, slotTransf)

			local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, nTrackEdge)

			-- local myGroundFacesFillKey = constants[eraPrefix .. 'groundFacesFillKey']
			local myModelId = 'lollo_freestyle_train_station/railroad/flatSides/passengers/' .. eraPrefix .. 'stairs_edge.mdl'

			result.models[#result.models + 1] = {
				id = myModelId,
				slotId = slotId,
				transf = adjustedTransf,
				tag = tag
			}

			local _autoBridgePathsRefData = autoBridgePathsHelper.getData4Era(eraPrefix)
			table.insert(
				result.edgeLists,
				{
					alignTerrain = false, -- only align on ground and in tunnels
					edges = transfUtils.getPosTanX2Transformed(
						{
							{ { 0.5, 0, 0 }, { 1, 0, 0 } },  -- node 0 pos, tan
							{ { 1.5, 0, 0 }, { 1, 0, 0 } },  -- node 1 pos, tan
						},
						adjustedTransf
					),
					-- better make it a bridge to avoid ugly autolinks between nearby modules
					edgeType = 'BRIDGE',
					edgeTypeName = _autoBridgePathsRefData.bridgeTypeName_withRailing,
					freeNodes = { 1 },
					params = {
						hasBus = true,
						tramTrackType  = 'NO',
						type = _autoBridgePathsRefData.streetTypeName_noBridge,
					},
					snapNodes = isSnap and { 1 } or {},
					tag2nodes = {},
					type = 'STREET'
				}
			)

			-- local groundFace = {
			-- 	{-1, -2, 0, 1},
			-- 	{-1, 2, 0, 1},
			-- 	{1.0, 2, 0, 1},
			-- 	{1.0, -2, 0, 1},
			-- }
			-- modulesutil.TransformFaces(zAdjustedTransf, groundFace)

			local terrainAlignmentList = {
				faces = {
					{
						{-1, -2, 0, 1},
						{-1, 2, 0, 1},
						{1.0, 2, 0, 1},
						{1.0, -2, 0, 1},
					}
				},
				optional = true,
				slopeHigh = constants.slopeHigh,
				slopeLow = constants.slopeLow,
				type = 'LESS',
			}
			for _, face in pairs(terrainAlignmentList.faces) do
				modulesutil.TransformFaces(adjustedTransf, face)
			end
			result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = terrainAlignmentList
        end,
        flushExit_updateFn = function(result, slotTransf, tag, slotId, addModelFn, params, updateScriptParams)
            local nTerminal, nTrackEdge, baseId = result.demangleId(slotId)
			if not nTerminal or not baseId then return end

			privateFuncs.flatAreas.addExitPole(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)

            local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[(nTrackEdge == 1 and 1 or #params.terminals[nTerminal].centrePlatformsFineRelative)]
			local pos1 = (nTrackEdge == 1)
				and cpf.posTanX2[1][1]
				or cpf.posTanX2[2][1]
			local deltaPos = (nTrackEdge == 1)
				and transfUtils.getVectorNormalised(
					{
						cpf.posTanX2[1][1][1] - cpf.posTanX2[2][1][1],
						cpf.posTanX2[1][1][2] - cpf.posTanX2[2][1][2],
						cpf.posTanX2[1][1][3] - cpf.posTanX2[2][1][3],
					},
					1
				)
				or transfUtils.getVectorNormalised(
					{
						cpf.posTanX2[2][1][1] - cpf.posTanX2[1][1][1],
						cpf.posTanX2[2][1][2] - cpf.posTanX2[1][1][2],
						cpf.posTanX2[2][1][3] - cpf.posTanX2[1][1][3],
					},
					1
				)
			local pos2 = {
				pos1[1] + deltaPos[1],
				pos1[2] + deltaPos[2],
				pos1[3] + deltaPos[3],
			}

			local laneTransf = transfUtils.getTransfZShiftedBy(
				transfUtils.get1MLaneTransf(pos1, pos2),
				result.laneZs[nTerminal]
			)

            local adjustedTransf = privateFuncs.axialAreas.getMNAdjustedTransf(params, slotId, slotTransf)
			result.models[#result.models+1] = {
				id = 'lollo_freestyle_train_station/passenger_lane_linkable_irregular.mdl',
				slotId = slotId,
				transf = adjustedTransf,
				tag = tag
			}
        end,
        getMNAdjustedTransf = function(params, slotId, slotTransf)
            return privateFuncs.axialAreas.getMNAdjustedTransf(params, slotId, slotTransf)
        end,
        getPreviewIcon = function(params)
			local variant = (params ~= nil and type(params.variant) == 'number') and params.variant or 0
			local tilt, min, max = privateFuncs.getFromVariant_AxialAreaTilt(variant)
			local arrowModelId = 'lollo_freestyle_train_station/icon/arrows_mid_blue.mdl'
			local arrowModelTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  10, -2, 8, 1}
            if tilt == min then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
            elseif tilt == max then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			elseif tilt < 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
			elseif tilt > 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			end
            return {
                id = arrowModelId,
                transf = arrowModelTransf,
            }
        end,
    },
    flatAreas = {
        doTerrain4StationSquare = function(height, slotTransf, result, groundFacesFillKey, groundFacesStrokeOuterKey)
            local groundFace = { -- the ground faces ignore z, the alignment lists don't
                {0, -5.5, height, 1},
                {0, 5.5, height, 1},
                {6.0, 5.5, height, 1},
                {6.0, -5.5, height, 1},
            }
            modulesutil.TransformFaces(slotTransf, groundFace)
            table.insert(
                result.groundFaces,
                {
                    face = groundFace,
                    modes = {
                        {
                            type = 'FILL',
                            key = groundFacesFillKey
                        },
                        {
                            type = 'STROKE_OUTER',
                            key = groundFacesStrokeOuterKey
                        }
                    }
                }
            )

            local terrainAlignmentList = {
                faces = { groundFace },
                optional = true,
                slopeHigh = constants.slopeHigh,
                slopeLow = constants.slopeLow,
                type = 'EQUAL',
            }
            result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = terrainAlignmentList
        end,
        getFromVariant_0_to_1 = function(variant, nSteps)
            return privateFuncs.getFromVariant_0_to_1(variant, nSteps)
        end,
        getMNAdjustedTransf = function(params, slotId, slotTransf, isFlush)
            return privateFuncs.flatAreas.getMNAdjustedTransf(params, slotId, slotTransf, isFlush)
        end,
        getMNAdjustedValue_0To1_Cycling = function(params, slotId, nSteps)
            local variant = privateFuncs.getVariant(params, slotId)
            return privateFuncs.getFromVariant_0_to_1(variant, nSteps)
        end,
        getPreviewIcon = function(params)
			local variant = (params ~= nil and type(params.variant) == 'number') and params.variant or 0
			local deltaZ, min, max = privateFuncs.getFromVariant_FlatAreaHeight(variant, false)
			local arrowModelId = 'lollo_freestyle_train_station/icon/arrows_mid_blue.mdl'
			local arrowModelTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  10, -2, 8, 1}
			if deltaZ == min then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			elseif deltaZ == max then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
            elseif deltaZ < 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			elseif deltaZ > 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
			end
            return {
                id = arrowModelId,
                transf = arrowModelTransf,
            }
        end,
        addCargoLaneToStreet = function(result, slotAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)
            return privateFuncs.flatAreas.addCargoLaneToStreet(result, slotAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)
        end,
        addPassengerLaneToStreet = function(result, slotAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)
            return privateFuncs.flatAreas.addPassengerLaneToStreet(result, slotAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)
        end,

        exitWithEdgeModule_updateFn = function(result, slotTransf, tag, slotId, addModelFn, params, updateScriptParams, isSnap)
			local nTerminal, nTrackEdge, baseId = result.demangleId(slotId)
			if not nTerminal or not baseId then return end

			-- LOLLO NOTE tag looks like '__module_201030', never mind what you write into it, the game overwrites it
			-- in base_config.lua
			-- Set it into the models, so the game knows what module they belong to.

			local zAdjustedTransf = privateFuncs.flatAreas.getMNAdjustedTransf(params, slotId, slotTransf, false)

			local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
			local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, nTrackEdge)

			-- local myGroundFacesFillKey = constants[eraPrefix .. 'groundFacesFillKey']
			local myModelId = 'lollo_freestyle_train_station/railroad/flatSides/passengers/' .. eraPrefix .. 'stairs_edge.mdl'

			result.models[#result.models + 1] = {
				id = myModelId,
				slotId = slotId,
				transf = zAdjustedTransf,
				tag = tag
			}

			-- this connects the platform to its outer edge (ie border)
			privateFuncs.flatAreas.addPassengerLaneToStreet(result, zAdjustedTransf, tag, slotId, params, nTerminal, nTrackEdge)

			local _autoBridgePathsRefData = autoBridgePathsHelper.getData4Era(eraPrefix)
			table.insert(
				result.edgeLists,
				{
					alignTerrain = false, -- only align on ground and in tunnels
					edges = transfUtils.getPosTanX2Transformed(
						{
							{ { 0.5, 0, 0 }, { 1, 0, 0 } },  -- node 0 pos, tan
							{ { 1.5, 0, 0 }, { 1, 0, 0 } },  -- node 1 pos, tan
						},
						zAdjustedTransf
					),
					-- better make it a bridge to avoid ugly autolinks between nearby modules
					edgeType = 'BRIDGE',
					edgeTypeName = _autoBridgePathsRefData.bridgeTypeName_withRailing,
					freeNodes = { 1 },
					params = {
						hasBus = true,
						tramTrackType  = 'NO',
						type = _autoBridgePathsRefData.streetTypeName_noBridge,
					},
					snapNodes = isSnap and { 1 } or {},
					tag2nodes = {},
					type = 'STREET'
				}
			)

			-- local groundFace = {
			-- 	{-1, -2, 0, 1},
			-- 	{-1, 2, 0, 1},
			-- 	{1.0, 2, 0, 1},
			-- 	{1.0, -2, 0, 1},
			-- }
			-- modulesutil.TransformFaces(zAdjustedTransf, groundFace)
			-- result.groundFaces[#result.groundFaces + 1] = moduleHelpers.getGroundFace(groundFace, myGroundFacesFillKey)

			local terrainAlignmentList = {
				faces = {
					{
						{-1, -2, constants.platformSideBitsZ, 1},
						{-1, 2, constants.platformSideBitsZ, 1},
						{1.0, 2, constants.platformSideBitsZ, 1},
						{1.0, -2, constants.platformSideBitsZ, 1},
					}
				},
				optional = true,
				slopeHigh = constants.slopeHigh,
				slopeLow = constants.slopeLow,
				type = 'LESS',
			}
			for _, face in pairs(terrainAlignmentList.faces) do
				modulesutil.TransformFaces(zAdjustedTransf, face)
			end
			result.terrainAlignmentLists[#result.terrainAlignmentLists + 1] = terrainAlignmentList
		end,

        addExitPole = function(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)
            return privateFuncs.flatAreas.addExitPole(result, slotTransf, tag, slotId, params, nTerminal, nTrackEdge)
        end
    },
    lifts = {
        getPreview = function(params, isSideLift)
			local variant = (params ~= nil and type(params.variant) == 'number') and params.variant or 0
			local deltaZ, min, max = privateFuncs.getFromVariant_LiftHeight(variant)
			local arrowModelId = 'lollo_freestyle_train_station/icon/arrows_mid_blue.mdl'
			local arrowModelTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  -10, -10, 0, 1}
            local mainModelId = isSideLift and 'lollo_freestyle_train_station/lift/side_lifts_9_5_20.mdl' or 'lollo_freestyle_train_station/lift/platform_lifts_9_5_20.mdl'
			local mainModelTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 15, 1}
            if deltaZ == min then
                arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  -10, -10, 1, 1}
                mainModelId = isSideLift and 'lollo_freestyle_train_station/lift/side_lifts_9_5_10.mdl' or 'lollo_freestyle_train_station/lift/platform_lifts_9_5_10.mdl'
			elseif deltaZ == max then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  -10, -10, -1, 1}
                mainModelId = isSideLift and 'lollo_freestyle_train_station/lift/side_lifts_9_5_30.mdl' or 'lollo_freestyle_train_station/lift/platform_lifts_9_5_30.mdl'
            elseif deltaZ < 0 then
                arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  -10, -10, 1, 1}
                mainModelId = isSideLift and 'lollo_freestyle_train_station/lift/side_lifts_9_5_15.mdl' or 'lollo_freestyle_train_station/lift/platform_lifts_9_5_15.mdl'
			elseif deltaZ > 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  -10, -10, -1, 1}
                mainModelId = isSideLift and 'lollo_freestyle_train_station/lift/side_lifts_9_5_25.mdl' or 'lollo_freestyle_train_station/lift/platform_lifts_9_5_25.mdl'
			end
            return {
                {
                    id = arrowModelId,
                    transf = arrowModelTransf,
                },
                {
                    id = mainModelId,
                    transf = mainModelTransf,
                },
            }
        end,
        tryGetLiftHeight = function(params, nTerminal, nTrackEdge, slotId)
            local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
            local cplP1 = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge+1] or {}
            local bridgeHeight = (cpl.type == 1 and cplP1.type == 1)
            and (params.mainTransf[15] + cpl.posTanX2[1][1][3] - cpl.terrainHeight1)
            or 0

            local buildingHeight = 0
            if bridgeHeight < privateConstants.lifts.bridgeHeights[1] then
                buildingHeight = 0
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[2] then
                buildingHeight = 5
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[3] then
                buildingHeight = 10
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[4] then
                buildingHeight = 15
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[5] then
                buildingHeight = 20
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[6] then
                buildingHeight = 25
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[7] then
                buildingHeight = 30
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[8] then
                buildingHeight = 35
            else
                buildingHeight = 40
            end

            local variant = privateFuncs.getVariant(params, slotId)
            local deltaZ = privateFuncs.getFromVariant_LiftHeight(variant)

            buildingHeight = buildingHeight + deltaZ
            if buildingHeight < 0 then buildingHeight = 0
            elseif buildingHeight > 40 then buildingHeight = 40
            end

            return buildingHeight
        end,
        tryGetSideLiftModelId = function(params, nTerminal, nTrackEdge, eraPrefix, bridgeHeight)
            local buildingModelId = 'lollo_freestyle_train_station/lift/'
            if eraPrefix == constants.eras.era_a.prefix then buildingModelId = 'lollo_freestyle_train_station/lift/era_a_'
            elseif eraPrefix == constants.eras.era_b.prefix then buildingModelId = 'lollo_freestyle_train_station/lift/era_b_'
            end

            if bridgeHeight < privateConstants.lifts.bridgeHeights[1] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_0.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[2] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_5.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[3] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_10.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[4] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_15.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[5] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_20.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[6] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_25.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[7] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_30.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[8] then
                buildingModelId = buildingModelId .. 'side_lifts_9_5_35.mdl'
            else
                buildingModelId = buildingModelId .. 'side_lifts_9_5_40.mdl'
            end
    
            return buildingModelId
        end,
        tryGetPlatformLiftModelId = function(params, nTerminal, nTrackEdge, eraPrefix, bridgeHeight)
            local buildingModelId = 'lollo_freestyle_train_station/lift/'
            if eraPrefix == constants.eras.era_a.prefix then buildingModelId = 'lollo_freestyle_train_station/lift/era_a_'
            elseif eraPrefix == constants.eras.era_b.prefix then buildingModelId = 'lollo_freestyle_train_station/lift/era_b_'
            end
    
            if bridgeHeight < privateConstants.lifts.bridgeHeights[1] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_5.mdl' -- non linearity
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[2] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_5.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[3] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_10.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[4] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_15.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[5] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_20.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[6] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_25.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[7] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_30.mdl'
            elseif bridgeHeight < privateConstants.lifts.bridgeHeights[8] then
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_35.mdl'
            else
                buildingModelId = buildingModelId .. 'platform_lifts_9_5_40.mdl'
            end
    
            return buildingModelId
        end,
    },
    openStairs = {
        exitWithEdgeModule_updateFn = function(result, slotTransf, tag, slotId, addModelFn, params, updateScriptParams, isSnap)
			local nTerminal, nTrackEdge, baseId = result.demangleId(slotId)
			if not nTerminal or not baseId then return end

			local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, nTrackEdge)
			local modelId = privateFuncs.openStairs.getPedestrianBridgeModelId(2, eraPrefix, true)
			local transf = privateFuncs.openStairs.getExitModelTransf(slotTransf, slotId, params)

			result.models[#result.models + 1] = {
				id = modelId,
				slotId = slotId,
				transf = transf,
				tag = tag
			}
			result.models[#result.models + 1] = {
				id = 'lollo_freestyle_train_station/passenger_lane.mdl',
				slotId = slotId,
				transf = transfUtilsUG.mul(slotTransf, {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  -1, 0, 0, 1}),
				tag = tag
			}

			local _autoBridgePathsRefData = autoBridgePathsHelper.getData4Era(eraPrefix)
			table.insert(
				result.edgeLists,
				{
					alignTerrain = false, -- only align on ground and in tunnels
					edges = transfUtils.getPosTanX2Transformed(
						{
							{ { 2, 0, 0 }, { 1, 0, 0 } },  -- node 0 pos, tan
							{ { 3, 0, 0 }, { 1, 0, 0 } },  -- node 1 pos, tan
						},
						transf
					),
					edgeType = 'BRIDGE',
					edgeTypeName = _autoBridgePathsRefData.bridgeTypeName_withRailing,
					freeNodes = { 1 },
					params = {
						hasBus = true,
						tramTrackType  = 'NO',
						type = _autoBridgePathsRefData.streetTypeName_noBridge,
					},
					snapNodes = isSnap and { 1 } or {},
					tag2nodes = {},
					type = 'STREET'
				}
			)
		end,
        getExitModelTransf = function(slotTransf, slotId, params)
            return privateFuncs.openStairs.getExitModelTransf(slotTransf, slotId, params)
        end,
        getPedestrianBridgeModelId = function(length, eraPrefix, isWithEdge)
            return privateFuncs.openStairs.getPedestrianBridgeModelId(length, eraPrefix, isWithEdge)
        end,
        getPedestrianBridgeModelId_Compressed = function(length, eraOfT1Prefix, eraOfT2Prefix)
            -- eraOfT1 and eraOfT2 are strings like 'era_a_'
            local newEraPrefix1 = eraOfT1Prefix
            if newEraPrefix1 ~= constants.eras.era_a.prefix and newEraPrefix1 ~= constants.eras.era_b.prefix and newEraPrefix1 ~= constants.eras.era_c.prefix then
                newEraPrefix1 = constants.eras.era_c.prefix
            end
            local newEraPrefix2 = eraOfT2Prefix
            if newEraPrefix2 ~= constants.eras.era_a.prefix and newEraPrefix2 ~= constants.eras.era_b.prefix and newEraPrefix2 ~= constants.eras.era_c.prefix then
                newEraPrefix2 = constants.eras.era_c.prefix
            end
            local newEraPrefix = (newEraPrefix1 > newEraPrefix2) and newEraPrefix1 or newEraPrefix2
    
            if length < 6 then return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_compressed_4m.mdl'
            elseif length < 12 then return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_compressed_8m.mdl'
            elseif length < 24 then return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_compressed_16m.mdl'
            elseif length < 48 then return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_compressed_32m.mdl'
            else return 'lollo_freestyle_train_station/open_stairs/' .. newEraPrefix .. 'bridge_chunk_compressed_64m.mdl'
            end
        end,
        getPreviewIcon = function(params)
			local variant = (params ~= nil and type(params.variant) == 'number') and params.variant or 0
			local tilt, min, max = privateFuncs.getFromVariant_BridgeTilt(variant)
			local arrowModelId = 'lollo_freestyle_train_station/icon/arrows_mid_blue.mdl'
			local arrowModelTransf = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  10, -2, 8, 1}
            if tilt == min then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
            elseif tilt == max then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_end_blue_orange.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			elseif tilt < 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, 1, 0,  0, 1, 0, 0,  -1, 0, 0, 0,  10, -2, 9, 1}
			elseif tilt > 0 then
				arrowModelId = 'lollo_freestyle_train_station/icon/arrow_blue.mdl'
				arrowModelTransf = {0, 0, -1, 0,  0, 1, 0, 0,  1, 0, 0, 0,  10, -2, 7, 1}
			end
            return {
                id = arrowModelId,
                transf = arrowModelTransf,
            }
        end,
    },
    platforms = {
        addPlatform = function(result, tag, slotId, params, nTerminal)
            -- LOLLO NOTE I can use a platform-track or dedicated models for the platform.
            -- The former is simpler, the latter requires adding an invisible track so the platform fits in bridges or tunnels.
            -- The former is a bit glitchy, the latter is prettier.
            local _getPlatformModelId = function (isCargo, isTrackOnPlatformLeft, width, nTrackEdge, era,
            previousLeadingIndex, currentLeadingIndex, nextLeadingIndex)
                local myModelId = ''
                if isCargo then
                    if width < 10 then
                        myModelId = 'lollo_freestyle_train_station/railroad/platform/era_c_cargo_platform_1m_base_5m_wide.mdl'
                    elseif width < 20 then
                        myModelId = 'lollo_freestyle_train_station/railroad/platform/era_c_cargo_platform_1m_base_10m_wide.mdl'
                    else
                        myModelId = 'lollo_freestyle_train_station/railroad/platform/era_c_cargo_platform_1m_base_20m_wide.mdl'
                    end
                else
                    local isUnderpass = params.modules[result.mangleId(nTerminal, nTrackEdge, constants.idBases.underpassSlotId)] ~= nil
                    and previousLeadingIndex == currentLeadingIndex
                    and currentLeadingIndex == nextLeadingIndex
                    if isUnderpass then
                        if width < 5 then
                            myModelId = isTrackOnPlatformLeft
                                and 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_3_1m_wide_hole_stripe_left.mdl'
                                or 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_3_1m_wide_hole_stripe_right.mdl'
                        else
                            myModelId = isTrackOnPlatformLeft
                                and 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_5_6m_wide_hole_stripe_left.mdl'
                                or 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_5_6m_wide_hole_stripe_right.mdl'
                        end
                    else
                        if width < 5 then
                            myModelId = isTrackOnPlatformLeft
                                and 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_3_1m_wide_stripe_left.mdl'
                                or 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_3_1m_wide_stripe_right.mdl'
                        else
                            myModelId = isTrackOnPlatformLeft
                                and 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_5_6m_wide_stripe_left.mdl'
                                or 'lollo_freestyle_train_station/railroad/platform/era_c_passenger_platform_1m_base_5_6m_wide_stripe_right.mdl'
                        end
                    end
                end
    
                if era == constants.eras.era_a.prefix then
                    return myModelId:gsub(constants.eras.era_c.prefix, constants.eras.era_a.prefix)
                elseif era == constants.eras.era_b.prefix then
                    return myModelId:gsub(constants.eras.era_c.prefix, constants.eras.era_b.prefix)
                else
                    return myModelId
                end
            end
    
            local isCargoTerminal = params.terminals[nTerminal].isCargo
            local isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft
            -- local isFirstDone = false
            for ii = 1, #params.terminals[nTerminal].centrePlatformsFineRelative do
                local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
                local cpfM1 = params.terminals[nTerminal].centrePlatformsFineRelative[ii-1] or {}
                local cpfP1 = params.terminals[nTerminal].centrePlatformsFineRelative[ii+1] or {}
                local myTransf = privateFuncs.getPlatformObjectTransf_WithYRotation(cpf.posTanX2)
                local eraPrefix = privateFuncs.getEraPrefix(params, nTerminal, cpf.leadingIndex)
                local myModelId = _getPlatformModelId(isCargoTerminal, isTrackOnPlatformLeft, cpf.width, cpf.leadingIndex, eraPrefix,
                cpfM1.leadingIndex, cpf.leadingIndex, cpfP1.leadingIndex)
                result.models[#result.models+1] = {
                    id = myModelId,
                    slotId = slotId,
                    tag = tag,
                    transf = myTransf
                }
                -- if not(isFirstDone) then myTransf[15] = myTransf[15] + 1 end
                -- result.models[#result.models+1] = {
                --     id = isFirstDone and 'lollo_freestyle_train_station/icon/green.mdl' or 'lollo_freestyle_train_station/icon/red.mdl',
                --     slotId = slotId,
                --     tag = tag,
                --     transf = myTransf
                -- }
                -- isFirstDone = true
            end
            -- local isFirstDone = false
            -- for _, cpl in pairs(params.terminals[nTerminal].centrePlatformsRelative) do
            --     local myTransf = privateFuncs.getPlatformObjectTransf_WithYRotation(cpl.posTanX2)
            --     myTransf[15] = myTransf[15] + 1
            --     result.models[#result.models+1] = {
            --         id = isFirstDone and 'lollo_freestyle_train_station/icon/red.mdl' or 'lollo_freestyle_train_station/icon/green.mdl',
            --         slotId = slotId,
            --         tag = tag,
            --         transf = myTransf
            --     }
            --     isFirstDone = true
            -- end
        end,
    },
    slopedAreas = {
        getYShift = function(params, t, i, slopedAreaWidth)
            local isTrackOnPlatformLeft = params.terminals[t].isTrackOnPlatformLeft
            if not(params.terminals[t].centrePlatformsRelative[i]) then return false end

            local platformWidth = params.terminals[t].centrePlatformsRelative[i].width
            local baseYShift = (slopedAreaWidth + platformWidth) * 0.5 -0.85
            local yShiftOutside = isTrackOnPlatformLeft and -baseYShift or baseYShift

            local yShiftOutside4StreetAccess = slopedAreaWidth * 2 -- - 1.2 -- - 1.8

            return yShiftOutside, yShiftOutside4StreetAccess
        end,
        addAll = function(result, tag, slotId, params, nTerminal, nTrackEdge, eraPrefix, areaWidth, modelId, waitingAreaModelId, groundFacesFillKey, isCargo)
            local _isEndFiller = privateFuncs.getIsEndFillerEvery3(nTrackEdge)
            local _waitingAreaScaleFactor = areaWidth * 0.8
            local _i1 = _isEndFiller and nTrackEdge or (nTrackEdge - 1)
            local _iN = _isEndFiller and nTrackEdge or (nTrackEdge + 1)
            local _isTrackOnPlatformLeft = params.terminals[nTerminal].isTrackOnPlatformLeft

            local waitingAreaIndex = 0
            local nWaitingAreas = 0
            local isDecoBarred = false
            local _cpfs = params.terminals[nTerminal].centrePlatformsFineRelative
            for ii = 1, #_cpfs do
                local cpf = params.terminals[nTerminal].centrePlatformsFineRelative[ii]
                local leadingIndex = cpf.leadingIndex
                if leadingIndex > _iN then break end
                if leadingIndex >= _i1 then
                    -- allow any size on ground or 2.5 m on bridges
                    local isCanBuild = privateFuncs.slopedAreas.isSlopedAreaAllowed(cpf, areaWidth)
                    if isCanBuild then
                        local platformWidth = cpf.width
                        local centreAreaPosTanX2, xRatio, yRatio = transfUtils.getParallelSidewaysWithRotZ(
                            cpf.posTanX2,
                            (_isTrackOnPlatformLeft and (-areaWidth -platformWidth) or (areaWidth + platformWidth)) * 0.5
                        )
                        local myTransf = privateFuncs.getPlatformObjectTransf_WithYRotation(centreAreaPosTanX2)
                        local xScaleFactor = math.max(xRatio * yRatio, 1.05) -- this is a bit crude but it's cheap
                        logger.print('xScaleFactor w ratios =', xScaleFactor)
                        result.models[#result.models+1] = {
                            id = modelId,
                            transf = transfUtilsUG.mul(
                                myTransf,
                                { xScaleFactor, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, constants.platformSideBitsZ, 1 }
                            ),
                            tag = tag
                        }

                        if waitingAreaModelId ~= nil
                        and _cpfs[ii - 2] ~= nil
                        and _cpfs[ii - 2].leadingIndex >= _i1
                        and _cpfs[ii + 2] ~= nil
                        and _cpfs[ii + 2].leadingIndex <= _iN then
                            if math.fmod(waitingAreaIndex, 5) == 0 then
                                result.models[#result.models+1] = {
                                    id = waitingAreaModelId,
                                    transf = transfUtilsUG.mul(
                                        myTransf,
                                        { 0, _waitingAreaScaleFactor, 0, 0,  -_waitingAreaScaleFactor, 0, 0, 0,  0, 0, 1, 0,  0, 0, result.laneZs[nTerminal], 1 }
                                    ),
                                    tag = slotHelpers.mangleModelTag(nTerminal, isCargo),
                                }
                                nWaitingAreas = nWaitingAreas + 1
                            end
                            waitingAreaIndex = waitingAreaIndex + 1
                        end
                    else
                        isDecoBarred = true
                        if waitingAreaModelId ~= nil
                        and _cpfs[ii - 2] ~= nil
                        and _cpfs[ii - 2].leadingIndex >= _i1
                        and _cpfs[ii + 2] ~= nil
                        and _cpfs[ii + 2].leadingIndex <= _iN then
                            if math.fmod(waitingAreaIndex, 5) == 0 then
                                nWaitingAreas = nWaitingAreas + 1
                            end
                            waitingAreaIndex = waitingAreaIndex + 1
                        end
                    end
                end
            end

            privateFuncs.slopedAreas._doTerrain4SlopedArea(result, params, nTerminal, nTrackEdge, _isEndFiller, areaWidth, groundFacesFillKey)
            if waitingAreaModelId ~= nil and not(isDecoBarred) then
                local cpl = params.terminals[nTerminal].centrePlatformsRelative[nTrackEdge]
                local verticalTransf = privateFuncs.getPlatformObjectTransf_AlwaysVertical(cpl.posTanX2)
                if isCargo then
                    privateFuncs.slopedAreas.addSlopedCargoAreaDeco(result, tag, slotId, params, nTerminal, nTrackEdge, eraPrefix, areaWidth, nWaitingAreas, verticalTransf)
                else
                    privateFuncs.slopedAreas.addSlopedPassengerAreaDeco(result, tag, slotId, params, nTerminal, nTrackEdge, eraPrefix, areaWidth, nWaitingAreas, verticalTransf)
                end
            end
        end,
    },
    subways = {
        doTerrain4Subways = function(result, slotTransf, groundFacesStrokeOuterKey)
            local groundFace = { -- the ground faces ignore z, the alignment lists don't
                {0.0, -0.95, 0, 1},
                {0.0, 0.95, 0, 1},
                {4.5, 0.95, 0, 1},
                {4.5, -0.95, 0, 1},
            }
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-0.2, -1.15, constants.platformSideBitsZ, 1},
                {-0.2, 1.15, constants.platformSideBitsZ, 1},
                {4.7, 1.15, constants.platformSideBitsZ, 1},
                {4.7, -1.15, constants.platformSideBitsZ, 1},
            }
            if type(slotTransf) == 'table' then
                modulesutil.TransformFaces(slotTransf, groundFace)
                modulesutil.TransformFaces(slotTransf, terrainFace)
            end
        
            table.insert(
                result.groundFaces,
                {
                    face = groundFace,
                    loop = true,
                    modes = {
                        {
                            -- key = 'lollo_freestyle_train_station/hole.lua',
                            key = 'hole.lua',
                            type = 'FILL',
                        },
                        {
                            key = groundFacesStrokeOuterKey,
                            type = 'STROKE_OUTER',
                        }
                    }
                }
            )
            table.insert(
                result.terrainAlignmentLists,
                {
                    faces =  { terrainFace },
                    optional = true,
                    slopeHigh = constants.slopeHigh,
                    slopeLow = constants.slopeLow,
                    type = 'EQUAL',
                }
            )
        end,
        doTerrain4HollowayMedium = function(result, slotTransf, groundFacesStrokeOuterKey)
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-3.4, -4.7, constants.platformSideBitsZ, 1},
                {-3.4, 4.7, constants.platformSideBitsZ, 1},
                {4.9, 4.7, constants.platformSideBitsZ, 1},
                {4.9, -4.7, constants.platformSideBitsZ, 1},
            }
            return privateFuncs.subways.doTerrain4ClosedSubways(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        end,
        doTerrain4HollowayLarge = function(result, slotTransf, groundFacesStrokeOuterKey)
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-3.4, -7.5, constants.platformSideBitsZ, 1},
                {-3.4, 7.5, constants.platformSideBitsZ, 1},
                {4.9, 7.5, constants.platformSideBitsZ, 1},
                {4.9, -7.5, constants.platformSideBitsZ, 1},
            }
            return privateFuncs.subways.doTerrain4ClosedSubways(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        end,
        doTerrain4ClaphamLarge = function(result, slotTransf, groundFacesStrokeOuterKey)
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-3.4, -3.4, constants.platformSideBitsZ, 1},
                {-3.4, 3.4, constants.platformSideBitsZ, 1},
                {2.2, 7.4, constants.platformSideBitsZ, 1},
                {2.2, -7.4, constants.platformSideBitsZ, 1},
            }
            return privateFuncs.subways.doTerrain4ClosedSubways(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        end,
        doTerrain4ClaphamMedium = function(result, slotTransf, groundFacesStrokeOuterKey)
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-2.0, -3.4, constants.platformSideBitsZ, 1},
                {-2.0, 3.4, constants.platformSideBitsZ, 1},
                {1.7, 5.8, constants.platformSideBitsZ, 1},
                {1.7, -5.8, constants.platformSideBitsZ, 1},
            }
            return privateFuncs.subways.doTerrain4ClosedSubways(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        end,
        doTerrain4ClaphamSmall = function(result, slotTransf, groundFacesStrokeOuterKey)
            local terrainFace = { -- the ground faces ignore z, the alignment lists don't
                {-2.0, -2.9, constants.platformSideBitsZ, 1},
                {-2.0, 2.9, constants.platformSideBitsZ, 1},
                {1.7, 2.9, constants.platformSideBitsZ, 1},
                {1.7, -2.9, constants.platformSideBitsZ, 1},
            }
            return privateFuncs.subways.doTerrain4ClosedSubways(result, slotTransf, groundFacesStrokeOuterKey, terrainFace)
        end,
    },
    tubeBridge = {
        getPedestrianBridgeModelId_Compressed = function(length, eraOfT1Prefix, eraOfT2Prefix)
            -- eraOfT1 and eraOfT2 are strings like 'era_a_'
            local newEraPrefix1 = eraOfT1Prefix
            if newEraPrefix1 ~= constants.eras.era_a.prefix and newEraPrefix1 ~= constants.eras.era_b.prefix and newEraPrefix1 ~= constants.eras.era_c.prefix then
                newEraPrefix1 = constants.eras.era_c.prefix
            end
            local newEraPrefix2 = eraOfT2Prefix
            if newEraPrefix2 ~= constants.eras.era_a.prefix and newEraPrefix2 ~= constants.eras.era_b.prefix and newEraPrefix2 ~= constants.eras.era_c.prefix then
                newEraPrefix2 = constants.eras.era_c.prefix
            end
            local newEraPrefix = (newEraPrefix1 > newEraPrefix2) and newEraPrefix1 or newEraPrefix2

            if length < 6 then return 'lollo_freestyle_train_station/tubeBridge/' .. newEraPrefix .. 'bridge_chunk_compressed_4m.mdl'
            elseif length < 12 then return 'lollo_freestyle_train_station/tubeBridge/' .. newEraPrefix .. 'bridge_chunk_compressed_8m.mdl'
            elseif length < 24 then return 'lollo_freestyle_train_station/tubeBridge/' .. newEraPrefix .. 'bridge_chunk_compressed_16m.mdl'
            elseif length < 48 then return 'lollo_freestyle_train_station/tubeBridge/' .. newEraPrefix .. 'bridge_chunk_compressed_32m.mdl'
            else return 'lollo_freestyle_train_station/tubeBridge/' .. newEraPrefix .. 'bridge_chunk_compressed_64m.mdl'
            end
        end,
    },
}
