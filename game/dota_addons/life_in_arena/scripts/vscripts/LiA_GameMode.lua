--
CORPSE_MODEL = "models/development/invisiblebox.vmdl" --"models/items/pudge/pudge_skeleton_hook.vmdl"
--"particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_eztzhok_ambient_blade_rope_lv.vpcf"
--"models/props_nature/grass_clump_00f.vmdl"
--"models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl"
CORPSE_DURATION = 88


_G.LIA_MODE_SURVIVAL = 1
_G.LIA_MODE_BATTLE_OF_CLANS = 2

_G.HERO_STATS_ATTACK_BONUS = 1.5

--Strenght
_G.HERO_STATS_HEALTH_BONUS = 8
_G.HERO_STATS_HEALTH_REGEN_BONUS = 0.05

--Agility
_G.HERO_STATS_ARMOR_BONUS = 1/6
_G.HERO_STATS_ATTACK_SPEED_BONUS = 1
_G.HERO_STATS_MOVE_SPEED_BONUS = 1

--Intellect
_G.HERO_STATS_MANA_BONUS = 12
_G.HERO_STATS_MANA_REGEN_BONUS = 0.05

------------------------------------------------------------------------------

require('survival/survival')
require('runes')

------------------------------------------------------------------------------

--LinkLuaModifier( "modifier_stats_bonus_fix", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_stun_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hide_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_orn_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_knight_shield_damage_return_lua", "items/modifier_knight_shield_damage_return_lua.lua", LUA_MODIFIER_MOTION_NONE) --модификатор для возвратки Рыцарского Щита
LinkLuaModifier( "modifier_knight_cuirass_damage_return_lua", "items/modifier_knight_cuirass_damage_return_lua.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier( "modifier_test_lia", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------------

if LiA == nil then
	_G.LiA = class({})
end

------------------------------------------------------------------------------

MAX_LEVEL = 50

XP_TABLE = {}
XP_TABLE[1] = 0
for i = 2, MAX_LEVEL do
    XP_TABLE[i] = XP_TABLE[i-1] + i * 100 
end

------------------------------------------------------------------------------

require('filtering')

function LiA:InitGameMode()
    LiA = self

    self.vUserIds = {}
    self.tPlayers = {}
    self.nPlayers = 0
    
    GameRules:SetSafeToLeave(true)
	GameRules:SetHeroSelectionTime(30)
	-- BUG valve: SetPreGameTime work as SetPostGameTime?
	GameRules:SetPreGameTime(0)
    GameRules:SetPostGameTime(60)
	--
	GameRules:SetGoldTickTime(2)
	GameRules:SetGoldPerTick(1)
	GameRules:SetHeroMinimapIconScale(0.8)
    GameRules:SetCreepMinimapIconScale(0.8)
	GameRules:SetRuneMinimapIconScale( 0.6 )
    GameRules:SetFirstBloodActive(false)

    GameRules:SetUseBaseGoldBountyOnHeroes(true)

    GameRules:SetCustomGameEndDelay(1)
    
	local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetMaximumAttackSpeed(500)
	
    GameMode:SetCustomHeroMaxLevel(MAX_LEVEL)    
    GameMode:SetCustomXPRequiredToReachNextLevel(XP_TABLE)
    GameMode:SetUseCustomHeroLevels(true)
    
    --GameMode:SetRecommendedItemsDisabled(true)
    --GameMode:SetHUDVisible(12, false)
    --GameMode:SetHUDVisible(1, false) 
    GameMode:SetTopBarTeamValuesVisible(false)
    
    GameMode:SetBuybackEnabled(false)
    GameMode:SetTowerBackdoorProtectionEnabled(false)
    GameMode:SetStashPurchasingDisabled(true)
    GameMode:SetLoseGoldOnDeath(false)

    GameRules:LockCustomGameSetupTeamAssignment(true)
    GameRules:SetCustomGameSetupRemainingTime(0)
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )

    GameRules:SetTimeOfDay(0.5)
    GameMode:SetDaynightCycleDisabled(true)

    PlayerResource:SetCustomPlayerColor(0, 255, 3, 3)
    PlayerResource:SetCustomPlayerColor(1, 0, 66, 255)
    PlayerResource:SetCustomPlayerColor(2, 28, 230, 185)
    PlayerResource:SetCustomPlayerColor(3, 84, 0, 129)
    PlayerResource:SetCustomPlayerColor(4, 255, 252, 1)
    PlayerResource:SetCustomPlayerColor(5, 254, 186, 14)
    PlayerResource:SetCustomPlayerColor(6, 32, 192, 0)
    PlayerResource:SetCustomPlayerColor(7, 229, 91, 176)

    --listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(LiA, 'OnGameStateChange'), self)
    ListenToGameEvent('player_disconnect', Dynamic_Wrap(LiA, 'OnDisconnect'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(LiA, 'OnConnectFull'), self)
    ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(LiA, 'OnPlayerLevelUp'), self)
    ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(LiA, 'OnPlayerLearnedAbility'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(LiA, 'OnNPCSpawned'), self)
	GameMode:SetDamageFilter( Dynamic_Wrap( LiA, "FilterDamage" ), self )
	
	--upgrades
	CustomGameEventManager:RegisterListener( "apply_ulu_command", Dynamic_Wrap(LiA, "RegisterClick"))
	--CustomGameEventManager:RegisterListener( "apply_ulu_command_getlumber", Dynamic_Wrap(LiA, "RegisterGetLumber"))
	--for hint
	CustomGameEventManager:RegisterListener( "apply_command_hint_hide", Dynamic_Wrap(LiA, "RegisterHintHide"))

    trigger_shop = Entities:FindByClassname(nil, "trigger_shop") --находим триггер отвечающий за работу магазина
    
	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	MergeTables(GameRules.UnitKV, LoadKeyValues("scripts/npc/npc_heroes_custom.txt")) --Load HeroKV into UnitKV

	GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")
