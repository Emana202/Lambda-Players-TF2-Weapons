table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_axtinguisher = {
        model = "models/lambdaplayers/tf2/weapons/w_axtinguisher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Axtinguisher",
        holdtype = "melee2",
        bonemerge = true,
        tfclass = 3,

        killicon = "lambdaplayers/killicons/icon_tf2_axtinguisher",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        
        deploydelay = 0.5,
        holstermult = 1.35,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 26.8 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/axe_hit_flesh1.wav",
                ")weapons/axe_hit_flesh2.wav",
                ")weapons/axe_hit_flesh3.wav"
            } )
            wepent:SetWeaponAttribute( "RandomCrits", false )
			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if !LAMBDA_TF2:IsBurning( target ) then return end
                
                if LAMBDA_TF2:GetCritType( dmginfo ) != TF_CRIT_FULL then
                    LAMBDA_TF2:SetCritType( dmginfo, TF_CRIT_MINI )
                end

                local burnTime = ( LAMBDA_TF2:GetBurnEndTime( target ) - CurTime() )
                dmginfo:AddDamage( ( burnTime / 0.5 ) * 3 )
            end )

            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, dealtDamage, isLethal )
            if !dealtDamage or !LAMBDA_TF2:IsBurning( target ) then return end
            LAMBDA_TF2:RemoveBurn( target )

            if !isLethal then return end
            self.l_TF_InSpeedBoost = ( CurTime() + 4 )
            self:EmitSound( ")weapons/discipline_device_power_up.wav", 65, nil, nil, CHAN_STATIC )
        end
    }
} )