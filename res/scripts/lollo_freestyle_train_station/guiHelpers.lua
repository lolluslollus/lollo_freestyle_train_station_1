local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local stringUtils = require('lollo_freestyle_train_station.stringUtils')

local _stationPickerWindowId = 'lollo_freestyle_station_picker_window'
local _warningWindowId = 'lollo_freestyle_station_warning_window'

local _texts = {
    goBack = _('GoBack'),
    goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
    join = _('Join'),
    noJoin = _('NoJoin'),
    stationPickerWindowTitle = _('StationPickerWindowTitle'),
    warningWindowTitle = _('WarningWindowTitle'),
}

local guiHelpers = {
    moveCamera = function(position)
        local cameraData = game.gui.getCamera()
        game.gui.setCamera({position[1], position[2], cameraData[3], cameraData[4], cameraData[5]})
    end
}
guiHelpers.showNearbyStationPicker = function(isCargo, stations, eventId, joinEventName, noJoinEventName, eventArgs)
    print('showNearbyStationPicker starting')
    local layout = api.gui.layout.BoxLayout.new('VERTICAL')
    local window = api.gui.util.getById(_stationPickerWindowId)
    if window == nil then
        window = api.gui.comp.Window.new(_texts.stationPickerWindowTitle, layout)
        window:setId(_stationPickerWindowId)
    else
        window:setContent(layout)
        window:setVisible(true, false)
    end

    local function addJoinButtonsOLD()
        if type(stations) ~= 'table' then return end

        for _, station in pairs(stations) do
            local buttonsLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')

            buttonsLayout:addItem(api.gui.comp.TextView.new(station.uiName or station.name or ''))
            if station.isCargo then
                buttonsLayout:addItem(api.gui.comp.ImageView.new('ui/icons/construction-menu/category_cargo.tga'))
            else
                buttonsLayout:addItem(api.gui.comp.ImageView.new('ui/icons/construction-menu/category_passengers.tga'))
            end

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
            buttonsLayout:addItem(gotoButton)

            -- if isCargo == station.isCargo then
                local joinButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                joinButtonLayout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'))
                joinButtonLayout:addItem(api.gui.comp.TextView.new(_texts.join))
                local joinButton = api.gui.comp.Button.new(joinButtonLayout, true)
                joinButton:onClick(
                    function()
                        if not(stringUtils.isNullOrEmptyString(joinEventName)) then
                            eventArgs.join2StationId = station.id
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
                buttonsLayout:addItem(joinButton)
            -- end

            layout:addItem(buttonsLayout)
        end
    end

    local function addJoinButtons()
        if type(stations) ~= 'table' then return end

        local components = {}
        for _, station in pairs(stations) do
            local name = api.gui.comp.TextView.new(station.uiName or station.name or '')
            local cargo = station.isCargo
                and api.gui.comp.ImageView.new('ui/icons/construction-menu/category_cargo.tga')
                or api.gui.comp.ImageView.new('ui/icons/construction-menu/category_passengers.tga')

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

            -- if isCargo == station.isCargo then
                local joinButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
                joinButtonLayout:addItem(api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga'))
                joinButtonLayout:addItem(api.gui.comp.TextView.new(_texts.join))
                local joinButton = api.gui.comp.Button.new(joinButtonLayout, true)
                joinButton:onClick(
                    function()
                        if not(stringUtils.isNullOrEmptyString(joinEventName)) then
                            eventArgs.join2StationId = station.id
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
            -- end

            components[#components + 1] = {name, cargo, gotoButton, joinButton}
        end

        if #components > 0 then
            local guiStationsTable = api.gui.comp.Table.new(#components, 'NONE')
            guiStationsTable:setNumCols(4)
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
    addGoBackToWrongObjectButton()

    -- window:setHighlighted(true)
    local position = api.gui.util.getMouseScreenPos()
    window:setPosition(position.x, position.y)
    window:onClose(
        function()
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
end

guiHelpers.showWarningWindowWithGoto = function(text, wrongObjectId, similarObjectsIds)
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
    window:setPosition(position.x, position.y)
    window:addHideOnCloseHandler()
end

guiHelpers.hideAllWarnings = function()
    local window = api.gui.util.getById(_stationPickerWindowId)
    if window ~= nil then
        window:setVisible(false, false)
    end
    window = api.gui.util.getById(_warningWindowId)
    if window ~= nil then
        window:setVisible(false, false)
    end
end

return guiHelpers
