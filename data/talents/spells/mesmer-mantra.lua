local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Mantra Meditation",
	type = {"spell/mesmer-other", 1},
	require = spells_req1,
	mode = "passive",
	points = 1,
	cooldown = 1,
	no_energy = true,
	direct_hit = true,
	tactical = { DEFEND = 1 },
	callbackOnRest = function(self, t)
		local mantra_list = {
			{self.T_MANTRA_OF_DISTRACTION, "mantra_of_distraction"},
			{self.T_MANTRA_OF_PAIN, "mantra_of_pain"},
			{self.T_MANTRA_OF_CONCENTRATION, "mantra_of_concentration"},
			{self.T_MANTRA_OF_RECOVERY, "mantra_of_recovery"},
			{self.T_MANTRA_OF_RESOLVE, "mantra_of_resolve"},
		}
		for _, pair in ipairs(mantra_list) do
			local tid, attr = pair[1], pair[2]
			if self:knowTalent(tid) then
				local nbMax = math.floor((self:getTalentLevelRaw(tid) + 1) / 2)
				local nbNow = self[attr] or 0
				if nbNow < nbMax then return true end
			end
		end
	end,
	callbackOnActBase = function(self, t)
		self.mantra_regen = (self.mantra_regen or 1) - 1
		if self.mantra_regen <= 0 then
			self.mantra_regen = 30
			local mantra_list = {
				{self.T_MANTRA_OF_DISTRACTION, "mantra_of_distraction"},
				{self.T_MANTRA_OF_PAIN, "mantra_of_pain"},
				{self.T_MANTRA_OF_CONCENTRATION, "mantra_of_concentration"},
				{self.T_MANTRA_OF_RECOVERY, "mantra_of_recovery"},
				{self.T_MANTRA_OF_RESOLVE, "mantra_of_resolve"},
			}
			for _, pair in ipairs(mantra_list) do
				local tid, attr = pair[1], pair[2]
				if self:knowTalent(tid) then
					local nbMax = math.floor((self:getTalentLevelRaw(tid) + 1) / 2)
					local nbNow = self[attr] or 0
					if nbNow < nbMax then
						self[attr] = nbNow + 1
					end
				end
			end
		end
	end,
	info = function(self, t)
		return ([[Use part of your consciousness to meditate on your mantras. You recover one use of each of your known mantras every 30 turns. Activating any mantra resets the required time for all mantras. You will recover another use of each mantra in %d turn(s).]]):format(
			self.mantra_regen or 1
		)
	end,
}

newTalent{
	name = "Mantra of Distraction",
	type = {"spell/mesmer-mantra", 1},
	require = spells_req1,
	points = 5,
	cooldown = 1,
	tactical = { DEFEND = 1, DISABLE = { confusion = 3 } },
	requires_target = false,
	direct_hit = true,
	no_energy = true,
	range = 10,
	getNb = function(self, t) return math.floor((self:getTalentLevelRaw(t) + 1) / 2) end,
	target = function(self, t)
		return {type="ball", range=0, radius=self:getTalentRadius(t), friendlyfire=false, talent=t}
	end,
	radius = function(self, t) return 2 + math.floor(self:getTalentLevel(t)) end,
	getDuration = function(self, t) return 2 + math.floor(mesmerTalentStatDamage(self, t, "mag", 2, 6)) end,
	on_pre_use = function(self, t, silent)
		if (self.mantra_of_distraction or 0) <= 0 then
			if not silent then game.logPlayer(self, "You cannot use Mantra of Distraction until more time passes.") end
			return false
		end
		return true
	end,
	action = function(self, t)
		local nbNow = self.mantra_of_distraction or 0
		if nbNow <= 0 then return nil end

		local tg = self:getTalentTarget(t)
		local dur = t.getDuration(self, t)
		self:project(tg, self.x, self.y, function(tx, ty)
			local target = game.level.map(tx, ty, Map.ACTOR)
			if not target or target == self then return end
			target:setEffect(target.EFF_DAZED, dur, {src=self, apply_power=self:getMag()})
			target:setEffect(target.EFF_CONFUSED, dur, {src=self, power=50, apply_power=self:getMag()})
		end)
		game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "shout", {additive=true, life=10, size=3, distorion_factor=0.5, radius=self:getTalentRadius(t), nb_circles=8, rm=0.7, rM=1, gm=0.7, gM=1, bm=0.7, bM=1, am=0.4, aM=0.6})
		self.mantra_of_distraction = nbNow - 1
		self.mantra_regen = 30
		game:playSoundNear(self, "talents/water")
		return true
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_MANTRA_MEDITATION) then
			self:learnTalent(self.T_MANTRA_MEDITATION, true, nil, {no_unlearn=true})
		end
	end,
	info = function(self, t)
		return ([[Meditate, charging a spell that will distract your target. You store up the energy to use mantras slowly, gaining one charge every 30 turns after last use of any mantra. Once charged, Mantras have no other cooldown and can be used rapidly. Mantra effects increase with Magic.
Mantra of Distraction confuses (power 50%%) and dazes all foes in radius %d for %d turn(s) and takes no time to use.
You currently have %d out of %d stored charges of Mantra of Distraction.]]):format(
			t.radius(self, t), t.getDuration(self, t), self.mantra_of_distraction or 0, t.getNb(self, t)
		)
	end,
}

newTalent{
	name = "Mantra of Pain",
	type = {"spell/mesmer-mantra", 1},
	require = spells_req2,
	points = 5,
	cooldown = 1,
	tactical = { ATTACK = { ARCANE = 2, LIGHT = 2 } },
	requires_target = true,
	direct_hit = true,
	no_energy = true,
	range = 10,
	getNb = function(self, t) return math.floor((self:getTalentLevelRaw(t) + 1) / 2) end,
	getDamage = function(self, t) return mesmerTalentStatDamage(self, t, "mag", 25, 290) end,
	on_pre_use = function(self, t, silent)
		if (self.mantra_of_pain or 0) <= 0 then
			if not silent then game.logPlayer(self, "You cannot use Mantra of Pain until more time passes.") end
			return false
		end
		return true
	end,
	action = function(self, t)
		local nbNow = self.mantra_of_pain or 0
		if nbNow <= 0 then return nil end

		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		self.mantra_of_pain = nbNow - 1
		self.mantra_regen = 30
		local dam = self:spellCrit(t.getDamage(self, t))
		DamageType:get(DamageType.ARCANE).projector(self, x, y, DamageType.ARCANE, dam / 2)
		DamageType:get(DamageType.LIGHT).projector(self, x, y, DamageType.LIGHT, dam / 2)
		game.level.map:particleEmitter(x, y, 1, "circle", {base_rot=0, oversize=0.7, a=130, limit_life=6, appear=6, speed=0, img="curse_gfx_03", radius=0})
		game:playSoundNear(self, "talents/water")
		return true
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_MANTRA_MEDITATION) then
			self:learnTalent(self.T_MANTRA_MEDITATION, true, nil, {no_unlearn=true})
		end
	end,
	info = function(self, t)
		return ([[Meditate, charging a spell that will damage your target. You store up the energy to use mantras slowly, gaining one charge every 30 turns from last use of any mantra. Once charged, Mantras have no other cooldown and can be used rapidly. Mantra effects increase with Magic and the critical chance is based on your magical crit rate.
Mantra of Pain deals %0.2f arcane and %0.2f light damage to one target and takes no time to use.
You currently have %d out of %d stored charges of Mantra of Pain.]]):format(
			damDesc(self, DamageType.ARCANE, t.getDamage(self, t) / 2),
			damDesc(self, DamageType.LIGHT, t.getDamage(self, t) / 2),
			self.mantra_of_pain or 0,
			t.getNb(self, t)
		)
	end,
}

newTalent{
	name = "Mantra of Concentration",
	type = {"spell/mesmer-mantra", 1},
	require = spells_req3,
	points = 5,
	cooldown = 1,
	tactical = { DEFEND = 1 },
	requires_target = false,
	direct_hit = true,
	no_energy = true,
	getNb = function(self, t) return math.floor((self:getTalentLevelRaw(t) + 1) / 2) end,
	getDuration = function(self, t) return 1 + math.floor(mesmerTalentStatDamage(self, t, "mag", 5, 15)) end,
	on_pre_use = function(self, t, silent)
		if (self.mantra_of_concentration or 0) <= 0 then
			if not silent then game.logPlayer(self, "You cannot use Mantra of Concentration until more time passes.") end
			return false
		end
		return true
	end,
	action = function(self, t)
		local nbNow = self.mantra_of_concentration or 0
		if nbNow <= 0 then return nil end

		self.mantra_of_concentration = nbNow - 1
		self.mantra_regen = 30
		self:setEffect(self.EFF_FREE_ACTION, t.getDuration(self, t), {power=1})
		game:playSoundNear(self, "talents/water")
		return true
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_MANTRA_MEDITATION) then
			self:learnTalent(self.T_MANTRA_MEDITATION, true, nil, {no_unlearn=true})
		end
	end,
	info = function(self, t)
		return ([[Meditate, charging a spell that will grant you stability. You store up the energy to use mantras slowly, gaining one charge every 30 turns from last use of any mantra. Once charged, Mantras have no other cooldown and can be used rapidly. Mantra effects increase with Magic.
Mantra of Concentration grants you free action for %d turns. This prevents all stuns, dazes, and pinning effects. Mantra of Concentration takes no time to use.
You currently have %d out of %d stored charges of Mantra of Concentration.]]):format(
			t.getDuration(self, t), self.mantra_of_concentration or 0, t.getNb(self, t)
		)
	end,
}

