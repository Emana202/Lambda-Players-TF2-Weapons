local ismatrix = ismatrix
local isvector = isvector
local isnumber = isnumber
local isentity = isentity
local isbool = isbool
local isangle = isangle
local isstring = isstring
local ipairs = ipairs
local IsValid = IsValid
local net = net
local CreateClientside = ents.CreateClientside
local CreateParticleSystem = CreateParticleSystem
local ents_Create = ents.Create
local SimpleTimer = timer.Simple
local hook_Add = hook.Add
local hook_Remove = hook.Remove
local lower = string.lower
local EndsWith = string.EndsWith
local CurTime = CurTime
local pairs = pairs
local Round = math.Round
local max = math.max
local Clamp = math.Clamp
local Rand = math.Rand
local CreateSound = CreateSound
local ParticleEffectAttach = ParticleEffectAttach
local RandomPairs = RandomPairs
local random = math.random
local table_Copy = table.Copy
local table_Random = table.Random
local table_Count = table.Count
local table_Merge = table.Merge
local isfunction = isfunction
local FindInSphere = ents.FindInSphere
local GetAmmoMax = game.GetAmmoMax
local TraceLine = util.TraceLine
local LocalPlayer = ( CLIENT and LocalPlayer )

local lockerMdls = {
    [ "models/props_gameplay/resupply_locker.mdl" ] = true,
    [ "models/props_medieval/medieval_resupply.mdl" ] = true
}

---

LAMBDA_TF2 = LAMBDA_TF2 or {}

TF_CRIT_NONE = 0
TF_CRIT_MINI = 1
TF_CRIT_FULL = 2

---

CreateLambdaConvar( "lambdaplayers_tf2_allowrandomcrits", 1, true, false, false, "If the weapons from TF2 should have a chance to earn a random crit", 0, 1, { type = "Bool", name = "Allow Random Crits", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_alwayscrit", 0, true, false, false, "If the weapons from TF2 should have always fire a crit shot", 0, 1, { type = "Bool", name = "Always Crit", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_dropammobox", 1, true, false, false, "If Lambda Players should drop ammopack on death. 0 - Disabled; 1 - When holding a TF2 weapon; 2 - Always", 0, 2, { type = "Slider", decimals = 0, name = "Drop Ammopacks", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_ammoboxlimit", 3, true, false, false, "How many ammoboxes can Lambda Players drop on death. Upon reaching this limit, the oldest ammobox will be delted", 1, 10, { type = "Slider", decimals = 0, name = "Ammopack Drop Limit", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_deathanimchance", 25, true, false, false, "The chance that Lambda Player will play a unique death animation when after dying from a specific TF2 weapon", 0, 100, { type = "Slider", decimals = 0, name = "Death Animation Chance", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_alwaysuseschadenfreude", 0, true, false, false, "If Lambda Players should always use play the Schadenfreude taunt when laughing instead of when holding a TF2 weapon", 0, 1, { type = "Bool", name = "Always Use Schadenfreude", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_schadenfreudeplaysclasslaughter", 0, true, false, false, "If Lambda Players using Schadenfreude should also play the laugh that animation belongs to alongside their own laughter", 0, 1, { type = "Bool", name = "Schadenfreude Uses Class-Specific Laughter", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_allowdominations", 0, true, false, false, "Enables the domination and revenge mechanic from TF2 to Lambda Players and real players", 0, 1, { type = "Bool", name = "Enable Dominations & Revenges", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_alwaysplayrivalrysnd", 0, true, true, false, "Should the domination and revenge sound cues play no matter if you were involved in it?", 0, 1, { type = "Bool", name = "Always Play Rivalry Sounds", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_capbackstabdamage", 0, true, false, false, "If not zero, the damage from backstabs will be set to this value if it's higher that it", 0, 1000, { type = "Slider", decimals = 0, name = "Backstab Max Damage", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_randomrechargeablechance", 10, true, false, false, "The chance that Lambda Player will have a random rechargeable item in their inventory that they can use if needed after their initial spawn. For example, Jarate, Sandvich, Crit-a-Cola, etc.", 0, 100, { type = "Slider", decimals = 0, name = "Random Rechargeable Item Chance", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_inventoryitemlimit", 1, true, false, false, "How many items can Lambda Player carry in their inventory?", 0, 4, { type = "Slider", decimals = 0, name = "Inventory Limit", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_wearonlyonebackpack", 1, true, false, false, "If Lambda Players are allowed to have only one item that is wearable on their back", 0, 1, { type = "Bool", name = "Wear Only One Backpack", category = "TF2 Stuff" } )
CreateLambdaConvar( "lambdaplayers_tf2_randomizeitemsonrespawn", 0, true, false, false, "If not zero, determines the chance that the Lambda Player's items will be randomized on its respawn", 0, 100, { type = "Slider", decimals = 0, name = "Random Items On Respawn Chance", category = "TF2 Stuff" } )
local objectorIncludePfps = CreateLambdaConvar( "lambdaplayers_tf2_objectorincludepfps", 0, true, false, false, "If Lambda Players using The Conscientious Objector should also use Lambda Profile Pictures as their image?", 0, 1, { type = "Bool", name = "Objector Includes PFPs", category = "TF2 Stuff" } )

---

function LAMBDA_TF2:PseudoNetworkVar( ent, name, initVar )
    local setFunc, getFunc, typeIndex
    if isnumber( initVar ) then
        if ( initVar % 1 ) != 0 then
            typeIndex = 1
            setFunc = ent.SetNW2Float
            getFunc = ent.GetNW2Float
        else
            typeIndex = 2
            setFunc = ent.SetNW2Int
            getFunc = ent.GetNW2Int
        end
    elseif isentity( initVar ) then
        typeIndex = 3
        setFunc = ent.SetNW2Entity
        getFunc = ent.GetNW2Entity
    elseif isvector( initVar ) then
        typeIndex = 4
        setFunc = ent.SetNW2Vector
        getFunc = ent.GetNW2Vector
    elseif isbool( initVar ) then
        typeIndex = 5
        setFunc = ent.SetNW2Bool
        getFunc = ent.GetNW2Bool
    elseif isangle( initVar ) then
        typeIndex = 6
        setFunc = ent.SetNW2Angle
        getFunc = ent.GetNW2Angle
    elseif isstring( initVar ) then
        typeIndex = 7
        setFunc = ent.SetNW2String
        getFunc = ent.GetNW2String
    end
    if !typeIndex then return end

    local varName = "lambda_tf2_" .. lower( name )
    if ( SERVER ) then setFunc( ent, varName, initVar ) end

    ent[ "Get" .. name ] = function( self ) return getFunc( ent, varName ) end
    ent[ "Set" .. name ] = function( self, value ) setFunc( ent, varName, value ) end
end

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

function LAMBDA_TF2:GetEntityHeadBone( ent )
    for hboxSet = 0, ( ent:GetHitboxSetCount() - 1 ) do
        for hitbox = 0, ( ent:GetHitBoxCount( hboxSet ) - 1 ) do
            if ent:GetHitBoxHitGroup( hitbox, hboxSet ) != HITGROUP_HEAD then continue end
            return ( ent:GetHitBoxBone( hitbox, hboxSet ) )
        end
    end

    return ( ent:LookupBone( "ValveBiped.Bip01_Head1" ) )
end

function LAMBDA_TF2:DecapitateHead( target, effects, force )
    if !IsValid( target ) then return end

    if CLIENT and target.IsLambdaPlayer then
        local ragdoll = target.ragdoll
        if !IsValid( ragdoll ) then return end
        target = ragdoll
    end

    local headBone = LAMBDA_TF2:GetEntityHeadBone( target )
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
            LAMBDA_TF2:CreateGib( headPos, headAng, force, "models/lambdaplayers/tf2/gibs/humanskull.mdl" )

            local bloodEffect = ents_Create( "info_particle_system" )
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

function LAMBDA_TF2:GetInvulnMaterial()
    return "lambdaplayers/effects/ubercharge_sheet"
end

function LAMBDA_TF2:GetCritGlowMaterial()
    return "lambdaplayers/effects/modelcritglow"
end

function LAMBDA_TF2:IsValidCharacter( ent, alive )
    if alive == nil then alive = true end
    return ( ( ent:IsPlayer() or ent.IsLambdaPlayer ) and ( !alive or ent:Alive() ) or ( ent:IsNPC() or ent:IsNextBot() ) and ( !alive or ent:Health() > 0 ) )
end

function LAMBDA_TF2:RemapClamped( value, inMin, inMax, outMin, outMax )
    if inMin == inMax then return ( value >= inMax and outMax or outMin ) end
    local clampedValue = ( ( value - inMin ) / ( inMax - inMin ) )
    clampedValue = Clamp( clampedValue, 0, 1 )
    return ( outMin + ( outMax - outMin ) * clampedValue )
end

function LAMBDA_TF2:StopParticlesNamed( ent, name )
    if ( SERVER ) then
        net.Start( "lambda_tf2_stopnamedparticle" )
            net.WriteEntity( ent )
            net.WriteString( name )
        net.Broadcast()
    else
        ent:StopParticlesNamed( name )
    end
end

function LAMBDA_TF2:CreateSound( targetEnt, soundName, filter )
    local soundPatch
    local sndTbl = targetEnt.l_TF_LoopingSounds
    if !sndTbl then
        targetEnt.l_TF_LoopingSounds = {}
    else
        soundPatch = sndTbl[ soundName ]
        if soundPatch then 
            soundPatch:Stop()
            soundPatch = NULL
            targetEnt.l_TF_LoopingSounds[ soundName ] = nil
        end
    end

    soundPatch = CreateSound( targetEnt, soundName, filter )
    if soundPatch then targetEnt.l_TF_LoopingSounds[ soundName ] = soundPatch end

    return soundPatch
end

function LAMBDA_TF2:StopSound( ent, sound )
    if !sound then return end

    if IsValid( ent ) then
        local loopingSnds = ent.l_TF_LoopingSounds
        if loopingSnds then
            for soundName, soundPatch in pairs( loopingSnds ) do
                if sound != soundPatch then continue end
                ent:StopSound( soundName )
                ent.l_TF_LoopingSounds[ soundName ] = nil
                break
            end
        end
    end

    sound:Stop()
    sound = NULL
end

function LAMBDA_TF2:AttachFlameParticle( ent, removeTime, teamClr )
    local partName = ( isstring( teamClr ) and teamClr or "burningplayer_" .. ( teamClr == 1 and "blue" or "red" ) )
    ParticleEffectAttach( partName, PATTACH_ABSORIGIN_FOLLOW, ent, 0 )

    local burningSnd = LAMBDA_TF2:CreateSound( ent, "ambient/fire/fire_small_loop" .. random( 2 ) .. ".wav" )
    burningSnd:PlayEx( 0.8, 100 )
    burningSnd:SetSoundLevel( 75 )

    local hookName = "LambdaTF2_ExtinguishFlame_" .. ent:GetClass() .. CurTime() .. random( 9999 )
    local removeFlameTime = ( CurTime() + removeTime )
    hook_Add( "Tick", hookName, function() 
        if IsValid( ent ) and CurTime() < removeFlameTime and ent:WaterLevel() < 2 then return end
        if IsValid( ent ) then LAMBDA_TF2:StopParticlesNamed( ent, partName ) end
        LAMBDA_TF2:StopSound( ent, burningSnd )
        hook_Remove( "Tick", hookName )
    end )
end

local eyeOffsetVec = Vector( 0, 0, 0 )

function LAMBDA_TF2:GetOverheadEffectPosition( ent )
    local eyePos
    if ent.IsLambdaPlayer then 
        eyePos = ent:GetAttachmentPoint( "eyes" ).Pos
    else
        eyePos = ent:EyePos()
    end

    eyeOffsetVec.z = ( eyePos.z - ent:GetPos().z + 20 )
    return eyeOffsetVec
end

function LAMBDA_TF2:AddOverheadEffect( ent, effectName )
    if ( CLIENT ) then
        if !ent.l_TF_OverheadEffects or IsValid( ent.l_TF_OverheadEffects[ effectName ] ) then return end

        local effect = CreateParticleSystem( ent, effectName, PATTACH_ABSORIGIN_FOLLOW, 0, LAMBDA_TF2:GetOverheadEffectPosition( ent ) )
        if !IsValid( effect ) then return end

        ent.l_TF_OverheadEffects[ effectName ] = effect
    else
        net.Start( "lambda_tf2_addoverheadeffect" )
            net.WriteEntity( ent )
            net.WriteString( effectName )
        net.Broadcast()
    end
end

function LAMBDA_TF2:RemoveOverheadEffect( ent, effectName, removeInstantly )
    if ( CLIENT ) then
        if !ent.l_TF_OverheadEffects then return end

        local effect = ent.l_TF_OverheadEffects[ effectName ]
        if !IsValid( effect ) then return end

        effect:StopEmission( false, ( removeInstantly or false ) )
        ent.l_TF_OverheadEffects[ effectName ] = nil
    else
        net.Start( "lambda_tf2_removeoverheadeffect" )
            net.WriteEntity( ent )
            net.WriteString( effectName )
            net.WriteBool( removeInstantly or false )
        net.Broadcast()
    end
end

local function OnEntityCreated( ent )
    ent.l_TF_LoopingSounds = {}

    LAMBDA_TF2:PseudoNetworkVar( ent, "IsBurning", false ) 
    LAMBDA_TF2:PseudoNetworkVar( ent, "FlameRemoveTime", -0.1 ) 
    LAMBDA_TF2:PseudoNetworkVar( ent, "IsInvulnerable", false ) 
    LAMBDA_TF2:PseudoNetworkVar( ent, "InvulnerabilityWearingOff", false ) 
    LAMBDA_TF2:PseudoNetworkVar( ent, "CritBoostType", TF_CRIT_NONE ) 

    if ( SERVER ) then
        if ent:GetClass() == "prop_dynamic" then 
            local entMdl = ent:GetModel()
            if lockerMdls[ entMdl ] then
                local locker = ents_Create( "lambda_tf_resupplylocker" )
                locker.Model = entMdl
                locker:SetPos( ent:GetPos() )
                locker:SetAngles( ent:GetAngles() )
                locker:Spawn()

                ent:Remove()
                return
            end
        end

        ent.l_TF_HasOverheal = false
        ent.l_TF_HealFraction = 0

        ent.l_TF_BleedInfo = {}

        ent.l_TF_MarkedForDeath = false
        ent.l_TF_MarkedForDeathSilent = false
        ent.l_TF_MarkedForDeathTarget = nil

        ent.l_TF_FlameBurnTime = 0
        ent.l_TF_BurnAttacker = NULL
        ent.l_TF_BurnWeapon = NULL
        ent.l_TF_BurnInflictor = NULL
        ent.l_TF_AfterburnImmunity = 0
        ent.l_TF_FireImmunity = 0
        ent.l_TF_FireEngulfSound = nil
        ent.l_TF_BurnDamage = 3
        ent.l_TF_BurnDamageCustom = TF_DMG_CUSTOM_BURNING

        ent.l_TF_CoveredInUrine = false
        ent.l_TF_CoveredInMilk = false

        ent.l_TF_LastTakeDamageTime = 0
        ent.l_TF_NextCritShootSoundT = 0

        ent.l_TF_HasOverheal = false
        ent.l_TF_HealFraction = 0
        ent.l_TF_OverhealDecreaseStartT = 0
        ent.l_TF_HealRateMultiplier = 1.0
        ent.l_TF_InvulnerabilityTime = 0
        ent.l_TF_MegaHealingTime = 0

        ent.l_TF_IsStunned = false
        ent.l_TF_JustGotStunned = true
        ent.l_TF_StunStateChangeT = 0
        ent.l_TF_PreStunState = nil
        ent.l_TF_StunMovement = false
        ent.l_TF_StunSpeedReduction = 1

        ent.l_TF_CritBoosts = {}
        ent.l_TF_LastCritBoost = TF_CRIT_NONE

        ent.l_TF_InSpeedBoost = false
        ent.l_TF_SpeedBoostActive = false
        ent.l_TF_SpeedBoostIsBuff = false
        ent.l_TF_SpeedBoostTrail = NULL

        ent.l_TF_OffenseBuffActive = false
        ent.l_TF_DefenseBuffActive = false
        ent.l_TF_SpeedBuffActive = false

        ent.l_TF_LastDamageResistSoundTime = 0
        ent.l_TF_NextLockerResupplyTime = 0
        ent.l_TF_UnansweredKills = {}
        ent.l_TF_AttackBonusEffect = {}
        ent.l_TF_BonemergedModels = {}

        ent.l_TF_WaterExitTime = false
        ent.l_TF_OldWaterLevel = 0

        ent:SetNW2Bool( "lambda_tf2_decapitatehead", false )
        ent:SetNW2Bool( "lambda_tf2_turnintoice", false )
        ent:SetNW2Bool( "lambda_tf2_turnintogold", false )
        ent:SetNW2Bool( "lambda_tf2_turnintoashes", false )
        ent:SetNW2Bool( "lambda_tf2_dissolve", false )
        ent:SetNW2Bool( "lambda_tf2_bleeding", false )
        ent:SetNW2Bool( "lambda_tf2_isjarated", false )

        if LAMBDA_TF2:IsValidCharacter( ent, false ) then
            local hookName = "LambdaTF2_EntityThink_" .. ent:GetClass() .. "_" .. ent:GetCreationID()
            hook_Add( "Think", hookName, function() 
                if !IsValid( ent ) then hook_Remove( "Think", hookName ) return end
                LAMBDA_TF2:EntityThink( ent )
            end )
        end
    else
        ent.l_TF_LastAttackBonusEffectT = CurTime()
        ent.l_TF_OverheadEffects = {}

        if LAMBDA_TF2:IsValidCharacter( ent, false ) then
            local hookName = "LambdaTF2_UpdateOverheadEffects_" .. ent:GetClass() .. ent:EntIndex()
            hook_Add( "Tick", hookName, function()
                if !IsValid( ent ) then hook_Remove( "Tick", hookName ) return end

                local effectTbl = ent.l_TF_OverheadEffects
                if !effectTbl then return end

                local effectCount = table_Count( effectTbl )
                if effectCount == 0 then return end

                local shouldDraw = ( !ent:GetNoDraw() and !ent:IsDormant() )
                local rightOffset, firstEffectOffset
                if shouldDraw then
                    firstEffectOffset = ( -12 * ( effectCount - 1 ) )

                    local eyePos
                    if ent.IsLambdaPlayer then 
                        eyePos = ent:GetAttachmentPoint( "eyes" ).Pos
                    else
                        eyePos = ent:EyePos()
                    end
                    eyeOffsetVec.z = ( eyePos.z - ent:GetPos().z + 20 )

                    local headDir = ( eyePos - LocalPlayer():EyePos() )
                    rightOffset = headDir:Cross( vector_up ):GetNormalized()
                end

                local validEffectCount = 0
                for name, effect in pairs( effectTbl ) do
                    if !IsValid( effect ) then
                        ent.l_TF_OverheadEffects[ name ] = nil
                        continue 
                    end

                    if shouldDraw then
                        local curOffset = ( firstEffectOffset + 24 * validEffectCount )
                        local finOffset = ( eyeOffsetVec + curOffset * rightOffset )
                        effect:AddControlPoint( 0, ent, PATTACH_ABSORIGIN_FOLLOW, 0, finOffset )
                        validEffectCount = ( validEffectCount + 1 )
                    end
                    effect:SetShouldDraw( shouldDraw )
                end
            end )
        end
    end
end

local function OnLambdaUseWeapon( lambda, target )
    if lambda.l_TF_AtomicPunched then return end
    lambda:l_TF_OldUseWeapon( target ) 
end

local function TFState_HealWithMedigun( lambda )
    LAMBDA_TF2:LambdaMedigunAI( lambda )
end

local taunts = {
    [ "scout_taunt_flip" ] = {
        PartnerOffset = Vector( 80, 0, 0 )
    }
}

local function TFState_TauntWithPartner( lambda )
    local partner = NULL

    for _, v in ipairs( GetLambdaPlayers() ) do
        if v == lambda or v:GetState() != "TauntWithPartner" or !lambda:IsInRange( v, 1000 ) or !lambda:CanSee( v ) then continue end
        partner = v
        break  
    end

    if IsValid( partner ) then
        lambda:MoveToPos( partner:GetPos(), {tol=64} )
        
        lambda.TauntPartner = partner
        partner.TauntPartner = lambda

        lambda:GetWeaponENT():SetNoDraw( true )
        lambda:GetWeaponENT():DrawShadow( false )

        local offset = partner.TauntData.PartnerOffset
        lambda:SetPos( partner:GetPos() + partner:GetForward() * offset.x + partner:GetRight() * offset.y + partner:GetUp() * offset.z )
        lambda:SetAngles( ( partner:GetPos() - lambda:GetPos() ):Angle() )

        local receiverAnim, receiverWaitT = lambda:LookupSequence( partner.TauntName .. "_receiver" )
        lambda:AddGestureSequence( receiverAnim )
        coroutine_wait( receiverWaitT )

        lambda:GetWeaponENT():SetNoDraw( lambda:IsWeaponMarkedNodraw() )
        lambda:GetWeaponENT():DrawShadow( !lambda:IsWeaponMarkedNodraw() )

        lambda:SetState( "Idle" )
    else
        lambda.TauntData, lambda.TauntName = table_Random( taunts )

        lambda:GetWeaponENT():SetNoDraw( true )
        lambda:GetWeaponENT():DrawShadow( false )

        local startAnim, startLoopTime = lambda:LookupSequence( lambda.TauntName .. "_start" )
        lambda:AddGestureSequence( startAnim )

        local loopAnimEndTime = ( CurTime() + startLoopTime )

        local stopTauntTime = ( CurTime() + random( 20, 40 ) )
        while ( !IsValid( lambda.TauntPartner ) and CurTime() < stopTauntTime ) do
            if CurTime() > loopAnimEndTime then
                local loopAnim, loopEndTime = lambda:LookupSequence( lambda.TauntName .. "_loop" )
                lambda:AddGestureSequence( loopAnim )
                loopAnimEndTime = ( CurTime() + loopEndTime )
            end

            coroutine_yield()
        end

        if IsValid( lambda.TauntPartner ) then
            local initiatorAnim, initiatorWaitT = lambda:LookupSequence( lambda.TauntName .. "_initiator" )
            lambda:AddGestureSequence( initiatorAnim )
            coroutine_wait( initiatorWaitT )
        end

        lambda:GetWeaponENT():SetNoDraw( lambda:IsWeaponMarkedNodraw() )
        lambda:GetWeaponENT():DrawShadow( !lambda:IsWeaponMarkedNodraw() )

        lambda:SetState( "Idle" )
    end
end

local function OnLambdaInitialize( lambda, weapon )
    LAMBDA_TF2:PseudoNetworkVar( lambda, "NextMeleeCrit", TF_CRIT_NONE )
    LAMBDA_TF2:PseudoNetworkVar( lambda, "IsShieldCharging", false ) 
    LAMBDA_TF2:PseudoNetworkVar( lambda, "ShieldChargeMeter", 100.001 ) 
    LAMBDA_TF2:PseudoNetworkVar( lambda, "ShieldLastNoChargeTime", CurTime() )

    local objectorImgs = table_Copy( LambdaPlayerSprays )
    if objectorIncludePfps:GetBool() then
        objectorImgs = table_Merge( objectorImgs, Lambdaprofilepictures )
    end

    local objectorPath = ( #objectorImgs != 0 and objectorImgs[ random( #objectorImgs ) ] )
    if !objectorPath then 
        objectorPath = ""
    elseif SERVER and !EndsWith( objectorPath, ".vtf" ) then
        net.Start( "lambda_tf2_addobjectorimage" )
            net.WriteString( objectorPath )
        net.Broadcast()
    end
    LAMBDA_TF2:PseudoNetworkVar( lambda, "ObjectorImage", objectorPath )

    weapon.l_TF_Owner = lambda

    if ( SERVER ) then
        lambda:SetShieldChargeMeter( 100 )

        lambda.l_TF_DamageEvents = {}
        lambda.l_TF_CritMult = 0
        lambda.l_TF_NextCritUpdateT = CurTime()
        
        lambda.l_TF_Decapitations = 0

        lambda.l_TF_Shield_PreChargeYawRate = lambda.loco:GetMaxYawRate()
        lambda.l_TF_Shield_Entity = NULL
        lambda.l_TF_Shield_Type = false
        lambda.l_TF_Shield_CritBoosted = false
        lambda.l_TF_Shield_CritBoostSound = nil
        lambda.l_TF_Shield_ChargeDrainRateMult = 1.0

        lambda.l_TF_AtomicPunched = false
        lambda.l_TF_AtomicPunched_Trail = NULL
        lambda.l_TF_AtomicPunched_DamageTaken = 0
        lambda.l_TF_AtomicPunched_SlowdownScale = false
        lambda.l_TF_AtomicPunched_SlowdownTime = 0

        lambda.l_TF_DiamondbackCrits = 0
        lambda.l_TF_FrontierJusticeKills = 0
        lambda.l_TF_RevengeCrits = 0

        lambda.TauntName = NULL
        lambda.TauntPartner = NULL
        lambda.TauntData = vector_origin

        lambda.l_TF_OldUseWeapon = lambda.UseWeapon
        lambda.UseWeapon = OnLambdaUseWeapon
        
        lambda.l_TF_CrikeyMeter = 0
        lambda.l_TF_CrikeyMeterFull = false

        lambda.l_TF_ThrownBaseball = false

        lambda.l_TF_DalokohsBars = {}

        lambda.l_TF_CollectedOrgans = 0

        lambda.l_TF_DonkVictims = {}

        lambda.l_TF_RageActivated = false
        lambda.l_TF_RageBuffType = nil
        lambda.l_TF_RageMeter = 0
        lambda.l_TF_RagePulseCount = 0
        lambda.l_TF_RageNextPulseTime = 0
        lambda.l_TF_RageBuffPack = NULL

        lambda.l_TF_MmmphActivated = false
        lambda.l_TF_MmmphMeter = 0

        lambda.l_TF_SniperShieldType = nil
        lambda.l_TF_SniperShieldModel = NULL
        lambda.l_TF_SniperShieldRechargeT = 0

        lambda.l_TF_ParachuteModel = NULL
        lambda.l_TF_ParachuteOpen = false
        lambda.l_TF_ParachuteCheckT = ( CurTime() + 1.0 )

        lambda.l_TF_HypeMeter = 0
        lambda.l_TF_HasGlovesOfRunning = false
        lambda.l_TF_HasMedigunEquipped = false
        lambda.l_TF_HasEdibles = false

        lambda.l_TF_MedicsToIgnoreList = {}

        lambda.l_TF_GRU_MaxHealth = lambda:GetMaxHealth()
        lambda.l_TF_GRU_MinHealth = Round( lambda.l_TF_GRU_MaxHealth * 0.5 )
        lambda.l_TF_GRU_DrainRate = Round( lambda.l_TF_GRU_MaxHealth * 0.2 )
        lambda.l_TF_GRU_DrainedHP = 0
        lambda.l_TF_GRU_ActionTime = 0

        lambda.l_TF_MedicTargetFilter = nil
        lambda.l_TF_MedigunChargeReleaseSound = "player/invulnerable_on.wav"
        lambda.l_TF_MedigunChargeDrainSound = "player/invulnerable_off.wav"

        lambda.l_TF_NextHealthRegenT = 0
        lambda.l_TF_Medic_HealTarget = NULL
        lambda.l_TF_Medic_TargetSearchT = 0

        lambda.l_TF_TeamColor = ( ( lambda:GetPlyColor()[ 3 ] > lambda:GetPlyColor()[ 1 ] ) and 1 or 0 )
        lambda:SimpleTimer( 0.2, function() lambda.l_TF_TeamColor = ( ( lambda:GetPlyColor()[ 3 ] > lambda:GetPlyColor()[ 1 ] ) and 1 or 0 ) end, true)

        lambda.l_TF_Medigun_ChargeMeter = 0
        lambda.l_TF_Medigun_ChargeReleased = false
        lambda.l_TF_Medigun_ChargeReady = false
        lambda.l_TF_Medigun_ChargeSound = nil

        lambda.HealWithMedigun = TFState_HealWithMedigun
        lambda.TauntWithPartner = TFState_TauntWithPartner

        lambda.l_TF_IsUsingItem = false
        lambda.l_TF_Inventory = {}
        lambda.l_TF_NextInventoryCheckT = ( CurTime() + Rand( 0.1, 1.0 ) )
        lambda.l_TF_PreInventorySwitchWeapon = nil
        lambda.l_TF_HasBackpackItem = false

        LAMBDA_TF2:AssignLambdaInventory( lambda )
    end
end

local function OnEntityRemoved( ent )
    if ( CLIENT ) then
        local overheadEffects = ent.l_TF_OverheadEffects
        if overheadEffects then
            for _, effect in pairs( overheadEffects ) do
                if !IsValid( effect ) then continue end
                effect:StopEmission( false, true )
            end
        end
    end

    local loopingSnds = ent.l_TF_LoopingSounds
    if loopingSnds then
        for soundName, soundPatch in pairs( loopingSnds ) do
            ent:StopSound( soundName )
            if !IsValid( soundPatch ) then continue end
            soundPatch:Stop()
            soundPatch = NULL
        end
    end
end


hook_Add( "OnEntityCreated", "LambdaTF2_OnEntityCreated", OnEntityCreated )
hook_Add( "PlayerInitialSpawn", "LambdaTF2_OnPlayerInitialSpawn", OnEntityCreated )
hook_Add( "LambdaOnInitialize", "LambdaTF2_OnLambdaInitialize", OnLambdaInitialize )
hook_Add( "EntityRemoved", "LambdaTF2_OnEntityRemoved", OnEntityRemoved )