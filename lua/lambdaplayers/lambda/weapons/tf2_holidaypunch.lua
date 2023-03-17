table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_holidaypunch = {
        model = "models/lambdaplayers/weapons/tf2/w_holidaypunch.mdl",
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
                "lambdaplayers/weapons/tf2/melee/bat_draw_swoosh1.mp3",
                "lambdaplayers/weapons/tf2/melee/bat_draw_swoosh2.mp3"
            } )
            wepent:SetWeaponAttribute( "HitSound", "lambdaplayers/weapons/tf2/melee/mittens_punch.mp3" )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                local isCrit = dmginfo:IsDamageType( DMG_CRITICAL )
                local toEnt = ( target:GetPos() - lambda:GetPos() ); toEnt:Normalize()
                weapon.l_TF_MakeLaugh = ( isCrit or toEnt:Dot( target:GetForward() ) > 0.7071 )

                if weapon.l_TF_MakeLaugh then
                    dmginfo:SetDamage( 0 )
                    if isCrit then dmginfo:SetDamageType( dmginfo:GetDamageType() - DMG_CRITICAL ) end
                end
			end )

            wepent.l_TF_MakeLaugh = false
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, 100, 0.5 )
            self:SimpleWeaponTimer( 0.1, function() wepent:EmitSound( "lambdaplayers/weapons/tf2/boxing_gloves_hit.mp3" ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !wepent.l_TF_MakeLaugh then return end
            if target.IsLambdaPlayer then
                if target.l_CurrentPlayedGesture != ACT_GMOD_TAUNT_LAUGH then
                    target:CancelMovement()
                    target:SetState( "Laughing" )
                end
            elseif target:IsPlayer() then
                target:ConCommand( "act laugh" )
            end
        end
    }
} )