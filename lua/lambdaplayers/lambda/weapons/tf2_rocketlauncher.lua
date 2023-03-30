local random = math.random
local Rand = math.Rand
local CurTime = CurTime

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_rocketlauncher = {
        model = "models/lambdaplayers/tf2/weapons/w_rocket_launcher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Rocket Launcher",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_rocketlauncher",

        clip = 4,
        islethal = true,
        attackrange = 2000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
           
            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 55 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.8, 1.2 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/rocket_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/rocket_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "MuzzleFlash", 7 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( ( !target:IsOnGround() or random( 1, 2 ) == 1 and self:IsInRange( target, 500 ) ) and target:WorldSpaceCenter() or target:GetPos() )
            targetPos = ( targetPos + ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( target ) * Rand( 0.5, 1.1 ) ) / 1100 ) )

            local spawnAng = ( ( targetPos + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( targetPos ) * Rand( 0.66, 1.1 ) ) / 1100 ) ) ) - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

            spawnPos = ( spawnPos + spawnAng:Forward() * ( self.loco:GetVelocity():Length() * FrameTime() * 4 ) )
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end
            
            LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent )
            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, {
                StartSound = "weapons/rocket_reload.wav",
                StartDelay = 0.92,
                StartFunction = function( lambda, weapon )
                    lambda.l_Clip = ( lambda.l_Clip + 1 )
                end,
                CycleSound = "weapons/rocket_reload.wav",
                CycleDelay = 0.8,
                LayerCycle = 0.1,
                LayerPlayRate = 1.2,
                EndFunction = false
            } )

            return true
        end
    }
} )