local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Ether Blast",
	type = {"spell/mesmer-longsword", 1},
	require = long_req1,
	points = 5,
	random_ego = "attack",
	cooldown = function(self, t) return mesmercooldown(self, t, 3) end,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 } },
	range = function(self, t) return math.ceil(3 + self:getTalentLevel(t) / 2) end,
	on_pre_use = reqlong,
	getDuration = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	getDamageLight = function(self, t) return mesmerTalentStatDamage(self, t, "str", 25, 230) / 2 end,
	getDamageArcane = function(self, t) return mesmerTalentStatDamage(self, t, "mag", 25, 230) / 2 end,
	requires_target = true,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	targetCone = function(self, t)
		return {type="cone", range=0, radius=self:getTalentRange(t), talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local dur = t.getDuration(self, t)
		local damL = t.getDamageLight(self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		self:project(tg, x, y, function(tx, ty)
			local target = game.level.map(tx, ty, Map.ACTOR)
			if target and target ~= self and self:reactionToward(target) < 0 then
				local dam = self:physicalCrit(damL, nil, target, self:combatAttack(), target:combatDefense())
				DamageType:get(DamageType.LIGHT).projector(self, tx, ty, DamageType.LIGHT, dam)
				self:attackTarget(target, nil, 0, true)
				target:setEffect(target.EFF_PINNED, dur, {src=self, apply_power=self:getStr()})
				if self:getTalentLevel(self.T_CRIPPLING_ILLUSIONS) >= 2 and target:canBe("knockback") then
					target:knockback(self.x, self.y, 1)
				end
			end
		end)
		game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "light_beam", {tx=x-self.x, ty=y-self.y})

		local tx, ty = util.findFreeGrid(x, y, 1, true, {[Map.ACTOR]=true})
		if tx and ty and core.fov.distance(self.x, self.y, tx, ty) <= self:getTalentRange(t) and not self.is_mesmer_illusion then
			game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport", {color=colors.VIOLET})
			self:teleportRandom(tx, ty, 0)
		end

		tg = t.targetCone(self, t)
		x, y = self:getTarget(tg)
		if not x or not y then return true end
		local damA = t.getDamageArcane(self, t)
		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self and self:reactionToward(target) < 0 then
				local dam = self:spellCrit(damA)
				target:setEffect(target.EFF_ARCANE_ILLUSION, 4, {src=self, power=dam / 4})
				self:attackTarget(target, nil, 0, true)
				target:setEffect(target.EFF_STUNNED, dur, {src=self, apply_power=self:getMag()})
			end
		end)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_breath", {radius=tg.radius, tx=x-self.x, ty=y-self.y, allow=core.shader.allow("distort")})
		if not self.is_mesmer_illusion then self:knockback(x, y, 1) end
		return true
	end,
	info = function(self, t)
		local damA = t.getDamageArcane(self, t)
		local damL = t.getDamageLight(self, t)
		local dur = t.getDuration(self, t)
		local range = self:getTalentRange(t)
		return ([[Assaults nearby foes with a two-stage attack. First, the mesmer creates a range %d beam that deals light damage to all foes, possibly pinning them. The effects increase with your Strength and your physical crit chance. The mesmer then teleports to the last square in the beam. Second, the mesmer creates a radius %d cone that deals arcane illusion damage to all foes, possibly stunning them. The effects increase with your Magic and your spell crit chance. The mesmer steps back one square away from the cone.
Beam Damage: %0.2f light damage
Beam Effect: Pinned for %d turn(s) (power %d)
Cone Damage: %0.2f arcane illusion damage (over 4 turns)
Cone Effect: Stunned for %d turn(s) (power %d)
In addition, weapon "on melee hit" effects can trigger.]]):format(
			range, range, damDesc(self, DamageType.LIGHT, damL), dur, self:getStr(), damDesc(self, DamageType.ARCANE, damA), dur, self:getMag()
		)
	end,
}

