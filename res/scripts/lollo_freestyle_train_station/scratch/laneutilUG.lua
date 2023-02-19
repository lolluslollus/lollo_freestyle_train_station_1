local vec3 = require "vec3"
local streetutil = require "streetutil"

local laneutil = { }

local function subtract(a, b)
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end 

local function scale(a, b)
	return { a[1] * b, a[2] * b, a[3] * b }
end 

function laneutil.createLanes(data, transportModes, speed, width, linkable)
	assert(data.curves ~= nil)

	local result = { nodes = {} }
	if speed then result.speedLimit = speed end
	if linkable then result.linkable = linkable end
	result.transportModes = transportModes
	
	local w = 0
	if width then w = width end
	
	for k, v in pairs(data.curves) do
		local nodes = result.nodes
		for i=1, #v do
			local points = v[i]
			if #points == 2 then
				local tangent = subtract(points[2], points[1])
				nodes[#nodes + 1] = { points[1], tangent, w }
				nodes[#nodes + 1] = { points[2], tangent, w }
			elseif #points == 3 then
				local tangent1 = scale(subtract(points[2], points[1]), 2.0)
				local tangent2 = scale(subtract(points[3], points[2]), 2.0)
				nodes[#nodes + 1] = { points[1], tangent1, w }
				nodes[#nodes + 1] = { points[3], tangent2, w }
			elseif #points == 4 then
				local tangent1 = scale(subtract(points[2], points[1]), 3.0)
				local tangent2 = scale(subtract(points[4], points[3]), 3.0)
				nodes[#nodes + 1] = { points[1], tangent1, w }
				nodes[#nodes + 1] = { points[4], tangent2, w }
			else
				assert(false)
			end
		end
	end	
	
	return result
end

return laneutil
