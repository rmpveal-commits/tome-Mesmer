local damDesc = Talents.main_env.damDesc

function removeCondition(self) 
  if not self then return end
  local count = self:getTalentLevel(self.T_CLEANSING_SIGNETS) 
  if count and count >= 2 then 
                local effs = {}
                -- Go through all spell effects
                for eff_id, p in pairs(self.tmp) do
                        local e = self.tempeffect_def[eff_id]
                        if e.status == "detrimental" then
                                effs[#effs+1] = {"effect", eff_id}
                        end
                end
                for i = 1, 1 do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                self:removeEffect(eff[2])
                        end
                end
  end 
end 

newTalent{
        name = "Signet of Illusions",
        type = {"spell/mesmer-signet", 1},
        mode = "sustained", no_sustain_autoreset = true, 
        require = swords_req1,
        points = 5,
        no_energy = true, 
        tactical = { DEFEND = 2 },
        cooldown = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
        end, 
        activate = function(self, t)
                game:playSoundNear(self, "talents/slime")
                local ret = {
                        per = self:addTemporaryValue("mesmer_illusion_health", 
                        self:combatTalentLimit(t, 30, 5, 15)),
                }
                return ret
        end,
        deactivate = function(self, t, p)
                removeCondition(self) 
                self:removeTemporaryValue("mesmer_illusion_health", p.per)
                self.talents_cd[self.T_DECOY] = nil
                self.talents_cd[self.T_MIND_WRACK] = nil
                return true
        end,
        info = function(self, t)
                return ([[While sustained, this signet increases the percentage of your health that each of your newly-created illusions receives by %d. 

When you deactivate this signet (which takes no time) it resets the cooldowns on Mind Wrack and Decoy.

The effects will increase with your Strength.

#LIGHT_BLUE#Commentary: Superficially similar to the "Resilience" talent for Summoners, but with a different passive benefit calculation. Since Mesmers cannot really wear any armor and have low health, they primarily survive by avoiding damage and by having their illusions take damage for them. As a result, this talent, which buffs illusion health by 5-25%%, may actually be closer to "Shielding", which buffs damage shields by 25-60%%.]]):
                format(self:combatTalentLimit(t, 30, 5, 15))
        end,
}

newTalent{
        name = "Signet of Domination",
        type = {"spell/mesmer-signet", 1},
        mode = "sustained", no_sustain_autoreset = true, 
        require = swords_req2,
        points = 5,
        tactical = { DEFEND = 2 },
        cooldown = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
        end, 
        radius = function(self, t) return 
          1 + math.floor(self:getTalentLevel(t))
        end,
        direct_hit = true,
        no_energy = true, 
        getDamageIncrease = function(self, t) return 
          mesmerTalentStatDamage(self, t, "str", 5, 25) 
        end,
        activate = function(self, t)
                game:playSoundNear(self, "talents/slime")
                local di = t.getDamageIncrease(self,t) 
                local ret = {
                        dam = self:addTemporaryValue("inc_damage", 
                          {[DamageType.ARCANE] = di,
                           [DamageType.LIGHT] = di,
                           [DamageType.PHYSICAL] = di,
                           })
                }
                return ret
        end,
        deactivate = function(self, t, p)
                removeCondition(self) 
                self:removeTemporaryValue("inc_damage", p.dam)
                local tg = {type="ball", range=self:getTalentRange(t),
                 selffire=false, friendlyfire=false,
                 radius=self:getTalentRadius(t)}
               self:project(tg, self.x, self.y, function(px, py, tg, self)
                       local target = game.level.map(px, py, Map.ACTOR)
                       if target and target ~= self then
                         target:setEffect(target.EFF_STUNNED, 3, 
                         {src=self, power=self:getStr()}) 
                       end
               end)
                return true
        end,
        info = function(self, t)
                local di = t.getDamageIncrease(self,t) 
                local rad = t.radius(self, t)
                return ([[While sustained, this signet increases the arcane, light and physical damage you deal by %0.2f%%. 

When you deactivate this signet (which takes no time) it stuns all foes (power %d) within radius %d for 3 turns. 

The effects will increase with your Strength.

#LIGHT_BLUE#Commentary: Mesmers primarily deal arcane, light and physical damage. The scaling (3%% per talent level) falls between "Hymn of Shadows" (5-25%% over five levels) and "Wildfire" (2%% per talent level).]]):
                format(di,
                  self:getStr(),
                  rad 
                ) 
        end,
}

newTalent{
        name = "Signet of Midnight",
        type = {"spell/mesmer-signet", 1},
        mode = "sustained", no_sustain_autoreset = true, 
        require = swords_req3,
        points = 5,
        tactical = { DEFEND = 2 },
        cooldown = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
        end, 
        radius = function(self, t) return 
          1 + math.floor(self:getTalentLevel(t))
        end,
        direct_hit = true,
        no_energy = true, 
        range = 0, 
        getBoonIncrease = function(self, t) return 
          1 + math.floor(self:combatTalentLimit(t, 4, 1, 3)) end, 
        callbackOnActBase = function(self, t) 
                local p = self.sustain_talents[t.id]
                if not p then return end 
                local target = self 
                local dur = t.getBoonIncrease(self, t) 
                for eff_id, p in pairs(target.tmp) do
                        local e = target.tempeffect_def[eff_id]
                        if e.type ~= "other" then
                                if (not e.signet_of_midnight) and e.status == "beneficial" then
                                        p.dur = p.dur + dur
                                        e.signet_of_midnight = true 
                                end 
                        end
                end
        end, 
        activate = function(self, t)
                game:playSoundNear(self, "talents/slime")
                local ret = { }
                return ret
        end,
        deactivate = function(self, t, p)
                removeCondition(self) 
                local tg = {type="ball", range=self:getTalentRange(t),
                  selffire=false, friendlyfire=false,
                  radius=self:getTalentRadius(t)}
                self:project(tg, self.x, self.y, function(px, py, tg, self)
                        local target = game.level.map(px, py, Map.ACTOR)
                        if target and target ~= self then
                          target:setEffect(target.EFF_BLINDED, 3, 
                          {src=self, power=self:getStr(),
                          no_ct_effect=true}) 
                        end
                end)
                return true
        end,
        info = function(self, t)
                local di = t.getBoonIncrease(self,t) 
                local rad = t.radius(self, t)
                return ([[While sustained, all temporary beneficial effects applied to you have their durations increased by %d turn(s). Each temporary effect instance can be extended only once. The duration increase is applied whenever you take an action, so ephemeral beneficial effects that last at most one turn (such as Mesmeric Dodge) may not be extended.

When you deactivate this signet (which takes no time) it blinds all foes (power %d) within radius %d for 3 turns. 

The effects will increase with your Strength.

#LIGHT_BLUE#Commentary: This "boon duration and synergy" effect has no general equivalent in ToME. There are talents that increase the durations of particular effects (e.g., only damage shields or only regenerations). This Signet increases all beneficial effects that last more than one turn. This has a pleasant synergy with default Mesmer staff powers, but the clever player will find other fruitful combinations (e.g., buffs from inscriptions or charms, etc.).]]):
                format(di,
                  self:getStr(),
                  rad 
                ) 
        end,
}


newTalent{
        name = "Signet of Inspiration",
        type = {"spell/mesmer-signet", 1},
        mode = "sustained", no_sustain_autoreset = true, 
        require = swords_req4,
        points = 5,
        tactical = { DEFEND = 2 },
        cooldown = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
        end, 
        getSpeed = function(self, t) return 
          mesmerTalentStatDamage(self,t, "str", 0.15, 0.5, 0.75)  
        end,
        getSpeedBurst = function(self, t) return 
          mesmerTalentStatDamage(self,t, "str", 470, 750, 0.75) / 2 
        end,
        getDuration = function(self, t) return
          1 + math.floor(self:getTalentLevel(t))
        end,
        direct_hit = true,
        no_energy = true, 
        range = 0, 
        activate = function(self, t)
                game:playSoundNear(self, "talents/slime")
                local ret = {
                        speed = self:addTemporaryValue("movement_speed", 
                          t.getSpeed(self,t)),
                }
                return ret
        end,
        deactivate = function(self, t, p)
                removeCondition(self) 
                self:removeTemporaryValue("movement_speed", p.speed)
                game:onTickEnd(function () 
                  self:setEffect(self.EFF_WILD_SPEED, 
                  (t.getDuration(self, t)), 
                  {power=t.getSpeedBurst(self, t)})
                end) 
                return true
        end,
        info = function(self, t)
                local s = t.getSpeed(self,t) 
                local sb = t.getSpeedBurst(self,t) 
                local dur = t.getDuration(self,t)
                return ([[While sustained, your movement speed is increased by %d%%.

When you deactivate this signet (which takes no time) it creates a burst of celerity, increasing your movement speed by %d%% for %d turn(s). Any actions other than movement will cancel the effect. Note: since you will be moving very fast, game turns will pass very slowly. 

The effects will increase with your Strength.

#LIGHT_BLUE#Commentary: The passive speed benefit follows "Celerity" (but does not include free item set switching). The burst speed benefit is half as strong as "Lightning Speed". Mobility is critical for Mesmers, and this is the only Mesmer power that increases raw movement speed.]]):
                format( s * 100, 
                        sb, dur) 
        end,
}

newTalent{
        name = "Signet of Ether",
        type = {"spell/mesmer-signet", 1},
        mode = "sustained", no_sustain_autoreset = true, 
        require = swords_req5,
        points = 5,
        tactical = { DEFEND = 2 },
        cooldown = function(self, t)
          return math.ceil(self:combatTalentLimit(t, 10, 30, 15))
        end, 
        getRegen = function(self, t) return 
          (self:getTalentLevel(t) * 3.0) 
        end,
        getHeal = function(self, t) return mesmerTalentStatDamage(self,t, "str", 40, 440) end,
        direct_hit = true,
        no_energy = true, 
        range = 0, 
        callbackOnActBase = function(self, t) 
                self.signet_of_ether_regen = 
                  (self.signet_of_ether_regen or 1) - 1 
                if self.signet_of_ether_regen <= 0 then
                  self.signet_of_ether_regen = 3
                  local amount = t.getRegen(self, t)
                  local count = 0 
                  for _, e in pairs(game.level.entities) do
                    if e.summoner and e.summoner == self and e.is_mesmer_illusion then
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
                local ret = { }
                return ret
        end,
        deactivate = function(self, t, p)
                removeCondition(self) 
                self:attr("allow_on_heal", 1)
                self:heal( t.getHeal(self, t), self) 
                self:attr("allow_on_heal", -1)
                self.talents_cd[self.T_MIRROR_BLADE] = nil
                self.talents_cd[self.T_PHANTASMAL_BERSERKER] = nil
                self.talents_cd[self.T_PHASE_RETREAT] = nil
                self.talents_cd[self.T_PHANTASMAL_WARLOCK] = nil
                return true
        end,
        info = function(self, t)
                local r = t.getRegen(self,t) 
                local h = t.getHeal(self,t) 
                return ([[Every three turns while this signet is sustained you heal %0.2f per illusion you control. 

When you deactivate (which takes no time) this signet it creates an ethereal burst, healing you for %02.f. In addition, the burst resets the cooldowns on the Mirror Blade, Phantasmal Berserker, Phase Retreat, and Phantasmal Warlock talents. 

The effects will increase with your Strength.

#LIGHT_BLUE#Commentary: This ability helps Mesmers when they need it most: in the middle of a tough battle that requires multiple illusions. When the illusions are gone, the deactivation power resets some of the cooldowns needed to summon more. The passive healing rate scaling (3.0 per illusion per talent level every 3 turns) loosely follows "Fast Metabolism" (about 3.0 per talent level every turn), assuming you can keep three illusions alive.]]):
                format( r, 
                        h )
        end,

}


