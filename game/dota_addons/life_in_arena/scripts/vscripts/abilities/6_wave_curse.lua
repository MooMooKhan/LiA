function Curse(event)
	local target = event.target
	local ability = event.ability
	local caster = event.caster
	if target:TriggerSpellAbsorb(ability) then
		return 
	end
	ability:ApplyDataDrivenModifier(caster, target, "modifier_6_wave_curse", nil)
end