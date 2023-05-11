local CurTime = CurTime
local random = math.random
local Rand = math.Rand
local IsValid = IsValid
local FrameTime = FrameTime
local pairs = pairs

local grenadeAttributes = {
    Model = "models/weapons/w_models/w_cannonball.mdl",
    Speed = 1440,
    ExplodeOnImpact = false,
    DetonateTime = 0.5,
    OnTouch = function( pipe, hitEnt )
        if pipe.l_HasTouched then return end

        local owner = pipe:GetOwner()
        if !IsValid( owner ) or !LambdaIsValid( hitEnt ) or pipe.l_PenetratedEntities[ hitEnt ] or !LAMBDA_TF2:TakesDamage( hitEnt ) or !owner:CanTarget( hitEnt ) then return end

        local distSqr = owner:GetPos():DistToSqr( hitEnt:GetPos() )
        local impactDmg = LAMBDA_TF2:RemapClamped( distSqr, 262144, 1048576, 30, 15 )

        local dmginfo = DamageInfo()
        dmginfo:SetDamage( impactDmg )
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( pipe )
        dmginfo:SetDamagePosition( pipe:GetPos() )
        dmginfo:SetDamageForce( pipe:GetPhysicsObject():GetVelocity() * impactDmg )
        dmginfo:SetDamageType( DMG_BLAST )

        dmginfo:SetDamageCustom( TF_DMG_CUSTOM_CANNONBALL_PUSH + TF_DMG_CUSTOM_HALF_FALLOFF )
        LAMBDA_TF2:SetCritType( dmginfo, pipe.l_ExplodeCrit )

        hitEnt:TakeDamageInfo( dmginfo )
        pipe.l_PenetratedEntities[ hitEnt ] = true

        if LAMBDA_TF2:IsValidCharacter( hitEnt ) then
            local vecToTarget = ( ( hitEnt:WorldSpaceCenter() - owner:WorldSpaceCenter() ):GetNormalized() * 400 )
            vecToTarget.z = ( vecToTarget.z + 350 )
            LAMBDA_TF2:ApplyAirBlastImpulse( hitEnt, vecToTarget )
        end

        pipe:SetPos( pipe:GetPos() - ( pipe:GetPhysicsObject():GetVelocity() * FrameTime() ) )
        pipe:EmitSound( "weapons/loose_cannon_ball_impact.wav", 80, random( 95, 105 ), 0.7, CHAN_WEAPON )

        for victim, expireTime in pairs( owner.l_TF_DonkVictims ) do
            if expireTime > CurTime() then continue end
            owner.l_TF_DonkVictims[ victim ] = nil
        end
        owner.l_TF_DonkVictims[ hitEnt ] = ( CurTime() + 0.5 )

        return true
    end,
    Sound = ")weapons/loose_cannon_explode.wav"
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
    tf2_loosecannon = {
        model = "models/lambdaplayers/tf2/weapons/w_demo_cannon.mdl",
        origin = "Team Fortress 2",
        prettyname = "Loose Cannon",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_loose_cannon",

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
            wepent:SetWeaponAttribute( "Sound", ")weapons/loose_cannon_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/loose_cannon_shootcrit.wav" )
            
            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_grenadelauncher" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local maxChargeTime = LAMBDA_TF2:RemapClamped( self:GetRangeTo( target ), 128, 768, 7.5, 0 )
            local chargeTime = ( random( 0, maxChargeTime ) / 10 )
            self.l_WeaponUseCooldown = ( CurTime() + chargeTime )

            wepent:EmitSound( "weapons/loose_cannon_charge.wav", 70, nil, 0.45, CHAN_WEAPON )
            self:SimpleWeaponTimer( chargeTime, function()
                wepent:StopSound( "weapons/loose_cannon_charge.wav" )
                if !IsValid( target ) then return end

                local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
                local targetPos = ( self:IsInRange( target, 100 ) and target:WorldSpaceCenter() or target:GetPos() + vector_up * ( self:GetRangeTo( target ) / random( 15, 20 ) ) )
                targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1200, Rand( 0.5, 1.1 ), targetPos )
    
                local spawnAng = ( targetPos - spawnPos ):Angle()
                spawnAng = ( ( targetPos + spawnAng:Right() * random( -10, 10 ) + spawnAng:Up() * random( -10, 10 ) ) - spawnPos ):Angle()
                if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return end
    
                local isCrit = wepent:CalcIsAttackCriticalHelper()
                if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return end

                self:SimpleWeaponTimer( 0.366667, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
                self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
                grenadeAttributes.DetonateTime = ( 1.0 - chargeTime )
                
                local ball = LAMBDA_TF2:CreatePipeGrenadeProjectile( spawnPos, spawnAng, self, wepent, isCrit, grenadeAttributes )
                ball.l_IsTFCannonBall = true
                ball.l_PenetratedEntities = {}
            end )

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )