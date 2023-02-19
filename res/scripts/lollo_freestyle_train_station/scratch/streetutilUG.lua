local vec3 = require "vec3"

local streetutil = { }

function streetutil.calcScale(dist, angle)
	if (angle < .001) then
		return dist
	end

	local pi = 3.14159
	local pi2 = pi / 2
	local sqrt2 = 1.41421

	local scale = 1.0
	if (angle >= pi2) then
		scale = 1.0 + (sqrt2 - 1.0) * ((angle - pi2) / pi2)
	end

	return .5 * dist / math.cos(.5 * pi - .5 * angle) * angle * scale
end

function streetutil.addStraightEdge(edges, p0, p1)
	local s0 = { p0.x, p0.y, p0.z }
	local s1 = { p1.x, p1.y, p1.z }
	local q = vec3.sub(p1, p0)
	local t = { q.x, q.y, q.z }

	edges[#edges + 1] = { s0, t }
	edges[#edges + 1] = { s1, t }
end

function streetutil.addRamp(edges, p0, p1)
	--compute ramp with slope 0 at both endpoints

	local s0 = { p0.x, p0.y, p0.z }
	local s1 = { p1.x, p1.y, p1.z }

	local approxLen = vec3.distance(p0, p1)
	local normalizedXYTangent = vec3.normalize(vec3.new(p1.x - p0.x, p1.y - p0.y, 0))
	local q = vec3.mul(approxLen, normalizedXYTangent)
	local t = { q.x, q.y, q.z }

	edges[#edges + 1] = { s0, t }
	edges[#edges + 1] = { s1, t }
end

function streetutil.addEdge(edges, p0, p1, t0, t1)
	edges[#edges + 1] = { { p0.x, p0.y, p0.z }, { t0.x, t0.y, t0.z } }
	edges[#edges + 1] = { { p1.x, p1.y, p1.z }, { t1.x, t1.y, t1.z } }
end

function streetutil.addEdgeAutoTangents(edges, p0, p1, t0, t1)
	local q0 = vec3.normalize(t0)
	local q1 = vec3.normalize(t1)

	local length = vec3.distance(p0, p1)
	local angle = vec3.angleUnit(q0, q1)

	local scale = streetutil.calcScale(length, angle)

	q0 = vec3.mul(scale, q0)
	q1 = vec3.mul(scale, q1)

	edges[#edges + 1] = { { p0.x, p0.y, p0.z }, { q0.x, q0.y, q0.z } }
	edges[#edges + 1] = { { p1.x, p1.y, p1.z }, { q1.x, q1.y, q1.z } }
end

function streetutil.freeAllNodes(edges)
	local freeNodes = { }
	for i = 1,#edges do
		freeNodes[i] = i-1
	end
	return freeNodes
end

return streetutil
