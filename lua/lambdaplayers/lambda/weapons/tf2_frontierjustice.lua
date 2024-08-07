local reloadData = { InterruptCondition = false }

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_frontierjustice = {
        model = "models/lambdaplayers/tf2/weapons/w_frontierjustice.mdl",
        origin = "Team Fortress 2",
        prettyname = "Frontier Justice",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_frontier_justice",
        tfclass = 6,

        clip = 3,
        islethal = true,
        attackrange = 500,
        keepdistance = 400,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.703125, 0.7875 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/frontier_justice_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/frontier_justice_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", DMG_BUCKSHOT )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_shotgun" )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_shotgun_tracer01" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) then
                if self.l_TF_RevengeCrits > 0 then
                    self.l_TF_RevengeCrits = ( self.l_TF_RevengeCrits - 1 )
                end

                self:SimpleWeaponTimer( 0.266, function()
                    wepent:EmitSound( "weapons/shotgun_cock_back.wav", 70, nil, nil, CHAN_STATIC )
                end )
                self:SimpleWeaponTimer( 0.416, function()
                    wepent:EmitSound( "weapons/shotgun_cock_forward.wav", 70, nil, nil, CHAN_STATIC )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end )
            end

            return true
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and self.l_TF_RevengeCrits > 0 then LAMBDA_TF2:AddCritBoost( self, "RevengeCrits", TF_CRIT_FULL, 0.1 ) end
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, isLethal )
            if !isLethal then return end
            self.l_TF_FrontierJusticeKills = ( self.l_TF_FrontierJusticeKills + 1 )
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )