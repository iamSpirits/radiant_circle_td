print ('[RCTD] radiantcircle.lua' )

DEBUG=false
USE_LOBBY=true
THINK_TIME = 0.1
NUMBERTOSPAWN = 100 --How many to spawn
SPAWNLOCATION = "spawntopRight"
WAYPOINTNAME1 = "topRight"

--See Everything
dota_fow_disable = 1
dota_all_vision = 1


if RCTDGameMode == nil then
    print ( '[RCTDGAMEMODE] creating RCTD game mode' )
      --RCTDGameMode = {}
      --RCTDGameMode.szEntityClassName = "RCTDGameMode"
      --RCTDGameMode.szNativeClassName = "dota_base_game_mode"
      --RCTDGameMode.__index = RCTDGameMode
    RCTDGameMode = class({})
end

function RCTDGameMode:new( o )
  print ( '[RCTDGameMode] RCTDGameMode:new' )
  o = o or {}
  setmetatable( o, RCTDGameMode )
  return o
end

--SPAWNING FUNCTION
function RCTDGameMode:spawnunitsTopRight()
				local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION )
				local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME1)
				
                --hscript CreateUnitByName( string name, vector origin, bool findOpenSpot, hscript, hscript, int team)
                local creature = CreateUnitByName( "npc_dota_creature_basic_zombie" , spawnLocation:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS )
				creature:AddNewModifier( creature, nil , "modifier_phased", {})
                print ("Spawned 1r1")
                --Sets the waypath to follow. path_wp1 in this example
                creature:SetInitialGoalEntity( waypointlocation )
			return 1.0

end

