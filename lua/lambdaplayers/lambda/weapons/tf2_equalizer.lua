table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_equalizer = {
        model = "models/lambdaplayers/weapons/tf2/w_equalizer.mdl",
        origin = "Team Fortress 2",
        prettyname = "Equalizer",
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

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                local healthRatio = ( self:Health() / self:GetMaxHealth() )
                local dmgScale = LAMBDA_TF2:RemapClamped( healthRatio, 0, 1, 1.65, 0.5 )
                dmginfo:ScaleDamage( dmgScale )
            end )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/shovel_draw.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )