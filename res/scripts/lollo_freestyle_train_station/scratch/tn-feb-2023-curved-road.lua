-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 30130,
    node1 = 20389,
    tangent0 = {
        x = -25.058628082275, -- this appears in all 6 geometries below
        y = 60.592456817627, -- idem
        z = 2.0206367969513, -- idem
    },
    tangent1 = {
        x = 19.886278152466, -- idem
        y = 58.180202484131, -- idem
        z = -1.8546106815338, -- idem
    },
    type = 0,
    typeIndex = -1,
    objects = { },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
        x = 952.89544677734, -- this appears in all 6 geometries below
        y = 1070.1520996094, -- idem
        z = 6.983268737793, -- this appears in all 6 geometries below, corrected by the sidewalk height
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
        x = 950.96978759766, -- this appears in all 6 geometries below
        y = 1131.4709472656, -- idem
        z = 6.6945719718933, -- this appears in all 6 geometries below, corrected by the sidewalk height
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
              entity = 20389,
              index = 1,
            },
            [2] = {
              new = nil,
              entity = 30130,
              index = 0,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
                [2] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
              },
              tangent = {
                [1] = {
                  x = -19.886278152466,
                  y = -58.180202484131,
                },
                [2] = {
                  x = 25.058628082275,
                  y = -60.592456817627,
                },
              },
              offset = -10,
            },
            tangent = {
              x = 1.8546106815338,
              y = -2.0206367969513,
            },
            height = {
              x = 6.9945721626282,
              y = 7.2832689285278,
            },
            length = 69.932563781738, -- this is different in every lane
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
              entity = 20389,
              index = 2,
            },
            [2] = {
              new = nil,
              entity = 30130,
              index = 2,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
                [2] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
              },
              tangent = {
                [1] = {
                  x = -19.886278152466,
                  y = -58.180202484131,
                },
                [2] = {
                  x = 25.058628082275,
                  y = -60.592456817627,
                },
              },
              offset = -6,
            },
            tangent = {
              x = 1.8546106815338,
              y = -2.0206367969513,
            },
            height = {
              x = 6.6945719718933,
              y = 6.983268737793,
            },
            length = 67.046073913574,
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
          curveSpeedLimit = 15.472853660583,
          curSpeed = 11.000000953674,
          precedence = false,
        },
        [3] = {
          conns = {
            [1] = {
              new = nil,
              entity = 20389,
              index = 3,
            },
            [2] = {
              new = nil,
              entity = 30130,
              index = 4,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
                [2] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
              },
              tangent = {
                [1] = {
                  x = -19.886278152466,
                  y = -58.180202484131,
                },
                [2] = {
                  x = 25.058628082275,
                  y = -60.592456817627,
                },
              },
              offset = -2,
            },
            tangent = {
              x = 1.8546106815338,
              y = -2.0206367969513,
            },
            height = {
              x = 6.6945719718933,
              y = 6.983268737793,
            },
            length = 64.15958404541,
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
          curveSpeedLimit = 15.138336181641,
          curSpeed = 11.000000953674,
          precedence = false,
        },
        [4] = {
          conns = {
            [1] = {
              new = nil,
              entity = 30130,
              index = 5,
            },
            [2] = {
              new = nil,
              entity = 20389,
              index = 4,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
                [2] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
              },
              tangent = {
                [1] = {
                  x = -25.058628082275,
                  y = 60.592456817627,
                },
                [2] = {
                  x = 19.886278152466,
                  y = 58.180202484131,
                },
              },
              offset = -2,
            },
            tangent = {
              x = 2.0206367969513,
              y = -1.8546106815338,
            },
            height = {
              x = 6.983268737793,
              y = 6.6945719718933,
            },
            length = 61.27307510376,
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
          curveSpeedLimit = 14.796257019043,
          curSpeed = 11.000000953674,
          precedence = false,
        },
        [5] = {
          conns = {
            [1] = {
              new = nil,
              entity = 30130,
              index = 3,
            },
            [2] = {
              new = nil,
              entity = 20389,
              index = 5,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
                [2] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
              },
              tangent = {
                [1] = {
                  x = -25.058628082275,
                  y = 60.592456817627,
                },
                [2] = {
                  x = 19.886278152466,
                  y = 58.180202484131,
                },
              },
              offset = -6,
            },
            tangent = {
              x = 2.0206367969513,
              y = -1.8546106815338,
            },
            height = {
              x = 6.983268737793,
              y = 6.6945719718933,
            },
            length = 58.386581420898,
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
          curveSpeedLimit = 14.446080207825,
          curSpeed = 11.000000953674,
          precedence = false,
        },
        [6] = {
          conns = {
            [1] = {
              new = nil,
              entity = 30130,
              index = 1,
            },
            [2] = {
              new = nil,
              entity = 20389,
              index = 0,
            },
          },
          geometry = {
            params = {
              pos = {
                [1] = {
                  x = 952.89544677734,
                  y = 1070.1520996094,
                },
                [2] = {
                  x = 950.96978759766,
                  y = 1131.4709472656,
                },
              },
              tangent = {
                [1] = {
                  x = -25.058628082275,
                  y = 60.592456817627,
                },
                [2] = {
                  x = 19.886278152466,
                  y = 58.180202484131,
                },
              },
              offset = -10,
            },
            tangent = {
              x = 2.0206367969513,
              y = -1.8546106815338,
            },
            height = {
              x = 7.2832689285278,
              y = 6.9945721626282,
            },
            length = 55.500095367432,
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