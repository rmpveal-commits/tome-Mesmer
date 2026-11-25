local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Mind Wrack",
	type = {"spell/mesmer-shatter", 1},
	require = mind_req1,
	points = 5,
	cooldown = function(self, t) return math.floor(16 - self:getTalentLevel(t)) end,
	tactical = { ATTACKAREA = 2 },
	radius = 2,
	requires_target = false,
	getDamage = function(self, t)
		return mesmerTalentStatDamage(self, t, "cun", 10, 320) * 3 / 4
	end,
	action = function(self, t)
		local dam = t.getDamage(self, t)
		local deaths = 0
		local confuse = 2 * self:getTalentLevel(self.T_CRY_OF_FRUSTRATION)
		local stun = 2 * self:getTalentLevel(self.T_DIVERSION)
		local invis = 2 * self:getTalentLevel(self.T_DISTORTION)
		local pull = 0
		if self:getTalentLevel(self.T_INTO_THE_VOID) > 0 then
			pull = self:getTalentLevel(self.T_INTO_THE_VOID) + 2
		end

		local illusions = {}
		for _, e in pairs(game.level.entities) do
			if e.summoner == self and e.is_mesmer_illusion and not e.dead then
				illusions[#illusions+1] = e
			end
		end

		for _, e in ipairs(illusions) do
			if pull > 0 then
				local pull_tg = {type="ball", range=0, selffire=false, friendlyfire=false, radius=pull, talent=t}
				local tgts = {}
				e:project(pull_tg, e.x, e.y, function(px, py)
					local target = game.level.map(px, py, Map.ACTOR)
					if target and self:reactionToward(target) < 0 then
						tgts[#tgts+1] = {actor=target, sqdist=core.fov.distance(e.x, e.y, px, py)}
					end
				end)
				table.sort(tgts, function(a, b) return a.sqdist < b.sqdist end)
				for _, entry in ipairs(tgts) do
					if entry.actor:canBe("knockback") then
						entry.actor:pull(e.x, e.y, pull_tg.radius)
					end
				end
			end

			local ex, ey = e.x, e.y
			local blast_tg = {type="ball", x=ex, y=ey, radius=2, friendlyfire=false}
			e:project(blast_tg, ex, ey, function(tx, ty)
				local target = game.level.map(tx, ty, Map.ACTOR)
				if not target or self:reactionToward(target) >= 0 then return end
				local localdam = self:mindCrit(dam)
				DamageType:get(DamageType.LIGHT).projector(self, tx, ty, DamageType.LIGHT, localdam)
				DamageType:get(DamageType.ARCANE).projector(self, tx, ty, DamageType.ARCANE, localdam)
				if confuse > 0 then
					target:setEffect(target.EFF_CONFUSED, confuse, {src=self, power=50, apply_power=self:combatMindpower()})
				end
				if stun > 0 then
					target:setEffect(target.EFF_STUNNED, stun, {src=self, power=self:combatMindpower(), apply_power=self:combatMindpower()})
				end
			end)

			e:die(self)
			deaths = deaths + 1
			game.level.map:particleEmitter(ex, ey, 2, "ball_blood", {radius=2})
			game:playSoundNear(e, "talents/fireflash")
		end

		if deaths > 0 and invis > 0 then
			self:setEffect(self.EFF_INVISIBILITY, math.floor(deaths * invis), {
				src = self,
				penalty = 0.4,
				power = deaths * (self:combatMindpower() / 2),
				no_ct_effect = true,
			})
		end

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local pull = 0
		if self:getTalentLevel(self.T_INTO_THE_VOID) > 0 then
			pull = 2 + self:getTalentLevel(self.T_INTO_THE_VOID)
		end
		return ([[Detonate all of your active illusions, harming every foe within radius 2 of one of your illusions.
Damage: %s light and %s arcane.
Stunned: %d turn(s) (power %d, from Diversion).
Confusion: %d turn(s) (power 50%%, from Cry of Frustration).
Pre-Detonation Pull: foes in radius %d (from Into the Void).
Invisibility: %d turn(s) per detonated illusion (power %d, reduces outgoing damage by 40%%, from Distortion).
Effects increase with Cunning. The critical chance is based on your mental crit rate.]]):format(
			damDesc(self, DamageType.LIGHT, damage),
			damDesc(self, DamageType.ARCANE, damage),
			2 * self:getTalentLevel(self.T_DIVERSION),
			self:combatMindpower(),
			2 * self:getTalentLevel(self.T_CRY_OF_FRUSTRATION),
			pull,
			2 * self:getTalentLevel(self.T_DISTORTION),
			self:combatMindpower() / 2
		)
	end,
}

newTalent{
	name = "Diversion",
	type = {"spell/mesmer-shatter", 2},
	points = 5,
	require = mind_req2,
	mode = "passive",
	info = function(self, t)
		local level = self:getTalentLevel(t)
		return ([[Mind Wrack now stuns foes within range of your detonated illusions. Foes are stunned (power %d) for %d turn(s). The effect increases with your Cunning.]]):format(
			self:combatMindpower(), 2 * level
		)
	end,
}

newTalent{
	name = "Cry of Frustration",
	type = {"spell/mesmer-shatter", 3},
	points = 5,
	require = mind_req3,
	mode = "passive",
	info = function(self, t)
		return ([[Mind Wrack now confuses foes within range of your detonated illusions. Foes are confused (power 50%%) for %d turn(s).]]):format(
			2 * self:getTalentLevel(t)
		)
	end,
}

newTalent{
	name = "Distortion",
	type = {"spell/mesmer-shatter", 4},
	points = 5,
	require = mind_req4,
	mode = "passive",
	info = function(self, t)
		return ([[Mind Wrack now takes you out of phase with reality, rendering you Invisible for %d turn(s) cumulative per illusion shattered with power %d cumulative per illusion shattered. As you become invisible you fade out of phase with reality: all of your damage is reduced by 40%%. The effect increases with your Cunning.]]):format(
			2 * self:getTalentLevel(t), self:combatMindpower() / 2
		)
	end,
}

newTalent{
	name = "Into the Void",
	type = {"spell/mesmer-shatter", 5},
	points = 5,
	require = mind_req5,
	mode = "passive",
	info = function(self, t)
		local pull = self:getTalentLevel(t) > 0 and (2 + self:getTalentLevel(t)) or 0
		return ([[Just before each of your illusions detonates via Mind Wrack, it pulls all foes within radius %d toward itself.]]):format(pull)
	end,
}
