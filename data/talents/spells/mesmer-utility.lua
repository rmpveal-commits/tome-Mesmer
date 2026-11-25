local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Decoy",
	type = {"spell/mesmer-utility", 1},
	require = mind_req1,
	points = 5,
	cooldown = function(self, t)
		local base = math.ceil(self:combatTalentLimit(t, 15, 45, 25))
		return mesmercooldown(self, t, base)
	end,
	no_energy = true,
	tactical = { DEFEND = 5, ESCAPE = 1 },
	requires_target = false,
	numClones = function(self, t)
		return math.floor((self:getTalentLevelRaw(t) + 1) / 2)
	end,
	getDuration = function(self, t)
		return 1 + math.floor(mesmerTalentStatDamage(self, t, "cun", 2, 6))
	end,
	action = function(self, t)
		for i = 1, t.numClones(self, t) do
			local tx, ty = util.findFreeGrid(self.x, self.y, 1, true, {[Map.ACTOR]=true})
			if tx and ty then
				createIllusion(self, tx, ty, t)
				game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
			end
		end
		game:playSoundNear(self, "talents/teleport")
		self:setEffect(self.EFF_INVISIBILITY, t.getDuration(self, t), {src=self, penalty=0.5, power=self:getCun(), no_ct_effect=true})
		return true
	end,
	info = function(self, t)
		return ([[Gain invisibility for %d turns (power %d, reduces outgoing damage by 50%%). This talent takes no time to use. In addition, %d illusionary clone(s) of you is created adjacent to your current location (if open space is available). %s Effects increase with Cunning.]]):format(
			t.getDuration(self, t), self:getCun(), t.numClones(self, t), describeIllusion(self, t)
		)
	end,
}

newTalent{
	name = "Ether Feast",
	type = {"spell/mesmer-utility", 2},
	require = mind_req2,
	points = 5,
	random_ego = "utility",
	cooldown = function(self, t) return mesmercooldown(self, t, 10) end,
	tactical = { HEAL = 2 },
	requires_target = false,
	getHeal = function(self, t)
		return mesmerTalentStatDamage(self, t, "cun", 20, 440)
	end,
	action = function(self, t)
		local mult = 1.0
		for _, e in pairs(game.level.entities) do
			if e.summoner == self and e.is_mesmer_illusion then
				mult = mult + 0.1
			end
		end
		self:attr("allow_on_heal", 1)
		self:heal(self:mindCrit(t.getHeal(self, t) * mult), self)
		self:attr("allow_on_heal", -1)
		game:playSoundNear(self, "talents/heal")
		return true
	end,
	info = function(self, t)
		local h = t.getHeal(self, t)
		return ([[Heal yourself for %d, plus %d per active illusion you control. Effects increase with Cunning.]]):format(h, h / 10)
	end,
}

