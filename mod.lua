function data()
    local _constants = require('lollo_freestyle_train_station.constants')
    local _mdlHelpers = require('lollo_freestyle_train_station.mdlHelpers')
    local _stringUtils = require('lollo_freestyle_train_station.stringUtils')
    local _trackHelpers = require('lollo_freestyle_train_station.trackHelpers')

    return {
        info = {
            minorVersion = 122,
            severityAdd = 'NONE',
            severityRemove = 'WARNING',
            name = _('NAME'),
            description = _('DESC'),
            tags = {
                'Station',
                'Bridge Station',
                'Cargo Station',
                'Elevated Station',
                'Elevator',
                'Lift',
                'Stairs',
                'Train Depot',
                'Train Station',
                'Underground Station',
                'Underground Train Depot',
            },
            authors = {
                {
                    name = 'Lollus',
                    role = 'CREATOR'
                },
                {
                    name = 'GordonDry',
                    role = 'TRANSLATOR'
                },
            }
        },

        -- streetside stations have colliders that annoy the station: get rid of them
        runFn = function(settings)
            addModifier(
                'loadModel',
                function(fileName, data)
                    if not(_stringUtils.stringEndsWith(fileName, '.mdl')) then return end

                    if data and data.metadata and data.metadata.streetTerminal then
                        data.boundingInfo = _mdlHelpers.getVoidBoundingInfo()
                        data.collider = _mdlHelpers.getVoidCollider()
                        -- print('LOLLO bounding reset, filename =', fileName)
                    end
                    return data
                end
            )
        end,

        postRunFn = function(settings, params)
            -- LOLLO NOTE yet another hack.
            -- base_mod.lua has postRunFn and loops over all the tracks it finds,
            -- including my platform-tracks. Then it creates modules for each, with and without catenary.
            -- They will crap up the stock station construction menu,
            -- so I set yearFrom = -1 and yearTo = -1 in the track files to make them invisible
            -- and then I restore them here.
            -- This works because this code always fires after base_mod.lua .
            -- As of version 1.75, platforms never expire.
            -- To keep the track construction menu tidy, we introduce a new category for non-platform tracks.
            local platformFileNames = {}
            local trackFileNames = api.res.trackTypeRep.getAll()
            for trackTypeIndex, trackFileName in pairs(trackFileNames) do
                local track = api.res.trackTypeRep.get(trackTypeIndex)
                if _trackHelpers.isPlatform2(track) then
                    platformFileNames[#platformFileNames+1] = trackFileName
                    -- local availability = _trackHelpers.getTrackAvailability(trackFileName)
                    -- track.yearFrom = availability.yearFrom -- we just change the value of the existing ref
                    -- -- track.yearTo = availability.yearTo -- idem
                    -- track.yearTo = 0 -- as of version 1.75, platforms never expire
                else
                    _trackHelpers.addCategory(track, _constants.trainTracksCategory)
                end
            end

            -- This is another way to do the same, to make life easier for some other mods
            local moduleNames = api.res.moduleRep.getAll()
            for moduleIndex, moduleName in pairs(moduleNames) do
                if _stringUtils.stringStartsWith(moduleName, 'trainstation_') then
                    for _, platformFileName in pairs(platformFileNames) do
                        if _stringUtils.stringContains(moduleName, platformFileName) then
                            api.res.moduleRep.setVisible(moduleIndex, false)
                            break
                        end
                    end
                end
            end

            -- This adds modules for modded tracks to the freestyle station
            for trackTypeIndex, trackFileName in pairs(trackFileNames) do
                if trackFileName ~= "standard.lua" and trackFileName ~= "high_speed.lua"
                and type(trackTypeIndex) == 'number' and trackTypeIndex > -1 and api.res.trackTypeRep.isVisible(trackTypeIndex)
                and type(trackFileName) == 'string'
                and not(_stringUtils.stringContains(trackFileName, 'ballast_standard'))
                and not(_stringUtils.stringContains(trackFileName, 'mus_mock'))
                and not(_stringUtils.stringContains(trackFileName, 'Seilbahn_Gleis'))
                and not(_stringUtils.stringContains(trackFileName, 'wk_track_dummy'))
                then
                    -- local track = api.res.trackTypeRep.get(api.res.trackTypeRep.find(trackFileName))
                    local track = api.res.trackTypeRep.get(trackTypeIndex)
                    if track ~= nil and not(_trackHelpers.isPlatform2(track)) and track.name ~= nil and track.desc ~= nil and track.icon ~= nil then
                        for __, catenary in pairs({false, true}) do
                            local module = api.type.ModuleDesc.new()
                            -- module.fileName = "trainstation_" .. tostring(trackFileName) .. (catenary and "catenary" or "")
                            module.fileName = 'station/rail/lollo_freestyle_train_station/trackTypes/dynamic_' .. (catenary and "catenary_" or "") .. tostring(trackFileName) .. '.module'

                            module.availability.yearFrom = track.yearFrom
                            module.availability.yearTo = track.yearTo
                            module.cost.price = math.floor(track.cost / 75 * 18000 + 0.5)

                            module.description.name = track.name .. (catenary and _(" with catenary") or "")
                            module.description.description = track.desc .. (catenary and _(" (with catenary)") or "")
                            module.description.icon = track.icon
                            -- if module.description.icon ~= "" then
                            --     module.description.icon = string.gsub(module.description.icon, ".tga", "")
                            --     module.description.icon = module.description.icon .. "_module" .. (catenary and "_catenary" or "") .. ".tga"
                            -- end

                            -- module.type = "track"
                            module.type = _constants.trackTypeModuleType
                            -- module.order.value = 0 + 10 * (catenary and 1 or 0)
                            module.order.value = 10 + 10 * (catenary and 1 or 0)
                            module.metadata = {
                                -- track = true,
                            }
                            -- module.category.categories = { "tracks", }
                            module.category.categories = { "track-type", }

                            -- module.updateScript.fileName = "construction/station/rail/modular_station/trackmodule.updateFn"
                            module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/trackTypes/dynamic.updateFn'
                            module.updateScript.params = {
                                trackType = trackFileName,
                                catenary = catenary
                            }
                            -- module.getModelsScript.fileName = "construction/station/rail/modular_station/trackmodule.getModelsFn"
                            module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/trackTypes/dynamic.getModelsFn'
                            module.getModelsScript.params = {
                                trackType = trackFileName,
                                catenary = catenary
                            }

                            api.res.moduleRep.add(module.fileName, module, true)
                        end
                    end
                end
            end

            -- This adds modules for bridges to the freestyle station
            local _getIsFitsRail = function(bridgeOrTunnel)
                if not(bridgeOrTunnel) or not(bridgeOrTunnel.carriers) then return false end

                for _, carrier in pairs(bridgeOrTunnel.carriers) do
                    if carrier == api.type.enum.Carrier.RAIL then return true end
                end
                return false
            end
            local bridgeFileNames = api.res.bridgeTypeRep.getAll()
            local bridgeCount = 1
            for bridgeTypeIndex, bridgeFileName in pairs(bridgeFileNames) do
                if type(bridgeTypeIndex) == 'number' and bridgeTypeIndex > -1 and api.res.bridgeTypeRep.isVisible(bridgeTypeIndex) then
                    local bridge = api.res.bridgeTypeRep.get(bridgeTypeIndex)
                    if bridge ~= nil and bridge.name ~= nil and _getIsFitsRail(bridge) then
                        local module = api.type.ModuleDesc.new()
                        module.fileName = 'station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic_' .. tostring(bridgeFileName) .. '.module'

                        module.availability.yearFrom = bridge.yearFrom
                        module.availability.yearTo = bridge.yearTo
                        module.cost.price = math.floor(bridge.cost / 75 * 18000 + 0.5)

                        module.description.name = bridge.name
                        module.description.description = bridge.name
                        module.description.icon = bridge.icon or 'ui/lollo_freestyle_train_station/none.tga'
                        -- if module.description.icon ~= "" then
                        --     module.description.icon = string.gsub(module.description.icon, ".tga", "")
                        --     module.description.icon = module.description.icon .. "_module" .. (catenary and "_catenary" or "") .. ".tga"
                        -- end

                        module.type = _constants.bridgeTypeModuleType
                        bridgeCount = bridgeCount + 1
                        module.order.value = bridgeCount
                        module.metadata = { }
                        module.category.categories = { "bridge-type", }

                        module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.updateFn'
                        module.updateScript.params = {
                            bridgeFileName = bridgeFileName,
                        }
                        module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.getModelsFn'
                        module.getModelsScript.params = {
                            bridgeFileName = bridgeFileName,
                        }

                        api.res.moduleRep.add(module.fileName, module, true)
                    end
                end
            end
--[[
            This works, but for now we let bridges be bridges and the rest be no bridges
            if bridgeCount > 1 then
                local module = api.type.ModuleDesc.new()
                module.fileName = 'station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic_NoBridge.module'

                module.availability.yearFrom = 0
                module.availability.yearTo = 0
                module.cost.price = 0

                module.description.name = _('NoBridge')
                module.description.description = _('NoBridge')
                module.description.icon = 'ui/lollo_freestyle_train_station/none.tga'
                -- if module.description.icon ~= "" then
                --     module.description.icon = string.gsub(module.description.icon, ".tga", "")
                --     module.description.icon = module.description.icon .. "_module" .. (catenary and "_catenary" or "") .. ".tga"
                -- end

                module.type = _constants.bridgeTypeModuleType
                -- bridgeCount = bridgeCount + 1
                module.order.value = 1
                module.metadata = { }
                module.category.categories = { "bridge-type", }

                module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.updateFn'
                module.updateScript.params = {
                    bridgeFileName = nil,
                }
                module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.getModelsFn'
                module.getModelsScript.params = {
                    bridgeFileName = nil,
                }

                api.res.moduleRep.add(module.fileName, module, true)
            end
]]
            -- This adds modules for tunnels to the freestyle station
            local tunnelFileNames = api.res.tunnelTypeRep.getAll()
            local tunnelCount = 1
            for tunnelTypeIndex, tunnelFileName in pairs(tunnelFileNames) do
                if type(tunnelTypeIndex) == 'number' and tunnelTypeIndex > -1 and api.res.tunnelTypeRep.isVisible(tunnelTypeIndex) then
                    local tunnel = api.res.tunnelTypeRep.get(tunnelTypeIndex)
                    if tunnel ~= nil and tunnel.name ~= nil and _getIsFitsRail(tunnel) then
                        local module = api.type.ModuleDesc.new()
                        module.fileName = 'station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic_' .. tostring(tunnelFileName) .. '.module'

                        module.availability.yearFrom = tunnel.yearFrom
                        module.availability.yearTo = tunnel.yearTo
                        module.cost.price = math.floor(tunnel.cost / 75 * 18000 + 0.5)

                        module.description.name = tunnel.name
                        module.description.description = tunnel.name
                        module.description.icon = tunnel.icon or 'ui/lollo_freestyle_train_station/none.tga'
                        -- if module.description.icon ~= "" then
                        --     module.description.icon = string.gsub(module.description.icon, ".tga", "")
                        --     module.description.icon = module.description.icon .. "_module" .. (catenary and "_catenary" or "") .. ".tga"
                        -- end

                        module.type = _constants.tunnelTypeModuleType
                        tunnelCount = tunnelCount + 1
                        module.order.value = tunnelCount
                        module.metadata = { }
                        module.category.categories = { "tunnel-type", }

                        module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic.updateFn'
                        module.updateScript.params = {
                            tunnelFileName = tunnelFileName,
                        }
                        module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic.getModelsFn'
                        module.getModelsScript.params = {
                            tunnelFileName = tunnelFileName,
                        }

                        api.res.moduleRep.add(module.fileName, module, true)
                    end
                end
            end
        end
    }
end
