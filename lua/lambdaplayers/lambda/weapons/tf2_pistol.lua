local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_pistol = {
        model = "models/lambdaplayers/weapons/tf2/w_pistol.mdl",
        origin = "Team Fortress 2",
        prettyname = "Pistol",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_pistol",
        
        clip = 12,
        islethal = true,
        attackrange = 1000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 9 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.15 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/pistol/pistol_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60  )
            
            local holdtype = ( random( 1, 2 ) == 1 and "pistol" or "revolver" )
            if holdtype == "revolver" then wepent:EmitSound( "lambdaplayers/weapons/tf2/pistol/pistol_draw_engineer.mp3", 60 ) end 
            self.l_HoldType = holdtype
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.02,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.5,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/pistol/pistol_worldreload.mp3" } }
    }
} )