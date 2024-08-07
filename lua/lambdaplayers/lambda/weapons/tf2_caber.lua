
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_caber = {
        model = "models/lambdaplayers/tf2/weapons/w_caber.mdl",
        origin = "Team Fortress 2",
        prettyname = "Ullapool Caber",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 4,

        killicon = "lambdaplayers/killicons/icon_tf2_caber_exploded",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 1.0,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 34 )
            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/bottle_hit_flesh1.wav",
                "weapons/bottle_hit_flesh2.wav",
                "weapons/bottle_hit_flesh3.wav"
            } )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            wepent.l_TF_Detonated = false
            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
		
		OnHolster = function( self, wepent )
            wepent.l_TF_Detonated = false
		    wepent:SetBodygroup( 1, 0 )
		end,
        
        OnDeath = function( self, wepent )
            wepent.l_TF_Detonated = false
            self:SimpleWeaponTimer( 0.1, function() wepent:SetBodygroup( 1, 0 ) end, true )
		end,

        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetBodygroup( 1, wepent:GetBodygroup( 1 ) )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo )
            if wepent.l_TF_Detonated then return end

            wepent.l_TF_Detonated = true
            wepent:SetBodygroup( 1, 1 )

            local wepPos = wepent:GetPos()
            ParticleEffect( "ExplosionCore_MidAir", wepPos, ( ( wepPos + vector_up * 1 ) - wepPos ):Angle() )
            wepent:EmitSound( ")lambdaplayers/tf2/explode" .. LambdaRNG( 1, 3 ) .. ".mp3", 85, nil, nil, CHAN_WEAPON )

            local explodeinfo = DamageInfo()
            explodeinfo:SetDamage( 45 )
            explodeinfo:SetAttacker( self )
            explodeinfo:SetInflictor( wepent )
            explodeinfo:SetDamagePosition( wepPos )
            explodeinfo:SetDamageForce( wepPos )
            explodeinfo:SetDamageType( DMG_BLAST )

            explodeinfo:SetDamageCustom( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_STICKBOMB_EXPLOSION )
            LAMBDA_TF2:SetCritType( explodeinfo, LAMBDA_TF2:GetCritType( dmginfo ) )

            LAMBDA_TF2:RadiusDamageInfo( explodeinfo, wepPos, 100 )

            self.loco:Jump()
            self.loco:SetVelocity( self.loco:GetVelocity() + vector_up * 250 )
        end
    }
} )