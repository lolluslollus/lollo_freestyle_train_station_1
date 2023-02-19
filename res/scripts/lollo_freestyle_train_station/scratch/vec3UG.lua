local vec3 = { }

local mt

function vec3.new(x, y, z)
	local v = { x = x, y = y, z = z }
	setmetatable(v, mt)
	return v
end

mt = {
	__add = function(a, b) return vec3.new(a.x + b.x, a.y + b.y, a.z + b.z) end,
	__sub = function(a, b) return vec3.new(a.x - b.x, a.y - b.y, a.z - b.z) end,
	__mul = function(f, v) return vec3.new(f * v.x, f * v.y, f * v.z) end
}

function vec3.add(a, b) return a + b end
function vec3.sub(a, b) return a - b end
function vec3.mul(f, v) return f * v end

function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z;
end

function vec3.cross(a, b)
	return vec3.new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x)
end

function vec3.length(v)
	return math.sqrt(vec3.dot(v, v))
end

function vec3.distance(a, b)
	return vec3.length(vec3.sub(a, b))
end

function vec3.normalize(v)
	return (1.0 / vec3.length(v)) * v
end

function vec3.angleUnit(a, b)
	local arg = vec3.dot(a, b)
	
	if (arg < -1.0) then 
		arg = -1.0
	elseif (arg > 1.0) then 
		arg = 1.0
	end
	
	return math.acos(arg)
end

function vec3.xyAngle(v)
	return math.atan2(v.y, v.x)
end

return vec3
