local random = math.random
local Rand = math.Rand
local DamageInfo = DamageInfo
local IsValid = IsValid
local ents_Create = ents.Create
local TraceLine = util.TraceLine
local trAttackTbl = { mask = ( MASK_SOLID + CONTENTS_HITBOX ) }
local ringSize = Vector( 1, 1, 1 )

local reloadData = {
    StartDelay = 0.566667,
    Animation = ACT_HL2MP_GESTURE_RELOAD_AR2,
    CycleSound = "weapons/bison_reload.wav",
    CycleDelay = 0.333333,
    LayerCycle = 0.625,
    LayerPlayRate = 1.33,
    EndFunction = false
}

local function OnEnergyRingTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS or ent:GetSolidFlags() == FSOLID_NOT_SOLID then return end

    local touchTr = self:GetTouchTrace()
    if touchTr.HitSky then self:Remove() return end
    
    local owner = self:GetOwner()
    local impactColor = 0
    if IsValid( owner ) then 
        if ent == owner then return end
        impactColor = owner:GetPlyColor()

        if LambdaIsValid( ent ) and LAMBDA_TF2:TakesDamage( ent ) and ( !LAMBDA_TF2:IsValidCharacter( ent ) or owner:CanTarget( ent ) ) then
            local hitTimes = self.l_HitEntities[ ent ]
            if hitTimes and hitTimes >= 2 then return end

            local dmginfo = DamageInfo()
            dmginfo:SetDamage( 12 )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamagePosition( self:GetPos() )
            dmginfo:SetDamageType( DMG_BULLET )

            dmginfo:SetDamageCustom( TF_DMG_CUSTOM_USEDISTANCEMOD + TF_DMG_CUSTOM_NOCLOSEDISTANCEMOD + TF_DMG_CUSTOM_PLASMA )
            LAMBDA_TF2:SetCritType( dmginfo, self.l_CritType )

            trAttackTbl.start = self:WorldSpaceCenter()
            trAttackTbl.endpos = ent:WorldSpaceCenter()
            trAttackTbl.filter = self
            ent:DispatchTraceAttack( dmginfo, TraceLine( trAttackTbl ), self:GetVelocity() )

            local vecDelta = ( ent:GetPos() - self:GetPos() )
            local vecNormalVel = self:GetVelocity():GetNormalized()
            local vecNewPos = ( ( vecDelta:Dot( vecNormalVel ) * vecNormalVel ) + self:GetPos() )

            if !hitTimes then
                LAMBDA_TF2:DispatchColorParticle( self, "drg_pomson_impact", PATTACH_WORLDORIGIN, vecNewPos, impactColor )
                ent:EmitSound( ")weapons/fx/rics/bison_projectile_impact_world.wav", nil, nil, nil, CHAN_STATIC )
            end
            self.l_HitEntities[ ent ] = ( !hitTimes and 1 or ( hitTimes + 1 ) )

            return 
        end
    end

    LAMBDA_TF2:DispatchColorParticle( self, "drg_pomson_impact", PATTACH_WORLDORIGIN, self:GetPos(), impactColor )
    self:EmitSound( ")weapons/fx/rics/bison_projectile_impact_world.wav", nil, nil, nil, CHAN_STATIC )
    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_righteousbison = {
        model = "models/lambdaplayers/tf2/weapons/w_righteousbison.mdl",
        origin = "Team Fortress 2",
        prettyname = "Righteous Bison",
        holdtype = "revolver",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_righteousbison",

        clip = 4,
        islethal = true,
        attackrange = 1500,
        keepdistance = 750,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "RateOfFire", { 0.8, 1.0 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/bison_main_shot_01.wav",
                ")weapons/bison_main_shot_02.wav"
            } )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/bison_main_shot_crit.wav" )
            wepent:SetWeaponAttribute( "FireBullet", false )

            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = target:WorldSpaceCenter()
            targetPos = LAMBDA_TF2:CalculateEntityMovePosition( target, spawnPos:Distance( targetPos ), 1200, Rand( 0.5, 1.1 ), targetPos )

            local spawnAng = ( targetPos - spawnPos ):Angle()
            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end
            
            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if !LAMBDA_TF2:WeaponAttack( self, wepent, target, isCrit ) then return end

            local plyColor = self:GetPlyColor()
            LAMBDA_TF2:DispatchColorParticle( wepent, "drg_bison_muzzleflash", PATTACH_POINT_FOLLOW, 1, plyColor )

            local energyRing = ents_Create( "base_anim" )
            energyRing:SetPos( spawnPos )
            energyRing:SetAngles( spawnAng )
            energyRing:SetModel( "models/weapons/w_models/w_drg_ball.mdl" )
            energyRing:SetOwner( self )
            energyRing:Spawn()

            energyRing:SetSolid( SOLID_BBOX )
            energyRing:SetMoveType( MOVETYPE_FLY )
            energyRing:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )
            energyRing:SetLocalVelocity( spawnAng:Forward() * 1200 )

	        energyRing:SetRenderMode( RENDERMODE_NONE )
	        energyRing:SetSolidFlags( FSOLID_TRIGGER + FSOLID_NOT_SOLID )
	        energyRing:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )

            energyRing:SetCollisionBounds( -ringSize, ringSize )
            energyRing:SetGravity( 0.3 )
            LAMBDA_TF2:TakeNoDamage( energyRing )

            local critType = self:GetCritBoostType()
            if isCrit then critType = TF_CRIT_FULL end
            
            local trailEffectName = "drg_bison_projectile" .. ( critType == TF_CRIT_FULL and "_crit" or "" )
            LAMBDA_TF2:DispatchColorParticle( energyRing, trailEffectName, PATTACH_ABSORIGIN_FOLLOW, 0, plyColor, true )

            energyRing.l_CritType = critType
            energyRing.l_HitEntities = {}
            energyRing.Touch = OnEnergyRingTouch

            energyRing.IsLambdaWeapon = true
            energyRing.l_IsTFWeapon = true
            energyRing.l_killiconname = wepent.l_killiconname

            return true
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, reloadData )
            return true
        end
    }
} )