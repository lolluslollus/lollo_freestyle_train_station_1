local arrayUtils = require('lollo_freestyle_train_station.arrayUtils')
local bridgeutil = require 'bridgeutil'
local mdlHelpers = require('lollo_freestyle_train_station.mdlHelpers')
local constants = require('lollo_freestyle_train_station.constants')

local _lod0_skinMaterials_era_a_rep = {
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
	'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
}
local _lod0_skinMaterials_era_a_side = {
	'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
}
local _lod0_skinMaterials_era_a_side_no_railing = {
	'lollo_freestyle_train_station/square_cobbles_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
}
local _lod1_materials_era_a = {
	'lollo_freestyle_train_station/square_cobbles.mtl',
}

local _lod0_skinMaterials_era_b_rep = {
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
	'lollo_freestyle_train_station/square_cobbles_large_low_prio_skinned.mtl',
}
local _lod0_skinMaterials_era_b_side = {
	'lollo_freestyle_train_station/square_cobbles_large_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
}
local _lod0_skinMaterials_era_b_side_no_railing = {
	'lollo_freestyle_train_station/square_cobbles_large_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_copper_skinned.mtl',
}
local _lod1_materials_era_b = {
	'lollo_freestyle_train_station/square_cobbles_large.mtl',
}

local _lod0_skinMaterials_era_c_rep = {
	'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
	'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
}
local _lod0_skinMaterials_era_c_side = {
	'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
}
local _lod0_skinMaterials_era_c_side_no_railing = {
	'lollo_freestyle_train_station/station_concrete_1_low_prio_skinned.mtl',
	'lollo_freestyle_train_station/metal/rough_iron_skinned.mtl',
}
local _lod1_materials_era_c = {
	'lollo_freestyle_train_station/station_concrete_1.mtl',
}

local function getDynamicProps(eraPrefix)
	local _lod0_skinMaterials_rep = {}
	local _lod0_skinMaterials_side = {}
	local _lod0_skinMaterials_side_no_railing = {}
	local _lod1_materials = {}
	if eraPrefix == constants.eras.era_a.prefix then
		_lod0_skinMaterials_rep = _lod0_skinMaterials_era_a_rep
		_lod0_skinMaterials_side = _lod0_skinMaterials_era_a_side
		_lod0_skinMaterials_side_no_railing = _lod0_skinMaterials_era_a_side_no_railing
		_lod1_materials = _lod1_materials_era_a
	elseif eraPrefix == constants.eras.era_b.prefix then
		_lod0_skinMaterials_rep = _lod0_skinMaterials_era_b_rep
		_lod0_skinMaterials_side = _lod0_skinMaterials_era_b_side
		_lod0_skinMaterials_side_no_railing = _lod0_skinMaterials_era_b_side_no_railing
		_lod1_materials = _lod1_materials_era_b
	else
		_lod0_skinMaterials_rep = _lod0_skinMaterials_era_c_rep
		_lod0_skinMaterials_side = _lod0_skinMaterials_era_c_side
		_lod0_skinMaterials_side_no_railing = _lod0_skinMaterials_era_c_side_no_railing
		_lod1_materials = _lod1_materials_era_c
	end

	return _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials
end

local utils = {
	getModel4Basic = function(nSegments, isCompressed, eraPrefix)
		if (not(nSegments) or nSegments < 1) then nSegments = 1 end

		local _2nSegments = 2 * nSegments
		local _iMaxLod0 = _2nSegments - 2
		local _iMaxLod1 = nSegments - 1
		local _xFactorLod0 = isCompressed and (1 / _2nSegments) or 1
		local _xFactorLod1 = isCompressed and (1 / nSegments) or 2
		local _xFactorTN = isCompressed and 1 or _2nSegments

		local _lod0_skinMaterials_rep, _lod0_skinMaterials_side, _lod0_skinMaterials_side_no_railing, _lod1_materials = getDynamicProps(eraPrefix)

		local lod0Children  = {}
		for i = 0, _iMaxLod0, 2 do
			lod0Children[#lod0Children + 1] = {
				children = {
					{
						children = {
							{
								name = 'cement_bridge_bone_2m_start',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
							},
							{
								name = 'cement_bridge_bone_2m_end',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
							},
						},
						name = 'container_2m',
						skin = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod0.msh',
						skinMaterials = _lod0_skinMaterials_rep,
					},
				},
				transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
			}
			lod0Children[#lod0Children + 1] = {
				children = {
					{
						children = {
							{
								name = 'cement_bridge_bone_2m_start_side1',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
							},
							{
								name = 'cement_bridge_bone_2m_end_side1',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
							},
						},
						name = 'container_2m_side1',
						skin = (i == 0 or i == _iMaxLod0)
							and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
							or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_tube_side_lod0.msh',
						skinMaterials = (i == 0 or i == _iMaxLod0)
							and _lod0_skinMaterials_side_no_railing
							or _lod0_skinMaterials_side,
					},
				},
				transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
			}
			lod0Children[#lod0Children + 1] = {
				children = {
					{
						children = {
							{
								name = 'cement_bridge_bone_2m_start_side2',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0.66667, 0, 1, },
							},
							{
								name = 'cement_bridge_bone_2m_end_side2',
								transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 0.66667, 0, 1, },
							},
						},
						name = 'container_2m_side2',
						skin = (i == 0 or i == _iMaxLod0)
							and 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod0.msh'
							or 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_tube_side_lod0.msh',
						skinMaterials = (i == 0 or i == _iMaxLod0)
							and _lod0_skinMaterials_side_no_railing
							or _lod0_skinMaterials_side,
					},
				},
				transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
			}
		end

		local lod1Children  = {}
		for i = 0, _iMaxLod1, 2 do
			lod1Children[#lod1Children + 1] = {
				children = {
					{
						mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
						materials = _lod1_materials,
					},
				},
				transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.5, 0, 1, },
			}
			lod1Children[#lod1Children + 1] = {
				children = {
					{
						mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_rep_skin/cement_low_bottom_railing_rep_rep_lod1.msh',
						materials = _lod1_materials,
					},
				},
				transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, i, -0.25, 0, 1, },
			}
			lod1Children[#lod1Children + 1] = {
				children = {
					{
						mesh = 'lollo_freestyle_train_station/bridge/pedestrian_cement/railing_rep_side_skin/cement_low_bottom_railing_rep_side_no_side_lod1.msh',
						materials = _lod1_materials,
					},
				},
				transf = { 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, i, 0.5, 0, 1, },
			}
		end

		local laneListsNotCompressed = {
			{
				linkable = false,
				nodes = {
					-- the lane starts where the model starts
					{
						{ 0, 0, 0 },
						{ _xFactorTN - 1.2, 0, 0 }, -- _xFactorTN >= 2, by construction
						1.5,
					},
					{
						{ _xFactorTN - 1.2, 0, 0 },
						{ _xFactorTN - 1.2, 0, 0 },
						1.5,
					},
				},
				transportModes = { 'PERSON', },
				speedLimit = 20,
			},
			{
				linkable = true,
				nodes = {
					{
						{ _xFactorTN - 1.2, 0, 0 },
						{ 0.2, 0, 0 },
						1.5,
					},
					-- the lane ends 1 m before the model ends, for seamless looking links
					{
						{ _xFactorTN - 1, 0, 0 },
						{ 0.2, 0, 0 },
						1.5,
					},
				},
				transportModes = { 'PERSON', },
				speedLimit = 20,
			}
		}
		local laneListsCompressed = {{
			linkable = false,
			nodes = {
				-- the lane starts where the model starts
				{
					{ 0, 0, 0 },
					{ _xFactorTN, 0, 0 },
					1.5,
				},
				-- the lane ends where the model ends
				{
					{ _xFactorTN, 0, 0 },
					{ _xFactorTN, 0, 0 },
					1.5,
				},
			},
			transportModes = { 'PERSON', },
			speedLimit = 20,
		}}
		return {
			boundingInfo = mdlHelpers.getVoidBoundingInfo(),
			collider = mdlHelpers.getVoidCollider(),
			lods = {
				{
					node = {
						children =  lod0Children,
						name = 'lod0Children',
						transf = { _xFactorLod0, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
					},
					static = false,
					visibleFrom = 0,
					visibleTo = 200,
				},
				{
					node = {
						children =  lod1Children,
						name = 'lod1Children',
						transf = { _xFactorLod1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1, },
					},
					static = false,
					visibleFrom = 200,
					visibleTo = 600,
				},
			},
			metadata = {
				transportNetworkProvider = {
					-- compressed bridges are inside stations;
					-- bridge exits and free open stairs bridges are uncompressed
					-- their x == 0 end is atop the stairs (free stairs or station stairs), their x > 0 end joins up with the outer world
					laneLists = isCompressed and laneListsCompressed or laneListsNotCompressed,
					runways = { },
					terminals = { },
				},
			},
			version = 1,
		}
	end,
}

return utils
