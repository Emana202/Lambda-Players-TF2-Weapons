table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_shahanshah = {
        model = "models/lambdaplayers/tf2/weapons/w_scimitar.mdl",
        origin = "Team Fortress 2",
        prettyname = "Shahanshah",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_shahanshah",
        keepdistance = 10,
        attackrange = 45,
        islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", ")weapons/machete_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/machete_swing_crit.wav" )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                dmginfo:ScaleDamage( ( self:Health() < ( self:GetMaxHealth() * 0.5 ) ) and 1.25 or 0.75 )
            end )

            wepent:EmitSound( "weapons/draw_machete_sniper.wav" )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )