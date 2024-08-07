local CurTime = CurTime
local IsValid = IsValid
local ents_Create = ents.Create
local FindInSphere = ents.FindInSphere
local ipairs = ipairs
local isentity = isentity
local ParticleEffect = ParticleEffect
local DamageInfo = DamageInfo
local TraceLine = util.TraceLine

local splashTrTbl = {
    mask = ( MASK_SHOT - CONTENTS_HITBOX ),
    collisiongroup = COLLISION_GROUP_PROJECTILE,
    filter = function( ent )
        if LAMBDA_TF2:IsValidCharacter( ent, false ) then return false end
    end
}
local angularImpulse = Angle( 300, 0, 0 )

local function OnJarExplode( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end

    local owner = self:GetOwner()
    local validOwner = IsValid( owner )
    if validOwner and ent == owner then return end

    ParticleEffect( "peejar_impact", self:GetPos(), angle_zero )
    self:EmitSound( ")weapons/jar_explode.wav", 80, nil, nil, CHAN_STATIC )
    
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
        elseif !validOwner or ent != owner and owner:CanTarget( ent ) then
            ent.l_TF_CoveredInUrine = effectDuration

            local fakeDmg = DamageInfo()
            fakeDmg:SetAttacker( owner )
            fakeDmg:SetInflictor( self )
            ent:TakeDamageInfo( fakeDmg )
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
        tfclass = 8,

        keepdistance = 600,
        attackrange = 1000,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:EmitSound( "weapons/draw_jarate.wav", nil, nil, nil, CHAN_STATIC )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead then return end

            if LAMBDA_TF2:IsBurning( self ) then
                self:LookTo( self:GetPos(), 0.5 )
                self:SimpleWeaponTimer( 0.33, function() self:UseWeapon( self ) end )
            elseif !self:InCombat() then
                local extinguishTargets = self:FindInSphere( nil, 750, function( ent )
                    return ( IsValid( ent ) and LAMBDA_TF2:IsValidCharacter( ent ) and LAMBDA_TF2:IsBurning( ent ) and self:CanSee( ent ) )
                end )
                if #extinguishTargets > 0 then
                    local target = extinguishTargets[ LambdaRNG( #extinguishTargets ) ]
                    self:LookTo( target, 0.5 )
                    self:SimpleWeaponTimer( 0.33, function() self:UseWeapon( target ) end )
                end
            end

            return 0.5
        end,

        OnAttack = function( self, wepent, target )
            if isentity( target ) and !IsValid( target ) then return true end

            local throwPos = ( !isentity( target ) and target or target:GetPos() )
            local throwAng = ( throwPos - self:GetPos() ):Angle()
            if target != self and self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )
            wepent:EmitSound( "weapons/jar_single.wav", 70, nil, nil, CHAN_ITEM )

            self:SimpleWeaponTimer( 0.25, function()
                local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                throwPos = ( isvector( target ) and target or ( IsValid( target ) and target:GetPos() or ( self:GetPos() + self:GetForward() * 500 ) ) )
                throwPos = ( throwPos + vector_up * ( spawnPos:Distance( throwPos ) / LambdaRNG( 20, 25 ) ) )
                throwAng = ( throwPos - spawnPos ):Angle()

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local jarate = ents_Create( "base_gmodentity" )
                jarate:SetModel( "models/weapons/c_models/urinejar.mdl" )
                jarate:SetPos( spawnPos )
                jarate:SetAngles( throwAng )
                jarate:SetOwner( self )
                jarate:Spawn()

                jarate:SetSolid( SOLID_BBOX )
                jarate:SetMoveType( MOVETYPE_FLYGRAVITY )
                jarate:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                LAMBDA_TF2:TakeNoDamage( jarate )

                jarate:SetFriction( 0.2 )
                jarate:SetElasticity( 0.45 )
                jarate:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

                jarate:SetLocalVelocity( throwAng:Forward() * 1000 + throwAng:Up() * ( 200 + LambdaRNG( -10, 10, true ) ) + throwAng:Right() * LambdaRNG( -10, 10, true ) )
                jarate:SetLocalAngularVelocity( angularImpulse )

                ParticleEffectAttach( "peejar_trail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ), PATTACH_ABSORIGIN_FOLLOW, jarate, 0 )

                jarate.l_TF_Detonated = false
                jarate.l_TF_DecreasedCooldown = false
                jarate.Touch = OnJarExplode

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )