local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local IsValid = IsValid
local DamageInfo = DamageInfo
local ParticleEffect = ParticleEffect
local TraceLine = util.TraceLine
local ParticleEffectAttach = ParticleEffectAttach
local ents_Create = ents.Create

local function OnFlareThink( flare )
    if flare.l_DidImpact and CurTime() > flare.l_ImpactTime then
        local impactEnt = flare.l_ImpactEntity
        if impactEnt then
            local flarePos = flare:GetPos()
            ParticleEffect( "flaregun_destroyed", flarePos, ( ( flarePos + flare.l_ImpactNormal ) - flarePos ):Angle(), impactEnt )
        end

        flare:Remove()
    end
    
    flare:NextThink( CurTime() + 0.1 )
    return true
end

local function OnFlareTouch( flare, ent )
    if flare.l_ImpactTime != 0 then return end
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local owner = flare:GetOwner()
    if owner == ent then return end

    if !flare.l_ImpactEntity then
        flare.l_ImpactEntity = ent
    end
    if !IsValid( ent ) then
        flare.l_DidImpact = true
    end

    local flarePos = flare:GetPos()
    local critType = flare.l_CritType
    if LAMBDA_TF2:IsBurning( ent ) and critType != TF_CRIT_FULL then critType = TF_CRIT_MINI end

    flare:AddSolidFlags( FSOLID_NOT_SOLID )
    LAMBDA_TF2:TakeNoDamage( flare )

    if IsValid( owner ) then 
        local dmginfo = DamageInfo()
        dmginfo:SetDamage( flare.l_Damage )
        dmginfo:SetAttacker( owner )
        dmginfo:SetInflictor( flare )
        dmginfo:SetDamagePosition( flarePos )
        dmginfo:SetDamageType( DMG_BULLET )

        dmginfo:SetDamageCustom( TF_DMG_CUSTOM_IGNITE + TF_DMG_CUSTOM_BURNING )
        LAMBDA_TF2:SetCritType( dmginfo, critType )

        ent:TakeDamageInfo( dmginfo )
    end

    if flare.l_DidImpact then
        flare:SetMoveType( MOVETYPE_FLY )
        flare:SetLocalVelocity( vector_origin )

        flare.l_ImpactTime = ( CurTime() + 0.1 )
        flare.l_ImpactNormal = flare:GetTouchTrace().HitNormal

        if IsValid( owner ) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( flare.l_Damage )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( owner:GetWeaponENT() )
            dmginfo:SetDamageType( DMG_BULLET )

            dmginfo:SetDamageCustom( TF_DMG_CUSTOM_IGNITE )
            LAMBDA_TF2:SetCritType( dmginfo, critType )

            LAMBDA_TF2:RadiusDamageInfo( dmginfo, flarePos, 110 )
        end

        local detonatePos = ( flarePos + vector_up * 8 )
        local detonateTr = TraceLine( {
            start = detonatePos,
            endpos = detonatePos - vector_up * 32,
            mask = MASK_SHOT_HULL,
            collisiongroup = COLLISION_GROUP_NONE,
            filter = flare
        } )
        ParticleEffect( "ExplosionCore_MidAir_Flare", flarePos, ( ( flarePos + detonateTr.HitNormal ) - flarePos ):Angle() )   
    else
        flare:EmitSound( "player/pl_impact_flare" .. random( 1, 3 ) .. ".wav", nil, nil, 0.7 )
    end

    flare:Remove()     
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_detonator = {
        model = "models/lambdaplayers/tf2/weapons/w_detonator.mdl",
        origin = "Team Fortress 2",
        prettyname = "Detonator",
        holdtype = "revolver",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_detonator",

        clip = 1,
        islethal = true,
        attackrange = 2000,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 15 )
            wepent:SetWeaponAttribute( "RateOfFire", 2.0 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", ")weapons/flare_detonator_launch.wav" )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "FireBullet", false )

            wepent:SetWeaponAttribute( "MuzzleFlash", "muzzle_shotgun" )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:SetSkin( self.l_TF_TeamColor )
            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/metal_hit_hand" .. random( 1, 3 ) .. ".wav", nil, nil, 0.74 ) end )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = target:WorldSpaceCenter()
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 2000, Rand( 0.4, 1.2 ), targetPos )
            targetPos = ( targetPos + vector_up * ( spawnPos:Distance( targetPos ) / random( 17.5, 25 ) ) )

            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -15, 15 ) + spawnAng:Up() * random( -15, 15 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return true end

            local flare = ents_Create( "base_gmodentity" )
            flare:SetPos( spawnPos )
            flare:SetAngles( spawnAng )
            flare:SetModel( "models/weapons/w_models/w_flaregun_shell.mdl" )
            flare:SetOwner( self )
            flare:Spawn()

            flare:SetSolid( SOLID_BBOX )
            flare:SetMoveType( MOVETYPE_FLYGRAVITY )
            flare:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
            flare:SetGravity( 0.3 )
            
            flare:SetSkin( self.l_TF_TeamColor )

            local launchVel = ( spawnAng:Forward() * 2000 )
            flare:SetLocalVelocity( launchVel )

            local critType = self:GetCritBoostType()
            if isCrit then critType = TF_CRIT_FULL end

            if critType == TF_CRIT_FULL then
                ParticleEffectAttach( "flaregun_trail_crit_" .. ( self.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, flare, 0 )
            else
                ParticleEffectAttach( "flaregun_trail_" .. ( self.l_TF_TeamColor == 1 and "blue" or "red" ), PATTACH_ABSORIGIN_FOLLOW, flare, 0 )
            end

            flare.l_IsTFWeapon = true
            flare.l_CritType = critType
            flare.l_DidImpact = false
            flare.l_ImpactEntity = nil
            flare.l_ImpactTime = 0
            flare.l_ImpactNormal = vector_origin
            flare.l_Damage = wepent:GetWeaponAttribute( "Damage" )
            flare.l_TF_AfterburnDuration = 7.5

            flare.Touch = OnFlareTouch
            flare.Think = OnFlareThink

            flare.IsLambdaWeapon = true
            flare.l_IsTFWeapon = true
            flare.l_killiconname = wepent.l_killiconname

            self:SimpleWeaponTimer( 0.8, function()
                self:ReloadWeapon()
            end )

            return true
        end,

        reloadtime = 1.2,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1.66,
        reloadsounds = { 
            { 0, "weapons/grenade_launcher_drum_open.wav" },
            { 0.2, "weapons/grenade_launcher_drum_load.wav" },
            { 0.766667, "weapons/flaregun_tube_closestart.wav" },
            { 0.833333, "weapons/flaregun_tube_closefinish.wav" }
        }
    }
} )