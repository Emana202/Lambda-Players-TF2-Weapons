local max = math.max
local min = math.min
local Round = math.Round

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_boxinggloves_running = {
        model = "models/lambdaplayers/tf2/weapons/w_boxing_gloves.mdl",
        origin = "Team Fortress 2",
        prettyname = "Gloves of Running Urgently",
        holdtype = "fist",
        bonemerge = true,
        dropondeath = false,
        tfclass = 5,

        killicon = "lambdaplayers/killicons/icon_tf2_boxinggloves_running",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,
        holstermult = 1.5,
		speedmultiplier = 1.3,

        isgru = true,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            wepent:SetWeaponAttribute( "Sound", {
                "weapons/boxing_gloves_swing1.wav",
                "weapons/boxing_gloves_swing2.wav",
                "weapons/boxing_gloves_swing4.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", "weapons/fist_swing_crit.wav" )
            wepent:SetWeaponAttribute( "HitSound", {
                "weapons/boxing_gloves_hit1.wav",
                "weapons/boxing_gloves_hit2.wav",
                "weapons/boxing_gloves_hit3.wav",
                "weapons/boxing_gloves_hit4.wav"
            } )
            wepent:SetWeaponAttribute( "HitCritSound", {
                "weapons/boxing_gloves_hit_crit1.wav",
                "weapons/boxing_gloves_hit_crit2.wav",
                "weapons/boxing_gloves_hit_crit3.wav"
            } )
            wepent:SetWeaponAttribute( "RateOfFire", 0.8 )

            wepent:SetSkin( self.l_TF_TeamColor + 2 )
            wepent:EmitSound("weapons/draw_melee.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.1, function() wepent:EmitSound( "weapons/boxing_gloves_hit.wav" ) end )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )