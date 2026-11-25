
newDamageType{
	name = "winds of chaos", type = "WINDS_OF_CHAOS",
          text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
      if src:reactionToward(target) < 0 then -- foe
        local mult = 1.0 
        if src.is_phantasmal_warlock then 
          for eff_id, p in pairs(target.tmp) do
            local e = target.tempeffect_def[eff_id]
            if e.status == "detrimental" then
              mult = mult + 0.1
            end 
          end 
        end 
        local damdam = dam.dam * mult 
        local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, damdam)
        -- now do weapon "on hit" damage
        local hitted = src:attackTarget(target, nil, 0, true)
        --
        local option = rng.range(1,2) 
        if option == 1 then 
          target:setEffect(target.EFF_LIGHT_ILLUSION, 4, {src=src, 
            power= (damdam * 3) / 4}) 
        end 
        if option == 2 then
          target:setEffect(target.EFF_ARCANE_ILLUSION, 4, {src=src, 
            power= (damdam * 3) / 4}) 
        end 
--      if option == 1 then 
--        target:setEffect(target.EFF_BURNING, 7, {src=src, 
--          power= (damdam * 3) / 7}) 
--      end 
--      if option == 2 and target:canBe("cut") then 
--        target:setEffect(target.EFF_CUT, 7, {src=src, 
--          power= (damdam * 3) / 7}) 
--      end 
--      if option == 3 and target:canBe("poison") then
--        target:setEffect(target.EFF_POISONED, 7, {src=src, 
--          power= (damdam * 3) / 7, 
--          apply_power=src:getMag() or 0}) 
--      end 
        if src and 
           src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) and
           src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) >= 2 then 
           target:knockback(src.x, src.y, 1) 
        end 
      else -- friend 
        -- local option = rng.range(1,2) 
        --if option == 1 then 
          target:setEffect(target.EFF_MESMERIC_OVERLOAD, 5, {src=src, 
            power= 10, 
            max=(10 * src:getTalentLevelRaw(src.T_WINDS_OF_CHAOS)), 
            no_ct_effect=true}) 
        --end 
        --if option == 2 then 
        --  target:setEffect(target.EFF_SPELLSURGE, 5, {src=src, 
        --    power= 10, max=50, no_ct_effect=true}) 
        --end 
      end 

        if dam.nb > 0 then
          dam.done = dam.done or {}
          dam.done[target.uid] = true
          dam.nb = dam.nb - 1

          local list = {}
          src:project({type="ball", selffire=true, x=x, y=y, radius=6, range=0}, x, y, function(bx, by)
            local actor = game.level.map(bx, by, Map.ACTOR)
            if actor and not dam.done[actor.uid] then -- and src:reactionToward(actor) < 0 then
              -- print("[BounceSlime] found possible actor", actor.name, bx, by, "distance", core.fov.distance(x, y, bx, by))
              list[#list+1] = actor
            end
          end)
          if #list > 0 then
            local st = rng.table(list)
            game.level.map:particleEmitter(x, y, math.max(math.abs(st.x-x), math.abs(st.y-y)), "matter_beam", {tx=st.x-x, ty=st.y-y})
            src:projectile({type="bolt",
                                          range=6, x=x, y=y, selffire=true,
                                          display={particle="bolt_arcane"}},
                                          st.x, st.y, 
                                          DamageType.WINDS_OF_CHAOS, dam, {type="arcanetrail"})
          end
      end 
			return realdam
		end		
	end,
}

newDamageType{
	name = "chaos storm", type = "CHAOS_STORM",
          text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
      if src:reactionToward(target) < 0 then -- foe
        local mult = 1.0 
        local damdam = dam * mult 
        local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, damdam)
        -- now do weapon "on hit" damage
        local hitted = src:attackTarget(target, nil, 0, true)
        --
        local option = rng.range(1,4) 
        local power = src:getMag() or 0 
        -- daze         |-> stunn
        -- chill        |-> frozen
        -- poison
        -- weakness     |-> 
        if option == 1 then 
          target:setEffect(target.EFF_STUNNED, 3, {src=src, 
            apply_power=power }) 
        end 
        if option == 2 then 
          target:setEffect(target.EFF_FROZEN, 3, {src=src, 
            apply_power=power, hp=power}) 
        end 
        if option == 3 then
          target:setEffect(target.EFF_POISONED, 3, {src=src, 
            power= (damdam * 3) / 3, 
            apply_power=power or 0}) 
        end 
        if option == 4 then 
          target:setEffect(target.EFF_WEAKENED, 3, {src=src, 
            power=33}) 
        end 
        return realdam 
      else -- friend 
        --local option = rng.range(1,2) 
        --if option == 1 then 
          target:setEffect(target.EFF_MESMERIC_OVERLOAD, 3, {src=src, 
            max=(10 * src:getTalentLevelRaw(src.T_CHAOS_STORM)), 
            max=50, no_ct_effect=true}) 
        --end 
        --if option == 2 then 
        --  target:setEffect(target.EFF_SPELLSURGE, 3, {src=src, 
        --    power= 10, max=50, no_ct_effect=true}) 
        --end 
        return 0 
      end 
    end 
	end,
}

newDamageType{
        name = "spatial surge", type = "SPATIAL_SURGE", 
          text_color = "#ROYAL_BLUE#",
        projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and src:reactionToward(target) < 0 then -- foe
                  local dist = core.fov.distance(src.x, src.y, x, y) 
                  local mult = 1.0
                  if dist < 8 then 
                          mult = (dist + 2) / 10 
                  end
                  local damdam = dam.dam * mult 
                  local dam = src:physicalCrit(damdam, 
                    nil, target, src:combatAttack(), target:combatDefense())
                  local realdam = 
                    DamageType.defaultProjector(src, x, y, DamageType.PHYSICAL, dam)
                  -- now do "weapon on hit' 
                  local hitted = src:attackTarget(target, nil, 0, true)
                  if src and 
                     src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) and
                     src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) >= 2 then 
                     target:knockback(src.x, src.y, 1) 
                  end 
                  return realdam
                end 
                return 0
        end,
}

