local LocalPlayer = LocalPlayer
local net = net
local CreateParticleSystem = CreateParticleSystem
local CurTime = CurTime
local IsValid = IsValid
local ipairs = ipairs
local random = math.random
local min = math.min
local max = math.max
local SimpleTimer = timer.Simple
local GetConVar = GetConVar
local StripExtension = string.StripExtension

local killiconClr = Color( 255, 80, 0, 255 )
local killIconBleed = Color( 255, 0, 0 )
local stunStarsOffset = ( vector_up * 80 )
local medigunBeamOffset = ( vector_up * 36 )
local vector_one = Vector( 1, 1, 1 )
local minicritClrVec = Vector( 1, 25, 25 )
local minicritClrVec2 = Vector( 127, 176, 98 )

local critHitData = {
    [ TF_CRIT_FULL ] = { "crit_text", {
        "player/crit_hit.wav",
        "player/crit_hit2.wav",
        "player/crit_hit3.wav",
        "player/crit_hit4.wav",
        "player/crit_hit5.wav"
    } },
    [ TF_CRIT_MINI ] = { "minicrit_text", {
        "player/crit_hit_mini.wav",
        "player/crit_hit_mini2.wav",
        "player/crit_hit_mini3.wav",
        "player/crit_hit_mini4.wav",
        "player/crit_hit_mini5.wav"
    } }
}

LAMBDA_TF2 = LAMBDA_TF2 or {}

LAMBDA_TF2.ObjectorSprayImages = LAMBDA_TF2.ObjectorSprayImages or {}
PrintTable( LAMBDA_TF2.ObjectorSprayImages )

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
    if IsValid( ent ) then ent:StopParticlesNamed( net.ReadString() ) end
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
        
        if victim == ply or attacker == ply or GetConVar( "lambdaplayers_tf2_alwaysplayrivalrysnd" ):GetBool() then
            EmitSound( "#misc/tf_domination.wav", vector_origin, -1, CHAN_STATIC, 0.65, 75, 0, 100 )
        end
    elseif rivalryType == 2 then
        GAMEMODE:AddDeathNotice( attackername, attackerteam, "lambdaplayers_tf2_rivalry_revenge", victimname, victimteam )
        
        if victim == ply or attacker == ply or GetConVar( "lambdaplayers_tf2_alwaysplayrivalrysnd" ):GetBool() then
            EmitSound( "#misc/tf_revenge.wav", vector_origin, -1, CHAN_STATIC, 0.65, 75, 0, 100 )
        end
    end
end )

net.Receive( "lambda_tf2_removecsragdoll", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end
    
    local ragdoll = lambda.ragdoll
    if !IsValid( ragdoll ) then return end 
    
    ragdoll:Remove()
    ragdoll.ragdoll = nil
end )

net.Receive( "lambda_tf2_removecsprop", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local cs_prop = lambda.cs_prop
    if !IsValid( cs_prop ) then return end

    cs_prop:Remove()
    lambda.cs_prop = nil
end )

net.Receive( "lambda_tf2_criteffects", function()
    local receiver = net.ReadEntity()
    if !IsValid( receiver ) or ( CurTime() - receiver.l_TF_LastCritEffectTime ) <= ( RealFrameTime() * 2 ) then return end

    local critType = net.ReadUInt( 2 )
    local critData = critHitData[ critType ]

    local textPos = net.ReadVector()
    local critPart = CreateParticleSystem( Entity( 0 ), critData[ 1 ], PATTACH_WORLDORIGIN, 0, textPos )

    receiver.l_TF_LastCritEffectTime = CurTime()
    receiver:EmitSound( critData[ 2 ][ random( #critData[ 2 ] ) ], 80, nil, nil, CHAN_STATIC )

    local ply = LocalPlayer()
    critPart:SetShouldDraw( ply != receiver )

    if ply == receiver and critType == TF_CRIT_FULL then
        local lethal = net.ReadBool()
        if lethal then receiver:EmitSound( "player/crit_received" .. random( 1, 3 ) .. ".wav", 80, random( 95, 105 ), nil, CHAN_STATIC ) end
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
    ParticleEffectAttach( partName, PATTACH_ABSORIGIN_FOLLOW, ragdoll, 0 )

    SimpleTimer( net.ReadFloat(), function()
        if !IsValid( ragdoll ) then return end 
        ragdoll:StopParticlesNamed( partName )
    end )
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

    stunnedEffect = CreateParticleSystem( ent, "conc_stars", PATTACH_ABSORIGIN_FOLLOW, 0, stunStarsOffset )
    ent.l_TF_StunnedEffect = stunnedEffect
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

// Hooks
local function OnCreateClientsideRagdoll( owner, ragdoll )
    if owner.IsLambdaPlayer then return end

    local turnIntoIce = owner:GetNW2Bool( "lambda_tf2_turnintoice", false )
    if turnIntoIce or owner:GetNW2Bool( "lambda_tf2_turnintogold", false ) then
        local bodygroupData = {}
        for _, data in ipairs( ragdoll:GetBodyGroups() ) do
            bodygroupData[ data.id ] = ragdoll:GetBodygroup( data.id )
        end

        local transformData = {}
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do    
            local bonePhys = ragdoll:GetPhysicsObjectNum( i )
            transformData[ i ] = { bonePhys:GetPos(), bonePhys:GetAngles(), bonePhys:GetVelocity() }
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
            ragdoll:Remove()
        end
    else
        if owner:GetNW2Bool( "lambda_tf2_decapitatehead", false ) then
            LAMBDA_TF2:DecapitateHead( ragdoll, true, ( ragdoll:GetVelocity() * 5 ) )
        end

        if owner:GetIsBurning() then
            local teamClr = 0
            if owner:IsPlayer() then
                local plyColor = owner:GetPlayerColor()
                teamClr = ( ( plyColor[ 3 ] > plyColor[ 1 ] ) and 1 or 0 )
            end
            LAMBDA_TF2:AttachFlameParticle( ragdoll, max( 3, ( owner:GetFlameRemoveTime() - CurTime() ) ), teamClr )
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

hook.Add( "CreateClientsideRagdoll", "LambdaTF2_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )
hook.Add( "PostDrawViewModel", "LambdaTF2_OnPostDrawViewModel", OnPostDrawViewModel )
hook.Add( "RenderScreenspaceEffects", "LambdaTF2_EffectPostProcessings", PostProcessingsEffects )

// Material Proxies
matproxy.Add( {
    name = "ModelGlowColor",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        local result = vector_one

        if IsValid( ent ) then
            local owner = ( ent.l_TF_Owner or ent:GetOwner() )

            if IsValid( owner ) and owner.GetPlayerColor then
                local isCustom = ( mat:GetInt( "$iscustom" ) == 1 )
                local normCritMult = ( isCustom and 1.33 or 100 )

                local critBoost = owner:GetCritBoostType()
                if critBoost != TF_CRIT_NONE then
                    result = owner:GetPlayerColor()
                    if critBoost == TF_CRIT_MINI then
                        if isCustom then
                            result = minicritClrVec
                        else
                            result = minicritClrVec2
                        end
                    else
                        result = ( result * normCritMult )
                    end

                    owner.l_TF_ChargeGlowing = false
                elseif owner.IsLambdaPlayer then 
                    local charging = owner:GetIsShieldCharging()
                    if charging or owner:GetNextMeleeCrit() != TF_CRIT_NONE then
                        owner.l_TF_ChargeGlowing = true

                        local glow
                        if charging then
                            glow = ( ( 100 - owner:GetShieldChargeMeter() ) / 100 )
                        else
                            glow = ( 1.0 - min( ( CurTime() - owner:GetShieldLastNoChargeTime() - 1.5 ) / 0.3, 1.0 ) )
                        end

                        result = ( owner:GetPlayerColor() * normCritMult )
                        result[ 1 ] = max( result[ 1 ] * glow, 1 )
                        result[ 2 ] = max( result[ 2 ] * glow, 1 )
                        result[ 3 ] = max( result[ 3 ] * glow, 1 )
                    elseif owner.l_TF_ChargeGlowing then
                        local glow = ( 1.0 - min( ( CurTime() - owner:GetShieldLastNoChargeTime() ) / 0.3, 1.0 ) )
                        if glow <= 0 then owner.l_TF_ChargeGlowing = false end

                        result = ( owner:GetPlayerColor() * normCritMult )
                        result[ 1 ] = max( result[ 1 ] * glow, 1 )
                        result[ 2 ] = max( result[ 2 ] * glow, 1 )
                        result[ 3 ] = max( result[ 3 ] * glow, 1 )
                    end
                end
            end
        end

        mat:SetVector( self.ResultTo, result )
    end
} )
matproxy.Add( {
    name = "LambdaUberedModelColor",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        if !IsValid( ent ) then return end

        local plyClr = ent.GetPlayerColor
        if plyClr then
            local col = ( plyClr( ent ) * 0.5 )
            mat:SetVector( self.ResultTo, col )
            return
        end

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if !IsValid( owner ) then return end
        
        plyClr = owner.GetPlayerColor
        if !plyClr then return end

        local col = ( plyClr( owner ) * 0.5 )
        mat:SetVector( self.ResultTo, col )
    end
} )
matproxy.Add( {
    name = "LambdaInvulnLevel",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        if IsValid( ent ) and ent:GetIsInvulnerable() and ent:GetInvulnerabilityWearingOff() then
            mat:SetFloat( self.ResultTo, 0.0 )
            return
        end

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if IsValid( owner ) and owner:GetIsInvulnerable() and owner:GetInvulnerabilityWearingOff() then
            mat:SetFloat( self.ResultTo, 0.0 )
            return
        end

        mat:SetFloat( self.ResultTo, 1.0 )
    end
} )
matproxy.Add( {
    name = "CustomSteamImageOnModel",
    init = function( self, mat, values )
        self.DefaultTexture = mat:GetTexture( "$basetexture" )
    end,
    bind = function( self, mat, ent )
        mat:SetTexture( "$basetexture", self.DefaultTexture )
        if !IsValid( ent ) then return end 

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if !IsValid( owner ) or !owner.IsLambdaPlayer then return end

        local imagePath = owner:GetObjectorImage()
        mat:SetTexture( "$basetexture", ( LAMBDA_TF2.ObjectorSprayImages[ imagePath ] or StripExtension( imagePath ) ) )
    end
} )