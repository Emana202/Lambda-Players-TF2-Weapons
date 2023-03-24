local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sandwich = {
        model = "models/lambdaplayers/weapons/tf2/w_sandwich.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sandvich",
        holdtype = "slam",
        bonemerge = true,
  
		islethal = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and self:Health() <= ( self:GetMaxHealth() * 0.5 ) then 
                self:UseWeapon()
            end

            return 1.0
        end,

        OnAttack = function( self, wepent, target )
            if self:Health() >= self:GetMaxHealth() then return true end
            self.l_WeaponUseCooldown = ( CurTime() + 10 )

            local useAnim, waitTime = self:LookupSequence( "heavy_taunt_sandwich" )
            self:AddGestureSequence( useAnim, true )

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            for i = 1, 4 do
                self:SimpleWeaponTimer( ( ( waitTime / 4 ) * i ), function()
                    if i == 1 then self:EmitSound( "lambdaplayers/weapons/tf2/sandwicheat09.mp3", 75, nil, nil, CHAN_VOICE ) end
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