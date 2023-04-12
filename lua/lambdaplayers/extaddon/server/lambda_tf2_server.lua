local IsValid = IsValid
local net = net
local SimpleTimer = timer.Simple
local random = math.random
local min = math.min
local VectorRand = VectorRand
local hook_Add = hook.Add
local hook_Remove = hook.Remove
local CurTime = CurTime
local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local istable = istable
local IsSinglePlayer = game.SinglePlayer
local CreateSound = CreateSound
local EffectData = EffectData
local util_Effect = util.Effect
local IsPredicted = IsFirstTimePredicted
local ents_Create = ents.Create
local ParticleEffectAttach = ParticleEffectAttach
local SoundDuration = SoundDuration
local GetConVar = GetConVar
local string_Explode = string.Explode
local Rand = math.Rand
local deg = math.deg
local acos = math.acos
local Clamp = math.Clamp
local floor = math.floor
local Round = math.Round
local max = math.max
local ipairs = ipairs
local RandomPairs = RandomPairs
local isvector = isvector
local isnumber = isnumber
local isentity = isentity
local isbool = isbool
local isangle = isangle
local isstring = isstring
local band = bit.band
local FrameTime = FrameTime
local DamageInfo = DamageInfo
local SafeRemoveEntity = SafeRemoveEntity
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local SpriteTrail = util.SpriteTrail
local ScreenShake = util.ScreenShake
local Decal = util.Decal
local table_Empty = table.Empty
local table_remove = table.remove
local table_Count = table.Count
local FindInSphere = ents.FindInSphere
local FindByModel = ents.FindByModel
local Weld = constraint.Weld
local NoCollide = constraint.NoCollide
local SetPhysProp = construct.SetPhysProp
local TraceLine = util.TraceLine
local TraceHull = util.TraceHull
local FindAlongRay = ents.FindAlongRay

local bulletTbl = {}
local spreadVector = Vector( 0, 0, 0 )
local pushScale = GetConVar( "phys_pushscale" )
local ignorePlys = GetConVar( "ai_ignoreplayers" )
local serverRags = GetConVar( "lambdaplayers_lambda_serversideragdolls" )
local wepDmgScale = GetConVar( "lambdaplayers_combat_weapondmgmultiplier" )

local explosionTrTbl = { 
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    collisiongroup = COLLISION_GROUP_PROJECTILE,
    filter = function( ent )
        if LAMBDA_TF2:IsValidCharacter( ent ) then return false end
    end
}
local shieldChargeTrTbl = { 
    mins = -Vector( 24, 24, 24 ), 
    maxs = Vector( 24, 24, 24),
    mask = MASK_SOLID,
    collisiongroup = COLLISION_GROUP_NONE
}

LAMBDA_TF2 = LAMBDA_TF2 or {}

DMG_HALF_FALLOFF				        = DMG_RADIATION
DMG_CRITICAL                            = DMG_ACID
DMG_RADIUS_MAX					        = DMG_ENERGYBEAM
DMG_IGNITE					            = DMG_SLOWBURN
DMG_MINICRITICAL                        = DMG_PHYSGUN
DMG_USEDISTANCEMOD                      = DMG_AIRBOAT
DMG_NOCLOSEDISTANCEMOD                  = DMG_SNIPER
DMG_MELEE                               = DMG_BLAST_SURFACE
DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE = DMG_DISSOLVE

TF_DMG_CUSTOM_HEADSHOT                  = 1
TF_DMG_CUSTOM_BACKSTAB                  = 2
TF_DMG_CUSTOM_BURNING                   = 3
TF_DMG_CUSTOM_BURNING_BEHIND            = 4
TF_DMG_CUSTOM_DECAPITATION              = 20
TF_DMG_CUSTOM_CHARGE_IMPACT             = 23
TF_DMG_CUSTOM_BLEEDING                  = 34
TF_DMG_CUSTOM_TURNGOLD                  = 35
TF_DMG_CUSTOM_STICKBOMB_EXPLOSION       = 42
TF_DMG_CUSTOM_HEADSHOT_REVOLVER         = 43
TF_DMG_CUSTOM_KATANA_DUEL               = 47
TF_DMG_CUSTOM_GLOVES_LAUGHING           = 56

TF_DAMAGE_CRIT_CHANCE                   = 0.02
TF_DAMAGE_CRIT_CHANCE_RAPID             = 0.02
TF_DAMAGE_CRIT_CHANCE_MELEE             = 0.15
TF_DAMAGE_CRIT_DURATION_RAPID           = 2.0

TF_DAMAGE_CRIT_MULTIPLIER               = 3.0
TF_DAMAGE_MINICRIT_MULTIPLIER           = 1.35

TF_DAMAGE_CRITMOD_MAXTIME		        = 20
TF_DAMAGE_CRITMOD_MINTIME		        = 2
TF_DAMAGE_CRITMOD_DAMAGE		        = 500
TF_DAMAGE_CRITMOD_MAXMULT		        = 6

local dmgCustomKillicons = {
    [ TF_DMG_CUSTOM_BACKSTAB ]              = "lambdaplayers_weaponkillicons_tf2_backstab",
    [ TF_DMG_CUSTOM_HEADSHOT ]              = "lambdaplayers_weaponkillicons_tf2_headshot",
    [ TF_DMG_CUSTOM_HEADSHOT_REVOLVER ]     = "lambdaplayers_weaponkillicons_tf2_ambassador_headshot",
    [ TF_DMG_CUSTOM_STICKBOMB_EXPLOSION ]   = "lambdaplayers_weaponkillicons_tf2_caber_explosion",
    [ TF_DMG_CUSTOM_KATANA_DUEL ]           = "lambdaplayers_weaponkillicons_tf2_katana_duel",
    [ TF_DMG_CUSTOM_BURNING_BEHIND ]        = "lambdaplayers_weaponkillicons_tf2_backburner_behind",
    [ TF_DMG_CUSTOM_GLOVES_LAUGHING ]       = "lambdaplayers_weaponkillicons_tf2_holidaypunch_laugh"
}
local dmgCustomDecapitates = {
    [ TF_DMG_CUSTOM_DECAPITATION ]          = true,
    [ TF_DMG_CUSTOM_KATANA_DUEL ]           = true
}
local dmgCustomHeadshots = {
    [ TF_DMG_CUSTOM_HEADSHOT ]              = true,
    [ TF_DMG_CUSTOM_HEADSHOT_REVOLVER ]     = true
}
local dmgCustomBurns = {
    [ TF_DMG_CUSTOM_BURNING ]               = true,
    [ TF_DMG_CUSTOM_BURNING_BEHIND ]        = true
}

local physProp_Metal = { Material = "metal" }
local physProp_Ice = { Material = "ice" }

util.AddNetworkString( "lambda_tf2_addobjectorimage" )
util.AddNetworkString( "lambda_tf2_domination" )
util.AddNetworkString( "lambda_tf2_stopnamedparticle" )
util.AddNetworkString( "lambda_tf2_removecsragdoll" )
util.AddNetworkString( "lambda_tf2_removecsprop" )
util.AddNetworkString( "lambda_tf2_criteffects" )
util.AddNetworkString( "lambda_tf2_ignite_csragdoll" )
util.AddNetworkString( "lambda_tf2_decapitate_csragdoll" )
util.AddNetworkString( "lambda_tf2_decapitate_sendgibdata" )
util.AddNetworkString( "lambda_tf2_stuneffect" )
util.AddNetworkString( "lambda_tf2_medigun_beameffect" )
util.AddNetworkString( "lambda_tf2_medigun_chargeeffect" )
util.AddNetworkString( "lambda_tf2_turncsragdollintostatue" )

net.Receive( "lambda_tf2_decapitate_sendgibdata", function()
    LAMBDA_TF2:CreateGib( net.ReadVector(), net.ReadAngle(), net.ReadVector(), "models/lambdaplayers/tf2/gibs/humanskull.mdl" )
end )

net.Receive( "lambda_tf2_turncsragdollintostatue", function()
    local ragdoll = ents_Create( "prop_ragdoll" )
    if !IsValid( ragdoll ) then return end

    ragdoll:SetModel( net.ReadString() )
    ragdoll:SetPos( net.ReadVector() )
    ragdoll:SetAngles( net.ReadAngle() )
    ragdoll:Spawn()
    
    ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    ragdoll:SetSkin( net.ReadUInt( 8 ) )
    for id, group in pairs( net.ReadTable() ) do
        ragdoll:SetBodygroup( id, group )
    end

    local turnIce = net.ReadBool()
    for id, data in pairs( net.ReadTable() ) do    
        local bonePhys = ragdoll:GetPhysicsObjectNum( id )
        bonePhys:SetPos( data[ 1 ], true )
        bonePhys:SetAngles( data[ 2 ] )
        if !turnIce then bonePhys:SetVelocity( data[ 3 ] ) end
    end

    local owner = net.ReadEntity()
    if !turnIce then
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/gold_player", physProp_Metal )
        ragdoll:EmitSound( ")weapons/saxxy_impact_gen_06.wav", 80, nil, nil, CHAN_STATIC )
    else
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/ice_player", physProp_Ice )
        
        if IsValid( owner ) and owner:OnGround() then
            ragdoll:SetSolid( SOLID_NONE )

            SimpleTimer( 0.1, function()
                if !IsValid( ragdoll ) then return end
                
                local physObjs = {}
                for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do    
                    local bonePhys = ragdoll:GetPhysicsObjectNum( i )
                    bonePhys:SetVelocityInstantaneous( vector_origin ) 
                    bonePhys:Sleep()
                    physObjs[ #physObjs + 1 ] = bonePhys
                end
                
                local frozenTime = ( CurTime() + Rand( 9.0, 11.0 ) )
                LambdaCreateThread( function()
                    while ( IsValid( ragdoll ) ) do
                        if CurTime() < frozenTime then
                            for _, bonePhys in ipairs( physObjs ) do
                                bonePhys:SetVelocityInstantaneous( vector_origin ) 
                                bonePhys:Sleep()
                            end
                        else
                            for _, bonePhys in ipairs( physObjs ) do
                                bonePhys:Wake()
                            end

                            ragdoll:SetSolid( SOLID_VPHYSICS )
                            return 
                        end

                        coroutine_yield()
                    end
                end )

                ParticleEffectAttach( "xms_icicle_impact_dryice", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )
                ragdoll:EmitSound( ")weapons/icicle_freeze_victim_01.wav", 80, nil, nil, CHAN_STATIC )
            end )
        end
    end
    
    ragdoll.l_TF_IsTurnedStatue = true
    if IsValid( owner ) then 
        local oldRagdoll = net.ReadEntity()

        if owner:IsPlayer() and IsValid( oldRagdoll ) then
            owner:Spectate( OBS_MODE_CHASE )
            owner:SpectateEntity( ragdoll )
            oldRagdoll:Remove()
        end

        hook.Run( "CreateEntityRagdoll", owner, ragdoll )
    end
end )

function LAMBDA_TF2:TurnIntoStatue( ragdoll, mat, physProp )
    local physBones = ( ragdoll:GetPhysicsObjectCount() - 1 )
    for physBone = 0, physBones do    
        if physBones > 1 and physBone != 0 then Weld( ragdoll, ragdoll, 0, physBone ) end
        if physProp then SetPhysProp( nil, ragdoll, physBone, nil, physProp ) end
    end

    ragdoll:RemoveInternalConstraint( -1 )
    ragdoll:SetMaterial( mat )
end

function LAMBDA_TF2:EntityThink( ent )
    local isDead = ( ent:Health() <= 0 or ( ent.IsLambdaPlayer or ent:IsPlayer() ) and !ent:Alive() )
    local curTime = CurTime()

    if ent.l_TF_HasOverheal then
        local curHealth = ent:Health()
        local maxHealth = ent:GetMaxHealth()

        if isDead or curHealth <= maxHealth then
            ent.l_TF_HasOverheal = false
        elseif curTime > ent.l_TF_OverhealDecreaseStartT then
            local boostMaxAmount = ( LAMBDA_TF2:GetMaxBuffedHealth( ent ) - maxHealth )
            ent.l_TF_HealFraction = ( ent.l_TF_HealFraction + ( FrameTime() * ( boostMaxAmount / 15 ) ) )

            local healthToDrain = Round( ent.l_TF_HealFraction )
            if healthToDrain > 0 then
                ent.l_TF_HealFraction = ( ent.l_TF_HealFraction - healthToDrain )
                ent:SetHealth( max( curHealth - healthToDrain, maxHealth ) )
            end
        end
    end

    if ent.l_TF_CoveredInUrine then 
        if ( isDead or curTime > ent.l_TF_CoveredInUrine or ent:WaterLevel() >= 2 ) then
            ent.l_TF_CoveredInUrine = false

            if ent.l_TF_UrineEffect then
                LAMBDA_TF2:StopParticlesNamed( ent, "peejar_drips" )
                ent.l_TF_UrineEffect = false
            end
        elseif !ent.l_TF_UrineEffect then
            ParticleEffectAttach( "peejar_drips", PATTACH_ABSORIGIN_FOLLOW, ent, 0 )
            ent.l_TF_UrineEffect = true
        end
    end
    ent:SetNW2Bool( "lambda_tf2_isjarated", ( ent.l_TF_CoveredInUrine != false ) )

    if ent.l_TF_CoveredInMilk then 
        if ( isDead or curTime > ent.l_TF_CoveredInMilk or ent:WaterLevel() >= 2 ) then
            ent.l_TF_CoveredInMilk = false

            if ent.l_TF_MilkEffect then
                LAMBDA_TF2:StopParticlesNamed( ent, "peejar_drips_milk" )
                ent.l_TF_MilkEffect = false
            end
        elseif !ent.l_TF_MilkEffect then
            ParticleEffectAttach( "peejar_drips_milk", PATTACH_ABSORIGIN_FOLLOW, ent, 0 )
            ent.l_TF_MilkEffect = true
        end
    end

    local bleedInfos = ent.l_TF_BleedInfo
    if bleedInfos then
        ent:SetNW2Bool( "lambda_tf2_bleeding", ( #bleedInfos > 0 ) )

        if #bleedInfos > 0 then
            if isDead or curTime <= ent.l_TF_InvulnerabilityTime then
                LAMBDA_TF2:RemoveBleeding( ent )
            else
                for index, info in ipairs( bleedInfos ) do
                    if !info.PermamentBleeding and curTime >= info.ExpireTime then
                        table_remove( bleedInfos, index )
                    elseif curTime >= info.BleedingTime then
                        info.BleedingTime = ( curTime + 0.5 )

                        local attacker = info.Attacker
                        if !IsValid( attacker ) then attacker = ent end

                        local dmginfo = DamageInfo()
                        dmginfo:SetAttacker( attacker )
                        dmginfo:SetInflictor( info.Inflictor )
                        dmginfo:SetDamage( info.BleedDmg )
                        dmginfo:SetDamageType( DMG_SLASH )
                        dmginfo:SetDamagePosition( ent:WorldSpaceCenter() + VectorRand( -5, 5 ) )
                        dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BLEEDING )

                        ent:TakeDamageInfo( dmginfo )
                    end
                end
            end
        end
    end
    
    if ent:GetIsBurning() then
        if isDead or curTime > ent:GetFlameRemoveTime() or ent:WaterLevel() >= 2 or curTime <= ent.l_TF_InvulnerabilityTime then
            LAMBDA_TF2:RemoveBurn( ent )
        elseif curTime >= ent.l_TF_FlameBurnTime then
            local burnDamage = 3
            local killType = TF_DMG_CUSTOM_BURNING

            local attacker = ent.l_TF_BurnAttacker
            if !IsValid( attacker ) then attacker = Entity( 0 ) end

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( attacker )
            dmginfo:SetInflictor( ent.l_TF_BurnInflictor )
            dmginfo:SetDamage( burnDamage )
            dmginfo:SetDamageType( DMG_BURN + DMG_PREVENT_PHYSICS_FORCE )
            dmginfo:SetDamagePosition( ent:WorldSpaceCenter() + VectorRand( -5, 5 ) )
            dmginfo:SetDamageCustom( killType )

            ent:TakeDamageInfo( dmginfo )
            ent.l_TF_FlameBurnTime = ( curTime + 0.5 )
        end
    end

    if ent.l_TF_InvulnerabilityTime then 
        local critBoosted = ( ent:GetCritBoostType() != TF_CRIT_NONE )
        local invulnMat = LAMBDA_TF2:GetInvulnMaterial()

        if curTime <= ent.l_TF_InvulnerabilityTime then
            ent:SetMaterial( invulnMat )

            for _, child in ipairs( ent:GetChildren() ) do
                if !IsValid( child ) or child:GetMaterial() == invulnMat then continue end
                if ent.IsLambdaPlayer then 
                    if child == ent.WeaponEnt and ( critBoosted or ent:IsWeaponMarkedNodraw() ) then continue end
                    if child == ent.l_TF_Shield_Entity and critBoosted then continue end
                end
                child:SetMaterial( invulnMat )
            end
        elseif ent:GetMaterial() == invulnMat then
            ent:SetMaterial( "" )

            for _, child in ipairs( ent:GetChildren() ) do                   
                if !IsValid( child ) or child:GetMaterial() != invulnMat then continue end
                if ent.IsLambdaPlayer then 
                    if child == ent.WeaponEnt and ( critBoosted or ent:IsWeaponMarkedNodraw() ) then continue end
                    if child == ent.l_TF_Shield_Entity and critBoosted then continue end
                end
                child:SetMaterial( "" )
            end
        end

        ent:SetIsInvulnerable( curTime <= ent.l_TF_InvulnerabilityTime )
        ent:SetInvulnerabilityWearingOff( ( ent.l_TF_InvulnerabilityTime - curTime ) < 0.9 )
    end

    if ent.l_TF_IsStunned then
        if isDead or curTime >= ent.l_TF_IsStunned then
            ent.l_TF_IsStunned = false

            if ent.IsLambdaPlayer and ent.l_TF_StunMovement then
                if !isDead then
                    ent.l_UpdateAnimations = true

                    local endAnim, stateTime = ent:LookupSequence( "tf_stun_end" )
                    ent:AddGestureSequence( endAnim )

                    ent:SimpleTimer( stateTime, function()
                        ent:SetState( ent.l_TF_PreStunState or "Idle" )
                    end )
                else
                    ent:SetState( ent.l_TF_PreStunState or "Idle" )
                end
            elseif ent:IsPlayer() then
                ent:SetWalkSpeed( ent:GetWalkSpeed() / 0.75 )
                ent:SetRunSpeed( ent:GetRunSpeed() / 0.75 )
                ent:SetDuckSpeed( ent:GetDuckSpeed() / 0.75 )
                ent:SetSlowWalkSpeed( ent:GetSlowWalkSpeed() / 0.75 )

                if ent.l_TF_StunMovement then ent:Freeze( false ) end
            end

            net.Start( "lambda_tf2_stuneffect" )
                net.WriteEntity( ent )
            net.Broadcast()
        else
            if ent.IsLambdaPlayer and ent.l_TF_StunMovement and curTime >= ent.l_TF_StunStateChangeT then
                if ent.l_TF_JustGotStunned then
                    local beginAnim, stateTime = ent:LookupSequence( "tf_stun_begin" )

                    ent:AddGestureSequence( beginAnim )

                    ent.l_TF_JustGotStunned = false
                    ent.l_TF_StunStateChangeT = ( curTime + stateTime )
                else
                    local middleAnim, stateTime = ent:LookupSequence( "tf_stun_middle" )

                    ent:SetSequence( middleAnim )
                    ent:ResetSequenceInfo()
                    ent:SetCycle( 0 )
                    
                    ent.l_UpdateAnimations = false
                    ent.l_TF_StunStateChangeT = ( curTime + stateTime )
                end
            end
        end
    end

    if ent.l_TF_CritBoosts then
        local boostType = TF_CRIT_NONE
        for boostName, boost in pairs( ent.l_TF_CritBoosts ) do
            if isDead or curTime >= boost.Duration then
                ent.l_TF_CritBoosts[ boostName ] = nil
            else
                local critType = boost.CritType
                if critType > boostType then boostType = critType end
            end
        end

        if ent.l_TF_LastCritBoost != boostType then
            LAMBDA_TF2:UpdateCritBoostEffect( ent, boostType )
        end
        ent.l_TF_LastCritBoost = boostType
    end
        
    if ent.l_TF_InSpeedBoost then 
        local boostTrail = ent.l_TF_SpeedBoostTrail

        if isDead or curTime >= ent.l_TF_InSpeedBoost then
            if !ent.l_TF_SpeedBoostIsBuff then
                ent:EmitSound( ")weapons/discipline_device_power_down.wav", 65, nil, nil, CHAN_STATIC )
            end

            if IsValid( boostTrail ) then
                boostTrail:SetParent()
                SafeRemoveEntityDelayed( boostTrail, 1 )
            end

            if ent.IsLambdaPlayer then
                ent.l_nextspeedupdate = 0
            elseif ent:IsPlayer() then
                ent:SetWalkSpeed( ent:GetWalkSpeed() / 1.4 )
                ent:SetRunSpeed( ent:GetRunSpeed() / 1.4 )
                ent:SetDuckSpeed( ent:GetDuckSpeed() / 1.4 )
                ent:SetSlowWalkSpeed( ent:GetSlowWalkSpeed() / 1.4 )
            end

            ent.l_TF_InSpeedBoost = false
            ent.l_TF_SpeedBoostIsBuff = false
        elseif !ent.l_TF_SpeedBoostActive then
            if !ent.l_TF_SpeedBoostIsBuff and !IsValid( boostTrail ) then
                boostTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 16, 8, 0.33, "effects/beam001_white", ent:WorldSpaceCenter(), ent )
                ent:DeleteOnRemove( boostTrail )
                ent.l_TF_SpeedBoostTrail = boostTrail
            end

            if ent.IsLambdaPlayer then
                ent.l_nextspeedupdate = 0
            elseif ent:IsPlayer() then
                ent:SetWalkSpeed( ent:GetWalkSpeed() * 1.4 )
                ent:SetRunSpeed( ent:GetRunSpeed() * 1.4 )
                ent:SetDuckSpeed( ent:GetDuckSpeed() * 1.4 )
                ent:SetSlowWalkSpeed( ent:GetSlowWalkSpeed() * 1.4 )
            end

            ent.l_TF_SpeedBoostActive = true
        end
    end

    local hadActiveBuff = false

    if ent.l_TF_DefenseBuffActive and ( isDead or curTime >= ent.l_TF_DefenseBuffActive ) then
        ent.l_TF_DefenseBuffActive = false 
        hadActiveBuff = true
    end
    if ent.l_TF_OffenseBuffActive and ( isDead or curTime >= ent.l_TF_OffenseBuffActive ) then
        ent.l_TF_OffenseBuffActive = false
        hadActiveBuff = true
    end
    local speedBuff = ent.l_TF_SpeedBuffActive
    if speedBuff then 
        if ( isDead or curTime >= speedBuff ) then
            ent.l_TF_SpeedBuffActive = false
            hadActiveBuff = true
        elseif !ent.l_TF_InSpeedBoost or speedBuff > ent.l_TF_InSpeedBoost then
            ent.l_TF_InSpeedBoost = speedBuff
            ent.l_TF_SpeedBoostIsBuff = true
        end
    end

    if hadActiveBuff == true then
        LAMBDA_TF2:StopParticlesNamed( ent, "soldierbuff_red_soldier" )
        LAMBDA_TF2:StopParticlesNamed( ent, "soldierbuff_blue_soldier" )
    end
end

local shotgunCockingTimings = {
    { 0.342857, 0.485714 },
    { 0.285714, 0.428571 },
    { 0.4, 0.533333 },
    { 0.233333, 0.366667 }
}
local shotgunReloadInterruptCond = function( lambda, weapon )
    return ( lambda.l_Clip > 0 and random( 1, 3 ) == 1 and lambda:InCombat() and lambda:IsInRange( lambda:GetEnemy(), 512 ) and lambda:CanSee( lambda:GetEnemy() ) )
end
local shotgunReloadEndFunc = function( lambda, weapon, interrupted )
    if interrupted then return end
    local cockTimings = shotgunCockingTimings[ random( #shotgunCockingTimings ) ]
    
    lambda:SimpleWeaponTimer( cockTimings[ 1 ], function()
        weapon:EmitSound( "weapons/shotgun_cock_back.wav", 70, nil, nil, CHAN_STATIC )
    end )
    lambda:SimpleWeaponTimer( cockTimings[ 2 ], function()
        weapon:EmitSound( "weapons/shotgun_cock_forward.wav", 70, nil, nil, CHAN_STATIC )
    end )
end

function LAMBDA_TF2:ShotgunReload( lambda, weapon, dataTbl )
    dataTbl = dataTbl or {}
    local startTime = ( dataTbl.StartDelay or 0.4 )
    local cycleTime = ( dataTbl.CycleDelay or 0.5 )

    local startFunc = dataTbl.StartFunction
    local cycleFunc = dataTbl.CycleFunction
    
    local interruptCondition = dataTbl.InterruptCondition
    if interruptCondition == nil then interruptCondition = shotgunReloadInterruptCond end

    local endFunc = dataTbl.EndFunction
    if endFunc == nil then endFunc = shotgunReloadEndFunc end

    local startSnd = dataTbl.StartSound
    local cycleSnd = ( dataTbl.CycleSound or "weapons/shotgun_worldreload.wav" )
    local endSnd = dataTbl.EndSound

    local animAct = ( dataTbl.Animation or ACT_HL2MP_GESTURE_RELOAD_AR2 )
    local layerCycle = ( dataTbl.LayerCycle or 0.2 )
    local layerRate = ( dataTbl.LayerPlayRate or 1.6 )

    local reloadLayer
    if isstring( animAct ) then
        reloadLayer = lambda:AddGestureSequence( lambda:LookupSequence( animAct ) )
    else
        lambda:RemoveGesture( animAct )
        reloadLayer = lambda:AddGesture( animAct )
    end

    lambda:SetIsReloading( true )
    lambda:Thread( function()

        if startFunc then startFunc( lambda, weapon ) end
        if startSnd then weapon:EmitSound( startSnd, 70, nil, nil, CHAN_STATIC ) end
        coroutine_wait( startTime )

        local interrupted = false
        while ( lambda.l_Clip < lambda.l_MaxClip ) do
            if !lambda:GetIsReloading() then return end

            if interruptCondition then
                interrupted = interruptCondition( lambda, weapon )
                if interrupted then break end
            end

            if !lambda:IsValidLayer( reloadLayer ) then
                reloadLayer = ( isstring( animAct ) and lambda:AddGestureSequence( lambda:LookupSequence( animAct ) ) or lambda:AddGesture( animAct ) )
            end
            lambda:SetLayerCycle( reloadLayer, layerCycle )
            lambda:SetLayerPlaybackRate( reloadLayer, layerRate )

            if cycleFunc then cycleFunc( lambda, weapon ) end

            lambda.l_Clip = lambda.l_Clip + 1
            weapon:EmitSound( cycleSnd, 70, nil, nil, CHAN_STATIC )
            coroutine_wait( cycleTime )
        end

        if endSnd then weapon:EmitSound( endSnd, 70, nil, nil, CHAN_STATIC ) end
        if endFunc then endFunc( lambda, weapon, interrupted ) end
        
        if !isstring( animAct ) then 
            lambda:RemoveGesture( animAct ) 
        elseif lambda:IsValidLayer( reloadLayer ) then
            lambda:SetLayerCycle( reloadLayer, 1 )
        end
        
        lambda:SetIsReloading( false )

    end, "TF2_ShotgunReload" )
end

function LAMBDA_TF2:CreateShellEject( weapon, name )
    if !IsPredicted() then return end

    local shellAttach = weapon:LookupAttachment( "shell" )
    if shellAttach <= 0 then return end

    local shellEject = weapon:GetAttachment( shellAttach )
    local shellData = EffectData()
    shellData:SetOrigin( shellEject.Pos )
    shellData:SetAngles( shellEject.Ang )
    shellData:SetEntity( weapon )
    util_Effect( name, shellData )
end

function LAMBDA_TF2:CreateMuzzleFlash( weapon, type )
    if !IsPredicted() then return end

    local muzzleAttach = weapon:LookupAttachment( "muzzle" )
    if muzzleAttach <= 0 then return end

    local muzzleFlash = weapon:GetAttachment( muzzleAttach )
    local muzzleData = EffectData()
    muzzleData:SetOrigin( muzzleFlash.Pos )
    muzzleData:SetStart( muzzleFlash.Pos )
    muzzleData:SetAngles( muzzleFlash.Ang )
    muzzleData:SetFlags( type )
    muzzleData:SetEntity( weapon )
    util_Effect( "MuzzleFlash", muzzleData )
end

function LAMBDA_TF2:GetPushScale()
    return ( pushScale:GetFloat() )
end

local fixedWpnSpreadPellets = {
    Vector( 0, 0, 0 ),
    Vector( 1, 0, 0 ),	
    Vector( -1, 0, 0 ),	
    Vector( 0, -1, 0 ),	
    Vector( 0, 1, 0 ),	
    Vector( 0.85, -0.85, 0 ),	
    Vector( 0.85, 0.85, 0 ),	
    Vector( -0.85, -0.85, 0 ),	
    Vector( -0.85, 0.85, 0 ),	
    Vector( 0, 0, 0 )
}

function LAMBDA_TF2:WeaponAttack( lambda, weapon, target, isCrit )
    isCrit = ( isCrit == nil and weapon:CalcIsAttackCriticalHelper() or isCrit )
    local isMelee = weapon:GetWeaponAttribute( "IsMelee", false )

    if !isMelee then
        local clipDrain = weapon:GetWeaponAttribute( "ClipDrain", 1 )
        if clipDrain then
            local curClip = lambda.l_Clip
            if curClip <= 0 then lambda:ReloadWeapon() return end
            lambda.l_Clip = max( curClip - clipDrain, 0 )
        end

        local attackAnim = weapon:GetWeaponAttribute( "Animation" )
        if attackAnim then
            lambda:RemoveGesture( attackAnim )
            lambda:AddGesture( attackAnim, true )
        end

        local cooldown = weapon:GetWeaponAttribute( "RateOfFire", 0.1 )
        if istable( cooldown ) then cooldown = Rand( cooldown[ 1 ], cooldown[ 2 ] ) end
        lambda.l_WeaponUseCooldown = ( CurTime() + cooldown )
    
        local shellName = weapon:GetWeaponAttribute( "ShellEject", "ShellEject" )
        if shellName then LAMBDA_TF2:CreateShellEject( weapon, shellName ) end

        local muzzleType = weapon:GetWeaponAttribute( "MuzzleFlash", 1 )
        if muzzleType then LAMBDA_TF2:CreateMuzzleFlash( weapon, muzzleType ) end

        local fireSnd = weapon:GetWeaponAttribute( "Sound" )
        if fireSnd then
            local critSnd = weapon:GetWeaponAttribute( "CritSound" )
            if critSnd and isCrit then fireSnd = critSnd end
            if istable( fireSnd ) then fireSnd = fireSnd[ random( #fireSnd ) ] end
            weapon:EmitSound( fireSnd, 75, 100, 1, CHAN_WEAPON )
        end

        local fireBullet = weapon:GetWeaponAttribute( "FireBullet", true )
        if fireBullet then
            local wepPos = weapon:GetPos()

            bulletTbl.Attacker = lambda
            bulletTbl.IgnoreEntity = lambda
            bulletTbl.Src = wepPos

            local tracer = weapon:GetWeaponAttribute( "Tracer", "Tracer" )
            bulletTbl.TracerName = tracer

            local damage = weapon:GetWeaponAttribute( "Damage", 5 )
            if istable( damage ) then damage = random( damage[ 1 ], damage[ 2 ] ) end
            bulletTbl.Damage = damage
            bulletTbl.Force = ( damage / 3 )

            local weaponSpread = weapon:GetWeaponAttribute( "Spread", 0.1 )
            spreadVector.x = weaponSpread
            spreadVector.y = weaponSpread
            bulletTbl.Spread = spreadVector

            local firePos = target:WorldSpaceCenter()
            
            local preBulletCallback = weapon:GetWeaponAttribute( "PreFireBulletCallback" )
            if preBulletCallback then 
                local overridePos = preBulletCallback( lambda, weapon, target, dmginfo, bulletTbl ) 
                if isvector( overridePos ) then firePos = overridePos end
            end

            local lambdaAccuracyOffset = LAMBDA_TF2:RemapClamped( lambda:GetRangeTo( target ), 128, 1024, 3, 30 )
            local fireAng = ( firePos - wepPos ):Angle()
            fireAng = ( ( firePos + fireAng:Right() * Rand( -lambdaAccuracyOffset, lambdaAccuracyOffset ) + fireAng:Up() * Rand( -lambdaAccuracyOffset, lambdaAccuracyOffset ) ) - wepPos ):Angle()

            bulletTbl.Callback = function( attacker, tr, dmginfo )
                local dmgTypes = ( weapon:GetWeaponAttribute( "DamageType", 0 ) )
                if isCrit then
                    dmgTypes = ( dmgTypes + DMG_CRITICAL )
                    LAMBDA_TF2:CreateCritBulletTracer( tr.StartPos, tr.HitPos, lambda:GetPlyColor():ToColor() )
                end
                dmginfo:SetDamageType( dmginfo:GetDamageType() + dmgTypes )

                local bulletCallback = weapon:GetWeaponAttribute( "BulletCallback" )
                if bulletCallback then bulletCallback( lambda, weapon, tr, dmginfo ) end
            end

            local firstShotAccurate = weapon:GetWeaponAttribute( "FirstShotAccurate", false )
            local bulletPreShot = weapon:GetWeaponAttribute( "ProjectileCount", 1 )
            local spreadRecovery = weapon:GetWeaponAttribute( "SpreadRecovery", ( bulletPreShot > 1 and 0.25 or 1.25 ) )
            local fixedSpread = weapon:GetWeaponAttribute( "FixedSpread", false )

            for i = 1, bulletPreShot do
                local spreadScalar = 0.5
                local spreadX, spreadY = 0, 0

                if fixedSpread then
                    local spreadIndex = i
                    if spreadIndex > #fixedWpnSpreadPellets then
                        spreadIndex = ( spreadIndex - #fixedWpnSpreadPellets )
                    end

                    spreadX = ( fixedWpnSpreadPellets[ spreadIndex ].x * spreadScalar )
                    spreadY = ( fixedWpnSpreadPellets[ spreadIndex ].y * spreadScalar )
                elseif !firstShotAccurate or ( CurTime() - weapon.l_TF_LastFireTime ) <= spreadRecovery then 
                    spreadX = ( Rand( -spreadScalar, spreadScalar ) + Rand( -spreadScalar, spreadScalar ) )
                    spreadY = ( Rand( -spreadScalar, spreadScalar ) + Rand( -spreadScalar, spreadScalar ) )
                end
                bulletTbl.Dir = ( fireAng:Forward() + ( spreadX * bulletTbl.Spread.x * fireAng:Right() ) + ( spreadY * bulletTbl.Spread.y * fireAng:Up() ) )

                local preBulletCallback = weapon:GetWeaponAttribute( "PreFireBulletCallback" )
                if preBulletCallback then preBulletCallback( lambda, weapon, target, dmginfo, bulletTbl ) end

                weapon:FireBullets( bulletTbl )
                weapon.l_TF_LastFireTime = CurTime()
            end
        end
    else
        local hitRange = weapon:GetWeaponAttribute( "HitRange", 42 )
        local hitDelay = weapon:GetWeaponAttribute( "HitDelay", 0.2 )
        
        local attackRange = hitRange
        if isnumber( hitDelay ) and hitDelay > 0 then
            attackRange = ( attackRange * ( 1 + Rand( 0, hitDelay ) ) )
        end

        local eyePos = lambda:GetAttachmentPoint( "eyes" ).Pos
        local hitPos = target:NearestPoint( eyePos )
        if eyePos:DistToSqr( hitPos ) > ( attackRange ^ 2 ) then return end
        
        local fireSnd = weapon:GetWeaponAttribute( "Sound", ")weapons/cbar_miss1.wav" )
        if fireSnd then
            local critSnd = weapon:GetWeaponAttribute( "CritSound", ")weapons/cbar_miss1_crit.wav" )
            if critSnd and isCrit then fireSnd = critSnd end
            if istable( fireSnd ) then fireSnd = fireSnd[ random( #fireSnd ) ] end
            weapon:EmitSound( fireSnd, 64, nil, 0.6, CHAN_WEAPON )
        end

        local attackAnim = weapon:GetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
        if attackAnim then 
            lambda:RemoveGesture( attackAnim )
            local attackLayer = lambda:AddGesture( attackAnim, true )
            lambda:SetLayerPlaybackRate( attackLayer, 0.85 )
        end
    
        local cooldown = weapon:GetWeaponAttribute( "RateOfFire", 0.8 )
        if istable( cooldown ) then cooldown = Rand( cooldown[ 1 ], cooldown[ 2 ] ) end
        lambda.l_WeaponUseCooldown = ( CurTime() + cooldown )

        local damage = weapon:GetWeaponAttribute( "Damage", 40 )
        if isfunction( damage ) then damage = damage( lambda, weapon, target ) end

        if damage then
            if istable( damage ) then damage = random( damage[ 1 ], damage[ 2 ] ) end
            local onMissFunc = weapon:GetWeaponAttribute( "OnMiss" )

            local hitFunction = function()
                eyePos = lambda:GetAttachmentPoint( "eyes" ).Pos
                hitPos = ( LambdaIsValid( target ) and target:NearestPoint( eyePos ) or nil )
                
                local missed = ( !hitPos or eyePos:DistToSqr( hitPos ) > ( hitRange ^ 2 ) ) 
                if missed then hitPos = eyePos end

                local dmginfo = DamageInfo()
                dmginfo:SetDamage( damage )
                dmginfo:SetAttacker( lambda )
                dmginfo:SetInflictor( weapon )
                dmginfo:SetDamageCustom( weapon:GetWeaponAttribute( "CustomDamage", 0 ) )
                dmginfo:SetDamagePosition( hitPos )

                local dmgTypes = ( DMG_MELEE + DMG_NEVERGIB + weapon:GetWeaponAttribute( "DamageType", DMG_CLUB ) )
                if isCrit then 
                    dmgTypes = ( dmgTypes + DMG_CRITICAL ) 
                elseif lambda:GetNextMeleeCrit() == TF_CRIT_MINI then 
                    dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
                end
                dmginfo:SetDamageType( dmgTypes )

                local hitAng = ( ( hitPos - lambda:GetForward() * ( hitRange and 1 or 0 ) ) - eyePos ):Angle()
                dmginfo:SetDamageForce( hitAng:Forward() * ( damage * 300 ) * LAMBDA_TF2:GetPushScale() * ( 1 / damage * 80 ) )

                local preHitCallback = weapon:GetWeaponAttribute( missed and "OnMiss" or "PreHitCallback" )
                if ( !preHitCallback or preHitCallback( lambda, weapon, target, dmginfo ) != true ) and !missed then
                    target:TakeDamageInfo( dmginfo )
                end
                lambda:SetNextMeleeCrit( TF_CRIT_NONE )
            end

            if !isnumber( hitDelay ) or hitDelay <= 0 then
                hitFunction()
            else
                lambda:SimpleWeaponTimer( hitDelay, hitFunction )
            end
        end
    end

    return true
end

function LAMBDA_TF2:UpdateCritBoostEffect( ent, boostType )        
    if !boostType then
        boostType = TF_CRIT_NONE
        for _, boost in pairs( ent.l_TF_CritBoosts ) do
            local critType = boost.CritType
            if critType > boostType then boostType = critType end
        end
    end

    local boostSnd = ent.l_TF_CritBoostSound
    local critMat = LAMBDA_TF2:GetCritGlowMaterial()
    if boostType != TF_CRIT_NONE then
        if ent.IsLambdaPlayer then
            local wepent = ent:GetWeaponENT()
            if IsValid( wepent ) and !wepent.TF2Data and !ent:IsWeaponMarkedNodraw() then
                wepent:SetMaterial( critMat )
            end
        elseif ent:IsPlayer() then
            for _, weapon in ipairs( ent:GetWeapons() ) do
                if !IsValid( weapon ) then continue end
                weapon:SetMaterial( critMat ) 
            end
        else
            local weapon = ent.GetActiveWeapon
            if weapon then weapon = weapon( ent ) end
            if IsValid( weapon ) then weapon:SetMaterial( critMat ) end
        end

        if !boostSnd then
            boostSnd = LAMBDA_TF2:CreateSound( ent, "weapons/crit_power.wav" )
            ent.l_TF_CritBoostSound = boostSnd
        end

        if boostSnd and !boostSnd:IsPlaying() then
            boostSnd:PlayEx( 0.5, 100 )
        end
    else
        if ent.IsLambdaPlayer then
            local weapon = ent:GetWeaponENT()
            if !ent:IsWeaponMarkedNodraw() and weapon:GetMaterial() == critMat then
                weapon:SetMaterial( "" ) 
            end
        elseif ent:IsPlayer() then
            for _, weapon in ipairs( ent:GetWeapons() ) do
                if !IsValid( weapon ) or weapon:GetMaterial() != critMat then continue end
                weapon:SetMaterial( "" ) 
            end
        else
            local weapon = ent.GetActiveWeapon
            if weapon then weapon = weapon( ent ) end

            if IsValid( weapon ) and weapon:GetMaterial() == critMat then 
                weapon:SetMaterial( "" ) 
            end
        end

        if boostSnd then
            boostSnd:Stop()
            ent.l_TF_CritBoostSound = nil
        end
    end

    ent:SetCritBoostType( boostType )
end

///

local medigunTraceTbl = {
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    filter = { NULL, NULL, NULL }
}

function LAMBDA_TF2:MedigunFire( lambda, weapon, target )
    local wepSrc = lambda:GetAttachmentPoint( "eyes" ).Pos
    local checkRange = ( 450 * ( target == lambda.l_TF_Medigun_HealTarget and 1.2 or 1 ) )
    if wepSrc:DistToSqr( target:NearestPoint( wepSrc ) ) > ( checkRange * checkRange ) then return true end

    medigunTraceTbl.start = wepSrc
    medigunTraceTbl.endpos = target:WorldSpaceCenter()
    medigunTraceTbl.filter[ 1 ] = lambda
    medigunTraceTbl.filter[ 2 ] = weapon
    medigunTraceTbl.filter[ 3 ] = target

    local medigunTr = TraceLine( medigunTraceTbl )
    if medigunTr.Fraction != 1.0 and medigunTr.Entity != target then return true end

    lambda.l_TF_Medigun_HealTarget = target
    lambda.l_TF_Medigun_DetachTime = ( CurTime() + 0.5 )

    return true 
end

function LAMBDA_TF2:MedigunHeal( lambda, weapon, target, chargeRateMult, beamSparks, overhealMult, healRateMult )
    local healSnd = lambda.l_TF_Medigun_HealSound
    if healSnd and !healSnd:IsPlaying() then healSnd:PlayEx( 0.75, 100 ) end

    if CurTime() > lambda.l_TF_Medigun_HealTime then
        LAMBDA_TF2:GiveHealth( target, 1, LAMBDA_TF2:GetMaxBuffedHealth( target, ( overhealMult or 1.5 ) ) )

        if target:GetIsBurning() then
            target:SetFlameRemoveTime( target:GetFlameRemoveTime() - ( 1 / ( target:GetFlameRemoveTime() - CurTime() ) ) )
        end
        local bleedInfo = target.l_TF_BleedInfo
        if bleedInfo and #bleedInfo > 0 then
            for _, info in ipairs( bleedInfo ) do
                info.ExpireTime = ( info.ExpireTime - ( 1 / ( info.ExpireTime - CurTime() ) ) )
            end
        end
        if target.l_TF_CoveredInMilk then
            target.l_TF_CoveredInMilk = ( target.l_TF_CoveredInMilk - ( 1 / ( target.l_TF_CoveredInMilk - CurTime() ) ) )
        end
        if target.l_TF_CoveredInUrine then
            target.l_TF_CoveredInUrine = ( target.l_TF_CoveredInUrine - ( 1 / ( target.l_TF_CoveredInUrine - CurTime() ) ) )
        end
        if target.IsLambdaPlayer and target:IsPanicking() and CurTime() <= target.l_retreatendtime then
            target.l_retreatendtime = ( target.l_retreatendtime - ( 1 / ( target.l_retreatendtime - CurTime() ) ) )
        end

        local healRate = ( LAMBDA_TF2:GetMediGunHealRate( target ) / ( healRateMult or 1.0 ) )
        lambda.l_TF_Medigun_HealTime = ( CurTime() + healRate )
    end

    if target.IsLambdaPlayer then
        target.l_TF_MedicsToIgnoreList[ lambda ] = ( CurTime() + random( 10, 30 ) )
    end

    if !lambda.l_TF_Medigun_ChargeReleased then
        local chargeRate = ( 2.5 * ( chargeRateMult or 1.0 ) )
        if target:Health() > ( target:GetMaxHealth() * 1.425 ) then chargeRate = ( chargeRate * 0.5 ) end
        for _, v in ipairs( GetLambdaPlayers() ) do
            if v == lambda or !v.l_TF_HasMedigunEquipped or v.l_TF_Medigun_HealTarget != target then continue end
            chargeRate = ( chargeRate * 0.5 ) 
            break
        end

        lambda.l_TF_Medigun_ChargeMeter = min( 100, lambda.l_TF_Medigun_ChargeMeter + ( chargeRate * FrameTime() ) )
    end

    if CurTime() > lambda.l_TF_Medigun_BeamUpdateTime then
        beamSparks = ( beamSparks == nil and false or beamSparks )
        
        net.Start( "lambda_tf2_medigun_beameffect" )
            net.WriteEntity( weapon )
            net.WriteEntity( target )
            net.WriteUInt( lambda.l_TF_TeamColor, 1 )
            net.WriteBool( lambda.l_TF_Medigun_ChargeReleased )
            net.WriteBool( beamSparks )
        net.Broadcast()

        lambda.l_TF_Medigun_BeamUpdateTime = ( CurTime() + 0.1 )
    end
end

function LAMBDA_TF2:MedigunDeploy( lambda, weapon )
    LAMBDA_TF2:InitializeWeaponData( lambda, weapon )

    lambda.l_TF_Medigun_HealTarget = nil
    lambda.l_TF_Medigun_LastTarget = nil
    lambda.l_TF_Medigun_HealTime = 0
    lambda.l_TF_Medigun_DetachTime = 0
    lambda.l_TF_Medigun_HealSound = LAMBDA_TF2:CreateSound( weapon, ")weapons/medigun_heal.wav" )
    lambda.l_TF_Medigun_BeamUpdateTime = ( CurTime() + 0.1 )

    weapon:SetSkin( lambda.l_TF_TeamColor )
    weapon:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )

    net.Start( "lambda_tf2_medigun_beameffect" )
        net.WriteEntity( weapon )
        net.WriteEntity( NULL )
    net.Broadcast()
end

function LAMBDA_TF2:MedigunHolster( lambda, weapon )
    if IsValid( lambda.l_TF_Medigun_HealTarget ) then 
        weapon:EmitSound( ")weapons/medigun_heal_detach.wav", nil, nil, nil, CHAN_STATIC )

        net.Start( "lambda_tf2_medigun_beameffect" )
            net.WriteEntity( weapon )
            net.WriteEntity( NULL )
        net.Broadcast()

        lambda.l_nextspeedupdate = 0
    end
    if lambda.l_TF_Medigun_HealSound then 
        lambda.l_TF_Medigun_HealSound:Stop()
    end

    lambda.l_TF_Medigun_HealTarget = nil
    lambda.l_TF_Medigun_LastTarget = nil
    lambda.l_TF_Medigun_HealTime = 0
    lambda.l_TF_Medigun_DetachTime = 0
    lambda.l_TF_Medigun_HealSound = nil
    lambda.l_TF_Medigun_BeamUpdateTime = ( CurTime() + 0.1 )
end

function LAMBDA_TF2:MedigunDetach( lambda, weapon, target )
    if IsValid( target ) then
        if target.IsLambdaPlayer and target:Alive() and target:Health() >= target:GetMaxHealth() and random( 1, 100 ) <= target:GetVoiceChance() and ( target:GetLastSpokenVoiceType() != "assist" or !target:IsSpeaking() ) then
            target:PlaySoundFile( "assist" )
        end

        lambda.l_nextspeedupdate = 0
    end

    net.Start( "lambda_tf2_medigun_beameffect" )
        net.WriteEntity( weapon )
        net.WriteEntity( NULL )
    net.Broadcast()

    weapon:EmitSound( ")weapons/medigun_heal_detach.wav", nil, nil, nil, CHAN_STATIC )
    lambda.l_WeaponUseCooldown = ( CurTime() + 0.5 )

    if lambda.l_TF_Medigun_HealSound then 
        lambda.l_TF_Medigun_HealSound:Stop()
    end

    lambda.l_TF_Medigun_HealTarget = nil
end

///

function LAMBDA_TF2:MinigunDeploy( lambda, weapon )
    weapon.l_WindUpState = 1
    weapon.l_SpinTime = CurTime()
    weapon.l_FireTime = CurTime()
    weapon.l_NextWindUpStateChangeT = CurTime()
    weapon.l_SpinSoundPlayT = CurTime()

    local spinSnd = weapon:GetWeaponAttribute( "SpinSound" )
    if spinSnd then weapon.l_SpinSound = LAMBDA_TF2:CreateSound( weapon, spinSnd ) end

    weapon.l_FireSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "FireSound" ) )
    weapon.l_CritSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "CritFireSound" ) )

    weapon:SetSkin( lambda.l_TF_TeamColor )
    weapon:EmitSound( "weapons/draw_minigun_heavy.wav", nil, nil, 0.5 )
end

function LAMBDA_TF2:MinigunHolster( lambda, weapon )
    weapon:StopSound( weapon:GetWeaponAttribute( "WindUpSound" ) )
    weapon:StopSound( weapon:GetWeaponAttribute( "WindDownSound" ) )

    if weapon.l_FireSound then weapon.l_FireSound:Stop(); weapon.l_FireSound = nil end 
    if weapon.l_SpinSound then weapon.l_SpinSound:Stop(); weapon.l_SpinSound = nil end 
    if weapon.l_CritSound then weapon.l_CritSound:Stop(); weapon.l_CritSound = nil end 
end

function LAMBDA_TF2:MinigunThink( lambda, weapon, isDead )
    if isDead then
        weapon:StopSound( weapon:GetWeaponAttribute( "WindUpSound" ) )

        if weapon.l_WindUpState == 2 then 
            weapon.l_WindUpState = 1 
            weapon.l_SpinTime = CurTime()
            weapon:EmitSound( weapon:GetWeaponAttribute( "WindDownSound" ), nil, nil, nil, CHAN_WEAPON )
        end

        if weapon.l_SpinSound then weapon.l_SpinSound:Stop() end 
        if weapon.l_FireSound then weapon.l_FireSound:Stop() end
        if weapon.l_CritSound then weapon.l_CritSound:Stop() end

        return
    end

    if CurTime() < weapon.l_SpinTime then
        local windUpSnd = weapon:GetWeaponAttribute( "WindUpSound" )

        if weapon.l_WindUpState == 2 and CurTime() > weapon.l_SpinSoundPlayT then
            local spinSnd = weapon.l_SpinSound
            if spinSnd and !spinSnd:IsPlaying() then 
                spinSnd:Play()
                weapon:StopSound( windUpSnd )
            end
        end

        if CurTime() > weapon.l_NextWindUpStateChangeT then
            if weapon.l_WindUpState == 1 then
                weapon:EmitSound( windUpSnd, nil, nil, nil, CHAN_WEAPON )
                weapon.l_SpinSoundPlayT = ( CurTime() + SoundDuration( windUpSnd ) )

                lambda.l_nextspeedupdate = 0
                weapon.l_WindUpState = 2
                weapon.l_NextWindUpStateChangeT = ( CurTime() + weapon:GetWeaponAttribute( "WindUpTime" ) )
            else
                if lambda:IsPanicking() or lambda:InCombat() and !lambda:IsInRange( lambda:GetEnemy(), ( lambda.l_CombatAttackRange or 1500 ) ) then
                    weapon.l_SpinTime = 0
                else
                    if CurTime() < weapon.l_FireTime then 
                        local isCrit = weapon:CalcIsAttackCriticalHelper()
                        local playSnd = ( isCrit and weapon.l_CritSound or weapon.l_FireSound )
                        local stopSnd = ( !isCrit and weapon.l_CritSound or weapon.l_FireSound )

                        if stopSnd and stopSnd:IsPlaying() then stopSnd:Stop() end
                        if playSnd and !playSnd:IsPlaying() then playSnd:Play() end
                    else
                        if weapon.l_FireSound then weapon.l_FireSound:Stop() end
                        if weapon.l_CritSound then weapon.l_CritSound:Stop() end 
                    end
                end
            end
        end
    elseif weapon.l_WindUpState == 2 then
        weapon.l_WindUpState = 1
        weapon.l_NextWindUpStateChangeT = ( CurTime() + 0.5 )

        if weapon.l_SpinSound then weapon.l_SpinSound:Stop() end
        if weapon.l_FireSound then weapon.l_FireSound:Stop() end
        if weapon.l_CritSound then weapon.l_CritSound:Stop() end 

        lambda.l_nextspeedupdate = 0
        weapon:EmitSound( weapon:GetWeaponAttribute( "WindDownSound" ), nil, nil, nil, CHAN_WEAPON )
    end

    if weapon.l_WindUpState == 2 then
        local speedMult = weapon:GetWeaponAttribute( "SpinSpeedScale", 1.0 )
        lambda.l_WeaponSpeedMultiplier = ( 0.37 * speedMult )
    else
        lambda.l_WeaponSpeedMultiplier = 0.77
    end
end

function LAMBDA_TF2:MinigunFire( lambda, weapon, target )
    weapon.l_SpinTime = ( CurTime() + Rand( 1, 4 ) )
    if weapon.l_WindUpState != 2 or CurTime() <= weapon.l_NextWindUpStateChangeT then return end

    if !LAMBDA_TF2:WeaponAttack( lambda, weapon, target ) then return end
    
    local rateoffire = weapon:GetWeaponAttribute( "RateOfFire" )
    weapon.l_FireTime = ( CurTime() + rateoffire )

    local curROF = 0
    local rateOfFire = ( rateoffire / 4 )
    for i = 1, weapon:GetWeaponAttribute( "ProjectileCount" ) do
        lambda:SimpleWeaponTimer( curROF, function() 
            lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2 )
            lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2, true )

            LAMBDA_TF2:CreateMuzzleFlash( weapon, 7 )
            LAMBDA_TF2:CreateShellEject( weapon, "RifleShellEject" ) 
        end )

        curROF = ( curROF + rateOfFire )
    end
end

///

local rayWorldTbl = {}
local dmgTraceTbl = { mask = ( MASK_SOLID + CONTENTS_HITBOX ) }

local function OnFlameThink( self )
    local selfPos = self:GetPos()
    if CurTime() >= self.l_RemoveTime or selfPos:IsUnderwater() then
        self:Remove()
        return
    end

    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()
    local prevPos = self.l_PreviousPos

    if selfPos != prevPos then
        local weapon = self:GetOwner()
        local attacker = self.l_Attacker
        local initialPos = self.l_InitialPos

        if IsValid( attacker ) then
            rayWorldTbl.start = initialPos
            rayWorldTbl.endpos = selfPos
            rayWorldTbl.mins = mins
            rayWorldTbl.maxs = maxs

            rayWorldTbl.filter = self    
            rayWorldTbl.mask = MASK_SOLID
            rayWorldTbl.collisiongroup = COLLISION_GROUP_DEBRIS

            local trWorld = TraceHull( rayWorldTbl )
            local hitWorld = ( trWorld.StartSolid or trWorld.Fraction < 1 )

            for _, ent in ipairs( FindAlongRay( prevPos, selfPos, mins, maxs ) ) do
                if ent == self or ent == attacker or self.l_EntitiesBurnt[ ent ] then continue end
                if attacker.IsLambdaPlayer and LAMBDA_TF2:IsValidCharacter( ent ) and !attacker:CanTarget( ent ) then continue end

                if hitWorld then
                    rayWorldTbl.filter = NULL 
                    rayWorldTbl.mask = ( MASK_SOLID + CONTENTS_HITBOX )
                    rayWorldTbl.collisiongroup = COLLISION_GROUP_NONE

                    local trEnt = TraceHull( rayWorldTbl )
                    if trEnt.Fraction >= trWorld.Fraction then continue end
                end

                local distance = selfPos:Distance( initialPos )
                local damage = max( 1, self.l_DmgAmount * LAMBDA_TF2:RemapClamped( distance, 175, 350, 1, 0.7 ) )

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker( attacker )
                dmginfo:SetInflictor( weapon )
                dmginfo:SetDamage( damage )
                dmginfo:SetDamageType( self.l_DmgType )
                dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BURNING )
                dmginfo:SetDamagePosition( ent:WorldSpaceCenter() + VectorRand( -5, 5 ) )
                dmginfo:SetReportedPosition( attacker:GetPos() )

                local onCollide = weapon:GetWeaponAttribute( "OnFlameCollide" )
                if onCollide and onCollide( self, ent, dmginfo ) == true then continue end

                dmgTraceTbl.start = self:WorldSpaceCenter()
                dmgTraceTbl.endpos = ent:WorldSpaceCenter()
                dmgTraceTbl.filter = self
                dmgTraceTbl.collisiongroup = COLLISION_GROUP_NONE

                self.l_EntitiesBurnt[ ent ] = true
                ent:DispatchTraceAttack( dmginfo, TraceLine( dmgTraceTbl ), self:GetAbsVelocity() )
            end

            if hitWorld then self:Remove() end
        end
    end

    local baseVel = ( self.l_BaseVelocity * 0.87 )
    self.l_BaseVelocity = baseVel

    local newVel = ( baseVel + ( vector_up * 50 ) + self.l_AttackerVelocity )
    self:SetAbsVelocity( newVel )

    self.l_PreviousPos = selfPos

    self:NextThink( CurTime() )
    return true
end

function LAMBDA_TF2:FlamethrowerDeploy( lambda, weapon )
    weapon.l_FireStartSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "StartFireSound" ) )
    weapon.l_FireLoopSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "FireSound" ) )
    weapon.l_FireCritSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "CritFireSound" ) )
    weapon.l_FireEndSound = LAMBDA_TF2:CreateSound( weapon, weapon:GetWeaponAttribute( "EndFireSound" ) )
    
    weapon.l_FireState = 0
    weapon.l_NextFireStateUpdateT = CurTime()

    weapon.l_FireAttackTime = false
    weapon.l_FireDirection = lambda:GetForward()
    weapon.l_FireShootTime = CurTime()

    local pilotSnd = LAMBDA_TF2:CreateSound( weapon, "weapons/flame_thrower_pilot.wav" )
    pilotSnd:PlayEx( 0.25, 100 )
    weapon.l_FirePilotSound = pilotSnd

    weapon:SetSkin( lambda.l_TF_TeamColor )
    weapon:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
end

function LAMBDA_TF2:FlamethrowerHolster( lambda, weapon )
    LAMBDA_TF2:StopParticlesNamed( weapon, "flamethrower" )
    
    if weapon.l_FirePilotSound then weapon.l_FirePilotSound:Stop(); weapon.l_FirePilotSound = nil end 
    if weapon.l_FireStartSound then weapon.l_FireStartSound:Stop(); weapon.l_FireStartSound = nil end 
    if weapon.l_FireLoopSound then weapon.l_FireLoopSound:Stop(); weapon.l_FireLoopSound = nil end 
    if weapon.l_FireCritSound then weapon.l_FireCritSound:Stop(); weapon.l_FireCritSound = nil end 
    if weapon.l_FireEndSound then weapon.l_FireEndSound:Stop(); weapon.l_FireEndSound = nil end 
end

function LAMBDA_TF2:FlamethrowerFire( lambda, weapon, target )
    weapon.l_FireAttackTime = CurTime() + Rand( 0.25, 0.66 )
    weapon.l_FireDirection = ( target:WorldSpaceCenter() - lambda:WorldSpaceCenter() ):GetNormalized()
end

function LAMBDA_TF2:FlamethrowerThink( lambda, weapon, isDead )
    if isDead then
        weapon.l_FireAttackTime = false
        weapon.l_FireState = 0
        weapon.l_NextFireStateUpdateT = CurTime()
        LAMBDA_TF2:StopParticlesNamed( weapon, "flamethrower" )

        if weapon.l_FirePilotSound then weapon.l_FirePilotSound:Stop() end 
        if weapon.l_FireStartSound then weapon.l_FireStartSound:Stop() end 
        if weapon.l_FireLoopSound then weapon.l_FireLoopSound:Stop() end 
        if weapon.l_FireCritSound then weapon.l_FireCritSound:Stop() end 
        if weapon.l_FireEndSound then weapon.l_FireEndSound:Stop() end 
    else
        if weapon.l_FireAttackTime then 
            if CurTime() > weapon.l_FireAttackTime then
                if weapon.l_FirePilotSound then weapon.l_FirePilotSound:Stop() end
                if weapon.l_FireStartSound then weapon.l_FireStartSound:Stop() end 
                if weapon.l_FireLoopSound then weapon.l_FireLoopSound:Stop() end
                if weapon.l_FireCritSound then weapon.l_FireCritSound:Stop() end
                if weapon.l_FireEndSound and !weapon.l_FireEndSound:IsPlaying() then weapon.l_FireEndSound:Play() end 
                
                weapon.l_FireAttackTime = false
                weapon.l_FireState = 0
                weapon.l_NextFireStateUpdateT = CurTime()
                LAMBDA_TF2:StopParticlesNamed( weapon, "flamethrower" )
            else
                local isCrit = weapon:CalcIsAttackCriticalHelper()

                if CurTime() > weapon.l_NextFireStateUpdateT then
                    if weapon.l_FireState == 0 then
                        if weapon.l_FireStartSound and !weapon.l_FireStartSound:IsPlaying() then weapon.l_FireStartSound:Play() end 
                        if weapon.l_FireEndSound then weapon.l_FireEndSound:Stop() end 
                        
                        weapon.l_FireState = 1
                        weapon.l_NextFireStateUpdateT = ( CurTime() + SoundDuration( weapon:GetWeaponAttribute( "StartFireSound" ) ) )
                        ParticleEffectAttach( "flamethrower", PATTACH_POINT_FOLLOW, weapon, 1 )
                    else
                        local playSnd = ( isCrit and weapon.l_FireCritSound or weapon.l_FireLoopSound )
                        local stopSnd = ( !isCrit and weapon.l_FireCritSound or weapon.l_FireLoopSound )

                        if playSnd and !playSnd:IsPlaying() then playSnd:Play() end
                        if stopSnd and stopSnd:IsPlaying() then stopSnd:Stop() end
                    end
                end

                if CurTime() > weapon.l_FireShootTime then
                    local fireInterval = weapon:GetWeaponAttribute( "RateOfFire" )
                    weapon.l_FireShootTime = ( CurTime() + fireInterval )

                    local damagePerSec = weapon:GetWeaponAttribute( "Damage" )
                    local totalDamage = ( damagePerSec * fireInterval )

                    local dmgTypes = weapon:GetWeaponAttribute( "DamageType" )
                    if isCrit then dmgTypes = ( dmgTypes + DMG_CRITICAL ) end

                    local ene = lambda:GetEnemy()
                    local eyes = lambda:GetAttachmentPoint( "eyes" )

                    local srcPos = eyes.Pos
                    local firePos = ( LambdaIsValid( ene ) and ene:WorldSpaceCenter() or ( srcPos + lambda:GetForward() * 96 ) )

                    local fireAng = ( firePos - srcPos ):Angle()
                    srcPos = ( srcPos + fireAng:Right() * 12 )

                    local flameEnt = ents_Create( "base_anim" )
                    flameEnt:SetPos( srcPos )
                    flameEnt:SetAngles( fireAng )
                    flameEnt:SetOwner( weapon )
                    flameEnt:Spawn()

                    flameEnt:SetNoDraw( true )
                    flameEnt:DrawShadow( false )

                    LAMBDA_TF2:TakeNoDamage( flameEnt )
                    flameEnt:SetSolid( SOLID_NONE )
                    flameEnt:SetSolidFlags( FSOLID_NOT_SOLID )
                    flameEnt:SetCollisionGroup( COLLISION_GROUP_NONE )
                    flameEnt:SetMoveType( MOVETYPE_NOCLIP )
                    flameEnt:AddEFlags( EFL_NO_WATER_VELOCITY_CHANGE )

                    local boxSize = Vector( 12, 12, 12 )
                    flameEnt:SetCollisionBounds( -boxSize, boxSize )

                    flameEnt.l_InitialPos = srcPos
                    flameEnt.l_PreviousPos = flameEnt.l_InitialPos
                    flameEnt.l_Attacker = lambda
                    flameEnt.l_DmgType = dmgTypes
                    flameEnt.l_DmgAmount = totalDamage
                    flameEnt.l_AttackerVelocity = lambda.loco:GetVelocity()
                    flameEnt.l_RemoveTime = ( CurTime() + ( 0.5 * Rand( 0.9, 1.1 ) ) )
                    flameEnt.l_EntitiesBurnt = {}

                    local speed = 2300
                    local velocity = ( fireAng:Forward() * speed )
                    flameEnt.l_BaseVelocity = ( velocity + VectorRand( -speed * 0.05, speed * 0.05 ) )
                    flameEnt:SetAbsVelocity( flameEnt.l_BaseVelocity )

                    flameEnt.Draw = function() end
                    flameEnt.Think = OnFlameThink
                end
            end
        end
    end
end

///

function LAMBDA_TF2:CreateMedkit( pos, model, healRatio, respawn, removeTime )
    local medkit = ents_Create( "lambda_tf_healthkit_base" )
    if !IsValid( medkit ) then return end

    if model then medkit.Model = model end
    if healRatio then medkit.HealRatio = healRatio end
    if removeTime then medkit.RemoveTime = removeTime end
    medkit.CanRespawn = ( respawn or false )

    medkit:SetPos( pos )
    medkit:Spawn()

    return medkit
end

function LAMBDA_TF2:CreateAmmobox( pos, model, refillRatio, respawn, removeTime )
    local ammobox = ents_Create( "lambda_tf_ammobox_base" )
    if !IsValid( ammobox ) then return end

    if model then ammobox.Model = model end
    if refillRatio then ammobox.RefillRatio = refillRatio end
    if removeTime then ammobox.RemoveTime = removeTime end
    ammobox.CanRespawn = ( respawn or false )

    ammobox:SetPos( pos )
    ammobox:Spawn()

    return ammobox
end

///

function LAMBDA_TF2:GetDamageForce( target, damage, scale )
    local size = ( target:OBBMaxs() - target:OBBMins() )
    return min( 1000, damage * ( 73728 / ( size.x * size.y * size.z ) ) * scale )
end

local JUMP_MIN_SPEED = 268.3281572999747

function LAMBDA_TF2:ApplyAirBlastImpulse( target, impulse )
    local vecForce = impulse
    local scale = ( target.l_TF_AirBlastVulnerability or 1.0 )

    vecForce = ( vecForce * scale )
    if target:OnGround() and vecForce.z < JUMP_MIN_SPEED then
        vecForce.z = JUMP_MIN_SPEED;
    end

    if target.l_TF_SniperShieldType == 2 then
        vecForce = ( vecForce * 0.8 )  
    end

    if target:IsNextBot() then
        target.loco:Jump()
        local entVel = target.loco:GetVelocity(); entVel.z = 0
        target.loco:SetVelocity( entVel + vecForce )
    else
        target:RemoveFlags( FL_ONGROUND )
        target:SetVelocity( vecForce )
    end
end

function LAMBDA_TF2:ApplyPushFromDamage( target, dmginfo, dir )
    local vecForce = ( dir * -LAMBDA_TF2:GetDamageForce( target, dmginfo:GetDamage(), 6 ) )

    local inflictor = dmginfo:GetInflictor()
    if IsValid( inflictor ) then 
        if inflictor.l_TF_HasKnockBack then 
            if vecForce.z < 0 then vecForce.z = 0 end
            inflictor.l_TF_HasKnockBack = false
        end

        if inflictor.l_TF_CausesAirBlast then
            local airForce = -LAMBDA_TF2:GetDamageForce( target, 100, 6 )
            LAMBDA_TF2:ApplyAirBlastImpulse( target, airForce * dir )
            vecForce:Zero()
        end 
    end

    if target.l_TF_SniperShieldType == 2 then
        vecForce = ( vecForce * 0.8 )  
    end

    if target:IsNextBot() then
        if !target.loco:IsAttemptingToMove() then
            target:SetPos( target:GetPos() + vector_up * 1 )
        end

        local heightDiff = ( ( target:GetPos() + vecForce ).z - target:GetPos().z )
        if target.IsLambdaPlayer and heightDiff >= 64 then target.loco:Jump() end
        
        local entVel = target.loco:GetVelocity(); entVel.z = 0
        target.loco:SetVelocity( entVel + vecForce )
    else
        target:SetVelocity( vecForce )
    end
end

local function CalcIsAttackCriticalHelper( self )
    local owner = self.l_TF_Owner
    if owner:GetCritBoostType() == TF_CRIT_FULL then return true end

    local remapCritMul = LAMBDA_TF2:RemapClamped( owner.l_TF_CritMult, 0, 255, 1, 4 )
    local randChance = random( 0, 9999 )
    local randCritsAllowed = GetConVar( "lambdaplayers_tf2_allowrandomcrits" ):GetBool()

    if self:GetWeaponAttribute( "IsMelee" ) then
        if owner:GetNextMeleeCrit() == TF_CRIT_FULL then return true end
        if !self:GetWeaponAttribute( "RandomCrits", true ) or !randCritsAllowed then return false end
        return ( randChance < ( TF_DAMAGE_CRIT_CHANCE_MELEE * remapCritMul * 9999 ) )
    end

    local isRapidFire = self:GetWeaponAttribute( "UseRapidFireCrits" )
    if isRapidFire and CurTime() < self.l_TF_CritTime then return true end
    if !self:GetWeaponAttribute( "RandomCrits", true ) or !randCritsAllowed then return false end

    if isRapidFire then
        if CurTime() < ( self.l_TF_LastRapidFireCritCheckT + 1 ) then return false end
        self.l_TF_LastRapidFireCritCheckT = CurTime()

        local totalCritChance = Clamp( TF_DAMAGE_CRIT_CHANCE_RAPID * remapCritMul, 0.01, 0.99 )
        local critDuration = TF_DAMAGE_CRIT_DURATION_RAPID
        local nonCritDuration = ( ( critDuration / totalCritChance ) - critDuration )
        local startCritChance = ( 1 / nonCritDuration )

        local isCrit = ( randChance < ( startCritChance * 9999 ) )
        if isCrit then 
            self.l_TF_CritTime = ( CurTime() + TF_DAMAGE_CRIT_DURATION_RAPID ) 
            return true
        end
    end
    
    return ( randChance < ( TF_DAMAGE_CRIT_CHANCE * remapCritMul * 9999 ) )
