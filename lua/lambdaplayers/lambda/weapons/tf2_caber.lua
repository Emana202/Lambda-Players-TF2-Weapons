local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_caber = {
        model = "models/lambdaplayers/weapons/tf2/w_caber.mdl",
        origin = "Team Fortress 2",
        prettyname = "Ullapool Caber",
        holdtype = "melee",
        bonemerge = true,

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
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh1.mp3",
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh2.mp3",
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh3.mp3"
            } )
            wepent:SetWeaponAttribute( "RateOfFire", 0.96 )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            if !self.l_TF_Shield_IsEquipped and random( 1, 3 ) == 1 then
                LAMBDA_TF2:GiveRemoveChargeShield( self, true )
            end

            wepent.l_TF_Detonated = false
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, nil, 0.5, CHAN_WEAPON )
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
            wepent:EmitSound( ")lambdaplayers/weapons/tf2/explode" .. random( 1, 3 ) .. ".mp3", 85, 100, 1.0, CHAN_WEAPON )

            local explodeinfo = DamageInfo()
            explodeinfo:SetDamage( 45 )
            explodeinfo:SetAttacker( self )
            explodeinfo:SetInflictor( wepent )
            explodeinfo:SetDamagePosition( wepPos )
            explodeinfo:SetDamageForce( wepPos )
            explodeinfo:SetDamageCustom( TF_DMG_CUSTOM_STICKBOMB_EXPLOSION )

            local dmgTypes = ( DMG_BLAST + DMG_USEDISTANCEMOD )
            if dmginfo:IsDamageType( DMG_CRITICAL ) then 
                dmgTypes = ( dmgTypes + DMG_CRITICAL ) 
            elseif dmginfo:IsDamageType( DMG_MINICRITICAL ) then 
                dmgTypes = ( dmgTypes + DMG_MINICRITICAL ) 
            end
            explodeinfo:SetDamageType( dmgTypes )

            LAMBDA_TF2:RadiusDamageInfo( explodeinfo, wepPos, 100 )

            self.loco:Jump()
            self.loco:SetVelocity( self.loco:GetVelocity() + vector_up * 250 )
        end
    }
} )