local CurTime = CurTime

local grenadeAttributes = {
    Model = "models/workshop/weapons/c_models/c_quadball/w_quadball_grenade.mdl",
    Radius = 124.1,
    DetonateTime = 1.4,
    OnPhysicsCollide = function( pipe, colData, collider )
        if pipe.l_HasTouched then return end
        collider:SetVelocity( collider:GetVelocity() * 0.1 )
        collider:SetAngleVelocity( collider:GetAngleVelocity() * 0.1 )
    end,
    Sound = {
        ")weapons/tacky_grenadier_explode1.wav",
        ")weapons/tacky_grenadier_explode2.wav",
        ")weapons/tacky_grenadier_explode3.wav"
    }
}
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
    tf2_ironbomber = {
        model = "models/lambdaplayers/tf2/weapons/w_iron_bomber.mdl",
        origin = "Team Fortress 2",
        prettyname = "Iron Bomber",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_iron_bomber",
        tfclass = 4,

        clip = 4,
        islethal = true,
        attackrange = 1000,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.6, 1.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/tacky_grenadier_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/tacky_grenadier_shoot_crit.wav" )
            
            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_grenadelauncher" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( self:IsInRange( target, 100 ) and target:WorldSpaceCenter() or target:GetPos() + vector_up * ( self:GetRangeTo( target ) / LambdaRNG( 10, 12 ) ) )
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1200, LambdaRNG( 0.5, 1.1, true ), targetPos )

            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * LambdaRNG( -10, 10 ) + spawnAng:Up() * LambdaRNG( -10, 10 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end
            
            self:SimpleWeaponTimer( 0.366667, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
            
            LAMBDA_TF2:CreatePipeGrenadeProjectile( spawnPos, spawnAng, self, wepent, isCrit, grenadeAttributes )
            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )