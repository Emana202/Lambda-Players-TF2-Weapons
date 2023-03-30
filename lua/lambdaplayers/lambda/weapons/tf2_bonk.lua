local random = math.random
local ents_Create = ents.Create

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bonk = {
        model = "models/lambdaplayers/tf2/weapons/w_energy_drink.mdl",
        origin = "Team Fortress 2",
        prettyname = "Bonk! Atomic Punch",
        holdtype = "slam",
        bonemerge = true,
    
		islethal = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            wepent:SetSkin( random( 0, 1 ) )
            wepent:EmitSound( "player/pl_scout_dodge_can_open.wav", nil, nil, 0.5 )
        end,

        OnThink = function( self, wepent, isdead )
            if !isdead and ( self:IsPanicking() or self:InCombat() and self:IsInRange( self:GetEnemy(), 1000 ) ) then
                self:UseWeapon()
            end
        end,

        OnAttack = function( self, wepent )
            self.l_WeaponUseCooldown = ( CurTime() + 10 )
            self:EmitSound( "player/pl_scout_dodge_can_drink.wav", nil, self:GetVoicePitch(), nil, CHAN_VOICE )

            local useAnim, waitTime = self:LookupSequence( "scout_taunt_drink" )
            if useAnim > 0 then
                self:AddGestureSequence( useAnim, true )
            else
                waitTime = 1
            end

            self.l_TF_IsUsingItem = true
            self.l_TF_PreUseItemState = self:GetState()
            self:CancelMovement()
            self:SetState( "UseTFItem" )

            self:SimpleWeaponTimer( waitTime, function()
                self.l_TF_AtomicPunched = ( CurTime() + 8 )
                
                local whirlTrail = self.l_TF_AtomicPunched_Trail 
                if IsValid( whirlTrail ) then
                    whirlTrail:SetParent( NULL )
                    SafeRemoveEntityDelayed( whirlTrail, 1 )
                end

                whirlTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 24, 12, 0.5, "effects/beam001_white", self:WorldSpaceCenter(), self )
                self:DeleteOnRemove( whirlTrail )
                self.l_TF_AtomicPunched_Trail = whirlTrail
                
                local usedCan = ents_Create( "prop_physics" )
                usedCan:SetPos( wepent:GetPos() )
                usedCan:SetAngles( wepent:GetAngles() )
                usedCan:SetModel( wepent:GetModel() )
                usedCan:SetSkin( wepent:GetSkin() )
                usedCan:Spawn()
                usedCan:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                SafeRemoveEntityDelayed( usedCan, 10 )

                usedCan:EmitSound( "player/pl_scout_dodge_can_crush.wav", 65, nil, nil, CHAN_ITEM )
                usedCan.l_PlayedHitSound = false
                usedCan:AddCallback( "PhysicsCollide", function( can )
                    if !can.l_PlayedHitSound then
                        can.l_PlayedHitSound = true
                        can:EmitSound( "player/pl_scout_dodge_can_pitch.wav", 65, nil, nil, CHAN_ITEM )
                    end
                end )     

                self.l_TF_IsUsingItem = false
                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SetState( self.l_TF_PreUseItemState )
                self:SwitchToLethalWeapon()
            end )

            return true 
        end
    }
} )