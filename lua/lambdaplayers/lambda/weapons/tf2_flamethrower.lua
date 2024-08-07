table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_flamethrower = {
        model = "models/lambdaplayers/tf2/weapons/w_flamethrower.mdl",
        origin = "Team Fortress 2",
        prettyname = "Flame Thrower",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_flamethrower",
        tfclass = 3,

        clip = 200,
        islethal = true,
        attackrange = 350,
        keepdistance = 250,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 100 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.04 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_PREVENT_PHYSICS_FORCE )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_IGNITE )

            wepent:SetWeaponAttribute( "StartFireSound", ")weapons/flame_thrower_start.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/flame_thrower_loop.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/flame_thrower_loop_crit.wav" )
            wepent:SetWeaponAttribute( "EndFireSound", ")weapons/flame_thrower_end.wav" )

            LAMBDA_TF2:FlamethrowerDeploy( self, wepent )
        end,

        OnThink = function( self, wepent, isdead )
            LAMBDA_TF2:FlamethrowerThink( self, wepent, isdead )
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:FlamethrowerHolster( self, wepent )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:FlamethrowerFire( self, wepent, target )
            return true
        end
    }
} )