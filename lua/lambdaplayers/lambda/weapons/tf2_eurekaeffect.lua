local ParticleEffect = ParticleEffect
local sound_Play = sound.Play
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_eurekaeffect = {
        model = "models/lambdaplayers/tf2/weapons/w_eurekaeffect.mdl",
        origin = "Team Fortress 2",
        prettyname = "Eureka Effect",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_eureka_effect",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", "weapons/wrench_swing.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/wrench_swing_crit.wav" )

            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
            wepent:EmitSound( "weapons/draw_wrench_engineer.wav", nil, nil, nil, CHAN_STATIC )
            self:SimpleWeaponTimer( 0.666667, function()
                wepent:EmitSound( "weapons/metal_hit_hand" .. random( 3 ) .. ".wav", nil, nil, 0.1 )
            end )
        end,

        OnThink = function( self, wepent, isdead )
            if isdead or self.l_TF_IsUsingItem or !self.l_issmoving then return end

            local spawnPos = self.l_SpawnPos
            if self:IsInRange( spawnPos, 1000 ) or spawnPos:DistToSqr( self:GetDestination() ) > 262144 then return end

            local useAnim, waitTime = self:LookupSequence( "engineer_taunt_wrenchtele" )
            if useAnim > 0 then
                self:AddGestureSequence( useAnim, true )
            else
                waitTime = 2
            end
            sound_Play( ")weapons/drg_wrench_teleport.wav", self:WorldSpaceCenter(), 90, 100, 1 )

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            self:SimpleWeaponTimer( 1.9, function()
                local prefix = ( self.l_TF_TeamColor == 1 and "_blue" or "_red" )
                ParticleEffect( "teleported" .. prefix, self:GetPos(), angle_zero )
                ParticleEffect( "player_sparkles" .. prefix, self:GetPos(), angle_zero, ent )
            end )

            self:SimpleWeaponTimer( waitTime, function()
                self:SetPos( spawnPos )
                self:SetAngles( self.l_SpawnAngles )
                self:EmitSound( ")weapons/teleporter_send.wav", 70, nil, nil, CHAN_STATIC )

                self.l_TF_IsUsingItem = false
                self:SetState( self.l_TF_PreUseItemState )
            end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )