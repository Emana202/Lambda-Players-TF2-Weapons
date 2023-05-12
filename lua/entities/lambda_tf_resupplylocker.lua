AddCSLuaFile()

ENT.PrintName				= "Resupply Locker"
ENT.Category				= "Lambda TF2"
ENT.Base 					= "base_anim"
ENT.Spawnable 				= true
ENT.AdminOnly 				= true
ENT.AutomaticFrameAdvance   = true
ENT.IsLambdaTFLocker        = true

if ( SERVER ) then

    local FindInSphere = ents.FindInSphere
    local ipairs = ipairs
    local SimpleTimer = timer.Simple
    local pairs = pairs
    local GetAmmoMax = game.GetAmmoMax
    local max = math.max
    local IsValid = IsValid
    local CurTime = CurTime
    local TraceLine = util.TraceLine
    local lockerTrTbl = { filter = { NULL, NULL } }

    function ENT:Initialize()
        self:SetModel( self.Model or "models/tf2pickups/resupply_locker.mdl" )
        self:SetSolid( SOLID_VPHYSICS )
        self:DrawShadow( false )
        self:SetMoveType( MOVETYPE_PUSH )
    end

    function ENT:Think()
        local lockerPos = self:WorldSpaceCenter()

        for _, ply in ipairs( FindInSphere( lockerPos, 48 ) ) do
            if !IsValid( ply ) or !ply.IsLambdaPlayer and !ply:IsPlayer() or !ply:Alive() then continue end 
            if ply.l_TF_NextLockerResupplyTime > CurTime() then continue end

            lockerTrTbl.start = lockerPos
            lockerTrTbl.endpos = ply:WorldSpaceCenter()
            lockerTrTbl.filter[ 1 ] = self
            lockerTrTbl.filter[ 2 ] = ply
            if TraceLine( lockerTrTbl ).Fraction != 1.0 then continue end 

            ply.l_TF_NextLockerResupplyTime = ( CurTime() + 3 )
            ply:SetHealth( max( ply:Health(), ply:GetMaxHealth() ) )

            LAMBDA_TF2:RemoveBurn( ply )
            LAMBDA_TF2:RemoveBleeding( ply )
            if ply.l_TF_CoveredInUrine then ply.l_TF_CoveredInUrine = 0 end
            if ply.l_TF_CoveredInMilk then ply.l_TF_CoveredInMilk = 0 end

            if ply.l_TF_IsStunned then
                ply.l_TF_IsStunned = 0
            end

            if !ply.IsLambdaPlayer then
                local gottenAmmo = {}
                local plyAmmo = ply:GetAmmo()

                for ammoID, ammoCount in pairs( plyAmmo ) do
                    local maxAmmo = GetAmmoMax( ammoID )
                    if ammoCount < maxAmmo then ply:SetAmmo( maxAmmo, ammoID ) end
                    gottenAmmo[ ammoID ] = true
                end

                plyAmmo = ply:GetAmmo()
                for _, wep in ipairs( ply:GetWeapons() ) do
                    local primType = wep:GetPrimaryAmmoType()
                    if !gottenAmmo[ primType ] then
                        local primAmmo = GetAmmoMax( primType )
                        if primAmmo != -1 and ( !plyAmmo[ primType ] or plyAmmo[ primType ] < primAmmo ) then 
                            ply:SetAmmo( primAmmo, primType ) 
                        end
                    end

                    local secType = wep:GetSecondaryAmmoType()
                    if !gottenAmmo[ secType ] then
                        local secAmmo = GetAmmoMax( secType )
                        if secAmmo != -1 and ( !plyAmmo[ secType ] or plyAmmo[ secType ] < secAmmo ) then 
                            ply:SetAmmo( secAmmo, secType ) 
                        end
                    end
                end
            else
                ply.l_TF_ThrownBaseball = false
                ply:SetShieldChargeMeter( 100 )

                for name, item in pairs( ply.l_TF_Inventory ) do
                    if item.NextUseTime then
                        item.IsReady = true
                        item.NextUseTime = 0
                    else
                        item.IsReady = LAMBDA_TF2.InventoryItems[ name ].Cooldown( ply )
                    end
                end
            end

            local openSeq = self:LookupSequence( "open" )
            if self:GetSequence() != openSeq then
                self:ResetSequence( openSeq )

                SimpleTimer( 2, function()
                    if !IsValid( self ) then return end
                    self:ResetSequence( "close" )
                end )
            end

            self:EmitSound( "items/regenerate.wav" )
        end

        self:NextThink( CurTime() )
        return true
    end

end