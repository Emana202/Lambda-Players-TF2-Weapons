local IsValid = IsValid
local ismatrix = ismatrix
local net = net
local SimpleTimer = timer.Simple
local random = math.random
local emptyFunc = function() end
local CreateParticleSystem = CreateParticleSystem
local CreateClientside = ents.CreateClientside
local hook_Add = hook.Add
local hook_Remove = hook.Remove

local headGibMdl = "models/lambdaplayers/tf2/gibs/humanskull.mdl"
local headGibAng = Angle( 90, 0, -90 )

local critMat = "lambdaplayers/models/tf2/criteffects/crit"

LAMBDA_TF2 = LAMBDA_TF2 or {}

CRIT_NONE = 0
CRIT_MINI = 1
CRIT_FULL = 2

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

    if CLIENT and target.IsLambdaPlayer then
        local ragdoll = target.ragdoll
        if !IsValid( ragdoll ) then return end
        target = ragdoll
    end

    local headBone = target:LookupBone( "ValveBiped.Bip01_Head1" )
    if !headBone then return end

    local decapitatedBones = { headBone }
    target:ManipulateBoneScale( headBone, vector_origin )
    ShrinkChildBones( target, headBone, decapitatedBones )

    if effects then
        target:EmitSound( ")player/flow.wav", nil, nil, nil, CHAN_STATIC )

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
                if !IsValid( bloodEffect ) or !IsValid( target ) then 
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

if ( CLIENT ) then 
    
    local LocalPlayer = LocalPlayer
    local killiconClr = Color( 255, 80, 0, 255 )
    local killIconBleed = Color( 255, 0, 0 )

    killicon.Add( "lambdaplayers_weaponkillicons_tf2_backstab", "lambdaplayers/killicons/icon_tf2_backstab", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_headshot", "lambdaplayers/killicons/icon_tf2_headshot", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_caber_explosion", "lambdaplayers/killicons/icon_tf2_caber", killiconClr )
    killicon.Add( "lambdaplayers_weaponkillicons_tf2_sandman_baseball", "lambdaplayers/killicons/icon_tf2_sandman_ball", killiconClr )
    
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

    local critHitData = {
        [ CRIT_FULL ] = { "crit_text", {
            "player/crit_hit.wav",
            "player/crit_hit2.wav",
            "player/crit_hit3.wav",
            "player/crit_hit4.wav",
            "player/crit_hit5.wav"
        } },
        [ CRIT_MINI ] = { "minicrit_text", {
            "player/crit_hit_mini.wav",
            "player/crit_hit_mini2.wav",
            "player/crit_hit_mini3.wav",
            "player/crit_hit_mini4.wav",
            "player/crit_hit_mini5.wav"
        } }
    }

    net.Receive( "lambda_tf2_criteffects", function()
        local receiver = net.ReadEntity()
        if ( CurTime() - receiver.l_TF_LastCritEffectTime ) <= ( RealFrameTime() * 2 ) then return end
        
        local critType = net.ReadUInt( 2 )
        local critData = critHitData[ critType ]

        local textPos = net.ReadVector()
        local critPart = CreateParticleSystem( Entity( 0 ), critData[ 1 ], PATTACH_WORLDORIGIN, 0, textPos )

        receiver.l_TF_LastCritEffectTime = CurTime()
        receiver:EmitSound( critData[ 2 ][ random( #critData[ 2 ] ) ], 80, nil, nil, CHAN_STATIC )

        local ply = LocalPlayer()
        critPart:SetShouldDraw( ply != receiver )

        if ply == receiver and critType == CRIT_FULL then
            local lethal = net.ReadBool()
            if lethal then receiver:EmitSound( "player/crit_received" .. random( 1, 3 ) .. ".wav", 80, random( 95, 105 ), nil, CHAN_STATIC ) end
        end
    end )

    net.Receive( "lambda_tf2_decapitate_csragdoll", function()
        LAMBDA_TF2:DecapitateHead( net.ReadEntity(), net.ReadBool(), net.ReadVector() )
    end )

    net.Receive( "lambda_tf2_stuneffect", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local stunnedEffect = ent.l_TF_StunnedEffect
        if IsValid( stunnedEffect ) then
            stunnedEffect:StopEmission()
            ent.l_TF_StunnedEffect = nil
            return 
        end

        stunnedEffect = CreateParticleSystem( ent, "conc_stars", PATTACH_ABSORIGIN_FOLLOW, 0, ( vector_up * 80 ) )
        if IsValid( stunnedEffect ) then ent.l_TF_StunnedEffect = stunnedEffect end
    end )

    net.Receive( "lambda_tf2_urineeffect", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local urineEffect = ent.l_TF_UrineEffect
        if IsValid( urineEffect ) then
            urineEffect:StopEmission()
            ent.l_TF_UrineEffect = nil
            return
        end

        urineEffect = CreateParticleSystem( ent, "peejar_drips", PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        if !IsValid( urineEffect ) then return end

        urineEffect:AddControlPoint( 1, ent, PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        ent.l_TF_UrineEffect = urineEffect
    end )

    net.Receive( "lambda_tf2_milkeffect", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local milkEffect = ent.l_TF_MilkEffect
        if IsValid( milkEffect ) then
            milkEffect:StopEmission()
            ent.l_TF_MilkEffect = nil
            return
        end

        milkEffect = CreateParticleSystem( ent, "peejar_drips_milk", PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        if !IsValid( milkEffect ) then return end

        milkEffect:AddControlPoint( 1, ent, PATTACH_ABSORIGIN_FOLLOW, 0, vector_origin )
        ent.l_TF_MilkEffect = milkEffect
    end )

    net.Receive( "lambda_tf2_medigun_chargeeffect", function()
        local medigun = net.ReadEntity()
        if !IsValid( medigun ) then return end

        local charged = net.ReadBool()
        local chargeEffect = medigun.l_TF_ChargeEffect
        if charged then
            if !IsValid( chargeEffect ) then
                chargeEffect = CreateParticleSystem( medigun, "medicgun_invulnstatus_fullcharge_" .. ( net.ReadUInt( 3 ) == 2 and "blue" or "red" ), PATTACH_POINT_FOLLOW, medigun:LookupAttachment( "muzzle" ) )
                medigun.l_TF_ChargeEffect = chargeEffect
            end
        elseif IsValid( chargeEffect ) then
            chargeEffect:StopEmission()
            medigun.l_TF_ChargeEffect = nil
        end
    end )

    net.Receive( "lambda_tf2_medigun_beameffect", function()
        local medigun = net.ReadEntity()
        if !IsValid( medigun ) then return end

        local beam = medigun.l_TF_BeamEffect
        local sparks = medigun.l_TF_KritzkriegEffect
        local healTarget = net.ReadEntity()

        if !IsValid( healTarget ) then
            if IsValid( beam ) then
                beam:StopEmission()
                medigun.l_TF_BeamEffect = nil
                medigun.l_TF_BeamEffectCharged = false
            end

            if IsValid( sparks ) then
                sparks:StopEmission()
                medigun.l_TF_KritzkriegEffect = nil
            end

            return
        end

        local beamClr = net.ReadUInt( 3 )
        local charged = net.ReadBool()
        local isKritzkrieg = net.ReadBool()

        local sparks = medigun.l_TF_KritzkriegEffect
        if isKritzkrieg == true then
            if !IsValid( sparks ) then
                sparks = CreateParticleSystem( medigun, "medicgun_beam_attrib_overheal_" .. ( beamClr == 2 and "blue" or "red" ), PATTACH_POINT_FOLLOW, medigun:LookupAttachment( "muzzle" ) )
                if IsValid( sparks ) then
                    sparks:AddControlPoint( 1, healTarget, PATTACH_ABSORIGIN_FOLLOW, 0, vector_up * 48 )
                    medigun.l_TF_KritzkriegEffect = sparks
                end
            end
        elseif IsValid( sparks ) then
            sparks:StopEmission()
            medigun.l_TF_KritzkriegEffect = nil
        end

        if !IsValid( beam ) or medigun.l_TF_BeamEffectCharged != charged then
            if medigun.l_TF_BeamEffectCharged != charged and IsValid( beam ) then beam:StopEmission() end

            beam = CreateParticleSystem( medigun, "medicgun_beam_" .. ( beamClr == 2 and "blue" or "red" ) .. ( charged and "_invun" or "" ), PATTACH_POINT_FOLLOW, medigun:LookupAttachment( "muzzle" ) )
            if IsValid( beam ) then
                beam:AddControlPoint( 1, healTarget, PATTACH_ABSORIGIN_FOLLOW, 0, vector_up * 48 )
                medigun.l_TF_BeamEffect = beam
                medigun.l_TF_BeamEffectCharged = charged
            end
        end
    end )

    local function OnCreateClientsideRagdoll( owner, ragdoll )
        if owner:GetNW2Bool( "lambda_tf2_canbedecapitated", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ( ragdoll:GetVelocity() * 5 ) )
        end
    end

    local function PostProcessingsEffects()
        local ply = LocalPlayer()
        
        if ply:GetNW2Bool( "lambda_tf2_invulnerable", false ) then
            local color = ply:GetNW2String( "lambda_tf2_invulnerabilitycolor", "red" )
            DrawMaterialOverlay( "effects/invuln_overlay_" .. color, 0 )
        end

        if ply:GetNW2Bool( "lambda_tf2_burning", false ) then
            DrawMaterialOverlay( "effects/imcookin", 0 )
        end

        if ply:GetNW2Bool( "lambda_tf2_bleeding", false ) then
            DrawMaterialOverlay( "effects/bleed_overlay", 0 )
        end

        if IsValid( ply.l_TF_UrineEffect ) then
            DrawMaterialOverlay( "effects/jarate_overlay", 0 )
        end
    end

    hook_Add( "PostDrawViewModel", "LambdaTF2_PostDrawViewModel", function( vm, ply, wep )
        local mat = vm:GetMaterial()
        local critBoost = ply:GetNW2Int( "lambda_tf2_critboost", CRIT_NONE )
        if critBoost == CRIT_NONE then
            if vm.l_TF_PreCritMat then 
                vm:SetMaterial( vm.l_TF_PreCritMat )
                vm.l_TF_PreCritMat = nil
            end
        elseif !vm.l_TF_PreCritMat then
            vm.l_TF_PreCritMat = mat
            vm:SetMaterial( critMat )
        end
    end )

    hook_Add( "RenderScreenspaceEffects", "LambdaTF2_EffectPostProcessings", PostProcessingsEffects )
    hook_Add( "CreateClientsideRagdoll", "LambdaTF2_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )

    hook_Add( "OnEntityCreated", "LambdaTF2_OnEntityCreated", function( ent )
        if !IsValid( ent ) then return end
        ent.l_TF_LastCritEffectTime = CurTime()
    end )

    local minicritVec = Vector( 1, 2, 2 )
    matproxy.Add( {
        name = "LambdaWeaponModelGlowColor",
        init = function( self, mat, values )
            self.ResultTo = values.resultvar
        end,
        bind = function( self, mat, ent )
            if !IsValid( ent ) then return end
    
            local owner = ent:GetOwner()
            if !IsValid( owner ) then return end

            local critBoost = owner:GetNW2Int( "lambda_tf2_critboost", CRIT_NONE )
            if critBoost == CRIT_NONE then return end

            local col
            if critBoost == CRIT_MINI then
                col = minicritVec
            else
                col = owner:GetPlayerColor()
            end

            mat:SetVector( self.ResultTo, col )
        end
    } )
end

local allowRandomCrits = CreateLambdaConvar( "lambdaplayers_tf2_allowrandomcrits", 1, true, false, false, "If the weapons from TF2 should have a chance to earn a random crit", 0, 1, { type = "Bool", name = "Allow Random Crits", category = "TF2 Stuff" } )
local alwaysCrit = CreateLambdaConvar( "lambdaplayers_tf2_alwayscrit", 0, true, false, false, "If the weapons from TF2 should have always fire a crit shot", 0, 1, { type = "Bool", name = "Always Crit", category = "TF2 Stuff" } )
local shieldSpawnChance = CreateLambdaConvar( "lambdaplayers_tf2_shieldspawnchance", 10, true, false, false, "The chance that the next spawned Lambda Player will have a random charge shield equipped with them. Note that the Demoman's melee weapons have their own chance instead of this", 0, 100, { type = "Slider", decimals = 0, name = "Shield Spawn Chance", category = "TF2 Stuff" } )
local deathAnimChance = CreateLambdaConvar( "lambdaplayers_tf2_deathanimchance", 25, true, false, false, "The chance that Lambda Player will play a unique death animation when after dying from a specific TF2 weapon", 0, 100, { type = "Slider", decimals = 0, name = "Death Animation Chance", category = "TF2 Stuff" } )
local alwaysUseSchadenfreude = CreateLambdaConvar( "lambdaplayers_tf2_alwaysuseschadenfreude", 0, true, false, false, "If Lambda Players should always use play the Schadenfreude taunt when laughing instead of when holding a TF2 weapon", 0, 1, { type = "Bool", name = "Always Use Schadenfreude", category = "TF2 Stuff" } )
local schadenfreudeUseClassLaughter = CreateLambdaConvar( "lambdaplayers_tf2_schadenfreudeuseclasslaughter", 0, true, false, false, "If Lambda Players using Schadenfreude should also play the laugh that animation belongs to alongside their own laughter", 0, 1, { type = "Bool", name = "Schadenfreude Uses Class-Specific Laughter", category = "TF2 Stuff" } )
local randomRechargeableItemChance = CreateLambdaConvar( "lambdaplayers_tf2_randomrechargeablechance", 10, true, false, false, "The chance that Lambda Player will have a random rechargeable item in their inventory that they can use if needed after their initial spawn. For example, Jarate, Sandvich, Crit-a-Cola, etc.", 0, 100, { type = "Slider", decimals = 0, name = "Random Rechargeable Item Chance", category = "TF2 Stuff" } )
local inventoryItemLimit = CreateLambdaConvar( "lambdaplayers_tf2_inventoryitemlimit", 1, true, false, false, "How many items can Lambda Player carry in their inventory?", 0, 4, { type = "Slider", decimals = 0, name = "Inventory Limit", category = "TF2 Stuff" } )

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
    TF_DMG_CUSTOM_BASEBALL                  = 22
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

    local CurTime = CurTime
    local coroutine_yield = coroutine.yield
    local coroutine_wait = coroutine.wait
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
    local floor = math.floor
    local Remap = math.Remap
    local ents_GetAll = ents.GetAll
    local ipairs = ipairs
    local RandomPairs = RandomPairs
    local isvector = isvector
    local FrameTime = FrameTime
    local DamageInfo = DamageInfo
    local StartsWith = string.StartWith
    local SafeRemoveEntity = SafeRemoveEntity
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
    local ignorePlys = GetConVar( "ai_ignoreplayers" )

    util.AddNetworkString( "lambda_tf2_stopnamedparticle" )
    util.AddNetworkString( "lambda_tf2_removecsragdoll" )
    util.AddNetworkString( "lambda_tf2_criteffects" )
    util.AddNetworkString( "lambda_tf2_decapitate_csragdoll" )
    util.AddNetworkString( "lambda_tf2_decapitate_sendgibdata" )
    util.AddNetworkString( "lambda_tf2_stuneffect" )
    util.AddNetworkString( "lambda_tf2_urineeffect" )
    util.AddNetworkString( "lambda_tf2_milkeffect" )
    util.AddNetworkString( "lambda_tf2_medigun_beameffect" )
    util.AddNetworkString( "lambda_tf2_medigun_chargeeffect" )
    
    net.Receive( "lambda_tf2_decapitate_sendgibdata", function()
        LAMBDA_TF2:CreateHeadGib( net.ReadVector(), net.ReadAngle(), net.ReadVector() )
    end )

    local function EntityThink( ent )
        local isDead = ( ent:Health() <= 0 or ( ent.IsLambdaPlayer or ent:IsPlayer() ) and !ent:Alive() )
    
        if ent.l_TF_HasOverheal then
            local curHealth = ent:Health()
            local maxHealth = ent:GetMaxHealth()
    
            if isDead or curHealth <= maxHealth then
                ent.l_TF_HasOverheal = false
            elseif CurTime() > ent.l_TF_OverhealDecreaseStartT then
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
            if ( isDead or CurTime() > ent.l_TF_CoveredInUrine or ent:WaterLevel() >= 2 ) then
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
            if ( isDead or CurTime() > ent.l_TF_CoveredInMilk or ent:WaterLevel() >= 2 ) then
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
        if bleedInfos then
            ent:SetNW2Bool( "lambda_tf2_bleeding", ( #bleedInfos > 0 ) )
    
            if #bleedInfos > 0 then
                if isDead or CurTime() <= ent.l_TF_InvulnerabilityTime then
                    LAMBDA_TF2:RemoveBleeding( ent )
                else
                    for index, info in ipairs( bleedInfos ) do
                        if !info.PermamentBleeding and CurTime() >= info.ExpireTime then
                            table_remove( bleedInfos, index )
                        elseif CurTime() >= info.BleedingTime then
                            info.BleedingTime = ( CurTime() + 0.5 )
    
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
    
        if ent.l_TF_IsBurning then
            if isDead or CurTime() > ent.l_TF_FlameRemoveTime or ent:WaterLevel() >= 2 or CurTime() <= ent.l_TF_InvulnerabilityTime then
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
        ent:SetNW2Bool( "lambda_tf2_burning", ent.l_TF_IsBurning )
    
        if ent.l_TF_InvulnerabilityTime then 
            local invulnMat = "lambdaplayers/models/tf2/ubercharge/ubercharge_" .. ( ent.l_TF_InvulnerabilityColor or "red" )
            
            if CurTime() <= ent.l_TF_InvulnerabilityTime then
                ent:SetMaterial( invulnMat )
    
                for _, child in ipairs( ent:GetChildren() ) do
                    if !IsValid( child ) or child:GetMaterial() == invulnMat then continue end
                    if ent.IsLambdaPlayer and child == ent:GetWeaponENT() and ent:IsWeaponMarkedNodraw() then continue end
                    child:SetMaterial( invulnMat )
                end
            elseif ent:GetMaterial() == invulnMat then
                ent:SetMaterial( "" )
    
                for _, child in ipairs( ent:GetChildren() ) do
                    if !IsValid( child ) or child:GetMaterial() != invulnMat then continue end
                    if ent.IsLambdaPlayer and child == ent:GetWeaponENT() and ent:IsWeaponMarkedNodraw() then continue end
                    child:SetMaterial( "" )
                end
            end
            
            ent:SetNW2Bool( "lambda_tf2_invulnerable", ( CurTime() <= ent.l_TF_InvulnerabilityTime ) )
            ent:SetNW2String( "lambda_tf2_invulnerabilitycolor", ent.l_TF_InvulnerabilityColor )
        end

        if ent.l_TF_IsStunned then
            if isDead or CurTime() >= ent.l_TF_IsStunned then
                ent.l_TF_IsStunned = false

                if ent.IsLambdaPlayer and ent.l_TF_StunIsMoonshot then
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
                    local speedData = ent.l_TF_PreStunSpeedData                    
                    ent:SetWalkSpeed( speedData[ 1 ] )
                    ent:SetRunSpeed( speedData[ 2 ] )
                    ent:SetDuckSpeed( speedData[ 3 ] )
                    ent:SetSlowWalkSpeed( speedData[ 4 ] )

                    if ent.l_TF_StunIsMoonshot then ent:Freeze( false ) end
                end

                net.Start( "lambda_tf2_stuneffect" )
                    net.WriteEntity( ent )
                net.Broadcast()
            else
                if ent.IsLambdaPlayer and ent.l_TF_StunIsMoonshot then
                    ent:CancelMovement()

                    if CurTime() >= ent.l_TF_StunStateChangeT then
                        if ent.l_TF_JustGotStunned then
                            local beginAnim, stateTime = ent:LookupSequence( "tf_stun_begin" )
                            
                            ent:AddGestureSequence( beginAnim )

                            ent.l_TF_JustGotStunned = false
                            ent.l_TF_StunStateChangeT = ( CurTime() + stateTime )
                        else
                            local middleAnim, stateTime = ent:LookupSequence( "tf_stun_middle" )

                            ent:SetSequence( middleAnim )
                            ent:ResetSequenceInfo()
                            ent:SetCycle( 0 )
                            
                            ent.l_UpdateAnimations = false
                            ent.l_TF_StunStateChangeT = ( CurTime() + stateTime )
                        end
                    end
                end
            end
        end

        if ent.l_TF_CritBoosts then
            local boostType = CRIT_NONE
            for boostName, boost in pairs( ent.l_TF_CritBoosts ) do
                if isDead or CurTime() >= boost.Duration then
                    ent.l_TF_CritBoosts[ boostName ] = nil
                else
                    local critType = boost.CritType
                    if critType > boostType then boostType = critType end
                end
            end
        
            local boostSnd = ent.l_TF_CritBoostSound
            if boostType != CRIT_NONE then
                if boostType != ent.l_TF_LastCritBoost then
                    if ent.IsLambdaPlayer then
                        if !ent:IsWeaponMarkedNodraw() then
                            ent:GetWeaponENT():SetMaterial( critMat )
                        end
                    else
                        local weapon = ent.GetActiveWeapon
                        if weapon then weapon = weapon( ent ) end
                        if IsValid( weapon ) then weapon:SetMaterial( critMat ) end
                    end
                end

                if !boostSnd then
                    boostSnd = LAMBDA_TF2:CreateSound( ent, "weapons/crit_power.wav" )
                    ent.l_TF_CritBoostSound = boostSnd
                end

                if boostSnd and !boostSnd:IsPlaying() then
                    boostSnd:PlayEx( 0.5, 100 )
                end
            else
                if boostType != ent.l_TF_LastCritBoost then
                    if ent.IsLambdaPlayer then
                        local weapon = ent:GetWeaponENT()
                        local mat = weapon:GetMaterial()
                        if !ent:IsWeaponMarkedNodraw() and ( mat == critMat ) then
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
                end

                if boostSnd then
                    boostSnd:Stop()
                    ent.l_TF_CritBoostSound = nil
                end
            end

            ent.l_TF_LastCritBoost = boostType
            ent:SetNW2Int( "lambda_tf2_critboost", boostType )
        end
    end

    local function OnEntityCreated( ent )
        SimpleTimer( 0, function()
            if !IsValid( ent ) then return end

            ent.l_TF_HasOverheal = false
            ent.l_TF_HealFraction = 0

            ent.l_TF_LoopingSounds = {}

            ent:CallOnRemove( "LambdaTF2_StopLoopingSounds" .. ent:GetCreationID(), function()
                local loopingSnds = ent.l_TF_LoopingSounds
                if !loopingSnds then return end

                for _, snd in pairs( loopingSnds ) do
                    if snd then snd:Stop(); snd = nil end
                end
            end )

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

            ent.l_TF_LastTakeDamageTime = 0

            ent.l_TF_HasOverheal = false
            ent.l_TF_HealFraction = 0
            ent.l_TF_OverhealDecreaseStartT = 0
            ent.l_TF_HealRateMultiplier = 1.0
            ent.l_TF_InvulnerabilityTime = 0
            ent.l_TF_InvulnerabilityColor = "red"

            ent.l_TF_IsStunned = false
            ent.l_TF_JustGotStunned = true
            ent.l_TF_StunStateChangeT = 0
            ent.l_TF_PreStunState = nil

            ent.l_TF_CritBoosts = {}
            ent.l_TF_LastCritBoost = CRIT_NONE

            ent:SetNW2Bool( "lambda_tf2_canbedecapitated", false )
            ent:SetNW2Bool( "lambda_tf2_bleeding", false )
            ent:SetNW2Bool( "lambda_tf2_burning", false )
            ent:SetNW2Bool( "lambda_tf2_invulnerable", false )
            ent:SetNW2String( "lambda_tf2_invulnerabilitycolor", ent.l_TF_InvulnerabilityColor )
            ent:SetNW2Int( "lambda_tf2_critboost", CRIT_NONE )

            if LAMBDA_TF2:IsValidCharacter( ent, false ) then
                local hookName = "LambdaTF2_EntityThink_" .. ent:GetClass() .. "_" .. ent:GetCreationID()
                hook_Add( "Think", hookName, function() 
                    if !IsValid( ent ) then hook_Remove( "Think", hookName ) return end
                    EntityThink( ent )
                end )
            end
        end )
    end

    hook_Add( "OnEntityCreated", "LambdaTF2_OnEntityCreated", OnEntityCreated )

    local shotgunCockingTimings = {
        { 0.342857, 0.485714 },
        { 0.285714, 0.428571 },
        { 0.4, 0.533333 },
        { 0.233333, 0.366667 }
    }
    local shotgunReloadInterruptCond = function( lambda, weapon )
        return ( lambda.l_Clip > 0 and random( 1, 3 ) != 1 and lambda:InCombat() and lambda:IsInRange( lambda:GetEnemy(), 512 ) and lambda:CanSee( lambda:GetEnemy() ) )
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

    function LAMBDA_TF2:WeaponAttack( lambda, weapon, target )
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

            local isCrit = weapon:CalcIsAttackCriticalHelper()
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
            
            local isCriticalHit = weapon:CalcIsAttackCriticalHelper()
            local fireSnd = weapon:GetWeaponAttribute( "Sound", ")weapons/cbar_miss1.wav" )
            if fireSnd then
                local critSnd = weapon:GetWeaponAttribute( "CritSound", ")weapons/cbar_miss1_crit.wav" )
                if critSnd and isCriticalHit then fireSnd = critSnd end
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
                    if isCriticalHit then 
                        dmgTypes = ( dmgTypes + DMG_CRITICAL ) 
                    elseif lambda.l_TF_NextMeleeCrit == CRIT_MINI then 
                        dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
                    end
                    dmginfo:SetDamageType( dmgTypes )

                    local hitAng = ( ( hitPos - lambda:GetForward() * ( hitRange and 1 or 0 ) ) - eyePos ):Angle()
                    dmginfo:SetDamageForce( hitAng:Forward() * ( damage * 300 ) * LAMBDA_TF2:GetPushScale() * ( 1 / damage * 80 ) )
                    
                    local preHitCallback = weapon:GetWeaponAttribute( missed and "OnMiss" or "PreHitCallback" )
                    if preHitCallback then preHitCallback( lambda, weapon, target, dmginfo ) end

                    if !missed then target:TakeDamageInfo( dmginfo ) end
                    lambda.l_TF_NextMeleeCrit = CRIT_NONE
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

        target:RemoveFlags( FL_ONGROUND )

        if target:IsNextBot() then
            target.loco:Jump()
            local entVel = target.loco:GetVelocity(); entVel.z = 0
            target.loco:SetVelocity( target.loco:GetVelocity() + vecForce )
        else
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
        if LAMBDA_TF2:GetCritBoost( owner ) == CRIT_FULL then return true end

        local remapCritMul = Remap( owner.l_TF_CritMult, 0, 255, 1, 4 )
        local randChance = random( 0, 9999 )

        if self:GetWeaponAttribute( "IsMelee" ) then
            if owner.l_TF_NextMeleeCrit == CRIT_FULL then return true end
            if !self:GetWeaponAttribute( "RandomCrits", true ) or !allowRandomCrits:GetBool() then return false end
            return ( randChance < ( TF_DAMAGE_CRIT_CHANCE_MELEE * remapCritMul * 9999 ) )
        end

        local isRapidFire = self:GetWeaponAttribute( "UseRapidFireCrits" )
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

        weapon:SetSkin( 0 )
        for _, bg in ipairs( weapon:GetBodyGroups() ) do
            weapon:SetBodygroup( bg.id, 0 )
        end

        net.Start( "lambdaplayers_serversideragdollplycolor" )
            net.WriteEntity( weapon )
            net.WriteVector( lambda:GetPlyColor() )
        net.Broadcast()

        weapon.l_TF_CritTime = CurTime()
        weapon.l_TF_LastFireTime = CurTime()
        weapon.l_TF_LastRapidFireCritCheckT = CurTime()

        weapon.SetWeaponAttribute = SetWeaponAttribute
        weapon.GetWeaponAttribute = GetWeaponAttribute
        weapon.CalcIsAttackCriticalHelper = CalcIsAttackCriticalHelper
    end

    function LAMBDA_TF2:Stun( target, time, moonshot )
        local expireTime = ( CurTime() + time )
        if !target.l_TF_IsStunned or expireTime > target.l_TF_IsStunned or moonshot then
            target.l_TF_IsStunned = expireTime
            target.l_TF_JustGotStunned = true
            target.l_TF_StunIsMoonshot = ( moonshot or false ) 

            if target.IsLambdaPlayer then
                target.l_TF_PreStunState = target:GetState()
                if moonshot then target:SetState( "Stunned" ) end

                if target.l_TF_Shield_IsCharging then
                    target.l_TF_Shield_IsCharging = false
                    target.l_TF_Shield_ChargeMeter = 0
                end

                target.l_nextspeedupdate = 0
            elseif target:IsPlayer() then
                local speedData ={
                    target:GetWalkSpeed(),
                    target:GetRunSpeed(),
                    target:GetDuckSpeed(),
                    target:GetSlowWalkSpeed()
                }
                target.l_TF_PreStunSpeedData = speedData
                
                target:SetWalkSpeed( speedData[ 1 ] * 0.75 )
                target:SetRunSpeed( speedData[ 2 ] * 0.75 )
                target:SetDuckSpeed( speedData[ 3 ] * 0.75 )
                target:SetSlowWalkSpeed( speedData[ 4 ] * 0.75 )

                if moonshot then target:Freeze( true ) end
            end
            
            net.Start( "lambda_tf2_stuneffect" )
                net.WriteEntity( target )
            net.Broadcast()
        end

        if moonshot then
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

    function LAMBDA_TF2:GetMaxBuffedHealth( ent, ratio )
        ratio = ( ratio or 1.5 )
        return floor( ( ( ent:GetMaxHealth() * ratio ) / 5 ) * 5 )
    end

    function LAMBDA_TF2:GetMediGunHealRate( medic, target )
        local healRate = ( 24 * LAMBDA_TF2:RemapClamped( ( CurTime() - target.l_TF_LastTakeDamageTime ), 10, 15, 1, 3 ) )
        healRate = ( healRate * medic.l_TF_MedigunHealRateMultiplier )
        healRate = ( healRate * target.l_TF_HealRateMultiplier )
        if target.l_TF_IsBurning then  healRate = ( healRate * 0.5 ) end
        return ( 1 / healRate )
    end

    function LAMBDA_TF2:GiveHealth( target, amount, maxHeal )
        local maxHealth = target:GetMaxHealth()
        local maxGive = ( maxHeal == nil and LAMBDA_TF2:GetMaxBuffedHealth( target ) or ( maxHeal == false and maxHealth or maxHeal ) )

        local curHealth = target:Health()
        target.l_TF_OverhealDecreaseStartT = ( CurTime() + 0.1 )
        if curHealth >= maxGive then return 0 end

        local preHP = target:Health()
        target:SetHealth( floor( min( curHealth + amount, maxGive ) ) )
        target.l_TF_HasOverheal = ( target:Health() > maxHealth )

        return ( target:Health() - preHP )
    end

    local shieldTbl = {
        { "models/lambdaplayers/tf2/weapons/w_targe.mdl", "lambdaplayers_weaponkillicons_tf2_chargintarge" },
        { "models/lambdaplayers/tf2/weapons/w_persian_shield.mdl", "lambdaplayers_weaponkillicons_tf2_splendidscreen" },
        { "models/lambdaplayers/tf2/weapons/w_wheel_shield.mdl", "lambdaplayers_weaponkillicons_tf2_tideturner" },
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

    function LAMBDA_TF2:AddCritBoost( ent, name, critType, duration, markForDeath )        
        ent.l_TF_CritBoosts[ name ] = {
            CritType = critType,
            Duration = ( CurTime() + duration ),
            MarkForDeathOnAttack = markForDeath
        }
    end

    function LAMBDA_TF2:RemoveCritBoost( ent, name )
        ent.l_TF_CritBoosts[ name ] = nil
    end

    function LAMBDA_TF2:GetCritBoost( ent, name )
        local critType = CRIT_NONE
        for critName, info in pairs( ent.l_TF_CritBoosts ) do
            if info.CritType > critType and ( !name or critName == name ) then
                critType = info.CritType
            end
        end
        return critType
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
        if istable( snds ) then snds = snds[ random( #snds ) ] end
        rocket:EmitSound( snds, 85, nil, nil, CHAN_WEAPON )
        rocket:Remove()
    end

    function LAMBDA_TF2:CreateRocketProjectile( pos, ang, owner, wepent, attributes )
        attributes = attributes or {}
        
        local rocket = ents_Create( "base_anim" )
        rocket:SetPos( pos )
        rocket:SetAngles( ang )
        rocket:SetModel( attributes.Model or "models/weapons/w_models/w_rocket.mdl" )
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
            ")lambdaplayers/tf2/explode1.mp3",
            ")lambdaplayers/tf2/explode2.mp3",
            ")lambdaplayers/tf2/explode3.mp3"
        } )
        rocket.l_TF_LambdaWeapon = wepent
        rocket.l_TF_OnDealDamage = attributes.OnDealDamage

        rocket.IsLambdaWeapon = true
        rocket.l_killiconname = ( attributes.KillIcon or wepent.l_killiconname )

        local critType = LAMBDA_TF2:GetCritBoost( owner )
        if wepent:CalcIsAttackCriticalHelper() then critType = CRIT_FULL end
        rocket.l_TF_ExplodeCrit = critType

        if critType != CRIT_NONE then
            rocket:SetMaterial( critMat )

            if critType == CRIT_FULL then
                ParticleEffectAttach( "critical_rocket_red", PATTACH_POINT_FOLLOW, rocket, 1 )
                ParticleEffectAttach( "critical_rocket_blue", PATTACH_POINT_FOLLOW, rocket, 1 )
            end
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

    function LAMBDA_TF2:IsBurning( ent )
        return ( ent.l_TF_IsBurning or ent:IsOnFire() )
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
        return ( dmginfo:IsDamageType( DMG_CRITICAL ) and CRIT_FULL or ( dmginfo:IsDamageType( DMG_MINICRITICAL ) and CRIT_MINI or CRIT_NONE ) )
    end

    function LAMBDA_TF2:AddInventoryCooldown( lambda, name )
        name = ( name or lambda:GetWeaponName() )
        local wepInv = lambda.l_TF_Inventory[ name ]
        if !wepInv or !wepInv.IsReady then return end
        wepInv.IsReady = false
        wepInv.NextUseTime = ( CurTime() + LAMBDA_TF2.InventoryItems[ name ].Cooldown ) 
    end

    function LAMBDA_TF2:DecreaseInventoryCooldown( lambda, name, amount )
        name = ( name or lambda:GetWeaponName() )
        local wepInv = lambda.l_TF_Inventory[ name ]
        if !wepInv or wepInv.IsReady then return end
        wepInv.NextUseTime = ( wepInv.NextUseTime - amount ) 
    end

    function LAMBDA_TF2:IsBehindBackstab( ent, target )
        local vecToTarget = ( target:GetPos() - ent:GetPos() ); vecToTarget.z = 0; vecToTarget:Normalize()
        local vecOwnerForward = ent:GetForward(); vecOwnerForward.z = 0; vecOwnerForward:Normalize()
        local vecTargetForward = target:GetForward(); vecTargetForward.z = 0; vecTargetForward:Normalize()
        return ( vecToTarget:Dot( vecTargetForward ) > 0 and vecToTarget:Dot( vecOwnerForward ) > 0.5 and vecTargetForward:Dot( vecOwnerForward ) > -0.3 )
    end

    function LAMBDA_TF2:GetMedigunHealers( ent )
        local healers = {}
        local count = 0
        for _, lambda in ipairs( GetLambdaPlayers() ) do
            if !lambda.l_TF_HasMedigunEquipped or lambda.l_TF_Medigun_HealTarget != ent and !healers[ lambda.l_TF_Medigun_HealTarget ] then continue end
            healers[ lambda ] = true
            count = ( count + 1 )
        end
        return healers, count
    end

    ---

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

    local function Schadenfreude( self )
        local laughSnd, seqName = table_Random( tf2LaughAnims )
        local animIndex = self:LookupSequence( seqName )
        if animIndex > 0 then
            if !self.l_preventdefaultspeak then
                self:PlaySoundFile( "laugh" )
            end
            if schadenfreudeUseClassLaughter:GetBool() then
                self:EmitSound( laughSnd, 80, self:GetVoicePitch(), nil, CHAN_VOICE )
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
            coroutine_wait( receiverWaitT )

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
                coroutine_wait( initiatorWaitT )
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

    LAMBDA_TF2.InventoryItems = {
        [ "tf2_sandwich" ] = {
            Condition = function( lambda )
                return ( !lambda:InCombat() and !lambda:IsPanicking() and lambda:Health() <= ( lambda:GetMaxHealth() * Rand( 0.5, 0.8 ) ) )
            end,
            Cooldown = 30
        },
        [ "tf2_chocolate" ] = {
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( lambda:Health() < ( lambda:GetMaxHealth() * Rand( 0.5, 0.9 ) ) and !lambda:InCombat() and !lambda:IsPanicking() or lambda:InCombat() and !lambda:IsInRange( ene, 300 ) and !lambda:CanSee( ene ) and random( 1, 12 ) == 1 )
            end,
            Cooldown = 10
        },
        [ "tf2_jarate" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( random( 1, 4 ) == 1 and lambda:InCombat() and LAMBDA_TF2:GetCritBoost( lambda ) == CRIT_NONE and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
            end,
            Cooldown = 20 
        },
        [ "tf2_madmilk" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( random( 1, 4 ) == 1 and lambda:InCombat() and LAMBDA_TF2:GetCritBoost( lambda ) == CRIT_NONE and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
            end,
            Cooldown = 20 
        },
        [ "tf2_critacola" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( random( 1, 8 ) == 1 and lambda:InCombat() and LAMBDA_TF2:GetCritBoost( lambda ) == CRIT_NONE and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and ( !lambda:IsInRange( ene, 300 ) or !lambda:CanSee( ene ) ) )
            end,
            Cooldown = 30
        },
        [ "tf2_cleaver" ] = {             
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                local attackDist = lambda.l_CombatAttackRange
                if !attackDist then attackDist = ( lambda.l_HasMelee and 70 or 1000 ) end
                return ( random( 1, 4 ) == 1 and lambda:InCombat() and lambda:CanSee( ene ) and lambda:IsInRange( ene, 1500 ) and ( lambda.l_Clip == 0 or lambda:GetIsReloading() or !lambda:IsInRange( ene, attackDist ) or random( 1, 10 ) == 1 ) )
            end,
            Cooldown = 5.1
        },
        [ "tf2_bonk" ] = {             
            Condition = function( lambda )
                return ( lambda:IsPanicking() and ( !LambdaIsValid( lambda.l_RetreatTarget ) or !lambda:CanSee( lambda.l_RetreatTarget ) ) )
            end,
            Cooldown = 30
        }
    }

    function LAMBDA_TF2:LambdaMedigunAI( lambda )
        if !lambda:HookExists( "Tick", "TFMedicThink" ) then
            lambda:Hook( "Tick", "TFMedicThink", function()
                if lambda:GetState() != "HealWithMedigun" then return "end" end
                if lambda:IsDisabled() then return end

                if !lambda.l_TF_HasMedigunEquipped then
                    lambda:CancelMovement()
                    lambda:SetState( "Idle" )
                    return "end"
                end

                local healTarget = lambda.l_TF_Medigun_HealTarget
                local targetDead = ( !IsValid( healTarget ) or !LAMBDA_TF2:IsValidCharacter( healTarget ) )
                if targetDead or random( 1, ( ( healTarget.l_TF_HasMedigunEquipped or !lambda:IsInRange( healTarget, 768 ) or healTarget.IsLambdaPlayer and !healTarget:InCombat() or healTarget:Health() >= ( LAMBDA_TF2:GetMaxBuffedHealth( healTarget ) * 0.9 ) ) and 100 or 300 ) ) == 1 then
                    if IsValid( healTarget ) and targetDead then
                        local killer = healTarget.l_TF_Killer
                        if IsValid( killer ) and LAMBDA_TF2:IsValidCharacter( killer ) and random( 1, 100 ) <= lambda:GetCombatChance() then
                            if random( 1, 100 ) <= lambda:GetVoiceChance() then lambda:PlaySoundFile( "taunt" ) end
                            lambda:SetEnemy( killer )
                            lambda:SetState( "Combat" )
                            lambda:CancelMovement()

                            lambda.l_TF_SwitchedOffMedigun = lambda:GetWeaponName()
                            lambda:SwitchToLethalWeapon()
                        else
                            lambda:RetreatFrom()
                        end

                        return "end"
                    end

                    local woundedTarget = nil
                    local filter = lambda.l_TF_MedicTargetFilter
                    local ignorePly = ignorePlys:GetBool()
                    local healers = LAMBDA_TF2:GetMedigunHealers( lambda )
                    local targetSearchFunc = function( ent )
                        if !ent.IsLambdaPlayer and !ent:IsPlayer() or !ent:Alive() then return false end
                        if ent:IsPlayer() and ignorePly then return false end
                        if ent.l_TF_HasMedigunEquipped and healers[ ent ] then return false end
                        if filter and filter( lambda, ent ) == false then return false end
                        if LambdaTeams and LambdaTeams:AreTeammates( lambda, ent ) == false then return false end
                        
                        local hp = ent:Health()
                        if hp > ( ent:GetMaxHealth() / 2 ) and !lambda:CanSee( ent ) then return false end
                        if ent != healTarget and hp >= LAMBDA_TF2:GetMaxBuffedHealth( ent ) then return false end

                        if !targetDead then
                            if healTarget.IsLambdaPlayer and healTarget:InCombat() and ent == healTarget:GetEnemy() then return false end
                            if ent.IsLambdaPlayer and ent:InCombat() and ent:GetEnemy() == healTarget then return false end
                        end
        
                        if woundedTarget and woundedTarget != ent then
                            if lambda.IsFriendsWith then 
                                if lambda:IsFriendsWith( ent ) and !lambda:IsFriendsWith( woundedTarget ) then return false end
                                if lambda:IsFriendsWith( woundedTarget ) and !lambda:IsFriendsWith( ent ) then return false end
                            end

                            if LambdaTeams then 
                                if LambdaTeams:AreTeammates( lambda, ent ) == true and !LambdaTeams:AreTeammates( lambda, woundedTarget ) then return false end
                                if LambdaTeams:AreTeammates( lambda, woundedTarget ) == true and !LambdaTeams:AreTeammates( lambda, ent ) then return false end
                            end
                            
                            if ent.IsLambdaPlayer and woundedTarget.IsLambdaPlayer then 
                                if ent:InCombat() and !woundedTarget:InCombat() then return false end
                                if woundedTarget:InCombat() and !ent:InCombat() then return false end
                            end
                            
                            if hp > woundedTarget:Health() then return false end
                        end

                        woundedTarget = ent
                        return true
                    end
                    lambda:FindInSphere( nil, ( targetDead and 2000 or 1000 ), targetSearchFunc )

                    healTarget = woundedTarget
                    lambda.l_TF_Medigun_HealTarget = healTarget
                end

                if IsValid( healTarget ) then
                    if lambda:IsInRange( healTarget, 750 ) and lambda:CanSee( healTarget ) then lambda:LookTo( healTarget, 0.5 ) end
                    lambda:UseWeapon( healTarget )
    
                    local targetInCombat = ( ( CurTime() - healTarget.l_TF_LastTakeDamageTime ) <= 1 or healTarget.IsLambdaPlayer and healTarget:InCombat() and healTarget:IsInRange( healTarget:GetEnemy(), 1000 ) and healTarget:CanSee( healTarget:GetEnemy() ) )
    
                    if !lambda:IsInRange( healTarget, 250 ) or ( CurTime() - lambda.l_TF_LastTakeDamageTime ) <= 5 or targetInCombat then
                        lambda:SetRun( true )
                    elseif healTarget.IsLambdaPlayer then
                        lambda:SetRun( healTarget:GetRun() )
                    elseif healTarget:IsPlayer() then
                        lambda:SetRun( healTarget:IsSprinting() )
                    else
                        lambda:SetRun( false )
                    end
    
                    if lambda:IsInRange( healTarget, 150 ) and lambda:CanSee( healTarget ) then 
                        if ( CurTime() - lambda.l_TF_LastTakeDamageTime ) <= 5 or targetInCombat or lambda:IsInRange( healTarget, 50 ) then
                            lambda.l_movepos = ( lambda:GetPos() + Vector( random( -100, 100 ), random( -100, 100 ), 0 ) )
                        else
                            lambda:CancelMovement()
                        end
                    else
                        lambda:SetCrouch( false )
                        lambda.l_movepos = healTarget
                    end
    
                    if !lambda.l_TF_Medigun_ChargeReleased and lambda.l_TF_Medigun_ChargeReady and ( targetInCombat or ( CurTime() - lambda.l_TF_LastTakeDamageTime ) <= 1 ) then
                        lambda.l_TF_Medigun_ChargeReleased = true
                        lambda:EmitSound( lambda.l_TF_MedigunChargeReleaseSound, nil, nil, 0.5, CHAN_STATIC )
    
                        net.Start( "lambda_tf2_medigun_chargeeffect" )
                            net.WriteEntity( lambda:GetWeaponENT() )
                            net.WriteBool( true )
                            net.WriteUInt( lambda.l_TF_Medigun_BeamColor, 3 )
                        net.Broadcast()
    
                        if random( 1, 100 ) <= lambda:GetVoiceChance() then
                            lambda:PlaySoundFile( "taunt" )
                        end
    
                        if healTarget.IsLambdaPlayer and random( 1, 100 ) <= healTarget:GetVoiceChance() then
                            healTarget:PlaySoundFile( "taunt" )
                        end
                    end
                end
            end )
        end

        if lambda:GetState() == "HealWithMedigun" then
            local healTarget = lambda.l_TF_Medigun_HealTarget
            if IsValid( healTarget ) then 
                if !lambda:IsInRange( healTarget, 150 ) or !lambda:CanSee( healTarget ) then
                    lambda:MoveToPos( healTarget, { update = 0.33, tol = 12 } )
                end
            else
                lambda:MoveToPos( lambda:GetRandomPosition(), { autorun = false, run = false, callback = function()
                    if IsValid( lambda.l_TF_Medigun_HealTarget ) then return false end
                end} )
            end
        end
    end

    local function LambdaMedigunState( self )
        LAMBDA_TF2:LambdaMedigunAI( self )
    end

    local function OnLambdaInitialize( lambda )        
        lambda.l_TF_DamageEvents = {}
        lambda.l_TF_CritMult = 0
        lambda.l_TF_NextCritUpdateT = CurTime()

        local weapon = lambda.WeaponEnt
        if IsValid( weapon ) then weapon.l_TF_Owner = lambda end
        
        lambda.l_TF_Decapitations = 0
        lambda.l_TF_NextMeleeCrit = CRIT_NONE

        lambda.l_TF_Shield_IsCharging = false
        lambda.l_TF_Shield_PreChargeYawRate = lambda.loco:GetMaxYawRate()
        lambda.l_TF_Shield_ChargeMeter = 100
        lambda.l_TF_Shield_ChargeMeterFull = true
        lambda.l_TF_Shield_IsEquipped = false
        lambda.l_TF_Shield_Entity = NULL
        lambda.l_TF_Shield_CritBoosted = false
        lambda.l_TF_Shield_CritBoostSound = nil 

        lambda.l_TF_AtomicPunched = false
        lambda.l_TF_AtomicPunched_Trail = NULL
        lambda.l_TF_AtomicPunched_DamageTaken = 0
        lambda.l_TF_AtomicPunched_SlowdownScale = false
        lambda.l_TF_AtomicPunched_SlowdownTime = 0

        lambda.l_TF_DiamondbackCrits = 0
        lambda.l_TF_FrontierJusticeKills = 0
        lambda.l_TF_RevengeCrits = 0

        lambda.l_TF_IsUsingItem = false
        lambda.l_TF_Inventory = {}
        lambda.l_TF_NextInventoryCheckT = ( CurTime() + Rand( 0.1, 1.0 ) )
        lambda.l_TF_PreInventorySwitchWeapon = nil

        lambda.l_TF_InSpeedBoost = false
        lambda.l_TF_SpeedBoostTrail = NULL

        local invLimit = inventoryItemLimit:GetInt()
        if invLimit > 0 then
            local chance = randomRechargeableItemChance:GetInt()

            for i = 1, invLimit do
                if random( 1, 100 ) <= chance then
                    for name, data in RandomPairs( LAMBDA_TF2.InventoryItems ) do
                        if lambda.l_TF_Inventory[ name ] or !lambda:CanEquipWeapon( name ) then continue end
                        lambda.l_TF_Inventory[ name ] = { NextUseTime = CurTime(), IsReady = true }
                        break
                    end
                end
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
        
        lambda.l_TF_CrikeyMeter = 0
        lambda.l_TF_CrikeyMeterFull = false

        lambda.l_TF_ThrownBaseball = false

        lambda.l_TF_DalokohsBars = {}

        lambda.l_TF_HasMedigunEquipped = false
        lambda.l_TF_MedigunHealRateMultiplier = 1.0
        lambda.l_TF_MedicTargetFilter = nil
        lambda.l_TF_MedigunChargeReleaseSound = "player/invulnerable_on.wav"
        lambda.l_TF_MedigunChargeDrainSound = "player/invulnerable_off.wav"

        lambda.l_TF_NextMedicHealthRegenT = 0
        lambda.l_TF_Medigun_HealTarget = NULL
        lambda.l_TF_Medigun_BeamColor = random( 1, 2 )
        lambda.l_TF_SwitchedOffMedigun = nil
        
        lambda.l_TF_Medigun_ChargeMeter = 0
        lambda.l_TF_Medigun_ChargeReleased = false
        lambda.l_TF_Medigun_ChargeReady = false
        lambda.l_TF_Medigun_ChargeSound = nil

        lambda.HealWithMedigun = LambdaMedigunState
    end

    local function OnLambdaThink( lambda, weapon, isdead )
        if isdead or CurTime() > lambda.l_TF_NextInventoryCheckT then 
            local wepName = lambda:GetWeaponName()
            local lambdaInv = lambda.l_TF_Inventory
            local invItems = LAMBDA_TF2.InventoryItems
            local preInvWep = lambda.l_TF_PreInventorySwitchWeapon

            if !lambdaInv[ wepName ] and ( !lambda.l_HasMelee or CurTime() > lambda.l_WeaponUseCooldown ) then
                if isdead or preInvWep and wepName == preInvWep.Name then
                    lambda.l_TF_PreInventorySwitchWeapon = nil
                end

                local prevMedigun = lambda.l_TF_SwitchedOffMedigun
                if !isdead and prevMedigun and wepName != prevMedigun and !lambda:InCombat() then
                    lambda:SwitchWeapon( prevMedigun )
                    lambda.l_TF_SwitchedOffMedigun = nil
                end
                
                for name, wep in RandomPairs( lambdaInv ) do
                    if isdead then
                        wep.IsReady = true 
                        wep.NextUseTime = CurTime()
                        continue
                    end

                    if !wep.IsReady then
                        if CurTime() >= wep.NextUseTime then
                            wep.IsReady = true
                            weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC )
                        else
                            continue
                        end
                    end

                    if wepName != name and invItems[ name ].Condition( lambda ) == true then
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

            local nextT = Rand( 0.1, 0.5 )
            lambda.l_TF_NextInventoryCheckT = ( CurTime() + nextT )

            if !isdead then
                local itemIndex = 1
                for name, item in pairs( lambda.l_TF_Inventory ) do
                    debugoverlay.Text( lambda:GetPos() + lambda:OBBCenter() * ( 2 + ( 0.33 * itemIndex ) ), name .. ": " .. tostring( item.IsReady ), nextT )
                    itemIndex = ( itemIndex + 1 )
                end
            end
        end
        
        if !isdead and alwaysCrit:GetBool() then 
            LAMBDA_TF2:AddCritBoost( lambda, "AlwaysCritSetting", CRIT_FULL, 0.1 )
        end

        if lambda.l_TF_AtomicPunched and ( isdead or CurTime() >= lambda.l_TF_AtomicPunched ) then
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
                trail:SetParent( NULL )
                SafeRemoveEntityDelayed( trail, 1 ) 
            end
        end

        local bonkSlowdown = lambda.l_TF_AtomicPunched_SlowdownScale
        if bonkSlowdown and ( isdead or CurTime() >= lambda.l_TF_AtomicPunched_SlowdownTime ) then
            bonkSlowdown = false
            lambda.l_TF_AtomicPunched_SlowdownScale = bonkSlowdown
            lambda.l_nextspeedupdate = 0
        end

        if lambda.l_TF_InSpeedBoost then 
            local boostTrail = lambda.l_TF_SpeedBoostTrail

            if isdead or CurTime() >= lambda.l_TF_InSpeedBoost then
                lambda.l_TF_InSpeedBoost = false
                lambda:EmitSound( ")weapons/discipline_device_power_down.wav", 65, nil, nil, CHAN_STATIC )

                if IsValid( boostTrail ) then
                    boostTrail:SetParent( NULL )
                    SafeRemoveEntityDelayed( boostTrail, 1 )
                end

                lambda.l_nextspeedupdate = 0
            elseif !IsValid( boostTrail ) then
                lambda.l_nextspeedupdate = 0
                boostTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 16, 8, 0.33, "effects/beam001_white", lambda:WorldSpaceCenter(), lambda )
                lambda:DeleteOnRemove( boostTrail )
                lambda.l_TF_SpeedBoostTrail = boostTrail
            end
        end

        if CurTime() > lambda.l_nextspeedupdate then
            lambda:SimpleTimer( FrameTime(), function()
                local desSpeed = lambda.loco:GetDesiredSpeed()

                if lambda.l_TF_InSpeedBoost then desSpeed = ( desSpeed + min( desSpeed * 0.4, 105 ) ) end
                if lambda.l_TF_IsStunned then desSpeed = ( desSpeed * 0.75 ) end
                if bonkSlowdown then desSpeed = ( desSpeed * bonkSlowdown ) end

                lambda.loco:SetDesiredSpeed( desSpeed )
            end )
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
                local isPanicking = ( lambda:IsPanicking() or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )

                local canCharge = isPanicking
                if !canCharge and lambda:InCombat() then
                    local selfPos = lambda:GetPos()
                    local enemyPos = enemy:GetPos()
                    local stepHeight = lambda.loco:GetStepHeight()        

                    if ( enemyPos.z >= ( selfPos.z - stepHeight ) and enemyPos.z <= ( selfPos.z + stepHeight ) ) and ( !lambda.l_HasMelee or lambda:IsInRange( enemy, 1000 ) ) and !lambda:IsInRange( enemy, ( lambda.l_CombatAttackRange or 1000 ) ) and lambda:CanSee( enemy ) then
                        lambda:LookTo( enemy, 1.0 )

                        local los = deg( acos( lambda:GetForward():Dot( ( enemyPos - selfPos ):GetNormalized() ) ) )
                        canCharge = ( los <= 15 )
                    end
                end

                if canCharge then
                    lambda:EmitSound( "lambdaplayers/tf2/shield_charge.mp3", 80, nil, nil, CHAN_STATIC )
                    lambda:PlaySoundFile( isPanicking and "fall" or "taunt" )

                    local chargeTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 32, 16, 0.75, "effects/beam001_white", lambda:WorldSpaceCenter(), lambda )
                    lambda:DeleteOnRemove( chargeTrail )
                    lambda.l_TF_Shield_ChargeTrail = chargeTrail

                    lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate / ( shieldType != 3 and 20 or 1 ) )
                    lambda.l_TF_Shield_IsCharging = true

                    LAMBDA_TF2:RemoveBurn( lambda )
                    LAMBDA_TF2:RemoveBleeding( lambda )

                    if lambda.l_TF_CoveredInUrine then lambda.l_TF_CoveredInUrine = 0 end
                    if lambda.l_TF_CoveredInMilk then lambda.l_TF_CoveredInMilk = 0 end
                end
            end

            if lambda.l_TF_Shield_IsCharging then
                if !isdead then
                    if lambda.l_HasMelee and CurTime() >= lambda.l_WeaponUseCooldown then
                        lambda.l_WeaponUseCooldown = CurTime() + 0.1
                    end

                    lambda.loco:SetVelocity( lambda:GetForward() * max( 750, lambda.loco:GetDesiredSpeed() * 2 ) )

                    if !lambda:IsWeaponMarkedNodraw() then
                        if lambda.l_TF_Shield_ChargeMeter <= 75 then
                            if !lambda.l_TF_Shield_CritBoosted then
                                lambda.l_TF_Shield_CritBoosted = true

                                local chargeSnd = LAMBDA_TF2:CreateSound( weapon, ")weapons/weapon_crit_charged_on.wav" )
                                if chargeSnd then chargeSnd:PlayEx( 0.25, 100 ) end
                                lambda.l_TF_Shield_CritBoostSound = chargeSnd
                            end
                            weapon:SetMaterial( critMat ) 
                        else
                            weapon:SetMaterial( "" ) 
                        end
                    end

                    local lambdaPos = lambda:GetAttachmentPoint( "eyes" ).Pos
                    shieldChargeTrTbl.start = lambdaPos
                    shieldChargeTrTbl.endpos = ( lambdaPos + lambda:GetForward() * 48 )
                    shieldChargeTrTbl.filter = { lambda, weapon, shield }

                    local chargeResult = TraceHull( shieldChargeTrTbl )
                    if chargeResult.Hit then
                        local impactEnt = chargeResult.Entity
                        if LAMBDA_TF2:IsValidCharacter( impactEnt ) then
                            impactEnt:EmitSound( "weapons/demo_charge_hit_flesh_range" .. random( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )

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
                            lambda:EmitSound( "weapons/demo_charge_hit_world" .. random( 1, 3 ) .. ".wav", 80, nil, nil, CHAN_STATIC )
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
                            local chargeSnd = lambda.l_TF_Shield_CritBoostSound
                            if chargeSnd then chargeSnd:Stop() end
                            lambda.l_TF_Shield_CritBoostSound = nil

                            lambda.l_TF_Shield_CritBoosted = false
                            weapon:EmitSound( ")weapons/weapon_crit_charged_off.wav", nil, nil, 0.25, CHAN_STATIC )
                        end

                        lambda.l_TF_NextMeleeCrit = CRIT_NONE 
                    end, true )

                    if !isdead then
                        lambda:RecomputePath()
                        if lambda.l_TF_Shield_ChargeMeter <= 40 then
                            lambda.l_TF_NextMeleeCrit = CRIT_FULL
                        elseif lambda.l_TF_Shield_ChargeMeter <= 75 then
                            lambda.l_TF_NextMeleeCrit = CRIT_MINI
                        end
                        lambda.l_TF_Shield_ChargeMeter = 0
                        lambda.l_TF_Shield_ChargeMeterFull = false
                    end

                    lambda.loco:SetMaxYawRate( lambda.l_TF_Shield_PreChargeYawRate )
                    lambda:StopSound( "lambdaplayers/tf2/shield_charge.mp3" )

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
                    weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC )
                    lambda.l_TF_Shield_ChargeMeter = 100
                    lambda.l_TF_Shield_ChargeMeterFull = true
                end
            end
        end

        if lambda.l_TF_ThrownBaseball and ( isdead or CurTime() > lambda.l_TF_ThrownBaseball ) then
            lambda.l_TF_ThrownBaseball = false
            if !isdead then weapon:EmitSound( "player/recharged.wav", 65, nil, nil, CHAN_STATIC ) end
        end

        for barIndex, bar in ipairs( lambda.l_TF_DalokohsBars ) do
            if !isdead and CurTime() < bar.ExpireTime then continue end
            local hpRatio = bar.HealthRatio
            local oldHP = ( lambda:GetMaxHealth() / hpRatio )
            if !isdead then lambda:SetHealth( floor( lambda:Health() * ( oldHP / lambda:GetMaxHealth() ) ) ) end
            lambda:SetMaxHealth( oldHP )
            table_remove( lambda.l_TF_DalokohsBars, barIndex )
        end

        if lambda.l_TF_Medigun_ChargeReleased then
            if isdead or lambda.l_TF_Medigun_ChargeMeter <= 0 then
                lambda:StopSound( lambda.l_TF_MedigunChargeReleaseSound )
                lambda:EmitSound( lambda.l_TF_MedigunChargeDrainSound, nil, nil, nil, CHAN_STATIC )

                lambda.l_TF_Medigun_ChargeReleased = false
                lambda.l_TF_Medigun_ChargeMeter = 0

                if lambda.l_TF_Medigun_ChargeReady then
                    lambda.l_TF_Medigun_ChargeReady = false

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
            end

            lambda.l_TF_Medigun_ChargeMeter = ( lambda.l_TF_Medigun_ChargeMeter - ( ( 100 / 9 ) * FrameTime() ) )
        end

        if !isdead then 
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

            if lambda.l_TF_HasMedigunEquipped then 
                if ( lambda:GetState() == "Idle" or lambda:GetState() == "Combat" or lambda:GetState() == "FindTarget" ) and lambda:GetState() != "HealWithMedigun" and !lambda:IsPanicking() then
                    lambda:CancelMovement()
                    lambda:SetState( "HealWithMedigun" )
                end

                local chargeSnd = lambda.l_TF_Medigun_ChargeSound
                if lambda.l_TF_Medigun_ChargeMeter >= 100 and !lambda.l_TF_Medigun_ChargeReady then
                    lambda.l_TF_Medigun_ChargeReady = true

                    if !chargeSnd then
                        chargeSnd = LAMBDA_TF2:CreateSound( weapon, "weapons/medigun_charged.wav" )
                        chargeSnd:Play()
                        chargeSnd:SetSoundLevel( 70 )
                        lambda.l_TF_Medigun_ChargeSound = chargeSnd
                    end

                    net.Start( "lambda_tf2_medigun_chargeeffect" )
                        net.WriteEntity( weapon )
                        net.WriteBool( true )
                        net.WriteUInt( lambda.l_TF_Medigun_BeamColor, 3 )
                    net.Broadcast()
                end
            end

            if CurTime() > lambda.l_TF_NextMedicHealthRegenT then
                lambda.l_TF_NextMedicHealthRegenT = ( CurTime() + 1 )

                if lambda.l_TF_HasMedigunEquipped then
                    local regenHP = max( 1, lambda:GetMaxHealth() * LAMBDA_TF2:RemapClamped( ( CurTime() - lambda.l_TF_LastTakeDamageTime ), 0, 10, 0.02, 0.04 ) )
                    LAMBDA_TF2:GiveHealth( lambda, regenHP, false )
                end

                local ene = lambda:GetEnemy()
                if ene.l_TF_HasMedigunEquipped and lambda:InCombat() and LAMBDA_TF2:GetMedigunHealers( lambda )[ ene ] then
                    lambda:CancelMovement()
                    lambda:SetEnemy( NULL )
                    lambda:SetState( "Idle" )
                end
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

            local target = lambda.l_TF_RevengeTarget
            if LambdaIsValid( target ) and lambda:CanTarget( target ) then
                lambda:AttackTarget( target )
            end
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

            if lambda.L_TF_Shield_IsCharging and shieldType == 3 and dmginfo:GetAttacker() != lambda and !dmginfo:IsDamageType( DMG_FALL ) then
                lambda.l_TF_Shield_ChargeMeter = ( lambda.l_TF_Shield_ChargeMeter - dmginfo:GetDamage() )
            end
        end

        local attacker = dmginfo:GetAttacker()
        local healTarget = lambda.l_TF_Medigun_HealTarget
        if lambda.l_TF_HasMedigunEquipped and IsValid( healTarget ) then
            if attacker.IsLambdaPlayer and attacker == healTarget then return true end

            if lambda:CanTarget( attacker ) and !lambda:IsSpeaking() then
                lambda:PlaySoundFile( "panic" )
            end
        end

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

        if attacker.IsLambdaPlayer then
            for _, boostInfo in pairs( attacker.l_TF_CritBoosts ) do
                local markTime = boostInfo.MarkForDeathOnAttack
                if markTime and ( CurTime() + markTime ) > attacker.l_TF_MarkedForDeath then
                    attacker.l_TF_MarkedForDeath = ( CurTime() + markTime )
                end
            end
        end
        if !IsValid( ent ) then return end

        if !LAMBDA_TF2:IsValidCharacter( ent ) then
            ent.l_TF_Killer = attacker
        end

        local inflictor = dmginfo:GetInflictor()
        if !IsValid( inflictor ) then return end
        
        local dmgType = dmginfo:GetDamageType()
        if ent.l_TF_IsBurning != nil and bit.band( dmgType, DMG_IGNITE ) != 0 and ent:WaterLevel() < 2 then
            LAMBDA_TF2:Burn( ent, attacker, inflictor )
        end

        if !LAMBDA_TF2:IsValidCharacter( ent, false ) then return end
        ent.l_TF_LastTakeDamageTime = CurTime()

        if bit.band( dmgType, DMG_MELEE ) != 0 then
            local hitSnd = inflictor:GetWeaponAttribute( "HitSound", {
                ")weapons/cbar_hitbod1.wav",
                ")weapons/cbar_hitbod2.wav",
                ")weapons/cbar_hitbod3.wav"
            } )
            if hitSnd then
                local critSnd = inflictor:GetWeaponAttribute( "HitCritSound" )
                if critSnd and bit.band( dmgType, DMG_CRITICAL ) != 0 then hitSnd = critSnd end
                if istable( hitSnd ) then hitSnd = hitSnd[ random( #hitSnd ) ] end
                inflictor:EmitSound( hitSnd, nil, nil, nil, CHAN_STATIC )
            end
        end

        local dmgCustom = dmginfo:GetDamageCustom()
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

                if ( inflictor.l_TF_IsTF2Weapon or inflictor.TF2Data ) and bit.band( dmgType, DMG_PREVENT_PHYSICS_FORCE ) == 0 then 
                    local vecDir = ( ( inflictor:WorldSpaceCenter() - vector_up * 10 ) - ent:WorldSpaceCenter() ):GetNormalized()
                    LAMBDA_TF2:ApplyPushFromDamage( ent, dmginfo, vecDir )     
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
        [ TF_DMG_CUSTOM_DECAPITATION ] = {
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

    local function OnLambdaKilled( lambda, dmginfo )
        local dmgCustom = dmginfo:GetDamageCustom()
        -- if dmgCustom == 0 then
        --     if lambda.l_TF_PreDeathDamage >= ( lambda:GetMaxHealth() / 2 ) then
        --         if lambda.l_lasthitgroup == HITGROUP_HEAD and dmginfo:IsBulletDamage() then
        --             dmgCustom = TF_DMG_CUSTOM_HEADSHOT
        --         end
        --     elseif dmginfo:IsDamageType( DMG_BURN + DMG_SLOWBURN ) then
        --         dmgCustom = TF_DMG_CUSTOM_BURNING
        --     end
        -- end

        local ragdoll = lambda.ragdoll
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
                local animEnt = ents_Create( "base_anim" )
                animEnt:SetModel( lambda:GetModel() )
                animEnt:SetPos( lambda:GetPos() )
                animEnt:SetAngles( lambda:GetAngles() )
                animEnt:Spawn()

                animEnt:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                LAMBDA_TF2:TakeNoDamage( animEnt )
                animEnt.l_IsTFDeathAnimation = true

                if dmgCustom == TF_DMG_CUSTOM_BURNING or LAMBDA_TF2:IsBurning( lambda ) then
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

                local speed = Rand( 0.8, 1.1 )
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

                lambda.ragdoll = animEnt
                lambda:SetNW2Entity( "lambda_serversideragdoll", animEnt )
                lambda:DeleteOnRemove( animEnt )
                
                local serverside = true
                if IsValid( ragdoll ) then
                    ragdoll:Remove()
                else
                    serverside = false

                    net.Start( "lambda_tf2_removecsragdoll" )
                        net.WriteEntity( lambda )
                    net.Broadcast()
                end
                ragdoll = animEnt

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
                        local serverRag = lambda:CreateServersideRagdoll( nil, animEnt )
                        if doDecapitation then LAMBDA_TF2:DecapitateHead( serverRag, false ) end
                    end

                    animEnt:Remove()
                
                end, "TF2_DeathAnimation", true )
            end
        end

        if doDecapitation then
            if !IsValid( ragdoll ) then
                net.Start( "lambda_tf2_decapitate_csragdoll" )
                    net.WriteEntity( lambda )
                    net.WriteBool( true )
                    net.WriteVector( dmginfo:GetDamageForce() / 2 )
                net.Broadcast()
            else
                LAMBDA_TF2:DecapitateHead( ragdoll, true, ( dmginfo:GetDamageForce() / 4 ) )
            end
        end

        if LAMBDA_TF2:IsBurning( lambda ) and IsValid( ragdoll ) then
            ragdoll:Ignite( ( lambda.l_TF_FlameRemoveTime - CurTime() ), 0 )
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
        lambda.l_TF_CrikeyMeter = 0
        lambda.l_TF_CrikeyMeterFull = false

        if lambda.l_TF_Medigun_ChargeReady then
            lambda:EmitSound( "player/medic_charged_death.wav", 85, nil, nil, CHAN_STATIC )
            if lambda.l_TF_Medigun_ChargeSound then lambda.l_TF_Medigun_ChargeSound:Stop(); lambda.l_TF_Medigun_ChargeSound = nil end
        end
        lambda.l_TF_Medigun_ChargeMeter = 0
        lambda.l_TF_Medigun_ChargeReady = false

        if lambda:GetWeaponName() == "tf2_frontierjustice" and lambda.l_TF_RevengeCrits > 0 then
            lambda.l_TF_RevengeCrits = 0
        else
            lambda.l_TF_RevengeCrits = min( lambda.l_TF_RevengeCrits + lambda.l_TF_FrontierJusticeKills, 35 )
        end
        lambda.l_TF_FrontierJusticeKills = 0
        
        if IsValid( attacker ) and lambda:CanTarget( attacker ) then
            lambda.l_TF_RevengeTarget = attacker
        end

        net.Start( "lambda_tf2_medigun_chargeeffect" )
            net.WriteEntity( lambda:GetWeaponENT() )
            net.WriteBool( false )
        net.Broadcast()

        dmginfo:SetDamage( lambda.l_TF_PreDeathDamage or 0 )
        OnPostEntityTakeDamage( lambda, dmginfo, true )

        for _, v in ipairs( GetLambdaPlayers() ) do
            OnLambdaOnOtherInjured( v, lambda, dmginfo, true )
        end
    end

    local function OnLambdaSwitchWeapon( lambda, weapon, data )
        if data.origin != "Team Fortress 2" then weapon.TF2Data = nil end

        net.Start( "lambda_tf2_medigun_chargeeffect" )
            net.WriteEntity( lambda:GetWeaponENT() )
            net.WriteBool( false )
        net.Broadcast()
    end

    local function OnLambdaChangeState( lambda, old, new )
        if new == "Laughing" then 
            if old == "HealWithMedigun" and ( lambda.l_TF_Medigun_ChargeReleased or random( 1, 3 ) != 1 ) then
                return true
            end

            if ( alwaysUseSchadenfreude:GetBool() or lambda:GetWeaponENT().TF2Data ) then
                lambda:SetState( "Schadenfreude" )
                return true
            end
        end

        if old == "UseTFItem" and lambda.l_TF_IsUsingItem and lambda:Alive() then 
            lambda.l_TF_PreUseItemState = new
            return true 
        end
        
        local healTarget = lambda.l_TF_Medigun_HealTarget
        if old == "HealWithMedigun" and new == "Retreat" and IsValid( healTarget ) and LAMBDA_TF2:IsValidCharacter( healTarget ) then return true end
    end

    local function OnLambdaCanSwitchWeapon( lambda, name, data )
        if lambda:GetState() == "UseTFItem" then return true end
        
        local invWep = lambda.l_TF_Inventory[ name ]
        if invWep and !invWep.IsReady then return true end
        
        local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
        if preInvWep and name != preInvWep.Name then return true end
    end

    local function OnLambdaSwitchWeapon( lambda, weapon, data )
        local preInvWep = lambda.l_TF_PreInventorySwitchWeapon
        if preInvWep and lambda:GetWeaponName() == preInvWep.Name then 
            lambda.l_Clip = preInvWep.Clip
        end

        lambda.l_TF_HealRateMultiplier = ( data.healratemult or 1.0 )
        lambda.l_TF_AirBlastVulnerability = ( data.airblast_vulnerability_multiplier or 1.2 )

        lambda.l_TF_HasMedigunEquipped = ( data.ismedigun or false )
        lambda.l_TF_MedigunHealRateMultiplier = ( data.medigunhealrate or 1.0 )
        lambda.l_TF_MedicTargetFilter = data.medictargetfilter
        lambda.l_TF_MedigunChargeReleaseSound = ( data.chargereleasesnd or "player/invulnerable_on.wav" )
        lambda.l_TF_MedigunChargeDrainSound = ( data.chargedrainedsnd or "player/invulnerable_off.wav" )

        if !lambda.l_TF_HasMedigunEquipped then
            if lambda.l_TF_Medigun_ChargeSound then 
                lambda.l_TF_Medigun_ChargeSound:Stop()
                lambda.l_TF_Medigun_ChargeSound = nil
            end

            net.Start( "lambda_tf2_medigun_chargeeffect" )
                net.WriteEntity( weapon )
                net.WriteBool( false )
            net.Broadcast()
        end
    end

    local function OnLambdaAttackTarget( lambda, target )
        local state = lambda:GetState()
        if state == "UseTFItem" or state == "Schadenfreude" then return true end

        if state == "HealWithMedigun" then
            local healTarget = lambda.l_TF_Medigun_HealTarget
            if lambda.l_TF_HasMedigunEquipped and LambdaIsValid( healTarget ) and healTarget.IsLambdaPlayer then
                healTarget:AttackTarget( target )
            end

            return true
        end
    end
    
    local function OnLambdaCanTarget( lambda, ent )
        if ent.l_TF_HasMedigunEquipped and LAMBDA_TF2:GetMedigunHealers( lambda )[ ent ] then return true end
    end
    
    local function OnLambdaBeginMove( lambda, pos, onNavmesh )
        if random( 1, 2 ) == 1 or lambda:InCombat() or lambda:IsPanicking() or lambda:Health() >= lambda:GetMaxHealth() and !LAMBDA_TF2:IsBleeding( lambda ) or !LAMBDA_TF2:IsBurning( lambda )  then return end

        local medkits = lambda:FindInSphere( nil, 1500, function( ent )
            return ( ent.l_IsTFMedkit and lambda:CanSee( ent ) )
        end )
        if #medkits == 0 then return end

        lambda:SetRun( true )
        lambda:RecomputePath( medkits[ random( #medkits ) ]:GetPos() )
    end

    hook_Add( "LambdaOnInitialize", "LambdaTF2_OnLambdaInitialize", OnLambdaInitialize )
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

    local dmgCustomKillicons = {
        [ TF_DMG_CUSTOM_BACKSTAB ]              = "lambdaplayers_weaponkillicons_tf2_backstab",
        [ TF_DMG_CUSTOM_HEADSHOT ]              = "lambdaplayers_weaponkillicons_tf2_headshot",
        [ TF_DMG_CUSTOM_STICKBOMB_EXPLOSION ]   = "lambdaplayers_weaponkillicons_tf2_caber_explosion",
        [ TF_DMG_CUSTOM_BASEBALL ]              = "lambdaplayers_weaponkillicons_tf2_sandman_baseball"
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

        if LAMBDA_TF2:IsValidCharacter( ent ) then
            local inflictor = dmginfo:GetInflictor()
            local attacker = dmginfo:GetAttacker()

            if IsValid( inflictor ) and attacker != ent then
                if inflictor:GetClass() == "entityflame" then
                    if ent.l_TF_IsBurning then return true end

                    local attachEnt = inflictor:GetInternalVariable( "m_hEntAttached" )
                    if IsValid( attachEnt ) and attachEnt.l_IsTFDeathAnimation then return true end
                end

                if attacker.l_IsTFProjectile and dmginfo:IsDamageType( DMG_CRUSH ) then
                    attacker:PhysicsCollide( {
                        HitEntity = ent,
                        OurOldVelocity = attacker:GetPhysicsObject():GetVelocity()
                    } )
                    return true
                end

                local dmgCustom = dmginfo:GetDamageCustom()
                ent:SetNW2Bool( "lambda_tf2_canbedecapitated", ( !ent.IsLambdaPlayer and dmgCustom == TF_DMG_CUSTOM_DECAPITATION ) )

                local critType = LAMBDA_TF2:GetCritType( dmginfo )
                if critType != CRIT_FULL and dmgCustomCrits[ dmgCustom ] then
                    critType = CRIT_FULL
                else
                    if critType == CRIT_NONE and ( ent.l_TF_CoveredInUrine or ent.l_TF_CoveredInMilk or CurTime() <= ent.l_TF_MarkedForDeath ) then
                        critType = CRIT_MINI
                    end
                    if critType == CRIT_MINI and inflictor.IsLambdaWeapon and inflictor.TF2Data and inflictor:GetWeaponAttribute( "MiniCritsToFull", false ) then
                        critType = CRIT_FULL
                    end

                    local critBoost = LAMBDA_TF2:GetCritBoost( attacker )
                    if critBoost > critType then critType = critBoost end
                end

                local critDamage = 0
                local damage = dmginfo:GetDamage()
                if critType == CRIT_FULL then
                    critDamage = ( ( TF_DAMAGE_CRIT_MULTIPLIER - 1 ) * damage )
                elseif critType == CRIT_MINI then
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

                    local doShortRangeDistanceIncrease = ( critType == CRIT_NONE or critType != CRIT_FULL )
                    local doLongRangeDistanceDecrease = ( critType == CRIT_NONE ) 

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
                if critType != CRIT_NONE and LAMBDA_TF2:IsValidCharacter( ent ) then
                    net.Start( "lambda_tf2_criteffects" )
                        net.WriteEntity( ent )
                        net.WriteUInt( critType, 2 )
                        net.WriteVector( ent:WorldSpaceCenter() + vector_up * 32 )
                        net.WriteBool( entDead )
                    net.Broadcast()
                end

                if attacker.IsLambdaPlayer then 
                    if entDead then
                        if attacker.l_TF_Shield_IsEquipped and !attacker.l_TF_Shield_ChargeMeterFull and attacker.l_TF_Shield_Type == 3 and ( dmgCustom == TF_DMG_CUSTOM_CHARGE_IMPACT or dmginfo:IsDamageType( DMG_MELEE ) ) then
                            attacker.l_TF_Shield_ChargeMeter = ( attacker.l_TF_Shield_ChargeMeter + 75 )
                        end

                        if dmgCustom == TF_DMG_CUSTOM_BACKSTAB then 
                            attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 2, 35 )
                        elseif dmginfo:IsDamageType( DMG_MELEE ) then
                            attacker.l_TF_DiamondbackCrits = min( attacker.l_TF_DiamondbackCrits + 1, 35 )
                        end
                    end

                    LAMBDA_TF2:RecordDamageEvent( attacker, dmginfo, entDead, entHealth ) 
                end
            end

            if ent.l_TF_InvulnerabilityTime and CurTime() <= ent.l_TF_InvulnerabilityTime then 
                ent:EmitSound( "SolidMetal.BulletImpact" )
                return true 
            end

            if ent.l_TF_AtomicPunched then
                ent:EmitSound( "player/pl_scout_jump" .. random( 1, 4 ) .. ".wav", 65, random( 90, 110 ), nil, CHAN_STATIC )
                ent.l_TF_AtomicPunched_DamageTaken = ( ent.l_TF_AtomicPunched_DamageTaken + dmginfo:GetDamage() )
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
        if owner:GetNW2Bool( "lambda_tf2_canbedecapitated", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ragdoll:GetVelocity() * 5 )
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

    hook_Add( "EntityTakeDamage", "LambdaTF2_OnEntityTakeDamage", OnEntityTakeDamage )
    hook_Add( "PostEntityTakeDamage", "LambdaTF2_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
    hook_Add( "Think", "LambdaTF2_OnServerThink", OnServerThink )
    hook_Add( "CreateEntityRagdoll", "LambdaTF2_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
    hook_Add( "ScalePlayerDamage", "LambdaTF2_OnScalePlayerDamage", OnScaleEntityDamage )
    hook_Add( "ScaleNPCDamage", "LambdaTF2_OnScaleNPCDamage", OnScaleEntityDamage )
    hook_Add( "PlayerInitialSpawn", "LambdaTF2_OnPlayerInitialSpawn", OnEntityCreated )

end