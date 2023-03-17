local random = math.random
local coroutine_wait = coroutine.wait

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_panicattack = {
        model = "models/lambdaplayers/weapons/tf2/w_trenchgun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Panic Attack",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_panicattack",

        clip = 6,
        islethal = true,
        attackrange = 1000,
        keepdistance = 400,
        deploydelay = 0.25,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 3 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/shotgun/tf2_backshot_shotty.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 15 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FixedSpread", true )

            local rndDraw = random( 1, 3 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/" .. ( rndDraw == 1 and "draw_secondary" or ( rndDraw == 2 and "draw_primary" or "shotgun/shotgun_draw_pyro" ) ) .. ".mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            if LAMBDA_TF2:WeaponAttack( self, wepent, target ) and self.l_Clip > 0 then
                self:SimpleWeaponTimer( 0.4, function()
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_back.mp3", 70 )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end )
                self:SimpleWeaponTimer( 0.55, function()
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_forward.mp3", 70 )
                end )
            end

            return true
        end,

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
            local reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )

            local wasEmpty = ( self.l_Clip == 0 )

            self:SetIsReloading( true )
            self:Thread( function()
                if wasEmpty then 
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_back.mp3", 70 )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )
                end
                coroutine_wait( 0.44 )

                while ( self.l_Clip < self.l_MaxClip ) do
                    if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( self:GetEnemy(), 512 ) and self:CanSee( self:GetEnemy() ) then break end 

                    if !self:IsValidLayer( reloadLayer ) then
                        reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                    end                    
                    self:SetLayerCycle( reloadLayer, 0.2 )
                    self:SetLayerPlaybackRate( reloadLayer, 1.6 )
                    
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_reload.mp3", 70 )
                    coroutine_wait( 0.51 )
                end

                if wasEmpty then 
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/shotgun/shotgun_cock_forward.mp3", 70 )
                end

                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                self:SetIsReloading( false )
            
            end, "TF2_ShotgunReload" )

            return true
        end
    }
} )