end

local function GetWeaponAttribute( self, attribute, fallback )
    local attributeVal = self.TF2Data[ attribute ]
    return ( attributeVal == nil and fallback or attributeVal )
end

local function SetWeaponAttribute( self, attribute, value )
    self.TF2Data[ attribute ] = value
end

function LAMBDA_TF2:InitializeWeaponData( lambda, weapon )
    weapon.TF2Data = {}

    weapon:SetSkin( 0 )
    for _, bg in ipairs( weapon:GetBodyGroups() ) do
        weapon:SetBodygroup( bg.id, 0 )
    end

    weapon.l_TF_CritTime = CurTime()
    weapon.l_TF_LastFireTime = CurTime()
    weapon.l_TF_LastRapidFireCritCheckT = CurTime()

    weapon.SetWeaponAttribute = SetWeaponAttribute
    weapon.GetWeaponAttribute = GetWeaponAttribute
    weapon.CalcIsAttackCriticalHelper = CalcIsAttackCriticalHelper
end

function LAMBDA_TF2:Stun( target, time, freeze )
    local expireTime = ( CurTime() + time )

    if !target.l_TF_IsStunned then
        target.l_TF_IsStunned = expireTime
        target.l_TF_JustGotStunned = true
        target.l_TF_StunMovement = ( freeze or false ) 

        if target.IsLambdaPlayer then
            if target:GetState() != "Stunned" then
                target.l_TF_PreStunState = target:GetState()
                if freeze then target:SetState( "Stunned" ) end
                target:CancelMovement()
            end

            if target:GetIsShieldCharging() then
                target:SetShieldChargeMeter( 0 )
            end

            target.l_nextspeedupdate = 0
        elseif target:IsPlayer() then
            target:SetWalkSpeed( target:GetWalkSpeed() * 0.75 )
            target:SetRunSpeed( target:GetRunSpeed() * 0.75 )
            target:SetDuckSpeed( target:GetDuckSpeed() * 0.75 )
            target:SetSlowWalkSpeed( target:GetSlowWalkSpeed() * 0.75 )

            if freeze then target:Freeze( true ) end
        end

        net.Start( "lambda_tf2_stuneffect" )
            net.WriteEntity( target )
        net.Broadcast()
    elseif expireTime > target.l_TF_IsStunned then
        target.l_TF_IsStunned = expireTime
        target.l_TF_JustGotStunned = true
        target.l_TF_StunMovement = ( freeze or false ) 
    end 

    if freeze then
        target.l_TF_StunStateChangeT = 0
        target:EmitSound( "player/pl_impact_stun_range.wav", 95, nil, nil, CHAN_STATIC )
    else
        target:EmitSound( "player/pl_impact_stun.wav", 85, nil, nil, CHAN_STATIC )
    end
end

function LAMBDA_TF2:RadiusDamageInfo( dmginfo, pos, radius, impactEnt, ignoreEnt )
    if radius <= 0 then return end
    
    local radSqr = ( radius * radius )

    local baseDamage = dmginfo:GetDamage()
    local baseDamageForce = dmginfo:GetDamageForce()
    local baseDamagePos = dmginfo:GetDamagePosition()

    local fallOff = ( baseDamage / radius )
    if dmginfo:IsDamageType( DMG_RADIUS_MAX ) then
        fallOff = 0
    elseif dmginfo:IsDamageType( DMG_HALF_FALLOFF ) then
        fallOff = 0.5
    end

    explosionTrTbl.start = pos

    for _, ent in ipairs( FindInSphere( pos, radius ) ) do
        if ent == ignoreEnt or !LambdaIsValid( ent ) or ent:GetInternalVariable( "m_takedamage" ) == 0 then continue end

        local nearPoint = ent:NearestPoint( pos )
        if nearPoint:DistToSqr( pos ) > radSqr then continue end
        
        local entPos = ent:WorldSpaceCenter()
        explosionTrTbl.endpos = entPos
        
        local tr = TraceLine( explosionTrTbl )
        if tr.Fraction != 1.0 and tr.Entity != ent then continue end

        local distToEnt
        if IsValid( impactEnt ) and ent == impactEnt then
            distToEnt = 0
        elseif LAMBDA_TF2:IsValidCharacter( ent ) then
            distToEnt = min( pos:Distance( entPos ), pos:Distance( ent:GetPos() ) )
        else
            distToEnt = pos:Distance( tr.HitPos )
        end

        local adjustedDamage = LAMBDA_TF2:RemapClamped( distToEnt, 0, radius, baseDamage, baseDamage * fallOff )
        if adjustedDamage <= 0 then continue end

        if tr.StartSolid then
            tr.HitPos = pos
            tr.Fraction = 0
        end

        dmginfo:SetDamage( adjustedDamage )

        local dirToEnt = ( entPos - pos ):GetNormalized()
        if baseDamageForce:IsZero() or baseDamagePos:IsZero() then
            dmginfo:SetDamageForce( dirToEnt * ( min( baseDamage * 300, 30000 ) * Rand( 0.85, 1.15 ) ) * LAMBDA_TF2:GetPushScale() * 1.5 )
        else
            dmginfo:SetDamageForce( dirToEnt * ( baseDamageForce:Length() * fallOff ) )
        end
        dmginfo:SetDamagePosition( pos )

        if tr.Fraction != 1 and tr.Entity == ent then
            ent:DispatchTraceAttack( dmginfo, tr, dirToEnt )
        else
            ent:TakeDamageInfo( dmginfo )
        end
    end
end

LAMBDA_TF2.TrailList = LAMBDA_TF2.TrailList or {}
LAMBDA_TF2.NextTrailListCheckT = CurTime()

function LAMBDA_TF2:CreateSpriteTrailEntity( color, additive, startWidth, endWidth, lifeTime, texture, pos, parent )
    local trailEnt = ents_Create( "base_anim" )
    if !IsValid( trailEnt ) then return end

    trailEnt:SetPos( pos )

    if IsValid( parent ) then
        trailEnt.l_HasParent = true
        trailEnt:SetParent( parent )
    end
    
    trailEnt:Spawn()
    trailEnt:SetNoDraw( true )
    trailEnt:DrawShadow( false )
    trailEnt:SetSolid( SOLID_NONE )
    trailEnt:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    trailEnt:SetMoveType( MOVETYPE_NONE )
    LAMBDA_TF2:TakeNoDamage( trailEnt )

    local trail = SpriteTrail( trailEnt, 0, ( color or color_white ), ( additive or true ), startWidth, endWidth, lifeTime, ( 1 / ( startWidth + endWidth ) * 0.5 ), texture )
    trailEnt:DeleteOnRemove( trail )

    LAMBDA_TF2.TrailList[ #LAMBDA_TF2.TrailList + 1 ] = trailEnt
    return trailEnt
end

function LAMBDA_TF2:CreateCritBulletTracer( startPos, endPos, color, time, size )
    time = time or 0.2
    size = size or 0.66

    local critTracer = LAMBDA_TF2:CreateSpriteTrailEntity( color, nil, size, size, time, "trails/smoke", startPos )
    if !IsValid( critTracer ) then return end

    SafeRemoveEntityDelayed( critTracer, time * 2 )
    SimpleTimer( FrameTime(), function()
        if !IsValid( critTracer ) then return end
        critTracer:SetPos( endPos )
    end )
end

function LAMBDA_TF2:GetTeamColor( ent )
    if ent:IsPlayer() then
        local plyColor = string_Explode( " ", ent:GetInfo( "cl_playercolor" ) )
        return ( ( plyColor[ 3 ] > plyColor[ 1 ] ) and 1 or 0 )
    end

    return ( ent.l_TF_TeamColor or 1 )
end

function LAMBDA_TF2:CreateBloodParticle( pos, ang, parent )
    local bloodParticle = ents_Create( "info_particle_system" )
    bloodParticle:SetKeyValue( "effect_name", "blood_impact_red_01" )
    bloodParticle:SetPos( pos )
    bloodParticle:SetAngles( ang )
    bloodParticle:SetParent( parent )
    bloodParticle:Spawn()
    bloodParticle:Activate()
    bloodParticle:Fire( "Start" )
    bloodParticle:Fire( "Kill", nil, 0.4 )
end

local headGibAng = Angle( 90, 0, -90 )

function LAMBDA_TF2:CreateGib( pos, ang, force, mdl )
    local headGib = ents_Create( "prop_physics" )
    headGib:SetModel( mdl )
    headGib:SetPos( pos )
    headGib:SetAngles( ang + headGibAng )
    headGib:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    headGib:Spawn()
    SafeRemoveEntityDelayed( headGib, 15 )

    local phys = headGib:GetPhysicsObject()
    if IsValid( phys ) then
        headGib:AddCallback( "PhysicsCollide", function( self, data )
            if data.Speed <= 50 or data.HitEntity != Entity( 0 ) then return end
            local hitPos, hitNormal = data.HitPos, data.HitNormal

            LAMBDA_TF2:CreateBloodParticle( hitPos, ( hitPos - self:GetPos() ):Angle(), self )
            Decal( "Blood", hitPos + hitNormal, hitPos - hitNormal )
            self:EmitSound( "Flesh_Bloody.ImpactHard" )
        end )

        if force then
            local applyForce = ( vector_up * 2000 + force )
            phys:ApplyForceCenter( applyForce ) 
        end
    end

    return headGib
end

function LAMBDA_TF2:GetMaxBuffedHealth( ent, ratio )
    ratio = ( ratio or 1.5 )
    return Round( ( ( ent:GetMaxHealth() * ratio ) / 5 ) * 5 )
end

function LAMBDA_TF2:GetTimeSinceLastDamage( ent )
    return ( CurTime() - ent.l_TF_LastTakeDamageTime )
end

function LAMBDA_TF2:GetMediGunHealRate( target )
    local healRate = ( 24 * LAMBDA_TF2:RemapClamped( LAMBDA_TF2:GetTimeSinceLastDamage( target ), 10, 15, 1, 3 ) )
    healRate = ( healRate * target.l_TF_HealRateMultiplier )
    if target:GetIsBurning() then healRate = ( healRate * 0.5 ) end
    return ( 1 / healRate )
end

function LAMBDA_TF2:GiveHealth( target, amount, maxHeal )
    local maxHealth = target:GetMaxHealth()
    local maxGive = ( maxHeal == nil and LAMBDA_TF2:GetMaxBuffedHealth( target ) or ( maxHeal == false and maxHealth or maxHeal ) )

    local curHealth = target:Health()
    target.l_TF_OverhealDecreaseStartT = ( CurTime() + 0.1 )
    if curHealth >= maxGive then return 0 end

    local preHP = target:Health()
    target:SetHealth( Round( min( curHealth + amount, maxGive ) ) )
    target.l_TF_HasOverheal = ( target:Health() > maxHealth )

    return ( target:Health() - preHP )
end

function LAMBDA_TF2:CreateBonemergedModel( parent, model, dropOnDeath )
    local ent = ents_Create( "base_anim" )
    ent:SetModel( model )
    ent:SetPos( parent:GetPos() )
    ent:SetAngles( parent:GetAngles() )
    ent:SetOwner( parent )
    ent:SetParent( parent )
    ent:Spawn()
    ent:AddEffects( EF_BONEMERGE )
    LAMBDA_TF2:TakeNoDamage( ent )

    if dropOnDeath then
        parent.l_TF_DropOnDeathEntities[ #parent.l_TF_DropOnDeathEntities + 1 ] = ent
    end

    parent:DeleteOnRemove( ent )
    return ent
end

local shieldTbl = {
    { "models/lambdaplayers/tf2/weapons/w_targe.mdl", "lambdaplayers_weaponkillicons_tf2_chargintarge" },
    { "models/lambdaplayers/tf2/weapons/w_persian_shield.mdl", "lambdaplayers_weaponkillicons_tf2_splendidscreen" },
    { "models/lambdaplayers/tf2/weapons/w_wheel_shield.mdl", "lambdaplayers_weaponkillicons_tf2_tideturner" },
}

function LAMBDA_TF2:GiveRemoveChargeShield( lambda, givenByWeapon )
    lambda.l_TF_Shield_IsEquipped = !lambda.l_TF_Shield_IsEquipped
    
    local shieldEnt = lambda.l_TF_Shield_Entity
    if lambda.l_TF_Shield_IsEquipped then
        local shieldType = random( #shieldTbl )
        lambda.l_TF_Shield_Type = shieldType

        shieldEnt = LAMBDA_TF2:CreateBonemergedModel( lambda, shieldTbl[ shieldType ][ 1 ], true )
        shieldEnt.IsLambdaWeapon = true
        shieldEnt.l_killiconname = shieldTbl[ shieldType ][ 2 ]
        shieldEnt.l_TF_GivenByWeapon = ( givenByWeapon and lambda:GetWeaponName() )

        lambda.l_TF_Shield_Entity = shieldEnt
    elseif IsValid( shieldEnt ) then
        shieldEnt:Remove()
    end

    return shieldEnt
end

function LAMBDA_TF2:RecordDamageEvent( attacker, dmginfo, kill, victimPrevHealth )
    if #attacker.l_TF_DamageEvents >= 128 then table_remove( attacker.l_TF_DamageEvents, 1 ) end

    local damage = dmginfo:GetBaseDamage()
    if kill then damage = min( damage, victimPrevHealth ) end
    local damageCritScale = ( dmginfo:IsDamageType( DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE ) and 0 or 1 )

    attacker.l_TF_DamageEvents[ #attacker.l_TF_DamageEvents ] = {
        Damage = damage,
        Time = CurTime(),
        DamageCriticalScale = damageCritScale
    }
end

function LAMBDA_TF2:AddCritBoost( ent, name, critType, duration )
    ent.l_TF_CritBoosts[ name ] = {
        CritType = critType,
        Duration = ( CurTime() + duration )
    }
    LAMBDA_TF2:UpdateCritBoostEffect( ent )
end

function LAMBDA_TF2:HasCritBoost( ent, name )
    return ( ent.l_TF_CritBoosts[ name ] != nil )
end

function LAMBDA_TF2:RemoveCritBoost( ent, name )
    ent.l_TF_CritBoosts[ name ] = nil
    LAMBDA_TF2:UpdateCritBoostEffect( ent )
end

local calcMoveTrTbl = {}

function LAMBDA_TF2:CalculateEntityMovePosition( ent, distance, speed, offsetScale, offsetPos )
    offsetPos = ( offsetPos or ent:GetPos() )
    local mins, maxs = ent:GetCollisionBounds()

    local entVel = ( ( ent:IsNextBot() and ent.loco or ent ):GetVelocity() * ( ( distance * offsetScale ) / speed )  )
    local entVelPos = ( offsetPos + entVel )
    if ent:OnGround() and entVelPos.z > offsetPos.z then entVelPos.z = offsetPos.z end

    calcMoveTrTbl.start = offsetPos
    calcMoveTrTbl.endpos = entVelPos
    calcMoveTrTbl.filter = ent
    calcMoveTrTbl.collisiongroup = ent:GetCollisionGroup()
    calcMoveTrTbl.mins = mins
    calcMoveTrTbl.maxs = maxs

    return TraceHull( calcMoveTrTbl ).HitPos
end

local function OnRocketTouch( rocket, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    
    local touchTr = rocket:GetTouchTrace()
    if touchTr.HitSky then rocket:Remove() return end
    local hitPos, hitNormal = rocket:WorldSpaceCenter(), touchTr.HitNormal
    
    local owner = rocket:GetOwner()
    if IsValid( owner ) then
        if ent == owner then return end

        local dmginfo = DamageInfo()
        dmginfo:SetDamage( rocket.l_ExplodeDamage )
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( rocket )
        
        local dmgTypes = ( DMG_BLAST + DMG_USEDISTANCEMOD + DMG_HALF_FALLOFF )
        if rocket.l_ExplodeCrit == 2 then
            dmgTypes = ( dmgTypes + DMG_CRITICAL )
        elseif rocket.l_ExplodeCrit == 1 then
            dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
        end
        dmginfo:SetDamageType(dmgTypes )

        LAMBDA_TF2:RadiusDamageInfo( dmginfo, hitPos, rocket.l_ExplodeRadius, ent )
    end

    ParticleEffect( "ExplosionCore_Wall", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )
    if ent:IsWorld() then Decal( "Scorch", hitPos + hitNormal, hitPos - hitNormal ) end

    local snds = rocket.l_ExplodeSound
    if istable( snds ) then snds = snds[ random( #snds ) ] end
    rocket:EmitSound( snds, 85, nil, nil, CHAN_WEAPON )
    rocket:Remove()
end

function LAMBDA_TF2:CreateRocketProjectile( pos, ang, owner, wepent, critical, attributes )
    attributes = attributes or {}
    
    local rocket = ents_Create( "base_anim" )
    rocket:SetPos( pos )
    rocket:SetAngles( ang )
    rocket:SetModel( attributes.Model or "models/weapons/w_models/w_rocket.mdl" )
    rocket:SetOwner( owner )
    rocket:Spawn()

    rocket:SetSolid( SOLID_BBOX )
    rocket:SetMoveType( MOVETYPE_FLY )
    rocket:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
    
    local flySpeed = ( attributes.Speed or 1100 )
    rocket:SetVelocity( ang:Forward() * flySpeed )
    
    rocket:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
    rocket:SetCollisionBounds( -vector_origin, vector_origin )
    LAMBDA_TF2:TakeNoDamage( rocket )

    ParticleEffectAttach( "rockettrail", PATTACH_POINT_FOLLOW, rocket, 1 )

    rocket.l_IsTFWeapon = true
    rocket.l_ExplodeDamage = ( attributes.Damage or 55 )
    rocket.l_ExplodeRadius = ( attributes.Radius or 146 )
    rocket.l_ExplodeSound = ( attributes.Sound or {
        ")lambdaplayers/tf2/explode1.mp3",
        ")lambdaplayers/tf2/explode2.mp3",
        ")lambdaplayers/tf2/explode3.mp3"
    } )
    rocket.l_LambdaWeapon = wepent
    rocket.l_OnDealDamage = attributes.OnDealDamage
    rocket.l_FlySpeed = flySpeed

    rocket.IsLambdaWeapon = true
    rocket.l_killiconname = ( attributes.KillIcon or wepent.l_killiconname )

    local critType = owner:GetCritBoostType()
    if critical then critType = TF_CRIT_FULL end
    rocket.l_ExplodeCrit = critType

    if critType == TF_CRIT_FULL then
        ParticleEffectAttach( "critical_rocket_" .. ( owner.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_POINT_FOLLOW, rocket, 1 )
    end

    rocket.Touch = OnRocketTouch
    return rocket
end

function LAMBDA_TF2:MakeBleed( ent, attacker, weapon, bleedingTime, bleedDmg, permaBleeding )
    bleedDmg = ( bleedDmg or 4 )
    permaBleed = ( permaBleed == nil and false or permaBleed )

    local expireTime = ( CurTime() + bleedingTime )
    for _, info in ipairs( ent.l_TF_BleedInfo ) do
        if !IsValid( info.Attacker ) or info.Attacker != attacker or !IsValid( info.Weapon ) or info.Weapon != weapon then continue end
        if expireTime <= info.ExpireTime then continue end
        info.ExpireTime = expireTime; return
    end

    local inflictor = ents_Create( "base_anim" )
    inflictor:SetPos( ent:GetPos() )
    inflictor:SetParent( ent )
    inflictor:Spawn()
    inflictor:SetNoDraw( true )
    inflictor:DrawShadow( false )
    inflictor:SetSolid( SOLID_NONE )
    inflictor:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
    LAMBDA_TF2:TakeNoDamage( inflictor )
 
    inflictor.IsLambdaWeapon = true
    inflictor.l_IsTFBleedInflictor = true
    inflictor.l_killiconname = "lambdaplayers_weaponkillicons_tf2_bleedout"

    ent.l_TF_BleedInfo[ #ent.l_TF_BleedInfo + 1 ] = {
        Attacker = attacker,
        Weapon = weapon,
        BleedingTime = bleedingTime,
        ExpireTime = expireTime,
        BleedDmg = bleedDmg,
        PermamentBleeding = permaBleeding,
        Inflictor = inflictor
    }
end

function LAMBDA_TF2:IsBleeding( ent )
    return ( ent.l_TF_BleedInfo and #ent.l_TF_BleedInfo > 0 )
end

function LAMBDA_TF2:RemoveBleeding( ent )
    local bleedInfo = ent.l_TF_BleedInfo
    if !bleedInfo or #bleedInfo == 0 then return end
    for _, info in ipairs(bleedInfo ) do
        SafeRemoveEntity( info.Inflictor )
    end
    table_Empty( bleedInfo )
end

function LAMBDA_TF2:Burn( ent, attacker, weapon, burningTime )
    if !ent:GetIsBurning() then
        ent:SetIsBurning( true )
        ent.l_TF_FlameBurnTime = CurTime()

        local inflictor = ents_Create( "base_anim" )
        inflictor:SetPos( ent:GetPos() )
        inflictor:SetParent( ent )
        inflictor:Spawn()
        inflictor:SetNoDraw( true )
        inflictor:DrawShadow( false )
        inflictor:SetSolid( SOLID_NONE )
        inflictor:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
        LAMBDA_TF2:TakeNoDamage( inflictor )
        inflictor.IsLambdaWeapon = true
        inflictor.l_IsTFBurnInflictor = true

        ent:DeleteOnRemove( inflictor )
        ent.l_TF_BurnInflictor = inflictor

        ParticleEffectAttach( "burningplayer_" .. ( LAMBDA_TF2:GetTeamColor( ent ) == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, ent, 0 )

        local engulfSnd = ent.l_TF_FireEngulfSound
        if !engulfSnd then
            engulfSnd = LAMBDA_TF2:CreateSound( ent, ")misc/flame_engulf.wav" )
            engulfSnd:Play()
            ent.l_TF_FireEngulfSound = engulfSnd
        end
    end

    local afterBurnImmune = false
    if ent.l_TF_SniperShieldType == 3 or CurTime() <= ent.l_TF_AfterburnImmunity then
        afterBurnImmune = true
    end

    local flameLife
    if afterBurnImmune then
        flameLife = 0.25
        ent:SetFlameRemoveTime( 0 )
    elseif weapon.TF2Data and weapon:GetWeaponAttribute( "IsFlareGun", false ) then
        flameLife = 7.5
    else
        flameLife = ( ( burningTime and burningTime > 0 ) and burningTime or 10 )
    end

    local burnEnd = ( CurTime() + flameLife )
    if burnEnd > ent:GetFlameRemoveTime() then
        ent:SetFlameRemoveTime( burnEnd )
    end

    ent.l_TF_BurnAttacker = attacker
    ent.l_TF_BurnWeapon = weapon
    ent.l_TF_BurnInflictor.l_killiconname = ( weapon.l_killiconname or "lambdaplayers_weaponkillicons_tf2_fire" )
end

function LAMBDA_TF2:IsBurning( ent )
    return ( ent:GetIsBurning() or ent:IsOnFire() )
end

function LAMBDA_TF2:RemoveBurn( ent )
    ent:Extinguish()

    if ent:GetIsBurning() then
        ent:SetIsBurning( false )
        ent.l_TF_BurnAttacker = nil
        ent.l_TF_BurnWeapon = nil
        SafeRemoveEntity( ent.l_TF_BurnInflictor )
    end

    LAMBDA_TF2:StopParticlesNamed( ent, "burningplayer_red" )
    LAMBDA_TF2:StopParticlesNamed( ent, "burningplayer_blue" )

    local engulfSnd = ent.l_TF_FireEngulfSound
    if engulfSnd then
        engulfSnd:Stop()
        ent.l_TF_FireEngulfSound = nil
    end
end

function LAMBDA_TF2:MarkForDeath( ent, time, silent, markerer )
    if LAMBDA_TF2:IsMarkedForDeath( ent ) then  LAMBDA_TF2:RemoveMarkForDeath( ent ) end

    if silent then 
        ent.l_TF_MarkedForDeathSilent = ( CurTime() + time )
    else
        ent.l_TF_MarkedForDeath = ( CurTime() + time )
    end

    if IsValid( markerer ) then
        local markedTarget = markerer.l_TF_MarkedForDeathTarget
        if IsValid( markedTarget ) and markedTarget != ent then LAMBDA_TF2:RemoveMarkForDeath( markedTarget ) end

        markerer.l_TF_MarkedForDeathTarget = ent
    end
end

function LAMBDA_TF2:IsMarkedForDeath( ent )
    return ( CurTime() <= ent.l_TF_MarkedForDeathSilent or CurTime() <= ent.l_TF_MarkedForDeath )
end

function LAMBDA_TF2:RemoveMarkForDeath( ent )
    ent.l_TF_MarkedForDeath = 0
    ent.l_TF_MarkedForDeathSilent = 0
end

function LAMBDA_TF2:TakeNoDamage( ent )
    ent:SetSaveValue( "m_takedamage", 0 )
end

function LAMBDA_TF2:CreateSound( targetEnt, soundName, filter )
    local snd = targetEnt.l_TF_LoopingSounds[ soundName ]
    if snd then snd:Stop(); targetEnt.l_TF_LoopingSounds[ soundName ] = nil end

    snd = CreateSound( targetEnt, soundName, filter )
    if snd then targetEnt.l_TF_LoopingSounds[ soundName ] = snd end

    return snd
end

function LAMBDA_TF2:IsValidCharacter( ent, alive )
    if alive == nil then alive = true end
    return ( ( ent:IsPlayer() or ent.IsLambdaPlayer ) and ( !alive or ent:Alive() ) or ( ent:IsNPC() or ent:IsNextBot() ) and ( !alive or ent:Health() > 0 ) )
end

function LAMBDA_TF2:GetCritType( dmginfo )
    return ( dmginfo:IsDamageType( DMG_CRITICAL ) and TF_CRIT_FULL or ( dmginfo:IsDamageType( DMG_MINICRITICAL ) and TF_CRIT_MINI or TF_CRIT_NONE ) )
end

function LAMBDA_TF2:SetCritType( dmginfo, critType )
    if dmginfo:IsDamageType( DMG_CRITICAL ) then dmginfo:SetDamageType( dmginfo:GetDamageType() - DMG_CRITICAL ) end
    if dmginfo:IsDamageType( DMG_MINICRITICAL ) then dmginfo:SetDamageType( dmginfo:GetDamageType() - DMG_MINICRITICAL ) end

    if critType == TF_CRIT_FULL then
        dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_CRITICAL )
    elseif critType == TF_CRIT_MINI then
        dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_MINICRITICAL )
    end
end

function LAMBDA_TF2:AddInventoryCooldown( lambda, name )
    name = ( name or lambda:GetWeaponName() )
    
    local wepInv = lambda.l_TF_Inventory[ name ]
    if !wepInv or !wepInv.IsReady then return end
    wepInv.IsReady = false

    if wepInv.NextUseTime then wepInv.NextUseTime = ( CurTime() + LAMBDA_TF2.InventoryItems[ name ].Cooldown ) end
end

function LAMBDA_TF2:IsInventoryItemReady( lambda, name )    
    local wepInv = lambda.l_TF_Inventory[ name ]
    return wepInv and wepInv.IsReady
end

function LAMBDA_TF2:DecreaseInventoryCooldown( lambda, name, amount )
    name = ( name or lambda:GetWeaponName() )
    
    local wepInv = lambda.l_TF_Inventory[ name ]
    if !wepInv or wepInv.IsReady or !wepInv.NextUseTime then return end
end

function LAMBDA_TF2:IsBehindBackstab( ent, target )
    local vecToTarget = ( target:GetPos() - ent:GetPos() ); vecToTarget.z = 0; vecToTarget:Normalize()
    local vecOwnerForward = ent:GetForward(); vecOwnerForward.z = 0; vecOwnerForward:Normalize()
    local vecTargetForward = target:GetForward(); vecTargetForward.z = 0; vecTargetForward:Normalize()
    return ( vecToTarget:Dot( vecTargetForward ) > 0 and vecToTarget:Dot( vecOwnerForward ) > 0.5 and vecTargetForward:Dot( vecOwnerForward ) > -0.3 )
end

function LAMBDA_TF2:GetMedigunHealers( ent, returnNum )
    local healers = {}
    local count = 0
    
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda.l_TF_HasMedigunEquipped or lambda.l_TF_Medic_HealTarget != ent and !healers[ lambda.l_TF_Medic_HealTarget ] then continue end
        healers[ lambda ] = true
        count = ( count + 1 )
    end

    return ( returnNum == true and count or healers )
end

---

function LAMBDA_TF2:LambdaMedigunAI( lambda )
    if !lambda:HookExists( "Tick", "TFMedicThink" ) then
        lambda:Hook( "Tick", "TFMedicThink", function()
            if !lambda:Alive() or lambda:GetState() != "HealWithMedigun" then 
                lambda.l_TF_Medic_HealTarget = nil 
                return "end" 
            end
            if !lambda.l_TF_HasMedigunEquipped then
                lambda:CancelMovement()
                lambda:SetState( "Idle" )

                lambda.l_TF_Medic_HealTarget = nil 
                return "end"
            end
            if lambda:IsDisabled() then return end

            local healTarget = lambda.l_TF_Medic_HealTarget
            local targetDead = ( !IsValid( healTarget ) or !LAMBDA_TF2:IsValidCharacter( healTarget ) )
            if targetDead or random( 1, ( ( lambda.l_TF_Medigun_ChargeReleased or healTarget.IsLambdaPlayer and healTarget:InCombat() ) and 250 or 100 ) ) == 1 then
                if IsValid( healTarget ) and targetDead then
                    lambda.l_TF_Medic_HealTarget = nil 
                    lambda:RetreatFrom( healTarget.l_TF_Killer )
                    return "end"
                end

                if CurTime() > lambda.l_TF_Medic_TargetSearchT then
                    lambda.l_TF_Medic_TargetSearchT = ( CurTime() + 1.0 )
                    print( lambda:Name() .. ":" )

                    local hasFriends = ( lambda.l_friends and table_Count( lambda.l_friends ) > 0 )
                    local woundedTarget = nil
                    local filter = lambda.l_TF_MedicTargetFilter
                    local ignorePly = ignorePlys:GetBool()
                    local healers = LAMBDA_TF2:GetMedigunHealers( lambda )
                    local targetSearchFunc = function( ent )
                        if !ent.IsLambdaPlayer and !ent:IsPlayer() or !ent:Alive() then return false end
                        if ent:IsPlayer() and ignorePly then return false end
                        if filter and filter( lambda, ent ) == false then return false end
                        if LambdaTeams and LambdaTeams:AreTeammates( lambda, ent ) == false then return false end
                        if ent != healTarget and !lambda:CanSee( ent ) then return false end
                        if ent.IsLambdaPlayer and ent:InCombat() and ent:GetEnemy() == lambda then return false end
                        if hasFriends and !lambda:IsFriendsWith( ent ) then return false end

                        if IsValid( healTarget ) then
                            if healTarget.IsLambdaPlayer and healTarget:InCombat() and healTarget:GetEnemy() == ent then return false end
                            if ent.IsLambdaPlayer and ent:InCombat() and ent:GetEnemy() == healTarget then return false end
                            if LambdaTeams and LambdaTeams:AreTeammates( healTarget, ent ) == false then return false end
                        end

                        if ( healers[ ent ] or ent.l_TF_HasMedigunEquipped ) then 
                            if ent:Health() > ent:GetMaxHealth() then return false end

                            local entHealTarget = ent.l_TF_Medic_HealTarget
                            if IsValid( entHealTarget ) and LambdaTeams and LambdaTeams:AreTeammates( lambda, entHealTarget ) == false then return false end
                        end

                        if woundedTarget then
                            if ent:Health() > woundedTarget:Health() then return false end
                            if ( LAMBDA_TF2:IsBurning( woundedTarget ) or LAMBDA_TF2:IsBleeding( woundedTarget ) ) and !LAMBDA_TF2:IsBurning( ent ) and !LAMBDA_TF2:IsBleeding( ent ) then return false end
                            if LambdaTeams and LambdaTeams:AreTeammates( woundedTarget, ent ) == false then return false end
                            if ent.IsLambdaPlayer and woundedTarget.IsLambdaPlayer and woundedTarget:InCombat() != ent:InCombat() then return false end
                        end

                        print( "        " .. ent:Name() )
                        woundedTarget = ent
                        return true
                    end
                    lambda:FindInSphere( nil, ( targetDead and 2000 or 1000 ), targetSearchFunc )

                    healTarget = woundedTarget
                    lambda.l_TF_Medic_HealTarget = healTarget
                end
            end

            if IsValid( healTarget ) then
                local canSee = lambda:CanSee( healTarget ) 

                if lambda:IsInRange( healTarget, 750 ) and canSee then lambda:LookTo( healTarget, 0.5 ) end
                lambda:UseWeapon( healTarget )

                local targetInCombat = ( LAMBDA_TF2:GetTimeSinceLastDamage( healTarget ) <= 1 )
                if !targetInCombat then
                    if healTarget.IsLambdaPlayer then
                        local ene = healTarget:GetEnemy()
                        local attackRange = ( healTarget.l_CombatAttackRange or 1000 )
                        if healTarget:InCombat() and healTarget:IsInRange( ene, attackRange ) and healTarget:CanSee( ene ) then
                            targetInCombat = true
                        end
                    elseif healTarget:IsPlayer() then
                        local weapon = healTarget:GetActiveWeapon()
                        local lookEnt = healTarget:GetEyeTrace().Entity
                        if IsValid( weapon ) and ( CurTime() - weapon:LastShootTime() ) <= 1 and IsValid( lookEnt ) and lookEnt != lambda and LAMBDA_TF2:IsValidCharacter( lookEnt ) then
                            targetInCombat = true
                        end
                    end
                end

                local medigunTarget = lambda.l_TF_Medigun_HealTarget
                if medigunTarget != healTarget or !healTarget.IsLambdaPlayer then
                    if !lambda:IsInRange( healTarget, 200 ) or LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) <= 5 or targetInCombat then
                        lambda:SetRun( true )
                    elseif healTarget.IsLambdaPlayer then
                        lambda:SetRun( healTarget:GetRun() )
                    elseif healTarget:IsPlayer() then
                        lambda:SetRun( healTarget:IsSprinting() )
                    else
                        lambda:SetRun( false )
                    end
                else
                    lambda:SetRun( false )
                end

                local closeRange = ( targetInCombat and 300 or 140 )
                if lambda:IsInRange( healTarget, closeRange ) and canSee then 
                    if LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) <= 5 or targetInCombat or lambda:IsInRange( healTarget, 30 ) then
                        local desSpeed = ( lambda.loco:GetDesiredSpeed() / 2 )
                        lambda.l_movepos = ( lambda:GetPos() + Vector( random( -desSpeed, desSpeed ), random( -desSpeed, desSpeed ), 0 ) )
                    elseif canSee then
                        lambda:WaitWhileMoving( 0.1 )
                    end
                else
                    lambda:SetCrouch( false )
                    lambda.l_movepos = healTarget
                end

                if !lambda.l_TF_Medigun_ChargeReleased and lambda.l_TF_Medigun_ChargeReady and ( LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) <= 1 or targetInCombat and medigunTarget == healTarget ) then
                    lambda.l_TF_Medigun_ChargeReleased = true

                    local releaseSnd = LAMBDA_TF2:CreateSound( lambda, lambda.l_TF_MedigunChargeReleaseSound )
                    if releaseSnd then
                        releaseSnd:Play()
                        lambda.l_TF_Medigun_ChargeReleaseSound = releaseSnd
                    end

                    net.Start( "lambda_tf2_medigun_chargeeffect" )
                        net.WriteEntity( lambda:GetWeaponENT() )
                        net.WriteBool( true )
                        net.WriteUInt( lambda.l_TF_TeamColor, 1 )
                    net.Broadcast()

                    if random( 1, 100 ) <= lambda:GetVoiceChance() then
                        lambda:PlaySoundFile( "taunt" )
                    end

                    if healTarget.IsLambdaPlayer and random( 1, 100 ) <= healTarget:GetVoiceChance() then
                        healTarget:PlaySoundFile( "taunt" )
                    end
                end
            end
        end, true )
    end

    if lambda:GetState() == "HealWithMedigun" then
        local healTarget = lambda.l_TF_Medic_HealTarget
        if IsValid( healTarget ) then 
            lambda:MoveToPos( healTarget, { update = 0.2, tol = 12, callback = function()
                if !IsValid( lambda.l_TF_Medic_HealTarget ) then return false end
            end } )
        else
            lambda:MoveToPos( lambda:GetRandomPosition(), { autorun = false, run = false, callback = function()
                if IsValid( lambda.l_TF_Medic_HealTarget ) then return false end
            end } )
        end
    end
end

function LAMBDA_TF2:ActivateRageBuff( lambda, pulseCount )
    LAMBDA_TF2:AddInventoryCooldown( lambda )
    lambda:EmitSound( "weapons/buff_banner_flag.wav", nil, nil, nil, CHAN_STATIC )

    lambda.l_TF_RageActivated = true
    lambda.l_TF_RagePulseCount = ( pulseCount or 10 )
    lambda.l_TF_RageNextPulseTime = 0

    local buffpack = lambda.l_TF_RageBuffPack
    if IsValid( buffpack ) then buffpack:SetBodygroup( 1, 1 ) end

    lambda:PlaySoundFile( "taunt" )
    lambda:SwitchToLethalWeapon()
end

function LAMBDA_TF2:GetFriendlyTargets( lambda, dist, visible )
    visible = ( visible == nil and false or visible )
    local friendTargs = { lambda }

    local ene = ( lambda:InCombat() and lambda:GetEnemy() or nil )
    local ignorePly = ignorePlys:GetBool()

    for _, ent in ipairs( FindInSphere( lambda:GetPos(), dist ) ) do
        if ent == lambda or !IsValid( ent ) or !LAMBDA_TF2:IsValidCharacter( ent ) then continue end
        if ent.GetEnemy and ent:GetEnemy() == lambda then continue end
        if ent:IsPlayer() and ignorePly then continue end
        if ent.Disposition and ent:Disposition( lambda ) == D_HT then continue end
        if LambdaTeams and LambdaTeams:AreTeammates( lambda, ent ) == false then continue end

        if ene then 
            if ent == ene then continue end
            if ene.IsLambdaPlayer then
                if ene.IsFriendsWith and ene:IsFriendsWith( ent ) then continue end
                if LAMBDA_TF2:GetMedigunHealers( ene )[ ent ] then continue end
            end
        end

        friendTargs[ #friendTargs + 1 ] = ent
    end

    return friendTargs
end

local function OnLambdaThink( lambda, weapon, isdead )
    if lambda.l_TF_Shield_IsEquipped then
        local shieldType = lambda.l_TF_Shield_Type
        
        if !isdead and !lambda:GetIsShieldCharging() and lambda:GetShieldChargeMeter() == 100 and random( 1, 30 ) == 1 then
            local enemy = lambda:GetEnemy()
            local isPanicking = ( lambda:IsPanicking() or !lambda:InCombat() and ( lambda.l_TF_CoveredInUrine or lambda.l_TF_CoveredInMilk or LAMBDA_TF2:IsBurning( lambda ) or LAMBDA_TF2:IsBleeding( lambda ) ) )

            local canCharge = isPanicking
            if !canCharge and lambda:InCombat() then
                local selfPos = lambda:GetPos()
                local enemyPos = enemy:GetPos()
                local stepHeight = lambda.loco:GetStepHeight()        
                local chargeDist = ( 1000 / lambda.l_TF_Shield_ChargeDrainRateMult )

                if ( enemyPos.z >= ( selfPos.z - stepHeight ) and enemyPos.z <= ( selfPos.z + stepHeight ) ) and ( !lambda.l_HasMelee and !lambda:GetIsReloading() or lambda.l_HasMelee and lambda:IsInRange( enemy, chargeDist ) ) and !lambda:IsInRange( enemy, ( lambda.l_CombatAttackRange or chargeDist ) ) and lambda:CanSee( enemy ) then
                    lambda:LookTo( enemy, 1.0 )

                    local los = deg( acos( lambda:GetForward():Dot( ( enemyPos - selfPos ):GetNormalized() ) ) )
                    canCharge = ( los <= 15 )
                end
            end

            if canCharge then
                lambda:EmitSound( "lambdaplayers/tf2/shield_charge.mp3", 80, nil, nil, CHAN_STATIC )
                lambda:PlaySoundFile( "fall" ) --( isPanicking and "fall" or "taunt" )

                local chargeTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 32, 16, 0.75, "effects/beam001_white", lambda:WorldSpaceCenter(), lambda )
                lambda:DeleteOnRemove( chargeTrail )
                lambda.l_TF_Shield_ChargeTrail = chargeTrail

                lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate / ( shieldType != 3 and 20 or 1 ) )
                lambda:SetIsShieldCharging( true )

                LAMBDA_TF2:RemoveBurn( lambda )
                LAMBDA_TF2:RemoveBleeding( lambda )
                if lambda.l_TF_CoveredInUrine then lambda.l_TF_CoveredInUrine = 0 end
                if lambda.l_TF_CoveredInMilk then lambda.l_TF_CoveredInMilk = 0 end

                lambda.l_nextspeedupdate = 0
                lambda:SetCrouch( false )
                lambda:SetSlowWalk( false )
            end
        end

        if lambda:GetIsShieldCharging() then
            if !isdead then
                if CurTime() >= lambda.l_WeaponUseCooldown then
                    lambda.l_WeaponUseCooldown = CurTime() + 0.1
                end

                lambda.loco:SetVelocity( lambda:GetForward() * min( lambda:GetRunSpeed() * 2 ) )

                if lambda:GetShieldChargeMeter() <= 75 then
                    if !lambda.l_TF_Shield_CritBoosted then
                        lambda.l_TF_Shield_CritBoosted = true

                        local chargeSnd = LAMBDA_TF2:CreateSound( weapon, ")weapons/weapon_crit_charged_on.wav" )
                        if chargeSnd then chargeSnd:PlayEx( 0.25, 100 ) end
                        lambda.l_TF_Shield_CritBoostSound = chargeSnd
                    end

                    if !weapon.TF2Data and !lambda:IsWeaponMarkedNodraw() then
                        weapon:SetMaterial( LAMBDA_TF2:GetCritGlowMaterial() )
                    end
                end

                local shield = lambda.l_TF_Shield_Entity
                local lambdaPos = lambda:GetAttachmentPoint( "eyes" ).Pos

                shieldChargeTrTbl.start = lambdaPos
                shieldChargeTrTbl.endpos = ( lambdaPos + lambda:GetForward() * 48 )
                shieldChargeTrTbl.filter = { lambda, weapon, shield }

                local chargeResult = TraceHull( shieldChargeTrTbl )
                if chargeResult.Hit then
                    local impactEnt = chargeResult.Entity
                    if LAMBDA_TF2:IsValidCharacter( impactEnt ) then
                        if lambda:GetShieldChargeMeter() <= 40 then
                            impactEnt:EmitSound( "weapons/demo_charge_hit_flesh_range" .. random( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                        else
                            impactEnt:EmitSound( "weapons/demo_charge_hit_flesh" .. random( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                        end

                        local bashDmg = LAMBDA_TF2:RemapClamped( lambda:GetShieldChargeMeter(), 90, 40, 10, 30 )
                        local heads = min( lambda.l_TF_Decapitations, 5 )
                        if heads > 0 then bashDmg = ( bashDmg * ( 1 + heads * 0.1 ) ) end
                        if shieldType == 2 then bashDmg = ( bashDmg * 1.7 ) end

                        local dmginfo = DamageInfo()
                        dmginfo:SetDamage( bashDmg )
                        dmginfo:SetAttacker( lambda )
                        dmginfo:SetInflictor( shield )
                        dmginfo:SetDamageForce( lambda.loco:GetVelocity() * bashDmg )
                        dmginfo:SetDamagePosition( chargeResult.HitPos )
                        dmginfo:SetDamageType( DMG_CLUB )
                        dmginfo:SetDamageCustom( TF_DMG_CUSTOM_CHARGE_IMPACT )
                        impactEnt:DispatchTraceAttack( dmginfo, chargeResult, lambda:GetForward() )
                    else
                        lambda:EmitSound( "weapons/demo_charge_hit_world" .. random( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                    end

                    lambda:SetIsShieldCharging( false )
                    ScreenShake( lambdaPos, 25, 150, 1, 750 )
                else
                    lambda:SetShieldChargeMeter( lambda:GetShieldChargeMeter() - ( ( ( 100 / 1.5 ) * FrameTime() ) * lambda.l_TF_Shield_ChargeDrainRateMult ) )
                    lambda:SetShieldLastNoChargeTime( CurTime() )
                end
            end

            if isdead or !lambda:GetIsShieldCharging() or lambda:GetShieldChargeMeter() <= 0 then
                lambda:SetIsShieldCharging( false )
                lambda:SetShieldLastNoChargeTime( CurTime() )

                lambda:SimpleTimer( 0.3, function() 
                    if lambda.l_TF_Shield_CritBoosted then
                        local chargeSnd = lambda.l_TF_Shield_CritBoostSound
                        if chargeSnd then chargeSnd:Stop() end
                        lambda.l_TF_Shield_CritBoostSound = nil

                        lambda.l_TF_Shield_CritBoosted = false
                        weapon:EmitSound( ")weapons/weapon_crit_charged_off.wav", nil, nil, 0.25, CHAN_STATIC )
                    end

                    lambda:SetNextMeleeCrit( TF_CRIT_NONE )
                end, true )

                lambda:SimpleTimer( 1.0, function() 
                    if lambda:GetCritBoostType() != TF_CRIT_NONE then return end
                    if !weapon.TF2Data and !lambda:IsWeaponMarkedNodraw() then weapon:SetMaterial( "" ) end
                end, true )

                if !isdead then
                    lambda:RecomputePath()
                    
                    lambda:SimpleTimer( 0.1, function() 
                        if lambda:IsSpeaking() and lambda:GetLastSpokenVoiceType() == "fall" and lambda:OnGround() then
                            net.Start( "lambdaplayers_stopcurrentsound" )
                                net.WriteEntity( lambda )
                            net.Broadcast()
                        end
                    end )

                    if lambda:GetShieldChargeMeter() <= 40 then
                        lambda:SetNextMeleeCrit( TF_CRIT_FULL )
                    elseif lambda:GetShieldChargeMeter() <= 75 then
                        lambda:SetNextMeleeCrit( TF_CRIT_MINI )
                    end

                    lambda:SetShieldChargeMeter( 0 )
                end

                lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate )
                lambda:StopSound( "lambdaplayers/tf2/shield_charge.mp3" )

                local chargeTrail = lambda.l_TF_Shield_ChargeTrail
                if IsValid( chargeTrail ) then
                    chargeTrail:SetParent()
                    SafeRemoveEntityDelayed( chargeTrail, 1 )
                end       
            end
        elseif !isdead and lambda:GetShieldChargeMeter() != 100 then
            local chargeRate = ( ( 100 / 12 ) * FrameTime() )
            if shieldType == 2 then chargeRate = ( chargeRate * 1.5 ) end
            lambda:SetShieldChargeMeter( lambda:GetShieldChargeMeter() + chargeRate )
            
            if lambda:GetShieldChargeMeter() >= 100 then
                weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC )
                lambda:SetShieldChargeMeter( 100 )
            end
        end
    end

    if !isdead then
        if lambda.l_TF_RageActivated then
            lambda.l_TF_RageMeter = ( lambda.l_TF_RageMeter - ( FrameTime() * 10 ) )
            
            if lambda.l_TF_RageMeter <= 0 then
                lambda.l_TF_RageMeter = 0
                lambda.l_TF_RagePulseCount = 0
                lambda.l_TF_RageNextPulseTime = 0
                lambda.l_TF_RageActivated = false

                local buffpack = lambda.l_TF_RageBuffPack
                if IsValid( buffpack ) then buffpack:SetBodygroup( 1, 0 ) end
            end
        end

        local buffType = lambda.l_TF_RageBuffType
        if lambda.l_TF_RagePulseCount > 0 then 
            if CurTime() > lambda.l_TF_RageNextPulseTime then
                if lambda.l_TF_RageNextPulseTime != 0 then
                    lambda.l_TF_RagePulseCount = ( lambda.l_TF_RagePulseCount - 1 )
                end
                lambda.l_TF_RageNextPulseTime = ( CurTime() + 1.0 )

                for _, ent in ipairs( LAMBDA_TF2:GetFriendlyTargets( lambda, 450 ) ) do
                    if buffType == 1 then
                        ent.l_TF_OffenseBuffActive = ( CurTime() + 1.2 )
                    elseif buffType == 2 then
                        ent.l_TF_DefenseBuffActive = ( CurTime() + 1.2 )
                    elseif buffType == 3 then
                        ent.l_TF_SpeedBuffActive = ( CurTime() + 1.2 )
                    end

                    local buffPartName = "soldierbuff_" .. ( lambda.l_TeamColor == 1 and "blue" or "red" ) .. "_soldier"
                    ParticleEffectAttach( buffPartName, PATTACH_ABSORIGIN_FOLLOW, ent, 0 )
                end
            end

            debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 1.8, "Buff Pulses Left: " .. lambda.l_TF_RagePulseCount, FrameTime() * 2 ) 
        end

        if buffType then 
            debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2.2, "Buff Type: " .. lambda.l_TF_RageBuffType, FrameTime() * 2 ) 
            debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2, "Buff Meter: " .. Round( lambda.l_TF_RageMeter ) .. "%", FrameTime() * 2 ) 
        end

        if lambda.l_TF_Medigun_ChargeReleased then
            lambda.l_TF_Medigun_ChargeMeter = max( 0, lambda.l_TF_Medigun_ChargeMeter - ( ( 100 / 9 ) * FrameTime() ) )
    
            if lambda.l_TF_Medigun_ChargeMeter <= 0 then                
                lambda.l_TF_Medigun_ChargeMeter = 0
                lambda:EmitSound( lambda.l_TF_MedigunChargeDrainSound, nil, nil, nil, CHAN_STATIC )
    
                local releaseSnd = lambda.l_TF_Medigun_ChargeReleaseSound
                if releaseSnd then 
                    releaseSnd:Stop()
                    releaseSnd = nil
                    lambda.l_TF_Medigun_ChargeReleaseSound = releaseSnd
                end
    
                if lambda.l_TF_Medigun_ChargeReady then
                    local chargeSnd = lambda.l_TF_Medigun_ChargeSound
                    if chargeSnd then 
                        chargeSnd:Stop()
                        chargeSnd = nil
                        lambda.l_TF_Medigun_ChargeSound = chargeSnd
                    end
    
                    net.Start( "lambda_tf2_medigun_chargeeffect" )
                        net.WriteEntity( weapon )
                        net.WriteBool( false )
                    net.Broadcast()
                end
    
                lambda.l_TF_Medigun_ChargeReleased = false
                lambda.l_TF_Medigun_ChargeReady = false
            end
        end
    
        if !lambda.l_TF_IsUsingItem and CurTime() > lambda.l_TF_NextInventoryCheckT then 
            local wepName = lambda:GetWeaponName()
            local lambdaInv = lambda.l_TF_Inventory

            local curItem = lambdaInv[ wepName ]
            if curItem and curItem.SwitchBackCond and curItem.SwitchBackCond( lambda ) == true then
                local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
                if preInvWep then
                    lambda:SwitchWeapon( preInvWep )
                    lambda.l_TF_PreInventorySwitchWeapon = nil
                else
                    lambda:SwitchToRandomWeapon()
                end
            elseif !curItem and ( !lambda.l_HasMelee or CurTime() > lambda.l_WeaponUseCooldown ) and !lambda.l_TF_HasEdibles then
                local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
                if preInvWep and wepName == preInvWep.Name then
                    lambda.l_TF_PreInventorySwitchWeapon = nil
                end

                local invItems = LAMBDA_TF2.InventoryItems
                for name, item in RandomPairs( lambdaInv ) do
                    if !item.IsReady then
                        local useTime = item.NextUseTime
                        if !useTime and invItems[ name ].Cooldown( lambda ) == true or useTime and CurTime() > useTime then
                            item.IsReady = true
                            weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC )
                        else
                            continue 
                        end
                    end

                    if item.IsWeapon and wepName != name and invItems[ name ].Condition( lambda ) == true then
                        local wepClip = lambda.l_Clip
                        
                        lambda:SwitchWeapon( name )

                        if lambda:GetWeaponName() == name then
                            lambda.l_TF_PreInventorySwitchWeapon = {
                                Name = wepName,
                                Clip = wepClip
                            }

                            break
                        end
                    end
                end
            end
    
            lambda.l_TF_NextInventoryCheckT = ( CurTime() + Rand( 0.1, 1.0 ) )
        end
        
        if lambda.l_TF_AtomicPunched and CurTime() >= lambda.l_TF_AtomicPunched then
            lambda.l_TF_AtomicPunched = false
    
            local damageTook = lambda.l_TF_AtomicPunched_DamageTaken
            if damageTook > 0 then
                lambda:EmitSound( "player/pl_scout_dodge_tired.wav", 60, lambda:GetVoicePitch(), nil, CHAN_VOICE )
                lambda.l_TF_AtomicPunched_SlowdownScale = LAMBDA_TF2:RemapClamped( damageTook, 0, 200, 1, 0.5 )
                lambda.l_TF_AtomicPunched_SlowdownTime = ( CurTime() + 5 )
                lambda.l_nextspeedupdate = 0
            else
                lambda.l_TF_AtomicPunched_SlowdownScale = false
            end
            lambda.l_TF_AtomicPunched_DamageTaken = 0
    
            local trail = lambda.l_TF_AtomicPunched_Trail
            if IsValid( trail ) then 
                trail:SetParent()
                SafeRemoveEntityDelayed( trail, 1 ) 
            end
        end

        local bonkSlowdown = lambda.l_TF_AtomicPunched_SlowdownScale
        if bonkSlowdown and CurTime() >= lambda.l_TF_AtomicPunched_SlowdownTime then
            bonkSlowdown = false
            lambda.l_TF_AtomicPunched_SlowdownScale = bonkSlowdown
            lambda.l_nextspeedupdate = 0
        end
    
        if lambda.l_TF_ThrownBaseball and CurTime() > lambda.l_TF_ThrownBaseball then
            lambda.l_TF_ThrownBaseball = false
            weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC )
        end
    
        for barIndex, bar in ipairs( lambda.l_TF_DalokohsBars ) do
            if CurTime() < bar.ExpireTime then continue end
    
            local hpRatio = bar.HealthRatio
            local oldHP = Round( lambda:GetMaxHealth() / hpRatio )
    
            if !isdead then lambda:SetHealth( Round( lambda:Health() * ( oldHP / lambda:GetMaxHealth() ) ) ) end
            lambda:SetMaxHealth( oldHP )
            
            table_remove( lambda.l_TF_DalokohsBars, barIndex )
        end

        if CurTime() > lambda.l_TF_GRU_ActionTime then
            local gruHP = lambda.l_TF_GRU_DrainedHP
            local curMax = lambda:GetMaxHealth()

            if lambda.l_TF_HasGlovesOfRunning then
                local newHP = max( curMax - 1, lambda.l_TF_GRU_MinHealth )
                lambda:SetHealth( Round( lambda:Health() * ( newHP / curMax ) ) )
                lambda:SetMaxHealth( newHP )
                lambda.l_TF_GRU_DrainedHP = ( gruHP + ( curMax - newHP ) )
            elseif gruHP > 0 then
                local newHP = min( curMax + 1, lambda.l_TF_GRU_MaxHealth )
                lambda:SetHealth( Round( lambda:Health() * ( newHP / curMax ) ) )
                lambda:SetMaxHealth( newHP )
                lambda.l_TF_GRU_DrainedHP = ( gruHP - 1 )
            end

            lambda.l_TF_GRU_ActionTime = ( CurTime() + ( lambda.l_TF_GRU_DrainRate * FrameTime() ) )
        end

        if CurTime() > lambda.l_TF_NextCritUpdateT then
            if #lambda.l_TF_DamageEvents == 0 then
                lambda.l_TF_CritMult = LAMBDA_TF2:RemapClamped( 1, 1, 4, 0, 255 )
            else
                local totalDmg = 0
                local curtime = CurTime()
                for k, v in ipairs( lambda.l_TF_DamageEvents ) do
                    local delta = ( curtime - v.Time )
                    if delta > 30 then
                        table_remove( lambda.l_TF_DamageEvents, k )
                        continue
                    end
                    if delta < TF_DAMAGE_CRITMOD_MINTIME or delta > TF_DAMAGE_CRITMOD_MAXTIME then continue end
                    totalDmg = ( totalDmg + v.Damage * v.DamageCriticalScale )
                end

                local mult = LAMBDA_TF2:RemapClamped( totalDmg, 0, TF_DAMAGE_CRITMOD_DAMAGE, 1, TF_DAMAGE_CRITMOD_MAXMULT )
                lambda.l_TF_CritMult = Round( LAMBDA_TF2:RemapClamped( mult, 1, 4, 0, 255 ) )
            end

            lambda.l_TF_NextCritUpdateT = ( CurTime() + 0.5 )
        end

        if lambda.l_TF_HasMedigunEquipped then 
            if ( lambda:GetState() == "Idle" or lambda:GetState() == "Combat" or lambda:GetState() == "FindTarget" ) and lambda:GetState() != "HealWithMedigun" and !lambda:IsPanicking() then
                lambda:CancelMovement()
                lambda:SetState( "HealWithMedigun" )
            end

            debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2, "Uber-Charge: " .. Round( lambda.l_TF_Medigun_ChargeMeter ) .. "%", FrameTime() * 2 ) 

            local chargeSnd = lambda.l_TF_Medigun_ChargeSound
            if lambda.l_TF_Medigun_ChargeMeter >= 100 and !lambda.l_TF_Medigun_ChargeReady then
                lambda.l_TF_Medigun_ChargeReady = true

                if !chargeSnd then
                    chargeSnd = LAMBDA_TF2:CreateSound( weapon, "weapons/medigun_charged.wav" )
                    chargeSnd:PlayEx( 0.5, 100 )
                    chargeSnd:SetSoundLevel( 70 )
                    lambda.l_TF_Medigun_ChargeSound = chargeSnd
                end

                net.Start( "lambda_tf2_medigun_chargeeffect" )
                    net.WriteEntity( weapon )
                    net.WriteBool( true )
                    net.WriteUInt( lambda.l_TF_TeamColor, 1 )
                net.Broadcast()
            end
        end

        if CurTime() > lambda.l_TF_NextHealthRegenT then
            lambda.l_TF_NextHealthRegenT = ( CurTime() + 1 )

            local regenAmount = 0
            if lambda.l_TF_HasMedigunEquipped then
                local hpGet = ( lambda:GetMaxHealth() * 0.04 )
                local medigunTarget = lambda.l_TF_Medigun_HealTarget
                if IsValid( medigunTarget ) and medigunTarget:Health() < medigunTarget:GetMaxHealth() then
                    hpGet = ( hpGet + hpGet )
                end

                regenAmount = ( regenAmount + hpGet )
            end
            if lambda.l_TF_RageBuffType == 3 then
                regenAmount = ( regenAmount + ( lambda:GetMaxHealth() * 0.02 ) )
            end
            if lambda.l_TF_SniperShieldType == 2 then
                regenAmount = ( regenAmount + ( lambda:GetMaxHealth() * 0.032 ) )
            end

            if regenAmount > 0 then
                local regenScale = 0.25
                local timeSinceDamage = LAMBDA_TF2:GetTimeSinceLastDamage( lambda )
                if timeSinceDamage >= 5 then regenScale = LAMBDA_TF2:RemapClamped( timeSinceDamage, 5, 10, 0.5, 1 ) end
                LAMBDA_TF2:GiveHealth( lambda, ( regenAmount * regenScale ), false )
            end

            local ene = lambda:GetEnemy()
            if ene.l_TF_HasMedigunEquipped and lambda:InCombat() and LAMBDA_TF2:GetMedigunHealers( lambda )[ ene ] then
                lambda:CancelMovement()
                lambda:SetEnemy( NULL )
                lambda:SetState( "Idle" )
            end

            local medkit = lambda.l_TF_GoingAfterMedkit
            if medkit then
                local moveEnt = lambda.l_movepos
                if !lambda.l_issmoving or isvector( moveEnt ) or !IsValid( moveEnt ) or moveEnt != medkit then
                    lambda.l_TF_GoingAfterMedkit = nil
                elseif !IsValid( medkit ) or medkit.IsLambdaTFMedkit and medkit.IsRespawning or lambda:Health() >= lambda:GetMaxHealth() or LAMBDA_TF2:GetMedigunHealers( lambda, true ) != 0 then
                    lambda:CancelMovement()
                    lambda.l_TF_GoingAfterMedkit = nil
                end
            end

            if lambda:GetIsBurning() then
                lambda:SetRun( true )
    
                if CurTime() > lambda.l_nextidlesound and !lambda:IsDisabled() and !lambda:GetIsTyping() and !lambda:IsSpeaking() and random( 1, 100 ) <= lambda:GetVoiceChance() then
                    lambda:PlaySoundFile( "panic" )
                end
            end
        end
        
        if GetConVar( "lambdaplayers_tf2_alwayscrit" ):GetBool() then
            LAMBDA_TF2:AddCritBoost( lambda, "AlwaysCritSetting", TF_CRIT_FULL, 0.1 )
        end

        if CurTime() > lambda.l_nextspeedupdate then
            lambda:SimpleTimer( FrameTime(), function()
                local desSpeed = lambda.loco:GetDesiredSpeed()

                if lambda.l_TF_IsStunned then desSpeed = ( desSpeed * 0.75 ) end
                if bonkSlowdown then desSpeed = ( desSpeed * bonkSlowdown ) end
                if lambda.l_TF_InSpeedBoost then desSpeed = ( desSpeed + min( desSpeed * 0.4, 105 ) ) end
                if LAMBDA_TF2:HasCritBoost( lambda, "BuffaloSteakBoost" ) then desSpeed = ( desSpeed * 1.3 ) end
    
                local healTarget = lambda.l_TF_Medigun_HealTarget
                if IsValid( healTarget ) and ( healTarget.IsLambdaPlayer or healTarget:IsPlayer() ) and healTarget:Alive() then
                    local targetSpeed = ( healTarget.IsLambdaPlayer and healTarget.loco:GetDesiredSpeed() or healTarget:GetRunSpeed() )
                    desSpeed = max( desSpeed, desSpeed * ( targetSpeed / desSpeed ) )
                end
    
                lambda.loco:SetDesiredSpeed( desSpeed )
            end )
        end
    end
end

local function OnLambdaRespawn( lambda )
    table_Empty( lambda.l_TF_DamageEvents )

    if lambda.l_TF_RevengeCrits > 0 and lambda:CanEquipWeapon( "tf2_frontierjustice" ) then 
        lambda:SwitchWeapon( "tf2_frontierjustice" )

        if random( 1, 100 ) <= lambda:GetVoiceChance() then
            lambda:PlaySoundFile( "taunt" )
        end

        local target = lambda.l_TF_Killer
        if LambdaIsValid( target ) and lambda:CanTarget( target ) then
            lambda:AttackTarget( target )
        end
    end

    if lambda.l_TF_CollectedOrgans > 0 then
        lambda.l_TF_Medigun_ChargeMeter = min( lambda.l_TF_Medigun_ChargeMeter, 15 * min( lambda.l_TF_CollectedOrgans, 4 ) )
    else
        lambda.l_TF_Medigun_ChargeMeter = 0
    end
    lambda.l_TF_CollectedOrgans = 0

    if lambda.l_TF_HasGlovesOfRunning then
        lambda.l_TF_GRU_DrainedHP = min( lambda.l_TF_GRU_DrainedHP + lambda.l_TF_GRU_DrainRate, lambda.l_TF_GRU_MinHealth )
        local newHP = max( lambda:GetMaxHealth() - lambda.l_TF_GRU_DrainRate, lambda.l_TF_GRU_MinHealth )
        lambda:SetHealth( Round( lambda:Health() * ( newHP / lambda:GetMaxHealth() ) ) )
        lambda:SetMaxHealth( newHP )
    end

    local buffpack = lambda.l_TF_RageBuffPack
    if IsValid( buffpack ) then
        lambda:ClientSideNoDraw( buffpack, false )
        buffpack:SetNoDraw( false )
        buffpack:DrawShadow( true )
    end

    local backshield = lambda.l_TF_SniperShieldModel
    if IsValid( backshield ) then
        lambda:ClientSideNoDraw( backshield, false )
        backshield:SetNoDraw( false )
        backshield:DrawShadow( true )
    end
    
    local shield = lambda.l_TF_Shield_Entity
    if IsValid( shield ) then
        lambda:ClientSideNoDraw( shield, false )
        shield:SetNoDraw( false )
        shield:DrawShadow( true )
    end
end

local function OnLambdaInjured( lambda, dmginfo )
    if lambda.l_TF_Shield_IsEquipped then
        local shieldType = lambda.l_TF_Shield_Type

        if dmginfo:IsDamageType( DMG_BURN ) then
            dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.5 )
        elseif dmginfo:IsExplosionDamage() then
            dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.7 )
        end

        if lambda:GetIsShieldCharging() and shieldType == 3 and dmginfo:GetAttacker() != lambda and !dmginfo:IsDamageType( DMG_FALL ) then
            lambda:SetShieldChargeMeter( lambda:GetShieldChargeMeter() - dmginfo:GetDamage() )
        end
    end

    local attacker = dmginfo:GetAttacker()
    local healTarget = lambda.l_TF_Medic_HealTarget
    if lambda.l_TF_HasMedigunEquipped and IsValid( healTarget ) then
        if attacker.IsLambdaPlayer and attacker == healTarget then return true end

        if lambda:CanTarget( attacker ) and !lambda:IsSpeaking() then
            lambda:PlaySoundFile( attacker == healTarget and "witness" or "panic" )
        end
    end

    if LAMBDA_TF2:HasCritBoost( lambda, "BuffaloSteakBoost" ) then
        dmginfo:ScaleDamage( 1.2 )
    end
    
    if lambda.l_TF_SniperShieldType == 3 and dmginfo:IsDamageType( DMG_BURN + DMG_IGNITE ) then
        dmginfo:ScaleDamage( 0.5 )
    end
    
    lambda.l_TF_HypeMeter = max( 0, lambda.l_TF_HypeMeter + ( dmginfo:GetDamage() * 4 ) )
    lambda.l_TF_PreDeathDamage = dmginfo:GetDamage()
