table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_buffalosteak = {
        model = "models/lambdaplayers/tf2/weapons/w_buffalo_steak.mdl",
        origin = "Team Fortress 2",
        prettyname = "Buffalo Steak Sandvich",
        holdtype = "slam",
        bonemerge = true,
  
		islethal = true,
        isedible = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
        end,

        OnDrop = function( self, wepent, cs_prop )
            cs_prop:Remove()
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead then 
                self:UseWeapon()
            end

            return 1.0
        end,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = ( CurTime() + 10 )

            local waitTime = 4.3
            local useAnim = self:LookupSequence( "heavy_taunt_sandwich" )
            if useAnim > 0 then self:AddGestureSequence( useAnim, true ) end

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            self:SimpleWeaponTimer( ( waitTime / 4 ), function()
                self:EmitSound( "vo/sandwicheat09.mp3", 80, self:GetVoicePitch(), nil, CHAN_VOICE )
                wepent:SetBodygroup( 0, 1 )
            end )

            self:SimpleWeaponTimer( waitTime, function()
                LAMBDA_TF2:AddCritBoost( self, "BuffaloSteakBoost", TF_CRIT_MINI, 16 )
                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )