
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_knife = {
        model = "models/lambdaplayers/tf2/weapons/w_knife.mdl",
        origin = "Team Fortress 2",
        prettyname = "Knife",
        holdtype = "knife",
        bonemerge = true,
        tfclass = 9,

        killicon = "lambdaplayers/killicons/icon_tf2_knife",
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
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
            wepent:SetWeaponAttribute( "HitDelay", 0 )
            wepent:SetWeaponAttribute( "Sound", ")weapons/knife_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/knife_swing_crit.wav" )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
			wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/blade_hit1.wav",
                ")weapons/blade_hit2.wav",
                ")weapons/blade_hit3.wav"
            } )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if !LAMBDA_TF2:IsBehindBackstab( lambda, target ) then return end

				lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
				local attackLayer = lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
				lambda:SetLayerCycle( attackLayer, 0.2 )
				lambda:SetLayerPlaybackRate( attackLayer, 1.1 )

				dmginfo:SetDamage( target:Health() * 2 )
				dmginfo:SetDamageCustom( dmginfo:GetDamageCustom() + TF_DMG_CUSTOM_BACKSTAB )
			end )

			wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
			self:SimpleWeaponTimer( 0.333333, function() wepent:EmitSound( "weapons/knife_open1.wav", nil, nil, 0.5, CHAN_STATIC ) end )
			self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/knife_open5.wav", nil, nil, 0.5, CHAN_STATIC ) end )
			self:SimpleWeaponTimer( 0.733333, function() wepent:EmitSound( "weapons/knife_open8.wav", nil, nil, 0.5, CHAN_STATIC ) end )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )