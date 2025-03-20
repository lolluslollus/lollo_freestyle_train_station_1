function data()
    return {
      name = _('TiledTunnel'),
      icon = 'lollo_freestyle_train_station/tunnel/tiled_tunnel.tga',
      carriers = { 'RAIL' },
      portals = {
        { 'lollo_freestyle_train_station/tunnel/tiled_single_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/tiled_double_tunnel.mdl' },
        { 'lollo_freestyle_train_station/tunnel/tiled_tunnel_start.mdl', 'lollo_freestyle_train_station/tunnel/tiled_tunnel_rep.mdl', 'lollo_freestyle_train_station/tunnel/tiled_tunnel_end.mdl' },
      },
      cost = 800.0,
      categories = { 'misc' },
    }
end
