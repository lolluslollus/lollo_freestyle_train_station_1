package.path = package.path .. ';res/scripts/?.lua'

local edgeUtils = require('lollo_freestyle_train_station.edgeUtils')
local aaa = { 1, 2, 3, 4}
table.remove(aaa, 2)

local myTransf = { 0.7620068192482, 0.64756900072098, 0, 0, -0.64756900072098, 0.7620068192482, 0, 0, 0, 0, 1, 0, 395.39279174805, -998.11505126953, 4.4527878761292, 1, }
local trackEdgeLists = {
    {
      catenary = true,
      posTanX2 = {
        {
          { 419.77224731445, -951.19073486328, 4.307719707489, },
          { -14.625322341919, -54.72110748291, 0.27865925431252, },
        },
        {
          { 387.68124389648, -997.86285400391, 3.8029117584229, },
          { -45.445621490479, -33.788608551025, -1.1843789815903, },
        },
      },
      trackType = 1,
      type = 0,
      typeIndex = -1,
    },
    {
      catenary = true,
      posTanX2 = {
        {
          { 387.68124389648, -997.86285400391, 3.8029117584229, },
          { -46.636291503906, -34.673866271973, -1.2154096364975, },
        },
        {
          { 332.19107055664, -1015.0908813477, 2.1493666172028, },
          { -58.031257629395, 2.776736497879, -1.8332767486572, },
        },
      },
      trackType = 1,
      type = 0,
      typeIndex = -1,
    },
  }

local posTanX2 = trackEdgeLists[1].posTanX2

local edgeXYZLen = edgeUtils.getVectorLength({
    posTanX2[1][1][1] - posTanX2[2][1][1],
    posTanX2[1][1][2] - posTanX2[2][1][2],
    posTanX2[1][1][3] - posTanX2[2][1][3]
})
local edgeTanLen1 = edgeUtils.getVectorLength({
    posTanX2[1][2][1],
    posTanX2[1][2][2],
    posTanX2[1][2][3]
})
local edgeTanLen2 = edgeUtils.getVectorLength({
    posTanX2[2][2][1],
    posTanX2[2][2][2],
    posTanX2[2][2][3]
})
-- up to 6 significant figures, the three lengths above are identical.
-- this data is obtained from a real game.

local dummy = 123