end

function LiA:RegisterHintHide( args )
	local pID = args['idPlayer']
	local dat = 
	{
		hide = true,
	}
	--print("				dat",dat)
	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(pID), "CustomUI_Set_forHint_Scoreboard", dat )

end

function LiA:RegisterClick( args )
	local pID = args['idPlayer']
	local name = args['nameUlu']  
	local player = PlayerResource:GetPlayer(pID)
	local hero = player:GetAssignedHero()
	local doneU = false
	local need_lumber
	local ability
	local lvl
	--[[
		"Ability6" "ulu_hero_armor" 	
		"Ability7" "ulu_hero_attack" 					
		"Ability8" "ulu_hero_attack_speed" 		
		"Ability9" "ulu_hero_hp_points" 
		"Ability10" "ulu_hero_mana_points" 
		"Ability11" "ulu_hero_hp_regen" 		
		"Ability12" "ulu_hero_mana_regen" 
	]]
    if Survival.State == SURVIVAL_STATE_DUEL_TIME then
        return
    end
	--print(name)
	local maxLumber = 333 -- 45*5=225 + 54*2=108 = 333
	if name == "armor" then
		ability = hero:GetAbilityByIndex(5)
		lvl =  ability:GetLevel()
		need_lumber = lvl+1
		--print("   ",need_lumber)
	end
	if name == "attack" then
		ability = hero:GetAbilityByIndex(6)
		lvl =  ability:GetLevel()
		need_lumber = lvl+1
	end
	if name == "attackSpeed" then
		ability = hero:GetAbilityByIndex(7)
		lvl =  ability:GetLevel()
		need_lumber = lvl
	end
	if name == "hpPoints" then
		ability = hero:GetAbilityByIndex(8)
		lvl =  ability:GetLevel()
		need_lumber = lvl
	end
	if name == "mpPoints" then
		ability = hero:GetAbilityByIndex(9)
		lvl =  ability:GetLevel()
		need_lumber = lvl
	end
	if name == "hpRegen" then
		ability = hero:GetAbilityByIndex(10)
		lvl =  ability:GetLevel()
		need_lumber = lvl
	end
	if name == "mpRegen" then
		ability = hero:GetAbilityByIndex(11)
		lvl =  ability:GetLevel()
		need_lumber = lvl
	end
	--
	local dataL
	if ability:GetLevel()+1 <= ability:GetMaxLevel() then
		--print("ability:GetLevel()",ability:GetLevel())
		--print("ability:GetMaxLevel() ",ability:GetMaxLevel())
		if hero.lumber >= 1+need_lumber then -- + Abilities.GetLevel(ability) )
			--SetLevel
			ability:SetLevel(ability:GetLevel()+1)
			hero.lumber = hero.lumber - (1+need_lumber)
			hero.lumberSpent = hero.lumberSpent + (1+need_lumber)
			hero.percUlu = 100*hero.lumberSpent/maxLumber
			--Abilities.SetLevel(ability,Abilities.GetLevel(ability)+1);
			--print("ability GetLevel ",ability:GetLevel())
			doneU = true
		end
		--
		if ability:GetLevel() == ability:GetMaxLevel() then
			dataL = Survival:GetDataForSendUlu(false,doneU,pID,1+need_lumber,true,name)
		else
			dataL = Survival:GetDataForSendUlu(false,doneU,pID,1+need_lumber,false,name)
		end
		--
		
		-- update lumber in hud
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(pID), "upd_action_lumber", dataL )
		--CustomGameEventManager:Send_ServerToAllClients( "upd_action_lumber", dataL )
	--else
	--	dataL = Survival:GetDataForSendUlu(false,doneU,pID,1+need_lumber,true,name)
	end

	

