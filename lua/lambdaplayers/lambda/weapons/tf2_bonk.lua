local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bonk = {
        model = "models/lambdaplayers/weapons/tf2/w_energy_drink.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bonk! Atomic Punch",
        holdtype = "slam",
        bonemerge = true,
    
		islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetSkin( random( 0, 1 ) )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/energydrink/pl_scout_dodge_can_open.mp3", 70, nil, nil, CHAN_ITEM )

            self.l_TF_HasSandvich = true
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and ( self:IsPanicking() or self:InCombat() and self:IsInRange( self:GetEnemy(), 1500 ) ) then
                self:UseWeapon()
            end
        end,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = ( CurTime() + 10 )
            self:EmitSound( "lambdaplayers/weapons/tf2/energydrink/pl_scout_dodge_can_drink.mp3", 70, nil, nil, CHAN_ITEM )
            
            local useAnim, waitTime = self:LookupSequence( "scout_taunt_drink" )
            self:AddGestureSequence( useAnim, true )
            
            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            self:SimpleWeaponTimer( waitTime, function()
                self.l_TF_AtomicPunched = ( CurTime() + 8 )
                
                local whirlTrail = self.l_TF_AtomicPunched_Trail 
                if IsValid( whirlTrail ) then
                    whirlTrail:SetParent()
                    SafeRemoveEntityDelayed( whirlTrail, 1 ) 
                end

                whirlTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 24, 12, 0.5, "effects/beam001_white", self:WorldSpaceCenter(), self )
                self:DeleteOnRemove( whirlTrail )
                self.l_TF_AtomicPunched_Trail = whirlTrail
                
                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )