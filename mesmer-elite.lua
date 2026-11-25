local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Reflective Feedback",
	type = {"spell/mesmer-elite", 1},
	require = mind_req_high1,
	points = 5,
	random_ego = "defensive",
	cooldown = function(self, t) return mesmercooldown(self, t, 40) end,
	tactical = { DEFEND = 5 },
	requires_target = false,
	getShield = function(self, t)
		return 3.5 * self:getCun() + self:combatTalentScale(t, 120, 400) + self:combatTalentLimit(t, 0.1, 0.01, 0.05) * self.max_life
	end,
	action = function(self, t)
		self:setEffect(self.EFF_DAMAGE_SHIELD, 10, {
			color = {0xcb/255, 0xcb/255, 0xcb/255},
			power = t.getShield(self, t),
			reflect = 100,
		})
		return true
	end,
	info = function(self, t)
		return ([[Create a mesmeric protective shield absorbing and reflecting at most %d damage for 10 turns. Effects increase with Cunning.]]):format(
			t.getShield(self, t)
		)
	end,
}

newTalent{
	name = "Veil",
	type = {"spell/mesmer-elite", 2},
	require = mind_req_high2,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 90) end,
	tactical = { BUFF = 3, ESCAPE = 2 },
	requires_target = false,
	getDuration = function(self, t) return math.ceil(1.5 * self:getTalentLevel(t)) end,
	action = function(self, t)
		local dur = t.getDuration(self, t)
		self:setEffect(self.EFF_INVISIBILITY, dur, {src=self, penalty=0.1, power=self:getCun(), no_ct_effect=true})
		for _, e in pairs(game.level.entities) do
			if e.summoner == self and e.is_mesmer_illusion then
				e:setEffect(e.EFF_INVISIBILITY, dur, {src=self, penalty=0.1, power=self:getCun(), no_ct_effect=true})
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[Grant yourself and all of your illusions invisibility for %d turn(s) (power %d, reduces outgoing damage by only 10%%). Effects increase with Cunning.]]):format(
			t.getDuration(self, t), self:getCun()
		)
	end,
}

newTalent{
	name = "Arcane Thievery",
	type = {"spell/mesmer-elite", 3},
	require = mind_req_high3,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 40) end,
	tactical = {
		CURE = function(self)
			local nb = 0
			for eff_id, _ in pairs(self.tmp) do
				local e = self.tempeffect_def[eff_id]
				if e and e.status == "detrimental" then nb = nb + 1 end
			end
			return nb
		end,
	},
	requires_target = true,
	direct_hit = true,
	no_energy = true,
	range = function(self, t) return 4 + math.floor(self:getTalentLevel(t)) end,
	getNb = function(self, t) return math.floor(self:getTalentLevel(t)) end,
	action = function(self, t)
		local num = t.getNb(self, t)
		local tg = {type="hit", range=self:getTalentRange(t), talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		self:project(tg, x, y, function(tx, ty)
			local target = game.level.map(tx, ty, Map.ACTOR)
			if not target or target == self then return end

			local ben_effs = {}
			for eff_id, p in pairs(target.tmp) do
				local e = target.tempeffect_def[eff_id]
				if e and e.status == "beneficial" then
					ben_effs[#ben_effs+1] = {eff_id, table.clone(p, true)}
				end
			end
			for i = 1, num do
				if #ben_effs == 0 then break end
				local eff = rng.tableRemove(ben_effs)
				target:removeEffect(eff[1])
				eff[2].src = self
				self:setEffect(eff[1], eff[2].dur, eff[2])
			end

			local det_effs = {}
			for eff_id, p in pairs(self.tmp) do
				local e = self.tempeffect_def[eff_id]
				if e and e.status == "detrimental" then
					det_effs[#det_effs+1] = {eff_id, table.clone(p, true)}
				end
			end
			for i = 1, num do
				if #det_effs == 0 then break end
				local eff = rng.tableRemove(det_effs)
				self:removeEffect(eff[1])
				eff[2].src = self
				target:setEffect(eff[1], eff[2].dur, eff[2])
			end
		end)

		game:playSoundNear(self, "talents/water")
		return true
	end,
	info = function(self, t)
		local num = t.getNb(self, t)
		return ([[Using devious manipulations you send %d temporary detrimental effect(s) plaguing you to a foe. At the same time you steal %d temporary beneficial effect(s) from that foe and move them to yourself. Arcane Thievery takes no time to cast. The effects increase with Cunning.]]):format(
			num, num
		)
	end,
}

newTalent{
	name = "Null Field",
	type = {"spell/mesmer-elite", 4},
	require = mind_req_high4,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 80) end,
	tactical = { CURE = 2 },
	range = 10,
	radius = 3,
	direct_hit = true,
	requires_target = true,
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
	end,
	getDuration = function(self, t) return 3 + math.ceil(self:getTalentLevel(t)) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _, _, _, x, y = self:canProject(tg, x, y)
		game.level.map:addEffect(self, x, y, t.getDuration(self, t), DamageType.NULL_FIELD, 1, self:getTalentRadius(t), 5, nil, {type="arcanestorm", dam=1}, nil, true)
		game:playSoundNear(self, "talents/cloud")
		return true
	end,
	info = function(self, t)
		return ([[Summon a null energy field of radius %d for %d turn(s). The field removes all temporary detrimental effects from allies and all temporary beneficial effects from foes. The effects will increase with your Cunning.]]):format(
			self:getTalentRadius(t), t.getDuration(self, t)
		)
	end,
}

newTalent{
	name = "Time Warp",
	type = {"spell/mesmer-elite", 5},
	require = mind_req_high5,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 90) end,
	no_energy = true,
	tactical = { BUFF = 2, CLOSEIN = 2, ESCAPE = 2 },
	getSpeed = function(self, t) return mesmerTalentStatDamage(self, t, "cun", 0.25, 0.50, 0.75) end,
	getDuration = function(self, t) return 1 + math.ceil(self:getTalentLevel(t)) end,
	action = function(self, t)
		local speed = t.getSpeed(self, t)
		local dur = t.getDuration(self, t)
		self:setEffect(self.EFF_SPEED, dur, {power=speed})
		for _, e in pairs(game.level.entities) do
			if e.summoner == self and e.is_mesmer_illusion then
				e:setEffect(e.EFF_SPEED, dur, {power=speed})
			end
		end
		return true
	end,
	info = function(self, t)
		return ([[You deceive time itself. This increases your speed, as well as the speed of all your current illusions, by %d%% for %d turn(s). The effects will increase with your Cunning.]]):format(
			100 * t.getSpeed(self, t), t.getDuration(self, t)
		)
	end,
}
