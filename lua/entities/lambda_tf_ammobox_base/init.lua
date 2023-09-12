AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

local IsValid = IsValid
local CurTime = CurTime
local Round = math.Round
local min = math.min
local GetAmmoMax = game.GetAmmoMax
local ipairs = ipairs
local pairs = pairs

function ENT:Initialize()
    self:SetModel( self.Model or "models/items/ammopack_small.mdl" )

    self.TouchTime = ( self.TouchTime or 0 )
    self.RefillRatio = ( self.RefillRatio or 0.2 )
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
    if self.IsRespawning or CurTime() <= self.TouchTime then return end 
    if !IsValid( other ) or !LAMBDA_TF2:IsValidCharacter( other ) then return end

    local refillRatio = self.RefillRatio
    local refilled = false

    if other:IsPlayer() then
        local gottenAmmo = {}
        local plyAmmo = other:GetAmmo()

        for ammoID, ammoCount in pairs( plyAmmo ) do
            local maxAmmo = GetAmmoMax( ammoID )
            if ammoCount < maxAmmo then 
                other:SetAmmo( min( ammoCount + Round( maxAmmo * refillRatio ), maxAmmo ), ammoID )
                refilled = true
            end
            
            gottenAmmo[ ammoID ] = true
        end

        plyAmmo = other:GetAmmo()
        for _, wep in ipairs( other:GetWeapons() ) do
            local primType = wep:GetPrimaryAmmoType()
            if !gottenAmmo[ primType ] then
                local primAmmo = GetAmmoMax( primType )
                local primCount = ( !plyAmmo[ primType ] and 0 or plyAmmo[ primType ] )
                if primAmmo != -1 and primCount < primAmmo then 
                    other:SetAmmo( min( primCount + Round( primAmmo * refillRatio ), primAmmo ), primType ) 
                    refilled = true
                end
            end

            local secType = wep:GetSecondaryAmmoType()
            if !gottenAmmo[ secType ] then
                local secAmmo = GetAmmoMax( secType )
                local secCount = ( !plyAmmo[ secType ] and 0 or plyAmmo[ secType ] )
                if secAmmo != -1 and secCount < secAmmo then 
                    other:SetAmmo( min( secCount + Round( secAmmo * refillRatio ), secAmmo ), secType ) 
                    refilled = true
                end
            end
        end
    elseif other.IsLambdaPlayer and !other.l_TF_CantReplenishClip then
        local clip = other.l_Clip
        local maxClip = other.l_MaxClip
        if clip < maxClip then 
            other.l_Clip = min( clip + Round( maxClip * refillRatio ), maxClip )
            other:SetIsReloading( false )
            refilled = true
        end
    end

    if refilled then
        self:EmitSound( "items/gunpickup2.wav", nil, nil, nil, CHAN_STATIC )

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