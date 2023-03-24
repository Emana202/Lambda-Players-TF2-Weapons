table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_spikewrench = {
        model = "models/lambdaplayers/weapons/tf2/w_spikewrench.mdl",
        origin = "Team Fortress 2",
        prettyname = "Southern Hospitality",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_southernhospitality",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/melee/wrench_swing.mp3" )
            wepent:SetWeaponAttribute( "BleedingDuration", 5 )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/wrench_draw.mp3", 74, 100, 0.5 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if dmginfo:IsDamageType( DMG_BURN + DMG_SLOWBURN + DMG_IGNITE ) or dmginfo:GetDamageCustom() == TF_DMG_CUSTOM_BURNING then
                dmginfo:ScaleDamage( 1.2 )
            end
        end
    }
} )