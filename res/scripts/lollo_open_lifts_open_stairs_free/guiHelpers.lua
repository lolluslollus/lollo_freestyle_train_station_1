local guiConfigWindow = require('lollo_freestyle_train_station.guiConfigWindow')
local logger = require('lollo_freestyle_train_station.logger')

return guiConfigWindow.new(
    'lollo_stairs_con_config_layout_',
    'lollo_stairs_warning_window_with_goto',
    {
        bulldoze = _('Bulldoze'),
        bulldozeAll = _('BulldozeAll'),
        conConfigWindowTitle = _('ConConfigWindowTitle'),
        goBack = _('GoBack'),
        goThere = _('GoThere'), -- cannot put this directly inside the loop for some reason
        warningWindowTitle = _('WarningWindowTitle'),
    },
    100,
    65, -- half the height of module icons, which we reuse here
    40,
    40
)
