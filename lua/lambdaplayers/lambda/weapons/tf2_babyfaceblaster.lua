local reloadData = {
    Animation = "reload_smg1_alt",
    StartDelay = 0.7,
    CycleSound = "weapons/scatter_gun_worldreload.wav",
    CycleFunction = function( lambda, weapon )
        LAMBDA_TF2:CreateShellEject( weapon, "ShotgunShellEject" )
    end,
    EndFunction = false
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_babyfaceblaster = {
        model = "models/lambdaplayers/tf2/weapons/w_babyface_blaster.mdl",
        origin = "Team Fortress 2",
        prettyname = "Baby Face's Blaster",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_babyfaceblaster",
        tfclass = 1,

        clip = 4,
        islethal = true,
        attackrange = 800,
        keepdistance = 300,
        deploydelay = 0.5,
		speedmultiplier = 0.9,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/doom_scout_shotgun.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/doom_scout_shotgun_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", DMG_BUCKSHOT )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_scattergun" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_scattergun_tracer01" )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnThink = function( self )
            self.l_WeaponSpeedMultiplier = LAMBDA_TF2:RemapClamped( self.l_TF_HypeMeter, 0, 99, 0.9, 1.3 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )