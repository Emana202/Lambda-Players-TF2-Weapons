local max = math.max
local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_widowmaker = {
        model = "models/lambdaplayers/weapons/tf2/w_widowmaker.mdl",
        origin = "Team Fortress 2",
        prettyname = "The Widowmaker",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_widowmaker",

        clip = 6,
        islethal = true,
        attackrange = 1000,
        keepdistance = 400,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", { 
                "lambdaplayers/weapons/tf2/shotgun/widow_maker_shot_01.mp3",
                "lambdaplayers/weapons/tf2/shotgun/widow_maker_shot_02.mp3",
                "lambdaplayers/weapons/tf2/shotgun/widow_maker_shot_03.mp3"
            } )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )

            wepent.l_TF_MetalAmount = 200
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            if wepent.l_TF_MetalAmount >= 30 and LAMBDA_TF2:WeaponAttack( self, wepent, target ) then
                wepent.l_TF_MetalAmount = max( wepent.l_TF_MetalAmount - 30, 0 )
            end
            return true
        end,

        OnThink = function( self, wepent, dead )
            if !dead then wepent.l_TF_MetalAmount = min( wepent.l_TF_MetalAmount + 1, 200 ) end
            return 0.1
        end,

        OnDeath = function( self, wepent )
            wepent.l_TF_MetalAmount = 200
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage then return end
            wepent.l_TF_MetalAmount = min( wepent.l_TF_MetalAmount + dmginfo:GetDamage(), 200 )
        end,

        OnReload = function( self, wepent )
            return true
        end
    }
} )