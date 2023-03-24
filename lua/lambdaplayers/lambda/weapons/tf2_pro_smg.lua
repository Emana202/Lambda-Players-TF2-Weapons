local min = math.min
local FrameTime = FrameTime

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_pro_smg = {
        model = "models/lambdaplayers/weapons/tf2/w_pro_smg.mdl",
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
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.13125 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/smg/doom_sniper_smg.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if wepent.l_TF_MiniCritBoostFull and !wepent.l_TF_MiniCritBoostActive and !lambda.l_TF_MiniCritBoosted then
                    wepent.l_TF_MiniCritBoostMeter = 0
                    wepent.l_TF_MiniCritBoostFull = false
                    wepent.l_TF_MiniCritBoostActive = true
                    lambda.l_TF_MiniCritBoosted = CurTime() + 8
                end
            end )

            wepent.l_TF_MiniCritBoostMeter = 0
            wepent.l_TF_MiniCritBoostFull = false
            wepent.l_TF_MiniCritBoostActive = false
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage or wepent.l_TF_MiniCritBoostFull or wepent.l_TF_MiniCritBoostActive then return end
            wepent.l_TF_MiniCritBoostMeter = ( wepent.l_TF_MiniCritBoostMeter + dmginfo:GetDamage() )
            
            if wepent.l_TF_MiniCritBoostMeter >= 100 then
                wepent.l_TF_MiniCritBoostMeter = 100
                wepent.l_TF_MiniCritBoostFull = true
                wepent:EmitSound( "lambdaplayers/weapons/tf2/recharged.mp3", 70, 100, 0.5, CHAN_STATIC )
            end
        end,

        OnThink = function( self, wepent, dead )
            if wepent.l_TF_MiniCritBoostActive and !self.l_TF_MiniCritBoosted then
                wepent.l_TF_MiniCritBoostActive = false
            end
        end,

        reloadtime = 1.1,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/smg/smg_worldreload.mp3" } },

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
            local reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )
            self:SetLayerPlaybackRate( reloadLayer, 2 )
        end
    }
} )