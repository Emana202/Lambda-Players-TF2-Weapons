local min = math.min
local Round = math.Round

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_skullcutter = {
        model = "models/lambdaplayers/tf2/weapons/w_battleaxe.mdl",
        origin = "Team Fortress 2",
        prettyname = "Scotsman's Skullcutter",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = 4,

        killicon = "lambdaplayers/killicons/icon_tf2_scotsmans_skullcutter",
        keepdistance = 10,
        attackrange = 80,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.875,
        speedmultiplier = 0.85,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:GetWeaponAttribute( "Damage", 48 )
            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitRange", 72 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/demo_sword_swing1.wav",
                ")weapons/demo_sword_swing2.wav",
                ")weapons/demo_sword_swing3.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/demo_sword_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/blade_slice_2.wav",
                "weapons/blade_slice_3.wav",
                "weapons/blade_slice_4.wav"
            } )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_DECAPITATION )

            wepent:EmitSound( "weapons/draw_sword.wav" )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )