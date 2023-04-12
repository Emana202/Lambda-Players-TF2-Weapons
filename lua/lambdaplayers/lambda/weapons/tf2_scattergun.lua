table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_scattergun = {
        model = "models/lambdaplayers/tf2/weapons/w_scattergun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Scattergun",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_scattergun",

        clip = 6,
        islethal = true,
        attackrange = 800,
        keepdistance = 200,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/scatter_gun_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/scatter_gun_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, {
                Animation = "reload_smg1_alt",
                StartDelay = 0.7,
                CycleSound = "weapons/scatter_gun_worldreload.wav",
                CycleFunction = function( lambda, weapon )
                    LAMBDA_TF2:CreateShellEject( weapon, "ShotgunShellEject" )
                end,
                EndFunction = false
            } )

            return true
        end
    }
} )