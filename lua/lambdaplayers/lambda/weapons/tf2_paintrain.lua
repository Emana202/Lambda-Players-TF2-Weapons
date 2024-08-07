table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_paintrain = {
        model = "models/lambdaplayers/tf2/weapons/w_paintrain.mdl",
        origin = "Team Fortress 2",
        prettyname = "Pain Train",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 2,

        killicon = "lambdaplayers/killicons/icon_tf2_paintrain",
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

            wepent:EmitSound( "weapons/draw_shovel_soldier.wav" )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if dmginfo:IsBulletDamage() then
                dmginfo:ScaleDamage( 1.1 )
            end
        end
    }
} )