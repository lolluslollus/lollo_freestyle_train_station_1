local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')

local privateValues = {
    maxLength = 200,
    yShiftMaxIndex = 24,
    zDeltaMaxIndex = 64,
    zRotationMaxIndex = 64,
}
privateValues.defaults = {
    lolloFenceAssets_doTerrain = 0,
    lolloFenceAssets_length = 9,
    lolloFenceAssets_model = 1,
    lolloFenceAssets_wallEraPrefix = 0,
    lolloFenceAssets_wallBehindModel = 0,
    lolloFenceAssets_wallBehindInTunnels = 0,
    lolloFenceAssets_wallBehindOnBridges = 0,
    lolloFenceAssets_yShift = privateValues.yShiftMaxIndex + 5,
    lolloFenceAssets_zDelta = privateValues.zDeltaMaxIndex,
    lolloFenceAssets_zRotation = privateValues.zRotationMaxIndex,
}
local privateFuncs = {
    getLengthValues = function()
        local results = {}
        for i = 1, privateValues.maxLength, 1 do
            results[#results+1] = tostring(i)
        end
        return results
    end,
    getYShiftActualValues = function()
        local results = {}
        for i = -privateValues.yShiftMaxIndex, privateValues.yShiftMaxIndex, 1 do
            results[#results+1] = i / 2
        end
        return results
    end,
    getYShiftDisplayValues = function()
        local results = {}
        for i = -privateValues.yShiftMaxIndex, privateValues.yShiftMaxIndex, 1 do
            results[#results+1] = ("%.3g"):format(i / 2)
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
    getModels = function()
        local results = {}
        local add = function(modelFileName, iconFileName, name)
            results[#results+1] = {
                fileName = modelFileName,
                icon = iconFileName,
                -- id = id,
                name = name
            }
        end
        add(nil, 'ui/lollo_freestyle_train_station/none.tga', _('NoWallName'))
        add('lollo_freestyle_train_station/platformWalls/tiled/platformWall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallTiled.tga', _("WallTiledName"))
        add('lollo_freestyle_train_station/platformWalls/iron_glass_copper/platformWall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallIronGlassCopper.tga', _("WallIronGlassCopperName"))
        add('lollo_freestyle_train_station/platformWalls/iron/wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallIron.tga', _("WallIronName"))
        add('lollo_freestyle_train_station/platformWalls/arco_mattoni/wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallArcoMattoni.tga', _("WallArcoMattoniName"))
        add('lollo_freestyle_train_station/platformWalls/bricks/platformWall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallBricks.tga', _('WallBricksName'))
        add('lollo_freestyle_train_station/platformWalls/tunnely/wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallTunnely.tga', _('WallTunnelyName'))
        add('lollo_freestyle_train_station/platformWalls/concrete_plain/platformWall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallConcretePlain.tga', _("WallConcretePlainName"))
        add('lollo_freestyle_train_station/platformWalls/tiled_large_stripes/wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallTiledWLargeStripes.tga', _("WallTiledWLargeStripesName"))
        add('lollo_freestyle_train_station/platformWalls/concrete_modern/wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallConcreteModern.tga', _("WallConcreteModernName"))
        add('lollo_freestyle_train_station/platformWalls/metal_glass/platformWall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallMetalGlass.tga', _("WallMetalGlassName"))
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs/modelled_wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallStaccionataFs.tga', _("WallStaccionataFsName"))
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs_tall/modelled_wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallStaccionataFsTall.tga', _("WallStaccionataFsTallName"))
        return results
    end,
    getWallBehindModels = function()
        local results = {}
        local add = function(modelFileName, iconFileName, name)
            results[#results+1] = {
                fileName = modelFileName,
                icon = iconFileName,
                -- id = id,
                name = name
            }
        end
        add(nil, 'ui/lollo_freestyle_train_station/none.tga', _('NoWallName'))
        add('lollo_freestyle_train_station/platformWalls/behind/brick_wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallBricks.tga', _('WallBricksName'))
        add('lollo_freestyle_train_station/platformWalls/behind/tunnely_wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallBehindTunnely.tga', _('WallTunnelyName'))
        add('lollo_freestyle_train_station/platformWalls/behind/concrete_wall_low_5m.mdl', 'ui/lollo_freestyle_train_station/wallConcretePlain.tga', _("WallConcretePlainName"))
        return results
    end,
}

return {
    getModels = function()
        return privateFuncs.getModels()
    end,
    getWallBehindModels = function()
        return privateFuncs.getWallBehindModels()
    end,
    getConParams = function ()
        local models = privateFuncs.getModels()
        local wallBehindModels = privateFuncs.getWallBehindModels()
        return {
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_model,
                key = 'lolloFenceAssets_model',
                name = _('fenceModelName'),
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
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallEraPrefix,
                key = 'lolloFenceAssets_wallEraPrefix',
                name = _('wallEraPrefix_0IsNoWall'),
                uiType = 'BUTTON',
                values = {_('NoWall'), 'A', 'B', 'C'},
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallBehindModel,
                key = 'lolloFenceAssets_wallBehindModel',
                name = _('wallBehindModel_0IsNoWall'),
                values = arrayUtils.map(
                    wallBehindModels,
                    function(model)
                        -- return model.name
                        return model.icon
                    end
                ),
                uiType = 'ICON_BUTTON',
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_doTerrain,
                key = 'lolloFenceAssets_doTerrain',
                name = _('DoTerrain'),
                uiType = 'BUTTON',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_length,
                key = 'lolloFenceAssets_length',
                name = _('Length'),
                uiType = 'SLIDER',
                values = privateFuncs.getLengthValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_yShift,
                key = 'lolloFenceAssets_yShift',
                name = _('YShift'),
                uiType = 'SLIDER',
                values = privateFuncs.getYShiftDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_zRotation,
                key = 'lolloFenceAssets_zRotation',
                name = _('ZRotation'),
                uiType = 'SLIDER',
                values = privateFuncs.getZRotationDisplayValues(),
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_zDelta,
                key = 'lolloFenceAssets_zDelta',
                name = _('ZDelta'),
                uiType = 'SLIDER',
                values = privateFuncs.getZDeltaDisplayValues(),
            },
        }
    end,
    getChangeableParamsMetadata = function()
        local models = privateFuncs.getModels()
        local wallBehindModels = privateFuncs.getWallBehindModels()
        local metadata_sorted = {
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_model,
                key = 'lolloFenceAssets_model',
                name = _('fenceModelName'),
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
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallEraPrefix,
                key = 'lolloFenceAssets_wallEraPrefix',
                name = _('wallEraPrefix_0IsNoWall'),
                uiType = 'BUTTON',
                values = {_('NoWall'), 'A', 'B', 'C'},
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallBehindModel,
                key = 'lolloFenceAssets_wallBehindModel',
                name = _('wallBehindModel_0IsNoWall'),
                values = arrayUtils.map(
                    wallBehindModels,
                    function(model)
                        -- return model.name
                        return model.icon
                    end
                ),
                uiType = 'ICON_BUTTON',
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallBehindOnBridges,
                key = 'lolloFenceAssets_wallBehindOnBridges',
                name = _('wallBehind_isOnBridges'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_wallBehindInTunnels,
                key = 'lolloFenceAssets_wallBehindInTunnels',
                name = _('wallBehind_isInTunnels'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
            {
                defaultIndex = privateValues.defaults.lolloFenceAssets_doTerrain,
                key = 'lolloFenceAssets_doTerrain',
                name = _('DoTerrain'),
                uiType = 'CHECKBOX',
                values = {_('NO'), _('YES')}
            },
        }
        -- add defaultIndex wherever not present
        for _, record in pairs(metadata_sorted) do
            record.defaultIndex = record.defaultIndex or 0
        end
        local metadata_indexed = {}
        for _, record in pairs(metadata_sorted) do
            metadata_indexed[record.key] = record
        end
        -- logger.print('metadata_sorted =') logger.debugPrint(metadata_sorted)
        -- logger.print('metadata_indexed =') logger.debugPrint(metadata_indexed)
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
    getYShiftActualValues = function()
        return privateFuncs.getYShiftActualValues()
    end,
    getZDeltaActualValues = function()
        return privateFuncs.getZDeltaActualValues()
    end,
    getZRotationActualValues = function()
        return privateFuncs.getZRotationActualValues()
    end,
    getDefaultIndexes = function()
        return privateValues.defaults
    end
    -- getConstants = function()
    --     return privateValues
    -- end,
}