end

local function OnLambdaOnOtherInjured( lambda, victim, dmginfo, tookDamage )
    local attacker = dmginfo:GetAttacker()
    if !LAMBDA_TF2:IsValidCharacter( attacker ) or attacker == victim or attacker == lambda then return end

    if victim.l_TF_HasMedigunEquipped and LAMBDA_TF2:GetMedigunHealers( lambda )[ victim ] and lambda:CanTarget( attacker ) then
        lambda:AttackTarget( attacker )
    end
end

local function OnPostEntityTakeDamage( ent, dmginfo, tookDamage )
    local attacker = dmginfo:GetAttacker()
    if !IsValid( attacker ) then return end

    if attacker.IsLambdaPlayer and LAMBDA_TF2:HasCritBoost( attacker, "Crit-A-Cola" ) then
        LAMBDA_TF2:MarkForDeath( attacker, 5, true )
    end
    
    if !IsValid( ent ) or !LAMBDA_TF2:IsValidCharacter( ent, false ) then return end
    ent.l_TF_LastTakeDamageTime = CurTime()

    local isDead = !LAMBDA_TF2:IsValidCharacter( ent )
    if isDead then ent.l_TF_Killer = attacker end

    local inflictor = dmginfo:GetInflictor()
    if !IsValid( inflictor ) then return end
    
    local dmgType = dmginfo:GetDamageType()
    if !ent:GetIsBurning() and band( dmgType, DMG_IGNITE ) != 0 and ent:WaterLevel() < 2 then
        LAMBDA_TF2:Burn( ent, attacker, inflictor )
    end

    local isTFWeapon = ( inflictor.IsLambdaWeapon and inflictor.TF2Data )
    local meleeDmg = ( band( dmgType, DMG_MELEE ) != 0 )
    if isTFWeapon and meleeDmg then
        local hitSnd = inflictor:GetWeaponAttribute( "HitSound", {
            ")weapons/cbar_hitbod1.wav",
            ")weapons/cbar_hitbod2.wav",
            ")weapons/cbar_hitbod3.wav"
        } )
        if hitSnd then
            local critSnd = inflictor:GetWeaponAttribute( "HitCritSound" )
            if critSnd and band( dmgType, DMG_CRITICAL ) != 0 then hitSnd = critSnd end
            if istable( hitSnd ) then hitSnd = hitSnd[ random( #hitSnd ) ] end
            inflictor:EmitSound( hitSnd, nil, nil, nil, CHAN_STATIC )
        end
    end

    local dmgCustom = dmginfo:GetDamageCustom()
    if dmgCustomBurns[ dmgCustom ] or ( isTFWeapon or inflictor.l_IsTFWeapon ) and ( meleeDmg or band( dmgType, DMG_BULLET ) != 0 or band( dmgType, DMG_BUCKSHOT ) != 0 ) then
        ent:EmitSound( "Flesh.BulletImpact" )
    end   

    if tookDamage then
        local bleedingDmg = ( dmgCustom == TF_DMG_CUSTOM_BLEEDING )
        if isTFWeapon and meleeDmg or dmgCustomBurns[ dmgCustom ] or bleedingDmg then
            local dmgPos = dmginfo:GetDamagePosition()
            LAMBDA_TF2:CreateBloodParticle( dmgPos, AngleRand( -180, 180 ), ent )
        end

        if ent.IsLambdaPlayer and ( inflictor.l_IsTFBleedInflictor or inflictor.l_IsTFBurnInflictor ) then
            ent:AddGestureSequence( ent:LookupSequence( "flinch_stomach_02" ) )
        end

        if isTFWeapon and meleeDmg and !bleedingDmg then
            local bleedingTime = inflictor:GetWeaponAttribute( "BleedingDuration" )
            if bleedingTime and bleedingTime > 0 then LAMBDA_TF2:MakeBleed( ent, attacker, inflictor, bleedingTime ) end
        end

        if attacker != ent then
            local critType = LAMBDA_TF2:GetCritType( dmginfo )
            if critType != TF_CRIT_NONE then
                net.Start( "lambda_tf2_criteffects" )
                    net.WriteEntity( ent )
                    net.WriteUInt( critType, 2 )
                    net.WriteVector( ent:WorldSpaceCenter() + vector_up * 32 )
                    net.WriteBool( isDead )
                net.Broadcast()
            end
    
            if attacker.IsLambdaPlayer then 
                if isDead then
                    if attacker.l_TF_Shield_IsEquipped and attacker:GetShieldChargeMeter() != 100 and attacker.l_TF_Shield_Type == 3 and ( dmgCustom == TF_DMG_CUSTOM_CHARGE_IMPACT or meleeDmg ) then
                        attacker:SetShieldChargeMeter( attacker:GetShieldChargeMeter() + 75 )
                    end
    
                    if dmgCustom == TF_DMG_CUSTOM_BACKSTAB then 
                        attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 2, 35 )
                    elseif meleeDmg then
                        attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 1, 35 )
                    end
                end
    
                if isTFWeapon and inflictor:GetWeaponAttribute( "MarkForDeath", false ) then
                    LAMBDA_TF2:MarkForDeath( ent, 15, false, attacker )
                end
    
                local entHealth = ent:Health()
                if ent.Armor then entHealth = ( entHealth + ent:Armor() ) end
    
                attacker.l_TF_HypeMeter = min( 99, attacker.l_TF_HypeMeter + max( 5, dmginfo:GetDamage() ) )
                LAMBDA_TF2:RecordDamageEvent( attacker, dmginfo, isDead, entHealth ) 
            end
            
            if ent.IsLambdaPlayer and ent:GetIsShieldCharging() and ent.l_TF_Shield_Type == 3 and band( dmgType, DMG_FALL ) == 0 then
                ent:SetShieldChargeMeter( ent:GetShieldChargeMeter() - dmginfo:GetDamage() )
            end

            if attacker.l_TF_RageBuffType and !attacker.l_TF_RageActivated and attacker:Alive() then
                local gainRage = ( dmginfo:GetDamage() / 4 )
                if attacker.l_TF_RageBuffType == 3 then gainRage = ( gainRage * 1.25 ) end
                attacker.l_TF_RageMeter = min( attacker.l_TF_RageMeter + gainRage, 100 )
            end

            local onDealDmgFunc = inflictor.l_OnDealDamage
            if isfunction( onDealDmgFunc ) then onDealDmgFunc( inflictor, ent, dmginfo ) end

            if ent.l_TF_CoveredInMilk and !dmgCustomBurns[ dmgCustom ] and LAMBDA_TF2:IsValidCharacter( attacker ) then
                LAMBDA_TF2:GiveHealth( attacker, ( dmginfo:GetDamage() * 0.6 ), false )
            end

            if attacker.l_TF_SpeedBuffActive then
                LAMBDA_TF2:GiveHealth( attacker, ( dmginfo:GetDamage() * 0.35 ), false )
            end
        end
    end
end

local gmodDeathAnims = { 
    "death_01", 
    "death_02", 
    "death_03", 
    "death_04",
}

local tf2DeathAnims = {
    [ TF_DMG_CUSTOM_BACKSTAB ] = {
        "sniper_death_backstab",
        "pyro_death_backstab",
        "medic_death_backstab",
        "demoman_death_backstab",
        "soldier_death_backstab",
        "engineer_death_backstab",
        "spy_death_backstab",
        "scout_death_backstab",
        "heavy_death_backstab"
    },
    [ TF_DMG_CUSTOM_BURNING ] = {
        "sniper_death_burning",
        "medic_death_burning",
        "demoman_death_burning",
        "soldier_death_burning",
        "engineer_death_burning",
        "spy_death_burning",
        "scout_death_burning",
        "heavy_death_burning"
    },
    [ TF_DMG_CUSTOM_HEADSHOT ] = {
        "sniper_death_headshot",
        "pyro_death_headshot",
        "medic_death_headshot",
        "demoman_death_headshot",
        "soldier_death_headshot",
        "engineer_death_headshot",
        "spy_death_headshot",
        "scout_death_headshot",
        "heavy_death_headshot"
    }
}

function LAMBDA_TF2:CalcDominationAndRevenge( attacker, victim )
    if !IsValid( attacker ) or !attacker.IsLambdaPlayer and !attacker:IsPlayer() then return end
    if !IsValid( victim ) or !victim.IsLambdaPlayer and !victim:IsPlayer() then return end
    if attacker == victim then return end

    if !GetConVar( "lambdaplayers_tf2_allowdominations" ):GetBool() then 
        table_Empty( victim.l_TF_UnansweredKills )
        table_Empty( attacker.l_TF_UnansweredKills )
        return 
    end

    local isDominating = victim.l_TF_UnansweredKills[ attacker ]
    if isDominating and isDominating >= 4 then
        net.Start( "lambda_tf2_domination" )
            net.WriteUInt( 2, 2 )
            net.WriteEntity( attacker )
            net.WriteEntity( victim )
        net.Broadcast()
    end
    victim.l_TF_UnansweredKills[ attacker ] = 0

    local kills = attacker.l_TF_UnansweredKills[ victim ]
    if !kills then
        kills = 1
        attacker.l_TF_UnansweredKills[ victim ] = kills
    else
        kills = ( kills + 1 )
        attacker.l_TF_UnansweredKills[ victim ] = kills
    end
    if kills == 4 then
        net.Start( "lambda_tf2_domination" )
            net.WriteUInt( 1, 2 )
            net.WriteEntity( attacker )
            net.WriteEntity( victim )
        net.Broadcast()
    end
    
    -- print( attacker:Nick(), attacker.l_TF_UnansweredKills[ victim ] )
    -- print( victim:Nick(), victim.l_TF_UnansweredKills[ attacker ] )
end

