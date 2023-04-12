table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_fistsofsteel = {
        model = "models/lambdaplayers/tf2/weapons/w_fists_of_steel.mdl",
        origin = "Team Fortress 2",
        prettyname = "Fists Of Steel",
        holdtype = "fist",
        bonemerge = true,
        dropondeath = false,

        killicon = "lambdaplayers/killicons/icon_tf2_fists_of_steel",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,
        holstermult = 2.0,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            wepent:SetWeaponAttribute( "Sound", {
                "weapons/boxing_gloves_swing1.wav",
                "weapons/boxing_gloves_swing2.wav",
                "weapons/boxing_gloves_swing4.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", "weapons/fist_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/metal_gloves_hit_flesh1.wav",
                ")weapons/metal_gloves_hit_flesh2.wav",
                ")weapons/metal_gloves_hit_flesh3.wav",
                ")weapons/metal_gloves_hit_flesh4.wav"
            } )
            wepent:SetWeaponAttribute( "HitCritSound", {
                ")weapons/metal_gloves_hit_crit1.wav",
                ")weapons/metal_gloves_hit_crit2.wav",
                ")weapons/metal_gloves_hit_crit3.wav",
                ")weapons/metal_gloves_hit_crit4.wav"
            } )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.1, function() wepent:EmitSound( "weapons/metal_gloves_hit.wav" ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if dmginfo:IsDamageType( DMG_MELEE ) then
                dmginfo:ScaleDamage( 2.0 )
            elseif dmginfo:IsDamageType( DMG_BLAST + DMG_BULLET + DMG_BUCKSHOT + DMG_IGNITE + DMG_SONIC ) then
                dmginfo:ScaleDamage( 0.6 )
            end
        end
    }
} )