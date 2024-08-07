local ceil = math.ceil

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_candycane = {
        model = "models/lambdaplayers/tf2/weapons/w_candy_cane.mdl",
        origin = "Team Fortress 2",
        prettyname = "Candy Cane",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 1,

        killicon = "lambdaplayers/killicons/icon_tf2_candy_cane",
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
            wepent:SetWeaponAttribute( "HitSound", ")weapons/bat_hit.wav" )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, isLethal )
            if !isLethal then return end
            local medkit = LAMBDA_TF2:CreateMedkit( target:WorldSpaceCenter(), "models/items/medkit_small.mdl", 0.2, false, 30 )
            local rndImpulse = VectorRand( -1, 1 )
            rndImpulse.z = 1; rndImpulse:Normalize()
            local velocity = ( rndImpulse * 250 )
            medkit:SetVelocity( velocity )
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if !dmginfo:IsExplosionDamage() then return end
            dmginfo:ScaleDamage( 1.25 )
        end
    }
} )