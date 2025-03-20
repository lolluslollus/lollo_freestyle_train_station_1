function data()
    return {
      name = _('BricksTunnel'),
      icon = 'lollo_freestyle_train_station/tunnel/bricks_tunnel.tga',
      carriers = { 'RAIL' },
      portals = {
        { 'lollo_freestyle_train_station/tunnel/bricks_single_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/bricks_double_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/bricks_tunnel_start.mdl', 'lollo_freestyle_train_station/tunnel/bricks_tunnel_rep.mdl', 'lollo_freestyle_train_station/tunnel/bricks_tunnel_end.mdl' },
      },
      cost = 800.0,
      categories = { 'misc' },
    }
end
