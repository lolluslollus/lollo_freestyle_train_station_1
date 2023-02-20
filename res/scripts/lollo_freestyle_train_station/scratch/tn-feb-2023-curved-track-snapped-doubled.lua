-- two track segments at awkward angles can be snapped together.
-- the bit between the segment ends looks like an edge but it is no proper edge:
-- it cannot be bulldozed and it has no edgeId
-- The edges involved are coerced into a different geometry,
-- which can twist the tangents at both ends and the position at the snapped end.

-- This is a very dirty track, which resulted in two TN edges.

-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 29492,
    node1 = 30072,
    tangent0 = {
      x = 10.5236120224,
      y = -5.0851712226868,
      z = -0.91291105747223,
    },
    tangent1 = {
      x = 11.072742462158,
      y = -3.7407801151276,
      z = -0.91636896133423,
    },
    type = 0,
    typeIndex = -1,
    objects = {
      { 26121, 2, },
    },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
  position = {
      x = -134.33062744141,
      y = 958.16882324219,
      z = 31.343250274658,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
      x = -123.82286071777,
      y = 953.88848876953,
      z = 30.600067138672,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleTN = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
local sampleTN = {
  nodes = {
    [1] = {
    },
  },
  edges = {
    [1] = {
      conns = {
        [1] = {
          new = nil,
          entity = 29492,
          index = 0,
        },
        [2] = {
          new = nil,
          entity = 26632,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = -134.33062744141,
              y = 958.16882324219,
            },
            [2] = {
              x = -124.84535980225,
              y = 954.23974609375,
            },
          },
          tangent = {
            [1] = {
              x = 9.5428056716919,
              y = -4.6112303733826,
            },
            [2] = {
              x = 9.8608112335205,
              y = -3.4447665214539,
            },
          },
        },
        tangent = {
          x = -0.8278272151947,
          y = -0.75183069705963,
        },
        height = {
          x = 31.873250961304,
          y = 31.211269378662,
        },
        length = 10.29406452179,
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
      curveSpeedLimit = 14.739421844482,
      curSpeed = 14.739421844482,
      precedence = false,
    },
    [2] = {
      conns = {
        [1] = {
          new = nil,
          entity = 26632,
          index = 0,
        },
        [2] = {
          new = nil,
          entity = 30072,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = -124.84535980225,
              y = 954.23974609375,
            },
            [2] = {
              x = -123.82286071777,
              y = 953.88848876953,
            },
          },
          tangent = {
            [1] = {
              x = 1.013491153717,
              y = -0.35405203700066,
            },
            [2] = {
              x = 1.0319858789444,
              y = -0.34864282608032,
            },
          },
        },
        tangent = {
          x = -0.077272929251194,
          y = -0.085406102240086,
        },
        height = {
          x = 31.211269378662,
          y = 31.130067825317,
        },
        length = 1.0842020511627,
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
      curveSpeedLimit = 14.739421844482,
      curSpeed = 14.739421844482,
      precedence = false,
    },
  },
  turnaroundEdges = {
    [1] = -1,
    [2] = -1,
  },
}
