local transf = require "/scripts/mat4.tl"
local vec3 = require "/scripts/vec3.tl"
local constructionutil = require "/scripts/construction/constructionutil.lua"
local modulesutil = require "/scripts/construction/modulesutil.lua"
local trainstationutil = require "::/stations/rail/trainstationutil.lua"
local laneutil = require "/scripts/construction/laneutil.lua"

local holeFn = function() return {
	{1.6,  -10.0, 0.0, 1.0},
	{1.6,  10.0,  0.0, 1.0},
	{-1.6, 10.0,  0.0, 1.0},
	{-1.6, -10.0, 0.0, 1.0},
} end

local facesPlatformCargoFn = function() return {
	{5.0,  -20.0, 0.0, 1.0},
	{5.0,  20.0,  0.0, 1.0},
	{-5.0, 20.0,  0.0, 1.0},
	{-5.0, -20.0, 0.0, 1.0},
} end

local facesPlatformPassengersFn = function() return {
	{2.5,  -20.0, 0.0, 1.0},
	{2.5,  20.0,  0.0, 1.0},
	{-2.5, 20.0,  0.0, 1.0},
	{-2.5, -20.0, 0.0, 1.0},
} end

local groudFaceModesPlatform = {
	{
		type = "FILL",
		key = "/terrain/materials/gravel_03/gravel_03.gtex"
	},
	{
		type = "STROKE_OUTER",
		key = "/infrastructure/street/shared/street_border.gtex"
	},
}

local groudFaceModesPlatformHole = {
	{
		type = "FILL",
		key = "::/infrastructure/shared/hole.gtex"
	}
}

local addNextAndPrevModelsPlatform = function(result, modelConfig, addModelFn, i, j, z)
	local nextM = result.GetModuleAt(i,j-1)
	local ca =  (nextM and (nextM.metadata.passenger_platform or nextM.metadata.cargo_platform)) or  result.connector[1000 * i + 100 * (j-1) + 7]
	if not ca then
		addModelFn(modelConfig.endPerron, transf.rotZTransl(math.rad(-90), vec3.new(0, -20, z)))
		--addModelFn(modelConfig.endPerronRoof, transf.rotZTransl(math.rad(-90), vec3.new(0, -20, 0)))
	end

	local prevM = result.GetModuleAt(i,j+1)
	local cb = (prevM and (prevM.metadata.passenger_platform or prevM.metadata.cargo_platform)) or  result.connector[1000 * i + 100 * (j+1) + 0]
	if not cb then
		addModelFn(modelConfig.endPerron, transf.rotZTransl(math.rad(90), vec3.new(0, 20, z)))
		--addModelFn(modelConfig.endPerronRoof, transf.rotZTransl(math.rad(90), vec3.new(0, 20, 0)))
	end
end

local addTransformGroundFacesAddonPlatform = function(result, transform, tag)
	local hole = holeFn()
	modulesutil.TransformFaces(transform, hole)
	table.insert(result.groundFaces, {  
		face = hole,
		modes = groudFaceModesPlatformHole,
	})
end

local updateFnAddonPlatformPassengerStairs = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local generatedData = captureParams.generatedData
	local modelConfig = captureParams.modelConfig
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end
	
	addTransformGroundFacesAddonPlatform(result, transform, tag)
	
	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]

	addModelFn(modelConfig.perron, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)), tag)
	
	local tran = transf.mul(transform, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)))
	
	local roof = result.GetRoofAt(i, j)
	
	local num1 = #result.models
	result.addPlatformCallback(i, j, function(left, n, station)
		local ns = tostring(n)
		if result.labelText[num1] == nil then result.labelText[num1] = {"", "", "", ""} end
		if left then
			result.labelText[num1][3] = ns
			result.labelText[num1][4] = ns
		else
			result.labelText[num1][1] = ns
			result.labelText[num1][2] = ns
		end
		local stationS = tostring(station)
		result.labelText[num1 + 1] = {stationS,stationS}
		result.labelText[num1 + 2] = {stationS,stationS}
	
		if left and generatedData["perron_assets_r"] then
			constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets_r"], result, tag, tran)
		elseif not left and generatedData["perron_assets_l"] then
			constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets_l"], result, tag, tran)
		end
	end)
	
	constructionutil.addModelsAndGroups(constrParams, generatedData["main"], result, tag, tran)
	constructionutil.addModelsAndGroups(constrParams, generatedData["name"], result, tag, tran)
	
	if generatedData["perron_underpass_assets"] then
		constructionutil.addModelsAndGroups(constrParams, generatedData["perron_underpass_assets"], result, tag, tran)
	end

	if generatedData["roofless_perron_assets"] then
		if roof then
			constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
		else
			constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
			constructionutil.addModelsAndGroups(constrParams, generatedData["roofless_perron_assets"], result, tag, tran)
		end
	else 
		constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
	end
	
	if  generatedData["lanes_person"] and generatedData["lanes_person"].curves["person_lanes"] then
		local lane = laneutil.createLane(generatedData["lanes_person"].curves["person_lanes"], { "PERSON"} , 30, 30, false)
		lane.transf = tran
		table.insert(result.laneLists, lane)
	end

	addNextAndPrevModelsPlatform(result, modelConfig, addModelFn, i, j, -2)
end

local updateFnBuilding = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local generatedData = captureParams.generatedData
	local config = captureParams.config
	result = result.cargoStation
	local addModelFn = function(a, b, c) 
		addModel(a, b, c, result.models)
	end
	
	local tran, i, j, k, head, side = trainstationutil.MakeMainBuildingModule(result, generatedData, transform, tag, slotId, addModelFn, constrParams, config)

	if generatedData["assets"] then
		constructionutil.addModelsAndGroups(constrParams, generatedData["assets"], result, tag, tran)
	end
	
	if generatedData["lanes_person"] then
		if generatedData["lanes_person"].curves["person_lanes"] then
			local lane = laneutil.createLane(generatedData["lanes_person"].curves["person_lanes"], { "PERSON"} , 30, 30, false)
			lane.transf = tran
			table.insert(result.laneLists, lane)
		end
		if generatedData["lanes_person"].curves["linkable_person_lanes"] then
			local lane = laneutil.createLane(generatedData["lanes_person"].curves["linkable_person_lanes"], { "PERSON"} , 30, 30, true)
			lane.transf = tran
			table.insert(result.laneLists, lane)
		end
	end
	
	if config.always_roof_head then
		if head and config.roof_head then
			addModelFn(config.roof_head, transf.rotZTransl(math.rad(-90), vec3.new(7.5,0,0)))
		elseif config.roof_side then
			addModelFn(config.roof_side, transf.rotZTransl(math.rad(-90), vec3.new(7.5,0,0)))
		end
	else
		if config.roof_head then
			if head then
				local add = false
				for s = -3, 4 do
					local front = result.GetRoofAt(i+s, j)
					if front and front.metadata.platform_roof_curved then
						add = true
						break
					end
				end
				if add then
					addModelFn(config.roof_head, transf.rotZTransl(math.rad(-90), vec3.new(7.5,0,0)))
				end
			else
				if k == 0 then 
					local front = result.GetRoofAt(i, j)
					if front and front.metadata.platform_roof_curved then
						addModelFn(config.roof_side, transf.rotZTransl(math.rad(-90), vec3.new(7.5,0,0)))
					end
				end
			end 
		end
	end

end

local updatePlatformCargo = function(captureParams, result, transform, tag, modelConfig, addModelFn)
	local facesPlatformCargo = facesPlatformCargoFn()
	modulesutil.TransformFaces(transform, facesPlatformCargo)
	local faces2 = { type = "EQUAL", faces = {  facesPlatformCargo } }
	table.insert(result.terrainAlignmentLists, faces2)
	
	local tran = transf.mul(transform, transf.transl(vec3.new(0, 0, 6)))

	table.insert(result.colliders, {
		type = "BOX",
		transf = tran,
		params = {
			halfExtents = { 5, 20, 8 },
		}
	})
		
	table.insert(result.groundFaces, {  
		face = facesPlatformCargo,
		modes = groudFaceModesPlatform,
	})
end

local addNextAndPrevModelsPlatformCargo = function(captureParams, result, transform, generatedData, modelConfig, addModelFn, i, j, constrParams)
	local mainTransf = transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0))
	local mainTransfRelative = transf.mul(transform, mainTransf)

	local nextM = result.GetModuleAt(i+1,j-1)
	local nextM2 = result.GetModuleAt(i,j-1)
	local cb1 = (nextM and (nextM.metadata.passenger_platform or nextM.metadata.cargo_platform)) or result.connector[1000 * (i+1) + 100 * (j-1) + 7]
	local cb2 = (nextM2 and (nextM2.metadata.passenger_platform or nextM2.metadata.cargo_platform)) or result.connector[1000 * (i) + 100 * (j-1) + 7]
	if not cb1 and not cb2 then
		addModelFn(modelConfig.endPerron, transf.rotZTransl(math.rad(-90), vec3.new(0, -20, 0)))
	elseif not cb1 then
		addModelFn(modelConfig.halfEndPerron, transf.rotZTransl(math.rad(-90), vec3.new(2.5, -20, 0)))
	elseif not cb2 then
		addModelFn(modelConfig.halfEndPerron, transf.rotZTransl(math.rad(-90), vec3.new(-2.5, -20, 0)))
	end

	local prevM = result.GetModuleAt(i+1,j+1)
	local prevM2 = result.GetModuleAt(i,j+1)
	local ca1 = (prevM and (prevM.metadata.passenger_platform or prevM.metadata.cargo_platform)) or result.connector[1000 * (i+1) + 100 * (j+1) + 0]
	local ca2 = (prevM2 and (prevM2.metadata.passenger_platform or prevM2.metadata.cargo_platform)) or result.connector[1000 * (i) + 100 * (j+1) + 0]
	if not ca1 and not ca2 then
		addModelFn(modelConfig.endPerron, transf.rotZTransl(math.rad(90), vec3.new(0, 20, 0)))
	elseif not ca1 then
		addModelFn(modelConfig.halfEndPerron, transf.rotZTransl(math.rad(90), vec3.new(2.5, 20, 0)))
	elseif not ca2 then
		addModelFn(modelConfig.halfEndPerron, transf.rotZTransl(math.rad(90), vec3.new(-2.5, 20, 0)))
	end
	
	addModelFn(modelConfig.perron, mainTransf)

	local addNumberOrStation = function(useStation, useLeft)
		local num1 = #result.models
		local call = function(left, n, station)
			if left == useLeft then
				local stationS = useStation and tostring(station) or tostring(n)
				result.labelText[num1 + 0] = {stationS, stationS}
			end
		end
		result.addPlatformCallback(i, j, call)
		result.addPlatformCallback(i+1, j, call)
	end
	
	local roof = result.GetRoofAt(i, j)
	
	local addConnector = function(config, tran)
		if not config then
			return
		end

		if config.model then
			addModelFn(config.model, tran)
		end
		if config.groups then
			local randomGroup = config.groups[math.random(1, #config.groups)]
			if generatedData[randomGroup] then
				constructionutil.addModelsAndGroups(constrParams, generatedData[randomGroup], result, tag, mainTransfRelative)
			end
		end
		if config.name and generatedData[config.name] then
			addNumberOrStation(true, false)
			constructionutil.addModelsAndGroups(constrParams, generatedData[config.name], result, tag, mainTransfRelative)
		end
		if config.leftNumber and generatedData[config.leftNumber] then
			addNumberOrStation(false, false)
			constructionutil.addModelsAndGroups(constrParams, generatedData[config.leftNumber], result, tag, mainTransfRelative)
		end
		if config.rightNumber and generatedData[config.rightNumber] then
			addNumberOrStation(false, true)
			constructionutil.addModelsAndGroups(constrParams, generatedData[config.rightNumber], result, tag, mainTransfRelative)
		end
	end

	if modelConfig.connectors then
		if modelConfig.connectors.main then
			addConnector(modelConfig.connectors.main, mainTransf)
		end

		local next1 = result.GetModuleAt2(i, j-1)
		local nextModel = (next1 and modelConfig.connectors.conn and modelConfig.connectors.conn[next1.metadata.specialization]) 
			and modelConfig.connectors.conn[next1.metadata.specialization] 
			or modelConfig.connectors["end"]
		if nextModel ~= nil then
			addConnector(nextModel, mainTransf)
		end
		local prev1 = result.GetModuleAt2(i, j+1)
		if not (prev1 and modelConfig.connectors.conn and modelConfig.connectors.conn[prev1.metadata.specialization]) then
			addConnector(modelConfig.connectors["start"], mainTransf)
		end
	end
end

local updateFnPlatformCargo = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local generatedData = captureParams.generatedData
	local modelConfig = captureParams.modelConfig

	result = result.cargoStation

	local addModelFn = function(a, b, c) 
		addModel(a, b, c, result.models)
	end

	updatePlatformCargo(captureParams, result, transform, tag, modelConfig, addModelFn)
	
	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]
	
	addNextAndPrevModelsPlatformCargo(captureParams, result, transform, generatedData, modelConfig, addModelFn, i, j, constrParams)

	local tran = transf.mul(transform, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)))
	
	if generatedData["lanes_person"] and generatedData["lanes_person"].curves["person_lanes"] then
		local lane = laneutil.createLane(generatedData["lanes_person"].curves["person_lanes"], { "PERSON"} , 30, 30, false)
		lane.transf = tran
		table.insert(result.laneLists, lane)
	end
end

local updatePlatformPassenger = function(result, transform, modelConfig, addModelFn, i, j)
	local facesPlatformPassengers = facesPlatformPassengersFn()
	modulesutil.TransformFaces(transform, facesPlatformPassengers)
	local faces2 = { type = "EQUAL", faces = { facesPlatformPassengers } }
	table.insert(result.terrainAlignmentLists, faces2)
	
	table.insert(result.colliders, {
		type = "BOX",
		transf = transform,
		params = {
			halfExtents = { 2.5, 20, 6 },
		}
	})
	
	table.insert(result.groundFaces, {  
		face = facesPlatformPassengers,
		modes = groudFaceModesPlatform,
	})

	local bottomM = result.GetModuleAt(i-1,j)
	local connectsBottom = modelConfig.perronBorder and bottomM and bottomM.metadata.track
	if connectsBottom then
		addModelFn(modelConfig.perronBorder, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)))
	end

	local topM = result.GetModuleAt(i+1,j)
	local connectsTop = modelConfig.perronBorder and topM and topM.metadata.track
	if connectsTop then
		addModelFn(modelConfig.perronBorder, transf.rotZTransl(math.rad(270), vec3.new(0, 20, 0)))
	end
end

local updateFnPlatformPassenger = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local generatedData = captureParams.generatedData
	local modelConfig = captureParams.modelConfig
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end
	
	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]
	
	updatePlatformPassenger(result, transform, modelConfig, addModelFn, i, j)

	local hasStairs = result.GetPlatformAddonAt(i, j) and result.GetPlatformAddonAt(i, j).metadata.underground
	
	local roof = result.GetRoofAt(i, j)
	local roofL = result.GetRoofAt(i, j - 1)
	local roofR = result.GetRoofAt(i, j + 1)
	
	if not hasStairs then
		addModelFn(modelConfig.perron, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)), tag)
		
		local tran = transf.mul(transform, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)))
		
		local num1 = #result.models
		result.addPlatformCallback(i, j, function(left, n, station)
			local ns = tostring(n)
			if result.labelText[num1] == nil then result.labelText[num1] = {"", "", "", ""} end
			if left then
				result.labelText[num1][3] = ns
				result.labelText[num1][4] = ns
			else
				result.labelText[num1][1] = ns
				result.labelText[num1][2] = ns
			end
			local stationS = tostring(station)
			result.labelText[num1 + 1] = {stationS,stationS}
			result.labelText[num1 + 2] = {stationS,stationS}

			if left and generatedData["perron_assets_r"] then
				constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets_r"], result, tag, tran)
			elseif not left and generatedData["perron_assets_l"] then
				constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets_l"], result, tag, tran)
			end
		end)
		constructionutil.addModelsAndGroups(constrParams, generatedData["main"], result, tag, tran)
		constructionutil.addModelsAndGroups(constrParams, generatedData["name"], result, tag, tran)

		if generatedData["roofless_perron_assets"] then
			if not roof and not roofL then
				constructionutil.addModelsAndGroups(constrParams, generatedData["roofless_start_perron_assets"], result, tag, tran)
			end
			if not roof and not roofR then
				constructionutil.addModelsAndGroups(constrParams, generatedData["roofless_end_perron_assets"], result, tag, tran)
			end
			if roof then
				constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
			else
				constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
				constructionutil.addModelsAndGroups(constrParams, generatedData["roofless_perron_assets"], result, tag, tran)
			end
		else 
			constructionutil.addModelsAndGroups(constrParams, generatedData["perron_assets"], result, tag, tran)
		end
		
		if generatedData["lanes_person"] and generatedData["lanes_person"].curves["person_lanes"] then
			local lane = laneutil.createLane(generatedData["lanes_person"].curves["person_lanes"], { "PERSON"} , 30, 30, false)
			lane.transf = tran
			table.insert(result.laneLists, lane)
		end

		addNextAndPrevModelsPlatform(result, modelConfig, addModelFn, i, j, 0)
	end
end

local addModelEndPerronRoof = function(result, modelConfig, addModelFn, i, j)
	if modelConfig.endPerronRoof then
		local nextM = result.GetRoofAt(i,j-1)
		local ca = nextM
		if not ca then
			local nextAddonM = result.GetAddonAt(3, -3, i-1)
			if not nextAddonM or nextAddonM[2] ~= j or not nextAddonM[1].metadata.has_roof then
				addModelFn(modelConfig.endPerronRoof, transf.rotZTransl(math.rad(-90), vec3.new(0, -20, -2)))
			end
		end
		local prevM = result.GetRoofAt(i,j+1)
		local cb = prevM
		if not cb then
			local prevAddonM = result.GetAddonAt(4, -3, i-1)
			if not prevAddonM or prevAddonM[2] ~= j or not prevAddonM[1].metadata.has_roof then
				addModelFn(modelConfig.endPerronRoof, transf.rotZTransl(math.rad(90), vec3.new(0, 20, -2)))
			end
		end
	end
end

local updateFnPlatformPassengerRoofCurvedEraC = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local modelConfig = captureParams.modelConfig
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end
	
	addModelFn(modelConfig.perronRoof, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)))
	
	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]
	
	addModelEndPerronRoof(result, modelConfig, addModelFn, i, j)
	if modelConfig.endPerronRoofConnL then
		local lm1 = result.GetModuleAt(i+1,j)
		local lm2 = result.GetRoofAt(i+2,j)

		if lm1 and lm1.metadata.track then
			if (not lm2 or not lm2.metadata.platform_roof_curved) then
				addModelFn(modelConfig.endPerronRoofConnL, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)))
			end
		end
	end
	if modelConfig.endPerronRoofConnR then
		local lp2 = result.GetRoofAt(i-2,j)
		local lp1 = result.GetModuleAt(i-1,j)

		if lp1 and lp1.metadata.track then
			if (not lp2 or not lp2.metadata.platform_roof_curved) then
				addModelFn(modelConfig.endPerronRoofConnR, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)))
			end
		end
	end
end

local updateFnPlatformPassengerRoof = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local modelConfig = captureParams.modelConfig
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end
	
	addModelFn(modelConfig.perronRoof, transf.rotZTransl(math.rad(90), vec3.new(0, -20, -2)))
	
	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]
	
	addModelEndPerronRoof(result, modelConfig, addModelFn, i, j)
end

local updatePlatformPassengerStairs = function(result, transform, tag, modelConfig, addModelFn)
	local facesPlatformPassengers = facesPlatformPassengersFn()
	modulesutil.TransformFaces(transform, facesPlatformPassengers)
	local faces2 = { type = "EQUAL", faces = { facesPlatformPassengers } }
	table.insert(result.terrainAlignmentLists, faces2)
	
	table.insert(result.colliders, {
		type = "BOX",
		transf = transform,
		params = {
			halfExtents = { 2.5, 20, 6 },
		}
	})

	local hole = holeFn()
	modulesutil.TransformFaces(transform, hole)
	table.insert(result.groundFaces, {  
		face = hole,
		modes = groudFaceModesPlatformHole,
	})
	
	table.insert(result.groundFaces, {  
		face = facesPlatformPassengers,
		modes = groudFaceModesPlatform,
	})
	
	addModelFn(modelConfig.perron, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)))
end

local updateFnPlatformPassengerStairs = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	local generatedData = captureParams.generatedData
	local modelConfig = captureParams.modelConfig
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end
	
	updatePlatformPassengerStairs(result, transform, tag, modelConfig, addModelFn)
	
	local tran = transf.mul(transform, transf.rotZTransl(math.rad(90), vec3.new(0, -20, 0)))
	
	if modelConfig.era == 2 then
		constructionutil.addModelsAndGroups(constrParams, generatedData["perron_underpass_assets"], result, tag, tran)
	elseif modelConfig.era == 1 then
		-- PUR YOUR ERA B code here
	else
		constructionutil.addModelsAndGroups(constrParams, generatedData["perron_underpass_assets"], result, tag, tran)
	end

	local coords = result.GetCoord(slotId)
	local i = coords[1]
	local j = coords[2]
	
	addNextAndPrevModelsPlatform(result, modelConfig, addModelFn, i, j, 0)
end

local updateFnStairs = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
	result = result.cargoStation
	local addModelFn = function(a, b, c) addModel(a, b, c, result.models) end

	local faces = {
		{5.0,  -5.0, 0.0, 1.0},
		{5.0,  5.0,  0.0, 1.0},
		{-1.0, 5.0,  0.0, 1.0},
		{-1.0, -5.0, 0.0, 1.0},
	}
	modulesutil.TransformFaces(transform, faces)
	local faces2 = { type = "EQUAL", faces = {  faces } }
	table.insert(result.terrainAlignmentLists, faces2)
	
	table.insert(result.groundFaces, {  
		face = faces,
		modes = {
			{
				type = "FILL",
				key = "shared/asphalt_01.gtex.lua"
			},
			{
				type = "STROKE_OUTER",
				key = "/infrastructure/street/shared/street_border.gtex"
			},
		},
	})
	
	addModelFn("/stations/rail/era_a/stairs.mdl", transf.rotZTransl(math.rad(90), vec3.new(0,0,0)))
end

local getModelsPlatform = function(captureParams, params)
	local modelConfig = captureParams.modelConfig
	local result = {
		{ 
			id = modelConfig.perron,
			transf = transf.rotZTransl(math.rad(90), vec3.new(0,-20,0)),
		},
		{ 
			id = modelConfig.endPerron,
			transf = transf.rotZTransl(math.rad(-90), vec3.new(0,-20,0)),
		},
		{ 
			id = modelConfig.endPerron,
			transf = transf.rotZTransl(math.rad(90), vec3.new(0,20,0)),
		},
	}
	if modelConfig.connectors then
		if modelConfig.connectors.main and modelConfig.connectors.main.model then
			table.insert(result, { 
				id = modelConfig.connectors.main.model,
				transf = transf.rotZTransl(math.rad(90), vec3.new(0,-20,0)),
			})
		end
		if modelConfig.connectors.start and modelConfig.connectors.start.model then
			table.insert(result, { 
				id = modelConfig.connectors.start.model,
				transf = transf.rotZTransl(math.rad(90), vec3.new(0,-20,0)),
			})
		end
		if modelConfig.connectors["end"] and modelConfig.connectors["end"].model then
			table.insert(result, { 
				id = modelConfig.connectors["end"].model,
				transf = transf.rotZTransl(math.rad(90), vec3.new(0,-20,0)),
			})
		end
	end

	return result
end

local getModelsPlatformRoof = function(captureParams, params)
	local modelConfig = captureParams.modelConfig
	local result = {
		{ 
			id = modelConfig.perronRoof,
			transf = transf.rotZTransl(math.rad(90), vec3.new(0,-20,0)),
		},
		{ 
			id = modelConfig.endPerronRoof,
			transf = transf.rotZTransl(math.rad(-90), vec3.new(0,-20,0)),
		},
		{ 
			id = modelConfig.endPerronRoof,
			transf = transf.rotZTransl(math.rad(90), vec3.new(0,20,0)),
		},
	}
	return result
end

local function getModelsFnBuilding(captureParams, params)
	local modelConfig = captureParams.config
	local result = {
		{ 
			id = modelConfig.main,
			transf = transf.rotZTransl(math.rad(-90), vec3.new(15,0,0)),
		},
		{ 
			id = modelConfig.end_left,
			transf = transf.rotZTransl(math.rad(-90), vec3.new(15,0,0)),
		},
		{ 
			id = modelConfig.end_right,
			transf = transf.rotZTransl(math.rad(-90), vec3.new(15,0,0)),
		},
	}
	return result
end

function data()
	return {
		addonPlatformPassengerStairs = {
			updateFn = updateFnAddonPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		addonPlatformPassengerStairsEraB = {
			updateFn = updateFnAddonPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		addonPlatformPassengerStairsEraC = {
			updateFn = updateFnAddonPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		mainBuilding = {
			updateFn = updateFnBuilding,
			getModelsFn = getModelsFnBuilding,
		},
		platformCargoEraA = {
			updateFn = updateFnPlatformCargo,
			getModelsFn = getModelsPlatform,
		},
		platformCargoEraB = {
			updateFn = updateFnPlatformCargo,
			getModelsFn = getModelsPlatform,
		},
		platformCargoEraC = {
			updateFn = updateFnPlatformCargo,
			getModelsFn = getModelsPlatform,
		},
		platformHighSpeedTrackCatenary = {
			updateFn = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
				trainstationutil.makeTrack(result, transform, tag, slotId, addModel, constrParams, 4)
			end,
			getModelsFn = function(captureParams, params)
				return {}
			end
		},
		platformHighSpeedTrack = {
			updateFn = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
				trainstationutil.makeTrack(result, transform, tag, slotId, addModel, constrParams, 3)
			end,
			getModelsFn = function(captureParams, params)
				return {}
			end
		},
		platformTrackCatenary = {
			updateFn = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
				trainstationutil.makeTrack(result, transform, tag, slotId, addModel, constrParams, 2)
			end,
			getModelsFn = function(captureParams, params)
				return {}
			end
		},
		platformTrack = {
			updateFn = function(captureParams, result, transform, tag, slotId, addModel, constrParams)
				trainstationutil.makeTrack(result, transform, tag, slotId, addModel, constrParams, 1)
			end,
			getModelsFn = function(captureParams, params)
				return {}
			end
		},
		platformPassenger = {
			updateFn = updateFnPlatformPassenger,
			getModelsFn = getModelsPlatform,
		},
		platformPassengerRoofCurvedEraC = {
			updateFn = updateFnPlatformPassengerRoofCurvedEraC,
			getModelsFn = getModelsPlatformRoof,
		},
		platformPassengerRoofEraA = {
			updateFn = updateFnPlatformPassengerRoof,
			getModelsFn = getModelsPlatformRoof,
		},
		platformPassengerRoofEraB = {
			updateFn = updateFnPlatformPassengerRoof,
			getModelsFn = getModelsPlatformRoof,
		},
		platformPassengerRoofEraC = {
			updateFn = updateFnPlatformPassengerRoof,
			getModelsFn = getModelsPlatformRoof,
		},
		platformPassengerStairsEraA = {
			updateFn = updateFnPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		platformPassengerStairsEraB = {
			updateFn = updateFnPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		platformPassengerStairsEraC = {
			updateFn = updateFnPlatformPassengerStairs,
			getModelsFn = getModelsPlatform,
		},
		stairs = {
			updateFn = updateFnStairs,
			getModelsFn = function (captureParams, params)
				local result = {
					{ 
						id = "/stations/rail/era_a/stairs.mdl",
						transf = transf.rotZTransl(math.rad(90), vec3.new(0,0,0)),
					},
				}
				return result
			end,
		},
	}
end
