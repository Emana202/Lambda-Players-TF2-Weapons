local Clamp = math.Clamp

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_prettyboypistol = {
        model = "models/lambdaplayers/weapons/tf2/w_pep_pistol.mdl",
        origin = "Team Fortress 2",
        prettyname = "Pretty Boy's Pocket Pistol",
        holdtype = "revolver",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_prettyboypocketpistol",
        
        clip = 9,
        islethal = true,
        attackrange = 1000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 9 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.1275 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/pistol/doom_scout_pistol.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60  )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, dealtDamage )
            if !dealtDamage then return end
            LAMBDA_TF2:GiveHealth( self, ( 3 * Clamp( dmginfo:GetDamage() / dmginfo:GetBaseDamage(), 0, 1 ) ), false )
        end,

        reloadtime = 1.02,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1.5,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/pistol/pistol_worldreload.mp3" } }
    }
} )