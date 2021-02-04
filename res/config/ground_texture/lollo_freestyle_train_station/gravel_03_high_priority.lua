local tu = require "texutil"

function data()
return {
	texture = tu.makeTextureLinearNearest("res/textures/terrain/material/mat255.tga", true, false,false),
	texSize = { 2.0, 2.0 },
	materialIndexMap = {
		[255] = "shared/gravel_03.lua",
	},
	priority = 12000,
}
end
