local IsValid = IsValid
local max = math.max
local min = math.min
local CurTime = CurTime
local StripExtension = string.StripExtension

local vector_one = Vector( 1, 1, 1 )
local minicritClrVec = Vector( 1, 25, 25 )
local minicritClrVec2 = Vector( 127, 176, 98 )

matproxy.Add( {
    name = "ModelGlowColor",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        local result = vector_one

        if IsValid( ent ) then
            local owner = ( ent.l_TF_Owner or ent:GetOwner() )

            if IsValid( owner ) and owner.GetPlayerColor then
                local isCustom = ( mat:GetInt( "$iscustom" ) == 1 )
                local normCritMult = ( isCustom and 1.33 or 100 )

                local critBoost = owner:GetCritBoostType()
                if critBoost != TF_CRIT_NONE then
                    result = owner:GetPlayerColor()
                    if critBoost == TF_CRIT_MINI then
                        if isCustom then
                            result = minicritClrVec
                        else
                            result = minicritClrVec2
                        end
                    else
                        result = ( result * normCritMult )
                    end

                    owner.l_TF_ChargeGlowing = false
                elseif owner.IsLambdaPlayer then 
                    local charging = owner:GetIsShieldCharging()
                    if charging or owner:GetNextMeleeCrit() != TF_CRIT_NONE then
                        owner.l_TF_ChargeGlowing = true

                        local glow
                        if charging then
                            glow = ( ( 100 - owner:GetShieldChargeMeter() ) / 100 )
                        else
                            glow = ( 1.0 - min( ( CurTime() - owner:GetShieldLastNoChargeTime() - 1.5 ) / 0.3, 1.0 ) )
                        end

                        result = ( owner:GetPlayerColor() * normCritMult )
                        result[ 1 ] = max( result[ 1 ] * glow, 1 )
                        result[ 2 ] = max( result[ 2 ] * glow, 1 )
                        result[ 3 ] = max( result[ 3 ] * glow, 1 )
                    elseif owner.l_TF_ChargeGlowing then
                        local glow = ( 1.0 - min( ( CurTime() - owner:GetShieldLastNoChargeTime() ) / 0.3, 1.0 ) )
                        if glow <= 0 then owner.l_TF_ChargeGlowing = false end

                        result = ( owner:GetPlayerColor() * normCritMult )
                        result[ 1 ] = max( result[ 1 ] * glow, 1 )
                        result[ 2 ] = max( result[ 2 ] * glow, 1 )
                        result[ 3 ] = max( result[ 3 ] * glow, 1 )
                    end
                end
            end
        end

        mat:SetVector( self.ResultTo, result )
    end
} )

matproxy.Add( {
    name = "LambdaUberedModelColor",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        if !IsValid( ent ) then return end

        local plyClr = ent.GetPlayerColor
        if plyClr then
            local col = ( plyClr( ent ) * 0.5 )
            mat:SetVector( self.ResultTo, col )
            return
        end

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if !IsValid( owner ) then return end
        
        plyClr = owner.GetPlayerColor
        if !plyClr then return end

        local col = ( plyClr( owner ) * 0.5 )
        mat:SetVector( self.ResultTo, col )
    end
} )

matproxy.Add( {
    name = "LambdaInvulnLevel",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        if IsValid( ent ) and ent:GetIsInvulnerable() and ent:GetInvulnerabilityWearingOff() then
            mat:SetFloat( self.ResultTo, 0.0 )
            return
        end

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if IsValid( owner ) and owner:GetIsInvulnerable() and owner:GetInvulnerabilityWearingOff() then
            mat:SetFloat( self.ResultTo, 0.0 )
            return
        end

        mat:SetFloat( self.ResultTo, 1.0 )
    end
} )

matproxy.Add( {
    name = "CustomSteamImageOnModel",
    init = function( self, mat, values )
        self.DefaultTexture = mat:GetTexture( "$basetexture" )
    end,
    bind = function( self, mat, ent )
        mat:SetTexture( "$basetexture", self.DefaultTexture )
        if !IsValid( ent ) then return end 

        local owner = ( ent.l_TF_Owner or ent:GetOwner() )
        if !IsValid( owner ) or !owner.IsLambdaPlayer then return end

        local imagePath = owner:GetObjectorImage()
        mat:SetTexture( "$basetexture", ( LAMBDA_TF2.ObjectorSprayImages[ imagePath ] or StripExtension( imagePath ) ) )
    end
} )