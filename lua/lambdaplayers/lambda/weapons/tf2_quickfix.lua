local CurTime = CurTime
local IsValid = IsValid

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_quickfix = {
        model = "models/lambdaplayers/tf2/weapons/w_proto_medigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Quick-Fix",
        holdtype = "physgun",
        bonemerge = true,
        tfclass = 7,
    
        ismedigun = true,
		islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:MedigunDeploy( self, wepent )
            wepent.l_QuickHealTime = 0
        end,
        OnHolster = function( self, wepent )
            LAMBDA_TF2:MedigunHolster( self, wepent )
        end,
        OnAttack = function( self, wepent, target )
            return LAMBDA_TF2:MedigunFire( self, wepent, target )
        end,

        OnThink = function( self, wepent, isdead )            
            if self.l_TF_Medigun_ChargeReleased then
                wepent.l_QuickHealTime = ( CurTime() + 1.0 )
            end

            local canHeal = ( CurTime() > self.l_TF_Medigun_HealTime )
            if CurTime() <= wepent.l_QuickHealTime and canHeal then 
                LAMBDA_TF2:GiveHealth( self, 1, LAMBDA_TF2:GetMaxBuffedHealth( self, 1.25 ) )

                if self.l_TF_IsBurning then
                    self.l_TF_FlameRemoveTime = ( self.l_TF_FlameRemoveTime - ( 1 / ( self.l_TF_FlameRemoveTime - CurTime() ) ) )
                end
                local bleedInfo = self.l_TF_BleedInfo
                if bleedInfo and #bleedInfo > 0 then
                    for _, info in ipairs( bleedInfo ) do
                        info.ExpireTime = ( info.ExpireTime - ( 1 / ( info.ExpireTime - CurTime() ) ) )
                    end
                end
                if self.l_TF_CoveredInMilk then
                    self.l_TF_CoveredInMilk = ( self.l_TF_CoveredInMilk - ( 1 / ( self.l_TF_CoveredInMilk - CurTime() ) ) )
                end
                if self.l_TF_CoveredInUrine then
                    self.l_TF_CoveredInUrine = ( self.l_TF_CoveredInUrine - ( 1 / ( self.l_TF_CoveredInUrine - CurTime() ) ) )
                end
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
                    local healRate = 1.4
                    if CurTime() <= wepent.l_QuickHealTime then 
                        healRate = ( healRate * 3 ) 
                        healTarget.l_TF_MegaHealingTime = ( CurTime() + 0.1 )
                    end
                    LAMBDA_TF2:MedigunHeal( self, wepent, healTarget, 1.1, true, 1.25, healRate )

                    if healTarget.IsLambdaPlayer and healTarget:l_GetIsShieldCharging() then
                        self.loco:SetVelocity( healTarget.loco:GetVelocity() )
                    end
                end
            end

            self.l_TF_Medigun_LastTarget = self.l_TF_Medigun_HealTarget
            if CurTime() <= wepent.l_QuickHealTime and CurTime() > self.l_TF_Medigun_HealTime then
                self.l_TF_Medigun_HealTime = ( CurTime() + ( ( LAMBDA_TF2:GetMediGunHealRate( self ) * 1.4 ) / 3 ) )
            end
        end
    }
} )