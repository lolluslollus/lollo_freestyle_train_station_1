function data()
    local _arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
    local _constants = require('lollo_freestyle_train_station.constants')
    local _mdlHelpers = require('lollo_freestyle_train_station.mdlHelpers')
    local _stringUtils = require('lollo_freestyle_train_station.stringUtils')
    local _trackHelpers = require('lollo_freestyle_train_station.trackHelpers')

    return {
        info = {
            minorVersion = 171,
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
                local trackType = api.res.trackTypeRep.get(trackTypeIndex)
                if _trackHelpers.isPlatform2(trackType) then
                    platformFileNames[#platformFileNames+1] = trackFileName
                    -- local availability = _trackHelpers.getTrackAvailability(trackFileName)
                    -- trackType.yearFrom = availability.yearFrom -- we just change the value of the existing ref
                    -- -- trackType.yearTo = availability.yearTo -- idem
                    -- trackType.yearTo = 0 -- as of version 1.75, platforms never expire
                else
                    _trackHelpers.addCategory(trackType, _constants.trainTracksCategory)
                end
            end

            -- This is another way to clean the stock station construction menu, to make life easier for some other mods
            local moduleNames = api.res.moduleRep.getAll()
            for moduleIndex, moduleName in pairs(moduleNames) do
                if _stringUtils.stringStartsWith(moduleName, 'trainstation_') then
                    for __, platformFileName in pairs(platformFileNames) do
                        if _stringUtils.stringContains(moduleName, platformFileName) then
                            api.res.moduleRep.setVisible(moduleIndex, false)
                            break
                        end
                    end
                end
            end

            -- add dynamic modules for track, bridge and tunnel types
            local _barredTrackFileNameBits = {
                'ballast_standard',
                'mus_mock',
                'Seilbahn_Gleis',
                'ust_mock',
                'wk_track_dummy',
            }
            local _barredBridgeFileNameBits = {
                'Seilbahn_Bruecke',
            }
            local _barredTunnelFileNameBits = {
                'ust_void',
            }
            local _isStringContainsAny = function(str, list)
                for __, item in pairs(list) do
                    if _stringUtils.stringContains(str, item) then
                        return true
                    end
                end
                return false
            end

            local _isFitsRail = function(bridgeOrTunnel)
                if not(bridgeOrTunnel) or not(bridgeOrTunnel.carriers) then return false end

                for __, carrier in pairs(bridgeOrTunnel.carriers) do
                    if carrier == api.type.enum.Carrier.RAIL then return true end
                end
                return false
            end

            -- Add modules for modded tracks to the freestyle station
            local trackTypes_sorted = {}
            for typeIndex, fileName in pairs(trackFileNames) do
                if fileName ~= "standard.lua" and fileName ~= "high_speed.lua"
                and type(typeIndex) == 'number' and typeIndex > -1
                and api.res.trackTypeRep.isVisible(typeIndex)
                and type(fileName) == 'string'
                and not(_isStringContainsAny(fileName, _barredTrackFileNameBits))
                then
                    local props = api.res.trackTypeRep.get(typeIndex)
                    if props ~= nil
                    and not(_trackHelpers.isPlatform2(props))
                    and type(props.name) == 'string'
                    and props.desc ~= nil
                    and props.icon ~= nil
                    and props.yearTo ~= -1
                    then
                        trackTypes_sorted[#trackTypes_sorted+1] = {
                            typeIndex = typeIndex,
                            fileName = fileName,
                            name = (_(props.name) or ''),
                            props = props
                        }
                    end
                end
            end
            _arrayUtils.sort(trackTypes_sorted, 'name', true)
            -- print('### trackFileNames =') debugPrint(trackFileNames)
            -- print('### trackTypes_sorted =') debugPrint(trackTypes_sorted)
            local trackCount = 100
            for __, trackType in pairs(trackTypes_sorted) do
                local props = trackType.props
                local fileName = trackType.fileName
                for ___, catenary in pairs({false, true}) do
                    local module = api.type.ModuleDesc.new()
                    -- module.fileName = "trainstation_" .. tostring(trackFileName) .. (catenary and "catenary" or "")
                    module.fileName = 'station/rail/lollo_freestyle_train_station/trackTypes/dynamic_' .. (catenary and "catenary_" or "") .. tostring(fileName) .. '.module'

                    module.availability.yearFrom = props.yearFrom
                    module.availability.yearTo = props.yearTo
                    module.cost.price = math.floor(props.cost / 75 * 18000 + 0.5)

                    module.description.name = props.name .. (catenary and _(" with catenary") or "")
                    module.description.description = props.desc .. (catenary and _(" (with catenary)") or "")
                    module.description.icon = props.icon
                    -- if module.description.icon ~= "" then
                    --     module.description.icon = string.gsub(module.description.icon, ".tga", "")
                    --     module.description.icon = module.description.icon .. "_module" .. (catenary and "_catenary" or "") .. ".tga"
                    -- end

                    -- module.type = "track"
                    module.type = _constants.trackTypeModuleType
                    -- module.order.value = 0 + 10 * (catenary and 1 or 0)
                    module.order.value = trackCount
                    trackCount = trackCount + 1

                    module.metadata = {
                        -- track = true,
                    }
                    module.category.categories = { "track-type", }

                    -- module.updateScript.fileName = "construction/station/rail/modular_station/trackmodule.updateFn"
                    module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/trackTypes/dynamic.updateFn'
                    module.updateScript.params = {
                        trackType = fileName,
                        catenary = catenary
                    }
                    -- module.getModelsScript.fileName = "construction/station/rail/modular_station/trackmodule.getModelsFn"
                    module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/trackTypes/dynamic.getModelsFn'
                    module.getModelsScript.params = {
                        trackType = fileName,
                        catenary = catenary
                    }

                    api.res.moduleRep.add(module.fileName, module, true)
                end
            end

            -- Add modules for bridges (modded or not) to the freestyle station
            local bridgeFileNames = api.res.bridgeTypeRep.getAll()
            local bridgeTypes_sorted = {}
            for typeIndex, fileName in pairs(bridgeFileNames) do
                if type(typeIndex) == 'number' and typeIndex > -1
                and api.res.bridgeTypeRep.isVisible(typeIndex)
                and type(fileName) == 'string'
                and not(_isStringContainsAny(fileName, _barredBridgeFileNameBits))
                then
                    local props = api.res.bridgeTypeRep.get(typeIndex)
                    if props ~= nil
                    and type(props.name) == 'string'
                    and _isFitsRail(props)
                    then
                        bridgeTypes_sorted[#bridgeTypes_sorted+1] = {
                            typeIndex = typeIndex,
                            fileName = fileName,
                            name = (_(props.name) or ''),
                            props = props
                        }
                    end
                end
            end
            _arrayUtils.sort(bridgeTypes_sorted, 'name', true)
            local bridgeCount = 1
            for __, bridgeType in pairs(bridgeTypes_sorted) do
                local fileName = bridgeType.fileName
                local props = bridgeType.props
                local module = api.type.ModuleDesc.new()
                module.fileName = 'station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic_' .. tostring(fileName) .. '.module'

                module.availability.yearFrom = props.yearFrom
                module.availability.yearTo = props.yearTo
                module.cost.price = math.floor(props.cost / 75 * 18000 + 0.5)

                module.description.name = props.name
                module.description.description = props.name
                module.description.icon = props.icon or 'ui/lollo_freestyle_train_station/none.tga'

                module.type = _constants.bridgeTypeModuleType
                module.order.value = bridgeCount
                bridgeCount = bridgeCount + 1

                module.metadata = { }
                module.category.categories = { "bridge-type", }

                module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.updateFn'
                module.updateScript.params = {
                    bridgeFileName = fileName,
                }
                module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/bridgeTypes/dynamic.getModelsFn'
                module.getModelsScript.params = {
                    bridgeFileName = fileName,
                }

                api.res.moduleRep.add(module.fileName, module, true)
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
            -- Add modules for tunnels (modded or not) to the freestyle station
            local tunnelFileNames = api.res.tunnelTypeRep.getAll()
            local tunnelTypes_sorted = {}
            for typeIndex, fileName in pairs(tunnelFileNames) do
                if type(typeIndex) == 'number' and typeIndex > -1
                and api.res.tunnelTypeRep.isVisible(typeIndex)
                and type(fileName) == 'string'
                and not(_isStringContainsAny(fileName, _barredTunnelFileNameBits))
                then
                    local props = api.res.tunnelTypeRep.get(typeIndex)
                    if props ~= nil
                    and type(props.name) == 'string'
                    and _isFitsRail(props)
                    then
                        tunnelTypes_sorted[#tunnelTypes_sorted+1] = {
                            typeIndex = typeIndex,
                            fileName = fileName,
                            name = (_(props.name) or ''),
                            props = props
                        }
                    end
                end
            end
            _arrayUtils.sort(tunnelTypes_sorted, 'name', true)
            local tunnelCount = 1
            for __, tunnelType in pairs(tunnelTypes_sorted) do
                local fileName = tunnelType.fileName
                local props = tunnelType.props
                local module = api.type.ModuleDesc.new()
                module.fileName = 'station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic_' .. tostring(fileName) .. '.module'

                module.availability.yearFrom = props.yearFrom
                module.availability.yearTo = props.yearTo
                module.cost.price = math.floor(props.cost / 75 * 18000 + 0.5)

                module.description.name = props.name
                module.description.description = props.name
                module.description.icon = props.icon or 'ui/lollo_freestyle_train_station/none.tga'

                module.type = _constants.tunnelTypeModuleType

                module.order.value = tunnelCount
                tunnelCount = tunnelCount + 1

                module.metadata = { }
                module.category.categories = { "tunnel-type", }

                module.updateScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic.updateFn'
                module.updateScript.params = {
                    tunnelFileName = fileName,
                }
                module.getModelsScript.fileName = 'construction/station/rail/lollo_freestyle_train_station/tunnelTypes/dynamic.getModelsFn'
                module.getModelsScript.params = {
                    tunnelFileName = fileName,
                }

                api.res.moduleRep.add(module.fileName, module, true)
            end

            -- Add categories for bridges that haven't got any
            for bridgeTypeIndex, bridgeFileName in pairs(bridgeFileNames) do
                if type(bridgeTypeIndex) == 'number' and bridgeTypeIndex > -1
                and api.res.bridgeTypeRep.isVisible(bridgeTypeIndex)
                then
                    local bridgeType = api.res.bridgeTypeRep.get(bridgeTypeIndex)
                    if bridgeType ~= nil
                    -- and bridgeType.name ~= nil
                    and (bridgeType.categories == nil or #bridgeType.categories == 0)
                    --and _isFitsRail(bridgeType)
                    then
                        bridgeType.categories = {'misc'} -- misc is in the game already
                    end
                end
            end

            -- LOLLO NOTE
            -- I tried sorting the bridge type table alphabetically: it does not work.
            -- First try: this table does not retain the changes.
            -- Second try: changing trackType.new crashes.
            -- Bridge types are sorted by file name already, and their indexes do not reflect in the selection popup.
        end
    }
end
