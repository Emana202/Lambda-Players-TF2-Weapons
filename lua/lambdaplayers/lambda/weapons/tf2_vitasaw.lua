local Round = math.Round
local AngleRand = AngleRand

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_vitasaw = {
        model = "models/lambdaplayers/tf2/weapons/w_uberneedle.mdl",
        origin = "Team Fortress 2",
        prettyname = "Vita-Saw",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_vita_saw",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,
        healthmultiplier = 0.9,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
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
            self.l_TF_CollectedOrgans = ( self.l_TF_CollectedOrgans + 1 )
            
            local organ = LAMBDA_TF2:CreateGib( target:WorldSpaceCenter(), AngleRand( -180, 180 ), nil, "models/player/gibs/random_organ.mdl" )
            organ:GetPhysicsObject():ApplyForceCenter( dmginfo:GetDamageForce() / 200 )
        end
    }
} )