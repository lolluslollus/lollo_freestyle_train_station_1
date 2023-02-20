-- sampleBaseEdge = api.engine.getComponent(edgeId, api.type.ComponentType.BASE_EDGE)
local sampleBaseEdge = {
    node0 = 28330,
    node1 = 30158,
    tangent0 = {
      x = 27.757242202759,
      y = 38.717987060547,
      z = 0.93919402360916,
    },
    tangent1 = {
      x = 27.757242202759,
      y = 38.717987060547,
      z = 0.93919390439987,
    },
    type = 0,
    typeIndex = -1,
    objects = { },
}
-- sampleBaseNode0 = api.engine.getComponent(edgeId.node0, api.type.ComponentType.BASE_NODE)
local sampleBaseNode0 = {
    position = {
        x = 741.00122070313,
        y = 932.67156982422,
        z = 5.2130689620972,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleBaseNode1 = api.engine.getComponent(edgeId.node1, api.type.ComponentType.BASE_NODE)
local sampleBaseNode1 = {
    position = {
        x = 768.75854492188,
        y = 971.38958740234,
        z = 6.1522631645203,
    },
    doubleSlipSwitch = false,
    trafficLightPreference = 2,
}
-- sampleTN = api.engine.getComponent(edgeId, api.type.ComponentType.TRANSPORT_NETWORK)
local sampleTN ={
    nodes = {
    },
    edges = {
      [1] = {
        conns = {
          [1] = {
            new = nil,
            entity = 30158,
            index = 1,
          },
          [2] = {
            new = nil,
            entity = 28330,
            index = 1,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
              [2] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
            },
            tangent = {
              [1] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
              [2] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
            },
            offset = -10,
          },
          tangent = {
            x = -0.93919390439987,
            y = -0.93919402360916,
          },
          height = {
            x = 6.4522633552551,
            y = 5.513069152832,
          },
          length = 47.649089813232,
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
            entity = 30158,
            index = 2,
          },
          [2] = {
            new = nil,
            entity = 28330,
            index = 2,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
              [2] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
            },
            tangent = {
              [1] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
              [2] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
            },
            offset = -6,
          },
          tangent = {
            x = -0.93919390439987,
            y = -0.93919402360916,
          },
          height = {
            x = 6.1522631645203,
            y = 5.2130689620972,
          },
          length = 47.649089813232,
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
        curveSpeedLimit = 160.00799560547,
        curSpeed = 11.000000953674,
        precedence = false,
      },
      [3] = {
        conns = {
          [1] = {
            new = nil,
            entity = 30158,
            index = 3,
          },
          [2] = {
            new = nil,
            entity = 28330,
            index = 3,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
              [2] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
            },
            tangent = {
              [1] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
              [2] = {
                x = -27.757242202759,
                y = -38.717987060547,
              },
            },
            offset = -2,
          },
          tangent = {
            x = -0.93919390439987,
            y = -0.93919402360916,
          },
          height = {
            x = 6.1522631645203,
            y = 5.2130689620972,
          },
          length = 47.649089813232,
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
        curveSpeedLimit = 160.00799560547,
        curSpeed = 11.000000953674,
        precedence = false,
      },
      [4] = {
        conns = {
          [1] = {
            new = nil,
            entity = 28330,
            index = 4,
          },
          [2] = {
            new = nil,
            entity = 30158,
            index = 4,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
              [2] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
            },
            tangent = {
              [1] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
              [2] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
            },
            offset = -2,
          },
          tangent = {
            x = 0.93919402360916,
            y = 0.93919390439987,
          },
          height = {
            x = 5.2130689620972,
            y = 6.1522631645203,
          },
          length = 47.649089813232,
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
        curveSpeedLimit = 160.00799560547,
        curSpeed = 11.000000953674,
        precedence = false,
      },
      [5] = {
        conns = {
          [1] = {
            new = nil,
            entity = 28330,
            index = 5,
          },
          [2] = {
            new = nil,
            entity = 30158,
            index = 5,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
              [2] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
            },
            tangent = {
              [1] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
              [2] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
            },
            offset = -6,
          },
          tangent = {
            x = 0.93919402360916,
            y = 0.93919390439987,
          },
          height = {
            x = 5.2130689620972,
            y = 6.1522631645203,
          },
          length = 47.649089813232,
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
        curveSpeedLimit = 160.00799560547,
        curSpeed = 11.000000953674,
        precedence = false,
      },
      [6] = {
        conns = {
          [1] = {
            new = nil,
            entity = 28330,
            index = 0,
          },
          [2] = {
            new = nil,
            entity = 30158,
            index = 0,
          },
        },
        geometry = {
          params = {
            pos = {
              [1] = {
                x = 741.00122070313,
                y = 932.67156982422,
              },
              [2] = {
                x = 768.75854492188,
                y = 971.38958740234,
              },
            },
            tangent = {
              [1] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
              [2] = {
                x = 27.757242202759,
                y = 38.717987060547,
              },
            },
            offset = -10,
          },
          tangent = {
            x = 0.93919402360916,
            y = 0.93919390439987,
          },
          height = {
            x = 5.513069152832,
            y = 6.4522633552551,
          },
          length = 47.649089813232,
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