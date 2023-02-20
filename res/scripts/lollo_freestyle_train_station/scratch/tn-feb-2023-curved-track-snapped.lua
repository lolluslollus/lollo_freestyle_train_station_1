-- two track segments at awkward angles can be snapped together.
-- the bit between the segment ends looks like an edge but it is no proper edge:
-- it cannot be bulldozed and it has no edgeId
-- The edges involved are coerced into a different geometry,
-- which can twist the tangents at both ends and the position at the snapped end.

-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 29333,
    node1 = 12372,
    tangent0 = {
        x = -19.559194564819, -- this does not appear in the geometry below
        y = 0.56661891937256, -- idem
        z = 0.7288663983345, -- idem
    },
    tangent1 = {
        x = -18.397771835327, -- idem
        y = 6.8158740997314, -- idem
        z = 1.4714804887772, -- idem
    },
    type = 0,
    typeIndex = -1,
    objects = { },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
        x = 1090.4459228516, -- this does not appear in the geometry below
        y = 1249.3011474609, -- idem
        z = 6.3121490478516, -- idem, even if we raise it by 0.53
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
        x = 1071.3392333984, -- this appears in the 1 geometry below
        y = 1253.0129394531, -- idem
        z = 7.533420085907, -- this appears in the 1 geometry below, raised by 0.53
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
          entity = 29333,
          index = 2,
        },
        [2] = {
          new = nil,
          entity = 12372,
          index = 0,
        },
      },
      geometry = {
        params = {
          pos = {
            [1] = {
              x = 1086.1459960938,
              y = 1249.5804443359,
            },
            [2] = {
              x = 1071.3392333984,
              y = 1253.0129394531,
            },
          },
          tangent = {
            [1] = {
              x = -15.150382995605,
              y = 1.532233953476,
            },
            [2] = {
              x = -14.341571807861,
              y = 5.3131623268127,
            },
          },
        },
        tangent = {
          x = 0.79314315319061,
          y = 1.1470597982407,
        },
        height = {
          x = 7.0359554290771,
          y = 8.0634202957153,
        },
        length = 15.275302886963,
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
      curveSpeedLimit = 12.646052360535,
      curSpeed = 12.646052360535,
      precedence = false,
    },
  },
  turnaroundEdges = {
    [1] = -1,
  },
}
