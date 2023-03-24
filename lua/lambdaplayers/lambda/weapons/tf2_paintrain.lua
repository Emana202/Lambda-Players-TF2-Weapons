table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_paintrain = {
        model = "models/lambdaplayers/weapons/tf2/w_paintrain.mdl",
        origin = "Team Fortress 2",
        prettyname = "Pain Train",
        holdtype = "melee",
        bonemerge = true,

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

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, nil, 0.5, CHAN_WEAPON )
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