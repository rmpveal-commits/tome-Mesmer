local damDesc = Talents.main_env.damDesc

newTalent{
	name = "Mind Wrack",
	type = {"spell/mesmer-shatter", 1},
	require = mind_req1,
	points = 5,
	cooldown = function(self, t) 
          return math.floor(16 - self:getTalentLevel(t))
        end ,
	tactical = { ATTACKAREA = 2 } , 
        radius = 2, 
        requires_target = false, 
        getDamage = function(self, t)
          -- 3/4 Shatter, but applied twice 
          return mesmerTalentStatDamage(self,t, "cun", 10, 320) * 3 / 4
        end,
	action = function(self, t)

                local dam = t.getDamage(self, t) 
                local deaths = 0 
                local confuse = 2*self:getTalentLevel(self.T_CRY_OF_FRUSTRATION) 
                local stun = 2*self:getTalentLevel(self.T_DIVERSION) 
                local invis = 2*self:getTalentLevel(self.T_DISTORTION) 
                local pull = 0
                if self:getTalentLevel(self.T_INTO_THE_VOID) and 
                   self:getTalentLevel(self.T_INTO_THE_VOID) > 0 then
                   pull = self:getTalentLevel(self.T_INTO_THE_VOID) + 2 
                end 

                for _, e in pairs(game.level.entities) do
                  if e.summoner and e.summoner == self and e.is_mesmer_illusion then

                    if pull > 0 then
                      local tg = {type="ball", range=0, selffire=false,
                        friendlyfire=false, radius=pull, talent=t}
                      local tgts = {}
                      e:project(tg, e.x, e.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target then
                          tgts[#tgts+1] = {actor=target, sqdist=core.fov.distance(e.x, e.y, px, py)}
                        end
                      end)
                      table.sort(tgts, "sqdist")
                      for i, target in ipairs(tgts) do
                        target.actor:pull(e.x, e.y, tg.radius)
                      end
                    end 

                    local x = e.x
                    local y = e.y 
                    local tg = { type="ball", x=x, y=y, radius=2, friendlyfire=false} 
                    e:project(tg, x, y, function(tx, ty)
                        local target = game.level.map(tx, ty, Map.ACTOR)
                        if not target then return end

                        local localdam = self:mindCrit(dam)
                        DamageType:get(DamageType.LIGHT).projector(self, tx, ty, DamageType.LIGHT, localdam)
                        DamageType:get(DamageType.ARCANE).projector(self, tx, ty, DamageType.ARCANE, localdam)
                        if confuse > 0 then
                          target:setEffect(target.EFF_CONFUSED, confuse, 
                            {src=self, power= 50}) 
                        end 
                        if stun > 0 then
                          target:setEffect(target.EFF_STUNNED, stun, {src=src, 
                            power=self:getCun()}) 
                        end 

                    end) 
                    e:die(self) 
                    deaths = deaths + 1 
                    game.level.map:particleEmitter(x, y, 2, "ball_blood", {radius=2})
                    game:playSoundNear(e, "talents/fireflash")
                  end 
                end 
                if deaths > 0 and invis > 0 then
                  self:setEffect(self.EFF_INVISIBILITY, 
                    math.floor(deaths * invis), 
                    {src=src, penalty = 0.4, 
                    power=(deaths * self:getCun() / 2), no_ct_effect=true}) 
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

Damage: %d light and %d arcane.
Stunned: %d turn(s) (power %d, from Diversion). 
Confusion: %d turn(s) (power 50%%, from Cry of Frustration).
Pre-Detonation Pull: foes in radius %d (from Into the Void). 

Invisibility: %d turn(s) per detonated illusion (power %d, reduces outgoing damage by 40%%, from Distortion). 

Effects increase with Cunning. The critical chance is based on your mental crit rate.

#LIGHT_BLUE#Commentary: This is an iconic Mesmer ability. When illusions are about to die -- or when you want to end a fight early -- they can be detonated to harm or cripple foes. The scaling is 150%% the damage dealt by the icy spell "Shatter". Mind Wrack is harder to aim, requires and destroys illusions, and does not inflict control effects without additional talent points spent elsewhere. It does have the potential to hit multiple targets, however, and foes surrounded by multiple illusions can be hit multiple times.]]): 
                format(
                  damDesc(self, DamageType.LIGHT, damage) ,
                  damDesc(self, DamageType.ARCANE, damage) ,
                  2*self:getTalentLevel(self.T_DIVERSION) ,
                  self:getCun() , 
                  2*self:getTalentLevel(self.T_CRY_OF_FRUSTRATION) ,
                  pull ,
                  2*self:getTalentLevel(self.T_DISTORTION) ,
                  self:getCun()) 
	end,
}

newTalent{
        name = "Diversion",
        type = {"spell/mesmer-shatter", 2},
        points = 5,
	require = mind_req2,
        mode = "passive",
        info = function(self, t)
                local level = (self:getTalentLevel(t))
                return([[Mind Wrack now stuns foes within range of your detonated illusions. Foes are stunned (power %d) for %d turn(s). The effect increases with your Cunning.
                
#LIGHT_BLUE#Commentary: These talents improve Mind Wrack in the same fashion that the Rampage or Shadow trees improve their base talents. Stunning may give the Mesmer a chance to escape now that all of its illusions are gone.]]):format(
                        self:getCun(),
                        2*level)
        end,
}


newTalent{
        name = "Cry of Frustration",
        type = {"spell/mesmer-shatter", 3},
        points = 5,
	require = mind_req3,
        mode = "passive",
        info = function(self, t)
                local level = (self:getTalentLevel(t))
                return([[Mind Wrack now confuses foes within range of your detonated illusions. Foes are confused (power 50%%) for %d turn(s).
                
#LIGHT_BLUE#Commentary: These talents improve Mind Wrack in the same fashion that the Rampage and Shadow trees improve their base talents. Confusion is rare, but if the Mesmer is lucky it can be more useful than stunning.]]):format(2*level)
        end,
}

newTalent{
        name = "Distortion",
        type = {"spell/mesmer-shatter", 4},
        points = 5,
	require = mind_req4,
        mode = "passive",
        info = function(self, t)
                local level = (self:getTalentLevel(t))
                return([[Mind Wrack now takes you out of phase with reality, rendering you Invisible for %d turn(s) cumulative per illusion shattered with power %d cumulative per illusion shattered. As you become invisible you fade out of phase with reality: all of your damage is reduced by 40%%. (Reminder: you may cancel beneficial temporary effects early if you so desire.) The effect increases with your Cunning.

#LIGHT_BLUE#Commentary: This provides another flavor of post-Wrack escape for the higher-level Mesmer.]]):format(2 * level, 
                        self:combatMindpower()/2
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
                local pull = 0 
                if self:getTalentLevel(t) > 0 then
                  pull = 2 + self:getTalentLevel(t)  
                end 
                return([[Just before each of your illusions detonates via Mind Wrack, it pulls all foes within radius %d toward itself. (The order in which illusions detonate is unspecified. Multiple illusions can pull the same foe.) 

#LIGHT_BLUE#Commentary: This is a flavorful way of increasing the effective range of Mind Wrack while providing an indirect escape for the Mesmer.]]):format(pull)
        end,
}

