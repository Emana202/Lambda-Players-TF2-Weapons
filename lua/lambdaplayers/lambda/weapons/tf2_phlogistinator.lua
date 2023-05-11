table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_phlogistinator = {
        model = "models/lambdaplayers/tf2/weapons/w_phlogistinator.mdl",
        origin = "Team Fortress 2",
        prettyname = "Phlogistinator",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_phlogistinator",

        clip = 200,
        islethal = true,
        attackrange = 350,
        keepdistance = 250,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 100 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.04 )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_PREVENT_PHYSICS_FORCE )
            wepent:SetWeaponAttribute( "DamageCustom", ( TF_DMG_CUSTOM_IGNITE + TF_DMG_CUSTOM_BURNING_PHLOG ) )

            wepent:SetWeaponAttribute( "StartFireSound", ")weapons/phlog_ignite.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/phlog_loop.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/phlog_loop_crit.wav" )
            wepent:SetWeaponAttribute( "EndFireSound", ")weapons/phlog_end.wav" )
            
            wepent:SetWeaponAttribute( "PilotSound", false )
            wepent:SetWeaponAttribute( "FireParticleName", "drg_phlo_stream" )

            LAMBDA_TF2:FlamethrowerDeploy( self, wepent )
        end,

        OnThink = function( self, wepent, isdead )
            LAMBDA_TF2:FlamethrowerThink( self, wepent, isdead )

            if !isdead then
                if self.l_TF_MmmphMeter > 100 then
                    self.l_TF_MmmphMeter = 100
                end

                if !self.l_TF_MmmphActivated then 
                    if !self.l_TF_IsUsingItem and self.l_TF_MmmphMeter == 100 and self:InCombat() and self:IsInRange( self:GetEnemy(), 750 ) then
                        local useAnim, waitTime = self:LookupSequence( "pyro_taunt_primary" )
                        if useAnim > 0 then
                            self:AddGestureSequence( useAnim, true )
                        else
                            waitTime = 2.266667
                        end

                        self.l_TF_IsUsingItem = true
                        self.l_TF_PreUseItemState = self:GetState()
                        self:CancelMovement()
                        self:SetState( "UseTFItem" )

                        self.l_TF_MmmphActivated = true
                        self.l_TF_InvulnerabilityTime = ( CurTime() + waitTime )
                        self:PlaySoundFile( "laugh" )

                        self:SimpleWeaponTimer( waitTime, function()
                            self.l_TF_MmmphMeter = 100
                            self.l_TF_IsUsingItem = false
                            self:SetState( self.l_TF_PreUseItemState )
                        end )
                    end
                else
                    LAMBDA_TF2:AddCritBoost( self, "PhlogCritBoost", TF_CRIT_FULL, 0.1 )
                end
            end
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:FlamethrowerHolster( self, wepent )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:FlamethrowerFire( self, wepent, target )
            return true
        end
    }
} )