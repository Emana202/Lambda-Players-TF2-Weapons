local IsValid = IsValid
local CurTime = CurTime

LAMBDA_TF2 = LAMBDA_TF2 or {}

LAMBDA_TF2.InventoryItems = {
    [ "tf2_sandwich" ] = {
        Class = 5,
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
        Class = 5,
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
        Class = 5,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LambdaRNG( 1, 20 ) == 1 and lambda.l_HasMelee and lambda:l_GetCritBoostType() == TF_CRIT_NONE and lambda:InCombat() and ( !lambda:CanSee( ene ) or !lambda:IsInRange( ene, 1500 ) ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( !lambda:InCombat() or lambda:CanSee( ene ) and lambda:IsInRange( ene, 1000 ) )
        end,
        Cooldown = 30
    },
    [ "tf2_chocolate" ] = {
        Class = 5,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LAMBDA_TF2:GetTimeSinceLastDamage( lambda ) > 10 and lambda:Health() < lambda:GetMaxHealth() and !lambda:InCombat() and !lambda:IsPanicking() or lambda:InCombat() and !lambda:IsInRange( ene, 300 ) and !lambda:CanSee( ene ) and LambdaRNG( 1, 12 ) == 1 )
        end,
        Cooldown = 10
    },
    [ "tf2_jarate" ] = {
        Class = 8,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LambdaRNG( 1, 5 ) == 1 and lambda:InCombat() and lambda:l_GetCritBoostType() == TF_CRIT_NONE and !LAMBDA_TF2:IsBurning( ene ) and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !LAMBDA_TF2:IsBurning( ene ) and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
        end,
        SwitchBackCond = function( lambda )
            return ( ( !lambda:InCombat() or lambda:l_GetCritBoostType() != TF_CRIT_NONE ) and !LAMBDA_TF2:IsBurning( lambda )  )
        end,
        Cooldown = 20 
    },
    [ "tf2_madmilk" ] = {
        Class = 1,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LambdaRNG( 1, 5 ) == 1 and lambda:InCombat() and lambda:l_GetCritBoostType() == TF_CRIT_NONE and !LAMBDA_TF2:IsBurning( ene ) and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and !LAMBDA_TF2:IsBurning( ene ) and !lambda:IsInRange( ene, 200 ) and lambda:IsInRange( ene, 750 ) or !lambda:InCombat() and LAMBDA_TF2:IsBurning( lambda ) )
        end,
        SwitchBackCond = function( lambda )
            return ( ( !lambda:InCombat() or lambda:l_GetCritBoostType() != TF_CRIT_NONE ) and !LAMBDA_TF2:IsBurning( lambda )  )
        end,
        Cooldown = 20 
    },
    [ "tf2_critacola" ] = {
        Class = 1,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( LambdaRNG( 1, 20 ) == 1 and lambda:InCombat() and lambda:l_GetCritBoostType() == TF_CRIT_NONE and !ene.l_TF_CoveredInMilk and !ene.l_TF_CoveredInUrine and ( !lambda:IsInRange( ene, 300 ) or !lambda:CanSee( ene ) ) )
        end,
        SwitchBackCond = function( lambda )
            return ( lambda:l_GetCritBoostType() != TF_CRIT_NONE )
        end,
        Cooldown = 30
    },
    [ "tf2_cleaver" ] = {
        Class = 1,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            local attackDist = lambda.l_CombatAttackRange
            if !attackDist then attackDist = ( lambda.l_HasMelee and 70 or 1000 ) end
            return ( LambdaRNG( 1, 10 ) == 1 and lambda:InCombat() and lambda:CanSee( ene ) and lambda:IsInRange( ene, 1500 ) and ( lambda.l_Clip == 0 or lambda:GetIsReloading() or !lambda:IsInRange( ene, attackDist ) or LambdaRNG( 1, 10 ) == 1 ) )
        end,
        SwitchBackCond = function( lambda )
            local ene = lambda:GetEnemy()
            return ( lambda:InCombat() and !lambda:CanSee( ene ) and !lambda:IsInRange( ene, 500 ) )
        end,
        Cooldown = 5.1
    },
    [ "tf2_bonk" ] = {
        Class = 1,
        Condition = function( lambda )
            local ene = lambda:GetEnemy()
            return ( lambda:IsPanicking() and ( !LambdaIsValid( ene ) or !lambda:CanSee( ene ) or !lambda:IsInRange( ene, 1000 ) ) )
        end,
        Cooldown = 30
    },
    [ "tf2_razorback" ] = {
        Class = 8,
        IsWeapon = false,
        PrettyName = "Razorback",
        WorldModel = "models/lambdaplayers/tf2/items/knife_shield.mdl",
        WearsOnBack = true,
        Initialize = function( lambda, mdlEnt )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 1
            lambda.l_TF_SniperShieldModel = mdlEnt
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
        OnUnequip = function( lambda ) 
            lambda.l_TF_SniperShieldType = nil 
            lambda.l_TF_SniperShieldModel = NULL
        end
    },
    [ "tf2_cozycamper" ] = {
        Class = 8,
        IsWeapon = false,
        PrettyName = "Cozy Camper",
        WorldModel = "models/lambdaplayers/tf2/items/commandobackpack.mdl",
        WearsOnBack = true,
        Initialize = function( lambda )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 2
        end,
        OnUnequip = function( lambda ) lambda.l_TF_SniperShieldType = nil end
    },
    [ "tf2_darvinshield" ] = {
        Class = 8,
        IsWeapon = false,
        PrettyName = "Darvin's Danger Shield",
        WorldModel = "models/lambdaplayers/tf2/items/croc_shield.mdl",
        WearsOnBack = true,
        Initialize = function( lambda )
            if lambda.l_TF_SniperShieldType then return true end
            lambda.l_TF_SniperShieldType = 3
        end,
        OnUnequip = function( lambda ) lambda.l_TF_SniperShieldType = nil end
    },
    [ "tf2_basejumper" ] = {
        Class = 2,
        IsWeapon = false,
        PrettyName = "B.A.S.E. Jumper",
        WorldModel = "models/lambdaplayers/tf2/items/base_jumper.mdl",
        WearsOnBack = true,
        Initialize = function( lambda, mdlEnt ) 
            lambda.l_TF_ParachuteModel = mdlEnt
            lambda.l_TF_ParachuteDeathDropHeight = lambda.loco:GetDeathDropHeight() 
            lambda.loco:SetDeathDropHeight( 3000 ) 
        end,
        OnUnequip = function( lambda ) 
            lambda.l_TF_ParachuteModel = NULL 
            lambda.loco:SetDeathDropHeight( lambda.l_TF_ParachuteDeathDropHeight ) 
        end
    },
    [ "tf2_chargintarge" ] = {
        Class = 4,
        IsWeapon = false,
        PrettyName = "Chargin' Targe",
        WorldModel = "models/lambdaplayers/tf2/weapons/w_targe.mdl",
        IsDemoShield = true,
        Initialize = function( lambda, mdlEnt ) 
            if lambda.l_TF_Shield_Type then return true end
            mdlEnt.IsLambdaWeapon = true
            mdlEnt.l_killiconname = "lambdaplayers_weaponkillicons_tf2_chargintarge"
            lambda.l_TF_Shield_Entity = mdlEnt
            lambda.l_TF_Shield_Type = 1
        end,
        OnUnequip = function( lambda ) 
            lambda.l_TF_Shield_Entity = NULL 
            lambda.l_TF_Shield_Type = false
        end
    },
    [ "tf2_splendidscreen" ] = {
        Class = 4,
        IsWeapon = false,
        PrettyName = "Splendid Screen",
        WorldModel = "models/lambdaplayers/tf2/weapons/w_persian_shield.mdl",
        IsDemoShield = true,
        Initialize = function( lambda, mdlEnt ) 
            if lambda.l_TF_Shield_Type then return true end
            mdlEnt.IsLambdaWeapon = true
            mdlEnt.l_killiconname = "lambdaplayers_weaponkillicons_tf2_splendidscreen"
            lambda.l_TF_Shield_Entity = mdlEnt
            lambda.l_TF_Shield_Type = 2
        end,
        OnUnequip = function( lambda ) 
            lambda.l_TF_Shield_Entity = NULL
            lambda.l_TF_Shield_Type = false
        end
    },
    [ "tf2_tideturner" ] = {
        Class = 4,
        IsWeapon = false,
        PrettyName = "Tide Turner",
        WorldModel = "models/lambdaplayers/tf2/weapons/w_wheel_shield.mdl",
        IsDemoShield = true,
        Initialize = function( lambda, mdlEnt ) 
            if lambda.l_TF_Shield_Type then return true end
            mdlEnt.IsLambdaWeapon = true
            mdlEnt.l_killiconname = "lambdaplayers_weaponkillicons_tf2_chargintarge"
            lambda.l_TF_Shield_Entity = mdlEnt
            lambda.l_TF_Shield_Type = 3
        end,
        OnUnequip = function( lambda ) 
            lambda.l_TF_Shield_Entity = NULL 
            lambda.l_TF_Shield_Type = false
        end
    }
}

for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
    if data.isbuffpack then
        local buffType = data.bufftype

        LAMBDA_TF2.InventoryItems[ name ] = {
            Class = 2,
            IsWeapon = true,
            PrettyName = data.prettyname,
            WorldModel = data.buffpackmdl,
            WearsOnBack = true,
            
            Condition = function( lambda )
                local ene = lambda:GetEnemy()
                return ( !lambda:InCombat() and #LAMBDA_TF2:GetFriendlyTargets( lambda, 450 ) > 1 or lambda:InCombat() and ( !lambda.l_HasMelee or CurTime() > lambda.l_WeaponUseCooldown ) and !lambda:IsInRange( ene, 600 ) )
            end,
            Cooldown = function( lambda )
                return ( !lambda.l_TF_RageActivated and lambda.l_TF_RageMeter >= 100 )
            end,
            Initialize = function( lambda, mdlEnt )
                if lambda.l_TF_RageBuffType then return true end
                lambda.l_TF_RageBuffPack = mdlEnt
                lambda.l_TF_RageBuffType = buffType
            end,
            OnUnequip = function( lambda ) 
                lambda.l_TF_RageBuffPack = NULL
                lambda.l_TF_RageBuffType = nil
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