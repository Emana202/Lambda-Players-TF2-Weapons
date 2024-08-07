table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_equalizer = {
        model = "models/lambdaplayers/tf2/weapons/w_equalizer.mdl",
        origin = "Team Fortress 2",
        prettyname = "Equalizer",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 2,

        killicon = "lambdaplayers/killicons/icon_tf2_equalizer",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        healratemult = 0.1,

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

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                local healthRatio = ( self:Health() / self:GetMaxHealth() )
                local dmgScale = LAMBDA_TF2:RemapClamped( healthRatio, 0, 1, 1.65, 0.5 )
                dmginfo:ScaleDamage( dmgScale )
            end )

            wepent:EmitSound( "weapons/draw_shovel_soldier.wav" )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )