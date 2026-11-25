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
	name = "Ether Blast",
	type = {"spell/mesmer-longsword", 1},
	require = long_req1,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,3) end,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 }, }, 
        range = function(self,t)
          return math.ceil(3 + self:getTalentLevel(t) / 2)
        end,
        on_pre_use = reqlong,
        getDuration = function(self, t)
          return math.floor(self:getTalentLevel(t))
        end, 
        getDamageLight = function(self, t)
          return mesmerTalentStatDamage(self, t, "str", 25, 230)/2
          -- same as spell/nightfall's Invoke Darkness
        end,
        getDamageArcane = function(self, t)
          return mesmerTalentStatDamage(self, t, "mag", 25, 230)/2
        end,
        requires_target = true,
        target = function(self, t)
          return {type="beam", range=self:getTalentRange(t), 
                  talent=t}
        end,
        targetCone = function(self, t)
          return {type="cone", range=0, radius=self:getTalentRange(t), 
                  talent=t}
        end,

	action = function(self, t)
        -- Light Beam Damage + Stun
        --      teleport to final target
        -- Arcane Cone Damage + Daze
        --      step back, push away 
                local tg = self:getTalentTarget(t)
                local dur = t.getDuration(self, t) 
                local damL = t.getDamageLight(self, t)
                local x, y, target = self:getTarget(tg) 
                if not x or not y then return nil end
                self:project(tg, x, y, function (tx, ty) 
                  local target = game.level.map(tx, ty, Map.ACTOR)
                  if target and target ~= self and 
                     self:reactionToward(target) < 0 then -- foe
                    local dam = self:physicalCrit(damL, nil, target, self:combatAttack(), target:combatDefense())
                    DamageType:get(DamageType.LIGHT).projector(self, tx, ty, DamageType.LIGHT, dam)
                    -- now do weapon "on hit" damage
                    local hitted = self:attackTarget(target, nil, 0, true)
                    target:setEffect(target.EFF_PINNED, dur, {src=self, 
                      apply_power=self:getStr() }) 

                    if self:getTalentLevel(self.T_CRIPPLING_ILLUSIONS) and
                       self:getTalentLevel(self.T_CRIPPLING_ILLUSIONS) >= 2 then 
                       target:knockback(self.x, self.y, 1) 
                    end 
                  end 
                end)
                game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "light_beam", {tx=x-self.x, ty=y-self.y})

                local tx, ty = util.findFreeGrid(x, y, 1, true, {[Map.ACTOR]=true})
                if tx then 
                  local range = self:getTalentRange(t)
                  local inrange = 
                    core.fov.distance(self.x, self.y, tx, ty) <= range
                  if inrange and tx and ty and not self.is_mesmer_illusion then
                    game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport", {color=colors.VIOLET})
                    self:teleportRandom(tx, ty, 0) 
                  end
                end 

                tg = t.targetCone(self,t)
                x, y, target = self:getTarget(tg) 
                if not x or not y then return true end
                local damA = t.getDamageArcane(self, t)
                self:project(tg, x, y, function (tx, ty) 
                  local target = game.level.map(tx, ty, Map.ACTOR)
                  if target and target ~= self and 
                     self:reactionToward(target) < 0 then -- foe
                    local dam = self:spellCrit(damA)
                    target:setEffect(target.EFF_ARCANE_ILLUSION, 4, {src=self, 
                       power= dam/4}) 
                    -- now do weapon "on hit" damage
                    local hitted = self:attackTarget(target, nil, 0, true)
                    target:setEffect(target.EFF_STUNNED, dur, {src=self, 
                      apply_power=self:getMag() }) 
                  end 
                end)
                game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_breath", {radius=tg.radius, tx=x-self.x, ty=y-self.y, allow=core.shader.allow("distort")})

                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
                return true
	end,

	info = function(self, t)
                local damA = t.getDamageArcane(self,t) 
                local damL = t.getDamageLight(self,t) 
                local dur = t.getDuration(self,t) 
                local range = self:getTalentRange(t) 
                return ([[Assaults nearby foes with a two-stage attack.

First, the mesmer creates a range %d beam that deals light damage to all foes, possibly pinning them. The effects increase with your Strength and your physical crit chance. The mesmer then teleports to the last square in the beam. 

Second, the mesmer creates a radius %d cone that deals arcane illusion damage to all foes, possibly stunning them. The effects increase with your Magic and your spell crit chance. The mesmer steps back one square away from the cone. 

Beam Damage: %0.2f light damage
Beam Effect: Pinned for %d turn(s) (power %d)
Cone Damage: %0.2f arcane illusion damage (over 4 turns)
Cone Effect: Stunned for %d turn(s) (power %d)
In addition, weapon "on melee hit" effects can trigger.

#LIGHT_BLUE#Commentary: This flexible talent can either serve as a short-range escape or as a source of disabling and damage. It requires careful positioning to be as damaging as Winds of Chaos or Spatial Surge, however. At low talent levels the mesmer must be dangerously close to foes to be effective -- this is a 'quadratic'-style talent that becomes much more effective around talent level 4. The damage follows "Invoke Darkness" with the addition of pinning and stunning.]]):  
                format(range, range,
                damDesc(self, DamageType.LIGHT, damL),
                dur, 
                self:getStr(), 
                damDesc(self, DamageType.ARCANE, damA),
                dur, 
                self:getMag()
                )
	end,
}

local basetrap = function(self, t, x, y, dur, add)
        local Trap = require "mod.class.Trap"
        local trap = {
                id_by_type=true, unided_name = "trap",
                display = '^',
                faction = self.faction,
                summoner = self, summoner_gain_exp = true,
                temporary = dur,
                x = x, y = y,
                canAct = false,
                energy = {value=0},
                act = function(self)
                        self:realact()
                        self:useEnergy()
                        self.temporary = self.temporary - 1
                        if self.temporary <= 0 then
                                if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
                                game.level:removeEntity(self, true)
                        end
                        -- double speed
                        self:realact()
                        self:useEnergy()
                        self.temporary = self.temporary - 1
                        if self.temporary <= 0 then
                                if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
                                game.level:removeEntity(self, true)
                        end
                end,
        }
        table.merge(trap, add)
        return Trap.new(trap)
end


newTalent{
	name = "Vortex",
	type = {"spell/mesmer-longsword", 2},
	require = long_req2,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,12) end,
	tactical = { ATTACK = { ARCANE = 2 }, }, 
        range = 0, 
        on_pre_use = reqlong,
        range = function(self,t)
          return math.ceil(2+1.5*self:getTalentLevel(t))
        end,
        getDuration = function(self, t)
          return math.floor(self:getTalentLevel(t))
        end, 
        getDamageLight = function(self, t)
          return mesmerTalentStatDamage(self, t, "str", 20, 150)
          -- same as spell/aether's Aether Beam 
        end,
        requires_target = true,
        target = function(self, t)
          return {type="cone", range=0, radius=self:getTalentRange(t), 
                  talent=t}
        end,

	action = function(self, t)
          for i = 1, 1 do 

                local tg = self:getTalentTarget(t)
                local dur = t.getDuration(self, t) 
                local range = self:getTalentRange(t) 
                local x, y, target = self:getTarget(tg) 
                if not x or not y then 
                  if i == 1 then 
                    return nil 
                  else
                    return true
                  end 
                end
                self:project(tg, x, y, function (tx, ty) 
                  local target = game.level.map(tx, ty, Map.ACTOR)
                  if target and target ~= self and 
                     self:reactionToward(target) < 0 then -- foe
                    -- now do weapon "on hit" damage
                    local hitted = self:attackTarget(target, nil, 0, true)
                    target:setEffect(target.EFF_PINNED, dur, {src=self, 
                      apply_power=self:getMag() }) 
                  end 
                end)

                game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_breath", {radius=tg.radius, tx=x-self.x, ty=y-self.y, allow=core.shader.allow("distort")})
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 

                tg = {type="hit", nolock=true, pass_terrain=false, nowarning=true, range=range, radius=range, requires_knowledge=true}
                x, y = self:getTarget(tg)
                if not x then return true end

                -- place a trap! 
                if (not game.level.map(x, y, Map.TRAP)) and
                   (not game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move")) then

                local t = basetrap(self, t, x, y, 120, {
                        type = "aether", subtype = "light", name = "blurred frenzy", color=colors.VIOLET, image = "trap/aether_beam.png",
                        dam = t.getDamageLight(self, t),
                        triggered = function(self, x, y, who) return true, true end,
                        combatSpellpower = function(self) return self.summoner:getStr() end,
                        rad = 6,
                        energy = {value=0, mod=16},
                        detect_power = self:combatSpellpower(),
                        disarm_power = self:combatSpellpower(),
                        on_added = function(self, level, x, y)
                                self.x, self.y = x, y
                                local tries = {}
                                local list = {i=1}
                                local sa = rng.range(0, 359)
                                local dir = rng.percent(50) and 1 or -1
                                for a = sa, sa + 359 * dir, dir do
                                        local rx, ry = math.floor(math.cos(math.rad(a)) * self.rad), math.floor(math.sin(math.rad(a)) * self.rad)
                                        if not tries[rx] or not tries[rx][ry] then
                                                tries[rx] = tries[rx] or {}
                                                tries[rx][ry] = true
                                                list[#list+1] = {x=rx+x, y=ry+y}
                                        end
                                end
                                self.list = list
                                self.on_added = nil
                        end,
                        disarmed = function(self, x, y, who)
                                game.level:removeEntity(self, true)
                        end,
                        realact = function(self)
                                if game.level.map(self.x, self.y, engine.Map.TRAP) ~= self then game.level:removeEntity(self, true) return end

                                local x, y = self.list[self.list.i].x, self.list[self.list.i].y
                                self.list.i = util.boundWrap(self.list.i + 1, 1, #self.list)

                                local tg = {type="beam", range=0, x=self.x, y=self.y, range=self.rad, selffire=true, talent=t} 
                                self.summoner.__project_source = self

                self.summoner:project(tg, x, y, function (tx, ty) 
                  local target = game.level.map(tx, ty, engine.Map.ACTOR)
                  if target and 
                     self.summoner:reactionToward(target) >= 0 then -- friend
                    target:setEffect(target.EFF_MESMERIC_OVERLOAD, 5, 
                      {src=self.summoner, 
                      power= 10, 
                      max=(10 * 
                      self.summoner:getTalentLevelRaw(self.summoner.T_BLURRED_FRENZY)), 
                      no_ct_effect=true}) 
                  end
                
                  if target and target ~= self and 
                     self.summoner:reactionToward(target) < 0 then -- foe
                        local dam = self.summoner:physicalCrit(self.dam, nil, target, self.summoner:combatAttack(), target:combatDefense())
                        DamageType:get(DamageType.LIGHT).projector(self.summoner, tx, ty, DamageType.LIGHT, dam)
                        target:pull(x,y,1) 
                  end 
                end)

                                self.summoner.__project_source = nil
                game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "light_beam", {tx=x-self.x, ty=y-self.y})
                        end,
                })
                t:identify(true)
                t:resolve() t:resolve(nil, true)
                t:setKnown(self, true)
                game.level:addEntity(t)
                game.zone:addEntity(game.level, t, "trap", x, y)
                game.level.map:particleEmitter(x, y, 1, "summon")

                end -- end: can make trap 

          end -- end: i=1,#beams
          return true
	end,

        -- trap will, in general, hit a foe twice

	info = function(self, t)
                local damL = t.getDamageLight(self,t) 
                local range = self:getTalentRange(t) 
                local dur = t.getDuration(self, t) 
                return ([[Controls an area with a two-stage attack.  

First, the mesmer creates a cone of radius %d that pins foes. The mesmer then steps back one square. 

Second, the mesmer creates a spinning trap of light anywhere in radius %d. The trap spins with incredible speed, typically enough to hit each nearby creature twice over about 8 turns. The trap harm foes and help friends in radius 6 (but not those standing directly atop it). 

Cone Effect to foes: Pinned for %d turn(s) (power %d)
Cone Effect to foes: Weapon "on melee hit" effects can trigger
Beam Damage to foes: %0.2f light damage to foes
Beam Effect to foes: Push 1 square 
Beam Effect to allies: Mesmeric Overload (+10%% to all damage per application, max %d%%) for 5 turns

Cone effects increase with Magic. Beam effects increase with Strength and use your physical crit chance. 

#LIGHT_BLUE#Commentary: The created trap follows "Aether Beam" in total damage but with double the radius. While not as effective as Chaos Storm, this talent can serve as reasonable area-of-effect control and damage. However, the relatively long time it takes to deal full damage means tha the mesmer must find other ways to stay alive in the interim.]]):
                format(
                range, 
                range, 
                dur,
                self:getMag(),
                damDesc(self, DamageType.LIGHT, damL),
                self:getTalentLevelRaw(t) * 10
                )
	end,
}

newTalent{
	name = "Illusionary Counter",
	type = {"spell/mesmer-longsword", 3},
	require = long_req3,
	points = 5,
	random_ego = "attack",
	cooldown = function (self, t) return mesmercooldown(self,t,10) end,
	tactical = { BUFF = 2}, 
        on_pre_use = reqlong,
        no_energy = true,
        getDuration = function(self, t)
          return math.ceil(1+self:getTalentLevel(t))
        end, 
        getNumber = function(self, t)
          return math.ceil(self:getTalentLevel(t)/3)
        end, 
        action = function(self, t)
                local dur = t.getDuration(self, t)
                local count = t.getNumber(self,t) 
                self.mesmer_create_illusion = createIllusion
                self:setEffect(self.EFF_ILLUSIONARY_COUNTER, dur, { count = count}) 
                self:setEffect(self.EFF_OUT_OF_PHASE, 1, {
                  power= 100, 
                  defense = 0, 
                  resists = 100, 
                  effect_reduction = 100 
                }) 
                return true
        end, 
	info = function(self, t)
                local dur = t.getDuration(self,t) 
                local count = t.getNumber(self,t) 
                return ([[Protects and retaliates with a two-stage defense.

First, the mesmer creates a personal illusionary shield for %d turns. During turn 1, the shield keeps you out of phase with reality (100%% resist all, 100%% detrimental effect duration reduction). 

Second, the next %d time(s) a source of damage would be applied to you, this shield attempts to create an illusionary clone adjacent to the attacker. After each such attack you take one step away from the attacker.

%s It serves largely to distract foes.

This spell takes no time to cast.

#LIGHT_BLUE#Commentary: Note that distance and line-of-sight are not required for this talent to function. However, unlike other effects that create illusionary clones, this one is not entirely under the Mesmer's control: you must take a hit from a foe to trigger it. It is thus difficult to use proactively, for scouting, or to draw early fire.]]): 
                format(dur, count,
                describeIllusion(self, t) 
                )
	end,
}

newTalent{
	name = "Temporal Curtain",
	type = {"spell/mesmer-longsword", 4},
	require = long_req4,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,25) end,
        on_pre_use = reqlong,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 }, }, 
        requires_target = true, 
        direct_hit = true, 
        range = 10, 
        getDamageLight = function(self, t)
          return mesmerTalentStatDamage(self, t, "str", 10, 170)*1.5
          -- same as chrono/gravity's Gravity Spike, with
          -- either 50% for pinned or for paradox
        end,
        getCount = function (self, t)
          return math.ceil(self:getTalentLevel(t))
        end,
        radius = function (self,t) 
          return math.ceil(2 + self:getTalentLevel(t)/2)
        end,
        target = function(self, t)
          return {type="ball", range=self:getTalentRange(t),
                radius=self:getTalentRadius(t), talent=t}
        end,
        targetWall = function(self, t)
          local r = 4
          return {type="wall", range = 5,
                --range=self:getTalentRange(t), 
                  halflength=r, halfmax_spots=r+1}
        end,
        getDuration = function(self, t)
          return math.ceil(2+2*self:getTalentLevel(t))
        end, 

	action = function(self, t)
                local tg = self:getTalentTarget(t)
                local rad = self:getTalentRadius(t) 
                local damL = t.getDamageLight(self, t)
                -- self:getTalentTarget(t)
                local x, y, target = self:getTarget(tg)
                if not x or not y then return nil end
                self:project(tg, x, y, function (tx, ty) 
                  local target = game.level.map(tx, ty, Map.ACTOR)
                  if target and self:reactionToward(target) >= 0 then
                    target:knockback(x,y, self:getTalentRadius(t))
                  end 
                  if target and self:reactionToward(target) < 0 then -- foe
                    local dam = self:physicalCrit(damL, nil, target, self:combatAttack(), target:combatDefense())
                    target:setEffect(target.EFF_LIGHT_ILLUSION, 4, {src=self, 
                       power= dam/4}) 
                    target:pull(x,y, self:getTalentRadius(t))
                    -- now do weapon "on hit" damage
                    local hitted = self:attackTarget(target, nil, 0, true)
                  end 
                end)
                game.level.map:particleEmitter(x, y, tg.radius, "gravity_spike", {radius=tg.radius, allow=core.shader.allow("distort")})

                tg = t.targetWall(self,t)
                x, y = self:getTarget(tg) 
                if not x or not y then return true end
                local dur = t.getDuration(self,t)
                local dam = t.getCount(self, t)
                self:project(tg, x, y, function (px, py) 
                  game.level.map:addEffect(self, px, py, dur, DamageType.TEMPORAL_CURTAIN, dam, 1, 5, nil, 
                  -- {type="inferno"}, 
                  {type="temporal_cloud", dam=1}, 
                  --engine.MapEffect.new{alpha=185, color_br=200, color_bg=200, color_bb=0, effect_shader="shader_images/paradox_effect.png"},
                  nil, true)
                end)

		return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
                local radius = self:getTalentRadius(t) 
                local count = t.getCount(self, t)
                local dur = t.getDuration(self,t) 
                local damL = t.getDamageLight(self,t) 
		return ([[Controls an area and manipulates cooldowns with a two-stage attack. 

First, the mesmer projects a distoring sphere of radius %d in range %d. Enemies within the sphere are damaged and pulled toward the center. Allies within the sphere are pushed out. 

Second, the mesmer creates a temporal curtain: a wall up to length 9 in range 5 with thickness-radius 1. Whenever a foe interacts with the curtain, up to %d of that foe's available talents (chosen at random) are placed on a %d turn cooldown. For each such talent placed on cooldown, one of the mesmer's cooling-down talents (chosen at random) has its timeout reduced by %d turn(s). Whenever a friendly illusionary clone or phantasm interacts with the wall, one of the illusion's cooldowns is reduced by 1 turn. The wall lasts for %d turn(s).

Sphere Damage to foes: %d light illusion (over 4 turns) 
Sphere Effect to foes: Weapon "on melee hit" effects can trigger
Curtain Effect to foes: %d separate %d-turn cooldown transfers
Curtain Effect to foes: Crippled (30%% melee, spell and mental speed) for 3 turns

Sphere effects increase with Strength and use your physical crit chance. 

#LIGHT_BLUE#Commentary: The sphere effect follows "Gravity Spike". With careful placement the sphere can separate the Mesmer from nearby enemies, allowing the wall to be placed between them. The mesmer has the flexible choice of filling the wall with friendly illusions (allowing them to attack faster) or leaving the wall empty so that foes will walk through it (allowing the mesmer's talents to recover faster). If this talent does not appear to be reducing your cooldowns, recall that most normal foes do not have actionable talents.]]): 
                format(
                        radius, range,
                        count, count, count,
                        dur,
                damDesc(self, DamageType.LIGHT, damL),
                        count, count
                ) 
	end,
}

newTalent{
	name = "Phantasmal Bladefighter",
	type = {"spell/mesmer-longsword", 5},
	require = long_req5,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,20) end,
        on_pre_use = reqlong,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 }, }, 
        requires_target = true, 
        direct_hit = true, 
        range = 8, 
        healthPercent = function(self, t)
          return 0.125 + (0.10 * self:getTalentLevel(t))
        end,
        illusionCanMove = true,
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

                createIllusion(self, x, y, t) 
                if not self.is_mesmer_illusion then self:knockback(x, y, 1) end 
		return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
		return ([[Summons an illusionary clone of you in an empty square in range %d. After the attack the mesmer steps one square away from the target. This illusion is uniquely adaptive: it is the only mesmer illusion capable of moving on its own. It cannot take advantage of "free step" movement built into certain Mesmer powers but can spend its turn to walk after foes.

%s 

#LIGHT_BLUE#Commentary: Phantasms have more health and deal more damage than normal illusionary clones. This is the only illusion with even a hint of movement, admitting a range of summoner tactics (e.g., sending the illusion into a foe-filled room you cannot see).]]): 
                format(range, 
                  describeIllusion(self, t)) 
	end,
}
