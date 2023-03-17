table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_revolver = {
        model = "models/lambdaplayers/weapons/tf2/w_revolver.mdl",
        origin = "Team Fortress 2",
        prettyname = "Revolver",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_revolver",
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 700,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 25 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.55, 0.75 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/revolver/revolver_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.133,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.33,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/revolver/revolver_worldreload.mp3" } }
   }
} )