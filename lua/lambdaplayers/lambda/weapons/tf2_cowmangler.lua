local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local ParticleEffectAttach = ParticleEffectAttach
local net = net

local reloadSnds = {
    ")weapons/cow_mangler_reload.wav",
    ")weapons/cow_mangler_reload_02.wav",
    ")weapons/cow_mangler_reload_03.wav",
    ")weapons/cow_mangler_reload_04.wav"
}
local reloadData = {
    StartDelay = 0.5,
    Animation = ACT_HL2MP_GESTURE_RELOAD_AR2,
    CycleSound = false,
    CycleFunction = function( lambda, weapon )
        if lambda.l_Clip == ( lambda.l_MaxClip - 1 ) then
            weapon:EmitSound( "weapons/cow_mangler_reload_final.wav", 70, nil, nil, CHAN_STATIC )
            return
        end

        weapon:EmitSound( reloadSnds[ random( #reloadSnds ) ], 70, nil, nil, CHAN_STATIC )
    end,    
    CycleDelay = 0.8,
    LayerCycle = 0.6,
    LayerPlayRate = 0.9,
    EndFunction = false
}
local rocketAttributes = {
    Model = "models/weapons/w_models/w_drg_ball.mdl",
    Sound = {
        ")weapons/cow_mangler_explosion_normal_01.wav",
        ")weapons/cow_mangler_explosion_normal_02.wav",
        ")weapons/cow_mangler_explosion_normal_03.wav"
    },
    DamageCustom = 8388608,
    HasCustomParticles = true,
    ExplodeParticle = {
        [ 0 ] = "drg_cow_explosioncore_normal",
        [ 1 ] = "drg_cow_explosioncore_normal_blue"
    },
}
local rocketChargedAttributes = {
    Model = "models/weapons/w_models/w_drg_ball.mdl",
    Sound = {
        ")weapons/cow_mangler_explosion_charge_01.wav",
        ")weapons/cow_mangler_explosion_charge_02.wav",
        ")weapons/cow_mangler_explosion_charge_03.wav"
    },
    DamageCustom = 16777216,
    HasCustomParticles = true,
    ExplodeParticle = {
        [ 0 ] = "drg_cow_explosioncore_charged",
        [ 1 ] = "drg_cow_explosioncore_charged_blue"
    },
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_cowmangler = {
        model = "models/lambdaplayers/tf2/weapons/w_cowmangler.mdl",
        origin = "Team Fortress 2",
        prettyname = "Cow Mangler 5000",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_cowmangler5000",

        clip = 4,
        islethal = true,
        attackrange = 2000,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
           
            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 55 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.8, 1.2 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "ClipDrain", 1 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent.l_IsCharging = false
            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnThink = function( self, wepent, isdead )
            if wepent.l_IsCharging then
                if isdead then wepent.l_IsCharging = false return end
                self.l_WeaponSpeedMultiplier = 0.33
            else
                self.l_WeaponSpeedMultiplier = 1.0
            end
        end,

        OnHolster = function( self, wepent )
            if wepent.l_IsCharging then return true end
        end,

        OnAttack = function( self, wepent, target )
            local chargedShot = false
            local teamColor = self.l_TF_TeamColor

            if self.l_Clip == self.l_MaxClip and random( 1, 3 ) == 1 and target == self:GetEnemy() and self:IsInRange( target, 1000 ) then
                chargedShot = true
                wepent.l_IsCharging = true
                wepent:EmitSound( ")weapons/cow_mangler_over_charge.wav", 75, nil, nil, CHAN_STATIC )
                self.l_WeaponUseCooldown = ( CurTime() + 2.5 )
                LAMBDA_TF2:DispatchColorParticle( wepent, "drg_cowmangler_muzzleflash_chargeup", PATTACH_POINT_FOLLOW, 1, teamColor )
            end

            self:SimpleWeaponTimer( ( chargedShot and 2.0 or 0.0 ), function()
                wepent.l_IsCharging = false

                local isCrit = wepent:CalcIsAttackCriticalHelper()
                if !LAMBDA_TF2:WeaponAttack( self, wepent, targetPos, isCrit ) then return end

                if !chargedShot then
                    wepent:EmitSound( ")weapons/cow_mangler_main_shot.wav", 75, 100, 1, CHAN_WEAPON )
                else
                    self.l_Clip = 0
                end

                local muzzleEffectName = "drg_cow_muzzleflash_" .. ( chargedShot and "charged" or "normal" ) .. ( teamColor == 1 and "_blue" or "" )
                LAMBDA_TF2:DispatchColorParticle( wepent, muzzleEffectName, PATTACH_POINT_FOLLOW, 1, teamColor )

                local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
                local targetPos
                if IsValid( target ) then
                    targetPos = ( ( ( !target:IsOnGround() or random( 1, 2 ) == 1 and self:IsInRange( target, 500 ) ) and !chargedShot ) and target:WorldSpaceCenter() or target:GetPos() )
                    targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1100, Rand( 0.5, 1.1 ), targetPos )
                else
                    targetPos = ( lambda:WorldSpaceCenter() + lambda:GetForward() * 500 )
                end

                local spawnAng = ( targetPos - spawnPos ):Angle()
                spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

                local energyBall = LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent, isCrit, ( chargedShot and rocketChargedAttributes or rocketAttributes ) )
                energyBall.l_TF_AfterburnDuration = 6
                energyBall.l_TF_AfterburnUseDefaultIcon = true

                if chargedShot or energyBall.l_ExplodeCrit == TF_CRIT_FULL then
                    energyBall.l_ExplodeCrit = TF_CRIT_MINI
                end

                local trailEffectName = "drg_cow_rockettrail_" .. ( chargedShot and "charged" or "normal" ) .. ( teamColor == 1 and "_blue" or "" )
                LAMBDA_TF2:DispatchColorParticle( energyBall, trailEffectName, PATTACH_ABSORIGIN_FOLLOW, 0, teamColor )
            end )

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )