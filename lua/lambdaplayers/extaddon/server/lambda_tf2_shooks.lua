local table_Empty = table.Empty
local CurTime = CurTime
local ScreenShake = util.ScreenShake
local ents_Create = ents.Create
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local IsValid = IsValid
local SimpleTimer = timer.Simple
local max = math.max
local min = math.min
local band = bit.band
local istable = istable
local AngleRand = AngleRand
local net = net
local isfunction = isfunction
local ipairs = ipairs
local table_remove = table.remove
local coroutine_yield = coroutine.yield
local ParticleEffectAttach = ParticleEffectAttach
local Clamp = math.Clamp
local deg = math.deg
local acos = math.acos
local TraceHull = util.TraceHull
local DamageInfo = DamageInfo
local FrameTime = FrameTime
local EmitSound = EmitSound
local debugoverlay = debugoverlay
local Round = math.Round
local RandomPairs = RandomPairs
local isvector = isvector
local GetConVar = GetConVar
local IsSinglePlayer = game.SinglePlayer
local coroutine_wait = coroutine.wait
local FindByClass = ents.FindByClass
local pairs = pairs
local table_Random = table.Random

local ammoboxAngImpulse = Vector()
local groundCheckTbl = {}
local serverRags = GetConVar( "lambdaplayers_lambda_serversideragdolls" )

local dmgCustomKillicons = {
    [ TF_DMG_CUSTOM_BACKSTAB ]              = "lambdaplayers_weaponkillicons_tf2_backstab",
    [ TF_DMG_CUSTOM_BACKSTAB_HIDDEN ]       = "lambdaplayers_weaponkillicons_tf2_sharpdresser_backstab",
    [ TF_DMG_CUSTOM_HEADSHOT ]              = "lambdaplayers_weaponkillicons_tf2_headshot",
    [ TF_DMG_CUSTOM_HEADSHOT_REVOLVER ]     = "lambdaplayers_weaponkillicons_tf2_ambassador_headshot",
    [ TF_DMG_CUSTOM_STICKBOMB_EXPLOSION ]   = "lambdaplayers_weaponkillicons_tf2_caber_explosion",
    [ TF_DMG_CUSTOM_KATANA_DUEL ]           = "lambdaplayers_weaponkillicons_tf2_katana_duel",
    [ TF_DMG_CUSTOM_BURNING_BEHIND ]        = "lambdaplayers_weaponkillicons_tf2_backburner_behind",
    [ TF_DMG_CUSTOM_GLOVES_LAUGHING ]       = "lambdaplayers_weaponkillicons_tf2_holidaypunch_laugh",
    [ TF_DMG_CUSTOM_PENETRATION ]           = "lambdaplayers_weaponkillicons_tf2_machina_penetrate",
    [ TF_DMG_CUSTOM_PENETRATION_HEADSHOT ]  = "lambdaplayers_weaponkillicons_tf2_machina_penetratehs",
    [ TF_DMG_CUSTOM_CANNONBALL_PUSH ]       = "lambdaplayers_weaponkillicons_tf2_loose_cannon_pushed"
}
local dmgCustomDecapitates = (
    TF_DMG_CUSTOM_DECAPITATION +
    TF_DMG_CUSTOM_KATANA_DUEL
)
local dmgCustomHeadshots = (
    TF_DMG_CUSTOM_HEADSHOT +
    TF_DMG_CUSTOM_HEADSHOT_REVOLVER
)
local dmgCustomBurns = (
    TF_DMG_CUSTOM_BURNING +
    TF_DMG_CUSTOM_BURNING_BEHIND +
    TF_DMG_CUSTOM_BURNING_PHLOG
)
local dmgCustomDissolves = (
    TF_DMG_CUSTOM_PLASMA +
    TF_DMG_CUSTOM_PLASMA_CHARGED
)
local dmgCustomBackstabs = (
    TF_DMG_CUSTOM_BACKSTAB +
    TF_DMG_CUSTOM_BACKSTAB_HIDDEN
)
local dmgCustomMachina = (
    TF_DMG_CUSTOM_PENETRATION +
    TF_DMG_CUSTOM_PENETRATION_HEADSHOT
)
local fullcritSnds = {
    "player/crit_hit.wav",
    "player/crit_hit2.wav",
    "player/crit_hit3.wav",
    "player/crit_hit4.wav",
    "player/crit_hit5.wav"
}
local minicritSnds = {
    "player/crit_hit_mini.wav",
    "player/crit_hit_mini2.wav",
    "player/crit_hit_mini3.wav",
    "player/crit_hit_mini4.wav",
    "player/crit_hit_mini5.wav"
}
local gmodDeathAnims = {
    "death_01",
    "death_02",
    "death_03",
    "death_04"
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
    },
    [ TF_DMG_CUSTOM_PLASMA ] = {
        "sniper_death_violent",
        "pyro_death_violent",
        "medic_death_violent",
        "demoman_death_violent",
        "soldier_death_violent",
        "engineer_death_violent",
        "spy_death_violent",
        "scout_death_violent",
        "heavy_death_violent"
    }
}
local shieldChargeTrTbl = {
    mins = -Vector( 24, 24, 24 ),
    maxs = Vector( 24, 24, 24),
    mask = MASK_SOLID,
    collisiongroup = COLLISION_GROUP_NONE
}

local function OnEntityTakeDamage( ent, dmginfo )
    if ent.l_TF_FixedBulletDamage then
        dmginfo:SetDamage( ent.l_TF_FixedBulletDamage * LambdaGetWeaponDamageScale( ent ) )
        ent.l_TF_FixedBulletDamage = false
    end

    local dmgCustom = dmginfo:GetDamageCustom()
    local isDissolving = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomDissolves ) )
    if isDissolving and !dmginfo:IsDamageType( DMG_DISSOLVE ) then
        dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_DISSOLVE )
    end

    if LAMBDA_TF2:IsValidCharacter( ent ) then
        local inflictor = dmginfo:GetInflictor()
        local attacker = dmginfo:GetAttacker()

        table_Empty( ent.l_TF_AttackBonusEffect )
        ent:SetNW2Bool( "lambda_tf2_decapitatehead", ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomDecapitates ) ) )
        ent:SetNW2Bool( "lambda_tf2_turnintogold", ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_TURNGOLD ) ) )
        ent:SetNW2Bool( "lambda_tf2_dissolve", isDissolving )
        ent:SetNW2Bool( "lambda_tf2_turnintoice", false )

        local turnToAshes = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_BURNING_PHLOG ) )
        if !turnToAshes and ent:l_GetIsBurning() then turnToAshes = ( LAMBDA_TF2:IsDamageCustom( ent.l_TF_BurnDamageCustom, TF_DMG_CUSTOM_BURNING_PHLOG ) ) end
        ent:SetNW2Bool( "lambda_tf2_turnintoashes", turnToAshes )

        local damageBlocked = false
        if ent.l_TF_InvulnerabilityTime and CurTime() <= ent.l_TF_InvulnerabilityTime then
            if dmginfo:IsDamageType( DMG_BULLET + DMG_CLUB + DMG_SLASH ) then
                ent:EmitSound( "SolidMetal.BulletImpact" )
            end
            damageBlocked = true
        end
        if ent.l_TF_AtomicPunched then
            if dmginfo:IsDamageType( DMG_BULLET + DMG_CLUB + DMG_SLASH ) then
                ent:EmitSound( "player/pl_scout_jump" .. LambdaRNG( 1, 4 ) .. ".wav", 65, LambdaRNG( 90, 110 ), nil, CHAN_STATIC )
            end
            damageBlocked = true
        end
        if CurTime() <= ent.l_TF_FireImmunity and ( dmginfo:IsDamageType( DMG_BURN ) or LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_IGNITE ) ) then
            damageBlocked = true
        end

        local isBackstab = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBackstabs ) )
        if isBackstab and ent.l_TF_SniperShieldType == 1 and LAMBDA_TF2:IsInventoryItemReady( ent, "tf2_razorback" ) then
            damageBlocked = true
            dmginfo:SetDamage( 0 )

            ScreenShake( ent:GetPos(), 25, 150, 1, 50 )
            ent:EmitSound( "player/spy_shield_break.wav", nil, nil, nil, CHAN_STATIC )
            ent:AttackTarget( attacker )

            for i = 1, 2 do
                local shieldGib = ents_Create( "prop_physics" )
                shieldGib:SetModel( "models/player/items/sniper/knife_shield_gib" .. i .. ".mdl" )
                shieldGib:SetPos( ent:GetPos() )
                shieldGib:SetAngles( ent:GetAngles() )
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

                if LambdaRNG( 1, 100 ) <= attacker:GetVoiceChance() then
                    attacker:PlaySoundFile( "panic" )
                end
            end
        end

        if IsValid( inflictor ) then
            local isTFWeapon = ( inflictor.IsLambdaWeapon and inflictor.TF2Data )
            ent:SetNW2Bool( "lambda_tf2_turnintoice", ( isTFWeapon and isBackstab and inflictor:GetWeaponAttribute( "FreezeOnBackstab", false ) ) )

            if attacker != ent then
                local doubleDonked = false
                if attacker.IsLambdaPlayer then
                    doubleDonked = ( inflictor.l_IsTFCannonBall and dmginfo:IsDamageType( DMG_BLAST ) and attacker.l_TF_DonkVictims[ ent ] and attacker.l_TF_DonkVictims[ ent ] > CurTime() )
                end

                local critType = LAMBDA_TF2:GetCritType( dmginfo )
                if critType != TF_CRIT_FULL and ( isBackstab or LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomHeadshots ) ) then
                    critType = TF_CRIT_FULL
                else
                    local isDirectAttack = ( !inflictor.l_IsTFBurnInflictor and !inflictor.l_IsTFBleedInflictor and ( !attacker.IsLambdaPlayer or inflictor == attacker:GetWeaponENT() or inflictor:GetOwner() == attacker ) )
                    if critType == TF_CRIT_NONE and ( ent.l_TF_CoveredInUrine or ent.l_TF_CoveredInMilk or LAMBDA_TF2:IsMarkedForDeath( ent ) or isDirectAttack and attacker.l_TF_OffenseBuffActive or doubleDonked ) then
                        critType = TF_CRIT_MINI
                    end
                    if critType == TF_CRIT_MINI and isTFWeapon and inflictor:GetWeaponAttribute( "MiniCritsToFull", false ) then
                        critType = TF_CRIT_FULL
                    end

                    if isDirectAttack and LAMBDA_TF2:IsValidCharacter( attacker ) then
                        local critBoost = attacker:l_GetCritBoostType()
                        if critBoost > critType then critType = critBoost end
                    end
                end

                local critDamage = 0
                local damage = dmginfo:GetDamage()

                if ent.l_TF_DefenseBuffActive and !isBackstab and !dmginfo:IsDamageType( DMG_CRUSH ) then
                    critType = TF_CRIT_NONE
                    damage = ( damage * 0.65 )
                end

                if critType == TF_CRIT_FULL then
                    critDamage = ( ( TF_DAMAGE_CRIT_MULTIPLIER - 1 ) * damage )

                    ent.l_TF_AttackBonusEffect[ 1 ] = "crit_text"
                    ent.l_TF_AttackBonusEffect[ 2 ] = fullcritSnds
                    ent.l_TF_AttackBonusEffect[ 3 ] = false
                elseif doubleDonked then
                    ent.l_TF_AttackBonusEffect[ 1 ] = "doubledonk_text"
                    ent.l_TF_AttackBonusEffect[ 2 ] = ")player/doubledonk.wav"
                    ent.l_TF_AttackBonusEffect[ 3 ] = true
                elseif critType == TF_CRIT_MINI then
                    critDamage = ( ( TF_DAMAGE_MINICRIT_MULTIPLIER - 1 ) * damage )

                    ent.l_TF_AttackBonusEffect[ 1 ] = "minicrit_text"
                    ent.l_TF_AttackBonusEffect[ 2 ] = minicritSnds
                    ent.l_TF_AttackBonusEffect[ 3 ] = false
                end

                LAMBDA_TF2:SetCritType( dmginfo, critType )

                local infKillicon = inflictor.l_killiconname
                if infKillicon then
                    for bitFlag, icon in pairs( dmgCustomKillicons ) do
                        if band( dmgCustom, bitFlag ) == 0 or infKillicon == icon then continue end
                        inflictor.l_killiconname = icon

                        SimpleTimer( 0, function()
                            if !IsValid( inflictor ) or inflictor.l_killiconname != icon then return end
                            inflictor.l_killiconname = infKillicon
                        end )

                        break
                    end
                end

                if ( isTFWeapon or inflictor.l_IsTFWeapon ) and !doubleDonked then
                    dmginfo:SetBaseDamage( dmginfo:GetDamage() )

                    local doShortRangeDistanceIncrease = ( critType == TF_CRIT_NONE or critType != TF_CRIT_FULL )
                    local doLongRangeDistanceDecrease = ( critType == TF_CRIT_NONE )

                    local rndDmgSpread = 0.1
                    local minSpread = ( 0.5 - rndDmgSpread )
                    local maxSpread = ( 0.5 + rndDmgSpread )

                    if LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_USEDISTANCEMOD ) then
                        local attackerPos = attacker:WorldSpaceCenter()
                        local optimalDist = 512

                        local dist = max( 1, ( attackerPos:Distance( ent:WorldSpaceCenter() ) ) )

                        local centerSpread = LAMBDA_TF2:RemapClamped( dist / optimalDist, 0, 2, 1, 0 )
                        if centerSpread > 0.5 and doShortRangeDistanceIncrease or centerSpread <= 0.5 then
                            if centerSpread > 0.5 and LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_NOCLOSEDISTANCEMOD ) then
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
                if isBackstab then
                    local maxBackstabDmg = GetConVar( "lambdaplayers_tf2_capbackstabdamage" ):GetInt()
                    if maxBackstabDmg != 0 then totalDamage = min( totalDamage, maxBackstabDmg ) end
                end

                dmginfo:SetDamageForce( dmginfo:GetDamageForce() * ( totalDamage / dmginfo:GetDamage() ) )
                dmginfo:SetDamage( totalDamage )
                dmginfo:SetDamageBonus( critDamage )

                if ( isTFWeapon or inflictor.l_IsTFWeapon ) and !dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) and ( !attacker.IsLambdaPlayer or attacker:CanTarget( ent ) ) then
                    local vecDir = ( ( inflictor:WorldSpaceCenter() - vector_up * 10 ) - ent:WorldSpaceCenter() ):GetNormalized()
                    LAMBDA_TF2:ApplyPushFromDamage( ent, dmginfo, vecDir )
                end
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

    local dmgCustom = dmginfo:GetDamageCustom()
    local isMeleeDmg = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_MELEE ) )

    local isTFWeapon = ( inflictor.IsLambdaWeapon and inflictor.TF2Data )
    if isTFWeapon and isMeleeDmg then
        local hitSnd = inflictor:GetWeaponAttribute( "HitSound", {
            ")weapons/cbar_hitbod1.wav",
            ")weapons/cbar_hitbod2.wav",
            ")weapons/cbar_hitbod3.wav"
        } )
        if hitSnd then
            local critSnd = inflictor:GetWeaponAttribute( "HitCritSound" )
            if critSnd and LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_CRITICAL ) then hitSnd = critSnd end
            if istable( hitSnd ) then hitSnd = hitSnd[ LambdaRNG( #hitSnd ) ] end
            inflictor:EmitSound( hitSnd, nil, nil, nil, CHAN_STATIC )
        end
    end

    if LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBurns ) or ( isTFWeapon or inflictor.l_IsTFWeapon ) and ( isMeleeDmg or dmginfo:IsBulletDamage() ) then
        ent:EmitSound( "Flesh.BulletImpact" )
    end

    if tookDamage then
        if !ent:l_GetIsBurning() and LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_IGNITE ) and LAMBDA_TF2:GetWaterLevel( ent ) < 2 then
            LAMBDA_TF2:Burn( ent, attacker, inflictor )
        end

        if LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBurns + TF_DMG_CUSTOM_BLEEDING ) then
            LAMBDA_TF2:CreateBloodParticle( dmginfo:GetDamagePosition(), AngleRand( -180, 180 ), ent )
        end

        if ent.IsLambdaPlayer and ( inflictor.l_IsTFBleedInflictor or inflictor.l_IsTFBurnInflictor ) then
            ent:AddGestureSequence( ent:LookupSequence( "flinch_stomach_02" ) )
        end

        if isTFWeapon and isMeleeDmg and !LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_BLEEDING ) then
            local bleedingTime = inflictor:GetWeaponAttribute( "BleedingDuration" )
            if bleedingTime and bleedingTime > 0 then LAMBDA_TF2:MakeBleed( ent, attacker, inflictor, bleedingTime ) end
        end

        if attacker != ent then
            local bonusEffect = ent.l_TF_AttackBonusEffect
            if #bonusEffect != 0 then
                local snd = bonusEffect[ 2 ]
                if istable( snd ) then snd = snd[ LambdaRNG( #snd ) ] end

                net.Start( "lambda_tf2_attackbonuseffect" )
                    net.WriteEntity( ent )
                    net.WriteString( bonusEffect[ 1 ] )
                    net.WriteVector( ent:GetPos() + ent:OBBCenter() * 2 )
                    net.WriteBool( bonusEffect[ 3 ] )
                    net.WriteString( snd )
                    net.WriteBool( isDead )
                net.Broadcast()
            end

            if attacker.IsLambdaPlayer then
                if isDead then
                    if attacker.l_TF_Shield_Type == 3 and attacker:l_GetShieldChargeMeter() != 100 and ( dmgCustom == TF_DMG_CUSTOM_CHARGE_IMPACT or isMeleeDmg ) then
                        attacker:l_SetShieldChargeMeter( attacker:l_GetShieldChargeMeter() + 75 )
                    end

                    local focusMeter = min( attacker.l_TF_FocusMeter + 20, 100 )
                    if focusMeter >= 100 and !attacker.l_TF_FocusMeterFull and !attacker.l_TF_FocusActivated then
                        attacker.l_TF_FocusMeterFull = true
                        attacker:GetWeaponENT():EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
                    end
                    attacker.l_TF_FocusMeter = focusMeter

                    if LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBackstabs ) then
                        attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 2, 35 )
                    elseif isMeleeDmg then
                        attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 1, 35 )
                    end

                    if LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomMachina ) then
                        EmitSound( "misc/sniper_railgun_double_kill.wav", vector_origin, 0, CHAN_STATIC, 0.8, 0, 0, 100 )
                    end
                end

                if isTFWeapon and inflictor:GetWeaponAttribute( "MarkForDeath", false ) then
                    LAMBDA_TF2:MarkForDeath( ent, 15, false, attacker )
                end

                local entHealth = ent:Health()
                local entArmor = ent.Armor
                if entArmor then entHealth = ( entHealth + ( isfunction( entArmor ) and entArmor( ent ) or entArmor ) ) end

                attacker.l_TF_HypeMeter = min( 99, attacker.l_TF_HypeMeter + max( 5, dmginfo:GetDamage() ) )
                LAMBDA_TF2:RecordDamageEvent( attacker, dmginfo, isDead, entHealth )

                if attacker.l_TF_RageBuffType and !attacker.l_TF_RageActivated and attacker:Alive() then
                    local gainRage = ( dmginfo:GetDamage() / ( LambdaRNG( 4, 5 ) * LambdaGetWeaponDamageScale( ent ) ) )
                    if attacker.l_TF_RageBuffType == 3 then gainRage = ( gainRage * 1.25 ) end
                    attacker.l_TF_RageMeter = min( attacker.l_TF_RageMeter + gainRage, 100 )
                end

                if !attacker.l_TF_MmmphActivated and attacker.l_TF_MmmphMeter < 100 and attacker:GetWeaponName() == "tf2_phlogistinator" and ( dmginfo:IsDamageType( DMG_BURN + DMG_PLASMA ) or LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_IGNITE ) ) then
                    attacker.l_TF_MmmphMeter = min( attacker.l_TF_MmmphMeter + ( dmginfo:GetDamage() / ( 3 * LambdaGetWeaponDamageScale( ent ) ) ), 100 )
                end
            end

            if ent.IsLambdaPlayer and ent:l_GetIsShieldCharging() and ent.l_TF_Shield_Type == 3 and !dmginfo:IsDamageType( DMG_FALL ) then
                ent:l_SetShieldChargeMeter( ent:l_GetShieldChargeMeter() - dmginfo:GetDamage() )
            end

            local onDealDmgFunc = inflictor.l_OnDealDamage
            if isfunction( onDealDmgFunc ) then onDealDmgFunc( inflictor, ent, dmginfo ) end

            if ent.l_TF_CoveredInMilk and !LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBurns ) and LAMBDA_TF2:IsValidCharacter( attacker ) then
                LAMBDA_TF2:GiveHealth( attacker, ( dmginfo:GetDamage() * 0.6 ), false )
            end

            if attacker.l_TF_SpeedBuffActive then
                LAMBDA_TF2:GiveHealth( attacker, ( dmginfo:GetDamage() * 0.35 ), false )
            end
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
                    trail:SetParent( NULL )
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

        local frozenTime = ( CurTime() + LambdaRNG( 9.0, 11.0, true ) )
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
        if owner:GetNW2Bool( "lambda_tf2_dissolve", false ) then
            ragdoll:EmitSound( "player/dissolve.wav", nil, nil, nil, CHAN_STATIC )

            local dissolver = ents_Create( "env_entity_dissolver" )
            dissolver:SetKeyValue( "target", "!activator" )
            dissolver:Input( "dissolve", ragdoll )
            dissolver:Remove()
        else
            if owner:GetNW2Bool( "lambda_tf2_decapitatehead", false ) then
                LAMBDA_TF2:DecapitateHead( ragdoll, true, ( ragdoll:GetVelocity() * 5 ) )
            end

            if owner:GetNW2Bool( "lambda_tf2_turnintoashes", false ) then
                ragdoll:SetRenderMode( RENDERMODE_TRANSCOLOR )
                ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )

                local removeT = ( CurTime() + 0.5 )
                LambdaCreateThread( function()
                    while ( IsValid( ragdoll ) and CurTime() < removeT ) do
                        local ragColor = ragdoll:GetColor()
                        ragColor.a = LAMBDA_TF2:RemapClamped( ( removeT - CurTime() ), 0, 0.5, 0, 255 )

                        ragdoll:SetColor( ragColor )
                        coroutine_yield()
                    end
                    if IsValid( ragdoll ) then ragdoll:Remove() end
                end )
            end
        end

        if owner:l_GetIsBurning() then
            LAMBDA_TF2:AttachFlameParticle( ragdoll, Clamp( ( owner:l_GetFlameRemoveTime() - CurTime() ), 2, 10 ), LAMBDA_TF2:GetTeamColor( owner ) )
        end
    end
end

local function OnScaleEntityDamage( ent, hitgroup, dmginfo )
    local inflictor = dmginfo:GetInflictor()
    if !IsValid( inflictor ) or ( !inflictor.IsLambdaWeapon or !inflictor.TF2Data ) and !inflictor.l_IsTFWeapon then
        ent.l_TF_FixedBulletDamage = false
    else
        ent.l_TF_FixedBulletDamage = dmginfo:GetDamage()
    end
end

local function OnEntityFireBullets( ent, data )
    if !IsValid( ent ) or !ent.l_TF_NextCritShootSoundT or CurTime() <= ent.l_TF_NextCritShootSoundT then return end
    ent.l_TF_NextCritShootSoundT = CurTime()

    if ent:IsPlayer() then
        local critBoost = ent:l_GetCritBoostType()
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

local function OnPlayerSpawn( ply, transition )
    if transition then return end
    local ragdoll = ply.l_TF_RagdollEntity
    if IsValid( ragdoll ) then ragdoll:Remove() end
end

hook.Add( "PlayerDeath", "LambdaTF2_OnPlayerDeath", OnPlayerDeath )
hook.Add( "PlayerSpawn", "LambdaTF2_OnPlayerSpawn", OnPlayerSpawn )
hook.Add( "EntityTakeDamage", "LambdaTF2_OnEntityTakeDamage", OnEntityTakeDamage )
hook.Add( "PostEntityTakeDamage", "LambdaTF2_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
hook.Add( "Think", "LambdaTF2_OnServerThink", OnServerThink )
hook.Add( "CreateEntityRagdoll", "LambdaTF2_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
hook.Add( "ScalePlayerDamage", "LambdaTF2_OnScalePlayerDamage", OnScaleEntityDamage )
hook.Add( "ScaleNPCDamage", "LambdaTF2_OnScaleNPCDamage", OnScaleEntityDamage )
hook.Add( "EntityFireBullets", "LambdaTF2_OnEntityFireBullets", OnEntityFireBullets )

---

local function OnLambdaThink( lambda, weapon, isdead )
    local shieldType = lambda.l_TF_Shield_Type
    if shieldType then
        if !isdead and lambda.l_issmoving and !lambda:l_GetIsShieldCharging() and lambda:l_GetShieldChargeMeter() == 100 and LambdaRNG( 1, 30 ) == 1 then
            local enemy = lambda:GetEnemy()
            local isPanicking = ( lambda:IsPanicking() and !lambda:GetIsFiring() or !lambda:InCombat() and ( lambda.l_TF_CoveredInUrine or lambda.l_TF_CoveredInMilk or LAMBDA_TF2:IsBurning( lambda ) or LAMBDA_TF2:IsBleeding( lambda ) ) )

            local canCharge = isPanicking
            if !canCharge and lambda:InCombat() then
                local selfPos = lambda:GetPos()
                local enemyPos = enemy:GetPos()
                local stepHeight = lambda.loco:GetStepHeight()
                local chargeDist = ( 1000 / lambda.l_TF_Shield_ChargeDrainRateMult )

                if ( enemyPos.z >= ( selfPos.z - stepHeight ) and enemyPos.z <= ( selfPos.z + stepHeight ) ) and ( !lambda.l_HasMelee and !lambda:GetIsReloading() or lambda.l_HasMelee and lambda:IsInRange( enemy, chargeDist ) ) and !lambda:IsInRange( enemy, ( lambda.l_CombatAttackRange or chargeDist ) ) and lambda:CanSee( enemy ) then
                    lambda:LookTo( enemy, 1.0 )
                    local eneDir = ( enemyPos - selfPos ); eneDir.z = 0
                    local los = deg( acos( lambda:GetForward():Dot( eneDir:GetNormalized() ) ) )
                    canCharge = ( los <= 15 )
                end
            end

            if canCharge then
                lambda:EmitSound( "lambdaplayers/tf2/shield_charge.mp3", 80, nil, nil, CHAN_STATIC )
                lambda:PlaySoundFile( "fall", false ) --( isPanicking and "fall" or "taunt" )

                local chargeTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 32, 16, 0.75, "effects/beam001_white", lambda:WorldSpaceCenter(), lambda )
                lambda:DeleteOnRemove( chargeTrail )
                lambda.l_TF_Shield_ChargeTrail = chargeTrail

                lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate / ( shieldType != 3 and 20 or 1 ) )
                lambda:l_SetIsShieldCharging( true )

                LAMBDA_TF2:RemoveBurn( lambda )
                LAMBDA_TF2:RemoveBleeding( lambda )
                if lambda.l_TF_CoveredInUrine then lambda.l_TF_CoveredInUrine = 0 end
                if lambda.l_TF_CoveredInMilk then lambda.l_TF_CoveredInMilk = 0 end

                lambda.l_nextspeedupdate = 0
                lambda:SetCrouch( false )
                lambda:SetSlowWalk( false )
            end
        end

        if lambda:l_GetIsShieldCharging() then
            if !isdead then
                if CurTime() >= lambda.l_WeaponUseCooldown then
                    lambda.l_WeaponUseCooldown = CurTime() + 0.1
                end

                local curVel = lambda.loco:GetVelocity()
                curVel.x = 0
                curVel.y = 0

                lambda.loco:SetVelocity( curVel + lambda:GetForward() * min( lambda:GetRunSpeed() * 2 ) )

                if lambda:l_GetShieldChargeMeter() <= 75 then
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
                        if lambda:l_GetShieldChargeMeter() <= 40 then
                            impactEnt:EmitSound( "weapons/demo_charge_hit_flesh_range" .. LambdaRNG( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                        else
                            impactEnt:EmitSound( "weapons/demo_charge_hit_flesh" .. LambdaRNG( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                        end

                        local bashDmg = LAMBDA_TF2:RemapClamped( lambda:l_GetShieldChargeMeter(), 90, 40, 10, 30 )
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
                        lambda:EmitSound( "weapons/demo_charge_hit_world" .. LambdaRNG( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
                    end

                    lambda:l_SetIsShieldCharging( false )
                    ScreenShake( lambdaPos, 25, 150, 1, 750 )
                else
                    lambda:l_SetShieldChargeMeter( lambda:l_GetShieldChargeMeter() - ( ( ( 100 / 1.5 ) * FrameTime() ) * lambda.l_TF_Shield_ChargeDrainRateMult ) )
                    lambda:l_SetShieldLastNoChargeTime( CurTime() )
                end
            end

            if isdead or !lambda:l_GetIsShieldCharging() or lambda:l_GetShieldChargeMeter() <= 0 then
                lambda:l_SetIsShieldCharging( false )
                if isdead then lambda:l_SetShieldChargeMeter( 100 ) end
                lambda:l_SetShieldLastNoChargeTime( CurTime() )

                lambda:SimpleTimer( ( isdead and 0 or 0.3 ), function()
                    if lambda.l_TF_Shield_CritBoosted then
                        weapon:EmitSound( ")weapons/weapon_crit_charged_off.wav", nil, nil, 0.25, CHAN_STATIC )
                    end
                    lambda.l_TF_Shield_CritBoosted = false
                    LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Shield_CritBoostSound )
                    lambda:l_SetNextMeleeCrit( TF_CRIT_NONE )
                end, true )

                lambda:SimpleTimer( 1.0, function()
                    if lambda:l_GetCritBoostType() != TF_CRIT_NONE then return end
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

                    if lambda:l_GetShieldChargeMeter() <= 40 then
                        lambda:l_SetNextMeleeCrit( TF_CRIT_FULL )
                    elseif lambda:l_GetShieldChargeMeter() <= 75 then
                        lambda:l_SetNextMeleeCrit( TF_CRIT_MINI )
                    end

                    lambda:l_SetShieldChargeMeter( 0 )
                end

                lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate )
                lambda:StopSound( "lambdaplayers/tf2/shield_charge.mp3" )

                local chargeTrail = lambda.l_TF_Shield_ChargeTrail
                if IsValid( chargeTrail ) then
                    chargeTrail:SetParent( NULL )
                    SafeRemoveEntityDelayed( chargeTrail, 1 )
                end
            end
        elseif !isdead and lambda:l_GetShieldChargeMeter() != 100 then
            local chargeRate = ( ( 100 / 12 ) * FrameTime() )
            if shieldType == 2 then chargeRate = ( chargeRate * 1.5 ) end
            lambda:l_SetShieldChargeMeter( lambda:l_GetShieldChargeMeter() + chargeRate )

            if lambda:l_GetShieldChargeMeter() >= 100 then
                weapon:EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
                lambda:l_SetShieldChargeMeter( 100 )
            end
        end
    end

    if !isdead then
        -- debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2.2, "TF Class: " .. ( lambda.l_TF_FavClass or lambda.l_TF_Class ), FrameTime() * 2 )

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

        if lambda.l_TF_MmmphActivated then
            lambda.l_TF_MmmphMeter = ( lambda.l_TF_MmmphMeter - ( FrameTime() * 10 ) )

            if lambda.l_TF_MmmphMeter <= 0 then
                lambda.l_TF_MmmphMeter = 0
                lambda.l_TF_MmmphActivated = false
            end
        end

        if lambda.l_TF_FocusActivated then
            lambda.l_TF_FocusMeter = ( lambda.l_TF_FocusMeter - ( FrameTime() * 10 ) )

            if lambda.l_TF_FocusMeter <= 0 then
                lambda.l_TF_FocusMeter = 0
                lambda.l_TF_FocusActivated = false
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

            -- debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 1.8, "Buff Pulses Left: " .. lambda.l_TF_RagePulseCount, FrameTime() * 2 )
        end

        local parachute = lambda.l_TF_ParachuteModel
        if IsValid( parachute ) then
            if lambda.l_FallVelocity > 100 then
                if !lambda.l_TF_ParachuteOpen then
                    if CurTime() >= lambda.l_TF_ParachuteCheckT then
                        lambda.l_TF_ParachuteOpen = true
                        parachute:SetBodygroup( 0, 1 )
                        parachute:SetBodygroup( 1, 1 )
                        parachute:EmitSound( "items/para_open.wav", 65, nil, nil, CHAN_STATIC )
                    end
                else
                    local vel = lambda.loco:GetVelocity()
                    vel.z = max( vel.z, -112 )
                    lambda.loco:SetVelocity( vel )
                end
            else
                if CurTime() >= lambda.l_TF_ParachuteCheckT then
                    lambda.l_TF_ParachuteCheckT = ( CurTime() + 1.0 )
                end

                if lambda.l_TF_ParachuteOpen then
                    lambda.l_TF_ParachuteOpen = false
                    parachute:SetBodygroup( 0, 0 )
                    parachute:SetBodygroup( 1, 0 )
                    parachute:EmitSound( "items/para_close.wav", 65, nil, nil, CHAN_STATIC )
                end
            end
        end

        -- if buffType then
        --     debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2.2, "Buff Type: " .. lambda.l_TF_RageBuffType, FrameTime() * 2 )
        --     debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2, "Buff Meter: " .. Round( lambda.l_TF_RageMeter ) .. "%", FrameTime() * 2 )
        -- end

        if lambda.l_TF_Medigun_ChargeReleased then
            lambda.l_TF_Medigun_ChargeMeter = max( 0, lambda.l_TF_Medigun_ChargeMeter - ( ( 100 / 9 ) * FrameTime() ) )

            if lambda.l_TF_Medigun_ChargeMeter <= 0 then
                lambda.l_TF_Medigun_ChargeMeter = 0
                lambda:EmitSound( lambda.l_TF_MedigunChargeDrainSound, nil, nil, nil, CHAN_STATIC )

                LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Medigun_ChargeReleaseSound )
                if lambda.l_TF_Medigun_ChargeReady then
                    LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Medigun_ChargeSound )

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
                            weapon:EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
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

            lambda.l_TF_NextInventoryCheckT = ( CurTime() + LambdaRNG( 0.1, 1.0, true ) )
        end

        if lambda.l_TF_AtomicPunched and CurTime() >= lambda.l_TF_AtomicPunched then
            lambda.l_TF_AtomicPunched = false

            local damageTook = lambda.l_TF_AtomicPunched_DamageTaken
            if damageTook > 0 then
                lambda:EmitSound( "player/pl_scout_dodge_tired.wav", 60, lambda:GetVoicePitch(), nil, CHAN_VOICE )
                lambda.l_TF_AtomicPunched_SlowdownScale = LAMBDA_TF2:RemapClamped( damageTook, 0, 200, 0.75, 0.5 )
                lambda.l_TF_AtomicPunched_SlowdownTime = ( CurTime() + 5 )
                lambda.l_nextspeedupdate = 0
            else
                lambda.l_TF_AtomicPunched_SlowdownScale = false
            end
            lambda.l_TF_AtomicPunched_DamageTaken = 0

            local trail = lambda.l_TF_AtomicPunched_Trail
            if IsValid( trail ) then
                trail:SetParent( NULL )
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
            weapon:EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
        end

        for barIndex, bar in ipairs( lambda.l_TF_DalokohsBars ) do
            if CurTime() < bar.ExpireTime then continue end

            local hpRatio = bar.HealthRatio
            local oldHP = Round( lambda:GetMaxHealth() / hpRatio )

            if !isdead then lambda:SetHealth( Round( lambda:Health() * ( oldHP / lambda:GetMaxHealth() ) ) ) end
            lambda:SetMaxHealth( oldHP )

            local headsGiveHP = weapon.l_TF_Eyelander_GiveHealth
            if headsGiveHP then weapon.l_TF_Eyelander_GiveHealth = ( headsGiveHP / hpRatio ) end

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
                    totalDmg = ( totalDmg + v.Damage )
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

            --debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * 2, "Uber-Charge: " .. Round( lambda.l_TF_Medigun_ChargeMeter ) .. "%", FrameTime() * 2 )

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

            local goPickup = lambda.l_TF_GoingAfterPickup
            if goPickup then
                local moveEnt = lambda.l_movepos
                if !lambda.l_issmoving or isvector( moveEnt ) or !IsValid( moveEnt ) or moveEnt != goPickup then
                    lambda.l_TF_GoingAfterPickup = nil
                elseif !IsValid( goPickup ) or goPickup.IsLambdaTFMedkit and ( goPickup.IsRespawning or lambda:Health() >= lambda:GetMaxHealth() or LAMBDA_TF2:GetMedigunHealers( lambda, true ) != 0 ) then
                    lambda:CancelMovement()
                    lambda.l_TF_GoingAfterPickup = nil
                end
            end

            if lambda:l_GetIsBurning() then
                lambda:SetRun( true )

                if CurTime() > lambda.l_nextidlesound and !lambda:IsDisabled() and !lambda:GetIsTyping() and !lambda:IsSpeaking() and LambdaRNG( 1, 100 ) <= lambda:GetVoiceChance() then
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

                if lambda.l_TF_IsStunned then desSpeed = ( desSpeed * ( 1.0 - lambda.l_TF_StunSpeedReduction ) ) end
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

    local rndClass = GetConVar( "lambdaplayers_tf2_changeclasschance" ):GetInt()
    if LambdaRNG( 1, 100 ) <= rndClass then lambda.l_TF_Class = LambdaRNG( 1, 9 ) end

    if lambda.l_TF_RevengeCrits > 0 and lambda:CanEquipWeapon( "tf2_frontierjustice" ) then
        lambda:SwitchWeapon( "tf2_frontierjustice" )

        if LambdaRNG( 1, 100 ) <= lambda:GetVoiceChance() then
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

    local rndItems = GetConVar( "lambdaplayers_tf2_randomizeitemsonrespawn" ):GetInt()
    if LambdaRNG( 1, 100 ) <= rndItems then LAMBDA_TF2:AssignLambdaInventory( lambda ) end

    local bonemergedMdls = lambda.l_TF_BonemergedModels
    for model, mdlEnt in pairs( bonemergedMdls ) do
        if !IsValid( mdlEnt ) then
            bonemergedMdls[ model ] = nil
            continue
        end

        if mdlEnt.l_TF_ParentDied then
            lambda:ClientSideNoDraw( mdlEnt, false )
            mdlEnt:SetNoDraw( false )
            mdlEnt:DrawShadow( true )
            mdlEnt.l_TF_ParentDied = false
        end
    end
end

local function OnLambdaInjured( lambda, dmginfo )
    local shieldType = lambda.l_TF_Shield_Type
    if shieldType then
        if dmginfo:IsDamageType( DMG_BURN ) or LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_IGNITE ) then
            dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.5 )
        elseif dmginfo:IsExplosionDamage() then
            dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.7 )
        end

        if lambda:l_GetIsShieldCharging() and shieldType == 3 and dmginfo:GetAttacker() != lambda and !dmginfo:IsDamageType( DMG_FALL ) then
            lambda:l_SetShieldChargeMeter( lambda:l_GetShieldChargeMeter() - dmginfo:GetDamage() )
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

    if lambda.l_TF_SniperShieldType == 3 and ( dmginfo:IsDamageType( DMG_BURN ) or LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_IGNITE ) ) then
        dmginfo:ScaleDamage( 0.5 )
    end

    lambda.l_TF_HypeMeter = max( 0, lambda.l_TF_HypeMeter + ( dmginfo:GetDamage() * 4 ) )
end

local function OnLambdaOnOtherInjured( lambda, victim, dmginfo, tookDamage )
    local attacker = dmginfo:GetAttacker()
    if !IsValid( attacker ) or !LAMBDA_TF2:IsValidCharacter( attacker ) or attacker == victim or attacker == lambda then return end

    if victim.l_TF_HasMedigunEquipped and LAMBDA_TF2:GetMedigunHealers( lambda )[ victim ] and lambda:CanTarget( attacker ) then
        lambda:AttackTarget( attacker )
    end
end

local function OnLambdaKilled( lambda, dmginfo )
    local ragdoll = lambda.ragdoll
    local isServerRags = serverRags:GetBool()

    local dmgCustom = dmginfo:GetDamageCustom()
    local doDecapitation = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomDecapitates ) )
    local isDissolving = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomDissolves ) )
    local shouldBurn = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBurns + TF_DMG_CUSTOM_IGNITE ) )

    local turnIntoAshes = ( LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_BURNING_PHLOG ) )
    if !turnIntoAshes and lambda:l_GetIsBurning() then
        turnIntoAshes = ( LAMBDA_TF2:IsDamageCustom( lambda.l_TF_BurnDamageCustom, TF_DMG_CUSTOM_BURNING_PHLOG ) )
    end

    local burnTime = LAMBDA_TF2:GetBurnEndTime( lambda )
    if burnTime then
        burnTime = ( burnTime - CurTime() )
    elseif shouldBurn then
        burnTime = LambdaRNG( 2, 5, true )
    end

    if LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_TURNGOLD ) then
        if !IsValid( ragdoll ) then
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
        local animTbl
        local turnIntoIce = false
        if isDissolving then
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_PLASMA ]
        elseif doDecapitation or LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomHeadshots ) then
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_HEADSHOT ]
        elseif LAMBDA_TF2:IsDamageCustom( dmgCustom, dmgCustomBackstabs ) then
            local inflictor = dmginfo:GetInflictor()
            turnIntoIce = ( IsValid( inflictor ) and inflictor.TF2Data and inflictor:GetWeaponAttribute( "FreezeOnBackstab", false ) )
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_BACKSTAB ]
        elseif shouldBurn then
            animTbl = tf2DeathAnims[ TF_DMG_CUSTOM_BURNING ]
        end

        local mins, maxs = lambda:GetCollisionBounds()
        groundCheckTbl.start = lambda:GetPos()
        groundCheckTbl.endpos = ( groundCheckTbl.start - vector_up * 4 )
        groundCheckTbl.filter = lambda
        groundCheckTbl.mins = mins
        groundCheckTbl.maxs = maxs
        groundCheckTbl.collisiongroup = lambda:GetCollisionGroup()
        groundCheckTbl.mask = lambda:GetSolidMask()

        local groundTr = TraceHull( groundCheckTbl )
        local onGround = ( groundTr.Hit )

        if animTbl and ( turnIntoIce or LambdaRNG( 1, 100 ) <= GetConVar( "lambdaplayers_tf2_deathanimchance" ):GetInt() ) and ( onGround or isDissolving ) then
            local isTFAnim = true
            local index, dur = lambda:LookupSequence( animTbl[ LambdaRNG( #animTbl ) ] )

            if index <= 0 then
                isTFAnim = false
                index, dur = lambda:LookupSequence( gmodDeathAnims[ LambdaRNG( #gmodDeathAnims ) ] )

                if index <= 0 then
                    index = lambda:SelectWeightedSequence( ACT_DIESIMPLE )
                    if index > 0 then dur = lambda:SequenceDuration( index ) end
                end
            end

            if index > 0 and ( isTFAnim or !isDissolving and !shouldBurn ) then
                local animEnt = ents_Create( "base_gmodentity" )
                animEnt:SetModel( lambda:GetModel() )
                animEnt:SetPos( groundTr.HitPos )
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

                local speed = LambdaRNG( 0.8, 1.1, true )
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

                if IsValid( ragdoll ) then
                    ragdoll:Remove()
                else
                    net.Start( "lambda_tf2_removecsragdoll" )
                        net.WriteEntity( lambda )
                    net.Broadcast()
                end
                ragdoll = animEnt

                if burnTime then
                    ParticleEffectAttach( "burningplayer_" .. ( lambda.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, animEnt, 0 )

                    local burningSnd = LAMBDA_TF2:CreateSound( animEnt, "ambient/fire/fire_small_loop" .. LambdaRNG( 1, 2 ) .. ".wav" )
                    burningSnd:PlayEx( 0.8, 100 )
                    burningSnd:SetSoundLevel( 75 )
                end

                local nextAshSpawnT
                if turnIntoAshes then
                    nextAshSpawnT = ( CurTime() + 0.5 )
                    ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, animEnt, 0 )
                end

                local finishTime = ( CurTime() + ( dur / speed ) * ( isTFAnim and 1 or LambdaRNG( 0.8, 1, true ) ) )
                lambda:Thread( function()

                    while ( IsValid( animEnt ) and CurTime() < finishTime and ( animEnt.l_FreezeTime == 0 or CurTime() < animEnt.l_FreezeTime ) ) do
                        animEnt:FrameAdvance()

                        if nextAshSpawnT and CurTime() > nextAshSpawnT then
                            nextAshSpawnT = ( CurTime() + 0.5 )
                            ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, animEnt, 0 )
                        end

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

                    if !isDissolving then
                        if !isServerRags and !turnIntoIce then
                            lambda:CreateClientsideRagdoll( nil, animEnt )
                            lambda.ragdoll = nil
                            lambda:SetNW2Entity( "lambda_serversideragdoll", nil )

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
                                    net.WriteFloat( Clamp( burnTime, 2, 10 ) )
                                    net.WriteBool( turnIntoAshes )
                                net.Broadcast()
                            end

                            for model, mdlEnt in pairs( animEnt.l_TF_BonemergedModels ) do
                                if !IsValid( mdlEnt ) or mdlEnt:GetNoDraw() then continue end

                                net.Start( "lambda_tf2_bonemergemodel" )
                                    net.WriteEntity( lambda )
                                    net.WriteString( model )
                                net.Broadcast()
                            end
                        else
                            local serverRag = lambda:CreateServersideRagdoll( nil, animEnt )

                            for model, mdlEnt in pairs( animEnt.l_TF_BonemergedModels ) do
                                if !IsValid( mdlEnt ) or mdlEnt:GetNoDraw() then continue end
                                LAMBDA_TF2:CreateBonemergedModel( serverRag, model )
                            end

                            if turnIntoIce then
                                LAMBDA_TF2:TurnIntoStatue( serverRag, "models/player/shared/ice_player", physProp_Ice )
                            else
                                if doDecapitation then
                                    LAMBDA_TF2:DecapitateHead( serverRag, false )
                                end

                                if burnTime then
                                    LAMBDA_TF2:AttachFlameParticle( serverRag, Clamp( burnTime, 2, 10 ), lambda.l_TF_TeamColor )
                                end

                                if turnIntoAshes then
                                    serverRag:SetRenderMode( RENDERMODE_TRANSCOLOR )
                                    ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, serverRag, 0 )

                                    local removeT = ( CurTime() + 0.5 )
                                    LambdaCreateThread( function()
                                        while ( IsValid( serverRag ) and CurTime() < removeT ) do
                                            local ragColor = serverRag:GetColor()
                                            ragColor.a = LAMBDA_TF2:RemapClamped( ( removeT - CurTime() ), 0, 0.5, 0, 255 )

                                            serverRag:SetColor( ragColor )
                                            coroutine_yield()
                                        end
                                        if IsValid( serverRag ) then serverRag:Remove() end
                                    end )
                                end
                            end
                        end
                    end

                    animEnt:SetNoDraw( true )
                    animEnt:DrawShadow( false )

                    coroutine_wait( 0.1 )
                    if IsValid( animEnt ) then animEnt:Remove() end

                end, "TF2_DeathAnimation_" .. animEnt:EntIndex(), true )
            end
        end

        if turnIntoIce and !onGround and !IsValid( ragdoll ) then
            net.Start( "lambda_tf2_removecsragdoll" )
                net.WriteEntity( lambda )
            net.Broadcast()

            ragdoll = lambda:CreateServersideRagdoll( dmginfo )
        end

        if IsValid( ragdoll ) then
            if turnIntoIce then
                local frozenTime = ( CurTime() + LambdaRNG( 9.0, 11.0, true ) )

                if ragdoll.l_IsTFDeathAnimation then
                    ragdoll.l_FreezeTime = ( CurTime() + ( LambdaRNG( 0.2, 0.75, true ) / ragdoll.l_PlayBackSpeed ) )
                    ragdoll.l_FrozenTime = frozenTime
                    ragdoll:SetMaterial( "models/player/shared/ice_player" )

                    SimpleTimer( 0, function()
                        if !IsValid( ragdoll ) then return end

                        for _, child in ipairs( ragdoll:GetChildren() ) do
                            if !IsValid( child ) then continue end
                            child:SetMaterial( "models/player/shared/ice_player" )
                        end
                    end )
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
                if isDissolving then
                    ragdoll:EmitSound( "player/dissolve.wav", nil, nil, nil, CHAN_STATIC )

                    if ragdoll.l_IsTFDeathAnimation then
                        local dissolver = ents_Create( "env_entity_dissolver" )
                        dissolver:SetKeyValue( "target", "!activator" )
                        dissolver:Input( "dissolve", ragdoll )
                        dissolver:Remove()
                    end
                else
                    if doDecapitation then
                        LAMBDA_TF2:DecapitateHead( ragdoll, true, ( dmginfo:GetDamageForce() / 10 ) )
                    end

                    if turnIntoAshes and !ragdoll.l_IsTFDeathAnimation then
                        ragdoll:SetRenderMode( RENDERMODE_TRANSCOLOR )
                        ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )

                        local removeT = ( CurTime() + 0.5 )
                        LambdaCreateThread( function()
                            while ( IsValid( ragdoll ) and CurTime() < removeT ) do
                                local ragColor = ragdoll:GetColor()
                                ragColor.a = LAMBDA_TF2:RemapClamped( ( removeT - CurTime() ), 0, 0.5, 0, 255 )

                                ragdoll:SetColor( ragColor )
                                coroutine_yield()
                            end
                            if IsValid( ragdoll ) then ragdoll:Remove() end
                        end )
                    end
                end

                if burnTime and !ragdoll.l_IsTFDeathAnimation then
                    LAMBDA_TF2:AttachFlameParticle( ragdoll, Clamp( burnTime, 2, 10 ), lambda.l_TF_TeamColor )
                end
            end
        else
            if doDecapitation then
                net.Start( "lambda_tf2_decapitate_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteBool( true )
                    net.WriteVector( dmginfo:GetDamageForce() / 2 )
                net.Broadcast()
            end

            if burnTime then
                net.Start( "lambda_tf2_ignite_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteString( "burningplayer_" .. ( lambda.l_TF_TeamColor == 1 and "blue" or "red" ) )
                    net.WriteFloat( Clamp( burnTime, 2, 10 ) )
                    net.WriteBool( turnIntoAshes )
                net.Broadcast()
            end

            lambda.ragdoll = nil
            lambda:SetNW2Entity( "lambda_serversideragdoll", lambda.ragdoll )
        end
    end

    lambda:l_SetShieldChargeMeter( 100 )

    local attacker = dmginfo:GetAttacker()
    LAMBDA_TF2:CalcDominationAndRevenge( attacker, lambda )

    if IsValid( attacker ) and attacker.IsLambdaPlayer then
        attacker.l_TF_Decapitations = ( attacker.l_TF_Decapitations + lambda.l_TF_Decapitations )
        attacker.l_TF_CollectedOrgans = ( attacker.l_TF_CollectedOrgans + lambda.l_TF_CollectedOrgans )
    end

    lambda:SimpleTimer( 0.1, function()
        lambda.l_TF_Decapitations = 0
    end, true )

    lambda.l_TF_IsUsingItem = false
    lambda.l_TF_CrikeyMeter = 0
    lambda.l_TF_CrikeyMeterFull = false

    lambda.l_TF_FocusActivated = false
    lambda.l_TF_FocusMeter = 0
    lambda.l_TF_FocusMeterFull = false

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

    lambda.l_TF_MmmphMeter = 0
    lambda.l_TF_MmmphActivated = false
    lambda.l_TF_SniperShieldRechargeT = 0
    lambda.l_TF_HypeMeter = 0
    lambda.l_TF_ThrownBaseball = false
    lambda.l_TF_AtomicPunched = false
    lambda.l_TF_AtomicPunched_SlowdownScale = false
    lambda.l_TF_AtomicPunched_DamageTaken = 0
    table_Empty( lambda.l_TF_MedicsToIgnoreList )

    local bonkTrail = lambda.l_TF_AtomicPunched_Trail
    if IsValid( bonkTrail ) then
        bonkTrail:SetParent( NULL )
        SafeRemoveEntityDelayed( bonkTrail, 1 )
    end
    lambda.l_TF_AtomicPunched_Trail = nil

    local ammopack
    local wepent = lambda:GetWeaponENT()
    local dropAmmo = GetConVar( "lambdaplayers_tf2_dropammobox" ):GetInt()
    if dropAmmo == 1 and wepent.TF2Data or dropAmmo == 2 then
        if lambda.l_TF_HasEdibles then
            ammopack = LAMBDA_TF2:CreateMedkit( wepent:GetPos(), "models/items/ammopack_medium.mdl", ( LambdaRNG( 1, 9 ) == 1 and 0.6 or 0.3 ), false, nil, true )
        else
            ammopack = LAMBDA_TF2:CreateAmmobox( wepent:GetPos(), "models/items/ammopack_medium.mdl", 0.5 )
        end
        if IsValid( ammopack ) then
            ammopack:SetAngles( wepent:GetUp():Angle() )
            ammopack:SetOwner( lambda )
            ammopack.IsLambdaSpawned = true

            local vecImpulse = vector_origin
            vecImpulse = ( vecImpulse + ammopack:GetUp() * LambdaRNG( -0.25, 0.25, true ) + ammopack:GetRight() * LambdaRNG( -0.25, 0.25, true ) ):GetNormalized()
            vecImpulse = ( vecImpulse * LambdaRNG( 100, 150, true ) + ammopack:GetVelocity() )

            local speed = vecImpulse:Length()
            if speed > 300 then vecImpulse = ( vecImpulse * ( 300 / speed ) ) end

            local phys = ammopack:GetPhysicsObject()
            if IsValid( phys ) then
                phys:SetMass( 25 )
                phys:SetVelocityInstantaneous( vecImpulse )

                ammoboxAngImpulse.y = LambdaRNG( 0, 100, true )
                phys:SetAngleVelocityInstantaneous( ammoboxAngImpulse )
            end
        end
    end

    local numPacks = 0
    local packLimit = GetConVar( "lambdaplayers_tf2_ammoboxlimit" ):GetInt()
    for _, oldAmmopack in ipairs( FindByClass( "lambda_tf_ammobox_*" ) ) do
        if oldAmmopack == ammopack or !IsValid( oldAmmopack ) or oldAmmopack:GetOwner() != lambda then continue end

        numPacks = ( numPacks + 1 )
        if numPacks >= packLimit then oldAmmopack:Remove() end
    end

    local bonemergedMdls = lambda.l_TF_BonemergedModels
    for model, mdlEnt in pairs( bonemergedMdls ) do
        if !IsValid( mdlEnt ) then
            bonemergedMdls[ model ] = nil
            continue
        end

        if !mdlEnt:GetNoDraw() then
            lambda:ClientSideNoDraw( mdlEnt, true )
            mdlEnt:SetNoDraw( true )
            mdlEnt:DrawShadow( false )
            mdlEnt.l_TF_ParentDied = true

            if IsValid( ragdoll ) then
                LAMBDA_TF2:CreateBonemergedModel( ragdoll, model )
            else
                net.Start( "lambda_tf2_bonemergemodel" )
                    net.WriteEntity( lambda )
                    net.WriteString( model )
                net.Broadcast()
            end
        end
    end

    local buffpack = lambda.l_TF_RageBuffPack
    if IsValid( buffpack ) then buffpack:SetBodygroup( 1, 0 ) end

    local parachute = lambda.l_TF_ParachuteModel
    if IsValid( parachute ) and lambda.l_TF_ParachuteOpen then
        lambda.l_TF_ParachuteOpen = false
        parachute:SetBodygroup( 0, 0 )
        parachute:SetBodygroup( 1, 0 )
        parachute:EmitSound( "items/para_close.wav", 65, nil, nil, CHAN_STATIC )
    end

    if lambda.l_TF_Medigun_ChargeReleased then
        lambda:EmitSound( lambda.l_TF_MedigunChargeDrainSound, nil, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Medigun_ChargeReleaseSound )
    end

    if lambda.l_TF_Medigun_ChargeReady then
        lambda:EmitSound( "player/medic_charged_death.wav", 75, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Medigun_ChargeSound )
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

    lambda:StopParticles()
    OnPostEntityTakeDamage( lambda, dmginfo, true )
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

    local healthMult = lambda.l_TF_WeaponHealthMultiplier
    if healthMult then
        local curHP = lambda:GetMaxHealth()
        local oldHP = Round( curHP / healthMult )
        lambda:SetHealth( Round( lambda:Health() * ( oldHP / curHP ) ) )
        lambda:SetMaxHealth( oldHP )
    end

    healthMult = data.healthmultiplier
    if healthMult then
        local curHP = lambda:GetMaxHealth()
        local newHP = Round( curHP * healthMult )
        lambda:SetHealth( Round( lambda:Health() * ( newHP / curHP ) ) )
        lambda:SetMaxHealth( newHP )
    end
    lambda.l_TF_WeaponHealthMultiplier = data.healthmultiplier

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
        LAMBDA_TF2:StopSound( lambda, lambda.l_TF_Medigun_ChargeSound )

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

local tf2LaughAnims = {
    [ "sniper_taunt_laugh" ]    = "vo/sniper_laughlong02.mp3",
    [ "pyro_taunt_laugh" ]      = "vo/pyro_laugh_addl04.mp3",
    [ "medic_taunt_laugh" ]     = "vo/medic_laughlong01.mp3",
    [ "demoman_taunt_laugh" ]   = "vo/demoman_laughlong02.mp3",
    [ "soldier_taunt_laugh" ]   = "vo/soldier_laughlong03.mp3",
    [ "engineer_taunt_laugh" ]  = "vo/engineer_laughlong02.mp3",
    [ "spy_taunt_laugh" ]       = "vo/spy_laughlong01.mp3",
    [ "scout_taunt_laugh" ]     = "vo/scout_laughlong02.mp3",
    [ "heavy_taunt_laugh" ]     = "vo/heavy_laugherbigsnort01.mp3"
}

local function OnLambdaPlayGesture( lambda, gesture )
    if gesture != ACT_GMOD_TAUNT_LAUGH or !lambda:GetWeaponENT().TF2Data and !GetConVar( "lambdaplayers_tf2_alwaysuseschadenfreude" ):GetBool() then return end

    local laughSnd, seqName = table_Random( tf2LaughAnims )
    if lambda:LookupSequence( seqName ) <= 0 then return end

    if GetConVar( "lambdaplayers_tf2_schadenfreudeplaysclasslaughter" ):GetBool() then
        lambda:EmitSound( laughSnd, 80, lambda:GetVoicePitch(), nil, CHAN_VOICE )
    end
    return seqName
end

local function OnLambdaChangeState( lambda, old, new, arg )
    if new == "Laughing" and old == "HealWithMedigun" and ( lambda.l_TF_Medigun_ChargeReleased or LambdaRNG( 1, 4 ) != 1 ) then
        return true
    end

    if lambda:Alive() then
        if old == "UseTFItem" and lambda.l_TF_IsUsingItem then
            lambda.l_TF_PreUseItemState = new
            return true
        end

        if old == "Stunned" and lambda.l_TF_IsStunned and CurTime() <= lambda.l_TF_StunStateChangeT then
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

    if GetConVar( "lambdaplayers_tf2_lockwpnsforclasses" ):GetBool() then
        local plyClass = ( lambda.l_TF_FavClass or lambda.l_TF_Class )
        local classReq = data.tfclass
        if plyClass and classReq then
            if istable( classReq ) then 
                if !classReq[ plyClass ] then return true end
            elseif plyClass != classReq then 
                return true 
            end
        end
    end

    local invWep = lambda.l_TF_Inventory[ name ]
    if invWep and !invWep.IsReady then return true end

    local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
    if preInvWep and name != preInvWep.Name then return true end
end

local function OnLambdaAttackTarget( lambda, target )
    if lambda.l_TF_IsUsingItem then return true end

    local state = lambda:GetState()
    if state == "Stunned" then return true end

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
    if medicList then
        if lambda:InCombat() and ent.l_TF_Medic_HealTarget == lambda:GetEnemy() then
            lambda.l_TF_MedicsToIgnoreList[ ent ] = nil
        elseif CurTime() <= medicList then
            return true
        end
    end

    if ent.l_TF_HasMedigunEquipped and LAMBDA_TF2:GetMedigunHealers( lambda )[ ent ] then return true end
end

local function OnLambdaBeginMove( lambda, pos, onNavmesh )
    local goPickup = nil

    if LambdaRNG( 1, 4 ) != 1 and !lambda:InCombat() and !lambda:IsPanicking() then
        if ( lambda:Health() < ( lambda:GetMaxHealth() * LambdaRNG( 0.66, 0.9, true ) ) or LAMBDA_TF2:IsBleeding( lambda ) or LAMBDA_TF2:IsBurning( lambda ) ) and LAMBDA_TF2:GetMedigunHealers( lambda, true ) == 0 then
            local medkits = lambda:FindInSphere( nil, LambdaRNG( 300, 1500 ), function( ent )
                return ( ent.IsLambdaTFMedkit and !ent.IsRespawning or ent.IsLambdaTFLocker )
            end )
            if #medkits != 0 then
                local rndMedkit = medkits[ LambdaRNG( #medkits ) ]
                lambda:SetRun( true )
                lambda:RecomputePath( rndMedkit )
                goPickup = rndMedkit

                if rndMedkit.IsLambdaTFLocker then
                    local path = lambda.l_CurrentPath
                    if IsValid( path ) then path:SetGoalTolerance( 50 ) end
                end
            end
        end

        if !goPickup and lambda.l_TF_ThrownBaseball then
            local balls = lambda:FindInSphere( nil, LambdaRNG( 300, 1500 ), function( ent )
                return ( ent.l_IsTFBaseball )
            end )
            if #balls != 0 then
                local rndBall = balls[ LambdaRNG( #balls ) ]
                lambda:SetRun( true )
                lambda:RecomputePath( rndBall )
                goPickup = rndBall
            end
        end
    end

    lambda.l_TF_GoingAfterPickup = goPickup
end

local function OnLambdaOnOtherKilled( lambda, victim, dmginfo )
    if victim != lambda:GetEnemy() then return end

    for medic, _ in RandomPairs( LAMBDA_TF2:GetMedigunHealers( victim ) ) do
        if lambda:CanTarget( medic ) then
            lambda:AttackTarget( medic )
            return true
        end
    end
end

hook.Add( "LambdaOnRespawn", "LambdaTF2_OnLambdaRespawn", OnLambdaRespawn )
hook.Add( "LambdaOnThink", "LambdaTF2_OnLambdaThink", OnLambdaThink )
hook.Add( "LambdaOnInjured", "LambdaTF2_OnLambdaOnInjured", OnLambdaInjured )
hook.Add( "LambdaOnOtherInjured", "LambdaTF2_OnLambdaOnOtherInjured", OnLambdaOnOtherInjured )
hook.Add( "LambdaOnKilled", "LambdaTF2_OnLambdaKilled", OnLambdaKilled )
hook.Add( "LambdaOnChangeState", "LambdaTF2_OnLambdaChangeState", OnLambdaChangeState )
hook.Add( "LambdaCanSwitchWeapon", "LambdaTF2_OnLambdaCanSwitchWeapon", OnLambdaCanSwitchWeapon )
hook.Add( "LambdaOnSwitchWeapon", "LambdaTF2_OnLambdaSwitchWeapon", OnLambdaSwitchWeapon )
hook.Add( "LambdaOnAttackTarget", "LambdaTF2_OnLambdaAttackTarget", OnLambdaAttackTarget )
hook.Add( "LambdaCanTarget", "LambdaTF2_OnLambdaCanTarget", OnLambdaCanTarget )
hook.Add( "LambdaOnBeginMove", "LambdaTF2_OnLambdaBeginMove", OnLambdaBeginMove )
hook.Add( "LambdaOnPlayGestureAndWait", "LambdaTF2_OnLambdaPlayGesture", OnLambdaPlayGesture )
hook.Add( "LambdaOnOtherKilled", "LambdaTF2_OnLambdaOnOtherKilled", OnLambdaOnOtherKilled )
