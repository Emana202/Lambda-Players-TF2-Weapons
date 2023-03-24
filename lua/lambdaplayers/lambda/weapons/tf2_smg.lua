table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_smg = {
        model = "models/lambdaplayers/weapons/tf2/w_smg.mdl",
        origin = "Team Fortress 2",
        prettyname = "SMG",
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
        killicon = "lambdaplayers/killicons/icon_tf2_smg",

        clip = 25,
        islethal = true,
        attackrange = 1500,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/smg/smg_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
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