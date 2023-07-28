local TraceLine = util.TraceLine
local TraceHull = util.TraceHull
local CurTime = CurTime
local ipairs = ipairs
local random = math.random
local net = net
local min = math.min
local max = math.max
local FrameTime = FrameTime
local IsValid = IsValid
local StartWith = string.StartWith
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local SoundDuration = SoundDuration
local DamageInfo = DamageInfo
local Rand = math.Rand
local VectorRand = VectorRand
local ents_Create = ents.Create
local FindAlongRay = ents.FindAlongRay
local ParticleTracerEx = util.ParticleTracerEx
local ParticleEffect = ParticleEffect
local ParticleEffectAttach = ParticleEffectAttach
local istable = istable
local isvector = isvector
local isnumber = isnumber
local isfunction = isfunction
local isstring = isstring
local EffectData = EffectData
local util_Effect = util.Effect
local util_Decal = util.Decal
local IsPredicted = IsFirstTimePredicted
local Vector = Vector
local SimpleTimer = timer.Simple

local meleetbl = { 
    mins = Vector( -18, -18, -18 ),
    maxs = Vector( 18, 18, 18 ),
    filter = { NULL, NULL } 
}
local bulletTbl = {
    Tracer = 0
}
local spreadVector = Vector( 0, 0, 0 )
local medigunTraceTbl = {
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    filter = { NULL, NULL, NULL }
}
local rayWorldTbl = {}
local dmgTraceTbl = { mask = ( MASK_SOLID + CONTENTS_HITBOX ) }
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
local shotgunCockingTimings = {
    { 0.342857, 0.485714 },
    { 0.285714, 0.428571 },
    { 0.4, 0.533333 },
    { 0.233333, 0.366667 }
}
local flameSize = Vector( 12, 12, 12 )
local pipeBounds = Vector( 2, 2, 2 )
local pipeTouchTrTbl = { mask = MASK_SOLID }
local groundTrTbl = { mask = MASK_SOLID_BRUSHONLY }

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
    local endSnd = dataTbl.EndSound

    local cycleSnd = dataTbl.CycleSound
    if cycleSnd == nil then cycleSnd = "weapons/shotgun_worldreload.wav" end

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
        if startSnd then weapon:EmitSound( ( istable( startSnd ) and startSnd[ random( #startSnd ) ] or startSnd ), 70, nil, nil, CHAN_STATIC ) end
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
            if cycleSnd then weapon:EmitSound( ( istable( cycleSnd ) and cycleSnd[ random( #cycleSnd ) ] or cycleSnd ), 70, nil, nil, CHAN_STATIC ) end
            coroutine_wait( cycleTime )
        end

        if endSnd then weapon:EmitSound( ( istable( endSnd ) and endSnd[ random( #endSnd ) ] or endSnd ), 70, nil, nil, CHAN_STATIC ) end
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

function LAMBDA_TF2:CreateMuzzleFlash( weapon, muzzleName )
    if !IsPredicted() then return end

    local muzzleAttach = weapon:LookupAttachment( "muzzle" )
    if muzzleAttach <= 0 then return end

    if isnumber( muzzleName ) then
        local muzzleFlash = weapon:GetAttachment( muzzleAttach )
        local muzzleData = EffectData()
        muzzleData:SetOrigin( muzzleFlash.Pos )
        muzzleData:SetStart( muzzleFlash.Pos )
        muzzleData:SetAngles( muzzleFlash.Ang )
        muzzleData:SetFlags( muzzleName )
        muzzleData:SetEntity( weapon )
        util_Effect( "MuzzleFlash", muzzleData )
    else
        ParticleEffectAttach( muzzleName, PATTACH_POINT_FOLLOW, weapon, muzzleAttach )
    end
end

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

            local damage = weapon:GetWeaponAttribute( "Damage", 5 )
            if istable( damage ) then damage = random( damage[ 1 ], damage[ 2 ] ) end
            bulletTbl.Damage = damage
            bulletTbl.Force = ( damage / 3 )

            local weaponSpread = weapon:GetWeaponAttribute( "Spread", 0.1 )
            spreadVector.x = weaponSpread
            spreadVector.y = weaponSpread
            bulletTbl.Spread = spreadVector

            local firePos = ( isvector( target ) and target or target:WorldSpaceCenter() )
            
            local preBulletCallback = weapon:GetWeaponAttribute( "PreFireBulletCallback" )
            if preBulletCallback then 
                local overridePos = preBulletCallback( lambda, weapon, target, dmginfo, bulletTbl ) 
                if isvector( overridePos ) then firePos = overridePos end
            end

            local lambdaAccuracyOffset = LAMBDA_TF2:RemapClamped( lambda:GetRangeTo( firePos ), 128, 1024, 3, 30 )
            local fireAng = ( firePos - wepPos ):Angle()
            fireAng = ( ( firePos + fireAng:Right() * Rand( -lambdaAccuracyOffset, lambdaAccuracyOffset ) + fireAng:Up() * Rand( -lambdaAccuracyOffset, lambdaAccuracyOffset ) ) - wepPos ):Angle()

            bulletTbl.Callback = function( attacker, tr, dmginfo )
                dmginfo:SetDamageType( dmginfo:GetDamageType() + weapon:GetWeaponAttribute( "DamageType", 0 ) )

                local dmgCustom = weapon:GetWeaponAttribute( "DamageCustom", 0 )
                if isCrit then dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL ) end
                dmginfo:SetDamageCustom( dmgCustom )

                local bulletCallback = weapon:GetWeaponAttribute( "BulletCallback" )
                if bulletCallback then bulletCallback( lambda, weapon, tr, dmginfo ) end

                local tracerEffect = weapon:GetWeaponAttribute( "TracerEffect" )
                if tracerEffect then
                    local tracerName = tracerEffect .. ( lambda.l_TF_TeamColor == 1 and "_blue" or "_red" )
                    if isCrit then tracerName = tracerName .. "_crit" end
                    ParticleTracerEx( tracerName, tr.StartPos, tr.HitPos, true, weapon:EntIndex(), -1 )
                end
            end

            local firstShotAccurate = weapon:GetWeaponAttribute( "FirstShotAccurate", false )
            local bulletPreShot = weapon:GetWeaponAttribute( "ProjectileCount", 1 )
            local spreadRecovery = weapon:GetWeaponAttribute( "SpreadRecovery", ( bulletPreShot > 1 and 0.25 or 1.25 ) )
            local fixedSpread = weapon:GetWeaponAttribute( "FixedSpread", false )
            local preBulletCallback = weapon:GetWeaponAttribute( "PreFireBulletCallback" )

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
        local nearPoint = target:NearestPoint( eyePos )
        if eyePos:DistToSqr( nearPoint ) > ( attackRange ^ 2 ) then return end

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

                meleetbl.start = eyePos
                meleetbl.endpos = ( eyePos + ( ( LambdaIsValid( target ) and target:WorldSpaceCenter() or ( lambda:WorldSpaceCenter() + lambda:GetForward() * hitRange ) ) - eyePos ):GetNormalized() * hitRange )
                meleetbl.filter[ 1 ] = lambda
                meleetbl.filter[ 2 ] = weapon

                local meleeTr = TraceLine( meleetbl )
                if meleeTr.Fraction >= 1.0 then meleeTr = TraceHull( meleetbl ) end

                local dmginfo = DamageInfo()
                dmginfo:SetDamage( damage )
                dmginfo:SetAttacker( lambda )
                dmginfo:SetInflictor( weapon )
                dmginfo:SetDamagePosition( meleeTr.HitPos )
                dmginfo:SetDamageType( weapon:GetWeaponAttribute( "DamageType", DMG_CLUB ) )

                local dmgCustom = ( TF_DMG_CUSTOM_MELEE + weapon:GetWeaponAttribute( "DamageCustom", 0 ) )
                if isCrit then 
                    dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL ) 
                elseif lambda:GetNextMeleeCrit() == TF_CRIT_MINI then 
                    dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_MINICRITICAL )
                end
                dmginfo:SetDamageCustom( dmgCustom )

                local hitAng = ( ( meleeTr.HitPos - lambda:GetForward() * ( hitRange and 1 or 0 ) ) - eyePos ):Angle()
                dmginfo:SetDamageForce( hitAng:Forward() * ( damage * 300 ) * LAMBDA_TF2:GetPushScale() * ( 1 / damage * 80 ) )

                local hitEnt = meleeTr.Entity
                local missed = ( !IsValid( hitEnt ) )

                local preHitCallback = weapon:GetWeaponAttribute( missed and "OnMiss" or "PreHitCallback" )
                if ( !preHitCallback or preHitCallback( lambda, weapon, hitEnt, dmginfo ) != true ) and !missed then
                    hitEnt:DispatchTraceAttack( dmginfo, meleeTr, hitAng:Forward() )
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

///

function LAMBDA_TF2:MedigunFire( lambda, weapon, target )
    if target == lambda:GetEnemy() then return true end

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

    LAMBDA_TF2:CreateMuzzleFlash( weapon, "muzzle_minigun" )

    local curROF = 0
    local rateOfFire = ( rateoffire / 4 )
    for i = 1, weapon:GetWeaponAttribute( "ProjectileCount" ) do
        lambda:SimpleWeaponTimer( curROF, function() 
            lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2 )
            lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2, true )

            LAMBDA_TF2:CreateShellEject( weapon, "RifleShellEject" ) 
        end )

        curROF = ( curROF + rateOfFire )
    end
end

///

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
                if ent == self or ent == weapon or ent == attacker or self.l_EntitiesBurnt[ ent ] or !IsValid( ent ) then continue end
                if attacker.IsLambdaPlayer and LAMBDA_TF2:IsValidCharacter( ent, false ) and !attacker:CanTarget( ent ) then continue end

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
                dmginfo:SetInflictor( self )
                dmginfo:SetDamage( damage )
                dmginfo:SetDamageType( self.l_DmgType )
                dmginfo:SetDamageCustom( self.l_DmgCustom )
                dmginfo:SetDamagePosition( ent:WorldSpaceCenter() + VectorRand( -5, 5 ) )
                dmginfo:SetReportedPosition( attacker:GetPos() )

                local onCollide = ( weapon.l_IsTFWeapon and weapon:GetWeaponAttribute( "OnFlameCollide" ) )
                if onCollide and onCollide( self, ent, dmginfo, attacker ) == true then continue end

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

    local pilotSndName = weapon:GetWeaponAttribute( "PilotSound", "weapons/flame_thrower_pilot.wav" )
    if pilotSndName then weapon:EmitSound( pilotSndName, 70, 100, 0.25, CHAN_STATIC ) end
    weapon.l_FirePilotSound = pilotSndName
    
    weapon.l_FireParticleName = weapon:GetWeaponAttribute( "FireParticleName", "flamethrower" )
    weapon.l_CurrentFireParticleName = false

    weapon:SetSkin( lambda.l_TF_TeamColor )
    weapon:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
end

function LAMBDA_TF2:FlamethrowerHolster( lambda, weapon )
    local curPartName = weapon.l_CurrentFireParticleName
    if curPartName then
        LAMBDA_TF2:StopParticlesNamed( weapon, curPartName )
        weapon.l_CurrentFireParticleName = false
    end

    if weapon.l_FirePilotSound then weapon:StopSound( weapon.l_FirePilotSound ) end
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
    local firePartName = weapon.l_FireParticleName
    local curPartName = weapon.l_CurrentFireParticleName
    
    if isDead then
        weapon.l_FireAttackTime = false
        weapon.l_FireState = 0
        weapon.l_NextFireStateUpdateT = CurTime()

        if curPartName then
            LAMBDA_TF2:StopParticlesNamed( weapon, curPartName )
            weapon.l_CurrentFireParticleName = false
        end

        if weapon.l_FirePilotSound then weapon:StopSound( weapon.l_FirePilotSound ) end
        if weapon.l_FireStartSound then weapon.l_FireStartSound:Stop() end 
        if weapon.l_FireLoopSound then weapon.l_FireLoopSound:Stop() end 
        if weapon.l_FireCritSound then weapon.l_FireCritSound:Stop() end 
        if weapon.l_FireEndSound then weapon.l_FireEndSound:Stop() end 
    else
        if weapon.l_FireAttackTime then 
            if CurTime() > weapon.l_FireAttackTime then
                if weapon.l_FirePilotSound then weapon:StopSound( weapon.l_FirePilotSound ) end
                if weapon.l_FireStartSound then weapon.l_FireStartSound:Stop() end 
                if weapon.l_FireLoopSound then weapon.l_FireLoopSound:Stop() end
                if weapon.l_FireCritSound then weapon.l_FireCritSound:Stop() end
                if weapon.l_FireEndSound and !weapon.l_FireEndSound:IsPlaying() then weapon.l_FireEndSound:Play() end 
                
                weapon.l_FireAttackTime = false
                weapon.l_FireState = 0
                weapon.l_NextFireStateUpdateT = CurTime()

                if curPartName then
                    LAMBDA_TF2:StopParticlesNamed( weapon, curPartName )
                    weapon.l_CurrentFireParticleName = false
                end
            else
                local isCrit = weapon:CalcIsAttackCriticalHelper()
                if isCrit then firePartName = firePartName .. "_crit" end

                if StartWith( firePartName, "flamethrower" ) then 
                    if isCrit then
                        firePartName = firePartName .. "_red"
                    elseif lambda.l_TF_TeamColor == 1 then
                        firePartName = firePartName .. "_blue"
                    end
                end

                if !curPartName or firePartName != curPartName then
                    if curPartName then LAMBDA_TF2:StopParticlesNamed( weapon, curPartName ) end
                    weapon.l_CurrentFireParticleName = firePartName
                    ParticleEffectAttach( firePartName, PATTACH_POINT_FOLLOW, weapon, 1 )
                end

                if CurTime() > weapon.l_NextFireStateUpdateT then
                    if weapon.l_FireState == 0 then
                        if weapon.l_FireStartSound and !weapon.l_FireStartSound:IsPlaying() then weapon.l_FireStartSound:Play() end 
                        if weapon.l_FireEndSound then weapon.l_FireEndSound:Stop() end 
                        
                        weapon.l_FireState = 1
                        weapon.l_NextFireStateUpdateT = ( CurTime() + SoundDuration( weapon:GetWeaponAttribute( "StartFireSound" ) ) )
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

                    local dmgCustom = weapon:GetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_BURNING )
                    if isCrit then dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL ) end

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
                    flameEnt:SetCollisionBounds( -flameSize, flameSize )

                    flameEnt.l_InitialPos = srcPos
                    flameEnt.l_PreviousPos = flameEnt.l_InitialPos
                    flameEnt.l_Attacker = lambda
                    flameEnt.l_DmgType = weapon:GetWeaponAttribute( "DamageType" )
                    flameEnt.l_DmgCustom = dmgCustom
                    flameEnt.l_DmgAmount = totalDamage
                    flameEnt.l_AttackerVelocity = lambda.loco:GetVelocity()
                    flameEnt.l_RemoveTime = ( CurTime() + ( 0.5 * Rand( 0.9, 1.1 ) ) )
                    flameEnt.l_EntitiesBurnt = {}
                    flameEnt.l_AfterburnDamage = weapon:GetWeaponAttribute( "AfterburnDamage", 3 )
                    flameEnt.l_AfterburnDuration = weapon:GetWeaponAttribute( "AfterburnDuration", 10 )

                    local speed = 2300
                    local velocity = ( fireAng:Forward() * speed )
                    flameEnt.l_BaseVelocity = ( velocity + VectorRand( -speed * 0.05, speed * 0.05 ) )
                    flameEnt:SetAbsVelocity( flameEnt.l_BaseVelocity )

                    flameEnt.Draw = function() end
                    flameEnt.Think = OnFlameThink

                    flameEnt.IsLambdaWeapon = true
                    flameEnt.l_IsTFWeapon = true
                    flameEnt.l_killiconname = weapon.l_killiconname
                end
            end
        end
    end
end

///

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
        dmginfo:SetDamageType( DMG_BLAST )

        dmginfo:SetDamageCustom( rocket.l_ExplodeDamageCustom )
        LAMBDA_TF2:SetCritType( dmginfo, rocket.l_ExplodeCrit )

        LAMBDA_TF2:RadiusDamageInfo( dmginfo, hitPos, rocket.l_ExplodeRadius, ent )
    end

    local explodePart = rocket.l_ExplodeParticle
    if istable( explodePart ) then explodePart = explodePart[ IsValid( owner ) and owner.l_TF_TeamColor or 0 ] end
    ParticleEffect( explodePart, hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )

    if ent:IsWorld() then util_Decal( "Scorch", hitPos + hitNormal, hitPos - hitNormal ) end

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

    rocket.l_IsTFWeapon = true
    rocket.l_ExplodeDamage = ( attributes.Damage or 55 )
    rocket.l_ExplodeRadius = ( attributes.Radius or 146 )
    rocket.l_ExplodeDamageCustom = ( attributes.DamageCustom or ( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_HALF_FALLOFF ) )
    rocket.l_ExplodeSound = ( attributes.Sound or {
        ")lambdaplayers/tf2/explode1.mp3",
        ")lambdaplayers/tf2/explode2.mp3",
        ")lambdaplayers/tf2/explode3.mp3"
    } )
    rocket.l_ExplodeParticle = ( attributes.ExplodeParticle or "ExplosionCore_Wall" )
    rocket.l_LambdaWeapon = wepent
    rocket.l_OnDealDamage = attributes.OnDealDamage
    rocket.l_FlySpeed = flySpeed

    rocket.IsLambdaWeapon = true
    rocket.l_killiconname = ( attributes.KillIcon or wepent.l_killiconname )

    local critType = owner:GetCritBoostType()
    if critical then critType = TF_CRIT_FULL end
    rocket.l_ExplodeCrit = critType

    if !attributes.HasCustomParticles then
        ParticleEffectAttach( "rockettrail", PATTACH_POINT_FOLLOW, rocket, 1 )
        
        if critType == TF_CRIT_FULL then
            ParticleEffectAttach( "critical_rocket_" .. ( owner.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_POINT_FOLLOW, rocket, 1 )
        end
    end

    rocket.Touch = OnRocketTouch
    return rocket
end

///

local function OnPipeTouch( self, other )
    local owner = self:GetOwner()
    if !other or !other:IsSolid() or other:GetSolidFlags() == FSOLID_VOLUME_CONTENTS or other == owner then return end

    local velDir = self:GetVelocity():GetNormalized()
    local vecOrigin = self:GetPos()
    local vecSpot = ( vecOrigin - velDir * 32 )

    pipeTouchTrTbl.start = vecSpot
    pipeTouchTrTbl.entpos = ( vecSpot + velDir * 64 )
    pipeTouchTrTbl.filter = self

    local tr = TraceLine( pipeTouchTrTbl )
    if tr.HitSky then self:Remove() return end

    if !self.l_HasTouched then
        local onTouch = self.l_OnTouch
        if onTouch and onTouch( self, other ) == true then return end

        self.l_HasTouched = true

        if self.l_ExplodeOnImpact and LambdaIsValid( other ) and LAMBDA_TF2:TakesDamage( other ) then
            ParticleEffect( "ExplosionCore_MidAir", vecOrigin, ( ( vecOrigin + tr.HitNormal ) - vecOrigin ):Angle() )

            if IsValid( owner ) then     
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( self.l_ExplodeDamage )
                dmginfo:SetAttacker( owner )
                dmginfo:SetInflictor( self )
                dmginfo:SetDamageType( DMG_BLAST )

                dmginfo:SetDamageCustom( TF_DMG_CUSTOM_HALF_FALLOFF )
                LAMBDA_TF2:SetCritType( dmginfo, self.l_ExplodeCrit )

                LAMBDA_TF2:RadiusDamageInfo( dmginfo, vecOrigin, self.l_ExplodeRadius, other )
            end

            local snds = self.l_ExplodeSound
            if istable( snds ) then snds = snds[ random( #snds ) ] end
            self:EmitSound( snds, 85, nil, nil, CHAN_WEAPON )
            
            self:Remove()
            return 
        end

        self.l_ExplodeDamage = ( self.l_ExplodeDamage * 0.6 )
    end
end

local function OnPipeCollide( self, colData, collider )
    self.l_OldVelocity = colData.OurOldVelocity

    local onPhysCollide = self.l_OnPhysicsCollide
    if onPhysCollide then onPhysCollide( self, colData, collider ) end

    if colData.Speed >= 100 then
        self:EmitSound( self.l_BounceSound, nil, random( 96, 100 ), 0.5, CHAN_STATIC )
    end
end

function LAMBDA_TF2:CreatePipeGrenadeProjectile( pos, ang, owner, wepent, critical, attributes )
    attributes = attributes or {}
    
    local pipe = ents_Create( "base_anim" )
    pipe:SetPos( pos )
    pipe:SetAngles( ang )
    pipe:SetModel( attributes.Model or "models/weapons/w_models/w_grenade_grenadelauncher.mdl" )
    pipe:SetOwner( owner )
    pipe:Spawn()

    pipe:PhysicsInit( SOLID_VPHYSICS )
    pipe:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
    pipe:AddSolidFlags( FSOLID_NOT_STANDABLE + FSOLID_TRIGGER )
    
    pipe:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
    pipe:SetCollisionBounds( -pipeBounds, pipeBounds )
    LAMBDA_TF2:TakeNoDamage( pipe )
    
    pipe:SetGravity( 0.4 )
    pipe:SetFriction( 0.2 )
    pipe:SetElasticity( 0.45 )
    pipe:DrawShadow( false )
    pipe:SetSkin( owner.l_TF_TeamColor )

    pipe.l_OnDealDamage = attributes.OnDealDamage
    pipe.l_OnPhysicsCollide = attributes.OnPhysicsCollide
    pipe.l_OnTouch = attributes.OnTouch
    
    local phys = pipe:GetPhysicsObject()
    local flySpeed = ( attributes.Speed or 1200 )
    if IsValid( phys ) then
        phys:Wake()
        
        local vel = ( ang:Forward() * flySpeed + ang:Up() * ( 200 + Rand( -10, 10 ) ) + ang:Right() * Rand( -10, 10 ) )
        phys:SetVelocity( vel )

        if !attributes.NoSpin then
            phys:SetAngleVelocity( Vector( 600, random( -1200, 1200 ), 0 ) )
        end
    end

    pipe.l_IsTFWeapon = true
    pipe.l_ExplodeDamage = ( attributes.Damage or 60 )
    pipe.l_ExplodeRadius = ( attributes.Radius or 146 )
    pipe.l_ExplodeSound = ( attributes.Sound or {
        ")lambdaplayers/tf2/explode1.mp3",
        ")lambdaplayers/tf2/explode2.mp3",
        ")lambdaplayers/tf2/explode3.mp3"
    } )
    pipe.l_LambdaWeapon = wepent
    pipe.l_HasTouched = false
    pipe.l_FlySpeed = flySpeed
    pipe.l_BounceSound = ( attributes.BounceSound or "weapons/grenade_impact.wav" )
    
    pipe.l_ExplodeOnImpact = attributes.ExplodeOnImpact
    if pipe.l_ExplodeOnImpact == nil then pipe.l_ExplodeOnImpact = true end

    pipe.IsLambdaWeapon = true
    pipe.l_killiconname = ( attributes.KillIcon or wepent.l_killiconname )

    local critType = owner:GetCritBoostType()
    if critical then critType = TF_CRIT_FULL end
    pipe.l_ExplodeCrit = critType

    ParticleEffectAttach( "pipebombtrail_" .. ( owner.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, pipe, 0 )
    if critType == TF_CRIT_FULL then
        ParticleEffectAttach( "critical_pipe_" .. ( owner.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, pipe, 0 )
    end

    pipe.Touch = OnPipeTouch
    pipe.PhysicsCollide = OnPipeCollide

    SimpleTimer( ( attributes.DetonateTime or 2.0 ), function()
        if !IsValid( pipe ) then return end
        local pipePos = pipe:WorldSpaceCenter()

        groundTrTbl.start = pipePos
        groundTrTbl.endpos = ( pipePos - vector_up * 32 )
        groundTrTbl.filter = pipe

        local groundTr = TraceLine( groundTrTbl )
        if groundTr.HitWorld then
            local hitPos, hitNormal = groundTr.HitPos, groundTr.HitNormal
            ParticleEffect( "ExplosionCore_Wall", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )
            util_Decal( "Scorch", hitPos + hitNormal, hitPos - hitNormal )
        else
            ParticleEffect( "ExplosionCore_MidAir", pipePos, Angle( 0, random( -360, 360 ), 0 ) )
        end

        if IsValid( owner ) then 
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( pipe.l_ExplodeDamage )
            dmginfo:SetDamagePosition( pipePos )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( pipe )
            dmginfo:SetDamageType( DMG_BLAST )

            local dmgCustom = ( TF_DMG_CUSTOM_HALF_FALLOFF )
            if pipe.l_ExplodeCrit == TF_CRIT_FULL then
                dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL )
            elseif pipe.l_ExplodeCrit == TF_CRIT_MINI then
                dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_MINICRITICAL )
            end
            dmginfo:SetDamageCustom( dmgCustom )

            LAMBDA_TF2:RadiusDamageInfo( dmginfo, pipePos, ( attributes.Radius or 146 ) )
        end

        local snds = pipe.l_ExplodeSound
        if istable( snds ) then snds = snds[ random( #snds ) ] end
        pipe:EmitSound( snds, 85, nil, nil, CHAN_WEAPON )
        pipe:Remove()
    end )

    return pipe
end