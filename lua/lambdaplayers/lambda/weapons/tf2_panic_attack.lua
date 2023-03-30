local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_panicattack = {
        model = "models/lambdaplayers/tf2/weapons/w_trenchgun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Panic Attack",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_panicattack",

        clip = 6,
        islethal = true,
        attackrange = 1000,
        keepdistance = 400,
        deploydelay = 0.25,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 3 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/tf2_backshot_shotty.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/tf2_backshot_shotty_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 15 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FixedSpread", true )

            wepent:EmitSound( random( 1, 4 ) != 1 and "weapons/draw_secondary.wav" or "weapons/draw_shotgun_pyro.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) then
                self:SimpleWeaponTimer( 0.266, function()
                    wepent:EmitSound( "weapons/shotgun_cock_back.wav", 70, nil, nil, CHAN_STATIC )
                end )
                self:SimpleWeaponTimer( 0.416, function()
                    wepent:EmitSound( "weapons/shotgun_cock_forward.wav", 70, nil, nil, CHAN_STATIC )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end )
            end

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent )
            return true
        end
    }
} )