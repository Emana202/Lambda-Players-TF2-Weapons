table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_escapeplan = {
        model = "models/lambdaplayers/weapons/tf2/w_escape_plan.mdl",
        origin = "Team Fortress 2",
        prettyname = "Escape Plan",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_equalizer",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", { 
                "lambdaplayers/weapons/tf2/melee/pickaxe_swing1.mp3", 
                "lambdaplayers/weapons/tf2/melee/pickaxe_swing2.mp3", 
                "lambdaplayers/weapons/tf2/melee/pickaxe_swing3.mp3" 
            } )
            wepent:SetWeaponAttribute( "HitSound", { 
                "lambdaplayers/weapons/tf2/melee/blade_slice_2.mp3", 
                "lambdaplayers/weapons/tf2/melee/blade_slice_3.mp3", 
                "lambdaplayers/weapons/tf2/melee/blade_slice_4.mp3" 
            } )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/shovel_draw.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnThink = function( self, wepent, dead )
            if dead then return end
            self.l_TF_MarkedForDeath = ( CurTime() + 1 )

            local healthRatio = ( self:Health() / self:GetMaxHealth() )
            self.l_WeaponSpeedMultiplier = LAMBDA_TF2:RemapClamped( healthRatio, 0.2, 0.8, 1.6, 1 )
        end
    }
} )