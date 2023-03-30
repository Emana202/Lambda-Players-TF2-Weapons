local floor = math.floor
local random = math.random
local Rand = math.Rand
local min = math.min
local SimpleTimer = timer.Simple

local function OnBallCollide( ball, data, collider )
    if ball.l_Touched then return end

    ball.l_Touched = true
    SafeRemoveEntityDelayed( ball, 4 )

    local owner = ball:GetOwner()
    if !IsValid( owner ) then return end

    local hitEnt = data.HitEntity
    if !IsValid( hitEnt ) or hitEnt == owner or !LAMBDA_TF2:IsValidCharacter( hitEnt ) then 
        if IsValid( hitEnt ) and hitEnt != owner then
            ball:EmitSound( "weapons/bat_baseball_hit_world" .. random( 1, 2 ) .. ".wav", nil, nil, nil, CHAN_STATIC )
        end
        return 
    end

    local dmgTypes = DMG_CLUB
    local critType = ball.l_TF_CritType
    if critType == CRIT_FULL then 
        dmgTypes = ( dmgTypes + DMG_CRITICAL )
    elseif critType == CRIT_MINI then
        dmgTypes = ( dmgTypes + DMG_MINICRITICAL )
    end
        
    local lifeTimeRatio = ( min( CurTime() - ball.l_CreationTime, 1.0 ) / 1.0 )
    if lifeTimeRatio > 0.1 then
        local isMoonShot = false
        local stunDuration = ( 6.0 * lifeTimeRatio )
        if critType == CRIT_FULL then stunDuration = ( stunDuration + 2.0 ) end

        if lifeTimeRatio >= 1.0 then
            isMoonShot = true
            stunDuration = ( stunDuration + 1.0 )
        end

        LAMBDA_TF2:Stun( hitEnt, stunDuration, isMoonShot )
    end

    local dmginfo = DamageInfo()
    dmginfo:SetAttacker( owner )
    dmginfo:SetInflictor( owner:GetWeaponENT() )
    dmginfo:SetDamage( 15 )
    dmginfo:SetDamageCustom( TF_DMG_CUSTOM_BASEBALL )
    dmginfo:SetDamageForce( data.OurOldVelocity:GetNormalized() * 15 )
    dmginfo:SetDamagePosition( ball:GetPos() )
    dmginfo:SetDamageType( dmgTypes )

    hitEnt:DispatchTraceAttack( dmginfo, ball:GetTouchTrace(), ball:GetForward() )
    hitEnt:EmitSound( ")weapons/bat_baseball_hit_flesh.wav", nil, nil, nil, CHAN_STATIC )
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

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.5 )
            wepent:SetWeaponAttribute( "HitSound", ")weapons/bat_hit.wav" )

            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        
            wepent.l_TF_Sandman_PreEquipHealth = self:GetMaxHealth()
            self:SetMaxHealth( wepent.l_TF_Sandman_PreEquipHealth * 0.85 )
            self:SetHealth( floor( self:Health() * ( self:GetMaxHealth() / wepent.l_TF_Sandman_PreEquipHealth ) ) )
        end,
        
        OnThink = function( self, wepent, isdead )
            if !isdead and !self.l_TF_ThrownBaseball and self:InCombat() and CurTime() > self.l_WeaponUseCooldown then 
                local ene = self:GetEnemy()
                if !self:IsInRange( ene, 150 ) and self:CanSee( ene ) then
                    local throwAnim = self:LookupSequence( "scout_range_ball" )
                    if throwAnim > 0 then
                        self:AddGestureSequence( throwAnim )
                    else
                        self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                        self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )
                    end

                    self.l_WeaponUseCooldown = ( CurTime() + 0.75 )
                    self:LookTo( ene, 0.75 )

                    self:SimpleWeaponTimer( 0.5, function()
                        self.l_TF_ThrownBaseball = ( CurTime() + 10 )
                        wepent:EmitSound( ")weapons/bat_baseball_hit" .. random( 1, 2 ) .. ".wav", 75, nil, nil, CHAN_STATIC )

                        local spawnPos = ( self:GetPos() + vector_up * 50 )
                        local spawnAng = ( ene:GetPos() - spawnPos ):Angle()
                        spawnPos = ( spawnPos + spawnAng:Forward() * 32 )
                        spawnAng = ( ene:GetPos() - spawnPos ):Angle()

                        local ball = ents.Create( "base_anim" )
                        ball:SetModel( "models/weapons/w_models/w_baseball.mdl" )
                        ball:SetPos( spawnPos )
                        ball:SetAngles( spawnAng )
                        ball:SetOwner( self )
                        ball:Spawn()
                        
                        ball:PhysicsInit( SOLID_BBOX )
                        ball:SetGravity( 0.4 )
                        ball:SetFriction( 0.2 )
                        ball:SetElasticity( 0.45 )
                        ball:AddSolidFlags( FSOLID_NOT_STANDABLE )
                        LAMBDA_TF2:TakeNoDamage( ball )
                        SafeRemoveEntityDelayed( ball, 15 )

                        local phys = ball:GetPhysicsObject()
                        if IsValid( phys ) then
                            local spawnVel = ( ( spawnAng:Forward() * 10 + spawnAng:Up() * 1 ):GetNormalized() * 3000 )
                            phys:SetVelocity( spawnVel )
                            phys:AddAngleVelocity( Vector( 0, Rand( 0, 100 ), 0 ) )
                            phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG + FVPHYSICS_NO_PLAYER_PICKUP + FVPHYSICS_NO_NPC_IMPACT_DMG )
                        end

                        local trail = LAMBDA_TF2:CreateSpriteTrailEntity( self:GetPlyColor():ToColor(), nil, 5.4, 0, 0.4, "trails/laser", ball:WorldSpaceCenter(), ball )
                        SimpleTimer( 3, function()
                            if !IsValid( trail ) then return end
                            local curPos = trail:GetPos()
                            trail:SetParent( NULL )
                            SafeRemoveEntityDelayed( trail, 1 )
                            trail:SetPos( curPos )
                        end )
                        ball:DeleteOnRemove( trail )
                        
                        ball.l_Trail = trail
                        ball.l_CreationTime = CurTime()
                        ball.l_Touched = false
                        ball.l_IsTFProjectile = true

                        local critType = LAMBDA_TF2:GetCritBoost( self )
                        if wepent:CalcIsAttackCriticalHelper() then critType = CRIT_FULL end
                        ball.l_TF_CritType = critType

                        ball.PhysicsCollide = OnBallCollide
                    end )
                end
            end

            return Rand( 0.1, 0.33 )
        end,

        OnHolster = function( self, wepent )
            self:SetHealth( floor( self:Health() * ( wepent.l_TF_Sandman_PreEquipHealth / self:GetMaxHealth() ) ) )
            self:SetMaxHealth( wepent.l_TF_Sandman_PreEquipHealth )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end
    }
} )