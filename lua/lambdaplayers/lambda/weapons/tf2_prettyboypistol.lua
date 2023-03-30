local Clamp = math.Clamp

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_prettyboypistol = {
        model = "models/lambdaplayers/tf2/weapons/w_pep_pistol.mdl",
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
            wepent:SetWeaponAttribute( "Sound", ")weapons/doom_scout_pistol.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/doom_scout_pistol_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.04 )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
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
        reloadsounds = { { 0, "weapons/pistol_worldreload.wav" } }
    }
} )