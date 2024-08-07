local CurTime = CurTime
local IsValid = IsValid

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_medigun = {
        model = "models/lambdaplayers/tf2/weapons/w_medigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Medi Gun",
        holdtype = "physgun",
        bonemerge = true,
        tfclass = 7,
    
        ismedigun = true,
		islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:MedigunDeploy( self, wepent )
        end,
        OnHolster = function( self, wepent )
            LAMBDA_TF2:MedigunHolster( self, wepent )
        end,
        OnAttack = function( self, wepent, target )
            return LAMBDA_TF2:MedigunFire( self, wepent, target )
        end,

        OnThink = function( self, wepent, isdead )            
            if !isdead and self.l_TF_Medigun_ChargeReleased then
                self.l_TF_InvulnerabilityTime = ( CurTime() + 1.0 )
            end

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
                    LAMBDA_TF2:MedigunHeal( self, wepent, healTarget )
                    if self.l_TF_Medigun_ChargeReleased then 
                        healTarget.l_TF_InvulnerabilityTime = ( CurTime() + 1.0 )
                    end
                end
            end

            self.l_TF_Medigun_LastTarget = self.l_TF_Medigun_HealTarget
        end
    }
} )