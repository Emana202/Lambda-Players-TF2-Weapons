table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_powerjack = {
        model = "models/lambdaplayers/tf2/weapons/w_powerjack.mdl",
        origin = "Team Fortress 2",
        prettyname = "Powerjack",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = 3,

        killicon = "lambdaplayers/killicons/icon_tf2_powerjack",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,
		speedmultiplier = 1.15,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "Damage", 30 )

            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end
            LAMBDA_TF2:GiveHealth( self, ( self:GetMaxHealth() * 0.25 ), false )
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            dmginfo:ScaleDamage( 1.2 )
        end
    }
} )