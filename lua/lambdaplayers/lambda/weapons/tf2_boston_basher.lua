table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bostonbasher = {
        model = "models/lambdaplayers/tf2/weapons/w_boston_basher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Boston Basher",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_bostonbasher",
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
            wepent:SetWeaponAttribute( "Sound", {
                "weapons/boxing_gloves_swing1.wav",
                "weapons/boxing_gloves_swing2.wav",
                "weapons/boxing_gloves_swing4.wav"
            } )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/eviction_notice_01.wav",
                ")weapons/eviction_notice_02.wav",
                ")weapons/eviction_notice_03.wav",
                ")weapons/eviction_notice_04.wav"
            } )
            wepent:SetWeaponAttribute( "HitCritSound", {
                ")weapons/eviction_notice_01_crit.wav",
                ")weapons/eviction_notice_02_crit.wav",
                ")weapons/eviction_notice_03_crit.wav",
                ")weapons/eviction_notice_04_crit.wav"
            } )
            wepent:SetWeaponAttribute( "BleedingDuration", 5 )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )

            wepent:SetWeaponAttribute( "OnMiss", function( lambda, weapon, target, dmginfo )
                dmginfo:ScaleDamage( 0.5 )
                lambda:TakeDamageInfo( dmginfo )
            end )

            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )