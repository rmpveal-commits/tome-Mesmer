local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Mesmeric Dodge",
	type = {"spell/mesmer-trait", 1},
	require = mind_req1,
	points = 2,
	cooldown = 5,
	tactical = { ESCAPE = 2, DEFEND = 1 },
	requires_target = false,
	is_teleport = true,
	direct_hit = true,
	range = 2,
	target = function(self, t)
		return {type="hit", range=self:getTalentRange(t), nolock=true, nowarning=true}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		local ox, oy = self.x, self.y
		if not x or not y then return nil end
		if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
			game.logSeen(self, "You do not have line of sight.")
			return nil
		end
		local _, x, y = self:canProject(tg, x, y)
		game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
		local tx, ty = util.findFreeGrid(x, y, 1, true, {[Map.ACTOR]=true})
		if tx and ty then
			if not self:teleportRandom(tx, ty, 0) then
				game.logSeen(self, "The spell fizzles!")
				return nil
			end
		end
		self:setEffect(self.EFF_OUT_OF_PHASE, 1, {power=100, defense=0, resists=100, effect_reduction=100})
		if self == game.player then
			self:attr("quick_weapon_swap", 1)
			self:quickSwitchWeapons()
			self:attr("quick_weapon_swap", -1)
		end
		game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
		game:playSoundNear(self, "talents/teleport")
		if self:getTalentLevel(t) >= 2 then
			local ix, iy = util.findFreeGrid(ox, oy, 1, true, {[Map.ACTOR]=true})
			if ix and iy then
				createIllusion(self, ix, iy, t)
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Perform a mesmeric dodge, teleporting you to an open square within range. During the dodge you become out of phase with reality (100%% resist all, 100%% detrimental effect duration reduction) for one turn, rendering you almost invulnerable. In addition, during the dodge you quickly swap your current weapon set and your alternate weapon set. At Talent level 2, you also create an illusionary clone of yourself in your old location. %s]]):format(
			describeIllusion(self, t)
		)
	end,
}

newTalent{
	name = "Crippling Illusions",
	type = {"spell/mesmer-trait", 1},
	require = mind_req1,
	mode = "passive",
	points = 2,
	info = function(self, t)
		return [[At Talent level 1, this trait has no effect. At Talent level 2, all illusions you create release a slowing backlash when destroyed, crippling all foes in radius 2 (reducing their speed by 30%) for 3 turns. This occurs whenever an illusion dies for any reason. In addition, your Winds of Chaos, Spatial Surge and Ether Blast talents knock foes back by 1 square.]]
	end,
}

newTalent{
	name = "Illusionary Frenzy",
	type = {"spell/mesmer-trait", 1},
	require = mind_req1,
	mode = "passive",
	points = 2,
	info = function(self, t)
		return [[At Talent level 1, this trait has no effect. At Talent level 2, all illusions you create have a +20% increased critical hit chance on all attacks. In addition, creating an illusion reduces your current remaining Mantra meditation recharge time by 50%.]]
	end,
}

newTalent{
	name = "Cleansing Signets",
	type = {"spell/mesmer-trait", 1},
	require = mind_req1,
	mode = "passive",
	points = 2,
	info = function(self, t)
		return [[At Talent level 1, this trait has no effect. At Talent level 2, whenever you deactivate a signet its mesmeric energies purge one temporary detrimental effect from you, chosen at random.]]
	end,
}

newTalent{
	name = "Restorative Illusions",
	type = {"spell/mesmer-trait", 1},
	require = mind_req1,
	mode = "passive",
	points = 2,
	info = function(self, t)
		local heal = mesmerTalentStatDamage(self, t, "cun", 20, 440) / 4
		return ([[At Talent level 1, this trait has no effect. At Talent level 2, whenever one of your illusions dies you scavenge some of its etheric essence and heal yourself for %d. The effect scales with Cunning.]]):format(heal)
	end,
}
