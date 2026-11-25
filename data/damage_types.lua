newDamageType{
	name = "winds of chaos",
	type = "WINDS_OF_CHAOS",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end

		if src:reactionToward(target) < 0 then
			local mult = 1.0
			if src.is_phantasmal_warlock then
				for eff_id, p in pairs(target.tmp) do
					local e = target.tempeffect_def[eff_id]
					if e and e.status == "detrimental" then
						mult = mult + 0.1
					end
				end
			end
			local damdam = dam.dam * mult
			local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, damdam)
			src:attackTarget(target, nil, 0, true)

			local option = rng.range(1, 2)
			if option == 1 then
				target:setEffect(target.EFF_LIGHT_ILLUSION, 4, {src=src, power=(damdam * 3) / 4})
			else
				target:setEffect(target.EFF_ARCANE_ILLUSION, 4, {src=src, power=(damdam * 3) / 4})
			end

			if src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) >= 2 and target:canBe("knockback") then
				target:knockback(src.x, src.y, 1)
			end

			if dam.nb and dam.nb > 0 then
				dam.done = dam.done or {}
				dam.done[target.uid] = true
				dam.nb = dam.nb - 1
				local list = {}
				src:project({type="ball", selffire=true, x=x, y=y, radius=6, range=0}, x, y, function(bx, by)
					local actor = game.level.map(bx, by, Map.ACTOR)
					if actor and not dam.done[actor.uid] then
						list[#list+1] = actor
					end
				end)
				if #list > 0 then
					local st = rng.table(list)
					game.level.map:particleEmitter(x, y, math.max(math.abs(st.x-x), math.abs(st.y-y)), "matter_beam", {tx=st.x-x, ty=st.y-y})
					src:projectile({type="bolt", range=6, x=x, y=y, selffire=true, display={particle="bolt_arcane"}}, st.x, st.y, DamageType.WINDS_OF_CHAOS, dam, {type="arcanetrail"})
				end
			end
			return realdam
		else
			local max_overload = 10 * math.max(1, src:getTalentLevelRaw(src.T_WINDS_OF_CHAOS))
			target:setEffect(target.EFF_MESMERIC_OVERLOAD, 5, {src=src, power=10, max=max_overload, no_ct_effect=true})
			return 0
		end
	end,
}

newDamageType{
	name = "chaos storm",
	type = "CHAOS_STORM",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end

		local base_dam = type(dam) == "table" and dam.dam or dam
		if src:reactionToward(target) < 0 then
			local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, base_dam)
			src:attackTarget(target, nil, 0, true)

			local option = rng.range(1, 4)
			local power = src:getMag() or 0
			if option == 1 then
				target:setEffect(target.EFF_STUNNED, 3, {src=src, apply_power=power})
			elseif option == 2 then
				target:setEffect(target.EFF_FROZEN, 3, {src=src, apply_power=power, hp=power})
			elseif option == 3 then
				target:setEffect(target.EFF_POISONED, 3, {src=src, power=base_dam, apply_power=power})
			elseif option == 4 then
				target:setEffect(target.EFF_WEAKENED, 3, {src=src, power=33, apply_power=power})
			end
			return realdam
		else
			local max_overload = 10 * math.max(1, src:getTalentLevelRaw(src.T_CHAOS_STORM))
			target:setEffect(target.EFF_MESMERIC_OVERLOAD, 3, {src=src, power=10, max=max_overload, no_ct_effect=true})
			return 0
		end
	end,
}

newDamageType{
	name = "spatial surge",
	type = "SPATIAL_SURGE",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and src:reactionToward(target) < 0 then
			local dist = core.fov.distance(src.x, src.y, x, y)
			local mult = 1.0
			if dist < 8 then
				mult = (dist + 2) / 10
			end
			local damdam = dam.dam * mult
			local crit_dam = src:physicalCrit(damdam, nil, target, src:combatAttack(), target:combatDefense())
			local realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, crit_dam)
			src:attackTarget(target, nil, 0, true)

			if src:getTalentLevel(src.T_CRIPPLING_ILLUSIONS) >= 2 and target:canBe("knockback") then
				target:knockback(src.x, src.y, 1)
			end
			return realdam
		end
		return 0
	end,
}

newDamageType{
	name = "mirror blade",
	type = "MIRROR_BLADE",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end

		local realdam = 0
		if src:reactionToward(target) < 0 then
			local damdam = src:physicalCrit(dam.dam, nil, target, src:combatAttack(), target:combatDefense())
			realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, damdam)
			src:attackTarget(target, nil, 0, true)
			target:setEffect(target.EFF_WEAKENED, 3, {src=src, power=33, apply_power=src:getStr() or 0})
		else
			local max_overload = 10 * math.max(1, src:getTalentLevelRaw(src.T_MIRROR_BLADE))
			target:setEffect(target.EFF_MESMERIC_OVERLOAD, 10, {src=src, power=10, max=max_overload, no_ct_effect=true})
		end

		if dam.nb and dam.nb > 0 then
			dam.done = dam.done or {}
			dam.done[target.uid] = true
			dam.nb = dam.nb - 1
			local list = {}
			src:project({type="ball", selffire=true, x=x, y=y, radius=6, range=0}, x, y, function(bx, by)
				local actor = game.level.map(bx, by, Map.ACTOR)
				if actor and not dam.done[actor.uid] then
					list[#list+1] = actor
				end
			end)
			if #list > 0 then
				local st = rng.table(list)
				game.level.map:particleEmitter(x, y, math.max(math.abs(st.x-x), math.abs(st.y-y)), "lightning_beam", {tx=st.x-x, ty=st.y-y, color=colors.VIOLET})
				src:projectile({type="bolt", range=12, x=x, y=y, selffire=true, display={particle="bolt_arcane"}}, st.x, st.y, DamageType.MIRROR_BLADE, dam, {type="arcanetrail"})
			end
		end
		return realdam
	end,
}

newDamageType{
	name = "null field",
	type = "NULL_FIELD",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end

		local status_to_remove = src:reactionToward(target) < 0 and "beneficial" or "detrimental"
		local effs = {}
		for eff_id, p in pairs(target.tmp) do
			local e = target.tempeffect_def[eff_id]
			if e and e.status == status_to_remove then
				effs[#effs+1] = eff_id
			end
		end
		for _, eff_id in ipairs(effs) do
			target:removeEffect(eff_id)
		end
		return 0
	end,
}

newDamageType{
	name = "temporal curtain",
	type = "TEMPORAL_CURTAIN",
	text_color = "#ROYAL_BLUE#",
	projector = function(src, x, y, type, dam, tmp)
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return 0 end

		local cdr_amt = type(dam) == "table" and dam.dam or dam
		if src:reactionToward(target) >= 0 and target.is_mesmer_illusion then
			local tids = {}
			for tid, cd in pairs(target.talents_cd) do
				if cd and cd > 0 then
					tids[#tids+1] = tid
				end
			end
			if #tids > 0 then
				local tid = rng.table(tids)
				target.talents_cd[tid] = math.max(0, (target.talents_cd[tid] or 0) - 1)
			end
		elseif src:reactionToward(target) < 0 then
			target:setEffect(target.EFF_CRIPPLE, 3, {src=src, speed=0.3, apply_power=src:getStr() or 0, no_ct_effect=true})

			local tids = {}
			for tid, lev in pairs(target.talents) do
				local t = target:getTalentFromId(tid)
				if t and not target.talents_cd[tid] and t.mode == "activated" and not t.innate then
					tids[#tids+1] = t
				end
			end

			local count = 0
			for i = 1, cdr_amt do
				local t = rng.tableRemove(tids)
				if not t then break end
				target.talents_cd[t.id] = cdr_amt
				game.logSeen(target, "%s's %s is disrupted by the Temporal Curtain!", target.name:capitalize(), t.name)
				count = count + 1
			end

			if count >= 1 then
				game.level.map:particleEmitter(x, y, 1, "generic_charge", {rm=10, rM=110, gm=10, gM=50, bm=20, bM=125, am=25, aM=255})
				game.level.map:particleEmitter(src.x, src.y, 1, "generic_charge", {rm=200, rM=255, gm=200, gM=255, bm=200, bM=255, am=125, aM=125})
				local src_tids = {}
				for tid, cd in pairs(src.talents_cd) do
					if cd and cd > 0 then
						src_tids[#src_tids+1] = tid
					end
				end
				for i = 1, count do
					if #src_tids == 0 then break end
					local tid = rng.tableRemove(src_tids)
					src.talents_cd[tid] = math.max(0, (src.talents_cd[tid] or 0) - cdr_amt)
				end
			end
		end
		return 0
	end,
}
