-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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

local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local Entity = require "engine.Entity"
local Chat = require "engine.Chat"
local Map = require "engine.Map"
local Level = require "engine.Level"

local _M = loadPrevious(...)

newEffect{
	name = "CHAOS_ARMOR", image = "talents/chaos_armor.png",
	desc = "Chaos Armor",
	long_desc = function(self, eff) return ("The target applies boons to itself and detrimental effects to its foes when it is struck."):format(eff.power) end,
	type = "magical",
	subtype = { arcane=true },
	status = "beneficial",
	parameters = {},
        on_gain = function(self,err) return "#Target# has chaos armor!", "+Chaos Armor" end,
        on_lose = function(self,err) return "#Target# loses chaos armor!", "-Chaos Armor" end,
	on_merge = function(self,old_eff,new_eff)
                old_eff.dur = old_eff.dur + new_eff.dur
		return old_eff
	end,
	activate = function(self, eff)
          eff.old_OTH = self.onTakeHit 
          self.onTakeHit = function(self, value, src) 
            if self:reactionToward(src) < 0 then -- foe
              local option = rng.range(1,3) 
              if option == 1 then 
                local healAmount =  -- same heal as 'Healing Light' 
                  self:combatTalentSpellDamage(self.T_CHAOS_ARMOR, 20, 440)
                self:attr("allow_on_heal", 1)
                self:heal(healAmount, self)
                self:attr("allow_on_heal", -1)
                game:playSoundNear(self, "talents/heal")
              end 
              if option == 2 then 
                self:setEffect(self.EFF_EARTHEN_BARRIER, 5, {src=self, 
                  power= self:combatSpellpower(),
                  no_ct_effect=true}) 
              end 
              if option == 3 then
                self:setEffect(self.EFF_OUT_OF_PHASE, 5, {src=self, 
                  power= self:combatSpellpower(), 
                  defense = 10,
                  resists = 0, 
                  effect_reduction = self:combatSpellpower(), 
                  no_ct_effect=true}) 
              end 
              local option = rng.range(1,3) 
              if option == 1 then 
                src:setEffect(src.EFF_CONFUSED, 5, {src=self, 
                  power= 50, apply_power=50}) 
              end 
              if option == 2 then
                src:setEffect(src.EFF_CRIPPLE, 5, {src=self, 
                  speed= 0.3}) 
              end 
              if option == 3 then
                src:setEffect(src.EFF_BLINDED, 5, {src=self, 
                  power= self:combatSpellpower(),
                  apply_power = self:combatSpellpower()
                  }) 
              end 

            end 
            if eff.old_OTH == nil then 
              return mod.class.Actor.onTakeHit(self, value, src)
            else 
              return eff.old_OTH(self, value, src) 
            end
          end -- end of: onTakeHit = ...
	end,
	deactivate = function(self, eff)
          self.onTakeHit = eff.old_OTH
	end,
}

newEffect{
        name = "MESMERIC_OVERLOAD", image="talents/winds_of_chaos.png",
        desc = "Mesmeric Overload",
        long_desc = function(self, eff) return ("The target radiates incredible power, increasing all damage done by %d%%. (Additional instances of Mesmeric Overload stack in power, up to %d%%, and reset the duration.)"):format(eff.power, eff.max) end,
        type = "magical",
        subtype = { arcane=true },
        status = "beneficial",
        parameters = { power=10, max=50 },
        on_gain = function(self, err) return "#Target# is overloaded with power.", "+Overload" end,
        on_lose = function(self, err) return "#Target# seems less dangerous.", "-Overload" end,
        on_merge = function(self, old_eff, new_eff)
                self:removeTemporaryValue("inc_damage", old_eff.pid)
                -- Merge the overload!
                old_eff.max = math.max(old_eff.max or 10, new_eff.max or 10)
                old_eff.power = math.min(old_eff.max,
                              (old_eff.power or 0) + (new_eff.power or 0))
                old_eff.dur = math.max(old_eff.dur or 0, new_eff.dur or 0) 
                old_eff.pid = self:addTemporaryValue("inc_damage", {all=old_eff.power})
                return old_eff
        end,
        activate = function(self, eff)
                eff.pid = self:addTemporaryValue("inc_damage", {all=eff.power})
        end,
        deactivate = function(self, eff)
                self:removeTemporaryValue("inc_damage", eff.pid)
        end,
}

newEffect{
	name = "ARCANE_ILLUSION", image = "talents/winds_of_chaos.png",
	desc = "Arcane Illusion",
	long_desc = function(self, eff) return ("The target is subject to an arcane illusion, taking %0.2f arcane damage per turn."):format(eff.power) end,
	type = "magical",
	subtype = { arcane=true },
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# suffers from an arcane illusion!", "+ArcaneI" end,
	on_lose = function(self, err) return "#Target# overcomes the arcane illusion.", "-ArcaneI" end,
	on_merge = function(self, old_eff, new_eff)
                -- apply all old damage now, overwrite with new_eff
		local olddam = old_eff.power * old_eff.dur
		DamageType:get(DamageType.ARCANE).projector(old_eff.src, self.x, self.y, DamageType.ARCANE, olddam) 
                return new_eff
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.ARCANE).projector(eff.src, self.x, self.y, DamageType.ARCANE, eff.power)
	end,
}

newEffect{
	name = "LIGHT_ILLUSION", image = "talents/winds_of_chaos.png",
	desc = "Light Illusion",
	long_desc = function(self, eff) return ("The target is subject to a light illusion, taking %0.2f light damage per turn."):format(eff.power) end,
	type = "magical",
	subtype = { light=true },
	status = "detrimental",
	parameters = { power=10 },
	on_gain = function(self, err) return "#Target# suffers from a light illusion!", "+LightI" end,
	on_lose = function(self, err) return "#Target# overcomes the light illusion.", "-LightI" end,
	on_merge = function(self, old_eff, new_eff)
		-- Merge the "flames!"
		local olddam = old_eff.power * old_eff.dur
		DamageType:get(DamageType.LIGHT).projector(old_eff.src, self.x, self.y, DamageType.LIGHT, olddam) 
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
          return ("The target is using Mesmer magic to block the next %d incoming attack(s) and retaliate by creating an illusion near the attacker."):format(eff.count)
        end,
        type = "magical",
        subtype = { tactic=true },
        status = "beneficial",
        parameters = { nb=1 },
        on_gain = function(self, eff) return nil, nil end,
        on_lose = function(self, eff) return nil, nil end,
	activate = function(self, eff)
          eff.old_OTH = self.onTakeHit 
          self.onTakeHit = function(self, value, src) 
            local ret
            if eff.old_OTH == nil then 
              ret = mod.class.Actor.onTakeHit(self, value, src)
            else 
              ret = eff.old_OTH(self, value, src) 
            end
            if self:reactionToward(src) < 0 then -- foe
                if eff.count > 0 then 
                  if not self.is_mesmer_illusion then self:knockback(src.x, src.y, 1) end 
                  local ill = self.mesmer_create_illusion(self, src.x, src.y, self.T_ILLUSIONARY_COUNTER) 
                  if not ill then return ret end 
                  eff.count = eff.count - 1
                  if not eff.count then 
                    self:removeEffect(self.EFF_ILLUSIONARY_COUNTER)
                  end 
                end 
            end
            return ret
          end -- end of: onTakeHit = ...
	end,
	deactivate = function(self, eff)
          self.onTakeHit = eff.old_OTH
	end,
}
