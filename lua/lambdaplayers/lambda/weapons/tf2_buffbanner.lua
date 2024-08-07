table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_buffbanner = {
        model = "models/lambdaplayers/tf2/items/buffbanner_bugle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Buff Banner",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 2,

		islethal = false,
        deploydelay = 0.5,
        cantbeselected = true,
        keepdistance = 600,

        isbuffpack = true,
        bufftype = 1,
        buffpackmdl = "models/lambdaplayers/tf2/items/buffbanner_backpack.mdl",

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnHolster = function( self, wepent )
            if !self.l_TF_RageActivated and CurTime() <= self.l_WeaponUseCooldown then return true end
        end,

        OnThink = function( self, wepent, isdead )
            if isdead or self.l_TF_RageMeter < 100 then return end
            self:UseWeapon()
        end,

        OnAttack = function( self, wepent )
            self.l_WeaponUseCooldown = ( CurTime() + 3 )

            local useAnim = self:LookupSequence( "soldier_range_bugle" )
            if useAnim > 0 then 
                self:AddGestureSequence( useAnim, true )
            else
                self.l_HoldType = "camera"
            end
            
            self:SimpleWeaponTimer( 0.22, function()
                wepent:EmitSound( "weapons/buff_banner_horn_" .. ( self.l_TF_TeamColor == 1 and "red" or "blue" ) .. ".wav", nil, nil, nil, CHAN_STATIC )
            end )
            self:SimpleWeaponTimer( 2.66, function()
                self.l_HoldType = bugleHoldType
                LAMBDA_TF2:ActivateRageBuff( self )
            end )

            return true 
        end
    }
} )