-- bulldozing a freestyle station, conParamsBak exists and has type	table
local param = 
{
  data = {
    collisionInfo = {
      collisionEntities = {
      },
      autoRemovalEntity2models = {
      },
      fieldEntities = {
      },
      buildingEntities = {
      },
    },
    entity2tn = {
      [26403] = {
        nodes = {
          [1] = {
          },
        },
        edges = {
        },
      },
      [26507] = {
        nodes = {
        },
        edges = {
          [1] = {
            conns = {
              [1] = {
                new = nil,
                entity = 26403,
                index = 0,
              },
              [2] = {
                new = nil,
                entity = 26373,
                index = 0,
              },
            },
            geometry = {
              params = {
                pos = {
                  x = -2367.2951660156,
                  y = -2070.3081054688,
                },
                tangent = {
                  x = 11.565076828003,
                  y = -2.7709228992462,
                },
              },
              tangent = {
                x = 0.091226138174534,
                y = 0.078497402369976,
              },
              height = {
                x = 19.710075378418,
                y = 19.784212112427,
              },
              length = 11.904690742493,
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
            curveSpeedLimit = 13.259494781494,
            curSpeed = 13.259494781494,
            precedence = false,
          },
        },
      },
      [26409] = {
        nodes = {
          [1] = {
          },
        },
        edges = {
        },
      },
      [26506] = {
        nodes = {
        },
        edges = {
          [1] = {
            conns = {
              [1] = {
                new = nil,
                entity = 6818,
                index = 0,
              },
              [2] = {
                new = nil,
                entity = 26409,
                index = 0,
              },
            },
            geometry = {
              params = {
                pos = {
                  x = -2419.8515625,
                  y = -2182.3837890625,
                },
                tangent = {
                  x = -2.1471333503723,
                  y = 4.4316811561584,
                },
              },
              tangent = {
                x = -0.22775866091251,
                y = -0.22751598060131,
              },
              height = {
                x = 22.749338150024,
                y = 22.521579742432,
              },
              length = 4.9296908378601,
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
      },
    },
    tpNetLinkProposal = {
      toRemove = {
      },
      toAdd = {
      },
    },
    costs = 0,
    errorState = {
      critical = false,
      messages = {
      },
      warnings = {
      },
    },
  },
  proposal = {
    proposal = {
      addedNodes = {
      },
      addedSegments = {
      },
      removedNodes = {
        [1] = {
          comp = {
            position = {
              x = -2426.1489257813,
              y = -2084.9645996094,
              z = 18.958381652832,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26456,
        },
        [2] = {
          comp = {
            position = {
              x = -2432.798828125,
              y = -2155.6606445313,
              z = 20.845947265625,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26411,
        },
        [3] = {
          comp = {
            position = {
              x = -2385.0415039063,
              y = -2064.7985839844,
              z = 19.039546966553,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26499,
        },
        [4] = {
          comp = {
            position = {
              x = -2422.5068359375,
              y = -2088.3903808594,
              z = 18.958381652832,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26398,
        },
        [5] = {
          comp = {
            position = {
              x = -2437.2985839844,
              y = -2157.8408203125,
              z = 20.845947265625,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26503,
        },
        [6] = {
          comp = {
            position = {
              x = -2432.9826660156,
              y = -2166.7485351563,
              z = 21.303743362427,
            },
            doubleSlipSwitch = false,
            trafficLightPreference = 2,
          },
          entity = 26500,
        },
      },
      removedSegments = {
        [1] = {
          entity = 26380,
          comp = {
            node0 = 26456,
            node1 = 26499,
            tangent0 = {
              x = 33.140613555908,
              y = 35.232791900635,
              z = -0.26145073771477,
            },
            tangent1 = {
              x = 46.09049987793,
              y = 4.4532451629639,
              z = 0.32076120376587,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 2,
            catenary = false,
          },
          playerOwned = {
            player = 19278,
          },
          streetEdge = {
            streetType = -1,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = 2,
            catenary = false,
          },
        },
        [2] = {
          entity = 26387,
          comp = {
            node0 = 26409,
            node1 = 26411,
            tangent0 = {
              x = -10.800157546997,
              y = 22.291511535645,
              z = -1.1444108486176,
            },
            tangent1 = {
              x = -10.800132751465,
              y = 22.29146194458,
              z = -1.1456311941147,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 1,
            catenary = true,
          },
          playerOwned = {
            player = 19278,
          },
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
        [3] = {
          entity = 26406,
          comp = {
            node0 = 26398,
            node1 = 26403,
            tangent0 = {
              x = 39.805053710938,
              y = 42.317958831787,
              z = -0.31402739882469,
            },
            tangent1 = {
              x = 56.4970703125,
              y = -13.536357879639,
              z = 0.44565284252167,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 1,
            catenary = true,
          },
          playerOwned = {
            player = 19278,
          },
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
        [4] = {
          entity = 26408,
          comp = {
            node0 = 26503,
            node1 = 26456,
            tangent0 = {
              x = -35.253570556641,
              y = 72.76335144043,
              z = -3.7395465373993,
            },
            tangent1 = {
              x = 55.396839141846,
              y = 58.894054412842,
              z = -0.43703308701515,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 2,
            catenary = false,
          },
          playerOwned = {
            player = 19278,
          },
          streetEdge = {
            streetType = -1,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = 2,
            catenary = false,
          },
        },
        [5] = {
          entity = 26457,
          comp = {
            node0 = 26500,
            node1 = 26503,
            tangent0 = {
              x = -4.3157544136047,
              y = 8.9077119827271,
              z = -0.45779660344124,
            },
            tangent1 = {
              x = -4.3157558441162,
              y = 8.90771484375,
              z = -0.45779657363892,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 2,
            catenary = false,
          },
          playerOwned = {
            player = 19278,
          },
          streetEdge = {
            streetType = -1,
            hasBus = false,
            tramTrackType = 0,
            precedenceNode0 = 2,
            precedenceNode1 = 2,
          },
          trackEdge = {
            trackType = 2,
            catenary = false,
          },
        },
        [6] = {
          entity = 26484,
          comp = {
            node0 = 26411,
            node1 = 26398,
            tangent0 = {
              x = -32.541721343994,
              y = 67.166084289551,
              z = -3.4518847465515,
            },
            tangent1 = {
              x = 51.135478973389,
              y = 54.363677978516,
              z = -0.40341466665268,
            },
            type = 0,
            typeIndex = -1,
            objects = { },
          },
          type = 1,
          params = {
            trackType = 1,
            catenary = true,
          },
          playerOwned = {
            player = 19278,
          },
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
      edgeObjectsToRemove = {
      },
      edgeObjectsToAdd = {
      },
      new2oldNodes = {
      },
      old2newNodes = {
      },
      new2oldSegments = {
      },
      old2newSegments = {
      },
      new2oldEdgeObjects = {
      },
      old2newEdgeObjects = {
      },
      frozenNodes = {
      },
    },
    terrainAlignSkipEdges = {
    },
    segmentTags = {
    },
    toRemove = {
      [1] = 26415,
    },
    toAdd = {
    },
    old2new = {
    },
    parcelsToRemove = {
    },
  },
  result = {
  },
}