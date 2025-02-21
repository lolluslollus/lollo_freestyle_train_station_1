function data()
    return {
      name = _('EraATunnel'),
      icon = 'lollo_freestyle_train_station/tunnel/era_a_tunnel.tga',
      carriers = { 'RAIL' },
      portals = {
        { 'lollo_freestyle_train_station/tunnel/era_a_single_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/era_a_double_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/era_a_tunnel_start.mdl', 'lollo_freestyle_train_station/tunnel/era_a_tunnel_rep.mdl', 'lollo_freestyle_train_station/tunnel/era_a_tunnel_end.mdl' },
      },
      cost = 800.0,
      categories = { 'misc' },
    }
end
