local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_minigun = {
        model = "models/lambdaplayers/tf2/weapons/w_natascha.mdl",
        origin = "Team Fortress 2",
        prettyname = "Natascha",
        holdtype = "crossbow",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_natascha",

        clip = 200,
        islethal = true,
        attackrange = 1500,
        keepdistance = 600,
		speedmultiplier = 0.77,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "Spread", 0.08 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            wepent:SetWeaponAttribute( "DamageCustom", TF_DMG_CUSTOM_USEDISTANCEMOD )

            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "TracerEffect", "bullet_tracer01" )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "WindUpTime", 0.975 )

            wepent:SetWeaponAttribute( "SpinSound", ")weapons/minifun_spin.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/minifun_shoot.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/minifun_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "WindUpSound", ")weapons/minifun_wind_up.wav" )
            wepent:SetWeaponAttribute( "WindDownSound", ")weapons/minifun_wind_down.wav" )

            LAMBDA_TF2:MinigunDeploy( self, wepent )
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:MinigunHolster( self, wepent )
        end,

        OnThink = function( self, wepent, dead )
            LAMBDA_TF2:MinigunThink( self, wepent, dead )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:MinigunFire( self, wepent, target )
            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, dealtDamage )
            if !dealtDamage then return end
            local stunAmount = LAMBDA_TF2:RemapClamped( self:GetRangeSquaredTo( target ), 262144, 2359296, 0.6, 0 )
            LAMBDA_TF2:Stun( target, 0.2, stunAmount )
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if wepent.l_WindUpState != 2 then return end

            local startDamage = dmginfo:GetDamage()
            if ( ( self:Health() - startDamage ) / self:GetMaxHealth() ) > 0.5 then return end

            dmginfo:ScaleDamage( 0.8 )
            if ( CurTime() - self.l_TF_LastDamageResistSoundTime ) > 0.1 then
                self.l_TF_LastDamageResistSoundTime = CurTime()
                local resistSnd = ")player/resistance_light" .. random( 4 ) .. ".wav"
                self:EmitSound( resistSnd, 70, random( 90, 110 ), LAMBDA_TF2:RemapClamped( startDamage, 1, 70, 0.7, 1 ), CHAN_STATIC )
            end
        end
    }
} )