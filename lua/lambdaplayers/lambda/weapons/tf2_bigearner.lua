local random = math.random
local CurTime = CurTime
local min = math.min
local floor = math.floor

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_bigearner = {
        model = "models/lambdaplayers/weapons/tf2/w_switchblade.mdl",
        origin = "Team Fortress 2",
        prettyname = "The Big Earner",
        holdtype = "knife",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_bigearner",
        keepdistance = 10,
        attackrange = 45,
        islethal = true,
        ismelee = true,
		speedmultiplier = 1.07,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 25 )
            wepent:SetWeaponAttribute( "Animation", false )
            wepent:SetWeaponAttribute( "HitDelay", 0 )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/melee/knife_swing.mp3" )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageType", DMG_SLASH )
			wepent:SetWeaponAttribute( "HitSound", {
				")lambdaplayers/weapons/tf2/melee/blade_hit1.mp3",
				")lambdaplayers/weapons/tf2/melee/blade_hit2.mp3",
				")lambdaplayers/weapons/tf2/melee/blade_hit3.mp3"
			} )

			wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target, dmginfo )
                local vecToTarget = ( target:GetPos() - lambda:GetPos() ); vecToTarget.z = 0; vecToTarget:Normalize()
				local vecOwnerForward = lambda:GetForward(); vecOwnerForward.z = 0; vecOwnerForward:Normalize()
				local vecTargetForward = target:GetForward(); vecTargetForward.z = 0; vecTargetForward:Normalize()
                if vecToTarget:Dot( vecTargetForward ) <= 0 or vecToTarget:Dot( vecOwnerForward ) <= 0.5 or vecTargetForward:Dot( vecOwnerForward ) <= -0.3 then return end

				lambda:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
				local attackLayer = lambda:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
				lambda:SetLayerCycle( attackLayer, 0.2 )
				lambda:SetLayerPlaybackRate( attackLayer, 1.1 )

				dmginfo:SetDamage( target:Health() * 2 )
				dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BACKSTAB )
			end )

            wepent.l_TF_InSpeedBoost = false
            wepent.l_TF_SpeedBoostTrail = NULL
            
            wepent.l_TF_BigEarner_PreEquipHealth = self:GetMaxHealth()
            self:SetMaxHealth( wepent.l_TF_BigEarner_PreEquipHealth * 0.75 )
            self:SetHealth( floor( self:Health() * ( self:GetMaxHealth() / wepent.l_TF_BigEarner_PreEquipHealth ) ) )

			wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_melee.mp3", 70, 100, 0.5 )
			self:SimpleWeaponTimer( ( 10 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/knife_open1.mp3", 70, 100, 0.5, CHAN_STATIC ) end )
			self:SimpleWeaponTimer( ( 16 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/knife_open5.mp3", 70, 100, 0.5, CHAN_STATIC ) end )
			self:SimpleWeaponTimer( ( 22 / 30 ), function() wepent:EmitSound( "lambdaplayers/weapons/tf2/melee/knife_open8.mp3", 70, 100, 0.5, CHAN_STATIC ) end )
        end,

        OnHolster = function( self, wepent )
            self:SetHealth( floor( self:Health() * ( wepent.l_TF_BigEarner_PreEquipHealth / self:GetMaxHealth() ) ) )
            self:SetMaxHealth( wepent.l_TF_BigEarner_PreEquipHealth )
        end,

		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnThink = function( self, wepent )
            if wepent.l_TF_InSpeedBoost and ( dead or CurTime() >= wepent.l_TF_InSpeedBoost and CurTime() > self.l_nextspeedupdate ) then
                wepent.l_TF_InSpeedBoost = false
                self:EmitSound( ")lambdaplayers/weapons/tf2/discipline_device_power_down.mp3", nil, nil, nil, CHAN_STATIC )
                
                local boostTrail = self.l_TF_SpeedBoostTrail
                if IsValid( boostTrail ) then
                    boostTrail:SetParent()
                    SafeRemoveEntityDelayed( boostTrail, 1 )
                end
            end

            if wepent.l_TF_InSpeedBoost and CurTime() > self.l_nextspeedupdate then
                self:SimpleTimer( FrameTime(), function()
                    local desSpeed = self.loco:GetDesiredSpeed()
                    self.loco:SetDesiredSpeed( desSpeed + min( desSpeed * 0.4, 105 ) )
                end )
            end
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, lethal )
            if !lethal then return end

            if !wepent.l_TF_InSpeedBoost then
                local desSpeed = self.loco:GetDesiredSpeed()
                self.loco:SetDesiredSpeed( desSpeed + min( desSpeed * 0.4, 105 ) )
                
                local boostTrail = self.l_TF_SpeedBoostTrail 
                if !IsValid( boostTrail ) then 
                    boostTrail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 16, 8, 0.33, "effects/beam001_white", self:WorldSpaceCenter(), self )
                    self:DeleteOnRemove( boostTrail )
                    self.l_TF_SpeedBoostTrail = boostTrail
                end
            end
            
            wepent.l_TF_InSpeedBoost = CurTime() + 3
            self:EmitSound( ")lambdaplayers/weapons/tf2/discipline_device_power_up.mp3", nil, nil, nil, CHAN_STATIC )
        end
    }
} )