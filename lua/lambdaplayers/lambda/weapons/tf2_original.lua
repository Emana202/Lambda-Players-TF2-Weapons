local random = math.random
local Rand = math.Rand
local CurTime = CurTime

local rocketAttributes = {
    Sound = "weapons/quake_explosion_remastered.wav"
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_original = {
        model = "models/lambdaplayers/tf2/weapons/w_bet_rocketlauncher.mdl",
        origin = "Team Fortress 2",
        prettyname = "The Original",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_original",

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
            wepent:SetWeaponAttribute( "Sound", "weapons/quake_rpg_fire_remastered.wav" )
            wepent:SetWeaponAttribute( "CritSound", "weapons/quake_rpg_fire_remastered_crit.wav" )
            wepent:SetWeaponAttribute( "MuzzleFlash", 7 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/quake_ammo_pickup_remastered.wav", nil, nil, nil, CHAN_STATIC )
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
            
            LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent, rocketAttributes )
            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, {
                StartSound = "weapons/quake_rpg_reload_remastered.wav",
                StartDelay = 0.92,
                StartFunction = function( lambda, weapon )
                    lambda.l_Clip = ( lambda.l_Clip + 1 )
                end,
                CycleSound = "weapons/quake_rpg_reload_remastered.wav",
                CycleDelay = 0.8,
                LayerCycle = 0.1,
                LayerPlayRate = 1.2,
                EndFunction = false
            } )

            return true
        end
    }
} )