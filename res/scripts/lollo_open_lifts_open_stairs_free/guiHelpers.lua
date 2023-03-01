local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
-- local constants = require('lollo_freestyle_train_station.constants')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local _extraHeight4Title = 100
local _extraHeight4Param = 40
local _conConfigLayoutIdPrefix = 'lollo_stairs_con_config_layout_'

local _texts = {
    conConfigWindowTitle = _('ConSettingsWindowTitle'),
    goBack = _('GoBack'),
    goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
    warningWindowTitle = _('WarningWindowTitle'),
}

local _windowXShift = 40
local _windowYShift = 40

local guiHelpers = {
    isShowingWarning = false,
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end
}

local _getConstructionConfigLayout = function(conId, paramsMetadataSorted, paramValues, onParamValueChanged, isAddTitle)
    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    layout:setId(_conConfigLayoutIdPrefix .. conId)

    if isAddTitle then
        local br = api.gui.comp.TextView.new('')
        br:setGravity(0.5, 0)
        layout:addItem(br)
        local title = api.gui.comp.TextView.new(_texts.conConfigWindowTitle)
        title:setGravity(0.5, 0)
        layout:addItem(title)
    end

    local function addParam(paramKey, paramMetadata, paramValue)
        logger.print('addParam starting, paramKey =', paramKey or 'NIL')
        if not(paramKey) or not(paramMetadata) or not(paramValue) then return end

        local paramNameTextBox = api.gui.comp.TextView.new(paramMetadata.name)
        if type(paramMetadata.tooltip) == 'string' and paramMetadata.tooltip:len() > 0 then
            paramNameTextBox:setTooltip(paramMetadata.tooltip)
        end
        layout:addItem(paramNameTextBox)
        local _valueIndexBase0 = paramValue or (paramMetadata.defaultIndex or 0)
        logger.print('_valueIndexBase0 =', _valueIndexBase0)
        if paramMetadata.uiType == 'ICON_BUTTON' then
            local buttonRowLayout = api.gui.comp.ToggleButtonGroup.new(api.gui.util.Alignment.HORIZONTAL, 0, true)
            buttonRowLayout:setGravity(0.5, 0) -- center horizontally
            buttonRowLayout:setOneButtonMustAlwaysBeSelected(true)
            buttonRowLayout:setEmitSignal(false)
            buttonRowLayout:onCurrentIndexChanged(
                function(newIndexBase0)
                    onParamValueChanged(conId, paramsMetadataSorted, paramKey, newIndexBase0)
                end
            )
            for indexBase1, value in pairs(paramMetadata.values) do
                local button = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new(value))
                buttonRowLayout:add(button)
                if indexBase1 -1 == _valueIndexBase0 then
                    button:setSelected(true, false)
                end
            end
            layout:addItem(buttonRowLayout)
        elseif paramMetadata.uiType == 'COMBOBOX' then
            local comboBox = api.gui.comp.ComboBox.new()
            comboBox:setGravity(0.5, 0) -- center horizontally
            for _, value in pairs(paramMetadata.values) do
                comboBox:addItem(value)
            end
            if comboBox:getNumItems() > _valueIndexBase0 then -- a simple validation
                comboBox:setSelected(_valueIndexBase0, false)
            end
            comboBox:onIndexChanged(
                function(indexBase0)
                    logger.print('comboBox:onIndexChanged firing, one =') logger.debugPrint(indexBase0)
                    onParamValueChanged(conId, paramsMetadataSorted, paramKey, indexBase0)
                end
            )
            layout:addItem(comboBox)
        elseif paramMetadata.uiType == 'SLIDER' then
            -- logger.print('paramMetadata =') logger.debugPrint(paramMetadata)
            local slider = api.gui.comp.Slider.new(true)
            slider:setGravity(0.5, 0) -- center horizontally
            local max = tonumber(paramMetadata.values[#paramMetadata.values], 10)
            local min = tonumber(paramMetadata.values[1], 10)
            local step = #paramMetadata.values > 1 and ((max-min) / (#paramMetadata.values - 1)) or 1
            -- logger.print('slider.min, max, step =', min, max, step, type(min), type(max), type(step))
            slider:setMaximum(max)
            slider:setMinimum(min)
            slider:setPageStep(step)
            slider:setStep(step)

            -- logger.print('#values, first value = ', #paramMetadata.values, paramMetadata.values[1])
            -- logger.print('first slider:getValue() =', slider:getValue(), type(slider:getValue()))
            if #paramMetadata.values > _valueIndexBase0 -- a simple validation
            and 0 <= _valueIndexBase0 then
                slider:setValue(tonumber(paramMetadata.values[_valueIndexBase0 + 1], 10), false)
                -- logger.print('second slider:getValue() =', slider:getValue(), type(slider:getValue()))
            end
            slider:onValueChanged(
                function(newValue)
                    local newValueIndexBase0 = math.floor(((newValue or 0) - min) / step)
                    -- logger.print('slider:onValueChanged firing, newValue =') logger.debugPrint(newValue)
                    -- logger.print('third slider:getValue() =', slider:getValue(), type(slider:getValue()))
                    -- logger.print('slider:getStep() =', slider:getStep(), type(slider:getStep()))
                    -- logger.print('slider:getPageStep() =', slider:getStep(), type(slider:getPageStep()))
                    -- logger.print('newValueIndexBase0 =', newValueIndexBase0)
                    onParamValueChanged(conId, paramsMetadataSorted, paramKey, newValueIndexBase0)
                end
            )
            slider:setMinimumSize(api.gui.util.Size.new(360, 40))
            layout:addItem(slider)
        else -- BUTTON or anything else
            local buttonRowLayout = api.gui.comp.ToggleButtonGroup.new(api.gui.util.Alignment.HORIZONTAL, 0, true)
            buttonRowLayout:setGravity(0.5, 0) -- center horizontally
            buttonRowLayout:setOneButtonMustAlwaysBeSelected(true)
            buttonRowLayout:setEmitSignal(false)
            buttonRowLayout:onCurrentIndexChanged(
                function(newIndexBase0)
                    onParamValueChanged(conId, paramsMetadataSorted, paramKey, newIndexBase0)
                end
            )
            for indexBase1, value in pairs(paramMetadata.values) do
                local button = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new(value))
                buttonRowLayout:add(button)
                if indexBase1 -1 == _valueIndexBase0 then
                    button:setSelected(true, false)
                end
            end
            layout:addItem(buttonRowLayout)
        end
    end
    -- logger.print('paramsMetadata =') logger.debugPrint(paramsMetadata)
    -- logger.print('paramValues =') logger.debugPrint(paramValues)
    for _, paramMetadata in pairs(paramsMetadataSorted) do
        for valueKey, value in pairs(paramValues) do
            if valueKey == paramMetadata.key then
                addParam(valueKey, paramMetadata, value)
                break
            end
        end
    end

    return layout
end

guiHelpers.addConConfigToWindow = function(conId, handleParamValueChanged, conParamsMetadata, conParams)
    local conWindowId = 'temp.view.entity_' .. conId
    print('conWindowId = \'' .. tostring(conWindowId) .. '\'')
    local window = api.gui.util.getById(conWindowId) -- eg temp.view.entity_26372
    local windowContent = window:getContent()
    -- local contentView = windowLayout:getItem(windowLayout:getNumItems() - 1)
    -- local layout = contentView:getLayout() -- :getItem(0)
    -- contentView:getLayout():getItem(0):setVisible(false, false)
    -- print('oldLayoutId =', oldLayout:getId() or 'NIL')

    -- layout:addItem(newLayout, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
    -- layout:addItem(newLayout, 1, 1)

    -- windowLayout:getItem(1):setEnabled(false) -- disables too much

    local newLayout = _getConstructionConfigLayout(conId, conParamsMetadata, conParams, handleParamValueChanged, true)
    local parentLayout = windowContent:getName() == 'ConstructionContent' and windowContent:getLayout() or windowContent
    local configureButtonIndex = windowContent:getName() == 'ConstructionContent' and 0 or 1
    -- if windowContent:getName() == 'ConstructionContent' then
    --     windowLayout:getLayout():getItem(0):setVisible(false, false) -- hide the "configure' button" without emitting a signal
    --     windowLayout:getLayout():addItem(newLayout)
    -- end
    parentLayout:getItem(configureButtonIndex):setVisible(false, false) -- hide the "configure' button" without emitting a signal

    for i = 0, parentLayout:getNumItems() - 1, 1 do
        local item = parentLayout:getItem(i)
        if item ~= nil and type(item.getId) == 'function' and stringUtils.stringStartsWith(item:getId() or '', _conConfigLayoutIdPrefix) then
            logger.print('one of my menus is already in the window, about to remove it')
            parentLayout:removeItem(item)
            logger.print('about to reset its id')
            if type(item.setId) == 'function' then item:setId('') end
            logger.print('about to call destroy')
            -- api.gui.util.destroyLater(item) -- this errors out
            item:destroy()
            logger.print('called destroy')
        end
    end

    parentLayout:addItem(newLayout)
    parentLayout:setGravity(0, 0) -- center top left

    local rect = window:getContentRect() -- this is mostly 0, 0 at this point
    local minSize = window:calcMinimumSize()
    -- logger.print('rect =') logger.debugPrint(rect)
    logger.print('minSize =') logger.debugPrint(minSize)

    local extraHeight = _extraHeight4Title + arrayUtils.getCount(conParamsMetadata) * _extraHeight4Param
    local size = api.gui.util.Size.new(math.max(rect.w, minSize.w), math.max(rect.h, minSize.h) + extraHeight)
    window:setSize(size)
    window:setResizable(true)
end

return guiHelpers
