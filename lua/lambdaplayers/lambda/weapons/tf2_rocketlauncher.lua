local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local coroutine_wait = coroutine.wait

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_rocketlauncher = {
        model = "models/lambdaplayers/weapons/tf2/w_rocket_launcher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Rocket Launcher",
        holdtype = "rpg",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_rocketlauncher",

        clip = 4,
        islethal = true,
        attackrange = 2000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
           
            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 55 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.8, 1.2 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/rocketlauncher/rocket_shoot.mp3" )
            wepent:SetWeaponAttribute( "MuzzleFlash", 7 )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 74, nil, 0.5, CHAN_WEAPON )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( ( !target:IsOnGround() or random( 1, 2 ) == 1 and self:IsInRange( target, 500 ) ) and target:WorldSpaceCenter() or target:GetPos() )
            targetPos = ( targetPos + ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( target ) * Rand( 0.5, 1.1 ) ) / 1100 ) )

            local spawnAng = ( ( targetPos + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( targetPos ) * Rand( 0.66, 1.1 ) ) / 1100 ) ) ) - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

            spawnPos = ( spawnPos + spawnAng:Forward() * ( self.loco:GetVelocity():Length() * FrameTime() * 4 ) )
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()

            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end
            
            LAMBDA_TF2:CreateRocketProjectile( spawnPos, spawnAng, self, wepent )
            return true
        end,

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
            local reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
            self:SetLayerPlaybackRate( reloadLayer, 1.2 )

            self:SetIsReloading( true )
            self:Thread( function()
                
                wepent:EmitSound( "lambdaplayers/weapons/tf2/rocketlauncher/rocket_reload.mp3", 74, 100, 1.0, CHAN_STATIC )
                coroutine_wait( 0.92 )
                self.l_Clip = self.l_Clip + 1

                while ( self.l_Clip < self.l_MaxClip ) do
                    if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( self:GetEnemy(), 700 ) and self:CanSee( self:GetEnemy() ) then break end 

                    if !self:IsValidLayer( reloadLayer ) then
                        reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                    end                    
                    self:SetLayerCycle( reloadLayer, 0.1 )
                    self:SetLayerPlaybackRate( reloadLayer, 1.2 )
                    
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/rocketlauncher/rocket_reload.mp3", 74, 100, 1.0, CHAN_STATIC )
                    coroutine_wait( 0.8 )
                end

                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                self:SetIsReloading( false )
            
            end, "TF2_RPGReload" )

            return true
        end
    }
} )