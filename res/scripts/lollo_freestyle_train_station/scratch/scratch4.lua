package.path = package.path .. ';res/scripts/?.lua'
package.path = package.path .. ';C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 2/res/scripts/?.lua'

local logger = require('lollo_freestyle_train_station.logger')
local transfUtils = require('lollo_freestyle_train_station.transfUtils')
local _constants = require('lollo_freestyle_train_station.constants')

local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local dummy = 123

local stationHelpers = require('lollo_freestyle_train_station.stationHelpers')

local edgeLists1 = {
    {
        leadingIndex = 1,
        posTanX2 = {
            {
                {0, 0, 0}, {10, 0, 0}
            },
            {
                {10, 0, 0}, {10, 0, 0}
            },
        },
    },
    {
        leadingIndex = 2,
        posTanX2 = {
            {
                {10, 0, 0}, {10, 0, 0}
            },
            {
                {20, 0, 0}, {10, 0, 0}
            },
        },
    },
}
-- local splits1 = stationHelpers.getCentralEdgePositions(edgeLists1, 7)


local edgeLists2 = {
    {
        catenary = false,
        era = "era_a_",
        leadingIndex = 1,
        posTanX2 = {
            {
                { 72.69287109375, 595.46820068359, 14.149421691895, },
                { 8.4114667253264, 3.1932004397108, -0.22516182892976, },
            },
            {
                { 81.104337819076, 598.66140132421, 13.924259935211, },
                { 8.4114666775778, 3.1932006719572, -0.2251617210165, },
            },
        },
        terrainHeight1 = 14.383262634277,
        trackType = 6,
        trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
        type = 0,
        typeIndex = -1,
        width = 5,
    },
    {
        catenary = false,
        era = "era_a_",
        leadingIndex = 2,
        posTanX2 = {
            {
                { 81.104337819076, 598.66140132421, 13.924259935211, },
                { 8.4114666775778, 3.1932006719572, -0.2251617210165, },
            },
            {
                { 89.515804545154, 601.85460200782, 13.699098189412, },
                { 8.4114666994519, 3.1932006116084, -0.22516175971086, },
            },
        },
        terrainHeight1 = 13.985610961914,
        trackType = 6,
        trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
        type = 0,
        typeIndex = -1,
        width = 5,
    },
    {
        posTanX2 = {
            {
                { 89.515804545154, 601.85460200782, 13.699098189412, },
                { 2.7478825798883, 1.043164129188, -0.073556503196616, },
            },
            {
                { 92.263687133789, 602.89776611328, 13.625541687012, },
                { 2.7478825886346, 1.0431640731434, -0.073556500710351, },
            },
        },
    },
  }

-- local splits2 = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(edgeLists2, 2)

local edgeLists3 = {
    {
      catenary = false,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -139.9704284668, 2353.1716308594, 110.11576080322, },
          { -0.35029852390289, -2.0228176116943, -0.013037061318755, },
        },
        {
          { -140.3207244873, 2351.1489257813, 110.10293579102, },
          { -0.350301861763, -2.0228197574615, -0.012617093510926, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -140.3207244873, 2351.1489257813, 110.10293579102, },
          { -3.228590965271, -18.64351272583, -0.11628666520119, },
        },
        {
          { -143.54928588867, 2332.5056152344, 110.00344085693, },
          { -3.2285737991333, -18.643692016602, -0.083605222404003, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -143.54928588867, 2332.5056152344, 110.00344085693, },
          { -1.8746665716171, -10.825435638428, -0.048545408993959, },
        },
        {
          { -145.42390441895, 2321.6799316406, 109.95977020264, },
          { -1.8746734857559, -10.825554847717, -0.038956969976425, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -145.42390441895, 2321.6799316406, 109.95977020264, },
          { -1.874635219574, -10.825332641602, -0.038956079632044, },
        },
        {
          { -147.2985534668, 2310.8542480469, 109.92517089844, },
          { -1.8746440410614, -10.82536315918, -0.030422085896134, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -147.2985534668, 2310.8542480469, 109.92517089844, },
          { -0.51127368211746, -2.95241355896, -0.0082970531657338, },
        },
        {
          { -147.8098449707, 2307.9020996094, 109.91717529297, },
          { -0.51127403974533, -2.9524164199829, -0.0077123241499066, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -147.8098449707, 2307.9020996094, 109.91717529297, },
          { -0.34084266424179, -1.9682388305664, -0.00514144776389, },
        },
        {
          { -148.15069580078, 2305.9338378906, 109.91216278076, },
          { -0.34085232019424, -1.9682669639587, -0.0048896786756814, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -148.15069580078, 2305.9338378906, 109.91216278076, },
          { -4.1522178649902, -23.977167129517, -0.059565424919128, },
        },
        {
          { -152.30285644531, 2281.9567871094, 109.86915588379, },
          { -4.1521496772766, -23.977235794067, -0.028357073664665, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -152.30285644531, 2281.9567871094, 109.86915588379, },
          { -3.2737874984741, -18.9049949646, -0.022358303889632, },
        },
        {
          { -155.57662963867, 2263.0517578125, 109.85378265381, },
          { -3.2737681865692, -18.905010223389, -0.009324349462986, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -155.57662963867, 2263.0517578125, 109.85378265381, },
          { -0.83014333248138, -4.7938241958618, -0.0023644149769098, },
        },
        {
          { -156.40676879883, 2258.2578125, 109.85173034668, },
          { -0.83013105392456, -4.7938265800476, -0.0017540538683534, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -156.40676879883, 2258.2578125, 109.85173034668, },
          { -0.38651180267334, -2.2320215702057, -0.00081669329665601, },
        },
        {
          { -156.79328918457, 2256.0258789063, 109.85097503662, },
          { -0.38652482628822, -2.2320194244385, -0.00069818960037082, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -156.79328918457, 2256.0258789063, 109.85097503662, },
          { -0.38929349184036, -2.2480072975159, -0.00070319068618119, },
        },
        {
          { -157.18257141113, 2253.7778320313, 109.85032653809, },
          { -0.38928410410881, -2.2480089664459, -0.00059283361770213, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.18257141113, 2253.7778320313, 109.85032653809, },
          { -0.094450138509274, -0.54542362689972, -0.00014383638335858, },
        },
        {
          { -157.27702331543, 2253.232421875, 109.85018920898, },
          { -0.094452515244484, -0.54542320966721, -0.00013722422590945, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.27702331543, 2253.232421875, 109.85018920898, },
          { -0.094370432198048, -0.54494917392731, -0.00013710495841224, },
        },
        {
          { -157.37138366699, 2252.6875, 109.85005187988, },
          { -0.094362020492554, -0.54495060443878, -0.00013150545419194, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.37138366699, 2252.6875, 109.85005187988, },
          { -0.18873094022274, -1.0899410247803, -0.00026302054175176, },
        },
        {
          { -157.5601348877, 2251.5974121094, 109.84980010986, },
          { -0.18874357640743, -1.0899388790131, -0.00023935954959597, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.5601348877, 2251.5974121094, 109.84980010986, },
          { -0.37784859538078, -2.1819648742676, -0.00047917745541781, },
        },
        {
          { -157.93798828125, 2249.4155273438, 109.84936523438, },
          { -0.37785297632217, -2.1819641590118, -0.00039299696800299, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = true,
      edgeType = "BRIDGE",
      edgeTypeName = "stone.lua",
      era = "era_c_",
      posTanX2 = {
        {
          { -157.93798828125, 2249.4155273438, 109.84936523438, },
          { -0.77880698442459, -4.4973282814026, -0.00081002083607018, },
        },
        {
          { -158.716796875, 2244.9182128906, 109.84871673584, },
          { -0.77880668640137, -4.4973282814026, -0.00049793208017945, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 1,
      typeIndex = 2,
      width = 2.5,
    },
    {
      catenary = false,
      era = "era_c_",
      posTanX2 = {
        {
          { -158.716796875, 2244.9182128906, 109.84871673584, },
          { -1.1986937522888, -6.9220266342163, -0.00076638802420348, },
        },
        {
          { -159.89352416992, 2237.9924316406, 109.84844207764, },
          { -1.1550387144089, -6.9294452667236, -3.673996161524e-06, },
        },
      },
      trackType = 19,
      trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_2_5m.lua",
      type = 0,
      typeIndex = -1,
      width = 2.5,
    },
  }

-- local splits3 = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(edgeLists2, 9)

local edgeLists4 = {
    {
      catenary = false,
      era = "era_a_",
      posTanX2 = {
        {
          { 14.894147872925, 746.41479492188, 20.958518981934, },
          { 1.1838198900223, 14.957947731018, 0.1933785378933, },
        },
        {
          { 16.077968597412, 761.37274169922, 21.15189743042, },
          { 1.183819770813, 14.957947731018, 0.19337843358517, },
        },
      },
      trackType = 6,
      trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
      type = 0,
      typeIndex = -1,
      width = 5,
    },
    {
      catenary = false,
      era = "era_a_",
      posTanX2 = {
        {
          { 16.077968597412, 761.37274169922, 21.15189743042, },
          { 1.183819770813, 14.957947731018, 0.19337843358517, },
        },
        {
          { 17.261787414551, 776.33068847656, 21.345275878906, },
          { 1.1838198900223, 14.957947731018, 0.19337847828865, },
        },
      },
      trackType = 6,
      trackTypeName = "lollo_freestyle_train_station/era_a_passenger_platform_5m.lua",
      type = 0,
      typeIndex = -1,
      width = 5,
    },
  }
-- local splits4 = stationHelpers.getCentralEdgePositions_OnlyOuterBounds(edgeLists4, 40)

local fineEdgeLists = {
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -182.4990991044, 2378.6369230797, 110.24574080924, },
        { -0.17062727808156, -0.98530095145316, -0.0082684363679345, },
      },
      {
        { -182.66972549193, 2377.6516271449, 110.23752959459, },
        { -0.17062739358231, -0.98530188334269, -0.0081542161274083, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -182.66972549193, 2377.6516271449, 110.23752959459, },
        { -0.17062739358231, -0.98530188334269, -0.0081542161274083, },
      },
      {
        { -182.84035182743, 2376.6663312063, 110.22943221169, },
        { -0.17062749254949, -0.9853027984002, -0.008040786716472, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -182.84035182743, 2376.6663312063, 110.22943221169, },
        { -0.17062749254949, -0.9853027984002, -0.008040786716472, },
      },
      {
        { -183.01097809766, 2375.6810352618, 110.22144786934, },
        { -0.17062757502897, -0.98530369689082, -0.0079281481459904, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.01097809766, 2375.6810352618, 110.22144786934, },
        { -0.17062757502897, -0.98530369689082, -0.0079281481459904, },
      },
      {
        { -183.18160428935, 2374.6957393092, 110.21357577636, },
        { -0.17062764106633, -0.98530457907785, -0.0078163004266021, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.18160428935, 2374.6957393092, 110.21357577636, },
        { -0.17062764106633, -0.98530457907785, -0.0078163004266021, },
      },
      {
        { -183.35223038926, 2373.7104433465, 110.20581514155, },
        { -0.1706276907068, -0.98530544522276, -0.0077052435687226, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.35223038926, 2373.7104433465, 110.20581514155, },
        { -0.1706276907068, -0.98530544522276, -0.0077052435687226, },
      },
      {
        { -183.52285638413, 2372.7251473715, 110.19816517371, },
        { -0.17062772399531, -0.98530629558513, -0.0075949775825474, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.52285638413, 2372.7251473715, 110.19816517371, },
        { -0.17062772399531, -0.98530629558513, -0.0075949775825474, },
      },
      {
        { -183.6934822607, 2371.7398513823, 110.19062508166, },
        { -0.17062774097648, -0.98530713042275, -0.0074855024780553, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.6934822607, 2371.7398513823, 110.19062508166, },
        { -0.17062774097648, -0.98530713042275, -0.0074855024780553, },
      },
      {
        { -183.86410800572, 2370.7545553765, 110.18319407419, },
        { -0.17062774169459, -0.98530794999152, -0.0073768182650113, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -183.86410800572, 2370.7545553765, 110.18319407419, },
        { -0.17062774169459, -0.98530794999152, -0.0073768182650113, },
      },
      {
        { -184.03473360593, 2369.7692593523, 110.17587136011, },
        { -0.17062772619361, -0.98530875454551, -0.0072689249529699, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -184.03473360593, 2369.7692593523, 110.17587136011, },
        { -0.17062772619361, -0.98530875454551, -0.0072689249529699, },
      },
      {
        { -184.20535904808, 2368.7839633074, 110.16865614823, },
        { -0.17062769451721, -0.98530954433695, -0.0071618225512779, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
  {
    catenary = true,
    era = "era_c_",
    posTanX2 = {
      {
        { -184.20535904808, 2368.7839633074, 110.16865614823, },
        { -0.13863704815099, -0.80057582169404, -0.0058190667153991, },
      },
      {
        { -184.34399414063, 2367.9833984375, 110.16287231445, },
        { -0.13863503362107, -0.80056487775794, -0.0057487512370337, },
      },
    },
    trackType = 20,
    trackTypeName = "lollo_freestyle_train_station/era_c_passenger_platform_5m.lua",
    type = 0,
    typeIndex = -1,
    width = 5,
  },
}
local groups1 = stationHelpers.calcCentralEdgePositions_GroupByMultiple(fineEdgeLists, 10)



local dummy2 = 123
