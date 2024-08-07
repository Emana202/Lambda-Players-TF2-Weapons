
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_reserveshooter = {
        model = "models/lambdaplayers/tf2/weapons/w_reserve_shooter.mdl",
        origin = "Team Fortress 2",
        prettyname = "Reserve Shooter",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_reserveshooter",
        tfclass = { [ 2 ] = true, [ 3 ] = true },
        
        clip = 6,
        islethal = true,
        attackrange = 800,
        keepdistance = 500,
        deploydelay = 0.4,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/reserve_shooter_01.wav",
                ")weapons/reserve_shooter_02.wav",
                ")weapons/reserve_shooter_03.wav",
                ")weapons/reserve_shooter_04.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", {
                ")weapons/reserve_shooter_01_crit.wav",
                ")weapons/reserve_shooter_02_crit.wav",
                ")weapons/reserve_shooter_03_crit.wav",
                ")weapons/reserve_shooter_04_crit.wav"
            } )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType",DMG_BUCKSHOT )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_shotgun" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_shotgun_tracer01" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo ) 
                if LAMBDA_TF2:GetCritType( dmginfo ) != TF_CRIT_NONE then return end

                local hitEnt = tr.Entity
                if !IsValid( hitEnt ) or !LAMBDA_TF2:IsValidCharacter( hitEnt ) or hitEnt:OnGround() then return end

                LAMBDA_TF2:GetCritType( dmginfo, TF_CRIT_MINI )
            end ) 

            wepent:EmitSound( LambdaRNG( 1, 2 ) == 1 and "weapons/draw_secondary.wav" or "weapons/draw_shotgun_pyro.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) then
                self:SimpleWeaponTimer( 0.266, function()
                    wepent:EmitSound( "weapons/shotgun_cock_back.wav", 70, nil, nil, CHAN_STATIC )
                end )
                self:SimpleWeaponTimer( 0.416, function()
                    wepent:EmitSound( "weapons/shotgun_cock_forward.wav", 70, nil, nil, CHAN_STATIC )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end )
            end

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent )
            return true
        end
    }
} )