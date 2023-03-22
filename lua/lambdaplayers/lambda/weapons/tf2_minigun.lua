local CurTime = CurTime
local CreateSound = CreateSound
local SoundDuration = SoundDuration
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_minigun = {
        model = "models/lambdaplayers/weapons/tf2/w_minigun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Minigun",
        holdtype = "physgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_minigun",

        clip = 200,
        islethal = true,
        attackrange = 1500,
        keepdistance = 400,
		speedmultiplier = 0.77,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 5 )
            wepent:SetWeaponAttribute( "ProjectileCount", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "Sound", false )
            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "Spread", 0.08 )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "ClipDrain", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_USEDISTANCEMOD )

            wepent.l_IsCritical = false
            wepent.l_WindUpState = 1
            wepent.l_SpinTime = CurTime()
            wepent.l_FireTime = CurTime()
            wepent.l_NextWindUpStateChangeT = CurTime()

            wepent.l_SpinSound = LAMBDA_TF2:CreateSound( wepent, "lambdaplayers/weapons/tf2/minigun/minigun_spin.wav" )            
            wepent.l_FireSound = LAMBDA_TF2:CreateSound( wepent, "lambdaplayers/weapons/tf2/minigun/minigun_shoot.wav" )
            wepent.l_CritSound = LAMBDA_TF2:CreateSound( wepent, "lambdaplayers/weapons/tf2/crits/crit_shoot_loop.wav" )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/minigun/minigun_draw.mp3", 60 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 74, 100, 0.5 )
        end,

        OnHolster = function( self, wepent )
            wepent:StopSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_up.wav" )
            wepent:StopSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_down.mp3" )

            if wepent.l_FireSound then wepent.l_FireSound:Stop(); wepent.l_FireSound = nil end 
            if wepent.l_SpinSound then wepent.l_SpinSound:Stop(); wepent.l_SpinSound = nil end 
            if wepent.l_CritSound then wepent.l_CritSound:Stop(); wepent.l_CritSound = nil end 
        end,

        OnThink = function( self, wepent, dead )
            if dead then
                wepent:StopSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_up.wav" )
                
                if wepent.l_WindUpState == 2 and self:GetIsDead() then 
                    wepent.l_WindUpState = 1 
                    wepent:StopSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_down.mp3" )
                end
                
                if wepent.l_FireSound then wepent.l_FireSound:Stop() end
                if wepent.l_SpinSound then wepent.l_SpinSound:Stop() end 
                if wepent.l_CritSound then wepent.l_CritSound:Stop() end
            else 
                if CurTime() < wepent.l_SpinTime then
                    if CurTime() > wepent.l_NextWindUpStateChangeT then
                        if wepent.l_WindUpState == 1 then
                            wepent.l_WindUpState = 2
                            wepent.l_NextWindUpStateChangeT = ( CurTime() + SoundDuration( "lambdaplayers/weapons/tf2/minigun/minigun_wind_up.wav" ) )

                            wepent:EmitSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_up.wav", 75, 100, 0.9 )
                        else
                            if self:IsPanicking() or !self:InCombat() and self.l_issmoving and !self:IsInRange( self:GetDestination(), 1000 ) then
                                wepent.l_SpinTime = 0
                            else
                                if wepent.l_SpinSound and !wepent.l_SpinSound:IsPlaying() then 
                                    wepent.l_SpinSound:Play()
                                    wepent.l_SpinSound:ChangeVolume( 0.75 )
                                end

                                if wepent.l_FireSound then
                                    if CurTime() < wepent.l_FireTime then 
                                        if !wepent.l_FireSound:IsPlaying() then 
                                            wepent.l_FireSound:Play()
                                        end
                                    else
                                        wepent.l_FireSound:Stop()
                                    end
                                end
                                
                                if wepent.l_CritSound then
                                    if wepent.l_IsCritical and CurTime() < wepent.l_FireTime then
                                        if !wepent.l_CritSound:IsPlaying() then
                                            wepent.l_CritSound:Play()
                                        end
                                    else
                                        wepent.l_CritSound:Stop()
                                    end
                                end
                            end
                        end
                    end
                elseif wepent.l_WindUpState == 2 then
                    wepent.l_WindUpState = 1
                    wepent.l_NextWindUpStateChangeT = ( CurTime() + 0.5 )

                    if wepent.l_SpinSound then wepent.l_SpinSound:Stop() end
                    if wepent.l_FireSound then wepent.l_FireSound:Stop() end
                    if wepent.l_CritSound then wepent.l_CritSound:Stop() end 

                    wepent:EmitSound( "lambdaplayers/weapons/tf2/minigun/minigun_wind_down.mp3", 75, 100, 0.9 )
                end

                if wepent.l_WindUpState == 2 then
                    self.l_WeaponSpeedMultiplier = 0.37
                else
                    self.l_WeaponSpeedMultiplier = 0.77
                end
            end
        end,

        OnAttack = function( self, wepent, target )
            wepent.l_FireTime = CurTime() + 0.25
            wepent.l_SpinTime = CurTime() + Rand( 2, 6 )
            wepent.l_IsCritical = wepent:CalcIsAttackCriticalHelper()

            if wepent.l_WindUpState != 2 or CurTime() <= wepent.l_NextWindUpStateChangeT then return true end
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end

            local curROF = 0
            local rateOfFire = ( wepent:GetWeaponAttribute( "RateOfFire" ) / 4 )
            for i = 1, 4 do
                self:SimpleWeaponTimer( curROF, function() 
                    self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2 )
                    local fireLayer = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2, true )
                    self:SetLayerPlaybackRate( fireLayer, 1.5 )

                    LAMBDA_TF2:CreateMuzzleFlash( wepent, 7 )
                    LAMBDA_TF2:CreateShellEject( wepent, "RifleShellEject" ) 
                end )
                
                curROF = ( curROF + rateOfFire )
            end

            return true
        end
    }
} )