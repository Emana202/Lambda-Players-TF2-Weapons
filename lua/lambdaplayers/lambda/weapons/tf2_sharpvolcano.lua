table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sharpvolcano = {
        model = "models/lambdaplayers/tf2/weapons/w_sharp_volcano.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sharpened Volcano Fragment",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = 3,

        killicon = "lambdaplayers/killicons/icon_tf2_sharpened_volcano_fragment",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_CLUB )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/axe_hit_flesh1.wav",
                ")weapons/axe_hit_flesh2.wav",
                ")weapons/axe_hit_flesh3.wav"
            } )
            wepent:SetWeaponAttribute( "Damage", 32 )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_IGNITE )

            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )