local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_widowmaker = {
        model = "models/lambdaplayers/tf2/weapons/w_widowmaker.mdl",
        origin = "Team Fortress 2",
        prettyname = "Widowmaker",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_widowmaker",

        clip = 200,
        islethal = true,
        attackrange = 1000,
        keepdistance = 400,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/widow_maker_shot_01.wav",
                ")weapons/widow_maker_shot_02.wav",
                ")weapons/widow_maker_shot_03.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", {
                ")weapons/widow_maker_shot_crit_01.wav",
                ")weapons/widow_maker_shot_crit_02.wav",
                ")weapons/widow_maker_shot_crit_03.wav"
            } )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "ClipDrain", 30 )

            wepent:EmitSound( "weapons/draw_secondary.wav" )
        end,

        OnAttack = function( self, wepent, target )
            if self.l_Clip >= 30 then LAMBDA_TF2:WeaponAttack( self, wepent, target ) end
            return true
        end,

        OnThink = function( self, wepent, dead )
            if !dead then self.l_Clip = min( self.l_Clip + 1, 200 ) end
            return 0.1
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage then return end
            self.l_Clip = min( self.l_Clip + dmginfo:GetDamage(), 200 )
        end,

        OnReload = function( self, wepent )
            return true
        end
    }
} )