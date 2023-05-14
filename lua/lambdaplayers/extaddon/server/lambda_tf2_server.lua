local IsValid = IsValid
local net = net
local SimpleTimer = timer.Simple
local random = math.random
local min = math.min
local VectorRand = VectorRand
local isnumber = isnumber
local CurTime = CurTime
local coroutine_yield = coroutine.yield
local istable = istable
local ents_Create = ents.Create
local ParticleEffect = ParticleEffect
local ParticleEffectAttach = ParticleEffectAttach
local GetConVar = GetConVar
local band = bit.band
local string_Explode = string.Explode
local Rand = math.Rand
local Clamp = math.Clamp
local Round = math.Round
local max = math.max
local ipairs = ipairs
local FrameTime = FrameTime
local DamageInfo = DamageInfo
local SafeRemoveEntity = SafeRemoveEntity
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local SpriteTrail = util.SpriteTrail
local Decal = util.Decal
local table_Empty = table.Empty
local table_remove = table.remove
local table_Count = table.Count
local FindInSphere = ents.FindInSphere
local Weld = constraint.Weld
local SetPhysProp = construct.SetPhysProp
local TraceLine = util.TraceLine
local TraceHull = util.TraceHull

local pushScale = GetConVar( "phys_pushscale" )
local ignorePlys = GetConVar( "ai_ignoreplayers" )
local explosionTrTbl = { 
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    collisiongroup = COLLISION_GROUP_PROJECTILE,
    filter = function( ent )
        if LAMBDA_TF2:IsValidCharacter( ent, false ) then return false end
    end
}

LAMBDA_TF2 = LAMBDA_TF2 or {}

TF_DMG_CUSTOM_HALF_FALLOFF              = 1
TF_DMG_CUSTOM_RADIUS_MAX                = 2
TF_DMG_CUSTOM_USEDISTANCEMOD            = 4
TF_DMG_CUSTOM_MELEE                     = 8
TF_DMG_CUSTOM_IGNITE                    = 16
TF_DMG_CUSTOM_NOCLOSEDISTANCEMOD        = 32
TF_DMG_CUSTOM_CRITICAL                  = 64
TF_DMG_CUSTOM_MINICRITICAL              = 128
TF_DMG_CUSTOM_HEADSHOT                  = 256
TF_DMG_CUSTOM_BACKSTAB                  = 512
TF_DMG_CUSTOM_BURNING                   = 1024
TF_DMG_CUSTOM_BURNING_BEHIND            = 2048
TF_DMG_CUSTOM_DECAPITATION              = 4096
TF_DMG_CUSTOM_CHARGE_IMPACT             = 8192
TF_DMG_CUSTOM_BLEEDING                  = 16384
TF_DMG_CUSTOM_TURNGOLD                  = 32768
TF_DMG_CUSTOM_STICKBOMB_EXPLOSION       = 65536
TF_DMG_CUSTOM_HEADSHOT_REVOLVER         = 131072
TF_DMG_CUSTOM_KATANA_DUEL               = 262144
TF_DMG_CUSTOM_GLOVES_LAUGHING           = 524288
TF_DMG_CUSTOM_BACKSTAB_HIDDEN           = 1048576
TF_DMG_CUSTOM_BURNING_PHLOG             = 2097152
TF_DMG_CUSTOM_CANNONBALL_PUSH           = 4194304
TF_DMG_CUSTOM_PLASMA                    = 8388608
TF_DMG_CUSTOM_PLASMA_CHARGED            = 16777216

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

local physProp_Metal = { Material = "metal" }
local physProp_Ice = { Material = "ice" }

util.AddNetworkString( "lambda_tf2_addobjectorimage" )
util.AddNetworkString( "lambda_tf2_dispatchcolorparticle" )
util.AddNetworkString( "lambda_tf2_addoverheadeffect" )
util.AddNetworkString( "lambda_tf2_removeoverheadeffect" )
util.AddNetworkString( "lambda_tf2_domination" )
util.AddNetworkString( "lambda_tf2_stopnamedparticle" )
util.AddNetworkString( "lambda_tf2_removecsragdoll" )
util.AddNetworkString( "lambda_tf2_removecsprop" )
util.AddNetworkString( "lambda_tf2_attackbonuseffect" )
util.AddNetworkString( "lambda_tf2_ignite_csragdoll" )
util.AddNetworkString( "lambda_tf2_decapitate_csragdoll" )
util.AddNetworkString( "lambda_tf2_decapitate_sendgibdata" )
util.AddNetworkString( "lambda_tf2_stuneffect" )
util.AddNetworkString( "lambda_tf2_medigun_beameffect" )
util.AddNetworkString( "lambda_tf2_medigun_chargeeffect" )
util.AddNetworkString( "lambda_tf2_removempragdoll" )
util.AddNetworkString( "lambda_tf2_turncsragdollintostatue" )

net.Receive( "lambda_tf2_decapitate_sendgibdata", function()
    LAMBDA_TF2:CreateGib( net.ReadVector(), net.ReadAngle(), net.ReadVector(), "models/lambdaplayers/tf2/gibs/humanskull.mdl" )
end )

net.Receive( "lambda_tf2_removempragdoll", function()
    local ragdoll = net.ReadEntity()
    if IsValid( ragdoll ) then ragdoll:Remove() end
end )

local backstabDeathAnims = {
    "sniper_death_backstab",
    "pyro_death_backstab",
    "medic_death_backstab",
    "demoman_death_backstab",
    "soldier_death_backstab",
    "engineer_death_backstab",
    "spy_death_backstab",
    "scout_death_backstab",
    "heavy_death_backstab"
}

local function OnDeathAnimEntThink( self )
    if CurTime() < self.l_FreezeTime then
        self:FrameAdvance()
    elseif CurTime() >= self.l_FrozenTime then
        local ragdoll = ents_Create( "prop_ragdoll" )
        ragdoll:SetModel( self:GetModel() )
        ragdoll:SetPos( self:GetPos() )
        ragdoll:SetAngles( self:GetAngles() )
        ragdoll:AddEffects( EF_BONEMERGE )
        ragdoll:SetParent( self )
        ragdoll:Spawn()

        ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        ragdoll:SetSkin( self:GetSkin() )
        for _, v in ipairs( self:GetBodyGroups() ) do 
            ragdoll:SetBodygroup( v.id, self:GetBodygroup( v.id ) )
        end

        ragdoll:SetParent( NULL )
        ragdoll:RemoveEffects( EF_BONEMERGE )
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/ice_player", physProp_Ice )

        local owner = self:GetOwner()
        if IsValid( owner ) then
            owner:Spectate( OBS_MODE_CHASE )
            owner:SpectateEntity( ragdoll )
            owner.l_TF_RagdollEntity = ragdoll
        end

        self:Remove()
        return
    end

    self:NextThink( CurTime() )
    return true
end

net.Receive( "lambda_tf2_turncsragdollintostatue", function()
    local ragdoll = ents_Create( "prop_ragdoll" )
    if !IsValid( ragdoll ) then return end

    ragdoll:SetModel( net.ReadString() )
    ragdoll:SetPos( net.ReadVector() )
    ragdoll:SetAngles( net.ReadAngle() )
    ragdoll:Spawn()
    ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    ragdoll:SetSkin( net.ReadUInt( 8 ) )
    for _, groupData in ipairs( net.ReadTable() ) do
        ragdoll:SetBodygroup( groupData[ 1 ], groupData[ 2 ] )
    end

    local turnIntoIce = net.ReadBool()
    for _, physData in ipairs( net.ReadTable() ) do    
        local bonePhys = ragdoll:GetPhysicsObjectNum( physData[ 1 ] )
        bonePhys:SetPos( physData[ 2 ], true )
        bonePhys:SetAngles( physData[ 3 ] )
        if !turnIntoIce then bonePhys:SetVelocity( physData[ 4 ] ) end
    end

    if turnIntoIce then
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/ice_player", physProp_Ice )
        ragdoll:EmitSound( ")weapons/icicle_freeze_victim_01.wav", 80, nil, nil, CHAN_STATIC )
        ParticleEffectAttach( "xms_icicle_impact_dryice", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )
    else
        LAMBDA_TF2:TurnIntoStatue( ragdoll, "models/player/shared/gold_player", physProp_Metal )
        ragdoll:EmitSound( ")weapons/saxxy_impact_gen_06.wav", 80, nil, nil, CHAN_STATIC )
    end

    local owner = net.ReadEntity()
    if IsValid( owner ) then
        if turnIntoIce and owner:OnGround() then
            SimpleTimer( FrameTime() * 2, function()
                if !IsValid( ragdoll ) then return end
                ragdoll:AddSolidFlags( FSOLID_NOT_SOLID )

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

                            ragdoll:RemoveSolidFlags( FSOLID_NOT_SOLID )
                            return 
                        end

                        coroutine_yield()
                    end
                end )

                ParticleEffectAttach( "xms_icicle_impact_dryice", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )
                ragdoll:EmitSound( ")weapons/icicle_freeze_victim_01.wav", 80, nil, nil, CHAN_STATIC )
            end )
        end

        local oldRagdoll = net.ReadEntity()
        if owner:IsPlayer() and IsValid( oldRagdoll ) then
            owner:Spectate( OBS_MODE_CHASE )
            owner:SpectateEntity( ragdoll )
            owner.l_TF_RagdollEntity = ragdoll
            oldRagdoll:Remove()
        end
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

function LAMBDA_TF2:GetWaterLevel( ent )
    return ( ent.IsLambdaPlayer and ent:GetWaterLevel() or ent:WaterLevel() )
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

    local waterLvl = LAMBDA_TF2:GetWaterLevel( ent )
    if isDead then
        ent.l_TF_WaterExitTime = false
    elseif waterLvl == 0 and ent.l_TF_OldWaterLevel != 0 then
        ent.l_TF_WaterExitTime = CurTime()
    end
    ent.l_TF_OldWaterLevel = waterLvl

    if ent.l_TF_CoveredInUrine then 
        if ( isDead or curTime > ent.l_TF_CoveredInUrine or waterLvl >= 2 ) then
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
        if ( isDead or curTime > ent.l_TF_CoveredInMilk or waterLvl >= 2 ) then
            ent.l_TF_CoveredInMilk = false

            if ent.l_TF_MilkEffect then
                LAMBDA_TF2:StopParticlesNamed( ent, "peejar_drips_milk" )
                ent.l_TF_MilkEffect = false

                if ent.IsLambdaPlayer and random( 1, 100 ) <= ent:GetVoiceChance() then
                    if random( 1, 2 ) == 1 then
                        ent:PlaySoundFile( "panic" )
                    else
                        ent:PlaySoundFile( "death" )
                    end
                end
            end
        elseif !ent.l_TF_MilkEffect then
            ParticleEffectAttach( "peejar_drips_milk", PATTACH_ABSORIGIN_FOLLOW, ent, 0 )
            ent.l_TF_MilkEffect = true

            if ent.IsLambdaPlayer and random( 1, 100 ) <= ent:GetVoiceChance() then
                if random( 1, 2 ) == 1 then
                    ent:PlaySoundFile( "panic" )
                else
                    ent:PlaySoundFile( "death" )
                end
            end
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
        if isDead or curTime > ent:GetFlameRemoveTime() or waterLvl >= 2 or curTime <= ent.l_TF_InvulnerabilityTime then
            LAMBDA_TF2:RemoveBurn( ent )
        elseif curTime >= ent.l_TF_FlameBurnTime then
            local burnDamage = ent.l_TF_BurnDamage
            local killType = ent.l_TF_BurnDamageCustom

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
                    ent:AddGesture( ent:GetSequenceActivity( ent:LookupSequence( "tf_stun_end" ) ) )
                    ent:SimpleTimer( 0.1, function() ent.l_UpdateAnimations = true end, true )
                    ent:SimpleTimer( 0.7, function() ent:SetState( ent.l_TF_PreStunState or "Idle" ) end )
                else
                    ent:SetState( ent.l_TF_PreStunState or "Idle" )
                end
            elseif ent:IsPlayer() then
                local stunAmount = ent.l_TF_StunSpeedReduction
                ent:SetWalkSpeed( ent:GetWalkSpeed() / ( 1.0 - stunAmount ) )
                ent:SetRunSpeed( ent:GetRunSpeed() / ( 1.0 - stunAmount ) )
                ent:SetDuckSpeed( ent:GetDuckSpeed() / ( 1.0 - stunAmount ) )
                ent:SetSlowWalkSpeed( ent:GetSlowWalkSpeed() / ( 1.0 - stunAmount ) )

                if ent.l_TF_StunMovement then ent:Freeze( false ) end
            end

            net.Start( "lambda_tf2_stuneffect" )
                net.WriteEntity( ent )
                net.WriteBool( false )
            net.Broadcast()
        else
            if ent.IsLambdaPlayer and ent.l_TF_StunMovement and CurTime() > ent.l_TF_StunStateChangeT then 
                if ent.l_TF_JustGotStunned then
                    ent:StartActivity( ent:GetSequenceActivity( ent:LookupSequence( "tf_stun_middle" ) ) )
                    ent:AddGesture( ent:GetSequenceActivity( ent:LookupSequence( "tf_stun_begin" ) ) )
                    ent.l_UpdateAnimations = false
                    ent.l_TF_JustGotStunned = false
                    ent.l_TF_StunStateChangeT = ( CurTime() + 0.833 )
                else
                    ent.l_TF_StunStateChangeT = ( CurTime() + 1.0 )
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
        if isDead or curTime >= ent.l_TF_InSpeedBoost then
            if !ent.l_TF_SpeedBoostIsBuff then
                ent:EmitSound( ")weapons/discipline_device_power_down.wav", 65, nil, nil, CHAN_STATIC )
            end

            LAMBDA_TF2:StopParticlesNamed( ent, "speed_boost_trail" )

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
            ent.l_TF_SpeedBoostActive = false
        elseif !ent.l_TF_SpeedBoostActive then
            ParticleEffectAttach( "speed_boost_trail", PATTACH_ABSORIGIN_FOLLOW, ent, 0 )

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

    local marksForDeath = 0
    local removedMarks = 0
    if ent.l_TF_MarkedForDeath then 
        if isDead or CurTime() >= ent.l_TF_MarkedForDeath then
            ent.l_TF_MarkedForDeath = false
            removedMarks = ( removedMarks + 1 )
        else
            marksForDeath = ( marksForDeath + 1 )
        end
    end
    if ent.l_TF_MarkedForDeathSilent then 
        if isDead or CurTime() >= ent.l_TF_MarkedForDeathSilent then
            ent.l_TF_MarkedForDeathSilent = false
            removedMarks = ( removedMarks + 1 )
        else
            marksForDeath = ( marksForDeath + 1 )
        end
    end
    if removedMarks != 0 and marksForDeath == 0 then
        LAMBDA_TF2:RemoveOverheadEffect( ent, "mark_for_death", true )
    end

    local activeBuffs = 0
    local removedBuffs = 0
    if ent.l_TF_DefenseBuffActive then 
        if isDead or curTime >= ent.l_TF_DefenseBuffActive then
            ent.l_TF_DefenseBuffActive = false 
            removedBuffs = ( removedBuffs + 1 )
        else
            activeBuffs = ( activeBuffs + 1 )
        end
    end
    if ent.l_TF_OffenseBuffActive then 
        if isDead or curTime >= ent.l_TF_OffenseBuffActive then
            ent.l_TF_OffenseBuffActive = false
            removedBuffs = ( removedBuffs + 1 )
        else
            activeBuffs = ( activeBuffs + 1 )
        end
    end
    local speedBuff = ent.l_TF_SpeedBuffActive
    if speedBuff then 
        if isDead or curTime >= speedBuff then
            ent.l_TF_SpeedBuffActive = false
            removedBuffs = ( removedBuffs + 1 )
        else
            activeBuffs = ( activeBuffs + 1 )

            if !ent.l_TF_InSpeedBoost or speedBuff > ent.l_TF_InSpeedBoost then
                ent.l_TF_InSpeedBoost = speedBuff
                ent.l_TF_SpeedBoostIsBuff = true
            end
        end
    end
    if removedBuffs != 0 and activeBuffs == 0 then
        LAMBDA_TF2:StopParticlesNamed( ent, "soldierbuff_red_soldier" )
        LAMBDA_TF2:StopParticlesNamed( ent, "soldierbuff_blue_soldier" )
    end
end

function LAMBDA_TF2:GetPushScale()
    return ( pushScale:GetFloat() )
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

        LAMBDA_TF2:StopSound( ent, ent.l_TF_CritBoostSound )
    end

    ent:SetCritBoostType( boostType )
end

///

function LAMBDA_TF2:CreateMedkit( pos, model, healRatio, respawn, removeTime, isProp )
    local medkit = ents_Create( "lambda_tf_healthkit_base" )
    if !IsValid( medkit ) then return end

    if model then medkit.Model = model end
    if healRatio then medkit.HealRatio = healRatio end
    if removeTime then medkit.RemoveTime = removeTime end
    medkit.CanRespawn = ( respawn or false )
    medkit.HasPhysics = ( isProp or false )

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

function LAMBDA_TF2:ApplyAirBlastImpulse( target, impulse )
    local vecForce = impulse
    local scale = ( target.l_TF_AirBlastVulnerability or 1.0 )

    vecForce = ( vecForce * scale )
    if target:OnGround() and vecForce.z < 268.3281572999747 then
        vecForce.z = 268.3281572999747
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

    if dmginfo:GetDamageCustom() == TF_DMG_CUSTOM_PLASMA_CHARGED then
        vecForce = ( vecForce * 1.25 )
    end

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

function LAMBDA_TF2:Stun( target, time, stunAmount, freeze )
    local expireTime = ( CurTime() + time )

    if !target.l_TF_IsStunned then
        target.l_TF_IsStunned = expireTime
        target.l_TF_JustGotStunned = true
        target.l_TF_StunMovement = ( freeze or false )
        target.l_TF_StunSpeedReduction = stunAmount

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
            target:SetWalkSpeed( target:GetWalkSpeed() * ( 1.0 - stunAmount ) )
            target:SetRunSpeed( target:GetRunSpeed() * ( 1.0 - stunAmount ) )
            target:SetDuckSpeed( target:GetDuckSpeed() * ( 1.0 - stunAmount ) )
            target:SetSlowWalkSpeed( target:GetSlowWalkSpeed() * ( 1.0 - stunAmount ) )

            if freeze then target:Freeze( true ) end
        end
    else
        local prevStunAmount = target.l_TF_StunSpeedReduction
        if stunAmount > prevStunAmount or freeze then
            if expireTime > target.l_TF_IsStunned then
                target.l_TF_IsStunned = expireTime
            end
            target.l_TF_StunSpeedReduction = ( 1.0 - stunAmount )
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
                target:SetWalkSpeed( target:GetWalkSpeed() / ( 1.0 - prevStunAmount ) * ( 1.0 - stunAmount ) )
                target:SetRunSpeed( target:GetRunSpeed() / ( 1.0 - prevStunAmount ) * ( 1.0 - stunAmount ) )
                target:SetDuckSpeed( target:GetDuckSpeed() / ( 1.0 - prevStunAmount ) * ( 1.0 - stunAmount ) )
                target:SetSlowWalkSpeed( target:GetSlowWalkSpeed() / ( 1.0 - prevStunAmount ) * ( 1.0 - stunAmount ) )

                if freeze then target:Freeze( true ) end
            end
        end
    end

    if freeze then
        target.l_TF_StunStateChangeT = 0
    end
end

function LAMBDA_TF2:IsDamageCustom( dmginfo, dmgCustom )
    return band( ( isnumber( dmginfo ) and dmginfo or dmginfo:GetDamageCustom() ), dmgCustom ) != 0
end

function LAMBDA_TF2:RadiusDamageInfo( dmginfo, pos, radius, impactEnt, ignoreEnt )
    if radius <= 0 then return end
    
    local radSqr = ( radius * radius )

    local baseDamage = dmginfo:GetDamage()
    local baseDamageForce = dmginfo:GetDamageForce()
    local baseDamagePos = dmginfo:GetDamagePosition()
    
    local fallOff = ( baseDamage / radius )
    if LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_RADIUS_MAX ) then
        fallOff = 0
    elseif LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_HALF_FALLOFF ) then
        fallOff = 0.5
    end

    explosionTrTbl.start = pos

    for _, ent in ipairs( FindInSphere( pos, radius ) ) do
        if ent == ignoreEnt or !LambdaIsValid( ent ) or !LAMBDA_TF2:TakesDamage( ent ) then continue end

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

    attacker.l_TF_DamageEvents[ #attacker.l_TF_DamageEvents ] = {
        Damage = damage,
        Time = CurTime()
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
        ent:EmitSound( ")misc/flame_engulf.wav", nil, nil, nil, CHAN_STATIC )

        local burningSnd = ent.l_TF_FireBurningSound
        if !burningSnd then
            burningSnd = LAMBDA_TF2:CreateSound( ent, "ambient/fire/fire_small_loop" .. random( 1, 2 ) .. ".wav" )
            burningSnd:PlayEx( 0.8, 100 )
            burningSnd:SetSoundLevel( 75 )
            ent.l_TF_FireBurningSound = burningSnd
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
    else
        local burnDuration = weapon.l_TF_AfterburnDuration
        if burnDuration then
            flameLife = burnDuration
        else
            flameLife = ( ( burningTime and burningTime > 0 ) and burningTime or 10 )
        end
    end

    local burnEnd = ( CurTime() + flameLife )
    if burnEnd > ent:GetFlameRemoveTime() then
        ent:SetFlameRemoveTime( burnEnd )
    end

    ent.l_TF_BurnAttacker = attacker
    ent.l_TF_BurnWeapon = weapon
    ent.l_TF_BurnDamage = ( weapon.l_AfterburnDamage or 3 )
    ent.l_TF_BurnDamageCustom = ( weapon.l_DmgCustom or TF_DMG_CUSTOM_BURNING )

    local killIcon = weapon.l_killiconname
    if !killIcon or weapon.l_TF_AfterburnUseDefaultIcon then killIcon = "lambdaplayers_weaponkillicons_tf2_fire" end
    ent.l_TF_BurnInflictor.l_killiconname = killIcon
end

function LAMBDA_TF2:IsBurning( ent )
    return ( ent:GetIsBurning() or ent:IsOnFire() )
end

function LAMBDA_TF2:GetBurnEndTime( ent )
    if ent:GetIsBurning() then return ent:GetFlameRemoveTime() end
    
    for _, child in ipairs( ent:GetChildren() ) do
        if !IsValid( child ) or child:GetClass() != "entityflame" then continue end
        return child:GetInternalVariable( "lifetime" )
    end
end

function LAMBDA_TF2:RemoveBurn( ent )
    ent:Extinguish()

    if ent:GetIsBurning() then
        ent:SetIsBurning( false )
        ent.l_TF_BurnAttacker = nil
        ent.l_TF_BurnWeapon = nil
        SafeRemoveEntity( ent.l_TF_BurnInflictor )
    end

    ent:StopSound( ")misc/flame_engulf.wav" )
    LAMBDA_TF2:StopParticlesNamed( ent, "burningplayer_red" )
    LAMBDA_TF2:StopParticlesNamed( ent, "burningplayer_blue" )
    LAMBDA_TF2:StopSound( ent, ent.l_TF_FireBurningSound )
end

function LAMBDA_TF2:MarkForDeath( ent, time, silent, markerer )
    if LAMBDA_TF2:IsMarkedForDeath( ent ) then 
        ent.l_TF_MarkedForDeath = false
        ent.l_TF_MarkedForDeathSilent = false
    end

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

    LAMBDA_TF2:AddOverheadEffect( ent, "mark_for_death" )
end

function LAMBDA_TF2:IsMarkedForDeath( ent )
    return ( ent.l_TF_MarkedForDeathSilent or ent.l_TF_MarkedForDeath )
end

function LAMBDA_TF2:RemoveMarkForDeath( ent )
    ent.l_TF_MarkedForDeath = false
    ent.l_TF_MarkedForDeathSilent = false
    LAMBDA_TF2:RemoveOverheadEffect( ent, "mark_for_death", true )
end

function LAMBDA_TF2:TakeNoDamage( ent )
    ent:SetSaveValue( "m_takedamage", 0 )
end

function LAMBDA_TF2:TakesDamage( ent )
    return ( ent:GetInternalVariable( "m_takedamage" ) == 2 )
end

function LAMBDA_TF2:GetCritType( dmginfo )
    local dmgCustom = dmginfo:GetDamageCustom()
    return ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_CRITICAL ) and TF_CRIT_FULL or ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_MINICRITICAL ) and TF_CRIT_MINI or TF_CRIT_NONE ) )
end

function LAMBDA_TF2:SetCritType( dmginfo, critType )
    local dmgCustom = dmginfo:GetDamageCustom()
    if LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_CRITICAL ) then
        dmgCustom = ( dmgCustom - TF_DMG_CUSTOM_CRITICAL )
    end
    if LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_MINICRITICAL ) then 
        dmgCustom = ( dmgCustom - TF_DMG_CUSTOM_MINICRITICAL )
    end

    if critType == TF_CRIT_FULL then
        dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL )
    elseif critType == TF_CRIT_MINI then
        dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_MINICRITICAL )
    end
    dmginfo:SetDamageCustom( dmgCustom ) 
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

local rndMovePos = Vector()

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
                if CurTime() > lambda.l_TF_Medic_TargetSearchT then
                    lambda.l_TF_Medic_TargetSearchT = ( CurTime() + 1.0 )

                    local hasFriends = ( lambda.l_friends and table_Count( lambda.l_friends ) > 0 )
                    local woundedTarget = nil
                    local filter = lambda.l_TF_MedicTargetFilter
                    local ignorePly = ignorePlys:GetBool()
                    local healers = LAMBDA_TF2:GetMedigunHealers( lambda )
                    local targetSearchFunc = function( ent )
                        if ( !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() ) or ent:Health() <= 0 then return false end
                        if ent:IsPlayer() and ignorePly then return false end
                        if filter and filter( lambda, ent ) == false then return false end
                        if ent != healTarget and !lambda:CanSee( ent ) then return false end

                        local isPlayer = ( ent.IsLambdaPlayer or ent:IsPlayer() )
                        if isPlayer then
                            if !ent:Alive() then return false end
                            if LambdaTeams and LambdaTeams:AreTeammates( lambda, ent ) == false then return false end
                            if hasFriends and !lambda:IsFriendsWith( ent ) then return false end
                            if ent.IsLambdaPlayer and ent:InCombat() and ent:GetEnemy() == lambda then return false end

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
                        elseif ent:GetInternalVariable( "m_lifeState" ) != 0 or lambda:Relations( ent ) != D_LI then 
                            return false 
                        end

                        if woundedTarget then
                            if ( ent:Health() / ent:GetMaxHealth() ) > ( woundedTarget:Health() / woundedTarget:GetMaxHealth() ) then return false end
                            if ( LAMBDA_TF2:IsBurning( woundedTarget ) or LAMBDA_TF2:IsBleeding( woundedTarget ) ) and !LAMBDA_TF2:IsBurning( ent ) and !LAMBDA_TF2:IsBleeding( ent ) then return false end
                            
                            if isPlayer then 
                                if LambdaTeams and LambdaTeams:AreTeammates( woundedTarget, ent ) == false then return false end
                                if ent.IsLambdaPlayer and woundedTarget.IsLambdaPlayer and woundedTarget:InCombat() != ent:InCombat() then return false end
                            end
                        end

                        woundedTarget = ent
                        return true
                    end
                    lambda:FindInSphere( nil, ( targetDead and 2000 or 1000 ), targetSearchFunc )

                    if !woundedTarget and targetDead and IsValid( healTarget ) then
                        lambda.l_TF_Medic_HealTarget = nil 
                        lambda:RetreatFrom( healTarget.l_TF_Killer )
                        return "end"
                    end

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
                if lambda:IsInRange( healTarget, closeRange ) and lambda.l_TF_Medigun_HealTarget == healTarget then 
                    if LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) <= 5 or targetInCombat or lambda:IsInRange( healTarget, 30 ) then
                        local desSpeed = ( lambda.loco:GetDesiredSpeed() / 2 )
                        rndMovePos.x = random( -desSpeed, desSpeed )
                        rndMovePos.y = random( -desSpeed, desSpeed )
                        lambda.l_movepos = ( lambda:GetPos() + rndMovePos )
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

function LAMBDA_TF2:GetUnmodifiedMaxHealth( ent, includeTbl )
    includeTbl = ( includeTbl or {} )
    local health = ent:GetMaxHealth()

    if ent.IsLambdaPlayer then
        if !includeTbl.GRU then health = ( health + ent.l_TF_GRU_DrainedHP ) end

        if !includeTbl.HealthMultiplier then
            local healthMult = ent.l_TF_WeaponHealthMultiplier
            if healthMult then health = ( health / healthMult ) end
        end

        if !includeTbl.DalokohsBar then
            for _, bar in ipairs( ent.l_TF_DalokohsBars ) do
                health = ( health / bar.HealthRatio )
            end
        end

        if !includeTbl.Eyelander and ent:GetWeaponName() == "tf2_eyelander" then
            health = ( ( health - ( ent:GetWeaponENT().l_TF_Eyelander_GiveHealth * min( ent.l_TF_Decapitations, 4 ) ) ) / 0.75 )
        end
    end
    return Round( health )
end

function LAMBDA_TF2:DispatchColorParticle( ent, effect, partAttachment, entAttachment, color, reverseOrder )
    net.Start( "lambda_tf2_dispatchcolorparticle" )
        net.WriteEntity( ent )
        net.WriteString( effect )
        
        net.WriteUInt( partAttachment, 3 )
        if partAttachment == PATTACH_WORLDORIGIN then
            net.WriteVector( entAttachment )
        else
            net.WriteUInt( entAttachment, 6 )
        end

        net.WriteBool( reverseOrder or false )
        
        if !color or isnumber( color ) then
            net.WriteBool( false )
            net.WriteUInt( color or 0, 2 )
        else
            net.WriteBool( true )
            net.WriteVector( color )
        end
    net.Broadcast()
end

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
end