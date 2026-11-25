local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local Entity = require "engine.Entity"
local Chat = require "engine.Chat"
local Map = require "engine.Map"
local Level = require "engine.Level"
local _M = loadPrevious(...)

newEffect{
	name = "OUT_OF_PHASE",
	image = "talents/mesmeric_dodge.png",
	desc = "Out of Phase",
	long_desc = function(self, eff)
		return ("The target is partially out of phase with reality, gaining %d%% all resistance and %d%% detrimental effect duration reduction."):format(eff.resists or 0, eff.effect_reduction or 0)
	end,
	type = "magical",
	subtype = { arcane=true },
	status = "beneficial",
	parameters = { resists=100, effect_reduction=100, defense=0 },
	activate = function(self, eff)
		eff.res_id = self:addTemporaryValue("resists", {all = eff.resists or 0})
		eff.red_id = self:addTemporaryValue("effect_reduction", eff.effect_reduction or 0)
		eff.def_id = self:addTemporaryValue("combat_def", eff.defense or 0)
	end,
	deactivate = function(self, eff)
		if eff.res_id then self:removeTemporaryValue("resists", eff.res_id) end
		if eff.red_id then self:removeTemporaryValue("effect_reduction", eff.red_id) end
		if eff.def_id then self:removeTemporaryValue("combat_def", eff.def_id) end
	end,
}

newEffect{
	name = "CHAOS_ARMOR",
	image = "talents/chaos_armor.png",
	desc = "Chaos Armor",
	long_desc = function(self, eff)
		return "The target applies boons to itself and detrimental effects to its foes when it is struck."
	end,
	type = "magical",
	subtype = { arcane=true },
	status = "beneficial",
	parameters = { power=100 },
	on_gain = function(self, err) return "#Target# has chaos armor!", "+Chaos Armor" end,
	on_lose = function(self, err) return "#Target# loses chaos armor!", "-Chaos Armor" end,
	on_merge = function(self, old_eff, new_eff)
		old_eff.dur = math.max(old_eff.dur, new_eff.dur) + math.min(old_eff.dur, new_eff.dur)
		old_eff.power = math.max(old_eff.power or 0, new_eff.power or 0)
		return old_eff
	end,
	activate = function(self, eff)
		eff.old_OTH = self.onTakeHit
		self.onTakeHit = function(actor_self, value, src)
			if src and actor_self:reactionToward(src) < 0 then
				local boon_opt = rng.range(1, 3)
				if boon_opt == 1 then
					local healAmount = eff.power or actor_self:combatTalentSpellDamage(actor_self.T_CHAOS_ARMOR, 20, 440)
					actor_self:attr("allow_on_heal", 1)
					actor_self:heal(healAmount, actor_self)
					actor_self:attr("allow_on_heal", -1)
					game:playSoundNear(actor_self, "talents/heal")
				elseif boon_opt == 2 then
					actor_self:setEffect(actor_self.EFF_EARTHEN_BARRIER, 5, {src=actor_self, power=actor_self:combatSpellpower(), no_ct_effect=true})
				else
					actor_self:setEffect(actor_self.EFF_OUT_OF_PHASE, 5, {src=actor_self, power=actor_self:combatSpellpower(), defense=10, resists=actor_self:getMag(), effect_reduction=actor_self:getMag(), no_ct_effect=true})
				end

				local bane_opt = rng.range(1, 3)
				if bane_opt == 1 then
					src:setEffect(src.EFF_CONFUSED, 5, {src=actor_self, power=50, apply_power=actor_self:getMag()})
				elseif bane_opt == 2 then
					src:setEffect(src.EFF_CRIPPLE, 5, {src=actor_self, speed=0.3, apply_power=actor_self:getMag()})
				else
					src:setEffect(src.EFF_BLINDED, 5, {src=actor_self, power=actor_self:combatSpellpower(), apply_power=actor_self:combatSpellpower()})
				end
			end
			if eff.old_OTH then
				return eff.old_OTH(actor_self, value, src)
			end
			return mod.class.Actor.onTakeHit(actor_self, value, src)
		end
	end,
	deactivate = function(self, eff)
		self.onTakeHit = eff.old_OTH
	end,
}

newEffect{
	name = "MESMERIC_OVERLOAD",
	image = "talents/winds_of_chaos.png",
	desc = "Mesmeric Overload",
	long_desc = function(self, eff)
		return ("The target radiates incredible power, increasing all damage done by %d%%. (Additional instances of Mesmeric Overload stack in power, up to %d%%, and reset the duration.)"):format(eff.power, eff.max)
	end,
	type = "magical",
	subtype = { arcane=true },
	status = "beneficial",
	parameters = { power=10, max=50 },
	on_gain = function(self, err) return "#Target# is overloaded with power.", "+Overload" end,
	on_lose = function(self, err) return "#Target# seems less dangerous.", "-Overload" end,
	on_merge = function(self, old_eff, new_eff)
		if old_eff.pid then self:removeTemporaryValue("inc_damage", old_eff.pid) end
		old_eff.max = math.max(old_eff.max or 10, new_eff.max or 10)
		old_eff.power = math.min(old_eff.max, (old_eff.power or 0) + (new_eff.power or 0))
		old_eff.dur = math.max(old_eff.dur or 0, new_eff.dur or 0)
		old_eff.pid = self:addTemporaryValue("inc_damage", {all=old_eff.power})
		return old_eff
	end,
	activate = function(self, eff)
		eff.pid = self:addTemporaryValue("inc_damage", {all=eff.power})
	end,
	deactivate = function(self, eff)
		if eff.pid then self:removeTemporaryValue("inc_damage", eff.pid) end
	end,
}

newEffect{
	name = "ARCANE_ILLUSION",
	image = "talents/winds_of_chaos.png",
	desc = "Arcane Illusion",
	long_desc = function(self, eff)
		return ("The target is subject to an arcane illusion, taking %0.2f arcane damage per turn."):format(eff.power)
	end,
	type = "magical",
	subtype = { arcane=true },
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# suffers from an arcane illusion!", "+ArcaneI" end,
	on_lose = function(self, err) return "#Target# overcomes the arcane illusion.", "-ArcaneI" end,
	on_merge = function(self, old_eff, new_eff)
		local olddam = (old_eff.power or 0) * (old_eff.dur or 0)
		if olddam > 0 then
			DamageType:get(DamageType.ARCANE).projector(old_eff.src, self.x, self.y, DamageType.ARCANE, olddam)
		end
		return new_eff
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.ARCANE).projector(eff.src, self.x, self.y, DamageType.ARCANE, eff.power)
	end,
}

newEffect{
	name = "LIGHT_ILLUSION",
	image = "talents/winds_of_chaos.png",
	desc = "Light Illusion",
	long_desc = function(self, eff)
		return ("The target is subject to a light illusion, taking %0.2f light damage per turn."):format(eff.power)
	end,
	type = "magical",
	subtype = { light=true },
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# suffers from a light illusion!", "+LightI" end,
	on_lose = function(self, err) return "#Target# overcomes the light illusion.", "-LightI" end,
	on_merge = function(self, old_eff, new_eff)
		local olddam = (old_eff.power or 0) * (old_eff.dur or 0)
		if olddam > 0 then
			DamageType:get(DamageType.LIGHT).projector(old_eff.src, self.x, self.y, DamageType.LIGHT, olddam)
		end
		return new_eff
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.LIGHT).projector(eff.src, self.x, self.y, DamageType.LIGHT, eff.power)
	end,
}

newEffect{
	name = "ILLUSIONARY_COUNTER",
	image = "talents/illusionary_counter.png",
	desc = "Illusionary Counter",
	long_desc = function(self, eff)
		return ("The target is using Mesmer magic to block the next %d incoming attack(s) and retaliate by creating an illusion near the attacker."):format(eff.count or 0)
	end,
	type = "magical",
	subtype = { tactic=true },
	status = "beneficial",
	parameters = { count=1 },
	on_gain = function(self, eff) return nil, nil end,
	on_lose = function(self, eff) return nil, nil end,
	activate = function(self, eff)
		eff.old_OTH = self.onTakeHit
		self.onTakeHit = function(actor_self, value, src)
			local ret
			if eff.old_OTH then
				ret = eff.old_OTH(actor_self, value, src)
			else
				ret = mod.class.Actor.onTakeHit(actor_self, value, src)
			end
			if src and actor_self:reactionToward(src) < 0 and (eff.count or 0) > 0 then
				if not actor_self.is_mesmer_illusion then
					actor_self:knockback(src.x, src.y, 1)
				end
				local creator = actor_self.mesmer_create_illusion or createIllusion
				local ill = creator(actor_self, src.x, src.y, actor_self:getTalentFromId(actor_self.T_ILLUSIONARY_COUNTER))
				if ill then
					eff.count = eff.count - 1
					if eff.count <= 0 then
						actor_self:removeEffect(actor_self.EFF_ILLUSIONARY_COUNTER)
					end
				end
			end
			return ret
		end
	end,
	deactivate = function(self, eff)
		self.onTakeHit = eff.old_OTH
	end,
}
