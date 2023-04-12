local min = math.min

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_ubersaw = {
        model = "models/lambdaplayers/tf2/weapons/w_ubersaw.mdl",
        origin = "Team Fortress 2",
        prettyname = "Ubersaw",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_ubersaw",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "RateOfFire", 0.96 )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/ubersaw_hit1.wav",
                "weapons/ubersaw_hit2.wav",
                "weapons/ubersaw_hit3.wav",
                "weapons/ubersaw_hit4.wav"
            } )
            
            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_melee.wav", nil, nil, 0.5 )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnThink = function( self, wepent )
            wepent:SetPoseParameter( "syringe_charge_level", ( self.l_TF_Medigun_ChargeMeter / 100 ) )
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage )
            if !tookDamage then return end
            self.l_TF_Medigun_ChargeMeter = min( 100, self.l_TF_Medigun_ChargeMeter + 25 )
        end
    }
} )