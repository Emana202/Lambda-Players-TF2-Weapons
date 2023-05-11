table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_neonannihilator = {
        model = "models/lambdaplayers/tf2/weapons/w_neonsign.mdl",
        origin = "Team Fortress 2",
        prettyname = "Neon Annihilator",
        holdtype = "melee2",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_neon_annihilator",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/neon_sign_hit_01.wav",
                ")weapons/neon_sign_hit_02.wav",
                ")weapons/neon_sign_hit_03.wav",
                ")weapons/neon_sign_hit_04.wav"
            } )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_PLASMA )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if target.IsLambdaPlayer or target:IsPlayer() then
                    dmginfo:ScaleDamage( 0.8 )
                end

                local waterExitT = target.l_TF_WaterExitTime
                if LAMBDA_TF2:GetCritType( dmginfo ) != TF_CRIT_FULL and ( target.l_TF_CoveredInUrine or target.l_TF_CoveredInMilk or waterExitT and ( CurTime() - waterExitT ) < 5.0 or LAMBDA_TF2:GetWaterLevel( target ) != 0 ) then
                    LAMBDA_TF2:SetCritType( dmginfo, TF_CRIT_FULL )
                end
            end )

            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )