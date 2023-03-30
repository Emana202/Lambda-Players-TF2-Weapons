table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_diamondback = {
        model = "models/lambdaplayers/tf2/weapons/w_diamondback.mdl",
        origin = "Team Fortress 2",
        prettyname = "Diamondback",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_diamondback",
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 21 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.55, 0.75 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/diamond_back_01.wav",
                ")weapons/diamond_back_02.wav",
                ")weapons/diamond_back_03.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", {
                ")weapons/diamond_back_01_crit.wav",
                ")weapons/diamond_back_02_crit.wav",
                ")weapons/diamond_back_03_crit.wav"
            } )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) and self.l_TF_DiamondbackCrits > 0 then
                self.l_TF_DiamondbackCrits = ( self.l_TF_DiamondbackCrits - 1 )
            end
            return true
        end,

        OnThink = function( self, wepent )
            if self.l_TF_DiamondbackCrits > 0 then
                LAMBDA_TF2:AddCritBoost( self, "DiamondbackCrits", CRIT_FULL, 0.1 )
            end
        end,

        OnDeath = function( self, wepent )
            self.l_TF_DiamondbackCrits = 0
        end,

        reloadtime = 1.133,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.33,
        reloadsounds = { { 0, "weapons/revolver_worldreload.wav" } }
   }
} )