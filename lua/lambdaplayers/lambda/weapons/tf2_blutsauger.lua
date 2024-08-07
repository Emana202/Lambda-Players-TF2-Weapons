local CurTime = CurTime
local IsValid = IsValid
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local IsFirstTimePredicted = IsFirstTimePredicted
local EffectData = EffectData
local util_Effect = util.Effect
local DamageInfo = DamageInfo
local Clamp = math.Clamp

local function OnSyringeTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end

    local dmgCustom = self.l_DamageCustom
    local critType = self.l_CritType
    if critType == TF_CRIT_FULL then
        dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_CRITICAL )
    elseif critType == TF_CRIT_MINI then
        dmgCustom = ( dmgCustom + TF_DMG_CUSTOM_MINICRITICAL )
    end

    local owner = self:GetOwner()
    if IsValid( owner ) then 
        if ent == owner then return end

        local dmginfo = DamageInfo()
        dmginfo:SetDamage( self.l_Damage )
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( self )
        dmginfo:SetDamagePosition( self:GetPos() )
        dmginfo:SetDamageForce( self:GetVelocity() * self.l_Damage )
        dmginfo:SetDamageType( self.l_DamageType )
        dmginfo:SetDamageCustom( dmgCustom )
    
        ent:DispatchTraceAttack( dmginfo, touchTr, self:GetForward() )
    end
    
    self.l_Stopped = true
    self:AddSolidFlags( FSOLID_NOT_SOLID )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetLocalVelocity( vector_origin )
    self:SetPos( touchTr.HitPos )

    if IsFirstTimePredicted() then
        local effectData = EffectData()
        effectData:SetOrigin( touchTr.HitPos )
        effectData:SetStart( touchTr.StartPos )
        effectData:SetSurfaceProp( touchTr.SurfaceProps )
        effectData:SetHitBox( touchTr.HitBox )
        effectData:SetDamageType( self.l_DamageType )
        effectData:SetEntity( touchTr.Entity )
        util_Effect( "Impact", effectData )
    end

    if touchTr.HitWorld then
        SafeRemoveEntityDelayed( self, 10 )
        
        LAMBDA_TF2:StopParticlesNamed( self, "nailtrails_medic_red" )
        LAMBDA_TF2:StopParticlesNamed( self, "nailtrails_medic_blue" )
        LAMBDA_TF2:StopParticlesNamed( self, "nailtrails_medic_red_crit" )
        LAMBDA_TF2:StopParticlesNamed( self, "nailtrails_medic_blue_crit" )
    else
        self:Remove()
    end
end

local function OnSyringeThink( self )
    if !self.l_Stopped then self:SetAngles( self:GetVelocity():Angle() ) end
    self:NextThink( CurTime() + 0.1 )
    return true
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_blutsauger = {
        model = "models/lambdaplayers/tf2/weapons/w_leechgun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Blutsauger",
        holdtype = "crossbow",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_blutsauger",
        tfclass = 7,

        clip = 40,
        islethal = true,
        attackrange = 1750,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 6 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BULLET + DMG_PREVENT_PHYSICS_FORCE ) )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            wepent:SetWeaponAttribute( "Sound", ")weapons/syringegun_shoot.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/syringegun_shoot_crit.wav" )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageCustom", ( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_NOCLOSEDISTANCEMOD ) )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_syringe" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_primary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = target:WorldSpaceCenter()
            local dist = spawnPos:Distance( targetPos )
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, dist, 1000, LambdaRNG( 0.5, 1.1, true ), targetPos )

            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng.x = ( spawnAng.x + LambdaRNG( -1.5, 1.5, true ) - ( dist / 128 ) )
            spawnAng.y = ( spawnAng.y + LambdaRNG( -1.5, 1.5, true ) )
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end

            local syringe = ents_Create( "base_gmodentity" )
            if !IsValid( syringe ) then return true end

            syringe:SetPos( spawnPos )
            syringe:SetAngles( spawnAng )
            syringe:SetModel( "models/weapons/c_models/c_leechgun/c_leech_proj.mdl" )
            syringe:SetOwner( self )
            syringe:Spawn()

            syringe:SetSolid( SOLID_BBOX )
            syringe:SetMoveType( MOVETYPE_FLYGRAVITY )
            syringe:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
            syringe:SetGravity( 0.3 )
            LAMBDA_TF2:TakeNoDamage( syringe )

            local teamClr = self.l_TF_TeamColor
            syringe:SetSkin( teamClr )
            syringe:SetLocalVelocity( spawnAng:Forward() * 1000 )

            local critType = self:l_GetCritBoostType()
            if isCrit then critType = TF_CRIT_FULL end

            ParticleEffectAttach( "nailtrails_medic_" .. ( teamClr == 1 and "blue" or "red" ) .. ( critType == TF_CRIT_FULL and "_crit" or "" ), PATTACH_ABSORIGIN_FOLLOW, syringe, 0 )

            syringe.l_IsTFWeapon = true
            syringe.l_CritType = critType
            syringe.l_Stopped = false
            syringe.l_Damage = wepent:GetWeaponAttribute( "Damage" )
            syringe.l_DamageType = wepent:GetWeaponAttribute( "DamageType" )
            syringe.l_DamageCustom = wepent:GetWeaponAttribute( "DamageCustom" )
            
            syringe.IsLambdaWeapon = true
            syringe.l_killiconname = wepent.l_killiconname

            syringe.Touch = OnSyringeTouch
            syringe.Think = OnSyringeThink

            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, dealtDamage )
            if !dealtDamage then return end
            LAMBDA_TF2:GiveHealth( self, ( 2 * Clamp( dmginfo:GetDamage() / dmginfo:GetBaseDamage(), 0, 1 ) ), false )
        end,

        reloadtime = 1.305,
        reloadsounds = { { 0, "weapons/syringegun_worldreload.wav" } },

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
            local reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )
            self:SetLayerPlaybackRate( reloadLayer, 1.5 )
        end
    }
} )