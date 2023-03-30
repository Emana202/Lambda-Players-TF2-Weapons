table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_enforcer = {
        model = "models/lambdaplayers/tf2/weapons/w_snub_nose.mdl",
        origin = "Team Fortress 2",
        prettyname = "Enforcer",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_enforcer",
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 25 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.66, 0.8 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/tf_spy_enforcer_revolver_01.wav",
                ")weapons/tf_spy_enforcer_revolver_02.wav",
                ")weapons/tf_spy_enforcer_revolver_03.wav",
                ")weapons/tf_spy_enforcer_revolver_04.wav",
                ")weapons/tf_spy_enforcer_revolver_05.wav",
                ")weapons/tf_spy_enforcer_revolver_06.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/tf_spy_enforcer_revolver_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )
            wepent:SetWeaponAttribute( "RandomCrits", false )

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