AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local CurTime = CurTime
local Round = math.Round

function ENT:Initialize()
    self:SetModel( self.Model or "models/items/medkit_small.mdl" )

    self.IsRespawning = false
    self.TouchTime = ( self.TouchTime or 0 )
    self.HealRatio = ( self.HealRatio or 0.2 )
    if self.CanRespawn == nil then self.CanRespawn = true end

    if self.CanRespawn then
        self:PhysicsDestroy()
        self:SetSolidFlags( FSOLID_NOT_SOLID + FSOLID_TRIGGER )
        self:ResetSequence( self:LookupSequence( "idle" ) )    
        self:SetMoveType( MOVETYPE_FLYGRAVITY )
        self:SetMoveCollide( MOVECOLLIDE_FLY_BOUNCE )
        self:SetSolid( SOLID_BBOX )
    else
        self:PhysicsInit( SOLID_VPHYSICS )
        self:PhysWake()
        self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        self:AddSolidFlags( FSOLID_TRIGGER )
    end
end

function ENT:Think()
    local removeT = self.RemoveTime
    if removeT and ( CurTime() - self:GetCreationTime() ) >= removeT then
        self:Remove()
        return
    end

    if self.IsRespawning and CurTime() >= self.IsRespawning then
        self:EmitSound( "items/spawn_item.wav", nil, nil, 0.25, CHAN_STATIC )
        self:SetNoDraw( false )
        self:DrawShadow( true )
        self.IsRespawning = false
    end

    self:NextThink( CurTime() )
    return true
end

function ENT:Touch( other )
    if self.IsRespawning or CurTime() <= self.TouchTime or !IsValid( other ) or !LAMBDA_TF2:IsValidCharacter( other ) then return end
    local givenHealth = LAMBDA_TF2:GiveHealth( other, Round( other:GetMaxHealth() * self.HealRatio ), false )

    if givenHealth > 0 or LAMBDA_TF2:IsBleeding( other ) or LAMBDA_TF2:IsBurning( other ) then
        self:EmitSound( "HealthKit.Touch" )
        LAMBDA_TF2:RemoveBurn( other )
        LAMBDA_TF2:RemoveBleeding( other )

        if !self.CanRespawn then
            self:Remove()
        else
            self:SetNoDraw( true )
            self:DrawShadow( false )
            self.IsRespawning = ( CurTime() + 10 )
        end
    end

    self.TouchTime = ( CurTime() + 0.1 )
end