newTalent{
	name = "Blink Portal",
	type = {"spell/mesmer-utility", 3},
	require = mind_req3,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 30) end,
	tactical = { ESCAPE = 2 },
	range = function(self, t) return 10 + math.floor(mesmerTalentStatDamage(self, t, "cun", 0, 5)) end,
	radius = function(self, t) return math.floor(self:combatTalentLimit(t, 0, 7, 3)) end,
	getDuration = function(self, t) return 2 + math.floor(mesmerTalentStatDamage(self, t, "cun", 4, 8)) end,
	no_npc_use = true,
	action = function(self, t)
		local entrance_x, entrance_y = self.x, self.y
		if not entrance_x or not entrance_y then return nil end
		local trap = game.level.map(entrance_x, entrance_y, engine.Map.TRAP)
		if trap or game.level.map:checkEntity(entrance_x, entrance_y, Map.TERRAIN, "block_move") then
			game.logPlayer(self, "You can't place a portal entrance here.")
			return nil
		end

		local radius = self:getTalentRadius(t)
		local tg = {type="ball", nolock=true, pass_terrain=true, nowarning=true, range=self:getTalentRange(t), radius=radius}
		local tx, ty = self:getTarget(tg)
		if not tx or not ty then return nil end
		if core.fov.distance(self.x, self.y, tx, ty) > self:getTalentRange(t) then
			game.logPlayer(self, "Pick a valid location.")
			return false
		end

		local poss = {}
		for i = tx - radius, tx + radius do
			for j = ty - radius, ty + radius do
				if game.level.map:isBound(i, j) and core.fov.distance(tx, ty, i, j) <= radius and self:canMove(i, j) and not game.level.map(i, j, engine.Map.TRAP) then
					poss[#poss+1] = {i, j}
				end
			end
		end
		if #poss == 0 then
			game.logPlayer(self, "No exit location could be found.")
			return false
		end
		local pos = rng.table(poss)
		local exit_x, exit_y = pos[1], pos[2]
		local dur = t.getDuration(self, t)

		local entrance = mod.class.Trap.new{
			name = "portal",
			type = "annoy",
			subtype = "teleport",
			id_by_type = true,
			unided_name = "trap",
			image = "terrain/wormhole.png",
			display = '&',
			color_r = 255, color_g = 255, color_b = 255,
			back_color = colors.STEEL_BLUE,
			message = "@Target@ moves onto the portal.",
			temporary = dur,
			x = entrance_x, y = entrance_y,
			canAct = false,
			energy = {value=0},
			disarm = function() return false end,
			destabilization_power = self:combatMindpower(0.3),
			summoned_by = self,
			triggered = function(trap_self, px, py, who)
				if not who or not trap_self.dest then return end
				if who == trap_self.summoned_by or trap_self.summoned_by:reactionToward(who) >= 0 then
					local fx, fy = util.findFreeGrid(trap_self.dest.x, trap_self.dest.y, 5, true, {[engine.Map.ACTOR]=true})
					if fx and fy then
						if not who:teleportRandom(fx, fy, 0) then
							game.logSeen(who, "%s tries to enter the wormhole but a violent force pushes it back.", who.name:capitalize())
						elseif who ~= trap_self.summoned_by then
							who:setEffect(who.EFF_CONTINUUM_DESTABILIZATION, 100, {power=trap_self.destabilization_power})
						end
					end
				else
					game.logSeen(who, "%s ignores the portal.", who.name:capitalize())
				end
				return true
			end,
			act = function(trap_self)
				trap_self:useEnergy()
				trap_self.temporary = trap_self.temporary - 1
				if trap_self.temporary <= 0 then
					game.logSeen(trap_self, "The mesmeric portal closes.")
					if game.level.map(trap_self.x, trap_self.y, engine.Map.TRAP) == trap_self then
						game.level.map:remove(trap_self.x, trap_self.y, engine.Map.TRAP)
					end
					game.level:removeEntity(trap_self)
				end
			end,
		}

		game.level:addEntity(entrance)
		entrance:identify(true)
		entrance:setKnown(self, true)
		game.zone:addEntity(game.level, entrance, "trap", entrance_x, entrance_y)
		game.level.map:particleEmitter(entrance_x, entrance_y, 1, "teleport")

		if not self:teleportRandom(exit_x, exit_y, 0) then
			game.logSeen(self, "Part of the portal fizzles!")
		end

		local exit = entrance:clone()
		exit.x, exit.y = exit_x, exit_y
		game.level:addEntity(exit)
		exit:identify(true)
		exit:setKnown(self, true)
		game.zone:addEntity(game.level, exit, "trap", exit_x, exit_y)
		game.level.map:particleEmitter(exit_x, exit_y, 1, "teleport")

		entrance.dest = exit
		exit.dest = entrance
		game:playSoundNear(self, "talents/heal")
		game.logSeen(self, "%s creates a mesmeric portal between two points.", self.name)
		return true
	end,
	info = function(self, t)
		return ([[You create a mesmeric portal, bridging the space between yourself and a point within range. You immediately step through, leaving behind a pair of linked portal entrances. If you or an ally step on either portal you will be teleported to the other. The portals will last %d turns. You may choose the general exit location target area (radius %d within range). The effects scale with your Cunning.]]):format(
			t.getDuration(self, t), self:getTalentRadius(t)
		)
	end,
}

newTalent{
	name = "Illusion of Life",
	type = {"spell/mesmer-utility", 4},
	require = mind_req4,
	points = 5,
	cooldown = function(self, t)
		local base = math.ceil(self:combatTalentLimit(t, 30, 90, 60))
		return mesmercooldown(self, t, base)
	end,
	no_energy = true,
	tactical = { DEFEND = 3 },
	requires_target = false,
	getDuration = function(self, t) return 1 + math.floor(mesmerTalentStatDamage(self, t, "cun", 10, 20)) end,
	getBonus = function(self, t) return mesmerTalentStatDamage(self, t, "cun", 5, 15) end,
	getHealth = function(self, t) return mesmerTalentStatDamage(self, t, "cun", 50, 300) end,
	action = function(self, t)
		self:setEffect(self.EFF_HEROISM, t.getDuration(self, t), {power=t.getBonus(self, t), die_at=t.getHealth(self, t)})
		return true
	end,
	info = function(self, t)
		return ([[Surround yourself with an illusion of life. This increases three of your primary stats by %d for %d turn(s). In addition, while this effect is active, you will only die when reaching -%d life. The effect will always increase your three highest stats and scales with your Cunning.]]):format(
			t.getBonus(self, t), t.getDuration(self, t), t.getHealth(self, t)
		)
	end,
}

newTalent{
	name = "Phantasmal Defender",
	type = {"spell/mesmer-utility", 5},
	require = mind_req5,
	points = 5,
	cooldown = function(self, t) return mesmercooldown(self, t, 30) end,
	tactical = { ATTACK = { weapon = 2 } },
	requires_target = true,
	on_pre_use = reqstaff,
	range = function(self, t) return 2 + math.ceil(self:getTalentLevel(t)) end,
	healthPercent = function(self, t) return mesmerTalentStatDamage(self, t, "cun", 50, 300) / 100 end,
	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, talent=t}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _, _, _, x, y = self:canProject(tg, x, y)
		if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
			game.logSeen(self, "You do not have line of sight.")
			return nil
		end
		createIllusion(self, x, y, t)
		return true
	end,
	info = function(self, t)
		return ([[Summons an illusionary clone of you in an empty square in range %d. %s It serves largely to distract your foes. The effects increase with your Cunning.]]):format(
			self:getTalentRange(t), describeIllusion(self, t)
		)
	end,
}
