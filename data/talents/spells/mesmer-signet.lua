local damDesc = Talents.main_env.damDesc

function removeCondition(self)
	if not self then return end
	local count = self:getTalentLevel(self.T_CLEANSING_SIGNETS)
	if count and count >= 2 then
		local effs = {}
		for eff_id, _ in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			if e and e.status == "detrimental" then
				effs[#effs+1] = eff_id
			end
		end
		if #effs > 0 then
			self:removeEffect(rng.table(effs))
		end
	end
end

newTalent{
	name = "Signet of Illusions",
	type = {"spell/mesmer-signet", 1},
	mode = "sustained",
	no_sustain_autoreset = true,
	require = swords_req1,
	points = 5,
	no_energy = true,
	tactical = { DEFEND = 2 },
	cooldown = function(self, t)
		return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		return {
			per = self:addTemporaryValue("mesmer_illusion_health", self:combatTalentLimit(t, 30, 5, 15)),
		}
	end,
	deactivate = function(self, t, p)
		removeCondition(self)
		self:removeTemporaryValue("mesmer_illusion_health", p.per)
		self.talents_cd[self.T_DECOY] = nil
		self.talents_cd[self.T_MIND_WRACK] = nil
		return true
	end,
	info = function(self, t)
		return ([[While sustained, this signet increases the percentage of your health that each of your newly-created illusions receives by %d%%. When you deactivate this signet (which takes no time) it resets the cooldowns on Mind Wrack and Decoy. The effects will increase with your Strength.]]):format(
			self:combatTalentLimit(t, 30, 5, 15)
		)
	end,
}

newTalent{
	name = "Signet of Domination",
	type = {"spell/mesmer-signet", 1},
	mode = "sustained",
	no_sustain_autoreset = true,
	require = swords_req2,
	points = 5,
	tactical = { DEFEND = 2 },
	cooldown = function(self, t)
		return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
	end,
	radius = function(self, t) return 1 + math.floor(self:getTalentLevel(t)) end,
	direct_hit = true,
	no_energy = true,
	getDamageIncrease = function(self, t)
		return mesmerTalentStatDamage(self, t, "str", 5, 25)
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		local di = t.getDamageIncrease(self, t)
		return {
			dam = self:addTemporaryValue("inc_damage", {
				[DamageType.ARCANE] = di,
				[DamageType.LIGHT] = di,
				[DamageType.PHYSICAL] = di,
			}),
		}
	end,
	deactivate = function(self, t, p)
		removeCondition(self)
		self:removeTemporaryValue("inc_damage", p.dam)
		local tg = {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)}
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				target:setEffect(target.EFF_STUNNED, 3, {src=self, power=self:getStr(), apply_power=self:getStr()})
			end
		end)
		return true
	end,
	info = function(self, t)
		return ([[While sustained, this signet increases the arcane, light and physical damage you deal by %0.2f%%. When you deactivate this signet (which takes no time) it stuns all foes (power %d) within radius %d for 3 turns. The effects will increase with your Strength.]]):format(
			t.getDamageIncrease(self, t), self:getStr(), t.radius(self, t)
		)
	end,
}

newTalent{
	name = "Signet of Midnight",
	type = {"spell/mesmer-signet", 1},
	mode = "sustained",
	no_sustain_autoreset = true,
	require = swords_req3,
	points = 5,
	tactical = { DEFEND = 2 },
	cooldown = function(self, t)
		return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
	end,
	radius = function(self, t) return 1 + math.floor(self:getTalentLevel(t)) end,
	direct_hit = true,
	no_energy = true,
	range = 0,
	getBoonIncrease = function(self, t)
		return 1 + math.floor(self:combatTalentLimit(t, 4, 1, 3))
	end,
	callbackOnActBase = function(self, t)
		if not self.sustain_talents[t.id] then return end
		local dur = t.getBoonIncrease(self, t)
		for eff_id, p in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			if e and e.type ~= "other" and e.status == "beneficial" and not p._signet_of_midnight_extended and (p.dur or 0) > 1 then
				p.dur = p.dur + dur
				p._signet_of_midnight_extended = true
			end
		end
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		return {}
	end,
	deactivate = function(self, t, p)
		removeCondition(self)
		local tg = {type="ball", range=self:getTalentRange(t), selffire=false, friendlyfire=false, radius=self:getTalentRadius(t)}
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and target ~= self then
				target:setEffect(target.EFF_BLINDED, 3, {src=self, power=self:getStr(), apply_power=self:getStr(), no_ct_effect=true})
			end
		end)
		return true
	end,
	info = function(self, t)
		return ([[While sustained, all temporary beneficial effects applied to you have their durations increased by %d turn(s). Each temporary effect instance can be extended only once. The duration increase is applied whenever you take an action, so ephemeral beneficial effects that last at most one turn (such as Mesmeric Dodge) may not be extended. When you deactivate this signet (which takes no time) it blinds all foes (power %d) within radius %d for 3 turns. The effects will increase with your Strength.]]):format(
			t.getBoonIncrease(self, t), self:getStr(), t.radius(self, t)
		)
	end,
}

