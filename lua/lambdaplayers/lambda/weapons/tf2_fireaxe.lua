table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_fireaxe = {
        model = "models/lambdaplayers/weapons/tf2/w_fireaxe.mdl",
        origin = "Team Fortress 2",
        prettyname = "Fireaxe",
        holdtype = "melee2",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_fireaxe",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "HitSound", {
                "lambdaplayers/weapons/tf2/melee/axe_hit_flesh1.mp3",
                "lambdaplayers/weapons/tf2/melee/axe_hit_flesh2.mp3",
                "lambdaplayers/weapons/tf2/melee/axe_hit_flesh3.mp3"
            } )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )