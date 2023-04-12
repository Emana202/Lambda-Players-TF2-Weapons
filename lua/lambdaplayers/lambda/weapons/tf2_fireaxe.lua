table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_fireaxe = {
        model = "models/lambdaplayers/tf2/weapons/w_fireaxe.mdl",
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
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/axe_hit_flesh1.wav",
                ")weapons/axe_hit_flesh2.wav",
                ")weapons/axe_hit_flesh3.wav"
            } )

            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )