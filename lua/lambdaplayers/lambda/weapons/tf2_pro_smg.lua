table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_pro_smg = {
        model = "models/lambdaplayers/tf2/weapons/w_pro_smg.mdl",
        origin = "Team Fortress 2",
        prettyname = "Cleaner's Carbine",
        holdtype = {
            idle = ACT_HL2MP_IDLE_RPG,
            run = ACT_HL2MP_RUN_RPG,
            walk = ACT_HL2MP_WALK_RPG,
            jump = ACT_HL2MP_JUMP_RPG,
            crouchIdle = ACT_HL2MP_IDLE_CROUCH_AR2,
            crouchWalk = ACT_HL2MP_WALK_CROUCH_AR2,
            swimIdle = ACT_HL2MP_SWIM_IDLE_RPG,
            swimMove = ACT_HL2MP_SWIM_RPG
        },
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_cleanercarbine",

        clip = 20,
        islethal = true,
        attackrange = 1500,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.13125 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            wepent:SetWeaponAttribute( "Sound", ")weapons/doom_sniper_smg.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/doom_sniper_smg_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            
            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_smg" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_pistol_tracer01" )

            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if !lambda.l_TF_CrikeyMeterFull or lambda:GetCritBoostType() != TF_CRIT_NONE then return end

                lambda.l_TF_CrikeyMeter = 0
                lambda.l_TF_CrikeyMeterFull = false
                LAMBDA_TF2:AddCritBoost( lambda, "CRIKEY", TF_CRIT_MINI, 8 )
            end )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage or self.l_TF_CritBoosts[ "CRIKEY" ] then return end
            self.l_TF_CrikeyMeter = ( self.l_TF_CrikeyMeter + dmginfo:GetDamage() )

            if self.l_TF_CrikeyMeter >= 100 and !self.l_TF_CrikeyMeterFull then
                self.l_TF_CrikeyMeterFull = true
                wepent:EmitSound( "player/recharged.wav", 65, nil, 0.5, CHAN_STATIC )
            end
        end,

        reloadtime = 1.1,
        reloadsounds = { { 0, "weapons/smg_worldreload.wav" } },

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
            local reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )
            self:SetLayerPlaybackRate( reloadLayer, 2 )
        end
    }
} )