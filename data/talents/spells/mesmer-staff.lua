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

local function hasgreat(self, t, silent) 
  local weapon = self:getInven("MAINHAND") 
  if weapon then
    weapon = weapon[1]
    if weapon then 
      return 
        (weapon.subtype == "greatsword") or
        (weapon.subtype == "trident") 
    end 
  end 
  return false 
end 

function reqgreat(self, t, silent) 
  local weapon = hasgreat(self, t, silent) 
  if not weapon then 
    if not silent then 
      game.logPlayer(self, "You need a greatsword or trident to use this talent.")
    end 
    return false
  end
--  if self.fatigue > 0 then
--    if not silent then 
--      game.logPlayer(self, "You cannot use this talent while fatigued by encumbering equipment.")
--    end 
--    return false
--  end 
  return true 
end 


local function haslong(self, t, silent) 
  local weapon = self:getInven("MAINHAND") 
  if weapon then
    weapon = weapon[1]
    if weapon then 
      return (weapon.subtype == "longsword") or
             (weapon.subtype == "dagger") 
    end 
  end 
  return false 
end 

function reqlong(self, t, silent) 
  local weapon = haslong(self, t, silent) 
  if not weapon then 
    if not silent then 
      game.logPlayer(self, "You need a longsword or dagger to use this talent.")
    end 
    return false
  end
--  if self.fatigue > 0 then
--    if not silent then 
--      game.logPlayer(self, "You cannot use this talent while fatigued by encumbering equipment.")
--    end 
--    return false
--  end 
  return true 
end 

local function hasgreatmaul(self, t, silent) 
  local weapon = self:getInven("MAINHAND") 
  if weapon then
    weapon = weapon[1]
    if weapon then 
      return 
        (weapon.subtype == "greatmaul") 
    end 
  end 
  return false 
end 

local function reqstaff(self, t, silent) 
  local weapon = self:hasStaffWeapon() or hasgreatmaul(self, t, silent)
  if not weapon then 
    if not silent then 
      game.logPlayer(self, "You need a staff or greatmaul to use this talent.")
    end 
    return false
  end
--  if self.fatigue > 0 then
--    if not silent then 
--      game.logPlayer(self, "You cannot use this talent while fatigued by encumbering equipment.")
--    end 
--    return false
--  end 
  return true 
end 

function mesmercooldown(self, t, base)
  local r = rng.range(1,100)
  if r < ((self.fatigue or 0)*2) then
    return (base*2)
  end
  return base
end 


newTalent{
	name = "Winds of Chaos",
	type = {"spell/mesmer-staff", 1},
	require = spells_req1,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,3) end,
	tactical = { ATTACK = { FIRE = 2, NATURE = 2 }, }, 
        requires_target = true, 
        proj_speed = 8, 
        range = 6, 
        on_pre_use = reqstaff,
        getBounces = function(self, t)
          return 2 + math.ceil(mesmerTalentStatDamage(self,t, "mag", 0, 4))
        end,
        getDamage = function(self, t)
          return mesmerTalentStatDamage(self, t, "mag", 25, 290) / 4 
        end,

	action = function(self, t)
		local tg = {type="bolt", range=self:getTalentRange(t), selffire=false, talent=t, display={particle="bolt_arcane"}}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "matter_beam", {tx=x-self.x, ty=y-self.y, color=colors.VIOLET})
		self:projectile(tg, x, y, DamageType.WINDS_OF_CHAOS, 
                  {nb = t.getBounces(self,t) ,
                   dam=self:spellCrit(t.getDamage(self,t))}
                   , {type="arcanetrail"})
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
		game:playSoundNear(self, "talents/arcane")
		return true
	end,

	info = function(self, t)
		return ([[Bounces an orb of kinetic energy between foes and allies that applies random beneficial effects to allies and harmful conditions to foes.

Damage to foes: %0.2f physical damage, plus one of: 
  either %0.2f illusion arcane damage over 4 turns
  or %0.2f illusion light damage over 4 turns.
In addition, weapon "on melee hit" effects can trigger. 

If illusion damage over time would be applied to a victim already suffering from that type of ongoing illusion, the resonance causes the entire previous illusion damage to be dealt at once before the new illusion effect is applied.

Effect to allies: Mesmeric Overload (+10%% to all damage per application, max %d%%) for 5 turns.

After the attack the mesmer steps back one square away from the target. 

The bolt can bounce to a creature within range 6 of the last target up to %d times. A creature cannot be struck by multiple bounces from the same use of this talent. Note that because of the bouncing you can profitably aim this talent at a friendly target, such as an illusion. The effects increase with Magic and the critical chance is based on your spell crit rate.

#LIGHT_BLUE#Commentary: This is one of three staple Mesmer powers. It reinforces a focus on ranged attacks and mobility. The cooldown and damage follow "Flame", except that Flame is dealt over 3 turns while this is dealt over 4 (further encouraging mobility). Stacking Mesmeric Overload from illusions can result in a substantial damage increase during long-running fights, but requires investment in this talent to raise the cap.]]): 
                format( 
                  damDesc(self, DamageType.PHYSICAL, t.getDamage(self,t)), 
                  damDesc(self, DamageType.ARCANE, 3.0 * t.getDamage(self,t)), 
                  damDesc(self, DamageType.LIGHT, 3.0 * t.getDamage(self,t)), 
--                  damDesc(self, DamageType.PHYSICAL, 3.0 * t.getDamage(self,t)), 
--                  damDesc(self, DamageType.NATURE, 3.0 * t.getDamage(self,t)), 
                  self:getTalentLevelRaw(t) * 10, 
                  t.getBounces(self,t) )
	end,
}

function describeIllusion(self, t)  
    local healthPercent = 0.01 + (0.05 * self:getTalentLevel(t)) 
    if t.healthPercent then
      healthPercent = t.healthPercent(self, t) 
    end 
    local damagePercent = self:getTalentLevel(t) 
    if t.damagePercent then
      damagePercent = t.damagePercent(self, t) 
    end 
  local signet_string = ""
  local talent_string = "and knows the talents Winds of Chaos, Spatial Surge and Ether Blast at the same levels you do"
  if self.mesmer_illusion_health then
    signet_string = ([[ (plus a %d%% bonus from signets)]]):format(self.mesmer_illusion_health)
  end 
  local heal_string = ""
  if self:getTalentLevel(self.T_RESTORATIVE_ILLUSIONS) and
    self:getTalentLevel(self.T_RESTORATIVE_ILLUSIONS) >= 2 then 
    local heal = mesmerTalentStatDamage(self, self.T_RESTORATIVE_ILLUSIONS, "cun", 20, 440) / 4 
    heal_string = ([[On death, the illusion heals you for %d.  ]]):format(heal)
  end 
  if t.illusionTalents then 
    talent_string = (t.illusionTalents(self, t)).describe
  end 
  local move_string = "never moves" 
  if t.illusionCanMove then
    move_string = "CAN move" 
  end 
  return ([[The illusionary clone has %d%% of your health%s, deals %d%% of your damage, %s, %s. %sNewly-created illusions are invulnerable for one turn. Illusions disappear after five turns without an enemy target.]]):format(100 * healthPercent, signet_string, damagePercent, move_string, talent_string, heal_string) 
end 

function createIllusion(self, x, y, t) 
    local healthPercent = 0.01 + (0.05 * self:getTalentLevel(t))
    if t.healthPercent then
      healthPercent = t.healthPercent(self, t) 
    end 
    local damagePercent = self:getTalentLevel(t) 
    if t.damagePercent then
      damagePercent = t.damagePercent(self, t) 
    end 
    local talents = nil 
    if t.illusionTalents then
      talents = (t.illusionTalents(self,t)).talents
    end 
    local m = self:cloneFull{
            shader = "shadow_simulacrum",
            shader_args = { color = {0.4, 0.0, 0.6}, base = 0.6, time_factor = 1500 },
            no_drops = true,
            faction = self.faction,
            summoner = self, summoner_gain_exp=true,
            summon_time = 5, 
            ai_target = {actor=nil},
            ai = "summoned", 
            -- ai_real = "tactical",
            ai_real = "dumb_talented_simple",
            ai_state = { talent_in = 1 } ,
            name = "Illusion of "..self.name,
            desc = [[An illusory shape that resembles you.]],
    }
    local x, y = util.findFreeGrid(x, y, 1, true, {[Map.ACTOR]=true})
    if not x then 
        return nil
    end 
    if not self then
        return nil
    end 
                local effs = {}
                -- Go through all spell effects
                for eff_id, p in pairs(m.tmp) do
                        local e = m.tempeffect_def[eff_id]
                        effs[#effs+1] = {"effect", eff_id}
                end
                for i = 1, 999 do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                m:removeEffect(eff[2])
                        end
                end
                m:removeAllMOs()
                m.make_escort = nil
                m.on_added_to_level = nil

                m.energy.value = 0
                m.player = nil
                m.max_life = m.max_life * 
                  (healthPercent + ((self.mesmer_illusion_health or 0)/100))
                m.inc_damage.all = (m.inc_damage.all or 0) - (100 - damagePercent)
                m.life = util.bound(m.life, 0, m.max_life)
                m.forceLevelup = function() end
                m.die = nil
                m.on_act = function(self) 
                  if not self.ai_target.actor or
                     self.ai_target.actor.dead then 
                     self.summon_time = (self.summon_time or 5) 
                     return nil
                  end
                  self.summon_time = nil 
                  return nil
                end  
                m.on_die = function(illusion_self) 
                  illusion_self:removeEffect(illusion_self.EFF_ARCANE_EYE,true) 

                  local heal = 0 
                  if self and 
                     self:getTalentLevel(self.T_RESTORATIVE_ILLUSIONS) and
                     self:getTalentLevel(self.T_RESTORATIVE_ILLUSIONS) >= 2 then 
                    heal = mesmerTalentStatDamage(self, self.T_RESTORATIVE_ILLUSIONS, "cun", 20, 440) / 4 
                  end 
                  if self and heal > 0 then
                    self:attr("allow_on_heal", 1)
                    self:heal(self:mindCrit(heal), self)
                    self:attr("allow_on_heal", -1)
		if core.shader.active(4) then
			self:addParticles(Particles.new("shader_shield_temp", 1, {toback=true, size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=2.0, beamColor1={0xd8/255, 0x00/255, 0x21/255, 1}, beamColor2={0xf7/255, 0x00/255, 0x9e/255, 1}, circleDescendSpeed=3}))
			self:addParticles(Particles.new("shader_shield_temp", 1, {toback=false,size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0, beamColor1={0xd8/255, 0x00/255, 0x21/255, 1}, beamColor2={0xf7/255, 0x00/255, 0x9e/255, 1}, circleDescendSpeed=3}))
		end
                    game:playSoundNear(self, "talents/heal")
                  end 

                  if self and 
                     self:getTalentLevel(self.T_CRIPPLING_ILLUSIONS) and 
                     self:getTalentLevel(self.T_CRIPPLING_ILLUSIONS) >= 2 then
                    local tg = { type="ball", x=illusion_self.x, y=illusion_self.y, radius=2, friendlyfire=false} 
                    illusion_self:project(tg, illusion_self.x, illusion_self.y, function(tx, ty)
                        local target = game.level.map(tx, ty, Map.ACTOR)
                        if not target then return end
                        target:setEffect(target.EFF_CRIPPLE, 3, 
                          {src=self, speed= 0.3, no_ct_effect=true}) 
                    end) 
                  end
                end
                if self and self:getTalentLevel(self.T_ILLUSIONARY_FRENZY) and 
                   self:getTalentLevel(self.T_ILLUSIONARY_FRENZY) >= 2 then
                  m.combat_physcrit = m.combat_physcrit + 20 
                  m.combat_mindcrit = m.combat_mindcrit + 20 
                  m.combat_spellcrit = m.combat_spellcrit + 20 

                  local regen = self.mantra_regen or 0 
                  if regen > 1 then 
                    self.mantra_regen = math.ceil(regen / 2)
                  end 
                end 
                m.on_acquire_target = nil
                m.seen_by = nil
                m.puuid = nil
                m.on_takehit = nil
                m.can_talk = nil
                m.clone_on_hit = nil
                m.exp_worth = 0
                m.no_inventory_access = true
                m.no_levelup_access = true
                m.cant_teleport = true
                m.talents = talents or { 
                  [self.T_WINDS_OF_CHAOS] =  
                    self:getTalentLevelRaw(self.T_WINDS_OF_CHAOS) ,
                  [self.T_SPATIAL_SURGE] =  
                    self:getTalentLevelRaw(self.T_SPATIAL_SURGE) ,
                  [self.T_ETHER_BLAST] =  
                    self:getTalentLevelRaw(self.T_ETHER_BLAST) 
                } 
                m.talents_cd = { } 
                m.inscriptions = {}
                m.inscriptions_data = {}
                m.max_inscriptions = 0 
                m.inscriptions_slots_added = 0
                m.talents_auto = {}

                m.inscription_restrictions =
                        { ["inscriptions/runes"] = true,
                          ["inscriptions/taints"] = true, 
                          ["inscriptions/infusions"] = true
                        } 
                if not t.illusionCanMove then 
                  m.never_move = 99
                end 
                m.remove_from_party_on_death = true
                m.no_breath = 1
                m.stone_immune = 1
                m.confusion_immune = 1
                m.fear_immune = 1
                m.teleport_immune = 1
                m.disease_immune = 1
                m.poison_immune = 1
                m.stun_immune = 1
                m.blind_immune = 1
                m.is_mesmer_illusion = true

                game.zone:addEntity(game.level, m, "actor", x, y)
                game.level.map:particleEmitter(x, y, 1, "shadow")
                if game.party:hasMember(self) then
                        game.party:addMember(m, { control="no",
                        type="summon", title="Summon"}) 
                end 
                -- game:onTickEnd(function() game.party:setPlayer(m) end)
                game:playSoundNear(self, "talents/spell_generic2")
                m:setEffect(m.EFF_OUT_OF_PHASE, 1, {
                  power= 100, 
                  defense = 0, 
                  resists = 100, 
                  effect_reduction = 100 
                }) 
        return m 
end



newTalent{
	name = "Phase Retreat",
	type = {"spell/mesmer-staff", 2},
	require = spells_req2,
	points = 5,
	cooldown = function(self, t) 
                -- t,limit,low,high,raw
                -- limit = approach as level increases
                -- low == value at level 1 (opt) 
                -- high = value at level 5
          local base = math.ceil(self:combatTalentLimit(t, 3, 9, 5))
          return mesmercooldown(self, t, base) 
          -- starts as "phase door", limit >3
        end, 
	tactical = { ESCAPE = 2} , 
        requires_target = true, 
        on_pre_use = reqstaff,
        range = 3,
        target = function(self, t)
          return {type="hit", range=self:getTalentRange(t),
            nolock=true, nowarning=true}
        end,
        is_teleport = true,
        direct_hit = true, 
        no_energy = true, 

	action = function(self, t)
                local tg = self:getTalentTarget(t)
                local x, y = self:getTarget(tg)
                local ox = self.x
                local oy = self.y
                       
                if not x or not y then return nil end
                if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
                        game.logSeen(self, "You do not have line of sight.")
                        return nil
                end
                local __, x, y = self:canProject(tg, x, y)
                game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport", {color=colors.VIOLET})
                -- since we're using a precise teleport we'll look for a free grid first
                local tx, ty = util.findFreeGrid(x, y, 5, true, {[Map.ACTOR]=true})
                if tx and ty then
                        if not self:teleportRandom(tx, ty, 0) then
                                game.logSeen(self, "The spell fizzles!")
                                return nil 
                        end
                end
                createIllusion(self, ox, oy, t) 
                game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport", {color=colors.VIOLET})
                game:playSoundNear(self, "talents/teleport")
                return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
                return ([[Teleports you to up to %d tiles away, to a targeted location in line of sight. 

In addition, an illusionary clone will be created at your old location. %s It serves largely to distract foes. 

This spell takes no time to cast.

#LIGHT_BLUE#Commentary: An iconic Mesmer ability, Phase Retreat is commonly used to escape melee foes as well as to dodge projectiles and area-of-effect attacks. The cooldown is the same as "Phase Door" and the instant perfect control follows "Dimensional Step", but the range is significantly lower than both.]]):format(range,
                describeIllusion(self, t) 
                )
	end,
}

newTalent{
	name = "Phantasmal Warlock",
	type = {"spell/mesmer-staff", 3},
	require = spells_req3,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,18) end,
	tactical = { ATTACK = { FIRE = 2, NATURE = 2 }, }, 
        requires_target = true, 
        on_pre_use = reqstaff,
        range = 4, 
        direct_hit = true, 
        healthPercent = function(self, t)
          return (0.10 * self:getTalentLevel(t))
        end,
        damagePercent = function(self, t)
          return 50 + (self:getTalentLevel(t) * 10) 
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

                local m = createIllusion(self, x, y, t) 
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                if m then m.is_phantasmal_warlock = true end 
		return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
		return ([[Summons an illusionary clone of you in an empty square in range %d. After the summoning the Mesmer steps back one square away from the target.

%s 

When using Winds of Chaos, the illusion deals an additional 10%% damage to a foe for each detrimental effect currently afflicting that foe.

#LIGHT_BLUE#Commentary: Phantasms have more health and deal more damage than normal illusionary clones. Between the Mesmeric Overload buff from Winds of Chaos and this phantasm's bonus based on enemy conditions, this talent has the potential to double your damage output -- if it can be kept alive.]]): 
                format(range, 
                  describeIllusion(self, t)
                ) 
	end,
}

newTalent{
	name = "Chaos Armor",
	type = {"spell/mesmer-staff", 4},
	require = spells_req4,
	points = 5,
	random_ego = "defensive",
	cooldown = function (self, t) return mesmercooldown(self,t,35) end,
	tactical = { DEFEND = 5 } , 
        requires_target = false, 
        no_energy = true, 
        on_pre_use = reqstaff,
        getDuration = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 12, 4, 10)) 
        end,

	action = function(self, t)
                self:setEffect(self.EFF_CHAOS_ARMOR, t.getDuration(self,t),
                  { } )
		return true
	end,

	info = function(self, t)
                local dur = t.getDuration(self, t) 
                local healAmount =  -- same heal as 'Healing Light' 
                mesmerTalentStatDamage(self,self.T_CHAOS_ARMOR, "mag", 20, 440)
		return ([[Surround yourself with chaos armor for %d turns. When you are struck, you receive a random beneficial effect and your foe receives a random detrimental effect. 

Beneficial: Heal for %d. 
Beneficial: Earthen Barrier (reduces incoming physical damage by %d%%) for 5 turns. 
Beneficial: Out of Phase (increases resists by %d, reduces incoming negative effect duration by %d%%) for 5 turns. 

Detrimental: Confused (50%% chance) for 5 turns. 
Detrimental: Crippled (30%% melee, spell and mental speed) for 5 turns.
Detrimental: Blinded (power %d) for 5 turns.

Effects increase with Magic.

#LIGHT_BLUE#Commentary: An iconic Mesmer power. The healing scaling follows "Healing Light". Commonly used when a tough foe has cornered the Mesmer and is in melee range. Be careful, however: if you are a Mesmer and foes are hitting you repeatedly, you are probably already about to lose.]]): 
                format(dur, healAmount, 
                  self:getMag(), 
                  self:getMag(), 
                  self:getMag(), 
                  self:getMag()
                ) 
	end,
}

newTalent{
        name = "Chaos Storm",
        type = {"spell/mesmer-staff",5},
        require = spells_req5,
        points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,35) end,
        tactical = { ATTACKAREA = { ARCANE = 2 } },
        range = 6, 
        radius = function(self, t)
          return math.floor(self:combatTalentLimit(t, 6, 3, 5))
          -- 3 + math.floor(mesmerTalentStatDamage(self,t, "mag", 0, 2))
        end, 
        direct_hit = true,
        requires_target = true,
        on_pre_use = reqstaff,
        target = function(self, t)
                return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
        end,
        getDamage = function(self, t) return mesmerTalentStatDamage(self,t, "mag", 15, 80) end,
        getDuration = function(self, t) return 6 + math.floor(mesmerTalentStatDamage(self,t, "mag", 0, 4)) end,
        action = function(self, t)
                local tg = self:getTalentTarget(t)
                local x, y = self:getTarget(tg)
                if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                -- Add a lasting map effect
                game.level.map:addEffect(self,
                        x, y, t.getDuration(self, t),
                        DamageType.CHAOS_STORM, t.getDamage(self, t),
                        self:getTalentRadius(t),
                        5, nil,
                        {type="arcanestorm", dam=t.getDamage(self,t)},
                        nil, true
                )
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                game:playSoundNear(self, "talents/cloud")
                return true
        end,
        info = function(self, t)
                local damage = t.getDamage(self, t)
                local radius = self:getTalentRadius(t) 
                local duration = t.getDuration(self, t)
                return ([[Summon a chaotic magical storm of radius %d for %d turns. Each turn the storm applies a beneficial effect to allies. Each turn the the storm applies damage and one random detrimental effect to foes.

Damage: %0.2f physical. In addition, weapon "on melee hit" effects can trigger.
Detrimental: Stunned for three turns (power %0.2f). 
Detrimental: Frozen for three turns (power %0.2f).
Detrimental: Poisoned for %0.2f damage over three turns. 
Detrimental: Weakened for three turns (power 33). 

Beneficial: Mesmeric Overload (+10%% to all damage per application, max %d%%) for 5 turns.

After summoning the storm the mesmer steps back one square away from the target.

The effects will increase with your Magic. This talent does not generate critical hits. 

#LIGHT_BLUE#Commentary: An iconic Mesmer power, and their only real source of area denial and true area-of-effect control. The damage to foes is immaterial compared to the crowd control effects, which are re-applied every turn as foes sit in the storm: forcing a foe to walk through a Chaos Storm is a significant advantage. Dually, sitting in one's own Chaos Storm can yield growing damage bonuses from stacks of Mesmeric Overload.]]):
                format(radius, 
                duration, 
                damDesc(self, DamageType.PHYSICAL, damage), 
                self:getMag(), 
                self:getMag(), 
                3.0 * damDesc(self, DamageType.NATURE, damage),
                10 * self:getTalentLevelRaw(t)
                )
        end,
}



