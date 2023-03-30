table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_wrench = {
        model = "models/lambdaplayers/tf2/weapons/w_wrench.mdl",
        origin = "Team Fortress 2",
        prettyname = "Wrench",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_wrench",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", "weapons/wrench_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/wrench_swing_crit.wav" )

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
            wepent:EmitSound( "weapons/draw_wrench_engineer.wav", nil, nil, nil, CHAN_STATIC )
            self:SimpleWeaponTimer( 0.666667, function()
                wepent:EmitSound( "weapons/metal_hit_hand" .. math.random( 1, 3 ) .. ".wav", nil, nil, 0.1 )
            end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )