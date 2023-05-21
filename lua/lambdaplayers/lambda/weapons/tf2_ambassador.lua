local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_ambassador = {
        model = "models/lambdaplayers/tf2/weapons/w_ambassador.mdl",
        origin = "Team Fortress 2",
        prettyname = "Ambassador",
        holdtype = "pistol",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_ambassador",
        
        clip = 6,
        islethal = true,
        attackrange = 1500,
        keepdistance = 700,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 21 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.7, 1.25 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", ")weapons/ambassador_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/ambassador_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.025 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "SpreadRecovery", 1.0 )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_revolver" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_pistol_tracer01" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:SetWeaponAttribute( "PreFireBulletCallback", function( lambda, weapon, target, dmginfo, bulletTbl )
                local spread = LAMBDA_TF2:RemapClamped( ( CurTime() - wepent.l_NextAccuracyCheckT ), 1.0, 0.5, 0.0, ( 0.0 + weapon:GetWeaponAttribute( "Spread" ) ) )
                bulletTbl.Spread.x = spread
                bulletTbl.Spread.y = spread

                local headHitBox = LAMBDA_TF2:GetEntityHeadBone( target )
                if headHitBox then return LAMBDA_TF2:GetBoneTransformation( target, headHitBox ) end
            end )
            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if ( CurTime() - wepent.l_NextAccuracyCheckT ) >= 1 and LambdaIsValid( tr.Entity ) and tr.HitGroup == HITGROUP_HEAD and tr.StartPos:DistToSqr( tr.HitPos ) <= 1440000 then 
                    dmginfo:SetDamageCustom( dmginfo:GetDamageCustom() + TF_DMG_CUSTOM_HEADSHOT_REVOLVER )
                end

                wepent.l_NextAccuracyCheckT = CurTime()
            end )

            wepent.l_NextAccuracyCheckT = 0
            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        reloadtime = 1.133,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.33,
        reloadsounds = { { 0, "weapons/revolver_worldreload.wav" } }
   }
} )