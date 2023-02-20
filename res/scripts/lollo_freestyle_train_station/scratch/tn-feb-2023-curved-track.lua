-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 30011,
    node1 = 30012,
    tangent0 = {
        x = -18.221038818359, -- this appears in the 1 geometry below
        y = 63.707412719727, -- idem
        z = 1.1736187934875, -- idem
    },
    tangent1 = {
        x = 20.52409362793, -- idem
        y = 60.046226501465, -- idem
        z = -1.9140939712524, -- idem
    },
    type = 0,
    typeIndex = -1,
    objects = { },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
        x = 931.35656738281, -- this appears in the 1 geometry below
        y = 1074.3094482422, -- idem
        z = 7.2239532470703, -- this appears in the 1 geometry below, raised by 0.53
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
        x = 932.99102783203, -- this appears in the 1 geometry below
        y = 1137.6162109375, -- idem
        z = 6.6945719718933, -- this appears in the 1 geometry below, raised by 0.53
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleTN = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
local sampleTN = {
  nodes = {
  },
  edges = {
    [1] = {
      conns = {
        [1] = {
          new = nil,
          entity = 30011,
          index = 0,
        },
        [2] = {
          new = nil,
          entity = 30012,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 931.35656738281,
              y = 1074.3094482422,
            },
            [2] = {
              x = 932.99102783203,
              y = 1137.6162109375,
            },
          },
          tangent = {
            [1] = {
              x = -18.221038818359,
              y = 63.707412719727,
            },
            [2] = {
              x = 20.52409362793,
              y = 60.046226501465,
            },
          },
        },
        tangent = {
          x = 1.1736187934875,
          y = -1.9140939712524,
        },
        height = {
          x = 7.7539529800415,
          y = 7.2245721817017,
        },
        length = 64.323501586914,
        width = 0,
      },
      transportModes = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 1,
        [9] = 1,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 33.333332061768,
      curveSpeedLimit = 16.156253814697,
      curSpeed = 16.156253814697,
      precedence = false,
    },
  },
  turnaroundEdges = {
    [1] = -1,
  },
}
