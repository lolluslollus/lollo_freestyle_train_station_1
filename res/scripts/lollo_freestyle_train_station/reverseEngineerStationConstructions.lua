local _constants = require('lollo_freestyle_train_station.constants')
local searchRadius = 500
local transf = _constants.idTransf
local transfUtils = require('lollo_freestyle_train_station.transfUtils')

local squareCentrePosition = transfUtils.getVec123Transformed({0, 0, 0}, transf)
local cons = game.interface.getEntities(
    {pos = squareCentrePosition, radius = searchRadius},
    {type = "CONSTRUCTION", includeData = true, fileName = _constants.stationConFileNameLong}
)
-- returns all constructions of the given type, with type table
-- api.engine.getComponent(25322, api.type.ComponentType.CONSTRUCTION) returns very similar data
-- with better names (frozenEdges and frozenNodes)
-- and the depots
-- and no name; to get the name, call api.engine.getComponent(25322, api.type.ComponentType.NAME)
local sampleCons = {
    [25322] = {
        baseEdges = { 25262, 25291, 25294, 25295, 25302, },
        baseNodes = { 25325, 25326, 25301, 25323, },
        dateBuilt = {
            day = 14,
            month = 1,
            year = 1970,
        },
        depots = { },
        fileName = "station/rail/lollo_freestyle_train_station/station.con",
        id = 25322,
        name = "construction name",
        params = {
            myTransf = { 0.93987399339676, 0.34152144193649, 0, 0, -0.34152144193649, 0.93987399339676, 0, 0, 0, 0, 1, 0, -1344.6668701172, -1272.1446533203, 7.7583150863647, 1, },
            platformEdgeLists = {
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1396.1495361328, -1290.8518066406, 7.3458642959595, },
                    { 29.953483581543, 10.884223937988, -0.06839232891798, },
                },
                {
                    { -1366.1960449219, -1279.9676513672, 7.2774720191956, },
                    { 29.953477859497, 10.884208679199, -0.068392097949982, },
                },
                },
                trackType = 2,
                trackTypeName = "platform.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1366.1960449219, -1279.9676513672, 7.2774720191956, },
                    { 92.668678283691, 33.673049926758, -0.21158829331398, },
                },
                {
                    { -1273.52734375, -1246.2946777344, 7.0658836364746, },
                    { 92.668670654297, 33.673046112061, -0.21158821880817, },
                },
                },
                trackType = 2,
                trackTypeName = "platform.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1273.52734375, -1246.2946777344, 7.0658836364746, },
                    { 92.668655395508, 33.673046112061, -0.21158820390701, },
                },
                {
                    { -1180.8587646484, -1212.6215820313, 6.854296207428, },
                    { 92.668670654297, 33.673049926758, -0.21158823370934, },
                },
                },
                trackType = 2,
                trackTypeName = "platform.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1180.8587646484, -1212.6215820313, 6.854296207428, },
                    { 92.668663024902, 33.673053741455, -0.21158823370934, },
                },
                {
                    { -1088.1900634766, -1178.9484863281, 6.6427073478699, },
                    { 92.668655395508, 33.673046112061, -0.21158817410469, },
                },
                },
                trackType = 2,
                trackTypeName = "platform.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1088.1900634766, -1178.9484863281, 6.6427073478699, },
                    { 65.523323059082, 23.809236526489, -0.14960788190365, },
                },
                {
                    { -1022.6666259766, -1155.1391601563, 6.4931001663208, },
                    { 65.523429870605, 23.809371948242, -0.14960753917694, },
                },
                },
                trackType = 2,
                trackTypeName = "platform.lua",
                type = 0,
                typeIndex = -1,
            },
            },
            seed = 1230000,
            trackEdgeLists = {
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1381.0095214844, -1280.0306396484, 7.3073964118958, },
                    { 13.105888366699, 4.7622952461243, -0.029924362897873, },
                },
                {
                    { -1367.9036865234, -1275.2683105469, 7.2774720191956, },
                    { 13.105889320374, 4.7622928619385, -0.029924379661679, },
                },
                },
                trackType = 1,
                trackTypeName = "standard.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1367.9036865234, -1275.2683105469, 7.2774720191956, },
                    { 92.668670654297, 33.673049926758, -0.21158827841282, },
                },
                {
                    { -1275.2349853516, -1241.5953369141, 7.0658836364746, },
                    { 92.668663024902, 33.673046112061, -0.21158820390701, },
                },
                },
                trackType = 1,
                trackTypeName = "standard.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1275.2349853516, -1241.5953369141, 7.0658836364746, },
                    { 92.668655395508, 33.673046112061, -0.21158820390701, },
                },
                {
                    { -1182.56640625, -1207.9222412109, 6.854296207428, },
                    { 92.668670654297, 33.673049926758, -0.21158823370934, },
                },
                },
                trackType = 1,
                trackTypeName = "standard.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1182.56640625, -1207.9222412109, 6.854296207428, },
                    { 92.668663024902, 33.673053741455, -0.21158823370934, },
                },
                {
                    { -1089.8977050781, -1174.2491455078, 6.6427073478699, },
                    { 92.668655395508, 33.673046112061, -0.21158817410469, },
                },
                },
                trackType = 1,
                trackTypeName = "standard.lua",
                type = 0,
                typeIndex = -1,
            },
            {
                catenary = true,
                posTanX2 = {
                {
                    { -1089.8977050781, -1174.2491455078, 6.6427073478699, },
                    { 48.673358917236, 17.686458587646, -0.11113475263119, },
                },
                {
                    { -1041.2243652344, -1156.5626220703, 6.5315728187561, },
                    { 48.673332214355, 17.686532974243, -0.11113391071558, },
                },
                },
                trackType = 1,
                trackTypeName = "standard.lua",
                type = 0,
                typeIndex = -1,
            },
            },
        },
        particleSystems = { },
        position = { -1218.8896484375, -1222.7673339844, 9.9194841384888, },
        simBuildings = { },
        stations = { 25332, },
        townBuildings = { },
        transf = { 0.93987399339676, 0.34152144193649, 0, 0, -0.34152144193649, 0.93987399339676, 0, 0, 0, 0, 1, 0, -1344.6668701172, -1272.1446533203, 7.7583150863647, 1, },
        type = "CONSTRUCTION",
        },
}

local stationGroups = game.interface.getEntities(
    {pos = squareCentrePosition, radius = searchRadius},
    {type = "STATION_GROUP", includeData = true, fileName = _constants.stationConFileNameLong}
)
-- returns all station groups, ignoring the file name, with type table
-- it is the only one to know the names
-- api.engine.getComponent(25333, api.type.ComponentType.STATION_GROUP) returns
-- {
--     stations = {
--         [1] = 25332,
--     },
-- }
-- api.engine.getComponent(25333, api.type.ComponentType.NAME) returns the correct UI name
local sampleStationGroups = {
    [25333] = {
        cargoWaiting = { },
        id = 25333,
        itemsLoaded = {
            _lastMonth = {
            _sum = 0,
            },
            _lastYear = {
            _sum = 0,
            },
            _sum = 0,
        },
        itemsUnloaded = {
            _lastMonth = {
            _sum = 0,
            },
            _lastYear = {
            _sum = 0,
            },
            _sum = 0,
        },
        name = "lollo1",
        position = { -1239.4377441406, -1230.4334716797, 9.4942855834961, },
        stations = { 25332, },
        type = "STATION_GROUP",
        },
}

local stations = game.interface.getEntities(
    {pos = squareCentrePosition, radius = searchRadius},
    {type = "STATION", includeData = true, fileName = _constants.stationConFileNameLong}
)
-- returns all stations, ignoring the file name, with type table
local sampleStations = {
    [25332] = {
        cargo = true,
        carriers = {
            RAIL = true,
        },
        id = 25332,
        name = "construction name",
        position = { -1239.4377441406, -1230.4334716797, 9.4942855834961, },
        stationGroup = 25333, -- you can also get it with api.engine.system.stationGroupSystem.getStationGroup(25332)
        town = 21550,
        type = "STATION",
        },
}
-- api.engine.getComponent(25332, api.type.ComponentType.STATION) returns
-- {
--     cargo = true,
--     terminals = {
--         [1] = userdata: 00000202A373FB18,
--     },
--     tag = 0,
-- }