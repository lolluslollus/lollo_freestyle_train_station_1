local constants = require('lollo_freestyle_train_station.constants')
local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local logger = require('lollo_freestyle_train_station.logger')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local _progressWindowId = 'lollo_freestyle_station_progress_window'
local _stationPickerWindowId = 'lollo_freestyle_station_picker_window'
local _warningWindowId = 'lollo_freestyle_station_warning_window_no_goto'
local _warningWindowWithGotoId = 'lollo_freestyle_station_warning_window_with_goto'
local _waypointDistanceWindowId = 'lollo_freestyle_station_waypoint_distance_window'
local _saveWarningWindowId = 'lollo_freestyle_station_workflow_warning_window'

local _texts = {
    bulldozeAll = _('BulldozeAll'),
    goBack = _('GoBack'),
    goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
    join = _('Join'),
    noJoin = _('NoJoin'),
    saveAnyway = _('SaveAnyway'),
    stationPickerWindowTitle = _('StationPickerWindowTitle'),
    wait4Join = _('Wait4Join'),
    warningWindowTitle = _('WarningWindowTitle'),
    waypointDistanceWindowTitle = _('WaypointDistanceWindowTitle'),
}

-- local _windowXShift = 40
local _windowYShift = 40

local guiHelpers = {
    isAllowSaving = false,
    isShowingProgress = false,
    isShowingWarning = false,
    isShowingWarningWithGoTo = false,
    isShowingWaypointDistance = false,
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end
}
---position window keeping it within the screen
---@param window any
---@param initialPosition {x:number, y:number}|nil
guiHelpers.setWindowPosition = function(window, initialPosition)
    local gameContentRect = api.gui.util.getGameUI():getContentRect()
    local windowContentRect = window:getContentRect()
    local windowMinimumSize = window:calcMinimumSize()
    logger.print('### gameContentRect =') logger.debugPrint(gameContentRect)
    logger.print('### windowContentRect =') logger.debugPrint(windowContentRect)
    logger.print('### windowMinimumSize =') logger.debugPrint(windowMinimumSize)

    local windowHeight = math.max(windowContentRect.h, windowMinimumSize.h)
    local windowWidth = math.max(windowContentRect.w, windowMinimumSize.w)
    local positionX = (initialPosition ~= nil and initialPosition.x) or math.max(0, (gameContentRect.w - windowWidth) * 0.5)
    local positionY = (initialPosition ~= nil and initialPosition.y) or math.max(0, (gameContentRect.h - windowHeight) * 0.5)

    logger.print('### positionX = ' .. tostring(positionX) .. ', positionY = ' .. tostring(positionY))

    if (positionX + windowWidth) > gameContentRect.w then
        positionX = math.max(0, gameContentRect.w - windowWidth)
    end
    if (positionY + windowHeight) > gameContentRect.h then
        positionY = math.max(0, gameContentRect.h - windowHeight -100)
    end
    logger.print('### final position x = ' .. tostring(positionX) .. ', y = ' .. tostring(positionY))
    window:setPosition(math.floor(positionX), math.floor(positionY))
end
---@param text string
---@param title string
---@param onCloseFunc function
guiHelpers.showProgress = function(text, title, onCloseFunc)
    guiHelpers.isShowingProgress = true

    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_progressWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(title or _texts.warningWindowTitle, layout)
        window:setId(_progressWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    -- window:setHighlighted(true)
    window:setMinimumSize(api.gui.util.Size.new(400, 70))
    guiHelpers.setWindowPosition(window)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            guiHelpers.isShowingProgress = false
            window:setVisible(false, false)
            if type(onCloseFunc) == 'function' then onCloseFunc() end
        end
    )
end

