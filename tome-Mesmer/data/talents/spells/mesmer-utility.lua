local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Decoy",
	type = {"spell/mesmer-utility", 1},
	require = mind_req1,
	points = 5,
	cooldown = function(self, t) 
          local base = math.ceil(self:combatTalentLimit(t, 15, 45, 25))
          return mesmercooldown(self, t, base) 
        end ,
        no_energy = true, 
	tactical = { DEFEND = 5, ESCAPE = 1 } , 
        requires_target = false, 
        -- same duration as Unstoppable 
        numClones = function(self, t) return
          math.floor((self:getTalentLevelRaw(t)+1) / 2) 
        end , 
        getDuration = function(self, t) return
          1 + math.floor(mesmerTalentStatDamage(self,t, "cun", 2, 6)) end, 
	action = function(self, t)

                for i = 1, t.numClones(self, t) do
                  local tx, ty = util.findFreeGrid(self.x, self.y, 1, true, {[Map.ACTOR]=true})
                  createIllusion(self, tx, ty, t) 
                  game.level.map:particleEmitter(self.x, self.y, 1, "temporal_teleport")
                end
                game:playSoundNear(self, "talents/teleport")

                self:setEffect(self.EFF_INVISIBILITY, 
                  t.getDuration(self, t) ,
                  {src=src, penalty = 0.5, 
                  power=self:getCun(), no_ct_effect=true}) 

		return true
	end,

	info = function(self, t)
                local d = t.getDuration(self, t) 
                local num = t.numClones(self, t) 
		return ([[Gain invisibility for %d turns (power %d, reduces outgoing damage by 50%%). This talent takes no time to use.

In addition, %d illusionary clone(s) of you is created adjacent to your current location (if open space is available). %s Each illusion serves largely to distract foes. 

Effects increase with Cunning.

#LIGHT_BLUE#Commentary: The duration scaling follows "Unstoppable". Invisibility is iconic for illusionist Mesmers, and this utility power provides access to it at low levels (but at 50%% reduced damage instead of the usual 40%%). The invisibility and the clone(s) serve to make this a useful escape power, but be wary of waiting until foes are in melee range to use it, since some foes will see through the invisibility.]]):format(d, 
            self:getCun(), 
            num, 
            describeIllusion(self, t) 
                  ) 
	end,
}

newTalent{
	name = "Ether Feast",
	type = {"spell/mesmer-utility", 2},
	require = mind_req2,
	points = 5,
	random_ego = "utility",
	cooldown = function (self, t) return mesmercooldown(self,t,10) end,
	tactical = { HEAL = 2 },
        requires_target = false, 
	getHeal = function(self, t) 
          return mesmerTalentStatDamage(self, t, "cun", 20, 440) end,
	action = function(self, t)

                local mult = 1.0 
                for _, e in pairs(game.level.entities) do
                  if e.summoner and e.summoner == self and e.is_mesmer_illusion then
                        mult = mult + 0.1
                  end 
                end 

		self:attr("allow_on_heal", 1)
		self:heal(self:mindCrit(t.getHeal(self, t) * mult), self)
		self:attr("allow_on_heal", -1)
		if core.shader.active(4) then
			self:addParticles(Particles.new("shader_shield_temp", 1, {toback=true, size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=2.0, beamColor1={0xd8/255, 0x00/255, 0x21/255, 1}, beamColor2={0xf7/255, 0x00/255, 0x9e/255, 1}, circleDescendSpeed=3}))
			self:addParticles(Particles.new("shader_shield_temp", 1, {toback=false,size_factor=1.5, y=-0.3, img="healcelestial", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0, beamColor1={0xd8/255, 0x00/255, 0x21/255, 1}, beamColor2={0xf7/255, 0x00/255, 0x9e/255, 1}, circleDescendSpeed=3}))
		end
		game:playSoundNear(self, "talents/heal")

		return true
	end,

	info = function(self, t)
                local h = t.getHeal(self, t) 
		return ([[Heal yourself for %d, plus %d per active illusion you control.

Effects increase with Cunning.

#LIGHT_BLUE#Commentary: The scaling and cooldown follow "Healing Light" but at a higher talent requirement. Repeated, weak healing that takes time is a Mesmer hallmark. Much like Archmages and similar squishy casters, Mesmers need early access to healing for survival. The weak-but-reusable nature of this heal provides actions for Mesmers to smooth out their weapon-swap-cooldown cycle.]]):format(h, h/10) 
	end,
}

newTalent{
	name = "Blink Portal",
	type = {"spell/mesmer-utility", 3},
	require = mind_req3,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,30) end,
	tactical = { ESCAPE = 2 },
	range = function (self, t) return 
          10 + math.floor(mesmerTalentStatDamage(self,t, "cun",0, 5)) end,
	radius = function(self, t) return math.floor(self:combatTalentLimit(t, 0, 7, 3)) end, -- Limit to radius 0
	requires_target = true,
	getDuration = function (self, t) return 
          2 + math.floor(mesmerTalentStatDamage(self,t, "cun", 4, 8)) end,
	no_npc_use = true,
	action = function(self, t)
		-- local tg = {type="bolt", nowarning=true, range=1, nolock=true, simple_dir_request=true, talent=t}
		local entrance_x, entrance_y = self.x, self.y
		if not entrance_x or not entrance_y then return nil end
		local _ _, entrance_x, entrance_y = self:canProject(tg, entrance_x, entrance_y)
		local trap = game.level.map(entrance_x, entrance_y, engine.Map.TRAP)
		if trap or game.level.map:checkEntity(entrance_x, entrance_y, Map.TERRAIN, "block_move") then game.logPlayer(self, "You can't place a portal entrance here.") return end

		-- Finding the exit location
		-- First, find the center possible exit locations
		local x, y, radius, minimum_distance
		if true then
			radius = self:getTalentRadius(t)
			minimum_distance = 0
			local tg = {type="ball", nolock=true, pass_terrain=true, nowarning=true, range=self:getTalentRange(t), radius=radius}
			x, y = self:getTarget(tg)
			print("[Target]", x, y)
			if not x then return nil end
			-- Make sure the target is within range
			if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) then
				game.logPlayer(self, "Pick a valid location.")
				return false
			end
		else
			x, y = self.x, self.y
			radius = self:getTalentRange(t)
			minimum_distance = 10
		end
		-- Second, select one of the possible exit locations
		local poss = {}
		for i = x - radius, x + radius do
			for j = y - radius, y + radius do
				if game.level.map:isBound(i, j) and
					core.fov.distance(x, y, i, j) <= radius and
					core.fov.distance(x, y, i, j) >= minimum_distance and
					self:canMove(i, j) and not game.level.map(i, j, engine.Map.TRAP) then
					poss[#poss+1] = {i,j}
				end
			end
		end
		if #poss == 0 then game.logPlayer(self, "No exit location could be found.")	return false end
		local pos = poss[rng.range(1, #poss)]
		exit_x, exit_y = pos[1], pos[2]
		print("[[portal]] entrance ", entrance_x, " :: ", entrance_y)
		print("[[portal]] exit ", exit_x, " :: ", exit_y)

		local power = self:getCun()

		-- Adding the entrance wormhole
		local entrance = mod.class.Trap.new{
			name = "portal",
			type = "annoy", subtype="teleport", id_by_type=true, unided_name = "trap",
			image = "terrain/wormhole.png",
			display = '&', color_r=255, color_g=255, color_b=255, back_color=colors.STEEL_BLUE,
			message = "@Target@ moves onto the portal.",
			temporary = t.getDuration(self, t),
			x = entrance_x, y = entrance_y,
			canAct = false,
			energy = {value=0},
			disarm = function(self, x, y, who) return false end,
			check_hit = power,
			destabilization_power = self:combatMindpower(0.3),
			summoned_by = self, -- "summoner" is immune to it's own traps
			triggered = function(self, x, y, who)
				if who == self.summoned_by then -- or who:checkHit(self.check_hit, who:combatMentalResist()+(who:attr("continuum_destabilization") or 0), 0, 95) and who:canBe("teleport") then -- Bug fix, Deprecrated checkhit call
					-- since we're using a precise teleport we'll look for a free grid first
					local tx, ty = util.findFreeGrid(self.dest.x, self.dest.y, 5, true, {[engine.Map.ACTOR]=true})
					if tx and ty then
						if not who:teleportRandom(tx, ty, 0) then
							game.logSeen(who, "%s tries to enter the wormhole but a violent force pushes it back.", who.name:capitalize())
						elseif who ~= self.summoned_by then
							who:setEffect(who.EFF_CONTINUUM_DESTABILIZATION, 100, {power=self.destabilization_power})
						end
					end
				else
					game.logSeen(who, "%s ignores the portal.", who.name:capitalize())
				end
				return true
			end,
			act = function(self)
				self:useEnergy()
				self.temporary = self.temporary - 1
				if self.temporary <= 0 then
					game.logSeen(self, "The mesmeric portal closes.")
					if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
					game.level:removeEntity(self)
				end
			end,
		}
		entrance.faction = nil
		game.level:addEntity(entrance)
		entrance:identify(true)
		entrance:setKnown(self, true)
		game.zone:addEntity(game.level, entrance, "trap", entrance_x, entrance_y)
		game.level.map:particleEmitter(entrance_x, entrance_y, 1, "teleport")
		game:playSoundNear(self, "talents/heal")

                if not self:teleportRandom(exit_x, exit_y, 0) then
                        game.logSeen(self, "Part of the portal fizzles!")
                end

		-- Adding the exit wormhole
		local exit = entrance:clone()
		exit.x = exit_x
		exit.y = exit_y
		game.level:addEntity(exit)
		exit:identify(true)
		exit:setKnown(self, true)
		game.zone:addEntity(game.level, exit, "trap", exit_x, exit_y)
		game.level.map:particleEmitter(exit_x, exit_y, 1, "teleport")

		-- Linking the wormholes
		entrance.dest = exit
		exit.dest = entrance

		game.logSeen(self, "%s creates a mesmeric portal between two points.", self.name)
		return true
	end,
	info = function(self, t)
		local duration = t.getDuration(self, t)
		local radius = self:getTalentRadius(t)
		return ([[You create a mesmeric portal, bridging the space between yourself and a point within range. You immediately step through, leaving behind a pair of linked portal entrances. If you step on either portal you will be teleported to the other. The portals will last %d turns. You may choose the general exit location target area (radius %d within range).  
                
The effects scale with your Cunning.

#LIGHT_BLUE#Commentary: The allies-only temporary portal is an iconic Mesmer power. The scaling and effects here follow "Wormhole" almost directly, but with one end of the portal under the Mesmer's feet and the other at an almost-random point in range (often into an unexplored area). This is provides a crucial but chancy additional escape power for Mesmers, and at higher levels can also be used for profitable back-and-forth kiting.]])
		:format(duration, radius)
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
        end ,
        no_energy = true, 
	tactical = { DEFEND = 3 } , 
        requires_target = false, 
        getDuration = function(self, t) return
          1 + math.floor(mesmerTalentStatDamage(self,t, "cun", 10, 20)) end, 
        getBonus = function(self, t) return 
          mesmerTalentStatDamage(self,t, "cun", 5, 15) end,
        getHealth = function(self, t) return 
          mesmerTalentStatDamage(self,t, "cun", 50, 300) end,

	action = function(self, t)

                local dur = t.getDuration(self, t) 
                local bon = t.getBonus(self, t)
                local hea = t.getHealth(self, t) 
                self:setEffect(self.EFF_HEROISM, dur, 
                  {power=bon, die_at = hea}) 

		return true
	end,

	info = function(self, t)
                local d = t.getDuration(self, t) 
                local bonus = t.getBonus(self, t)
                local health = t.getHealth(self, t) 
		return ([[Surround yourself with an illusion of life. This increases three of your primary stats by %d for %d turn(s). 

In addition, while this effect is active, you will only die when reaching -%d life. However, when below 0 you cannot see how much life you have left. 

The effect will always increase your three highest stats and scales with your Cunning.

#LIGHT_BLUE#Commentary: The effects follow "Infusion: Heroism". This provides another last-second saving grace power for squishy Mesmers. The relatively long duration should allow Mesmers losing a fight to escape and recover.]]):format(bonus, d, health) 
                
	end,
}

newTalent{
	name = "Phantasmal Defender",
	type = {"spell/mesmer-utility", 5},
	require = mind_req5,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,30) end,
	tactical = { ATTACK = { weapon = 2 }, }, 
        requires_target = true, 
        on_pre_use = reqstaff,
        range = function(self, t)
          return 2 + math.ceil(self:getTalentLevel(t)) 
        end,
        healthPercent = function(self, t)
          return mesmerTalentStatDamage(self,t, "cun", 50, 300) / 100
        end,

	action = function(self, t)
                local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, talent=t}
                -- self:getTalentTarget(t)
                local x, y, target = self:getTarget(tg)
                if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
                        game.logSeen(self, "You do not have line of sight.")
                        return nil
                end

                createIllusion(self, x, y, t) 
		return true
	end,

	info = function(self, t)
                local range = self:getTalentRange(t) 
		return ([[Summons an illusionary clone of you in an empty square in range %d. 

%s It serves largely to distract your foes.

The effects increase with your Cunning.

#LIGHT_BLUE#Commentary: The primary advantage of this power is the high health of the illusionary clone. This allows it to serve either as an indirect damage shield while you fight or as a long-lived distraction while you flee.]]): 
                format(range, 
                  describeIllusion(self, t) 
                ) 
	end,
}
