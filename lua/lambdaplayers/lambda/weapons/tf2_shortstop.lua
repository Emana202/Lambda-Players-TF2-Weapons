local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_shortstop = {
        model = "models/lambdaplayers/tf2/weapons/w_shortstop.mdl",
        origin = "Team Fortress 2",
        prettyname = "Shortstop",
        holdtype = "revolver",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_shortstop",

        clip = 4,
        islethal = true,
        attackrange = 800,
        keepdistance = 400,
        deploydelay = 0.5,

        airblast_vulnerability_multiplier = 1.2,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 7 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.4, 0.5 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", ")weapons/short_stop_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/short_stop_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.52,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.25,
        reloadsounds = {
            { 0.033333, "weapons/pistol_reload_scout.wav" },
            { 0.6, "weapons/pistol_clipin.wav" }
        }
    }
} )