local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_katana = {
        model = "models/lambdaplayers/tf2/weapons/w_katana.mdl",
        origin = "Team Fortress 2",
        prettyname = "Half-Zatoichi",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_katana",
        keepdistance = 10,
        attackrange = 80,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.875,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitRange", 72 )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/samurai/TF_Katana_01.wav",
                ")weapons/samurai/TF_Katana_02.wav",
                ")weapons/samurai/TF_Katana_03.wav",
                ")weapons/samurai/TF_Katana_04.wav",
                ")weapons/samurai/TF_Katana_05.wav",
                ")weapons/samurai/TF_Katana_06.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/samurai/TF_katana_crit_miss_01.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/samurai/TF_katana_slice_01.wav",
                ")weapons/samurai/TF_katana_slice_02.wav",
                ")weapons/samurai/TF_katana_slice_03.wav"
            } )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_DECAPITATION )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
				if !target.IsLambdaPlayer or target:GetWeaponName() != "tf2_katana" then return end
                dmginfo:SetDamage( target:Health() * 3 )
                dmginfo:SetDamageCustom( TF_DMG_CUSTOM_KATANA_DUEL )
			end )

            if !self.l_TF_Shield_IsEquipped and random( 4 ) == 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent.l_TF_IsHonorbound = true
            wepent:EmitSound( ")weapons/samurai/TF_katana_draw_0" .. random( 1, 2 ) .. ".wav", 70, nil, 0.7 )
        end,

        OnHolster = function( self, wepent )
            if !wepent.l_TF_IsHonorbound then
                if self:Health() <= 50 then return true end
                self:TakeDamage( 50, self, wepent )
            end
        end,

        OnDeath = function( self, wepent )
            self:SimpleWeaponTimer( 0.1, function() wepent:SetSkin( 0 ) end, true )
        end,
        
        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetSkin( wepent:GetSkin() )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end
            LAMBDA_TF2:GiveHealth( self, ( self:GetMaxHealth() * 0.5 ) )
            wepent.l_TF_IsHonorbound = false
            wepent:SetSkin( 1 )
        end
    }
} )