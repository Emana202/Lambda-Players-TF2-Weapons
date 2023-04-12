local random = math.random
local min = math.min
local ceil = math.ceil
local floor = math.floor

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_chocolate = {
        model = "models/lambdaplayers/tf2/weapons/w_chocolate.mdl",
        origin = "Team Fortress 2",
        prettyname = "Dalokohs Bar",
        holdtype = "slam",
        bonemerge = true,
  
		islethal = false,
        isedible = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetSkin( self.l_TF_TeamColor )
        end,

        OnDrop = function( self, wepent, cs_prop )
            cs_prop:Remove()
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead then self:UseWeapon() end
            return 1.0
        end,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = ( CurTime() + 10 )

            local waitTime = 4.3
            local useAnim = self:LookupSequence( "heavy_taunt_sandwich" )
            if useAnim > 0 then self:AddGestureSequence( useAnim, true ) end

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            local barIndex = ( #self.l_TF_DalokohsBars + 1 )
            self.l_TF_DalokohsBars[ barIndex ] = {
                HealthRatio = 1.0,
                ExpireTime = ( CurTime() + 30 )
            }

            local preEatHP = self:GetMaxHealth()
            for i = 1, 4 do
                self:SimpleWeaponTimer( ( ( waitTime / 4 ) * i ), function()
                    if !self.l_TF_DalokohsBars[ barIndex ] then return end

                    if i == 1 then 
                        self:EmitSound( "vo/sandwicheat09.mp3", 80, self:GetVoicePitch(), nil, CHAN_VOICE )
                        wepent:SetBodygroup( 1, 1 )
                    end

                    local giveHP = ceil( ( preEatHP / 3 ) / 4 )
                    local maxHP = min( self:GetMaxHealth() + giveHP, ( preEatHP / 0.75 ) )
                    self:SetMaxHealth( maxHP )
                    LAMBDA_TF2:GiveHealth( self, giveHP, false )

                    self.l_TF_DalokohsBars[ barIndex ].HealthRatio = ( maxHP / preEatHP )
                end )
            end

            self:SimpleWeaponTimer( waitTime, function()
                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )