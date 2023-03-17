local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_katana = {
        model = "models/lambdaplayers/weapons/tf2/w_katana.mdl",
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
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                "lambdaplayers/weapons/tf2/katana/tf_katana_01.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_02.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_03.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_04.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_05.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_06.mp3"
            } )
            wepent:SetWeaponAttribute( "HitSound", {
                "lambdaplayers/weapons/tf2/katana/tf_katana_slice_01.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_slice_02.mp3",
                "lambdaplayers/weapons/tf2/katana/tf_katana_slice_03.mp3"
            } )
            wepent:SetWeaponAttribute( "CustomDamage", TF_DMG_CUSTOM_DECAPITATION )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
				if !target.IsLambdaPlayer or target:GetWeaponName() != lambda:GetWeaponName() then return end
                dmginfo:SetDamage( target:Health() * 3 )
			end )

            if !self.l_TF_Shield_IsEquipped and random( 1, 4 ) == 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent.l_TF_IsHonorbound = true
            wepent:EmitSound( "lambdaplayers/weapons/tf2/katana/tf_katana_draw_0" .. random( 1, 2 ) .. ".mp3", 74, 100, 0.5 )
        end,

        OnHolster = function( self, wepent )
            if !wepent.l_TF_IsHonorbound then return end
            self:TakeDamage( 50, self, wepent )
            wepent:SetSkin( 0 )
        end,

        OnDeath = function( self, wepent )
            wepent:SetSkin( 0 )
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