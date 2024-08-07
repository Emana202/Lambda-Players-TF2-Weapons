local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local ignorePlys = GetConVar( "ai_ignoreplayers" )

local angularImpulse = Angle( 500, 0, 0 )
local hitFleshSnds = {
    ")weapons/cleaver_hit_02.wav",
    ")weapons/cleaver_hit_03.wav",
    ")weapons/cleaver_hit_05.wav",
    ")weapons/cleaver_hit_06.wav",
    ")weapons/cleaver_hit_07.wav"
}

local function OnCleaverTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end
    if ent:IsPlayer() and ignorePlys:GetBool() then self:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end

    local owner = self:GetOwner()
    if IsValid( owner ) then 
        if ent == owner then return end

        if IsValid( ent ) then
            local critType = self.l_CritType

            if LAMBDA_TF2:IsValidCharacter( ent ) then
                LAMBDA_TF2:MakeBleed( ent, owner, owner:GetWeaponENT(), 5 )
                
                if ( CurTime() - self:GetCreationTime() ) >= 1 then
                    LAMBDA_TF2:DecreaseInventoryCooldown( owner, "tf2_cleaver", 1.5 )
                    if critType == TF_CRIT_NONE then critType = TF_CRIT_MINI end
                end
            end

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( 30 )
            dmginfo:SetDamagePosition( self:GetPos() )
            dmginfo:SetDamageForce( self:GetVelocity() * dmginfo:GetDamage() )
            dmginfo:SetDamageType( DMG_GENERIC )
            LAMBDA_TF2:SetCritType( dmginfo, critType )

            ent:DispatchTraceAttack( dmginfo, touchTr, self:GetForward() )
        end
    end
    
    self:AddSolidFlags( FSOLID_NOT_SOLID )
    self:SetMoveType( MOVETYPE_NONE )

    if IsValid( ent ) and LAMBDA_TF2:IsValidCharacter( ent, false ) then
        self:EmitSound( hitFleshSnds[ LambdaRNG( #hitFleshSnds ) ], nil, nil, nil, CHAN_STATIC )
        LAMBDA_TF2:CreateBloodParticle( self:GetPos(), AngleRand( -180, 180 ), ent )

        self:SetNoDraw( true )
        self:DrawShadow( false )
        self:SetSolid( SOLID_NONE )
        SafeRemoveEntityDelayed( self, 0.1 )
    else
        self:EmitSound( ")weapons/cleaver_hit_world.wav", nil, nil, nil, CHAN_STATIC )
        self:SetPos( touchTr.HitPos + touchTr.HitNormal * 3 )
        SafeRemoveEntityDelayed( self, 2 )
        
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_red_glow" )
        LAMBDA_TF2:StopParticlesNamed( self, "peejar_trail_blu_glow" )
    end
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_cleaver = {
        model = "models/lambdaplayers/tf2/weapons/w_cleaver.mdl",
        origin = "Team Fortress 2",
        prettyname = "Flying Guillotine",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 1,

        killicon = "lambdaplayers/killicons/icon_tf2_flyingguillotine",
        keepdistance = 750,
        attackrange = 2500,
		islethal = true,
        ismelee = false,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )
            if !wepent.l_TF_CleaverSkin then wepent.l_TF_CleaverSkin = LambdaRNG( 1, 2 ) end
            wepent:SetSkin( wepent.l_TF_CleaverSkin )
            wepent:EmitSound( "weapons/cleaver_draw.wav", nil, nil, nil, CHAN_STATIC )
        end,

        OnAttack = function( self, wepent, target )
            local throwPos = target:GetPos()
            local throwAng = ( throwPos - self:GetPos() ):Angle()
            if self:GetForward():Dot( throwAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            self.l_WeaponUseCooldown = ( CurTime() + 2 )
            
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true )

            wepent:EmitSound( ")weapons/cleaver_throw.wav", 70, nil, nil, CHAN_WEAPON )

            self:SimpleWeaponTimer( 0.25, function()
                local spawnPos = self:GetAttachmentPoint( "eyes" ).Pos
                throwPos = ( IsValid( target ) and target:GetPos() or ( self:GetPos() + self:GetForward() * 500 ) )
                throwAng = ( throwPos - spawnPos ):Angle()

                self:ClientSideNoDraw( wepent, true )
                wepent:SetNoDraw( true )
                wepent:DrawShadow( false )

                local cleaver = ents_Create( "base_gmodentity" )
                cleaver:SetModel( wepent:GetModel() )
                cleaver:SetPos( spawnPos )
                cleaver:SetAngles( throwAng )
                cleaver:SetOwner( self )
                cleaver:Spawn()

                cleaver:SetSolid( SOLID_BBOX )
                cleaver:SetMoveType( MOVETYPE_FLYGRAVITY )
                cleaver:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
                LAMBDA_TF2:TakeNoDamage( cleaver )
                
                cleaver:SetFriction( 0.2 )
                cleaver:SetElasticity( 0.45 )
                cleaver:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

                local throwVel = vector_origin
                throwVel = throwVel + throwAng:Forward() * 10
                throwVel = throwVel + throwAng:Up() * 1
                throwVel:Normalize()
                throwVel = throwVel * 3000

                cleaver:SetLocalVelocity( throwVel )
                cleaver:SetLocalAngularVelocity( angularImpulse )
    
                cleaver:SetSkin( wepent.l_TF_CleaverSkin )
                ParticleEffectAttach( "peejar_trail_" .. ( self.l_TF_TeamColor == 1 and "blu" or "red" ) .. "_glow", PATTACH_ABSORIGIN_FOLLOW, cleaver, 0 )

                cleaver.l_IsTFWeapon = true
                cleaver.Touch = OnCleaverTouch
                
                cleaver.IsLambdaWeapon = true
                cleaver.l_killiconname = wepent.l_killiconname

                local critType = self:l_GetCritBoostType()
                if wepent:CalcIsAttackCriticalHelper() then critType = TF_CRIT_FULL end
                cleaver.l_CritType = critType

                LAMBDA_TF2:AddInventoryCooldown( self )
                self:SimpleWeaponTimer( 0.8, function()
                    self:SwitchToLethalWeapon()
                end )
            end )

            return true
        end
    }
} )