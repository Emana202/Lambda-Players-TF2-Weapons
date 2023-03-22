local random = math.random
local coroutine_wait = coroutine.wait

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_familybusiness = {
        model = "models/lambdaplayers/weapons/tf2/w_russian_riot.mdl",
        origin = "Team Fortress 2",
        prettyname = "The Family Business",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_familybusiness",
        
        clip = 8,
        islethal = true,
        attackrange = 1000,
        keepdistance = 400,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 3.4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.531, 0.65 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/shotgun/family_business_shoot.mp3" )
            wepent:SetWeaponAttribute( "CritSound", "lambdaplayers/weapons/tf2/shotgun/family_business_shoot_crit.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) then
                self:SimpleWeaponTimer( 0.266, function()
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_back.mp3", 70 )
                end )
                self:SimpleWeaponTimer( 0.416, function()
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_forward.mp3", 70 )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end )
            end

            return true
        end,

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
            local reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )

            self:SetIsReloading( true )
            self:Thread( function()
                coroutine_wait( 0.4 )

                local interupted = false
                while ( self.l_Clip < self.l_MaxClip ) do
                    interupted = ( self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( self:GetEnemy(), 512 ) and self:CanSee( self:GetEnemy() ) )
                    if interupted then break end

                    if !self:IsValidLayer( reloadLayer ) then
                        reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                    end                    
                    self:SetLayerCycle( reloadLayer, 0.2 )
                    self:SetLayerPlaybackRate( reloadLayer, 1.6 )
                    
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_reload.mp3", 70 )
                    coroutine_wait( 0.5 )
                end

                if !interupted then
                    local cockBack, cockForward
                    local randEnd = random( 1, 4 )
                    if randEnd == 1 then
                        cockBack = ( 12 / 35 )
                        cockForward = ( 17 / 35 )
                    elseif randEnd == 2 then
                        cockBack = ( 10 / 35 )
                        cockForward = ( 15 / 35 )
                    elseif randEnd == 3 then
                        cockBack = ( 12 / 30 )
                        cockForward = ( 16 / 30 )
                    else
                        cockBack = ( 7 / 30 )
                        cockForward = ( 11 / 30 )
                    end

                    self:SimpleWeaponTimer( cockBack, function()
                        wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_back.mp3", 70 )
                    end )
                    self:SimpleWeaponTimer( cockForward, function()
                        wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_forward.mp3", 70 )
                    end )
                else
                    self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                end

                self:SetIsReloading( false )
            end, "TF2_ShotgunReload" )

            return true
        end
    }
} )