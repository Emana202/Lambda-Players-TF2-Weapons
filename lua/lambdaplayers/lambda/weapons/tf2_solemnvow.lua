table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_solemnvow = {
        model = "models/lambdaplayers/tf2/weapons/w_solemn_vow.mdl",
        origin = "Team Fortress 2",
        prettyname = "Solemn Vow",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_solemn_vow",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "RateOfFire", 0.88 )

            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )