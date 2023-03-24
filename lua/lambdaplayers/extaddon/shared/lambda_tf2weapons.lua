local IsValid = IsValid
local ismatrix = ismatrix
local net = net
local SimpleTimer = timer.Simple
local random = math.random
local emptyFunc = function() end
local CreateParticleSystem = CreateParticleSystem
local CreateClientside = ents.CreateClientside

local headGibMdl = "models/lambdaplayers/gibs/hgibs/humanskull.mdl"
local headGibAng = Angle( 90, 0, -90 )

LAMBDA_TF2 = LAMBDA_TF2 or {}

function LAMBDA_TF2:GetBoneTransformation( ent, index )
    local matrix = ent:GetBoneMatrix( index )
    if ismatrix( matrix ) then
        return matrix:GetTranslation(), matrix:GetAngles()
    end
    return ent:GetBonePosition( index )
end

local function ShrinkChildBones( target, parentId, boneTbl )
    for _, childID in ipairs( target:GetChildBones( parentId ) ) do
        target:ManipulateBoneScale( childID, vector_origin )
        boneTbl[ #boneTbl + 1 ] = childID
        ShrinkChildBones( target, childID, boneTbl )
    end
end

function LAMBDA_TF2:DecapitateHead( target, effects, force )
    if !IsValid( target ) then return end

    if ( CLIENT ) then
        local ragdoll = target.ragdoll
        if IsValid( ragdoll ) then target = ragdoll end
    end

    local headBone = target:LookupBone( "ValveBiped.Bip01_Head1" )
    if !headBone then return end

    local decapitatedBones = { headBone }
    target:ManipulateBoneScale( headBone, vector_origin )
    ShrinkChildBones( target, headBone, decapitatedBones )

    if effects then
        target:EmitSound( "lambdaplayers/weapons/tf2/head_decapitation.mp3", 70, 100, 0.75, CHAN_STATIC )

        local headPos, headAng = LAMBDA_TF2:GetBoneTransformation( target, headBone )
        if ( CLIENT ) then
            net.Start( "lambda_tf2_decapitate_sendgibdata" )
                net.WriteVector( headPos )
                net.WriteAngle( headAng )
                net.WriteVector( force )
            net.SendToServer()

            local damnyousourceengine = CreateClientside( "base_anim" )
            damnyousourceengine:SetPos( headPos )
            damnyousourceengine:SetAngles( headAng )
            damnyousourceengine:SetParent( target )
            damnyousourceengine:Spawn()
            damnyousourceengine.Draw = emptyFunc

            local bloodEffect = CreateParticleSystem( damnyousourceengine, "blood_advisor_puncture_withdraw", PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
            damnyousourceengine:LambdaHookTick( "FollowRagdollHead", function()
                if !bloodEffect or !bloodEffect:IsValid() or !IsValid( target ) then 
                    damnyousourceengine:Remove()
                    return true 
                end
    
                headPos, headAng = LAMBDA_TF2:GetBoneTransformation( target, headBone )
                if !headPos or !headAng then 
                    damnyousourceengine:Remove()
                    return true 
                end
    
                damnyousourceengine:SetPos( headPos )
                damnyousourceengine:SetAngles( headAng )
            end )
        else
            LAMBDA_TF2:CreateHeadGib( headPos, headAng, force )

            local bloodEffect = ents.Create( "info_particle_system" )
            bloodEffect:SetKeyValue( "effect_name", "blood_advisor_puncture_withdraw" )
            bloodEffect:SetPos( headPos )
            bloodEffect:SetAngles( headAng )
            bloodEffect:SetParent( target )
            bloodEffect:Spawn()
            bloodEffect:Activate()

            bloodEffect:Fire( "Start", "", 0 )
            bloodEffect:Fire( "Kill", "", 2.5 )

            bloodEffect:LambdaHookTick( "FollowRagdollHead", function()
                if !IsValid( target ) then return true end

                headPos, headAng = LAMBDA_TF2:GetBoneTransformation( target, headBone )
                if !headPos or !headAng then return true end

                bloodEffect:SetPos( headPos )
                bloodEffect:SetAngles( headAng )
            end )
        end
    end
end

---

local function OnEntityCreated( ent )
    SimpleTimer( 0, function()
        if !IsValid( ent ) then return end

        if ( CLIENT ) then
            ent.l_TF_LastCritEffectTime = CurTime()
        end

        if ( SERVER ) then
            ent.l_TF_HasOverheal = false
            ent.l_TF_HealFraction = 0

            ent.l_TF_LoopingSounds = {}

            ent.l_TF_BleedInfo = {}
            
            ent.l_TF_MarkedForDeath = 0

            ent.l_TF_IsBurning = false
            ent.l_TF_FlameBurnTime = CurTime()
            ent.l_TF_FlameRemoveTime = CurTime()
            ent.l_TF_BurnAttacker = NULL
            ent.l_TF_BurnWeapon = NULL
            ent.l_TF_BurnInflictor = NULL

            ent.l_TF_CoveredInUrine = false
            ent.l_TF_CoveredInMilk = false

            ent:SetNW2Bool( "lambda_tf2_canbedecapitated", false )
        end
    end )
end

hook.Add( "OnEntityCreated", "LambdaTF2_OnEntityCreated", OnEntityCreated )

if ( CLIENT ) then 
    
    local LocalPlayer = LocalPlayer
    local killiconClr = Color( 255, 80, 0, 255 )
    local killIconBleed = Color( 255, 0, 0 )

    killicon.Add( "lambdaplayers_weaponkillicons_tf2_backstab", "lambdaplayers/killicons/icon_tf2_backstab", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_headshot", "lambdaplayers/killicons/icon_tf2_headshot", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_caber_explosion", "lambdaplayers/killicons/icon_tf2_caber", killiconClr )
    
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_chargintarge", "lambdaplayers/killicons/icon_tf2_chargintarge", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_splendidscreen", "lambdaplayers/killicons/icon_tf2_splendidscreen", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_tideturner", "lambdaplayers/killicons/icon_tf2_tideturner", killiconClr )
    
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_fire", "lambdaplayers/killicons/icon_tf2_fire", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_bleedout", "lambdaplayers/killicons/icon_tf2_bleedout", killIconBleed )

    net.Receive( "lambda_tf2_stopnamedparticle", function()
        local ent = net.ReadEntity()
        if IsValid( ent ) then ent:StopParticlesNamed( net.ReadString() ) end
    end)

    net.Receive( "lambda_tf2_removecsragdoll", function()
        local lambda = net.ReadEntity()
        if !IsValid( lambda ) then return end
        
        local ragdoll = lambda.ragdoll
        if IsValid( ragdoll ) then ragdoll:Remove() end
    end )

    net.Receive( "lambda_tf2_criteffects", function()
        local critType = net.ReadUInt( 2 )
        local textPos = net.ReadVector()
        local receiver = net.ReadEntity()
        local lethal = net.ReadBool()

        if ( CurTime() - receiver.l_TF_LastCritEffectTime ) <= ( RealFrameTime() * 10 ) then return end
        receiver.l_TF_LastCritEffectTime = CurTime()

        local critPart = CreateParticleSystem( Entity( 0 ), ( critType == 1 and "mini" or "" ) .. "crit_text", PATTACH_WORLDORIGIN, 0, textPos )
        
        local ply = LocalPlayer()
        critPart:SetShouldDraw( ply != receiver )

        receiver:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_hit" .. ( critType == 1 and "_mini" or "" ) .. random( 1, 5 ) .. ".mp3", 75, random( 90, 110 ), 1, CHAN_STATIC )
        if lethal and ply == receiver and critType == 2 then
            receiver:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_received" .. random( 1, 3 ) .. ".mp3", 70, random( 95, 110 ), 1, CHAN_STATIC )
        end
    end )

    net.Receive( "lambda_tf2_decapitate_csragdoll", function()
        LAMBDA_TF2:DecapitateHead( net.ReadEntity(), net.ReadBool(), net.ReadVector() )
    end )

    net.Receive( "lambda_tf2_urineeffect", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local urineEffect = ent.l_TF_UrineEffect
        if urineEffect and urineEffect:IsValid() then
            urineEffect:StopEmission()
            ent.l_TF_UrineEffect = nil
            return
        end

        urineEffect = CreateParticleSystem( ent, "peejar_drips", PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        if !urineEffect or !urineEffect:IsValid() then return end

        urineEffect:AddControlPoint( 1, ent, PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        ent.l_TF_UrineEffect = urineEffect
    end )

    net.Receive( "lambda_tf2_milkeffect", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local milkEffect = ent.l_TF_MilkEffect
        if milkEffect and milkEffect:IsValid() then
            milkEffect:StopEmission()
            ent.l_TF_MilkEffect = nil
            return
        end

        milkEffect = CreateParticleSystem( ent, "peejar_drips_milk", PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        if !milkEffect or !milkEffect:IsValid() then return end

        milkEffect:AddControlPoint( 1, ent, PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        ent.l_TF_MilkEffect = milkEffect
    end )

    local function OnCreateClientsideRagdoll( owner, ragdoll )
        if owner:GetNW2Bool( "lambda_tf2_canbedecapitated", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ( ragdoll:GetVelocity() * 5 ) )
        end
    end

	hook.Add( "CreateClientsideRagdoll", "LambdaTF2_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )
end

local allowRandomCrits = CreateLambdaConvar( "lambdaplayers_tf2_allowrandomcrits", 1, true, false, false, "If the weapons from TF2 should have a chance to earn a random crit", 0, 1, { type = "Bool", name = "Allow Random Crits", category = "TF2 Stuff" } )
local alwaysCrit = CreateLambdaConvar( "lambdaplayers_tf2_alwayscrit", 0, true, false, false, "If the weapons from TF2 should have always fire a crit shot", 0, 1, { type = "Bool", name = "Always Crit", category = "TF2 Stuff" } )
local shieldSpawnChance = CreateLambdaConvar( "lambdaplayers_tf2_shieldspawnchance", 10, true, false, false, "The chance that the next spawned Lambda Player will have a random charge shield equipped with them. Note that the Demoman's melee weapons have their own chance instead of this", 0, 100, { type = "Slider", decimals = 0, name = "Shield Spawn Chance", category = "TF2 Stuff" } )
local deathAnimChance = CreateLambdaConvar( "lambdaplayers_tf2_deathanimchance", 25, true, false, false, "The chance that Lambda Player will play a unique death animation when after dying from a specific TF2 weapon", 0, 100, { type = "Slider", decimals = 0, name = "Death Animation Chance", category = "TF2 Stuff" } )
local alwaysUseSchadenfreude = CreateLambdaConvar( "lambdaplayers_tf2_alwaysuseschadenfreude", 0, true, false, false, "If Lambda Players should always use play the Schadenfreude taunt when laughing instead of when holding a TF2 weapon", 0, 1, { type = "Bool", name = "Always Use Schadenfreude", category = "TF2 Stuff" } )
local schadenfreudeUseClassLaughter = CreateLambdaConvar( "lambdaplayers_tf2_schadenfreudeuseclasslaughter", 0, true, false, false, "If Lambda Players using Schadenfreude should also play the laugh that animation belongs to alongside their own laughter", 0, 1, { type = "Bool", name = "Schadenfreude Uses Class-Specific Laughter", category = "TF2 Stuff" } )
local randomSituationalWeaponChance = CreateLambdaConvar( "lambdaplayers_tf2_randomsituationalchance", 10, true, false, false, "The chance that Lambda Player will have a random situational weapon in their inventory when they spawn first time, like Jarate, Sandvich, The Escape Plan, and etc.", 0, 100, { type = "Slider", decimals = 0, name = "Random Situational Weapon Chance", category = "TF2 Stuff" } )

if ( SERVER ) then

    DMG_HALF_FALLOFF				        = DMG_RADIATION
    DMG_CRITICAL                            = DMG_ACID
    DMG_RADIUS_MAX					        = DMG_ENERGYBEAM
    DMG_IGNITE					            = DMG_SLOWBURN
    DMG_MINICRITICAL                        = DMG_PHYSGUN
    DMG_USEDISTANCEMOD                      = DMG_AIRBOAT
    DMG_NOCLOSEDISTANCEMOD                  = DMG_POISON
    DMG_MELEE                               = DMG_BLAST_SURFACE
    DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE = DMG_DISSOLVE
    
    TF_DMG_CUSTOM_HEADSHOT                  = 1
    TF_DMG_CUSTOM_BACKSTAB                  = 2
    TF_DMG_CUSTOM_BURNING                   = 3
    TF_DMG_CUSTOM_DECAPITATION              = 20
    TF_DMG_CUSTOM_CHARGE_IMPACT             = 23
    TF_DMG_CUSTOM_BLEEDING                  = 34
    TF_DMG_CUSTOM_STICKBOMB_EXPLOSION       = 42
    
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

    MELEE_NOCRIT                            = 0
    MELEE_MINICRIT                          = 1
    MELEE_CRIT                              = 2

    local CurTime = CurTime
    local coroutine_yield = coroutine.yield
    local istable = istable
    local vector_allone = Vector( 1, 1, 1 )
    local sound_Play = sound.Play
    local EffectData = EffectData
    local util_Effect = util.Effect
    local IsPredicted = IsFirstTimePredicted
    local ents_Create = ents.Create
    local Rand = math.Rand
    local min = math.min
    local deg = math.deg
    local acos = math.acos
    local Clamp = math.Clamp
    local bulletTbl = {}
    local spreadVector = Vector()
    local max = math.max
    local Round = math.Round
    local floor = math.floor
    local Remap = math.Remap
    local ents_GetAll = ents.GetAll
    local ipairs = ipairs
    local RandomPairs = RandomPairs
    local isvector = isvector
    local FrameTime = FrameTime
    local DamageInfo = DamageInfo
    local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
    local SpriteTrail = util.SpriteTrail
    local ScreenShake = util.ScreenShake
    local Decal = util.Decal
    local table_Empty = table.Empty
    local table_remove = table.remove
    local table_Random = table.Random
    local table_Merge = table.Merge
    local FindInSphere = ents.FindInSphere
    local TraceLine = util.TraceLine
    local TraceHull = util.TraceHull
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

    local pushScale = GetConVar( "phys_pushscale" )

    util.AddNetworkString( "lambda_tf2_stopnamedparticle" )
    util.AddNetworkString( "lambda_tf2_removecsragdoll" )
    util.AddNetworkString( "lambda_tf2_criteffects" )
    util.AddNetworkString( "lambda_tf2_decapitate_csragdoll" )
    util.AddNetworkString( "lambda_tf2_decapitate_sendgibdata" )
    util.AddNetworkString( "lambda_tf2_urineeffect" )
    util.AddNetworkString( "lambda_tf2_milkeffect" )
    
    net.Receive( "lambda_tf2_decapitate_sendgibdata", function()
        LAMBDA_TF2:CreateHeadGib( net.ReadVector(), net.ReadAngle(), net.ReadVector() )
    end )

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

    function LAMBDA_TF2:WeaponAttack( lambda, weapon, target )
        local isMelee = weapon:GetWeaponAttribute( "IsMelee", false )
        if !isMelee then
            local clipDrain = weapon:GetWeaponAttribute( "ClipDrain", 1 )
            if clipDrain then
                local curClip = lambda.l_Clip
                if curClip <= 0 then lambda:ReloadWeapon() return end
                lambda.l_Clip = ( curClip - clipDrain )
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

            local isCrit = weapon:CalcIsAttackCriticalHelper()
            local fireSnd = weapon:GetWeaponAttribute( "Sound" )
            local critSnd = weapon:GetWeaponAttribute( "CritSound" )
            if critSnd and isCrit then fireSnd = critSnd end

            if fireSnd then
                if istable( fireSnd ) then fireSnd = fireSnd[ random( #fireSnd ) ] end
                weapon:EmitSound( fireSnd, 75, 100, 1, CHAN_WEAPON )
                if isCrit and fireSnd != critSnd then weapon:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_shoot.mp3", 75, random( 90, 110 ), 1, CHAN_STATIC ) end
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

                local lambdaAccuracyOffset = LAMBDA_TF2:RemapClamped( lambda:GetRangeTo( target ), 128, 1024, 5, 30 )
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
            
            local fireSnd = weapon:GetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/melee/cbar_miss1.mp3" )
            if istable( fireSnd ) then fireSnd = fireSnd[ random( #fireSnd ) ] end
            weapon:EmitSound( fireSnd, 64, 100, 0.6, CHAN_WEAPON )
        
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

                local isCriticalHit = weapon:CalcIsAttackCriticalHelper()
                if isCriticalHit then lambda:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_shoot.mp3", 70, random( 90, 110 ), 0.5 ) end

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
                    if isCriticalHit then 
                        dmgTypes = ( dmgTypes + DMG_CRITICAL ) 
                    elseif lambda.l_TF_NextMeleeCrit == MELEE_MINICRIT then 
                        dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
                    end
                    dmginfo:SetDamageType( dmgTypes )

                    local hitAng = ( ( hitPos - lambda:GetForward() * ( hitRange and 1 or 0 ) ) - eyePos ):Angle()
                    dmginfo:SetDamageForce( hitAng:Forward() * ( damage * 300 ) * LAMBDA_TF2:GetPushScale() * ( 1 / damage * 80 ) )
                    
                    local preHitCallback = weapon:GetWeaponAttribute( missed and "OnMiss" or "PreHitCallback" )
                    if preHitCallback then preHitCallback( lambda, weapon, target, dmginfo ) end

                    if !missed then target:TakeDamageInfo( dmginfo ) end
                    lambda.l_TF_NextMeleeCrit = MELEE_NOCRIT
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

    function LAMBDA_TF2:ApplyPushFromDamage( target, dmginfo, dir )
        local size = ( target:OBBMaxs() - target:OBBMins() )
        local force = min( 1000, dmginfo:GetDamage() * ( ( 48 * 48 * 82 ) / ( size.x * size.y * size.z ) ) )
        local vecForce = ( dir * -force )

        local inflictor = dmginfo:GetInflictor()
        if IsValid( inflictor ) and inflictor.l_TF_HasKnockBack then 
            if vecForce.z < 0 then
                vecForce.z = 0
            end
            inflictor.l_TF_HasKnockBack = false
        end 

        if target:IsNextBot() then
            local heightDiff = ( ( target:GetPos() + vecForce ).z - target:GetPos().z )
            if target.IsLambdaPlayer and heightDiff >= 64 then target.loco:Jump() end
            target.loco:SetVelocity( target.loco:GetVelocity() + vecForce )
        else
            target:SetVelocity( vecForce )
        end
    end

    local function CalcIsAttackCriticalHelper( self )
        if alwaysCrit:GetBool() then return true end

        local owner = self.l_TF_Owner
        local remapCritMul = Remap( owner.l_TF_CritMult, 0, 255, 1, 4 )
        local randChance = random( 0, 9999 )

        if self:GetWeaponAttribute( "IsMelee" ) then
            if owner.l_TF_NextMeleeCrit == MELEE_CRIT then return true end
            if !self:GetWeaponAttribute( "RandomCrits", true ) or !allowRandomCrits:GetBool() then return false end
            return ( randChance < ( TF_DAMAGE_CRIT_CHANCE_MELEE * remapCritMul * 9999 ) )
        end

        local isRapidFire = self:GetWeaponAttribute( "IsRapidFire" )
        if isRapidFire and CurTime() < self.l_TF_CritTime then return true end
        if !self:GetWeaponAttribute( "RandomCrits", true ) or !allowRandomCrits:GetBool() then return false end

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
        
        weapon.l_TF_CritTime = CurTime()
        weapon.l_TF_LastFireTime = CurTime()
        weapon.l_TF_LastRapidFireCritCheckT = CurTime()

        weapon.SetWeaponAttribute = SetWeaponAttribute
        weapon.GetWeaponAttribute = GetWeaponAttribute
        weapon.CalcIsAttackCriticalHelper = CalcIsAttackCriticalHelper
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

            local adjustedDamage = Remap( distToEnt, 0, radius, baseDamage, baseDamage * fallOff )
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

    function LAMBDA_TF2:RemapClamped( value, inMin, inMax, outMin, outMax )
        if inMin == inMax then return ( value >= inMax and outMax or outMin ) end
        local clampedValue = ( ( value - inMin ) / ( inMax - inMin ) )
        clampedValue = Clamp( clampedValue, 0, 1 )
        return ( outMin + ( outMax - outMin ) * clampedValue )
    end

    function LAMBDA_TF2:CreateSpriteTrailEntity( color, additive, startWidth, endWidth, lifeTime, texture, pos, parent )
        local trailEnt = ents_Create( "base_anim" )
        if !IsValid( trailEnt ) then return end

        trailEnt:SetPos( pos )
        trailEnt:SetParent( parent )
        trailEnt:Spawn()
        trailEnt:SetNoDraw( true )
        trailEnt:DrawShadow( false )
        trailEnt:SetSolid( SOLID_NONE )
        trailEnt:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
        trailEnt:SetMoveType( MOVETYPE_NONE )
        LAMBDA_TF2:TakeNoDamage( trailEnt )

        SpriteTrail( trailEnt, 0, ( color or color_white ), ( additive or true ), startWidth, endWidth, lifeTime, ( 1 / ( startWidth + endWidth ) * 0.5 ), texture )
        return trailEnt
    end

    function LAMBDA_TF2:CreateCritBulletTracer( startPos, endPos, color, time, size )
        time = time or 0.25
        size = size or 0.66

        local critTracer = LAMBDA_TF2:CreateSpriteTrailEntity( color, nil, size, size, time, "trails/smoke", startPos )
        if !IsValid( critTracer ) then return end

        SafeRemoveEntityDelayed( critTracer, time * 2 )
        SimpleTimer( FrameTime(), function()
            if !IsValid( critTracer ) then return end
            critTracer:SetPos( endPos )
        end )
    end

    function LAMBDA_TF2:StopParticlesNamed( ent, name )
        net.Start( "lambda_tf2_stopnamedparticle" )
            net.WriteEntity( ent )
            net.WriteString( name )
        net.Broadcast()
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

    function LAMBDA_TF2:CreateHeadGib( pos, ang, force )
        local headGib = ents.Create( "prop_physics" )
        headGib:SetModel( headGibMdl )
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

            local applyForce = ( vector_up * 2000 )
            if force then applyForce = ( applyForce + force ) end
            phys:ApplyForceCenter( applyForce ) 
        end
    end

    function LAMBDA_TF2:GetMaxBuffedHealth( ent )
        return floor( ( ( ent:GetMaxHealth() * 1.5 ) / 5 ) * 5 )
    end

    function LAMBDA_TF2:GiveHealth( target, amount, maxHeal )
        local maxHealth = target:GetMaxHealth()
        local maxGive = ( maxHeal == nil and LAMBDA_TF2:GetMaxBuffedHealth( target ) or ( maxHeal == false and maxHealth or maxHeal ) )

        local curHealth = target:Health()
        if curHealth >= maxGive then return end
        target:SetHealth( floor( min( curHealth + amount, maxGive ) ) )

        target.l_TF_HasOverheal = ( target:Health() > maxHealth )
    end

    local shieldTbl = {
        { "models/lambdaplayers/weapons/tf2/w_targe.mdl", "lambdaplayers_weaponkillicons_tf2_chargintarge" },
        { "models/lambdaplayers/weapons/tf2/w_persian_shield.mdl", "lambdaplayers_weaponkillicons_tf2_splendidscreen" },
        { "models/lambdaplayers/weapons/tf2/w_wheel_shield.mdl", "lambdaplayers_weaponkillicons_tf2_tideturner" },
    }

    function LAMBDA_TF2:GiveRemoveChargeShield( lambda, givenByWeapon )
        lambda.l_TF_Shield_IsEquipped = !lambda.l_TF_Shield_IsEquipped
        
        local shieldEnt
        if lambda.l_TF_Shield_IsEquipped then
            local shieldType = random( #shieldTbl )
            lambda.l_TF_Shield_Type = shieldType

            shieldEnt = ents_Create( "base_anim" )
            shieldEnt:SetModel( shieldTbl[ shieldType ][ 1 ] )
            shieldEnt:SetPos( lambda:GetPos() )
            shieldEnt:SetAngles( lambda:GetAngles() )
            shieldEnt:SetParent( lambda )
            shieldEnt:Spawn()
            shieldEnt:AddEffects( EF_BONEMERGE )
            LAMBDA_TF2:TakeNoDamage( shieldEnt )

            shieldEnt.IsLambdaWeapon = true
            shieldEnt.l_killiconname = shieldTbl[ shieldType ][ 2 ]
            shieldEnt.l_TF_GivenByWeapon = ( givenByWeapon and lambda:GetWeaponName() )
            
            lambda.l_TF_Shield_Entity = shieldEnt
        elseif IsValid( lambda.l_TF_Shield_Entity ) then
            lambda.l_TF_Shield_Entity:Remove()
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

    local function OnRocketTouch( rocket, ent )
        if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    
        local touchTr = rocket:GetTouchTrace()
        if touchTr.HitSky then rocket:Remove() return end

        local hitPos, hitNormal = rocket:WorldSpaceCenter(), touchTr.HitNormal
        ParticleEffect( "ExplosionCore_Wall", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )
        if ent:IsWorld() then Decal( "Scorch", hitPos + hitNormal, hitPos - hitNormal ) end
    
        local owner = rocket:GetOwner()
        if IsValid( owner ) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( rocket.l_TF_ExplodeDamage )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( rocket )
            
            local dmgTypes = ( DMG_BLAST + DMG_USEDISTANCEMOD + DMG_HALF_FALLOFF )
            if rocket.l_TF_ExplodeCrit == 2 then
                dmgTypes = ( dmgTypes + DMG_CRITICAL )
            elseif rocket.l_TF_ExplodeCrit == 1 then
                dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
            end
            dmginfo:SetDamageType(dmgTypes )

            LAMBDA_TF2:RadiusDamageInfo( dmginfo, hitPos, rocket.l_TF_ExplodeRadius, ent )
        end

        local snds = rocket.l_TF_ExplodeSound
        rocket:EmitSound( snds[ random( #snds ) ], 85, 100, 1.0, CHAN_WEAPON )
        rocket:Remove()
    end

    function LAMBDA_TF2:CreateRocketProjectile( pos, ang, owner, wepent, attributes )
        attributes = attributes or {}
        
        local rocket = ents_Create( "base_anim" )
        rocket:SetPos( pos )
        rocket:SetAngles( ang )
        rocket:SetModel( attributes.Model or "models/lambdaplayers/weapons/tf2/w_rocket_launcher_proj.mdl" )
        rocket:SetOwner( owner )
        rocket:Spawn()

        rocket:SetSolid( SOLID_BBOX )
        rocket:SetMoveType( MOVETYPE_FLY )
        rocket:SetVelocity( ang:Forward() * ( attributes.Speed or 1100 ) )
        rocket:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
        rocket:SetCollisionBounds( -vector_origin, vector_origin )
        LAMBDA_TF2:TakeNoDamage( rocket )

        ParticleEffectAttach( "rockettrail", PATTACH_POINT_FOLLOW, rocket, 1 )

        rocket.l_TF_IsTF2Weapon = true
        rocket.l_TF_ExplodeDamage = ( attributes.Damage or 55 )
        rocket.l_TF_ExplodeRadius = ( attributes.Radius or 146 )
        rocket.l_TF_ExplodeSound = ( attributes.Sound or {
            ")lambdaplayers/weapons/tf2/explode1.mp3",
            ")lambdaplayers/weapons/tf2/explode2.mp3",
            ")lambdaplayers/weapons/tf2/explode3.mp3"
        } )
        rocket.l_TF_LambdaWeapon = wepent
        rocket.l_TF_OnDealDamage = attributes.OnDealDamage

        rocket.IsLambdaWeapon = true
        rocket.l_killiconname = ( attributes.KillIcon or wepent.l_killiconname )

        rocket.l_TF_ExplodeCrit = ( wepent:CalcIsAttackCriticalHelper() and 2 or ( owner.l_TF_MiniCritBoosted and 1 or 0 ) )
        if rocket.l_TF_ExplodeCrit == 2 then
            rocket.l_TF_ExplodeCrit = true
            rocket:SetMaterial( "models/shiny" )

            local plyColor = owner:GetPlyColor():ToColor()
            rocket:SetColor( plyColor )
            ParticleEffectAttach( "critical_rocket_red", PATTACH_POINT_FOLLOW, rocket, 1 )
            ParticleEffectAttach( "critical_rocket_blue", PATTACH_POINT_FOLLOW, rocket, 1 )
        elseif rocket.l_TF_ExplodeCrit == 1 then
            rocket:SetMaterial( "lambdaplayers/models/weapons/tf2/criteffects/minicrit" )
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

        ent.l_TF_BleedInfo[ #ent.l_TF_BleedInfo + 1 ] = {
            Attacker = attacker,
            Weapon = weapon,
            BleedingTime = bleedingTime,
            ExpireTime = expireTime,
            BleedDmg = bleedDmg,
            PermamentBleeding = permaBleeding
        }
    end

    function LAMBDA_TF2:Burn( ent, attacker, weapon, burningTime )
        if !ent.l_TF_IsBurning then
            ent.l_TF_IsBurning = true
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

            ent:DeleteOnRemove( inflictor )
            ent.l_TF_BurnInflictor = inflictor
        end

        local flameLife = ( ( burningTime and burningTime > 0 ) and burningTime or 10 )
        local burnEnd = ( CurTime() + flameLife )
        if burnEnd > ent.l_TF_FlameRemoveTime then
            ent.l_TF_FlameRemoveTime = burnEnd
        end

        ent.l_TF_BurnAttacker = attacker
        ent.l_TF_BurnWeapon = weapon
        ent.l_TF_BurnInflictor.l_killiconname = ( weapon.l_killiconname or "lambdaplayers_weaponkillicons_tf2_fire" )
    end

    function LAMBDA_TF2:RemoveBurn( ent )
        ent:Extinguish()
        ent.l_TF_IsBurning = false
        ent.l_TF_BurnAttacker = NULL
        ent.l_TF_BurnWeapon = NULL
        SafeRemoveEntity( ent.l_TF_BurnInflictor )
    end

    function LAMBDA_TF2:TakeNoDamage( ent )
        ent:SetSaveValue( "m_takedamage", 0 )
    end

    function LAMBDA_TF2:CreateSound( targetEnt, soundName, filter )
        local snd = CreateSound( targetEnt, soundName, filter )
        if snd then targetEnt.l_TF_LoopingSounds[ #targetEnt.l_TF_LoopingSounds + 1 ] = snd end
        return snd
    end

    function LAMBDA_TF2:IsValidCharacter( ent, alive )
        if alive == nil then alive = true end
        return ( ( ent:IsPlayer() or ent.IsLambdaPlayer ) and ( !alive or ent:Alive() ) or ( ent:IsNPC() or ent:IsNextBot() ) and ( !alive or ent:Health() > 0 ) )
    end

    function LAMBDA_TF2:GetCritType( dmginfo )
        return ( dmginfo:IsDamageType( DMG_CRITICAL ) and 2 or ( dmginfo:IsDamageType( DMG_MINICRITICAL ) and 1 or 0 ) )
    end

    function LAMBDA_TF2:AddInventoryCooldown( lambda, name )
        local wepInv = lambda.l_TF_Inventory[ name or lambda:GetWeaponName() ]
        if !wepInv or !wepInv.IsReady then return end
        wepInv.IsReady = false
        wepInv.NextUseTime = ( CurTime() + wepInv.Cooldown ) 
    end

    ---

    local tf2LaughAnims = {
        [ "sniper_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_sniper.mp3",
        [ "pyro_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_pyro.mp3",
        [ "medic_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_medic.mp3",
        [ "demoman_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_demoman.mp3",
        [ "soldier_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_soldier.mp3",
        [ "engineer_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_engineer.mp3",
        [ "spy_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_spy.mp3",
        [ "scout_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_scout.mp3",
        [ "heavy_taunt_laugh" ] = "lambdaplayers/vo_tf2/schadenfreude_heavy.mp3"
    }

    local function Schadenfreude( self )
        local laughSnd, seqName = table_Random( tf2LaughAnims )
        local animIndex = self:LookupSequence( seqName )
        if animIndex > 0 then
            if !self.l_preventdefaultspeak then
                self:PlaySoundFile( "laugh" )
            end
            if schadenfreudeUseClassLaughter:GetBool() then
                self:EmitSound( laughSnd, 80, nil, nil, CHAN_VOICE )
            end

            self:PlayGestureAndWait( seqName )
            if self:GetState() == "Schadenfreude" then self:SetState( "Idle" ) end
        else
            self:SetState( "Laughing" )
        end
    end

    local taunts = {
        [ "scout_taunt_flip" ] = {
            PartnerOffset = Vector( 80, 0, 0 )
        }
    }

    local function TauntWithPartner( self )
        local partner = NULL

        for _, v in ipairs( GetLambdaPlayers() ) do
            if v == self or v:GetState() != "TauntWithPartner" or !self:IsInRange( v, 1000 ) or !self:CanSee( v ) then continue end
            partner = v
            break  
        end

        if IsValid( partner ) then
            self:MoveToPos( partner:GetPos(), {tol=64} )
            
            self.TauntPartner = partner
            partner.TauntPartner = self

            self:GetWeaponENT():SetNoDraw( true )
            self:GetWeaponENT():DrawShadow( false )

            local offset = partner.TauntData.PartnerOffset
            self:SetPos( partner:GetPos() + partner:GetForward() * offset.x + partner:GetRight() * offset.y + partner:GetUp() * offset.z )
            self:SetAngles( ( partner:GetPos() - self:GetPos() ):Angle() )

            local receiverAnim, receiverWaitT = self:LookupSequence( partner.TauntName .. "_receiver" )
            self:AddGestureSequence( receiverAnim )
            coroutine.wait( receiverWaitT )

            self:GetWeaponENT():SetNoDraw( self:IsWeaponMarkedNodraw() )
            self:GetWeaponENT():DrawShadow( !self:IsWeaponMarkedNodraw() )

            self:SetState( "Idle" )
        else
            self.TauntData, self.TauntName = table_Random( taunts )

            self:GetWeaponENT():SetNoDraw( true )
            self:GetWeaponENT():DrawShadow( false )

            local startAnim, startLoopTime = self:LookupSequence( self.TauntName .. "_start" )
            self:AddGestureSequence( startAnim )

            local loopAnimEndTime = ( CurTime() + startLoopTime )

            local stopTauntTime = ( CurTime() + random( 20, 40 ) )
            while ( !IsValid( self.TauntPartner ) and CurTime() < stopTauntTime ) do
                if CurTime() > loopAnimEndTime then
                    local loopAnim, loopEndTime = self:LookupSequence( self.TauntName .. "_loop" )
                    self:AddGestureSequence( loopAnim )
                    loopAnimEndTime = ( CurTime() + loopEndTime )
                end

                coroutine_yield()
            end

            if IsValid( self.TauntPartner ) then
                local initiatorAnim, initiatorWaitT = self:LookupSequence( self.TauntName .. "_initiator" )
                self:AddGestureSequence( initiatorAnim )
                coroutine.wait( initiatorWaitT )
            end

            self:GetWeaponENT():SetNoDraw( self:IsWeaponMarkedNodraw() )
            self:GetWeaponENT():DrawShadow( !self:IsWeaponMarkedNodraw() )

            self:SetState( "Idle" )
        end
    end

    local function OnLambdaUseWeapon( lambda, target )
        if lambda.l_TF_AtomicPunched then return end
        lambda:l_TF_OldUseWeapon( target ) 
    end

    local inventoryItems = {
        [ "tf2_sandwich" ] = {
            Condition = function( lambda )
                return ( !lambda:InCombat() and !lambda:IsPanicking() and lambda:Health() <= ( lambda:GetMaxHealth() * Rand( 0.5, 0.8 ) ) )
            end,
            Cooldown = 30
        },
        [ "tf2_jarate" ] = {             
            Condition = function( lambda )
                return ( lambda:InCombat() and lambda:IsInRange( lambda:GetEnemy(), 750 ) and random( 1, 3 ) == 1 or lambda.l_TF_IsBurning or lambda:IsOnFire() )
            end,
            Cooldown = 20 
        },
        [ "tf2_madmilk" ] = {             
            Condition = function( lambda )
                return ( lambda:InCombat() and lambda:IsInRange( lambda:GetEnemy(), 750 ) and random( 1, 3 ) == 1 or lambda.l_TF_IsBurning or lambda:IsOnFire() )
            end,
            Cooldown = 20 
        },
        [ "tf2_critacola" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( lambda:InCombat() and random( 1, 2 ) == 1 and ( !lambda:IsInRange( ene, 400 ) or !lambda:CanSee( ene ) ) )
            end,
            Cooldown = 30
        },
        [ "tf2_cleaver" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                local attackDist = ( lambda.l_CombatAttackRange or ( lambda.l_HasMelee and 70 or 1000 ) )
                return ( lambda:InCombat() and lambda:CanSee( ene ) and lambda:IsInRange( ene, 1500 ) and random( 1, 2 ) == 1 and ( lambda.l_Clip == 0 or lambda:GetIsReloading() or !lambda:IsInRange( ene, attackDist ) or random( 1, 10 ) == 1 ) )
            end,
            Cooldown = 5
        },
        [ "tf2_bonk" ] = {             
            Condition = function( lambda )
                return ( lambda:IsPanicking() and ( !LambdaIsValid( lambda.l_RetreatTarget ) or !lambda:CanSee( lambda.l_RetreatTarget ) ) )
            end,
            Cooldown = 30
        },
        [ "tf2_escapeplan" ] = {
            Condition = function( lambda )
                return ( lambda:IsPanicking() and lambda:Health() <= ( lambda:GetMaxHealth() * 0.75 ) and ( !LambdaIsValid( lambda.l_RetreatTarget ) or !lambda:CanSee( lambda.l_RetreatTarget ) ) )
            end
        },
        [ "tf2_bushwacka" ] = {
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( lambda:InCombat() and lambda:IsInRange( ene, 200 ) and ( lambda.l_TF_MiniCritBoosted or ene.l_TF_CoveredInUrine or ene.l_TF_CoveredInMilk or CurTime() <= ene.l_TF_MarkedForDeath ) and random( 1, 2 ) == 1 )
            end
        },
        [ "tf2_shahanshah" ] = {
            Condition = function( lambda )
                return ( lambda:InCombat() and ( lambda:Health() < ( lambda:GetMaxHealth() * 0.5 ) ) and lambda:IsInRange( lambda:GetEnemy(), 200 ) and random( 1, 4 ) == 1 )
            end
        },
        [ "tf2_reserveshooter" ] = {
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( lambda:InCombat() and lambda:IsInRange( ene, 800 ) and !ene:OnGround() )
            end
        }
    }

    local function OnLambdaInitialize( lambda )        
        lambda.l_TF_DamageEvents = {}
        lambda.l_TF_CritMult = 0
        lambda.l_TF_NextCritUpdateT = CurTime()

        lambda.l_TF_HasOverheal = false
        lambda.l_TF_HealFraction = 0

        local weapon = lambda.WeaponEnt
        if IsValid( weapon ) then weapon.l_TF_Owner = lambda end
        
        lambda.l_TF_Decapitations = 0
        lambda.l_TF_NextMeleeCrit = MELEE_NOCRIT

        lambda.l_TF_Shield_IsCharging = false
        lambda.l_TF_Shield_PreChargeYawRate = lambda.loco:GetMaxYawRate()
        lambda.l_TF_Shield_ChargeMeter = 100
        lambda.l_TF_Shield_ChargeMeterFull = true
        lambda.l_TF_Shield_IsEquipped = false
        lambda.l_TF_Shield_Entity = NULL
        lambda.l_TF_Shield_CritBoosted = false

        lambda.l_TF_MiniCritBoosted = false
        lambda.l_TF_MiniCritBoosted_MarkAfterAttacking = false

        lambda.l_TF_AtomicPunched = false
        lambda.l_TF_AtomicPunched_Trail = NULL

        lambda.l_TF_IsUsingItem = false
        lambda.l_TF_Inventory = {}
        lambda.l_TF_NextInventoryCheckT = ( CurTime() + Rand( 0.1, 1.0 ) )

        if random( 1, 100 ) <= randomSituationalWeaponChance:GetInt() then
            for name, data in RandomPairs( inventoryItems ) do
                if !lambda:CanEquipWeapon( name ) then continue end
                local newInvWep = table_Merge( { NextUseTime = CurTime(), IsReady = true }, data )
                lambda.l_TF_Inventory[ name ] = newInvWep
                break
            end
        end

        lambda:SimpleTimer( FrameTime() * 2, function() 
            if !lambda.l_TF_Shield_IsEquipped then
                local shieldChance = shieldSpawnChance:GetInt()
                if random( 1, 100 ) <= shieldChance then LAMBDA_TF2:GiveRemoveChargeShield( lambda ) end
            end
        end, true )

        lambda.TauntName = NULL
        lambda.TauntPartner = NULL
        lambda.TauntData = vector_origin

        lambda.Schadenfreude = Schadenfreude
        lambda.TauntWithPartner = TauntWithPartner

        lambda.l_TF_OldUseWeapon = lambda.UseWeapon
        lambda.UseWeapon = OnLambdaUseWeapon
    end

    local function OnLambdaThink( lambda, weapon, isdead )
        if isdead or CurTime() > lambda.l_TF_NextInventoryCheckT then
            local equipped = false
            local wepName = lambda:GetWeaponName()
            
            for name, wep in RandomPairs( lambda.l_TF_Inventory ) do
                if isdead then
                    wep.IsReady = true 
                    wep.NextUseTime = CurTime()
                    continue
                end

                if !wep.IsReady then
                    if CurTime() >= wep.NextUseTime then
                        wep.IsReady = true
                        weapon:EmitSound( "lambdaplayers/weapons/tf2/recharged.mp3", 70, 100, 0.5, CHAN_STATIC )
                    else
                        continue
                    end
                end

                if wepName != name and wep.Condition( lambda ) == true then
                    lambda:SwitchWeapon( name )
                    if lambda:GetWeaponName() == name then
                        equipped = true
                        break
                    end
                end
            end

            local nextT = Rand( 0.1, 0.5 )
            if equipped then nextT = ( nextT + random( 1, 3 ) ) end
            lambda.l_TF_NextInventoryCheckT = ( CurTime() + nextT )
        end

        if lambda.l_TF_MiniCritBoosted then
            local boostSnd = lambda.l_TF_CritBoostSound

            if isdead or CurTime() >= lambda.l_TF_MiniCritBoosted then
                lambda.l_TF_MiniCritBoosted = false
                lambda.l_TF_MiniCritBoosted_MarkAfterAttacking = false
                
                if !lambda:IsWeaponMarkedNodraw() then 
                    weapon:SetMaterial( "" ) 
                end

                if boostSnd then
                    boostSnd:Stop()
                    lambda.l_TF_CritBoostSound = nil
                end
            else
                if !lambda:IsWeaponMarkedNodraw() then 
                    weapon:SetMaterial( "lambdaplayers/models/weapons/tf2/criteffects/minicrit" )
                end

                if !boostSnd then
                    boostSnd = LAMBDA_TF2:CreateSound( weapon, "lambdaplayers/weapons/tf2/crits/crit_idle.wav" )
                    lambda.l_TF_CritBoostSound = boostSnd
                end

                if boostSnd and !boostSnd:IsPlaying() then
                    boostSnd:PlayEx( 0.5, 100 )
                end
            end
        end

        if lambda.l_TF_AtomicPunched and ( isdead or CurTime() >= lambda.l_TF_AtomicPunched ) then
            lambda.l_TF_AtomicPunched = false

            local trail = lambda.l_TF_AtomicPunched_Trail
            if IsValid( trail ) then 
                trail:SetParent()
                SafeRemoveEntityDelayed( trail, 1 ) 
            end
        end

        if lambda.l_TF_Shield_IsEquipped then
            local shield = lambda.l_TF_Shield_Entity
            local shieldType = lambda.l_TF_Shield_Type

            if IsValid( shield ) then
                local dontDraw = lambda:GetNoDraw()
                shield:SetNoDraw( dontDraw )
                shield:DrawShadow( !dontDraw )
            end

            if !isdead and !lambda.l_TF_Shield_IsCharging and lambda.l_TF_Shield_ChargeMeterFull and random( 1, 40 ) == 1 then
                local enemy = lambda:GetEnemy()
                local isPanicking = ( lambda:IsPanicking() or lambda:IsOnFire() or lambda.l_TF_IsBurning )

                local canCharge = isPanicking
                if !canCharge and lambda.l_HasMelee and lambda:InCombat() then
                    local selfPos = lambda:GetPos()
                    local enemyPos = enemy:GetPos()
                    local stepHeight = lambda.loco:GetStepHeight()        

                    if ( enemyPos.z >= ( selfPos.z - stepHeight ) and enemyPos.z <= ( selfPos.z + stepHeight ) ) and lambda:IsInRange( enemy, 1000 ) and !lambda:IsInRange( enemy, lambda.l_CombatAttackRange ) and lambda:CanSee( enemy ) then
                        lambda:LookTo( enemy, 1.0 )

                        local los = deg( acos( lambda:GetForward():Dot( ( enemyPos - selfPos ):GetNormalized() ) ) )
                        canCharge = ( los <= 15 )
                    end
                end

                if canCharge then
                    lambda:EmitSound( "lambdaplayers/weapons/tf2/shield_charge.mp3", 80, 100, 1, CHAN_STATIC )
                    lambda:PlaySoundFile( isPanicking and "fall" or "taunt" )

                    local chargeTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 32, 16, 0.75, "effects/beam001_white", lambda:WorldSpaceCenter(), lambda )
                    lambda:DeleteOnRemove( chargeTrail )
                    lambda.l_TF_Shield_ChargeTrail = chargeTrail

                    lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate / ( shieldType != 3 and 20 or 1 ) )
                    lambda.l_TF_Shield_IsCharging = true

                    LAMBDA_TF2:RemoveBurn( lambda )

                    if lambda.l_TF_CoveredInUrine then lambda.l_TF_CoveredInUrine = 0 end
                    if lambda.l_TF_CoveredInMilk then lambda.l_TF_CoveredInMilk = 0 end
                    
                    table_Empty( lambda.l_TF_BleedInfo )
                end
            end

            if lambda.l_TF_Shield_IsCharging then
                if !isdead then
                    if lambda.l_HasMelee and CurTime() >= lambda.l_WeaponUseCooldown then
                        lambda.l_WeaponUseCooldown = CurTime() + 0.1
                    end

                    lambda.loco:SetVelocity( lambda:GetForward() * max( 750, lambda.loco:GetDesiredSpeed() * 2 ) )

                    if !lambda:IsWeaponMarkedNodraw() then
                        local critMat = ""
                        if lambda.l_TF_Shield_ChargeMeter <= 40 then
                            critMat = "lambdaplayers/models/weapons/tf2/criteffects/crit"
                        elseif lambda.l_TF_Shield_ChargeMeter <= 75 then
                            if !lambda.l_TF_Shield_CritBoosted then
                                lambda.l_TF_Shield_CritBoosted = true
                                weapon:EmitSound( "lambdaplayers/weapons/tf2/crits/weapon_crit_charged_on.mp3", 74, nil, 0.25, CHAN_STATIC )
                            end
                            critMat = "lambdaplayers/models/weapons/tf2/criteffects/minicrit"
                        end
                        weapon:SetMaterial( critMat ) 
                    end

                    local lambdaPos = lambda:GetAttachmentPoint( "eyes" ).Pos
                    shieldChargeTrTbl.start = lambdaPos
                    shieldChargeTrTbl.endpos = ( lambdaPos + lambda:GetForward() * 48 )
                    shieldChargeTrTbl.filter = { lambda, weapon, shield }

                    local chargeResult = TraceHull( shieldChargeTrTbl )
                    if chargeResult.Hit then
                        local impactEnt = chargeResult.Entity
                        if LAMBDA_TF2:IsValidCharacter( impactEnt ) then
                            impactEnt:EmitSound( "lambdaplayers/weapons/tf2/charge/charge_hit_flesh_range" .. random( 1, 3 ) .. ".mp3", 75, 100, 1, CHAN_STATIC )

                            local bashDmg = LAMBDA_TF2:RemapClamped( lambda.l_TF_Shield_ChargeMeter, 90, 40, 10, 30 )
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
                            lambda:EmitSound( "lambdaplayers/weapons/tf2/charge/charge_hit_world" .. random( 1, 3 ) .. ".mp3", 75, 100, 1, CHAN_STATIC )
                        end

                        lambda.l_TF_Shield_IsCharging = false
                        ScreenShake( lambdaPos, 25, 150, 1, 750 )
                    else
                        lambda.l_TF_Shield_ChargeMeter = ( lambda.l_TF_Shield_ChargeMeter - ( ( 100 / 1.5 ) * FrameTime() ) )
                    end
                end

                if isdead or !lambda.l_TF_Shield_IsCharging or lambda.l_TF_Shield_ChargeMeter <= 0 then
                    lambda.l_TF_Shield_IsCharging = false
    
                    lambda:SimpleTimer( 0.3, function() 
                        if !lambda:IsWeaponMarkedNodraw() then
                            weapon:SetMaterial( "" ) 
                        end

                        if lambda.l_TF_Shield_CritBoosted then
                            lambda.l_TF_Shield_CritBoosted = false
                            weapon:StopSound( "lambdaplayers/weapons/tf2/crits/weapon_crit_charged_on.mp3" )
                            weapon:EmitSound( "lambdaplayers/weapons/tf2/crits/weapon_crit_charged_off.mp3", 74, nil, 0.25, CHAN_STATIC )
                        end

                        lambda.l_TF_NextMeleeCrit = MELEE_NOCRIT 
                    end, true )

                    if !isdead then
                        lambda:RecomputePath()
                        if lambda.l_TF_Shield_ChargeMeter <= 40 then
                            lambda.l_TF_NextMeleeCrit = MELEE_CRIT
                        elseif lambda.l_TF_Shield_ChargeMeter <= 75 then
                            lambda.l_TF_NextMeleeCrit = MELEE_MINICRIT
                        end
                        lambda.l_TF_Shield_ChargeMeter = 0
                        lambda.l_TF_Shield_ChargeMeterFull = false
                    end

                    lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate )
                    lambda:StopSound( "lambdaplayers/weapons/tf2/shield_charge.mp3" )

                    local chargeTrail = lambda.l_TF_Shield_ChargeTrail
                    if IsValid( chargeTrail ) then
                        chargeTrail:SetParent( NULL )
                        SafeRemoveEntityDelayed( chargeTrail, 1 )
                    end
                end
            elseif !isdead and !lambda.l_TF_Shield_ChargeMeterFull then
                local chargeRate = ( ( 100 / 12 ) * FrameTime() )
                if shieldType == 2 then chargeRate = ( chargeRate * 1.5 ) end
                lambda.l_TF_Shield_ChargeMeter = ( lambda.l_TF_Shield_ChargeMeter + chargeRate )
                
                if lambda.l_TF_Shield_ChargeMeter >= 100 then
                    weapon:EmitSound( "lambdaplayers/weapons/tf2/recharged.mp3", 70, 100, 0.5, CHAN_STATIC )
                    lambda.l_TF_Shield_ChargeMeter = 100
                    lambda.l_TF_Shield_ChargeMeterFull = true
                end
            end
        end

        if CurTime() > lambda.l_TF_NextCritUpdateT then
            if #lambda.l_TF_DamageEvents == 0 then
                lambda.l_TF_CritMult = Remap( 1, 1, 4, 0, 255 )
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

                local mult = Remap( totalDmg, 0, TF_DAMAGE_CRITMOD_DAMAGE, 1, TF_DAMAGE_CRITMOD_MAXMULT )
                lambda.l_TF_CritMult = Round( Remap( mult, 1, 4, 0, 255 ) )
            end

            lambda.l_TF_NextCritUpdateT = ( CurTime() + 0.5 )
        end
    end
    
    local function OnLambdaRespawn( lambda )
        table_Empty( lambda.l_TF_DamageEvents )
    end

    local function OnLambdaInjured( lambda, dmginfo )
        if lambda.l_TF_Shield_IsEquipped then
            local shieldType = lambda.l_TF_Shield_Type

            if dmginfo:IsDamageType( DMG_BURN ) then
                dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.5 )
            elseif dmginfo:IsExplosionDamage() then
                dmginfo:ScaleDamage( shieldType == 3 and 0.85 or shieldType == 2 and 0.8 or 0.7 )
            end

            if lambda.L_TF_Shield_IsCharging and shieldType == 3 and dmginfo:GetAttacker() != lambda and !dmginfo:IsDamageType( DMG_FALL ) then
                lambda.l_TF_Shield_ChargeMeter = ( lambda.l_TF_Shield_ChargeMeter - dmginfo:GetDamage() )
            end
        end
    end

    local function OnPostEntityTakeDamage( ent, dmginfo, tookDamage )
        if !IsValid( ent ) then return end 

        local attacker = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()
        if !IsValid( attacker ) or !IsValid( inflictor ) then return end
        
        local dmgType = dmginfo:GetDamageType()
        if ent.l_TF_IsBurning != nil and bit.band( dmgType, DMG_IGNITE ) != 0 and ent:WaterLevel() < 2 then
            LAMBDA_TF2:Burn( ent, attacker, inflictor )
        end

        local markOnAttack = attacker.l_TF_MiniCritBoosted_MarkAfterAttacking
        if markOnAttack then
            attacker.l_TF_MarkedForDeath = ( CurTime() + markOnAttack )
        end

        if !LAMBDA_TF2:IsValidCharacter( ent, false ) then return end
        local dmgCustom = dmginfo:GetDamageCustom()

        if bit.band( dmgType, DMG_MELEE ) != 0 then
            local hitSnd = inflictor:GetWeaponAttribute( "HitSound", { "lambdaplayers/weapons/tf2/melee/cbar_hitbod1.mp3", "lambdaplayers/weapons/tf2/melee/cbar_hitbod2.mp3", "lambdaplayers/weapons/tf2/melee/cbar_hitbod3.mp3" } )
            if istable( hitSnd ) then hitSnd = hitSnd[ random( #hitSnd ) ] end
            inflictor:EmitSound( hitSnd, 75, 100, 1, CHAN_STATIC )
        end

        if dmgCustom == TF_DMG_CUSTOM_BURNING or ( inflictor.l_TF_IsTF2Weapon or inflictor.TF2Data ) and ( bit.band( dmgType, DMG_CLUB ) != 0 or bit.band( dmgType, DMG_SLASH ) != 0 or dmginfo:IsBulletDamage() ) then
            ent:EmitSound( "Flesh.BulletImpact" )
        end

        if tookDamage then
            if bit.band( dmgType, DMG_MELEE ) != 0 or dmgCustom == TF_DMG_CUSTOM_BURNING or dmgCustom == TF_DMG_CUSTOM_BLEEDING then
                local dmgPos = dmginfo:GetDamagePosition()
                LAMBDA_TF2:CreateBloodParticle( dmgPos, AngleRand( -180, 180 ), ent )
            end

            if bit.band( dmgType, DMG_MELEE ) != 0 and dmgCustom != TF_DMG_CUSTOM_BLEEDING then
                local bleedingTime = inflictor:GetWeaponAttribute( "BleedingDuration" )
                if bleedingTime and bleedingTime > 0 then LAMBDA_TF2:MakeBleed( ent, attacker, inflictor, bleedingTime ) end
            end

            if attacker != ent then
                if ent.IsLambdaPlayer and ent.L_TF_Shield_IsCharging and ent.l_TF_Shield_Type == 3 and bit.band( dmgType, DMG_FALL ) == 0 then
                    ent.l_TF_Shield_ChargeMeter = ( ent.l_TF_Shield_ChargeMeter - dmginfo:GetDamage() )
                end

                local onDealDmgFunc = inflictor.l_TF_OnDealDamage
                if isfunction( onDealDmgFunc ) then onDealDmgFunc( inflictor, ent, dmginfo ) end

                if ent.l_TF_CoveredInMilk and dmgCustom != TF_DMG_CUSTOM_BURNING and LAMBDA_TF2:IsValidCharacter( attacker ) then
                    LAMBDA_TF2:GiveHealth( attacker, ( dmginfo:GetDamage() * 0.6 ), false )
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
        }
    }
    tf2DeathAnims[ TF_DMG_CUSTOM_HEADSHOT ] = {
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
    tf2DeathAnims[ TF_DMG_CUSTOM_DECAPITATION ] = tf2DeathAnims[ TF_DMG_CUSTOM_HEADSHOT ]

    local function OnLambdaKilled( lambda, dmginfo )
        local dmgCustom = dmginfo:GetDamageCustom()
        local doDecapitation = ( dmgCustom == TF_DMG_CUSTOM_DECAPITATION )

        local animTbl = tf2DeathAnims[ dmgCustom ]
        if animTbl and random( 1, 100 ) <= deathAnimChance:GetInt() then
            local isTFAnim = true
            local index, dur = lambda:LookupSequence( animTbl[ random( #animTbl ) ] )

            if index <= 0 then
                isTFAnim = false
                index, dur = lambda:LookupSequence( gmodDeathAnims[ random( #gmodDeathAnims ) ] )
            end

            if index > 0 then
                local serverside = true

                local animEnt = ents_Create( "base_anim" )
                animEnt:SetModel( lambda:GetModel() )
                animEnt:SetPos( lambda:GetPos() )
                animEnt:SetAngles( lambda:GetAngles() )
                animEnt:Spawn()

                animEnt:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                LAMBDA_TF2:TakeNoDamage( animEnt )

                if dmgCustom == TF_DMG_CUSTOM_BURNING or lambda.l_TF_IsBurning or lambda:IsOnFire() then
                    animEnt:Ignite( dur + 1, 0 )
                end

                animEnt:SetSkin( lambda:GetSkin() )
                for _, v in ipairs( lambda:GetBodyGroups() ) do 
                    animEnt:SetBodygroup( v.id, lambda:GetBodygroup( v.id ) )
                end

                net.Start( "lambdaplayers_serversideragdollplycolor" )
                    net.WriteEntity( animEnt )
                    net.WriteVector( lambda:GetPlyColor() ) 
                net.Broadcast()

                animEnt:SetSequence( lambda:GetSequence() )
                animEnt:ResetSequenceInfo()
                animEnt:SetCycle( lambda:GetCycle() )
                animEnt:FrameAdvance()

                local speed = Rand( 0.8, 1.2 )
                if isTFAnim then
                    local animLayer = animEnt:AddGestureSequence( index, true )
                    animEnt:SetLayerPlaybackRate( animLayer, speed )

                    SimpleTimer( 1, function()
                        if !IsValid( animEnt ) then return end
                        animEnt:SetSequence( ACT_DIERAGDOLL )
                        animEnt:ResetSequenceInfo()
                    end )
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

                local ragdoll = lambda.ragdoll
                lambda.ragdoll = animEnt

                lambda:SetNW2Entity( "lambda_serversideragdoll", animEnt )
                lambda:DeleteOnRemove( animEnt )

                local finishTime = ( CurTime() + ( dur / speed ) * ( isTFAnim and 1 or Rand( 0.8, 1 ) ) )
                lambda:Thread( function()
                    
                    while ( CurTime() < finishTime ) do
                        animEnt:FrameAdvance()
                        coroutine_yield() 
                    end

                    if !serverside then
                        lambda:CreateClientsideRagdoll( nil, animEnt )

                        if doDecapitation then
                            net.Start( "lambda_tf2_decapitate_csragdoll" )
                                net.WriteEntity( lambda )
                                net.WriteBool( false )
                            net.Broadcast()
                        end
                    else
                        ragdoll = lambda:CreateServersideRagdoll( nil, animEnt )
                        if doDecapitation then LAMBDA_TF2:DecapitateHead( ragdoll, false ) end
                    end

                    animEnt:Remove()
                
                end, "TF2_DeathAnimation", true )
                
                if IsValid( ragdoll ) then
                    ragdoll:Remove()
                else
                    serverside = false

                    net.Start( "lambda_tf2_removecsragdoll" )
                        net.WriteEntity( lambda )
                    net.Broadcast()
                end
            end
        end

        if doDecapitation then
            local target = lambda.ragdoll

            if target != lambda and !IsValid( target ) then
                net.Start( "lambda_tf2_decapitate_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteBool( true )
                    net.WriteVector( dmginfo:GetDamageForce() / 2 )
                net.Broadcast()
            else
                LAMBDA_TF2:DecapitateHead( target, true, ( dmginfo:GetDamageForce() / 4 ) )
            end
        end

        if lambda.l_TF_IsBurning and IsValid( lambda.ragdoll ) then
            lambda.ragdoll:Ignite( ( lambda.l_TF_FlameRemoveTime- CurTime() ), 0 )
        end

        if lambda.l_TF_Shield_IsEquipped then
            lambda.l_TF_Shield_ChargeMeter = 100
            lambda.l_TF_Shield_ChargeMeterFull = true

            local shield = lambda.l_TF_Shield_Entity
            if IsValid( shield ) then
                net.Start( "lambdaplayers_createclientsidedroppedweapon" )
                    net.WriteEntity( shield )
                    net.WriteEntity( lambda )
                    net.WriteVector( lambda:GetPhysColor() )
                    net.WriteString( lambda:GetWeaponName() )
                    net.WriteVector( dmginfo:GetDamageForce() )
                    net.WriteVector( dmginfo:GetDamagePosition() )
                net.Broadcast()

                local givenWeapon = shield.l_TF_GivenByWeapon
                if givenWeapon and lambda.l_SpawnWeapon != givenWeapon then
                    LAMBDA_TF2:GiveRemoveChargeShield( lambda )
                end
            end
        end

        local attacker = dmginfo:GetAttacker()
        if IsValid( attacker ) and attacker.IsLambdaPlayer and attacker:GetWeaponName() == "tf2_eyelander" then
            attacker.l_TF_Decapitations = ( attacker.l_TF_Decapitations + lambda.l_TF_Decapitations )
        end
        lambda.l_TF_Decapitations = 0

        lambda.l_TF_IsUsingItem = false

        OnPostEntityTakeDamage( lambda, dmginfo, true )
    end

    local function OnLambdaSwitchWeapon( lambda, weapon, data )
        if data.origin != "Team Fortress 2" then weapon.TF2Data = nil end
    end

    local function OnLambdaChangeState( lambda, old, new )
        if new == "Laughing" and ( alwaysUseSchadenfreude:GetBool() or lambda:GetWeaponENT().TF2Data ) then
            lambda:SetState( "Schadenfreude" )
            return true
        end

        if old == "UseTFItem" and lambda.l_TF_IsUsingItem and lambda:Alive() then return true end
    end
    
    local function OnLambdaCanSwitchWeapon( lambda, name, data )
        if lambda:GetState() == "UseTFItem" then return true end
        
        local invWep = lambda.l_TF_Inventory[ name ]
        if invWep and !invWep.IsReady then return true end
    end

    hook.Add( "LambdaOnInitialize", "LambdaTF2_OnLambdaInitialize", OnLambdaInitialize )
    hook.Add( "LambdaOnRespawn", "LambdaTF2_OnLambdaRespawn", OnLambdaRespawn )
    hook.Add( "LambdaOnThink", "LambdaTF2_OnLambdaThink", OnLambdaThink )
    hook.Add( "LambdaOnInjured", "LambdaTF2_OnLambdaOnInjured", OnLambdaInjured )
    hook.Add( "LambdaOnKilled", "LambdaTF2_OnLambdaKilled", OnLambdaKilled )
    hook.Add( "LambdaOnChangeState", "LambdaTF2_OnLambdaChangeState", OnLambdaChangeState )
    hook.Add( "LambdaCanSwitchWeapon", "LambdaTF2_OnLambdaSwitchWeapon", OnLambdaCanSwitchWeapon )

    ---

    local dmgCustomKillicons = {
        [ TF_DMG_CUSTOM_BACKSTAB ]              = "lambdaplayers_weaponkillicons_tf2_backstab",
        [ TF_DMG_CUSTOM_HEADSHOT ]              = "lambdaplayers_weaponkillicons_tf2_headshot",
        [ TF_DMG_CUSTOM_STICKBOMB_EXPLOSION ]   = "lambdaplayers_weaponkillicons_tf2_caber_explosion",
        [ TF_DMG_CUSTOM_BLEEDING ]              = "lambdaplayers_weaponkillicons_tf2_bleedout"
    }
    local dmgCustomCrits = {
        [ TF_DMG_CUSTOM_BACKSTAB ]              = true,
        [ TF_DMG_CUSTOM_HEADSHOT ]              = true
    }
    local wepDmgScale = GetConVar( "lambdaplayers_combat_weapondmgmultiplier" )

    local function OnEntityTakeDamage( ent, dmginfo )
        if ent.l_TF_FixedBulletDamage then
            dmginfo:SetDamage( ent.l_TF_FixedBulletDamage * wepDmgScale:GetFloat() )
            ent.l_TF_FixedBulletDamage = false
        end

        local inflictor = dmginfo:GetInflictor()
        if !IsValid( inflictor ) then return end

        local isTF2Weapon = ( inflictor.TF2Data != nil )
        
        local attacker = dmginfo:GetAttacker()
        if attacker == ent then return end

        if !LAMBDA_TF2:IsValidCharacter( ent ) then return end
        if ent.l_TF_IsBurning and inflictor:GetClass() == "entityflame" then return true end

        local dmgCustom = dmginfo:GetDamageCustom()
        ent:SetNW2Bool( "lambda_tf2_canbedecapitated", ( !ent.IsLambdaPlayer and dmgCustom == TF_DMG_CUSTOM_DECAPITATION ) )

        local isCritical = ( dmginfo:IsDamageType( DMG_CRITICAL ) )
        if !isCritical and dmgCustomCrits[ dmgCustom ] then
            isCritical = true
            dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_CRITICAL )
        end

        local critType = ( isCritical and 2 or ( dmginfo:IsDamageType( DMG_MINICRITICAL ) and 1 or 0 ) )
        if critType == 0 and ( attacker.l_TF_MiniCritBoosted or ent.l_TF_CoveredInUrine or ent.l_TF_CoveredInMilk or CurTime() <= ent.l_TF_MarkedForDeath ) then
            critType = 1
        end
        if critType == 1 and isTF2Weapon and inflictor:GetWeaponAttribute( "MiniCritsToFull", false ) then
            critType = 2 
        end

        local critDamage = 0
        local damage = dmginfo:GetDamage()
        if critType == 2 then
            critDamage = ( ( TF_DAMAGE_CRIT_MULTIPLIER - 1 ) * damage )
        elseif critType == 1 then
            critDamage = ( ( TF_DAMAGE_MINICRIT_MULTIPLIER - 1 ) * damage )
        end

        local entHealth = ent:Health()
        if ent.Armor then entHealth = ( entHealth + ent:Armor() ) end
        
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

        if inflictor.l_TF_IsTF2Weapon or inflictor.TF2Data then
            dmginfo:SetBaseDamage( dmginfo:GetDamage() )

            local doShortRangeDistanceIncrease = ( critType <= 1 )
            local doLongRangeDistanceDecrease = ( critType == 0 ) 

            local rndDmgSpread = 0.1
            local minSpread = ( 0.5 - rndDmgSpread )
            local maxSpread = ( 0.5 + rndDmgSpread )
    
            if dmginfo:IsDamageType( DMG_USEDISTANCEMOD ) then
                local attackerPos = attacker:WorldSpaceCenter()
                local optimalDist = 512
    
                local dist = max( 1, ( attackerPos:Distance( ent:WorldSpaceCenter() ) ) )
                    
                local centerSpread = Remap( dist / optimalDist, 0, 2, 1, 0 )
                if centerSpread > 0.5 and doShortRangeDistanceIncrease or centerSpread <= 0.5 then
                    if centerSpread > 0.5 and dmginfo:IsDamageType( DMG_NOCLOSEDISTANCEMOD ) then
                        centerSpread = Remap( centerSpread, 0.5, 1, 0.5, 0.65 )
                    end

                    minSpread = max( 0, ( centerSpread - rndDmgSpread ) )
                    maxSpread = min( 1, ( centerSpread + rndDmgSpread ) )
                end
            end

            local rndDamage = ( damage * 0.5 )
            local rndRangeVal = ( minSpread + rndDmgSpread )

            local dmgVariance = Remap( rndRangeVal, 0, 1, -rndDamage, rndDamage )
            if doShortRangeDistanceIncrease and dmgVariance > 0 or doLongRangeDistanceDecrease then 
                damage = ( damage + dmgVariance ) 
            end
        end

        local totalDamage = ( damage + critDamage )
        dmginfo:SetDamageForce( dmginfo:GetDamageForce() * ( totalDamage / dmginfo:GetDamage() ) )
        dmginfo:SetDamage( totalDamage )
        dmginfo:SetDamageBonus( critDamage )
        local entDead = ( totalDamage >= entHealth )

        if entDead and attacker.IsLambdaPlayer and attacker.l_TF_Shield_IsEquipped and !attacker.l_TF_Shield_ChargeMeterFull and attacker.l_TF_Shield_Type == 3 and ( dmgCustom == TF_DMG_CUSTOM_CHARGE_IMPACT or dmginfo:IsDamageType( DMG_MELEE ) ) then
            attacker.l_TF_Shield_ChargeMeter = ( attacker.l_TF_Shield_ChargeMeter + 75 )
        end

        if critType > 0 and LAMBDA_TF2:IsValidCharacter( ent ) then
            net.Start( "lambda_tf2_criteffects" )
                net.WriteUInt( critType, 2 )
                net.WriteVector( ent:WorldSpaceCenter() + vector_up * 32 )
                net.WriteEntity( ent )
                net.WriteBool( entDead )
            net.Broadcast()
        end

        if ( inflictor.l_TF_IsTF2Weapon or inflictor.TF2Data ) then 
            if attacker.IsLambdaPlayer then 
                LAMBDA_TF2:RecordDamageEvent( attacker, dmginfo, entDead, entHealth ) 
            end

            if !dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) then
                local vecDir = ( ( inflictor:WorldSpaceCenter() - vector_up * 10 ) - ent:WorldSpaceCenter() ):GetNormalized()
                LAMBDA_TF2:ApplyPushFromDamage( ent, dmginfo, vecDir )     
            end
        end

        if ent.l_TF_AtomicPunched then return true end
    end

    local function OnServerThink()
        for _, ent in ipairs( ents_GetAll() ) do
            if !IsValid( ent ) then continue end
            
            local isDead = ( ent:Health() <= 0 or ( ent.IsLambdaPlayer or ent:IsPlayer() ) and !ent:Alive() )
            local waterLvl = ent:WaterLevel()

            if ent.l_TF_HasOverheal then
                local curHealth = ent:Health()
                local maxHealth = ent:GetMaxHealth()

                if isDead or curHealth <= maxHealth then
                    ent.l_TF_HasOverheal = false
                else
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
                if ( isDead or CurTime() > ent.l_TF_CoveredInUrine or waterLvl >= 2 ) then
                    ent.l_TF_CoveredInUrine = false

                    if ent.l_TF_UrineEffect then
                        ent.l_TF_UrineEffect = false
                        
                        net.Start( "lambda_tf2_urineeffect" )
                            net.WriteEntity( ent )
                        net.Broadcast()
                    end
                elseif !ent.l_TF_UrineEffect then
                    net.Start( "lambda_tf2_urineeffect" )
                        net.WriteEntity( ent )
                    net.Broadcast()

                    ent.l_TF_UrineEffect = true
                end
            end

            if ent.l_TF_CoveredInMilk then 
                if ( isDead or CurTime() > ent.l_TF_CoveredInMilk or waterLvl >= 2 ) then
                    ent.l_TF_CoveredInMilk = false

                    if ent.l_TF_MilkEffect then
                        ent.l_TF_MilkEffect = false
                        
                        net.Start( "lambda_tf2_milkeffect" )
                            net.WriteEntity( ent )
                        net.Broadcast()
                    end
                elseif !ent.l_TF_MilkEffect then
                    net.Start( "lambda_tf2_milkeffect" )
                        net.WriteEntity( ent )
                    net.Broadcast()

                    ent.l_TF_MilkEffect = true
                end
            end

            local bleedInfos = ent.l_TF_BleedInfo
            if bleedInfos and #bleedInfos > 0 then
                if isDead then
                    table_Empty( bleedInfos )
                else
                    for index, info in ipairs( bleedInfos ) do
                        if !info.PermamentBleeding and CurTime() >= info.ExpireTime then
                            table_remove( bleedInfos, index )
                        elseif CurTime() >= info.BleedingTime then
                            info.BleedingTime = ( CurTime() + 0.5 )

                            local attacker = info.Attacker
                            if !IsValid( attacker ) then attacker = Entity( 0 ) end

                            local weapon = info.Weapon
                            if !IsValid( weapon ) then weapon = attacker end

                            local dmginfo = DamageInfo()
                            dmginfo:SetAttacker( attacker )
                            dmginfo:SetInflictor( weapon )
                            dmginfo:SetDamage( info.BleedDmg )
                            dmginfo:SetDamageType( DMG_SLASH )
                            dmginfo:SetDamagePosition( ent:WorldSpaceCenter() + VectorRand( -5, 5 ) )
                            dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BLEEDING )

                            ent:TakeDamageInfo( dmginfo )
                        end
                    end
                end
            end

            if ent.l_TF_IsBurning then
                if isDead or CurTime() > ent.l_TF_FlameRemoveTime or waterLvl >= 2 then
                    LAMBDA_TF2:RemoveBurn( ent )
                else
                    if !ent:IsOnFire() then
                        ent:Ignite( ( ent.l_TF_FlameRemoveTime - CurTime() ), 0 )
                    end

                    if CurTime() >= ent.l_TF_FlameBurnTime then
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
                        ent.l_TF_FlameBurnTime = ( CurTime() + 0.5 )
                    end
                end
            end
        end
    end

    local function OnCreateEntityRagdoll( owner, ragdoll )
        if owner:GetNW2Bool( "lambda_tf2_canbedecapitated", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ragdoll:GetVelocity() * 5 )
        end
    end

    local function OnEntityRemoved( ent )
        local loopingSnds = ent.l_TF_LoopingSounds
        if loopingSnds then
            for _, snd in ipairs( loopingSnds ) do
                if snd then snd:Stop(); snd = NULL end
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

    hook.Add( "EntityTakeDamage", "LambdaTF2_OnEntityTakeDamage", OnEntityTakeDamage )
    hook.Add( "PostEntityTakeDamage", "LambdaTF2_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
    hook.Add( "Think", "LambdaTF2_OnServerThink", OnServerThink )
    hook.Add( "CreateEntityRagdoll", "LambdaTF2_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
    hook.Add( "EntityRemoved", "LambdaTF2_OnEntityRemoved", OnEntityRemoved )
    hook.Add( "ScalePlayerDamage", "LambdaTF2_OnScalePlayerDamage", OnScaleEntityDamage )
    hook.Add( "ScaleNPCDamage", "LambdaTF2_OnScaleNPCDamage", OnScaleEntityDamage )
    hook.Add( "PlayerInitialSpawn", "LambdaTF2_OnPlayerInitialSpawn", OnEntityCreated )

end