---@param isTheNewObjectCargo boolean
---@param stations table<any>
---@param eventId string
---@param joinEventName string
---@param noJoinEventName string|nil
---@param eventArgs table<any>
---@param onClickJoinFunc? function
guiHelpers.showNearbyStationPicker = function(isTheNewObjectCargo, stations, eventId, joinEventName, noJoinEventName, eventArgs, onClickJoinFunc)
    -- print('showNearbyStationPicker starting')
    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_stationPickerWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.stationPickerWindowTitle, layout)
        window:setId(_stationPickerWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    local function addJoinButtons()
        if type(stations) ~= 'table' then return end

        local components = {}
        for _, station in pairs(stations) do
            local name = api.gui.comp.TextView.new(station.uiName or station.name or '')
            local cargoIcon = station.isCargo
                and api.gui.comp.ImageView.new('ui/icons/construction-menu/category_cargo.tga')
                or api.gui.comp.TextView.new('')
            local passengerIcon = station.isPassenger
                and api.gui.comp.ImageView.new('ui/icons/construction-menu/category_passengers.tga')
                or api.gui.comp.TextView.new('')

            local gotoButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            gotoButtonLayout:addItem(api.gui.comp.ImageView.new('ui/design/window-content/locate_small.tga'))
            gotoButtonLayout:addItem(api.gui.comp.TextView.new(_texts.goThere))
            local gotoButton = api.gui.comp.Button.new(gotoButtonLayout, true)
            gotoButton:onClick(
                function()
                    guiHelpers.moveCamera(station.position)
                    -- game.gui.setCamera({con.position[1], con.position[2], 100, 0, 0})
                end
            )

            local joinButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
            joinButtonLayout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'))
            joinButtonLayout:addItem(api.gui.comp.TextView.new(_texts.join))
            local joinButton = api.gui.comp.Button.new(joinButtonLayout, true)
            joinButton:onClick(
                function()
                    if type(onClickJoinFunc) == 'function' then onClickJoinFunc() end
                    logger.print('guiHelpers 120')
                    if not(stringUtils.isNullOrEmptyString(joinEventName)) then
                        eventArgs.join2StationConId = station.id
                        api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                            string.sub(debug.getinfo(1, 'S').source, 1),
                            eventId,
                            joinEventName,
                            eventArgs
                        ))
                    end
                    window:setVisible(false, false)
                end
            )

            components[#components + 1] = {name, cargoIcon, passengerIcon, gotoButton, joinButton}
        end

        if #components > 0 then
            -- local guiStationsTable = api.gui.comp.Table.new(#components, 'NONE')
            -- guiStationsTable:setNumCols(5)
            local guiStationsTable = api.gui.comp.Table.new(5, 'NONE') -- num of columns, one of "NONE", "SELECTABLE" or "MULTI"
            for _, value in pairs(components) do
                guiStationsTable:addRow(value)
            end
            layout:addItem(guiStationsTable)
        end
    end

    local function addNoJoinButton()
        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_invalid.tga'))
        buttonLayout:addItem(api.gui.comp.TextView.new(_texts.noJoin))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                -- print('string.sub(debug.getinfo(1, \'S\').source, 1) =') debugPrint(string.sub(debug.getinfo(1, 'S').source, 1))
                -- the following dumps
                -- print('string.sub(debug.getinfo(1, \'S\').source, 2) =') debugPrint(string.sub(debug.getinfo(2, 'S').source, 1))
                -- print('string.sub(debug.getinfo(1, \'S\').source, 3) =') debugPrint(string.sub(debug.getinfo(3, 'S').source, 1))
                -- print('string.sub(debug.getinfo(1, \'S\').source, 4) =') debugPrint(string.sub(debug.getinfo(4, 'S').source, 1))
                -- if type(onClickJoinFunc) == 'function' then onClickJoinFunc() end
                logger.print('guiHelpers 160')
                if not(stringUtils.isNullOrEmptyString(noJoinEventName)) then
                    api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
                        string.sub(debug.getinfo(1, 'S').source, 1),
                        eventId,
                        noJoinEventName,
                        eventArgs
                    ))
                end
                window:setVisible(false, false)
            end
        )
        layout:addItem(button)
    end

    local function addWait4JoinNotice()
        layout:addItem(api.gui.comp.TextView.new(_texts.wait4Join))
    end

    local function addGoBackToWrongObjectButton()
        if not(edgeUtils.isValidAndExistingId(eventArgs.platformWaypoint1Id)) then return end

        local newObjectPosition = edgeUtils.getObjectPosition(eventArgs.platformWaypoint1Id)
        if newObjectPosition ~= nil then
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
                    guiHelpers.moveCamera(newObjectPosition)
                    -- game.gui.setCamera({wrongObjectPosition[1], wrongObjectPosition[2], 100, 0, 0})
                end
            )
            layout:addItem(button)
        end
    end

    addJoinButtons()
    addNoJoinButton()
    addWait4JoinNotice()
    addGoBackToWrongObjectButton()

    -- window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    -- position.x = position.x + _windowXShift
    position.y = position.y + _windowYShift
    guiHelpers.setWindowPosition(window, position)

    window:onClose(
        function()
            logger.print('guiHelpers 215')
            -- do not do anything!
            -- if not(stringUtils.isNullOrEmptyString(noJoinEventName)) then
            --     api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
            --         string.sub(debug.getinfo(1, 'S').source, 1),
            --         eventId,
            --         noJoinEventName,
            --         eventArgs
            --     ))
            -- end
            window:setVisible(false, false)
        end
    )
end

---@param text string
---@param onCloseFunc function
guiHelpers.showWarning = function(text, onCloseFunc)
    guiHelpers.isShowingWarning = true

    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_warningWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.warningWindowTitle, layout)
        window:setId(_warningWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    window:setHighlighted(true)
    window:setMinimumSize(api.gui.util.Size.new(400, 70))
    guiHelpers.setWindowPosition(window)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            guiHelpers.isShowingWarning = false
            window:setVisible(false, false)
            if type(onCloseFunc) == 'function' then onCloseFunc() end
        end
    )
