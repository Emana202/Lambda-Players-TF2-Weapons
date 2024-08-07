table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bushwacka = {
        model = "models/lambdaplayers/tf2/weapons/w_croc_knife.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bushwacka",
        holdtype = "knife",
        bonemerge = true,
        tfclass = 8,

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
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "MiniCritsToFull", true )

            wepent:EmitSound( "weapons/draw_machete_sniper.wav" )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            dmginfo:ScaleDamage( 1.2 )
        end
    }
} )