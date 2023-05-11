table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sunonastick = {
        model = "models/lambdaplayers/tf2/weapons/w_sun_on_a_stick.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sun-on-a-Stick",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_sunonastick",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 15 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.5 )
            wepent:SetWeaponAttribute( "HitSound", ")weapons/bat_hit.wav" )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if !LAMBDA_TF2:IsBurning( target ) then return end
                LAMBDA_TF2:SetCritType( dmginfo, TF_CRIT_FULL )
			end )

            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if dmginfo:IsDamageType( DMG_BURN + DMG_SLOWBURN ) or LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_IGNITE ) then
                dmginfo:ScaleDamage( 0.75 )
            end
        end
    }
} )