local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_ambassador = {
        model = "models/lambdaplayers/weapons/tf2/w_ambassador.mdl",
        origin = "Team Fortress 2",
        prettyname = "Ambassador",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_ambassador",
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 800,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 21 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.6, 1.2 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/revolver/ambassador_shoot.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "SpreadRecovery", 1.0 )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "PreFireBulletCallback", function( lambda, weapon, target, dmginfo, bulletTbl )
                local headBone = target:LookupBone( "ValveBiped.Bip01_Head1" )
                if headBone then return LAMBDA_TF2:GetBoneTransformation( target, headBone ) end
            end )
            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if !LambdaIsValid( tr.Entity ) or tr.HitGroup != HITGROUP_HEAD then return end
                dmginfo:SetDamageCustom( TF_DMG_CUSTOM_HEADSHOT )
            end )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.133,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.33,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/revolver/revolver_worldreload.mp3" } }
   }
} )