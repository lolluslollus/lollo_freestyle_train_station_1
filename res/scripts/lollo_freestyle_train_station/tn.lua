-- given 25289 a track edge
local tn = api.engine.getComponent(25289, api.type.ComponentType.TRANSPORT_NETWORK)
local sampleTn = {
    nodes = {
    },
    edges = {
      [1] = {
        conns = {
          [1] = {
            new = nil,
            entity = 25257,
            index = 0,
          },
          [2] = {
            new = nil,
            entity = 25282,
            index = 0,
          },
        },
        geometry = {
          params = {
            pos = {
              x = 1598.162109375, -- identical to baseNode0.position.x
              y = 533.51306152344, -- identical to baseNode0.position.y
            },
            tangent = {
              x = -17.557006835938, -- identical to baseEdge.tangent0.x and baseEdge.tangent1.x
              y = -10.97265625, -- identical to baseEdge.tangent0.y and baseEdge.tangent1.y
            },
          },
          tangent = {
            x = -0.089698798954487, -- identical to baseEdge.tangent0.z
            y = -0.089698284864426, -- identical to baseEdge.tangent1.z
          },
          height = {
            x = 24.639444351196, -- similar, but not identical, to baseNode0.position.z. The difference is 0.530000686645
            y = 24.549745559692, -- similar, but not identical, to baseNode1.position.z. The difference is 0.530000686645
          },
          length = 20.704002380371,
          -- similar, but not identical, to math.sqrt(params.tangent.x * params.tangent.x + params.tangent.y * params.tangent.y),
          -- which is 20.703808205686
          -- closer, but not identical, to math.sqrt(
          --    params.tangent.x * params.tangent.x
          --  + params.tangent.y * params.tangent.y
          --  + tangent.x * tangent.x),
          -- which is 20.704002513823
          -- a little closer, but not identical, to math.sqrt(
          --    params.tangent.x * params.tangent.x
          --  + params.tangent.y * params.tangent.y
          --  + tangent.x * tangent.y),
          -- which is 20.704002512709
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
        curveSpeedLimit = 213.89448547363,
        curSpeed = 22,
        precedence = false,
      },
    },
  }
local baseEdge = api.engine.getComponent(25289, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 25257,
    node1 = 25282,
    tangent0 = {
      x = -17.557006835938,
      y = -10.97265625,
      z = -0.089698798954487,
    },
    tangent1 = {
      x = -17.557006835938,
      y = -10.97265625,
      z = -0.089698284864426,
    },
    type = 0,
    typeIndex = -1,
    objects = { },
  }
local baseNode0 = api.engine.getComponent(25257, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
      x = 1598.162109375,
      y = 533.51306152344,
      z = 24.109443664551,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
  }
local baseNode1 = api.engine.getComponent(25282, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
      x = 1580.6051025391,
      y = 522.54040527344,
      z = 24.019744873047,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
  }
