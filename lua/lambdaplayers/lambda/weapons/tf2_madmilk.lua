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
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return false end
    end
}
local angularImpulse = Vector( 0, 500, 0 )

local function OnJarExplode( self, colData, collider )
    if self.l_TF_Detonated then return end
    self.l_TF_Detonated = true

    ParticleEffect( "peejar_impact_milk", self:GetPos(), angle_zero )
    self:EmitSound( "lambdaplayers/weapons/tf2/jarate/jar_explode.mp3", 85, nil, nil, CHAN_STATIC )

    splashTrTbl.start = self:GetPos()
    
    local owner = self:GetOwner()
    local effectDuration = ( CurTime() + 10 )
    for _, ent in ipairs( FindInSphere( self:GetPos(), 200 ) ) do
        if !LambdaIsValid( ent ) or !LAMBDA_TF2:IsValidCharacter( ent ) then continue end

        splashTrTbl.endpos = ent:GetPos()
        if TraceLine( splashTrTbl ).HitWorld then continue end

        if ent.l_TF_IsBurning or ent:IsOnFire() then
            ent:EmitSound( ")lambdaplayers/weapons/tf2/flame_out.mp3", nil, nil, nil, CHAN_STATIC )
            LAMBDA_TF2:RemoveBurn( ent )
        end

        if ent != owner and owner:CanTarget( ent ) then
            ent.l_TF_CoveredInMilk = effectDuration
        end
    end

    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_madmilk = {
        model = "models/lambdaplayers/weapons/tf2/w_madmilk.mdl",
        origin = "Team Fortress 2",
        prettyname = "Mad Milk",
        holdtype = "grenade",
        bonemerge = true,

        keepdistance = 400,
        attackrange = 750,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/madmilk/draw_madmilk.mp3", nil, nil, nil, CHAN_STATIC )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead then return end

            if self.l_TF_IsBurning or self:IsOnFire() then
                local selfPos = self:GetPos()
                self:LookTo( selfPos, 1.0 )
                self:SimpleWeaponTimer( 0.5, function() self:UseWeapon( selfPos ) end )
            else
                local extinguishTargets = self:FindInSphere( nil, 750, function( ent )
                    return ( LambdaIsValid( ent ) and ( ent.l_TF_IsBurning or ent:IsOnFire() ) and LAMBDA_TF2:IsValidCharacter( ent ) and self:CanSee( ent ) )
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
            local throwAng = ( ( ( isvector( target ) and target or target:GetPos() ) - wepent:GetPos() ):Angle() )
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            self:SimpleWeaponTimer( 0.25, function()
                throwAng = ( isvector( target ) and target or ( IsValid( target ) and ( target:GetPos() - wepent:GetPos() ):Angle() or self:GetAngles() ) )

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local milkjar = ents_Create( "base_anim" )
                milkjar:SetModel( "models/lambdaplayers/weapons/tf2/w_madmilk.mdl" )
                milkjar:SetPos( wepent:GetPos() )
                milkjar:SetAngles( throwAng )
                milkjar:SetOwner( self )
                milkjar:Spawn()

                milkjar:PhysicsInit( SOLID_BBOX )
                milkjar:SetGravity( 0.4 )
                milkjar:SetFriction( 0.2 )
                milkjar:SetElasticity( 0.45 )
                milkjar:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
                LAMBDA_TF2:TakeNoDamage( milkjar )

                local phys = milkjar:GetPhysicsObject()
                if IsValid( phys ) then
                    local throwVel = ( throwAng:Forward() * 1000 + throwAng:Up() * ( 200 + Rand( -10, 10 ) ) + throwAng:Right() * Rand( -10, 10 ) )
                    phys:AddVelocity( throwVel )

                    phys:AddAngleVelocity( angularImpulse )
                    phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG )
                end

                milkjar.l_TF_Detonated = false
                milkjar.PhysicsCollide = OnJarExplode

                self:SimpleWeaponTimer( 0.8, function()
                    LAMBDA_TF2:AddInventoryCooldown( self )
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )