local min = math.min
local TraceLine = util.TraceLine
local net = net
local FrameTime = FrameTime
local CurTime = CurTime
local IsValid = IsValid
local random = math.random

local medigunTraceTbl = {
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    filter = { NULL, NULL, NULL }
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_kritzkrieg = {
        model = "models/lambdaplayers/tf2/weapons/w_medigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Kritzkrieg",
        holdtype = "physgun",
        bonemerge = true,
    
		islethal = true,
        deploydelay = 0.5,

        ismedigun = true,
        medictargetfilter = function( lambda, target )
            if lambda.l_TF_Medigun_ChargeReady then
                return ( !target.IsLambdaPlayer and IsValid( target:GetActiveWeapon() ) or target.IsLambdaPlayer and target.l_HasLethal )
            end
        end,
        chargereleasesnd = ")weapons/weapon_crit_charged_on.wav",
        chargedrainedsnd = ")weapons/weapon_crit_charged_off.wav",

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetBodygroup( 1, 1 )

            wepent.l_HealTarget = NULL
            wepent.l_LastHealTarget = NULL
            wepent.l_HealTime = 0
            wepent.l_HealGiveTime = 0
            wepent.l_HealSound = LAMBDA_TF2:CreateSound( wepent, ")weapons/medigun_heal.wav" )
            
            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )

            net.Start( "lambda_tf2_medigun_beameffect" )
                net.WriteEntity( wepent )
                net.WriteEntity( NULL )
            net.Broadcast()
        end,

        OnThink = function( self, wepent, isdead )
            local healTarget = wepent.l_HealTarget
            local healSnd = wepent.l_HealSound
            local lastTarget = wepent.l_LastHealTarget

            if !IsValid( healTarget ) and IsValid( lastTarget ) or IsValid( healTarget ) and ( isdead or CurTime() > wepent.l_HealTime or !LAMBDA_TF2:IsValidCharacter( healTarget ) or IsValid( lastTarget ) and lastTarget != healTarget ) then
                if IsValid( lastTarget ) and lastTarget != healTarget then healTarget = lastTarget end
                if LambdaIsValid( healTarget ) and healTarget.IsLambdaPlayer and healTarget:Health() >= healTarget:GetMaxHealth() and random( 1, 100 ) <= healTarget:GetVoiceChance() and ( healTarget:GetLastSpokenVoiceType() != "assist" or !healTarget:IsSpeaking() ) then
                    healTarget:PlaySoundFile( "assist" )
                end

                healTarget = NULL
                wepent.l_HealTarget = healTarget

                wepent:EmitSound( ")weapons/medigun_heal_detach.wav", nil, nil, nil, CHAN_STATIC )
                if healSnd and healSnd:IsPlaying() then healSnd:Stop() end
                self.l_WeaponUseCooldown = ( CurTime() + 0.5 )

                net.Start( "lambda_tf2_medigun_beameffect" )
                    net.WriteEntity( wepent )
                    net.WriteEntity( NULL )
                net.Broadcast()
            elseif !isdead and IsValid( healTarget ) then
                if healSnd and !healSnd:IsPlaying() then 
                    healSnd:PlayEx( 0.75, 100 ) 
                end

                if CurTime() > wepent.l_HealGiveTime then
                    LAMBDA_TF2:GiveHealth( healTarget, 1 )
                    if healTarget.l_TF_IsBurning then
                        healTarget.l_TF_FlameRemoveTime = ( healTarget.l_TF_FlameRemoveTime - ( 1 / ( healTarget.l_TF_FlameRemoveTime - CurTime() ) ) )
                    end
                    local bleedInfo = healTarget.l_TF_BleedInfo
                    if bleedInfo and #bleedInfo > 0 then
                        for _, info in ipairs( bleedInfo ) do
                            info.ExpireTime = ( info.ExpireTime - ( 1 / ( info.ExpireTime - CurTime() ) ) )
                        end
                    end

                    wepent.l_HealGiveTime = ( CurTime() + LAMBDA_TF2:GetMediGunHealRate( self, healTarget ) )
                end

                if self.l_TF_Medigun_ChargeReleased then
                    LAMBDA_TF2:AddCritBoost( healTarget, "KritzkriegCrits", CRIT_FULL, 0.1 )
                else
                    local chargeRate = 3.125
                    if healTarget:Health() > ( healTarget:GetMaxHealth() * 1.425 ) then chargeRate = ( chargeRate * 0.5 ) end
                    self.l_TF_Medigun_ChargeMeter = min( 100, self.l_TF_Medigun_ChargeMeter + ( chargeRate * FrameTime() ) )
                end

                net.Start( "lambda_tf2_medigun_beameffect" )
                    net.WriteEntity( wepent )
                    net.WriteEntity( healTarget )
                    net.WriteUInt( self.l_TF_Medigun_BeamColor, 3 )
                    net.WriteBool( self.l_TF_Medigun_ChargeReleased )
                    net.WriteBool( true )
                net.Broadcast()
            end

            wepent.l_LastHealTarget = healTarget
        end,

        OnHolster = function( self, wepent )
            if IsValid( wepent.l_HealTarget ) then 
                wepent:EmitSound( ")weapons/medigun_heal_detach.wav", nil, nil, nil, CHAN_STATIC )

                net.Start( "lambda_tf2_medigun_beameffect" )
                    net.WriteEntity( wepent )
                    net.WriteEntity( NULL )
                net.Broadcast()
            end
            if wepent.l_HealSound then 
                wepent.l_HealSound:Stop()
            end

            wepent.l_HealTarget = nil
            wepent.l_HealTime = nil
            wepent.l_HealSound = nil
        end,

		OnAttack = function( self, wepent, target )
            local wepSrc = self:GetAttachmentPoint( "eyes" ).Pos
            local checkRange = ( 450 * ( target == wepent.l_HealTarget and 1.2 or 1 ) )
            if wepSrc:DistToSqr( target:NearestPoint( wepSrc ) ) > ( checkRange * checkRange ) then return true end

            medigunTraceTbl.start = wepSrc
            medigunTraceTbl.endpos = target:WorldSpaceCenter()
            medigunTraceTbl.filter[ 1 ] = self
            medigunTraceTbl.filter[ 2 ] = wepent
            medigunTraceTbl.filter[ 3 ] = target

            local medigunTr = TraceLine( medigunTraceTbl )
            if medigunTr.Fraction != 1.0 and medigunTr.Entity != target then return true end

            wepent.l_HealTarget = target
            wepent.l_HealTime = ( CurTime() + 0.5 )

            return true 
        end
    }
} )