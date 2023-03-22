local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_persianpersuader = {
        model = "models/lambdaplayers/weapons/tf2/w_sultan_sword.mdl",
        origin = "Team Fortress 2",
        prettyname = "The Persian Persuader",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_eyelander",
        keepdistance = 10,
        attackrange = 80,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.875,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitRange", 72 )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                "lambdaplayers/weapons/tf2/melee/sword_swing1.mp3",
                "lambdaplayers/weapons/tf2/melee/sword_swing2.mp3",
                "lambdaplayers/weapons/tf2/melee/sword_swing3.mp3"
            } )
            wepent:SetWeaponAttribute( "HitSound", {
                "lambdaplayers/weapons/tf2/melee/blade_slice_2.mp3",
                "lambdaplayers/weapons/tf2/melee/blade_slice_3.mp3",
                "lambdaplayers/weapons/tf2/melee/blade_slice_4.mp3"
            } )
            wepent:SetWeaponAttribute( "CustomDamage", TF_DMG_CUSTOM_DECAPITATION )

            if !self.l_TF_Shield_IsEquipped and random( 1, 3 ) != 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/sword_draw.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage or !self.l_TF_Shield_IsEquipped and self.l_TF_Shield_ChargeMeterFull then return end
            self.l_TF_Shield_ChargeMeter = ( self.l_TF_Shield_ChargeMeter + 20 )
        end
    }
} )