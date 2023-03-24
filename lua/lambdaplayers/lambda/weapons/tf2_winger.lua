table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_winger = {
        model = "models/lambdaplayers/weapons/tf2/w_winger_pistol.mdl",
        origin = "Team Fortress 2",
        prettyname = "Winger",
        holdtype = "revolver",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_winger",

        clip = 5,
        islethal = true,
        attackrange = 1000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 10.35 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.15 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/pistol/winger_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent.l_TF_Winger_PreEquipJumpHeight = self.loco:GetJumpHeight()
            self.loco:SetJumpHeight( wepent.l_TF_Winger_PreEquipJumpHeight * 1.25 )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnHolster = function( self, wepent )
            self.loco:SetJumpHeight( wepent.l_TF_Winger_PreEquipJumpHeight )
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