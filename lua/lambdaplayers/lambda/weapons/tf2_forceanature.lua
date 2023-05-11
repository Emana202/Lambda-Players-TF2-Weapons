local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_forceanature = {
        model = "models/lambdaplayers/tf2/weapons/w_force_a_nature.mdl",
        origin = "Team Fortress 2",
        prettyname = "Force-A-Nature",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_forceanature",

        clip = 2,
        islethal = true,
        attackrange = 700,
        keepdistance = 200,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 3 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.3125, 0.4 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/scatter_gun_double_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/scatter_gun_double_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ProjectileCount", 12 )
            wepent:SetWeaponAttribute( "DamageType", DMG_BUCKSHOT )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_bignasty" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_bignasty_tracer01" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage then return end
            
            local vecDir = ( self:WorldSpaceCenter() - target:WorldSpaceCenter() )
            if vecDir:LengthSqr() > 160000 then return end
            
            wepent.l_TF_HasKnockBack = true

            vecDir:Normalize()
            local force = LAMBDA_TF2:GetDamageForce( target, dmginfo:GetDamage(), 3 )
            local vecForce = ( vecDir * -force )

            local size = ( target:OBBMaxs() - target:OBBMins() )
            local force = min( 1000, dmginfo:GetDamage() * ( 73728 / ( size.x * size.y * size.z ) ) * 3 )
            
            local vecForce = ( vecDir * -force )
            vecForce.z = ( vecForce.z + 268.3281572999747 )
            LAMBDA_TF2:ApplyAirBlastImpulse( target, vecForce )
        end,

        reloadtime = 1.4,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1.33,
        reloadsounds = {
            { 0.2, "weapons/scatter_gun_double_tube_open.wav" },
            { 0.466667, "weapons/scatter_gun_double_shells_out.wav" },
            { 0.933333, "weapons/scatter_gun_double_shells_in.wav" },
            { 1.366667, "weapons/scatter_gun_double_tube_close.wav" }
        },

        OnReload = function( self, wepent )
            self:SimpleWeaponTimer( 0.466667, function()
                LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
            end )
        end
    }
} )