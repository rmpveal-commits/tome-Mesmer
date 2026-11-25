local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Reflective Feedback",
	type = {"spell/mesmer-elite", 1},
	require = mind_req_high1,
	points = 5,
	random_ego = "defensive",
	cooldown = function (self, t) return mesmercooldown(self,t,40) end,
	tactical = { DEFEND = 5 } , 
        requires_target = false, 
        getShield = function(self, t) -- same as "Bone Shield" 
                return 3.5*self:getCun()+self:combatTalentScale(t, 120, 400) + self:combatTalentLimit(t, 0.1, 0.01, 0.05)*self.max_life
        end,
        action = function(self, t)
          self:setEffect(self.EFF_DAMAGE_SHIELD, 10,
              {color={0xcb/255, 0xcb/255, 0xcb/255},

              power=t.getShield(self, t), reflect=100})
          return true
        end,
	info = function(self, t)
                local pow = t.getShield(self, t) 
		return ([[Create a mesmeric protective shield absorbing and reflecting at most %d damage for 10 turns. 

Effects increase with Cunning.

#LIGHT_BLUE#Commentary: Much like the Archmage, the Mesmer relies on avoiding damage and damage shields. The scaling is the same as "Bone Armor" but the cooldown is 30%% longer and the shield reflects.]]):format(pow) 
	end,
}

newTalent{
	name = "Veil",
	type = {"spell/mesmer-elite", 2},
	require = mind_req_high2,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,90) end,
	tactical = { BUFF = 3, ESCAPE = 2  } , 
        requires_target = false, 
        -- same duration as Unstoppable 
        getDuration = function(self, t) return
          math.ceil(1.5 * self:getTalentLevel(t))
          -- math.ceil(self:combatTalentLimit(t, 10, 2, 9)) 
        end,
	action = function(self, t)

                self:setEffect(self.EFF_INVISIBILITY, 
                  t.getDuration(self, t) ,
                  {src=src, penalty = 0.1, 
                  power=self:getCun(), no_ct_effect=true}) 

                for _, e in pairs(game.level.entities) do
                  if e.summoner and e.summoner == self and e.is_mesmer_illusion then
                e:setEffect(self.EFF_INVISIBILITY, 
                  t.getDuration(self, t) ,
                  {src=src, penalty = 0.1, 
                  power=self:getCun(), no_ct_effect=true}) 
                  end
                end 

		return true
	end,

	info = function(self, t)
                local d = t.getDuration(self, t) 
		return ([[Grant yourself and all of your illusions invisibility for %d turn(s) (power %d, reduces outgoing damage by only 10%%). 

Effects increase with Cunning.

#LIGHT_BLUE#Commentary: Most invisibility effects in the game reduce damage by 40%% to prevent abuse: this one has a temporary duration and very high cooldown instead, creating a different feel.]]):format(d, self:getCun()) 
	end,
}

newTalent{
	name = "Arcane Thievery",
	type = {"spell/mesmer-elite", 3},
	require = mind_req_high3,
	points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,40) end,
	tactical = { CURE = function(self,t,target) 
                local nb = 0
                for eff_id, p in pairs(self.tmp) do
                        local e = self.tempeffect_def[eff_id]
                        if e.status == "detrimental" then
                                nb = nb + 1
                        end
                end
                return nb
        end }, 
        requires_target = true, 
        direct_hit = true, 
        no_energy = true, 
	range = function (self, t) return 
          4 + math.floor(self:getTalentLevel(t)) 
          -- range = 5, 
        end, 
        getNb = function(self, t)
          return math.floor(self:getTalentLevel(t)) 
          -- return math.ceil(self:combatTalentLimit(t, 5, 1, 5))
        end,
	action = function(self, t)
                local num = t.getNb(self, t) 
                local tg = {type="hit", range=self:getTalentRange(t), talent=t}
                local x, y = self:getTarget(tg)
                if not x or not y then return nil end
                self:project(tg, x, y, function(tx, ty)
                        local target = game.level.map(tx, ty, Map.ACTOR)
                        if not target or target == self then return end

                local effs = {}
                -- Go through all spell effects
                for eff_id, p in pairs(target.tmp) do
                        local e = target.tempeffect_def[eff_id]
                        if e.status == "beneficial" then
                                effs[#effs+1] = {"effect", eff_id, p}
                        end
                end
                for i = 1, num do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                target:removeEffect(eff[2])
                                self:setEffect(eff[2], eff[3].dur, eff[3]) 
                        end
                end

                local effs = {}
                for eff_id, p in pairs(self.tmp) do
                        local e = self.tempeffect_def[eff_id]
                        if e.status == "detrimental" then
                                effs[#effs+1] = {"effect", eff_id, p}
                        end
                end
                for i = 1, num do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                self:removeEffect(eff[2])
                                target:setEffect(eff[2], eff[3].dur, eff[3]) 
                        end
                end

                end) 
                game:playSoundNear(self, "talents/water")
                return true
	end,

	info = function(self, t)
                local num = t.getNb(self, t) 
		return ([[Using devious manipulations you send %d temporary detrimental effect(s) plaguing you to a foe. At the same time you steal %d temporary beneficial effect(s) from that foe and move them to yourself.

Arcane Thievery takes no time to cast. The effects increase with Cunning.

#LIGHT_BLUE#Commentary: Mesmers have no innate way to gain resistance to elements or to stunning, confusion, pinning, etc. Talents such as this are critical for dealing with detrimental effects.]]):
                format( num, num ) 
	end,
}


newTalent{
        name = "Null Field",
        type = {"spell/mesmer-elite",4},
        require = mind_req_high4,
        points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,80) end,
        tactical = { CURE = 2 },
        range = 10,
        radius = 3,
        direct_hit = true,
        requires_target = true,
        on_pre_use = reqstaff,
        target = function(self, t)
                return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t)}
        end,
        getDuration = function(self, t) 
          return 3 + math.ceil(self:getTalentLevel(t))
          -- return 1 + math.ceil(self:combatTalentLimit(t, 10, 4, 8)) 
        end,
        action = function(self, t)
                local tg = self:getTalentTarget(t)
                local x, y = self:getTarget(tg)
                if not x or not y then return nil end
                local _ _, _, _, x, y = self:canProject(tg, x, y)
                -- Add a lasting map effect
                game.level.map:addEffect(self,
                        x, y, t.getDuration(self, t),
                        DamageType.NULL_FIELD, 1,
                        self:getTalentRadius(t),
                        5, nil,
                        {type="arcanestorm", dam=1},
                        nil, true
                )
                game:playSoundNear(self, "talents/cloud")
                return true
        end,
        info = function(self, t)
                local radius = self:getTalentRadius(t) 
                local duration = t.getDuration(self, t)
                return ([[Summon null energy field of radius %d for %d turn(s). The field removes all temporary detrimental effects from allies and all temporary beneficial effects from foes. 

The effects will increase with your Cunning.

#LIGHT_BLUE#Commentary: Mesmers have no innate way to gain resistance to elements or to stunning, confusion, pinning, etc. This talent is critical for dealing with foes that repeatedly apply detrimental effects.]]):
                format(radius, 
                duration)
        end,
}


newTalent{
        name = "Time Warp",
        type = {"spell/mesmer-elite",5},
        require = mind_req_high5,
        points = 5,
	cooldown = function (self, t) return mesmercooldown(self,t,90) end,
        no_energy = true,
        tactical = { BUFF = 2, CLOSEIN = 2, ESCAPE = 2 },
        getSpeed = function(self, t) return 0.50 
          -- self:combatTalentScale(t, 0.14, 0.45, 0.75) 
        end,
        getDuration = function(self, t) 
          return 1 + math.ceil(self:getTalentLevel(t))
          -- return math.ceil(self:combatTalentLimit(t, 8, 1, 6)) 
        end, 
        action = function(self, t)
                self:setEffect(self.EFF_SPEED, 
                  t.getDuration(self, t), {power=t.getSpeed(self, t)})
                for _, e in pairs(game.level.entities) do
                  if e.summoner and e.summoner == self and e.is_mesmer_illusion then
                    e:setEffect(self.EFF_SPEED, 
                      t.getDuration(self, t), {power=t.getSpeed(self, t)})
                  end
                end 
                return true
        end,
        info = function(self, t)
                return ([[You deceive time itself. This increases your speed, as well as the speed of all your current illusions, by %d%% for %d turn(s). 

The effects will increase with your Cunning.

#LIGHT_BLUE#Commentary: The duration scaling (from 3 to 7) approximates "Blinding Speed" (which is always 5). The cooldown is about twice that of of "Blinding Speed".]]):
                format(100*t.getSpeed(self, t),
                       t.getDuration(self,t))
        end,
}
