local moduleHelpers = require('lollo_freestyle_train_station.moduleHelpers')

function data()
    return {
      name = _('EraBTunnel'),
      icon = 'lollo_freestyle_train_station/tunnel/era_b_tunnel.tga',
      carriers = { 'RAIL' },
      portals = {
        { 'lollo_freestyle_train_station/tunnel/era_b_single_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/era_b_double_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/era_b_tunnel_start.mdl', 'lollo_freestyle_train_station/tunnel/era_b_tunnel_rep.mdl', 'lollo_freestyle_train_station/tunnel/era_b_tunnel_end.mdl' },
      },
      yearFrom = moduleHelpers.eras.era_b.startYear,
      yearTo = 0,
      cost = 800.0,
      categories = { 'misc' },
    }
end
