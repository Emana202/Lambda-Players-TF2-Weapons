
table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bottle = {
        model = "models/lambdaplayers/tf2/weapons/w_bottle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bottle",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 4,

        killicon = "lambdaplayers/killicons/icon_tf2_bottle",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/bottle_hit_flesh1.wav",
                "weapons/bottle_hit_flesh2.wav",
                "weapons/bottle_hit_flesh3.wav"
            } )

            wepent.l_TF_Broken = false
            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
		
		OnHolster = function( self, wepent )
            wepent.l_TF_Broken = false
		    wepent:SetBodygroup( 0, 0 )
		end,

        OnDeath = function( self, wepent )
            wepent.l_TF_Broken = false
            self:SimpleWeaponTimer( 0.1, function() wepent:SetBodygroup( 0, 0 ) end, true )
		end,
        
        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetBodygroup( 0, wepent:GetBodygroup( 0 ) )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo )
            if wepent.l_TF_Broken or !LAMBDA_TF2:IsDamageCustom( dmginfo, TF_DMG_CUSTOM_CRITICAL ) then return end
            wepent.l_TF_Broken = true
            wepent:SetBodygroup( 0, 1 )
            wepent:EmitSound( "weapons/bottle_break.wav", 80, nil, nil, CHAN_WEAPON )
        end
    }
} )