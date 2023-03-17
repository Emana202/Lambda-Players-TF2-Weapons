table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_wrench = {
        model = "models/lambdaplayers/weapons/tf2/w_wrench.mdl",
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
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/melee/wrench_swing.mp3" )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/wrench_draw.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )