require "engine.class"

newTalentType{ allow_random=true, is_spell=true, type="spell/mesmer-staff", name = "mesmer staff", description = "Mesmer attacks channeled through staves or greatmauls." }
newTalentType{ allow_random=true, is_spell=true, type="spell/mesmer-mantra", name = "mantras", description = "Mesmer mantras, stored slowly and released quickly." }
newTalentType{ allow_random=true, type="spell/mesmer-greatsword", name = "mesmer greatblade", description = "Mesmer attacks channeled through greatblades (a greatsword or a trident equipped)." }
newTalentType{ allow_random=true, type="spell/mesmer-longsword", name = "mesmer shortblade", description = "Mesmer attacks channeled through shortblades (a dagger or longsword in the mainhand)." }
newTalentType{ allow_random=true, type="spell/mesmer-signet", name = "signets", description = "Mesmer beneficial sustained talents that have additional effects when deactivated." }
newTalentType{ generic=true, allow_random=true, is_mind=true, type="spell/mesmer-shatter", name = "shatter illusions", description = "Mesmer attacks that detonate your summoned illusions to harm foes." }
newTalentType{ generic=true, allow_random=true, is_mind=true, type="spell/mesmer-utility", name = "mesmer utility", description = "Mesmer utility powers." }
newTalentType{ generic=true, allow_random=true, is_mind=true, type="spell/mesmer-trait", name = "mesmer traits", description = "Mesmer traits." }
newTalentType{ allow_random=true, is_mind=true, type="spell/mesmer-elite", name = "mesmer elites", description = "Mesmer elite talents." }
newTalentType{ is_mind=true, type="spell/mesmer-other", name = "mesmer other", description = "Internal abilities related to the Mesmer class." }

spells_req1 = { stat = { mag=function(level) return 12 + (level-1) * 2 end }, level = function(level) return 0 + (level-1) end }
spells_req2 = { stat = { mag=function(level) return 18 + (level-1) * 2 end }, level = function(level) return 3 + (level-1) end }
spells_req3 = { stat = { mag=function(level) return 24 + (level-1) * 2 end }, level = function(level) return 6 + (level-1) end }
spells_req4 = { stat = { mag=function(level) return 30 + (level-1) * 2 end }, level = function(level) return 9 + (level-1) end }
spells_req5 = { stat = { mag=function(level) return 36 + (level-1) * 2 end }, level = function(level) return 12 + (level-1) end }

swords_req1 = { stat = { str=function(level) return 12 + (level-1) * 2 end }, level = function(level) return 0 + (level-1) end }
swords_req2 = { stat = { str=function(level) return 18 + (level-1) * 2 end }, level = function(level) return 3 + (level-1) end }
swords_req3 = { stat = { str=function(level) return 24 + (level-1) * 2 end }, level = function(level) return 6 + (level-1) end }
swords_req4 = { stat = { str=function(level) return 30 + (level-1) * 2 end }, level = function(level) return 9 + (level-1) end }
swords_req5 = { stat = { str=function(level) return 36 + (level-1) * 2 end }, level = function(level) return 12 + (level-1) end }

mind_req1 = { stat = { cun=function(level) return 12 + (level-1) * 2 end }, level = function(level) return 0 + (level-1) end }
mind_req2 = { stat = { cun=function(level) return 18 + (level-1) * 2 end }, level = function(level) return 3 + (level-1) end }
mind_req3 = { stat = { cun=function(level) return 24 + (level-1) * 2 end }, level = function(level) return 6 + (level-1) end }
mind_req4 = { stat = { cun=function(level) return 30 + (level-1) * 2 end }, level = function(level) return 9 + (level-1) end }
mind_req5 = { stat = { cun=function(level) return 36 + (level-1) * 2 end }, level = function(level) return 12 + (level-1) end }

mind_req_high1 = { stat = { cun=function(level) return 22 + (level-1) * 2 end }, level = function(level) return 10 + (level-1) end }
mind_req_high2 = { stat = { cun=function(level) return 30 + (level-1) * 2 end }, level = function(level) return 14 + (level-1) end }
mind_req_high3 = { stat = { cun=function(level) return 38 + (level-1) * 2 end }, level = function(level) return 18 + (level-1) end }
mind_req_high4 = { stat = { cun=function(level) return 46 + (level-1) * 2 end }, level = function(level) return 22 + (level-1) end }
mind_req_high5 = { stat = { cun=function(level) return 54 + (level-1) * 2 end }, level = function(level) return 26 + (level-1) end }

long_req1 = { stat = { str=function(level) return 12 + (level-1) * 2 end, mag=function(level) return 12 + (level-1) * 2 end }, level = function(level) return 0 + (level-1) end }
long_req2 = { stat = { str=function(level) return 16 + (level-1) * 2 end, mag=function(level) return 16 + (level-1) * 2 end }, level = function(level) return 3 + (level-1) end }
long_req3 = { stat = { str=function(level) return 20 + (level-1) * 2 end, mag=function(level) return 20 + (level-1) * 2 end }, level = function(level) return 6 + (level-1) end }
long_req4 = { stat = { str=function(level) return 24 + (level-1) * 2 end, mag=function(level) return 24 + (level-1) * 2 end }, level = function(level) return 9 + (level-1) end }
long_req5 = { stat = { str=function(level) return 28 + (level-1) * 2 end, mag=function(level) return 28 + (level-1) * 2 end }, level = function(level) return 12 + (level-1) end }

function mesmerTalentStatDamage(self, t, stat, base, max, scale)
	if type(t) ~= "table" then t = self:getTalentFromId(t) end
	return self:combatTalentStatDamage(t, stat, base, max, scale)
end

load("/data-Mesmer/talents/spells/mesmer-staff.lua")
load("/data-Mesmer/talents/spells/mesmer-greatsword.lua")
load("/data-Mesmer/talents/spells/mesmer-longsword.lua")
load("/data-Mesmer/talents/spells/mesmer-shatter.lua")
load("/data-Mesmer/talents/spells/mesmer-mantra.lua")
load("/data-Mesmer/talents/spells/mesmer-signet.lua")
load("/data-Mesmer/talents/spells/mesmer-utility.lua")
load("/data-Mesmer/talents/spells/mesmer-trait.lua")
load("/data-Mesmer/talents/spells/mesmer-elite.lua")