local basetrap = function(self, t, x, y, dur, add)
	local Trap = require "mod.class.Trap"
	local trap = {
		id_by_type = true,
		unided_name = "trap",
		display = '^',
		faction = self.faction,
		summoner = self,
		summoner_gain_exp = true,
		temporary = dur,
		x = x, y = y,
		canAct = false,
		energy = {value=0},
		act = function(trap_self)
			for step = 1, 2 do
				trap_self:realact()
				trap_self:useEnergy()
				trap_self.temporary = trap_self.temporary - 1
				if trap_self.temporary <= 0 then
					if game.level.map(trap_self.x, trap_self.y, engine.Map.TRAP) == trap_self then
						game.level.map:remove(trap_self.x, trap_self.y, engine.Map.TRAP)
					end
					game.level:removeEntity(trap_self, true)
					break
				end
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
	cooldown = function(self, t) return mesmercooldown(self, t, 12) end,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 } },
	on_pre_use = reqlong,
	range = function(self, t) return math.ceil(2 + 1.5 * self:getTalentLevel(t)) end,
	getDuration = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	getDamageLight = function(self, t) return mesmerTalentStatDamage(self, t, "str", 20, 150) end,
	requires_target = true,
	target = function(self, t)
		return {type="cone", range=0, radius=self:getTalentRange(t), talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local dur = t.getDuration(self, t)
		local range = self:getTalentRange(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self and self:reactionToward(target) < 0 then
				self:attackTarget(target, nil, 0, true)
				target:setEffect(target.EFF_PINNED, dur, {src=self, apply_power=self:getMag()})
			end
		end)
		game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_breath", {radius=tg.radius, tx=x-self.x, ty=y-self.y, allow=core.shader.allow("distort")})
		if not self.is_mesmer_illusion then self:knockback(x, y, 1) end

		local trap_tg = {type="hit", nolock=true, pass_terrain=false, nowarning=true, range=range, radius=range, requires_knowledge=true}
		local tx, ty = self:getTarget(trap_tg)
		if not tx or not ty then return true end

		if not game.level.map(tx, ty, Map.TRAP) and not game.level.map:checkEntity(tx, ty, Map.TERRAIN, "block_move") then
			local trap_ent = basetrap(self, t, tx, ty, 120, {
				type = "aether",
				subtype = "light",
				name = "blurred frenzy",
				color = colors.VIOLET,
				image = "trap/aether_beam.png",
				dam = t.getDamageLight(self, t),
				triggered = function() return true, true end,
				combatSpellpower = function(trap_self) return trap_self.summoner:getStr() end,
				rad = 6,
				energy = {value=0, mod=16},
				on_added = function(trap_self, level, gx, gy)
					trap_self.x, trap_self.y = gx, gy
					local tries = {}
					local list = {}
					local sa = rng.range(0, 359)
					local dir = rng.percent(50) and 1 or -1
					for a = sa, sa + 359 * dir, dir do
						local rx, ry = math.floor(math.cos(math.rad(a)) * trap_self.rad), math.floor(math.sin(math.rad(a)) * trap_self.rad)
						tries[rx] = tries[rx] or {}
						if not tries[rx][ry] then
							tries[rx][ry] = true
							list[#list+1] = {x=rx+gx, y=ry+gy}
						end
					end
					trap_self.list = list
					trap_self.list_i = 1
					trap_self.on_added = nil
				end,
				disarmed = function(trap_self)
					game.level:removeEntity(trap_self, true)
				end,
				realact = function(trap_self)
					if game.level.map(trap_self.x, trap_self.y, engine.Map.TRAP) ~= trap_self then
						game.level:removeEntity(trap_self, true)
						return
					end
					if not trap_self.list or #trap_self.list == 0 then return end
					local pt = trap_self.list[trap_self.list_i]
					trap_self.list_i = util.boundWrap(trap_self.list_i + 1, 1, #trap_self.list)
					local beam_tg = {type="beam", range=trap_self.rad, selffire=true, talent=t}
					trap_self.summoner.__project_source = trap_self
					trap_self.summoner:project(beam_tg, pt.x, pt.y, function(bx, by)
						local actor = game.level.map(bx, by, engine.Map.ACTOR)
						if not actor then return end
						if trap_self.summoner:reactionToward(actor) >= 0 then
							local max_ov = 10 * math.max(1, trap_self.summoner:getTalentLevelRaw(trap_self.summoner.T_VORTEX))
							actor:setEffect(actor.EFF_MESMERIC_OVERLOAD, 5, {src=trap_self.summoner, power=10, max=max_ov, no_ct_effect=true})
						elseif actor ~= trap_self then
							local d = trap_self.summoner:physicalCrit(trap_self.dam, nil, actor, trap_self.summoner:combatAttack(), actor:combatDefense())
							DamageType:get(DamageType.LIGHT).projector(trap_self.summoner, bx, by, DamageType.LIGHT, d)
							actor:pull(pt.x, pt.y, 1)
						end
					end)
					trap_self.summoner.__project_source = nil
					game.level.map:particleEmitter(trap_self.x, trap_self.y, math.max(math.abs(pt.x-trap_self.x), math.abs(pt.y-trap_self.y)), "light_beam", {tx=pt.x-trap_self.x, ty=pt.y-trap_self.y})
				end,
			})
			trap_ent.detect_power = trap_ent:combatSpellpower()
			trap_ent.disarm_power = trap_ent:combatSpellpower()
			trap_ent:identify(true)
			trap_ent:resolve()
			trap_ent:resolve(nil, true)
			trap_ent:setKnown(self, true)
			game.level:addEntity(trap_ent)
			game.zone:addEntity(game.level, trap_ent, "trap", tx, ty)
			game.level.map:particleEmitter(tx, ty, 1, "summon")
		end
		return true
	end,
	info = function(self, t)
		local damL = t.getDamageLight(self, t)
		local range = self:getTalentRange(t)
		local dur = t.getDuration(self, t)
		return ([[Controls an area with a two-stage attack. First, the mesmer creates a cone of radius %d that pins foes. The mesmer then steps back one square. Second, the mesmer creates a spinning trap of light anywhere in radius %d. The trap spins with incredible speed, typically enough to hit each nearby creature twice over about 8 turns. The trap harms foes and helps friends in radius 6 (but not those standing directly atop it).
Cone Effect to foes: Pinned for %d turn(s) (power %d)
Cone Effect to foes: Weapon "on melee hit" effects can trigger
Beam Damage to foes: %0.2f light damage to foes
Beam Effect to foes: Push 1 square
Beam Effect to allies: Mesmeric Overload (+10%% to all damage per application, max %d%%) for 5 turns
Cone effects increase with Magic. Beam effects increase with Strength and use your physical crit chance.]]):format(
			range, range, dur, self:getMag(), damDesc(self, DamageType.LIGHT, damL), self:getTalentLevelRaw(t) * 10
		)
	end,
}

newTalent{
	name = "Illusionary Counter",
	type = {"spell/mesmer-longsword", 3},
	require = long_req3,
	points = 5,
	random_ego = "attack",
	cooldown = function(self, t) return mesmercooldown(self, t, 10) end,
	tactical = { BUFF = 2 },
	on_pre_use = reqlong,
	no_energy = true,
	getDuration = function(self, t) return math.ceil(1 + self:getTalentLevel(t)) end,
	getNumber = function(self, t) return math.ceil(self:getTalentLevel(t) / 3) end,
	action = function(self, t)
		self.mesmer_create_illusion = createIllusion
		self:setEffect(self.EFF_ILLUSIONARY_COUNTER, t.getDuration(self, t), {count=t.getNumber(self, t)})
		self:setEffect(self.EFF_OUT_OF_PHASE, 1, {power=100, defense=0, resists=100, effect_reduction=100})
		return true
	end,
	info = function(self, t)
		return ([[Protects and retaliates with a two-stage defense. First, the mesmer creates a personal illusionary shield for %d turns. During turn 1, the shield keeps you out of phase with reality (100%% resist all, 100%% detrimental effect duration reduction). Second, the next %d time(s) a source of damage would be applied to you, this shield attempts to create an illusionary clone adjacent to the attacker. After each such attack you take one step away from the attacker. %s This spell takes no time to cast.]]):format(
			t.getDuration(self, t), t.getNumber(self, t), describeIllusion(self, t)
		)
	end,
}

newTalent{
	name = "Temporal Curtain",
	type = {"spell/mesmer-longsword", 4},
	require = long_req4,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 25) end,
	on_pre_use = reqlong,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 } },
	requires_target = true,
	direct_hit = true,
	range = 10,
	getDamageLight = function(self, t) return mesmerTalentStatDamage(self, t, "str", 10, 170) * 1.5 end,
	getCount = function(self, t) return math.ceil(self:getTalentLevel(t)) end,
	radius = function(self, t) return math.ceil(2 + self:getTalentLevel(t) / 2) end,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), talent=t}
	end,
	targetWall = function(self, t)
		local r = 4
		return {type="wall", range=5, halflength=r, halfmax_spots=r+1}
	end,
	getDuration = function(self, t) return math.ceil(2 + 2 * self:getTalentLevel(t)) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local damL = t.getDamageLight(self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		self:project(tg, x, y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			if self:reactionToward(target) >= 0 then
				target:knockback(x, y, self:getTalentRadius(t))
			else
				local dam = self:physicalCrit(damL, nil, target, self:combatAttack(), target:combatDefense())
				target:setEffect(target.EFF_LIGHT_ILLUSION, 4, {src=self, power=dam / 4})
				target:pull(x, y, self:getTalentRadius(t))
				self:attackTarget(target, nil, 0, true)
			end
		end)
		game.level.map:particleEmitter(x, y, tg.radius, "gravity_spike", {radius=tg.radius, allow=core.shader.allow("distort")})

		local wall_tg = t.targetWall(self, t)
		local wx, wy = self:getTarget(wall_tg)
		if not wx or not wy then return true end
		local dur = t.getDuration(self, t)
		local dam = t.getCount(self, t)
		self:project(wall_tg, wx, wy, function(px, py)
			game.level.map:addEffect(self, px, py, dur, DamageType.TEMPORAL_CURTAIN, dam, 1, 5, nil, {type="temporal_cloud", dam=1}, nil, true)
		end)
		return true
	end,
	info = function(self, t)
		local range = self:getTalentRange(t)
		local radius = self:getTalentRadius(t)
		local count = t.getCount(self, t)
		local dur = t.getDuration(self, t)
		local damL = t.getDamageLight(self, t)
		return ([[Controls an area and manipulates cooldowns with a two-stage attack. First, the mesmer projects a distoring sphere of radius %d in range %d. Enemies within the sphere are damaged and pulled toward the center. Allies within the sphere are pushed out. Second, the mesmer creates a temporal curtain: a wall up to length 9 in range 5 with thickness-radius 1. Whenever a foe interacts with the curtain, up to %d of that foe's available talents (chosen at random) are placed on a %d turn cooldown. For each such talent placed on cooldown, one of the mesmer's cooling-down talents (chosen at random) has its timeout reduced by %d turn(s). Whenever a friendly illusionary clone or phantasm interacts with the wall, one of the illusion's cooldowns is reduced by 1 turn. The wall lasts for %d turn(s).
Sphere Damage to foes: %s light illusion (over 4 turns)
Sphere Effect to foes: Weapon "on melee hit" effects can trigger
Curtain Effect to foes: %d separate %d-turn cooldown transfers
Curtain Effect to foes: Crippled (30%% melee, spell and mental speed) for 3 turns
Sphere effects increase with Strength and use your physical crit chance.]]):format(
			radius, range, count, count, count, dur, damDesc(self, DamageType.LIGHT, damL), count, count
		)
	end,
}

newTalent{
	name = "Phantasmal Bladefighter",
	type = {"spell/mesmer-longsword", 5},
	require = long_req5,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 20) end,
	on_pre_use = reqlong,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 } },
	requires_target = true,
	direct_hit = true,
	range = 8,
	healthPercent = function(self, t) return 0.125 + (0.10 * self:getTalentLevel(t)) end,
	illusionCanMove = true,
	damagePercent = function(self, t) return 50 + (self:getTalentLevel(t) * 10) end,
	target = function(self, t)
		return {type="hit", range=self:getTalentRange(t), nolock=true, nowarning=true}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _, _, _, x, y = self:canProject(tg, x, y)
		if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
			game.logSeen(self, "You do not have line of sight.")
			return nil
		end
		createIllusion(self, x, y, t)
		if not self.is_mesmer_illusion then self:knockback(x, y, 1) end
		return true
	end,
	info = function(self, t)
		return ([[Summons an illusionary clone of you in an empty square in range %d. After the attack the mesmer steps one square away from the target. This illusion is uniquely adaptive: it is the only mesmer illusion capable of moving on its own. %s]]):format(
			self:getTalentRange(t), describeIllusion(self, t)
		)
	end,
}