--GAME MODE INITIATION
function RCTDGameMode:InitGameMode()

  print('[RCTDGameMode] Starting to load RadiantCircleTD gamemode...')
  
  GameRules:GetGameModeEntity():SetThink( "spawnunitsTopRight", self, "spawnunitsTopRightThinker", 1 ) 
  
  -- Setup rules
  GameRules:SetHeroRespawnEnabled( false )
  GameRules:SetUseUniversalShopMode( true )
  GameRules:SetSameHeroSelectionEnabled( true )
  GameRules:SetHeroSelectionTime( 30.0 )
  GameRules:SetPreGameTime( 30.0)
  GameRules:SetPostGameTime( 45.0 )
  GameRules:SetTreeRegrowTime( 60.0 )
  GameRules:SetGoldPerTick( 0.0 )
  print('[RCTDGameMode] Rules set')

  InitLogFile( "log/RCTD.txt","")

   --[[Hooks
  ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( RCTDGameMode, "OnGameRulesStateChange" ), self )
  ListenToGameEvent('entity_killed', Dynamic_Wrap(RCTDGameMode, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(RCTDGameMode, 'AutoAssignPlayer'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(RCTDGameMode, 'CleanupPlayer'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(RCTDGameMode, 'ShopReplacement'), self)
  ListenToGameEvent('player_say', Dynamic_Wrap(RCTDGameMode, 'PlayerSay'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(RCTDGameMode, 'PlayerConnect'), self)
  --ListenToGameEvent('player_info', Dynamic_Wrap(RCTDGameMode, 'PlayerInfo'), self)
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(RCTDGameMode, 'AbilityUsed'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap( RCTDGameMode, 'OnNPCSpawned' ), self )
  ]]
   -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))
  
  
  -- Timers
  self.timers = {}

  -- userID map
  self.vUserNames = {}
  self.vUserIds = {}
  self.vSteamIds = {}
  self.vBots = {}
  self.vBroadcasters = {}

  self.vPlayers = {}
  self.vRadiant = {}
  self.vDire = {}
  self.scoreRadiant = 0
  self.scoreDire = 0

  -- Active Hero Map
  self.vPlayerHeroData = {}
  print('[RCTDGameMode] values set')

  print('[RCTDGameMode] Precaching stuff...')
  --PrecacheUnitByName('npc_precache_everything')
  print('[RCTDGameMode] Done precaching!') 

  print('[RCTDGameMode] Done loading RadiantCircleTD gamemode!\n\n')
end



 function RCTDGameMode:CaptureGameMode()
  if GameMode == nil then
    -- Set GameMode parameters
    GameMode = GameRules:GetGameModeEntity()    
    -- Disables recommended items...though I don't think it works
    GameMode:SetRecommendedItemsDisabled( true )
    -- Override the normal camera distance.  Usual is 1134
    GameMode:SetCameraDistanceOverride( 1504.0 )
    -- Set Buyback options
    GameMode:SetCustomBuybackCostEnabled( true )
    GameMode:SetCustomBuybackCooldownEnabled( true )
    GameMode:SetBuybackEnabled( false )
    -- Override the top bar values to show your own settings instead of total deaths
    GameMode:SetTopBarTeamValuesOverride ( true )
    -- Chage the minimap icon size
    GameRules:SetHeroMinimapIconSize( 500 )

    print( '[RCTDGameMode] Beginning Think' ) 
    GameMode:SetContextThink("RCTDGameModeThink", Dynamic_Wrap( RCTDGameMode, 'Think' ), 0.1 )
  end 
end 


-- WELCOME MESSAGE
function RCTDGameMode:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    ShowGenericPopup( "#rctd_instructions_title", "#rctd_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
  end
end


-- Cleanup a player when they leave
function RCTDGameMode:CleanupPlayer(keys)
  print('[RCTDGameMode] Player Disconnected ' .. tostring(keys.userid))
end

function RCTDGameMode:CloseServer()
  -- Just exit
  SendToServerConsole('exit')
end

function RCTDGameMode:PlayerConnect(keys)
  print('[RCTDGameMode] PlayerConnect')
  PrintTable(keys)
  
  -- Fill in the usernames for this userID
  self.vUserNames[keys.userid] = keys.name
  if keys.bot == 1 then
    -- This user is a Bot, so add it to the bots table
    self.vBots[keys.userid] = 1
  end
 end
local hook = nil
local attach = 0
local controlPoints = {}
local particleEffect = ""

function RCTDGameMode:PlayerSay(keys)
  print ('[RCTDGameMode] PlayerSay')
  PrintTable(keys)
  
  -- Get the player entity for the user speaking
  local ply = self.vUserIds[keys.userid]
  if ply == nil then
    return
  end
  
  -- Get the player ID for the user speaking
  local plyID = ply:GetPlayerID()
  if not PlayerResource:IsValidPlayer(plyID) then
    return
  end
  
  -- Should have a valid, in-game player saying something at this point
  -- The text the person said
  local text = keys.text
  
  -- Match the text against something
  local matchA, matchB = string.match(text, "^-swap%s+(%d)%s+(%d)")
  if matchA ~= nil and matchB ~= nil then
    -- Act on the match
  end
  
end

--make lvl6 for passives
function RCTDGameMode:OnNPCSpawned( keys )
  print ( '[RCTDGameMode] OnNPCSpawned' )
  local spawnedUnit = EntIndexToHScript( keys.entindex )
  if spawnedUnit:IsHero() then
    local level = spawnedUnit:GetLevel()
      while level < 6 do
        spawnedUnit:AddExperience (2000,false)
        level = spawnedUnit:GetLevel()
      end
  end
end

function RCTDGameMode:Think()
  -- If the game's over, it's over.
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return
  end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local now = GameRules:GetGameTime()
  --print("now: " .. now)
  if RCTDGameMode.t0 == nil then
    RCTDGameMode.t0 = now
  end
  local dt = now - RCTDGameMode.t0
  RCTDGameMode.t0 = now

  --RCTDGameMode:thinkState( dt )

  -- Process timers
  for k,v in pairs(RCTDGameMode.timers) do
    local bUseGameTime = false
    if v.useGameTime and v.useGameTime == true then
      bUseGameTime = true;
    end
    -- Check if the timer has finished
    if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
      -- Remove from timers list
      RCTDGameMode.timers[k] = nil

      -- Run the callback
      local status, nextCall = pcall(v.callback, RCTDGameMode, v)

      -- Make sure it worked
      if status then
        -- Check if it needs to loop
        if nextCall then
          -- Change it's end time
          v.endTime = nextCall
          RCTDGameMode.timers[k] = v
        end

      else
        -- Nope, handle the error
        RCTDGameMode:HandleEventError('Timer', k, nextCall)
      end
    end
  end

  return THINK_TIME
end

function RCTDGameMode:CreateTimer(name, args)
  --[[
  args: {
  endTime = Time you want this timer to end: Time() + 30 (for 30 seconds from now),
  useGameTime = use Game Time instead of Time()
  callback = function(frota, args) to run when this timer expires,
  text = text to display to clients,
  send = set this to true if you want clients to get this,
  persist = bool: Should we keep this timer even if the match ends?
  }

  If you want your timer to loop, simply return the time of the next callback inside of your callback, for example:

  callback = function()
  return Time() + 30 -- Will fire again in 30 seconds
  end
  ]]

  if not args.endTime or not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  -- Store the timer
  self.timers[name] = args
end

function RCTDGameMode:RemoveTimer(name)
  -- Remove this timer
  self.timers[name] = nil
end

function RCTDGameMode:RemoveTimers(killAll)
  local timers = {}

  -- If we shouldn't kill all timers
  if not killAll then
    -- Loop over all timers
    for k,v in pairs(self.timers) do
      -- Check if it is persistant
      if v.persist then
        -- Add it to our new timer list
        timers[k] = v
      end
    end
  end

  -- Store the new batch of timers
  self.timers = timers
end

function RCTDGameMode:OnEntityKilled( keys )
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  local killerEntity = nil
  if keys.entindex_attacker == nil then
    return
  end
  
  killerEntity = EntIndexToHScript( keys.entindex_attacker )
  local killedTeam = killedUnit:GetTeam()
  local killerTeam = killerEntity:GetTeam()

  if killedUnit:IsRealHero() == true then
    local death_count_down = 5
    killedUnit:SetTimeUntilRespawn(death_count_down)

    RCTDGameMode:CreateTimer(DoUniqueString("respawn"), {
      endTime = GameRules:GetGameTime() + 1,
      useGameTime = true,
      callback = function(reflex, args)
        death_count_down = death_count_down - 1
        if death_count_down == 0 then
          --Respawn hero after 5 seconds
          killedUnit:RespawnHero(false,false,false)
          return
        else
          killedUnit:SetTimeUntilRespawn(death_count_down)
          return GameRules:GetGameTime() + 1
        end
      end
    })

    if killedTeam == DOTA_TEAM_BADGUYS then
      if killerTeam == 2 then
        self.scoreRadiant = self.scoreRadiant + 1
      end
    elseif killedTeam == DOTA_TEAM_GOODGUYS then
      if killerTeam == 3 then
        self.scoreDire = self.scoreDire + 1
      end
    end

    GameMode:SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.scoreDire)
    GameMode:SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.scoreRadiant )

    if self.scoreDire >= MAX_KILLS then
      GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
      GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
      GameRules:Defeated()
    end
    if self.scoreRadiant >= MAX_KILLS  then
      GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
      GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
      GameRules:Defeated()
    end
  end
end

-- A helper function for dealing damage from a source unit to a target unit.  Damage dealt is pure damage
function dealDamage(source, target, damage)
  local unit = nil
  if damage == 0 then
    return
  end
  
  if source ~= nil then
    unit = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, source, source, source:GetTeamNumber())
  else
    unit = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NOTEAM)
  end
  unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  unit:AddNewModifier(unit, nil, "modifier_phased", {})
  local dummy = unit:FindAbilityByName("reflex_dummy_unit")
  dummy:SetLevel(1)
  
  local abilIndex = math.floor((damage-1) / 20) + 1
  local abilLevel = math.floor(((damage-1) % 20)) + 1
  if abilIndex > 100 then
    abilIndex = 100
    abilLevel = 20
  end
  
  local abilityName = "modifier_damage_applier" .. abilIndex
  unit:AddAbility(abilityName)
  ability = unit:FindAbilityByName( abilityName )
  ability:SetLevel(abilLevel)
  
  local diff = nil
  
  local hp = target:GetHealth()
  
  diff = target:GetAbsOrigin() - unit:GetAbsOrigin()
  diff.z = 0
  unit:SetForwardVector(diff:Normalized())
  unit:CastAbilityOnTarget(target, ability, 0 )
  
  RCTDGameMode:CreateTimer(DoUniqueString("damage"), {
    endTime = GameRules:GetGameTime() + 0.3,
    useGameTime = true,
    callback = function(RCTDGameMode, args)
      unit:Destroy()
      if target:GetHealth() == hp and hp ~= 0 and damage ~= 0 then
        print ("[RCTDGameMode] WARNING: dealDamage did no damage: " .. hp)
        dealDamage(source, target, damage)
      end
    end
  })
end

-- Create the game mode when we activate --REPLACE THIS--
function Activate()
	GameRules.RCTDGameMode = RCTDGameMode()
	GameRules.RCTDGameMode:InitGameMode()
end



-- Evaluate the state of the game
function RCTDGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "RCTD addon script is running, BITCH." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end