newTalent{
	name = "Mantra of Resolve",
	type = {"spell/mesmer-mantra", 1},
	require = spells_req4,
	points = 5,
	cooldown = 1,
	tactical = { CURE = 1 },
	requires_target = false,
	no_energy = true,
	direct_hit = true,
	getNb = function(self, t) return math.floor((self:getTalentLevelRaw(t) + 1) / 2) end,
	getCount = function(self, t) return 1 + math.floor(mesmerTalentStatDamage(self, t, "mag", 1, 3)) end,
	on_pre_use = function(self, t, silent)
		if (self.mantra_of_resolve or 0) <= 0 then
			if not silent then game.logPlayer(self, "You cannot use Mantra of Resolve until more time passes.") end
			return false
		end
		return true
	end,
	action = function(self, t)
		local nbNow = self.mantra_of_resolve or 0
		if nbNow <= 0 then return nil end

		self.mantra_of_resolve = nbNow - 1
		self.mantra_regen = 30
		local count = t.getCount(self, t)
		local effs = {}
		for eff_id, _ in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			if e and e.status == "detrimental" then
				effs[#effs+1] = eff_id
			end
		end
		for i = 1, count do
			if #effs == 0 then break end
			self:removeEffect(rng.tableRemove(effs))
		end
		game:playSoundNear(self, "talents/water")
		return true
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_MANTRA_MEDITATION) then
			self:learnTalent(self.T_MANTRA_MEDITATION, true, nil, {no_unlearn=true})
		end
	end,
	info = function(self, t)
		return ([[Meditate, charging a spell that will free you of harmful effects. You store up the energy to use mantras slowly, gaining one charge every 30 turns since last use of any mantra. Once charged, Mantras have no other cooldown and can be used rapidly. Mantra effects increase with Magic.
Mantra of Resolve removes %d detrimental effect(s) currently afflicting you, chosen at random. It takes no time to use.
You currently have %d out of %d stored charges of Mantra of Resolve.]]):format(
			t.getCount(self, t), self.mantra_of_resolve or 0, t.getNb(self, t)
		)
	end,
}

newTalent{
	name = "Mantra of Recovery",
	type = {"spell/mesmer-mantra", 1},
	require = spells_req5,
	points = 5,
	cooldown = 1,
	tactical = { HEAL = 2 },
	requires_target = false,
	direct_hit = true,
	no_energy = true,
	is_heal = true,
	getHeal = function(self, t) return 20 + mesmerTalentStatDamage(self, t, "mag", 15, 480) end,
	getNb = function(self, t) return math.floor((self:getTalentLevelRaw(t) + 1) / 2) end,
	on_pre_use = function(self, t, silent)
		if (self.mantra_of_recovery or 0) <= 0 then
			if not silent then game.logPlayer(self, "You cannot use Mantra of Recovery until more time passes.") end
			return false
		end
		return true
	end,
	on_learn = function(self, t)
		if not self:knowTalent(self.T_MANTRA_MEDITATION) then
			self:learnTalent(self.T_MANTRA_MEDITATION, true, nil, {no_unlearn=true})
		end
	end,
	action = function(self, t)
		local nbNow = self.mantra_of_recovery or 0
		if nbNow <= 0 then return nil end

		self.mantra_of_recovery = nbNow - 1
		self.mantra_regen = 30
		self:attr("allow_on_heal", 1)
		self:heal(self:spellCrit(t.getHeal(self, t)), self)
		self:attr("allow_on_heal", -1)
		game:playSoundNear(self, "talents/water")
		game:playSoundNear(self, "talents/heal")
		return true
	end,
	info = function(self, t)
		return ([[Meditate, charging a spell that will restore your health. You store up the energy to use mantras slowly, gaining one charge every 30 turns since last use of any mantra. Once charged, Mantras have no other cooldown and can be used rapidly. Mantra effects increase with Magic.
Mantra of Recovery restores %0.2f health. Mantra of Recovery takes no time to use.
You currently have %d out of %d stored charges of Mantra of Recovery.]]):format(
			t.getHeal(self, t), self.mantra_of_recovery or 0, t.getNb(self, t)
		)
	end,
}
