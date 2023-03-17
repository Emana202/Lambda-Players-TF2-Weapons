local IsValid = IsValid
local CurTime = CurTime
local CreateSound = CreateSound
local ipairs = ipairs
local DamageInfo = DamageInfo
local SoundDuration = SoundDuration
local ParticleEffectAttach = ParticleEffectAttach
local max = math.max
local Rand = math.Rand
local ceil = math.ceil
local TraceLine = util.TraceLine
local TraceHull = util.TraceHull
local debugoverlay = debugoverlay
local FindAlongRay = ents.FindAlongRay
local ents_Create = ents.Create
local dev = GetConVar( "developer" )

local color_hitsomething = Color( 255, 255, 0, 100 )
local color_hitworld = Color( 255, 0, 0, 100 )

local rayWorldTbl = {}
local dmgTraceTbl = {
    mask = ( MASK_SOLID + CONTENTS_HITBOX ),
}

local function KillSounds( wepent ) 
    wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_pilot.mp3" )
    wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav" )
    wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_end.mp3" )
    
    if wepent.l_FireLoopSound then wepent.l_FireLoopSound:Stop(); wepent.l_FireLoopSound = nil end 
    if wepent.l_FireCritSound then wepent.l_FireCritSound:Stop(); wepent.l_FireCritSound = nil end 
end

local function OnFlameThink( self )
    if CurTime() >= self.l_RemoveTime then
        self:Remove()
        return
    end

    local selfPos = self:GetPos()
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()
    local prevPos = self.l_PreviousPos

    if selfPos != prevPos then
        local attacker = self.l_Attacker
        local initialPos = self.l_InitialPos

        if IsValid( attacker ) then
            rayWorldTbl.start = initialPos
            rayWorldTbl.endpos = selfPos
            rayWorldTbl.mins = mins
            rayWorldTbl.maxs = maxs

            rayWorldTbl.filter = self    
            rayWorldTbl.mask = MASK_SOLID
            rayWorldTbl.collisiongroup = COLLISION_GROUP_DEBRIS

            local trWorld = TraceHull( rayWorldTbl )
            local hitWorld = ( trWorld.StartSolid or trWorld.Fraction < 1 )

            local hitSomething = false
            for _, ent in ipairs( FindAlongRay( prevPos, selfPos, mins, maxs ) ) do
                if ent == self or ent == attacker then continue end
                if attacker.IsLambdaPlayer and ( ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() ) and !attacker:CanTarget( ent ) then continue end

                local alreadyBurning = false
                for _, v in ipairs( self.l_EntitiesBurnt ) do
                    if v != ent then continue end
                    alreadyBurning = true; break
                end
                if alreadyBurning then continue end

                if hitWorld then
                    rayWorldTbl.filter = NULL 
                    rayWorldTbl.mask = ( MASK_SOLID + CONTENTS_HITBOX )
                    rayWorldTbl.collisiongroup = COLLISION_GROUP_NONE

                    local trEnt = TraceHull( rayWorldTbl )
                    if trEnt.Fraction >= trWorld.Fraction then continue end
                end

                if selfPos:IsUnderwater() then
                    self:Remove()
                    return
                end

                self.l_EntitiesBurnt[ #self.l_EntitiesBurnt + 1 ] = ent

                local distance = selfPos:Distance( initialPos )
                local damage = max( 1, self.l_DmgAmount * LAMBDA_TF2:RemapClamped( distance, 175, 350, 1, 0.7 ) )

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker( attacker )
                dmginfo:SetInflictor( self:GetOwner() )
                dmginfo:SetDamage( damage )
                dmginfo:SetDamageType( self.l_DmgType )
                dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BURNING )
                dmginfo:SetReportedPosition( attacker:GetPos() )

                dmgTraceTbl.start = self:WorldSpaceCenter()
                dmgTraceTbl.endpos = ent:WorldSpaceCenter()
                dmgTraceTbl.filter = self
                dmgTraceTbl.collisiongroup = COLLISION_GROUP_NONE
                ent:DispatchTraceAttack( dmginfo, TraceLine( dmgTraceTbl ), self:GetAbsVelocity() )

                hitSomething = true
            end

            if hitSomething and dev:GetBool() then
                debugoverlay.SweptBox( prevPos, selfPos, mins, maxs, angle_zero, 5, color_hitsomething )
                debugoverlay.BoxAngles( selfPos, mins, maxs, self:GetAngles(), 0, color_hitsomething )
            end

            if hitWorld then
                if dev:GetBool() then debugoverlay.SweptBox( initialPos, selfPos, mins, maxs, angle_zero, 3, color_hitworld ) end
                self:Remove()
            end
        end
    end

    local baseVel = ( self.l_BaseVelocity * 0.87 )
    self.l_BaseVelocity = baseVel

    local newVel = ( baseVel + ( vector_up * 50 ) + self.l_AttackerVelocity )
    self:SetAbsVelocity( newVel )

    if dev:GetBool() then
        if #self.l_EntitiesBurnt > 0 then
            local val = ceil( CurTime() * 10 % 255 )
            debugoverlay.BoxAngles( selfPos, mins, maxs, self:GetAngles(), 0, Color( val, 255, val, 0 ) )
        else
            debugoverlay.BoxAngles( selfPos, mins, maxs, self:GetAngles(), 0, Color( 0, 100, 255, 0 ) )
        end
    end

    self.l_PreviousPos = selfPos

    self:NextThink( CurTime() )
    return true
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_flamethrower = {
        model = "models/lambdaplayers/weapons/tf2/w_flamethrower.mdl",
        origin = "Team Fortress 2",
        prettyname = "Flame Thrower",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_flamethrower",

        clip = 200,
        islethal = true,
        attackrange = 350,
        keepdistance = 100,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 100 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.04 )
            wepent:SetWeaponAttribute( "IsRapidFire", true )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_IGNITE + DMG_PREVENT_PHYSICS_FORCE ) )

            wepent.l_IsCritical = true
            wepent.l_FireLoopSound = CreateSound( wepent, "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_loop.wav" )
            wepent.l_FireCritSound = CreateSound( wepent, "lambdaplayers/weapons/tf2/crits/crit_shoot_loop.wav" )
            wepent.l_FireState = 0
            wepent.l_NextFireStateUpdateT = CurTime()
            
            wepent.l_FireAttackTime = false
            wepent.l_FireDirection = self:GetForward()
            wepent.l_FireShootTime = CurTime()

            wepent.l_ActiveFlames = 0

            wepent:CallOnRemove( "LambdaTF2_Flamethrower_StopSound" .. wepent:EntIndex(), KillSounds )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_pilot.mp3", 60 )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_primary.mp3", 74, 100, 0.5 )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead or self:GetNoDraw() then
                wepent.l_FireAttackTime = false
                wepent.l_FireState = 0
                wepent.l_NextFireStateUpdateT = CurTime()

                wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav" )
                wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_end.mp3" )
                LAMBDA_TF2:StopParticlesNamed( wepent, "flamethrower" )

                if wepent.l_FireLoopSound then wepent.l_FireLoopSound:Stop() end
                if wepent.l_FireCritSound then wepent.l_FireCritSound:Stop() end 
            else
                if wepent.l_FireAttackTime then 
                    if CurTime() > wepent.l_FireAttackTime then
                        if wepent.l_FireLoopSound then wepent.l_FireLoopSound:Stop() end
                        if wepent.l_FireCritSound then wepent.l_FireCritSound:Stop() end

                        wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav" )
                        wepent:EmitSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_end.mp3", 70 )
                        LAMBDA_TF2:StopParticlesNamed( wepent, "flamethrower" )

                        wepent.l_FireAttackTime = false
                        wepent.l_FireState = 0
                        wepent.l_NextFireStateUpdateT = CurTime()
                    else
                        if CurTime() > wepent.l_NextFireStateUpdateT then
                            if wepent.l_FireState == 0 then
                                wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_end.mp3" )
                                wepent:EmitSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav", 70 )
                                ParticleEffectAttach( "flamethrower", PATTACH_POINT_FOLLOW, wepent, 1 )

                                wepent.l_FireState = 1
                                wepent.l_NextFireStateUpdateT = CurTime() + SoundDuration( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav" )
                            elseif wepent.l_FireLoopSound and !wepent.l_FireLoopSound:IsPlaying() then 
                                wepent.l_FireLoopSound:Play() 
                            end
                        end

                        if wepent.l_FireCritSound then
                            if wepent.l_IsCritical then
                                if !wepent.l_FireCritSound:IsPlaying() then
                                    wepent.l_FireCritSound:Play()
                                end
                            else
                                wepent.l_FireCritSound:Stop()
                            end
                        end

                        if CurTime() > wepent.l_FireShootTime then
                            wepent.l_IsCritical = wepent:CalcIsAttackCriticalHelper()

                            local fireInterval = wepent:GetWeaponAttribute( "RateOfFire" )
                            wepent.l_FireShootTime = ( CurTime() + fireInterval )

                            local damagePerSec = wepent:GetWeaponAttribute( "Damage" )
                            local totalDamage = ( damagePerSec * fireInterval )

                            local dmgTypes = wepent:GetWeaponAttribute( "DamageType" )
                            if wepent.l_IsCritical then dmgTypes = ( dmgTypes + DMG_CRITICAL ) end

                            local ene = self:GetEnemy()
                            local eyes = self:GetAttachmentPoint( "eyes" )

                            local srcPos = eyes.Pos
                            local firePos = ( LambdaIsValid( ene ) and ene:WorldSpaceCenter() or ( srcPos + self:GetForward() * 96 ) )

                            local fireAng = ( firePos - srcPos ):Angle()
                            srcPos = ( srcPos + fireAng:Right() * 12 )

                            local flameEnt = ents_Create( "base_anim" )
                            flameEnt:SetPos( srcPos )
                            flameEnt:SetAngles( fireAng )
                            flameEnt:SetOwner( wepent )
                            flameEnt:Spawn()

                            flameEnt:SetNoDraw( true )
                            flameEnt:DrawShadow( false )

                            flameEnt:SetSaveValue( "m_takedamage", 0 )
                            flameEnt:SetSolid( SOLID_NONE )
                            flameEnt:SetSolidFlags( FSOLID_NOT_SOLID )
                            flameEnt:SetCollisionGroup( COLLISION_GROUP_NONE )
                            flameEnt:SetMoveType( MOVETYPE_NOCLIP )
                            flameEnt:AddEFlags( EFL_NO_WATER_VELOCITY_CHANGE )

                            local boxSize = Vector( 12, 12, 12 )
                            flameEnt:SetCollisionBounds( -boxSize, boxSize )



                            flameEnt.l_InitialPos = srcPos
                            flameEnt.l_PreviousPos = flameEnt.l_InitialPos
                            flameEnt.l_Attacker = self
                            flameEnt.l_DmgType = dmgTypes
                            flameEnt.l_DmgAmount = totalDamage
                            flameEnt.l_AttackerVelocity = self.loco:GetVelocity()
                            flameEnt.l_RemoveTime = ( CurTime() + ( 0.5 * Rand( 0.9, 1.1 ) ) )
                            flameEnt.l_EntitiesBurnt = {}

                            local speed = 2300
                            local velocity = ( fireAng:Forward() * speed )
                            flameEnt.l_BaseVelocity = ( velocity + VectorRand( -speed * 0.05, speed * 0.05 ) )
                            flameEnt:SetAbsVelocity( flameEnt.l_BaseVelocity )

                            flameEnt.Draw = function() end
                            flameEnt.Think = OnFlameThink
                        end
                    end
                end
            end
        end,

        OnHolster = function( self, wepent )
            wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_pilot.mp3" )
            wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_start.wav" )
            wepent:StopSound( "lambdaplayers/weapons/tf2/flamethrower/flame_thrower_end.mp3" )
            LAMBDA_TF2:StopParticlesNamed( wepent, "flamethrower" )

            if wepent.l_FireLoopSound then wepent.l_FireLoopSound:Stop(); wepent.l_FireLoopSound = nil end 
            if wepent.l_FireCritSound then wepent.l_FireCritSound:Stop(); wepent.l_FireCritSound = nil end 
        end,

        OnAttack = function( self, wepent, target )
            wepent.l_FireAttackTime = CurTime() + Rand( 0.1, 0.66 )
            wepent.l_FireDirection = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
            return true
        end
    }
} )