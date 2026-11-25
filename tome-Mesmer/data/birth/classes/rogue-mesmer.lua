-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local Particles = require "engine.Particles"
getBirthDescriptor("class", "Rogue").descriptor_choices.subclass["Mesmer"] = "allow"

newBirthDescriptor{
	type = "subclass",
	name = "Mesmer",
	desc = {
		"The Mesmer is a master of mirage, deceiving through spells, mentalism and technique to create distracting illusions.", 
                "Mesmers require the use of a staff or greatsword and cannot use their abilities while encumbered by fatiguing armor.", 
                "Mobility, evasion and timing are hallmarks of the successful mesmer.", 
		"Their use of magic, mentalism and physical technique is innate and not really studied; as such they do not naturally use or regenerate mana, psi or stamina. Instead, Mesmers manage weapon sets and cooldowns as resources.",
		"Their most important stats are: Strength (greatsword and signet powers), Magic (staff and mantra power) and Cunning (utility powers)",
		"#GOLD#Stat modifiers:",
		"#LIGHT_BLUE# * +3 Strength, +0 Dexterity, +0 Constitution",
		"#LIGHT_BLUE# * +3 Magic, +0 Willpower, +3 Cunning",
		"#GOLD#Life per level:#LIGHT_BLUE# -3"
	},
        not_on_random_boss = true,
	power_source = {technique=true, arcane=true},
	stats = { mag=3, str=3, cun=3},
	talents_types = {
		["spell/mesmer-staff"]={true, 0.3},
		["spell/mesmer-greatsword"]={true, 0.3},
		["spell/mesmer-longsword"]={true, 0.3},
		["spell/mesmer-shatter"]={true, 0.3},
		["spell/mesmer-mantra"]={true, 0.3},
		["spell/mesmer-signet"]={true, 0.3},
		["spell/mesmer-utility"]={true, 0.3},
		["spell/mesmer-trait"]={true, 0.0},
		["spell/mesmer-elite"]={false, 0.3},

                ["cunning/survival"]={true, 0},

	},
	talents = {
		[ActorTalents.T_MESMERIC_DODGE] = 1,
		[ActorTalents.T_WINDS_OF_CHAOS] = 1,
		[ActorTalents.T_SPATIAL_SURGE] = 1,
		[ActorTalents.T_MIND_WRACK] = 1,
		[ActorTalents.T_DECOY] = 1,
		[ActorTalents.T_MANA_POOL] = 1,

--	[ActorTalents.T_PHASE_RETREAT] = 1,
--	[ActorTalents.T_PHANTASMAL_WARLOCK] = 1,
--	[ActorTalents.T_CHAOS_ARMOR] = 1,
--	[ActorTalents.T_CHAOS_STORM] = 1,
--
--	[ActorTalents.T_MIRROR_BLADE] = 1,
--	[ActorTalents.T_MIND_STAB] = 1,
--	[ActorTalents.T_PHANTASMAL_BERSERKER] = 1,
--	[ActorTalents.T_ILLUSIONARY_WAVE] = 1,
--
--	[ActorTalents.T_CRY_OF_FRUSTRATION] = 1,
--	[ActorTalents.T_DISTORTION] = 1,
--	[ActorTalents.T_DIVERSION] = 1,
--
--	[ActorTalents.T_MANTRA_OF_PAIN] = 1,
--	[ActorTalents.T_MANTRA_OF_DISTRACTION] = 1,
--	[ActorTalents.T_MANTRA_OF_CONCENTRATION] = 1,
--	[ActorTalents.T_MANTRA_OF_RESOLVE] = 1,
--	[ActorTalents.T_MANTRA_OF_RECOVERY] = 1,
--
--	[ActorTalents.T_SIGNET_OF_ILLUSIONS] = 1,
--	[ActorTalents.T_SIGNET_OF_DOMINATION] = 1,
--	[ActorTalents.T_SIGNET_OF_MIDNIGHT] = 1,
--	[ActorTalents.T_SIGNET_OF_INSPIRATION] = 1,
--	[ActorTalents.T_SIGNET_OF_ETHER] = 1,
--
--	[ActorTalents.T_BLINK_PORTAL] = 1,
--	[ActorTalents.T_ILLUSION_OF_LIFE] = 1,
--	[ActorTalents.T_PHANTASMAL_DEFENDER] = 1,
	},
	copy = {
		max_life = 100, -- not quite as low as "archmage"
		resolvers.equipbirth{ id=true,
			{type="weapon", subtype="greatsword", name="iron greatsword", autoreq=true, ego_chance=-1000, ego_chance=-1000},
			{type="armor", subtype="cloth", name="linen robe", autoreq=true, ego_chance=-1000},
		},
		resolvers.inventorybirth{ id=true, inven="QS_MAINHAND",
			{type="weapon", subtype="staff", name="elm staff", autoreq=true, ego_chance=-1000},
		},
		resolvers.inventorybirth{ id=true, 
			{type="weapon", subtype="longsword", name="iron longsword", autoreq=true, ego_chance=-1000},
		},
	},
	copy_add = {
		life_rating = -3, -- not quite as low as "archmage"
	},
}
