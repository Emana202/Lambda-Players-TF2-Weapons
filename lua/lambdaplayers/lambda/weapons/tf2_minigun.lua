table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_minigun = {
        model = "models/lambdaplayers/tf2/weapons/w_minigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Minigun",
        holdtype = "crossbow",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_minigun",
        tfclass = 5,

        clip = 200,
        islethal = true,
        attackrange = 1500,
        keepdistance = 600,
		speedmultiplier = 0.77,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "Spread", 0.08 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_tracer01" )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "WindUpTime", 0.75 )

            wepent:SetWeaponAttribute( "SpinSound", ")weapons/minigun_spin.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/minigun_shoot.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/minigun_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "WindUpSound", ")weapons/minigun_wind_up.wav" )
            wepent:SetWeaponAttribute( "WindDownSound", ")weapons/minigun_wind_down.wav" )

            LAMBDA_TF2:MinigunDeploy( self, wepent )
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:MinigunHolster( self, wepent )
        end,

        OnThink = function( self, wepent, dead )
            LAMBDA_TF2:MinigunThink( self, wepent, dead )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:MinigunFire( self, wepent, target )
            return true
        end
    }
} )