-- this works
local proposal01 = {
    streetProposal = {
      nodesToAdd = {
      },
      edgesToAdd = {
        [1] = {
          entity = -1,
          comp = {
            node0 = 30692,
            node1 = 30729,
            tangent0 = {
              x = -18.781312942505,
              y = -0.89817231893539,
              z = -1.3580846786499,
            },
            tangent1 = {
              x = -18.781312942505,
              y = -0.89817547798157,
              z = -1.3580846786499,
            },
            type = 1,
            typeIndex = 16,
            objects = {
              { -1, 1, },
            },
          },
          type = 0,
          params = {
            streetType = 38,
            hasBus = true,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          playerOwned = nil,
          streetEdge = {
            streetType = 38,
            hasBus = true,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = -1,
            catenary = false,
          },
        },
      },
      nodesToRemove = {
      },
      edgesToRemove = {
      },
      edgeObjectsToAdd = {
        [1] = {
          edgeEntity = -1,
          param = 0.78838884830475,
          oneWay = false,
          left = true,
          model = "street/signal_waypoint.mdl",
          playerEntity = 23826,
          name = "Thornbury Waypoint #1",
        },
      },
      edgeObjectsToRemove = {
      },
    },
    constructionsToAdd = {
    },
    constructionsToRemove = {
    },
    old2new = {
    },
  }
-- also this works
local proposal02 = {
    streetProposal = {
      nodesToAdd = {
      },
      edgesToAdd = {
        [1] = {
          entity = -1,
          comp = {
            node0 = 30734,
            node1 = 30712,
            tangent0 = {
              x = 9.9976062774658,
              y = 0.213962033391,
              z = -0.29356688261032,
            },
            tangent1 = {
              x = 9.9976062774658,
              y = 0.21396194398403,
              z = -0.29356691241264,
            },
            type = 0,
            typeIndex = -1,
            objects = {
              { -1, 2, },
            },
          },
          type = 1,
          params = {
            trackType = 1,
            catenary = true,
          },
          playerOwned = nil,
          streetEdge = {
            streetType = -1,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = 1,
            catenary = true,
          },
        },
      },
      nodesToRemove = {
      },
      edgesToRemove = {
      },
      edgeObjectsToAdd = {
        [1] = {
          edgeEntity = -1,
          param = 0.69279098510742,
          oneWay = false,
          left = false,
          model = "railroad/signal_path_c.mdl",
          playerEntity = 23826,
          name = "Thornbury Signal #1",
        },
      },
      edgeObjectsToRemove = {
      },
    },
    constructionsToAdd = {
    },
    constructionsToRemove = {
    },
    old2new = {
    },
  }

-- this fails
local proposal = {
    streetProposal = {
      nodesToAdd = {
        [1] = {
          comp = {
            position = {
              x = 88.771644592285,
              y = -23.351211547852,
              z = 2.6500015258789,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = -1,
        },
      },
      edgesToAdd = {
        [1] = {
          entity = -2,
          comp = {
            node0 = 30689,
            node1 = -1,
            tangent0 = {
              x = 9.9976062774658,
              y = 0.213962033391,
              z = -0.29356688261032,
            },
            tangent1 = {
              x = 9.9976062774658,
              y = 0.21396194398403,
              z = -0.29356691241264,
            },
            type = 0,
            typeIndex = -1,
            objects = {
              { 0, 2, },
            },
          },
          type = 1,
          params = {
            trackType = 1,
            catenary = true,
          },
          playerOwned = nil,
          streetEdge = {
            streetType = -1,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = 1,
            catenary = true,
          },
        },
      },
      nodesToRemove = {
      },
      edgesToRemove = {
      },
      edgeObjectsToAdd = {
        [1] = {
          edgeEntity = -1,
          param = 0.69431805610657,
          oneWay = false,
          left = true,
          model = "railroad/signal_path_c.mdl",
          playerEntity = 23826,
          name = "Thornbury Signal #1",
        },
      },
      edgeObjectsToRemove = {
      },
    },
    constructionsToAdd = {
    },
    constructionsToRemove = {
    },
    old2new = {
    },
  }
