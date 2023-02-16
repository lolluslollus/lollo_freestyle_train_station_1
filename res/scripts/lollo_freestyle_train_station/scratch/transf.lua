local vec3 = require "vec3"
local vec4 = require "vec4"

local transf = { }

function transf.new(col0, col1, col2, col3)
	return {
		col0.x, col0.y, col0.z, col0.w,
		col1.x, col1.y, col1.z, col1.w,
		col2.x, col2.y, col2.z, col2.w,
		col3.x, col3.y, col3.z, col3.w
	}
end

function transf.flipY(m)
	return {
		m[1], -m[2], m[3], m[4],
		m[5], -m[6], m[7], m[8],
		m[9], -m[10], m[11], m[12],
		m[13], -m[14], m[15], m[16]
	}
end

function transf.transl(t)
	return transf.new(
		vec4.new(1.0, .0, .0, .0),
		vec4.new(.0, 1.0, .0, .0),
		vec4.new(.0, .0, 1.0, .0),
		vec4.new(t.x, t.y, t.z, 1.0))
end

function transf.scale(t)
	return transf.new(
		vec4.new(t.x, .0, .0, .0),
		vec4.new(.0, t.y, .0, .0),
		vec4.new(.0, .0, t.z, .0),
		vec4.new(.0, .0, .0, 1.0))
end

function transf.rotYCntTransl(rotY, cnt, transl)
	local sy = math.sin(rotY)
	local cy = math.cos(rotY)

	local tx = cnt.x + transl.x
	local ty = cnt.y + transl.y
	local tz = cnt.z + transl.z

	return transf.new(
		vec4.new(cy, .0, -sy, .0),
		vec4.new(.0, 1.0, .0, .0),
		vec4.new(sy, .0, cy, .0),
		vec4.new(-cy * cnt.x - sy * cnt.z + tx, -cnt.y + ty, sy * cnt.x - cy * cnt.z + tz, 1.0))

end

function transf.rotZ(rotZ)
	local sz = math.sin(rotZ)
	local cz = math.cos(rotZ)

	return transf.new(
		vec4.new(cz, sz, .0, .0),
		vec4.new(-sz, cz, .0, .0),
		vec4.new(.0, .0, 1.0, .0),
		vec4.new(.0, .0, .0, 1.0))
end

function transf.rotY(rotY)
	local sz = math.sin(rotY)
	local cz = math.cos(rotY)

	return transf.new(
		vec4.new(cz, .0, -sz, .0),
		vec4.new(.0, 1.0, .0, .0),
		vec4.new(sz, .0, cz, .0),
		vec4.new(.0, .0, .0, 1.0))
end

function transf.rotX(rotX)
	local sz = math.sin(rotX)
	local cz = math.cos(rotX)

	return transf.new(
		vec4.new(1.0, .0, .0, .0),
		vec4.new(.0, cz, sz, .0),
		vec4.new(.0, -sz, cz, .0),
		vec4.new(.0, .0, .0, 1.0))
end

function transf.rotZTransl(rotZ, transl)
	local sz = math.sin(rotZ)
	local cz = math.cos(rotZ)

	return transf.new(
		vec4.new(cz, sz, .0, .0),
		vec4.new(-sz, cz, .0, .0),
		vec4.new(.0, .0, 1.0, .0),
		vec4.new(transl.x, transl.y, transl.z, 1.0))
end

function transf.scaleRotZTransl(scale, rotZ, transl)
	local sz = math.sin(rotZ)
	local cz = math.cos(rotZ)

	return transf.new(
		vec4.new(scale * cz, scale * sz, .0, .0),
		vec4.new(scale * -sz, scale * cz, .0, .0),
		vec4.new(.0, .0, scale, .0),
		vec4.new(transl.x, transl.y, transl.z, 1.0))
end

function transf.scaleXYZRotZTransl(scale, rotZ, transl)
	local sz = math.sin(rotZ)
	local cz = math.cos(rotZ)

	return transf.new(
		vec4.new(scale.x * cz,  scale.x * sz, .0, .0),
		vec4.new(scale.y * -sz, scale.y * cz, .0, .0),
		vec4.new(.0, .0, scale.z, .0),
		vec4.new(transl.x, transl.y, transl.z, 1.0))
end

function transf.rotZYXTransl(rot, transl)
	local sx = math.sin(rot.z)
	local sy = math.sin(rot.y)
	local sz = math.sin(rot.x)
	local cx = math.cos(rot.z)
	local cy = math.cos(rot.y)
	local cz = math.cos(rot.x)

	return transf.new(
		vec4.new(cy * cz, cy * sz, -sy, .0),
		vec4.new(-cx * sz + sx * sy * cz, cx * cz + sx * sy * sz, sx * cy, .0),
		vec4.new(sx * sz + cx * sy * cz, -sx * cz + cx * sy * sz, cx * cy, .0),
		vec4.new(transl.x, transl.y, transl.z, 1.0))
end

function transf.scaleRotZYXTransl(scale, rot, transl)
	return transf.mul(transf.rotZYXTransl(rot, transl), transf.scale(scale))
end

function transf.degToRad(dx, dy, dz)
	return vec3.new(math.rad(dx), math.rad(dy), math.rad(dz))
end

function transf.mul(m1, m2)
	return {
		m1[1] * m2[1]  + m1[5] * m2[2]  + m1[9]  * m2[3]  + m1[13] * m2[4],
		m1[2] * m2[1]  + m1[6] * m2[2]  + m1[10] * m2[3]  + m1[14] * m2[4],
		m1[3] * m2[1]  + m1[7] * m2[2]  + m1[11] * m2[3]  + m1[15] * m2[4],
		m1[4] * m2[1]  + m1[8] * m2[2]  + m1[12] * m2[3]  + m1[16] * m2[4],
		m1[1] * m2[5]  + m1[5] * m2[6]  + m1[9]  * m2[7]  + m1[13] * m2[8],
		m1[2] * m2[5]  + m1[6] * m2[6]  + m1[10] * m2[7]  + m1[14] * m2[8],
		m1[3] * m2[5]  + m1[7] * m2[6]  + m1[11] * m2[7]  + m1[15] * m2[8],
		m1[4] * m2[5]  + m1[8] * m2[6]  + m1[12] * m2[7]  + m1[16] * m2[8],
		m1[1] * m2[9]  + m1[5] * m2[10] + m1[9]  * m2[11] + m1[13] * m2[12],
		m1[2] * m2[9]  + m1[6] * m2[10] + m1[10] * m2[11] + m1[14] * m2[12],
		m1[3] * m2[9]  + m1[7] * m2[10] + m1[11] * m2[11] + m1[15] * m2[12],
		m1[4] * m2[9]  + m1[8] * m2[10] + m1[12] * m2[11] + m1[16] * m2[12],
		m1[1] * m2[13] + m1[5] * m2[14] + m1[9]  * m2[15] + m1[13] * m2[16],
		m1[2] * m2[13] + m1[6] * m2[14] + m1[10] * m2[15] + m1[14] * m2[16],
		m1[3] * m2[13] + m1[7] * m2[14] + m1[11] * m2[15] + m1[15] * m2[16],
		m1[4] * m2[13] + m1[8] * m2[14] + m1[12] * m2[15] + m1[16] * m2[16],
	}
end

return transf