end

---@param text string
guiHelpers.showSaveWarning = function(text)
    guiHelpers.isAllowSaving = false

    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_saveWarningWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.warningWindowTitle, layout)
        window:setId(_saveWarningWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    layout:addItem(api.gui.comp.TextView.new(text))

    local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
    toggleButtonLayout:addItem(api.gui.comp.ImageView.new('ui/save.tga'))
    toggleButtonLayout:addItem(api.gui.comp.TextView.new(_texts.saveAnyway))
    local button = api.gui.comp.ToggleButton.new(toggleButtonLayout)
    button:setSelected(guiHelpers.isAllowSaving, false)
    button:onToggle(
        function(isOn)
            guiHelpers.isAllowSaving = isOn
        end
    )
    layout:addItem(button)

    window:setHighlighted(true)
    window:setMinimumSize(api.gui.util.Size.new(600, 120))
    guiHelpers.setWindowPosition(window)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            window:setVisible(false, false)
            guiHelpers.isAllowSaving = false
        end
    )
end

---@param text string
---@param wrongObjectId? integer
---@param similarObjectsIds? table<integer>
guiHelpers.showWarningWithGoto = function(text, wrongObjectId, similarObjectsIds, removeAllFunc)
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

    local function addBulldozeAllObjectsButton()
        if type(removeAllFunc) ~= 'function' then return end

        local bulldozeButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        bulldozeButtonLayout:addItem(api.gui.comp.ImageView.new('ui/cursors/bulldoze.tga'))
        bulldozeButtonLayout:addItem(api.gui.comp.TextView.new(_texts.bulldozeAll))
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
    -- position.x = position.x + _windowXShift
    position.y = position.y + _windowYShift
    guiHelpers.setWindowPosition(window, position)
    -- window:addHideOnCloseHandler()
    window:onClose(
        function()
            logger.print('guiHelpers.showWarningWithGoto closing')
            guiHelpers.isShowingWarningWithGoTo = false
            window:setVisible(false, false)
        end
    )
end

---@param distance number
guiHelpers.showWaypointDistance = function(distance)
    guiHelpers.isShowingWaypointDistance = true

    local text = tostring((_texts.waypointDistanceWindowTitle .. " %.0f m"):format(distance))
    local content = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_waypointDistanceWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.waypointDistanceWindowTitle, content)
        window:setId(_waypointDistanceWindowId)
    else
        window:setContent(content)
        window:setVisible(true, false)
    end

    content:addItem(api.gui.comp.TextView.new(text))

    local position = api.gui.util.getMouseScreenPos()
    -- position.x = position.x + _windowXShift
    position.y = position.y + _windowYShift
    guiHelpers.setWindowPosition(window, position)

    -- make title bar invisible without that dumb pseudo css
    window:getLayout():getItem(0):setVisible(false, false)

    window:onClose(
        function()
            logger.print('guiHelpers 374')
            guiHelpers.isShowingWaypointDistance = false
            window:setVisible(false, false)
        end
    )
end

---@param onCloseFunc function
guiHelpers.hideProgress = function(onCloseFunc)
    if guiHelpers.isShowingProgress then -- only for performance
        guiHelpers.isShowingProgress = false

        local window = api.gui.util.getById(_progressWindowId)
        if window ~= nil then
            window:setVisible(false, false)
            if type(onCloseFunc) == 'function' then onCloseFunc() end
        end
    end
end

-- guiHelpers.hideStationPicker = function()
--     local window = api.gui.util.getById(_stationPickerWindowId)
--     if window ~= nil then
--         window:setVisible(false, false)
--     end
-- end

---@param onCloseFunc? function
guiHelpers.hideWarning = function(onCloseFunc)
    if guiHelpers.isShowingWarning then -- only for performance
        guiHelpers.isShowingWarning = false

        local window = api.gui.util.getById(_warningWindowId)
        if window ~= nil then
            window:setVisible(false, false)
            if type(onCloseFunc) == 'function' then onCloseFunc() end
        end
    end
end

guiHelpers.hideWarningWithGoTo = function()
    if guiHelpers.isShowingWarningWithGoTo then -- only for performance
        guiHelpers.isShowingWarningWithGoTo = false

        local window = api.gui.util.getById(_warningWindowWithGotoId)
        if window ~= nil then
            window:setVisible(false, false)
        end
    end
end

guiHelpers.hideWaypointDistance = function()
    if guiHelpers.isShowingWaypointDistance then -- only for performance
        guiHelpers.isShowingWaypointDistance = false

        local window = api.gui.util.getById(_waypointDistanceWindowId)
        if window ~= nil then
            logger.print('guiHelpers 431')
            window:setVisible(false, false)
        end
    end
end

return guiHelpers