local function OnLambdaKilled( lambda, dmginfo )
    local ragdoll = lambda.ragdoll
    local dmgCustom = dmginfo:GetDamageCustom()
    local doDecapitation = ( dmgCustomDecapitates[ dmgCustom ] )
    local isBurning = ( dmgCustomBurns[ dmgCustom ] or lambda:GetIsBurning() )

    if dmgCustom == TF_DMG_CUSTOM_TURNGOLD then
        if !serverRags:GetBool() and !IsValid( ragdoll ) then
            net.Start( "lambda_tf2_removecsragdoll" )
                net.WriteEntity( lambda )
            net.Broadcast()

            ragdoll = lambda:CreateServersideRagdoll( dmginfo )
        end

        if IsValid( ragdoll ) then
            LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/gold_player", physProp_Metal )
            ragdoll:EmitSound( ")weapons/saxxy_impact_gen_06.wav", 80, nil, nil, CHAN_STATIC )
        end
    else
        local turnIntoIce = false
        if dmgCustom == TF_DMG_CUSTOM_BACKSTAB then
            local inflictor = dmginfo:GetInflictor()
            turnIntoIce = ( IsValid( inflictor ) and inflictor.TF2Data and inflictor:GetWeaponAttribute( "FreezeOnBackstab", false ) )
        end

        local animTbl = tf2DeathAnims[ dmgCustom ]
        if doDecapitation or dmgCustomHeadshots[ dmgCustom ] then 
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_HEADSHOT ] 
        elseif dmgCustomBurns[ dmgCustom ] then
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_BURNING ] 
        end

        local onGround = lambda.loco:IsOnGround()
        if animTbl and ( turnIntoIce or random( 1, 100 ) <= GetConVar( "lambdaplayers_tf2_deathanimchance" ):GetInt() ) and onGround then
            local isTFAnim = true
            local index, dur = lambda:LookupSequence( animTbl[ random( #animTbl ) ] )

            if index <= 0 then
                isTFAnim = false
                index, dur = lambda:LookupSequence( gmodDeathAnims[ random( #gmodDeathAnims ) ] )
            end

            if index > 0 then
                local animEnt = ents_Create( "base_anim" )
                animEnt:SetModel( lambda:GetModel() )
                animEnt:SetPos( lambda:GetPos() )
                animEnt:SetAngles( lambda:GetAngles() )
                animEnt:Spawn()

                animEnt:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                LAMBDA_TF2:TakeNoDamage( animEnt )

                animEnt:SetSkin( lambda:GetSkin() )
                for _, v in ipairs( lambda:GetBodyGroups() ) do 
                    animEnt:SetBodygroup( v.id, lambda:GetBodygroup( v.id ) )
                end

                animEnt:SetSequence( lambda:GetSequence() )
                animEnt:ResetSequenceInfo()
                animEnt:SetCycle( lambda:GetCycle() )
                animEnt:FrameAdvance()

                animEnt.l_IsTFDeathAnimation = true
                animEnt.l_FreezeTime = 0
                animEnt.l_FrozenTime = 0
                
                local speed = Rand( 0.8, 1.1 )
                animEnt.l_PlayBackSpeed = speed

                if isTFAnim then
                    if IsSinglePlayer() then
                        local animLayer = animEnt:AddGestureSequence( index, true )
                        animEnt:SetLayerPlaybackRate( animLayer, speed )
                    else
                        SimpleTimer( FrameTime(), function()
                            if !IsValid( animEnt ) then return end
                            animEnt:SetSequence( index )
                            animEnt:ResetSequenceInfo()
                            animEnt:SetCycle( 0 )
                            animEnt:SetPlaybackRate( speed )
                        end )
                    end
                else
                    for i = 0, lambda:GetNumPoseParameters() - 1 do
                        local poseName = lambda:GetPoseParameterName( i )
                        animEnt:SetPoseParameter( lambda:GetPoseParameterName( i ), lambda:GetPoseParameter( poseName ) )
                    end

                    SimpleTimer( FrameTime(), function()
                        if !IsValid( animEnt ) then return end
                        animEnt:SetSequence( index )
                        animEnt:ResetSequenceInfo()
                        animEnt:SetCycle( 0 )
                        animEnt:FrameAdvance()
                        animEnt:SetPlaybackRate( speed )
                    end )
                end
                
                if IsSinglePlayer() then
                    net.Start( "lambdaplayers_serversideragdollplycolor" )
                        net.WriteEntity( animEnt )
                        net.WriteVector( lambda:GetPlyColor() ) 
                    net.Broadcast()
                else
                    SimpleTimer( FrameTime() * 2, function()
                        if !IsValid( animEnt ) then return end

                        net.Start( "lambdaplayers_serversideragdollplycolor" )
                            net.WriteEntity( animEnt )
                            net.WriteVector( lambda:GetPlyColor() ) 
                        net.Broadcast()
                    end )
                end

                lambda.ragdoll = animEnt
                lambda:SetNW2Entity( "lambda_serversideragdoll", animEnt )
                lambda:DeleteOnRemove( animEnt )

                local serverside = serverRags:GetBool()
                if !serverside then
                    net.Start( "lambda_tf2_removecsragdoll" )
                        net.WriteEntity( lambda )
                    net.Broadcast()
                elseif IsValid( ragdoll ) then
                    ragdoll:Remove()
                end
                ragdoll = animEnt

                local burnTime
                if isBurning then
                    burnTime = ( lambda:GetFlameRemoveTime() - CurTime() )
                    ParticleEffectAttach( "burningplayer_" .. ( lambda.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, animEnt, 0 )
                end

                local finishTime = ( CurTime() + ( dur / speed ) * ( isTFAnim and 1 or Rand( 0.8, 1 ) ) )
                lambda:Thread( function()
                    
                    while ( IsValid( animEnt ) and CurTime() < finishTime and ( animEnt.l_FreezeTime == 0 or CurTime() < animEnt.l_FreezeTime ) ) do
                        animEnt:FrameAdvance()
                        coroutine_yield() 
                    end
                    if !IsValid( animEnt ) then return end

                    if isTFAnim then
                        animEnt:SetSequence( ACT_DIERAGDOLL )
                        animEnt:ResetSequenceInfo()

                        for i = 0, animEnt:GetNumPoseParameters() - 1 do
                            animEnt:SetPoseParameter( animEnt:GetPoseParameterName( i ), 0 )
                        end
                    end

                    while ( IsValid( animEnt ) and CurTime() < animEnt.l_FrozenTime ) do
                        coroutine_yield() 
                    end
                    if !IsValid( animEnt ) then return end

                    if !serverside and !turnIntoIce then
                        lambda:CreateClientsideRagdoll( nil, animEnt )

                        if doDecapitation then
                            net.Start( "lambda_tf2_decapitate_csragdoll" )
                                net.WriteEntity( lambda )
                                net.WriteBool( false )
                            net.Broadcast()
                        end

                        if burnTime then
                            net.Start( "lambda_tf2_ignite_csragdoll" )
                                net.WriteEntity( lambda )
                                net.WriteString( "burningplayer_" .. ( lambda.l_TF_TeamColor == 1 and "blue" or "red" ) )
                                net.WriteFloat( max( 3, burnTime ) )
                            net.Broadcast()
                        end
                    else
                        local serverRag = lambda:CreateServersideRagdoll( nil, animEnt )

                        if turnIntoIce then
                            LAMBDA_TF2:TurnIntoStatue( serverRag, "models/player/shared/ice_player", physProp_Ice )
                        else
                            if doDecapitation then 
                                LAMBDA_TF2:DecapitateHead( serverRag, false )
                            end

                            if burnTime then
                                LAMBDA_TF2:AttachFlameParticle( serverRag, max( 3, burnTime ), lambda.l_TF_TeamColor )
                            end
                        end
                    end

                    animEnt:Remove()
                
                end, "TF2_DeathAnimation_" .. animEnt:EntIndex(), true )
            end
        end

        if turnIntoIce and !onGround and !serverRags:GetBool() and !IsValid( ragdoll ) then
            net.Start( "lambda_tf2_removecsragdoll" )
                net.WriteEntity( lambda )
            net.Broadcast()

            ragdoll = lambda:CreateServersideRagdoll( dmginfo )
        end

        if IsValid( ragdoll ) then
            if turnIntoIce then
                local frozenTime = ( CurTime() + Rand( 9.0, 11.0 ) )
    
                if ragdoll.l_IsTFDeathAnimation then
                    ragdoll.l_FreezeTime = ( CurTime() + ( Rand( 0.2, 0.75 ) / ragdoll.l_PlayBackSpeed ) )
                    ragdoll.l_FrozenTime = frozenTime
                    ragdoll:SetMaterial( "models/player/shared/ice_player" )
                else
                    LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/ice_player", physProp_Ice )
                    
                    if onGround then
                        ragdoll:SetSolid( SOLID_NONE )
        
                        local physObjs = {}
                        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do    
                            local bonePhys = ragdoll:GetPhysicsObjectNum( i )
                            bonePhys:SetVelocityInstantaneous( vector_origin ) 
                            bonePhys:Sleep()
                            physObjs[ #physObjs + 1 ] = bonePhys
                        end
                        
                        lambda:Thread( function()
        
                            while ( IsValid( ragdoll ) ) do
                                if CurTime() < frozenTime then
                                    for _, bonePhys in ipairs( physObjs ) do
                                        bonePhys:SetVelocityInstantaneous( vector_origin ) 
                                        bonePhys:Sleep()
                                    end
                                else
                                    for _, bonePhys in ipairs( physObjs ) do
                                        bonePhys:Wake()
                                    end
        
                                    ragdoll:SetSolid( SOLID_VPHYSICS )
                                    return 
                                end
        
                                coroutine_yield()
                            end
        
                        end, "TF2_FrozenRagdoll_" .. ragdoll:EntIndex(), true )
                    end
                end
    
                ParticleEffectAttach( "xms_icicle_impact_dryice", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )
                ragdoll:EmitSound( ")weapons/icicle_freeze_victim_01.wav", 80, nil, nil, CHAN_STATIC )
            else
                if doDecapitation then
                    LAMBDA_TF2:DecapitateHead( ragdoll, true, ( dmginfo:GetDamageForce() / 4 ) )
                end

                if isBurning then
                    LAMBDA_TF2:AttachFlameParticle( ragdoll, max( 3, ( lambda:GetFlameRemoveTime() - CurTime() ) ), lambda.l_TF_TeamColor )
                end
            end
        elseif !serverRags:GetBool() then
            if doDecapitation then
                net.Start( "lambda_tf2_decapitate_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteBool( true )
                    net.WriteVector( dmginfo:GetDamageForce() / 2 )
                net.Broadcast()
            end

            if isBurning then
                net.Start( "lambda_tf2_ignite_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteString( "burningplayer_" .. ( lambda.l_TF_TeamColor == 1 and "blue" or "red" ) )
                    net.WriteFloat( max( 3, ( lambda:GetFlameRemoveTime() - CurTime() ) ) )
                net.Broadcast()
            end

            lambda.ragdoll = NULL 
            lambda:SetNW2Entity( "lambda_serversideragdoll", lambda.ragdoll )
        end
    end

    if lambda.l_TF_Shield_IsEquipped then
        lambda:SetIsShieldCharging( false )
        lambda:SetShieldChargeMeter( 100 )

        local shield = lambda.l_TF_Shield_Entity
        local givenWeapon = shield.l_TF_GivenByWeapon
        if IsValid( shield ) and givenWeapon and lambda.l_SpawnWeapon != givenWeapon then
            LAMBDA_TF2:GiveRemoveChargeShield( lambda )
        end
    end

    local attacker = dmginfo:GetAttacker()
    LAMBDA_TF2:CalcDominationAndRevenge( attacker, lambda )

    if IsValid( attacker ) and attacker.IsLambdaPlayer then 
        local wepName = attacker:GetWeaponName()
        if wepName == "tf2_eyelander" and doDecapitation then
            attacker.l_TF_Decapitations = ( attacker.l_TF_Decapitations + lambda.l_TF_Decapitations + lambda.l_TF_CollectedOrgans )
        elseif wepName == "tf2_vitasaw" then
            attacker.l_TF_CollectedOrgans = ( attacker.l_TF_CollectedOrgans + lambda.l_TF_CollectedOrgans + lambda.l_TF_Decapitations )
        end
    end
    
    lambda:SimpleTimer( 0.1, function()
        lambda.l_TF_Decapitations = 0
    end, true )

    lambda.l_TF_IsUsingItem = false
    lambda.l_TF_CrikeyMeter = 0
    lambda.l_TF_CrikeyMeterFull = false

    if lambda:GetWeaponName() == "tf2_frontierjustice" and lambda.l_TF_RevengeCrits > 0 then
        lambda.l_TF_RevengeCrits = 0
    end
    lambda.l_TF_RevengeCrits = min( lambda.l_TF_RevengeCrits + lambda.l_TF_FrontierJusticeKills, 35 )
    lambda.l_TF_FrontierJusticeKills = 0

    if lambda.l_TF_HasGlovesOfRunning then
        lambda.l_TF_GRU_DrainedHP = 0
        lambda:SetMaxHealth( lambda.l_TF_GRU_MaxHealth )
    end

    for barIndex, bar in ipairs( lambda.l_TF_DalokohsBars ) do
        lambda:SetMaxHealth( Round( lambda:GetMaxHealth() / bar.HealthRatio ) )
        table_remove( lambda.l_TF_DalokohsBars, barIndex )
    end

    lambda.l_TF_RageActivated = false
    lambda.l_TF_RageMeter = 0
    lambda.l_TF_RagePulseCount = 0
    lambda.l_TF_RageNextPulseTime = 0

    lambda.l_TF_SniperShieldRechargeT = 0
    lambda.l_TF_HypeMeter = 0
    lambda.l_TF_ThrownBaseball = false
    lambda.l_TF_AtomicPunched = false
    lambda.l_TF_AtomicPunched_SlowdownScale = false
    lambda.l_TF_AtomicPunched_DamageTaken = 0
    table_Empty( lambda.l_TF_MedicsToIgnoreList )

    local bonkTrail = lambda.l_TF_AtomicPunched_Trail
    if IsValid( bonkTrail ) then 
        bonkTrail:SetParent()
        SafeRemoveEntityDelayed( bonkTrail, 1 ) 
    end
    lambda.l_TF_AtomicPunched_Trail = nil

    local wepent = lambda:GetWeaponENT()
    local dropAmmo = GetConVar( "lambdaplayers_tf2_dropammobox" ):GetInt()
    if dropAmmo == 1 and wepent.TF2Data or dropAmmo == 2 then
        local ammopack
        if lambda.l_TF_HasEdibles then
            ammopack = LAMBDA_TF2:CreateMedkit( wepent:GetPos(), "models/items/ammopack_medium.mdl", ( random( 1, 9 ) == 1 and 0.6 or 0.3 ), false )
        else
            ammopack = LAMBDA_TF2:CreateAmmobox( wepent:GetPos(), "models/items/ammopack_medium.mdl", 0.5 )
        end
        if IsValid( ammopack ) then
            ammopack:SetAngles( wepent:GetUp():Angle() )
            ammopack:SetOwner( lambda )

            local vecImpulse = vector_origin
            vecImpulse = ( vecImpulse + ammopack:GetUp() * Rand( -0.25, 0.25 ) + ammopack:GetRight() * Rand( -0.25, 0.25 ) ):GetNormalized()
            vecImpulse = ( vecImpulse * Rand( 100, 150 ) + ammopack:GetVelocity() )
        
            local speed = vecImpulse:Length()
            if speed > 300 then
                vecImpulse = ( vecImpulse * ( 300 / speed ) )
            end

            local phys = ammopack:GetPhysicsObject()
            if IsValid( phys ) then
                phys:SetMass( 25 )
                phys:SetVelocityInstantaneous( vecImpulse )
                phys:SetAngleVelocityInstantaneous( Vector( 0, Rand( 0, 100 ), 0 ) )
            end
        end
    end

    local numPacks = 0
    local oldestPack = nil
    for _, oldAmmopack in ipairs( FindByModel( "models/items/ammopack_medium.mdl" ) ) do
        if !IsValid( oldAmmopack ) or oldAmmopack:GetOwner() != lambda then continue end
        numPacks = ( numPacks + 1 )

        if oldestPack and oldestPack:GetCreationTime() <= oldAmmopack:GetCreationTime() then continue end
        oldestPack = oldAmmopack
    end
    if numPacks > GetConVar( "lambdaplayers_tf2_ammoboxlimit" ):GetInt() and oldestPack then
        oldestPack:Remove()
    end

    for _, dropEnt in ipairs( lambda.l_TF_DropOnDeathEntities ) do
        if !IsValid( dropEnt ) or dropEnt:GetNoDraw() then continue end

        net.Start( "lambdaplayers_createclientsidedroppedweapon" )
            net.WriteEntity( dropEnt )
            net.WriteEntity( lambda )
            net.WriteVector( lambda:GetPhysColor() )
            net.WriteString( lambda:GetWeaponName() )
            net.WriteVector( dmginfo:GetDamageForce() )
            net.WriteVector( dmginfo:GetDamagePosition() )
        net.Broadcast()
    end

    local buffpack = lambda.l_TF_RageBuffPack
    if IsValid( buffpack ) then
        lambda:ClientSideNoDraw( buffpack, true )
        buffpack:SetNoDraw( true )
        buffpack:DrawShadow( false )
        buffpack:SetBodygroup( 1, 0 )
    end

    local backshield = lambda.l_TF_SniperShieldModel
    if IsValid( backshield ) then
        lambda:ClientSideNoDraw( backshield, true )
        backshield:SetNoDraw( true )
        backshield:DrawShadow( false )
    end

    local shield = lambda.l_TF_Shield_Entity
    if IsValid( shield ) then
        lambda:ClientSideNoDraw( shield, true )
        shield:SetNoDraw( true )
        shield:DrawShadow( false )
    end

    if lambda.l_TF_Medigun_ChargeReleased then
        lambda:EmitSound( lambda.l_TF_MedigunChargeDrainSound, nil, nil, nil, CHAN_STATIC )

        local releaseSnd = lambda.l_TF_Medigun_ChargeReleaseSound
        if releaseSnd then 
            releaseSnd:Stop()
            releaseSnd = nil
            lambda.l_TF_Medigun_ChargeReleaseSound = releaseSnd
        end
    end

    if lambda.l_TF_Medigun_ChargeReady then
        lambda:EmitSound( "player/medic_charged_death.wav", 75, nil, nil, CHAN_STATIC )

        local chargeSnd = lambda.l_TF_Medigun_ChargeSound
        if chargeSnd then 
            chargeSnd:Stop()
            chargeSnd = nil
            lambda.l_TF_Medigun_ChargeSound = chargeSnd
        end
    end

    net.Start( "lambda_tf2_medigun_chargeeffect" )
        net.WriteEntity( weapon )
        net.WriteBool( false )
    net.Broadcast()

    lambda.l_TF_Medigun_ChargeReleased = false
    lambda.l_TF_Medigun_ChargeReady = false

    for name, item in pairs( lambda.l_TF_Inventory ) do
        if item.NextUseTime then
            item.IsReady = true
            item.NextUseTime = 0
        else
            item.IsReady = LAMBDA_TF2.InventoryItems[ name ].Cooldown( lambda )
        end
    end
    lambda.l_TF_PreInventorySwitchWeapon = nil

    dmginfo:SetDamage( lambda.l_TF_PreDeathDamage or 0 )
    OnPostEntityTakeDamage( lambda, dmginfo, true )

    for _, v in ipairs( GetLambdaPlayers() ) do
        if v == lambda then continue end
        OnLambdaOnOtherInjured( v, lambda, dmginfo, true )
    end
end

local function OnLambdaSwitchWeapon( lambda, weapon, data )
    if data.origin != "Team Fortress 2" then weapon.TF2Data = nil end
    
    local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
    if preInvWep and lambda:GetWeaponName() == preInvWep.Name then 
        lambda.l_Clip = preInvWep.Clip
    end

    lambda.l_TF_HealRateMultiplier = ( data.healratemult or 1.0 )
    lambda.l_TF_AirBlastVulnerability = ( data.airblast_vulnerability_multiplier or 1.0 )

    lambda.l_TF_HasMedigunEquipped = ( data.ismedigun or false )
    lambda.l_TF_MedigunHealRateMultiplier = ( data.medigunhealrate or 1.0 )
    lambda.l_TF_MedicTargetFilter = data.medictargetfilter
    lambda.l_TF_MedigunChargeReleaseSound = ( data.chargereleasesnd or "player/invulnerable_on.wav" )
    lambda.l_TF_MedigunChargeDrainSound = ( data.chargedrainedsnd or "player/invulnerable_off.wav" )

    local holsterMult = lambda.l_TF_HolsterTimeMultiplier
    if holsterMult then
        local deployT = lambda.l_WeaponUseCooldown
        lambda.l_WeaponUseCooldown = ( deployT - ( deployT - CurTime() ) + ( ( data.deploydelay or 0.1 ) * holsterMult ) )
    end
    lambda.l_TF_HolsterTimeMultiplier = data.holstermult

    local gruHP = lambda.l_TF_GRU_DrainedHP
    lambda.l_TF_HasGlovesOfRunning = ( data.isgru or false )
    if lambda.l_TF_HasGlovesOfRunning then
        gruHP = min( gruHP + lambda.l_TF_GRU_DrainRate, lambda.l_TF_GRU_MinHealth )
        lambda.l_TF_GRU_DrainedHP = gruHP
        
        local newHP = max( lambda:GetMaxHealth() - lambda.l_TF_GRU_DrainRate, lambda.l_TF_GRU_MinHealth )
        lambda:SetHealth( Round( lambda:Health() * ( newHP / lambda:GetMaxHealth() ) ) )
        lambda:SetMaxHealth( newHP )
    elseif gruHP and gruHP > 0 then
        gruHP = Round( gruHP * ( lambda:GetMaxHealth() / ( lambda.l_TF_GRU_MaxHealth - gruHP ) ) )
        lambda.l_TF_GRU_DrainedHP = gruHP

        lambda.l_TF_GRU_MaxHealth = ( lambda:GetMaxHealth() + gruHP )
        lambda.l_TF_GRU_MinHealth = Round( lambda.l_TF_GRU_MaxHealth * 0.5 )
        lambda.l_TF_GRU_DrainRate = Round( lambda.l_TF_GRU_MaxHealth * 0.33 )
    end

    lambda.l_TF_HasEdibles = ( data.isedible or false )
    lambda.l_TF_CantReplenishClip = ( data.cantreplenishclip or false )
    lambda.l_TF_Shield_ChargeDrainRateMult = ( data.shieldchargedrainrate or 1.0 )

    if !lambda.l_TF_HasMedigunEquipped then
        if lambda.l_TF_Medigun_ChargeSound then 
            lambda.l_TF_Medigun_ChargeSound:Stop()
            lambda.l_TF_Medigun_ChargeSound = nil
        end

        net.Start( "lambda_tf2_medigun_chargeeffect" )
            net.WriteEntity( weapon )
            net.WriteBool( false )
        net.Broadcast()

        net.Start( "lambda_tf2_medigun_beameffect" )
            net.WriteEntity( weapon )
            net.WriteEntity( NULL )
        net.Broadcast()
    end
end

local function OnLambdaChangeState( lambda, old, new )
    if new == "Laughing" then 
        if old == "HealWithMedigun" and ( lambda.l_TF_Medigun_ChargeReleased or random( 1, 4 ) != 1 ) then
            return true
        end

        if ( GetConVar( "lambdaplayers_tf2_alwaysuseschadenfreude" ):GetBool() or lambda:GetWeaponENT().TF2Data ) then
            lambda:SetState( "Schadenfreude" )
            return true
        end
    end

    if lambda:Alive() then
        if old == "UseTFItem" and lambda.l_TF_IsUsingItem then 
            lambda.l_TF_PreUseItemState = new
            return true 
        end

        if lambda.l_TF_IsStunned and lambda.l_TF_StunMovement then
            lambda.l_TF_PreStunState = new
            return true
        end
    end

    local healTarget = lambda.l_TF_Medic_HealTarget
    if old == "HealWithMedigun" and new == "Retreat" and IsValid( healTarget ) and LAMBDA_TF2:IsValidCharacter( healTarget ) then return true end
end

local function OnLambdaCanSwitchWeapon( lambda, name, data )
    if lambda.l_TF_IsUsingItem then return true end
    if data.ismedigun and lambda:InCombat() then return true end
    if !data.ismelee and LAMBDA_TF2:HasCritBoost( lambda, "BuffaloSteakBoost" ) then return true end

    local invWep = lambda.l_TF_Inventory[ name ]
    if invWep then 
        if !invWep.IsReady then return true end
    else
        if data.isbuffpack then
            local buffType = lambda.l_TF_RageBuffType
            if !buffType or buffType != data.bufftype then return true end
        end
    end

    local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
    if preInvWep and name != preInvWep.Name then return true end
end

local function OnLambdaAttackTarget( lambda, target )
    if lambda.l_TF_IsUsingItem then return true end

    local state = lambda:GetState()
    if state == "Schadenfreude" then return true end

    if state == "HealWithMedigun" then
        local healTarget = lambda.l_TF_Medigun_HealTarget
        if LambdaIsValid( healTarget ) and healTarget.IsLambdaPlayer and !healTarget.l_TF_HasMedigunEquipped and ( !healTarget:InCombat() or healTarget:GetEnemy() != target ) and healTarget:CanTarget( target ) then
            healTarget:AttackTarget( target )
        end
        return true
    end
end

local function OnLambdaCanTarget( lambda, ent )
    local medicList = lambda.l_TF_MedicsToIgnoreList[ ent ]
    if medicList and CurTime() <= medicList and ( !lambda:InCombat() or ent.l_TF_Medic_HealTarget != lambda:GetEnemy() ) then return true end
    if ent.l_TF_HasMedigunEquipped and LAMBDA_TF2:GetMedigunHealers( lambda )[ ent ] then return true end
end

local function OnLambdaBeginMove( lambda, pos, onNavmesh )
    lambda.l_TF_GoingAfterMedkit = nil
    if random( 1, 4 ) == 1 or lambda:InCombat() or lambda:IsPanicking() or LAMBDA_TF2:GetMedigunHealers( lambda, true ) != 0 then return end
    if lambda:Health() >= ( lambda:GetMaxHealth() * Rand( 0.66, 0.9 ) ) and !LAMBDA_TF2:IsBleeding( lambda ) and !LAMBDA_TF2:IsBurning( lambda ) then return end

    local medkits = lambda:FindInSphere( nil, random( 300, 1500 ), function( ent )
        return ( ent.IsLambdaTFMedkit and !ent.IsRespawning or ent.IsLambdaTFLocker )
    end )
    if #medkits == 0 then return end
    
    local rndMedkit = medkits[ random( #medkits ) ]
    lambda:SetRun( true )
    lambda:RecomputePath( rndMedkit )
    lambda.l_TF_GoingAfterMedkit = rndMedkit

    if rndMedkit.IsLambdaTFLocker then
        local path = lambda.l_CurrentPath
        if IsValid( path ) then path:SetGoalTolerance( 50 ) end
    end
end

hook_Add( "LambdaOnRespawn", "LambdaTF2_OnLambdaRespawn", OnLambdaRespawn )
hook_Add( "LambdaOnThink", "LambdaTF2_OnLambdaThink", OnLambdaThink )
hook_Add( "LambdaOnInjured", "LambdaTF2_OnLambdaOnInjured", OnLambdaInjured )
hook_Add( "LambdaOnOtherInjured", "LambdaTF2_OnLambdaOnOtherInjured", OnLambdaOnOtherInjured )
hook_Add( "LambdaOnKilled", "LambdaTF2_OnLambdaKilled", OnLambdaKilled )
hook_Add( "LambdaOnChangeState", "LambdaTF2_OnLambdaChangeState", OnLambdaChangeState )
hook_Add( "LambdaCanSwitchWeapon", "LambdaTF2_OnLambdaCanSwitchWeapon", OnLambdaCanSwitchWeapon )
hook_Add( "LambdaOnSwitchWeapon", "LambdaTF2_OnLambdaSwitchWeapon", OnLambdaSwitchWeapon )
hook_Add( "LambdaOnAttackTarget", "LambdaTF2_OnLambdaAttackTarget", OnLambdaAttackTarget )
hook_Add( "LambdaCanTarget", "LambdaTF2_OnLambdaCanTarget", OnLambdaCanTarget )
hook_Add( "LambdaOnBeginMove", "LambdaTF2_OnLambdaBeginMove", OnLambdaBeginMove )

---

local function OnEntityTakeDamage( ent, dmginfo )
    ent:SetNW2Bool( "lambda_tf2_decapitatehead", false )
    ent:SetNW2Bool( "lambda_tf2_turnintoice", false )
    ent:SetNW2Bool( "lambda_tf2_turnintogold", false )

    if ent.l_TF_FixedBulletDamage then
        dmginfo:SetDamage( ent.l_TF_FixedBulletDamage * wepDmgScale:GetFloat() )
        ent.l_TF_FixedBulletDamage = false
    end

    if LAMBDA_TF2:IsValidCharacter( ent ) then
        local inflictor = dmginfo:GetInflictor()
        local attacker = dmginfo:GetAttacker()
        local dmgCustom = dmginfo:GetDamageCustom()

        local damageBlocked = false
        if ent.l_TF_InvulnerabilityTime and CurTime() <= ent.l_TF_InvulnerabilityTime then 
            ent:EmitSound( "SolidMetal.BulletImpact" )
            damageBlocked = true 
        end
        if ent.l_TF_AtomicPunched then
            if dmginfo:IsDamageType( DMG_BULLET + DMG_MELEE + DMG_CLUB ) then
                ent:EmitSound( "player/pl_scout_jump" .. random( 1, 4 ) .. ".wav", 65, random( 90, 110 ), nil, CHAN_STATIC )
            end
            damageBlocked = true 
        end
        if CurTime() <= ent.l_TF_FireImmunity and dmginfo:IsDamageType( DMG_BURN + DMG_SLOWBURN + DMG_IGNITE ) then
            damageBlocked = true 
        end
        if dmgCustom == TF_DMG_CUSTOM_BACKSTAB and ent.l_TF_SniperShieldType == 1 and LAMBDA_TF2:IsInventoryItemReady( ent, "tf2_razorback" ) then
            damageBlocked = true
            dmginfo:SetDamage( 0 )

            ScreenShake( ent:GetPos(), 25, 150, 1, 50 )
            ent:EmitSound( "player/spy_shield_break.wav", nil, nil, nil, CHAN_STATIC )
            ent:AttackTarget( attacker )
            
            for i = 1, 2 do
                local shieldGib = ents_Create( "prop_physics" )
                shieldGib:SetModel( "models/player/items/sniper/knife_shield_gib" .. i .. ".mdl" )
                shieldGib:SetPos( ent:GetPos() )
                shieldGib:SetAngles( ent:GetAngles() + Angle( 0, 0, 0 ) )
                shieldGib:SetOwner( ent )
                shieldGib:Spawn()

                shieldGib:SetModelScale( 0.9 )
                shieldGib:Activate()
                shieldGib:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                SafeRemoveEntityDelayed( shieldGib, 10 )

                local phys = shieldGib:GetPhysicsObject()
                if IsValid( phys ) then
                    phys:ApplyForceCenter( dmginfo:GetDamageForce() / 100 )
                end
            end

            local backShield = ent.l_TF_SniperShieldModel
            if IsValid( backShield ) then
                ent:ClientSideNoDraw( backShield, true )
                backShield:SetNoDraw( true )
                backShield:DrawShadow( false )
            end

            ent.l_TF_SniperShieldRechargeT = ( CurTime() + 30 )
            LAMBDA_TF2:AddInventoryCooldown( ent, "tf2_razorback" )

            if attacker.IsLambdaPlayer then
                attacker.l_WeaponUseCooldown = ( CurTime() + 2.0 )
                
                if random( 1, 100 ) <= attacker:GetVoiceChance() then
                    attacker:PlaySoundFile( "panic" )
                end
            end
        end

        if IsValid( inflictor ) and attacker != ent then
            local isTFWeapon = ( inflictor.IsLambdaWeapon and inflictor.TF2Data )

            ent:SetNW2Bool( "lambda_tf2_decapitatehead", ( dmgCustomDecapitates[ dmgCustom ] or false ) )
            ent:SetNW2Bool( "lambda_tf2_turnintoice", ( isTFWeapon and dmgCustom == TF_DMG_CUSTOM_BACKSTAB and inflictor:GetWeaponAttribute( "FreezeOnBackstab", false ) ) )
            ent:SetNW2Bool( "lambda_tf2_turnintogold", ( dmgCustom == TF_DMG_CUSTOM_TURNGOLD ) )
    
            local critType = LAMBDA_TF2:GetCritType( dmginfo )
            if critType != TF_CRIT_FULL and ( dmgCustom == TF_DMG_CUSTOM_BACKSTAB or dmgCustomHeadshots[ dmgCustom ] ) then
                critType = TF_CRIT_FULL
            else
                if critType == TF_CRIT_NONE and ( ent.l_TF_CoveredInUrine or ent.l_TF_CoveredInMilk or LAMBDA_TF2:IsMarkedForDeath( ent ) or attacker.l_TF_OffenseBuffActive ) then
                    critType = TF_CRIT_MINI
                end
                if critType == TF_CRIT_MINI and isTFWeapon and inflictor:GetWeaponAttribute( "MiniCritsToFull", false ) then
                    critType = TF_CRIT_FULL
                end

                if LAMBDA_TF2:IsValidCharacter( attacker ) then
                    local critBoost = attacker:GetCritBoostType()
                    if critBoost > critType then critType = critBoost end
                end
            end

            if ent.l_TF_DefenseBuffActive and dmgCustom != TF_DMG_CUSTOM_BACKSTAB and !dmginfo:IsDamageType( DMG_CRUSH ) then
                critType = TF_CRIT_NONE
                dmginfo:ScaleDamage( 0.65 )
            end

            local critDamage = 0
            local damage = dmginfo:GetDamage()
            if critType == TF_CRIT_FULL then
                critDamage = ( ( TF_DAMAGE_CRIT_MULTIPLIER - 1 ) * damage )
            elseif critType == TF_CRIT_MINI then
                critDamage = ( ( TF_DAMAGE_MINICRIT_MULTIPLIER - 1 ) * damage )
            end
            LAMBDA_TF2:SetCritType( dmginfo, critType )
            
            local infKillicon = inflictor.l_killiconname
            if infKillicon then
                local dmgKillicon = dmgCustomKillicons[ dmgCustom ]
                if dmgKillicon and infKillicon != dmgKillicon then
                    inflictor.l_killiconname = dmgKillicon
                    SimpleTimer( 0, function() 
                        if !IsValid( inflictor ) or inflictor.l_killiconname != dmgKillicon then return end 
                        inflictor.l_killiconname = infKillicon 
                    end )
                end
            end

            if isTFWeapon or inflictor.l_IsTFWeapon then
                dmginfo:SetBaseDamage( dmginfo:GetDamage() )

                local doShortRangeDistanceIncrease = ( critType == TF_CRIT_NONE or critType != TF_CRIT_FULL )
                local doLongRangeDistanceDecrease = ( critType == TF_CRIT_NONE ) 

                local rndDmgSpread = 0.1
                local minSpread = ( 0.5 - rndDmgSpread )
                local maxSpread = ( 0.5 + rndDmgSpread )
        
                if dmginfo:IsDamageType( DMG_USEDISTANCEMOD ) then
                    local attackerPos = attacker:WorldSpaceCenter()
                    local optimalDist = 512
        
                    local dist = max( 1, ( attackerPos:Distance( ent:WorldSpaceCenter() ) ) )
                        
                    local centerSpread = LAMBDA_TF2:RemapClamped( dist / optimalDist, 0, 2, 1, 0 )
                    if centerSpread > 0.5 and doShortRangeDistanceIncrease or centerSpread <= 0.5 then
                        if centerSpread > 0.5 and dmginfo:IsDamageType( DMG_NOCLOSEDISTANCEMOD ) then
                            centerSpread = LAMBDA_TF2:RemapClamped( centerSpread, 0.5, 1, 0.5, 0.65 )
                        end

                        minSpread = max( 0, ( centerSpread - rndDmgSpread ) )
                        maxSpread = min( 1, ( centerSpread + rndDmgSpread ) )
                    end
                end

                local rndDamage = ( damage * 0.5 )
                local rndRangeVal = ( minSpread + rndDmgSpread )

                local dmgVariance = LAMBDA_TF2:RemapClamped( rndRangeVal, 0, 1, -rndDamage, rndDamage )
                if doShortRangeDistanceIncrease and dmgVariance > 0 or doLongRangeDistanceDecrease then 
                    damage = ( damage + dmgVariance ) 
                end
            end

            local totalDamage = ( damage + critDamage )
            dmginfo:SetDamageForce( dmginfo:GetDamageForce() * ( totalDamage / dmginfo:GetDamage() ) )
            dmginfo:SetDamage( totalDamage )
            dmginfo:SetDamageBonus( critDamage )

            if ( isTFWeapon or inflictor.l_IsTFWeapon ) and !dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) and ( !attacker.IsLambdaPlayer or attacker:CanTarget( ent ) ) then 
                local vecDir = ( ( inflictor:WorldSpaceCenter() - vector_up * 10 ) - ent:WorldSpaceCenter() ):GetNormalized()
                LAMBDA_TF2:ApplyPushFromDamage( ent, dmginfo, vecDir )     
            end
        end

        if damageBlocked then 
            if ent.l_TF_AtomicPunched then
                ent.l_TF_AtomicPunched_DamageTaken = ( ent.l_TF_AtomicPunched_DamageTaken + dmginfo:GetDamage() )
            end
            
            return true 
        end
    end
end

local function OnServerThink()
    if CurTime() >= LAMBDA_TF2.NextTrailListCheckT then
        local trailList = LAMBDA_TF2.TrailList
        for index, trail in ipairs( trailList ) do
            if !IsValid( trail ) then
                table_remove( trailList, index )
                continue 
            end

            if trail.l_HasParent then
                local parent = trail:GetParent()
                if !IsValid( parent ) or LAMBDA_TF2:IsValidCharacter( parent, false ) and !LAMBDA_TF2:IsValidCharacter( parent ) then
                    trail:SetParent()
                    SafeRemoveEntityDelayed( trail, 1 )
                    table_remove( trailList, index )
                    continue 
                end
            end
        end
        LAMBDA_TF2.NextTrailListCheckT = ( CurTime() + 1 )
    end
end

local function OnCreateEntityRagdoll( owner, ragdoll )
    if owner.IsLambdaPlayer or ragdoll.l_TF_IsTurnedStatue then return end

    if owner:GetNW2Bool( "lambda_tf2_turnintogold", false ) then
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/gold_player", physProp_Metal )
        ragdoll:EmitSound( ")weapons/saxxy_impact_gen_06.wav", 80, nil, nil, CHAN_STATIC )
    elseif owner:GetNW2Bool( "lambda_tf2_turnintoice", false ) then
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/ice_player", physProp_Ice )
        ragdoll:SetSolid( SOLID_NONE )

        local physObjs = {}
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do    
            local bonePhys = ragdoll:GetPhysicsObjectNum( i )
            bonePhys:SetVelocityInstantaneous( vector_origin ) 
            bonePhys:Sleep()
            physObjs[ #physObjs + 1 ] = bonePhys
        end
        
        local frozenTime = ( CurTime() + Rand( 9.0, 11.0 ) )
        LambdaCreateThread( function()
            while ( IsValid( ragdoll ) ) do
                if CurTime() < frozenTime then
                    for _, bonePhys in ipairs( physObjs ) do
                        bonePhys:SetVelocityInstantaneous( vector_origin ) 
                        bonePhys:Sleep()
                    end
                else
                    for _, bonePhys in ipairs( physObjs ) do
                        bonePhys:Wake()
                    end

                    ragdoll:SetSolid( SOLID_VPHYSICS )
                    return 
                end

                coroutine_yield()
            end
        end )

        ParticleEffectAttach( "xms_icicle_impact_dryice", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )
        ragdoll:EmitSound( ")weapons/icicle_freeze_victim_01.wav", 80, nil, nil, CHAN_STATIC )
    else
        if owner:GetNW2Bool( "lambda_tf2_decapitatehead", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ragdoll:GetVelocity() * 5 )
        end
        
        if owner:GetIsBurning() then
            LAMBDA_TF2:AttachFlameParticle( ragdoll, max( 3, ( owner:GetFlameRemoveTime() - CurTime() ) ), LAMBDA_TF2:GetTeamColor( owner ) )
        end
    end
end

local function OnScaleEntityDamage( ent, hitgroup, dmginfo )
    local inflictor = dmginfo:GetInflictor()
    if !IsValid( inflictor ) or !inflictor.IsLambdaWeapon or !inflictor.TF2Data then
        ent.l_TF_FixedBulletDamage = false
    else
        ent.l_TF_FixedBulletDamage = dmginfo:GetDamage()
    end
end

local function OnEntityFireBullets( ent, data )
    if !IsValid( ent ) or !ent.l_TF_NextCritShootSoundT or CurTime() <= ent.l_TF_NextCritShootSoundT then return end
    ent.l_TF_NextCritShootSoundT = CurTime()

    if ent:IsPlayer() then 
        local critBoost = ent:GetCritBoostType()
        if critBoost != TF_CRIT_NONE then
            ent:EmitSound( "lambdaplayers/tf2/crit_shoot.mp3", nil, nil, ( critBoost == TF_CRIT_MINI and 0.5 or 0.75 ), CHAN_STATIC )
        end
    end
end

local function OnPlayerDeath( ply, inflictor, attacker )
    SimpleTimer( 0, function() 
        LAMBDA_TF2:CalcDominationAndRevenge( attacker, ply )
    end )
end

hook_Add( "PlayerDeath", "LambdaTF2_OnPlayerDeath", OnPlayerDeath )
hook_Add( "EntityTakeDamage", "LambdaTF2_OnEntityTakeDamage", OnEntityTakeDamage )
hook_Add( "PostEntityTakeDamage", "LambdaTF2_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
hook_Add( "Think", "LambdaTF2_OnServerThink", OnServerThink )
hook_Add( "CreateEntityRagdoll", "LambdaTF2_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
hook_Add( "ScalePlayerDamage", "LambdaTF2_OnScalePlayerDamage", OnScaleEntityDamage )
hook_Add( "ScaleNPCDamage", "LambdaTF2_OnScaleNPCDamage", OnScaleEntityDamage )
hook_Add( "EntityFireBullets", "LambdaTF2_OnEntityFireBullets", OnEntityFireBullets )