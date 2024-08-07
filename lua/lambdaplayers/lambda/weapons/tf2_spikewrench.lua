
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_spikewrench = {
        model = "models/lambdaplayers/tf2/weapons/w_spikewrench.mdl",
        origin = "Team Fortress 2",
        prettyname = "Southern Hospitality",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 6,

        killicon = "lambdaplayers/killicons/icon_tf2_southernhospitality",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", "weapons/wrench_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/wrench_swing_crit.wav" )
            wepent:SetWeaponAttribute( "BleedingDuration", 5 )

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
            wepent:EmitSound( "weapons/draw_wrench_engineer.wav", nil, nil, nil, CHAN_STATIC )
            self:SimpleWeaponTimer( 0.666667, function()
                wepent:EmitSound( "weapons/metal_hit_hand" .. LambdaRNG( 3 ) .. ".wav", nil, nil, 0.1 )
            end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if dmginfo:IsDamageType( DMG_BURN + DMG_SLOWBURN ) or LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_IGNITE + TF_DMG_CUSTOM_BURNING ) then
                dmginfo:ScaleDamage( 1.2 )
            end
        end
    }
} )