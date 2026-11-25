local DamageType = require "engine.DamageType"
local Map = require "engine.Map"
local class = require"engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"

class:bindHook("ToME:load", function(self, data) 
	local Birther = require "engine.Birther"
	DamageType:loadDefinition("/data-Mesmer/damage_types.lua")
	ActorTalents:loadDefinition("/data-Mesmer/talents/spells/spells-mesmer.lua")
	-- ActorTalents:loadDefinition("/data-Spellsword/talents/spells/spells-spellsword.lua")
	Birther:loadDefinition("/data-Mesmer/birth/classes/rogue-mesmer.lua")
end)
