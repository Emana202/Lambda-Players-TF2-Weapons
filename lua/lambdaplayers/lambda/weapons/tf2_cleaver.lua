local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create

local angularImpulse = Vector( 0, 500, 0 )

local function OnCleaverCollide( self, colData, collider )
    local owner = self:GetOwner()
    local hitEnt = colData.HitEntity

    if IsValid( owner ) and IsValid( hitEnt ) then
        LAMBDA_TF2:MakeBleed( hitEnt, owner, owner:GetWeaponENT(), 5 )

        local dmginfo = DamageInfo()
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( owner:GetWeaponENT() )
        dmginfo:SetDamage( 30 )
        dmginfo:SetDamagePosition( self:GetPos() )

        local dmgTypes = DMG_GENERIC
        if self.l_IsCritical then 
            dmgTypes = ( dmgTypes + DMG_CRITICAL )
        elseif ( CurTime() - self.l_CreationTime ) >= 1 then
            dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
        end
        dmginfo:SetDamageType( dmgTypes )

        hitEnt:DispatchTraceAttack( dmginfo, self:GetTouchTrace(), self:GetForward() )
    end

    local trail = self.l_Trail
    if IsValid( trail ) then
        trail:SetParent()
        trail:SetPos( colData.HitPos )
        SafeRemoveEntityDelayed( trail, 1 )
    end

    if IsValid( hitEnt ) and LAMBDA_TF2:IsValidCharacter( hitEnt ) then
        self:EmitSound( "lambdaplayers/weapons/tf2/cleaver/cleaver_hit_0" .. random( 1, 6 ) .. ".mp3", 85, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:CreateBloodParticle( self:GetPos(), AngleRand( -180, 180 ), hitEnt )
        self:Remove()
    else
        self:EmitSound( "lambdaplayers/weapons/tf2/cleaver/cleaver_hit_world.mp3", 85, nil, nil, CHAN_STATIC )
        self:SetPos( colData.HitPos + colData.HitNormal * 5 )
        self:SetMoveType( MOVETYPE_NONE )
        SafeRemoveEntityDelayed( self, 2 )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_cleaver = {
        model = "models/lambdaplayers/weapons/tf2/w_cleaver.mdl",
        origin = "Team Fortress 2",
        prettyname = "Flying Guillotine",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_flyingguillotine",
        keepdistance = 500,
        attackrange = 1500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/cleaver/cleaver_draw.mp3", nil, nil, nil, CHAN_STATIC )
        end,

        OnAttack = function( self, wepent, target )
            local throwAng = ( target:GetPos() - wepent:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/cleaver/cleaver_throw.mp3", 84, nil, nil, CHAN_WEAPON )

            self:SimpleWeaponTimer( 0.25, function()
                throwAng = ( IsValid( target ) and ( target:GetPos() - wepent:GetPos() ):Angle() or self:GetAngles() )

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local cleaver = ents_Create( "base_anim" )
                cleaver:SetModel( "models/lambdaplayers/weapons/tf2/w_cleaver.mdl" )
                cleaver:SetPos( wepent:GetPos() )
                cleaver:SetAngles( throwAng )
                cleaver:SetOwner( self )
                cleaver:Spawn()
    
                cleaver:PhysicsInit( SOLID_BBOX )
                cleaver:SetGravity( 0.4 )
                cleaver:SetFriction( 0.2 )
                cleaver:SetElasticity( 0.45 )
                cleaver:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
                LAMBDA_TF2:TakeNoDamage( cleaver )
    
                local phys = cleaver:GetPhysicsObject()
                if IsValid( phys ) then
                    local throwVel = vector_origin
                    throwVel = throwVel + throwAng:Forward() * 10
                    throwVel = throwVel + throwAng:Up() * 1
                    throwVel:Normalize()
                    throwVel = throwVel * 3000
                    phys:AddVelocity( throwVel )
    
                    phys:AddAngleVelocity( angularImpulse )
                    phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
                end
    
                cleaver.l_CreationTime = CurTime()
                cleaver.l_IsCritical = wepent:CalcIsAttackCriticalHelper()
                cleaver.PhysicsCollide = OnCleaverCollide

                local trail = LAMBDA_TF2:CreateSpriteTrailEntity( self:GetPlyColor():ToColor(), nil, 10, 5, 0.5, "trails/laser", cleaver:WorldSpaceCenter(), cleaver )
                cleaver.l_Trail = trail

                self:SimpleWeaponTimer( 0.8, function()
                    LAMBDA_TF2:AddInventoryCooldown( self )
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )