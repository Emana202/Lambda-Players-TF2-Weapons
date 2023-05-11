table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sharpdresser = {
        model = "models/lambdaplayers/tf2/weapons/w_hookblade.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sharp Dresser",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_sharp_dresser",
        keepdistance = 10,
        attackrange = 45,
        islethal = true,
        ismelee = true,
        isspyknife = true,
		speedmultiplier = 1.07,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 25 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            wepent:SetWeaponAttribute( "HitDelay", 0 )
            wepent:SetWeaponAttribute( "Sound", ")weapons/knife_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/knife_swing_crit.wav" )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
			wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/spy_assassin_knife_impact_01.wav",
                ")weapons/spy_assassin_knife_impact_02.wav"
            } )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if !LAMBDA_TF2:IsBehindBackstab( lambda, target ) then return end

				lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
				local attackLayer = lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
				lambda:SetLayerCycle( attackLayer, 0.2 )
				lambda:SetLayerPlaybackRate( attackLayer, 1.1 )

				dmginfo:SetDamage( target:Health() * 2 )
				dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BACKSTAB_HIDDEN )
			end )

			wepent:EmitSound( ")weapons/spy_assassin_knife_draw.wav", nil, nil, 0.5 )
       end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )