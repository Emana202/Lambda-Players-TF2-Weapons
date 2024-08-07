table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_shovel = {
        model = "models/lambdaplayers/tf2/weapons/w_shovel.mdl",
        origin = "Team Fortress 2",
        prettyname = "Shovel",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 2,

        killicon = "lambdaplayers/killicons/icon_tf2_shovel",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", ")weapons/shovel_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/shovel_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/axe_hit_flesh1.wav",
                ")weapons/axe_hit_flesh2.wav",
                ")weapons/axe_hit_flesh3.wav"
            } )

            wepent:EmitSound( "weapons/draw_shovel_soldier.wav" )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )