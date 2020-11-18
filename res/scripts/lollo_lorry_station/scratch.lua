package.path = package.path .. ';res/scripts/?.lua'

local arrayUtils = require('lollo_lorry_station/arrayUtils')
local stringUtils = require('lollo_lorry_station/stringUtils')

local _modConstants = require('lollo_lorry_station/constants')
-- local edgeUtils = require('lollo_lorry_station/edgeHelper')
-- local slotUtils = require('lollo_lorry_station/slotHelpers')

local transfStr = '((0.594247 / -0.804282 / 0 / 0)/(0.804282 / 0.594247 / 0 / 0)/(0 / 0 / 1 / 0)/(-3463.13 / 3196.42 / 55.4744 / 1))'
local function _getTransfFromApiResult(transfStr)
	transfStr = transfStr:gsub('%(%(', '(')
	transfStr = transfStr:gsub('%)%)', ')')
	local results = {}
	for match0 in transfStr:gmatch('%([^(%))]+%)') do
		local noBrackets = match0:gsub('%(', '')
		noBrackets = noBrackets:gsub('%)', '')
		for match1 in noBrackets:gmatch('[%-%.%d]+') do
			results[#results + 1] = match1
		end
	end
	return results
end

local transf1 = _getTransfFromApiResult(transfStr)
local dummy = 0

local n1 = -1440.7044677734
local n1000 = math.ceil(n1 * 1000) / 1000
local tab1 = {
	a = {
		aa = 1,
		bb = 2,
		cc = {
			aaa = 2,
			bbb = 2,
			ccc = {
				aaaa = 3,
			}
		}
	}
}

local tab1Cloned = arrayUtils.cloneDeepOmittingFields(tab1)
tab1Cloned.a.cc.ccc.aaaa = 99999
local dummy = 0
-- only for testing
-- if math.atan2 == nil then
-- 	math.atan2 = function(dy, dx)
-- 		local result = 0
-- 		if dx == 0 then
-- 			result = math.pi * 0.5
-- 		else
-- 			result = math.atan(dy / dx)
-- 		end

-- 		if dx > 0 then
-- 			return result
-- 		elseif dx < 0 and dy >= 0 then
-- 			return result + math.pi
-- 		elseif dx < 0 and dy < 0 then
-- 			return result - math.pi
-- 		elseif dy > 0 then
-- 			return result
-- 		elseif dy < 0 then
-- 			return - result
-- 		else return false
-- 		end
-- 	end
-- end

-- local _constants = arrayUtils.addProps(
-- 	{
-- 		innerSpacing4x4 = {0.0, 0.0, 0.0, 0.0}, -- {5, 5, 5, 5},
-- 		-- the smaller these guys, the closer to the road I can fill a slot without it turning red.
-- 		-- negative values don't matter, the api takes up the abs value
-- 		-- anyStreetsideSpacing = {0.1, 0.1, 0.1, 0.1},
-- 		anyStreetsideSpacing = {0.0, 0.0, 0.0, 0.0},
-- 		idBases = { -- LOLLO NOTE keep this sorted descending
-- 			cargoAreaInner15x15SlotId = 120000,
--             baySlotIdBase = 110000,
--             lollo = 1333,
--             lalla = 999999999999
-- 		},
-- 		idRoundingFactor = 100
-- 	},
-- 	_modConstants
-- )
-- local _idBasesSortedDesc = {}
-- for k, v in pairs(_constants.idBases) do
--     table.insert(_idBasesSortedDesc, {id = v, name = k})
-- end
-- arrayUtils.sort(_idBasesSortedDesc, 'id', false)

-- local mangleId = function(x, y, baseId)
-- 	return baseId + _constants.idRoundingFactor * (y  - _constants.yMin) + (x  - _constants.xMin)
-- end

-- -- result.demangleId = function(slotId)
-- -- 	local rem = slotId % 100
-- -- 	local variant = rem
-- -- 	slotId = (slotId - rem) / 100
-- -- 	rem = slotId % 2000
-- -- 	local coordI = rem - 100
-- -- 	slotId = (slotId - rem) / 2000
-- -- 	return coordI, slotId - 100, variant
-- -- end

-- local demangleId = function(slotId)
-- 	local function _getIdBase(slotId)
-- 		local baseId = 0
-- 		for _, v in pairs(_idBasesSortedDesc) do
-- 			if slotId >= v.id then
-- 				baseId = v.id
-- 				break
-- 			end
-- 		end

-- 		return baseId > 0 and baseId or false
-- 	end

-- 	local baseId = _getIdBase(slotId)
-- 	if not baseId then return false, false, false end

-- 	local y = math.floor((slotId - baseId) / _constants.idRoundingFactor)
-- 	local x = math.floor((slotId - baseId - y * _constants.idRoundingFactor))

-- 	return x + _constants.xMin, y + _constants.yMin, baseId
-- end

-- local mangledIds = {}
-- for x = _constants.xMin, _constants.xMax do
-- 	for y = _constants.yMin, _constants.yMax do
-- 		mangledIds[#mangledIds + 1] = mangleId(x, y, _constants.idBases.cargoAreaInner15x15SlotId)
-- 	end
-- end

-- local demangledIds = {}
-- for i = 1, #mangledIds do
-- 	local x, y, baseId = demangleId(mangledIds[i])
-- 	demangledIds[#demangledIds + 1] = {x, y, baseId}
-- end
-- game = {
-- 	interface = {}
-- }
-- game.interface.getHeight = function(fff)
-- 	return 0
-- end

-- local nested1 = {}
-- slotUtils.setValueInNestedTable(nested1, 'A', 2, 2)
-- slotUtils.setValueInNestedTable(nested1, 'A', 4, 2)
-- slotUtils.setValueInNestedTable(nested1, 'A', 4, 3)
-- slotUtils.setValueInNestedTable(nested1, 'A', -4, 3)
-- slotUtils.setValueInNestedTable(nested1, 'A', -4, -3)
-- local flat = slotUtils.getFlatTable(nested1)

-- local edge0 = {
-- 	{0, 0, 0},
-- 	{-1, 1, 0}
-- }
-- -- local edge1 = {
-- -- 	{10, 0, 0},
-- -- 	{1, 0, 0}
-- -- }
-- local edge1 = {
-- 	{-10, 10, 0},
-- 	{-1, 1, 0}
-- }
-- local edgeMiddle = edgeUtils.getEdgeBetween(edge0, edge1)

-- print('source 0 = ', debug.getinfo(0).source)
-- print('source 1 = ', debug.getinfo(1).source)
-- local currentFileName = debug.getinfo(1).source
-- local currentFileNameEnd = string.sub(currentFileName, string.len(currentFileName) - 5)
-- local id = currentFileNameEnd:sub(1, 2)

-- local getIdFromFileName = function()
--     local currentFileName = debug.getinfo(2).source
--     local fileNameEnd = string.sub(currentFileName, string.len(currentFileName) - 5)
--     return fileNameEnd:sub(1, 2)
-- end

-- local id = getIdFromFileName()

-- local par = { lollo = true }
