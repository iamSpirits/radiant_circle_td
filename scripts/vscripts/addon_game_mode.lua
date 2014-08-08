-- RCTD Addon File

--require( "blah" )

if RCTDGameMode == nil then
	RCTDGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate --REPLACE THIS--
function Activate()
	GameRules.RCTD = RCTDGameMode()
	GameRules.RCTD:InitGameMode()
end

function RCTDGameMode:InitGameMode()
	self._nRoundNumber = 1
	self._currentRound = nil
	self._flLastThinkGameTime = nil
	
	self:_ReadGameConfiguration()
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( false )
	GameRules:SetHeroSelectionTime( 10.0 )
	GameRules:SetPreGameTime( 40.0 )
	GameRules:SetPostGameTime( 40.0 )
	GameRules:SetTreeRegrowTime( 10.0 )
	GameRules:SetHeroMinimapIconSize( 400 )
	GameRules:SetCreepMinimapIconScale( 0.7 )
	GameRules:SetRuneMinimapIconScale( 0.7 )
	GameRules:SetGoldTickTime( 60.0 )
	GameRules:SetGoldPerTick( 0 )
	GameRules:GetGameModeEntity():SetRemoveIllusionsOnDeath( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	
	-- Custom console commands
	Convars:RegisterCommand( "rctd_test_round", function(...) return self:_TestRoundConsoleCommand( ... ) end, "Test a round of rctd.", FCVAR_CHEAT )
	Convars:RegisterCommand( "rctd_status_report", function(...) return self:_StatusReportConsoleCommand( ... ) end, "Report the status of the current rctd game.", FCVAR_CHEAT )
	
	-- Hook into game events allowing reload of functions at run time
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( RCTDGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( RCTDGameMode, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( RCTDGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( RCTDGameMode, "OnGameRulesStateChange" ), self )

	-- Register OnThink with the game engine so it is called every 0.25 seconds
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 ) 

	
	print( "RCTD addon is loaded." )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
end

STARTING_GOLD = 10000

-- Evaluate the state of the game
function RCTDGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "RCTD addon script is running, BITCH." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end