end

function LiA:OnGameStateChange()  
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
        self.GameMode = LIA_MODE_SURVIVAL
        Survival:InitSurvival() --пока только так)
    end
    if self.GameMode == LIA_MODE_SURVIVAL then
        Survival:OnGameStateChange()
    else 

    end
end

function LiA:OnConnectFull(event)
    PrintTable("OnConnectFull",event)
    local entIndex = event.index+1
    local player = EntIndexToHScript(entIndex)
    local playerID = player:GetPlayerID()

    self.vUserIds[event.userid] = player
    
    --local playerSteamID = PlayerResource:GetSteamAccountID(playerID)
    --print("SteamID = ",playerSteamID)
    
    table.insert(self.tPlayers,player)
    self.nPlayers = self.nPlayers + 1  

    if self.GameMode == LIA_MODE_SURVIVAL then
        Survival:OnConnectFull(event)
    end
end

function LiA:OnDisconnect(event)
    PrintTable("OnDisconnect",event)
    local player = self.vUserIds[event.userid]

    if not player then
        return 
    end
    

    if player.readyToWave then
        player.readyToWave = false
        nPlayersReady = nPlayersReady - 1
    end
    
    for k,v in pairs(self.tPlayers) do 
        if player == v then
            table.remove(self.tPlayers,k)
        end
    end
   
    self.nPlayers = self.nPlayers - 1

    if self.GameMode == LIA_MODE_SURVIVAL then
        Survival:OnDisconnect(event)
    end
end

function LiA:OnNPCSpawned( event )
    local spawnedUnit = EntIndexToHScript( event.entindex )
    if spawnedUnit:IsHero() and not spawnedUnit:HasModifier("modifier_stats_bonus_fix") then
        spawnedUnit:AddAbility("stats_bonus_fix") --исправляет бонусы за характеристики для героев
   end
end

function LiA:OnPlayerLevelUp(event)
    local hero = PlayerResource:GetSelectedHeroEntity(event.player - 1) 

    if not hero.abilityPointsUsed then
    	hero.abilityPointsUsed = 0 
    end
    
    if hero:GetAbilityPoints() > 22-hero.abilityPointsUsed then
    	hero:SetAbilityPoints(22-hero.abilityPointsUsed)
    end

    if hero.abilityPointsUsed >= 22 then 
    	hero:SetAbilityPoints(0)
    end
end

function LiA:OnPlayerLearnedAbility(event)
    local hero = PlayerResource:GetSelectedHeroEntity(event.player - 1) 
    
    if not hero.abilityPointsUsed then
    	hero.abilityPointsUsed = 0 
    end

    hero.abilityPointsUsed = hero.abilityPointsUsed + 1 
end



function DisableShop()
    trigger_shop:Disable()
end

function EnableShop()
    trigger_shop:Enable()
end
