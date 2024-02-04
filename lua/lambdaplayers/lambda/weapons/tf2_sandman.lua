local Round = math.Round
local random = math.random
local Rand = math.Rand
local min = math.min
local SimpleTimer = timer.Simple
local IsValid = IsValid
local CurTime = CurTime
local DamageInfo = DamageInfo
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local function OnBallTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    if ent:IsPlayer() and ignorePlys:GetBool() then self:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end

    if self.l_Touched then 
        if ent.l_TF_ThrownBaseball then
            ent.l_TF_ThrownBaseball = 0
            self:Remove()
        end

        return 
    end

    local owner = self:GetOwner()
    local curVel = self:GetVelocity()
    if IsValid( owner ) then
        if ent == owner then return end

        if IsValid( ent ) then
            local critType = self.l_CritType

            if LAMBDA_TF2:IsValidCharacter( ent ) and owner:CanTarget( ent ) then
                local lifeTimeRatio = ( min( CurTime() - self:GetCreationTime(), 1.0 ) / 1.0 )
                if lifeTimeRatio > 0.1 then
                    local isMoonShot = false
                    local stunDuration = ( 6.0 * lifeTimeRatio )
                    if critType == TF_CRIT_FULL then stunDuration = ( stunDuration + 2.0 ) end
            
                    if lifeTimeRatio >= 1.0 then
                        isMoonShot = true
                        stunDuration = ( stunDuration + 1.0 )

                        ent:EmitSound( "player/pl_impact_stun_range.wav", 90, nil, nil, CHAN_STATIC )

                        net.Start( "lambda_tf2_stuneffect" )
                            net.WriteEntity( ent )
                            net.WriteBool( true )
                        net.Broadcast()
                    else
                        ent:EmitSound( "player/pl_impact_stun.wav", 80, nil, nil, CHAN_STATIC )
                    end
            
                    LAMBDA_TF2:Stun( ent, stunDuration, 0.5, isMoonShot )
                end
            end
    
            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( 15 )
            dmginfo:SetDamageForce( curVel * 15 )
            dmginfo:SetDamagePosition( self:GetPos() )
            dmginfo:SetDamageType( DMG_CLUB )
            LAMBDA_TF2:SetCritType( dmginfo, critType )

            ent:DispatchTraceAttack( dmginfo, touchTr, self:GetForward() )
            ent:EmitSound( ")weapons/bat_baseball_hit_flesh.wav", nil, nil, nil, CHAN_STATIC )
        elseif touchTr.HitWorld then
            self:EmitSound( "weapons/baseball_hitworld" .. random( 1, 3 ) .. ".wav", nil, nil, nil, CHAN_STATIC )
        end
    end

    self.l_Touched = true
    SafeRemoveEntityDelayed( self, 4 )

    self:PhysicsInit( SOLID_VPHYSICS )
    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then 
        phys:Wake() 
        phys:AddVelocity( -curVel * 0.1 ) 
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_sandman = {
        model = "models/lambdaplayers/tf2/weapons/w_wooden_bat.mdl",
        origin = "Team Fortress 2",
        prettyname = "Sandman",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_sandman",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,
        healthmultiplier = 0.9,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.5 )
            wepent:SetWeaponAttribute( "HitSound", ")weapons/bat_baseball_hit_flesh.wav" )

            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        end,
        
        OnThink = function( self, wepent, isdead )
            if !isdead and !self.l_TF_ThrownBaseball and self:InCombat() and CurTime() > self.l_WeaponUseCooldown then 
                local ene = self:GetEnemy()
                if !self:IsInRange( ene, 150 ) and self:IsInRange( ene, 2000 ) and self:CanSee( ene ) then
                    local throwAnim = self:LookupSequence( "scout_range_ball" )
                    if throwAnim > 0 then
                        self:AddGestureSequence( throwAnim )
                    else
                        self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                        self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )
                    end

                    self.l_WeaponUseCooldown = ( CurTime() + 0.75 )
                    self:LookTo( ene, 0.75 )

                    self:SimpleWeaponTimer( 0.45, function()
                        self.l_TF_ThrownBaseball = ( CurTime() + 10 )
                        wepent:EmitSound( ")weapons/bat_baseball_hit" .. random( 1, 2 ) .. ".wav", 75, nil, nil, CHAN_STATIC )

                        local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                        local targetPos = ene:GetPos()                        
                        targetPos = LAMBDA_TF2:CalculateEntityMovePosition( ene, spawnPos:Distance( targetPos ), 3000, Rand( 0.5, 1.1 ), targetPos )
                        targetPos = ( targetPos + ( vector_up * ( spawnPos:Distance( targetPos ) / 100 ) ) )

                        local spawnAng = ( targetPos - spawnPos ):Angle()
                        spawnPos = ( spawnPos + spawnAng:Forward() * 32 )
                        spawnAng = ( targetPos - spawnPos ):Angle()

                        local ball = ents.Create( "base_gmodentity" )
                        ball:SetModel( "models/weapons/w_models/w_baseball.mdl" )
                        ball:SetPos( spawnPos )
                        ball:SetAngles( spawnAng )
                        ball:SetOwner( self )
                        ball:Spawn()

                        ball:SetSolid( SOLID_BBOX )
                        ball:SetMoveType( MOVETYPE_FLYGRAVITY )
                        ball:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                        ball:AddSolidFlags( FSOLID_TRIGGER )
                        LAMBDA_TF2:TakeNoDamage( ball )

                        ball:SetFriction( 0.2 )
                        ball:SetElasticity( 0.45 )
                        ball:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
                        SafeRemoveEntityDelayed( ball, 15 )

                        ball:SetLocalVelocity( ( spawnAng:Forward() * 10 + spawnAng:Up() * 1 ):GetNormalized() * 3000 )
                        ball:SetLocalAngularVelocity( Angle( 0, Rand( 0, 100 ), 0 ) )

                        local trail = LAMBDA_TF2:CreateSpriteTrailEntity( nil, nil, 5.4, 0, 0.4, "effects/baseballtrail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ), ball:WorldSpaceCenter(), ball )
                        SimpleTimer( 3, function()
                            if !IsValid( trail ) then return end
                            local curPos = trail:GetPos()
                            trail:SetParent( NULL )
                            SafeRemoveEntityDelayed( trail, 1 )
                            trail:SetPos( curPos )
                        end )

                        ball:DeleteOnRemove( trail )
                        ball.l_Trail = trail

                        ball.l_IsTFWeapon = true
                        ball.l_Touched = false

                        local critType = self:GetCritBoostType()
                        if wepent:CalcIsAttackCriticalHelper() then critType = TF_CRIT_FULL end
                        ball.l_CritType = critType
                
                        ball.IsLambdaWeapon = true
                        ball.l_IsTFBaseball = true
                        ball.l_killiconname = "lambdaplayers_weaponkillicons_tf2_sandman_baseball"

                        ball.Touch = OnBallTouch
                    end )
                end
            end

            return Rand( 0.1, 0.33 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )