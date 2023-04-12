local CurTime = CurTime
local IsValid = IsValid

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_kritzkrieg = {
        model = "models/lambdaplayers/tf2/weapons/w_medigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Kritzkrieg",
        holdtype = "physgun",
        bonemerge = true,
    
		islethal = true,
        ismedigun = true,
        deploydelay = 0.5,

        medictargetfilter = function( lambda, target )
            if lambda.l_TF_Medigun_ChargeReady then
                return ( !target.IsLambdaPlayer and IsValid( target:GetActiveWeapon() ) or target.IsLambdaPlayer and target.l_HasLethal )
            end
        end,
        chargereleasesnd = ")weapons/weapon_crit_charged_on.wav",
        chargedrainedsnd = ")weapons/weapon_crit_charged_off.wav",

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:MedigunDeploy( self, wepent )
            wepent:SetBodygroup( 1, 1 )
        end,
        OnHolster = function( self, wepent )
            LAMBDA_TF2:MedigunHolster( self, wepent )
        end,
        OnAttack = function( self, wepent, target )
            return LAMBDA_TF2:MedigunFire( self, wepent, target )
        end,
        
        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetBodygroup( 1, wepent:GetBodygroup( 1 ) )
        end,

        OnThink = function( self, wepent, isdead )            
            local healTarget = self.l_TF_Medigun_HealTarget
            if !IsValid( healTarget ) or !LAMBDA_TF2:IsValidCharacter( healTarget ) then
                if healTarget != nil then
                    LAMBDA_TF2:MedigunDetach( self, wepent )
                end
            else
                local lastTarget = self.l_TF_Medigun_LastTarget
                if IsValid( lastTarget ) and lastTarget != healTarget then
                    LAMBDA_TF2:MedigunDetach( self, wepent, lastTarget )
                elseif isdead or CurTime() > self.l_TF_Medigun_DetachTime then
                    LAMBDA_TF2:MedigunDetach( self, wepent, healTarget )
                elseif !isdead then
                    LAMBDA_TF2:MedigunHeal( self, wepent, healTarget, 1.25 )
                    if self.l_TF_Medigun_ChargeReleased then
                        LAMBDA_TF2:AddCritBoost( healTarget, "KritzkriegCrits", TF_CRIT_FULL, 0.1 )
                    end
                end
            end

            self.l_TF_Medigun_LastTarget = self.l_TF_Medigun_HealTarget
        end
    }
} )