newTalent{
	name = "Signet of Inspiration",
	type = {"spell/mesmer-signet", 1},
	mode = "sustained",
	no_sustain_autoreset = true,
	require = swords_req4,
	points = 5,
	tactical = { DEFEND = 2 },
	cooldown = function(self, t)
		return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
	end,
	getSpeed = function(self, t) return mesmerTalentStatDamage(self, t, "str", 0.15, 0.5, 0.75) end,
	getSpeedBurst = function(self, t) return mesmerTalentStatDamage(self, t, "str", 470, 750, 0.75) / 2 end,
	getDuration = function(self, t) return 1 + math.floor(self:getTalentLevel(t)) end,
	direct_hit = true,
	no_energy = true,
	range = 0,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		return {
			speed = self:addTemporaryValue("movement_speed", t.getSpeed(self, t)),
		}
	end,
	deactivate = function(self, t, p)
		removeCondition(self)
		self:removeTemporaryValue("movement_speed", p.speed)
		game:onTickEnd(function()
			self:setEffect(self.EFF_WILD_SPEED, t.getDuration(self, t), {power=t.getSpeedBurst(self, t)})
		end)
		return true
	end,
	info = function(self, t)
		return ([[While sustained, your movement speed is increased by %d%%. When you deactivate this signet (which takes no time) it creates a burst of celerity, increasing your movement speed by %d%% for %d turn(s). Any actions other than movement will cancel the effect. The effects will increase with your Strength.]]):format(
			t.getSpeed(self, t) * 100, t.getSpeedBurst(self, t), t.getDuration(self, t)
		)
	end,
}

newTalent{
	name = "Signet of Ether",
	type = {"spell/mesmer-signet", 1},
	mode = "sustained",
	no_sustain_autoreset = true,
	require = swords_req5,
	points = 5,
	tactical = { DEFEND = 2 },
	cooldown = function(self, t)
		return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
	end,
	getRegen = function(self, t) return self:getTalentLevel(t) * 3.0 end,
	getHeal = function(self, t) return mesmerTalentStatDamage(self, t, "str", 40, 440) end,
	direct_hit = true,
	no_energy = true,
	range = 0,
	callbackOnActBase = function(self, t)
		if not self.sustain_talents[t.id] then return end
		self.signet_of_ether_regen = (self.signet_of_ether_regen or 1) - 1
		if self.signet_of_ether_regen <= 0 then
			self.signet_of_ether_regen = 3
			local amount = t.getRegen(self, t)
			local count = 0
			for _, e in pairs(game.level.entities) do
				if e.summoner == self and e.is_mesmer_illusion then
					count = count + 1
				end
			end
			local h = amount * count
			if h > 0 then
				self:attr("allow_on_heal", 1)
				self:heal(h, self)
				self:attr("allow_on_heal", -1)
			end
		end
	end,
	activate = function(self, t)
		game:playSoundNear(self, "talents/slime")
		return {}
	end,
	deactivate = function(self, t, p)
		removeCondition(self)
		self:attr("allow_on_heal", 1)
		self:heal(t.getHeal(self, t), self)
		self:attr("allow_on_heal", -1)
		self.talents_cd[self.T_MIRROR_BLADE] = nil
		self.talents_cd[self.T_PHANTASMAL_BERSERKER] = nil
		self.talents_cd[self.T_PHASE_RETREAT] = nil
		self.talents_cd[self.T_PHANTASMAL_WARLOCK] = nil
		return true
	end,
	info = function(self, t)
		return ([[Every three turns while this signet is sustained you heal %0.2f per illusion you control. When you deactivate (which takes no time) this signet it creates an ethereal burst, healing you for %0.2f. In addition, the burst resets the cooldowns on the Mirror Blade, Phantasmal Berserker, Phase Retreat, and Phantasmal Warlock talents. The effects will increase with your Strength.]]):format(
			t.getRegen(self, t), t.getHeal(self, t)
		)
	end,
}
