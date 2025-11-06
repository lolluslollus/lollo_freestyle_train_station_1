local guiConfigWindow = require('lollo_freestyle_train_station.guiConfigWindow')
local logger = require('lollo_freestyle_train_station.logger')

return guiConfigWindow.new(
    'lollo_base_wall_con_config_layout_',
    'lollo_base_wall_warning_window_with_goto',
    {
        bulldoze = _('Bulldoze'),
        bulldozeAll = _('BulldozeAll'),
        conConfigWindowTitle = _('ConConfigWindowTitle'),
        goBack = _('GoBack'),
        goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
        warningWindowTitle = _('WarningWindowTitle'),
    }
)
