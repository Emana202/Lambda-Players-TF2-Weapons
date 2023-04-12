local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sandwich = {
        model = "models/lambdaplayers/tf2/weapons/w_sandwich.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sandvich",
        holdtype = "slam",
        bonemerge = true,
  
		islethal = false,
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
                if self:Health() < self:GetMaxHealth() then 
                    self:UseWeapon()
                end
            end

            return 1.0
        end,

        OnAttack = function( self, wepent, target )
            if self:Health() >= self:GetMaxHealth() then return true end
            self.l_WeaponUseCooldown = ( CurTime() + 10 )

            local waitTime = 4.3
            local useAnim = self:LookupSequence( "heavy_taunt_sandwich" )
            if useAnim > 0 then self:AddGestureSequence( useAnim, true ) end

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            for i = 1, 4 do
                self:SimpleWeaponTimer( ( ( waitTime / 4 ) * i ), function()
                    if i == 1 then 
                        self:EmitSound( "vo/sandwicheat09.mp3", 80, self:GetVoicePitch(), nil, CHAN_VOICE )
                        wepent:SetBodygroup( 1, 1 )
                    end

                    LAMBDA_TF2:GiveHealth( self, self:GetMaxHealth() / 4, false )
                end )
            end

            self:SimpleWeaponTimer( waitTime, function()
                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )