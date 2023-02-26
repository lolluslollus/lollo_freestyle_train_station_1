local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local _extraHeight4Title = 100
local _extraHeight4Param = 40
local _conConfigLayoutIdPrefix = 'lollo_fence_con_config_layout_'

local _warningWindowWithGotoId = 'lollo_fence_warning_window_with_goto'

local _texts = {
    bulldoze = _('Bulldoze'),
    conConfigWindowTitle = _('ConConfigWindowTitle'),
    goBack = _('GoBack'),
    goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
    warningWindowTitle = _('WarningWindowTitle'),
}

local _windowXShift = 40
local _windowYShift = 40

local _getConstructionConfigLayout = function(conId, paramsMetadataSorted, paramValues, onParamValueChanged, isAddTitle, onBulldozeClicked)
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
        logger.print('addParam starting')
        if not(paramMetadata) or not(paramValue) then return end

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
            -- logger.print('button clicked')
            local buttonRowLayout = api.gui.comp.ToggleButtonGroup.new(api.gui.util.Alignment.HORIZONTAL, 0, true)
            buttonRowLayout:setGravity(0.5, 0) -- center horizontally
            buttonRowLayout:setOneButtonMustAlwaysBeSelected(true)
            buttonRowLayout:setEmitSignal(false)
            buttonRowLayout:onCurrentIndexChanged(
                function(newIndexBase0)
                    -- logger.print('buttonRowLayout:onCurrentIndexChanged, newIndexBase0 =', newIndexBase0 or 'NIL')
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
    for _, paramMetadata in pairs(paramsMetadataSorted) do
        for valueKey, value in pairs(paramValues) do
            if type(valueKey) == 'string' and valueKey == (paramMetadata.key) then
                addParam(valueKey, paramMetadata, value)
                break
            end
        end
    end
--[[
    if type(onBulldozeClicked) == 'function' then
        local bulldozeButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        bulldozeButtonLayout:addItem(api.gui.comp.ImageView.new('ui/cursors/bulldoze.tga'))
        bulldozeButtonLayout:addItem(api.gui.comp.TextView.new(_texts.bulldoze))
        local bulldozeButton = api.gui.comp.Button.new(bulldozeButtonLayout, true)
        bulldozeButton:onClick(
            function()
                if type(onBulldozeClicked) == 'function' then
                    onBulldozeClicked(conId)
                    -- window:setVisible(false, false) NO!
                end
            end
        )
        bulldozeButton:setGravity(0.5, 0)
        layout:addItem(bulldozeButton)
    end
]]
    return layout
end

local guiHelpers = {
    isShowingWarning = false,
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end,
    addConConfigToWindow = function(conId, handleParamValueChanged, conParamsMetadata, conParams, onBulldozeClicked)
        local conWindowId = 'temp.view.entity_' .. conId
        logger.print('conWindowId = \'' .. tostring(conWindowId) .. '\'')
        local window = api.gui.util.getById(conWindowId) -- eg temp.view.entity_26372
        local windowContent = window:getContent()
        -- local contentView = windowLayout:getItem(windowLayout:getNumItems() - 1)
        -- local layout = contentView:getLayout() -- :getItem(0)
        -- contentView:getLayout():getItem(0):setVisible(false, false)
        -- logger.print('oldLayoutId =', oldLayout:getId() or 'NIL')

        -- layout:addItem(newLayout, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        -- layout:addItem(newLayout, 1, 1)

        -- windowLayout:getItem(1):setEnabled(false) -- disables too much

        local newLayout = _getConstructionConfigLayout(conId, conParamsMetadata, conParams, handleParamValueChanged, true, onBulldozeClicked)
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
        -- logger.print('minSize =') logger.debugPrint(minSize)

        local extraHeight = _extraHeight4Title + arrayUtils.getCount(conParamsMetadata) * _extraHeight4Param
        local size = api.gui.util.Size.new(math.max(rect.w, minSize.w), math.max(rect.h, minSize.h) + extraHeight)
        window:setSize(size)
        window:setResizable(true)
    end,
}
---@param text string
---@param wrongObjectId? integer
---@param similarObjectsIds? table<integer>
guiHelpers.showWarningWithGoto = function(text, wrongObjectId, similarObjectsIds)
    logger.print('guiHelpers.showWarningWithGoto starting, text =', text or 'NIL')
    guiHelpers.isShowingWarningWithGoTo = true

    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_warningWindowWithGotoId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.warningWindowTitle, layout)
        window:setId(_warningWindowWithGotoId)
        logger.print('the window does not exist yet, _warningWindowWithGotoId =', _warningWindowWithGotoId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
        logger.print('the window exists already, _warningWindowWithGotoId =', _warningWindowWithGotoId)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    local function addGotoOtherObjectsButtons()
        if type(similarObjectsIds) ~= 'table' then return end

        local wrongObjectIdTolerant = wrongObjectId
        if not(edgeUtils.isValidAndExistingId(wrongObjectIdTolerant)) then wrongObjectIdTolerant = -1 end

        for _, otherObjectId in pairs(similarObjectsIds) do
            if otherObjectId ~= wrongObjectIdTolerant and edgeUtils.isValidAndExistingId(otherObjectId) then
                local otherObjectPosition = edgeUtils.getObjectPosition(otherObjectId)
                if otherObjectPosition ~= nil then
                    local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                    buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/locate_small.tga'))
                    buttonLayout:addItem(api.gui.comp.TextView.new(_texts.goThere))
                    local button = api.gui.comp.Button.new(buttonLayout, true)
                    button:onClick(
                        function()
                            -- UG TODO this dumps, ask UG to fix it
                            -- api.gui.util.CameraController:setCameraData(
                            --     api.type.Vec2f.new(otherObjectPosition[1], otherObjectPosition[2]),
                            --     100, 0, 0
                            -- )
                            -- x, y, distance, angleInRad, pitchInRad
                            guiHelpers.moveCamera(otherObjectPosition)
                            -- game.gui.setCamera({otherObjectPosition[1], otherObjectPosition[2], 100, 0, 0})
                        end
                    )
                    layout:addItem(button)
                end
            end
        end
    end
    local function addGoBackToWrongObjectButton()
        if not(edgeUtils.isValidAndExistingId(wrongObjectId)) then return end

        local wrongObjectPosition = edgeUtils.getObjectPosition(wrongObjectId)
        if wrongObjectPosition ~= nil then
            local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/arrow_style1_left.tga'))
            buttonLayout:addItem(api.gui.comp.TextView.new(_texts.goBack))
            local button = api.gui.comp.Button.new(buttonLayout, true)
            button:onClick(
                function()
                    -- UG TODO this dumps, ask UG to fix it
                    -- api.gui.util.CameraController:setCameraData(
                    --     api.type.Vec2f.new(wrongObjectPosition[1], wrongObjectPosition[2]),
                    --     100, 0, 0
                    -- )
                    -- x, y, distance, angleInRad, pitchInRad
                    guiHelpers.moveCamera(wrongObjectPosition)
                    -- game.gui.setCamera({wrongObjectPosition[1], wrongObjectPosition[2], 100, 0, 0})
                end
            )
            layout:addItem(button)
        end
    end
    addGotoOtherObjectsButtons()
    addGoBackToWrongObjectButton()

    window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    logger.print('window position (without shifts) =') logger.debugPrint(position)
    window:setPosition(position.x + _windowXShift, position.y + _windowYShift)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            logger.print('guiHelpers.showWarningWithGoto closing')
            guiHelpers.isShowingWarningWithGoTo = false
            window:setVisible(false, false)
        end
    )
end

return guiHelpers
