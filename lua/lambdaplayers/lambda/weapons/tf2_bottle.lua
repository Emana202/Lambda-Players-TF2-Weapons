local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bottle = {
        model = "models/lambdaplayers/weapons/tf2/w_bottle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bottle",
        holdtype = "melee",
        bonemerge = true,

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
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh1.mp3",
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh2.mp3",
                "lambdaplayers/weapons/tf2/melee/bottle_hit_flesh3.mp3"
            } )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                if !wepent.l_TF_Broken then return end
                dmginfo:SetDamageType( dmginfo:GetDamageType() - DMG_CLUB + DMG_SLASH )
            end )

            wepent.l_TF_Broken = false
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 74, nil, 0.5, CHAN_WEAPON )
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
            if wepent.l_TF_Broken or !dmginfo:IsDamageType( DMG_CRITICAL ) then return end
            wepent.l_TF_Broken = true
            wepent:SetBodygroup( 0, 1 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/bottle_break.mp3", 70, random( 90, 110 ) )
        end
    }
} )