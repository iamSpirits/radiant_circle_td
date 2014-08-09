-- RCTD Addon File


require( 'radiantcircle' )

if RCTDGameMode == nil then
	RCTDGameMode = class({})
end

function Precache( context )
        --Cache the zombie model
        PrecacheUnitByNameAsync( "npc_dota_creature_basic_zombie", context )
        PrecacheModel( "npc_dota_creature_basic_zombie", context )
end

-- Create the game mode when we activate --REPLACE THIS--
function Activate()
	GameRules.RCTDGameMode = RCTDGameMode()
	GameRules.RCTDGameMode:InitGameMode()
end