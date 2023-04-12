table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_warriorspirit = {
        model = "models/lambdaplayers/tf2/weapons/w_bear_claw.mdl",
        origin = "Team Fortress 2",
        prettyname = "Warrior's Spirit",
        holdtype = "fist",
        bonemerge = true,
        dropondeath = false,

        killicon = "lambdaplayers/killicons/icon_tf2_warrior_spirit",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            wepent:SetWeaponAttribute( "Sound", {
                "weapons/boxing_gloves_swing1.wav",
                "weapons/boxing_gloves_swing2.wav",
                "weapons/boxing_gloves_swing4.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", "weapons/fist_swing_crit.wav" )
            wepent:SetWeaponAttribute( "Damage", 52 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.8 )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.1, function() wepent:EmitSound( "weapons/boxing_gloves_hit.wav" ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end
            LAMBDA_TF2:GiveHealth( self, 25, false )
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            dmginfo:ScaleDamage( 1.3 )
        end
    }
} )