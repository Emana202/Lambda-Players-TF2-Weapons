table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_tribalmanshiv = {
        model = "models/lambdaplayers/tf2/weapons/w_wood_machete.mdl",
        origin = "Team Fortress 2",
        prettyname = "Tribalman's Shiv",
        holdtype = "knife",
        bonemerge = true,
        tfclass = 8,

        killicon = "lambdaplayers/killicons/icon_tf2_tribalmanshiv",
        keepdistance = 10,
        attackrange = 45,
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "Sound", ")weapons/machete_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/machete_swing_crit.wav" )
            wepent:SetWeaponAttribute( "BleedingDuration", 6 )

            wepent:EmitSound( "weapons/draw_machete_sniper.wav" )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )