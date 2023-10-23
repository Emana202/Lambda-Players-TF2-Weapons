local LocalPlayer = LocalPlayer
local net = net
local CreateParticleSystem = CreateParticleSystem
local IsValid = IsValid
local ipairs = ipairs
local random = math.random
local SimpleTimer = timer.Simple
local max = math.max
local hook_Add = hook.Add
local hook_Remove = hook.Remove
local GetConVar = GetConVar
local ents_CreateClientside = ents.CreateClientside

local killiconClr = Color( 255, 80, 0, 255 )
local killIconBleed = Color( 255, 0, 0 )
local medigunBeamOffset = ( vector_up * 36 )
local eyeHeightVec = Vector( 0, 0, 0 )

local TF_PARTICLE_WEAPON_RED_1 = Vector( 0.72, 0.22, 0.23 )
local TF_PARTICLE_WEAPON_RED_2 = Vector( 0.5, 0.18, 0.125 )
local TF_PARTICLE_WEAPON_BLUE_1 = Vector( 0.345, 0.52, 0.635 )
local TF_PARTICLE_WEAPON_BLUE_2 = Vector( 0.145, 0.427, 0.55 )

LAMBDA_TF2 = LAMBDA_TF2 or {}

LAMBDA_TF2.ObjectorSprayImages = LAMBDA_TF2.ObjectorSprayImages or {}

// Killicons
killicon.Add( "lambdaplayers_weaponkillicons_tf2_backstab", "lambdaplayers/killicons/icon_tf2_backstab", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_headshot", "lambdaplayers/killicons/icon_tf2_headshot", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_caber_explosion", "lambdaplayers/killicons/icon_tf2_caber", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_sandman_baseball", "lambdaplayers/killicons/icon_tf2_sandman_ball", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_chargintarge", "lambdaplayers/killicons/icon_tf2_chargintarge", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_splendidscreen", "lambdaplayers/killicons/icon_tf2_splendidscreen", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_tideturner", "lambdaplayers/killicons/icon_tf2_tideturner", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_fire", "lambdaplayers/killicons/icon_tf2_fire", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_katana_duel", "lambdaplayers/killicons/icon_tf2_katana_duel", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_backburner_behind", "lambdaplayers/killicons/icon_tf2_backburner_behind", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_ambassador_headshot", "lambdaplayers/killicons/icon_tf2_ambassador_headshot", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_holidaypunch_laugh", "lambdaplayers/killicons/icon_tf2_holidaypunch_laugh", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_loose_cannon_pushed", "lambdaplayers/killicons/icon_tf2_loose_cannon_pushed", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_sharpdresser_backstab", "lambdaplayers/killicons/icon_tf2_sharp_dresser_backstab", killiconClr )
killicon.Add( "lambdaplayers_weaponkillicons_tf2_bleedout", "lambdaplayers/killicons/icon_tf2_bleedout", killIconBleed )

killicon.Add( "lambdaplayers_tf2_rivalry_domination", "lambdaplayers/killicons/icon_tf2_domination", killiconClr )
killicon.Add( "lambdaplayers_tf2_rivalry_revenge", "lambdaplayers/killicons/icon_tf2_revenge", killiconClr )

// Networking
net.Receive( "lambda_tf2_addobjectorimage", function()
    local imagePath = net.ReadString()
    if LAMBDA_TF2.ObjectorSprayImages[ imagePath ] then return end

    local imageMat = Material( imagePath )
    if !IsValid( imageMat ) then return end

    local imageTex = imageMat:GetTexture( "$basetexture" )
    if !IsValid( imageTex ) or imageTex:IsErrorTexture() then return end

    LAMBDA_TF2.ObjectorSprayImages[ imagePath ] = imageTex
end )

net.Receive( "lambda_tf2_stopnamedparticle", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end 

    local partName = net.ReadString()
    ent:StopParticlesNamed( partName )
end )

net.Receive( "lambda_tf2_dispatchcolorparticle", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) or ent:IsDormant() then return end

    local trail
    local effectName = net.ReadString()
    local partAttachment = net.ReadUInt( 3 )
    if partAttachment == PATTACH_WORLDORIGIN then
        local origin = net.ReadVector()
        trail = CreateParticleSystem( Entity( 0 ), effectName, partAttachment, 0, origin )
    else
        local entAttachment = net.ReadUInt( 6 )
        trail = CreateParticleSystem( ent, effectName, partAttachment, entAttachment, vector_origin )
    end

    if IsValid( trail ) then
        local reverseClr = net.ReadBool()
        local customClr = net.ReadBool()

        local baseColor, secondColor
        if customClr then
            baseColor = net.ReadVector()
            secondColor = ( baseColor * 0.7 )
        else
            local teamColor = net.ReadUInt( 2 )
            baseColor = ( teamColor == 1 and TF_PARTICLE_WEAPON_BLUE_1 or TF_PARTICLE_WEAPON_RED_1 )
            secondColor = ( teamColor == 1 and TF_PARTICLE_WEAPON_BLUE_2 or TF_PARTICLE_WEAPON_RED_2 )
        end
        trail:SetControlPoint( 9, ( reverseClr and secondColor or baseColor ) )
        trail:SetControlPoint( 10, ( reverseClr and baseColor or secondColor ) )
    end
end )

net.Receive( "lambda_tf2_addoverheadeffect", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) or !ent.l_TF_OverheadEffects then return end

    local effectName = net.ReadString()
    if IsValid( ent.l_TF_OverheadEffects[ effectName ] ) then return end

    local effect = CreateParticleSystem( ent, effectName, PATTACH_ABSORIGIN_FOLLOW, 0, LAMBDA_TF2:GetOverheadEffectPosition( ent ) )
    if !IsValid( effect ) then return end

    ent.l_TF_OverheadEffects[ effectName ] = effect
end )

net.Receive( "lambda_tf2_removeoverheadeffect", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) or !ent.l_TF_OverheadEffects then return end

    local effectName = net.ReadString()
    local effect = ent.l_TF_OverheadEffects[ effectName ]
    if !IsValid( effect ) then return end

    effect:StopEmission( false, net.ReadBool() )
    ent.l_TF_OverheadEffects[ effectName ] = nil
end )

net.Receive( "lambda_tf2_domination", function()
    local rivalryType = net.ReadUInt( 2 )
    local attacker = net.ReadEntity()
    local victim = net.ReadEntity()

    local attackername = ( ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and attacker:Nick() or ( attacker.IsZetaPlayer and attacker.zetaname or "#" .. attacker:GetClass() ) )
    local attackerteam = ( ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and attacker:Team() or -1 )

    local victimname = ( ( victim.IsLambdaPlayer or victim:IsPlayer() ) and victim:Nick() or ( victim.IsZetaPlayer and victim.zetaname or "#" .. victim:GetClass() ) )
    local victimteam = ( ( victim.IsLambdaPlayer or victim:IsPlayer() ) and victim:Team() or -1 )

    local ply = LocalPlayer()
    if rivalryType == 1 then
        GAMEMODE:AddDeathNotice( attackername, attackerteam, "lambdaplayers_tf2_rivalry_domination", victimname, victimteam )
        if victim == ply then 
            LAMBDA_TF2:AddOverheadEffect( attacker, "particle_nemesis_red" )
            EmitSound( "#misc/tf_nemesis.wav", vector_origin, -1, CHAN_STATIC, 0.6, 75, 0, 100 )
        elseif attacker == ply or GetConVar( "lambdaplayers_tf2_alwaysplayrivalrysnd" ):GetBool() then
            EmitSound( "#misc/tf_domination.wav", vector_origin, -1, CHAN_STATIC, 0.6, 75, 0, 100 )
        end
    elseif rivalryType == 2 then
        GAMEMODE:AddDeathNotice( attackername, attackerteam, "lambdaplayers_tf2_rivalry_revenge", victimname, victimteam )

        if victim == ply or attacker == ply or GetConVar( "lambdaplayers_tf2_alwaysplayrivalrysnd" ):GetBool() then
            LAMBDA_TF2:RemoveOverheadEffect( victim, "particle_nemesis_red", true )
            EmitSound( "#misc/tf_revenge.wav", vector_origin, -1, CHAN_STATIC, 0.6, 75, 0, 100 )
        end
    end
end )

net.Receive( "lambda_tf2_removecsragdoll", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end
    
    local ragdoll = lambda.ragdoll
    if !IsValid( ragdoll ) then return end 
    
    ragdoll:Remove()
    lambda.ragdoll = nil
end )

net.Receive( "lambda_tf2_bonemergemodel", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end
    
    local ragdoll = lambda.ragdoll
    if !IsValid( ragdoll ) then return end 

    local mdlEnt = ents_CreateClientside( "base_gmodentity" )
    mdlEnt:SetModel( net.ReadString() )
    mdlEnt:SetPos( ragdoll:GetPos() )
    mdlEnt:SetAngles( ragdoll:GetAngles() )
    mdlEnt:SetOwner( ragdoll )
    mdlEnt:SetParent( ragdoll )
    mdlEnt:Spawn()
    mdlEnt:AddEffects( EF_BONEMERGE )
    function mdlEnt:Think() if !IsValid( ragdoll ) then mdlEnt:Remove() end end
end )

net.Receive( "lambda_tf2_removecsprop", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local cs_prop = lambda.cs_prop
    if !IsValid( cs_prop ) then return end

    cs_prop:Remove()
    lambda.cs_prop = nil
end )

net.Receive( "lambda_tf2_attackbonuseffect", function()
    local receiver = net.ReadEntity()
    if !IsValid( receiver ) or ( CurTime() - receiver.l_TF_LastAttackBonusEffectT ) <= ( RealFrameTime() * 2 ) then return end

    local ply = LocalPlayer()
    local partName = net.ReadString()
    local partOffset = net.ReadVector()
    if net.ReadBool() == true or ply != receiver then CreateParticleSystem( Entity( 0 ), partName, PATTACH_WORLDORIGIN, 0, partOffset ) end

    receiver:EmitSound( net.ReadString(), 80, nil, nil, CHAN_STATIC )
    receiver.l_TF_LastAttackBonusEffectT = CurTime()

    if ply == receiver and partName == "crit_text" and net.ReadBool() == true then
        receiver:EmitSound( "player/crit_received" .. random( 3 ) .. ".wav", 80, random( 95, 105 ), nil, CHAN_STATIC )
    end
end )

net.Receive( "lambda_tf2_decapitate_csragdoll", function()
    LAMBDA_TF2:DecapitateHead( net.ReadEntity(), net.ReadBool(), net.ReadVector() )
end )

net.Receive( "lambda_tf2_ignite_csragdoll", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end
    
    local ragdoll = lambda.ragdoll
    if !IsValid( ragdoll ) then return end 
    
    local partName = net.ReadString()
    local removeTime = net.ReadFloat()
    LAMBDA_TF2:AttachFlameParticle( ragdoll, removeTime, partName )

    local turnIntoAshes = net.ReadBool()
    if turnIntoAshes then
        ragdoll:SetRenderMode( RENDERMODE_TRANSCOLOR )
        ParticleEffectAttach( "drg_fiery_death", PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )

        local removeT = ( CurTime() + 0.5 )
        LambdaCreateThread( function()
            while ( IsValid( ragdoll ) and CurTime() < removeT ) do
                local ragColor = ragdoll:GetColor()
                ragColor.a = LAMBDA_TF2:RemapClamped( ( removeT - CurTime() ), 0, 0.5, 0, 255 )

                ragdoll:SetColor( ragColor )
                coroutine.yield()
            end
            if IsValid( ragdoll ) then 
                if ragdoll:GetClass() == "class C_HL2MPRagdoll" then
                    net.Start( "lambda_tf2_removempragdoll" )
                        net.WriteEntity( ragdoll )
                    net.SendToServer()
                else
                    ragdoll:Remove()
                end
            end
        end )
    end
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

    local createNew = net.ReadBool()
    if createNew then
        stunnedEffect = CreateParticleSystem( ent, "conc_stars", PATTACH_ABSORIGIN_FOLLOW, 0, Vector( 0, 0, ent:OBBMaxs().z + 10 ) )
        ent.l_TF_StunnedEffect = stunnedEffect
    end
end )

net.Receive( "lambda_tf2_medigun_chargeeffect", function()        
    local medigun = net.ReadEntity()
    if !IsValid( medigun ) then return end
    
    local chargeEffect = medigun.l_TF_ChargeEffect
    local charged = net.ReadBool()
    if charged then
        if !IsValid( chargeEffect ) then
            chargeEffect = CreateParticleSystem( medigun, "medicgun_invulnstatus_fullcharge_" .. ( net.ReadUInt( 1 ) == 1 and "blue" or "red" ), PATTACH_POINT_FOLLOW, medigun:LookupAttachment( "muzzle" ) )
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

    local beamNormal = medigun.l_TF_BeamEffect
    local beamCharged = medigun.l_TF_BeamChargedEffect
    local beamSparks = medigun.l_TF_BeamSparkEffect

    local healTarget = net.ReadEntity()
    if !IsValid( healTarget ) then
        if IsValid( beamNormal ) then 
            beamNormal:StopEmission() 
            medigun.l_TF_BeamEffect = nil
        end

        if IsValid( beamCharged ) then 
            beamCharged:StopEmission() 
            medigun.l_TF_BeamChargedEffect = nil
        end

        if IsValid( beamSparks ) then 
            beamSparks:StopEmission() 
            medigun.l_TF_BeamSparkEffect = nil
        end
        
        return
    end

    local muzzleAttach = medigun:LookupAttachment( "muzzle" )
    local beamClr = net.ReadUInt( 1 )
    beamClr = ( beamClr == 1 and "blue" or "red" )

    local charged = net.ReadBool()
    if charged then
        if IsValid( beamNormal ) then 
            beamNormal:StopEmission() 
            medigun.l_TF_BeamEffect = nil
        end

        if !IsValid( beamCharged ) then
            beamCharged = CreateParticleSystem( medigun, "medicgun_beam_" .. beamClr .. "_invun" , PATTACH_POINT_FOLLOW, muzzleAttach )
            beamCharged:AddControlPoint( 1, healTarget, PATTACH_ABSORIGIN_FOLLOW, 0, medigunBeamOffset )
            medigun.l_TF_BeamChargedEffect = beamCharged
        end
    else
        if IsValid( beamCharged ) then 
            beamCharged:StopEmission() 
            medigun.l_TF_BeamChargedEffect = nil
        end

        if !IsValid( beamNormal ) then
            beamNormal = CreateParticleSystem( medigun, "medicgun_beam_" .. beamClr, PATTACH_POINT_FOLLOW, muzzleAttach )
            beamNormal:AddControlPoint( 1, healTarget, PATTACH_ABSORIGIN_FOLLOW, 0, medigunBeamOffset )
            medigun.l_TF_BeamEffect = beamNormal
        end
    end

    local hasSparks = net.ReadBool()
    if hasSparks then
        if !IsValid( beamSparks ) then
            beamSparks = CreateParticleSystem( medigun, "medicgun_beam_attrib_overheal_" .. beamClr, PATTACH_POINT_FOLLOW, muzzleAttach )
            beamSparks:AddControlPoint( 1, healTarget, PATTACH_ABSORIGIN_FOLLOW, 0, medigunBeamOffset )
            medigun.l_TF_BeamSparkEffect = beamSparks
        end
    elseif IsValid( beamSparks ) then 
        beamSparks:StopEmission() 
        medigun.l_TF_BeamSparkEffect = nil
    end
end )

// Atrocious detour
local entMeta = FindMetaTable( "Entity" )
if !LAMBDA_TF2.OldRemove then LAMBDA_TF2.OldRemove = entMeta.Remove end

function entMeta:Remove()
    if self:IsRagdoll() then 
        local loopingSnds = self.l_TF_LoopingSounds
        if loopingSnds then
            for soundName, soundPatch in pairs( loopingSnds ) do
                self:StopSound( soundName )
                if !IsValid( soundPatch ) then continue end
                soundPatch:Stop()
                soundPatch = NULL
            end
        end
    end

    LAMBDA_TF2.OldRemove( self )
end

// Hooks
local function OnCreateClientsideRagdoll( owner, ragdoll )
    if owner.IsLambdaPlayer then return end

    local turnIntoIce = owner:GetNW2Bool( "lambda_tf2_turnintoice", false )
    if turnIntoIce or owner:GetNW2Bool( "lambda_tf2_turnintogold", false ) then
        local bodygroupData = {}
        for _, data in ipairs( ragdoll:GetBodyGroups() ) do
            local id = data.id
            bodygroupData[ #bodygroupData + 1 ] = { id, ragdoll:GetBodygroup( id ) }
        end

        local transformData = {}
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do    
            local bonePhys = ragdoll:GetPhysicsObjectNum( i )
            transformData[ #transformData + 1 ] = { i, bonePhys:GetPos(), bonePhys:GetAngles(), bonePhys:GetVelocity() }
        end

        net.Start( "lambda_tf2_turncsragdollintostatue" )
            net.WriteString( ragdoll:GetModel() )
            net.WriteVector( ragdoll:GetPos() )
            net.WriteAngle( ragdoll:GetAngles() )
            net.WriteUInt( ragdoll:GetSkin(), 8 )
            net.WriteTable( bodygroupData )
            net.WriteBool( turnIntoIce )
            net.WriteTable( transformData )
            net.WriteEntity( owner )
            net.WriteEntity( ragdoll )
        net.SendToServer()

        if ragdoll:GetClass() == "class C_ClientRagdoll" then
            net.Start( "lambda_tf2_removempragdoll" )
                net.WriteEntity( ragdoll )
            net.SendToServer()
        end
    else
        if owner:GetNW2Bool( "lambda_tf2_dissolve", false ) then
            ragdoll:EmitSound( "player/dissolve.wav", nil, nil, nil, CHAN_STATIC )
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
                        coroutine.yield()
                    end
                    if IsValid( ragdoll ) then ragdoll:Remove() end
                end )
            end
        end

        if owner:GetIsBurning() then
            local teamClr = 0
            if owner:IsPlayer() then
                local plyColor = owner:GetPlayerColor()
                teamClr = ( ( plyColor[ 3 ] > plyColor[ 1 ] ) and 1 or 0 )
            end
            LAMBDA_TF2:AttachFlameParticle( ragdoll, max( 2, ( owner:GetFlameRemoveTime() - CurTime() ) ), teamClr )
        end
    end
end

local function OnPostDrawViewModel( vm, ply, wep )
    local hands = ply:GetHands()

    local critBoost = ply:GetCritBoostType()
    local invuln = ply:GetIsInvulnerable()
    
    if critBoost == TF_CRIT_NONE and !invuln then
        if vm.l_TF_PreVMMat then 
            vm:SetMaterial( vm.l_TF_PreVMMat )
            vm.l_TF_PreVMMat = nil
        end
        if IsValid( hands ) and hands.l_TF_PreVMMat then
            hands:SetMaterial( hands.l_TF_PreVMMat )
            hands.l_TF_PreVMMat = nil
        end
    else
        if !vm.l_TF_PreVMMat then
            vm.l_TF_PreVMMat = vm:GetMaterial()

            if critBoost != TF_CRIT_NONE then
                vm:SetMaterial( LAMBDA_TF2:GetCritGlowMaterial() )
            elseif invuln then
                vm:SetMaterial( LAMBDA_TF2:GetInvulnMaterial() )
            end
        end
        if invuln and IsValid( hands ) and !hands.l_TF_PreVMMat then
            hands.l_TF_PreVMMat = hands:GetMaterial()
            hands:SetMaterial( LAMBDA_TF2:GetInvulnMaterial() )
        end
    end
end

local function PostProcessingsEffects()
    local ply = LocalPlayer()
    
    if ply:GetIsInvulnerable() then
        DrawMaterialOverlay( "effects/invuln_overlay_red", 0 )
    end

    if ply:GetIsBurning() then
        DrawMaterialOverlay( "lambdaplayers/effects/lethimcook", 0 )
    end

    if ply:GetNW2Bool( "lambda_tf2_bleeding", false ) then
        DrawMaterialOverlay( "effects/bleed_overlay", 0 )
    end

    if ply:GetNW2Bool( "lambda_tf2_isjarated", false ) then
        DrawMaterialOverlay( "effects/jarate_overlay", 0 )
    end
end

hook_Add( "CreateClientsideRagdoll", "LambdaTF2_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )
hook_Add( "PostDrawViewModel", "LambdaTF2_OnPostDrawViewModel", OnPostDrawViewModel )
hook_Add( "RenderScreenspaceEffects", "LambdaTF2_EffectPostProcessings", PostProcessingsEffects )