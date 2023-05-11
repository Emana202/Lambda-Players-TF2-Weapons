local CurTime = CurTime
local random = math.random
local Rand = math.Rand

local reloadData = {
    StartSound = "weapons/grenade_launcher_drum_open.wav",
    StartDelay = 0.6,
    CycleSound = "weapons/grenade_launcher_drum_load.wav",
    CycleDelay = 0.666667,
    EndSound = "weapons/grenade_launcher_drum_close.wav",
    EndFunction = false,
    LayerPlayRate = 1.6
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_grenadelauncher = {
        model = "models/lambdaplayers/tf2/weapons/w_grenade_launcher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Grenade Launcher",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_grenadelauncher",

        clip = 4,
        islethal = true,
        attackrange = 1500,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.6, 1.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/grenade_launcher_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/grenade_launcher_shoot_crit.wav" )
            
            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_grenadelauncher" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( self:IsInRange( target, 100 ) and target:WorldSpaceCenter() or target:GetPos() + vector_up * ( self:GetRangeTo( target ) / random( 15, 20 ) ) )
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1200, Rand( 0.5, 1.1 ), targetPos )

            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -10, 10 ) + spawnAng:Up() * random( -10, 10 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end
            
            self:SimpleWeaponTimer( 0.366667, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )

            LAMBDA_TF2:CreatePipeGrenadeProjectile( spawnPos, spawnAng, self, wepent, isCrit )
            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )