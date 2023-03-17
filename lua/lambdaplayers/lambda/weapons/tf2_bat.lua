table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bat = {
        model = "models/lambdaplayers/weapons/tf2/w_bat.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bat",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_bat",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.5 )
            wepent:SetWeaponAttribute( "HitSound", "lambdaplayers/weapons/tf2/melee/bat_hit.mp3" )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/bat_draw.mp3", 75, 100, 0.5 )
            self:SimpleWeaponTimer( ( 8 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/bat_draw_swoosh2.mp3", 75, 100, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( ( 16 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/bat_draw_swoosh1.mp3", 75, 100, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( ( 20 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/metal_hit_hand1.mp3", 75, 100, 1, CHAN_WEAPON ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )