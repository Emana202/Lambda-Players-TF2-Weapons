local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_forceanature = {
        model = "models/lambdaplayers/weapons/tf2/w_force_a_nature.mdl",
        origin = "Team Fortress 2",
        prettyname = "Force-A-Nature",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_forceanature",

        clip = 2,
        islethal = true,
        attackrange = 1000,
        keepdistance = 200,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 3 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.3125, 0.4 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/forceanature/scatter_gun_double_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 12 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )

            wepent.l_TF_HasKnockBack = false
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage then return end
            local vecDir = ( self:WorldSpaceCenter() - target:WorldSpaceCenter() )
            if vecDir:LengthSqr() > ( 400 * 400 ) then return end
            wepent.l_TF_HasKnockBack = true

            vecDir:Normalize()
            local size = ( target:OBBMaxs() - target:OBBMins() )
            local force = min( 1000, dmginfo:GetDamage() * ( ( 48 * 48 * 82 ) / ( size.x * size.y * size.z ) ) * 3 )
            local vecForce = ( vecDir * -force )

            local jumpSpeed = 268.3281572999747
            vecForce.z = ( vecForce.z + jumpSpeed )
            if target:IsOnGround() and vecForce.z < jumpSpeed then
                vecForce.z = jumpSpeed
            end

            if target:IsNextBot() then
                target.loco:Jump()

                local entVel = target.loco:GetVelocity(); entVel.z = 0
                target.loco:SetVelocity( entVel + vecForce )
            else
                target:SetVelocity( vecForce )
            end
        end,

        reloadtime = 1.4,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1.66,
        reloadsounds = {
            { 0.3, "lambdaplayers/weapons/tf2/forceanature/scatter_gun_double_tube_open.mp3" },
            { 1, "lambdaplayers/weapons/tf2/forceanature/scatter_gun_double_tube_close.mp3" }
        },

        OnReload = function( self, wepent )
            self:SimpleTimer( 0.35, function()
                LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
            end )
        end
    }
} )