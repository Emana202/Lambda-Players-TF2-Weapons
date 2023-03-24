local IsValid = IsValid
local net = net
local FrameTime = FrameTime
local CurTime = CurTime
local random = math.random
local Rand = math.Rand
local min = math.min
local max = math.max
local SpriteTrail = util.SpriteTrail
local ParticleEffect = ParticleEffect
local FindInSphere = ents.FindInSphere
local ipairs = ipairs
local util_Decal = util.Decal
local BlastDamage = util.BlastDamage
local ents_Create = ents.Create
local SimpleTimer = timer.Simple
local TraceLine = util.TraceLine
local groundTrTbl = { mask = MASK_SOLID_BRUSHONLY }
local pipeBounds = Vector( 2, 2, 2 )
local DamageInfo = DamageInfo

local function OnPhysicsCollide( self, colData, collider )
    if colData.TheirSurfaceProps == SURF_SKY then self:Remove() return end

    local owner = self:GetOwner()
    local hitEnt = colData.HitEntity
    if IsValid( hitEnt ) and hitEnt != owner and !hitEnt.l_IsTF2PipeBomb then
        local hitPos, hitNormal = colData.HitPos, colData.HitNormal
        ParticleEffect( "ExplosionCore_MidAir", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )

        if IsValid( owner ) then 
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( self.l_ExplodeDamage )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( owner:GetWeaponENT() )
            
            local dmgTypes = ( DMG_BLAST + DMG_HALF_FALLOFF )
            if self.l_TF_ExplodeCrit == 2 then
                dmgTypes = ( dmgTypes + DMG_CRITICAL )
            elseif self.l_TF_ExplodeCrit == 1 then
                dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
            end
            dmginfo:SetDamageType(dmgTypes )

            LAMBDA_TF2:RadiusDamageInfo( dmginfo, hitPos, 150, hitEnt )
        end

        self:EmitSound( ")lambdaplayers/weapons/tf2/explode" .. random( 1, 3 ) .. ".mp3", 85, 100, 1.0, CHAN_WEAPON )
        self:Remove()
        return
    end

    if !self.l_HasTouched then
        self.l_HasTouched = true
        self.l_ExplodeDamage = ( self.l_ExplodeDamage * 0.6 )
    end

    if colData.Speed >= 100 then
        self:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_impact" .. random( 1, 3 ) .. ".mp3", 74, 100, 1, CHAN_STATIC )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_grenadelauncher = {
        model = "models/lambdaplayers/weapons/tf2/w_grenade_launcher.mdl",
        origin = "Team Fortress 2",
        prettyname = "Grenade Launcher",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_grenadelauncher",

        clip = 4,
        islethal = true,
        attackrange = 1500,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 60 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.6, 1.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_shoot.mp3" )
            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            
            local targetPos = ( self:IsInRange( target, 100 ) and target:WorldSpaceCenter() or target:GetPos() + vector_up * ( self:GetRangeTo( target ) / random( 12, 15 ) ) )
            targetPos = ( targetPos + ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( target ) * Rand( 0.5, 0.9 ) ) / 700 ) )
            
            local spawnAng = ( targetPos - spawnPos ):Angle()

            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end

            local pipe = ents_Create( "base_anim" )
            if !IsValid( pipe ) then return true end
            
            self:SimpleWeaponTimer( 11 / 30, function() wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_start.mp3", 75, 100, 0.4, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 16 / 30, function() wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_start.mp3", 75, 100, 0.4, CHAN_STATIC ) end )

            pipe:SetPos( spawnPos )
            pipe:SetAngles( spawnAng )
            pipe:SetModel( "models/lambdaplayers/weapons/tf2/w_grenade_launcher_proj.mdl" )
            pipe:SetOwner( self )
            pipe:Spawn()

            pipe:DrawShadow( false )
            pipe:PhysicsInit( SOLID_BBOX )
            pipe:SetCollisionBounds( -pipeBounds, pipeBounds )
            pipe:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
            LAMBDA_TF2:TakeNoDamage( pipe )

            local phys = pipe:GetPhysicsObject()
            if IsValid( phys ) then
                phys:Wake()
                phys:AddVelocity( spawnAng:Forward() * 750 + spawnAng:Up() * ( 200 + Rand( -10, 10 ) ) + spawnAng:Right() * Rand( -10, 10 ) )
                phys:AddAngleVelocity( Vector( 600, random( -1200, 1200 ), 0 ) )
            end

            local plyColor = self:GetPlyColor()
            net.Start( "lambdaplayers_serversideragdollplycolor" )
                net.WriteEntity( pipe )
                net.WriteVector( plyColor )
            net.Broadcast()

            pipe.l_HasTouched = false
            pipe.l_IsTF2PipeBomb = true
            pipe.PhysicsCollide = OnPhysicsCollide
            pipe.l_ExplodeDamage = wepent:GetWeaponAttribute( "Damage" )

            pipe.l_TF_ExplodeCrit = ( wepent:CalcIsAttackCriticalHelper() and 2 or ( self.l_TF_MiniCritBoosted and 1 or 0 ) )
            if pipe.l_TF_ExplodeCrit == 2 then
                pipe:SetMaterial( "models/shiny" )
                pipe:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_shoot.mp3", 75, random( 90, 110 ), 1.0, CHAN_STATIC )
                
                pipe:SetColor( plyColor:ToColor() )
                SpriteTrail( pipe, 0, plyColor:ToColor(), true, 15, 7.5, 1, ( 1 / ( 15 + 7.5 ) * 0.5 ), "trails/laser" )
            else
                if pipe.l_TF_ExplodeCrit == 1 then
                    pipe:SetMaterial( "lambdaplayers/models/weapons/tf2/criteffects/minicrit" )
                end

                SpriteTrail( pipe, 0, plyColor:ToColor(), true, 8.5, 4.25, 0.33, ( 1 / ( 8.5 + 4.25 ) * 0.5 ), "trails/laser" )
            end

            SimpleTimer( 2.0, function()
                if !IsValid( pipe ) then return end
                local pipePos = pipe:WorldSpaceCenter()

                groundTrTbl.start = pipePos
                groundTrTbl.endpos = ( pipePos - vector_up * 32 )
                groundTrTbl.filter = pipe

                local groundTr = TraceLine( groundTrTbl )
                if groundTr.HitWorld then
                    local hitPos, hitNormal = groundTr.HitPos, groundTr.HitNormal
                    ParticleEffect( "ExplosionCore_Wall", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )
                    util_Decal( "Scorch", hitPos + hitNormal, hitPos - hitNormal )
                else
                    ParticleEffect( "ExplosionCore_MidAir", pipePos, Angle( 0, random( -360, 360 ), 0 ) )
                end
    
                if IsValid( self ) then 
                    local dmginfo = DamageInfo()
                    dmginfo:SetDamage( pipe.l_ExplodeDamage )
                    dmginfo:SetDamagePosition( pipePos )
                    dmginfo:SetAttacker( self )
                    dmginfo:SetInflictor( wepent )
                    dmginfo:SetDamageType( DMG_BLAST + ( pipe.l_IsCritical and DMG_CRITICAL or 0 ) )

                    LAMBDA_TF2:RadiusDamageInfo( dmginfo, pipePos, 150 )
                end

                pipe:EmitSound( ")lambdaplayers/weapons/tf2/explode" .. random( 1, 3 ) .. ".mp3", 85, 100, 1.0, CHAN_WEAPON )
                pipe:Remove()
            end )

            return true
        end,

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
            local reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )

            self:SetIsReloading( true )
            self:Thread( function()
                
                wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_open.mp3", 75, 100, 1.0, CHAN_STATIC )
                self:SimpleWeaponTimer( 0.64, function() wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_load.mp3", 75, 100, 1.0, CHAN_STATIC ) end )

                coroutine.wait( 1.24 )
                self.l_Clip = self.l_Clip + 1

                local interrupted = false
                while ( self.l_Clip < self.l_MaxClip ) do
                    interrupted = ( self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( self:GetEnemy(), 700 ) and self:CanSee( self:GetEnemy() ) ) 
                    if interrupted then break end

                    if !self:IsValidLayer( reloadLayer ) then
                        reloadLayer = self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                    end                    
                    self:SetLayerCycle( reloadLayer, 0.2 )
                    self:SetLayerPlaybackRate( reloadLayer, 1.5 )
                    
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_load.mp3", 75, 100, 1.0, CHAN_STATIC )
                    coroutine.wait( 0.6 )
                end

                if !interrupted then
                    wepent:EmitSound( "lambdaplayers/weapons/tf2/grenadelauncher/grenade_launcher_drum_close.mp3", 75, 100, 1.0, CHAN_STATIC )
                end
                
                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_AR2 )
                self:SetIsReloading( false )
            
            end, "TF2_RPGReload" )

            return true
        end
    }
} )