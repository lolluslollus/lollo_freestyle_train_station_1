local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')

local private = {
    getLengthValues = function()
        local results = {}
        for i = 1, 40, 1 do
            results[#results+1] = tostring(i)
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
        add('lollo_freestyle_train_station/platformWalls/bricks/platformWall_5m.mdl', 'ui/lollo_freestyle_train_station/wallBricks.tga', _('WallBricksName'))
        add('lollo_freestyle_train_station/platformWalls/concrete_modern/wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallConcreteModern.tga', _("WallConcreteModernName"))
        add('lollo_freestyle_train_station/platformWalls/concrete_plain/platformWall_5m.mdl', 'ui/lollo_freestyle_train_station/wallConcretePlain.tga', _("WallConcretePlainName"))
        add('lollo_freestyle_train_station/platformWalls/iron/wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallIron.tga', _("WallIronName"))
        add('lollo_freestyle_train_station/platformWalls/iron_glass_copper/platformWall_5m.mdl', 'ui/lollo_freestyle_train_station/wallIronGlassCopper.tga', _("WallIronGlassCopperName"))
        add('lollo_freestyle_train_station/platformWalls/metal_glass/platformWall_5m.mdl', 'ui/lollo_freestyle_train_station/wallMetalGlass.tga', _("WallMetalGlassName"))
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs/modelled_wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallStaccionataFs.tga', _("WallStaccionataFsName"))
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs_tall/modelled_wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallStaccionataFsTall.tga', _("WallStaccionataFsTallName"))
        add('lollo_freestyle_train_station/platformWalls/tiled/platformWall_5m.mdl', 'ui/lollo_freestyle_train_station/wallTiled.tga', _("WallTiledName"))
        add('lollo_freestyle_train_station/platformWalls/tiled_large_stripes/wall_5m.mdl', 'ui/lollo_freestyle_train_station/wallTiledWLargeStripes.tga', _("WallTiledWLargeStripesName"))
        return results
    end,
}

return {
    getModelsWApi = function()
        local results = {}
        local add = function(fileName)
            local id = api.res.modelRep.find(fileName)
            if id < 0 then return false end

            local model = api.res.modelRep.get(id)
            if model == nil then return false end

            results[#results+1] = {
                fileName = fileName,
                icon = model.metadata.description.icon,
                id = id,
                name = model.metadata.description.name
            }
        end
        add('lollo_freestyle_train_station/platformWalls/bricks/platformWall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/concrete_modern/wall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/concrete_plain/platformWall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/iron/wall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/iron_glass_copper/platformWall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/metal_glass/platformWall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs/modelled_wall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/staccionata_fs_tall/modelled_wall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/tiled/platformWall_5m.mdl')
        add('lollo_freestyle_train_station/platformWalls/tiled_large_stripes/wall_5m.mdl')
        return results
    end,
    getModels = function()
        return private.getModels()
    end,
    getConParamsWApi = function (modelData)
        return {
            {
                defaultIndex = 0,
                key = 'lolloFenceAssets_model',
                name = _('fenceModelName'),
                values = arrayUtils.map(
                    modelData,
                    function(model)
                        -- return model.name
                        return model.icon
                    end
                ),
                uiType = 'ICON_BUTTON',
            },
            {
                defaultIndex = 0,
                key = 'lolloFenceAssets_wallEraPrefix',
                name = _('wallEraPrefix_0IsNoWall'),
                uiType = 'BUTTON',
                values = {_('NoWall'), 'A', 'B', 'C'},
            },
            {
                defaultIndex = 9,
                key = 'lolloFenceAssets_length',
                name = _('Length'),
                uiType = 'SLIDER',
                values = private.getLengthValues(),
            },
        }
    end,
    getConParams = function ()
        local models = private.getModels()
        return {
            {
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
                key = 'lolloFenceAssets_wallEraPrefix',
                name = _('wallEraPrefix_0IsNoWall'),
                uiType = 'BUTTON',
                values = {_('NoWall'), 'A', 'B', 'C'},
            },
            {
                defaultIndex = 9,
                key = 'lolloFenceAssets_length',
                name = _('Length'),
                uiType = 'SLIDER',
                values = private.getLengthValues(),
            },
        }
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
}
