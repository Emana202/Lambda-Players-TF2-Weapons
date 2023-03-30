table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_escapeplan = {
        model = "models/lambdaplayers/tf2/weapons/w_escape_plan.mdl",
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
                ")weapons/pickaxe_swing1.wav",
                ")weapons/pickaxe_swing2.wav",
                ")weapons/pickaxe_swing3.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/pickaxe_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/blade_slice_2.wav",
                "weapons/blade_slice_3.wav",
                "weapons/blade_slice_4.wav"
            } )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )

            wepent:EmitSound( "weapons/draw_shovel_soldier.wav" )
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