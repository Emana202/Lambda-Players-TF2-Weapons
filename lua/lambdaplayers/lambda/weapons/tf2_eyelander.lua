local min = math.min
local Round = math.Round
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_eyelander = {
        model = "models/lambdaplayers/tf2/weapons/w_eyelander.mdl",
        origin = "Team Fortress 2",
        prettyname = "Eyelander",
        holdtype = "melee2",
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

            local newHP = Round( self:GetMaxHealth() * 0.75 )
            local giveHP = Round( ( self:GetMaxHealth() - newHP ) * 0.6 )

            wepent.l_TF_Eyelander_GiveHealth = giveHP
            newHP = Round( min( newHP + ( giveHP * self.l_TF_Decapitations ), newHP + ( giveHP * 4 ) ) )

            self:SetHealth( Round( self:Health() * ( newHP / self:GetMaxHealth() ) ) )
            self:SetMaxHealth( newHP )
            self.l_WeaponSpeedMultiplier = min( 1 + ( 0.08 * self.l_TF_Decapitations ), 1.32 )

            if !self.l_TF_Shield_IsEquipped and random( 1, 3 ) != 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent:EmitSound( "weapons/draw_sword.wav" )
        end,

        OnHolster = function( self, wepent )
            local hpNoBuffs = ( self:GetMaxHealth() - ( wepent.l_TF_Eyelander_GiveHealth * min( self.l_TF_Decapitations, 4 ) ) )
            local oldHP = Round( hpNoBuffs / 0.75 )

            self:SetHealth( Round( self:Health() * ( oldHP / self:GetMaxHealth() ) ) )
            self:SetMaxHealth( oldHP )
            self.l_WeaponSpeedMultiplier = 1
            wepent.l_TF_Eyelander_GiveHealth = nil
        end,

        OnDeath = function( self, wepent, dmginfo )
            local hpNoBuffs = ( self:GetMaxHealth() - ( wepent.l_TF_Eyelander_GiveHealth * min( self.l_TF_Decapitations, 4 ) ) )
            self:SetMaxHealth( hpNoBuffs )
            self.l_WeaponSpeedMultiplier = 1
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end
            
            local giveHP = wepent.l_TF_Eyelander_GiveHealth
            local targetHeads = ( target.l_TF_Decapitations or 0 )
            local actualGive = ( giveHP * ( 1 + targetHeads ) )
            local hpNoBuffs = ( self:GetMaxHealth() - ( giveHP * min( self.l_TF_Decapitations - targetHeads, 4 ) ) )
            self.l_TF_Decapitations = ( self.l_TF_Decapitations + 1 )

            self:SetMaxHealth( min( self:GetMaxHealth() + actualGive, hpNoBuffs + ( giveHP * 4 ) ) )
            LAMBDA_TF2:GiveHealth( self, actualGive )

            self.l_WeaponSpeedMultiplier = min( 1 + ( 0.08 * self.l_TF_Decapitations ), 1.32 )
        end
    }
} )