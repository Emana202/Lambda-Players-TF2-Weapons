local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local ents_Create = ents.Create
local FindInSphere = ents.FindInSphere
local ipairs = ipairs
local ParticleEffect = ParticleEffect
local TraceLine = util.TraceLine

local splashTrTbl = {
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    collisiongroup = COLLISION_GROUP_PROJECTILE,
    filter = function( ent )
        if LAMBDA_TF2:IsValidCharacter( ent, false ) then return false end
    end
}
local angularImpulse = Vector( 0, 500, 0 )

local function OnJarExplode( self, colData, collider )
    if self.l_TF_Detonated then return end
    self.l_TF_Detonated = true

    ParticleEffect( "peejar_impact", self:GetPos(), angle_zero )
    self:EmitSound( ")weapons/jar_explode.wav", 80, nil, nil, CHAN_STATIC )
    
    local owner = self:GetOwner()
    local validOwner = IsValid( owner )

    splashTrTbl.start = self:GetPos()
    local effectDuration = ( CurTime() + 10 )

    for _, ent in ipairs( FindInSphere( self:GetPos(), 200 ) ) do
        if !IsValid( ent ) or !LAMBDA_TF2:IsValidCharacter( ent ) then continue end

        splashTrTbl.endpos = ent:GetPos()
        if TraceLine( splashTrTbl ).HitWorld then continue end

        if LAMBDA_TF2:IsBurning( ent ) then
            ent:EmitSound( ")player/flame_out.wav", nil, nil, nil, CHAN_STATIC )
            LAMBDA_TF2:RemoveBurn( ent )
            
            if validOwner and ent != owner and !self.l_TF_DecreasedCooldown then
                self.l_TF_DecreasedCooldown = true
                LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_jarate", 4 )
            end
        end

        if !validOwner or ent != owner and owner:CanTarget( ent ) then
            ent.l_TF_CoveredInUrine = effectDuration
        end
    end

    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_jarate = {
        model = "models/lambdaplayers/tf2/weapons/w_jarate.mdl",
        origin = "Team Fortress 2",
        prettyname = "Jarate",
        holdtype = "grenade",
        bonemerge = true,

        keepdistance = 400,
        attackrange = 750,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "weapons/draw_jarate.wav", nil, nil, nil, CHAN_STATIC )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead or self:InCombat() then return end

            if LAMBDA_TF2:IsBurning( self ) then
                self:LookTo( self, 1.0 )
                self:SimpleWeaponTimer( 0.5, function() self:UseWeapon( self ) end )
            else
                local extinguishTargets = self:FindInSphere( nil, 750, function( ent )
                    return ( LambdaIsValid( ent ) and LAMBDA_TF2:IsBurning( ent ) and LAMBDA_TF2:IsValidCharacter( ent ) and self:CanSee( ent ) )
                end )
                if #extinguishTargets > 0 then
                    local target = extinguishTargets[ random( #extinguishTargets ) ]
                    self:LookTo( target, 1.0 )
                    self:SimpleWeaponTimer( 0.5, function() self:UseWeapon( target ) end )
                end
            end

            return 1.5
        end,

        OnAttack = function( self, wepent, target )
            local throwPos = ( isvector( target ) and target or target:GetPos() )
            local throwAng = ( throwPos - wepent:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( "weapons/jar_single.wav", 70, nil, nil, CHAN_ITEM )

            self:SimpleWeaponTimer( 0.25, function()
                throwPos = ( isvector( target ) and target or ( IsValid( target ) and target:GetPos() or ( self:GetPos() + self:GetForward() * 500 ) ) )
                throwAng = ( throwPos - wepent:GetPos() ):Angle()

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local jarate = ents_Create( "base_anim" )
                jarate:SetModel( wepent:GetModel() )
                jarate:SetPos( wepent:GetPos() )
                jarate:SetAngles( throwAng )
                jarate:SetOwner( self )
                jarate:Spawn()

                jarate:PhysicsInit( SOLID_BBOX )
                jarate:SetGravity( 0.4 )
                jarate:SetFriction( 0.2 )
                jarate:SetElasticity( 0.45 )
                jarate:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
                LAMBDA_TF2:TakeNoDamage( jarate )

                local phys = jarate:GetPhysicsObject()
                if IsValid( phys ) then
                    local throwVel = ( throwAng:Forward() * 1000 + throwAng:Up() * ( 200 + Rand( -10, 10 ) ) + throwAng:Right() * Rand( -10, 10 ) )
                    phys:AddVelocity( throwVel )

                    phys:AddAngleVelocity( angularImpulse )
                    phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
                end

                jarate.l_TF_Detonated = false
                jarate.l_TF_DecreasedCooldown = false
                jarate.PhysicsCollide = OnJarExplode

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )