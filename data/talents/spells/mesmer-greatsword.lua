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

local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Spatial Surge",
	type = {"spell/mesmer-greatsword", 1},
	require = swords_req1,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,3) end,
	tactical = { ATTACK = { PHYSICAL = 2 }, }, 
        range = 12, 
        on_pre_use = reqgreat,
        getDamage = function(self, t)
          return mesmerTalentStatDamage(self, t, "str", 20, 350)
          -- same as spell/air's Lightning
        end,
        direct_hit = true,
        requires_target = true,
        target = function(self, t)
          return {type="beam", range=self:getTalentRange(t), talent=t}
        end,

	action = function(self, t)
                local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
                local dam = t.getDamage(self, t) 
                self:project(tg, x, y, DamageType.SPATIAL_SURGE, {dam=dam}) 

                if core.shader.active() then game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "lightning_beam", {tx=x-self.x, ty=y-self.y, color=colors.VIOLET}, {type="lightning", color1={0.4, 0.0, 0.6}, color2={0.6, 0.0, 0.4}})
                else game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "lightning_beam", {tx=x-self.x, ty=y-self.y, color1={0.4, 0.0, 0.6}, color2={0.6, 0.0, 0.4}})
                end

                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                game:playSoundNear(self, "talents/lightning")
                return true
	end,

	info = function(self, t)
                local damage = t.getDamage(self,t) 
                return ([[Conjures a spatial disturbance beam that can hit multiple foes. The damage increases with your Strength and your distance to the target. The critical chance is based on your physical crit rate. After the attack the mesmer steps back one square away from the target.

Range 8+: %0.2f physical damage 
Range 7: %0.2f physical damage 
Range 6: %0.2f physical damage 
Range 5: %0.2f physical damage 
Range 4: %0.2f physical damage 
Range 3: %0.2f physical damage 
Range 2: %0.2f physical damage 
Range 1: %0.2f physical damage
In addition, weapon "on melee hit" effects can trigger.

#LIGHT_BLUE#Commentary: This is one of three staple Mesmer powers. It reinforces a focus on long-range attacks and mobility. The cooldown and damage follow "Lightning", but the damage total is based on distance instead of being based on chance.]]):
                format(
                damDesc(self, DamageType.PHYSICAL, damage),
                damDesc(self, DamageType.PHYSICAL, 0.9 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.8 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.7 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.6 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.5 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.4 * damage),
                damDesc(self, DamageType.PHYSICAL, 0.3 * damage)
                )
	end,
}

newTalent{
	name = "Mirror Blade",
	type = {"spell/mesmer-greatsword", 2},
	require = swords_req2,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,8) end,
	tactical = { ATTACK = { PHYSICAL = 2 }, }, 
        requires_target = true, 
        proj_speed = 8, 
        on_pre_use = reqgreat,
        range = 10, 
        getBounces = function(self, t)
          return 3 + math.floor(mesmerTalentStatDamage(self,t, "str", 0, 4))
        end,
        getDamage = function(self, t)
          return (mesmerTalentStatDamage(self,t, "str", 10, 250)) -- flameshock
        end,

	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), selffire=false, talent=t, display={particle="bolt_arcane"}}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "lightning_beam", {tx=x-self.x, ty=y-self.y, color1={0.4,0.0,0.6}, color2={0.6,0.0,0.4}})
		self:projectile(tg, x, y, DamageType.MIRROR_BLADE, 
                  {nb = t.getBounces(self,t) ,
                   dam=t.getDamage(self,t)}
                   , {type="arcanetrail"})

                local talents = { [self.T_SPATIAL_SURGE] =  
                  self:getTalentLevelRaw(self.T_SPATIAL_SURGE) 
                } 
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                createIllusion(self, self.x, self.y, t) 

                game:playSoundNear(self, "talents/lightning")
		return true
	end,

	info = function(self, t)
		return ([[Bounces an illusionary greatblade between foes and allies. The weapon applies random beneficial effects to allies and harmful conditions to foes. After the attack the Mesmer steps back one square away from the target.

Base damage to foes: %0.2f physical damage. The damage will increase with Strength and the critical chance is based on your physical crit rate. In addition, weapon "on melee hit" effects can trigger.
Extra effect to foes: Weakened for three turns (power 33). 
Effect to allies: Mesmeric Overload (+10%% to all damage per application, max %d%%) for 10 turns.

The bolt can bounce to a creature within range 6 of the last target up to %d times. No creature will be struck twice by the same bolt.

In addition, an illusionary clone is created adjacent to your current location. %s It serves largely to distract foes.

#LIGHT_BLUE#Commentary: The damage scaling follows "Flameshock". This does not stun but does have a lower cooldown and creates an illusion.]]): 
                format( 
                  damDesc(self, DamageType.PHYSICAL, t.getDamage(self,t)), 
                  10 * self:getTalentLevelRaw(t), 
                  t.getBounces(self,t) ,
                  describeIllusion(self, t) 
                  )
	end,
}

newTalent{
	name = "Mind Stab",
	type = {"spell/mesmer-greatsword", 3},
	require = swords_req3,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,12) end,
	tactical = { ATTACKAREA = { PHYSICAL = 2 }, }, 
        requires_target = true, 
        direct_hit = true, 
        on_pre_use = reqgreat,
        radius = function(self, t)
          return 1 + math.floor(self:combatTalentLimit(t, 4, 0, 2) )
        end, 
        range = 10, 
        getRemoveCount = function(self, t) 
          return math.floor(self:getTalentLevel(t))
          -- 1 + math.floor(self:combatTalentLimit(t, 6, 0, 4))
        end,
        getDamage = function(self, t) -- fireflash
          return mesmerTalentStatDamage(self,t, "str", 28, 280) 
        end,
        target = function(self, t)
          return {type="ball", range=self:getTalentRange(t),
            radius=self:getTalentRadius(t), friendlyfire=false, talent=t}
        end,

	action = function(self, t)

                local tg = self:getTalentTarget(t)
                local x, y = self:getTarget(tg)
                local dam = t.getDamage(self,t) 
                if not x or not y then return nil end
                self:project(tg, x, y, function(tx, ty)
                        local target = game.level.map(tx, ty, Map.ACTOR)
                        if not target or target == self then return end
                        local localdam = self:physicalCrit(dam, nil, target, self:combatAttack(), target:combatDefense())
                        DamageType:get(DamageType.PHYSICAL).projector(self, tx, ty, DamageType.PHYSICAL, localdam)
                        -- now do weapon "on hit" damage
                        local hitted = self:attackTarget(target, nil, 0, true)
                        --

                        local effs = { } 
                        for eff_id, p in pairs(target.tmp) do
                                local e = target.tempeffect_def[eff_id]
                                if e.status == "beneficial" then
                                        effs[#effs+1] = {"effect", eff_id}
                                end
                        end
                        -- Go through all sustains
                        for tid, act in pairs(target.sustain_talents) do
                                if act then
                                        local talent = target:getTalentFromId(tid)
                                        effs[#effs+1] = {"talent", tid} 
                                end
                        end
                        for i = 1, t.getRemoveCount(self, t) do
                                if #effs == 0 then break end
                                local eff = rng.tableRemove(effs)

                                if eff[1] == "effect" then
                                        target:removeEffect(eff[2])
                                else
                                        target:forceUseTalent(eff[2], {ignore_energy=true})
                                end
                        end

                end)
		game.level.map:particleEmitter(x, y, tg.radius, "ball_fire", {radius=tg.radius})
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                game:playSoundNear(self, "talents/slime")
                return true
	end,

	info = function(self, t)
                local radius=self:getTalentRadius(t)
		return ([[Slices an illusionary greatblade through the target area. Each foe within a radius %d of the target is struck for %0.2f physical damage and has up to %d beneficial temporary effect(s) or sustained talent(s) removed. In addition, weapon "on melee hit" effects can occur. After the attack the Mesmer steps back one square away from the target. The damage increases with Strength and the critical chance is based on your physical crit rate.
                
#LIGHT_BLUE#Commentary: The damage scaling follows "Fireflash", but the radius here is smaller and the cooldown is higher. Removing beneficial effects from foes is thematic to the Mesmer.]]): 
                format(radius,
                  damDesc(self, DamageType.PHYSICAL, t.getDamage(self,t)), 
                  t.getRemoveCount(self,t) 
                )
	end,
}

newTalent{
        name = "Illusionary Death Dance",
        type = {"spell/mesmer-other", 1},
        require = techs_req1,
        points = 5,
        cooldown = 2,
        tactical = { ATTACKAREA = { weapon = 3 } },
        range = 0,
        radius = 2,
        requires_target = true,
        target = function(self, t)
                return {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)}
        end,
        on_pre_use = function(self, t, silent) if not self:hasTwoHandedWeapon() then if not silent then game.logPlayer(self, "You require a two handed weapon to use this talent.") end return false end return true end,
        action = function(self, t)
                local weapon = self:hasTwoHandedWeapon()
                if not weapon then
                        game.logPlayer(self, "You cannot use Death Dance without a two-handed weapon!")
                        return nil
                end

                local tg = self:getTalentTarget(t)
                self:project(tg, self.x, self.y, function(px, py, tg, self)
                        local target = game.level.map(px, py, Map.ACTOR)
                        if target and target ~= self then
                                self:attackTargetWith(target, weapon.combat, nil, self:combatTalentWeaponDamage(t, 1.4, 2.1))
                                target:setEffect(target.EFF_CRIPPLE, 1, {src=self, speed = 0.3, no_ct_effect=true}) 
                        end
                end)

                self:addParticles(Particles.new("meleestorm", 1, {}))

                return true
        end,
        info = function(self, t)
                return ([[Spin around, extending your weapon and damaging all foes around you for %d%% weapon damage, as well as reducing their speed by 33% for one turn.]]):format(100 * self:combatTalentWeaponDamage(t, 1.4, 2.1))
        end,
}


newTalent{
	name = "Phantasmal Berserker",
	type = {"spell/mesmer-greatsword", 4},
	require = swords_req4,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,20) end,
        on_pre_use = reqgreat,
	tactical = { ATTACK = { weapon = 2 }, }, 
        requires_target = true, 
        direct_hit = true, 
        range = 8, 
        healthPercent = function(self, t)
          return 0.15 + (0.10 * self:getTalentLevel(t))
        end,
        damagePercent = function(self, t)
          return 50 + (self:getTalentLevel(t) * 10) 
        end, 
        illusionTalents = function(self, t) 
          local talents = { 
            [self.T_ILLUSIONARY_DEATH_DANCE] =  
              self:getTalentLevelRaw(self.T_PHANTASMAL_BERSERKER) ,
            [self.T_WEAPON_COMBAT] = 
              self:getTalentLevelRaw(self.T_PHANTASMAL_BERSERKER) ,
          } 
          local describe = "and knows the talents Combat Accuracy and Illusionary Death Dance at this level" 
          return { talents = talents, describe = describe } 
        end,
        target = function(self, t)
          return {type="hit", range=self:getTalentRange(t),
            nolock=true, nowarning=true}
        end,

	action = function(self, t)
                local tg = self:getTalentTarget(t)
                -- self:getTalentTarget(t)
                local x, y, target = self:getTarget(tg)
                if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
                        game.logSeen(self, "You do not have line of sight.")
                        return nil
                end

                createIllusion(self, x, y, t) 
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
		return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
		return ([[Summons an illusionary clone of you in an empty square in range %d. After the attack the mesmer steps one square away from the target.

%s Illusionary Death Dance can be used every other turn: the illusion attacks all foes in radius 2 for %d%% of weapon damage and cripples them, reducing their speeds by 33%% for one turn.

#LIGHT_BLUE#Commentary: Phantasms have more health and deal more damage than normal illusionary clones. Illusionary Death Dance follows "Death Dance" but with radius 2 (recall: illusions cannot move) and an additional cripple. This is the only Memser talent that uses attacks to inflict direct weapon damage; the illusion can miss.]]): 
                format(range, 
                  describeIllusion(self, t),
                  100 * self:combatTalentWeaponDamage(t, 1.4, 2.1)
                ) 
	end,
}

newTalent{
        name = "Illusionary Wave",
        type = {"spell/mesmer-greatsword",5}, 
        require = swords_req5,
        points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,28) end,
        on_pre_use = reqgreat,
        tactical = { ATTACKAREA = {PHYSICAL = 2}, ESCAPE = 2 },
        range = 0,
        radius = function(self, t) 
          return math.floor(self:combatTalentLimit(t, 9, 4, 7))
        end,
        requires_target = true,
        direct_hit = true,
        target = function(self, t)
                return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), friendlyfire=false, talent=t}
        end,
        getDamage = function(self, t)
          return (mesmerTalentStatDamage(self,t, "str", 10, 170) * 1.5) / 3.0
        end,
        action = function(self, t)
                local tg = self:getTalentTarget(t)
                local x, y = self:getTarget(tg)
                local radius = self:getTalentRadius(t)
                local dam = t.getDamage(self,t)
                if (not x) or (not y) then return nil end
                for i = 1,3 do 
                self:project(tg, x, y, function (tx,ty) 
                  local target = game.level.map(tx, ty, Map.ACTOR)
                  if (not target) or (target == self) then return end
                  local localdam = self:physicalCrit(dam, nil, target, self:combatAttack(), target:combatDefense())
                  DamageType:get(DamageType.PHYSICAL).projector(self, tx, ty, DamageType.PHYSICAL, localdam)
                  -- now do weapon "on hit" damage
                  local hitted = self:attackTarget(target, nil, 0, true)
                  --
                  if target:canBe("knockback") then 
                    target:knockback(self.x, self.y, 2) 
                  end 
                end) 
                end 
                game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_breath", {radius=tg.radius, tx=x-self.x, ty=y-self.y, allow=core.shader.allow("distort")})
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                game:playSoundNear(self, "talents/earth")
                return true
        end,
        info = function(self, t)
                local damage = t.getDamage(self, t)
                local radius = self:getTalentRadius(t)
                return ([[Push back all foes in front of you with waves of magical energy. Sends out three consecutive blast waves in a %d radius cone to foes. Each wave separately deals %0.2f physical damage, applies weapon "on hit" effects, and knocks victims back by two squares. The blast waves usually hit foes more then once, depending on the radius and the knockback effect.

After the attack the mesmer steps back one square away from the target.

The damage will scale with your Strength.

#LIGHT_BLUE#Commentary: The radius and damage loosely follow "Repulsion Blast", but with a 50%% damage increase (instead of Paradox scaling) and 700%% cooldown increase. This is typically a last-ditch talent for Mesmers who are out of mobility talents.]]):
                format(radius, damDesc(self, DamageType.PHYSICAL, t.getDamage(self, t)))
        end,
}

