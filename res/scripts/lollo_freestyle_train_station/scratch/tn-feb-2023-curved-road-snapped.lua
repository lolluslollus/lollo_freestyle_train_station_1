-- two road segments at awkward angles can be snapped together.
-- the bit between the segment ends looks like an edge but it is no proper edge:
-- it cannot be bulldozed and it has no edgeId
-- The edges involved are coerced into a different geometry,
-- which can twist the tangents at both ends and the position at the snapped end.

-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 30178,
    node1 = 29262,
    tangent0 = {
        x = 95.541572570801, -- this does not appear in the geometries below
        y = 0, -- idem
        z = 0, -- idem
    },
    tangent1 = {
        x = -95.037528991699, -- this does not appear in the geometries below
        y = 9.8008985519409, -- idem
        z = -5.4047169685364, -- idem
    },
    type = 0,
    typeIndex = -1,
    objects = { },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
        x = 1031.1207275391, -- this does not appear in the geometries below
        y = 1262.21484375, -- idem
        z = 9.1439971923828, -- this appears in all 6 geometries below, corrected by the sidewalk height
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
        x = 1028.5412597656, -- this appears in all 6 geometries below
        y = 1212.0568847656, -- idem
        z = 6.302848815918, -- this appears in all 6 geometries below, corrected by the sidewalk height
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
          entity = 29262,
          index = 1,
        },
        [2] = {
          new = nil,
          entity = 30178,
          index = 8,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
            [2] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
          },
          tangent = {
            [1] = {
              x = 85.628440856934,
              y = -8.8305711746216,
            },
            [2] = {
              x = -67.717109680176,
              y = 25.67625617981,
            },
          },
          offset = -10,
        },
        tangent = {
          x = 4.86962890625,
          y = -0,
        },
        height = {
          x = 6.6028490066528,
          y = 9.4439973831177,
        },
        length = 98.664016723633,
        width = 4,
      },
      transportModes = {
        [1] = 1,
        [2] = 1,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 0,
      curveSpeedLimit = 0,
      curSpeed = 0,
      precedence = false,
    },
    [2] = {
      conns = {
        [1] = {
          new = nil,
          entity = 29262,
          index = 3,
        },
        [2] = {
          new = nil,
          entity = 30178,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
            [2] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
          },
          tangent = {
            [1] = {
              x = 85.628440856934,
              y = -8.8305711746216,
            },
            [2] = {
              x = -67.717109680176,
              y = 25.67625617981,
            },
          },
          offset = -6,
        },
        tangent = {
          x = 4.86962890625,
          y = -0,
        },
        height = {
          x = 6.302848815918,
          y = 9.1439971923828,
        },
        length = 87.123985290527,
        width = 4,
      },
      transportModes = {
        [1] = 0,
        [2] = 0,
        [3] = 1,
        [4] = 1,
        [5] = 1,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 16.666667938232,
      curveSpeedLimit = 8.4326105117798,
      curSpeed = 8.4326105117798,
      precedence = false,
    },
    [3] = {
      conns = {
        [1] = {
          new = nil,
          entity = 29262,
          index = 5,
        },
        [2] = {
          new = nil,
          entity = 30178,
          index = 4,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
            [2] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
          },
          tangent = {
            [1] = {
              x = 85.628440856934,
              y = -8.8305711746216,
            },
            [2] = {
              x = -67.717109680176,
              y = 25.67625617981,
            },
          },
          offset = -2,
        },
        tangent = {
          x = 4.86962890625,
          y = -0,
        },
        height = {
          x = 6.302848815918,
          y = 9.1439971923828,
        },
        length = 75.584609985352,
        width = 4,
      },
      transportModes = {
        [1] = 0,
        [2] = 0,
        [3] = 1,
        [4] = 1,
        [5] = 1,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 16.666667938232,
      curveSpeedLimit = 7.801854133606,
      curSpeed = 7.801854133606,
      precedence = false,
    },
    [4] = {
      conns = {
        [1] = {
          new = nil,
          entity = 30178,
          index = 3,
        },
        [2] = {
          new = nil,
          entity = 29262,
          index = 4,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
            [2] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
          },
          tangent = {
            [1] = {
              x = 67.717109680176,
              y = -25.67625617981,
            },
            [2] = {
              x = -85.628440856934,
              y = 8.8305711746216,
            },
          },
          offset = -2,
        },
        tangent = {
          x = 0,
          y = -4.86962890625,
        },
        height = {
          x = 9.1439971923828,
          y = 6.302848815918,
        },
        length = 64.045227050781,
        width = 4,
      },
      transportModes = {
        [1] = 0,
        [2] = 0,
        [3] = 1,
        [4] = 1,
        [5] = 1,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 16.666667938232,
      curveSpeedLimit = 7.1153998374939,
      curSpeed = 7.1153998374939,
      precedence = false,
    },
    [5] = {
      conns = {
        [1] = {
          new = nil,
          entity = 30178,
          index = 7,
        },
        [2] = {
          new = nil,
          entity = 29262,
          index = 2,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
            [2] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
          },
          tangent = {
            [1] = {
              x = 67.717109680176,
              y = -25.67625617981,
            },
            [2] = {
              x = -85.628440856934,
              y = 8.8305711746216,
            },
          },
          offset = -6,
        },
        tangent = {
          x = 0,
          y = -4.86962890625,
        },
        height = {
          x = 9.1439971923828,
          y = 6.302848815918,
        },
        length = 52.505214691162,
        width = 4,
      },
      transportModes = {
        [1] = 0,
        [2] = 0,
        [3] = 1,
        [4] = 1,
        [5] = 1,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 16.666667938232,
      curveSpeedLimit = 6.3552284240723,
      curSpeed = 6.3552284240723,
      precedence = false,
    },
    [6] = {
      conns = {
        [1] = {
          new = nil,
          entity = 30178,
          index = 11,
        },
        [2] = {
          new = nil,
          entity = 29262,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1039.5679931641,
              y = 1260.7507324219,
            },
            [2] = {
              x = 1028.5412597656,
              y = 1212.0568847656,
            },
          },
          tangent = {
            [1] = {
              x = 67.717109680176,
              y = -25.67625617981,
            },
            [2] = {
              x = -85.628440856934,
              y = 8.8305711746216,
            },
          },
          offset = -10,
        },
        tangent = {
          x = 0,
          y = -4.86962890625,
        },
        height = {
          x = 9.4439973831177,
          y = 6.6028490066528,
        },
        length = 40.965522766113,
        width = 4,
      },
      transportModes = {
        [1] = 1,
        [2] = 1,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
        [13] = 0,
        [14] = 0,
        [15] = 0,
        [16] = 0,
      },
      speedLimit = 0,
      curveSpeedLimit = 0,
      curSpeed = 0,
      precedence = false,
    },
  },
  turnaroundEdges = {
    [1] = 5,
    [2] = 4,
    [3] = 3,
    [4] = 2,
    [5] = 1,
    [6] = 0,
  },
}
