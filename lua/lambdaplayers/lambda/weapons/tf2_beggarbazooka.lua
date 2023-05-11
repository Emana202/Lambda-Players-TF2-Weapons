local random = math.random
local Rand = math.Rand
local CurTime = CurTime

local rocketAttributes = {
    Radius = 116.8
}
local reloadData = {
    StartDelay = 0.65,
    CycleSound = "weapons/dumpster_rocket_reload.wav",
    CycleDelay = 1.04,
    LayerCycle = 0.076923,
    LayerPlayRate = 0.923077,
    InterruptCondition = function( lambda, weapon )
        return ( lambda.l_Clip > 0 and ( !lambda:InCombat() and CurTime() > weapon.l_FireTime or lambda:InCombat() and random( 1, 3 ) == 1 and lambda:IsInRange( lambda:GetEnemy(), 512 ) and lambda:CanSee( lambda:GetEnemy() ) ) )
    end,
    EndFunction = false
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_beggarbazooka = {
        model = "models/lambdaplayers/tf2/weapons/w_dumpster_device.mdl",
        origin = "Team Fortress 2",
        prettyname = "Beggar's Bazooka",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_beggarbazooka",

        clip = 3,
        islethal = true,
        attackrange = 1500,
        keepdistance = 600,
        deploydelay = 0.5,

        cantreplenishclip = true,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
           
            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 55 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.24 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/doom_rocket_launcher.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/doom_rocket_launcher_crit.wav" )
            wepent:SetWeaponAttribute( "MuzzleFlash", 7 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            self.l_Clip = 0
            wepent.l_FireTime = 0
            wepent.l_IsAlive = true
            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnThink = function( self, wepent, isDead )
            if !isDead then 
                if wepent.l_IsAlive == false then
                    self.l_Clip = 0
                    wepent.l_IsAlive = true
                end

                if self.l_Clip > 0 and !self:GetIsReloading() then
                    self:UseWeapon( self:InCombat() and self:GetEnemy() or ( self:WorldSpaceCenter() + self:GetForward() * 500 ) )
                end
            else
                wepent.l_IsAlive = false
            end
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos
            if isvector( target ) then
                targetPos = target
            else
                targetPos = ( ( !target:IsOnGround() or random( 1, 2 ) == 1 and self:IsInRange( target, 500 ) ) and target:WorldSpaceCenter() or target:GetPos() )
                targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1100, Rand( 0.5, 1.1 ), targetPos )
            end


            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

            local angSpread = AngleRand( -3, 3 )
            angSpread.z = 0.0
            spawnAng = ( spawnAng + angSpread )

            if self.l_Clip == 0 and !self:GetIsReloading() and self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end
            wepent.l_FireTime = ( CurTime() + 0.1 )

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end

            LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent, isCrit, rocketAttributes )
            return true
        end,

        OnReload = function( self, wepent )
            if CurTime() <= wepent.l_FireTime then
                LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            end
            return true
        end
    }
} )