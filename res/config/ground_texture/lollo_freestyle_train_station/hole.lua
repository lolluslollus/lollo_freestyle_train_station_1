-- local tu = require "texutil"
-- LOLLO TODO tried these to see how they handle the hole. they all suck the same.
-- Using a larger picture does not help, either.
-- function data()
-- return {
-- 	-- texture = tu.makeTextureLinearNearest("res/textures/terrain/material/mat255.tga", true, false,false),
-- 	-- texture = tu.makeTextureLinearClamp("res/textures/terrain/material/mat255.tga", true, false,false),
-- 	texture = tu.makeTextureMipmapRepeat("res/textures/terrain/material/mat255.tga", true, false,false),
-- 	-- texture = tu.makeTextureMipmapClamp("res/textures/terrain/material/mat255.tga", true, false,false),
-- 	-- texture = tu.makeTextureMipmapClampVertical("res/textures/terrain/material/mat255.tga", true, false,false),
-- 	-- texSize = { 2.0, 2.0 },
-- 	-- texSize = { 1.0, 1.0 },
-- 		texSize = { 32.0, 32.0 },
-- 	-- texSize = { 64.0, 64.0 },
-- 	materialIndexMap = {
-- 		[255] = "",
-- 	},
-- 	priority = 999999999
-- }
-- end

-- original
local tu = require "texutil"

function data()
return {
	texture = tu.makeTextureLinearNearest("res/textures/terrain/material/mat255.tga", true, false,false),
	texSize = { 32.0, 32.0 },
	materialIndexMap = {
		[255] = "",
	},
	priority = 5000
}
end

