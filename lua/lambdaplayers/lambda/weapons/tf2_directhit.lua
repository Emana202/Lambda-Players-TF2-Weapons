local CurTime = CurTime

local rocketAttributes = {
    Radius = 43.8,
    Speed = 1980,
    Damage = 68.75,
    Sound = {
        ")weapons/rocket_directhit_explode1.wav",
        ")weapons/rocket_directhit_explode2.wav",
        ")weapons/rocket_directhit_explode3.wav"
    },
    OnDealDamage = function( rocket, hitEnt, dmginfo )
        if LAMBDA_TF2:GetCritType( dmginfo ) != TF_CRIT_NONE or !IsValid( hitEnt ) or !LAMBDA_TF2:IsValidCharacter( hitEnt ) or hitEnt:OnGround() then return end
        LAMBDA_TF2:SetCritType( dmginfo, TF_CRIT_MINI )
    end
}
local reloadData = {
    StartDelay = 0.5,
    CycleSound = "weapons/rocket_reload.wav",
    CycleDelay = 0.8,
    LayerCycle = 0.1,
    LayerPlayRate = 1.2,
    EndFunction = false
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_directhit = {
        model = "models/lambdaplayers/tf2/weapons/w_directhit.mdl",
        origin = "Team Fortress 2",
        prettyname = "Direct Hit",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_directhit",
        tfclass = 2,

        clip = 4,
        islethal = true,
        attackrange = 2500,
        keepdistance = 1000,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
           
            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 55 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.8, 1.2 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/rocket_directhit_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/rocket_directhit_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "MuzzleFlash", 7 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( ( !target:IsOnGround() or LambdaRNG( 1, 2 ) == 1 and self:IsInRange( target, 500 ) ) and target:WorldSpaceCenter() or target:GetPos() )
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1100, LambdaRNG( 0.5, 1.1, true ), targetPos )

            local spawnAng = ( ( targetPos + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( targetPos ) * LambdaRNG( 0.66, 1.1, true ) ) / 1100 ) ) ) - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * LambdaRNG( -5, 5 ) + spawnAng:Up() * LambdaRNG( -5, 5 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end
            
            LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent, isCrit, rocketAttributes )
            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )