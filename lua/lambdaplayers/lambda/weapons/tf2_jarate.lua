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
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end
    end
}
local angularImpulse = Vector( 0, 500, 0 )

local function OnJarExplode( self, colData, collider )
    if self.l_TF_Detonated then return end
    self.l_TF_Detonated = true

    ParticleEffect( "peejar_impact", self:GetPos(), angle_zero )
    self:EmitSound( "lambdaplayers/weapons/tf2/jarate/jar_explode.mp3", 85, nil, nil, CHAN_STATIC )

    splashTrTbl.start = self:GetPos()
    
    local owner = self:GetOwner()
    local effectDuration = ( CurTime() + 10 )
    for _, ent in ipairs( FindInSphere( self:GetPos(), 200 ) ) do
        if !LambdaIsValid( ent ) or !ent:IsPlayer() and !ent:IsNPC() and !ent:IsNextBot() or !owner:CanTarget( ent ) then continue end

        splashTrTbl.endpos = ent:GetPos()
        if TraceLine( splashTrTbl ).HitWorld then continue end

        if ent != owner then
            ent.l_TF_CoveredInUrine = effectDuration
        elseif ent.l_TF_IsBurning or ent:IsOnFire() then
            ent:EmitSound( ")lambdaplayers/weapons/tf2/flame_out.mp3", nil, nil, nil, CHAN_STATIC )
            LAMBDA_TF2:RemoveBurn( ent )
        end
    end

    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_jarate = {
        model = "models/lambdaplayers/weapons/tf2/w_jarate.mdl",
        origin = "Team Fortress 2",
        prettyname = "Jarate",
        holdtype = "grenade",
        bonemerge = true,

        keepdistance = 500,
        attackrange = 700,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/jarate/draw_jarate.mp3", nil, nil, nil, CHAN_STATIC )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead then return end

            if self.l_TF_IsBurning or self:IsOnFire() then
                local selfPos = self:GetPos()
                self:LookTo( selfPos, 1.0 )
                self:SimpleWeaponTimer( 0.5, function() self:UseWeapon( selfPos ) end )
                return 1.5
            end
        end,

        OnAttack = function( self, wepent, target )
            local throwAng = ( ( ( isvector( target ) and target or target:GetPos() ) - wepent:GetPos() ):Angle() )
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( "lambdaplayers/weapons/tf2/jarate/jar_single.mp3", 84, nil, nil, CHAN_WEAPON )
            
            self:ClientSideNoDraw( wepent, true )
            wepent:SetNoDraw( true )
            wepent:DrawShadow( false )

            local jarate = ents_Create( "base_anim" )
            jarate:SetModel( "models/lambdaplayers/weapons/tf2/w_jarate.mdl" )
            jarate:SetPos( wepent:GetPos() )
            jarate:SetAngles( throwAng )
            jarate:SetOwner( self )
            jarate:Spawn()

            jarate:PhysicsInit( SOLID_BBOX )
            jarate:SetGravity( 0.4 )
            jarate:SetFriction( 0.2 )
            jarate:SetElasticity( 0.45 )
            jarate:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

            local phys = jarate:GetPhysicsObject()
            if IsValid( phys ) then
                local throwVel = ( throwAng:Forward() * 1000 + throwAng:Up() * ( 200 + Rand( -10, 10 ) ) + throwAng:Right() * Rand( -10, 10 ) )
                phys:AddVelocity( throwVel )

                phys:AddAngleVelocity( angularImpulse )
                phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
            end

            jarate.l_TF_Detonated = false
            jarate.PhysicsCollide = OnJarExplode

            self:SimpleWeaponTimer( 1, function()
                self:SwitchToLethalWeapon()
            end )

            return true
        end
    }
} )