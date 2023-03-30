local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create

local angularImpulse = Vector( 0, 500, 0 )
local hitFleshSnds = {
    ")weapons/cleaver_hit_02.wav",
    ")weapons/cleaver_hit_03.wav",
    ")weapons/cleaver_hit_05.wav",
    ")weapons/cleaver_hit_06.wav",
    ")weapons/cleaver_hit_07.wav"
}

local function OnCleaverCollide( self, colData, collider )
    local hitEnt = colData.HitEntity

    if !self.l_DealtDamage then
        local owner = self:GetOwner()
        if IsValid( owner ) and IsValid( hitEnt ) then
            if LAMBDA_TF2:IsValidCharacter( hitEnt ) then
                LAMBDA_TF2:MakeBleed( hitEnt, owner, owner:GetWeaponENT(), 5 )
                if ( CurTime() - self.l_CreationTime ) >= 1 then
                    LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_cleaver", 1.5 )
                    if self.l_TF_CritType == CRIT_NONE then self.l_TF_CritType = CRIT_MINI end
                end
            end

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( 30 )
            dmginfo:SetDamagePosition( self:GetPos() )

            local dmgTypes = DMG_GENERIC
            if self.l_TF_CritType == CRIT_FULL then 
                dmgTypes = ( dmgTypes + DMG_CRITICAL )
            elseif self.l_TF_CritType == CRIT_MINI then
                dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
            end
            dmginfo:SetDamageType( dmgTypes )

            hitEnt:DispatchTraceAttack( dmginfo, self:GetTouchTrace(), self:GetForward() )
        end

        self.l_DealtDamage = true
    end

    local trail = self.l_Trail
    if IsValid( hitEnt ) and LAMBDA_TF2:IsValidCharacter( hitEnt ) then
        if IsValid( trail ) then
            trail:SetParent()
            SafeRemoveEntityDelayed( trail, 1 )
        end

        self:EmitSound( hitFleshSnds[ random( #hitFleshSnds ) ], nil, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:CreateBloodParticle( self:GetPos(), AngleRand( -180, 180 ), hitEnt )

        self:SetNoDraw( true )
        self:DrawShadow( false )
        self:SetSolid( SOLID_NONE )
        SafeRemoveEntityDelayed( self, 0.1 )
    else
        self:EmitSound( ")weapons/cleaver_hit_world.wav", nil, nil, nil, CHAN_STATIC )
        self:SetPos( colData.HitPos + colData.HitNormal * 3 )
        self:SetMoveType( MOVETYPE_NONE )

        if IsValid( trail ) then self:DeleteOnRemove( trail ) end
        SafeRemoveEntityDelayed( self, 2 )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_cleaver = {
        model = "models/lambdaplayers/tf2/weapons/w_cleaver.mdl",
        origin = "Team Fortress 2",
        prettyname = "Flying Guillotine",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_flyingguillotine",
        keepdistance = 750,
        attackrange = 2500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "weapons/cleaver_draw.wav", nil, nil, nil, CHAN_STATIC )
        end,

        OnAttack = function( self, wepent, target )
            local throwAng = ( target:GetPos() - wepent:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( ")weapons/cleaver_throw.wav", 70, nil, nil, CHAN_WEAPON )

            self:SimpleWeaponTimer( 0.25, function()
                throwAng = ( IsValid( target ) and ( target:GetPos() - wepent:GetPos() ):Angle() or self:GetAngles() )

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local cleaver = ents_Create( "base_anim" )
                cleaver:SetModel( wepent:GetModel() )
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

                cleaver.IsLambdaWeapon = true
                cleaver.l_killiconname = wepent.l_killiconname
                cleaver.l_TF_IsTF2Weapon = true
                cleaver.l_IsTFProjectile = true

                cleaver.l_CreationTime = CurTime()
                cleaver.l_DealtDamage = false
                cleaver.PhysicsCollide = OnCleaverCollide

                local critType = LAMBDA_TF2:GetCritBoost( self )
                if wepent:CalcIsAttackCriticalHelper() then critType = CRIT_FULL end
                cleaver.l_TF_CritType = critType

                local trail = LAMBDA_TF2:CreateSpriteTrailEntity( self:GetPlyColor():ToColor(), nil, 10, 5, 0.5, "trails/laser", cleaver:WorldSpaceCenter(), cleaver )
                cleaver.l_Trail = trail

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )