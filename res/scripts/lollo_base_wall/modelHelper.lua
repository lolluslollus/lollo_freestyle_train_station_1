local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local constants = require('lollo_freestyle_train_station.constants')


local _platformHeightsSorted = {}
for _, plh in pairs(constants.platformHeights) do
    _platformHeightsSorted[#_platformHeightsSorted+1] = plh
end
arrayUtils.sort(_platformHeightsSorted, 'aboveRail', true)
local _getZShiftDefaultIndex = function()
    local index_base0 = 0
    for _, plh in pairs(_platformHeightsSorted) do
        if plh.aboveGround == constants.defaultPlatformHeight then return index_base0 end
        index_base0 = index_base0 + 1
    end
    return 0
end

local privateValues = {
    maxLength = 200,
    yShiftFineMaxIndex = 15,
    zDeltaMaxIndex = 64,
    zRotationMaxIndex = 64,
}
privateValues.defaults = {
    -- lolloBaseWallAssets_buildOnFrozenEdges = 0,
    lolloBaseWallAssets_doTerrain = 1,
    lolloBaseWallAssets_isDownToGround = 1,
    lolloBaseWallAssets_isSkewed = 0,
    lolloBaseWallAssets_isThick = 0,
    lolloBaseWallAssets_isYFlipped = 0,
    lolloBaseWallAssets_length = 9,
    lolloBaseWallAssets_model = 0,
    lolloBaseWallAssets_onlyOn = 0,
    lolloBaseWallAssets_yShiftFine = privateValues.yShiftFineMaxIndex,
    lolloBaseWallAssets_zDelta = privateValues.zDeltaMaxIndex,
    lolloBaseWallAssets_zRotation = privateValues.zRotationMaxIndex,
    lolloBaseWallAssets_zShift = _getZShiftDefaultIndex(),
}
local privateFuncs = {
    getLengthValues = function()
        local results = {}
        for i = 1, privateValues.maxLength, 1 do
            results[#results+1] = tostring(i)
        end
        return results
    end,
    getYShiftFineActualValues = function()
        local results = {}
        for i = -privateValues.yShiftFineMaxIndex, privateValues.yShiftFineMaxIndex, 1 do
            results[#results+1] = i * 0.1
        end
        return results
    end,
    getYShiftFineDisplayValues = function()
        local results = {}
        for i = -privateValues.yShiftFineMaxIndex, privateValues.yShiftFineMaxIndex, 1 do
            results[#results+1] = ("%.3g"):format(i * 0.1)
        end
        return results
    end,
    getZDeltaActualValues = function()
        local results = {}
        for i = -privateValues.zDeltaMaxIndex, privateValues.zDeltaMaxIndex, 1 do
            results[#results+1] = i / privateValues.zDeltaMaxIndex
        end
        return results
    end,
    getZDeltaDisplayValues = function()
        local results = {}
        for i = -privateValues.zDeltaMaxIndex, privateValues.zDeltaMaxIndex, 1 do
            results[#results+1] = ("%.3g %%"):format(i * 100 / privateValues.zDeltaMaxIndex)
        end
        return results
    end,
    getZRotationActualValues = function()
        local results = {}
        for i = -privateValues.zRotationMaxIndex, privateValues.zRotationMaxIndex, 1 do
            results[#results+1] = tostring(i * math.pi / 2 / privateValues.zRotationMaxIndex)
        end
        return results
    end,
    getZRotationDisplayValues = function()
        local results = {}
        for i = -privateValues.zRotationMaxIndex, privateValues.zRotationMaxIndex, 1 do
            results[#results+1] = ("%.2g °"):format(i / privateValues.zRotationMaxIndex * 90)
        end
        return results
    end,
    getZShiftActualValues = function()
        local results = {}
        for _, plh in pairs(_platformHeightsSorted) do
            results[#results+1] = plh.aboveGround - constants.defaultPlatformHeight
        end
        return results
    end,
    getZShiftDisplayValues = function()
        local results = {}
        for _, plh in pairs(_platformHeightsSorted) do
            results[#results+1] = ("%.3g m"):format(plh.aboveRail)
        end
        return results
    end,
    getModels = function(isThick)
        local results = {}
        local add = function(modelFileName, iconFileName, name)
            results[#results+1] = {
                fileName = modelFileName,
                icon = iconFileName,
                -- id = id,
                name = name
            }
        end

        if isThick then
            -- add(nil, 'ui/lollo_freestyle_train_station/none.tga', _('NoWallName'))
            add('lollo_freestyle_train_station/baseWalls/stone_brown_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneBrown.tga', _('WallStoneBrown'))
            add('lollo_freestyle_train_station/baseWalls/stone_grey_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneGrey.tga', _('WallStoneGrey'))
            add('lollo_freestyle_train_station/baseWalls/stone_orange_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneOrange.tga', _('WallStoneOrange'))
            add('lollo_freestyle_train_station/baseWalls/bricks_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseBricks.tga', _('WallBricksName'))
            add('lollo_freestyle_train_station/baseWalls/concrete_rough_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseConcreteRough.tga', _('WallConcreteRoughName'))
            add('lollo_freestyle_train_station/baseWalls/concrete_rough_light_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseConcreteRoughLight.tga', _('WallConcreteRoughLightName'))
            add('lollo_freestyle_train_station/baseWalls/tunnely_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallTunnely.tga', _('WallTunnelyName'))
            add('lollo_freestyle_train_station/baseWalls/tunnely_light_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallTunnelyLight.tga', _('WallTunnelyLightName'))
            add('lollo_freestyle_train_station/baseWalls/arco_mattoni_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/wallArcoMattoni.tga', _('WallArcoMattoniName'))
            add('lollo_freestyle_train_station/baseWalls/arco_concrete_rough_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/arco_concrete_rough_wall.tga', _('WallArcoConcreteRough'))
            add('lollo_freestyle_train_station/baseWalls/arco_concrete_rough_light_wall_2m_thick_4m.mdl', 'ui/lollo_freestyle_train_station/arco_concrete_rough_light_wall.tga', _('WallArcoConcreteRoughLight'))
        else
            -- add(nil, 'ui/lollo_freestyle_train_station/none.tga', _('NoWallName'))
            add('lollo_freestyle_train_station/baseWalls/stone_brown_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneBrown.tga', _('WallStoneBrown'))
            add('lollo_freestyle_train_station/baseWalls/stone_grey_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneGrey.tga', _('WallStoneGrey'))
            add('lollo_freestyle_train_station/baseWalls/stone_orange_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallStoneOrange.tga', _('WallStoneOrange'))
            add('lollo_freestyle_train_station/baseWalls/bricks_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseBricks.tga', _('WallBricksName'))
            add('lollo_freestyle_train_station/baseWalls/concrete_rough_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseConcreteRough.tga', _('WallConcreteRoughName'))
            add('lollo_freestyle_train_station/baseWalls/concrete_rough_light_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallBaseConcreteRoughLight.tga', _('WallConcreteRoughLightName'))
            add('lollo_freestyle_train_station/baseWalls/tunnely_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallTunnely.tga', _('WallTunnelyName'))
            add('lollo_freestyle_train_station/baseWalls/tunnely_light_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallTunnelyLight.tga', _('WallTunnelyLightName'))
            add('lollo_freestyle_train_station/baseWalls/arco_mattoni_wall_4m.mdl', 'ui/lollo_freestyle_train_station/wallArcoMattoni.tga', _('WallArcoMattoniName'))
            add('lollo_freestyle_train_station/baseWalls/arco_concrete_rough_wall_4m.mdl', 'ui/lollo_freestyle_train_station/arco_concrete_rough_wall.tga', _('WallArcoConcreteRough'))
            add('lollo_freestyle_train_station/baseWalls/arco_concrete_rough_light_wall_4m.mdl', 'ui/lollo_freestyle_train_station/arco_concrete_rough_light_wall.tga', _('WallArcoConcreteRoughLight'))
        end
        return results
    end,
}

return {
    getModels = function(isThick)
        return privateFuncs.getModels(isThick)
    end,
    getConParams = function ()
        local models = privateFuncs.getModels()
        return {
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_model,
                key = 'lolloBaseWallAssets_model',
                name = _('wallModelName'),
                values = arrayUtils.map(
                    models,
                    function(model)
                        -- return model.name
                        return model.icon
                    end
                ),
                uiType = 'ICON_BUTTON',
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isThick',
                name = _('baseWall_isThick'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isSkewed',
                name = _('baseWall_isSkewed'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isDownToGround',
                name = _('isDownToGround'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isYFlipped,
                key = 'lolloBaseWallAssets_isYFlipped',
                name = _('isFlipped'),
                tooltip = _('isFlippedTooltip'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_doTerrain,
                key = 'lolloBaseWallAssets_doTerrain',
                name = _('DoTerrain'),
                uiType = 'BUTTON',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_length,
                key = 'lolloBaseWallAssets_length',
                name = _('Length'),
                uiType = 'SLIDER',
                values = privateFuncs.getLengthValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_yShiftFine,
                key = 'lolloBaseWallAssets_yShiftFine',
                name = _('YShiftFine'),
                uiType = 'SLIDER',
                values = privateFuncs.getYShiftFineDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_zRotation,
                key = 'lolloBaseWallAssets_zRotation',
                name = _('ZRotation'),
                uiType = 'SLIDER',
                values = privateFuncs.getZRotationDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_zDelta,
                key = 'lolloBaseWallAssets_zDelta',
                name = _('ZDelta'),
                uiType = 'SLIDER',
                values = privateFuncs.getZDeltaDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_zShift,
                key = 'lolloBaseWallAssets_zShift',
                name = _('ZShift'),
                uiType = 'BUTTON',
                values = privateFuncs.getZShiftDisplayValues(),
            },
        }
    end,
    getChangeableParamsMetadata = function()
        local models = privateFuncs.getModels()
        local metadata_sorted = {
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_model,
                key = 'lolloBaseWallAssets_model',
                name = _('wallModelName'),
                values = arrayUtils.map(
                    models,
                    function(model)
                        -- return model.name
                        return model.icon
                    end
                ),
                uiType = 'ICON_BUTTON',
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isThick',
                name = _('baseWall_isThick'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isSkewed',
                name = _('baseWall_isSkewed'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isDownToGround,
                key = 'lolloBaseWallAssets_isDownToGround',
                name = _('isDownToGround'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_isYFlipped,
                key = 'lolloBaseWallAssets_isYFlipped',
                name = _('isFlipped'),
                tooltip = _('isFlippedTooltip'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_onlyOn,
                key = 'lolloBaseWallAssets_onlyOn',
                name = _('baseWall_onlyOn'),
                uiType = 'BUTTON',
                values = {_('baseWall_onlyOnBridgesGround'), _('baseWall_onlyOnBridges'), _('baseWall_onlyOnGround')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_doTerrain,
                key = 'lolloBaseWallAssets_doTerrain',
                name = _('DoTerrain'),
                uiType = 'BUTTON',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_yShiftFine,
                key = 'lolloBaseWallAssets_yShiftFine',
                name = _('YShiftAuto'),
                uiType = 'SLIDER',
                values = privateFuncs.getYShiftFineDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloBaseWallAssets_zShift,
                key = 'lolloBaseWallAssets_zShift',
                name = _('ZShift'),
                uiType = 'BUTTON',
                values = privateFuncs.getZShiftDisplayValues(),
            },
            -- there is no way yet to accurately find out if an edge is frozen without the api:
            -- I often add or remove one metre, unless I rewrite getCentralEdgePositions_OnlyOuterBounds
            -- {
            --     defaultIndex = privateValues.defaults.lolloBaseWallAssets_buildOnFrozenEdges,
            --     key = 'lolloBaseWallAssets_buildOnFrozenEdges',
            --     name = _('BuildOnStations'),
            --     uiType = 'CHECKBOX',
            --     values = {_('NO'), _('YES')}
            -- },
        }
        -- add defaultIndex wherever not present
        for _, record in pairs(metadata_sorted) do
            record.defaultIndex = record.defaultIndex or 0
        end
        local metadata_indexed = {}
        for _, record in pairs(metadata_sorted) do
            metadata_indexed[record.key] = record
        end
        -- logger.infoOut('metadata_sorted =', metadata_sorted})
        -- logger.infoOut('metadata_indexed =', metadata_indexed})
        return metadata_sorted, metadata_indexed
    end,
    getUiTypeNumber = function(uiTypeStr)
        if uiTypeStr == 'BUTTON' then return 0
        elseif uiTypeStr == 'SLIDER' then return 1
        elseif uiTypeStr == 'COMBOBOX' then return 2
        elseif uiTypeStr == 'ICON_BUTTON' then return 3 -- double-check this
        elseif uiTypeStr == 'CHECKBOX' then return 4 -- double-check this
        else return 0
        end
    end,
    getYShiftFineActualValues = function()
        return privateFuncs.getYShiftFineActualValues()
    end,
    getZDeltaActualValues = function()
        return privateFuncs.getZDeltaActualValues()
    end,
    getZRotationActualValues = function()
        return privateFuncs.getZRotationActualValues()
    end,
    getZShiftActualValues = function()
        return privateFuncs.getZShiftActualValues()
    end,
    getDefaultIndexes = function()
        return privateValues.defaults
    end
    -- getConstants = function()
    --     return privateValues
    -- end,
}
