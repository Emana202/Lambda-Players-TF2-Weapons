local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_scotlandshard = {
        model = "models/lambdaplayers/tf2/weapons/w_scotland_shard.mdl",
        origin = "Team Fortress 2",
        prettyname = "Scottish Handshake",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_scottish_handshake",
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
		    wepent:SetBodygroup( 1, 0 )
		end,

        OnDeath = function( self, wepent )
            wepent.l_TF_Broken = false
            self:SimpleWeaponTimer( 0.1, function() wepent:SetBodygroup( 1, 0 ) end, true )
		end,
        
        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetBodygroup( 1, wepent:GetBodygroup( 0 ) )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo )
            if wepent.l_TF_Broken or !dmginfo:IsDamageType( DMG_CRITICAL ) then return end
            wepent.l_TF_Broken = true
            wepent:SetBodygroup( 1, 1 )
            wepent:EmitSound( "weapons/bottle_break.wav", 80, nil, nil, CHAN_WEAPON )
        end
    }
} )