table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_picket = {
        model = "models/lambdaplayers/tf2/weapons/w_picket.mdl",
        origin = "Team Fortress 2",
        prettyname = "Conscientious Objector",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = { [ 1 ] = true, [ 2 ] = true, [ 3 ] = true, [ 4 ] = true, [ 5 ] = true, [ 7 ] = true, [ 8 ] = true },

        killicon = "lambdaplayers/killicons/icon_tf2_conscientious_objector",
        keepdistance = 10,
        attackrange = 45,
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", ")weapons/machete_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/machete_swing_crit.wav" )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )

            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
        end,

        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetOwner( self )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )