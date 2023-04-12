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
local ParticleEffectAttach = ParticleEffectAttach
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
    if IsValid( hitEnt ) and hitEnt != owner and !hitEnt.l_IsTFWeapon then
        local hitPos, hitNormal = colData.HitPos, colData.HitNormal
        ParticleEffect( "ExplosionCore_MidAir", hitPos, ( ( hitPos + hitNormal ) - hitPos ):Angle() )

        if IsValid( owner ) then 
            local wepent = owner:GetWeaponENT()

            local dmginfo = DamageInfo()
            dmginfo:SetDamage( self.l_ExplodeDamage )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( wepent )

            local dmgTypes = self.l_DamageType
            if self.l_CritType == TF_CRIT_FULL then
                dmgTypes = ( dmgTypes + DMG_CRITICAL )
            elseif self.l_CritType == TF_CRIT_MINI then
                dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
            end
            dmginfo:SetDamageType(dmgTypes )

            LAMBDA_TF2:RadiusDamageInfo( dmginfo, hitPos, 150, hitEnt )
        end

        self:EmitSound( ")lambdaplayers/tf2/explode" .. random( 3 ) .. ".mp3", 95, nil, nil, CHAN_WEAPON )
        self:Remove()
        return
    end

    if !self.l_HasTouched then
        self.l_HasTouched = true
        self.l_ExplodeDamage = ( self.l_ExplodeDamage * 0.6 )
    end

    if colData.Speed >= 100 then
        self:EmitSound( "BaseGrenade.BounceSound" )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_grenadelauncher = {
        model = "models/lambdaplayers/tf2/weapons/w_grenade_launcher.mdl",
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
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BLAST + DMG_HALF_FALLOFF ) )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.6, 1.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
            wepent:SetWeaponAttribute( "Sound", ")weapons/grenade_launcher_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/grenade_launcher_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            
            local targetPos = ( self:IsInRange( target, 100 ) and target:WorldSpaceCenter() or target:GetPos() + vector_up * ( self:GetRangeTo( target ) / random( 12, 15 ) ) )
            targetPos = ( targetPos + ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( target ) * Rand( 0.5, 0.9 ) ) / 700 ) )
            
            local spawnAng = ( targetPos - spawnPos ):Angle()

            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end

            local pipe = ents_Create( "base_anim" )
            if !IsValid( pipe ) then return true end
            
            self:SimpleWeaponTimer( 0.366667, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/grenade_launcher_drum_start.wav", nil, nil, 0.4, CHAN_STATIC ) end )

            pipe:SetPos( spawnPos )
            pipe:SetAngles( spawnAng )
            pipe:SetModel( "models/weapons/w_models/w_grenade_grenadelauncher.mdl" )
            pipe:SetOwner( self )
            pipe:Spawn()

            pipe:SetSkin( self.l_TF_TeamColor )
            pipe:DrawShadow( false )
            pipe:PhysicsInit( SOLID_BBOX )
            pipe:SetGravity( 0.4 )
            pipe:SetFriction( 0.2 )
            pipe:SetElasticity( 0.45 )
            pipe:SetCollisionBounds( -pipeBounds, pipeBounds )
            pipe:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
            LAMBDA_TF2:TakeNoDamage( pipe )

            local phys = pipe:GetPhysicsObject()
            if IsValid( phys ) then
                phys:Wake()
                phys:AddVelocity( spawnAng:Forward() * 1200 + spawnAng:Up() * ( 200 + Rand( -10, 10 ) ) + spawnAng:Right() * Rand( -10, 10 ) )
                phys:AddAngleVelocity( Vector( 600, random( -1200, 1200 ), 0 ) )
            end

            pipe.l_IsTFWeapon = true
            pipe.l_CritType = critType
            pipe.l_HasTouched = false
            pipe.l_ExplodeDamage = wepent:GetWeaponAttribute( "Damage" )
            pipe.l_DamageType = wepent:GetWeaponAttribute( "DamageType" )
            
            pipe.PhysicsCollide = OnPhysicsCollide

            local critType = self:GetCritBoostType()
            if isCrit then critType = TF_CRIT_FULL end

            if critType == TF_CRIT_FULL then
                ParticleEffectAttach( "critical_pipe_" .. ( self.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, pipe, 0 )
            end

            ParticleEffectAttach( "pipebombtrail_" .. ( self.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, pipe, 0 )

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
            
                    local dmgTypes = ( DMG_BLAST + DMG_HALF_FALLOFF )
                    if pipe.l_CritType == TF_CRIT_FULL then
                        dmgTypes = ( dmgTypes + DMG_CRITICAL )
                    elseif pipe.l_CritType == TF_CRIT_MINI then
                        dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
                    end
                    dmginfo:SetDamageType(dmgTypes )

                    LAMBDA_TF2:RadiusDamageInfo( dmginfo, pipePos, 150 )
                end

                pipe:EmitSound( ")lambdaplayers/tf2/explode" .. random( 3 ) .. ".mp3", 85, nil, nil, CHAN_WEAPON )
                pipe:Remove()
            end )

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, {
                StartSound = "weapons/grenade_launcher_drum_open.wav",
                StartDelay = 1.24,
                StartFunction = function( lambda, weapon )
                    lambda:SimpleWeaponTimer( 0.64, function() 
                        lambda.l_Clip = ( lambda.l_Clip + 1 )
                        weapon:EmitSound( "weapons/grenade_launcher_drum_load.wav" ) 
                    end )
                end,
                CycleSound = "weapons/grenade_launcher_drum_load.wav",
                CycleDelay = 0.6,
                EndSound = "weapons/grenade_launcher_drum_close.wav",
                EndFunction = false,
                LayerPlayRate = 1.5
            } )

            return true
        end
    }
} )