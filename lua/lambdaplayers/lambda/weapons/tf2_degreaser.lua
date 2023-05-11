table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_degreaser = {
        model = "models/lambdaplayers/tf2/weapons/w_degreaser.mdl",
        origin = "Team Fortress 2",
        prettyname = "Degreaser",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_degreaser",

        clip = 200,
        islethal = true,
        attackrange = 350,
        keepdistance = 250,

        deploydelay = 0.2,
        holstermult = 0.7,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 100 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.04 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_PREVENT_PHYSICS_FORCE )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_IGNITE )

            wepent:SetWeaponAttribute( "StartFireSound", ")weapons/flame_thrower_dg_start.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/flame_thrower_dg_loop.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/flame_thrower_dg_loop_crit.wav" )
            wepent:SetWeaponAttribute( "EndFireSound", ")weapons/flame_thrower_dg_end.wav" )

            wepent:SetWeaponAttribute( "AfterburnDamage", 1.02 )

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