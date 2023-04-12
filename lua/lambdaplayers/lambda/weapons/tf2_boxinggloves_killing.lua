table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_boxinggloves_killing = {
        model = "models/lambdaplayers/tf2/weapons/w_boxing_gloves.mdl",
        origin = "Team Fortress 2",
        prettyname = "Killing Gloves of Boxing",
        holdtype = "fist",
        bonemerge = true,
        dropondeath = false,

        killicon = "lambdaplayers/killicons/icon_tf2_boxinggloves_killing",
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
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/boxing_gloves_hit1.wav",
                "weapons/boxing_gloves_hit2.wav",
                "weapons/boxing_gloves_hit3.wav",
                "weapons/boxing_gloves_hit4.wav"
            } )
            wepent:SetWeaponAttribute( "HitCritSound", {
                "weapons/boxing_gloves_hit_crit1.wav",
                "weapons/boxing_gloves_hit_crit2.wav",
                "weapons/boxing_gloves_hit_crit3.wav"
            } )
            wepent:SetWeaponAttribute( "RateOfFire", 0.96 )

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
            LAMBDA_TF2:AddCritBoost( self, "GlovesCritBoost", TF_CRIT_FULL, 5 )
        end
    }
} )