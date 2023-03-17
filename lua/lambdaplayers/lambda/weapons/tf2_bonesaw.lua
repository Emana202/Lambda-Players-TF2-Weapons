table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bonesaw = {
        model = "models/lambdaplayers/weapons/tf2/w_bonesaw.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bonesaw",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_bonesaw",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )