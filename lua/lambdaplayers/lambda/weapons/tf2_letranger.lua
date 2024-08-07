table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_letranger = {
        model = "models/lambdaplayers/tf2/weapons/w_letranger.mdl",
        origin = "Team Fortress 2",
        prettyname = "L'Etranger",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_letranger",
        tfclass = 9,
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.55, 0.75 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", ")weapons/letranger_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/letranger_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_revolver" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_pistol_tracer01" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.133,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.33,
        reloadsounds = { { 0, "weapons/revolver_worldreload.wav" } }
   }
} )