
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_claidheamohmor = {
        model = "models/lambdaplayers/tf2/weapons/w_claidheamohmor.mdl",
        origin = "Team Fortress 2",
        prettyname = "Claidheamohmor",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = 4,

        killicon = "lambdaplayers/killicons/icon_tf2_claidheamohmor",
        keepdistance = 10,
        attackrange = 80,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.875,
        shieldchargedrainrate = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitRange", 72 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/demo_sword_swing1.wav",
                ")weapons/demo_sword_swing2.wav",
                ")weapons/demo_sword_swing3.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/demo_sword_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/blade_slice_2.wav",
                "weapons/blade_slice_3.wav",
                "weapons/blade_slice_4.wav"
            } )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_DECAPITATION )

            wepent:EmitSound( "weapons/draw_sword.wav" )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal or !self.l_TF_Shield_Type or self.l_TF_Shield_ChargeMeterFull then return end
            self:l_SetShieldChargeMeter( self:l_GetShieldChargeMeter() + 25 )
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            dmginfo:ScaleDamage( 1.15 )
        end
    }
} )