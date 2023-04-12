local random = math.random
local IsValid = IsValid
local CurTime = CurTime

LAMBDA_TF2 = LAMBDA_TF2 or {}

LAMBDA_TF2.InventoryItems = {
    [ "tf2_sandwich" ] = {
        Condition = function( lambda )
            return ( LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) > 10 and !lambda:InCombat() and !lambda:IsPanicking() and lambda:Health() <= ( lambda:GetMaxHealth() * 0.5 ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( lambda:Health() >= lambda:GetMaxHealth() or lambda:InCombat() and lambda:CanSee( ene ) )
        end,
        Cooldown = 30
    },
    [ "tf2_banana" ] = {
        Condition = function( lambda )
            return ( LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) > 10 and !lambda:InCombat() and !lambda:IsPanicking() and lambda:Health() <= ( lambda:GetMaxHealth() * 0.75 ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( lambda:Health() >= lambda:GetMaxHealth() or lambda:InCombat() and lambda:CanSee( ene ) )
        end,
        Cooldown = 10
    },
    [ "tf2_buffalosteak" ] = {
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( random( 1, 4 ) == 1 and lambda.l_HasMelee and lambda:GetCritBoostType() == TF_CRIT_NONE and lambda:InCombat() and ( !lambda:CanSee( ene ) or !lambda:IsInRange( ene, 1500 ) ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( !lambda:InCombat() or lambda:CanSee( ene ) and lambda:IsInRange( ene, 1000 ) )
        end,
        Cooldown = 30
    },
    [ "tf2_chocolate" ] = {
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) > 10 and lambda:Health() < lambda:GetMaxHealth() and !lambda:InCombat() and !lambda:IsPanicking() or lambda:InCombat() and !lambda:IsInRange( ene, 300 ) and !lambda:CanSee( ene ) and random( 1, 12 ) == 1 )
        end,
        Cooldown = 10
    },
    [ "tf2_jarate" ] = {             
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( random( 1, 4 ) == 1 and lambda:InCombat() and lambda:GetCritBoostType() == TF_CRIT_NONE and !LAMBDA_TF2:IsBurning( ene ) and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !LAMBDA_TF2:IsBurning( ene ) and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
        end,
        SwitchBackCond = function( lambda )
            return ( ( !lambda:InCombat() or lambda:GetCritBoostType() != TF_CRIT_NONE ) and !LAMBDA_TF2:IsBurning( lambda )  )
        end,
        Cooldown = 20 
    },
    [ "tf2_madmilk" ] = {             
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( random( 1, 4 ) == 1 and lambda:InCombat() and lambda:GetCritBoostType() == TF_CRIT_NONE and !LAMBDA_TF2:IsBurning( ene ) and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !LAMBDA_TF2:IsBurning( ene ) and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
        end,
        SwitchBackCond = function( lambda )
            return ( ( !lambda:InCombat() or lambda:GetCritBoostType() != TF_CRIT_NONE ) and !LAMBDA_TF2:IsBurning( lambda )  )
        end,
        Cooldown = 20 
    },
    [ "tf2_critacola" ] = {             
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( random( 1, 10 ) == 1 and lambda:InCombat() and lambda:GetCritBoostType() == TF_CRIT_NONE and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and ( !lambda:IsInRange( ene, 300 ) or !lambda:CanSee( ene ) ) )
        end,
        SwitchBackCond = function( lambda )
            return ( lambda:GetCritBoostType() != TF_CRIT_NONE )
        end,
        Cooldown = 30
    },
    [ "tf2_cleaver" ] = {             
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            local attackDist = lambda.l_CombatAttackRange
            if !attackDist then attackDist = ( lambda.l_HasMelee and 70 or 1000 ) end
            return ( random( 1, 8 ) == 1 and lambda:InCombat() and lambda:CanSee( ene ) and lambda:IsInRange( ene, 1500 ) and ( lambda.l_Clip == 0 or lambda:GetIsReloading() or !lambda:IsInRange( ene, attackDist ) or random( 1, 10 ) == 1 ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( lambda:InCombat() and !lambda:CanSee( ene ) and !lambda:IsInRange( ene, 500 ) )
        end,
        Cooldown = 5.1
    },
    [ "tf2_bonk" ] = {             
        Condition = function( lambda )
            local retreatEnt = lambda.l_RetreatTarget
            return ( lambda:IsPanicking() and ( !LambdaIsValid( retreatEnt ) or !lambda:CanSee( retreatEnt ) or !lambda:IsInRange( retreatEnt, 1000 ) ) )
        end,
        Cooldown = 30
    },
    [ "tf2_razorback" ] = {             
        IsWeapon = false,
        PrettyName = "Razorback",
        Initialize = function( lambda )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 1
            lambda.l_TF_SniperShieldModel = LAMBDA_TF2:CreateBonemergedModel( lambda, "models/lambdaplayers/tf2/items/knife_shield.mdl", true )
        end,
        Cooldown = function( lambda )
            if CurTime() > lambda.l_TF_SniperShieldRechargeT then
                if lambda:Alive() then
                    local backshield = lambda.l_TF_SniperShieldModel
                    if IsValid( backshield ) then
                        lambda:ClientSideNoDraw( backshield, false )
                        backshield:SetNoDraw( false )
                        backshield:DrawShadow( true )
                    end
                end

                return true
            end
        end,
    },
    [ "tf2_cozycamper" ] = {             
        IsWeapon = false,
        PrettyName = "Cozy Camper",
        Initialize = function( lambda )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 2
            lambda.l_TF_SniperShieldModel = LAMBDA_TF2:CreateBonemergedModel( lambda, "models/lambdaplayers/tf2/items/commandobackpack.mdl", true )
        end
    },
    [ "tf2_darvinshield" ] = {             
        IsWeapon = false,
        PrettyName = "Darvin's Danger Shield",
        Initialize = function( lambda )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 3
            lambda.l_TF_SniperShieldModel = LAMBDA_TF2:CreateBonemergedModel( lambda, "models/lambdaplayers/tf2/items/croc_shield.mdl", true )
        end
    }
}

for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
    if data.isbuffpack then
        local buffType = data.bufftype
        local buffpackMdl = data.buffpackmdl

        LAMBDA_TF2.InventoryItems[ name ] = {
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( !lambda:InCombat() and #LAMBDA_TF2:GetFriendlyTargets( lambda, 450 ) > 1 or lambda:InCombat() and ( !lambda.l_HasMelee or CurTime() > lambda.l_WeaponUseCooldown ) and !lambda:IsInRange( ene, 600 ) )
            end,
            Cooldown = function( lambda )
                return ( !lambda.l_TF_RageActivated and lambda.l_TF_RageMeter >= 100 )
            end,
            Initialize = function( lambda )
                if lambda.l_TF_RageBuffType then return true end
                lambda.l_TF_RageBuffPack = LAMBDA_TF2:CreateBonemergedModel( lambda, buffpackMdl, true )
                lambda.l_TF_RageBuffType = buffType
            end
        }
    end
end

for item, data in pairs( LAMBDA_TF2.InventoryItems ) do
    if data.IsWeapon != false or !data.PrettyName then continue end

    local prettyName = data.PrettyName
    if !prettyName then continue end

    _LAMBDAPLAYERSWEAPONS[ item ] = {
        origin = "Team Fortress 2",
        notagprettyname = prettyName,
        prettyname = "[Team Fortress 2] " .. prettyName,
        cantbeselected = true
    }
    _LAMBDAWEAPONALLOWCONVARS[ item ] = CreateLambdaConvar( "lambdaplayers_weapons_allow_" .. item, 1, true, false, false, "Allows the Lambda Players to equip " .. prettyName .. " from Team Fortress 2 category", 0, 1 )
end