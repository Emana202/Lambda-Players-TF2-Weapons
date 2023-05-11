local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_pistol = {
        model = "models/lambdaplayers/tf2/weapons/w_pistol.mdl",
        origin = "Team Fortress 2",
        prettyname = "Pistol",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_pistol",
        
        clip = 12,
        islethal = true,
        attackrange = 1000,
        keepdistance = 600,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 9 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.15 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            wepent:SetWeaponAttribute( "Sound", ")weapons/pistol_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/pistol_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_pistol" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_pistol_tracer01" )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
            local holdtype = ( random( 2 ) == 1 and "pistol" or "revolver" )
            if holdtype == "pistol" then wepent:EmitSound( "weapons/draw_pistol_engineer.wav", nil, nil, 0.5, CHAN_STATIC ) end 
            self.l_HoldType = holdtype
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.02,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.5,
        reloadsounds = { { 0, "weapons/pistol_worldreload.wav" } }
    }
} )