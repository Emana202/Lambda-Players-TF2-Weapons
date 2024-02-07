table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_holidaypunch = {
        model = "models/lambdaplayers/tf2/weapons/w_holidaypunch.mdl",
        origin = "Team Fortress 2",
        prettyname = "Holiday Punch",
        holdtype = "fist",
        bonemerge = true,
        dropondeath = false,

        killicon = "lambdaplayers/killicons/icon_tf2_holidaypunch",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            wepent:SetWeaponAttribute( "Sound", {
                "weapons/bat_draw_swoosh1.wav",
                "weapons/bat_draw_swoosh2.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", "weapons/fist_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", ")weapons/mittens_punch.wav" )
            wepent:SetWeaponAttribute( "HitCritSound", ")weapons/mittens_punch_crit.wav" )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                local dmgCustom = dmginfo:GetDamageCustom()
                local isCrit = LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_CRITICAL )

                local toEnt = ( target:GetPos() - lambda:GetPos() ); toEnt:Normalize()
                weapon.l_TF_MakeLaugh = ( isCrit or toEnt:Dot( target:GetForward() ) > 0.7071 )

                if weapon.l_TF_MakeLaugh then
                    dmginfo:SetDamage( 0 )
                    if isCrit then dmgCustom = ( dmgCustom - TF_DMG_CUSTOM_CRITICAL ) end
                end
                if target:IsPlayer() and target:IsPlayingTaunt() or target.IsLambdaPlayer and ( target:GetState() == "Schadenfreude" or target:GetState() == "Laughing" ) then
                    dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_GLOVES_LAUGHING )
                end

                dmginfo:SetDamageCustom( dmgCustom )
			end )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent.l_TF_MakeLaugh = false
            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.1, function() wepent:EmitSound( ")weapons/mittens_punch.wav", nil, nil, 0.4 ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !wepent.l_TF_MakeLaugh then return end
            if target.IsLambdaPlayer then
                if target:GetState() != "Laughing" then
                    target:CancelMovement()
                    target:SetState( "Laughing" )
                end
            elseif target:IsPlayer() then
                target:ConCommand( "act laugh" )
            end
        end
    }
} )