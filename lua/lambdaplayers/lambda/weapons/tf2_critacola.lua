table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_critacola = {
        model = "models/lambdaplayers/weapons/tf2/w_energy_drink.mdl",
        origin = "Team Fortress 2",
        prettyname = "Crit-a-Cola",
        holdtype = "slam",
        bonemerge = true,

        islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetSkin( 2 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/energydrink/pl_scout_dodge_can_open.mp3", 70, nil, nil, CHAN_ITEM )
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and self:InCombat() and self:IsInRange( self:GetEnemy(), 1500 ) then
                self:UseWeapon()
            end
        end,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            self:EmitSound( "lambdaplayers/weapons/tf2/energydrink/pl_scout_dodge_can_drink.mp3", 70, nil, nil, CHAN_ITEM )
            
            local useAnim, waitTime = self:LookupSequence( "scout_taunt_drink" )
            self:AddGestureSequence( useAnim, true )
            
            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            self:SimpleWeaponTimer( waitTime, function()
                self.l_TF_MiniCritBoosted = ( CurTime() + 8 )
                self.l_TF_MiniCritBoosted_MarkAfterAttacking = 5

                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )