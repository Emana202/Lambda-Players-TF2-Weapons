local random = math.random
local coroutine_wait = coroutine.wait

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_backscatter = {
        model = "models/lambdaplayers/weapons/tf2/w_scatterdrum.mdl",
        origin = "Team Fortress 2",
        prettyname = "Back Scatter",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_backscatter",

        clip = 4,
        islethal = true,
        attackrange = 1000,
        keepdistance = 300,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/scattergun/tf2_back_scatter.mp3" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 * 1.20 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if LAMBDA_TF2:GetCritType( dmginfo ) != 0 then return end

                local hitEnt = tr.Entity
                if !IsValid( hitEnt ) or !LAMBDA_TF2:IsValidCharacter( hitEnt ) then return end

                local toEnt = ( hitEnt:GetPos() - lambda:GetPos() )
                if toEnt:LengthSqr() >= ( 512 * 512 ) then return end

                toEnt.z = 0; toEnt:Normalize()
                if toEnt:Dot( hitEnt:GetForward() ) <= 0.259 then return end

                dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_MINICRITICAL )
            end )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
            local reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )

            self:SetIsReloading( true )
            self:Thread( function()

                coroutine_wait( 0.7 )

                while ( self.l_Clip < self.l_MaxClip ) do
                    if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( self:GetEnemy(), 512 ) and self:CanSee( self:GetEnemy() ) then break end 

                    if !self:IsValidLayer( reloadLayer ) then
                        reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )
                    end
                    self:SetLayerCycle( reloadLayer, 0.72 )
                    self:SetLayerPlaybackRate( reloadLayer, 0.8 )
                    
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/scattergun/scatter_gun_reload.mp3", 65 )
                    LAMBDA_TF2:CreateShellEject( wepent, "ShotgunShellEject" )

                    self.l_Clip = self.l_Clip + 1
                    coroutine_wait( 0.5 )
                end

                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
                self:SetIsReloading( false )

            end, "TF2_ShotgunReload" )

            return true
        end
    }
} )