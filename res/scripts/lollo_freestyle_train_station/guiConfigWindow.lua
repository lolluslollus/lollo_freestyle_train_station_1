local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
-- local constants = require('lollo_freestyle_train_station.constants')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local guiHelpers = require('lollo_freestyle_train_station.guiHelpers')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local samplePrivateData = {
    -- constants
    conConfigLayoutIdPrefix = 'lollo_stairs_con_config_layout_',
    warningWindowWithGotoId = 'lollo_stairs_warning_window_with_goto',

    texts = {
        bulldoze = _('Bulldoze'),
        bulldozeAll = _('BulldozeAll'),
        conConfigWindowTitle = _('ConConfigWindowTitle'),
        goBack = _('GoBack'),
        goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
        warningWindowTitle = _('WarningWindowTitle'),
    },

    extraHeight4Param = 40, -- half the height of module icons, which we reuse here
    extraHeight4Window = 50,
    extraWidth4Window = 20,
    minWindowWidth = 490,
    windowXShift = -60,
    windowYShift = 20,

    -- attributes
    isShowingWarning = false,
}

return {
    ---ctor
    ---@param configLayoutIdPrefix string
    ---@param warningWindowWithGotoId string
    ---@param texts table<string, string>
    ---@param windowXShift? number
    ---@param windowYShift? number
    ---@return table
    new = function(configLayoutIdPrefix, warningWindowWithGotoId, texts, windowXShift, windowYShift)
        local self = {
            privateData = {
                conConfigLayoutIdPrefix = configLayoutIdPrefix,
                warningWindowWithGotoId = warningWindowWithGotoId,
                texts = texts,
                extraHeight4Window = samplePrivateData.extraHeight4Window,
                extraHeight4Param = samplePrivateData.extraHeight4Param,
                extraWidth4Window = samplePrivateData.extraWidth4Window,
                minWindowWidth = samplePrivateData.minWindowWidth,
                windowXShift = windowXShift or samplePrivateData.windowXShift,
                windowYShift = windowYShift or samplePrivateData.windowYShift,
            }
        }

        self.privateFuncs = {
            getConstructionConfigList = function(entityId, paramsMetadataSorted, paramValues, onParamValueChanged, isAddTitle, onBulldozeClicked)
                local mainLayout = api.gui.layout.BoxLayout.new('VERTICAL')

                if isAddTitle then
                    -- local br = api.gui.comp.TextView.new('')
                    -- br:setGravity(0.5, 0)
                    -- mainLayout:addItem(br)
                    local title = api.gui.comp.TextView.new('- ' .. self.privateData.texts.conConfigWindowTitle .. (entityId or '') .. ' -')
                    title:setGravity(0.5, 0)
                    mainLayout:addItem(title)
                end

                local function addParam(paramKey, paramMetadata, paramValue)
                    logger.infoOut('addParam starting, paramKey =', paramKey)
                    if not(paramKey) or not(paramMetadata) or not(paramMetadata.values) or not(paramValue) then return end

                    local paramNameTextBox = api.gui.comp.TextView.new(paramMetadata.name)
                    if type(paramMetadata.tooltip) == 'string' and paramMetadata.tooltip:len() > 0 then
                        paramNameTextBox:setTooltip(paramMetadata.tooltip)
                    end
                    local textBoxLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                    textBoxLayout:addItem(paramNameTextBox)
                    local textBoxComponent = api.gui.comp.Component.new('')
                    textBoxComponent:setLayout(textBoxLayout)
                    mainLayout:addItem(textBoxComponent)

                    local _valueIndexBase0 = paramValue or (paramMetadata.defaultIndex or 0)
                    logger.infoOut('_valueIndexBase0 =', _valueIndexBase0)
                    if paramMetadata.uiType == 'ICON_BUTTON' then
                        local buttonRow = api.gui.comp.ToggleButtonGroup.new(api.gui.util.Alignment.HORIZONTAL, 0, true)
                        buttonRow:setGravity(0.5, 0) -- center horizontally
                        buttonRow:setOneButtonMustAlwaysBeSelected(true)
                        buttonRow:setEmitSignal(false)
                        buttonRow:onCurrentIndexChanged(
                            function(newIndexBase0)
                                onParamValueChanged(entityId, paramsMetadataSorted, paramKey, newIndexBase0)
                            end
                        )
                        for indexBase1, value in pairs(paramMetadata.values) do
                            -- logger.infoOut('### paramMetadata =', paramMetadata})
                            local imageView = api.gui.comp.ImageView.new(value)
                            imageView:setMaximumSize(api.gui.util.Size.new(self.privateData.extraHeight4Param, self.privateData.extraHeight4Param))
                            local button = api.gui.comp.ToggleButton.new(imageView)
                            buttonRow:add(button)
                            if indexBase1 -1 == _valueIndexBase0 then
                                button:setSelected(true, false)
                            end
                        end
                        mainLayout:addItem(buttonRow)
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
                                logger.infoOut('comboBox:onIndexChanged firing, one =', indexBase0)
                                onParamValueChanged(entityId, paramsMetadataSorted, paramKey, indexBase0)
                            end
                        )
                        mainLayout:addItem(comboBox)
                    elseif paramMetadata.uiType == 'SLIDER' then
                        logger.infoOut('paramMetadata =', paramMetadata)
                        local sliderValueView = api.gui.comp.TextView.new(tostring(paramMetadata.values[_valueIndexBase0 + 1]))
                        sliderValueView:setGravity(0.5, 0) -- center horizontally
                        local slider = api.gui.comp.Slider.new(true) -- true means horizontal
                        slider:setGravity(0.5, 0) -- center horizontally
                        slider:setMaximum(math.max(#paramMetadata.values -1, 1))
                        slider:setMinimum(0)
                        slider:setStep(1)
                        slider:setValue(_valueIndexBase0, false)
                        slider:onValueChanged(
                            function(newValueIndexBase0)
                                logger.infoOut('slider emitted newValue =', newValueIndexBase0)
                                sliderValueView:setText(tostring(paramMetadata.values[newValueIndexBase0 + 1]))
                                onParamValueChanged(entityId, paramsMetadataSorted, paramKey, newValueIndexBase0)
                            end
                        )
                        slider:setMinimumSize(api.gui.util.Size.new(self.privateData.minWindowWidth, 20))

                        local sliderLayout = api.gui.layout.BoxLayout.new('VERTICAL')
                        sliderLayout:addItem(slider)
                        sliderLayout:addItem(sliderValueView)

                        local sliderComponent = api.gui.comp.Component.new('')
                        sliderComponent:setLayout(sliderLayout)
                        mainLayout:addItem(sliderComponent)
                    elseif paramMetadata.uiType == 'CHECKBOX' then
                        local checkbox = api.gui.comp.CheckBox.new('', 'ui/design/components/checkbox_invalid.tga', 'ui/design/components/checkbox_valid.tga')
                        checkbox:setGravity(0.5, 0) -- center horizontally
                        checkbox:onToggle(
                            function(isSelected)
                                -- logger.thingOut('checkbox selected = ' .. tostring(isSelected))
                                onParamValueChanged(entityId, paramsMetadataSorted, paramKey, isSelected and 1 or 0)
                            end
                        )
                        checkbox:setSelected(paramValue == 1, false)
                        textBoxLayout:addItem(checkbox)
                    else -- BUTTON or anything else
                        -- logger.infoOut('button clicked')
                        local buttonRow = api.gui.comp.ToggleButtonGroup.new(api.gui.util.Alignment.HORIZONTAL, 0, true)
                        buttonRow:setGravity(0.5, 0) -- center horizontally
                        buttonRow:setOneButtonMustAlwaysBeSelected(true)
                        buttonRow:setEmitSignal(false)
                        buttonRow:onCurrentIndexChanged(
                            function(newIndexBase0)
                                -- logger.infoOut('buttonRowLayout:onCurrentIndexChanged, newIndexBase0 =', newIndexBase0})
                                onParamValueChanged(entityId, paramsMetadataSorted, paramKey, newIndexBase0)
                            end
                        )
                        for indexBase1, value in pairs(paramMetadata.values) do
                            local button = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new(value))
                            buttonRow:add(button)
                            if indexBase1 -1 == _valueIndexBase0 then
                                button:setSelected(true, false)
                            end
                        end
                        mainLayout:addItem(buttonRow)
                    end
                end
                -- logger.infoOut('paramValues =', paramValues})
                for _, paramMetadata in pairs(paramsMetadataSorted) do
                    local isFound = false
                    for valueKey, value in pairs(paramValues) do
                        if valueKey == paramMetadata.key then
                            addParam(valueKey, paramMetadata, value)
                            isFound = true
                            break
                        end
                    end
                    -- allow adding new params to old cons that did not have them
                    if not(isFound) and paramMetadata ~= nil and paramMetadata.key ~= nil then
                        logger.infoOut('new param found, paramMetadata.key =', paramMetadata.key)
                        addParam(paramMetadata.key, paramMetadata, paramMetadata.defaultIndex)
                    end
                end

                if type(onBulldozeClicked) == 'function' then
                    local bulldozeButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                    bulldozeButtonLayout:addItem(api.gui.comp.ImageView.new('ui/cursors/bulldoze.tga'))
                    bulldozeButtonLayout:addItem(api.gui.comp.TextView.new(self.privateData.texts.bulldoze))
                    local bulldozeButton = api.gui.comp.Button.new(bulldozeButtonLayout, true)
                    bulldozeButton:onClick(
                        function()
                            if type(onBulldozeClicked) == 'function' then
                                local gameUI = api.gui.util.getGameUI()
                                if gameUI and gameUI.playSoundEffect then
                                    -- gameUI:playSoundEffect('bulldozeMedium')
                                    gameUI:playSoundEffect('bulldozeLarge')
                                end
                                onBulldozeClicked(entityId)
                                -- window:setVisible(false, false) NO!
                            end
                        end
                    )
                    bulldozeButton:setGravity(0.5, 0.0)
                    mainLayout:addItem(bulldozeButton)
                end

                local resultComponent = api.gui.comp.Component.new('')
                resultComponent:setLayout(mainLayout)
                return resultComponent
            end,
            getListId = function(entityId)
                return self.privateData.conConfigLayoutIdPrefix .. entityId
            end,
            moveCamera = function(position)
                local cameraData = game.gui.getCamera()
                game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
            end,
        }

        self.addEntityConfigToWindow = function(entityId, handleParamValueChanged, conParamsMetadata, conParams, onBulldozeClicked)
            local _conWindowId = 'temp.view.entity_' .. entityId
            logger.infoOut('conWindowId = \'', _conWindowId, '\'')
            local _window = api.gui.util.getById(_conWindowId) -- eg temp.view.entity_26372
            if _window == nil then logger.errorOut('cannot get config window by id') return end

            local _windowOldContent = _window:getContent()
            if _windowOldContent ~= nil and type(_windowOldContent.getId) == 'function' and _windowOldContent:getId() == self.privateFuncs.getListId(entityId) then
                logger.infoOut('### window with content with old id')
                -- these crash:
                -- if windowOldContent ~= nil and type(windowOldContent.destroy) == 'function' then logger.thingOut('### about to destroy') windowOldContent:destroy() end
                -- if windowOldContent ~= nil and type(windowOldContent.destroy) == 'function' then logger.thingOut('### about to destroy') api.gui.util.destroyLater(windowOldContent) end
            else
                logger.infoOut('### window with content with new id')
                local _gameGUI = api.gui.util.getGameUI()
                if _gameGUI == nil or type(_gameGUI.getContentRect) ~= 'function' then
                    logger.errorOut('no game GUI found')
                    return
                end
                local _GUIContentRect = _gameGUI:getContentRect()
                if _GUIContentRect == nil or type(_GUIContentRect.w) ~= 'number' then
                    logger.errorOut('no game GUI content rectangle found')
                    return
                end
                local _configComponent = self.privateFuncs.getConstructionConfigList(entityId, conParamsMetadata, conParams, handleParamValueChanged, true, onBulldozeClicked)
                if _configComponent == nil then
                    logger.errorOut('no config component')
                    return
                end

                _configComponent:setGravity(0.0, -1)
                local _configWrapper = api.gui.comp.ScrollArea.new(_configComponent, '')
                -- ALWAYS_OFF, ALWAYS_ON, AS_NEEDED, SIMPLE
                _configWrapper:setHorizontalScrollBarPolicy(api.gui.comp.ScrollBarPolicy.SIMPLE)
                -- _configWrapper:ensureVisible(_configComponent)
                _configWrapper:setGravity(0.0, -1)
                _configWrapper:setId(self.privateFuncs.getListId(entityId))
                _window:setContent(_configWrapper)
                local _wrapperContentSize = _configWrapper:calcMinimumSize()
                local _windowSize = api.gui.util.Size.new(
                    math.max(self.privateData.minWindowWidth, _wrapperContentSize.w) + self.privateData.extraWidth4Window,
                    _wrapperContentSize.h + self.privateData.extraHeight4Window
                )
                _window:setSize(_windowSize)
                guiHelpers.setWindowPosition(
                    _window,
                    {
                        x = _GUIContentRect.w + self.privateData.windowXShift - _windowSize.w,
                        y = self.privateData.windowYShift
                    }
                )
            end
            _window:setResizable(true)
            -- _window:setAttached(false)
            -- _window:setPinned(false)
        end
        self.isShowingWarning = self.privateData.isShowingWarning
        ---@param text string
        ---@param wrongObjectId? integer
        ---@param similarObjectsIds? table<integer>
        self.showWarningWithGoto = function(text, wrongObjectId, similarObjectsIds, removeAllFunc)
            logger.infoOut('guiHelpers.showWarningWithGoto starting, text =', text)
            self.privateData.isShowingWarning = true

            local layout = api.gui.layout.BoxLayout.new('VERTICAL')
            local window = api.gui.util.getById(self.privateData.warningWindowWithGotoId)
            if window == nil then
                window = api.gui.comp.Window.new(self.privateData.texts.warningWindowTitle, layout)
                window:setId(self.privateData.warningWindowWithGotoId)
                logger.infoOut('the window does not exist yet, _warningWindowWithGotoId =', self.privateData.warningWindowWithGotoId)
            else
                window:setContent(layout)
                window:setVisible(true, false)
                logger.infoOut('the window exists already, _warningWindowWithGotoId =', self.privateData.warningWindowWithGotoId)
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
                            buttonLayout:addItem(api.gui.comp.TextView.new(self.privateData.texts.goThere))
                            local button = api.gui.comp.Button.new(buttonLayout, true)
                            button:onClick(
                                function()
                                    -- UG TODO this dumps, ask UG to fix it
                                    -- api.gui.util.CameraController:setCameraData(
                                    --     api.type.Vec2f.new(otherObjectPosition[1], otherObjectPosition[2]),
                                    --     100, 0, 0
                                    -- )
                                    -- x, y, distance, angleInRad, pitchInRad
                                    self.privateFuncs.moveCamera(otherObjectPosition)
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
                    buttonLayout:addItem(api.gui.comp.TextView.new(self.privateData.texts.goBack))
                    local button = api.gui.comp.Button.new(buttonLayout, true)
                    button:onClick(
                        function()
                            -- UG TODO this dumps, ask UG to fix it
                            -- api.gui.util.CameraController:setCameraData(
                            --     api.type.Vec2f.new(wrongObjectPosition[1], wrongObjectPosition[2]),
                            --     100, 0, 0
                            -- )
                            -- x, y, distance, angleInRad, pitchInRad
                            self.privateFuncs.moveCamera(wrongObjectPosition)
                            -- game.gui.setCamera({wrongObjectPosition[1], wrongObjectPosition[2], 100, 0, 0})
                        end
                    )
                    layout:addItem(button)
                end
            end
            local function addBulldozeAllObjectsButton()
                if type(removeAllFunc) ~= 'function' then return end

                local bulldozeButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                bulldozeButtonLayout:addItem(api.gui.comp.ImageView.new('ui/cursors/bulldoze.tga'))
                bulldozeButtonLayout:addItem(api.gui.comp.TextView.new(self.privateData.texts.bulldozeAll))
                local bulldozeButton = api.gui.comp.Button.new(bulldozeButtonLayout, true)
                bulldozeButton:onClick(
                    function()
                        if type(removeAllFunc) == 'function' then
                            local gameUI = api.gui.util.getGameUI()
                            if gameUI and gameUI.playSoundEffect then
                                -- gameUI:playSoundEffect('bulldozeMedium')
                                gameUI:playSoundEffect('bulldozeLarge')
                            end
                            removeAllFunc()
                            -- window:setVisible(false, false) NO!
                        end
                    end
                )
                layout:addItem(bulldozeButton)
            end
            addGotoOtherObjectsButtons()
            addGoBackToWrongObjectButton()
            addBulldozeAllObjectsButton()

            window:setHighlighted(true)
            local position = api.gui.util.getMouseScreenPos()
            position.x = position.x + self.privateData.windowXShift
            position.y = position.y + self.privateData.windowYShift
            guiHelpers.setWindowPosition(window, position)
            -- window:addHideOnCloseHandler()
            window:onClose(
                function()
                    logger.infoOut('guiHelpers.showWarningWithGoto closing')
                    self.privateData.isShowingWarning = false
                    if window ~= nil then window:setVisible(false, false) end
                end
            )
        end

        return self
    end,
}