newDamageType{
	name = "mirror blade", type = "MIRROR_BLADE",
          text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
      if src:reactionToward(target) < 0 then -- foe
        local mult = 1.0 
        local damdam = dam.dam * mult 
        local damdam = src:physicalCrit(damdam, 
              nil, target, src:combatAttack(), target:combatDefense())
        local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, damdam)
        -- now do weapon "on hit" damage
        local hitted = src:attackTarget(target, nil, 0, true)
        --
        target:setEffect(target.EFF_WEAKENED, 3, {src=src, 
          power=33}) 
      else -- friend 
        target:setEffect(target.EFF_MESMERIC_OVERLOAD, 10, {src=src, 
          max=(10 * src:getTalentLevelRaw(src.T_MIRROR_BLADE)), 
          max=50, no_ct_effect=true}) 
      end 

        if dam.nb > 0 then
          dam.done = dam.done or {}
          dam.done[target.uid] = true
          dam.nb = dam.nb - 1

          local list = {}
          src:project({type="ball", selffire=true, x=x, y=y, radius=6, range=0}, x, y, function(bx, by)
            local actor = game.level.map(bx, by, Map.ACTOR)
            if actor and not dam.done[actor.uid] then -- and src:reactionToward(actor) < 0 then
              -- print("[BounceSlime] found possible actor", actor.name, bx, by, "distance", core.fov.distance(x, y, bx, by))
              list[#list+1] = actor
            end
          end)
          if #list > 0 then
            local st = rng.table(list)
            game.level.map:particleEmitter(x, y, math.max(math.abs(st.x-x), math.abs(st.y-y)), "lightning_beam", {tx=st.x-x, ty=st.y-y, color=colors.VIOLET})
            src:projectile({type="bolt",
                                          range=12, x=x, y=y, selffire=true,
                                          display={particle="bolt_arcane"}},
                                          st.x, st.y, 
                                          DamageType.WINDS_OF_CHAOS, dam, {type="arcanetrail"})
          end
      end 
			return realdam
		end		
	end,
}

newDamageType{
	name = "null field", type = "NULL_FIELD",
          text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
      if src:reactionToward(target) < 0 then -- foe
                local count = 99 

                local effs = {}
                -- Go through all spell effects
                for eff_id, p in pairs(target.tmp) do
                        local e = target.tempeffect_def[eff_id]
                        if e.status == "beneficial" then
                                effs[#effs+1] = {"effect", eff_id}
                        end
                end
                for i = 1, count do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                target:removeEffect(eff[2])
                        end
                end

      else -- friend 

                local count = 99 
                local effs = {}
                -- Go through all spell effects
                for eff_id, p in pairs(target.tmp) do
                        local e = target.tempeffect_def[eff_id]
                        if e.status == "detrimental" then
                                effs[#effs+1] = {"effect", eff_id}
                        end
                end
                for i = 1, count do 
                        if #effs == 0 then break end
                        local eff = rng.tableRemove(effs)

                        if eff[1] == "effect" then
                                target:removeEffect(eff[2])
                        end
                end

        return 0 
      end 
    end 
	end,
}

newDamageType{
	name = "temporal curtain", type = "TEMPORAL_CURTAIN",
          text_color = "#ROYAL_BLUE#",
    projector = function(src, x, y, type, dam, tmp)
      local target = game.level.map(x, y, Map.ACTOR)
      if target then
        if src:reactionToward(target) >= 0 and
           target.is_mesmeric_illusion then -- friendly illusion
                        local tids = {}
                        for tid, _ in pairs(target.talents_cd) do
                                local tt = target:getTalentFromId(tid)
                                tids[#tids+1] = tid
                        end
                        for i = 1, 1 do
                                if #tids == 0 then break end
                                local tid = rng.tableRemove(tids)
                                target.talents_cd[tid] = target.talents_cd[tid] - 1
                        end
        end
        if src:reactionToward(target) < 0 then -- foe

                target:setEffect(target.EFF_CRIPPLE, 3, 
                  {src=src, speed= 0.3, no_ct_effect=true}) 

                local tids = {}
                for tid, lev in pairs(target.talents) do
                        local t = target:getTalentFromId(tid)
                        if t and not target.talents_cd[tid] and t.mode == "activated" and not t.innate then tids[#tids+1] = t end
                end

                local count = 0
                local cdr = dam

                for i = 1, dam do 
                        local t = rng.tableRemove(tids)
                        if not t then break end
                        target.talents_cd[t.id] = cdr
                        game.logSeen(target, "%s's %s is disrupted by the Temporal Curtain!", target.name:capitalize(), t.name)
                        count = count + 1
                end

                if count >= 1 then

game.level.map:particleEmitter(x, y, 1, "generic_charge", {rm=10, rM=110, gm=10, gM=50, bm=20, bM=125, am=25, aM=255})
game.level.map:particleEmitter(src.x, src.y, 1, "generic_charge", {rm=200, rM=255, gm=200, gM=255, bm=200, bM=255, am=125, aM=125})

                        local tids = {}
                        for tid, _ in pairs(src.talents_cd) do
                                local tt = src:getTalentFromId(tid)
                                tids[#tids+1] = tid
                        end
                        for i = 1, count do
                                if #tids == 0 then break end
                                local tid = rng.tableRemove(tids)
                                src.talents_cd[tid] = src.talents_cd[tid] - dam
                        end
                end

        end
      end 
    end,
}
